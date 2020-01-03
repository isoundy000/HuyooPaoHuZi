--[[
*名称:NewClubSellFatigueLayer
*描述:疲劳值赠送
*作者:admin
*创建日期:2019-10-17 14:48:40
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

local NewClubSellFatigueLayer      = class("NewClubSellFatigueLayer", cc.load("mvc").ViewBase)

function NewClubSellFatigueLayer:onConfig()
    self.widget         = {
        {"Button_no", "onNo"},
        {"Button_yes", "onYes"},
        {"TextField_playerId"},
        {"TextField_num"},
    }
end

function NewClubSellFatigueLayer:onEnter()
	EventMgr:registListener(EventType.RET_SETTINGS_CLUB_MEMBER ,self,self.RET_SETTINGS_CLUB_MEMBER)
end

function NewClubSellFatigueLayer:onExit()
	EventMgr:unregistListener(EventType.RET_SETTINGS_CLUB_MEMBER ,self,self.RET_SETTINGS_CLUB_MEMBER)
end

function NewClubSellFatigueLayer:onCreate(param)
	self.clubData = param[1]
end

function NewClubSellFatigueLayer:onNo()
    self:removeFromParent()
end

function NewClubSellFatigueLayer:onYes()
    local dwUserID = tonumber(self.TextField_playerId:getString())
    if not dwUserID then
    	require("common.MsgBoxLayer"):create(0,nil,"输入玩家ID错误!")
    	return
    end

    local value = tonumber(self.TextField_num:getString())
    if not value or value <= 0 then
    	require("common.MsgBoxLayer"):create(0,nil,"输入赠送数量错误!")
    	return
    end

    if value > 1000000 then
        require("common.MsgBoxLayer"):create(0,nil,"您赠送的数量超限!")
        return
    end

    UserData.Guild:reqSettingsClubMember(11, self.clubData.dwClubID, dwUserID, 0, "", value)
end

function NewClubSellFatigueLayer:RET_SETTINGS_CLUB_MEMBER(event)
    local data = event._usedata
    dump(data, 'RET_SETTINGS_CLUB_MEMBER::')
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
        elseif data.lRet == 7 then
    		require("common.MsgBoxLayer"):create(0,nil,"您疲劳值不足!")
        elseif data.lRet == 100 then
            require("common.MsgBoxLayer"):create(0,nil,"对局中不能减少疲劳值")
        else
            require("common.MsgBoxLayer"):create(0,nil,"操作失败!")
        end
        return
    end
    self:removeFromParent()
end

return NewClubSellFatigueLayer