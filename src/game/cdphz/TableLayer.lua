local StaticData = require("app.static.StaticData")
local GameCommon = require("game.cdphz.GameCommon")
local NetMgr = require("common.NetMgr")
local NetMsgId = require("common.NetMsgId")
local EventMgr = require("common.EventMgr")
local EventType = require("common.EventType")
local NetMsgId = require("common.NetMsgId")
local Bit = require("common.Bit")
local Common = require("common.Common")
local Base64 = require("common.Base64")
local LocationSystem = require("common.LocationSystem")
local Default = require("common.Default")
local GameOperation = require("game.cdphz.GameOperation")
local GameLogic = require("game.cdphz.GameLogic")
local UserData = require("app.user.UserData")
local GameDesc = require("common.GameDesc")

local IsUseNewTP = true

local CardSendSpeed = 0.2
local CardSizeArr = {
	[1] = cc.size(75, 111),
	[2] = cc.size(87, 111),
	[3] = cc.size(94, 111),
}
local CardSpeedArr = {
	[1] = 0.5,
	[2] = 0.4,
	[3] = 0.3,
	[4] = 0.1,
}
local cardtype = cc.UserDefault:getInstance():getIntegerForKey('CDpaiSize', 2)
local CardSize = CardSizeArr[cardtype]
local IsOpenTin = cc.UserDefault:getInstance():getBoolForKey('CDisOpenTin', true)
local CtlSpeed = cc.UserDefault:getInstance():getIntegerForKey('CDspeed', 2)

local TableLayer = class("TableLayer", function()
	return ccui.Layout:create()
end)
local APPNAME = 'cdphz'
function TableLayer:create(root)
	local view = TableLayer.new()
	view:onCreate(root)
	local function onEventHandler(eventType)
		if eventType == "enter" then
			view:onEnter()
		elseif eventType == "exit" then
			view:onExit()
		end
	end
	view:registerScriptHandler(onEventHandler)
	return view
end

function TableLayer:onEnter()
	EventMgr:registListener(EventType.EVENT_TYPE_SKIN_CHANGE, self, self.EVENT_TYPE_SKIN_CHANGE)
	EventMgr:registListener(EventType.EVENT_TYPE_SIGNAL, self, self.EVENT_TYPE_SIGNAL)
	EventMgr:registListener(EventType.EVENT_TYPE_ELECTRICITY, self, self.EVENT_TYPE_ELECTRICITY)
	
	if GameCommon.tableConfig.nTableType ~= TableType_Playback then
		if PLATFORM_TYPE == cc.PLATFORM_OS_APPLE_REAL and cus.JniControl:getInstance():getSystemVersion() < 10 then
			local uiImage_signal = ccui.Helper:seekWidgetByName(self.root, "Image_signal")
			if uiImage_signal ~= nil then
				uiImage_signal:setVisible(false)
			end
		else
			-- self:addChild(require("common.GameTimeLayer"):create())
		end
	end
	UserData.User:initByLevel()
	
	local mousic = string.format("cdzipai/sound/bgmusic/room_bgm.mp3")
	cc.SimpleAudioEngine:getInstance():playMusic(mousic, true)
end

function TableLayer:onExit()
	EventMgr:unregistListener(EventType.EVENT_TYPE_SKIN_CHANGE, self, self.EVENT_TYPE_SKIN_CHANGE)
	EventMgr:unregistListener(EventType.EVENT_TYPE_SIGNAL, self, self.EVENT_TYPE_SIGNAL)
	EventMgr:unregistListener(EventType.EVENT_TYPE_ELECTRICITY, self, self.EVENT_TYPE_ELECTRICITY)
	
	if self.scheduleUpdateObj then
		cc.Director:getInstance():getScheduler():unscheduleScriptEntry(self.scheduleUpdateObj)
	end
	
	local Musictype = cc.UserDefault:getInstance():getFloatForKey("UserDefault_Musictype", 1)
	local mousic = string.format("achannel/%d/music%d.mp3", CHANNEL_ID, Musictype)
	cc.SimpleAudioEngine:getInstance():playMusic(mousic, true)
	self.dragTPData = nil
end

function TableLayer:onCreate(root)
	self.root = root
	self.cotrolCardTPData = nil
	self.locationPos = cc.p(0, 0)
	local touchLayer = ccui.Layout:create()
	self.root:addChild(touchLayer)
	local function onTouchBegan(touch, event)
		self.locationPos = touch:getLocation()
		return true
	end
	local function onTouchMoved(touch, event)
		self.locationPos = touch:getLocation()
	end
	local function onTouchEnded(touch, event)
		self.locationPos = touch:getLocation()
	end
	local listener = cc.EventListenerTouchOneByOne:create()
	listener:setSwallowTouches(false)
	listener:registerScriptHandler(onTouchBegan, cc.Handler.EVENT_TOUCH_BEGAN)
	listener:registerScriptHandler(onTouchMoved, cc.Handler.EVENT_TOUCH_MOVED)
	listener:registerScriptHandler(onTouchEnded, cc.Handler.EVENT_TOUCH_ENDED)
	cc.Director:getInstance():getEventDispatcher():addEventListenerWithSceneGraphPriority(listener, touchLayer)
	return true
end

function TableLayer:doAction(action, pBuffer)
	GameCommon.waitOutCardUser = nil
	if action == GameCommon.ACTION_OUT_CARD_NOTIFY then
		local wChairID = pBuffer.wCurrentUser
		GameCommon.waitOutCardUser = wChairID
		if wChairID == GameCommon:getRoleChairID() then
			local uiPanel_outCardTips = ccui.Helper:seekWidgetByName(self.root, "Panel_outCardTips")
			uiPanel_outCardTips:removeAllChildren()
			ccs.ArmatureDataManager:getInstance():addArmatureFileInfo("game/finger/finger.ExportJson")
			local armature = ccs.Armature:create("finger")
			uiPanel_outCardTips:addChild(armature)
			armature:getAnimation():playWithIndex(0)
			self.cotrolCardTPData = {}
			GameCommon.bIsOutCardTips = true	
			self:showTingPaiTips()
		else
			self.cotrolCardTPData = nil
		end
		self:runAction(cc.Sequence:create(cc.DelayTime:create(0), cc.CallFunc:create(function(sender, event) EventMgr:dispatch(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK) end)))
		
	elseif action == GameCommon.ACTION_TI_CARD then
		local wChairID = pBuffer.wActionUser
		local cbCardData = pBuffer.cbActionCard
		local cbCardIndex = GameLogic:SwitchToCardIndex(cbCardData)
		local viewID = GameCommon:getViewIDByChairID(wChairID)
		--判断是不是存在吃牌组合中
		local isExist = false
		local location = GameCommon.player[wChairID].bWeaveItemCount + 1
		for i = 1, GameCommon.player[wChairID].bWeaveItemCount do
			local key = i
			local var = GameCommon.player[wChairID].WeaveItemArray[i]
			if var.cbWeaveKind == GameCommon.ACK_WEI and var.cbCenterCard == cbCardData then
				isExist = true
				location = key
				GameCommon.player[wChairID].bWeaveItemCount = GameCommon.player[wChairID].bWeaveItemCount - 1
				table.remove(GameCommon.player[wChairID].WeaveItemArray, key)
				break
			end
		end
		if isExist == false then
			for i = 1, pBuffer.cbRemoveCount do
				self:removeHandCard(wChairID, cbCardData)
			end
			self:showHandCard(wChairID, 2)
		end
		local uiPanel_tipsCard = ccui.Helper:seekWidgetByName(self.root, "Panel_tipsCard")
		local uiPanel_tipsCardPos = ccui.Helper:seekWidgetByName(self.root, string.format("Panel_tipsCardPos%d", viewID))
		local uiPanel_userTips = ccui.Helper:seekWidgetByName(self.root, string.format("Panel_userTips%d", viewID))
		local uiSendOrOutCardNode = uiPanel_tipsCard:getChildByName("SendOrOutCardNode")
		local uiPanel_operation = ccui.Helper:seekWidgetByName(self.root, "Panel_operation")
		uiPanel_operation:removeAllChildren()
		--添加吃牌组合
		local WeaveItemArray = {}
		WeaveItemArray.cbWeaveKind = GameCommon.ACK_TI
		WeaveItemArray.cbCardCount = 4
		WeaveItemArray.cbCenterCard = cbCardData
		WeaveItemArray.cbCardList = {}
		for i = 1, 4 do
			WeaveItemArray.cbCardList[i] = cbCardData
		end
		if uiSendOrOutCardNode ~= nil then
			self:addWeaveItemArray(wChairID, WeaveItemArray, location, cc.p(uiSendOrOutCardNode:getPosition()))
			if uiSendOrOutCardNode.cbCardData == cbCardData then
				uiSendOrOutCardNode:removeFromParent()
			end
		else
			self:addWeaveItemArray(wChairID, WeaveItemArray, location, cc.p(uiPanel_tipsCardPos:getPosition()))
		end
		self:showCountDown(wChairID)
		if GameCommon.tableConfig.wKindID == 16 then
			if(pBuffer.cbRemoveCount == 4) then
				GameCommon:playAnimation(self.root, "提龙", wChairID)
			else
				GameCommon:playAnimation(self.root, "蛇", wChairID)
			end
		else
			GameCommon:playAnimation(self.root, "提", wChairID)
		end		
		self:runAction(cc.Sequence:create(cc.DelayTime:create(0.5), cc.CallFunc:create(function(sender, event) EventMgr:dispatch(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK) end)))
		
	elseif action == GameCommon.ACTION_PAO_CARD then
		local wChairID = pBuffer.wActionUser
		local cbCardData = pBuffer.cbActionCard
		local viewID = GameCommon:getViewIDByChairID(wChairID)
		local cbCardIndex = GameLogic:SwitchToCardIndex(cbCardData)
		--判断是不是存在吃牌组合中
		local isExist = false
		local location = GameCommon.player[wChairID].bWeaveItemCount + 1
		for i = 1, GameCommon.player[wChairID].bWeaveItemCount do
			local key = i
			local var = GameCommon.player[wChairID].WeaveItemArray[i]
			if(var.cbWeaveKind == GameCommon.ACK_WEI or var.cbWeaveKind == GameCommon.ACK_PENG) and var.cbCenterCard == cbCardData then
				isExist = true
				location = key
				GameCommon.player[wChairID].bWeaveItemCount = GameCommon.player[wChairID].bWeaveItemCount - 1
				table.remove(GameCommon.player[wChairID].WeaveItemArray, key)
				break
			end
		end
		if isExist == false then
			for i = 1, 3 do
				self:removeHandCard(wChairID, cbCardData)
			end
			self:showHandCard(wChairID, 2)
		end
		local uiPanel_tipsCard = ccui.Helper:seekWidgetByName(self.root, "Panel_tipsCard")
		local uiPanel_tipsCardPos = ccui.Helper:seekWidgetByName(self.root, string.format("Panel_tipsCardPos%d", viewID))
		local uiSendOrOutCardNode = uiPanel_tipsCard:getChildByName("SendOrOutCardNode")
		local uiPanel_operation = ccui.Helper:seekWidgetByName(self.root, "Panel_operation")
		uiPanel_operation:removeAllChildren()
		--添加吃牌组合
		local WeaveItemArray = {}
		WeaveItemArray.cbWeaveKind = GameCommon.ACK_PAO
		WeaveItemArray.cbCardCount = 4
		WeaveItemArray.cbCenterCard = cbCardData
		WeaveItemArray.cbCardList = {}
		for i = 1, 4 do
			WeaveItemArray.cbCardList[i] = cbCardData
		end
		if uiSendOrOutCardNode ~= nil then
			self:addWeaveItemArray(wChairID, WeaveItemArray, location, cc.p(uiSendOrOutCardNode:getPosition()))
			uiSendOrOutCardNode:removeFromParent()
		else
			self:addWeaveItemArray(wChairID, WeaveItemArray, location, cc.p(uiPanel_tipsCardPos:getPosition()))
		end
		
		if GameCommon.tableConfig.wKindID == 16 then
			for i = 0, GameCommon.gameConfig.bPlayerCount - 1 do
				if GameCommon.player[i].bDiscardCardCount ~= 0 then
					for k = 1, GameCommon.player[i].bDiscardCardCount do	
						if GameCommon.player[i].bDiscardCard[k] == cbCardData then
							GameCommon.player[i].bDiscardCardCount = GameCommon.player[i].bDiscardCardCount - 1
							self:deletingDiscardCard(i, k)
							break
						end		
					end
				end
			end
		end
		
		self:showCountDown(wChairID)
		GameCommon:playAnimation(self.root, "跑", wChairID)
		self:runAction(cc.Sequence:create(cc.DelayTime:create(0.5), cc.CallFunc:create(function(sender, event) EventMgr:dispatch(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK) end)))
		
	elseif action == GameCommon.ACTION_WEI_CARD then
		local wChairID = pBuffer.wActionUser
		local cbCardData = pBuffer.cbActionCard
		local cbCardIndex = GameLogic:SwitchToCardIndex(cbCardData)
		local viewID = GameCommon:getViewIDByChairID(wChairID)
		if GameCommon.tableConfig.wKindID == 16 then
			for i = 1, 3 do
				self:removeHandCard(wChairID, cbCardData)
			end
		else
			for i = 1, 2 do
				self:removeHandCard(wChairID, cbCardData)
			end
		end
		self:showHandCard(wChairID, 2)
		local uiPanel_tipsCard = ccui.Helper:seekWidgetByName(self.root, "Panel_tipsCard")
		local uiPanel_tipsCardPos = ccui.Helper:seekWidgetByName(self.root, string.format("Panel_tipsCardPos%d", viewID))
		local uiSendOrOutCardNode = uiPanel_tipsCard:getChildByName("SendOrOutCardNode")
		local uiPanel_operation = ccui.Helper:seekWidgetByName(self.root, "Panel_operation")
		uiPanel_operation:removeAllChildren()
		--添加吃牌组合
		local cbWeaveKind = GameCommon.ACK_WEI
		for k, v in pairs(GameCommon.player) do
			for i = 1, v.bDiscardCardCount do
				if v.bDiscardCard[i] == cbCardData then
					cbWeaveKind = GameCommon.ACK_CHOUWEI
					break
				end
			end
			for k, v in pairs(v.WeaveItemArray) do
				if v.cbWeaveKind == GameCommon.ACK_CHI and v.cbCenterCard == cbCardData then
					cbWeaveKind = GameCommon.ACK_CHOUWEI
					break
				end
			end
		end
		local WeaveItemArray = {}
		WeaveItemArray.cbWeaveKind = cbWeaveKind
		WeaveItemArray.cbCardCount = 3
		WeaveItemArray.cbCenterCard = cbCardData
		WeaveItemArray.cbCardList = {}
		for i = 1, 3 do
			WeaveItemArray.cbCardList[i] = cbCardData
		end
		if uiSendOrOutCardNode ~= nil then
			self:addWeaveItemArray(wChairID, WeaveItemArray, GameCommon.player[wChairID].bWeaveItemCount + 1, cc.p(uiSendOrOutCardNode:getPosition()))
			uiSendOrOutCardNode:removeFromParent()
		else
			self:addWeaveItemArray(wChairID, WeaveItemArray, GameCommon.player[wChairID].bWeaveItemCount + 1, cc.p(uiPanel_tipsCardPos:getPosition()))
		end
		self:showCountDown(wChairID)
		if(GameCommon.tableConfig.wKindID == 16) and pBuffer.lUserActionCout >= 3 then
			if(pBuffer.lUserActionCout == 3) then
				GameCommon:playAnimation(self.root, "坎三大", wChairID)
			elseif(pBuffer.lUserActionCout == 4) then
				GameCommon:playAnimation(self.root, "坎四清", wChairID)
			end
		else
			if WeaveItemArray.cbWeaveKind == GameCommon.ACK_CHOUWEI then
				GameCommon:playAnimation(self.root, "臭偎", wChairID)
			else
				GameCommon:playAnimation(self.root, "偎", wChairID)
			end
		end
		self:runAction(cc.Sequence:create(cc.DelayTime:create(0.5), cc.CallFunc:create(function(sender, event) EventMgr:dispatch(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK) end)))
		
	elseif action == GameCommon.ACTION_PENG_CARD then
		local wChairID = pBuffer.wActionUser
		local cbCardData = pBuffer.cbActionCard
		local cbCardIndex = GameLogic:SwitchToCardIndex(cbCardData)
		local viewID = GameCommon:getViewIDByChairID(wChairID)
		for i = 1, 2 do
			self:removeHandCard(wChairID, cbCardData)
		end
		self:showHandCard(wChairID, 2)
		local uiPanel_tipsCard = ccui.Helper:seekWidgetByName(self.root, "Panel_tipsCard")
		local uiPanel_tipsCardPos = ccui.Helper:seekWidgetByName(self.root, string.format("Panel_tipsCardPos%d", viewID))
		local uiSendOrOutCardNode = uiPanel_tipsCard:getChildByName("SendOrOutCardNode")
		local uiPanel_operation = ccui.Helper:seekWidgetByName(self.root, "Panel_operation")
		uiPanel_operation:removeAllChildren()
		--添加吃牌组合
		local WeaveItemArray = {}
		WeaveItemArray.cbWeaveKind = GameCommon.ACK_PENG
		WeaveItemArray.cbCenterCard = cbCardData
		WeaveItemArray.cbCardList = {}
		
		if GameCommon.tableConfig.wKindID == 16 and pBuffer.m_bDispatch == false then
			if uiSendOrOutCardNode ~= nil then			
				uiSendOrOutCardNode:runAction(cc.Sequence:create(cc.ScaleTo:create(0.2, 42 / uiSendOrOutCardNode:getContentSize().width, 42 / uiSendOrOutCardNode:getContentSize().height),
				cc.RemoveSelf:create(),
				cc.CallFunc:create(function(sender, event)
					print('==================>>>>>ACTION_PENG_CARD')
					self:addDiscardCard(sender.wChairID, sender.cbCardData)
				end)))
			end
			WeaveItemArray.cbCardCount = 2
			for i = 1, 2 do
				WeaveItemArray.cbCardList[i] = cbCardData
			end
			self:addWeaveItemArray(wChairID, WeaveItemArray, GameCommon.player[wChairID].bWeaveItemCount + 1, cc.p(uiPanel_tipsCardPos:getPosition()))
		else
			WeaveItemArray.cbCardCount = 3
			for i = 1, 3 do
				WeaveItemArray.cbCardList[i] = cbCardData
			end		
			if uiSendOrOutCardNode ~= nil then
				
				self:addWeaveItemArray(wChairID, WeaveItemArray, GameCommon.player[wChairID].bWeaveItemCount + 1, cc.p(uiSendOrOutCardNode:getPosition()))
				uiSendOrOutCardNode:removeFromParent()
			else
				self:addWeaveItemArray(wChairID, WeaveItemArray, GameCommon.player[wChairID].bWeaveItemCount + 1, cc.p(uiPanel_tipsCardPos:getPosition()))
			end			
		end
		
		self:showCountDown(wChairID)
		
		if(GameCommon.tableConfig.wKindID == 16) and pBuffer.lUserActionCout >= 3 then
			if pBuffer.lUserActionCout == 3 then		
				GameCommon:playAnimation(self.root, "碰三清", wChairID)
			elseif pBuffer.lUserActionCout == 4 then
				GameCommon:playAnimation(self.root, "碰四清", wChairID)
			end
		else
			GameCommon:playAnimation(self.root, "碰", wChairID)
		end
		self:runAction(cc.Sequence:create(cc.DelayTime:create(0.5), cc.CallFunc:create(function(sender, event) EventMgr:dispatch(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK) end)))
		
	elseif action == GameCommon.ACTION_CHI_CARD then
		local wChairID = pBuffer.wActionUser
		local cbActionCard = pBuffer.cbActionCard	
		local viewID = GameCommon:getViewIDByChairID(wChairID)
		local uiPanel_tipsCard = ccui.Helper:seekWidgetByName(self.root, "Panel_tipsCard")
		local uiPanel_tipsCardPos = ccui.Helper:seekWidgetByName(self.root, string.format("Panel_tipsCardPos%d", viewID))
		local uiSendOrOutCardNode = uiPanel_tipsCard:getChildByName("SendOrOutCardNode")
		local uiPanel_operation = ccui.Helper:seekWidgetByName(self.root, "Panel_operation")
		uiPanel_operation:removeAllChildren()
		local cbDebarCard = cbActionCard
		for i = 1, pBuffer.cbResultCount do
			--添加吃牌组合
			local cbCardData = pBuffer.cbCardData[i]
			local count = 0
			while 1 do
				local isFound = false
				for key, var in pairs(cbCardData) do
					if var == cbActionCard then
						table.remove(cbCardData, key)
						isFound = true
						break
					end
				end
				if isFound == false then
					break
				else
					count = count + 1
				end
			end
			for num = 1, count do
				table.insert(cbCardData, 3 - count + num, cbActionCard)
			end
			local WeaveItemArray = {}
			WeaveItemArray.cbWeaveKind = GameCommon.ACK_CHI
			WeaveItemArray.cbCardCount = 3
			WeaveItemArray.cbCenterCard = cbActionCard
			WeaveItemArray.cbCardList = cbCardData
			for key, var in pairs(WeaveItemArray.cbCardList) do
				if cbDebarCard ~= var then
					if GameLogic:IsValidCard(var) then
						self:removeHandCard(wChairID, var)
					end
				else
					cbDebarCard = 0
				end
			end
			if uiSendOrOutCardNode ~= nil then
				self:addWeaveItemArray(wChairID, WeaveItemArray, GameCommon.player[wChairID].bWeaveItemCount + 1, cc.p(uiSendOrOutCardNode:getPosition()))
			else
				self:addWeaveItemArray(wChairID, WeaveItemArray, GameCommon.player[wChairID].bWeaveItemCount + 1, cc.p(uiPanel_tipsCardPos:getPosition()))
			end
			
		end
		if uiSendOrOutCardNode ~= nil then
			uiSendOrOutCardNode:removeFromParent()
		end
		self:showHandCard(wChairID, 2)		
		self:showCountDown(wChairID)
		if pBuffer.cbResultCount > 1 then
			GameCommon:playAnimation(self.root, "比", wChairID)
		else
			GameCommon:playAnimation(self.root, "吃", wChairID)
		end
		self:runAction(cc.Sequence:create(cc.DelayTime:create(0.5), cc.CallFunc:create(function(sender, event) EventMgr:dispatch(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK) end)))
		
	elseif action == GameCommon.ACTION_SEND_CARD then
		local wChairID = pBuffer.wAttachUser
		local viewID = GameCommon:getViewIDByChairID(wChairID)
		local cbCardData = pBuffer.cbCardData
		local uiPanel_operation = ccui.Helper:seekWidgetByName(self.root, "Panel_operation")
		uiPanel_operation:removeAllChildren()
		local uiPanel_stacks = ccui.Helper:seekWidgetByName(self.root, "Panel_stacks")
		local uiPanel_tipsCardPos = ccui.Helper:seekWidgetByName(self.root, string.format("Panel_tipsCardPos%d", viewID))
		local uiPanel_tipsCard = ccui.Helper:seekWidgetByName(self.root, "Panel_tipsCard")
		local uiSendOrOutCardNode = uiPanel_tipsCard:getChildByName("ShowCardNode")
		if uiSendOrOutCardNode ~= nil then
			uiSendOrOutCardNode:runAction(cc.Sequence:create(cc.ScaleTo:create(0.2, 42 / uiSendOrOutCardNode:getContentSize().width, 42 / uiSendOrOutCardNode:getContentSize().height),
			cc.RemoveSelf:create()))
		end
		local uiSendOrOutCardNode = uiPanel_tipsCard:getChildByName("SendOrOutCardNode")
		if uiSendOrOutCardNode ~= nil then
			uiSendOrOutCardNode:runAction(cc.Sequence:create(cc.ScaleTo:create(0.2, 42 / uiSendOrOutCardNode:getContentSize().width, 42 / uiSendOrOutCardNode:getContentSize().height),
			cc.RemoveSelf:create(),
			cc.CallFunc:create(function(sender, event)
				
				local isOutCard = sender.isOutCard
				if not isOutCard then
					isOutCard = false
				end
				self:addDiscardCard(sender.wChairID, sender.cbCardData,isOutCard)
			end)))
		end
		if pBuffer.cbShow ~= 0 or cbCardData == GameCommon.CardData_WW then
			uiSendOrOutCardNode = GameCommon:getSendOrOutCard(cbCardData, true)
			GameCommon:playAnimation(self.root, GameLogic:SwitchToCardIndex(cbCardData), wChairID)
		else
			uiSendOrOutCardNode = GameCommon:getSendOrOutCard(0, true)
		end
		uiSendOrOutCardNode:setName("SendOrOutCardNode")
		uiSendOrOutCardNode.cbCardData = cbCardData
		uiSendOrOutCardNode.wChairID = wChairID
		uiPanel_tipsCard:addChild(uiSendOrOutCardNode)
		uiSendOrOutCardNode:setPosition(uiPanel_stacks:getPosition())
		uiSendOrOutCardNode:setScale(0)
		local time = 0.6
		if cbCardData == GameCommon.CardData_WW then
			time = 1.2
		end
		uiSendOrOutCardNode:runAction(cc.Sequence:create(
		cc.Spawn:create(cc.MoveTo:create(0.1, cc.p(uiPanel_tipsCardPos:getPosition())), cc.ScaleTo:create(0.1, 1)),
		cc.CallFunc:create(function(sender, event)
			if cbCardData == GameCommon.CardData_WW then
				uiSendOrOutCardNode:runAction(cc.Sequence:create(
				cc.DelayTime:create(1),
				cc.FadeOut:create(0.1),
				cc.RemoveSelf:create(),
				cc.CallFunc:create(function(sender, event)
					self:addOneHandCard(sender.wChairID, GameCommon.CardData_WW, cc.p(uiPanel_tipsCardPos:getPosition()))
					self:showHandCard(sender.wChairID, 2)
				end)))
			end
		end)))
		self:updateLeftCardCount(GameCommon.bLeftCardCount - 1, false, true)
		self:showCountDown(wChairID)
		self:runAction(cc.Sequence:create(cc.DelayTime:create(time), cc.CallFunc:create(function(sender, event) EventMgr:dispatch(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK) end)))
		
	elseif action == GameCommon.ACTION_OUT_CARD then
		local Button_qipai = ccui.Helper:seekWidgetByName(self.root, "Button_qipai")
		Button_qipai:setVisible(false)
		self.cotrolCardTPData = nil
		self.dragTPData = nil
		local uiPanel_outCardTips = ccui.Helper:seekWidgetByName(self.root, "Panel_outCardTips")
		uiPanel_outCardTips:removeAllChildren()
		local wChairID = pBuffer.wOutCardUser
		local viewID = GameCommon:getViewIDByChairID(wChairID)
		local cbCardData = pBuffer.cbOutCardData
		local uiPanel_operation = ccui.Helper:seekWidgetByName(self.root, "Panel_operation")
		uiPanel_operation:removeAllChildren()
		local uiPanel_tipsCardPos = ccui.Helper:seekWidgetByName(self.root, string.format("Panel_tipsCardPos%d", viewID))
		local uiPanel_tipsCard = ccui.Helper:seekWidgetByName(self.root, "Panel_tipsCard")
		local uiSendOrOutCardNode = uiPanel_tipsCard:getChildByName("ShowCardNode")
		if uiSendOrOutCardNode ~= nil then
			uiSendOrOutCardNode:runAction(cc.Sequence:create(cc.ScaleTo:create(0.2, 42 / uiSendOrOutCardNode:getContentSize().width, 42 / uiSendOrOutCardNode:getContentSize().height),
			cc.RemoveSelf:create()))
		end
		local uiSendOrOutCardNode = uiPanel_tipsCard:getChildByName("SendOrOutCardNode")
		if uiSendOrOutCardNode ~= nil then
			uiSendOrOutCardNode:runAction(cc.Sequence:create(cc.ScaleTo:create(0.2, 42 / uiSendOrOutCardNode:getContentSize().width, 42 / uiSendOrOutCardNode:getContentSize().height),
			cc.RemoveSelf:create(),
			cc.CallFunc:create(function(sender, event)
				self:addDiscardCard(sender.wChairID, sender.cbCardData,true)
			end)))
		end
		uiSendOrOutCardNode = GameCommon:getSendOrOutCard(cbCardData)
		uiSendOrOutCardNode:setName("SendOrOutCardNode")
		uiSendOrOutCardNode.cbCardData = cbCardData
		uiSendOrOutCardNode.wChairID = wChairID
		uiSendOrOutCardNode.isOutCard = true;
		uiPanel_tipsCard:addChild(uiSendOrOutCardNode)
		uiSendOrOutCardNode:setPosition(self:getPlayerheadPos(wChairID))
		uiSendOrOutCardNode:setScale(0)
		uiSendOrOutCardNode:runAction(cc.Spawn:create(cc.MoveTo:create(0.1, cc.p(uiPanel_tipsCardPos:getPosition())), cc.ScaleTo:create(0.1, 1)))
		
		if self.outData ~= nil and wChairID == GameCommon:getRoleChairID() and
		self.outData.cbCardData == cbCardData and
		GameCommon.player[self.outData.wChairID].cardStackInfo[self.outData.x] ~= nil and
		GameCommon.player[self.outData.wChairID].cardStackInfo[self.outData.x].cbCardData[self.outData.y] ~= nil and
		GameCommon.player[self.outData.wChairID].cardStackInfo[self.outData.x].cbCardData[self.outData.y].node ~= nil and
		GameCommon.player[self.outData.wChairID].cardStackInfo[self.outData.x].cbCardData[self.outData.y].data == cbCardData then
			local cbCardIndex = GameLogic:SwitchToCardIndex(self.outData.cbCardData)
			local node = GameCommon.player[self.outData.wChairID].cardStackInfo[self.outData.x].cbCardData[self.outData.y].node
			if node ~= nil then
				if node.copyNode ~= nil then
					node.copyNode:removeFromParent()
					node.copyNode = nil
				end
				node:removeFromParent()
				node = nil
			end
			GameCommon.player[self.outData.wChairID].bUserCardCount = GameCommon.player[self.outData.wChairID].bUserCardCount - 1
			GameCommon.player[self.outData.wChairID].cbCardIndex[cbCardIndex] = GameCommon.player[self.outData.wChairID].cbCardIndex[cbCardIndex] - 1
			GameCommon.player[self.outData.wChairID].cardStackInfo[self.outData.x].nCardCount = GameCommon.player[self.outData.wChairID].cardStackInfo[self.outData.x].nCardCount - 1
			if GameCommon.player[self.outData.wChairID].cardStackInfo[self.outData.x].nCardCount <= 0 then
				table.remove(GameCommon.player[self.outData.wChairID].cardStackInfo, self.outData.x) --删除整列
			else
				table.remove(GameCommon.player[self.outData.wChairID].cardStackInfo[self.outData.x].cbCardData, self.outData.y)
			end
			self:showHandCard(self.outData.wChairID, 2)
			self.outData = nil
		else
			self.outData = nil
			if pBuffer.isNoDelete ~= true and GameLogic:IsValidCard(cbCardData) then
				self:removeHandCard(wChairID, cbCardData)
				self:showHandCard(wChairID, 2)
			end
		end
		self:showCountDown(wChairID)
		GameCommon:playAnimation(self.root, GameLogic:SwitchToCardIndex(cbCardData), wChairID)
		self:runAction(cc.Sequence:create(cc.DelayTime:create(0.4), cc.CallFunc:create(function(sender, event) EventMgr:dispatch(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK) end)))
		
	elseif action == GameCommon.ACTION_WD then
		local wChairID = pBuffer.wCurrentUser
		local cbActionCard = pBuffer.cbActionCard
		local viewID = GameCommon:getViewIDByChairID(wChairID)
		local uiPanel_tipsCard = ccui.Helper:seekWidgetByName(self.root, "Panel_tipsCard")
		local uiPanel_tipsCardPos = ccui.Helper:seekWidgetByName(self.root, string.format("Panel_tipsCardPos%d", viewID))
		local count = 1
		for i = 1, 1 do
			local card = GameCommon:getSendOrOutCard(GameCommon.CardData_WW, true)
			card.cbCardData = GameCommon.CardData_WW
			card.wChairID = wChairID
			uiPanel_tipsCard:addChild(card)
			if uiPanel_tipsCardPos:getAnchorPoint().x == 1 then
				card:setPosition(uiPanel_tipsCardPos:getPositionX() + i * 80, uiPanel_tipsCardPos:getPositionY())
			else
				card:setPosition(uiPanel_tipsCardPos:getPositionX() - i * 80, uiPanel_tipsCardPos:getPositionY())
			end
			card:setScale(0)
			card:runAction(cc.ScaleTo:create(0.2, 1))
		end
		GameCommon:playAnimation(self.root, "王钓", wChairID)
		self:runAction(cc.Sequence:create(cc.DelayTime:create(0.5), cc.CallFunc:create(function(sender, event) EventMgr:dispatch(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK) end)))
		
	elseif action == GameCommon.ACTION_WC then      --王闯  
		local wChairID = pBuffer.wCurrentUser
		local cbActionCard = pBuffer.cbActionCard
		local viewID = GameCommon:getViewIDByChairID(wChairID)
		local uiPanel_tipsCard = ccui.Helper:seekWidgetByName(self.root, "Panel_tipsCard")
		local uiPanel_tipsCardPos = ccui.Helper:seekWidgetByName(self.root, string.format("Panel_tipsCardPos%d", viewID))
		local count = 1
		for i = 1, 2 do
			local card = GameCommon:getSendOrOutCard(GameCommon.CardData_WW, true)
			card.cbCardData = GameCommon.CardData_WW
			card.wChairID = wChairID
			uiPanel_tipsCard:addChild(card)
			if uiPanel_tipsCardPos:getAnchorPoint().x == 1 then
				card:setPosition(uiPanel_tipsCardPos:getPositionX() + i * 80, uiPanel_tipsCardPos:getPositionY())
			else
				card:setPosition(uiPanel_tipsCardPos:getPositionX() - i * 80, uiPanel_tipsCardPos:getPositionY())
			end
			card:setScale(0)
			card:runAction(cc.ScaleTo:create(0.2, 1))
		end
		GameCommon:playAnimation(self.root, "王闯", wChairID)
		self:runAction(cc.Sequence:create(cc.DelayTime:create(0.5), cc.CallFunc:create(function(sender, event) EventMgr:dispatch(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK) end)))
		
	elseif action == GameCommon.ACTION_3WC then
		local wChairID = pBuffer.wCurrentUser
		local cbActionCard = pBuffer.cbActionCard
		local viewID = GameCommon:getViewIDByChairID(wChairID)
		local uiPanel_tipsCard = ccui.Helper:seekWidgetByName(self.root, "Panel_tipsCard")
		local uiPanel_tipsCardPos = ccui.Helper:seekWidgetByName(self.root, string.format("Panel_tipsCardPos%d", viewID))
		local count = 1
		for i = 1, 3 do
			local card = GameCommon:getSendOrOutCard(GameCommon.CardData_WW, true)
			card.cbCardData = GameCommon.CardData_WW
			card.wChairID = wChairID
			uiPanel_tipsCard:addChild(card)
			if uiPanel_tipsCardPos:getAnchorPoint().x == 1 then
				card:setPosition(uiPanel_tipsCardPos:getPositionX() + i * 80, uiPanel_tipsCardPos:getPositionY())
			else
				card:setPosition(uiPanel_tipsCardPos:getPositionX() - i * 80, uiPanel_tipsCardPos:getPositionY())
			end
			card:setScale(0)
			card:runAction(cc.ScaleTo:create(0.2, 1))
		end
		GameCommon:playAnimation(self.root, "三王闯", wChairID)
		self:runAction(cc.Sequence:create(cc.DelayTime:create(0.5), cc.CallFunc:create(function(sender, event) EventMgr:dispatch(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK) end)))
		
	elseif action == GameCommon.ACTION_OPERATE_NOTIFY then
		if pBuffer.cbOperateCode ~= GameCommon.ACK_NULL then
			local wChairID = GameCommon:getRoleChairID()
			local uiPanel_operation = ccui.Helper:seekWidgetByName(self.root, "Panel_operation")
			uiPanel_operation:removeAllChildren()
			local oprationLayer = GameOperation:create(0, pBuffer.cbOperateCode, pBuffer.cbActionCard, GameCommon.player[wChairID].cbCardIndex, pBuffer.cbSubOperateCode)
			uiPanel_operation:addChild(oprationLayer)
		end
		self:runAction(cc.Sequence:create(cc.DelayTime:create(0), cc.CallFunc:create(function(sender, event) EventMgr:dispatch(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK) end)))
		
	elseif action == GameCommon.ACTION_FANG_CARD then
		local wChairID = pBuffer.wWinUser
		local viewID = GameCommon:getViewIDByChairID(wChairID)
		local visibleSize = cc.Director:getInstance():getVisibleSize()
		local uiPanel_tipsCard = ccui.Helper:seekWidgetByName(self.root, "Panel_tipsCard")
		local uiPanel_tipsCardPos = ccui.Helper:seekWidgetByName(self.root, string.format("Panel_tipsCardPos%d", viewID))
		local card = GameCommon:getSendOrOutCard(pBuffer.cbShengCard, true)
		card.cbCardData = pBuffer.cbShengCard
		card.wChairID = wChairID
		uiPanel_tipsCard:addChild(card)
		card:setPosition(visibleSize.width / 2, visibleSize.height * 0.8)
		card:setScale(0)
		card:runAction(cc.ScaleTo:create(0.2, 0.5))
		if GameCommon.gameConfig.FanXing.bType == 1 or GameCommon.gameConfig.FanXing.bType == 2 then
			GameCommon:playAnimation(self.root, "翻省")
		else
			GameCommon:playAnimation(self.root, "跟省")
		end
		
	elseif action == GameCommon.ACTION_SISHOU then
		local wChairID = pBuffer.wCurrentUser
		local viewID = GameCommon:getViewIDByChairID(wChairID)
		GameCommon:playAnimation(self.root, "死守", wChairID)
		self:runAction(cc.Sequence:create(cc.DelayTime:create(0.5), cc.CallFunc:create(function(sender, event) EventMgr:dispatch(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK) end)))
		GameCommon.bIsSiShou = true	
		if viewID == 1 then
			self:showTingPaiTips()
		end
		
	elseif action == GameCommon.ACTION_HU_CARD then
		local wChairID = pBuffer.wWinUser
		local uiPanel_operation = ccui.Helper:seekWidgetByName(self.root, "Panel_operation")
		uiPanel_operation:removeAllChildren()
		self:resetUserCountTimeAni()
		
		if wChairID ~= GameCommon.INVALID_CHAIR then
			local viewID = GameCommon:getViewIDByChairID(wChairID)	
			GameCommon:playAnimation(self.root, "胡", wChairID)
		else
			GameCommon:playAnimation(self.root, "黄庄")			
		end
		
	elseif action == GameCommon.ACTION_WPei then	
		local wChairID = pBuffer.wAttachUser
		local viewID = GameCommon:getViewIDByChairID(wChairID)	
		local uiPanel_tipsCard = ccui.Helper:seekWidgetByName(self.root, "Panel_tipsCard")
		local uiPanel_tipsCardPos = ccui.Helper:seekWidgetByName(self.root, string.format("Panel_tipsCardPos%d", viewID))
		local count = 1
		for i = 1, pBuffer.wWcout do
			local card = GameCommon:getSendOrOutCard(GameCommon.CardData_WW, true)
			card.cbCardData = GameCommon.CardData_WW
			card.wChairID = wChairID
			uiPanel_tipsCard:addChild(card)
			if uiPanel_tipsCardPos:getAnchorPoint().x == 1 then
				card:setPosition(uiPanel_tipsCardPos:getPositionX() + i * 80, uiPanel_tipsCardPos:getPositionY())
			else
				card:setPosition(uiPanel_tipsCardPos:getPositionX() - i * 80, uiPanel_tipsCardPos:getPositionY())
			end
			card:setScale(0)
			card:runAction(cc.ScaleTo:create(0.2, 1))
		end
		local uiWPei = nil
		if pBuffer.wMoney > 0 then
			uiWPei = ccui.TextAtlas:create(string.format(":%d", pBuffer.wMoney), "fonts/fonts_6.png", 26, 43, '0')
		else
			uiWPei = ccui.TextAtlas:create(string.format(":%d", pBuffer.wMoney), "fonts/fonts_7.png", 26, 43, '0')
		end
		uiPanel_tipsCard:addChild(uiWPei)
		uiWPei:setPosition(uiPanel_tipsCardPos:getPosition())
		self:runAction(cc.Sequence:create(cc.DelayTime:create(0.5), cc.CallFunc:create(function(sender, event) EventMgr:dispatch(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK) end)))
		
	elseif action == GameCommon.ACTION_HUANG_PEI then	
		local wChairID = pBuffer.wAttachUser
		local viewID = GameCommon:getViewIDByChairID(wChairID)	
		local uiPanel_tipsCard = ccui.Helper:seekWidgetByName(self.root, "Panel_tipsCard")
		local uiPanel_tipsCardPos = ccui.Helper:seekWidgetByName(self.root, string.format("Panel_tipsCardPos%d", viewID))
		local uiWPei = nil
		if pBuffer.wMoney > 0 then
			uiWPei = ccui.TextAtlas:create(string.format(":%d", pBuffer.wMoney), "fonts/fonts_6.png", 26, 43, '0')
		else
			uiWPei = ccui.TextAtlas:create(string.format(":%d", pBuffer.wMoney), "fonts/fonts_7.png", 26, 43, '0')
		end
		uiPanel_tipsCard:addChild(uiWPei)
		uiWPei:setPosition(uiPanel_tipsCardPos:getPosition())
		self:runAction(cc.Sequence:create(cc.DelayTime:create(0.5), cc.CallFunc:create(function(sender, event) EventMgr:dispatch(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK) end)))
		
	elseif action == GameCommon.ACTION_SHOW_CARD then
		local wChairID = pBuffer.wAttachUser
		local viewID = GameCommon:getViewIDByChairID(wChairID)
		local cbCardData = pBuffer.cbCardData
		local uiPanel_operation = ccui.Helper:seekWidgetByName(self.root, "Panel_operation")
		uiPanel_operation:removeAllChildren()
		local uiPanel_stacks = ccui.Helper:seekWidgetByName(self.root, "Panel_stacks")
		local uiPanel_tipsCardPos = ccui.Helper:seekWidgetByName(self.root, string.format("Panel_tipsCardPos%d", viewID))
		local uiPanel_tipsCard = ccui.Helper:seekWidgetByName(self.root, "Panel_tipsCard")
		local uiSendOrOutCardNode = uiPanel_tipsCard:getChildByName("SendOrOutCardNode")
		if uiSendOrOutCardNode ~= nil then
			uiSendOrOutCardNode:runAction(cc.Sequence:create(cc.ScaleTo:create(0.2, 42 / uiSendOrOutCardNode:getContentSize().width, 42 / uiSendOrOutCardNode:getContentSize().height),
			cc.RemoveSelf:create(),
			cc.CallFunc:create(function(sender, event)
				self:addDiscardCard(sender.wChairID, sender.cbCardData,true)
			end)))
		end
		if pBuffer.cbShow ~= 0 or cbCardData == GameCommon.CardData_WW then
			uiSendOrOutCardNode = GameCommon:getSendOrOutCard(cbCardData, true)
			GameCommon:playAnimation(self.root, GameLogic:SwitchToCardIndex(cbCardData), wChairID)
		else
			uiSendOrOutCardNode = GameCommon:getSendOrOutCard(0, true)
		end
		uiSendOrOutCardNode:setName("ShowCardNode")
		uiSendOrOutCardNode.cbCardData = cbCardData
		uiSendOrOutCardNode.wChairID = wChairID
		uiPanel_tipsCard:addChild(uiSendOrOutCardNode)
		uiSendOrOutCardNode:setPosition(uiPanel_stacks:getPosition())
		uiSendOrOutCardNode:setScale(0)
		uiSendOrOutCardNode:runAction(cc.Sequence:create(
		cc.Spawn:create(cc.MoveTo:create(0.1, cc.p(uiPanel_tipsCardPos:getPosition())), cc.ScaleTo:create(0.2, 1)),
		cc.DelayTime:create(2),
		cc.RemoveSelf:create()))
		
	elseif action == GameCommon.ACTION_WUFU_ADD_BASE then
		local uiPanel_operation = ccui.Helper:seekWidgetByName(self.root, "Panel_operation")
		uiPanel_operation:removeAllChildren()
		local oprationLayer = GameOperation:create(1)
		uiPanel_operation:addChild(oprationLayer)
		self:runAction(cc.Sequence:create(cc.DelayTime:create(0), cc.CallFunc:create(function(sender, event) EventMgr:dispatch(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK) end)))
		
	elseif action == GameCommon.ACTION_WUFU_ADD_BASE_VIEW then
		if pBuffer.wActionUser == GameCommon:getRoleChairID() then
			local uiPanel_operation = ccui.Helper:seekWidgetByName(self.root, "Panel_operation")
			uiPanel_operation:removeAllChildren()
		end
		self:runAction(cc.Sequence:create(cc.DelayTime:create(0), cc.CallFunc:create(function(sender, event) EventMgr:dispatch(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK) end)))
		
	elseif action == GameCommon.ACTION_DATUO_ADD_BASE then
		local uiPanel_operation = ccui.Helper:seekWidgetByName(self.root, "Panel_operation")
		uiPanel_operation:removeAllChildren()
		local oprationLayer = GameOperation:create(2)
		uiPanel_operation:addChild(oprationLayer)
		self:runAction(cc.Sequence:create(cc.DelayTime:create(0), cc.CallFunc:create(function(sender, event) EventMgr:dispatch(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK) end)))
		
	elseif action == GameCommon.ACTION_DATUO_ADD_BASE_VIEW then
		if pBuffer.wActionUser == GameCommon:getRoleChairID() then
			local uiPanel_operation = ccui.Helper:seekWidgetByName(self.root, "Panel_operation")
			uiPanel_operation:removeAllChildren()
		end
		self:runAction(cc.Sequence:create(cc.DelayTime:create(0), cc.CallFunc:create(function(sender, event) EventMgr:dispatch(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK) end)))
		
	end
	
end

function TableLayer:showCountDown(wChairID)
	self:resetUserCountTimeAni()
	
	local speed = 15
	local viewID = GameCommon:getViewIDByChairID(wChairID)
	local Panel_player = ccui.Helper:seekWidgetByName(self.root, string.format("Panel_player%d", viewID))
	local Panel_countdown = Panel_player:getChildByName("Panel_countdown")
	Panel_countdown:removeAllChildren()
	Panel_countdown:setVisible(true)
	local to = cc.ProgressFromTo:create(speed, 0, 100)
	local progressTimer = cc.ProgressTimer:create(cc.Sprite:create('cdzipai/ui/seat_clock.png'))
	progressTimer:setType(cc.PROGRESS_TIMER_TYPE_RADIAL)
	progressTimer:setReverseDirection(false)
	progressTimer:setName('progressTimer')
	Panel_countdown:addChild(progressTimer)
	local action = cc.RepeatForever:create(cc.Sequence:create(to, cc.Blink:create(0.5, 1), cc.CallFunc:create(function()
		progressTimer:setVisible(true)
	end)))
	progressTimer:runAction(action)
	
	local clock = cc.ParticleSystemQuad:create("cdzipai/particle/seat_clock.plist")
	Panel_countdown:addChild(clock)
	local size = Panel_player:getChildByName('Image_avatar'):getContentSize()
	size = {width = size.width - 1, height = size.height - 1}
	local pos_tc = cc.p(0, size.height / 2)
	local pos_tr = cc.p(size.width / 2, size.height / 2)
	local pos_dr = cc.p(size.width / 2, - size.height / 2)
	local pos_dl = cc.p(- size.width / 2, - size.height / 2)
	local pos_tl = cc.p(- size.width / 2, size.height / 2)
	clock:setPosition(pos_tc)
	clock:setRotation(90)
	local step = speed / 8
	local move_tc_tr = cc.MoveTo:create(step, pos_tr)
	local rota_td = cc.CallFunc:create(function()
		clock:setRotation(180)
	end)
	local move_tr_dr = cc.MoveTo:create(step * 2, pos_dr)
	local rota_rl = cc.CallFunc:create(function()
		clock:setRotation(270)
	end)
	local move_dr_dl = cc.MoveTo:create(step * 2, pos_dl)
	local rota_dt = cc.CallFunc:create(function()
		clock:setRotation(360)
	end)
	local move_dl_tl = cc.MoveTo:create(step * 2, pos_tl)
	local rota_lr = cc.CallFunc:create(function()
		clock:setRotation(90)
	end)
	local move_tl_tc = cc.MoveTo:create(step, pos_tc)
	local delayTime = cc.DelayTime:create(0.5)
	local action = cc.Sequence:create(move_tc_tr, rota_td, move_tr_dr, rota_rl, move_dr_dl, rota_dt, move_dl_tl, rota_lr, move_tl_tc, delayTime)
	clock:runAction(cc.RepeatForever:create(action))
end

function TableLayer:showLeftCardCount(bLeftCardCount, bLeftCardData)
	local uiPanel_showEndCard = ccui.Helper:seekWidgetByName(self.root, "Panel_showEndCard")
	local uiPanel_stacks = ccui.Helper:seekWidgetByName(self.root, "Panel_stacks")
	uiPanel_stacks:removeAllChildren()
	local Text_stacks = ccui.Helper:seekWidgetByName(self.root, "Text_stacks")
	Text_stacks:setVisible(false)
	local uiPanel_showStack = ccui.Helper:seekWidgetByName(uiPanel_showEndCard, "Panel_showStack")
	local uiListView_showStack1 = ccui.Helper:seekWidgetByName(uiPanel_showEndCard, "ListView_showStack1")
	local uiListView_showStack2 = ccui.Helper:seekWidgetByName(uiPanel_showEndCard, "ListView_showStack2")
	local cardScale = 0.4
	uiListView_showStack1:setScale(cardScale)
	uiListView_showStack2:setScale(cardScale)
	-- uiListView_showStack2:setPositionY()
	for i = 1, bLeftCardCount do
		local card = GameCommon:GetCardHand(bLeftCardData[i])
		if i <= 12 then
			uiListView_showStack1:pushBackCustomItem(card)
		else
			uiListView_showStack2:pushBackCustomItem(card)
		end
	end
	
	local Button_change = ccui.Helper:seekWidgetByName(self.root, "Button_change")
	Button_change:setVisible(false)
	local Image_tp = ccui.Helper:seekWidgetByName(self.root, "Image_tp")
	Image_tp:setVisible(false)
end

--更新牌堆
function TableLayer:updateLeftCardCount(bLeftCardCount, isEffects, isSendCardEffects)
	GameCommon.bLeftCardCount = bLeftCardCount
	local uiPanel_stack = ccui.Helper:seekWidgetByName(self.root, "Panel_stack")
	uiPanel_stack:setVisible(true)
	local uiPanel_stacks = ccui.Helper:seekWidgetByName(self.root, "Panel_stacks")
	uiPanel_stacks:removeAllChildren()
	local Text_stacks = ccui.Helper:seekWidgetByName(self.root, "Text_stacks")
	Text_stacks:setString(string.format("%d", GameCommon.bLeftCardCount))
	local showCount = 7
	if GameCommon.bLeftCardCount < showCount then
		showCount = GameCommon.bLeftCardCount
	end
	local size = uiPanel_stacks:getContentSize()
	local cardBgIndex = nil
	if CHANNEL_ID == 10 or CHANNEL_ID == 11 or CHANNEL_ID == 2 or CHANNEL_ID == 3 then
		cardBgIndex = cc.UserDefault:getInstance():getIntegerForKey(Default.UserDefault_ZiPaiCardBg, 1)
	else
		cardBgIndex = cc.UserDefault:getInstance():getIntegerForKey(Default.UserDefault_ZiPaiCardBg, 0)
	end
	
	-- local initPos = cc.p(size.width/2, size.height + 100)
	-- for i = 1, showCount do
	local img = nil
	if cardBgIndex ~= 0 then
		img = ccui.ImageView:create("cdzipai/cardpaidun.png")
	else
		img = ccui.ImageView:create("cdzipai/card/paidun.png")
	end
	-- local pos = cc.p(size.width*0.5,size.height*0.45+i*2+3)
	-- if isEffects == true then
	-- img:setPosition(initPos)
	-- img:runAction(cc.MoveTo:create(1*i*0.03,pos))
	-- else
	-- img:setPosition(pos)
	-- end
	uiPanel_stacks:addChild(img)
	-- end
	if isSendCardEffects == true and showCount >= 7 then
		local i = 8
		local img = nil
		if cardBgIndex ~= 0 then
			img = ccui.ImageView:create("cdzipai/card/paidun.png")
		else
			img = ccui.ImageView:create("cdzipai/card/paidun.png")
		end
		-- local pos = cc.p(size.width*0.5,size.height*0.45+i*2+3)
		-- img:setPosition(pos)
		uiPanel_stacks:addChild(img)
		-- img:runAction(cc.Sequence:create(cc.ScaleTo:create(0.1,0),cc.RemoveSelf:create()))
	end
end

-------------------------------------------------------吃牌组合-----------------------------------------------------
--添加吃牌组合
function TableLayer:addWeaveItemArray(wChairID, WeaveItemArray, location, pos)
	GameCommon.player[wChairID].bWeaveItemCount = GameCommon.player[wChairID].bWeaveItemCount + 1
	table.insert(GameCommon.player[wChairID].WeaveItemArray, location, WeaveItemArray)
	local viewID = GameCommon:getViewIDByChairID(wChairID)
	local node = self:setWeaveItemArray(wChairID, GameCommon.player[wChairID].bWeaveItemCount, GameCommon.player[wChairID].WeaveItemArray, location)
	if pos ~= nil then
		local srcPos = cc.p(node:getPosition())
		local uiPanel_tipsCardPos = ccui.Helper:seekWidgetByName(self.root, string.format("Panel_tipsCardPos%d", viewID))
		node:setPosition(cc.p(node:getParent():convertToNodeSpace(cc.p(uiPanel_tipsCardPos:getPosition()))))
		local speed = CardSpeedArr[CtlSpeed] or 0.3
		node:runAction(cc.MoveTo:create(speed, srcPos))
	end
end

--更新吃牌组合
function TableLayer:setWeaveItemArray(wChairID, bWeaveItemCount, WeaveItemArray, location)
	GameCommon.player[wChairID].bWeaveItemCount = bWeaveItemCount
	GameCommon.player[wChairID].WeaveItemArray = WeaveItemArray
	local viewID = GameCommon:getViewIDByChairID(wChairID)
	local uiPanel_weaveItemArray = ccui.Helper:seekWidgetByName(self.root, string.format("Panel_weaveItemArray%d", viewID))
	uiPanel_weaveItemArray:removeAllChildren()
	local uiPanel_tipsCardPos = ccui.Helper:seekWidgetByName(self.root, string.format("Panel_tipsCardPos%d", viewID))
	local pos = cc.p(uiPanel_tipsCardPos:getPosition())
	local anchorPoint = uiPanel_weaveItemArray:getAnchorPoint()
	local size = uiPanel_weaveItemArray:getContentSize()
	local bWeaveItemCount = GameCommon.player[wChairID].bWeaveItemCount
	local WeaveItemArray = GameCommon.player[wChairID].WeaveItemArray
	local cardScale = 0.55
	local cardSpace = - 10
	local cardWidth = CardSize.width * cardScale
	local cardHeight = CardSize.height * cardScale + cardSpace
	local stepX = 1
	local stepY = 1
	local maxRow = 7
	local beganX = cardWidth / 2
	if anchorPoint.x == 1 then
		beganX = size.width - cardWidth / 2
		stepX = - 1
	end
	local node = nil
	for key = 1, bWeaveItemCount do
		local var = GameCommon.player[wChairID].WeaveItemArray[key]
		if var == nil then
			assert(false, "组合数量和组合牌型不对")
		end
		
		local content = ccui.Layout:create()
		content:ignoreAnchorPointForPosition(false)
		content:setAnchorPoint(cc.p(0.5, 0.5))
		if key == location then
			node = content
		end
		GameCommon.player[wChairID].WeaveItemArray[key].node = content
		uiPanel_weaveItemArray:addChild(content)
		content:setContentSize(cc.size(cardWidth, cardHeight +(cardHeight - 6) *(var.cbCardCount - 1)))
		local beganY = content:getContentSize().height / 2
		if anchorPoint.y == 1 then
			beganY = size.height - content:getContentSize().height / 2
			stepY = - 1
		end
		content:setPosition(beganX +(cardWidth + 2) *(key - 1) * stepX, beganY + cardSpace)
		
		for k, v in pairs(var.cbCardList) do
			if GameLogic:IsValidCard(v) then
				local card = nil
				if var.cbWeaveKind == GameCommon.ACK_CHI then
					card = GameCommon:GetCardHand(v)
					if k == 3 then
						card:setColor(cc.c3b(150, 150, 150))
					end
					
				elseif var.cbWeaveKind == GameCommon.ACK_CHOUWEI then
					if k < 3 then
						card = GameCommon:GetCardHand(0)
					else
						card = GameCommon:GetCardHand(v)
					end
					
				elseif var.cbWeaveKind == GameCommon.ACK_WEI then
					if GameCommon.weiCardType == 0 then
						if k < 3 then
							card = GameCommon:GetCardHand(0)
						else
							card = GameCommon:GetCardHand(v)
						end
					else
						if GameCommon.tableConfig.nTableType == TableType_Playback or viewID == 1 or GameCommon.gameState == GameCommon.GameState_Over then
							card = GameCommon:GetCardHand(v)
							card:setColor(cc.c3b(150, 150, 150))
						else
							card = GameCommon:GetCardHand(0)
						end
					end
					
				elseif var.cbWeaveKind == GameCommon.ACK_TI then
					if GameCommon.tiCardType == 0 then
						if k < 4 then
							card = GameCommon:GetCardHand(0)
						else
							card = GameCommon:GetCardHand(v)
						end
					else
						if GameCommon.tableConfig.nTableType == TableType_Playback or viewID == 1 or GameCommon.gameState == GameCommon.GameState_Over then
							card = GameCommon:GetCardHand(v)
							card:setColor(cc.c3b(150, 150, 150))
						else
							card = GameCommon:GetCardHand(0)
						end
					end
					
				else
					card = GameCommon:GetCardHand(v)
				end
				content:addChild(card, 4 - k)
				card:setAnchorPoint(cc.p(0, 0))
				card:setScale(cardScale)
				card:setPosition(0,(k - 1) *(cardHeight - 6))
			end
		end
	end
	return node
end

-------------------------------------------------------弃牌-----------------------------------------------------
--添加弃牌
function TableLayer:addDiscardCard(wChairID, cbDiscardCard,isMask)
	if not isMask then
		isMask = false
	end
	GameCommon.player[wChairID].bDiscardCardCount = GameCommon.player[wChairID].bDiscardCardCount + 1
	GameCommon.player[wChairID].bDiscardCard[GameCommon.player[wChairID].bDiscardCardCount] = cbDiscardCard
	GameCommon.player[wChairID].bOutCardMark[GameCommon.player[wChairID].bDiscardCardCount] = isMask
	local viewID = GameCommon:getViewIDByChairID(wChairID)
	local node = self:setDiscardCard(wChairID, GameCommon.player[wChairID].bDiscardCardCount, GameCommon.player[wChairID].bDiscardCard,GameCommon.player[wChairID].bOutCardMark)
	local pos = cc.p(node:getPosition())
	local uiPanel_tipsCardPos = ccui.Helper:seekWidgetByName(self.root, string.format("Panel_tipsCardPos%d", viewID))
	node:setPosition(cc.p(node:getParent():convertToNodeSpace(cc.p(uiPanel_tipsCardPos:getPosition()))))
	node:runAction(cc.MoveTo:create(0.2, pos))
end
--删除弃牌
function TableLayer:deletingDiscardCard(wChairID, deleting)	
	for i = deleting, GameCommon.player[wChairID].bDiscardCardCount do	
		GameCommon.player[wChairID].bDiscardCard[i] = GameCommon.player[wChairID].bDiscardCard[i + 1]	
		GameCommon.player[wChairID].bOutCardMark[i] = GameCommon.player[wChairID].bOutCardMark[i + 1]
	end
	local viewID = GameCommon:getViewIDByChairID(wChairID)
	self:setDiscardCard(wChairID, GameCommon.player[wChairID].bDiscardCardCount, GameCommon.player[wChairID].bDiscardCard,GameCommon.player[wChairID].bOutCardMark)			
end
--添加多个弃牌
function TableLayer:setDiscardCard(wChairID, bDiscardCardCount, bDiscardCard,bOutCardMark)

	GameCommon.player[wChairID].bDiscardCardCount = bDiscardCardCount
	GameCommon.player[wChairID].bDiscardCard = bDiscardCard
	bOutCardMark = bOutCardMark or {}
	GameCommon.player[wChairID].bOutCardMark = bOutCardMark
	
	local isThreeRoom = false
	local viewID = GameCommon:getViewIDByChairID(wChairID)
	if viewID == 1 and GameCommon.gameConfig.bPlayerCount <= 3 then
		viewID = 4
		isThreeRoom = true
	end
	local uiPanel_discardCard = ccui.Helper:seekWidgetByName(self.root, string.format("Panel_discardCard%d", viewID))
	-- if isThreeRoom then
	--     local parentWidth = uiPanel_discardCard:getParent():getContentSize().width
	--     uiPanel_discardCard:setPositionX(parentWidth * 0.99) 
	-- end
	uiPanel_discardCard:removeAllChildren()
	local anchorPoint = uiPanel_discardCard:getAnchorPoint()
	local size = uiPanel_discardCard:getContentSize()
	local bDiscardCardCount = GameCommon.player[wChairID].bDiscardCardCount
	local bDiscardCard = GameCommon.player[wChairID].bDiscardCard
	local cardScale = 0.5
	local cardWidth = CardSize.width * cardScale
	local cardHeight = CardSize.height * cardScale
	local stepX = cardWidth + 2
	local stepY = cardHeight - 15
	local maxRow = 5
	if GameCommon.gameConfig.bPlayerCount >= 4 then
		maxRow = 10
	end
	local beganX = cardWidth / 2
	if anchorPoint.x == 1 then
		beganX = size.width - cardWidth / 2
		stepX = - stepX
	end
	local beganY = cardHeight / 2
	if anchorPoint.y == 1 then
		beganY = size.height - cardHeight / 2
		stepY = - stepY
	end
	local lastNode = nil
	for i = 1, bDiscardCardCount do
		local card = GameCommon:GetCardHand(bDiscardCard[i])
		local isMask = bOutCardMark[i]
		if isMask then
			card:setColor(cc.c3b(150, 150, 150))
		end
		lastNode = card
		uiPanel_discardCard:addChild(card)
		card:setLocalZOrder(4 - i)
		card:setScale(cardScale)
		
		local row = i % maxRow
		if row == 0 then
			row = maxRow
		end
		local index = math.ceil(i / maxRow)
		card:setPosition(beganX + stepX *(row - 1), beganY + stepY *(index - 1))
	end
	return lastNode
end

-------------------------------------------------------手牌-----------------------------------------------------
--设置手牌
function TableLayer:setHandCard(wChairID, bUserCardCount, cbCardIndex, maxHanCardRow, cbCardCoutWW, isReconnect)
	GameCommon.player[wChairID].bUserCardCount = bUserCardCount
	GameCommon.player[wChairID].maxHanCardRow = maxHanCardRow
	GameCommon.player[wChairID].cbCardIndex = cbCardIndex
	GameCommon.player[wChairID].cbCardCoutWW = 0
	
	--设置排序
	local visibleSize = cc.Director:getInstance():getVisibleSize()
	local uiPanel_stacks = ccui.Helper:seekWidgetByName(self.root, "Panel_stacks")
	GameCommon.player[wChairID].cardStackInfo = GameLogic:sortHandCard(clone(cbCardIndex), maxHanCardRow, cc.p(uiPanel_stacks:getPosition()), 1)
	if GameCommon.player[wChairID].cbCardCoutWW ~= nil then
		for i = 1, cbCardCoutWW do
			self:addOneHandCard(wChairID, 33, cc.p(uiPanel_stacks:getPosition()))
		end
	end
	
	--重连恢复手牌拖动位置(屏蔽断线重连手牌恢复功能，注销这里即可)
	if GameCommon.tableConfig.nTableType ~= TableType_Playback then
		if isReconnect and GameCommon.reconnectCardInfo[wChairID] then
			local srcInfo = GameCommon.player[wChairID].cardStackInfo
			local cacheInfo = GameCommon.reconnectCardInfo[wChairID]
			local cache = self:reconnetCardInfoReset(srcInfo, cacheInfo)
			GameCommon.player[wChairID].cardStackInfo = cache
		else
			GameCommon.reconnectCardInfo = {}
		end
	end
end

--添加任意手牌
function TableLayer:addOneHandCard(wChairID, cbCard, pos)
	GameCommon.player[wChairID].bUserCardCount = GameCommon.player[wChairID].bUserCardCount + 1
	if GameCommon.player[wChairID].cbCardIndex == nil then
		return
	end
	if cbCard == GameCommon.CardData_WW then
		GameCommon.player[wChairID].cbCardCoutWW = GameCommon.player[wChairID].cbCardCoutWW + 1
	end
	for key, var in pairs(GameCommon.player[wChairID].cardStackInfo) do
		if var.nCardCount < 3 then
			local _cardData = {}
			_cardData.data = cbCard
			_cardData.pt = pos
			
			table.insert(var.cbCardData, #var.cbCardData + 1, _cardData)
			var.nCardCount = var.nCardCount + 1
			return GameCommon.player[wChairID].cardStackInfo
		end
	end
	
	local cardinfo = {}
	cardinfo.nCardCount = 1
	cardinfo.cbCardData = {}
	
	local _cardData = {}
	_cardData.data = cbCard
	_cardData.pt = pos
	table.insert(cardinfo.cbCardData, #cardinfo.cbCardData + 1, _cardData)
	
	table.insert(GameCommon.player[wChairID].cardStackInfo, #GameCommon.player[wChairID].cardStackInfo + 1, cardinfo)
	return GameCommon.player[wChairID].cardStackInfo
end

--删除手牌
function TableLayer:removeHandCard(wChairID, cbCardData)
	local cbCardIndex = GameLogic:SwitchToCardIndex(cbCardData)
	GameCommon.player[wChairID].bUserCardCount = GameCommon.player[wChairID].bUserCardCount - 1
	local viewID = GameCommon:getViewIDByChairID(wChairID)
	local uiPanel_card = ccui.Helper:seekWidgetByName(self.root, "Panel_card")
	local uiPanel_handCard = ccui.Helper:seekWidgetByName(uiPanel_card, string.format("Panel_handCard%d", viewID))
	if viewID == 1 and(GameCommon.gameConfig.bPlayerCount <= 3 or(GameCommon.gameConfig.bPlayerCount == 4 and StaticData.Games[GameCommon.tableConfig.wKindID].isZuoXing4 == 1) or GameCommon.tableConfig.nTableType ~= TableType_Playback) then
		uiPanel_handCard = ccui.Helper:seekWidgetByName(uiPanel_card, "Panel_handCardRole")
	end
	local pos = uiPanel_handCard:convertToWorldSpace(cc.p(uiPanel_handCard:getContentSize().width / 2, uiPanel_handCard:getContentSize().height / 2))
	if GameCommon.player[wChairID].cbCardIndex == nil then
		return pos
	end
	if self.copyHandCard ~= nil then
		self.copyHandCard.targetNode:setColor(cc.c3b(255, 255, 255))
		self.copyHandCard:removeFromParent()
		self.copyHandCard = nil
	end
	if cbCardData ~= GameCommon.CardData_WW then
		GameCommon.player[wChairID].cbCardIndex[cbCardIndex] = GameCommon.player[wChairID].cbCardIndex[cbCardIndex] - 1
		if GameCommon.player[wChairID].cbCardIndex[cbCardIndex] < 0 then
			GameCommon.player[wChairID].cbCardIndex[cbCardIndex] = 0
		end
	else
		GameCommon.player[wChairID].cbCardCoutWW = GameCommon.player[wChairID].cbCardCoutWW - 1
		if GameCommon.player[wChairID].cbCardCoutWW < 0 then
			GameCommon.player[wChairID].cbCardCoutWW = 0
		end
	end
	if GameCommon.player[wChairID].cardStackInfo ~= nil then
		local isDel = false
		for key, var in pairs(GameCommon.player[wChairID].cardStackInfo) do
			for k, v in pairs(var.cbCardData) do
				if v.data == cbCardData then
					--                    pos = v.pt
					pos = v.node:getParent():convertToWorldSpace(cc.p(v.node:getPosition()))
					if v.node ~= nil then
						v.node:removeFromParent()
						v.node = nil
					end
					GameCommon.player[wChairID].cardStackInfo[key].nCardCount = GameCommon.player[wChairID].cardStackInfo[key].nCardCount - 1
					if GameCommon.player[wChairID].cardStackInfo[key].nCardCount <= 0 then
						table.remove(GameCommon.player[wChairID].cardStackInfo, key) --删除整列
					else
						table.remove(GameCommon.player[wChairID].cardStackInfo[key].cbCardData, k)
					end
					isDel = true
					break
				end
			end
			if isDel == true then
				break
			end
		end
	end
	return pos
end

--更新手牌
function TableLayer:showHandCard(wChairID, effectsType, isShowEndCard)
	print('=====>>>>>>>>>',wChairID, effectsType, isShowEndCard)
	if GameCommon.player[wChairID].cbCardIndex == nil then
		return
	end
	if GameCommon.tableConfig.nTableType ~= TableType_Playback then
		GameCommon.reconnectCardInfo[wChairID] = GameCommon.player[wChairID].cardStackInfo
	end
	
	local isCanMove = false
	local viewID = GameCommon:getViewIDByChairID(wChairID)
	local uiImage_line = ccui.Helper:seekWidgetByName(self.root, "Image_line")
	uiImage_line:setVisible(true)
	local lineY = uiImage_line:getPositionY()
	local uiPanel_handCard = nil
	local cardScale = 0.4
	if isShowEndCard == true then
		cardScale = 0.4
		local uiPanel_card = ccui.Helper:seekWidgetByName(self.root, "Panel_card")
		uiPanel_handCard = ccui.Helper:seekWidgetByName(uiPanel_card, "Panel_handCard")
		uiPanel_handCard:removeAllChildren()
		local uiPanel_showEndCard = ccui.Helper:seekWidgetByName(self.root, "Panel_showEndCard")
		uiPanel_showEndCard:setVisible(true)
		uiPanel_handCard = ccui.Helper:seekWidgetByName(uiPanel_showEndCard, string.format("Panel_handCard%d", viewID))
		if viewID == 1 and(GameCommon.gameConfig.bPlayerCount <= 3 or(GameCommon.gameConfig.bPlayerCount == 4 and StaticData.Games[GameCommon.tableConfig.wKindID].isZuoXing4 == 1)) then
			uiPanel_handCard = ccui.Helper:seekWidgetByName(uiPanel_showEndCard, "Panel_handCardRole")
			cardScale = 1
		end
	else
		local uiPanel_card = ccui.Helper:seekWidgetByName(self.root, "Panel_card")
		uiPanel_handCard = ccui.Helper:seekWidgetByName(uiPanel_card, string.format("Panel_handCard%d", viewID))
		if viewID == 1 and(GameCommon.gameConfig.bPlayerCount <= 3 or(GameCommon.gameConfig.bPlayerCount == 4 and StaticData.Games[GameCommon.tableConfig.wKindID].isZuoXing4 == 1) or GameCommon.tableConfig.nTableType ~= TableType_Playback) then
			cardScale = 1.1
			isCanMove = true
			if uiPanel_handCard then
				uiPanel_handCard:removeAllChildren()
			end
			uiPanel_handCard = ccui.Helper:seekWidgetByName(uiPanel_card, "Panel_handCardRole")
		end
	end
	uiPanel_handCard:removeAllChildren()
	local uiPanel_copyHandCard = ccui.Helper:seekWidgetByName(self.root, "Panel_copyHandCard")
	uiPanel_copyHandCard:removeAllChildren()
	self.copyHandCard = nil
	local uiPanel_stacks = ccui.Helper:seekWidgetByName(self.root, "Panel_stacks")
	local pos = cc.p(uiPanel_handCard:getPosition())
	local cardStackInfo = GameCommon.player[wChairID].cardStackInfo
	local maxHanCardRow = GameCommon.player[wChairID].maxHanCardRow
	local nCardStackCount = #cardStackInfo
	local size = uiPanel_handCard:getContentSize()
	local visibleSize = cc.Director:getInstance():getVisibleSize()
	
	local anchorPoint = uiPanel_handCard:getAnchorPoint()
	local index = 0
	local time = 0.2
	local cardWidth = CardSize.width * cardScale
	local cardHeight = CardSize.height * cardScale
	local stepX = cardWidth
	local stepY = cardHeight * 0.7
	local beganX =(size.width - nCardStackCount * stepX) / 2
	if anchorPoint.x == 0 then
		beganX = 0
	elseif anchorPoint.x == 1 then
		beganX = size.width - nCardStackCount * stepX
	end
	for key, var in pairs(cardStackInfo) do
		for k, v in pairs(var.cbCardData) do
			local card = GameCommon:GetCardHand(v.data)
			uiPanel_handCard:addChild(card)
			v.node = card
			card:setLocalZOrder(4 - k)
			if effectsType == 1 then--发牌特效
				index = index + 1
				--                card:setPosition(uiPanel_handCard:convertToNodeSpace(cc.p(uiPanel_stacks:getParent():convertToWorldSpace(cc.p(uiPanel_stacks:getPosition())))))
				--                v.pt = cc.p(beganX + key*stepX - cardWidth/2, stepY*(k-1) + cardHeight/2)
				--                card:setScale(0)
				--                card:runAction(cc.Sequence:create(cc.DelayTime:create(1*index*0.03),cc.Spawn:create(cc.ScaleTo:create(time,cardScale),cc.MoveTo:create(time,v.pt))))
				if anchorPoint.x == 0.5 then
					card:setPosition(uiPanel_handCard:getContentSize().width / 2, stepY *(k - 1) + cardHeight / 2)
				elseif anchorPoint.x == 0 then
					card:setPosition(beganX + 1 * stepX - cardWidth / 2, stepY *(k - 1) + cardHeight / 2)
				else
					card:setPosition(beganX + nCardStackCount * stepX - cardWidth / 2, stepY *(k - 1) + cardHeight / 2)
				end
				v.pt = cc.p(beganX + key * stepX - cardWidth / 2, stepY *(k - 1) + cardHeight / 2)
				card:setScale(cardScale)
				card:runAction(cc.MoveTo:create(math.abs(v.pt.x - card:getPositionX()) * time * 0.01, v.pt))
			elseif effectsType == 2 then
				index = index + 1
				card:setPosition(v.pt)
				v.pt = cc.p(beganX + key * stepX - cardWidth / 2, stepY *(k - 1) + cardHeight / 2)
				card:setScale(cardScale)
				card:runAction(cc.MoveTo:create(time, v.pt))

				--听牌角标
				self:setTPCardFlag(card, v.data)
			else
				card:setPosition(v.pt)
				v.pt = cc.p(beganX + key * stepX - cardWidth / 2, stepY *(k - 1) + cardHeight / 2)
				card:setPosition(v.pt)
				card:setScale(cardScale)
			end
			if isCanMove == true then --主角位置才能拖动手牌
				self:setUnMovedCardGrey(var, v)
				card:setTouchEnabled(true)
				local preRow = 0
				card:addTouchEventListener(function(sender, event)
					if event == ccui.TouchEventType.began then
						-- self:setTPDataToCotrol(v.data)
						-- uiImage_line:setVisible(true)
						local pos = cc.p(uiPanel_handCard:convertToNodeSpace(self.locationPos))
						local posX = pos.x - beganX
						local row = math.floor(posX / stepX)
						if posX % stepX > 0 then
							row = row + 1
						end
						--判断是否可以拖动
						local isCan = true
						if v.data ~= GameCommon.CardData_WW and GameCommon.player[wChairID].cardStackInfo[row] and GameCommon.player[wChairID].cardStackInfo[row].nCardCount >= 3 then
							isCan = false
							local value = nil
							for key, var in pairs(GameCommon.player[wChairID].cardStackInfo[row].cbCardData) do
								if value ~= nil and value ~= var.data then
									isCan = true
									break
								end
								value = var.data
							end
						end
						if isCan == false then
							return
						end

						---[[ 听牌提示：client and server two version
						if IsUseNewTP then
							self:showDragTPTips(v.data)
						else
							if type(self.cotrolCardTPData) == 'table' then
								if self.cotrolCardTPData[v.data] then
									self:setOutCardTPTips(self.cotrolCardTPData[v.data])
								else
									-- NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_C_OUT_CARD_TING_CARD, "b", v.data)

									local cbCardIndex = GameCommon.player[wChairID].cbCardIndex
									if cbCardIndex then
										local tempCardIdx = clone(cbCardIndex)
										local index = GameLogic:SwitchToCardIndex(v.data);
										tempCardIdx[index] = tempCardIdx[index] - 1
										-- local data = {
										-- 	wChairID = wChairID, 
										-- 	cbCardIndex = tempCardIdx, 
										-- 	cbCardData = v.data
										-- }
										self:checkTPShowTips(wChairID, tempCardIdx, v.data)
									end
								end
							end
						end
						--]]
						
						preRow = row
						uiPanel_copyHandCard:removeAllChildren()
						self.copyHandCard = nil
						self.copyHandCard = GameCommon:getSendOrOutCard(v.data)
						self.copyHandCard.targetNode = card
						
						--170
						-- card:setColor(cc.c3b(150,150,150))
						card:setVisible(false)
						uiPanel_copyHandCard:addChild(self.copyHandCard)
						self.copyHandCard:setPosition(self.locationPos)
					elseif event == ccui.TouchEventType.moved then
						if self.copyHandCard ~= nil then
							self.copyHandCard:setPosition(self.locationPos)
						end
					else
						---[[ 听牌提示：client and server two version
						if IsUseNewTP then
							self:hideDragTPTips(v.data)
						else
							if type(self.cotrolCardTPData) == 'table' then
								self:setOutCardTPTips(self.normolTPData)
							end
						end
						--]]

						-- self:setTPDataToCotrol()
						-- uiImage_line:setVisible(false)
						if self.copyHandCard ~= nil then
							local beganPos = cc.p(uiPanel_handCard:convertToNodeSpace(self.locationPos))
							local endPos = v.pt--cc.p(card:getPosition())
							uiPanel_copyHandCard:removeAllChildren()
							self.copyHandCard = nil
							-- card:setColor(cc.c3b(255,255,255))
							if v.data ~= GameCommon.CardData_WW and GameCommon.waitOutCardUser == GameCommon:getRoleChairID() and self.locationPos.y > lineY then
								self.outData = {wChairID = wChairID, cbCardData = v.data, x = key, y = k}
								EventMgr:dispatch(EventType.EVENT_TYPE_OPERATIONAL_OUT_CARD, self.outData)
								return
							end
							if GameCommon.waitOutCardUser ~= GameCommon:getRoleChairID() and self.locationPos.y > lineY then
								self:ignoreCardMoved(card, beganPos, endPos)
								return
							end
							
							local pos = cc.p(uiPanel_handCard:convertToNodeSpace(self.locationPos))
							local posX = pos.x - beganX
							local row = math.floor(posX / stepX)
							if posX % stepX > 0 then
								row = row + 1
							end
							if row <= 0 then   --插入最左边
								if nCardStackCount < maxHanCardRow or GameCommon.player[wChairID].cardStackInfo[preRow].nCardCount <= 1 then
									card:removeFromParent()
									v.node = nil
									GameCommon.player[wChairID].cardStackInfo[key].nCardCount = GameCommon.player[wChairID].cardStackInfo[key].nCardCount - 1
									if GameCommon.player[wChairID].cardStackInfo[key].nCardCount <= 0 then
										table.remove(GameCommon.player[wChairID].cardStackInfo, key) --删除整列
									else
										table.remove(GameCommon.player[wChairID].cardStackInfo[key].cbCardData, k)
									end
									
									local cardinfo = {}
									cardinfo.nCardCount = 1
									cardinfo.cbCardData = {}
									
									local _cardData = {}
									_cardData.data = v.data
									_cardData.pt = pos
									table.insert(cardinfo.cbCardData, 1, _cardData)
									table.insert(GameCommon.player[wChairID].cardStackInfo, 1, cardinfo)
									
									self:showHandCard(wChairID, 2)
								else
									self:ignoreCardMoved(card, beganPos, endPos)
								end
							elseif row > nCardStackCount then   --插入最右边
								if nCardStackCount < maxHanCardRow or GameCommon.player[wChairID].cardStackInfo[preRow].nCardCount <= 1 then
									card:removeFromParent()
									v.node = nil
									GameCommon.player[wChairID].cardStackInfo[key].nCardCount = GameCommon.player[wChairID].cardStackInfo[key].nCardCount - 1
									if GameCommon.player[wChairID].cardStackInfo[key].nCardCount <= 0 then
										table.remove(GameCommon.player[wChairID].cardStackInfo, key) --删除整列
									else
										table.remove(GameCommon.player[wChairID].cardStackInfo[key].cbCardData, k)
									end
									
									local cardinfo = {}
									cardinfo.nCardCount = 1
									cardinfo.cbCardData = {}
									
									local _cardData = {}
									_cardData.data = v.data
									_cardData.pt = pos
									table.insert(cardinfo.cbCardData, 1, _cardData)
									table.insert(GameCommon.player[wChairID].cardStackInfo, #GameCommon.player[wChairID].cardStackInfo + 1, cardinfo)
									
									self:showHandCard(wChairID, 2)
								else
									self:ignoreCardMoved(card, beganPos, endPos)
								end
							else
								if(GameCommon.player[wChairID].cardStackInfo[row].nCardCount < 4) and self:isCardInsert(wChairID, row) then --or
									-- (row == key and k < var.nCardCount and GameCommon.player[wChairID].cardStackInfo[row].nCardCount < 4) then
									card:removeFromParent()
									v.node = nil
									local _cardData = {}
									_cardData.data = v.data
									_cardData.pt = pos
									local colNum = #GameCommon.player[wChairID].cardStackInfo[row].cbCardData
									local index = self:getMovedCardIndex(pos, colNum)
									if row == key and index <= colNum then
										if index >= k then
											index = index + 1
										else
											k = k + 1
										end
									end
									GameCommon.player[wChairID].cardStackInfo[row].nCardCount = GameCommon.player[wChairID].cardStackInfo[row].nCardCount + 1
									table.insert(GameCommon.player[wChairID].cardStackInfo[row].cbCardData, index, _cardData)
									
									GameCommon.player[wChairID].cardStackInfo[key].nCardCount = GameCommon.player[wChairID].cardStackInfo[key].nCardCount - 1
									if GameCommon.player[wChairID].cardStackInfo[key].nCardCount <= 0 then
										table.remove(GameCommon.player[wChairID].cardStackInfo, key) --删除整列
									else
										table.remove(GameCommon.player[wChairID].cardStackInfo[key].cbCardData, k)
									end
									self:showHandCard(wChairID, 2)
								else
									self:ignoreCardMoved(card, beganPos, endPos)
								end
							end
						end
					end
				end)
			end
		end
	end
end

function TableLayer:isCardInsert(wChairID, row)
	local isCan = true
	if GameCommon.player[wChairID].cardStackInfo[row].nCardCount >= 3 then
		isCan = false
		local value = nil
		for key, var in pairs(GameCommon.player[wChairID].cardStackInfo[row].cbCardData) do
			if value ~= nil and value ~= var.data then
				isCan = true
				break
			end
			value = var.data
		end
	end
	return isCan
end

function TableLayer:ignoreCardMoved(card, beganPos, endPos)
	card:setVisible(true)
	card:setPosition(beganPos)
	card:stopAllActions()
	card:runAction(cc.MoveTo:create(CardSendSpeed, endPos))
end

function TableLayer:getMovedCardIndex(curPos, colNum)
	local uiPanel_card = ccui.Helper:seekWidgetByName(self.root, "Panel_card")
	local uiPanel_handCard = ccui.Helper:seekWidgetByName(uiPanel_card, "Panel_handCardRole")
	local offsetH = uiPanel_handCard:getPositionY()
	local cardScale = 1
	local cardHeight = CardSize.height * cardScale
	local stepY = cardHeight * 0.7
	for i = 1, colNum do
		local splitY = offsetH + cardHeight +(i - 1) * stepY
		if curPos.y < splitY then
			return i
		end
	end
	return colNum + 1
end

function TableLayer:initUI()
	local visibleSize = cc.Director:getInstance():getVisibleSize()
	require("common.Common"):playEffect("game/pipeidonghua.mp3")
	local wKindID = GameCommon.tableConfig.wKindID
	--水印
	local uiImage_watermark = ccui.Helper:seekWidgetByName(self.root,"Image_watermark")
	uiImage_watermark:loadTexture(StaticData.Games[wKindID].icon)	
	uiImage_watermark:ignoreContentAdaptWithSize(true)
	--string.format("puke/card/card0/puke_%d_%d.png",color,value)
	if wKindID ~= 38 and wKindID ~= 60  then 
		local sCircle = cc.Sprite:create(string.format("game/cdphz/%d/icon3.png",wKindID))	
		uiImage_watermark:addChild(sCircle)
		sCircle:setPosition(-10,-30)
		local sCircle = cc.Sprite:create(string.format("game/cdphz/%d/icon4.png",wKindID))	
		uiImage_watermark:addChild(sCircle)
		sCircle:setPosition(240,-30)
	else 
		local sCircle = cc.Sprite:create(string.format("game/cdphz/%d/icon3.png",wKindID))	
		uiImage_watermark:addChild(sCircle)
		sCircle:setPosition(100,-30)
	end 

	-- local uiText_desc = ccui.Helper:seekWidgetByName(self.root,"Text_desc")
	-- uiText_desc:setString("")
	-- local uiText_time = ccui.Helper:seekWidgetByName(self.root,"Text_time")
	-- uiText_time:runAction(cc.RepeatForever:create(cc.Sequence:create(cc.CallFunc:create(function(sender,event) 
	--     local date = os.date("*t",os.time())
	--     uiText_time:setString(string.format("%02d:%02d:%02d",date.hour,date.min,date.sec))
	-- end),cc.DelayTime:create(1))))
	local Text_node = GameCommon:seekWidgetByNameEx(self.root, "Text_node")
	Text_node:setString("")
	
	--卡牌层
	local uiImage_line = ccui.Helper:seekWidgetByName(self.root, "Image_line")
	uiImage_line:setVisible(false)
	local uiPanel_stack = ccui.Helper:seekWidgetByName(self.root, "Panel_stack")
	uiPanel_stack:setVisible(false)
	
	--动画层
	self:resetUserCountTimeAni()
	
	--用户层
	for i = 1, 4 do
		local uiPanel_player = ccui.Helper:seekWidgetByName(self.root, string.format("Panel_player%d", i))
		uiPanel_player:setVisible(false)
		local uiImage_avatarFrame = ccui.Helper:seekWidgetByName(uiPanel_player, "Image_avatarFrame")
		local uiImage_avatar = ccui.Helper:seekWidgetByName(uiPanel_player, "Image_avatar")
		uiImage_avatar:loadTexture("cdzipai/ui/default.png")
		
		uiImage_avatarFrame:setTouchEnabled(true)
		uiImage_avatarFrame:addTouchEventListener(function(sender, event)
			if event == ccui.TouchEventType.ended then
				for key, var in pairs(GameCommon.player) do
					if GameCommon:getViewIDByChairID(var.wChairID, true) == i then
						NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER, NetMsgId.REQ_GR_USER_PLAYER_INFO, "d", var.dwUserID)
						break
					end
				end
			end
		end)
		
		local uiImage_laba = ccui.Helper:seekWidgetByName(uiPanel_player, "Image_laba")
		uiImage_laba:setVisible(false)
		local uiImage_banker = ccui.Helper:seekWidgetByName(uiPanel_player, "Image_banker")
		uiImage_banker:setVisible(false)
		local uiText_name = ccui.Helper:seekWidgetByName(uiPanel_player, "Text_name")
		uiText_name:setString("")
		local uiText_huXi = ccui.Helper:seekWidgetByName(uiPanel_player, "Text_huXi")
		uiText_huXi:setString("")
		local uiText_score = ccui.Helper:seekWidgetByName(uiPanel_player, "Text_score")
		uiText_score:setString("")
		local uiImage_ready = ccui.Helper:seekWidgetByName(uiPanel_player, "Image_ready")
		uiImage_ready:setVisible(false)
		local uiImage_chat = ccui.Helper:seekWidgetByName(uiPanel_player, "Image_chat")
		uiImage_chat:setVisible(false)
	end
	
	--UI层
	local uiButton_menu = ccui.Helper:seekWidgetByName(self.root, "Button_menu")
	local uiPanel_function = ccui.Helper:seekWidgetByName(self.root, "Panel_function")
	uiPanel_function:setEnabled(false)
	Common:addTouchEventListener(uiButton_menu, function()
		uiPanel_function:stopAllActions()
		uiPanel_function:runAction(cc.Sequence:create(cc.MoveTo:create(0.2, cc.p(- 99, 0)), cc.CallFunc:create(function(sender, event)
			uiPanel_function:setEnabled(true)
		end)))
		uiButton_menu:stopAllActions()
		uiButton_menu:runAction(cc.ScaleTo:create(0.2, 0))
	end)
	uiPanel_function:addTouchEventListener(function(sender, event)
		if event == ccui.TouchEventType.ended then
			uiPanel_function:stopAllActions()
			uiPanel_function:runAction(cc.Sequence:create(cc.CallFunc:create(function(sender, event)
				uiPanel_function:setEnabled(false)
			end), cc.MoveTo:create(0.2, cc.p(0, 0))))
			uiButton_menu:stopAllActions()
			uiButton_menu:runAction(cc.ScaleTo:create(0.2, 1))
		end
	end)
	-- local uiPanel_bg = ccui.Helper:seekWidgetByName(self.root,"Panel_bg")
	Common:addTouchEventListener(ccui.Helper:seekWidgetByName(self.root, "Button_skin"), function()
		local UserDefault_ZiPaipaizhuo = nil
		if CHANNEL_ID == 10 or CHANNEL_ID == 11 then
			UserDefault_ZiPaipaizhuo = cc.UserDefault:getInstance():getIntegerForKey(Default.UserDefault_ZiPaipaizhuo, 1)
		else
			UserDefault_ZiPaipaizhuo = cc.UserDefault:getInstance():getIntegerForKey(Default.UserDefault_ZiPaipaizhuo, 0)
		end
		UserDefault_ZiPaipaizhuo = UserDefault_ZiPaipaizhuo + 1
		if UserDefault_ZiPaipaizhuo < 0 or UserDefault_ZiPaipaizhuo > 2 then
			UserDefault_ZiPaipaizhuo = 0
		end
		cc.UserDefault:getInstance():setIntegerForKey(Default.UserDefault_ZiPaipaizhuo, UserDefault_ZiPaipaizhuo)
		-- uiPanel_bg:removeAllChildren()
		-- if CHANNEL_ID == 10 or CHANNEL_ID == 11 then 
		--     uiPanel_bg:addChild(ccui.ImageView:create(string.format("achannel/%d/paohuzi_table_bg%d.jpg",CHANNEL_ID,UserDefault_ZiPaipaizhuo)))
		-- else
		--     uiPanel_bg:addChild(ccui.ImageView:create(string.format("game/paohuzi_table_bg%d.jpg",UserDefault_ZiPaipaizhuo)))
		-- end
	end)
	local UserDefault_ZiPaipaizhuo = nil
	if CHANNEL_ID == 10 or CHANNEL_ID == 11 then
		UserDefault_ZiPaipaizhuo = cc.UserDefault:getInstance():getIntegerForKey(Default.UserDefault_ZiPaipaizhuo, 1)
	else
		UserDefault_ZiPaipaizhuo = cc.UserDefault:getInstance():getIntegerForKey(Default.UserDefault_ZiPaipaizhuo, 0)
	end
	if UserDefault_ZiPaipaizhuo < 0 or UserDefault_ZiPaipaizhuo > 2 then
		UserDefault_ZiPaipaizhuo = 0
		cc.UserDefault:getInstance():setIntegerForKey(Default.UserDefault_ZiPaipaizhuo, UserDefault_ZiPaipaizhuo)
	end
	--if UserDefault_ZiPaipaizhuo ~= 0 then
	--     uiPanel_bg:removeAllChildren()
	-- if CHANNEL_ID == 10 or CHANNEL_ID == 11 then 
	--     uiPanel_bg:addChild(ccui.ImageView:create(string.format("achannel/%d/paohuzi_table_bg%d.jpg",CHANNEL_ID,UserDefault_ZiPaipaizhuo)))
	-- else
	--     uiPanel_bg:addChild(ccui.ImageView:create(string.format("game/paohuzi_table_bg%d.jpg",UserDefault_ZiPaipaizhuo)))
	-- end
	--end
	Common:addTouchEventListener(ccui.Helper:seekWidgetByName(self.root, "Button_font"), function()
		local UserDefault_ZiPaiCard = nil
		if CHANNEL_ID == 9 or CHANNEL_ID == 8 then
			UserDefault_ZiPaiCard = cc.UserDefault:getInstance():getIntegerForKey(Default.UserDefault_ZiPaiCard, 1)
		else
			UserDefault_ZiPaiCard = cc.UserDefault:getInstance():getIntegerForKey(Default.UserDefault_ZiPaiCard, 0)
		end
		UserDefault_ZiPaiCard = UserDefault_ZiPaiCard + 1
		if UserDefault_ZiPaiCard < 0 or UserDefault_ZiPaiCard > 3 then
			UserDefault_ZiPaiCard = 0
		end
		cc.UserDefault:getInstance():setIntegerForKey(Default.UserDefault_ZiPaiCard, UserDefault_ZiPaiCard)
		self:showHandCard(GameCommon:getRoleChairID(), 0)
		for i = 0, GameCommon.gameConfig.bPlayerCount - 1 do
			local wChairID = i
			if GameCommon.player ~= nil and GameCommon.player[wChairID] ~= nil then
				self:setWeaveItemArray(wChairID, GameCommon.player[wChairID].bWeaveItemCount, GameCommon.player[wChairID].WeaveItemArray)
				self:setDiscardCard(wChairID, GameCommon.player[wChairID].bDiscardCardCount, GameCommon.player[wChairID].bDiscardCard,GameCommon.player[wChairID].bOutCardMark)
			end
		end
	end)
	
	local uiPanel_night = ccui.Helper:seekWidgetByName(self.root, "Panel_night")
	local UserDefault_ZiPailiangdu = cc.UserDefault:getInstance():getIntegerForKey(Default.UserDefault_ZiPailiangdu, 0)
	if UserDefault_ZiPailiangdu == 0 then
		uiPanel_night:setVisible(false)
	else
		uiPanel_night:setVisible(true)
	end
	Common:addTouchEventListener(ccui.Helper:seekWidgetByName(self.root, "Button_set"), function()
		local path = self:requireClass('CDSetting')
		local box = require("app.MyApp"):create():createGame(path)
		self:addChild(box)
		
	end)
	local uiButton_expression = ccui.Helper:seekWidgetByName(self.root, "Button_expression")
	uiButton_expression:setPressedActionEnabled(true)
	local function onEventExpression(sender, event)
		if event == ccui.TouchEventType.ended then
			Common:palyButton()
			local child = self:getChildByName('CDChat')
			if child and child:getName() == 'CDChat' then
				child:setVisible(true)
				return true
			end
			local path = self:requireClass('CDChat')
			local box = require("app.MyApp"):create():createGame(path)
			box:setName('CDChat')
			self:addChild(box)
			-- require("common.GameChatLayer"):create(GameCommon.tableConfig.wKindID,function(index) 
			--     NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_GF_USER_EXPRESSION,"ww",index,GameCommon:getRoleChairID())
			-- end, 
			-- function(index,contents)
			--     NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER,NetMsgId.REQ_GR_USER_SEND_CHAT,"dwbnsdns",
			--         GameCommon:getRoleChairID(),index,GameCommon:getUserInfo(GameCommon:getRoleChairID()).cbSex,32,"",string.len(contents),string.len(contents),contents)
			-- end)
		end
	end
	uiButton_expression:addTouchEventListener(onEventExpression)
	local uiButton_ready = ccui.Helper:seekWidgetByName(self.root, "Button_ready")
	Common:addTouchEventListener(uiButton_ready, function()
		NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER, NetMsgId.REQ_GR_USER_READY, "o", false)
		--安全处理，保证下局开始前清理上局脏数据
		GameCommon.reconnectCardInfo = {}
	end)
	local uiButton_Invitation = ccui.Helper:seekWidgetByName(self.root, "Button_Invitation")
	Common:addTouchEventListener(uiButton_Invitation, function()
		local currentPlayerCount = 0
		for key, var in pairs(GameCommon.player) do
			currentPlayerCount = currentPlayerCount + 1
		end
		local player = "("
		for key, var in pairs(GameCommon.player) do
			if key == 0 then
				player = player .. var.szNickName
			else
				player = player .. "、" .. var.szNickName
			end
		end
		player = player .. ")"
        local data = clone(UserData.Share.tableShareParameter[3])
        data.dwClubID = GameCommon.tableConfig.dwClubID
        data.szShareTitle = string.format(data.szShareTitle,StaticData.Games[GameCommon.tableConfig.wKindID].name,
            GameCommon.tableConfig.wTbaleID,GameCommon.tableConfig.wTableNumber,
            GameCommon.gameConfig.bPlayerCount,GameCommon.gameConfig.bPlayerCount-currentPlayerCount)..player
        data.szShareContent = GameDesc:getGameDesc(GameCommon.tableConfig.wKindID,GameCommon.gameConfig,GameCommon.tableConfig).." (点击加入游戏)"
        data.szShareUrl = string.format(data.szShareUrl,GameCommon.tableConfig.szGameID)
        if GameCommon.tableConfig.nTableType ~= TableType_ClubRoom then
            data.cbTargetType = Bit:_xor(data.cbTargetType,0x20)
        end
        require("app.MyApp"):create(data, handler(self, self.pleaseOnlinePlayer)):createView("ShareLayer")
	end)
	
	local uiButton_disbanded = ccui.Helper:seekWidgetByName(self.root, "Button_quik")
	Common:addTouchEventListener(uiButton_disbanded, function()
		
		local conform = function(...)
			NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER, NetMsgId.REQ_GR_DISMISS_TABLE, "")
		end
		local config = {
			content = '确定解散房间？',
			button1 = {'取消'},
			button2 = {'确定', conform}
		}
		self:openBox(config)
	end)
	local uiButton_cancel = ccui.Helper:seekWidgetByName(self.root, "Button_cancel")  --取消按钮
	Common:addTouchEventListener(uiButton_cancel, function()
		require("common.SceneMgr"):switchScene(require("app.MyApp"):create():createView("HallLayer"), SCENE_HALL)
	end)
	local uiButton_out = ccui.Helper:seekWidgetByName(self.root, "Button_out")
	Common:addTouchEventListener(uiButton_out, function()
		
		local conform = function(...)
			NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER, NetMsgId.REQ_GR_LEAVE_TABLE_USER, "")
		end
		local config = {
			content = '您确定离开房间?\n房主离开意味着房间被解散',
			button1 = {'确认', conform},
			button2 = {'取消'}
		}
		self:openBox(config)
	end)
	
	local uiButton_return = ccui.Helper:seekWidgetByName(self.root, "Button_return")
	Common:addTouchEventListener(uiButton_return, function()
		-- require("common.MsgBoxLayer"):create(1, nil, "您确定返回大厅?", function()
		-- 	require("common.SceneMgr"):switchScene(require("app.MyApp"):create():createView("HallLayer"), SCENE_HALL)
		-- end)
		local conform = function(...)
			require("common.SceneMgr"):switchScene(require("app.MyApp"):create():createView("HallLayer"), SCENE_HALL)
		end
		local config = {
			content = '您确定返回大厅',
			button1 = {'取消'},
			button2 = {'确定', conform}
		}
		self:openBox(config)
	end)
	
	local uiButton_SignOut = ccui.Helper:seekWidgetByName(self.root, "Button_SignOut")
	Common:addTouchEventListener(uiButton_SignOut, function()
		require("common.MsgBoxLayer"):create(1, nil, "您确定返回大厅?", function()
			require("common.SceneMgr"):switchScene(require("app.MyApp"):create():createView("HallLayer"), SCENE_HALL)
		end)
	end)
	if CHANNEL_ID == 6 or CHANNEL_ID == 7 or CHANNEL_ID == 8 or CHANNEL_ID == 9 then
	else
		uiButton_SignOut:setVisible(false)
		-- uiButton_out:setPositionX(visibleSize.width*0.36)       
		-- uiButton_Invitation:setPositionX(visibleSize.width*0.64)  
	end
	local uiButton_position = ccui.Helper:seekWidgetByName(self.root, "Button_position")   -- 定位
	Common:addTouchEventListener(uiButton_position, function()
		require("common.PositionLayer"):create(GameCommon.tableConfig.wKindID)
	end)
	-- local uiPanel_playerInfoBg = ccui.Helper:seekWidgetByName(self.root,"Panel_playerInfoBg")
	-- if GameCommon.tableConfig.wCurrentNumber == 0 and  GameCommon.tableConfig.nTableType > TableType_GoldRoom then
	--     if CHANNEL_ID ~= 0 and CHANNEL_ID ~= 1 then
	--         uiPanel_playerInfoBg:setVisible(true) 
	--     else 
	--         uiPanel_playerInfoBg:setVisible(false)
	--     end
	-- end
	--结算层
	local uiPanel_end = ccui.Helper:seekWidgetByName(self.root, "Panel_end")
	uiPanel_end:setVisible(false)
	--灯光层
	local uiButton_voice = ccui.Helper:seekWidgetByName(self.root, "Button_voice")
	-- local uiText_title = ccui.Helper:seekWidgetByName(self.root,"Text_title")
	-- local uiText_des = ccui.Helper:seekWidgetByName(self.root,"Text_des")
	-- uiText_title:setString(StaticData.Games[GameCommon.tableConfig.wKindID].name)    
	if GameCommon.tableConfig.nTableType > TableType_GoldRoom then
		self:addVoice()
		local uiListView_function = ccui.Helper:seekWidgetByName(self.root, "ListView_function")
		if StaticData.Hide[CHANNEL_ID].btn10 == 0 then
			uiListView_function:removeItem(uiListView_function:getIndex(uiButton_position))
			-- uiPanel_playerInfoBg:setVisible(false) 
		end
		uiButton_cancel:setVisible(false)
		if GameCommon.gameState == GameCommon.GameState_Start then
			local uiPanel_ready = ccui.Helper:seekWidgetByName(self.root, "Panel_ready")
			uiPanel_ready:setVisible(false)

			
		elseif GameCommon.tableConfig.wCurrentNumber > 0 then
			uiButton_Invitation:setVisible(false)
			uiButton_out:setVisible(false)
			uiButton_SignOut:setVisible(false)
		end			
		if StaticData.Hide[CHANNEL_ID].btn4 ~= 1 then
			uiButton_Invitation:setVisible(false)
			uiButton_out:setPositionX(visibleSize.width*0.5)   
		else
			uiButton_Invitation:setVisible(true)
		end
		-- local Text_roomInfo = GameCommon:seekWidgetByNameEx(self.root, "Text_roomInfo")
		-- Text_roomInfo:setString(string.format("房间:%d 第%d/%d局", GameCommon.tableConfig.wTbaleID, GameCommon.tableConfig.wCurrentNumber, GameCommon.tableConfig.wTableNumber))	
		--	self:setTablePlayWayInfo()
		local Button_copy = ccui.Helper:seekWidgetByName(self.root, "Button_copy")
		if GameCommon.tableConfig.wCurrentNumber > 0 then
			Button_copy:setVisible(false)
		else
			Button_copy:setVisible(true)
		end
		
		-- ccs.ArmatureDataManager:getInstance():addArmatureFileInfo("game/dengdaihaoyou/dengdaihaoyou.ExportJson")
-- local waitArmature=ccs.Armature:create("dengdaihaoyou") 
-- waitArmature:setPosition(-179.2,120)
-- if CHANNEL_ID == 6 or  CHANNEL_ID  == 7 or CHANNEL_ID == 8 or  CHANNEL_ID  == 9 then
--     waitArmature:setPosition(0,120)
-- end        
-- waitArmature:getAnimation():playWithIndex(0)
-- uiButton_Invitation:addChild(waitArmature)   
	elseif GameCommon.tableConfig.nTableType == TableType_GoldRoom then			
		self:addVoice()
		-- uiPanel_playerInfoBg:setVisible(false)
		uiButton_ready:setVisible(false)
		uiButton_Invitation:setVisible(false)
		uiButton_out:setVisible(false)
		uiButton_SignOut:setVisible(false)
		local uiListView_function = ccui.Helper:seekWidgetByName(self.root, "ListView_function")
		uiListView_function:removeItem(uiListView_function:getIndex(uiButton_disbanded))
		uiListView_function:removeItem(uiListView_function:getIndex(uiButton_position))
		local uiPanel_ready = ccui.Helper:seekWidgetByName(self.root, "Panel_ready")
		--        uiPanel_ready:setVisible(false)
		uiButton_voice:setVisible(false)
		uiButton_expression:setVisible(false)
		if GameCommon.tableConfig.cbLevel == 2 then
			-- uiText_des:setString(string.format("中级场 倍率 %d",GameCommon.tableConfig.wCellScore))
		elseif GameCommon.tableConfig.cbLevel == 3 then
			-- uiText_des:setString(string.format("高级场 倍率 %d",GameCommon.tableConfig.wCellScore))
		else
			-- uiText_des:setString(string.format("初级场 倍率 %d",GameCommon.tableConfig.wCellScore))
		end
		self:drawnout()					
		ccs.ArmatureDataManager:getInstance():addArmatureFileInfo("game/xunzhaoduishou/xunzhaoduishou.ExportJson")
		local waitArmature = ccs.Armature:create("xunzhaoduishou")
		waitArmature:setPosition(0, - 100)
		waitArmature:getAnimation():playWithIndex(0)
		uiButton_cancel:addChild(waitArmature)
		local Button_copy = ccui.Helper:seekWidgetByName(self.root, "Button_copy")
		Button_copy:setVisible(false)
		uiButton_cancel:setVisible(true)
		local Panel_goldType = ccui.Helper:seekWidgetByName(self.root, "Panel_goldType")
		Panel_goldType:setVisible(false)
		local Button_set = ccui.Helper:seekWidgetByName(self.root, "Button_set")
		Button_set:setPositionX(243.27)
		
	elseif GameCommon.tableConfig.nTableType == TableType_SportsRoom then			
		self:addVoice()
		-- uiPanel_playerInfoBg:setVisible(false)
		uiButton_ready:setVisible(false)
		uiButton_Invitation:setVisible(false)
		uiButton_out:setVisible(false)
		uiButton_SignOut:setVisible(false)
		local uiListView_function = ccui.Helper:seekWidgetByName(self.root, "ListView_function")
		uiListView_function:removeItem(uiListView_function:getIndex(uiButton_disbanded))
		if StaticData.Hide[CHANNEL_ID].btn10 == 0 then
			uiListView_function:removeItem(uiListView_function:getIndex(uiButton_position))
		end
		local uiPanel_ready = ccui.Helper:seekWidgetByName(self.root, "Panel_ready")
		--        uiPanel_ready:setVisible(false)
		uiButton_voice:setVisible(false)
		uiButton_expression:setVisible(false)
		-- uiText_des:setString("竞技场")
		self:drawnout()
		ccs.ArmatureDataManager:getInstance():addArmatureFileInfo("game/xunzhaoduishou/xunzhaoduishou.ExportJson")
		local waitArmature = ccs.Armature:create("xunzhaoduishou")
		waitArmature:setPosition(0, - 100)
		waitArmature:getAnimation():playWithIndex(0)
		uiButton_cancel:addChild(waitArmature)
		local Button_copy = ccui.Helper:seekWidgetByName(self.root, "Button_copy")
		Button_copy:setVisible(false)
	else
		local uiPanel_ui = ccui.Helper:seekWidgetByName(self.root, "Panel_ui")
		uiPanel_ui:setVisible(false)
		-- uiText_des:setString("牌局回放")
	end

	local Button_qipai = ccui.Helper:seekWidgetByName(self.root, "Button_qipai")
	Button_qipai:setPressedActionEnabled(true)
	local function onEventReset(sender, event)
		if event == ccui.TouchEventType.ended then
			Common:palyButton()
			local conform = function()
				print('------->>>>弃牌')
				NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_C_SISHOU, "b", 1)
				local uiPanel_outCardTips = ccui.Helper:seekWidgetByName(self.root, "Panel_outCardTips")
				uiPanel_outCardTips:removeAllChildren()
				Button_qipai:setVisible(false)
			end
			local config = {
				content = '是否确定弃牌？',
				button1 = {'确定', conform},
				button2 = {'取消'}
			}
			self:openBox(config)
		end
	end
	Button_qipai:addTouchEventListener(onEventReset)

	local Button_jushou = ccui.Helper:seekWidgetByName(self.root, "Button_jushou")
	Button_jushou:setPressedActionEnabled(true)
	local function onEventJuShou(sender, event)
		if event == ccui.TouchEventType.ended then
			Common:palyButton()
			NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_C_JUSHOUZUOSHENG,'b',2)
		end
	end
	Button_jushou:addTouchEventListener(onEventJuShou)

	local Button_quxiao = ccui.Helper:seekWidgetByName(self.root, "Button_quxiao")
	Button_quxiao:setPressedActionEnabled(true)
	local function onEventQuxiao(sender, event)
		if event == ccui.TouchEventType.ended then
			Common:palyButton()
			NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_C_JUSHOUZUOSHENG,'b',0)
		end
	end
	Button_quxiao:addTouchEventListener(onEventQuxiao)


	--重启游戏
	local Button_reset = ccui.Helper:seekWidgetByName(self.root, "Button_reset")
	Button_reset:setPressedActionEnabled(true)
	local function onEventReset(sender, event)
		if event == ccui.TouchEventType.ended then
			Common:palyButton()
			require("common.SceneMgr"):switchScene(require("app.MyApp"):create(true, true):createView("LoginLayer"), SCENE_LOGIN)
		end
	end
	Button_reset:addTouchEventListener(onEventReset)
	
	--回到结算
	local Button_showEnd = ccui.Helper:seekWidgetByName(self.root, "Button_showEnd")
	Button_showEnd:setPressedActionEnabled(true)
	local function onEventReset(sender, event)
		if event == ccui.TouchEventType.ended then
			Common:palyButton()
			EventMgr:dispatch(EventType.CUS_GAMEENDlAYER_CLIENT)
		end
	end
	Button_showEnd:addTouchEventListener(onEventReset)
	
	--准备
	local Button_readStart = ccui.Helper:seekWidgetByName(self.root, "Button_readStart")
	Button_readStart:setPressedActionEnabled(true)
	local function onEventReset(sender, event)
		if event == ccui.TouchEventType.ended then
			Common:palyButton()
			if GameCommon.tableConfig.nTableType > TableType_GoldRoom then
				if GameCommon.tableConfig.wTableNumber == GameCommon.tableConfig.wCurrentNumber then
					EventMgr:dispatch(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK)
				else
					GameCommon:ContinueGame(GameCommon.tableConfig.cbLevel)
				end
			elseif GameCommon.tableConfig.nTableType == TableType_GoldRoom then
				GameCommon:ContinueGame(GameCommon.tableConfig.cbLevel)
			else
				require("common.SceneMgr"):switchScene(require("app.MyApp"):create():createView("HallLayer"), SCENE_HALL)
			end
		end
	end
	Button_readStart:addTouchEventListener(onEventReset)
	
	--定位
	local Button_location = ccui.Helper:seekWidgetByName(self.root, "Button_location")
	Button_location:setPressedActionEnabled(true)
	local function onEventReset(sender, event)
		if event == ccui.TouchEventType.ended then
			Common:palyButton()
			require("common.SceneMgr"):switchOperation(require("app.MyApp"):create():createGame("game.cdphz.CDLocationLayer"))
		end
	end
	Button_location:addTouchEventListener(onEventReset)
	
	--复制房间号
	local Button_copy = ccui.Helper:seekWidgetByName(self.root, "Button_copy")
	Button_copy:setPressedActionEnabled(true)
	local function onEventReset(sender, event)
		if event == ccui.TouchEventType.ended then
			Common:palyButton()
			local currentPlayerCount = 0
			for key, var in pairs(GameCommon.player) do
				currentPlayerCount = currentPlayerCount + 1
			end
			local player = "("
			for key, var in pairs(GameCommon.player) do
				if key == 0 then
					player = player .. var.szNickName
				else
					player = player .. "、" .. var.szNickName
				end
			end
			player = player .. ")"
            local data = clone(UserData.Share.tableShareParameter[3])
            data.dwClubID = GameCommon.tableConfig.dwClubID
            data.szShareTitle = string.format(data.szShareTitle,StaticData.Games[GameCommon.tableConfig.wKindID].name,
                GameCommon.tableConfig.wTbaleID,GameCommon.tableConfig.wTableNumber,
                GameCommon.gameConfig.bPlayerCount,GameCommon.gameConfig.bPlayerCount-currentPlayerCount)..player
            data.szShareContent = GameDesc:getGameDesc(GameCommon.tableConfig.wKindID,GameCommon.gameConfig,GameCommon.tableConfig).." (点击加入游戏)"
            data.szShareUrl = string.format(data.szShareUrl,GameCommon.tableConfig.szGameID)
            data.text = data.szShareTitle .. "\n" .. data.szShareContent
            UserData.User:copydata(data.text)
            require("common.MsgBoxLayer"):create(0, nil, "复制成功")
            			
			local conform = function(...)
				UserData.User:OpenExternal('0')
			end
			local config = {
				content = '复制到剪贴板成功！请进入微信粘贴\n发送到友/群，是否进入微信？',
				button2 = {'打开微信', conform}
			}
			self:openBox(config)			
		end
	end
	Button_copy:addTouchEventListener(onEventReset)
	
	--重置牌排序
	local Button_change = ccui.Helper:seekWidgetByName(self.root, "Button_change")
	Button_change:setPressedActionEnabled(true)
	Button_change:setVisible(false)
	local index = 1
	local hitCount = 0
	local function onEventReset(sender, event)
		if event == ccui.TouchEventType.ended then
			Common:palyButton()
			index = index + 1
			if index > 3 then
				index = 1
			end
			local wChairID = self:getChairIDByUserID(UserData.User.userID) or 0
			local cbCardIndex = GameCommon.player[wChairID].cbCardIndex
			local maxHanCardRow = GameCommon.player[wChairID].maxHanCardRow
			local uiPanel_stacks = ccui.Helper:seekWidgetByName(self.root, "Panel_stacks")
			
			local newStackInfo = GameLogic:sortHandCard(clone(cbCardIndex), maxHanCardRow, cc.p(uiPanel_stacks:getPosition()), index)
			local isEquil = self:isHandCardAllEqual(GameCommon.player[wChairID].cardStackInfo, newStackInfo)
			if isEquil then
				hitCount = hitCount + 1
				if hitCount > 2 then
					hitCount = 0
					return
				end
				onEventReset(nil, ccui.TouchEventType.ended)
			else
				hitCount = 0
				GameCommon.player[wChairID].cardStackInfo = newStackInfo
				self:showHandCard(wChairID, 3)
			end
		end
	end
	Button_change:addTouchEventListener(onEventReset)
	
	self:initTableViewInfo()
end

function TableLayer:refreshQiPaiView(pBuffer)
	dump(pBuffer)
	if type(pBuffer) ~= 'table' then
		return
	end

	for i,v in ipairs(pBuffer.bUserSiShou) do
		local viewID = GameCommon:getViewIDByChairID(i - 1)
		local uiPanel_player = ccui.Helper:seekWidgetByName(self.root, string.format("Panel_player%d", viewID))
		local Image_qipai = ccui.Helper:seekWidgetByName(uiPanel_player, "Image_qipai")
		if v ~= 0 then
			Image_qipai:setVisible(true)
		else
			Image_qipai:setVisible(false)
		end
	end
end

function TableLayer:drawnout()
	local uiImage_timedown = ccui.Helper:seekWidgetByName(self.root, "Image_timedown")
	uiImage_timedown:setVisible(true)
	
	local uiText__timedown = ccui.Helper:seekWidgetByName(self.root, "Text__timedown")
	uiText__timedown:setPosition(uiText__timedown:getParent():getContentSize().width / 2, uiText__timedown:getParent():getContentSize().height * 0.56)
	uiText__timedown:stopAllActions()
	uiText__timedown:setString("00:00:00")
	local currentTime = 0
	local function onEventTime(sender, event)
		currentTime = currentTime + 1
		uiText__timedown:setString(string.format("%02d:%02d:%02d", math.floor(currentTime /(60 * 60)), math.floor(currentTime / 60), math.floor(currentTime % 60)))
	end
	uiText__timedown:runAction(cc.RepeatForever:create(cc.Sequence:create(cc.DelayTime:create(1), cc.CallFunc:create(onEventTime))))
	
	
end

function TableLayer:updateGameState(state)
	GameCommon.gameState = state
	local visibleSize = cc.Director:getInstance():getVisibleSize()
	if state == GameCommon.GameState_Init then
		
	elseif state == GameCommon.GameState_Start then
		require("common.SceneMgr"):switchOperation()
		-- local uiPanel_playerInfoBg = ccui.Helper:seekWidgetByName(self.root,"Panel_playerInfoBg")
		-- uiPanel_playerInfoBg:setVisible(false)
		local uiPanel_ready = ccui.Helper:seekWidgetByName(self.root, "Panel_ready")
		uiPanel_ready:setVisible(false)
		if GameCommon.tableConfig.nTableType > TableType_GoldRoom then		
			
			--距离报警  
			--  if GameCommon.tableConfig.wCurrentNumber ~= nil and GameCommon.tableConfig.wCurrentNumber == 1 and GameCommon.DistanceAlarm == 0 and StaticData.Hide[CHANNEL_ID].btn16 == 1  then
			--      GameCommon.DistanceAlarm = 1 
			--      require("common.DistanceAlarm"):create(GameCommon)
			-- end
			for i = 1, 4 do
				local uiPanel_player = ccui.Helper:seekWidgetByName(self.root, string.format("Panel_player%d", i))
				local uiImage_ready = ccui.Helper:seekWidgetByName(uiPanel_player, "Image_ready")
				uiImage_ready:setVisible(false)
			end
		elseif GameCommon.tableConfig.nTableType == TableType_GoldRoom or GameCommon.tableConfig.nTableType == TableType_SportsRoom then
			local uiButton_expression = ccui.Helper:seekWidgetByName(self.root, "Button_expression")
			uiButton_expression:setVisible(true)
			local uiButton_voice = ccui.Helper:seekWidgetByName(self.root, "Button_voice")
			uiButton_voice:setVisible(true)
		end
		local uiButton_cancel = ccui.Helper:seekWidgetByName(self.root, "Button_cancel")  --取消按钮
		uiButton_cancel:setVisible(false)
		local uiImage_timedown = ccui.Helper:seekWidgetByName(self.root, "Image_timedown")
		uiImage_timedown:setVisible(false)
		local Button_change = ccui.Helper:seekWidgetByName(self.root, "Button_change")
		Button_change:setVisible(true)
		
		if GameCommon.gameConfig.bPlayerCount >= 4 then
			self:fourTableLayout()
		end
	elseif state == GameCommon.GameState_Over then
		UserData.Game:addGameStatistics(GameCommon.tableConfig.wKindID)
	else
		
	end
end

--语音
function TableLayer:addVoice()
	self.tableVoice = {}
	local startVoiceTime = 0
	local maxVoiceTime = 15
	local intervalTimePackage = 0.1
	local fileName = "temp_voice.mp3"
	local uiButton_voice = ccui.Helper:seekWidgetByName(self.root, "Button_voice")
	local animVoice = cc.CSLoader:createNode("VoiceNode.csb")
	self:addChild(animVoice, 120)
	local root = animVoice:getChildByName("Panel_root")
	local uiPanel_recording = ccui.Helper:seekWidgetByName(root, "Panel_recording")
	local uiPanel_cancel = ccui.Helper:seekWidgetByName(root, "Panel_cancel")
	local uiText_surplus = ccui.Helper:seekWidgetByName(root, "Text_surplus")
	animVoice:setVisible(false)
	
	--重置状态
	local duration = 0
	local function resetVoice()
		startVoiceTime = 0
		animVoice:stopAllActions()
		animVoice:setVisible(false)
		uiPanel_recording:setVisible(true)
		
		local uiImage_pro = ccui.Helper:seekWidgetByName(root, "Image_pro")
		uiImage_pro:removeAllChildren()
		local volumeMusic = cc.UserDefault:getInstance():getFloatForKey("UserDefault_Music", 1)
		cc.SimpleAudioEngine:getInstance():setMusicVolume(volumeMusic)
		cc.SimpleAudioEngine:getInstance():setEffectsVolume(1)
		uiButton_voice:removeAllChildren()
		local node = require("common.CircleLoadingBar"):create("huaihua/ui/chat/btnMask.png")
		node:setColor(cc.c3b(0, 0, 0))
		uiButton_voice:addChild(node)
		node:setPosition(node:getParent():getContentSize().width / 2, node:getParent():getContentSize().height / 2)
		node:start(1)
		uiButton_voice:setEnabled(false)
		uiButton_voice:stopAllActions()
		uiButton_voice:runAction(cc.Sequence:create(cc.DelayTime:create(1), cc.CallFunc:create(function(sender, event)
			uiButton_voice:setEnabled(true)
		end)))
	end
	
	root:setTouchEnabled(true)
	root:addTouchEventListener(function(sender, event)
		UserData.Game:cancelVoice()
		resetVoice()
	end)
	
	local function onEventSendVoic(event)
		if self.root == nil then
			return
		end
		if cc.PLATFORM_OS_ANDROID == cc.Application:getInstance():getTargetPlatform() then
			if event == nil or string.len(event) <= 0 then
				return
			else
				event = Base64.decode(event)
			end
			local file = io.open(FileDir.dirVoice .. fileName, "wb+")
			file:write(event)
			file:close()
		end
		if cc.FileUtils:getInstance():isFileExist(FileDir.dirVoice .. fileName) == false then
			print("没有找到录音文件", FileDir.dirVoice .. fileName)
			return
		end
		local fp = io.open(FileDir.dirVoice .. fileName, "rb")
		local fileData = fp:read("*a")
		fp:close()
		
		local data = {}
		data.chirID = GameCommon:getRoleChairID()
		data.time = duration
		data.file = string.format("%d_%d.mp3", os.time(), UserData.User.userID)
		
		local fp = io.open(FileDir.dirVoice .. data.file, "wb+")
		fp:write(fileData)
		fp:close()
		table.insert(self.tableVoice, #self.tableVoice + 1, data)
		
		cc.FileUtils:getInstance():removeFile(FileDir.dirVoice .. fileName)   --windows test
		
		local fileSize = string.len(fileData)
		local packSize = 1024
		local additional = fileSize % packSize
		if additional > 0 then
			additional = 1
		else
			additional = 0
		end
		local packCount = math.floor(fileSize / packSize) + additional
		local currentPos = 0
		for i = 1, packCount do
			local periodData = string.sub(fileData, 1, packSize)
			fileData = string.sub(fileData, packSize + 1)
			local periodSize = string.len(periodData)
			NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME, NetMsgId.SUB_GF_USER_VOICE, "wwwdddnsnf", GameCommon:getRoleChairID(), packCount, i, data.time, fileSize, periodSize, 32, data.file, periodSize, periodData)
		end
		
	end
	
	local function onEventVoice(sender, event)
		if event == ccui.TouchEventType.began then
			startVoiceTime = 0
			uiButton_voice:setEnabled(false)
			animVoice:setVisible(true)
			cc.SimpleAudioEngine:getInstance():setMusicVolume(0)
			cc.SimpleAudioEngine:getInstance():setEffectsVolume(0)
			uiPanel_recording:setVisible(true)
			startVoiceTime = os.time()
			UserData.Game:startVoice(FileDir.dirVoice .. fileName, maxVoiceTime, onEventSendVoic)
			
			local node = require("common.CircleLoadingBar"):create("common/yuying02.png")
			local uiImage_pro = ccui.Helper:seekWidgetByName(root, "Image_pro")
			uiImage_pro:removeAllChildren()
			uiImage_pro:addChild(node)
			node:setPosition(node:getParent():getContentSize().width / 2, node:getParent():getContentSize().height / 2)
			node:start(maxVoiceTime)
			
			local currentTime = 0
			uiText_surplus:stopAllActions()
			uiText_surplus:setString(string.format("还剩%d秒", maxVoiceTime - currentTime))
			uiText_surplus:runAction(cc.RepeatForever:create(cc.Sequence:create(cc.DelayTime:create(1), cc.CallFunc:create(function(sender, event)
				currentTime = currentTime + 1
				if currentTime > maxVoiceTime then
					uiText_surplus:stopAllActions()
					return
				end
				uiText_surplus:setString(string.format("还剩%d秒", maxVoiceTime - currentTime))
			end))))
			
		elseif event == ccui.TouchEventType.ended then
			if startVoiceTime == 0 or os.time() - startVoiceTime < 1 then
				UserData.Game:cancelVoice()
				resetVoice()
				return
			end
			duration = os.time() - startVoiceTime
			resetVoice()
			UserData.Game:overVoice()
			--onEventSendVoic() --windows test
		elseif event == ccui.TouchEventType.canceled then
			if startVoiceTime == 0 or os.time() - startVoiceTime < 1 then
				resetVoice()
				return
			end
			resetVoice()
			UserData.Game:cancelVoice()
		end
	end
	uiButton_voice:addTouchEventListener(onEventVoice)
	local function onEventPlayVoice(sender, event)
		if #self.tableVoice > 0 then
			local data = self.tableVoice[1]
			table.remove(self.tableVoice, 1)
			if data.time > maxVoiceTime then
				data.time = maxVoiceTime
			end
			local viewID = GameCommon:getViewIDByChairID(data.chirID)
			local wanjia = ccui.Helper:seekWidgetByName(self.root, string.format("Panel_player%d", viewID))
			local uiImage_laba = ccui.Helper:seekWidgetByName(wanjia, "Image_laba")
			local blinks = math.floor(data.time * 2) + 1
			uiImage_laba:stopAllActions()
			uiImage_laba:runAction(cc.Sequence:create(
			cc.Show:create(),
			cc.CallFunc:create(function(sender, event)
				require("common.Common"):playVoice(FileDir.dirVoice .. data.file)
			end),
			cc.Blink:create(data.time, blinks),
			cc.Hide:create(),
			cc.DelayTime:create(1),
			cc.CallFunc:create(function(sender, event)
				cc.FileUtils:getInstance():removeFile(FileDir.dirVoice .. data.file)
				onEventPlayVoice()
			end)
			))
			
		else
			self:runAction(cc.Sequence:create(cc.DelayTime:create(0), cc.CallFunc:create(onEventPlayVoice)))
		end
	end
	onEventPlayVoice()
end

function TableLayer:OnUserChatVoice(event)
	if self.tableVoicePackages == nil then
		self.tableVoicePackages = {}
	end
	if self.tableVoicePackages[event.szFileName] == nil then
		self.tableVoicePackages[event.szFileName] = {}
	end
	self.tableVoicePackages[event.szFileName] [event.wPackIndex] = event
	
	--组包
	if event.wPackCount == #self.tableVoicePackages[event.szFileName] then
		local fileData = ""
		for key, var in pairs(self.tableVoicePackages[event.szFileName]) do
			fileData = fileData .. var.szPeriodData
		end
		local data = {}
		data.chirID = self.tableVoicePackages[event.szFileName] [1].wChairID
		data.time = self.tableVoicePackages[event.szFileName] [1].dwTime
		data.file = self.tableVoicePackages[event.szFileName] [1].szFileName
		local fp = io.open(FileDir.dirVoice .. data.file, "wb+")
		fp:write(fileData)
		fp:close()
		table.insert(self.tableVoice, #self.tableVoice + 1, data)
		self.tableVoicePackages[event.szFileName] = nil
		print("插入一条语音...", fileData)
	end
end

function TableLayer:showPlayerPosition()   -- 显示玩家距离
	EventMgr:dispatch(EventType.RET_GAMES_USER_POSITION)
end

function TableLayer:showPlayerInfo(infoTbl)       -- 查看玩家信息
	Common:palyButton()
	require("common.SceneMgr"):switchOperation(require("app.MyApp"):create(infoTbl, self):createGame("game.cdphz.CDPersonInfoLayer"))
	-- self:addChild(require("app.MyApp"):create(infoTbl, self):createGame("game.cdphz.CDPersonInfoLayer"))
end

function TableLayer:showChat(pBuffer)
	local viewID = GameCommon:getViewIDByChairID(pBuffer.dwUserID, true)
	local uiPanel_player = ccui.Helper:seekWidgetByName(self.root, string.format("Panel_player%d", viewID))
	local uiImage_chat = ccui.Helper:seekWidgetByName(uiPanel_player, "Image_chat")
	local uiText_chat = ccui.Helper:seekWidgetByName(uiPanel_player, "Text_chat")
	uiText_chat:setString(pBuffer.szChatContent)
	uiImage_chat:setVisible(true)
	uiImage_chat:setScale(0)
	uiImage_chat:stopAllActions()
	uiImage_chat:runAction(cc.Sequence:create(cc.ScaleTo:create(0.1, 1), cc.DelayTime:create(5), cc.Hide:create()))
	local wKindID = GameCommon.tableConfig.wKindID
	local Chat = nil
	local Chat = require("game.cdphz.ChatConfig")
	local data = Chat[pBuffer.dwSoundID - 100]
	local sound = nil
	if data then
		sound = data.sound
	end
	local soundData = nil
	local soundFile = ''
	if data then
		
		soundData = sound[GameCommon.language]
		if GameCommon.language ~= 0 then
			local wKindID = GameCommon.tableConfig.wKindID
			if wKindID == 47 or wKindID == 48 or wKindID == 49 or wKindID == 60 then
				soundData = sound[2]
			end
		end
		
		if soundData ~= nil then
			soundFile = soundData[pBuffer.cbSex]
		end
	end
	
	if data ~= nil and soundFile ~= "" then
		require("common.Common"):playEffect(soundFile)
	end
end

function TableLayer:showExperssion(pBuffer)
	print('----------->>>收到消息', pBuffer.wIndex)
	-- if pBuffer.wIndex <= 100 then
	-- 	self:playFrameAnimation(pBuffer)
	-- else
	-- 	self:playSpine(pBuffer)
	-- end
	self:playSpine(pBuffer)
end

--50进行分页
function TableLayer:playSpine(pBuffer)
    local cusNode = cc.Director:getInstance():getNotificationNode()
    if not cusNode then
    	printInfo('global_node is nil')
    	return
    end
    local arr = cusNode:getChildren()
    for i,v in ipairs(arr) do
        v:setVisible(false)
    end

	local viewID = GameCommon:getViewIDByChairID(pBuffer.wChairID, true)
	local userAnim = ccui.Helper:seekWidgetByName(self.root, string.format("Panel_anim_%d", viewID))
	local worldPos = cc.p(userAnim:getParent():convertToWorldSpace(cc.p(userAnim:getPosition())))

	local path = ''
	local index = math.floor(pBuffer.wIndex / 50) + 1
	local animIndex
	if index == 1 then --第一页
		animIndex = 23
	elseif index == 2 then --第二页
		animIndex = 24
	end
	local anim
	if animIndex then
		anim = require("game.cdphz.Animation") [animIndex]
	end
	if anim then
		local id = math.mod(pBuffer.wIndex, 50)
		local data = anim[id]
		if data then
			local skeletonNode = cusNode:getChildByName('cdskele_' .. pBuffer.wIndex)
			if not skeletonNode then
				skeletonNode = sp.SkeletonAnimation:create(data.animFile .. '.json', data.animFile .. '.atlas')
				cusNode:addChild(skeletonNode)
				skeletonNode:setName('cdskele_' .. pBuffer.wIndex)
			end
			skeletonNode:setPosition(worldPos)
			skeletonNode:setAnimation(0, data.animName, false)
			skeletonNode:setVisible(true)

			local idx = 1
			skeletonNode:registerSpineEventHandler(function()
				idx = idx + 1
				if idx > 3 then
					-- skeletonNode:runAction(cc.Sequence:create(cc.DelayTime:create(0), cc.RemoveSelf:create()))
					skeletonNode:setVisible(false)
				else
					skeletonNode:setAnimation(0, data.animName, false)
				end
			end, sp.EventType.ANIMATION_COMPLETE)
			
			local sound = data.sound
			local soundData = nil
			local soundFile = ''
			if sound then
				
				soundData = sound[GameCommon.language]
				if GameCommon.language ~= 0 then
					local wKindID = GameCommon.tableConfig.wKindID
					if wKindID == 47 or wKindID == 48 or wKindID == 49 or wKindID == 60 then
						soundData = sound[2]
					end
				end
				
				if soundData ~= nil then
					local player = GameCommon.player[pBuffer.wChairID]
					local csbSex = 0
					if player then
						csbSex = player.cbSex
					end
					soundFile = soundData[csbSex]
				end
			end
			
			if soundFile and soundFile ~= "" then
				require("common.Common"):playEffect(soundFile)
			end
		end
	end
end

function TableLayer:EVENT_TYPE_SKIN_CHANGE(event)
	local data = event._usedata
	self:initTableViewInfo()
	
	--亮度
	local uiPanel_night = ccui.Helper:seekWidgetByName(self.root, "Panel_night")
	local UserDefault_ZiPailiangdu = cc.UserDefault:getInstance():getIntegerForKey(Default.UserDefault_ZiPailiangdu, 0)
	if UserDefault_ZiPailiangdu == 0 then
		uiPanel_night:setVisible(false)
	else
		uiPanel_night:setVisible(true)
	end
	
	self:showHandCard(GameCommon:getRoleChairID(), 0)
	
	--牌背
	for i = 0, GameCommon.gameConfig.bPlayerCount - 1 do
		local wChairID = i
		if GameCommon.player ~= nil and GameCommon.player[wChairID] ~= nil then
			self:setWeaveItemArray(wChairID, GameCommon.player[wChairID].bWeaveItemCount, GameCommon.player[wChairID].WeaveItemArray)
			self:setDiscardCard(wChairID, GameCommon.player[wChairID].bDiscardCardCount, GameCommon.player[wChairID].bDiscardCard,GameCommon.player[wChairID].bOutCardMark)
		end
	end
end

function TableLayer:initTableViewInfo()
	--背景
	local uiPanel_bg = ccui.Helper:seekWidgetByName(self.root, "Image_bg")
	local bgNum = nil
	
	bgNum = cc.UserDefault:getInstance():getIntegerForKey('CDzipaiBg', 1)
	if bgNum < 1 or bgNum > 4 then
		bgNum = 1
	end
	uiPanel_bg:loadTexture(string.format("cdzipai/bg/room_bg%d.jpg", bgNum))
	
	-- --字体
	-- for i = 1, 2 do
	-- 	local BitmapFontLabel = ccui.Helper:seekWidgetByName(self.root, string.format("BitmapFontLabel_%d", i))
	-- 	BitmapFontLabel:setFntFile(string.format("cdzipai/font/gametype%d.fnt", bgNum))
	-- end
	
	--虚线高度
	local visibleSize = cc.Director:getInstance():getVisibleSize()
	local lineH = cc.UserDefault:getInstance():getIntegerForKey('CDlineHeight', 0)
	local uiImage_line = ccui.Helper:seekWidgetByName(self.root, "Image_line")
	if lineH == 0 then
		uiImage_line:setPositionY(visibleSize.height * 0.47)
	else
		uiImage_line:setPositionY(visibleSize.height * 0.55)
	end
	
	--卡牌大小
	cardtype = cc.UserDefault:getInstance():getIntegerForKey('CDpaiSize', 2)
	CardSize = CardSizeArr[cardtype]
	
	IsOpenTin = cc.UserDefault:getInstance():getBoolForKey('CDisOpenTin', true)
	if not IsOpenTin then
		local Image_tp = ccui.Helper:seekWidgetByName(self.root, "Image_tp")
		Image_tp:setVisible(false)
	end
	
	CtlSpeed = cc.UserDefault:getInstance():getIntegerForKey('CDspeed', 2)
	
	-- --游戏标题
	-- local wKindID = GameCommon.tableConfig.wKindID
	-- local BitmapFontLabel_1 = ccui.Helper:seekWidgetByName(self.root, "BitmapFontLabel_1")
	-- if wKindID == 47 or wKindID == 48 or wKindID == 49 then
	-- 	BitmapFontLabel_1:setString('常德跑胡子')
	-- else
	-- 	BitmapFontLabel_1:setString(StaticData.Games[wKindID].name)
	-- end
	
	-- local BitmapFontLabel_2 = ccui.Helper:seekWidgetByName(self.root, "BitmapFontLabel_2")
	-- BitmapFontLabel_2:setString(StaticData.Games[wKindID].describe)
end

--[
-- @brief  设置不能扯动的牌置灰
-- @param  rowCardInfo 一列牌信息
-- @param  oneCardInfo 这列下单张牌信息
-- @return void
--]
function TableLayer:setUnMovedCardGrey(rowCardInfo, oneCardInfo)
	if true then
		--置灰暂时屏蔽，代理不喜欢
		return
	end
	
	local isCan = true
	if oneCardInfo.data ~= GameCommon.CardData_WW and rowCardInfo.nCardCount >= 3 then
		isCan = false
		local value = nil
		for key, var in pairs(rowCardInfo.cbCardData) do
			if value ~= nil and value ~= var.data then
				isCan = true
				break
			end
			value = var.data
		end
	end
	
	if isCan == false then
		oneCardInfo.node:setColor(cc.c3b(150, 150, 150))
	end
end

--[
-- @brief  重置用户出牌计时动作
-- @param  void
-- @return void
--]
function TableLayer:resetUserCountTimeAni()
	-- for i = 1, 4 do
	--     local Panel_player = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_player%d",i))
	--     local Panel_countdown = Panel_player:getChildByName("Panel_countdown")
	--     local AtlasLabel_countdownTime = Panel_countdown:getChildByName("AtlasLabel_countdownTime")
	--     Panel_countdown:setVisible(false)
	--     AtlasLabel_countdownTime:stopAllActions()
	--     local aniNode = Panel_countdown:getChildByName('AniTimeCount' .. i)
	--     if not aniNode then
	--         ccs.ArmatureDataManager:getInstance():addArmatureFileInfo("game/wanjiachupaitishi/wanjiachupaitishi.ExportJson")
	--         local waitArmature = ccs.Armature:create("wanjiachupaitishi")
	--         waitArmature:getAnimation():playWithIndex(0)
	--         Panel_countdown:addChild(waitArmature)
	--         waitArmature:setName('AniTimeCount' .. i)
	--     end
	-- end
	for i = 1, 4 do
		local Panel_player = ccui.Helper:seekWidgetByName(self.root, string.format("Panel_player%d", i))
		local Panel_countdown = Panel_player:getChildByName("Panel_countdown")
		Panel_countdown:removeAllChildren()
	end
end

function TableLayer:EVENT_TYPE_SIGNAL(event)
	local time = event._usedata
	local uiImage_signal = ccui.Helper:seekWidgetByName(self.root, "Image_signal")
	local uiText_signal = ccui.Helper:seekWidgetByName(self.root, "Text_signal")
	if GameCommon.tableConfig.nTableType ~= TableType_Playback then
		if time <= 100 then
			uiImage_signal:loadTexture("common/xinghao4.png")
			uiText_signal:setColor(cc.c3b(140, 255, 25))
		elseif time <= 200 then
			uiImage_signal:loadTexture("common/xinghao3.png")
			uiText_signal:setColor(cc.c3b(219, 255, 0))
		elseif time <= 300 then
			uiImage_signal:loadTexture("common/xinghao2.png")
			uiText_signal:setColor(cc.c3b(255, 191, 0))
		else
			uiImage_signal:loadTexture("common/xinghao1.png")
			uiText_signal:setColor(cc.c3b(255, 0, 20))
		end
		if time < 0 then
			uiText_signal:setString("")
		else
			uiText_signal:setString(string.format("%dms", time))
		end
	else
		uiImage_signal:setVisible(false)
	end
end

function TableLayer:EVENT_TYPE_ELECTRICITY(event)
	local data = event._usedata
	local Image_Electricity = ccui.Helper:seekWidgetByName(self.root, "Image_Electricity")
	local Text_eleNum = ccui.Helper:seekWidgetByName(self.root, "Text_eleNum")
	if data >= 1 then
		Image_Electricity:loadTexture('cdzipai/ui/icon_dianliang_1.png')
	elseif data > 0.4 then
		Image_Electricity:loadTexture('cdzipai/ui/icon_dianliang_2.png')
	elseif data > 0.1 then
		Image_Electricity:loadTexture('cdzipai/ui/icon_dianliang_3.png')
	else
		Image_Electricity:loadTexture('cdzipai/ui/icon_dianliang_4.png')
	end
	Text_eleNum:setString(data * 100 .. '%')
end

--[
-- @brief  重连手牌位置还原
-- @param  srcInfo 服务器手牌数据
-- @param  cacheInfo 客户端缓冲手牌数据
-- @return 比对校验后手牌数据
--]
function TableLayer:reconnetCardInfoReset(srcInfo, cacheInfo)
	--查找原数据是否在选择表中，存在就从选择表中移除并返回ture，否则返回false
	local tempInfo = clone(cacheInfo)
	local function findCardResult(srcCard, controlTbl)
		for i, v in ipairs(controlTbl) do
			for idx, card in ipairs(v.cbCardData) do
				if srcCard.data == card.data then
					if v.nCardCount > 1 then
						table.remove(v.cbCardData, idx)
						v.nCardCount = v.nCardCount - 1
					else
						table.remove(controlTbl, i)
					end
					return true
				end
			end
		end
		return false
	end
	
	--服务端数据与缓冲数据比对
	for _, v in pairs(srcInfo) do
		for __, card in pairs(v.cbCardData) do
			local isFinded = findCardResult(card, tempInfo)
			if not isFinded then
				local cardinfo = {}
				cardinfo.nCardCount = 1
				cardinfo.cbCardData = {}
				table.insert(cardinfo.cbCardData, card)
				table.insert(cacheInfo, cardinfo)
				dump(cardinfo, 'AddToCacheHandCard::')
			end
		end
	end
	dump(tempInfo, 'ControlLastHandCard::')
	
	--移除缓存里在原数据中不存在的数据
	for _, v in pairs(tempInfo) do
		for __, card in pairs(v.cbCardData) do
			local isFinded = findCardResult(card, cacheInfo)
			if not isFinded then
				printError('tempInfo data no exist in cacheInfo')
			else
				dump(card, 'RemoveCacheHandCard::')
			end
		end
	end
	
	return cacheInfo
end

function TableLayer:getViewWorldPosByChairID(wChairID)
	for key, var in pairs(GameCommon.player) do
		if wChairID == var.wChairID then
			local viewid = GameCommon:getViewIDByChairID(var.wChairID, true)
			local uiPanel_player = ccui.Helper:seekWidgetByName(self.root, string.format("Panel_player%d", viewid))
			local uiImage_avatar = ccui.Helper:seekWidgetByName(uiPanel_player, "Image_avatar")
			return uiImage_avatar:getParent():convertToWorldSpace(cc.p(uiImage_avatar:getPosition()))
		end
	end
end

function TableLayer:getChairIDByUserID(dwUserID)
	for key, var in pairs(GameCommon.player) do
		if dwUserID == var.dwUserID then
			return var.wChairID
		end
	end
end

function TableLayer:openBox(params)
	local path = self:requireClass('CDNoticeBox')
	local box = require("app.MyApp"):create(params):createGame(path)
	self:addChild(box)
end

function TableLayer:requireClass(name)
	local path = string.format("game.%s.%s", APPNAME, name)
	return path
end

function TableLayer:isStartGame(...)
	return GameCommon.gameState == GameCommon.GameState_Start
end

function TableLayer:refreshTableInfo()
	local playerNum = 0
	for k, v in pairs(GameCommon.player or {}) do
		playerNum = playerNum + 1
	end
	local Button_Invitation = ccui.Helper:seekWidgetByName(self.root, "Button_Invitation")
	local Button_copy = ccui.Helper:seekWidgetByName(self.root, "Button_copy")
	if playerNum >= GameCommon.gameConfig.bPlayerCount or StaticData.Hide[CHANNEL_ID].btn4 ~= 1 then
		Button_Invitation:setVisible(false)
		Button_copy:setVisible(false)
		self:setDistanceWarning()
	else
		Button_Invitation:setVisible(true)
		Button_copy:setVisible(true)
	end
	
	if GameCommon.player[0] then
		local viewID = GameCommon:getViewIDByChairID(GameCommon.player[0].wChairID, true)
		local uiPanel_player = ccui.Helper:seekWidgetByName(self.root, string.format("Panel_player%d", viewID))
		local Image_owner = ccui.Helper:seekWidgetByName(uiPanel_player, "Image_owner")
		Image_owner:setVisible(true)
	end
	
	self:refreshTablePos()
end

function TableLayer:refreshTablePos()
	local Panel_btnPos = ccui.Helper:seekWidgetByName(self.root, "Panel_btnPos")
	local nodeArr = Panel_btnPos:getChildren()
	local visibleTbl = {}
	for i, v in ipairs(nodeArr) do
		if v:isVisible() then
			table.insert(visibleTbl, v)
		end
	end
	
	local size = Panel_btnPos:getContentSize()
	if #visibleTbl == 1 then
		visibleTbl[1]:setPositionX(size.width * 0.5)
	elseif #visibleTbl == 2 then
		visibleTbl[1]:setPositionX(size.width * 0.3)
		visibleTbl[2]:setPositionX(size.width * 0.7)
	elseif #visibleTbl == 3 then
		visibleTbl[1]:setPositionX(size.width * 0.17)
		visibleTbl[2]:setPositionX(size.width * 0.5)
		visibleTbl[3]:setPositionX(size.width * 0.83)
	end
end

function TableLayer:getPlayerheadPos(wChairID)
	local viewID = GameCommon:getViewIDByChairID(wChairID, true)
	if viewID == 1 then
		return cc.p(display.width * 0.5, 100)
	else
		local uiPanel_player = ccui.Helper:seekWidgetByName(self.root, string.format("Panel_player%d", viewID))
		local uiImage_avatar = ccui.Helper:seekWidgetByName(uiPanel_player, "Image_avatar")
		local pos = cc.p(uiImage_avatar:getPosition())
		return cc.p(uiImage_avatar:getParent():convertToWorldSpace(pos))
	end
end

function TableLayer:fourTableLayout()
	--弃牌
	local Panel_discardCard = ccui.Helper:seekWidgetByName(self.root, "Panel_discardCard")
	local size = Panel_discardCard:getContentSize()
	local Panel_discardCard1 = Panel_discardCard:getChildByName("Panel_discardCard1")
	Panel_discardCard1:setAnchorPoint(0, 0)
	Panel_discardCard1:setPosition(0, size.height * 0.165)
	
	local Panel_discardCard2 = Panel_discardCard:getChildByName("Panel_discardCard2")
	Panel_discardCard2:setAnchorPoint(0, 0)
	Panel_discardCard2:setPosition(0, size.height * 0.515)
	
	local Panel_discardCard3 = Panel_discardCard:getChildByName("Panel_discardCard3")
	Panel_discardCard3:setAnchorPoint(1, 0)
	Panel_discardCard3:setPosition(size.width, size.height * 0.515)
	
	local Panel_discardCard4 = Panel_discardCard:getChildByName("Panel_discardCard4")
	Panel_discardCard4:setAnchorPoint(1, 0)
	Panel_discardCard4:setPosition(size.width * 0.925, size.height * 0.165)
	
	--吃碰
	local Panel_weaveItemArray = ccui.Helper:seekWidgetByName(self.root, "Panel_weaveItemArray")
	local size = Panel_weaveItemArray:getContentSize()
	local Panel_weaveItemArray1 = Panel_weaveItemArray:getChildByName("Panel_weaveItemArray1")
	Panel_weaveItemArray1:setAnchorPoint(0, 0)
	Panel_weaveItemArray1:setPosition(0, size.height * 0.27)
	
	local Panel_weaveItemArray2 = Panel_weaveItemArray:getChildByName("Panel_weaveItemArray2")
	Panel_weaveItemArray2:setAnchorPoint(0, 0)
	Panel_weaveItemArray2:setPosition(0, size.height * 0.625)
	
	local Panel_weaveItemArray3 = Panel_weaveItemArray:getChildByName("Panel_weaveItemArray3")
	Panel_weaveItemArray3:setAnchorPoint(1, 0)
	Panel_weaveItemArray3:setPosition(size.width, size.height * 0.625)
	
	local Panel_weaveItemArray4 = Panel_weaveItemArray:getChildByName("Panel_weaveItemArray4")
	Panel_weaveItemArray4:setAnchorPoint(1, 0)
	Panel_weaveItemArray4:setPosition(size.width * 0.925, size.height * 0.27)
	
	--菜单按钮调整
	local Button_voice = ccui.Helper:seekWidgetByName(self.root, "Button_voice")
	local Button_expression = ccui.Helper:seekWidgetByName(self.root, "Button_expression")
	local Button_change = ccui.Helper:seekWidgetByName(self.root, "Button_change")
	Button_voice:setPosition(538.5, - 424)
	Button_expression:setPosition(538.5, - 356)
	Button_change:setPosition(538.5, - 295)
end

function TableLayer:isHandCardAllEqual(oldinfo, curinfo)
	for key, var in pairs(oldinfo) do
		for k, v in pairs(var.cbCardData) do
			if not(curinfo[key] and curinfo[key].cbCardData and curinfo[key].cbCardData[k]) then
				return false
			end
			
			if v.data ~= curinfo[key].cbCardData[k].data then
				return false
			end
		end
	end
	return true
end

--表情互动
function TableLayer:playSkelStartToEndPos(sChairID, eChairID, index)
	self.isOpen = cc.UserDefault:getInstance():getBoolForKey('CDOpenUserEffect', true)
	
	if GameCommon.meChairID == sChairID then --我发出
		if sChairID == eChairID then
			for i, v in pairs(GameCommon.player or {}) do
				if v.wChairID ~= sChairID then
					self:playSketlAnim(sChairID, v.wChairID, index)
				end
			end
		else
			self:playSketlAnim(sChairID, eChairID, index)
		end
	else
		if self.isOpen then
			if sChairID == eChairID then
				for i, v in pairs(GameCommon.player or {}) do
					if v.wChairID ~= sChairID then
						self:playSketlAnim(sChairID, v.wChairID, index)
					end
				end
			else
				self:playSketlAnim(sChairID, eChairID, index)
			end
		end
	end
	
end

function TableLayer:playSketlAnim(sChairID, eChairID, index)
	local cusNode = cc.Director:getInstance():getNotificationNode()
    if not cusNode then
    	printInfo('global_node is nil!')
    	return
    end
    local arr = cusNode:getChildren()
    for i,v in ipairs(arr) do
        v:setVisible(false)
    end

	local Animation = require("game.cdphz.Animation")
	local AnimCnf = Animation[22]
	
	if not AnimCnf[index] then
		return
	end
	
	local spos = self:getViewWorldPosByChairID(sChairID)
	local epos = self:getViewWorldPosByChairID(eChairID)
	local image = ccui.ImageView:create(AnimCnf[index].imageFile .. '.png')
	self:addChild(image)
	image:setPosition(spos)
	local moveto = cc.MoveTo:create(0.6, cc.p(epos))
	local callfunc = cc.CallFunc:create(function()
		local path = AnimCnf[index].animFile
		local skeletonNode = cusNode:getChildByName('cdhudong_' .. index)
		if not skeletonNode then
			skeletonNode = sp.SkeletonAnimation:create(path .. '.json', path .. '.atlas', 1)
			cusNode:addChild(skeletonNode)
			skeletonNode:setName('cdhudong_' .. index)
		end
		skeletonNode:setPosition(epos)
		skeletonNode:setAnimation(0, AnimCnf[index].animName, false)
		skeletonNode:setVisible(true)
		image:removeFromParent()

		skeletonNode:registerSpineEventHandler(function(event)
			skeletonNode:setVisible(false)
		end, sp.EventType.ANIMATION_END)
		
		local soundData = AnimCnf[index]
		local soundFile = ''
		if soundData then
			local sound = soundData.sound
			if sound then
				soundFile = sound[0]
			end
		end
		
		if soundFile ~= "" then
			require("common.Common"):playEffect(soundFile)
		end
	end)
	image:runAction(cc.Sequence:create(moveto, callfunc))
end

function TableLayer:setDisMissData(data)
	GameCommon.disMissData = data
end

function TableLayer:setDistanceWarning()
	if GameCommon.gameConfig.bPlayerCount == 2 or GameCommon.gameState == GameCommon.GameState_Start then
		return
	end
	
	--距离报警  
	if not GameCommon.tableConfig.wCurrentNumber or GameCommon.tableConfig.wCurrentNumber == 0 then
		require("common.DistanceAlarm"):create(GameCommon)
	end
end

---更新
function TableLayer:updateJUshou(pBuffer)
	if not pBuffer then
		return
	end
	local Button_jushou = ccui.Helper:seekWidgetByName(self.root, "Button_jushou")
	Button_jushou:setVisible(false)
	local Button_quxiao = ccui.Helper:seekWidgetByName(self.root, "Button_quxiao")
	Button_quxiao:setVisible(false)
	for key, var in pairs(GameCommon.player) do
		local viewid = GameCommon:getViewIDByChairID(var.wChairID, true)
		local state = pBuffer.bJuShouZuoSheng[var.wChairID]
		local uiPanel_player = ccui.Helper:seekWidgetByName(self.root, string.format("Panel_player%d", viewid))
		local Image_jushou = ccui.Helper:seekWidgetByName(uiPanel_player, "Image_jushou")
		
		if state == 0 then --不可举手
			Image_jushou:setVisible(false)
		elseif state == 1 then --可举手
			if GameCommon.meChairID == var.wChairID then
				Button_jushou:setVisible(true)
				Button_quxiao:setVisible(true)
			end
			Image_jushou:setVisible(false)
		elseif state == 2 then --2已经举手
			Image_jushou:setVisible(true)
		end
	end
end

---------听牌操作----------
function TableLayer:setOutCardTPTips(pBuffer)
	local Image_tp = ccui.Helper:seekWidgetByName(self.root, "Image_tp")
	if not IsOpenTin then
		Image_tp:setVisible(false)
		return
	end

	if not pBuffer then
		Image_tp:setVisible(false)
		return
	end
	
	if pBuffer.isTingCard then
		self:setTPView(pBuffer)
	else
		Image_tp:setVisible(false)
	end

	if pBuffer.cbCardData == 0 then
		self.normolTPData = pBuffer
	end
	dump(pBuffer)

	if type(self.cotrolCardTPData) == 'table' then
		self.cotrolCardTPData[pBuffer.cbCardData] = pBuffer
	end
end

function TableLayer:setTPView(data)
	local Image_tp = ccui.Helper:seekWidgetByName(self.root, "Image_tp")
	local Image_tpFrame = Image_tp:getChildByName('Image_tpFrame')
	Image_tp:setVisible(true)
	Image_tpFrame:removeAllChildren()
	local tpNum = data.cbTingCount
	local row = math.ceil(tpNum / 3)
	Image_tpFrame:setContentSize(Image_tpFrame:getContentSize().width, 50 +(row - 1) * 50)
	
	local index = 0
	for key, var in pairs(data.cbCardIndexTing) do
		if var > 0 then
			index = index + 1
			local card = nil
			if key <= 10 then
				card = ccui.ImageView:create(string.format("cdzipai/card/listencard_%ds.png", key))
			else
				card = ccui.ImageView:create(string.format("cdzipai/card/listencard_%db.png", key - 10))
			end
			local size = Image_tpFrame:getContentSize()
			local row = math.ceil(index / 3)
			local col = index % 3
			if col == 0 then
				col = 3
			end
			Image_tpFrame:addChild(card)
			local x = size.width * 0.2 +(col - 1) * size.width * 0.3
			local y = size.height - 25 -(row - 1) * 50
			card:setPosition(x, y)
		end
	end
end

function TableLayer:setTPDataToCotrol(data)
	-- local Image_tp = ccui.Helper:seekWidgetByName(self.root, "Image_tp")
	-- local Image_tpFrame = Image_tp:getChildByName('Image_tpFrame')
	-- if not IsOpenTin then
	-- 	Image_tp:setVisible(false)
	-- 	return
	-- end
	
	-- if type(self.cotrolCardTPData) ~= 'table' then
	-- 	return
	-- end
	
	-- if not data then
	-- 	Image_tp:setVisible(false)
	-- 	return
	-- end
	
	-- local pBuffer = self.cotrolCardTPData
	-- if pBuffer.isTingCard then
	-- 	for k, v in pairs(pBuffer.stuTingCardInfo) do
	-- 		if v.isTingCard and GameLogic:SwitchToCardIndex(data) == k then
	-- 			self:setTPView(v)
	-- 			break
	-- 		end
	-- 	end
	-- else
	-- 	Image_tp:setVisible(false)
	-- end
end

function TableLayer:saveCotrolCardTPData(pBuffer)
	-- self.cotrolCardTPData = pBuffer
	-- local Image_tp = ccui.Helper:seekWidgetByName(self.root, "Image_tp")
	-- Image_tp:setVisible(false)
end


function TableLayer:setTablePlayWayInfo()
	local Text_node = GameCommon:seekWidgetByNameEx(self.root, "Text_node")
	Text_node:setTextHorizontalAlignment(cc.TEXT_ALIGNMENT_CENTER)

	if GameCommon.tableConfig.nTableType == TableType_GoldRoom then
		if GameCommon.tableConfig.cbLevel == 2 then
			Text_node:setString(string.format("中级场 倍率 %d",GameCommon.tableConfig.wCellScore))
		elseif GameCommon.tableConfig.cbLevel == 3 then
			Text_node:setString(string.format("高级场 倍率 %d",GameCommon.tableConfig.wCellScore))
		else
			Text_node:setString(string.format("初级场 倍率 %d",GameCommon.tableConfig.wCellScore))
		end
		return
	end

	local roomId = GameCommon.tableConfig.wTbaleID or 0
	local curJuShu = GameCommon.tableConfig.wCurrentNumber or 0
	local maxJuShu = GameCommon.tableConfig.wTableNumber or 0
	local playwayDes = GameDesc:getGameDesc(GameCommon.tableConfig.wKindID, GameCommon.gameConfig, GameCommon.tableConfig)
	local playwayArr = string.split(playwayDes, "/")
	local len = #playwayArr
	if len < 1 then
		return
	end
	if GameCommon.tableConfig.nTableType == TableType_ClubRoom and GameCommon.tableConfig.dwClubID ~= 0  then
       table.remove( playwayArr, 1)
	end 
	
	local des = ""
	if not (roomId == 0 or maxJuShu == 0) then
		des = string.format("房间:%d 第%d/%d局", roomId, curJuShu, maxJuShu)
	end
	for i, v in ipairs(playwayArr) do
		if len <= 2 then
			des = des .. " " .. v
		elseif len <= 5 then
			if i == 1 then
				des = des .. "\n" .. v
			else
				des = des .. " " .. v
			end
		elseif len <= 8 then
			if i == len - 5 then
				des = des .. " " .. v .. "\n"
			else
				des = des .. " " .. v
			end
		else
			if i == 1 then
				des = des .. " " .. v .. "\n"
			elseif i <= 6 then
				if i == 6 then
					des = des .. " " .. v .. "\n"
				else
					des = des .. " " .. v
				end
			else
				des = des .. " " .. v
			end
		end
	end
	if GameCommon.tableConfig.nTableType == TableType_ClubRoom and GameCommon.tableConfig.dwClubID ~= 0  then
		des = des.."\n"..string.format("(亲友圈[%d])",GameCommon.tableConfig.dwClubID)
	 end 
	Text_node:setString(des)
end


------------------------------------------
--听牌检查
------------------------------------------
local function getPlayerHuXi(wChairID)
	local huXiCount = 0
	local viewID = GameCommon:getViewIDByChairID(wChairID)
	if GameCommon.player[wChairID].WeaveItemArray ~= nil then
		for key, var in pairs(GameCommon.player[wChairID].WeaveItemArray) do	
			if(var.cbWeaveKind == GameCommon.ACK_TI and GameCommon.tiCardType == 1 and wChairID ~= GameCommon:getRoleChairID()) or
			(var.cbWeaveKind == GameCommon.ACK_WEI and GameCommon.weiCardType == 1 and wChairID ~= GameCommon:getRoleChairID()) then
				
			else
				huXiCount = huXiCount + GameLogic:GetWeaveHuXi(var)
			end
		end
	end
	return huXiCount
end

local function EstimatePoPaoHuCardInfo(wCurrentUser, cbCardIndex, cbCenterCard)
	--不能跑胡
	if cbCenterCard == 0 then	
		return false 
	end

	if GameLogic:IsValidCard(cbCenterCard) == false then 
		return false
	end

	--跑提计算
	local cbTiPaoCount = 0
	for i=1, GameCommon.player[wCurrentUser].bWeaveItemCount do
		if GameCommon.player[wCurrentUser].WeaveItemArray[i].cbCardCount == 4 then 
			cbTiPaoCount = cbTiPaoCount + 1
		end
	end

	if cbTiPaoCount >= 1 then
		return false
	end
	
	local i = wCurrentUser
	local bUserHuXiCount = 0
	local tempWeaveItemCount = GameCommon.player[i].bWeaveItemCount				--组合数目
	local tempWeaveItemArray = clone(GameCommon.player[i].WeaveItemArray)	--组合扑克
	local cbCardIndexTemp = clone(cbCardIndex)

	--桌面定义
	for cbIndex=1, tempWeaveItemCount do
		--变量定义
		local cbWeaveKind=tempWeaveItemArray[cbIndex].cbWeaveKind
		local cbWeaveCard=tempWeaveItemArray[cbIndex].cbCardList[1]

		--转换判断
		local bChangeWeave=false
		if cbCenterCard==cbWeaveCard then
			if cbWeaveKind==GameCommon.ACK_WEI then
				bChangeWeave=true
			elseif cbWeaveKind==GameCommon.ACK_PENG then
				bChangeWeave=true
			end
		end

		if bChangeWeave then 
			--设置组合
			tempWeaveItemArray[cbIndex].cbCardCount=4
			tempWeaveItemArray[cbIndex].cbWeaveKind=GameCommon.ACK_PAO
			tempWeaveItemArray[cbIndex].cbCardList[4]=cbCenterCard

			--胡息计算
			local bUserHuXiCount=0
			for j=1,tempWeaveItemCount do
				bUserHuXiCount = bUserHuXiCount + GameLogic:GetWeaveHuXi(tempWeaveItemArray[j])
			end

			--用牌值为0去判断是否可以胡牌
			local isBool, HuCardInfo = GameLogic:GetHuCardInfo(cbCardIndexTemp,0,bUserHuXiCount)
			if isBool then
				if HuCardInfo.cbCardEye ~= 0 then
					return true
				end
			end
		end
	end

	--手跑胡判断
	if GameLogic:IsTiPaoCard(cbCardIndexTemp,cbCenterCard) then
		--变量定义
		local cbRemoveIndex=GameLogic:SwitchToCardIndex(cbCenterCard)
		local cbRemoveCount=cbCardIndexTemp[cbRemoveIndex]

		--删除扑克
		cbCardIndexTemp[cbRemoveIndex]=0

		--设置组合
		local cbIndex=tempWeaveItemCount + 1
		tempWeaveItemArray[cbIndex] = tempWeaveItemArray[cbIndex] or {}
		tempWeaveItemArray[cbIndex].cbCardList = tempWeaveItemArray[cbIndex].cbCardList or {}
		tempWeaveItemArray[cbIndex].cbCardCount=4
		tempWeaveItemArray[cbIndex].cbWeaveKind=GameLogic.ACK_PAO
		tempWeaveItemArray[cbIndex].cbCenterCard=cbCenterCard
		tempWeaveItemArray[cbIndex].cbCardList[1]=cbCenterCard
		tempWeaveItemArray[cbIndex].cbCardList[2]=cbCenterCard
		tempWeaveItemArray[cbIndex].cbCardList[3]=cbCenterCard
		tempWeaveItemArray[cbIndex].cbCardList[4]=cbCenterCard

		--胡息计算
		local bUserHuXiCount=0
		for j=1,tempWeaveItemCount do
			bUserHuXiCount = bUserHuXiCount + GameLogic:GetWeaveHuXi(tempWeaveItemArray[j])
		end

		-- 用牌值为0去判断是否可以胡牌
		local isBool, HuCardInfo = GameLogic:GetHuCardInfo(cbCardIndexTemp,0,bUserHuXiCount)
		if isBool then
			if HuCardInfo.cbCardEye ~=0 then
				return true
			end
		end
	end

	return false
end

function TableLayer:TingCardCheck(wChairID, cbCardIndex, coroutine)
	local stuTingCardInfo = {}
	stuTingCardInfo.cbCardData = 0
	stuTingCardInfo.isTingCard = false
	stuTingCardInfo.cbTingCount = 0
	stuTingCardInfo.cbCardIndexTing = {}
	
	if wChairID >= 65535 then
		return stuTingCardInfo
	end
	if GameCommon.tableConfig.nTableType == TableType_GoldRoom or GameCommon.tableConfig.nTableType == TableType_SportsRoom then
		return stuTingCardInfo
	end
	if GameCommon.bIsSiShou then
		return stuTingCardInfo
	end
	if GameCommon.bIsOutCardTips then
		printInfo('===============cur_out_card tips============')
		GameCommon.bIsOutCardTips = false
		return stuTingCardInfo
	end

	local cbCardIndexTemp = clone(cbCardIndex)
	local tempWeaveItemCount = GameCommon.player[wChairID].bWeaveItemCount
	local tempWeaveItemArray = clone(GameCommon.player[wChairID].WeaveItemArray)

	local bUserHuXiCountModify = 0
	local cbCardIndexModify = {}
	local WeaveItemCountModify = 0
	local WeaveItemArrayModify = {}

	local weiCardType = 1
	local tiCardType = 0
	GameCommon.DGCS = 0
	local timew= 0
	for i =1,GameCommon.MAX_INDEX do
		if GameLogic:GetHuCardInfoData(wChairID,cbCardIndex,i) then
			local nSurplusCount = 4
			if nSurplusCount <= 0 then
				nSurplusCount = -1
			end
			stuTingCardInfo.cbCardIndexTing[i] = nSurplusCount
			if nSurplusCount > 0 then
				stuTingCardInfo.isTingCard = true
				stuTingCardInfo.cbTingCount = stuTingCardInfo.cbTingCount + 1
			end
		end
		coroutine.yield()
		print('coroutine is yield count = ', i)
	end
	return stuTingCardInfo
end

function TableLayer:isCheckTingCard(wChairID, isReconnect)
	local IsOpenTin = cc.UserDefault:getInstance():getBoolForKey('CDisOpenTin', true)
	if not IsOpenTin then
		return false
	end

	if wChairID ~= GameCommon:getRoleChairID() and not isReconnect then
		return false
	end

	return true
end

function TableLayer:showTingCard(cbCardData, stuTingCardInfo)
	if cbCardData then
		stuTingCardInfo.cbCardData = cbCardData
	end
	self:setOutCardTPTips(stuTingCardInfo)
end

-------------------------------
--听牌提示入口
-------------------------------
function TableLayer:checkTPShowTips(wChairID, cbCardIndex, cbCardData, isReconnect)
	if IsUseNewTP then
		return
	end

    local thread_i = coroutine.create(function()
    	--1
		print('coroutine do count 1')
		local isCheck = self:isCheckTingCard(wChairID, isReconnect)
		if not isCheck then
			return
		end
        coroutine.yield()

        --2
        print('coroutine do count 2')
        local stuTingCardInfo = self:TingCardCheck(wChairID, cbCardIndex, coroutine)
		dump(stuTingCardInfo, 'TingCardCheck::')

        --3
        print('coroutine do count 3')
        self:showTingCard(cbCardData, stuTingCardInfo)
        coroutine.yield()
    end)

    local node = ccui.Helper:seekWidgetByName(self.root, "Image_tp")
    local callback = function()
        if coroutine.status(thread_i) == 'dead' then
            print('coroutine thread is deaded!')
            node:stopAllActions()
        end
        coroutine.resume(thread_i)
    end
    node:stopAllActions()
    schedule(node, callback, 0.03)
end


--邀请在线好友
function TableLayer:pleaseOnlinePlayer()
	local dwClubID = GameCommon.tableConfig.dwClubID
	require("common.SceneMgr"):switchOperation(require("app.MyApp"):create(dwClubID):createView("PleaseOnlinePlayerLayer"))
end


----------------------------------
-- 新听牌提示(server versers)
----------------------------------
function TableLayer:showTingPaiTips(pBuffer, isDragType)
	dump(pBuffer, 'TPData::')
	print(isDragType)

	if not IsUseNewTP then
		return
	end

	local Image_tp = ccui.Helper:seekWidgetByName(self.root, "Image_tp")
	if not pBuffer then
		Image_tp:setVisible(false)
		return
	end

	if not IsOpenTin then
		Image_tp:setVisible(false)
		return
	end

	if pBuffer.cbCardCount ~= 0 then
		self:showTPSmallCard(pBuffer)
		if not isDragType then
			self.dragTPData = nil
		end
	else
		Image_tp:setVisible(false)
	end
end

function TableLayer:showTPSmallCard(data)
	local Image_tp = ccui.Helper:seekWidgetByName(self.root, "Image_tp")
	local Image_tpFrame = Image_tp:getChildByName('Image_tpFrame')
	Image_tp:setVisible(true)
	Image_tpFrame:removeAllChildren()
	local tpNum = data.cbCardCount
	local row = math.ceil(tpNum / 3)
	Image_tpFrame:setContentSize(Image_tpFrame:getContentSize().width, 50 +(row - 1) * 50)
	
	local index = 0
	for key, var in pairs(data.cbCardIndex) do
		if var > 0 then
			index = index + 1
			local card = nil
			if key <= 10 then
				card = ccui.ImageView:create(string.format("cdzipai/card/listencard_%ds.png", key))
			else
				card = ccui.ImageView:create(string.format("cdzipai/card/listencard_%db.png", key - 10))
			end
			local size = Image_tpFrame:getContentSize()
			local row = math.ceil(index / 3)
			local col = index % 3
			if col == 0 then
				col = 3
			end
			Image_tpFrame:addChild(card)
			local x = size.width * 0.2 +(col - 1) * size.width * 0.3
			local y = size.height - 25 -(row - 1) * 50
			card:setPosition(x, y)
		end
	end
end

function TableLayer:saveDragTPData(pBuffer)
	dump(pBuffer, 'DragTPData::')
	if not (IsUseNewTP and IsOpenTin) then
		return
	end

	self.dragTPData = pBuffer
	local Image_tp = ccui.Helper:seekWidgetByName(self.root, "Image_tp")
	Image_tp:setVisible(false)
	self:showHandCard(GameCommon:getRoleChairID(), 2)
end

function TableLayer:showDragTPTips(value)
	if not (IsUseNewTP and IsOpenTin) then
		return
	end

	local valueIdx = GameLogic:SwitchToCardIndex(value)
	printInfo('Show Drag Card Data = %d, CardIdx = %d', value, valueIdx)
	if self.dragTPData then
		local valcount = self.dragTPData.cbCardIndex[valueIdx]
		if valcount and valcount > 0 then
			self:showTingPaiTips(self.dragTPData.tTingCard[valueIdx], true)
		end
	end
end

function TableLayer:hideDragTPTips(value)
	if not (IsUseNewTP and IsOpenTin) then
		return
	end

	local valueIdx = GameLogic:SwitchToCardIndex(value)
	printInfo('Hide Drag Card Data = %d, CardIdx = %d', value, valueIdx)
	if self.dragTPData then
		local valcount = self.dragTPData.cbCardIndex[valueIdx]
		if valcount and valcount > 0 then
			local Image_tp = ccui.Helper:seekWidgetByName(self.root, "Image_tp")
			Image_tp:setVisible(false)
		end
	end
end

function TableLayer:setTPCardFlag(card, value)
	if not IsUseNewTP then
		return
	end

	local valueIdx = GameLogic:SwitchToCardIndex(value)
	printInfo('value=%d, valueIdx=%d',value, valueIdx)
	if self.dragTPData and self.dragTPData.cbCardIndex[valueIdx] > 0 and IsOpenTin then
		dump(self.dragTPData.cbCardIndex)
		local flagNode = ccui.ImageView:create('common/ting.png')
		card:addChild(flagNode)
		flagNode:setName('tp_card_flag')
		local size = card:getContentSize()
		flagNode:setPosition(size.width * 0.2, size.height * 0.81)
	else
		local flagNode = card:getChildByName('tp_card_flag')
		if flagNode then
			flagNode:removeFromParent()
		end
	end
end


return TableLayer 