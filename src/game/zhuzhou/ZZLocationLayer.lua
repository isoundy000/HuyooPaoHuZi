--[[
*名称:ZZLocationLayer
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
local GameCommon            = require("game.zhuzhou.GameCommon") 

local ZZLocationLayer       = class("ZZLocationLayer", cc.load("mvc").ViewBase)

function ZZLocationLayer:onConfig()
    self.widget             = {
        {"distance3"},
        {"distance4"},
        {'distance2'},
        {'Button_continue','onClose'},
        {'Button_quit','cancleGame'}
    }
end

function ZZLocationLayer:onEnter()
    EventMgr:registListener(EventType.RET_GAMES_USER_POSITION,self,self.RET_GAMES_USER_POSITION)
end

function ZZLocationLayer:onExit()
    EventMgr:unregistListener(EventType.RET_GAMES_USER_POSITION,self,self.RET_GAMES_USER_POSITION)    
end

function ZZLocationLayer:onCreate()
    self:refreshUI()
end

function ZZLocationLayer:onClose()
    self:removeFromParent()
end

function ZZLocationLayer:cancleGame( ... )
    --离开游戏
    require("common.MsgBoxLayer"):create(6,nil,"解散房间","是否确定解散房间？",function()
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER,NetMsgId.REQ_GR_DISMISS_TABLE,"")
    end)
end

------------------------------------------------------------------------
--                            game logic                              --
------------------------------------------------------------------------
function ZZLocationLayer:refreshUI()
    self:hideAllLocation()
    local playerNum = GameCommon.gameConfig.bPlayerCount
    local rootNode = self['distance' .. playerNum]
    rootNode:setVisible(true)
    self:showPlayerPosition(rootNode, playerNum)
end

function ZZLocationLayer:hideAllLocation( ... )
    for i=2,4 do
        self['distance' .. i]:setVisible(false)
    end
end

--加载人物头像
function ZZLocationLayer:loadPeopleImage( wChairID,rootNode)
    local viewID = GameCommon:getViewIDByChairID(wChairID, true) --wChairID + 1
    for k,v in pairs(rootNode:getChildren()) do
        print(k,v:getName())
    end
    local target = rootNode:getChildByName(string.format("Panel_players%d",viewID))
    local uiImage_avatar = ccui.Helper:seekWidgetByName(target,'Image_defaut')
    Common:requestUserAvatar(GameCommon.player[wChairID].dwUserID,GameCommon.player[wChairID].szPto,uiImage_avatar,"clip")
end

--设置人物头像外框
function ZZLocationLayer:setHeadIcom(playerUI,isJoin)
    local imagegray = ccui.Helper:seekWidgetByName(playerUI,'Image_gray')
    local imageRed = ccui.Helper:seekWidgetByName(playerUI,'Image_read')
    local imagegreen = ccui.Helper:seekWidgetByName(playerUI,'Image_green')

    imagegray:setVisible(not isJoin)
    imageRed:setVisible(false)
    imagegreen:setVisible(isJoin)
end


function ZZLocationLayer:showPlayerPosition(rootNode, playerNum)

    for k,v in pairs(GameCommon.player) do
       self:loadPeopleImage(k,rootNode)
    end

    self.localtion = {}
    for wChairID = 0, playerNum - 1 do            
        local viewID = GameCommon:getViewIDByChairID(wChairID, true) --wChairID + 1
        local uiPanel_players = ccui.Helper:seekWidgetByName(rootNode,string.format("Panel_players%d",viewID))
        if GameCommon.player[wChairID] then
            local x = GameCommon.player[wChairID].location.x
            local y = GameCommon.player[wChairID].location.y
            uiPanel_players:setVisible(true)
            local Text_areaInfo = ccui.Helper:seekWidgetByName(uiPanel_players,"Text_location")

            local Userip = NetMgr:getLogicInstance().cppFunc:int2ip(GameCommon.player[wChairID].dwPlayAddr)
            --Text_areaInfo:setString('未知地点')
            self.localtion[wChairID] = Text_areaInfo
            local pos = UserData.User:getDetailLocation(y,x,function ( address )
                if self.localtion and self.localtion[wChairID] then
                    self.localtion[wChairID]:setString(address)
                end
            end)
            for wTargetChairID = 0, playerNum - 1 do
                local targetViewID = GameCommon:getViewIDByChairID(wTargetChairID, true)  --wTargetChairID + 1

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
                        local playerUI = ccui.Helper:seekWidgetByName(rootNode,string.format("Panel_players%d",viewID))
                        self:setHeadIcom(playerUI,true)

                    end
                end
            end
        else
            local playerUI = ccui.Helper:seekWidgetByName(rootNode,string.format("Panel_players%d",viewID))
            self:setHeadIcom(playerUI,false)
            for wTargetChairID = 0,  playerNum - 1 do
                local targetViewID = GameCommon:getViewIDByChairID(wTargetChairID, true)
                if wTargetChairID ~= wChairID and viewID < targetViewID  then
                    local uiText_location = ccui.Helper:seekWidgetByName(rootNode,string.format("Text_%dto%d",viewID,targetViewID))
                    uiText_location:setString("等待加入...")
                end
            end
        end
    end
end

function ZZLocationLayer:RET_GAMES_USER_POSITION(event)
    self:hideAllLocation()
    local playerNum = GameCommon.gameConfig.bPlayerCount
    local rootNode = self['distance' .. playerNum]
    rootNode:setVisible(true)
    self:showPlayerPosition(rootNode, playerNum)
end

return ZZLocationLayer