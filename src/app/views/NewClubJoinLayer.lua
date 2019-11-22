--[[
*名称:NewClubJoinLayer
*描述:加入亲友圈
*作者:admin
*创建日期:2018-06-14 18:07:55
*修改日期:
]]

local EventMgr              = require("common.EventMgr")
local EventType             = require("common.EventType")
local NetMgr                = require("common.NetMgr")
local NetMsgId              = require("common.NetMsgId")
local StaticData            = require("app.static.StaticData")
local UserData              = require("app.user.UserData")
local Common                = require("common.Common")
local Default               = require("common.Default")
local GameConfig            = require("common.GameConfig")
local Log                   = require("common.Log")

local NewClubJoinLayer      = class("NewClubJoinLayer", cc.load("mvc").ViewBase)

function NewClubJoinLayer:onConfig()
    self.widget             = {
        {"Button_close", "onClose"},
    }
end

function NewClubJoinLayer:onEnter()
    EventMgr:registListener(EventType.RET_JOIN_CLUB,self,self.RET_JOIN_CLUB)
end

function NewClubJoinLayer:onExit()
    EventMgr:unregistListener(EventType.RET_JOIN_CLUB,self,self.RET_JOIN_CLUB)
end

function NewClubJoinLayer:onCreate()
    self.root = self.csb:getChildByName("Image_bg")
    if self.root then
        self:initUI()
    end
end

function NewClubJoinLayer:onClose()
    self:removeFromParent()
end

------------------------------------------------------------------------
--                            game logic                              --
------------------------------------------------------------------------
function NewClubJoinLayer:initUI()
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
        local Button_num = ccui.Helper:seekWidgetByName(self.root, btnName)
        Button_num:setPressedActionEnabled(true)
        Button_num:addTouchEventListener(onEventInput)
        Button_num.index = i
    end
end

--加入亲友圈请求
function NewClubJoinLayer:sendJoinClub(dwClubID)
    local dwClubID = tonumber(dwClubID)
    UserData.Guild:joinClub(dwClubID)
end

--重置数字
function NewClubJoinLayer:resetNumber()
    for i = 1 , 8 do
        local numName = string.format("Text_number%d", i)
        local Text_number = ccui.Helper:seekWidgetByName(self.root, numName)
        if Text_number then
            Text_number:setString("")
        end
    end
end

--输入数字
function NewClubJoinLayer:inputNumber(num)
    local roomNumber = ""
    for i = 1 , 8 do
        local numName = string.format("Text_number%d", i)
        local Text_number = ccui.Helper:seekWidgetByName(self.root, numName)
        if Text_number:getString() == "" then
            Text_number:setString(tostring(num))
            roomNumber = roomNumber .. Text_number:getString()
            if i == 8 then  
                self:sendJoinClub(roomNumber)                      
            end
            break
        else
            roomNumber = roomNumber .. Text_number:getString()
        end
    end
end

--删除数字
function NewClubJoinLayer:deleteNumber()
    for i = 8 , 1 , -1 do
        local numName = string.format("Text_number%d", i)
        local Text_number = ccui.Helper:seekWidgetByName(self.root, numName)
        if Text_number:getString() ~= "" then
            Text_number:setString("")
            break
        end
    end
end

------------------------------------------------------------------------
--                            server rvc                              --
------------------------------------------------------------------------
function NewClubJoinLayer:RET_JOIN_CLUB(event)
    local data = event._usedata
    if data.lRet == 0 then
        require("common.MsgBoxLayer"):create(2,nil,"申请成功,等待群主审核!")
        self:removeFromParent()
    elseif data.lRet == 1 then 
        require("common.MsgBoxLayer"):create(0,nil,"亲友圈ID输入错误!")
    elseif data.lRet == 2 then
        require("common.MsgBoxLayer"):create(0,nil,"您已经存在该亲友圈,不可重复提交申请!")
        self:removeFromParent()
    else
        require("common.MsgBoxLayer"):create(0,nil,"申请加入失败,请升级到最新版本!")
        self:removeFromParent()
    end
end

return NewClubJoinLayer