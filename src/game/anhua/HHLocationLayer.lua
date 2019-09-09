--[[
*名称:HHLocationLayer
*描述:定位
*作者:[]
*创建日期:2018-07-11 10:07:55
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
local GameCommon            = require("game.anhua.GameCommon") 

local HHLocationLayer       = class("HHLocationLayer", cc.load("mvc").ViewBase)

function HHLocationLayer:onConfig()
    self.widget             = {
        {"Button_close", "onClose"},
        {"Image_distance2"},
        {"Image_distance3"},
    }
end

function HHLocationLayer:onEnter()
    EventMgr:registListener(EventType.RET_GAMES_USER_POSITION,self,self.RET_GAMES_USER_POSITION)

end

function HHLocationLayer:onExit()
    EventMgr:unregistListener(EventType.RET_GAMES_USER_POSITION,self,self.RET_GAMES_USER_POSITION)    
end

function HHLocationLayer:onCreate()
    self:refreshUI()
end

function HHLocationLayer:onClose()
    self:removeFromParent()
end

------------------------------------------------------------------------
--                            game logic                              --
------------------------------------------------------------------------
function HHLocationLayer:refreshUI()
    self.Image_distance2:setVisible(false)
    self.Image_distance3:setVisible(false)
    local playerNum = GameCommon.gameConfig.bPlayerCount
    local rootNode = self['Image_distance' .. playerNum]
    rootNode:setVisible(true)
    self:showPlayerPosition(rootNode, playerNum)
end

function HHLocationLayer:showPlayerPosition(rootNode, playerNum)
    for i=1,playerNum do
        local uiPanel_players = ccui.Helper:seekWidgetByName(rootNode,string.format("Panel_players%d",i))
        if uiPanel_players then
            uiPanel_players:setVisible(false)
        end
    end
    self.localtion = {}
    for wChairID = 0, playerNum - 1 do            
        local viewID = GameCommon:getViewIDByChairID(wChairID) --wChairID + 1
        local uiPanel_players = ccui.Helper:seekWidgetByName(rootNode,string.format("Panel_players%d",viewID))
        if GameCommon.player[wChairID] then

            local x = GameCommon.player[wChairID].location.x
            local y = GameCommon.player[wChairID].location.y


            uiPanel_players:setVisible(true)
            local Text_ip = ccui.Helper:seekWidgetByName(uiPanel_players,"Text_ip")
            local Text_name = ccui.Helper:seekWidgetByName(uiPanel_players,"Text_name")
            local Text_areaInfo = ccui.Helper:seekWidgetByName(uiPanel_players,"Text_location")

            local Userip = NetMgr:getLogicInstance().cppFunc:int2ip(GameCommon.player[wChairID].dwPlayAddr)
            Text_ip:setString(Userip)
            Text_name:setString(GameCommon.player[wChairID].szNickName)
            Text_areaInfo:setString('未知地点')
            self.localtion[wChairID] = Text_areaInfo
            local pos = UserData.User:getDetailLocation(y,x,function ( address )
                if self.localtion and self.localtion[wChairID] then
                    self.localtion[wChairID]:setString(address)
                end
                
            end)
            for wTargetChairID = 0, playerNum - 1 do
                local targetViewID = GameCommon:getViewIDByChairID(wTargetChairID)  --wTargetChairID + 1
                if viewID < targetViewID then
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
                    if GameCommon.player[wTargetChairID] then
                        uiText_location:setString("等待加入...")
                    else
                        uiText_location:setString("")
                    end
                end
            end
        end
    end
end

function HHLocationLayer:RET_GAMES_USER_POSITION(event)
    local playerNum = GameCommon.gameConfig.bPlayerCount
    local rootNode = self['Image_distance' .. playerNum]
    rootNode:setVisible(true)
    self:showPlayerPosition(rootNode, playerNum)
end

return HHLocationLayer