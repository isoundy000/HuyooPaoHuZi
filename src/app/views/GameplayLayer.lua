local Common = require("common.Common")
local StaticData = require("app.static.StaticData")
local UserData = require("app.user.UserData")
local EventType = require("common.EventType")
local EventMgr = require("common.EventMgr")
local NetMgr = require("common.NetMgr")
local NetMsgId = require("common.NetMsgId")
local Default = require("common.Default")
local Bit = require("common.Bit")


local GameplayLayer = class("GameplayLayer", cc.load("mvc").ViewBase)

function GameplayLayer:onEnter()

end

function GameplayLayer:onExit()

end

function GameplayLayer:onCreate(parameter)
    local locationID = parameter[1]
    self.showType    = parameter[2]    --显示类型  0默认     1设置亲友圈参数  2亲友圈自定义创房 3竞技场设置玩法
    self.dwClubID = parameter[3]
    NetMgr:getGameInstance():closeConnect()
    self.tableFriendsRoomParams = nil
    local visibleSize = cc.Director:getInstance():getVisibleSize()
    local csb = cc.CSLoader:createNode("RoomCreateLayer.csb")
    self:addChild(csb)
    self.root = csb:getChildByName("Panel_root")
    Common:addTouchEventListener(ccui.Helper:seekWidgetByName(self.root,"Button_return"),function(sender,event) self:removeFromParent() end)
    
    
    local uiImage_biaoqian = ccui.Helper:seekWidgetByName(self.root,"Image_biaoqian")
    uiImage_biaoqian:loadTexture("newroom/newroom_1.png")
    local uiListView_games = ccui.Helper:seekWidgetByName(self.root,"ListView_games")
    --  列表间距              uiListView_betting:setItemsMargin(10)
    local regionID = cc.UserDefault:getInstance():getIntegerForKey(Default.UserDefault_RegionID,0)
    if locationID == nil or locationID == 0 and UserData.Game.talbeCommonGames[1]~= 51 and UserData.Game.talbeCommonGames[1]~= 53 then
        locationID = UserData.Game.talbeCommonGames[1]
    end
    local uiImage_1 = ccui.Helper:seekWidgetByName(self.root,"Image_1")      
    local uiImage_3 = ccui.Helper:seekWidgetByName(self.root,"Image_3")      
    uiImage_1:setVisible(false)
    uiImage_3:setVisible(false)
    local uiButton_zipai = ccui.Helper:seekWidgetByName(self.root,"Button_zipai")      
    local uiButton_majiang = ccui.Helper:seekWidgetByName(self.root,"Button_majiang")  
    local uiButton_puke = ccui.Helper:seekWidgetByName(self.root,"Button_puke") 

    local uiPanel_parameter = ccui.Helper:seekWidgetByName(self.root,"Panel_parameter")
    local uiPanel_para = ccui.Helper:seekWidgetByName(self.root,"Panel_para")
    uiPanel_parameter:setVisible(false)

    local uiButton_iten = ccui.Helper:seekWidgetByName(self.root,"Button_iten")
    uiButton_iten:retain()
    uiButton_iten:setVisible(false)

    local function showGameType(type)
        if type == 1 then
            uiButton_zipai:setBright(true)
            uiButton_majiang:setBright(false)
            uiButton_puke:setBright(false)      
        elseif type == 2 then
            uiButton_zipai:setBright(false)
            uiButton_majiang:setBright(false)
            uiButton_puke:setBright(true)
        elseif type == 3 then
            uiButton_zipai:setBright(false)
            uiButton_majiang:setBright(true)
            uiButton_puke:setBright(false)
        end

        uiListView_games:removeAllItems()
        local games = {}
        games = clone(UserData.Game.tableSortGames)
        local isFound = false
        for key, var in pairs(games) do
            local wKindID = tonumber(var)
            local data = StaticData.Games[wKindID]
            if UserData.Game.tableGames[wKindID] ~= nil and Bit:_and(data.friends,1) ~= 0 and (data.type == type or type == nil ) and wKindID ~= 51 and wKindID ~= 53 then
                local img1 = "newroom/createv2_zuoqieye_liang.png" 
                local img2 = "newroom/createv2_zuoqieye_putong.png" 
                local item = uiButton_iten:clone()
                item.wKindID = wKindID
                item:setBright(false)
                item:setVisible(true)
                local uiImage_icon1 = ccui.Helper:seekWidgetByName(item,"Image_icon1")
                local uiImage_icon2 = ccui.Helper:seekWidgetByName(item,"Image_icon2")
                uiImage_icon1:loadTexture(data.icon1)
                uiImage_icon2:loadTexture(data.icons)
                uiImage_icon1:setVisible(false)
                uiImage_icon2:setVisible(true)
                uiListView_games:pushBackCustomItem(item)
                item:setAnchorPoint(cc.p(0,0.5))
                Common:addTouchEventListener(item,function() self:showGameParameter(wKindID) end)
                if wKindID == locationID then
                    isFound = true
                end
            end 
        end
        if isFound == true then
            local btn = self:showGameParameter(locationID)
            if btn ~= nil then
                btn:runAction(cc.Sequence:create(cc.DelayTime:create(0),cc.CallFunc:create(function(sender,event)
                    --位置刷新
                    uiListView_games:refreshView()
                    local container = uiListView_games:getInnerContainer()
                    local pos = cc.p(btn:getPosition())
                    pos = cc.p(btn:getParent():convertToWorldSpace(pos))
                    pos = cc.p(container:convertToNodeSpace(pos))
                    local value = (1-pos.y/container:getContentSize().height)*100
                    if value <= 5 then
                        value = 0
                    elseif value >= 95 then
                        value = 100
                    end
                    uiListView_games:scrollToPercentVertical(value,1,true)
                end)))
            end
        else
            local item = uiListView_games:getItem(0)
            if item ~= nil then
                self:showGameParameter(item.wKindID)
            end
        end
    end 

    Common:addTouchEventListener(uiButton_zipai,function() showGameType(1) end)
    Common:addTouchEventListener(uiButton_puke,function() showGameType(2) end)
    Common:addTouchEventListener(uiButton_majiang,function() showGameType(3) end)
    if  #UserData.Game.tableSortGames <= 5 then  
        showGameType()
    else
        if locationID == nil or locationID == 0 or UserData.Game.tableGames[locationID] == nil then
            showGameType(1)
        else
            showGameType(StaticData.Games[locationID].type)
        end
    end
end

function GameplayLayer:showGameParameter(wKindID)
    local uiListView_games = ccui.Helper:seekWidgetByName(self.root,"ListView_games")
    local items = uiListView_games:getItems()
    local node = nil
    for key, var in pairs(items) do
        local uiImage_icon1 = ccui.Helper:seekWidgetByName(var,"Image_icon1")
        local uiImage_icon2 = ccui.Helper:seekWidgetByName(var,"Image_icon2")
    	if var.wKindID == wKindID then
    	   if var:isBright() then
    	       return nil
    	   end
    	   node = var
           var:setBright(true)
           uiImage_icon1:setVisible(true)
           uiImage_icon2:setVisible(false)
    	else
            var:setBright(false)
            uiImage_icon1:setVisible(false)
            uiImage_icon2:setVisible(true)
        end
    end                       
    if PLATFORM_TYPE ~= cc.PLATFORM_OS_DEVELOPER then

        local uiPanel_para = ccui.Helper:seekWidgetByName(self.root,"Panel_para")
        uiPanel_para:removeAllChildren()  
        local uiWebView = ccexp.WebView:create()
        uiPanel_para:addChild(uiWebView)
        uiWebView:setContentSize(uiPanel_para:getContentSize())
        uiWebView:setAnchorPoint(cc.p(0.5,0.5))
        uiWebView:setPosition(uiWebView:getParent():getContentSize().width/2,uiWebView:getParent():getContentSize().height/2)
        uiWebView:setScalesPageToFit(true)
        uiWebView:loadURL(StaticData.Games[wKindID].ruleCSB)
        --uiWebView:enableDpadNavigation(false)
    end
    return node
end

return GameplayLayer
