local EventMgr = require("common.EventMgr")
local EventType = require("common.EventType")
local NetMgr = require("common.NetMgr")
local StaticData = require("app.static.StaticData")
local UserData = require("app.user.UserData")
local Common = require("common.Common")
local Bit = require("common.Bit")
local HttpUrl = require("common.HttpUrl")

local NewMallLayer = class("NewMallLayer", cc.load("mvc").ViewBase)

function NewMallLayer:onEnter()

end

function NewMallLayer:onExit()
end

function NewMallLayer:onCreate(parames)

    local visibleSize = cc.Director:getInstance():getVisibleSize()
    local csb = cc.CSLoader:createNode("NewMallLayer.csb")
    self:addChild(csb)
    self.root = csb:getChildByName("Panel_root")
    self.csb = csb
    
    Common:addTouchEventListener(ccui.Helper:seekWidgetByName(self.root,"Button_return"),function() 
        self:removeFromParent()
    end)   
    local uiText_contents = ccui.Helper:seekWidgetByName(self.root,"Text_contents")
    uiText_contents:setString("")

    for i = 1 ,5 do 
       local item = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_daili%d", i))
       local uiText_wixin = ccui.Helper:seekWidgetByName(item,"Text_wixin")
        Common:addTouchEventListener(ccui.Helper:seekWidgetByName(item,"Button_copy"),function()   
            local btnName =  uiText_wixin:getString()
            UserData.User:copydata(btnName)
            require("common.MsgBoxLayer"):create(0,nil,"复制成功")
        end) 
    end 

end


return NewMallLayer