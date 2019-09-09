local StaticData = require("app.static.StaticData")
local EventType = require("common.EventType")
local EventMgr = require("common.EventMgr")
local UserData = require("app.user.UserData")
local Common = require("common.Common")
local GameCommon = require("game.cdphz.GameCommon")
local Base64 = require("common.Base64")

local FriendsRoomEndLayer = class("FriendsRoomEndLayer", function()
	return ccui.Layout:create()
end)

local Location = {
	[2] = {
		cc.p(290, 74),
		cc.p(732, 74),
	},
	[3] = {
		cc.p(182, 74),
		cc.p(518, 74),
		cc.p(855, 74),
	},
	[4] = {
		cc.p(104, 74),
		cc.p(368, 74),
		cc.p(632, 74),
		cc.p(896, 74),
	}
}
local endDes = {
	[0] = '',
	[1] = '提示：该房间被房主解散',
	[2] = '提示：该房间被管理员解散',
	[3] = '提示：该房间投票解散',
	[4] = '提示：该房间因疲劳值不足被强制解散',
	[5] = '提示：该房间被官方系统强制解散',
	[6] = '提示：该房间因超时未开局被强制解散',
	[7] = '提示：该房间因超时投票解散',
}


--映射关系
local EndList = {
	[-1] = '总囤数',
	[1] = '胡牌次数',
	[2] = '黄庄次数',
	[3] = '自摸次数',
	[4] = '点炮次数',
	[5] = '提牌次数',
	[6] = '跑牌次数',
	[7] = '碰牌次数',
	[8] = '偎牌次数',
}

function FriendsRoomEndLayer:create(pBuffer)
	local view = FriendsRoomEndLayer.new()
	view:onCreate(pBuffer)
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

function FriendsRoomEndLayer:onEnter()
	--保存游戏截屏
	local uiListView_function = ccui.Helper:seekWidgetByName(self.root, "ListView_function")
	uiListView_function:setVisible(false)
	local uiButton_return = ccui.Helper:seekWidgetByName(self.root, "Button_return")
	local uiButton_share = ccui.Helper:seekWidgetByName(self.root, "Button_share")
	if StaticData.Hide[CHANNEL_ID].btn5 ~= 1 then
		uiListView_function:removeItem(uiListView_function:getIndex(uiButton_share))
	end
	uiListView_function:refreshView()
	uiListView_function:setContentSize(cc.size(uiListView_function:getInnerContainerSize().width, uiListView_function:getInnerContainerSize().height))
	uiListView_function:setPositionX(uiListView_function:getParent():getContentSize().width / 2)
	local date = os.date("*t", os.time())
	self.endTime = string.format("%d-%02d-%02d  %02d:%02d:%02d", date.year, date.month, date.day, date.hour, date.min, date.sec)
	self:runAction(cc.Sequence:create(cc.DelayTime:create(0), cc.CallFunc:create(function(sender, event)
		require("common.Common"):screenshot(FileName.battlefieldScreenshot)
	end), cc.DelayTime:create(0), cc.CallFunc:create(function()
		uiListView_function:setVisible(true)
	end)))
end

function FriendsRoomEndLayer:onExit()
	
end

function FriendsRoomEndLayer:onCreate(pBuffer)
	cc.Director:getInstance():getRunningScene():removeChildByTag(LAYER_TIPS)
	self.ShareName = string.format("%d.jpg", os.time())
	self.root = nil
	self.pBuffer = pBuffer
	local csb = cc.CSLoader:createNode("CDGameOver.csb")
	self:addChild(csb)
	self.root = csb:getChildByName("Panel_root")

	local tishi_des = ccui.Helper:seekWidgetByName(self.root,"tishi_des")
    tishi_des:setString(endDes[self.pBuffer.cbOrigin])

	self:initSetting()
	self:initVar()
	self:initDisMissValue()
	local uiButton_return = ccui.Helper:seekWidgetByName(self.root, "Button_return")
	uiButton_return:setPressedActionEnabled(true)
	local function onEventReturn(sender, event)
		if event == ccui.TouchEventType.ended then
			Common:palyButton()
			require("common.SceneMgr"):switchScene(require("app.MyApp"):create():createView("HallLayer"), SCENE_HALL)
		end
	end
	uiButton_return:addTouchEventListener(onEventReturn)
	self.ListView_end = ccui.Helper:seekWidgetByName(self.root, "ListView_end")
	self.Panel_score = ccui.Helper:seekWidgetByName(self.root, "Panel_score")
	self:updatePlayerInfo(pBuffer)
	local Button_conform = ccui.Helper:seekWidgetByName(self.root, "Button_conform")
	Button_conform:setPressedActionEnabled(true)
	local function onEventButton_conform(sender, event)
		if event == ccui.TouchEventType.ended then
			Common:palyButton()
			self.Panel_dissolve:setVisible(false)
		end
	end
	Button_conform:addTouchEventListener(onEventButton_conform)
	
	local Button_close_dissove = ccui.Helper:seekWidgetByName(self.root, "Button_close_dissove")
	Button_close_dissove:setPressedActionEnabled(true)
	Button_close_dissove:addTouchEventListener(onEventButton_conform)
	
	local dissolve_btn = ccui.Helper:seekWidgetByName(self.root, "dissolve_btn")
	dissolve_btn:setPressedActionEnabled(true)
	local function onDissolve(sender, event)
		if event == ccui.TouchEventType.ended then
			Common:palyButton()
			self:dissolve()
		end
	end
    dissolve_btn:addTouchEventListener(onDissolve)
    
     local isShow =  pBuffer.tableConfig.wCurrentNumber == pBuffer.tableConfig.wTableNumber 

    dissolve_btn:setVisible(not isShow)
	
	local setting_btn = ccui.Helper:seekWidgetByName(self.root, "setting_btn")
	setting_btn:setPressedActionEnabled(true)
	local function onSetting(sender, event)
		if event == ccui.TouchEventType.ended then
			Common:palyButton()
			self:setting()
		end
	end
	setting_btn:addTouchEventListener(onSetting)
	
	
	local Button_zhanji = ccui.Helper:seekWidgetByName(self.root, "Button_zhanji")
    Button_zhanji:setPressedActionEnabled(true)
    local function onEventHistory(sender, event)
		if event == ccui.TouchEventType.ended then
			Common:palyButton()
            local des = self:copyData()
			UserData.User:copydata(des)
			require("common.MsgBoxLayer"):create(0,nil,"复制成功")
		end
    end
    Button_zhanji:addTouchEventListener(onEventHistory)


	local uiButton_share = ccui.Helper:seekWidgetByName(self.root, "Button_share")
	uiButton_share:setPressedActionEnabled(true)
	local function onEventShare(sender, event)
		if event == ccui.TouchEventType.ended then
			Common:palyButton()
            local data = clone(UserData.Share.tableShareParameter[4])
            data.dwClubID = pBuffer.tableConfig.dwClubID
            data.szShareTitle = string.format("战绩分享-房间号:%d,局数:%d/%d",pBuffer.tableConfig.wTbaleID, pBuffer.tableConfig.wCurrentNumber, pBuffer.tableConfig.wTableNumber)
            data.szShareContent = ""
            local maxScore = 0
            for i = 1, 8 do
                if pBuffer.tScoreInfo[i].dwUserID ~= nil and pBuffer.tScoreInfo[i].dwUserID ~= 0 and pBuffer.tScoreInfo[i].totalScore > maxScore then 
                    maxScore = pBuffer.tScoreInfo[i].totalScore
                end
            end
            for i = 1, 8 do
                if pBuffer.tScoreInfo[i].dwUserID ~= nil and pBuffer.tScoreInfo[i].dwUserID ~= 0 then
                    if data.szShareContent ~= "" then
                        data.szShareContent = data.szShareContent.."\n"
                    end
                    if maxScore ~= 0 and pBuffer.tScoreInfo[i].totalScore >= maxScore then
                        data.szShareContent = data.szShareContent..string.format("【%s:%d(大赢家)】",pBuffer.tScoreInfo[i].player.szNickName,pBuffer.tScoreInfo[i].totalScore)
                    else
                        data.szShareContent = data.szShareContent..string.format("【%s:%d】",pBuffer.tScoreInfo[i].player.szNickName,pBuffer.tScoreInfo[i].totalScore)
                    end
                end
            end
            data.szShareUrl = string.format(data.szShareUrl,pBuffer.szGameID)
			data.szShareImg = FileName.battlefieldScreenshot
			data.szGameID = pBuffer.szGameID
			data.isInClub = self:isInClub(pBuffer);
            require("app.MyApp"):create(data):createView("ShareLayer")
		end
	end
	uiButton_share:addTouchEventListener(onEventShare)
	local uiText_time = ccui.Helper:seekWidgetByName(self.root, "Text_time")
	-- local function onEventRefreshTime(sender, event)
		local date = os.date("*t", os.time())
		uiText_time:setString(string.format("%d-%02d-%02d  %02d:%02d:%02d", date.year, date.month, date.day, date.hour, date.min, date.sec))
	-- 	uiText_time:runAction(cc.Sequence:create(cc.DelayTime:create(1), cc.CallFunc:create(onEventRefreshTime)))
	-- end
	-- onEventRefreshTime()
	local uiText_homeowner = ccui.Helper:seekWidgetByName(self.root, "Text_homeowner")
	uiText_homeowner:setString(string.format("房主:%s(%d)", pBuffer.szOwnerName, pBuffer.dwTableOwnerID))
	local uiText_roomInfo = ccui.Helper:seekWidgetByName(self.root, "Text_roomInfo")
	--uiText_roomInfo:setString(string.format("局数:%d/%d\n房间号:%d",pBuffer.tableConfig.wCurrentNumber,pBuffer.tableConfig.wTableNumber,pBuffer.tableConfig.wTbaleID))
	uiText_roomInfo:setString(string.format("房间号:%d", pBuffer.tableConfig.wTbaleID))
	local uiText_roomInfo1 = ccui.Helper:seekWidgetByName(self.root, "Text_roomInfo_num")
	uiText_roomInfo1:setString(string.format(string.format("局数:%d/%d", pBuffer.tableConfig.wCurrentNumber, pBuffer.tableConfig.wTableNumber)))
	local uiText_roomInfo2 = ccui.Helper:seekWidgetByName(self.root, "Text_roomInfo_name")
	uiText_roomInfo2:setString(StaticData.Games[pBuffer.tableConfig.wKindID].name)
	local uiText_gameInfo = ccui.Helper:seekWidgetByName(self.root, "Text_gameInfo")
	if pBuffer.gameDesc ~= nil and pBuffer.gameDesc ~= "" then
		uiText_gameInfo:setString(string.format("%s", StaticData.Games[pBuffer.tableConfig.wKindID].name .. " " .. pBuffer.gameDesc))
	else
		uiText_gameInfo:setString(string.format("%s", StaticData.Games[pBuffer.tableConfig.wKindID].name))
	end
end

function FriendsRoomEndLayer:isInClub( pBuffer )
    return pBuffer.tableConfig.nTableType == TableType_ClubRoom and pBuffer.tableConfig.dwClubID ~= 0
end

function FriendsRoomEndLayer:initVar(...)
	self.Panel_payerInfo = ccui.Helper:seekWidgetByName(self.root, "Panel_payerInfo")
	self.center = ccui.Helper:seekWidgetByName(self.root, "center")
	self.updateItems = {}
end

function FriendsRoomEndLayer:updatePlayerInfo(pBuffer)
	if not pBuffer then
		return
	end
	local Pos = Location[pBuffer.dwUserCount]
	
	local winner = self:getWinner(pBuffer)
	
	for i = 1, pBuffer.dwUserCount do
		local item = self.Panel_payerInfo:clone()
		local tScoreInfo = pBuffer.tScoreInfo[i]
		local uiImage_avatar = ccui.Helper:seekWidgetByName(item, "Image_avatar")
		Common:requestUserAvatar(tScoreInfo.dwUserID, tScoreInfo.player.szPto, uiImage_avatar, "img")
		local uiText_palyerName = ccui.Helper:seekWidgetByName(item, "Text_palyerName")
		uiText_palyerName:setString(tScoreInfo.player.szNickName)
		uiText_palyerName:setColor(cc.c3b(129, 18, 18))
		local uiText_id = ccui.Helper:seekWidgetByName(item, "Text_id")
		uiText_id:setString(string.format("ID:%d", tScoreInfo.dwUserID))
		uiText_id:setColor(cc.c3b(129, 18, 18))
		local uiImage_host = ccui.Helper:seekWidgetByName(item, "Image_host")
		if tScoreInfo.dwUserID == pBuffer.dwTableOwnerID then
			uiImage_host:setVisible(true)
		else
			uiImage_host:setVisible(false)
		end
		local Image_winner = ccui.Helper:seekWidgetByName(item, "Image_winner")
		Image_winner:setVisible(false)
		if winner[tScoreInfo.dwUserID] then
			Image_winner:setVisible(true)
		end
		
	

		local uiAtlasLabel_integral = ccui.Helper:seekWidgetByName(item, "AtlasLabel_integral")
		if tScoreInfo.totalScore >= 0 then
			uiAtlasLabel_integral:setProperty(string.format(".%d",self:getScore(tScoreInfo.totalScore)), "record/rocord_shuzi1.png", 22, 29, ".")
		else
			uiAtlasLabel_integral:setProperty(string.format(".%d", self:getScore(-tScoreInfo.totalScore)), "record/rocord_shuzi2.png", 22, 29, ".")
		end
		self:updatePlayerStatics(item, pBuffer.statistics[i],tScoreInfo.totalScore)
		
		--------
		local Text_difeng = ccui.Helper:seekWidgetByName(item, "Text_difeng")
		Text_difeng:setColor(cc.c3b(177, 76, 15))
		Text_difeng:setString('(1底分:0)')
		self.center:addChild(item)
		item:setPosition(Pos[i])

		self.updateItems[i] = {Text_difeng, self:getScore(tScoreInfo.totalScore)}
	end
	
	self:updateTotalScore()
end

--获取倍数
function FriendsRoomEndLayer:getScore ( score )
	local wKindID = GameCommon.tableConfig.wKindID
	if GameCommon.gameConfig.bPlayerCount == 2 and wKindID == 40 then
		local tempScore = math.abs(score)
		local bei = GameCommon.gameConfig.bMinLostCell or 1
		if bei <= 0 then
			bei = 1
		end
		if GameCommon.gameConfig.bMinLost == 0 then
			if bei > 1 then --不限分加倍
				return score * bei
			else
				return score
			end
		else
			if tempScore <= GameCommon.gameConfig.bMinLost   then
				return score * bei
			else
				return score
			end
		end
	else
		return score
	end
end

function FriendsRoomEndLayer:getWinner(pBuffer)
	if not pBuffer then
		return
	end
	local max = - 1
	local winner = {}
	local score = -1
	for i = 1, 8 do
		if not pBuffer.tScoreInfo[i] then
			score = -1
		else
			score = pBuffer.tScoreInfo[i].totalScore or -1
		end
		if score >= max then
			max = score
		end
	end
	for i = 1, 8 do
		if not pBuffer.tScoreInfo[i] then
			score = -1
		else
			score = pBuffer.tScoreInfo[i].totalScore or -1
		end
		if score == max and max > 0 then
			local id = pBuffer.tScoreInfo[i].dwUserID
			winner[id] = true
		end
	end
	return winner
end

--用户统计
function FriendsRoomEndLayer:updatePlayerStatics(root, statics,score)
	local showEnd = {-1,1,3,4,5,6}
	local wkindID = GameCommon.tableConfig.wKindID
	if wkindID == 47 or wkindID == 48 or wkindID == 49  or wkindID == 60 then
		showEnd = {-1,1,3,5,6}
	end
	local listEnd = root:getChildByName('ListView_end')
	for i=1,#showEnd do
		local item = self.Panel_score:clone()
		local Text_name = item:getChildByName('Text_name')
		local Text_num = item:getChildByName('Text_num')
		Text_name:setColor(cc.c3b(177, 76, 15))
		Text_num:setColor(cc.c3b(177, 76, 15))
		local index = showEnd[i]
		Text_name:setString(EndList[index])
		if index == -1 then --胡息总数
			Text_num:setString(score)
		else
			Text_num:setString(statics[index] or 0)
		end
		listEnd:pushBackCustomItem(item)
	end
end

--==============================--
--desc: 打开解散
--time:2018-07-19 02:30:20
--==============================--
function FriendsRoomEndLayer:dissolve()
	self.Panel_dissolve:setVisible(true)
	self:updateDimissUI()
end

--==============================--
--desc:设置底分
--time:2018-07-19 02:31:34
--@return 
--==============================--
function FriendsRoomEndLayer:setting()
	self.inputValue = {}
	self.Panel_setting:setVisible(true)
end

local function split(str, delimiter)
	if str == nil or str == '' or delimiter == nil then
		return nil
	end
	
	local result = {}
	for match in(str .. delimiter):gmatch("(.-)" .. delimiter) do
		table.insert(result, match)
	end
	return result
end

function FriendsRoomEndLayer:initSetting(...)
	self.inputValue = {}
	local close = ccui.Helper:seekWidgetByName(self.root, "Button_close")
	close:setPressedActionEnabled(true)
	self.Panel_setting = ccui.Helper:seekWidgetByName(self.root, "Panel_setting")
	self.Panel_setting:setVisible(false)
	
	self.textField_input = ccui.Helper:seekWidgetByName(self.root, "TextField_input")
	
	local function onEventClose(sender, event)
		if event == ccui.TouchEventType.ended then
			Common:palyButton()
			self.inputValue = {}
			self.textField_input:setString('')
			self.Panel_setting:setVisible(false)
		end
	end
	close:addTouchEventListener(onEventClose)
	
	local clear = ccui.Helper:seekWidgetByName(self.root, "Button_input_clear")
	clear:setPressedActionEnabled(true)
	local function onEventClear(sender, event)
		if event == ccui.TouchEventType.ended then
			Common:palyButton()
			self.inputValue = {}
			self.textField_input:setString('')
		end
	end
	clear:addTouchEventListener(onEventClear)
	
	
	local finish = ccui.Helper:seekWidgetByName(self.root, "Button_input_finish")
	finish:setPressedActionEnabled(true)
	local function onEventFinish(sender, event)
		if event == ccui.TouchEventType.ended then
			Common:palyButton()
			self:updateTotalScore()
			self.inputValue = {}
			self.textField_input:setString('')
			self.Panel_setting:setVisible(false)
		end
	end
	finish:addTouchEventListener(onEventFinish)
	
	for i = 1, 11 do
		local btn = ccui.Helper:seekWidgetByName(self.Panel_setting, "Button_input_" .. i)
		btn:addTouchEventListener(function(sender, event)
			if event == ccui.TouchEventType.ended then
				Common:palyButton()
				local name = sender:getName()
				local str = split(name, '_')
				self:clickInput(str[3])
			end
		end)
		btn:setPressedActionEnabled(true)
	end
end

function FriendsRoomEndLayer:clickInput(inputName)
	if #self.inputValue >= 3 then
		require("common.MsgBoxLayer"):create(0, nil, "不超过3位数")
		return
	end
	if #self.inputValue == 0 then
		if inputName == '10' then
			table.insert(self.inputValue, '0')
			table.insert(self.inputValue, '.')
			local str = ''
			for i, v in ipairs(self.inputValue) do
				str = str .. v
			end
			self.textField_input:setString(str)
			return
		elseif inputName == '11' then
			return
		end
	end
	
	if inputName == '10' then
		if self:checkIsHavePoint() then
			return
		end
		inputName = '.'
	elseif inputName == '11' then
		inputName = '0'
	end
	
	table.insert(self.inputValue, inputName)
	local str = ''
	for i, v in ipairs(self.inputValue) do
		str = str .. v
	end
	self.textField_input:setString(str)
end

function FriendsRoomEndLayer:checkIsHavePoint(...)
	for i, v in ipairs(self.inputValue) do
		if v == '.' then
			return true
		end
	end
	return false
end

--str 转 int
function FriendsRoomEndLayer:strToInt(...)
	if #self.inputValue == 0 then
		return 1
	end
	local str = ''
	for i, v in ipairs(self.inputValue) do
		str = str .. v
	end
	
	return tonumber(str)
end

function FriendsRoomEndLayer:updateTotalScore(...)
	local num = self:strToInt()
	for i = 1, self.pBuffer.dwUserCount do
		local updateItem = self.updateItems[i]
		if updateItem then
			local str = num .. ' 底分：' ..(updateItem[2] * num) -- (1底分:0)
			updateItem[1]:setString(str)
		end
	end
end

function FriendsRoomEndLayer:initDisMissValue(...)
	self.Panel_dissolve = ccui.Helper:seekWidgetByName(self.root, 'Panel_dissolve')
	self.dimiss_template = ccui.Helper:seekWidgetByName(self.root, 'dimiss_template')
	self.panel_childs = ccui.Helper:seekWidgetByName(self.Panel_dissolve, 'Panel_Childs')
	self.Panel_dissolve:setVisible(false)
end

local posDis = {
	[2] = {
		cc.p(414, 448),
		cc.p(873, 450),
	},
	[3] = {
		cc.p(414, 448),
		cc.p(873, 450),
		cc.p(414, 242),
	},
	[4] = {
        cc.p(414, 448),
		cc.p(873, 450),
		cc.p(414, 242),
		cc.p(873, 242),
	}
}

function FriendsRoomEndLayer:updateDimissUI(...)
	self.panel_childs:removeAllChildren()
	local data = GameCommon.disMissData
	local playerID = self:disMissTableInfo(data)
	local pos = posDis[GameCommon.gameConfig.bPlayerCount]
	local item = nil
	if playerID and data then
		for i = 1, GameCommon.gameConfig.bPlayerCount do
			if data.dwUserIDALL[i] ~= 0 then
				if data.cbDisbandeState[i] == 1 then --不可操作
					if data.dwUserIDALL[i] == playerID then --发起了解散
						item = self:updateDisMissState(2, data.dwUserIDALL[i], data.szNickNameALL[i])
					else
						item = self:updateDisMissState(3, data.dwUserIDALL[i], data.szNickNameALL[i])
					end
				elseif data.cbDisbandeState[i] == 2 then --
				else
					item = self:updateDisMissState(3, data.dwUserIDALL[i], data.szNickNameALL[i])
				end
			end
			if item then
				item:setPosition(pos[i])
			end
		end
	end
end

function FriendsRoomEndLayer:disMissTableInfo(data)
    if not data then
        return nil
    end
	local disPlayerID = nil
	local advocateName = ''
	for i = 1, 3 do
		if data.dwUserIDALL[i] ~= 0 then
			if data.cbDisbandeState[i] == 1 then --已经同意
				if data.wAdvocateDisbandedID == i - 1 then
					disPlayerID = data.dwUserIDALL[i] --谁发起
					advocateName = data.szNickNameALL[i] --谁发起
					break
				end
			end
		end
	end
	return disPlayerID, advocateName
end

function FriendsRoomEndLayer:updateDisMissState(state, id, name)
	local item = self.dimiss_template:clone()
	local image_state = item:getChildByName('image_state')
	if state == 1 then --未发表已经
		image_state:loadTexture('cdzipai/ui/zi_wefabiao.png')
	elseif state == 2 then --玩家发起了解散申请
		image_state:loadTexture('cdzipai/ui/zi_faqishenqing.png')		
	elseif state == 3 then -- 
		image_state:loadTexture('cdzipai/ui/zi_tongyishenqing.png')		
    end
    image_state:ignoreContentAdaptWithSize(true)
	
	local text_name = item:getChildByName('text_name')
	text_name:setString(name)
	text_name:setColor(cc.c3b(177, 76, 15))
	local text_id = item:getChildByName('text_id')
	text_id:setString('ID:' .. id)
	text_id:setColor(cc.c3b(177, 76, 15))
	
	local uiImage_avatar = item:getChildByName("Image_avatar_player")
	local player = GameCommon:getUserInfoByUserID(id)
	if player then
		Common:requestUserAvatar(id, player.szPto, uiImage_avatar, "img")
	end
	self.panel_childs:addChild(item)	
	return item
end

--复制总战绩
function FriendsRoomEndLayer:copyData()
    local pBuffer = self.pBuffer
    local clubId = '亲友圈ID:' .. pBuffer.tableConfig.dwClubID .. '\n'
    dump(pBuffer.tableConfig)
	local strRoom = '房间号:' .. pBuffer.tableConfig.wTbaleID .. '\n'
	local endRoo = '结束时间:' .. self.endTime .. '\n'
	local roomBanker = '房主:' .. pBuffer.szOwnerName .. '\n'
	
	local des = StaticData.Games[pBuffer.tableConfig.wKindID].name .. string.format(" 局数:%d/%d", pBuffer.tableConfig.wCurrentNumber, pBuffer.tableConfig.wTableNumber) .. '\n'
	local endDes = ''
    for i = 1, pBuffer.dwUserCount do
        local tScoreInfo = pBuffer.tScoreInfo[i]
        endDes = endDes .. tScoreInfo.player.szNickName .. ' ID：' .. tScoreInfo.dwUserID .. ' ' ..   tScoreInfo.totalScore .. '\n'
	end
    local history = clubId .. strRoom .. endRoo .. roomBanker .. des .. endDes
    print('------------------>>',history)
    return history
end

return FriendsRoomEndLayer
