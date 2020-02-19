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

local GameCommon
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
    EventMgr:unregistListener(EventType.RET_GAMES_USER_POSITION,self,self.RET_GAMES_USER_POSITION)    
end

function PositionLayer:onCleanup()
end

function PositionLayer:onCreate(wKindID)
    EventMgr:registListener(EventType.RET_GAMES_USER_POSITION,self,self.RET_GAMES_USER_POSITION)
    local visibleSize = cc.Director:getInstance():getVisibleSize()
    local csb = cc.CSLoader:createNode("PositionLayer.csb")
    self:addChild(csb)
    self.root = csb:getChildByName("Panel_root")
    
    local Image_distanceBg = ccui.Helper:seekWidgetByName(self.root,"Image_distanceBg")
    Common:playPopupAnim(Image_distanceBg)
    Common:addTouchEventListener(self.root,function() 
        self:removeFromParent()
    end,true)

    GameCommon = nil
    if wKindID == 43 then
       GameCommon = require("game.paohuzi.43.GameCommon") 
    elseif StaticData.Games[wKindID].type == 1 then
        GameCommon = require("game.paohuzi.GameCommon")
    elseif StaticData.Games[wKindID].type == 2 then
        GameCommon = require("game.puke.GameCommon")    
    elseif StaticData.Games[wKindID].type == 3 then 
        if wKindID == 42  then
            GameCommon = require("game.laopai.GameCommon")
        else
            GameCommon = require("game.majiang.GameCommon")
        end 
    else
        return
    end
    if wKindID == 42 then       
        GameCommon.gameConfig = {}  
        GameCommon.gameConfig.bPlayerCount = 4
    end  
    if GameCommon.gameConfig.bPlayerCount == nil then 
        require("common.MsgBoxLayer"):create(0,nil,"房间配置获取失败!!!")    
        self:removeFromParent()
        return 
    end 
    require("common.SceneMgr"):switchOperation(self)
    self:init()
    self:refreshUI()
end

function PositionLayer:init( ... )
    self.Image_distance2 = ccui.Helper:seekWidgetByName(self.root,"Image_distance2")
    self.Image_distance3 = ccui.Helper:seekWidgetByName(self.root,'Image_distance3')
    self.Image_distance4 = ccui.Helper:seekWidgetByName(self.root,'Image_distance4')
end

function PositionLayer:refreshUI()
    self.Image_distance2:setVisible(false)
    self.Image_distance3:setVisible(false)
    self.Image_distance4:setVisible(false)
    local playerNum = GameCommon.gameConfig.bPlayerCount
    local rootNode = self['Image_distance' .. playerNum]
    rootNode:setVisible(true)
    self:showPlayerPosition(rootNode, playerNum)
end


--更新距离
function PositionLayer:updateLocationDis( rootNode, playerNum)
    
    for wChairID = 0, playerNum - 1 do    
        local viewID = GameCommon:getViewIDByChairID(wChairID,true)
        local uiPanel_players = ccui.Helper:seekWidgetByName(rootNode,string.format("Panel_players%d",viewID))
        print('============',wChairID,viewID)
        if GameCommon.player[wChairID] then
            uiPanel_players:setVisible(true)
            local uiImage_avatar = ccui.Helper:seekWidgetByName(uiPanel_players,"Image_avatar")
            Common:requestUserAvatar(GameCommon.player[wChairID].dwUserID,GameCommon.player[wChairID].szPto,uiImage_avatar,"img")
            local uiText_name = ccui.Helper:seekWidgetByName(uiPanel_players,"Text_name")
            uiText_name:setString(GameCommon.player[wChairID].szNickName)

            for wTargetChairID=0,playerNum-1 do
                local targetViewID = GameCommon:getViewIDByChairID(wTargetChairID,true)
                local uiText_location = ccui.Helper:seekWidgetByName(rootNode,string.format("Text_%dto%d",viewID,targetViewID))
                if uiText_location and  wTargetChairID ~= wChairID then
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
        else
            uiPanel_players:setVisible(false)
            for wTargetChairID=0,playerNum-1 do
                local targetViewID = GameCommon:getViewIDByChairID(wTargetChairID,true)
                if wTargetChairID ~= wChairID then
                    local uiText_location = ccui.Helper:seekWidgetByName(rootNode,string.format("Text_%dto%d",viewID,targetViewID))
                    if uiText_location then
                        uiText_location:setString("")
                    end
                end
            end

        end

    end
end


function PositionLayer:showPlayerPosition(rootNode, playerNum)
    for i = 1, playerNum do
        local uiPanel_players = ccui.Helper:seekWidgetByName(rootNode,string.format("Panel_players%d",i))
        local uiImage_avatar = ccui.Helper:seekWidgetByName(uiPanel_players,"Image_avatar")
        uiImage_avatar:loadTexture("common/hall_avatar.png")
        local uiText_name = ccui.Helper:seekWidgetByName(uiPanel_players,"Text_name")
        uiText_name:setString("")
    end

    self:updateLocationDis(rootNode,playerNum)
end

function PositionLayer:RET_GAMES_USER_POSITION(event)
    print('-->>>>update')
    local playerNum = GameCommon.gameConfig.bPlayerCount
    local rootNode = self['Image_distance' .. playerNum]
    rootNode:setVisible(true)
    self:showPlayerPosition(rootNode, playerNum)
end

return PositionLayer
    