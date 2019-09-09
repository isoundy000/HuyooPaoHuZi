--[[
*名称:CDLocationLayer
*描述:定位
*作者:cxx
*创建日期:2018-07-05 18:07:55
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
local GameCommon            = require("game.cdphz.GameCommon") 

local CDLocationLayer          = class("CDLocationLayer", cc.load("mvc").ViewBase)

function CDLocationLayer:onConfig()
    self.widget             = {
        {"Button_close", "onClose"},
        {"Image_distance2"},
        {"Image_distance3"},
        {"Image_distance4"},
    }
end

function CDLocationLayer:onEnter()
    EventMgr:registListener(EventType.RET_GAMES_USER_POSITION,self,self.RET_GAMES_USER_POSITION)
    
end

function CDLocationLayer:onExit()
    EventMgr:unregistListener(EventType.RET_GAMES_USER_POSITION,self,self.RET_GAMES_USER_POSITION)    
end

function CDLocationLayer:onCreate()
    self:refreshUI()
end

function CDLocationLayer:onClose()
    self:removeFromParent()
end

------------------------------------------------------------------------
--                            game logic                              --
------------------------------------------------------------------------
function CDLocationLayer:refreshUI()
    self.Image_distance2:setVisible(false)
    self.Image_distance3:setVisible(false)
    self.Image_distance4:setVisible(false)
    local playerNum = GameCommon.gameConfig.bPlayerCount
    local rootNode = self['Image_distance' .. playerNum]
    rootNode:setVisible(true)
    self:showPlayerPosition(rootNode, playerNum)
end

function CDLocationLayer:showPlayerPosition(rootNode, playerNum)
    for i = 1, playerNum do
        local uiPanel_players = ccui.Helper:seekWidgetByName(rootNode,string.format("Panel_players%d",i))
        local uiImage_avatar = ccui.Helper:seekWidgetByName(uiPanel_players,"Image_avatar")
        uiImage_avatar:loadTexture("cdzipai/ui/default.png")
        local uiText_name = ccui.Helper:seekWidgetByName(uiPanel_players,"Text_name")
        uiText_name:setString("")
    end
    for wChairID = 0, playerNum - 1 do    
        local viewID = GameCommon:getViewIDByChairID(wChairID)
        local uiPanel_players = ccui.Helper:seekWidgetByName(rootNode,string.format("Panel_players%d",viewID))
        if GameCommon.player[wChairID] then
            uiPanel_players:setVisible(true)
            local uiImage_avatar = ccui.Helper:seekWidgetByName(uiPanel_players,"Image_avatar")
            Common:requestUserAvatar(GameCommon.player[wChairID].dwUserID,GameCommon.player[wChairID].szPto,uiImage_avatar,"img")
            
            local uiText_name = ccui.Helper:seekWidgetByName(uiPanel_players,"Text_name")
            uiText_name:setString(GameCommon.player[wChairID].szNickName)

            for wTargetChairID = 0, playerNum - 1 do
                local targetViewID = GameCommon:getViewIDByChairID(wTargetChairID)
                if wTargetChairID ~= wChairID and viewID < targetViewID then
                    local uiText_location = ccui.Helper:seekWidgetByName(rootNode,string.format("Text_%dto%d",viewID,targetViewID))
                    if uiText_location then
                        local distance = ''
                        if GameCommon.player[wChairID] == nil or GameCommon.player[wTargetChairID] == nil then
                            distance = "等待加入..."
                        elseif GameCommon.tableConfig.nTableType == TableType_GoldRoom or GameCommon.tableConfig.nTableType == TableType_SportsRoom then
                            distance = math.random(1000,300000)
                        elseif GameCommon.player[wChairID].location.x < 0.1 then
                            distance = string.format("%s\n未开启定位",GameCommon.player[wChairID].szNickName)
                        elseif GameCommon.player[wTargetChairID].location.x < 0.1 then
                            distance = string.format("%s\n未开启定位",GameCommon.player[wTargetChairID].szNickName)
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
            for wTargetChairID = 0,  playerNum - 1 do
                local targetViewID = GameCommon:getViewIDByChairID(wTargetChairID)
                if wTargetChairID ~= wChairID and viewID < targetViewID  then
                    local uiText_location = ccui.Helper:seekWidgetByName(rootNode,string.format("Text_%dto%d",viewID,targetViewID))
                    uiText_location:setString("")
                end
            end
        end
    end
end

function CDLocationLayer:RET_GAMES_USER_POSITION(event)
    local playerNum = GameCommon.gameConfig.bPlayerCount
    local rootNode = self['Image_distance' .. playerNum]
    rootNode:setVisible(true)
    self:showPlayerPosition(rootNode, playerNum)
end

------------------------------------------------------------------------
--                            server rvc                              --
------------------------------------------------------------------------
return CDLocationLayer