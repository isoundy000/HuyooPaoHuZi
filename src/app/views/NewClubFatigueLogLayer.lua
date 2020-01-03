--[[
*名称:NewClubFatigueLogLayer
*描述:疲劳值赠送
*作者:admin
*创建日期:2019-10-23 11:53:53
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

local NewClubFatigueLogLayer = class("NewClubFatigueLogLayer", cc.load("mvc").ViewBase)

function NewClubFatigueLogLayer:onConfig()
    self.widget         = {
    	{"Image_frame"},
        {"ListView_score"},
        {"Panel_item"},
    }
end

function NewClubFatigueLogLayer:onEnter()
	EventMgr:registListener(EventType.RET_GET_CLUB_MEMBER_FATIGUE_RECORD ,self,self.RET_GET_CLUB_MEMBER_FATIGUE_RECORD)
    EventMgr:registListener(EventType.RET_GET_CLUB_MEMBER_FATIGUE_RECORD_FINISH ,self,self.RET_GET_CLUB_MEMBER_FATIGUE_RECORD_FINISH)
end

function NewClubFatigueLogLayer:onExit()
	EventMgr:unregistListener(EventType.RET_GET_CLUB_MEMBER_FATIGUE_RECORD ,self,self.RET_GET_CLUB_MEMBER_FATIGUE_RECORD)
    EventMgr:unregistListener(EventType.RET_GET_CLUB_MEMBER_FATIGUE_RECORD_FINISH ,self,self.RET_GET_CLUB_MEMBER_FATIGUE_RECORD_FINISH)
end

function NewClubFatigueLogLayer:onCreate(param)
	self.itemData = param[1]
	Common:registerScriptMask(self.Image_frame, function()
		self:removeFromParent()
	end)

	self.curNewPushID = self.itemData.dwUserID
    self.recordPage = 1
    self.recordState = 0
    UserData.Guild:getClubFatigueRecord(self.itemData.dwClubID,self.itemData.dwUserID,1)
	self.ListView_score:addScrollViewEventListener(handler(self, self.listViewEventListen))
end

function NewClubFatigueLogLayer:listViewEventListen(sender, evenType)
    if evenType == ccui.ScrollviewEventType.scrollToBottom then
        if self.recordState == 1 then
            self.recordState = 0
            UserData.Guild:getClubFatigueRecord(self.itemData.dwClubID,self.curNewPushID,self.recordPage)
        end
    end
end

function NewClubFatigueLogLayer:RET_GET_CLUB_MEMBER_FATIGUE_RECORD(event)
    local data = event._usedata
    dump(data, 'RET_GET_CLUB_MEMBER_FATIGUE_RECORD=')
    local listview = self.ListView_score
    if data.cbType == 4 then
        local item = self.Panel_item:clone()
        listview:pushBackCustomItem(item)
        listview:refreshView()
        local Text_time = ccui.Helper:seekWidgetByName(item, "Text_time")
        local Text_num = ccui.Helper:seekWidgetByName(item, "Text_num")
        Text_time:setColor(cc.c3b(131, 88, 45))
        Text_time:setString(os.date('%Y年%m月%d日 %H:%M:%S', data.dwOperTime))
        if data.lFatigue >= 0 then
            Text_num:setColor(cc.c3b(255, 0, 0))
            Text_num:setString('+' .. data.lFatigue)
        else
            Text_num:setColor(cc.c3b(0, 128, 0))
            Text_num:setString(data.lFatigue)
        end
    end
end

function NewClubFatigueLogLayer:RET_GET_CLUB_MEMBER_FATIGUE_RECORD_FINISH(event)
    local data = event._usedata
    if data.isFinish then
        self.recordState = 2
    else
        self.recordState = 1
    end
    self.recordPage = self.recordPage + 1
end

return NewClubFatigueLogLayer