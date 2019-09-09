local Common = require("common.Common")
local StaticData = require("app.static.StaticData")

local GameChatLayer = class("GameChatLayer", function()
    return ccui.Layout:create()
end)

function GameChatLayer:create(wKindID,expressCallback, quickCallback)
    local view = GameChatLayer.new()
    view:onCreate(wKindID,expressCallback, quickCallback)
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

function GameChatLayer:onEnter()

end

function GameChatLayer:onExit()

end

function GameChatLayer:onCleanup()

end

function GameChatLayer:onCreate(wKindID,expressCallback, quickCallback)    
    local visibleSize = cc.Director:getInstance():getVisibleSize()
    local csb = cc.CSLoader:createNode("YZGameChatLayer.csb")
    self:addChild(csb)
    self.root = csb:getChildByName("Panel_root")
    -- self.root:addTouchEventListener(function(sender,event)
    --     if event == ccui.TouchEventType.ended then
    --         Common:palyButton()
    --         self:removeFromParent()
    --     end
    -- end)

    local uiButton_ruturn = ccui.Helper:seekWidgetByName(self.root,"Button_ruturn")
    Common:addTouchEventListener(uiButton_ruturn,function()
        self:removeFromParent() 
    end)
    local uiPanel_expression = ccui.Helper:seekWidgetByName(self.root,"Panel_expression")
   -- Common:playPopupAnim(uiPanel_expression)
    local Chat = nil
    Chat = require("game.yongzhou.Animation")["Chat"]
 
    local uiListView_quick = ccui.Helper:seekWidgetByName(self.root,"ListView_quick")
    local uiButton_item = uiListView_quick:getItem(0)
    uiButton_item:retain()
    uiListView_quick:removeAllItems()
    for i = 1, #Chat  do   --var in pairs(Chat)
        local item = uiButton_item:clone()
        uiListView_quick:pushBackCustomItem(item)
        local uiText_contents = ccui.Helper:seekWidgetByName(item,"Text_contents")
        uiText_contents:setString(Chat[i].text)
        uiText_contents:setTextColor(cc.c3b(100,69,52))
        Common:addTouchEventListener(item,function() 
            if quickCallback then
                quickCallback(i,Chat[i].text)
            end
            self:removeFromParent()
        end)
    end
    uiButton_item:release()
    for i = 1, 12 do
        local uiButton_item = ccui.Helper:seekWidgetByName(self.root,string.format("Button_item%d",i))
        Common:addTouchEventListener(uiButton_item,function() 
            if expressCallback then
                expressCallback(i-1)
            end
            self:removeFromParent()
        end)
    end
    require("common.SceneMgr"):switchOperation(self)
end

return GameChatLayer   