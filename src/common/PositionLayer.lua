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

end

function PositionLayer:onExit()
    
end

function PositionLayer:onCleanup()
end

function PositionLayer:onCreate(wKindID)
    local visibleSize = cc.Director:getInstance():getVisibleSize()
    local csb = cc.CSLoader:createNode("PositionLayer.csb")
    self:addChild(csb)
    self.root = csb:getChildByName("Panel_root")
    
    local uiImage_playerInfoBg = ccui.Helper:seekWidgetByName(self.root,"Image_playerInfoBg")
--    Common:playPopupAnim(uiImage_playerInfoBg)
    Common:addTouchEventListener(self.root,function() 
        self:removeFromParent()
    end,true)
    local visibleSize = cc.Director:getInstance():getVisibleSize()
    local uiImage_playerInfoBg = ccui.Helper:seekWidgetByName(self.root,"Image_playerInfoBg")
    local wChairID = 0
    local GameCommon = nil
    if wKindID == 32 then
       GameCommon = require("game.yongzhou.GameCommon") 
    elseif StaticData.Games[wKindID].type == 1 then
        GameCommon = require("game.paohuzi.GameCommon")
    elseif StaticData.Games[wKindID].type == 2 then
        GameCommon = require("game.puke.GameCommon")    
    elseif StaticData.Games[wKindID].type == 3 then 
        GameCommon = require("game.majiang.GameCommon")
    else
        return
    end
    
    for key, var in pairs(GameCommon.player) do
        if var.dwUserID == GameCommon.dwUserID then
            wChairID = var.wChairID
            break
        end
    end
    if wKindID == 42 then       
        GameCommon.gameConfig = {}  
        GameCommon.gameConfig.bPlayerCount = 4
    end  
    if GameCommon.gameConfig.bPlayerCount ~= 4 then
        local uiPanel_player4 = ccui.Helper:seekWidgetByName(self.root,"Panel_player4")
        uiPanel_player4:setVisible(false)
    end
   if GameCommon.gameConfig.bPlayerCount == 2 then
        if StaticData.Games[wKindID].type == 1 then
            local uiPanel_player3 = ccui.Helper:seekWidgetByName(self.root,"Panel_player3")
            uiPanel_player3:setVisible(false)
        else
            local uiPanel_player2 = ccui.Helper:seekWidgetByName(self.root,"Panel_player2")
            uiPanel_player2:setVisible(false)
        end 
    end
    local viewID = GameCommon:getViewIDByChairID(wChairID) 
    for wChairID = 0, 3 do
        if GameCommon.player[wChairID] ~= nil then
            local viewID = GameCommon:getViewIDByChairID(wChairID)
            local uiPanel_player = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_player%d",viewID))
            local uiPanel_playerInfo = ccui.Helper:seekWidgetByName(uiPanel_player,"Panel_playerInfo")
            uiPanel_playerInfo:setVisible(true)
            local uiImage_avatar = ccui.Helper:seekWidgetByName(uiPanel_player,"Image_avatar")
            Common:requestUserAvatar(GameCommon.player[wChairID].dwUserID,GameCommon.player[wChairID].szPto,uiImage_avatar,"img")
            local uiText_name = ccui.Helper:seekWidgetByName(uiPanel_player,"Text_name")
            uiText_name:setString(GameCommon.player[wChairID].szNickName)
            local uiText_ID = ccui.Helper:seekWidgetByName(uiPanel_player,"Text_ID")
            uiText_ID:setVisible(false)
            if GameCommon.player[wChairID].dwOhterID ~= nil and GameCommon.player[wChairID].dwOhterID ~= 0 then
                uiText_ID:setString(string.format("%d",GameCommon.player[wChairID].dwOhterID))
            else
                uiText_ID:setString(string.format("%d",GameCommon.player[wChairID].dwUserID))
            end
            local uiImage_gender = ccui.Helper:seekWidgetByName(uiPanel_player,"Image_gender")
            if GameCommon.player[wChairID].cbSex == 0 then
                uiImage_gender:loadTexture("user/user_g.png")
            end
            for wTargetChairID = 0, GameCommon.gameConfig.bPlayerCount-1 do
                local targetViewID = GameCommon:getViewIDByChairID(wTargetChairID)
                if GameCommon.gameConfig.bPlayerCount == 3 and wTargetChairID == 3 then
                    viewID = 4
                end
                if wTargetChairID ~= wChairID then
                    local uiText_location = ccui.Helper:seekWidgetByName(self.root,string.format("Text_%dto%d",viewID,targetViewID))
                    if viewID > targetViewID then
                        uiText_location = ccui.Helper:seekWidgetByName(self.root,string.format("Text_%dto%d",targetViewID,viewID))
                    end
                    if GameCommon.gameConfig.bPlayerCount == 2 then                
                        if StaticData.Games[wKindID].type == 1 then
                            uiText_location = ccui.Helper:seekWidgetByName(self.root,string.format("Text_%dto%d",1,2))
                        else
                            uiText_location = ccui.Helper:seekWidgetByName(self.root,string.format("Text_%dto%d",1,3))
                        end 
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
                            distance = string.format("%s未开启定位",GameCommon.player[wChairID].szNickName)
                        elseif GameCommon.player[wTargetChairID].location.x < 0.1 then
                            distance = string.format("%s未开启定位",GameCommon.player[wTargetChairID].szNickName)
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
        end
    end
    require("common.SceneMgr"):switchOperation(self)
end

return PositionLayer
    