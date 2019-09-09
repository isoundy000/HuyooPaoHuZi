local Common = require("common.Common")
local NetMgr = require("common.NetMgr")
local NetMsgId = require("common.NetMsgId")
local MsgBoxLayer = class("MsgBoxLayer", function()
    return cc.Node:create()
end)

--@param    type: 0文本提示   1确定取消  2确定  3同意拒绝 
--@return   node: 制定加入的父节点
--require("common.MsgBoxLayer"):create(0,nil,"恭喜您获得1000金币")
--require("common.MsgBoxLayer"):create(1,nil,"您确定要退出游戏？",okCallback,cancelCallback)
--require("common.MsgBoxLayer"):create(2,nil,"请稍后...",okCallback)
--require("common.MsgBoxLayer"):create(3,nil,"是否同意该协议？",agreeCallback,refuseCallback)
--require("common.MsgBoxLayer"):create(4,nil,"是否同意解散？") --兼顾解散特例

function MsgBoxLayer:create(type,node,...)
    local view = MsgBoxLayer.new()
    view:onCreate(type,node,...)
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

function MsgBoxLayer:onEnter()

end

function MsgBoxLayer:onExit()

end

function MsgBoxLayer:onCleanup()

end

function MsgBoxLayer:onCreate(type,node,...)
    local visibleSize = cc.Director:getInstance():getVisibleSize()
    local csb = cc.CSLoader:createNode("YZMsgBoxLayer.csb")
    self:addChild(csb)
    self.root = csb:getChildByName("Panel_root")
    self.csb = csb
    local params = {...} 
    local uiPanel_ok = ccui.Helper:seekWidgetByName(self.root,"Panel_ok")
    local uiPanel_okCancel = ccui.Helper:seekWidgetByName(self.root,"Panel_okCancel")
    local uiPanel_agreeCancel = ccui.Helper:seekWidgetByName(self.root,"Panel_agreeCancel")
    local uiPanel_tips = ccui.Helper:seekWidgetByName(self.root,"Panel_tips")
    local uiPanel_Blackscreen = ccui.Helper:seekWidgetByName(self.root,"Panel_Blackscreen")
    if type == 0 then
        --文本提示
        uiPanel_ok:removeFromParent()
        uiPanel_okCancel:removeFromParent()
        uiPanel_agreeCancel:removeFromParent()
        uiPanel_tips:setVisible(true)
        uiPanel_Blackscreen:setVisible(false)
        local uiPanel_tipsBg = ccui.Helper:seekWidgetByName(self.root,"Panel_tipsBg")
        local uiText_contents = ccui.Helper:seekWidgetByName(self.root,"Text_contents")
        uiText_contents:setString(params[1])
        if uiText_contents:getAutoRenderSize().width + 50 < 600 then 
        else
            uiPanel_tipsBg:setContentSize(cc.size(uiText_contents:getAutoRenderSize().width + 50,50))
        end  
        uiText_contents:setPosition(uiText_contents:getParent():getContentSize().width/2,uiText_contents:getParent():getContentSize().height/2)
        uiPanel_tipsBg:setPosition(visibleSize.width/2,uiPanel_tipsBg:getPositionY())--,cc.MoveBy:create(2,cc.p(0,100))
        uiPanel_tipsBg:setOpacity(0)
        uiPanel_tipsBg:runAction(cc.Sequence:create(cc.FadeIn:create(0.2),cc.DelayTime:create(1.5),cc.FadeOut:create(0.2),cc.CallFunc:create(function(sender,event) self:removeFromParent() end)))
        self.root:setTouchEnabled(false)
    elseif type == 1 then
        --确定取消
        uiPanel_ok:removeFromParent()
        uiPanel_okCancel:setVisible(true)
        uiPanel_agreeCancel:removeFromParent()
        uiPanel_tips:removeFromParent()
        local uiText_contents = ccui.Helper:seekWidgetByName(self.root,"Text_contents")
        uiText_contents:setString(params[1]) 
        local uiButton_ok = ccui.Helper:seekWidgetByName(self.root,"Button_ok")
        Common:addTouchEventListener(uiButton_ok,function() 
            self:removeFromParent()
            if params[2] ~= nil then
                params[2]()
            end
        end)
        local uiButton_cancel = ccui.Helper:seekWidgetByName(self.root,"Button_cancel")
        Common:addTouchEventListener(uiButton_cancel,function() 
            self:removeFromParent()
            if params[3] ~= nil then
                params[3]()
            end
        end)
        self.root:setTouchEnabled(true)
        --Common:playPopupAnim(uiPanel_okCancel)
    elseif type == 2 then
        --确定
        uiPanel_ok:setVisible(true)
        uiPanel_okCancel:removeFromParent()
        uiPanel_agreeCancel:removeFromParent()
        uiPanel_tips:removeFromParent()
        local uiText_contents = ccui.Helper:seekWidgetByName(self.root,"Text_contents")
        uiText_contents:setString(params[1]) 
        local uiButton_ok = ccui.Helper:seekWidgetByName(self.root,"Button_ok")
        Common:addTouchEventListener(uiButton_ok,function()
            self:removeFromParent() 
            if params[2] ~= nil then
                params[2]()
            end
        end)
        self.root:setTouchEnabled(true)
        --Common:playPopupAnim(uiPanel_ok)
    elseif type == 3 then
        --同意取消
        local uiText_contents = ccui.Helper:seekWidgetByName(self.root,"Text_contents")
        uiText_contents:setString(params[1]) 
        local uiButton_agree = ccui.Helper:seekWidgetByName(self.root,"Button_agree")
        Common:addTouchEventListener(uiButton_agree,function()
            self:removeFromParent() 
            if params[2] ~= nil then
                params[2]()
            end
        end)
        local uiButton_refuse = ccui.Helper:seekWidgetByName(self.root,"Button_refuse")
        Common:addTouchEventListener(uiButton_refuse,function() 
            self:removeFromParent()
            if params[3] ~= nil then
                params[3]()
            end
        end)
        self.root:setTouchEnabled(true)
        --Common:playPopupAnim(uiPanel_agreeCancel)
    else
        print("MsgBoxLayer,类型错误!",type)
        return
    end
    
    if node ~= nil then
        node:addChild(self)
    else
        require("common.SceneMgr"):switchTips(self)
    end
end

return MsgBoxLayer
