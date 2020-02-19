--[[
*名称:NewClubParnterAddMemLayer
*描述:添加合伙人成员
*作者:admin
*创建日期:2018-11-20 11:30:52
*修改日期:
]]

local EventMgr          = require("common.EventMgr")
local EventType         = require("common.EventType")
local NetMgr            = require("common.NetMgr")
local NetMsgId          = require("common.NetMsgId")
local StaticData        = require("app.static.StaticData")
local UserData          = require("app.user.UserData")
local Common            = require("common.Common")
local Default           = require("common.Default")
local GameConfig        = require("common.GameConfig")
local Log               = require("common.Log")

local NewClubParnterAddMemLayer = class("NewClubParnterAddMemLayer", cc.load("mvc").ViewBase)

function NewClubParnterAddMemLayer:onConfig()
    self.widget         = {
        {"Image_inputFrame"},
        {"Button_addMem", "onAddMem"},
    }
end

function NewClubParnterAddMemLayer:onEnter()
    EventMgr:registListener(EventType.RET_CLUB_GROUP_INVITE ,self,self.RET_CLUB_GROUP_INVITE)
    EventMgr:registListener(EventType.RET_ADD_CLUB_MEMBER,self,self.RET_ADD_CLUB_MEMBER)
end

function NewClubParnterAddMemLayer:onExit()
    EventMgr:unregistListener(EventType.RET_CLUB_GROUP_INVITE ,self,self.RET_CLUB_GROUP_INVITE)
    EventMgr:unregistListener(EventType.RET_ADD_CLUB_MEMBER,self,self.RET_ADD_CLUB_MEMBER)
end

function NewClubParnterAddMemLayer:onCreate(param)
	self.clubData = param[1]
    self.isMegeClub = param[2]
	self:initNumberArea()
	Common:registerScriptMask(self.Image_inputFrame, function()
		self:removeFromParent()
	end)
end

function NewClubParnterAddMemLayer:onAddMem()
	local roomNumber = ""
    for i = 1 , 8 do
        local numName = string.format("Text_number%d", i)
        local Text_number = ccui.Helper:seekWidgetByName(self.Image_inputFrame, numName)
        if Text_number:getString() == "" then
            break;
        else
            roomNumber = roomNumber .. Text_number:getString()
        end
    end

    local inputId = tonumber(roomNumber)
    if not inputId then
        require("common.MsgBoxLayer"):create(0,nil,"输入ID不正确!")
        return
    end

    if self.isMegeClub then
        UserData.Guild:sendClubGroupInvite(self.clubData.dwClubID, UserData.User.userID, inputId)
    else
        UserData.Guild:addClubMember(self.clubData.dwClubID, inputId, UserData.User.userID)
    end
	self:resetNumber()
end

function NewClubParnterAddMemLayer:RET_CLUB_GROUP_INVITE(event)
    local data = event._usedata
    Log.d(data)
    if data.lRet ~= 0 then
        if data.lRet == 1 then
            require("common.MsgBoxLayer"):create(0,nil,"亲友圈不存在")
        elseif data.lRet == 2 then
            require("common.MsgBoxLayer"):create(0,nil,"目标亲友圈不存在")
        elseif data.lRet == 3 then
            require("common.MsgBoxLayer"):create(0,nil,"权限不足")
        elseif data.lRet == 4 then
            require("common.MsgBoxLayer"):create(0,nil,"不能重复邀请")
        else
            require("common.MsgBoxLayer"):create(0,nil,"合群发起失败")
        end
        return
    end
    require("common.MsgBoxLayer"):create(0,nil,"合群发起成功")
end

--返回添加亲友圈成员
function NewClubParnterAddMemLayer:RET_ADD_CLUB_MEMBER(event)
    local data = event._usedata
    dump(data)
    if data.lRet ~= 0 then
        if data.lRet == 1 then
            require("common.MsgBoxLayer"):create(0,self,"ID输入错误!")
        elseif data.lRet == 2 then
            require("common.MsgBoxLayer"):create(0,self,"该成员已在亲友圈内，请勿重复操作!")
        elseif data.lRet == 3 then
            require("common.MsgBoxLayer"):create(0,self,"玩家不存在!")
        elseif data.lRet == 4 then
            require("common.MsgBoxLayer"):create(0,self,"您没有权限导入！")
        elseif data.lRet == 5 then
            require("common.MsgBoxLayer"):create(0,self,"人数已满!")
        else
            require("common.MsgBoxLayer"):create(0,self,"请升级游戏版本!")
        end
        return
    end
    require("common.MsgBoxLayer"):create(0,self,"添加成员成功")
end


------------------------------------------------------------------------
--                            game logic                              --
------------------------------------------------------------------------
function NewClubParnterAddMemLayer:initNumberArea()
    self:resetNumber()

    local function onEventInput(sender,event)
        if event == ccui.TouchEventType.ended then
            Common:palyButton()
            local index = sender.index
            if index == 10 then
                self:resetNumber()
            elseif index == 11 then
                self:deleteNumber()
            else
                self:inputNumber(index)
            end
        end
    end

    for i = 0 , 11 do
        local btnName = string.format("Button_num%d", i)
        local Button_num = ccui.Helper:seekWidgetByName(self.Image_inputFrame, btnName)
        Button_num:setPressedActionEnabled(true)
        Button_num:addTouchEventListener(onEventInput)
        Button_num.index = i
    end
end

--重置数字
function NewClubParnterAddMemLayer:resetNumber()
    for i = 1 , 8 do
        local numName = string.format("Text_number%d", i)
        local Text_number = ccui.Helper:seekWidgetByName(self.Image_inputFrame, numName)
        if Text_number then
            Text_number:setString("")
        end
    end
end

--输入数字
function NewClubParnterAddMemLayer:inputNumber(num)
    local roomNumber = ""
    for i = 1 , 8 do
        local numName = string.format("Text_number%d", i)
        local Text_number = ccui.Helper:seekWidgetByName(self.Image_inputFrame, numName)
        if Text_number:getString() == "" then
            Text_number:setString(tostring(num))
            roomNumber = roomNumber .. Text_number:getString()
            if i == 8 then
                -- UserData.Guild:addClubMember(self.clubData.dwClubID, tonumber(roomNumber), UserData.User.userID)
            end
            break
        else
            roomNumber = roomNumber .. Text_number:getString()
        end
    end
end

--删除数字
function NewClubParnterAddMemLayer:deleteNumber()
    for i = 8 , 1 , -1 do
        local numName = string.format("Text_number%d", i)
        local Text_number = ccui.Helper:seekWidgetByName(self.Image_inputFrame, numName)
        if Text_number:getString() ~= "" then
            Text_number:setString("")
            break
        end
    end
end


return NewClubParnterAddMemLayer