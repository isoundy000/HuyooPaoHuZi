local EventMgr = require("common.EventMgr")
local EventType = require("common.EventType")
local NetMgr = require("common.NetMgr")
local NetMsgId = require("common.NetMsgId")
local UserData = require("app.user.UserData")
local Common = require("common.Common")
local StaticData = require("app.static.StaticData")
local NetMsgId = require("common.NetMsgId")


local PositionLayer = class("PositionLayer", function()
    return ccui.Layout:create()
end)


function PositionLayer:create(wKindID)
    local view = PositionLayer.new()
    view:onCreate(wKindID)
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

function PositionLayer:onEnter()
    EventMgr:registListener(EventType.RET_GAMES_USER_POSITION,self,self.RET_GAMES_USER_POSITION)
end

function PositionLayer:onExit()
    EventMgr:unregistListener(EventType.RET_GAMES_USER_POSITION,self,self.RET_GAMES_USER_POSITION)
end

function PositionLayer:onCleanup()
end

function PositionLayer:onCreate(wKindID)
    EventMgr:registListener(EventType.RET_GAMES_USER_POSITION,self,self.RET_GAMES_USER_POSITION)
    local visibleSize = cc.Director:getInstance():getVisibleSize()
    local csb = cc.CSLoader:createNode("YZPositionLayer.csb")
    self:addChild(csb)
    self.root = csb:getChildByName("Panel_root")
    
    local uiButton_return = ccui.Helper:seekWidgetByName(self.root,"Button_return")
    Common:addTouchEventListener(uiButton_return,function() 
        EventMgr:unregistListener(EventType.RET_GAMES_USER_POSITION,self,self.RET_GAMES_USER_POSITION)
        self:removeFromParent()
    end,true)

    self:show(wKindID)
    
    require("common.SceneMgr"):switchOperation(self)
end

function PositionLayer:show(wKindID)
    local visibleSize = cc.Director:getInstance():getVisibleSize()
    local uiImage_playerInfoBg3 = ccui.Helper:seekWidgetByName(self.root,"Image_playerInfoBg3")
    local uiImage_playerInfoBg4 = ccui.Helper:seekWidgetByName(self.root,"Image_playerInfoBg4")
    uiImage_playerInfoBg3:setVisible(false)
    uiImage_playerInfoBg4:setVisible(false)
    local uiPanel_playerInfoBg = nil 
    local GameCommon  = nil 
    
    if StaticData.Games[wKindID].type == 1 then
        GameCommon = require("game.yongzhou.GameCommon") 
    elseif StaticData.Games[wKindID].type == 2 then
        GameCommon = require("game.puke.GameCommon")    
    elseif StaticData.Games[wKindID].type == 3 then 
        GameCommon = require("game.majiang.GameCommon")
    else
        return
    end

    if GameCommon.gameConfig.bPlayerCount == 4 then
        uiImage_playerInfoBg4:setVisible(true)
        uiPanel_playerInfoBg = uiImage_playerInfoBg4   
    else        
        uiImage_playerInfoBg3:setVisible(true)
        uiPanel_playerInfoBg = uiImage_playerInfoBg3
    end      

    local wChairID = 0

    for key, var in pairs(GameCommon.player) do
        if var.dwUserID == GameCommon.dwUserID then
            wChairID = var.wChairID
            break
        end
    end
    for wChairID = 1, GameCommon.gameConfig.bPlayerCount do
        local uiPanel_players = ccui.Helper:seekWidgetByName(uiPanel_playerInfoBg,string.format("Panel_player%d",wChairID))
        local uiText_name = ccui.Helper:seekWidgetByName(uiPanel_players,"Text_name")
        uiText_name:setString("") 
        for i = wChairID+1 , GameCommon.gameConfig.bPlayerCount do 
            local  uiText_location = ccui.Helper:seekWidgetByName(uiPanel_playerInfoBg,string.format("Text_%dto%d",wChairID,i)) 
            uiText_location:setString("")       
        end
    end 
    local num = GameCommon.gameConfig.bPlayerCount-1 
    for wChairID = 0, num do            
        local viewID = GameCommon:getViewIDByChairID(wChairID)
        local uiPanel_players = ccui.Helper:seekWidgetByName(uiPanel_playerInfoBg,string.format("Panel_player%d",viewID))
        if GameCommon.player[wChairID] ~= nil then
            uiPanel_players:setVisible(true)
            local uiPanel_playerInfo = ccui.Helper:seekWidgetByName(uiPanel_players,"Panel_playerInfo")
            uiPanel_playerInfo:setVisible(true)

            local uiText_name = ccui.Helper:seekWidgetByName(uiPanel_players,"Text_name")
            uiText_name:setString(GameCommon.player[wChairID].szNickName)
            local Userip = NetMgr:getLogicInstance().cppFunc:int2ip(GameCommon.player[wChairID].dwPlayAddr)
            -- local uiText_ip = ccui.Helper:seekWidgetByName(uiPanel_players,"Text_ip")
            -- uiText_ip:setString(Userip)              
            local uiText_ip = ccui.Helper:seekWidgetByName(uiPanel_players,"Text_ip")     
            if GameCommon.player[wChairID].dwPlayAddr ~= 0 then  
                uiText_ip:setString( string.format("IP:%s",Userip))
                else
                uiText_ip:setString("")
            end   
            for wTargetChairID = 0, num do
                local targetViewID = GameCommon:getViewIDByChairID(wTargetChairID)
                if GameCommon.gameConfig.bPlayerCount == 3 and wTargetChairID == 3 then
                    viewID = 4
                end
                if wTargetChairID ~= wChairID then
                    local uiText_location = ccui.Helper:seekWidgetByName(uiPanel_playerInfoBg,string.format("Text_%dto%d",viewID,targetViewID))
                    if viewID > targetViewID then
                        uiText_location = ccui.Helper:seekWidgetByName(uiPanel_playerInfoBg,string.format("Text_%dto%d",targetViewID,viewID))
                    end
                    if uiText_location ~= nil then
                        local distance = uiText_location:getString()
                        if GameCommon.gameConfig.bPlayerCount == 3 and (wChairID == 3 or wTargetChairID == 3) then
                            distance = ""
                        elseif GameCommon.player[wChairID] == nil or GameCommon.player[wTargetChairID] == nil then
                            distance = "等待加入..."
                        elseif GameCommon.tableConfig.nTableType == TableType_GoldRoom or GameCommon.tableConfig.nTableType == TableType_SportsRoom then
                            if distance == "500m" then
                                distance = math.random(1000,300000)
                            end
                        elseif GameCommon.player[wChairID].location.x < 0.1 then
                            distance =""-- string.format("%s\n未开启定位",GameCommon.player[wChairID].szNickName)
                        elseif GameCommon.player[wTargetChairID].location.x < 0.1 then
                            distance =""-- string.format("%s\n未开启定位",GameCommon.player[wTargetChairID].szNickName)
                        else
                            distance = GameCommon:GetDistance(GameCommon.player[wChairID].location,GameCommon.player[wTargetChairID].location) 
                        end                     
                        if type(distance) == "string" then

                        elseif distance > 1000 then
                            distance = string.format("%dkm",distance/1000)
                        else
                            distance = string.format("%dm",distance)
                        end
                        uiText_location:setString(distance)
                    end
                end
            end
        else
            uiPanel_players:setVisible(false)
            for wTargetChairID = 0, num do
                local targetViewID = GameCommon:getViewIDByChairID(wTargetChairID)
                if GameCommon.gameConfig.bPlayerCount == 3 and wTargetChairID == 3 then
                    viewID = 4
                end
                if wTargetChairID ~= wChairID then
                    local uiText_location = ccui.Helper:seekWidgetByName(uiPanel_playerInfoBg,string.format("Text_%dto%d",viewID,targetViewID))
                    if viewID > targetViewID then
                        uiText_location = ccui.Helper:seekWidgetByName(uiPanel_playerInfoBg,string.format("Text_%dto%d",targetViewID,viewID))
                    end  
                    uiText_location:setString("")
                end
            end
        end
    end
end 
function PositionLayer:RET_GAMES_USER_POSITION(event)
    self:show()
end
return PositionLayer
    