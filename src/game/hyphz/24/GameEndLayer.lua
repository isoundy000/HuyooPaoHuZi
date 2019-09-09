local GameCommon = require("game.hyphz.GameCommon")
local EventType = require("common.EventType")
local EventMgr = require("common.EventMgr")
local NetMgr = require("common.NetMgr")
local NetMsgId = require("common.NetMsgId")
local Bit = require("common.Bit")
local StaticData = require("app.static.StaticData")
local Common = require("common.Common")
local GameLogic = require("game.hyphz.GameLogic")
local UserData = require("app.user.UserData")
local Base64 = require("common.Base64")

local GameEndLayer = class("GameEndLayer", function()
	return ccui.Layout:create()
end)


--位置设置
local Pos = {
	[2] = {
		cc.p(147.80, 380.60),
		cc.p(147.80, 111.19),
	},
	[3] = {
		cc.p(147.80, 380.60),
		cc.p(147.80, 111.19),
		cc.p(452.01, 111.19),
	},
	[4] = {
		cc.p(147.80, 380.60),
		cc.p(147.80, 111.19),
		cc.p(452.01, 111.19),
		cc.p(759.56, 111.19),
	}
}

function GameEndLayer:create(pBuffer)
	local view = GameEndLayer.new()
	view:onCreate(pBuffer)
	local function onEventHandler(eventType)
		if eventType == "enter" then
			view:onEnter()
		elseif eventType == "exit" then
			view:onExit()
		elseif eventType == "cleanup" then
			view:onCleanup()
		end
	end
	view:registerScriptHandler(onEventHandler)
	return view
end

function GameEndLayer:onEnter()
	EventMgr:registListener(EventType.SUB_GR_MATCH_TABLE_FAILED, self, self.SUB_GR_MATCH_TABLE_FAILED)
	EventMgr:registListener(EventType.CUS_GAMEENDlAYER_CLIENT,self,self.CUS_GAMEENDlAYER_CLIENT)

	self:runAction(cc.Sequence:create(cc.DelayTime:create(0), cc.CallFunc:create(function(sender, event)
		require("common.Common"):screenshot(FileName.battlefieldScreenshot)
	end)))
end

function GameEndLayer:onExit()
	EventMgr:unregistListener(EventType.SUB_GR_MATCH_TABLE_FAILED, self, self.SUB_GR_MATCH_TABLE_FAILED)
	EventMgr:unregistListener(EventType.CUS_GAMEENDlAYER_CLIENT,self,self.CUS_GAMEENDlAYER_CLIENT)
end

function GameEndLayer:onCleanup()
	
end

--更新人物信息
function GameEndLayer:updatePlayerInfo(pBuffer)
	local pos = Pos[GameCommon.gameConfig.bPlayerCount]
	local index = 1
	local itemCache = {}
	for i = 1, GameCommon.gameConfig.bPlayerCount do
		local item = self.playerInfo_template:clone()
		self.panel_look:addChild(item)
		itemCache[i] = item
		item:setPosition(pos[i])
	end
	
	local index = 2
	for key, var in pairs(GameCommon.player) do
		local item = nil
		if var.wChairID == pBuffer.wWinUser then --赢家
			item = itemCache[1]
			local dwGold = Common:itemNumberToString(pBuffer.lGameScore[var.wChairID + 1])   
			self.text_total:setString('共计:' ..tostring(dwGold))
		else
			item = itemCache[index]
			index = index + 1
		end
		local avatar = ccui.Helper:seekWidgetByName(item, "Image_avatar")
		Common:requestUserAvatar(var.dwUserID, var.szPto, avatar, 'img')
		local Image_zhuang = ccui.Helper:seekWidgetByName(item, "Image_zhuang")
		local isZhuang = var.wChairID == GameCommon.wBankerUser
		Image_zhuang:setVisible(isZhuang)
		local name = ccui.Helper:seekWidgetByName(item, "Text_name")	
		name:setString(var.szNickName)
		self:setTextColor(name)
		local score = ccui.Helper:seekWidgetByName(item, "Text_score")
		self:setTextColor(score)
		if pBuffer.lGameScore[var.wChairID + 1] < 0 then 			
			local dwGold = Common:itemNumberToString(pBuffer.lGameScore[var.wChairID + 1])   
			score:setString(tostring(dwGold))
		else
			if pBuffer.lGameScore[var.wChairID + 1] == 0 then
				score:setString(0)
			else
				local dwGold = Common:itemNumberToString(pBuffer.lGameScore[var.wChairID + 1])   
				score:setString('+' ..tostring(dwGold))
			end
		end
	end
end

--更新结算信息
function GameEndLayer:updateEndInfo(pBuffer)
	--胡息
	local huxi = string.format("胡息:%d", pBuffer.HuCardInfo.cbHuXiCount)
	self:insertInfo(huxi)
	
	--囤数
	local tunshu = string.format("囤数:%d", pBuffer.wTun)
	self:insertInfo(tunshu)
end

function GameEndLayer:insertInfo(des)
	local list = nil
	local count = self.listview_info:getChildrenCount()
	if count <= 4 then
		list = self.listview_info
	else
		list = self.listview_player
	end
	local item = self.content_template:clone()
	item:setVisible(true)
	local text = item:getChildByName('des')
	self:setTextColor(text)
	text:setString(des)
	list:pushBackCustomItem(item)
end

function GameEndLayer:onCreate(pBuffer)
	local csb = cc.CSLoader:createNode("HYGameLayerZiPai_End.csb")
	self:addChild(csb)
	self.root = csb:getChildByName("Panel_root")
	
	self.playerInfo_template = ccui.Helper:seekWidgetByName(self.root, 'panel_playerInfo') --模板
	
	self.content_template = ccui.Helper:seekWidgetByName(self.root, 'content_template')
	self.content_template:setVisible(false)
	
	self.listview_info = ccui.Helper:seekWidgetByName(self.root, 'ListView_info')
	
	self.listview_player = ccui.Helper:seekWidgetByName(self.root, 'ListView_player')
	
	self.image_show = ccui.Helper:seekWidgetByName(self.root, 'image_show')
	self.image_show:setVisible(false)
	self.Panel_fanxing = ccui.Helper:seekWidgetByName(self.root, 'Panel_fanxing')
	self.Panel_fanxing:setVisible(false)
	self.text_total = ccui.Helper:seekWidgetByName(self.root, 'Text_total')
	
	local uiButton_return = ccui.Helper:seekWidgetByName(self.root, "Button_dissolve")
	uiButton_return:setPressedActionEnabled(true)
	local function onEventReturn(sender, event)
		if event == ccui.TouchEventType.ended then
			Common:palyButton()
			NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER, NetMsgId.REQ_GR_DISMISS_TABLE, "")
		end
	end
	uiButton_return:addTouchEventListener(onEventReturn)
	local uiButton_continue = ccui.Helper:seekWidgetByName(self.root, "Button_continue")
	uiButton_continue:setPressedActionEnabled(true)
	local function onEventContinue(sender, event)
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
	uiButton_continue:addTouchEventListener(onEventContinue)

	------------结束
	local isPlayBack = GameCommon.tableConfig.nTableType == TableType_Playback
	local button_exit = ccui.Helper:seekWidgetByName(self.root, "Button_exit")
	button_exit:setPressedActionEnabled(true)
	local function onExitEnd(sender, event)
		if event == ccui.TouchEventType.ended then
			Common:palyButton()
			require("common.SceneMgr"):switchScene(require("app.MyApp"):create():createView("HallLayer"), SCENE_HALL)
		end
	end
	button_exit:addTouchEventListener(onExitEnd)
	button_exit:setVisible(isPlayBack)
	uiButton_continue:setVisible(not isPlayBack)
	
	if GameCommon.iscardcark == true then
		uiButton_continue:setVisible(false)
	end
	local uiPanel_look = ccui.Helper:seekWidgetByName(self.root, "Panel_look")
	self.panel_look = uiPanel_look
	local uiButton_look = ccui.Helper:seekWidgetByName(self.root, "Button_look")
	Common:addTouchEventListener(uiButton_look, function()
		if uiPanel_look:isVisible() then
			uiPanel_look:setVisible(false)
		else
			uiPanel_look:setVisible(true)
		end
	end)
	
	local uiAtlasLabel_jb = ccui.Helper:seekWidgetByName(self.root, "AtlasLabel_jb")
	local uiImage_iconjb = ccui.Helper:seekWidgetByName(self.root, "Image_iconjb")
	uiAtlasLabel_jb:setVisible(false)
	uiImage_iconjb:setVisible(false)
	local integral = nil
	self.WPnumber = 0
	local number = 0
	--pBuffer.lGameScore[var.wChairID+1]
	for i = 1, GameCommon.gameConfig.bPlayerCount do
		if number < pBuffer.lGameScore[i] then
			number = pBuffer.lGameScore[i]
		end
		print("玩家得分", pBuffer.lGameScore[i], number)	
	end
	uiAtlasLabel_jb:setString(string.format(".%d", number))
	if GameCommon.tableConfig.nTableType ~= TableType_GoldRoom or GameCommon.iscardcark == true then
		uiImage_iconjb:loadTexture("game/game_table_score.png")
	else
		-- uiImage_iconjb:setVisible(true)
	end
	--    if pBuffer.lGameScore[i]  <= 0 then
	--            uiAtlasLabel_jb:setProperty(string.format(".%d",integral),"fonts/fonts_12.png",26,45,'.')
	--    end
	local uiPanel_result = ccui.Helper:seekWidgetByName(self.root, "Panel_result")
	local uiImage_result = ccui.Helper:seekWidgetByName(self.root, "Image_result")
	local viewID = GameCommon:getViewIDByChairID(pBuffer.wWinUser)
	local textureName = nil
	if viewID == 1 then --自己胜
		textureName = "hyphz/smallover/img_05.png"
	else
		textureName = "hyphz/smallover/img_06.png"	
	end
	local texture = cc.Director:getInstance():getTextureCache():addImage(textureName)
	uiImage_result:loadTexture(textureName)
	uiImage_result:setContentSize(texture:getContentSizeInPixels())
	
	
	self:updatePlayerInfo(pBuffer)
	
	self:updateEndInfo(pBuffer)
	
	self:showPaiXing(pBuffer)
	self:showMingTang(pBuffer)
	self:showDiPai(pBuffer)
	self:share(pBuffer)
end

function GameEndLayer:share(pBuffer)
	local uiButton_share = ccui.Helper:seekWidgetByName(self.root, "Button_share")
	uiButton_share:setPressedActionEnabled(true)
	local function onEventShare(sender, event)
		if event == ccui.TouchEventType.ended then
			Common:palyButton()
            local data = clone(UserData.Share.tableShareParameter[6])
            data.szShareImg = FileName.battlefieldScreenshot
            require("app.MyApp"):create(data):createView("ShareLayer")
		end
	end
	uiButton_share:addTouchEventListener(onEventShare)
end

function GameEndLayer:updateFanXing(name, num, data)
	self.Panel_fanxing:setVisible(true)
	
	local text = self.Panel_fanxing:getChildByName('des')
	text:setString(name)
	local numText = self.Panel_fanxing:getChildByName('num')
	numText:setString(num)
	
	local _spt = GameCommon:GetCardHand(data)
	_spt:setScale(0.5)
	self.Panel_fanxing:addChild(_spt)
	_spt:setPosition(109, 21)
end

function GameEndLayer:setTextColor(text, color)
	if text then
		text:setColor(cc.c3b(176, 74, 34))
	end
end

--显示牌型和眼牌
function GameEndLayer:showPaiXing(pBuffer)
	local uiListView_weave = ccui.Helper:seekWidgetByName(self.root, "ListView_weave")
	local uiPanel_defaultWeave = ccui.Helper:seekWidgetByName(self.root, "Panel_defaultWeave")
	uiListView_weave:removeAllChildren()
	local isAddHuPai = false
	for WeaveItemIndex = 1, pBuffer.HuCardInfo.cbWeaveCount do
		local item = uiPanel_defaultWeave:clone()

		local   WeaveItemArray= pBuffer.HuCardInfo.WeaveItemArray[WeaveItemIndex]            --组合扑克
        if not WeaveItemArray then
            break
        end
        
 

		local list_child = item:getChildByName('ListView_child')
		local WeaveItemArray = pBuffer.HuCardInfo.WeaveItemArray[WeaveItemIndex]            --组合扑克
		for i = 1, WeaveItemArray.cbCardCount do
			local data = WeaveItemArray.cbCardList[i]
			local _spt = GameCommon:GetCardHand(data)
			list_child:pushBackCustomItem(_spt)

            if data == pBuffer.cbHuCard and not isAddHuPai then --胡牌
                local di = cc.Sprite:create('hyphz/smallover/img_15.png')
				_spt:addChild(di)
				di:setScale(2)
                local size = _spt:getContentSize()
                di:setPosition(size.width / 2,size.height / 2)
                isAddHuPai = true
            end

		end
		local typeName = item:getChildByName('des')
		self:setTextColor(typeName)
		local WeaveType = self:getSptWeaveType(WeaveItemArray.cbWeaveKind)
		typeName:setString(WeaveType)
		
		local huxicout = GameLogic:GetWeaveHuXi(clone(WeaveItemArray))
		local huxiNum = item:getChildByName('num')
		self:setTextColor(huxiNum)
		huxiNum:setString(huxicout)
		local count = list_child:getChildrenCount()
		local enPosy = 20
		if count >= 4 then
			enPosy = - 20
		end
		huxiNum:setPosition(cc.p(25, enPosy))
		uiListView_weave:pushBackCustomItem(item)
	end
	--眼牌
	if pBuffer.HuCardInfo.cbWeaveCount <= 6 and pBuffer.HuCardInfo.cbCardEye ~= 0 then
		local item = uiPanel_defaultWeave:clone()
		local list_child = item:getChildByName('ListView_child')
		local typeName = item:getChildByName('des')
		self:setTextColor(typeName)
		typeName:setString('对')
		local huxiNum = item:getChildByName('num')
		self:setTextColor(huxiNum)
		huxiNum:setString(0)
		huxiNum:setPosition(cc.p(25, 20))
		for i = 0, 1 do
			local data = pBuffer.HuCardInfo.cbCardEye
			local _spt = GameCommon:GetCardHand(data)
			list_child:pushBackCustomItem(_spt)

			if data == pBuffer.cbHuCard and not isAddHuPai then --胡牌
                local di = cc.Sprite:create('hyphz/smallover/img_15.png')
				_spt:addChild(di)
				di:setScale(2)
                local size = _spt:getContentSize()
                di:setPosition(size.width / 2,size.height / 2)
                isAddHuPai = true
            end
		end
		uiListView_weave:pushBackCustomItem(item)
	end
end

--显示名堂
function GameEndLayer:showMingTang(pBuffer)
	self.PHZ_HT_ZiMo				= 1                  --自摸        类型+数量
	self.PHZ_HT_HongHu			= 2                  --红胡        >=10红牌，（多一张加一番，起番看配置/固定番数）
	self.PHZ_HT_HeiHu			= 4                  --黑胡        全黑
	self.PHZ_HT_DianHu			= 8                  --点胡        一张红
	self.PHZ_HT_HongWu			= 16                  --红乌        >=13红牌，没有红胡，多一张加一番，起番看配置
	self.PHZ_HT_DuiDuiHu			= 32                  --对对胡       没有吃牌类型，包括手牌
	self.PHZ_HT_DaZiHu			= 64                  --大字胡       >=18张大牌，多一张加一番，起番看配置
	self.PHZ_HT_XiaoZiHu			= 128                  --小字胡       >=16张小牌，多一张加一番,起番看配置
	self.PHZ_HT_HaiDiHu			= 256                 --海底胡       牌墩最后一张牌胡了
	self.PHZ_HT_DianDeng			= 512                 --点灯        
	self.PHZ_HT_DiHu				= 1024                 --地胡        庄家亮牌，闲家胡了，选了亮牌才有
	self.PHZ_HT_TianHu			= 2048                 --天胡        庄家起手胡牌
	self.PHZ_HT_HuangFan			= 4096                --黄番        上一局黄庄，这把胡了,番数X2
	self.PHZ_HT_QuanHong			= 8192                --全红        
	self.PHZ_HT_ShuaHou			= 16384                --耍猴        最后一张牌单吊
	self.PHZ_HT_TingHu			= 32768                --听胡        手牌没动过，胡息>=15
	self.PHZ_HT_WuDuiHu			= 65536               --乌对胡       对对胡+黑胡
	self.PHZ_HT_WangChuang		= 131072               --王闯        >=2个癞子，两个王钓其他的牌
	self.PHZ_HT_WangDiao			= 262144               --王钓        >=1个癞子，单吊王其他牌
	self.PHZ_HT_WangDiaoWang		= 524288               --王钓王       >=2个癞子，单王钓王
	self.PHZ_HT_WangChuangWang	= 1048576              --王闯王       >=3个癞子，双王钓到王
	self.PHZ_HT_SanWangChuang	= 2097152              --三王闯       >=3个癞子，3个王钓其他牌
	self.PHZ_HT_SangWangChuangWang = 4194304              --三王闯王      >=4个癞子，3个王钓到王
	
	-- 变量定义 
	local wHZCount = 0
	local wDZCount = 0
	local wXZCount = 0
	local bIsDDH = true
	local sdata = {
		wTun = 0,          --囤
		wType = 0,         --数据
		wFanCount = 0,      --翻
	}
	--组合牌类型
	for cbIndex = 1, pBuffer.HuCardInfo.cbWeaveCount do
		--变量定义
		local cbWeaveKind = pBuffer.HuCardInfo.WeaveItemArray[cbIndex].cbWeaveKind
		local cbWeaveCardCount = pBuffer.HuCardInfo.WeaveItemArray[cbIndex].cbCardCount
		
		--合法验证
		if cbWeaveKind ~= 0 then
			--组合内统计
			for cbCardIndex = 1, cbWeaveCardCount do
				if pBuffer.HuCardInfo.WeaveItemArray[cbIndex].cbCardList[cbCardIndex] ~= 0 then
					--红字统计
					if Bit:_and(pBuffer.HuCardInfo.WeaveItemArray[cbIndex].cbCardList[cbCardIndex], GameCommon.MASK_VALUE) == 2
					or Bit:_and(pBuffer.HuCardInfo.WeaveItemArray[cbIndex].cbCardList[cbCardIndex], GameCommon.MASK_VALUE) == 7
					or Bit:_and(pBuffer.HuCardInfo.WeaveItemArray[cbIndex].cbCardList[cbCardIndex], GameCommon.MASK_VALUE) == 10 then
						wHZCount = wHZCount + 1
					end
				end
			end
			
		end
	end
	
	for i = 1, 2 do
		if pBuffer.fanXing[i].cbShengCard ~= 0 then
			if GameCommon.gameConfig.FanXing.bType == 1 or GameCommon.gameConfig.FanXing.bType == 2 then
				local str = string.format( "%d",pBuffer.fanXing[i].cbShengCout)
				self:updateFanXing('翻省','',pBuffer.fanXing[i].cbShengCard)

			elseif GameCommon.gameConfig.FanXing.bType == 3 then

				local str = string.format( "%d",pBuffer.fanXing[i].cbShengCout)

				self:updateFanXing('跟省','',pBuffer.fanXing[i].cbShengCard)

				
			end
		end
	end
	
	
	--眼牌
	if pBuffer.HuCardInfo.cbCardEye ~= 0 then
		for i = 1, 2 do
			--大小字统计
			if Bit:_and(pBuffer.HuCardInfo.cbCardEye, GameCommon.MASK_COLOR) == 16 then
				wDZCount = wDZCount + 1
				
			else
				
				wXZCount = wXZCount + 1
			end
			--红字统计
			if Bit:_and(pBuffer.HuCardInfo.cbCardEye, GameCommon.MASK_VALUE) == 2
			or Bit:_and(pBuffer.HuCardInfo.cbCardEye, GameCommon.MASK_VALUE) == 7
			or Bit:_and(pBuffer.HuCardInfo.cbCardEye, GameCommon.MASK_VALUE) == 10 then
				
				wHZCount = wHZCount + 1
			end
		end
	end

	--飘胡
	if Bit:_and(pBuffer.wType, self.PHZ_HT_DianDeng) ~= 0 then
		local str = string.format("飘胡")
		self:insertInfo(str)
	end
	
	--自摸判断
	if Bit:_and(pBuffer.wType, self.PHZ_HT_ZiMo) ~= 0 then
		local str = string.format("自摸:%d倍", 2)
		self:insertInfo(str)
		self.image_show:setVisible(false)
		self.image_show:loadTexture('cdzipai/ui/tu.png')
		self.image_show:ignoreContentAdaptWithSize(true)
	end
	
	--红胡判断
	if Bit:_and(pBuffer.wType, self.PHZ_HT_HongHu) ~= 0 then
		if GameCommon.gameConfig.bHongHu == 1 then
			if wHZCount >= 13 then
				local str = string.format("红胡:%d番", 5)
				self:insertInfo(str)
				
				local str = string.format("胡息:%d",(wHZCount - 13) * 3)
				self:insertInfo(str)
				
			elseif wHZCount >= 10 then
				local str = string.format("红胡:%d番", 3)
				self:insertInfo(str)
				
				local str = string.format("胡息:%d",(wHZCount - 10) * 3)
				self:insertInfo(str)
			else
				local str = string.format("红胡:%d番", 3)
				self:insertInfo(str)
			end
		else
			if wHZCount >= 13 then
				local str = string.format("红胡:%d番", 5)
				self:insertInfo(str)
			elseif wHZCount >= 10 then
				local str = string.format("红胡:%d番", 3)
				self:insertInfo(str)
			else
				local str = string.format("红胡:%d番", 3)
				self:insertInfo(str)
			end
		end
	end
	
	--黑胡判断
	if Bit:_and(pBuffer.wType, self.PHZ_HT_HeiHu) ~= 0 then
		local str = string.format("黑胡:%d番", 5)
		self:insertInfo(str)
	end
	--点胡判断
	if Bit:_and(pBuffer.wType, self.PHZ_HT_DianHu) ~= 0 then
		local str = string.format("点胡:%d番", 3)
		self:insertInfo(str)
	end
	
	--天胡
	if Bit:_and(pBuffer.wType, self.PHZ_HT_TianHu) ~= 0 then
		local str = string.format("天胡:%d番", 2)
		self:insertInfo(str)
	end
	--地胡
	if Bit:_and(pBuffer.wType, self.PHZ_HT_DiHu) ~= 0 then
		local str = string.format("地胡:%d番", 2)
		self:insertInfo(str)
	end
	--海底胡
	if Bit:_and(pBuffer.wType, self.PHZ_HT_HaiDiHu) ~= 0 then
		local str = string.format("海底胡:%d番", 2)
		self:insertInfo(str)
	end
	
end

function GameEndLayer:insertInfo(des)
	local list = nil
	local count = self.listview_info:getChildrenCount()
	if count <= 4 then
		list = self.listview_info
	else
		list = self.listview_player
	end
	local item = self.content_template:clone()
	item:setVisible(true)
	local text = item:getChildByName('des')
	self:setTextColor(text)
	text:setString(des)
	list:pushBackCustomItem(item)
end

--显示底牌
function GameEndLayer:showDiPai(pBuffer)
	--1人 
	local uiListView_diPai1 = ccui.Helper:seekWidgetByName(self.root, "ListView_diPai1") 
	local uiListView_diPai2 = ccui.Helper:seekWidgetByName(self.root, "ListView_diPai2")
	for i = 1, pBuffer.bLeftCardCount do
		if pBuffer.bLeftCardDataEx[i] ~= 0 then
			local item = GameCommon:GetCardHand(pBuffer.bLeftCardDataEx[i])
			if i <= 17 then
				uiListView_diPai1:pushBackCustomItem(item)
			else
				uiListView_diPai2:pushBackCustomItem(item)
			end
		end
	end
    uiListView_diPai2:setScale(0.4)
    uiListView_diPai1:setScale(0.4)
    uiListView_diPai1:refreshView()
    uiListView_diPai2:refreshView()
end

function GameEndLayer:getSptWeaveType(type)
	local sptname = ""
	if type == GameCommon.ACK_TI then
		sptname = "提"
	elseif type == GameCommon.ACK_PAO then
		sptname = "跑"
	elseif type == GameCommon.ACK_WEI then
		sptname = "偎"
	elseif type == GameCommon.ACK_CHI then
		sptname = "吃"
	elseif type == GameCommon.ACK_PENG then
		sptname = "碰"
	else
		
	end
	return sptname
end

function GameEndLayer:SUB_GR_MATCH_TABLE_FAILED(event)
	local data = event._usedata
	require("common.SceneMgr"):switchScene(require("app.MyApp"):create():createView("HallLayer"), SCENE_HALL)
	if data.wErrorCode == 0 then
		require("common.MsgBoxLayer"):create(0, nil, "您在游戏中!")
	elseif data.wErrorCode == 1 then
		require("common.MsgBoxLayer"):create(0, nil, "游戏配置发生错误!")
	elseif data.wErrorCode == 2 then
		if StaticData.Hide[CHANNEL_ID].btn8 == 1 and StaticData.Hide[CHANNEL_ID].btn9 == 1 then
			require("common.MsgBoxLayer"):create(2, nil, "您的金币不足,请前往商城充值!", function() require("common.SceneMgr"):switchOperation(require("app.MyApp"):create(2):createView("NewMallLayer")) end)
		else
			require("common.MsgBoxLayer"):create(1, nil, "您的金币不足,请联系代理购买！", function() require("common.SceneMgr"):switchOperation(require("app.MyApp"):create():createView("GuilLayer")) end)
		end
	elseif data.wErrorCode == 3 then
		require("common.MsgBoxLayer"):create(0, nil, "您的金币已超过上限，请前往更高一级匹配!")
	elseif data.wErrorCode == 4 then
		require("common.MsgBoxLayer"):create(0, nil, "房间已满,稍后再试!")
	else
		require("common.MsgBoxLayer"):create(0, nil, "未知错误,请升级版本!")
	end
end

function GameEndLayer:CUS_GAMEENDlAYER_CLIENT(event)
	local uiPanel_look = ccui.Helper:seekWidgetByName(self.root, "Panel_look")
	uiPanel_look:setVisible(true)
end

return GameEndLayer
