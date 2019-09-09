local GameCommon = require("game.puke.GameCommon")
local Bit = require("common.Bit")
local StaticData = require("app.static.StaticData")
local EventType = require("common.EventType")
local EventMgr = require("common.EventMgr")
local GameLogic = require("game.puke.GameLogic")
local Common = require("common.Common")

local GameEndLayer = class("GameEndLayer",function()
    return ccui.Layout:create()
end)

function GameEndLayer:create(pBuffer)
    local view = GameEndLayer.new()
    view:onCreate(pBuffer)
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

function GameEndLayer:onEnter()
    EventMgr:registListener(EventType.SUB_GR_MATCH_TABLE_FAILED,self,self.SUB_GR_MATCH_TABLE_FAILED)
end

function GameEndLayer:onExit()
    EventMgr:unregistListener(EventType.SUB_GR_MATCH_TABLE_FAILED,self,self.SUB_GR_MATCH_TABLE_FAILED)
end

function GameEndLayer:onCleanup()

end

function GameEndLayer:onCreate(pBuffer)       
    local csb = cc.CSLoader:createNode("GameLayerPaoDeKuai_End.csb")
    self:addChild(csb)
    self.root = csb:getChildByName("Panel_root")
    
    --动画
    local visibleSize = cc.Director:getInstance():getVisibleSize()
    ccs.ArmatureDataManager:getInstance():addArmatureFileInfo("game/wuguidonghua/wuguidonghua.ExportJson")
    local armature2=ccs.Armature:create("wuguidonghua")
    armature2:getAnimation():playWithIndex(0)
    local uiImage_bg = ccui.Helper:seekWidgetByName(self.root,"Image_bg")
    uiImage_bg:addChild(armature2)
    armature2:setPosition(0,armature2:getParent():getContentSize().height)
    armature2:runAction(cc.MoveTo:create(20,cc.p(armature2:getParent():getContentSize().width,armature2:getPositionY())))
    
    local uiButton_return = ccui.Helper:seekWidgetByName(self.root,"Button_return")
    uiButton_return:setPressedActionEnabled(true)
    local function onEventReturn(sender,event)
    	if event == ccui.TouchEventType.ended then
            Common:palyButton()
            require("common.SceneMgr"):switchScene(require("app.MyApp"):create():createView("HallLayer"),SCENE_HALL) 
    	end
    end
    uiButton_return:addTouchEventListener(onEventReturn)
    local uiButton_continue = ccui.Helper:seekWidgetByName(self.root,"Button_continue")
    uiButton_continue:setPressedActionEnabled(true)
    local function onEventContinue(sender,event)
    	if event == ccui.TouchEventType.ended then
            Common:palyButton()
            if GameCommon.tableConfig.nTableType > TableType_GoldRoom then
                if GameCommon.tableConfig.wTableNumber == GameCommon.tableConfig.wCurrentNumber then
                    EventMgr:dispatch(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK)
                else
                    GameCommon:ContinueGame(GameCommon.tableConfig.cbLevel)
                end
            elseif GameCommon.tableConfig.nTableType == TableType_GoldRoom then 
                GameCommon:ContinueGame(GameCommon.tableConfig.cbLevel)
            else
                require("common.SceneMgr"):switchScene(require("app.MyApp"):create():createView("HallLayer"),SCENE_HALL) 
            end          
    	end
    end
    uiButton_continue:addTouchEventListener(onEventContinue)
    if GameCommon.tableConfig.nTableType > TableType_GoldRoom then
        uiButton_return:setVisible(false)
        uiButton_continue:setPositionX(uiButton_continue:getParent():getContentSize().width/2)
    end
    local uiPanel_result = ccui.Helper:seekWidgetByName(self.root,"Panel_result")
  --  local uiPanel_look = ccui.Helper:seekWidgetByName(self.root,"Panel_look")
    local uiButton_look = ccui.Helper:seekWidgetByName(self.root,"Button_look")
    Common:addTouchEventListener(uiButton_look,function() 
        if uiPanel_result:isVisible() then
            uiPanel_result:setVisible(false)
            uiButton_look:setBright(false)
        else
            uiPanel_result:setVisible(true)
            uiButton_look:setBright(true)
        end
    end)
    local uiText_info = ccui.Helper:seekWidgetByName(self.root,"Text_info")
    uiText_info:setString("")
    if GameCommon.tableConfig.nTableType == TableType_GoldRoom then
        uiText_info:setString(string.format("倍率：%d\n本局消耗：%d",GameCommon.tableConfig.wCellScore,GameCommon.tableConfig.wCellScore*0.5))
    end
    local uiImage_result = ccui.Helper:seekWidgetByName(self.root,"Image_result")
    local viewID = GameCommon:getViewIDByChairID(pBuffer.wWinUser)
    local textureName = nil
    if viewID == 1 then --自己胜
        textureName = "common/common_end1.png"   
    else
        textureName = "common/common_end2.png"       
    end
    local texture = cc.Director:getInstance():getTextureCache():addImage(textureName)
    uiImage_result:loadTexture(textureName)
    uiImage_result:setContentSize(texture:getContentSizeInPixels())   
    local uiListView_player = ccui.Helper:seekWidgetByName(self.root,"ListView_player")
    for key, var in pairs(GameCommon.player) do
        local viewID = GameCommon:getViewIDByChairID(var.wChairID)           
        local root = ccui.Helper:seekWidgetByName(uiListView_player,string.format("Panel_player%d",viewID))
        local uiImage_avatar = ccui.Helper:seekWidgetByName(root,"Image_avatar")
        Common:requestUserAvatar(var.dwUserID,var.szPto,uiImage_avatar,"img") 
        local uiText_name = ccui.Helper:seekWidgetByName(root,"Text_name")       
        uiText_name:setString(string.format("%s",var.szNickName)) 
        local uiText_surplus = ccui.Helper:seekWidgetByName(root,"Text_surplus")
        if pBuffer.bUserCardCount[key+1] >= GameCommon.gameConfig.bSpringMinCount then
            uiText_surplus:setString(string.format("%d(全关)",pBuffer.bUserCardCount[key+1]))
        else
            uiText_surplus:setString(string.format("%d",pBuffer.bUserCardCount[key+1]))
        end

        if pBuffer.cbFalseSpring[key+1] == true then
            uiText_surplus:setString(string.format("%d(假春天)",pBuffer.bUserCardCount[key+1]))    
        end
        local uiText_bomb = ccui.Helper:seekWidgetByName(root,"Text_bomb")
        uiText_bomb:setString(string.format("%d",pBuffer.cbBombCount[key+1]))
        local uiImage_red10 = ccui.Helper:seekWidgetByName(root,"Image_red10")
        if pBuffer.wChariIDred10 == var.wChairID then
            uiImage_red10:setVisible(true)
        else
            uiImage_red10:setVisible(false)
        end
        local uiText_result = ccui.Helper:seekWidgetByName(root,"Text_result")
        uiText_result:setString(string.format("%d",pBuffer.lGameScore[key+1]))      
        local uiText_abandon = ccui.Helper:seekWidgetByName(root,"Text_abandon")
        if pBuffer.wChariIDAbandon == var.wChairID then
            uiText_abandon:setString("(放走包赔)")
        elseif pBuffer.wWinUser == var.wChairID then
            uiText_abandon:setString("(上游)")
        else
            uiText_abandon:setString("")
        end
    end
    for i = GameCommon.gameConfig.bPlayerCount+1, 3 do
        local root = ccui.Helper:seekWidgetByName(uiListView_player,string.format("Panel_player%d",i))
        root:setVisible(false)
    end
    local uiText_time = ccui.Helper:seekWidgetByName(self.root,"Text_time")
    -- uiText_time:runAction(cc.RepeatForever:create(cc.Sequence:create(cc.CallFunc:create(function(sender,event) 
        local date = os.date("*t",os.time())
        uiText_time:setString(string.format("%d-%d-%d %02d:%02d:%02d",date.year,date.month,date.day,date.hour,date.min,date.sec))
        -- end),cc.DelayTime:create(1))))
end

function GameEndLayer:SUB_GR_MATCH_TABLE_FAILED(event)
    local data = event._usedata
    require("common.SceneMgr"):switchScene(require("app.MyApp"):create():createView("HallLayer"),SCENE_HALL) 
    if data.wErrorCode == 0 then
        require("common.MsgBoxLayer"):create(0,nil,"您在游戏中!")
    elseif data.wErrorCode == 1 then
        require("common.MsgBoxLayer"):create(0,nil,"游戏配置发生错误!")
    elseif data.wErrorCode == 2 then
        if  StaticData.Hide[CHANNEL_ID].btn8 == 1 and StaticData.Hide[CHANNEL_ID].btn9 == 1  then
            require("common.MsgBoxLayer"):create(2,nil,"您的金币不足,请前往商城充值!",function()             require("common.SceneMgr"):switchOperation(require("app.MyApp"):create(2):createView("NewMallLayer"))  end)
        else
            require("common.MsgBoxLayer"):create(1,nil,"您的金币不足,请联系会长购买！",function() require("common.SceneMgr"):switchOperation(require("app.MyApp"):create():createView("GuilLayer"))  end)
        end
    elseif data.wErrorCode == 3 then
        require("common.MsgBoxLayer"):create(0,nil,"您的金币已超过上限，请前往更高一级匹配!")
    elseif data.wErrorCode == 4 then
        require("common.MsgBoxLayer"):create(0,nil,"房间已满,稍后再试!")
    else
        require("common.MsgBoxLayer"):create(0,nil,"未知错误,请升级版本!") 
    end
end

return GameEndLayer
