--[[
*名称:NewClubFatigueLayer
*描述:疲劳值界面
*作者:admin
*创建日期:2019-10-22 10:22:01
*修改日期:
]]

local EventMgr          = require("common.EventMgr")
local EventType         = require("common.EventType")
local NetMgr            = require("common.NetMgr")
local NetMsgId          = require("common.NetMsgId")
local StaticData        = require("app.static.StaticData")
local UserData          = require("app.user.UserData")
local Common            = require("common.Common")
local GameConfig        = require("common.GameConfig")

local NewClubFatigueLayer      = class("NewClubFatigueLayer", cc.load("mvc").ViewBase)

function NewClubFatigueLayer:onConfig()
    self.widget         = {
        {"Button_close", "onClose"},
        {"Button_record", "onRecord"},
        {"Button_operate", "onOperate"},
        {"Button_log", "onFatigueLog"},
        {"Panel_frame"},
        {"Text_fatigueNum"},
        {"TextField_memID"},
        {"Image_find"},
        {"Button_findMem", "onFindMem"},
        {"Button_return", "onFindReturn"},
        {"Panel_pushFrame"},
        {"Image_pushHead"},
        {"Text_pushName"},
        {"Text_pushId"},
        {"Button_pushReturn", "onPushReturn"},
        {"Image_record"},
        {"ListView_record"},
        {"Image_operate"},
        {"Panel_operate"},
        {"ListView_mem"},
        {"ListView_find"},
        {"Panel_pushOperate"},
        {"ListView_pushOperate"},
        {"Panel_item"},
        {"Image_item"},
        {"Image_log"},
        {"ListView_log"},
        {"Panel_logItem"},
    }
end

function NewClubFatigueLayer:onEnter()
	EventMgr:registListener(EventType.RET_GET_CLUB_MEMBER_FATIGUE_RECORD ,self,self.RET_GET_CLUB_MEMBER_FATIGUE_RECORD)
    EventMgr:registListener(EventType.RET_GET_CLUB_MEMBER_FATIGUE_RECORD_FINISH ,self,self.RET_GET_CLUB_MEMBER_FATIGUE_RECORD_FINISH)
    EventMgr:registListener(EventType.RET_GET_CLUB_NOT_PARTNER_MEMBER ,self,self.RET_GET_CLUB_NOT_PARTNER_MEMBER)
    EventMgr:registListener(EventType.RET_GET_CLUB_NOT_PARTNER_MEMBER_FINISH ,self,self.RET_GET_CLUB_NOT_PARTNER_MEMBER_FINISH)
    EventMgr:registListener(EventType.RET_SETTINGS_CLUB_MEMBER ,self,self.RET_SETTINGS_CLUB_MEMBER)
    EventMgr:registListener(EventType.RET_CLUB_MEMBER_INFO ,self,self.RET_CLUB_MEMBER_INFO)
end

function NewClubFatigueLayer:onExit()
	EventMgr:unregistListener(EventType.RET_GET_CLUB_MEMBER_FATIGUE_RECORD ,self,self.RET_GET_CLUB_MEMBER_FATIGUE_RECORD)
    EventMgr:unregistListener(EventType.RET_GET_CLUB_MEMBER_FATIGUE_RECORD_FINISH ,self,self.RET_GET_CLUB_MEMBER_FATIGUE_RECORD_FINISH)
    EventMgr:unregistListener(EventType.RET_GET_CLUB_NOT_PARTNER_MEMBER ,self,self.RET_GET_CLUB_NOT_PARTNER_MEMBER)
    EventMgr:unregistListener(EventType.RET_GET_CLUB_NOT_PARTNER_MEMBER_FINISH ,self,self.RET_GET_CLUB_NOT_PARTNER_MEMBER_FINISH)
    EventMgr:unregistListener(EventType.RET_SETTINGS_CLUB_MEMBER ,self,self.RET_SETTINGS_CLUB_MEMBER)
    EventMgr:unregistListener(EventType.RET_CLUB_MEMBER_INFO ,self,self.RET_CLUB_MEMBER_INFO)
end

function NewClubFatigueLayer:onCreate(param)
	self.clubData = param[1]
	self.userFatigueValue = param[2]
	self.userOffice = param[3]
	self.Text_fatigueNum:setString(self.userFatigueValue)
	self.ListView_record:addScrollViewEventListener(handler(self, self.listViewFatigueEventListen))
    self.ListView_pushOperate:addScrollViewEventListener(handler(self, self.listViewFatigueEventListen))
    self.ListView_log:addScrollViewEventListener(handler(self, self.listViewFatigueEventListen))
    self.ListView_mem:addScrollViewEventListener(handler(self, self.listViewMemEventListen))
	
	if self.userOffice == 2 then
		self.Button_operate:setVisible(false)
        self.Button_log:setVisible(false)
        self.Button_record:setPositionY(580.34)
        self:switchType(1)
    else
        self:switchType(2)
	end
end

function NewClubFatigueLayer:onClose()
    self:removeFromParent()
end

function NewClubFatigueLayer:onRecord()
	self:switchType(1)
end

function NewClubFatigueLayer:onOperate()
	self:switchType(2)
end

function NewClubFatigueLayer:onFatigueLog()
    self:switchType(3)
end

function NewClubFatigueLayer:onFindMem()
	local playerid = tonumber(self.TextField_memID:getString())
    if playerid then
        if self:isHasAdmin() then
            UserData.Guild:reqClubMemberInfo(self.clubData.dwClubID, UserData.User.userID, 0, playerid, 1)
        else
            UserData.Guild:reqClubMemberInfo(self.clubData.dwClubID, UserData.User.userID, 2, playerid, 1)
        end
    else
        require("common.MsgBoxLayer"):create(0,nil,"输入玩家ID错误!")
    end
end

function NewClubFatigueLayer:onFindReturn()
	self.ListView_mem:setVisible(true)
	self.ListView_find:setVisible(false)
	self.Button_findMem:setVisible(true)
	self.Button_return:setVisible(false)
end

function NewClubFatigueLayer:onPushReturn()
    self.Panel_frame:setVisible(true)
    self.Panel_pushFrame:setVisible(false)
    self.Panel_operate:setVisible(true)
    self.Panel_pushOperate:setVisible(false)
end

function NewClubFatigueLayer:listViewFatigueEventListen(sender, evenType)
    if evenType == ccui.ScrollviewEventType.scrollToBottom then
        if self.recordState == 1 then
            self.recordState = 0
            if self.Image_log:isVisible() then
                UserData.Guild:getClubFatigueRecord(self.clubData.dwClubID, UserData.User.userID, self.recordPage, 3)
            else
                UserData.Guild:getClubFatigueRecord(self.clubData.dwClubID, self.curSelUserId, self.recordPage)
            end
        end
    end
end

function NewClubFatigueLayer:listViewMemEventListen(sender, evenType)
    local targetID = nil
    if self:isAdmin(UserData.User.userID) then
        targetID = self.clubData.dwUserID
    end
    if evenType == ccui.ScrollviewEventType.scrollToBottom then
        if self.memberState == 1 then
            self.memberState = 0
            UserData.Guild:getClubNotPartnerMember(0, self.memberPage, self.clubData.dwClubID, targetID)
        end
    end
end

function NewClubFatigueLayer:switchType(itype)
    self.Panel_frame:setVisible(true)
    self.Panel_pushFrame:setVisible(false)
    self.Button_findMem:setVisible(true)
    self.Button_return:setVisible(false)
	if itype == 1 then
		self.Button_record:setBright(false)
		self.Button_operate:setBright(true)
        self.Button_log:setBright(true)
		self.Image_record:setVisible(true)
		self.Image_operate:setVisible(false)
        self.Image_log:setVisible(false)
		self.Image_find:setVisible(false)
		self.ListView_record:removeAllItems()
        self.recordPage = 1
        self.recordState = 0
        UserData.Guild:getClubFatigueRecord(self.clubData.dwClubID, UserData.User.userID,1)
	elseif itype == 2 then
		self.Button_record:setBright(true)
		self.Button_operate:setBright(false)
        self.Button_log:setBright(true)
		self.Image_record:setVisible(false)
		self.Image_operate:setVisible(true)
        self.Panel_operate:setVisible(true)
        self.Panel_pushOperate:setVisible(false)
        self.Image_log:setVisible(false)
		self.Image_find:setVisible(true)
		self.ListView_mem:setVisible(true)
    	self.ListView_find:setVisible(false)
		self.ListView_mem:removeAllItems()
        self.memberState = 0
        self.memberPage = 1
        local targetID = nil
        if self:isAdmin(UserData.User.userID) then
            targetID = self.clubData.dwUserID
        end
        UserData.Guild:getClubNotPartnerMember(0, self.memberPage, self.clubData.dwClubID, targetID)
    elseif itype == 3 then
        self.Button_record:setBright(true)
        self.Button_operate:setBright(true)
        self.Button_log:setBright(false)
        self.Image_record:setVisible(false)
        self.Image_operate:setVisible(false)
        self.Image_log:setVisible(true)
        self.Image_find:setVisible(false)
        self.ListView_log:removeAllItems()
        self.recordPage = 1
        self.recordState = 0
        UserData.Guild:getClubFatigueRecord(self.clubData.dwClubID, UserData.User.userID,1,3)
	end
end

function NewClubFatigueLayer:isHasAdmin()
    return (self.clubData.dwUserID == UserData.User.userID) or self:isAdmin(UserData.User.userID)
end

function NewClubFatigueLayer:isAdmin(userid)
    for i,v in ipairs(self.clubData.dwAdministratorID or {}) do
        if v == userid then
            return true
        end
    end
    return false
end

function NewClubFatigueLayer:getPlaywayIndex(wKindID)
	for i,v in ipairs(self.clubData.wKindID or {}) do
        if v == wKindID then
        	return i
        end
    end
    return nil
end

function NewClubFatigueLayer:loadMemerItem(item, data)
	local Image_head = self:seekWidgetByNameEx(item, "Image_head")
    local Text_offer = self:seekWidgetByNameEx(item, "Text_offer")
    local Text_name = self:seekWidgetByNameEx(item, "Text_name")
    local Text_id = self:seekWidgetByNameEx(item, "Text_id")
    local Text_snum = self:seekWidgetByNameEx(item, "Text_snum")
    local Button_js = self:seekWidgetByNameEx(item, "Button_js")
    local Button_add = self:seekWidgetByNameEx(item, "Button_add")
    local Button_log = self:seekWidgetByNameEx(item, "Button_log")
    Text_offer:setColor(cc.c3b(131, 88, 45))
    Text_name:setColor(cc.c3b(131, 88, 45))
    Text_id:setColor(cc.c3b(131, 88, 45))
    Text_snum:setColor(cc.c3b(131, 88, 45))
    Common:requestUserAvatar(data.dwUserID, data.szLogoInfo, Image_head, "img")
    local name = Common:getShortName(data.szNickName, 14 , 7)
    Text_name:setString(name)
    Text_id:setString(data.dwUserID)
    Text_snum:setString(data.lFatigueValue)
    if data.cbOffice == 0 then
        Text_offer:setString('圈主')
    elseif data.cbOffice == 1 then
        Text_offer:setString('管理员')
    elseif data.cbOffice == 3 then
        Text_offer:setString('合伙人')
    else
        Text_offer:setString('成员')
    end

    local userInfo = {
        name = name,
        userID = data.dwUserID,
        fatigue = data.lFatigueValue
    }
    local setType = 7
    Common:addTouchEventListener(Button_add,function()
        userInfo.fatigue = tonumber(Text_snum:getString()) or userInfo.fatigue
        local node = require("app.MyApp"):create(userInfo, 1, function(value)
        	self.curJYValue = value
            UserData.Guild:reqSettingsClubMember(setType, data.dwClubID, data.dwUserID,0,"",value)
        end):createView("NewClubInputFatigueLayer")
        self:addChild(node)
    end)

    Common:addTouchEventListener(Button_js,function()
        local lastFatigue = tonumber(Text_snum:getString()) or 0
        userInfo.fatigue = tonumber(Text_snum:getString()) or userInfo.fatigue
        local node = require("app.MyApp"):create(userInfo, 2, function(value) 
            if lastFatigue < value then
                require("common.MsgBoxLayer"):create(0,nil,"设置疲劳值错误!")
            else
            	self.curJYValue = -value
                UserData.Guild:reqSettingsClubMember(setType, data.dwClubID, data.dwUserID,0,"",-value)
            end
        end):createView("NewClubInputFatigueLayer")
        self:addChild(node)
    end)
    
    Common:addTouchEventListener(Button_log,function() 
        self.Panel_frame:setVisible(false)
        self.Panel_pushFrame:setVisible(true)
        self.Panel_operate:setVisible(false)
        self.Panel_pushOperate:setVisible(true)
        Common:requestUserAvatar(data.dwUserID, data.szLogoInfo, self.Image_pushHead, "img")
        self.Text_pushName:setString(data.szNickName)
        self.Text_pushId:setString(data.dwUserID)

        --请求疲劳值记录
        self.ListView_pushOperate:removeAllItems()
        self.recordPage = 1
        self.recordState = 0
        self.curSelUserId = data.dwUserID
        UserData.Guild:getClubFatigueRecord(data.dwClubID, self.curSelUserId, 1)
    end)
end

function NewClubFatigueLayer:loadTotalRecordItem(data)
    local listview = self.ListView_log
    if data.cbType == 3 then
        --合伙人买卖疲劳值
        local item = self.Panel_logItem:clone()
        listview:pushBackCustomItem(item)
        listview:refreshView()
        local Text_name = ccui.Helper:seekWidgetByName(item, "Text_name")
        local Text_id = ccui.Helper:seekWidgetByName(item, "Text_id")
        local Text_num = ccui.Helper:seekWidgetByName(item, "Text_num")
        local Text_renum = ccui.Helper:seekWidgetByName(item, "Text_renum")
        local Text_time = ccui.Helper:seekWidgetByName(item, "Text_time")
        Text_name:setColor(cc.c3b(131, 88, 45))
        Text_id:setColor(cc.c3b(131, 88, 45))
        Text_num:setColor(cc.c3b(131, 88, 45))
        Text_renum:setColor(cc.c3b(131, 88, 45))
        Text_time:setColor(cc.c3b(131, 88, 45))
        Text_time:setString(os.date('%m-%d %H:%M', data.dwOperTime))
        local name = Common:getShortName(data.szOriginNickName, 14 , 7)
        Text_name:setString(name)
        Text_id:setString(data.dwOriginID)

        if data.lFatigue >= 0 then
            Text_num:setColor(cc.c3b(255, 0, 0))
            Text_num:setString('+' .. data.lFatigue)
        else
            Text_num:setColor(cc.c3b(0, 128, 0))
            Text_num:setString(data.lFatigue)
        end
        Text_renum:setString(data.lNewFatigue)

    elseif data.cbType == 5 and UserData.User.userID == data.dwOriginID then
         --新设置疲劳值
        local item = self.Panel_logItem:clone()
        listview:pushBackCustomItem(item)
        listview:refreshView()
        local Text_name = ccui.Helper:seekWidgetByName(item, "Text_name")
        local Text_id = ccui.Helper:seekWidgetByName(item, "Text_id")
        local Text_num = ccui.Helper:seekWidgetByName(item, "Text_num")
        local Text_renum = ccui.Helper:seekWidgetByName(item, "Text_renum")
        local Text_time = ccui.Helper:seekWidgetByName(item, "Text_time")
        Text_name:setColor(cc.c3b(131, 88, 45))
        Text_id:setColor(cc.c3b(131, 88, 45))
        Text_num:setColor(cc.c3b(131, 88, 45))
        Text_time:setColor(cc.c3b(131, 88, 45))
        Text_time:setString(os.date('%m-%d %H:%M', data.dwOperTime))
        local name = Common:getShortName(data.szNickName, 14 , 7)
        Text_name:setString(name)
        Text_id:setString(data.dwUserID)

        if data.lFatigue >= 0 then
            Text_num:setColor(cc.c3b(255, 0, 0))
            Text_num:setString('+' .. data.lFatigue)
        else
            Text_num:setColor(cc.c3b(0, 128, 0))
            Text_num:setString(data.lFatigue)
        end
        Text_renum:setString(data.lNewFatigue)
    end
end

function NewClubFatigueLayer:RET_GET_CLUB_MEMBER_FATIGUE_RECORD(event)
    local data = event._usedata
    dump(data, 'RET_GET_CLUB_MEMBER_FATIGUE_RECORD:')
    local listview = self.ListView_record
    if self.Image_operate:isVisible() then
        listview = self.ListView_pushOperate
    elseif self.Image_log:isVisible() then
        self:loadTotalRecordItem(data)
        return
    end

    if data.cbType == 1 then
        --房费
        local item = self.Panel_item:clone()
        listview:pushBackCustomItem(item)
        listview:refreshView()
        local Text_time = ccui.Helper:seekWidgetByName(item, "Text_time")
        local Text_type = ccui.Helper:seekWidgetByName(item, "Text_type")
        local Text_playway = ccui.Helper:seekWidgetByName(item, "Text_playway")
        local Text_xnum = ccui.Helper:seekWidgetByName(item, "Text_xnum")
        local Text_snum = ccui.Helper:seekWidgetByName(item, "Text_snum")
        local Text_des = ccui.Helper:seekWidgetByName(item, "Text_des")
        Text_time:setColor(cc.c3b(131, 88, 45))
        Text_type:setColor(cc.c3b(131, 88, 45))
        Text_playway:setColor(cc.c3b(131, 88, 45))
        Text_xnum:setColor(cc.c3b(131, 88, 45))
        Text_snum:setColor(cc.c3b(131, 88, 45))
        Text_des:setColor(cc.c3b(131, 88, 45))
        Text_time:setString(os.date('%m-%d %H:%M', data.dwOperTime))
        
        if StaticData.Games[data.wKindID] then
            Text_playway:setString(StaticData.Games[data.wKindID].name)
        else
            Text_playway:setString('')
        end
        
        if data.lFatigue >= 0 then
            Text_type:setString('游戏收益')
            Text_xnum:setString('+' .. data.lFatigue)
            Text_snum:setString(data.lNewFatigue)
            Text_des:setString(data.szDesc)
        else
            Text_type:setString('游戏消耗')
            Text_xnum:setString(data.lFatigue)
            Text_snum:setString(data.lNewFatigue)
            local index = self:getPlaywayIndex(data.wKindID)
            local cbPayMode = self.clubData.cbPayMode[index]
            if cbPayMode == 1 then
                Text_des:setString('大赢家支付')
            elseif cbPayMode == 2 then
                Text_des:setString('赢家支付')
            elseif cbPayMode == 3 then
                Text_des:setString('AA支付')
            else
                Text_des:setString('免费')
            end
        end
        
    elseif data.cbType == 2 then
        --对局
        local item = self.Panel_item:clone()
        listview:pushBackCustomItem(item)
        listview:refreshView()
        local Text_time = ccui.Helper:seekWidgetByName(item, "Text_time")
        local Text_type = ccui.Helper:seekWidgetByName(item, "Text_type")
        local Text_playway = ccui.Helper:seekWidgetByName(item, "Text_playway")
        local Text_xnum = ccui.Helper:seekWidgetByName(item, "Text_xnum")
        local Text_snum = ccui.Helper:seekWidgetByName(item, "Text_snum")
        local Text_des = ccui.Helper:seekWidgetByName(item, "Text_des")
        Text_time:setColor(cc.c3b(131, 88, 45))
        Text_type:setColor(cc.c3b(131, 88, 45))
        Text_playway:setColor(cc.c3b(131, 88, 45))
        Text_xnum:setColor(cc.c3b(131, 88, 45))
        Text_snum:setColor(cc.c3b(131, 88, 45))
        Text_des:setColor(cc.c3b(131, 88, 45))
        Text_time:setString(os.date('%m-%d %H:%M', data.dwOperTime))

        if StaticData.Games[data.wKindID] then
            Text_playway:setString(StaticData.Games[data.wKindID].name)
        else
            Text_playway:setString('')
        end

        if data.lFatigue >= 0 then
            Text_type:setString('对局收益')
            Text_xnum:setString('+' .. data.lFatigue)
            Text_snum:setString(data.lNewFatigue)
        else
            Text_type:setString('对局消耗')
            Text_xnum:setString(data.lFatigue)
            Text_snum:setString(data.lNewFatigue)
        end
        Text_des:setString('')

    elseif data.cbType == 3 then
        --玩家买卖疲劳值
        local item = self.Panel_item:clone()
        listview:pushBackCustomItem(item)
        listview:refreshView()
        local Text_time = ccui.Helper:seekWidgetByName(item, "Text_time")
        local Text_type = ccui.Helper:seekWidgetByName(item, "Text_type")
        local Text_playway = ccui.Helper:seekWidgetByName(item, "Text_playway")
        local Text_xnum = ccui.Helper:seekWidgetByName(item, "Text_xnum")
        local Text_snum = ccui.Helper:seekWidgetByName(item, "Text_snum")
        local Text_des = ccui.Helper:seekWidgetByName(item, "Text_des")
        Text_time:setColor(cc.c3b(131, 88, 45))
        Text_type:setColor(cc.c3b(131, 88, 45))
        Text_playway:setColor(cc.c3b(131, 88, 45))
        Text_xnum:setColor(cc.c3b(131, 88, 45))
        Text_snum:setColor(cc.c3b(131, 88, 45))
        Text_des:setColor(cc.c3b(131, 88, 45))
        Text_time:setString(os.date('%m-%d %H:%M', data.dwOperTime))
        Text_playway:setString('')
        Text_type:setString('疲劳值')
        if data.lFatigue >= 0 then
            Text_xnum:setString('+' .. data.lFatigue)
            Text_snum:setString(data.lNewFatigue)
        else
            Text_xnum:setString(data.lFatigue)
            Text_snum:setString(data.lNewFatigue)
        end
        local name = Common:getShortName(data.szOriginNickName, 14 , 7)
        Text_des:setString(string.format('%s(%d)操作', name, data.dwOriginID))

    elseif data.cbType == 4 or data.cbType == 5 then
        --设置疲劳值
        local item = self.Panel_item:clone()
        listview:pushBackCustomItem(item)
        listview:refreshView()
        local Text_time = ccui.Helper:seekWidgetByName(item, "Text_time")
        local Text_type = ccui.Helper:seekWidgetByName(item, "Text_type")
        local Text_playway = ccui.Helper:seekWidgetByName(item, "Text_playway")
        local Text_xnum = ccui.Helper:seekWidgetByName(item, "Text_xnum")
        local Text_snum = ccui.Helper:seekWidgetByName(item, "Text_snum")
        local Text_des = ccui.Helper:seekWidgetByName(item, "Text_des")
        Text_time:setColor(cc.c3b(131, 88, 45))
        Text_type:setColor(cc.c3b(131, 88, 45))
        Text_playway:setColor(cc.c3b(131, 88, 45))
        Text_xnum:setColor(cc.c3b(131, 88, 45))
        Text_snum:setColor(cc.c3b(131, 88, 45))
        Text_des:setColor(cc.c3b(131, 88, 45))
        Text_time:setString(os.date('%m-%d %H:%M', data.dwOperTime))

        if StaticData.Games[data.wKindID] then
        	Text_playway:setString(StaticData.Games[data.wKindID].name)
        else
        	Text_playway:setString('')
        end

        Text_type:setString('疲劳值')
        if data.lFatigue >= 0 then
            Text_xnum:setString('+' .. data.lFatigue)
            Text_snum:setString(data.lNewFatigue)
        else
            Text_xnum:setString(data.lFatigue)
            Text_snum:setString(data.lNewFatigue)
        end
        
        local name = Common:getShortName(data.szOriginNickName, 14 , 7)
    	Text_des:setString(string.format('%s(%d)操作', name, data.dwOriginID))

    elseif data.cbType == 6 then
        --疲劳值均摊房费
        local item = self.Panel_item:clone()
        listview:pushBackCustomItem(item)
        listview:refreshView()
        local Text_time = ccui.Helper:seekWidgetByName(item, "Text_time")
        local Text_type = ccui.Helper:seekWidgetByName(item, "Text_type")
        local Text_playway = ccui.Helper:seekWidgetByName(item, "Text_playway")
        local Text_xnum = ccui.Helper:seekWidgetByName(item, "Text_xnum")
        local Text_snum = ccui.Helper:seekWidgetByName(item, "Text_snum")
        local Text_des = ccui.Helper:seekWidgetByName(item, "Text_des")
        Text_time:setColor(cc.c3b(131, 88, 45))
        Text_type:setColor(cc.c3b(131, 88, 45))
        Text_playway:setColor(cc.c3b(131, 88, 45))
        Text_xnum:setColor(cc.c3b(131, 88, 45))
        Text_snum:setColor(cc.c3b(131, 88, 45))
        Text_des:setColor(cc.c3b(131, 88, 45))
        Text_time:setString(os.date('%m-%d %H:%M', data.dwOperTime))
        if StaticData.Games[data.wKindID] then
            Text_playway:setString(StaticData.Games[data.wKindID].name)
        else
            Text_playway:setString('')
        end
        Text_type:setString('游戏消耗')
        Text_xnum:setString('-' .. data.lFatigue)
        Text_snum:setString(data.lNewFatigue)
        Text_des:setString('均摊')

    elseif data.cbType == 7 then
        --疲劳值收益
        local item = self.Panel_item:clone()
        listview:pushBackCustomItem(item)
        listview:refreshView()
        local Text_time = ccui.Helper:seekWidgetByName(item, "Text_time")
        local Text_type = ccui.Helper:seekWidgetByName(item, "Text_type")
        local Text_playway = ccui.Helper:seekWidgetByName(item, "Text_playway")
        local Text_xnum = ccui.Helper:seekWidgetByName(item, "Text_xnum")
        local Text_snum = ccui.Helper:seekWidgetByName(item, "Text_snum")
        local Text_des = ccui.Helper:seekWidgetByName(item, "Text_des")
        Text_time:setColor(cc.c3b(131, 88, 45))
        Text_type:setColor(cc.c3b(131, 88, 45))
        Text_playway:setColor(cc.c3b(131, 88, 45))
        Text_xnum:setColor(cc.c3b(131, 88, 45))
        Text_snum:setColor(cc.c3b(131, 88, 45))
        Text_des:setColor(cc.c3b(131, 88, 45))
        Text_time:setString(os.date('%m-%d %H:%M', data.dwOperTime))
        if StaticData.Games[data.wKindID] then
        	Text_playway:setString(StaticData.Games[data.wKindID].name)
        else
        	Text_playway:setString('')
        end
        Text_type:setString('游戏收益')
	    Text_xnum:setString('+' .. data.lFatigue)
	    Text_snum:setString(data.lNewFatigue)
        local name = Common:getShortName(data.szOriginNickName, 14 , 7)
	    Text_des:setString(string.format('%s(%d)贡献收益', name, data.dwOriginID))

    elseif data.cbType == 8 or data.cbType == 9 then
        --8玩家赠送疲劳值 9玩家受赠疲劳值
        local item = self.Panel_item:clone()
        listview:pushBackCustomItem(item)
        listview:refreshView()
        local Text_time = ccui.Helper:seekWidgetByName(item, "Text_time")
        local Text_type = ccui.Helper:seekWidgetByName(item, "Text_type")
        local Text_playway = ccui.Helper:seekWidgetByName(item, "Text_playway")
        local Text_xnum = ccui.Helper:seekWidgetByName(item, "Text_xnum")
        local Text_snum = ccui.Helper:seekWidgetByName(item, "Text_snum")
        local Text_des = ccui.Helper:seekWidgetByName(item, "Text_des")
        Text_time:setColor(cc.c3b(131, 88, 45))
        Text_type:setColor(cc.c3b(131, 88, 45))
        Text_playway:setColor(cc.c3b(131, 88, 45))
        Text_xnum:setColor(cc.c3b(131, 88, 45))
        Text_snum:setColor(cc.c3b(131, 88, 45))
        Text_des:setColor(cc.c3b(131, 88, 45))
        Text_time:setString(os.date('%m-%d %H:%M', data.dwOperTime))

        if StaticData.Games[data.wKindID] then
            Text_playway:setString(StaticData.Games[data.wKindID].name)
        else
            Text_playway:setString('')
        end

        Text_type:setString('疲劳值')

        if data.cbType == 8 then
            Text_xnum:setString(data.lFatigue)
            Text_snum:setString(data.lNewFatigue)
            local name = Common:getShortName(data.szOriginNickName, 14 , 7)
            Text_des:setString(string.format('给%s(%d)赠送', name, data.dwOriginID))
        elseif data.cbType == 9 then
            Text_xnum:setString(data.lFatigue)
            Text_snum:setString(data.lNewFatigue)
            local name = Common:getShortName(data.szOriginNickName, 14 , 7)
            Text_des:setString(string.format('%s(%d)给我赠送', name, data.dwOriginID))
        end
    end
end

function NewClubFatigueLayer:RET_GET_CLUB_MEMBER_FATIGUE_RECORD_FINISH(event)
    local data = event._usedata
    if data.isFinish then
        self.recordState = 2
    else
        self.recordState = 1
    end
    self.recordPage = self.recordPage + 1
end

function NewClubFatigueLayer:RET_GET_CLUB_NOT_PARTNER_MEMBER(event)
    local data = event._usedata
    local item = self.Image_item:clone()
    if data.dwUserID == UserData.User.userID then
        return
    else
        self.ListView_mem:pushBackCustomItem(item)
    end
    self.ListView_mem:refreshView()
    item:setName('fatigue_' .. data.dwUserID)
    self:loadMemerItem(item, data)
end

function NewClubFatigueLayer:RET_GET_CLUB_NOT_PARTNER_MEMBER_FINISH(event)
    local data = event._usedata
    if data.isFinish then
        self.memberState = 2
    else
        self.memberState = 1
    end
    self.memberPage = self.memberPage + 1
end

--返回修改亲友圈成员
function NewClubFatigueLayer:RET_SETTINGS_CLUB_MEMBER(event)
    local data = event._usedata
    if data.lRet ~= 0 then
        if data.lRet == 1 then
            require("common.MsgBoxLayer"):create(0,nil,"亲友圈不存在!")
        elseif data.lRet == 2 then
            require("common.MsgBoxLayer"):create(0,nil,"亲友圈成员不存在!")
        elseif data.lRet == 3 then
            require("common.MsgBoxLayer"):create(0,nil,"亲友圈合伙人已达人数上限!")
        elseif data.lRet == 4 then
            require("common.MsgBoxLayer"):create(0,nil,"普通成员才可以设置为合伙人!")
        elseif data.lRet == 5 then
            require("common.MsgBoxLayer"):create(0,nil,"您的权限不足!")
        elseif data.lRet == 6 then
            require("common.MsgBoxLayer"):create(0,nil,"权限不足,只有合伙人才能设置!")
        elseif data.lRet == 7 then
            require("common.MsgBoxLayer"):create(0,nil,"合伙人疲劳值不足!")
        elseif data.lRet == 8 then
            require("common.MsgBoxLayer"):create(0,nil,"目标玩家疲劳值不足!")
        elseif data.lRet == 9 then
            require("common.MsgBoxLayer"):create(0,nil,"合伙人的疲劳值不够扣!")
        elseif data.lRet == 10 then
            require("common.MsgBoxLayer"):create(0,nil,"参数错误!")
        elseif data.lRet == 11 then
            require("common.MsgBoxLayer"):create(0,nil,"比例超过最大限!")
        elseif data.lRet == 12 then
            require("common.MsgBoxLayer"):create(0,nil,"超层级上限不能设置合伙人!")
        elseif data.lRet == 13 then
            require("common.MsgBoxLayer"):create(0,nil,"防沉迷不等于0不得设置!")
        elseif data.lRet == 100 then
            require("common.MsgBoxLayer"):create(0,nil,"对局中不能减少疲劳值!")
        else
            require("common.MsgBoxLayer"):create(0,nil,"设置错误! code=" .. data.lRet)
        end
        return
    end

    if data.cbSettingsType == 7 then
        --交易疲劳值
        dump(data, '疲劳值交易:')
        local item = self.ListView_mem:getChildByName('fatigue_' .. data.dwUserID)
        if item then
            local Text_snum = self:seekWidgetByNameEx(item, "Text_snum")
            Text_snum:setString(data.lFatigueValue)
            require("common.MsgBoxLayer"):create(0,nil,"疲劳值操作成功")
        end
        local curNum = tonumber(self.Text_fatigueNum:getString())
        self.Text_fatigueNum:setString(curNum - self.curJYValue)
    end
end

function NewClubFatigueLayer:RET_CLUB_MEMBER_INFO(event)
    local data = event._usedata
    if data.dwClubID == 0 then
        require("common.MsgBoxLayer"):create(0,nil,"用户不存在!")
        return
    end
    
    self.ListView_mem:setVisible(false)
	self.ListView_find:setVisible(true)
	self.Button_findMem:setVisible(false)
	self.Button_return:setVisible(true)
    self.ListView_find:removeAllItems()
    local item = self.Image_item:clone()
    self.ListView_find:pushBackCustomItem(item)
    self.ListView_find:refreshView()
    item:setName('fatigue_' .. data.dwUserID)
    self:loadMemerItem(item, data)
end

return NewClubFatigueLayer