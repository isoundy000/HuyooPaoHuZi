local StaticData = require("app.static.StaticData")
local GameCommon = require("game.majiang.GameCommon") 
local NetMgr = require("common.NetMgr")
local NetMsgId = require("common.NetMsgId")
local EventMgr = require("common.EventMgr")
local EventType = require("common.EventType")
local NetMsgId = require("common.NetMsgId")
local Bit = require("common.Bit")
local Common = require("common.Common")
local Base64 = require("common.Base64")
local LocationSystem = require("common.LocationSystem")
local Default = require("common.Default")
local GameLogic = require("game.majiang.GameLogic")
local UserData = require("app.user.UserData")
local GameOpration = require("game.majiang.GameOpration")
local GameGangOpration = require("game.majiang.GameGangOpration")
local GameSpecial = require("game.majiang.GameSpecial")
local GameDesc = require("common.GameDesc")

local TableLayer = class("TableLayer",function()
    return ccui.Layout:create()
end)

function TableLayer:create(root)
    local view = TableLayer.new()
    view:onCreate(root)
    local function onEventHandler(eventType)  
        if eventType == "enter" then  
            view:onEnter() 
        elseif eventType == "exit" then
            view:onExit() 
        end  
    end  
    view:registerScriptHandler(onEventHandler)
    return view
end

function TableLayer:onEnter()
    EventMgr:registListener(EventType.EVENT_TYPE_SKIN_CHANGE,self,self.EVENT_TYPE_SKIN_CHANGE)
    EventMgr:registListener(EventType.EVENT_TYPE_SIGNAL,self,self.EVENT_TYPE_SIGNAL)
    EventMgr:registListener(EventType.EVENT_TYPE_ELECTRICITY,self,self.EVENT_TYPE_ELECTRICITY)

    if GameCommon.tableConfig.nTableType ~= TableType_Playback then
        if PLATFORM_TYPE == cc.PLATFORM_OS_APPLE_REAL and cus.JniControl:getInstance():getSystemVersion() < 10.0 then
            local uiImage_signal = ccui.Helper:seekWidgetByName(self.root,"Image_signal")
            if uiImage_signal ~= nil then 
                uiImage_signal:setVisible(false) 
            end
        end
    end
    UserData.User:initByLevel()
end

function TableLayer:onExit()
    EventMgr:unregistListener(EventType.EVENT_TYPE_SKIN_CHANGE,self,self.EVENT_TYPE_SKIN_CHANGE)
    EventMgr:unregistListener(EventType.EVENT_TYPE_SIGNAL,self,self.EVENT_TYPE_SIGNAL)
    EventMgr:unregistListener(EventType.EVENT_TYPE_ELECTRICITY,self,self.EVENT_TYPE_ELECTRICITY)

end

function TableLayer:onCreate(root)
    self.flagNode = nil    --最后一张牌箭标
    self.lastDiscardNode = nil
    self.lastDiscardChariID = nil
    self.lastSendCardChariID = nil
    self.root = root    
    self.cotrolCardTPData = nil
    self.locationPos = cc.p(0,0)
    self.locationBeganPos = cc.p(0,0)
    local touchLayer = ccui.Layout:create()
    self.root:addChild(touchLayer)
    local function onTouchBegan(touch , event)
        self.locationPos = touch:getLocation()
        self.locationBeganPos = self.locationPos
        return true
    end
    local function onTouchMoved(touch , event)
        self.locationPos = touch:getLocation()
    end
    local function onTouchEnded(touch , event)
        self.locationPos = touch:getLocation()
    end
    local listener = cc.EventListenerTouchOneByOne:create()
    listener:setSwallowTouches(false)
    listener:registerScriptHandler(onTouchBegan, cc.Handler.EVENT_TOUCH_BEGAN)
    listener:registerScriptHandler(onTouchMoved, cc.Handler.EVENT_TOUCH_MOVED)
    listener:registerScriptHandler(onTouchEnded, cc.Handler.EVENT_TOUCH_ENDED)
    cc.Director:getInstance():getEventDispatcher():addEventListenerWithSceneGraphPriority(listener,touchLayer) 
    return true
end

function TableLayer:doAction(action,pBuffer)
    --重连最后出牌角标恢复
    if pBuffer.wLastOutCardUser then
        printInfo('Reconnect last card info = %d', pBuffer.wLastOutCardUser)
        local viewID = GameCommon:getViewIDByChairID(pBuffer.wLastOutCardUser)
        local uiPanel_discardCard = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_discardCard%d",viewID))
        if uiPanel_discardCard then
            local nodeArr = uiPanel_discardCard:getChildren()
            local childLen = #nodeArr
            if childLen > 0 then
                self:removeLastCardFlagEft()
                self:addLastCardFlagEft(nodeArr[childLen])
            end
        end
    end

    if (GameCommon.tableConfig.wKindID == 50 or GameCommon.tableConfig.wKindID == 70) and action == NetMsgId.SUB_S_SpecialCard_RESULT and pBuffer.wActionUser ~= GameCommon:getRoleChairID() then
    
    else
        local uiPanel_operation = ccui.Helper:seekWidgetByName(self.root,"Panel_operation")
        uiPanel_operation:removeAllChildren()   
        uiPanel_operation:setVisible(false)
    end
    if action == NetMsgId.SUB_S_OUT_CARD_NOTIFY_MAJIANG then
        local wChairID = pBuffer.wOutCardUser   
        GameCommon.waitOutCardUser = wChairID
        self:showCountDown(wChairID)
        if wChairID == GameCommon:getRoleChairID() then
            local uiPanel_outCardTips = ccui.Helper:seekWidgetByName(self.root,"Panel_outCardTips")
            uiPanel_outCardTips:removeAllChildren()
            ccs.ArmatureDataManager:getInstance():addArmatureFileInfo("game/finger/finger.ExportJson")
            local armature = ccs.Armature:create("finger")
            uiPanel_outCardTips:addChild(armature)
            armature:getAnimation():playWithIndex(0)
            self.cotrolCardTPData = {}
			GameCommon.bIsOutCardTips = true	
		else
			self.cotrolCardTPData = nil
        end
        self:runAction(cc.Sequence:create(cc.DelayTime:create(0),cc.CallFunc:create(function(sender,event) EventMgr:dispatch(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK) end)))

    elseif action == NetMsgId.SUB_S_OUT_CARD_RESULT then
        local uiPanel_hucardbg = ccui.Helper:seekWidgetByName(self.root,"Panel_hucardbg")  
        uiPanel_hucardbg:setVisible(false) 
        local uiButton_chakan = ccui.Helper:seekWidgetByName(self.root,"Button_chakan")
       
        if (GameCommon.tableConfig.wKindID == 50 or GameCommon.tableConfig.wKindID == 70) then --玩家出牌.杠数据清空清空
            GameCommon.mGang = false
        end
        GameCommon.cbOperateCode = 0 --玩家出牌.王闯王钓清空
    --    if  pBuffer.wOutCardUser == GameCommon:getRoleChairID() and GameCommon.mBaoTingCard~=nil and GameCommon.mBaoTingCard[1] ~= 0 then
    --        for i = 1 ,#GameCommon.mBaoTingCard do
    --            if  pBuffer.cbOutCardData ==  GameCommon.mBaoTingCard[i] then
    --                uiButton_chakan:setVisible(true)  
    --           end
    --        end 
    --    end       
       if  StaticData.Hide[CHANNEL_ID].btn16 == 0 then   --pBuffer.wOutCardUser == GameCommon:getRoleChairID() and  GameCommon.tableConfig.wKindID ~= 63 or
           uiButton_chakan:setVisible(false)  
       end
        GameCommon.waitOutCardUser = nil
        GameCommon.mBaoTingCard = {}
        local uiPanel_outCardTips = ccui.Helper:seekWidgetByName(self.root,"Panel_outCardTips")
        uiPanel_outCardTips:removeAllChildren()
        local wChairID = pBuffer.wOutCardUser
        local viewID = GameCommon:getViewIDByChairID(wChairID)
        local uiPanel_tipsCardPos = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_tipsCardPos%d",viewID))
        local uiPanel_tipsCard = ccui.Helper:seekWidgetByName(self.root,"Panel_tipsCard")
        
        --[[
        local uiSendOrOutCardNode = uiPanel_tipsCard:getChildByName("SendOrOutCardNode")
        if uiSendOrOutCardNode ~= nil then
            uiSendOrOutCardNode:runAction(cc.Sequence:create(
            cc.RemoveSelf:create(),
            cc.CallFunc:create(function(sender,event) 
                self:addDiscardCard(sender.wChairID, sender.cbCardData) 
            end)))
        end
        --]]

        local uiSendOrOutCardNode = uiPanel_tipsCard:getChildByName("SendOrOutCardNode")
        if uiSendOrOutCardNode then
            uiSendOrOutCardNode:removeFromParent()
        else
            local  n = 2
            if GameCommon.gameConfig.mKGNPFlag ~= nil and GameCommon.gameConfig.mKGNPFlag ~= 0 then 
                n = GameCommon.gameConfig.mKGNPFlag
            end 
            for i = 1, n do
                local uiSendOrOutCardNode = uiPanel_tipsCard:getChildByName(string.format("SendOrOutCardNode%d",i))
                if uiSendOrOutCardNode then
                    uiSendOrOutCardNode:removeFromParent()
                end
            end
        end
        
        uiSendOrOutCardNode = GameCommon:getDiscardCardAndWeaveItemArray(pBuffer.cbOutCardData,1)
        uiSendOrOutCardNode:setName("SendOrOutCardNode")
        uiSendOrOutCardNode.cbCardData = pBuffer.cbOutCardData
        uiSendOrOutCardNode.wChairID = wChairID
        uiPanel_tipsCard:addChild(uiSendOrOutCardNode)
        local pos = nil
        if pBuffer.isNoDelete ~= true then
            if self.outData ~= nil and wChairID == GameCommon:getRoleChairID() and self.outData.cbCardData == pBuffer.cbOutCardData then
                --优先找出牌的节点
                local posCardData = -1
                for i = 1, GameCommon.player[wChairID].cbCardCount do
                    if GameCommon.player[wChairID].cbCardData[i] == pBuffer.cbOutCardData then
                        posCardData = i
                        break
                    end
                end
                local posCardNode = -1
                for key, var in pairs(GameCommon.player[wChairID].cardNode) do
                	if var.node == self.outData.cardNode then
                        posCardNode = key
                        break
                	end
                end
                if posCardData == -1 or posCardNode == -1 then
                    pos = self:removeHandCard(wChairID, pBuffer.cbOutCardData)
                else
                    table.remove(GameCommon.player[wChairID].cbCardData,posCardData)
                    local var = GameCommon.player[wChairID].cardNode[posCardNode]
                    pos = cc.p(var.node:getParent():convertToWorldSpace(cc.p(var.node:getPosition())))
                    var.node:removeFromParent()
                    table.remove(GameCommon.player[wChairID].cardNode,posCardNode)
                    GameCommon.player[wChairID].cbCardCount = GameCommon.player[wChairID].cbCardCount - 1
                end
                self.outData = nil
                self:showHandCard(wChairID,2)
            else
                self.outData = nil
                pos = self:removeHandCard(wChairID, pBuffer.cbOutCardData)
                self:showHandCard(wChairID,2)
            end
        end

        uiSendOrOutCardNode:setPosition(uiPanel_tipsCardPos:getPosition())
        uiSendOrOutCardNode:setScale(1.2)
        uiSendOrOutCardNode:setVisible(false)
        self:addDiscardCard(uiSendOrOutCardNode.wChairID, uiSendOrOutCardNode.cbCardData)
        
        --[[
        if pos == nil then
--            ccs.ArmatureDataManager:getInstance():addArmatureFileInfo("majiang/animation/hudepaitishi/hudepaitishi.ExportJson")
--            local armature = ccs.Armature:create("hudepaitishi")
--            armature:getAnimation():playWithIndex(0,-1,1)
--            armature:setAnchorPoint(cc.p(0.5,0.5))            
--            armature:setVisible(false)  
--            uiSendOrOutCardNode:addChild(armature) 
--            armature:setPosition(armature:getParent():getContentSize().width/2,armature:getParent():getContentSize().height/2) 
--            if viewID == 2 or viewID == 4 then    
--                armature:setRotation(90)   
--            end         
            uiSendOrOutCardNode:setPosition(uiPanel_tipsCardPos:getPosition())
            uiSendOrOutCardNode:setScale(0)           
            uiSendOrOutCardNode:runAction(cc.ScaleTo:create(0.1,1))
--            uiSendOrOutCardNode:runAction(cc.Sequence:create(cc.ScaleTo:create(0.1,1),cc.CallFunc:create(function(sender,event) 
--                armature:setVisible(true)  
--            end)))
                       
        else
--            ccs.ArmatureDataManager:getInstance():addArmatureFileInfo("majiang/animation/hudepaitishi/hudepaitishi.ExportJson")
--            local armature = ccs.Armature:create("hudepaitishi")
--            armature:getAnimation():playWithIndex(0,-1,1)
--            armature:setAnchorPoint(cc.p(0.5,0.5))            
--            armature:setVisible(false)  
--            uiSendOrOutCardNode:addChild(armature) 
--            armature:setPosition(armature:getParent():getContentSize().width/2,armature:getParent():getContentSize().height/2)  
--            if viewID == 2 or viewID == 4 then    
--                armature:setRotation(90)   
--            end      
            uiSendOrOutCardNode:setPosition(cc.p(uiSendOrOutCardNode:getParent():convertToNodeSpace(pos)))
            uiSendOrOutCardNode:runAction(cc.MoveTo:create(0.1,cc.p(uiPanel_tipsCardPos:getPosition()))) 
            uiSendOrOutCardNode:runAction(cc.ScaleTo:create(0.1,1))                         
--            uiSendOrOutCardNode:runAction(cc.Sequence:create(cc.ScaleTo:create(0.1,1),cc.CallFunc:create(function(sender,event) 
--                armature:setVisible(true)  
--            end)))  
        end
        --]]

        GameCommon:playAnimation(self.root, pBuffer.cbOutCardData,wChairID)
        self:runAction(cc.Sequence:create(cc.DelayTime:create(0.1),cc.CallFunc:create(function(sender,event) EventMgr:dispatch(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK) end)))
        -- Common:playEffect("game/audio_card_out.mp3")
    elseif action == NetMsgId.SUB_S_SEND_CARD_MAJIANG then
        local wChairID = pBuffer.wCurrentUser
        print('--------->>>>>>>>添加手牌',wChairID)
        
        local starttime = os.clock(); 
        GameCommon.waitOutCardUser = wChairID
        self.lastSendCardChariID = wChairID
        local viewID = GameCommon:getViewIDByChairID(wChairID)
        -- if viewID == 1  then
        --     GameCommon.cdTingData = nil
        -- end
        local uiButton_chakan = ccui.Helper:seekWidgetByName(self.root,"Button_chakan")    
        if  StaticData.Hide[CHANNEL_ID].btn16 == 0  then  -- wChairID == GameCommon:getRoleChairID() and  GameCommon.tableConfig.wKindID ~= 63 or
            uiButton_chakan:setVisible(false)  
        end
        local uiPanel_tipsCardPos = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_tipsCardPos%d",viewID))
        local uiPanel_tipsCard = ccui.Helper:seekWidgetByName(self.root,"Panel_tipsCard")
        if (GameCommon.tableConfig.wKindID == 50 or GameCommon.tableConfig.wKindID == 70) then
            local  n = 2
            if GameCommon.gameConfig.mKGNPFlag ~= nil and GameCommon.gameConfig.mKGNPFlag ~= 0 then 
                n = GameCommon.gameConfig.mKGNPFlag
            end 
            for i = 1, n do
                local uiSendOrOutCardNode = uiPanel_tipsCard:getChildByName(string.format("SendOrOutCardNode%d",i))
                if uiSendOrOutCardNode ~= nil then
                    uiSendOrOutCardNode:runAction(cc.Sequence:create(
                    cc.RemoveSelf:create(),
                    cc.CallFunc:create(function(sender,event) 
                        self:addDiscardCard(sender.wChairID, sender.cbCardData) 
                    end)))
                end
            end
        end
        --[[
        local uiSendOrOutCardNode = uiPanel_tipsCard:getChildByName("SendOrOutCardNode")
        if uiSendOrOutCardNode ~= nil then
            uiSendOrOutCardNode:runAction(cc.Sequence:create(
            cc.RemoveSelf:create(),
            cc.CallFunc:create(function(sender,event) 
                self:addDiscardCard(sender.wChairID, sender.cbCardData) 
            end)))
        end
        --]]
        self:addOneHandCard(wChairID,pBuffer.cbCardData)
        self:showHandCard(wChairID,1)
        self:showCountDown(wChairID)
        self:updateLeftCardCount(GameCommon.cbLeftCardCount-1)
        local endtime = os.clock() - starttime;                           --> os.clock()用法
        print(string.format("时间间隔 : %.4f", endtime))
        self:runAction(cc.Sequence:create(cc.DelayTime:create(0.2),cc.CallFunc:create(function(sender,event) EventMgr:dispatch(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK) end)))
    
    elseif action == NetMsgId.SUB_S_OPERATE_NOTIFY_MAJIANG then
        if (GameCommon.tableConfig.wKindID == 50 or GameCommon.tableConfig.wKindID == 70) and pBuffer.cbActionCard == 0 then
            pBuffer.tableActionCard = {}
            local uiPanel_tipsCard = ccui.Helper:seekWidgetByName(self.root,"Panel_tipsCard")
            local  n = 2
            if GameCommon.gameConfig.mKGNPFlag ~= nil and GameCommon.gameConfig.mKGNPFlag ~= 0 then 
                n = GameCommon.gameConfig.mKGNPFlag
            end 
            for i = 1, n do
                local uiSendOrOutCardNode = uiPanel_tipsCard:getChildByName(string.format("SendOrOutCardNode%d",i))
                if uiSendOrOutCardNode ~= nil then
                    pBuffer.tableActionCard[i] = uiSendOrOutCardNode.cbCardData
                end
            end
        end
        local oprationLayer = GameOpration:create(pBuffer)
        local uiPanel_operation = ccui.Helper:seekWidgetByName(self.root,"Panel_operation")
        uiPanel_operation:addChild(oprationLayer)
        uiPanel_operation:setVisible(true)
        -- Common:playEffect("game/audio_tip_operate.mp3")
        self:runAction(cc.Sequence:create(cc.DelayTime:create(0),cc.CallFunc:create(function(sender,event) EventMgr:dispatch(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK) end)))
    
    elseif action == NetMsgId.SUB_S_BAOTINGOUTCARD then
        GameCommon.mBaoTingCard = {}
        local isBaoting = false
        for i = 1, 14 do
            if pBuffer.cbBTCard[i] ~= 0 then
                GameCommon.mBaoTingCard[i] = pBuffer.cbBTCard[i]
                isBaoting = true
            end
        end         
        local uiButton_chakan = ccui.Helper:seekWidgetByName(self.root,"Button_chakan")
        if isBaoting == true then
            self:showHandCard(GameCommon:getRoleChairID(),3) --GameCommon.waitOutCardUser
            uiButton_chakan:setVisible(false)  
        else
            
            uiButton_chakan:setVisible(true)  
        end
        GameCommon.mBTHuCard = {}
        for i = 1, 14 do
            if pBuffer.mBTHuCard[i] ~= nil and pBuffer.mBTHuCard[i] ~= 0 then
                GameCommon.mBTHuCard[i]= {}
                for j = 1, 27 do
                    if pBuffer.mBTHuCard[i][j]~= nil and pBuffer.mBTHuCard[i][j] ~= 0 then
                        GameCommon.mBTHuCard[i][j]=pBuffer.mBTHuCard[i][j]
                        print("+++++报停胡获取胡那些牌++++",i,j,pBuffer.mBTHuCard[i][j])
                    end                
                end 
            end
        end 
      self:runAction(cc.Sequence:create(cc.DelayTime:create(0),cc.CallFunc:create(function(sender,event) EventMgr:dispatch(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK) end))) 

    -- elseif action == NetMsgId.SUB_S_ALONE_BAOTINGCARD then
    --     GameCommon.mHuCard = {}
    --     for i = 1, 27 do
    --         if pBuffer.cbGangCard[i]~= nil and pBuffer.cbGangCard[i] ~= 0 then 
    --             GameCommon.mHuCard[i] = pBuffer.cbGangCard[i]                  
    --         end 
    --         print("---------可胡的牌----：",i,pBuffer.cbGangCard[i])             
    --     end
    --     if GameCommon.mHuCard~= {} then                 
    --         self:huCardShow()
    --     end 
    --     self:runAction(cc.Sequence:create(cc.DelayTime:create(0),cc.CallFunc:create(function(sender,event) EventMgr:dispatch(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK) end))) 
    elseif action == NetMsgId.SUB_S_ACTION_BAOTINGCARD then     -- 土匪麻将独有的消息
       
    elseif action == NetMsgId.SUB_S_OPERATE_RESULT then
        GameCommon.waitOutCardUser = pBuffer.wOperateUser               
        local uiPanel_operation = ccui.Helper:seekWidgetByName(self.root,"Panel_operation")
        uiPanel_operation:removeAllChildren()
        uiPanel_operation:setVisible(false)
        local wChairID = pBuffer.wOperateUser
        local viewID = GameCommon:getViewIDByChairID(wChairID)
               
       local uiButton_chakan = ccui.Helper:seekWidgetByName(self.root,"Button_chakan")    
       if   StaticData.Hide[CHANNEL_ID].btn16 == 0  then --wChairID == GameCommon:getRoleChairID() and  GameCommon.tableConfig.wKindID ~= 63 or
           uiButton_chakan:setVisible(false)  
       end
        
        local cbOperateCode = pBuffer.cbOperateCard
        local WeaveItemArray = {}
        WeaveItemArray.cbWeaveKind = pBuffer.cbOperateCode
        WeaveItemArray.cbCenterCard = pBuffer.cbOperateCard
        WeaveItemArray.cbPublicCard = pBuffer.cbPublicCard
        WeaveItemArray.wProvideUser = pBuffer.wProvideUser
        WeaveItemArray.wChiFengJianCard = pBuffer.wChiFengJianCard
        local uiPanel_tipsCard = ccui.Helper:seekWidgetByName(self.root,"Panel_tipsCard")
        local uiPanel_userTips = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_userTips%d",viewID))
        local uiSendOrOutCardNode = uiPanel_tipsCard:getChildByName("SendOrOutCardNode")
        if uiSendOrOutCardNode ~= nil then
            uiSendOrOutCardNode:removeFromParent()
            if wChairID ~= self.lastSendCardChariID then
                self:removeOperateDisCard()
            end
        end
        if(GameCommon.tableConfig.wKindID == 50 or GameCommon.tableConfig.wKindID == 70)then
            local onceFlag = false
            local  n = 2
            if GameCommon.gameConfig.mKGNPFlag ~= nil and GameCommon.gameConfig.mKGNPFlag ~= 0 then 
                n = GameCommon.gameConfig.mKGNPFlag
            end 
            for i = 1, n do
                local uiSendOrOutCardNode = uiPanel_tipsCard:getChildByName(string.format("SendOrOutCardNode%d",i))
                if uiSendOrOutCardNode ~= nil then
                    if uiSendOrOutCardNode.cbCardData == pBuffer.cbOperateCard and not onceFlag then
                        uiSendOrOutCardNode:removeFromParent()
                        onceFlag = true
                    else
                        uiSendOrOutCardNode:runAction(cc.Sequence:create(
                            cc.RemoveSelf:create(),
                            cc.CallFunc:create(function(sender,event) 
                                self:addDiscardCard(sender.wChairID, sender.cbCardData) 
                            end)))
                    end
                end
            end
        end
        if Bit:_and(WeaveItemArray.cbWeaveKind,GameCommon.WIK_GANG) ~= 0 then
            GameCommon:playAnimation(self.root, "杠",wChairID)
            GameCommon.waitOutCardUser = nil
        elseif Bit:_and(WeaveItemArray.cbWeaveKind,GameCommon.WIK_FILL) ~= 0 then
            GameCommon:playAnimation(self.root, "补",wChairID)
            GameCommon.waitOutCardUser = nil
        elseif Bit:_and(WeaveItemArray.cbWeaveKind,GameCommon.WIK_PENG) ~= 0 then
            GameCommon:playAnimation(self.root, "碰",wChairID)
        elseif Bit:_and(WeaveItemArray.cbWeaveKind,GameCommon.WIK_LEFT) ~= 0 or Bit:_and(WeaveItemArray.cbWeaveKind,GameCommon.WIK_CENTER) ~= 0 or Bit:_and(WeaveItemArray.cbWeaveKind,GameCommon.WIK_RIGHT) ~= 0 then
            GameCommon:playAnimation(self.root, "吃",wChairID)
        else
        
        end

        self:addWeaveItemArray(wChairID, WeaveItemArray)
        self:showCountDown(wChairID)
        self:runAction(cc.Sequence:create(cc.DelayTime:create(0),cc.CallFunc:create(function(sender,event) EventMgr:dispatch(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK) end)))

    elseif action == NetMsgId.SUB_S_GAME_END_MAJIANG then
        if pBuffer.wProvideUser >= GameCommon.gameConfig.bPlayerCount then
            GameCommon:playAnimation(self.root, "黄庄")
        else
            for i = 1, GameCommon.gameConfig.bPlayerCount do
                local wChairID = i - 1
                if pBuffer.wWinner[i] == true then
                    -- local wChiHuKind = true
                    -- if GameCommon.tableConfig.wKindID == 70 then 
                    --     if Bit:_and(pBuffer.wChiHuKind[i],GameCommon.CHK_PENG_PENG) ~= 0 then
                    --         GameCommon:playAnimation(self.root, "自摸",wChairID)
                    --     end
                    --     if Bit:_and(pBuffer.wChiHuKind[i],GameCommon.CHK_JIANG_JIANG) ~= 0 then
                    --         GameCommon:playAnimation(self.root, "自摸",wChairID)
                    --     end
                    --     if Bit:_and(pBuffer.wChiHuKind[i],GameCommon.CHR_QING_YI_SE) ~= 0 then
                    --         GameCommon:playAnimation(self.root, "自摸",wChairID)
                    --     end
                    --     if Bit:_and(pBuffer.wChiHuKind[i],GameCommon.CHR_QUAN_QIU_REN) ~= 0 then
                    --         GameCommon:playAnimation(self.root, "自摸",wChairID)
                    --     end
                    --     if Bit:_and(pBuffer.wChiHuKind[i],GameCommon.CHR_HAIDI) ~= 0 then
                    --         GameCommon:playAnimation(self.root, "自摸",wChairID)
                    --     end
                    --     if Bit:_and(pBuffer.wChiHuKind[i],GameCommon.CHK_QI_XIAO_DUI) ~= 0 then
                    --         GameCommon:playAnimation(self.root, "自摸",wChairID)
                    --     end
                    --     if Bit:_and(pBuffer.wChiHuKind[i],GameCommon.CHK_QI_XIAO_DUI_HAO) ~= 0 then
                    --         GameCommon:playAnimation(self.root, "自摸",wChairID)
                    --     else   
                    --         if Bit:_and(pBuffer.wChiHuKind[i],GameCommon.CHK_QI_XIAO_DUI) ~= 0 then
                    --             GameCommon:playAnimation(self.root, "自摸",wChairID)
                    --         end
                    --     end
                    --     if Bit:_and(pBuffer.wChiHuKind[i],GameCommon.CHR_GANG) ~= 0 or Bit:_and(wChiHuKind,GameCommon.CHR_GANG_SHUANG) ~= 0 then
                    --         GameCommon:playAnimation(self.root, "自摸",wChairID)
                    --     end
                    --     if Bit:_and(pBuffer.wChiHuKind[i],GameCommon.CHR_QI_XIAO_DUI_CHAO_HAO) ~= 0 then
                    --         GameCommon:playAnimation(self.root, "自摸",wChairID)
                    --     end
                    --     if Bit:_and(pBuffer.wChiHuKind[i],GameCommon.CHR_QI_XIAO_DUI_CHAO_CHAO) ~= 0 then
                    --         GameCommon:playAnimation(self.root, "自摸",wChairID)
                    --     end
                    --     if Bit:_and(pBuffer.wChiHuKind[i],CHR_QIANG_GANG_HU) ~= 0 then
                    --         GameCommon:playAnimation(self.root, "自摸",wChairID)
                    --     end
                    --     if Bit:_and(pBuffer.wChiHuKind[i],CHR_MENQING_HU) ~= 0 then
                    --         GameCommon:playAnimation(self.root, "自摸",wChairID)
                    --     end
                    -- end 
                    if wChairID == pBuffer.wProvideUser then
                        GameCommon:playAnimation(self.root, "自摸",wChairID)
                    else
                        GameCommon:playAnimation(self.root, "胡",wChairID)
                    end
                end
            end
        end

        local uiAtlasLabel_countdownTime = ccui.Helper:seekWidgetByName(self.root,"AtlasLabel_countdownTime")
        if uiAtlasLabel_countdownTime then
            uiAtlasLabel_countdownTime:stopAllActions()
        end

    elseif action == NetMsgId.SUB_S_SpecialCard then
        local oprationLayer = GameSpecial:create(pBuffer)
        local uiPanel_operation = ccui.Helper:seekWidgetByName(self.root,"Panel_operation")
        uiPanel_operation:addChild(oprationLayer)
        uiPanel_operation:setVisible(true)
        self:runAction(cc.Sequence:create(cc.DelayTime:create(0),cc.CallFunc:create(function(sender,event) EventMgr:dispatch(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK) end)))
        
    elseif action == NetMsgId.SUB_S_SpecialCard_RESULT then
        if  pBuffer.cbUserAction == 0x0200 then
            local cbCardDataTemp = {}
            cbCardDataTemp[1] = pBuffer.cbCardData[1]
            cbCardDataTemp[2] = pBuffer.cbCardData[2]
            for i = 1 , 6 do
                if i <= 3 then
                    pBuffer.cbCardData[i] = cbCardDataTemp[1]
                elseif i <= 6 then
                    pBuffer.cbCardData[i] = cbCardDataTemp[2] 
                end
            end
        end   
        local wChairID = pBuffer.wActionUser
        local viewID = GameCommon:getViewIDByChairID(wChairID) 
        if pBuffer.wActionUser ~= GameCommon:getRoleChairID() then
            local cbCardCount = GameCommon.player[wChairID].cbCardCount
            local cbCardData = GameCommon.player[wChairID].cbCardData
            if pBuffer.wActionUser == GameCommon.wBankerUser then
                self:setHandCard(pBuffer.wActionUser,14, pBuffer.cbCardData)
            else
                self:setHandCard(pBuffer.wActionUser,13, pBuffer.cbCardData)
            end
            self:showHandCard(pBuffer.wActionUser,0)
            
            self:setHandCard(pBuffer.wActionUser,cbCardCount, cbCardData)
            local uiPanel_handCard = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_handCard%d",viewID))
            uiPanel_handCard:stopAllActions()
            uiPanel_handCard:runAction(cc.Sequence:create(
                cc.DelayTime:create(5),
                cc.CallFunc:create(function(sender,event) 
                    self:showHandCard(pBuffer.wActionUser,0)
                end)
            ))  
        end
        local time = 0.5
        local wSiceCount = pBuffer.wSiceCount

        if wSiceCount >= 2 then
            time = 3
            local visibleSize = cc.Director:getInstance():getVisibleSize()
            ccs.ArmatureDataManager:getInstance():addArmatureFileInfo("game/yaoshaizi/yaoshaizi.ExportJson")
            local armature = ccs.Armature:create("yaoshaizi")
            armature:getAnimation():playWithIndex(0,-1,-1)
            armature:setPosition(visibleSize.width*0.5,visibleSize.height*0.5)
            self:addChild(armature)
            require("common.Common"):playEffect("majiang/sound/mandarin/yaoshuiazi.mp3")
            armature:runAction(cc.Sequence:create(cc.DelayTime:create(1),cc.CallFunc:create(function(sender,event) 
                local tableSiceCount = {}
                -- if wSiceCount >= 2 then
                --     if wSiceCount <= 7 then
                --         tableSiceCount[1] = math.random(1,wSiceCount-1)
                --     else
                --         tableSiceCount[1] = math.random(wSiceCount-6,6)
                --     end
                --     tableSiceCount[2] = wSiceCount - tableSiceCount[1]
                -- end
                local cbValue = Bit:_and(wSiceCount,0xFFFF)
                local cbColor = Bit:_rshift(Bit:_and(wSiceCount,0xFFFF),4)   
                for key, var in pairs(tableSiceCount) do
                    local img = ccui.ImageView:create(string.format("game/shuaiz_%d.png",var))
                    armature:addChild(img,1000)
                    img:setPosition(-55 + (key-1)*110,0)
                end
                local wChairID = pBuffer.wTargetUser
                local viewID = GameCommon:getViewIDByChairID(wChairID)
                ccs.ArmatureDataManager:getInstance():addArmatureFileInfo("game/niaodonghua/niaodonghua.ExportJson")
                local armature1 = ccs.Armature:create("niaodonghua")
                armature1:getAnimation():playWithIndex(0,-1,-1)
                armature:addChild(armature1)
                armature1:setPosition(cc.p(armature1:getParent():convertToNodeSpace(cc.p(visibleSize.width*0.5,visibleSize.height*0.5))))
                local uiPanel_player = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_player%d",viewID))
                armature1:runAction(
                cc.MoveTo:create(1,cc.p(armature1:getParent():convertToNodeSpace(cc.p(uiPanel_player:convertToWorldSpace(cc.p(uiPanel_player:getContentSize().width/2,uiPanel_player:getContentSize().height/2)))))))
            end),
            cc.DelayTime:create(1),
            cc.CallFunc:create(function(sender,event) 
                for i = 1, GameCommon.gameConfig.bPlayerCount do
                    local wChairID = i-1
                    local viewID = GameCommon:getViewIDByChairID(wChairID)
                    local uiPanel_tipsCard = ccui.Helper:seekWidgetByName(self.root,"Panel_tipsCard")
                    local uiPanel_tipsCardPos = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_tipsCardPos%d",viewID)) 
                    local uiTextAtlasScore = nil
                    if pBuffer.lGameScore[i] > 0 then
                        uiTextAtlasScore = ccui.TextAtlas:create(string.format(":%d",pBuffer.lGameScore[i]),"fonts/fonts_6.png",26,43,'0')
                    else
                        uiTextAtlasScore = ccui.TextAtlas:create(string.format(":%d",pBuffer.lGameScore[i]),"fonts/fonts_7.png",26,43,'0')
                    end
                    uiPanel_tipsCard:addChild(uiTextAtlasScore)
                    uiTextAtlasScore:setPosition(uiPanel_tipsCardPos:getPosition())  
                    uiTextAtlasScore:runAction(cc.Sequence:create(
                        cc.DelayTime:create(0.5),
                        cc.ScaleTo:create(0.5,1.2),
                        cc.ScaleTo:create(0.5,1.0),
                        cc.RemoveSelf:create())) 
                end
            end),
            cc.RemoveSelf:create()))
        end
        self:runAction(cc.Sequence:create(cc.DelayTime:create(time),cc.CallFunc:create(function(sender,event) EventMgr:dispatch(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK) end)))
        if Bit:_and(pBuffer.cbUserAction,GameCommon.CHK_SIXI_HU) ~= 0 then
            GameCommon:playAnimation(self.root, "大四喜",wChairID)
        elseif Bit:_and(pBuffer.cbUserAction,GameCommon.CHK_BANBAN_HU) ~= 0 then
            GameCommon:playAnimation(self.root, "无将胡",wChairID)
        elseif Bit:_and(pBuffer.cbUserAction,GameCommon.CHK_LIULIU_HU) ~= 0 then
            GameCommon:playAnimation(self.root, "六六顺",wChairID)
        elseif Bit:_and(pBuffer.cbUserAction,GameCommon.CHK_QUEYISE_HU) ~= 0 then
            GameCommon:playAnimation(self.root, "缺一色",wChairID)
        elseif Bit:_and(pBuffer.cbUserAction,GameCommon.CHK_BUBUGAO_HU) ~= 0 then
            GameCommon:playAnimation(self.root, "步步高",wChairID)
        elseif Bit:_and(pBuffer.cbUserAction,GameCommon.CHK_SANTONG_HU) ~= 0 then
            GameCommon:playAnimation(self.root, "三同",wChairID)
        elseif Bit:_and(pBuffer.cbUserAction,GameCommon.CHK_YIZHIHUA_HU) ~= 0 then
            GameCommon:playAnimation(self.root, "一枝花",wChairID)
        elseif Bit:_and(pBuffer.cbUserAction,GameCommon.CHK_ZTSX_HU) ~= 0 then
            GameCommon:playAnimation(self.root, "中途四喜",wChairID)
        elseif Bit:_and(pBuffer.cbUserAction,GameCommon.CHK_ZTLLS_HU) ~= 0 then
            GameCommon:playAnimation(self.root, "中途六六顺",wChairID)
        else

        end
        
    elseif action == NetMsgId.SUB_S_CASTDICE_RESULT then
        local wChairID = pBuffer.wCurrentUser
        local viewID = GameCommon:getViewIDByChairID(wChairID)
        local uiPanel_tipsCardPos = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_tipsCardPos%d",viewID))
        local uiPanel_tipsCard = ccui.Helper:seekWidgetByName(self.root,"Panel_tipsCard")
        local uiSendOrOutCardNode = uiPanel_tipsCard:getChildByName("SendOrOutCardNode")
        if uiSendOrOutCardNode ~= nil then
            uiSendOrOutCardNode:runAction(cc.Sequence:create(
                cc.RemoveSelf:create(),
                cc.CallFunc:create(function(sender,event) 
                    self:addDiscardCard(sender.wChairID, sender.cbCardData) 
                end)))
        end
        local tableCard = {}
        if pBuffer.wDiceCardOne ~= 0 then
            table.insert(tableCard,#tableCard+1,pBuffer.wDiceCardOne)
        end
        if pBuffer.wDiceCardTwo ~= 0 then
            table.insert(tableCard,#tableCard+1,pBuffer.wDiceCardTwo)
        end
        for i = 1,6 do
            if pBuffer.wDiceCard~=nil and pBuffer.wDiceCard[i] ~= 0 then
                table.insert(tableCard,#tableCard+1,pBuffer.wDiceCard[i])
            end
        end  
        for key, var in pairs(tableCard) do
            uiSendOrOutCardNode = GameCommon:getDiscardCardAndWeaveItemArray(var,viewID)
            uiSendOrOutCardNode:setName(string.format("SendOrOutCardNode%d",key))
            uiSendOrOutCardNode.cbCardData = var
            uiSendOrOutCardNode.wChairID = wChairID
            uiPanel_tipsCard:addChild(uiSendOrOutCardNode)
            uiSendOrOutCardNode:setPosition(uiPanel_tipsCardPos:getPosition())
            uiSendOrOutCardNode:setScale(0)
            uiSendOrOutCardNode:runAction(cc.ScaleTo:create(0.2,1))
            self:updateLeftCardCount(GameCommon.cbLeftCardCount-1)
            GameCommon.btableCard = tableCard
            if #tableCard > 1 then
                local i = 0
                if key%2 == 0 then
                    i = -(key/2)
                else
                    i = key/2 +0.5
                end
                if viewID == 1 then   -- 两两麻将间距为 60   
                    if i == 1 or  i == -1 then
                        uiSendOrOutCardNode:setPositionX(uiSendOrOutCardNode:getPositionX()+(40*i))
                    elseif i == 2 or  i == -2 then
                        uiSendOrOutCardNode:setPositionX(uiSendOrOutCardNode:getPositionX()+(60*i))
                    elseif i == 3 or  i == -3 then
                        uiSendOrOutCardNode:setPositionX(uiSendOrOutCardNode:getPositionX()+(70*i))
                    end
                    
                elseif viewID == 2 then
                    if i == 1 or  i == -1 then
                        uiSendOrOutCardNode:setPositionY(uiSendOrOutCardNode:getPositionY()-(30*i))
                    elseif i == 2 or  i == -2 then
                        uiSendOrOutCardNode:setPositionY(uiSendOrOutCardNode:getPositionY()-(45*i))
                    elseif i == 3 or  i == -3 then
                        uiSendOrOutCardNode:setPositionY(uiSendOrOutCardNode:getPositionY()-(50*i))
                    end
                    
                elseif viewID == 3 then
                    if i == 1 or  i == -1 then
                        uiSendOrOutCardNode:setPositionX(uiSendOrOutCardNode:getPositionX()-(40*i))
                    elseif i == 2 or  i == -2 then
                        uiSendOrOutCardNode:setPositionX(uiSendOrOutCardNode:getPositionX()-(60*i))
                    elseif i == 3 or  i == -3 then
                        uiSendOrOutCardNode:setPositionX(uiSendOrOutCardNode:getPositionX()-(70*i))
                    end
                    
                elseif viewID == 4 then
                    if i == 1 or  i == -1 then
                        uiSendOrOutCardNode:setPositionY(uiSendOrOutCardNode:getPositionY()-(30*i))
                    elseif i == 2 or  i == -2 then
                        uiSendOrOutCardNode:setPositionY(uiSendOrOutCardNode:getPositionY()-(45*i))
                    elseif i == 3 or  i == -3 then
                        uiSendOrOutCardNode:setPositionY(uiSendOrOutCardNode:getPositionY()-(50*i))
                    end
                end
            end
        end
        self:showCountDown(wChairID)
        self:runAction(cc.Sequence:create(cc.DelayTime:create(0.5),cc.CallFunc:create(function(sender,event) EventMgr:dispatch(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK) end)))
	
    elseif action == NetMsgId.SUB_S_OPERATE_HAIDI then
        local uiPanel_tipsCard = ccui.Helper:seekWidgetByName(self.root,"Panel_tipsCard")
        if GameCommon.tableConfig.wKindID == 50 and GameCommon.tableConfig.wKindID == 70 then
            local  n = 2
            if GameCommon.gameConfig.mKGNPFlag ~= nil and GameCommon.gameConfig.mKGNPFlag ~= 0 then 
                n = GameCommon.gameConfig.mKGNPFlag
            end 
            for i = 1, n do
                local uiSendOrOutCardNode = uiPanel_tipsCard:getChildByName(string.format("SendOrOutCardNode%d",i))
                if uiSendOrOutCardNode ~= nil then
                    uiSendOrOutCardNode:runAction(cc.Sequence:create(
                        cc.RemoveSelf:create(),
                        cc.CallFunc:create(function(sender,event) 
                            self:addDiscardCard(sender.wChairID, sender.cbCardData) 
                        end)))
                end
            end
        end
        local uiSendOrOutCardNode = uiPanel_tipsCard:getChildByName("SendOrOutCardNode")
        if uiSendOrOutCardNode ~= nil then
            uiSendOrOutCardNode:runAction(cc.Sequence:create(
                cc.RemoveSelf:create(),
                cc.CallFunc:create(function(sender,event) 
                    self:addDiscardCard(sender.wChairID, sender.cbCardData) 
                end)))
        end
        if pBuffer.wCurrentUser == GameCommon:getRoleChairID() then
            local oprationLayer = GameOpration:create(pBuffer,1)
            local uiPanel_operation = ccui.Helper:seekWidgetByName(self.root,"Panel_operation")
            uiPanel_operation:addChild(oprationLayer)
            uiPanel_operation:setVisible(true)
            Common:playEffect("game/audio_tip_operate.mp3")
        end
        self:runAction(cc.Sequence:create(cc.DelayTime:create(0),cc.CallFunc:create(function(sender,event) EventMgr:dispatch(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK) end)))
	
    elseif action == NetMsgId.SUB_S_SEND_HAIDICARD then
        GameCommon.waitOutCardUser = nil
        local uiPanel_outCardTips = ccui.Helper:seekWidgetByName(self.root,"Panel_outCardTips")
        uiPanel_outCardTips:removeAllChildren()
        local wChairID = pBuffer.wCurrentUser
        local viewID = GameCommon:getViewIDByChairID(wChairID)
        local uiPanel_tipsCardPos = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_tipsCardPos%d",viewID))
        local uiPanel_tipsCard = ccui.Helper:seekWidgetByName(self.root,"Panel_tipsCard")
        local uiSendOrOutCardNode = uiPanel_tipsCard:getChildByName("SendOrOutCardNode")
        if uiSendOrOutCardNode ~= nil then
            uiSendOrOutCardNode:runAction(cc.Sequence:create(
                cc.RemoveSelf:create(),
                cc.CallFunc:create(function(sender,event) 
                    self:addDiscardCard(sender.wChairID, sender.cbCardData) 
                end)))
        end
        uiSendOrOutCardNode = GameCommon:getDiscardCardAndWeaveItemArray(pBuffer.cbCardData,viewID)
        uiSendOrOutCardNode:setName("SendOrOutCardNode")
        uiSendOrOutCardNode.cbCardData = pBuffer.cbCardData
        uiSendOrOutCardNode.wChairID = wChairID
        uiPanel_tipsCard:addChild(uiSendOrOutCardNode)
        uiSendOrOutCardNode:setPosition(uiPanel_tipsCardPos:getPosition())
        uiSendOrOutCardNode:setScale(0)
        uiSendOrOutCardNode:runAction(cc.ScaleTo:create(0.2,1))
        GameCommon:playAnimation(self.root, pBuffer.cbOutCardData,wChairID)
        self:runAction(cc.Sequence:create(cc.DelayTime:create(0.5),cc.CallFunc:create(function(sender,event) EventMgr:dispatch(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK) end)))

    elseif action == NetMsgId.SUB_S_WCWD then
        if pBuffer.mCode == 0 and  GameCommon.tableConfig.wKindID == 67 then 
            local oprationLayer = GameOpration:create(pBuffer,2)
            local uiPanel_operation = ccui.Helper:seekWidgetByName(self.root,"Panel_operation")
            uiPanel_operation:addChild(oprationLayer)
            uiPanel_operation:setVisible(true)
            -- Common:playEffect("game/audio_tip_operate.mp3")
            self:runAction(cc.Sequence:create(cc.DelayTime:create(0),cc.CallFunc:create(function(sender,event) EventMgr:dispatch(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK) end)))
        else
            local wChairID = pBuffer.mWCWDUser
        --    local cbActionCard = pBuffer.cbActionCard
            local viewID = GameCommon:getViewIDByChairID(wChairID)
            local uiPanel_tipsCard = ccui.Helper:seekWidgetByName(self.root,"Panel_tipsCard")
            local uiPanel_tipsCardPos = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_tipsCardPos%d",viewID))
            local count = 1
            local mWCWDOperate = pBuffer.mWCWDOperate 
            GameCommon.mWCWDOperate = 0
            if Bit:_and(mWCWDOperate,GameCommon.WIK_WD) ~= 0 then--王钓
                for i = 1, 1 do
                    local card = GameCommon:GetHUCard(GameCommon.CardData_WW)
                    card.cbCardData = GameCommon.CardData_WW
                    card.wChairID = wChairID
                    uiPanel_tipsCard:addChild(card)
                     if uiPanel_tipsCardPos:getAnchorPoint().x == 1 then
                        card:setPosition(uiPanel_tipsCardPos:getPositionX() + i*100,uiPanel_tipsCardPos:getPositionY())
                    else
                        card:setPosition(uiPanel_tipsCardPos:getPositionX() - i*100,uiPanel_tipsCardPos:getPositionY())
                    end
                    card:setScale(0)
                    card:runAction(cc.ScaleTo:create(0.2,1))
                end            
                GameCommon:playAnimation(self.root, "王钓",wChairID)
            elseif Bit:_and(mWCWDOperate,GameCommon.WIK_WC) ~= 0 then--王闯
                GameCommon.mWCWDOperate = 2
                for i = 1, 2 do
                    local card = GameCommon:GetHUCard(GameCommon.CardData_WW)
                    card.cbCardData = GameCommon.CardData_WW
                    card.wChairID = wChairID
                    uiPanel_tipsCard:addChild(card)
                     if uiPanel_tipsCardPos:getAnchorPoint().x == 1 then
                        card:setPosition(uiPanel_tipsCardPos:getPositionX() + i*100,uiPanel_tipsCardPos:getPositionY())
                    else
                        card:setPosition(uiPanel_tipsCardPos:getPositionX() - i*100,uiPanel_tipsCardPos:getPositionY())
                    end
                    card:setScale(0)
                    card:runAction(cc.ScaleTo:create(0.2,1))
                end
                GameCommon:playAnimation(self.root, "王闯",wChairID)
            end
            self:runAction(cc.Sequence:create(cc.DelayTime:create(0.5),cc.CallFunc:create(function(sender,event) EventMgr:dispatch(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK) end)))
        end 
    elseif action == NetMsgId.CMD_S_WCWDSendCard then          --王闯王钓拿牌
        local wChairID = pBuffer.GetCardUser
        local viewID = GameCommon:getViewIDByChairID(wChairID)
        local uiPanel_tipsCard = ccui.Helper:seekWidgetByName(self.root,"Panel_tipsCard")
        local uiPanel_tipsCardPos = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_tipsCardPos%d",viewID))

        local card = GameCommon:GetHUCard(pBuffer.cbCardData)
        card.cbCardData = pBuffer.cbCardData
        card.wChairID = wChairID
        uiPanel_tipsCard:addChild(card)
        GameCommon.waitOutCardUser = wChairID
        if uiPanel_tipsCardPos:getAnchorPoint().x == 1 then
            if GameCommon.mWCWDOperate ~= nil and GameCommon.mWCWDOperate == 2 then 
                card:setPosition(uiPanel_tipsCardPos:getPositionX() + 300,uiPanel_tipsCardPos:getPositionY())
            else
                card:setPosition(uiPanel_tipsCardPos:getPositionX() + 240,uiPanel_tipsCardPos:getPositionY())
            end 
        else
            if GameCommon.mWCWDOperate ~= nil and GameCommon.mWCWDOperate == 2 then 
                card:setPosition(uiPanel_tipsCardPos:getPositionX() - 300,uiPanel_tipsCardPos:getPositionY())
            else
                card:setPosition(uiPanel_tipsCardPos:getPositionX() - 240,uiPanel_tipsCardPos:getPositionY())
            end 
        end
        card:setScale(0)
        card:runAction(cc.ScaleTo:create(0.2,1))
        self:runAction(cc.Sequence:create(cc.DelayTime:create(0.5),cc.CallFunc:create(function(sender,event) EventMgr:dispatch(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK) end)))

    else
	
	end
	
end

------============================------
--desc:相关数据客户端整理运行
--time:2019-02-13 09:24:00
--@wChairID:
--@return   
------=============================------
function TableLayer:DataClient(pBuffer)  
    pBuffer.tableChiCard = {} 
    pBuffer.tablePengCard = {} 
    pBuffer.tableGangCard = {}
    pBuffer.tableBuCard = {}
    pBuffer.tableHuCard = {}
    pBuffer.tableBiHuCard = {}
    for i = 1,24 do 
        local cbOperateCode = pBuffer.mGangItemArray[i].cbGangKind
        local tableActionCard = pBuffer.mGangItemArray[i].cbPublicCard
        if Bit:_and(cbOperateCode,GameCommon.WIK_LEFT) ~= 0 or Bit:_and(cbOperateCode,GameCommon.WIK_CENTER) ~= 0 or Bit:_and(cbOperateCode,GameCommon.WIK_RIGHT) ~= 0 then
            table.insert(pBuffer.tableChiCard,#pBuffer.tableChiCard+1,{tableActionCard = tableActionCard,cbOperateCode=cbOperateCode})
        end
        if Bit:_and(cbOperateCode,GameCommon.WIK_PENG) ~= 0 then
            table.insert(pBuffer.tablePengCard,#pBuffer.tablePengCard+1,{tableActionCard = tableActionCard,cbOperateCode=cbOperateCode})
        end 

        if Bit:_and(cbOperateCode,GameCommon.WIK_FILL) ~= 0 then
            table.insert(pBuffer.tableBuCard,#pBuffer.tableBuCard+1,{tableActionCard = tableActionCard,cbOperateCode=cbOperateCode})
        end 

        if Bit:_and(cbOperateCode,GameCommon.WIK_GANG) ~= 0 then
            table.insert(pBuffer.tableGangCard,#pBuffer.tableGangCard+1,{tableActionCard = tableActionCard,cbOperateCode=cbOperateCode})
        end 

        if Bit:_and(cbOperateCode,GameCommon.WIK_CHI_HU) ~= 0 then
            table.insert(pBuffer.tableHuCard,#pBuffer.tableHuCard+1,{tableActionCard = tableActionCard,cbOperateCode=cbOperateCode})
        end

        if Bit:_and(cbOperateCode,GameCommon.WIK_BIHU) ~= 0  or  Bit:_and(cbOperateCode,GameCommon.CHR_GANG) ~= 0  then
             if GameCommon.waitGangCardUser == GameCommon:getRoleChairID() then 
                table.insert(pBuffer.tableBiHuCard,#pBuffer.tableBiHuCard+1,{tableActionCard = tableActionCard,cbOperateCode=cbOperateCode})
            else
                table.insert(pBuffer.tableHuCard,#pBuffer.tableHuCard+1,{tableActionCard = tableActionCard,cbOperateCode=cbOperateCode})
            end 
        end
    end   

    local oprationLayer = GameGangOpration:create(pBuffer)
    local uiPanel_operation = ccui.Helper:seekWidgetByName(self.root,"Panel_operation")
    uiPanel_operation:removeAllChildren()   
    uiPanel_operation:addChild(oprationLayer)
    uiPanel_operation:setVisible(true)
    GameCommon.waitGangCardUser = nil 
    self:runAction(cc.Sequence:create(cc.DelayTime:create(0),cc.CallFunc:create(function(sender,event) EventMgr:dispatch(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK) end)))
end

-- function TableLayer:showBaoting(pBuffer)
--     GameCommon.mHuCard = {}
--     for i = 1, 27 do
--         if pBuffer.cbGangCard[i]~= nil and pBuffer.cbGangCard[i] ~= 0 then 
--             GameCommon.mHuCard[i] = pBuffer.cbGangCard[i]                  
--         end 
--         print("---------可胡的牌：",i,pBuffer.cbGangCard[i])             
--     end
--     -- print("可以的赢了",GameCommon.mHuCard)
--     if GameCommon.cdTingData ~=nil then          --       GameCommon.mHuCard~= {} and GameCommon.mHuCard [1] ~=nil
--         self:huCardShow(0,GameCommon.cdTingData)
--     else
--         require("common.MsgBoxLayer"):create(0,nil,"您还未报听!!!")             
--     end 
--     self:runAction(cc.Sequence:create(cc.DelayTime:create(0),cc.CallFunc:create(function(sender,event) EventMgr:dispatch(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK) end)))       
-- end 

function TableLayer:showCountDown(wChairID)
    for i = 0 ,3 do 
    local n = GameCommon:getViewIDByChairID(i) 
   
    end 
    local viewID = GameCommon:getViewIDByChairID(wChairID)
    local uiImage_direction = ccui.Helper:seekWidgetByName(self.root,"Image_direction")
    local uiAtlasLabel_countdownTime = ccui.Helper:seekWidgetByName(self.root,"AtlasLabel_countdownTime")
    local uiText_stack = ccui.Helper:seekWidgetByName(self.root,"Text_stack")
  
    local seat = 0
    local num = GameCommon:getViewIDByChairID(seat) 
    if GameCommon.gameConfig.bPlayerCount == 4 then
        if seat == 0 and num == 1 then
            uiImage_direction:setRotation(90)
            uiAtlasLabel_countdownTime:setRotation(270)
            uiText_stack:setRotation(270)
        elseif seat == 0 and num == 2 then
            uiImage_direction:setRotation(180)
            uiAtlasLabel_countdownTime:setRotation(180)
            uiText_stack:setRotation(180)
        elseif seat == 0 and num == 3 then
            uiImage_direction:setRotation(270)
            uiAtlasLabel_countdownTime:setRotation(90)
            uiText_stack:setRotation(90)
        elseif seat == 0 and num == 4 then
            uiImage_direction:setRotation(0)
            uiAtlasLabel_countdownTime:setRotation(0)
            uiText_stack:setRotation(0)
        end 
    elseif GameCommon.gameConfig.bPlayerCount == 3 then     
        if seat == 0 and num == 1 then
            uiImage_direction:setRotation(90)
            uiAtlasLabel_countdownTime:setRotation(270)
            uiText_stack:setRotation(270)
        elseif seat == 0 and num == 2 then
            uiImage_direction:setRotation(180)
            uiAtlasLabel_countdownTime:setRotation(180)
            uiText_stack:setRotation(180)
        elseif seat == 0 and num == 3 then
            uiImage_direction:setRotation(270)
            uiAtlasLabel_countdownTime:setRotation(90)
            uiText_stack:setRotation(90)
        elseif seat == 0 and num == 4 then
            uiImage_direction:setRotation(0)
            uiAtlasLabel_countdownTime:setRotation(0)
            uiText_stack:setRotation(0)
        end 
    elseif GameCommon.gameConfig.bPlayerCount == 2 then    
        if seat == 0 and num == 1 then
            uiImage_direction:setRotation(90)
            uiAtlasLabel_countdownTime:setRotation(270)
            uiText_stack:setRotation(270)
        elseif seat == 0 and num == 3 then
            uiImage_direction:setRotation(270)
            uiAtlasLabel_countdownTime:setRotation(90)
            uiText_stack:setRotation(90)
        end
    end 
    uiAtlasLabel_countdownTime:setPosition(uiAtlasLabel_countdownTime:getParent():getContentSize().width/2,uiAtlasLabel_countdownTime:getParent():getContentSize().height/2)
    uiAtlasLabel_countdownTime:stopAllActions()
    uiAtlasLabel_countdownTime:setString(15)
    
    local function onEventTime(sender,event)
        local currentTime = tonumber(uiAtlasLabel_countdownTime:getString())
        currentTime = currentTime - 1
        if currentTime < 0 then
            currentTime = 0
        end
        uiAtlasLabel_countdownTime:setString(tostring(currentTime))

        --自己出牌最后5秒倒计时音效
        -- if viewID == 1 and currentTime <= 5 then
        --     Common:playEffect('game/timeup_alarm.mp3')
        -- end
    end

    uiAtlasLabel_countdownTime:runAction(cc.RepeatForever:create(cc.Sequence:create(cc.DelayTime:create(1),cc.CallFunc:create(onEventTime))))    
    local uiPanel_outCardTips = ccui.Helper:seekWidgetByName(self.root,"Panel_outCardTips")
    uiPanel_outCardTips:removeAllChildren()
    local uiImage_dir = ccui.Helper:seekWidgetByName(self.root,string.format("Image_%d",0))
    if GameCommon.gameConfig.bPlayerCount == 4 then
        for i = 0 ,3 do
            uiImage_dir = ccui.Helper:seekWidgetByName(self.root,string.format("Image_%d",i))
            uiImage_dir:stopAllActions()
            uiImage_dir:setVisible(false)
        end  
        uiImage_dir = ccui.Helper:seekWidgetByName(self.root,string.format("Image_%d",wChairID))
    elseif GameCommon.gameConfig.bPlayerCount == 3 then    
        for i = 0 ,3 do
            uiImage_dir = ccui.Helper:seekWidgetByName(self.root,string.format("Image_%d",i))
            uiImage_dir:setVisible(false)
            uiImage_dir:stopAllActions()        
        end  
        if seat == 0 and num == 1 then
            if wChairID == 0 then 
                uiImage_dir = ccui.Helper:seekWidgetByName(self.root,string.format("Image_%d",0))
            elseif wChairID == 1 then 
                uiImage_dir = ccui.Helper:seekWidgetByName(self.root,string.format("Image_%d",1))          
            elseif wChairID == 2 then  
                uiImage_dir = ccui.Helper:seekWidgetByName(self.root,string.format("Image_%d",2))          
            end 
        elseif seat == 0 and num == 2 then
            if wChairID == 0 then 
                uiImage_dir = ccui.Helper:seekWidgetByName(self.root,string.format("Image_%d",0))
            elseif wChairID == 1 then 
                uiImage_dir = ccui.Helper:seekWidgetByName(self.root,string.format("Image_%d",1))          
            elseif wChairID == 2 then  
                uiImage_dir = ccui.Helper:seekWidgetByName(self.root,string.format("Image_%d",3))          
            end
        elseif seat == 0 and num == 3 then
            if wChairID == 0 then 
                uiImage_dir = ccui.Helper:seekWidgetByName(self.root,string.format("Image_%d",0))
            elseif wChairID == 1 then 
                uiImage_dir = ccui.Helper:seekWidgetByName(self.root,string.format("Image_%d",2))          
            elseif wChairID == 2 then  
                uiImage_dir = ccui.Helper:seekWidgetByName(self.root,string.format("Image_%d",3))          
            end
        end 
    elseif GameCommon.gameConfig.bPlayerCount == 2 then   
        for i = 0 ,3 do
            uiImage_dir = ccui.Helper:seekWidgetByName(self.root,string.format("Image_%d",i))
            uiImage_dir:setVisible(false)
            uiImage_dir:stopAllActions()        
        end       
  
        if wChairID == 0 then 
            uiImage_dir = ccui.Helper:seekWidgetByName(self.root,string.format("Image_%d",0))        
        else
            uiImage_dir = ccui.Helper:seekWidgetByName(self.root,string.format("Image_%d",2))          
        end
    end
    if uiImage_dir ~= nil then
        uiImage_dir:runAction(cc.RepeatForever:create(cc.Blink:create(1,1)))
    end 
end

--更新牌堆
function TableLayer:updateLeftCardCount(cbLeftCardCount)
    GameCommon.cbLeftCardCount = cbLeftCardCount
    local uiText_stack = ccui.Helper:seekWidgetByName(self.root,"Text_stack")
    uiText_stack:setString(string.format("剩余%d",GameCommon.cbLeftCardCount))
    uiText_stack:setVisible(true)
end

-------------------------------------------------------吃牌组合-----------------------------------------------------

--添加吃牌组合
function TableLayer:addWeaveItemArray(wChairID,WeaveItemArray)
    local cbCardList = self:getWeaveItemArray(WeaveItemArray)
    local isFound = false
    local pos = GameCommon.player[wChairID].bWeaveItemCount + 1
    if Bit:_and(WeaveItemArray.cbWeaveKind,GameCommon.WIK_GANG) ~= 0 then
        if WeaveItemArray.cbPublicCard == 0 then
            if wChairID == GameCommon:getRoleChairID()  then 
                local uiPanel_handCard = ccui.Helper:seekWidgetByName(self.root,"Panel_handCard1")
                local items = uiPanel_handCard:getChildren()
                --遍历查找
                local foundNode = false
                for key, var in pairs(items) do
                    if var.data == cbCardList[1] then
                        foundNode = true
                        break
                    end
                end
                if foundNode == true then   
                --先碰后来再杠的
                    self:removeHandCard(wChairID,cbCardList[1])
                end 
            else
                if (GameCommon.tableConfig.wKindID ~= 50 and GameCommon.tableConfig.wKindID ~= 70)or GameCommon.mGang ~= true then
                    self:removeHandCard(wChairID,cbCardList[1])
                end 
            end 
            for i = 1, GameCommon.player[wChairID].bWeaveItemCount do
                local var = GameCommon.player[wChairID].WeaveItemArray[i]
                if var.cbCenterCard == WeaveItemArray.cbCenterCard then
                    GameCommon.player[wChairID].WeaveItemArray[i] = WeaveItemArray
                    isFound = true
                    pos = i
                    break
                end
            end
        elseif WeaveItemArray.cbPublicCard == 1 then
            --别人打的杠
            for key, var in pairs(cbCardList) do
                if key ~= 4 then
                    self:removeHandCard(wChairID,var)
                end
            end
            if(GameCommon.tableConfig.wKindID == 50 or GameCommon.tableConfig.wKindID == 70)then 
                for i = 1, GameCommon.player[wChairID].bWeaveItemCount do
                    local var = GameCommon.player[wChairID].WeaveItemArray[i]
                    if var.cbCenterCard == WeaveItemArray.cbCenterCard then
                        GameCommon.player[wChairID].WeaveItemArray[i] = WeaveItemArray
                        isFound = true
                        pos = i
                        break
                    end
                end
            end 
        elseif WeaveItemArray.cbPublicCard == 2 then          
            --暗杠
            for key, var in pairs(cbCardList) do
                self:removeHandCard(wChairID,var)
            end       
        else    
        end
        if(GameCommon.tableConfig.wKindID == 50 or GameCommon.tableConfig.wKindID == 70)then 
            GameCommon.mGang = true
        end     
    elseif Bit:_and(WeaveItemArray.cbWeaveKind,GameCommon.WIK_FILL) ~= 0 then
        if WeaveItemArray.cbPublicCard == 0 then
            --先碰后来再杠的
            self:removeHandCard(wChairID,cbCardList[1])
            for i = 1, GameCommon.player[wChairID].bWeaveItemCount do
                local var = GameCommon.player[wChairID].WeaveItemArray[i]
                if var.cbCenterCard == WeaveItemArray.cbCenterCard then
                    GameCommon.player[wChairID].WeaveItemArray[i] = WeaveItemArray
                    isFound = true
                    pos = i
                    break
                end
            end
        elseif WeaveItemArray.cbPublicCard == 1 then
            --别人打的杠
            for key, var in pairs(cbCardList) do
                if key ~= 4 then
                    self:removeHandCard(wChairID,var)
                end
            end
            for i = 1, GameCommon.player[wChairID].bWeaveItemCount do
                local var = GameCommon.player[wChairID].WeaveItemArray[i]
                if var.cbCenterCard == WeaveItemArray.cbCenterCard then
                    GameCommon.player[wChairID].WeaveItemArray[i] = WeaveItemArray
                    isFound = true
                    pos = i
                    break
                end
            end
        elseif WeaveItemArray.cbPublicCard == 2 then
            --暗杠
            for key, var in pairs(cbCardList) do
                self:removeHandCard(wChairID,var)
            end
        else

        end
         
    elseif Bit:_and(WeaveItemArray.cbWeaveKind,GameCommon.WIK_LEFT) ~= 0 then
        for key, var in pairs(cbCardList) do
            if key ~= 2 then
                self:removeHandCard(wChairID,var)
            end
        end
        
    elseif Bit:_and(WeaveItemArray.cbWeaveKind,GameCommon.WIK_CENTER) ~= 0 then
        for key, var in pairs(cbCardList) do
            if key ~= 2 then
                self:removeHandCard(wChairID,var)
            end
        end
        
    elseif Bit:_and(WeaveItemArray.cbWeaveKind,GameCommon.WIK_RIGHT) ~= 0 then
        for key, var in pairs(cbCardList) do
            if key ~= 2 then
                self:removeHandCard(wChairID,var)
            end
        end
        
    elseif Bit:_and(WeaveItemArray.cbWeaveKind,GameCommon.WIK_PENG) ~= 0 then
        for key, var in pairs(cbCardList) do
            if key ~= 3 then
                self:removeHandCard(wChairID,var)
            end
        end
        
    else
     
    end
    self:showHandCard(wChairID,2)
    if isFound == false then
        GameCommon.player[wChairID].bWeaveItemCount = GameCommon.player[wChairID].bWeaveItemCount + 1
        GameCommon.player[wChairID].WeaveItemArray[GameCommon.player[wChairID].bWeaveItemCount] = WeaveItemArray
    end
    local viewID = GameCommon:getViewIDByChairID(wChairID)
    local node = self:setWeaveItemArray(wChairID, GameCommon.player[wChairID].bWeaveItemCount, GameCommon.player[wChairID].WeaveItemArray,pos)
    local srcPos = cc.p(node:getPosition())
    local uiPanel_tipsCardPos = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_tipsCardPos%d",viewID))
    node:setPosition(cc.p(node:getParent():convertToNodeSpace(cc.p(uiPanel_tipsCardPos:getPosition()))))
    node:runAction(cc.MoveTo:create(0.2,srcPos))
end

function TableLayer:getWeaveItemArray(var)
    local cbCardList = {}
    if Bit:_and(var.cbWeaveKind,GameCommon.WIK_GANG) ~= 0 then
        cbCardList = {var.cbCenterCard,var.cbCenterCard,var.cbCenterCard,var.cbCenterCard}
    elseif Bit:_and(var.cbWeaveKind,GameCommon.WIK_FILL) ~= 0 then        
        cbCardList = {var.cbCenterCard,var.cbCenterCard,var.cbCenterCard,var.cbCenterCard}
    elseif Bit:_and(var.cbWeaveKind,GameCommon.WIK_PENG) ~= 0 then
        cbCardList = {var.cbCenterCard,var.cbCenterCard,var.cbCenterCard}
    elseif Bit:_and(var.cbWeaveKind,GameCommon.WIK_LEFT) ~= 0 then
    
        if (var.cbCenterCard >= 49 and var.cbCenterCard <= 55) and GameCommon.tableConfig.wKindID == 65 then
            cbCardList = {var.wChiFengJianCard[1],var.wChiFengJianCard[2],var.wChiFengJianCard[3]}
        else
            cbCardList = {var.cbCenterCard+1,var.cbCenterCard,var.cbCenterCard+2}
        end   
    elseif Bit:_and(var.cbWeaveKind,GameCommon.WIK_CENTER) ~= 0 then
        cbCardList = {var.cbCenterCard-1,var.cbCenterCard,var.cbCenterCard+1}
    elseif Bit:_and(var.cbWeaveKind,GameCommon.WIK_RIGHT) ~= 0 then
        cbCardList = {var.cbCenterCard-2,var.cbCenterCard,var.cbCenterCard-1}
    else
        assert(false,"吃牌类型错误")
    end
    return cbCardList
end

--更新吃牌组合
function TableLayer:setWeaveItemArray(wChairID, bWeaveItemCount, WeaveItemArray,pos)
    GameCommon.player[wChairID].bWeaveItemCount = bWeaveItemCount
    GameCommon.player[wChairID].WeaveItemArray = WeaveItemArray
    local viewID = GameCommon:getViewIDByChairID(wChairID)
    local uiPanel_weaveItemArray = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_weaveItemArray%d",viewID))
    uiPanel_weaveItemArray:removeAllChildren()
    local size = uiPanel_weaveItemArray:getContentSize()
    local bWeaveItemCount = GameCommon.player[wChairID].bWeaveItemCount
    local WeaveItemArray = GameCommon.player[wChairID].WeaveItemArray
    local node = nil
    if viewID == 1 then
        local cardScale = 1
        local cardWidth = 55 * cardScale
        local cardHeight = 85 * cardScale
        local beganX = cardWidth/2
        local beganY = cardHeight/2
        local stepX = cardWidth*3
        local stepY = 0
        for key = 1, bWeaveItemCount do
            local var = GameCommon.player[wChairID].WeaveItemArray[key]
            local content = ccui.Layout:create()
            if key == pos then
                node = content
            end
            GameCommon.player[wChairID].WeaveItemArray[key].node = content
            uiPanel_weaveItemArray:addChild(content)
            content:setContentSize(cc.size(cardWidth*3,size.height))
            content:setPosition(stepX*(key-1),0)
            local cbCardList = self:getWeaveItemArray(var)
            for k, v in pairs(cbCardList) do
                local card = nil
                if k < 4 and var.cbPublicCard == 2 and (Bit:_and(var.cbWeaveKind,GameCommon.WIK_GANG) ~= 0 or Bit:_and(var.cbWeaveKind,GameCommon.WIK_FILL) ~= 0) then
                    card = GameCommon:getDiscardCardAndWeaveItemArray(0,viewID)
                else
                    card = GameCommon:getDiscardCardAndWeaveItemArray(v,viewID)
                    if k == 2 and Bit:_and(var.cbWeaveKind,GameCommon.WIK_LEFT) ~= 0 then
                        card:setColor(cc.c3b(170,170,170))
                    elseif k == 2 and Bit:_and(var.cbWeaveKind,GameCommon.WIK_CENTER) ~= 0 then
                        card:setColor(cc.c3b(170,170,170))
                    elseif k == 2 and Bit:_and(var.cbWeaveKind,GameCommon.WIK_RIGHT) ~= 0 then
                        card:setColor(cc.c3b(170,170,170))
                    else
                    end
                end
                content:addChild(card)
                if k == 4 then
                    card:setScale(cardScale) 
                    card:setPosition(cardWidth/2+(2-1)*cardWidth,size.height/2+20)
                else
                    card:setScale(cardScale) 
                    card:setPosition(cardWidth/2+(k-1)*cardWidth,size.height/2)
                end
            end
        end
        
    elseif viewID == 2 then
        local cardScale = 1
        local cardWidth = 54 * cardScale
        local cardHeight = 53 * cardScale
        local beganX = 0
        local beganY = size.height-(cardHeight-20)*3
        local stepX = 0
        local stepY = -((cardHeight-20)*3)
        for key = 1, bWeaveItemCount do
            local var = GameCommon.player[wChairID].WeaveItemArray[key]
            local content = ccui.Layout:create()
            if key == pos then
                node = content
            end
            GameCommon.player[wChairID].WeaveItemArray[key].node = content
            uiPanel_weaveItemArray:addChild(content)
            content:setContentSize(cc.size(size.width,(cardHeight-20)*3))
            content:setPosition(beganX,beganY + stepY*(key-1))
            local cbCardList = self:getWeaveItemArray(var)
            for k, v in pairs(cbCardList) do
                local card = nil
                if k < 4 and var.cbPublicCard == 2 and (Bit:_and(var.cbWeaveKind,GameCommon.WIK_GANG) ~= 0 or Bit:_and(var.cbWeaveKind,GameCommon.WIK_FILL) ~= 0) then
                    card = GameCommon:getDiscardCardAndWeaveItemArray(0,viewID)
                else
                    card = GameCommon:getDiscardCardAndWeaveItemArray(v,viewID)
                    if k == 2 and Bit:_and(var.cbWeaveKind,GameCommon.WIK_LEFT) ~= 0 then
                        card:setColor(cc.c3b(170,170,170))
                    elseif k == 2 and Bit:_and(var.cbWeaveKind,GameCommon.WIK_CENTER) ~= 0 then
                        card:setColor(cc.c3b(170,170,170))
                    elseif k == 2 and Bit:_and(var.cbWeaveKind,GameCommon.WIK_RIGHT) ~= 0 then
                        card:setColor(cc.c3b(170,170,170))
                    else
                    end
                end
                content:addChild(card)
                if k == 4 then
                    card:setScale(cardScale) 
                    card:setPosition(size.width/2,cardHeight/2+(2-1)*(cardHeight-20))
                    card:setLocalZOrder(4)    
                else
                    card:setScale(cardScale) 
                    card:setPosition(size.width/2,cardHeight/2-20+(k-1)*(cardHeight-20))
                    card:setLocalZOrder(3-k)    
                end  
            end
        end
    elseif viewID == 3 then
        local cardScale = 0.9
        local cardWidth = 55 * cardScale
        local cardHeight = 85 * cardScale
        local beganX = size.width-cardWidth*3
        local beganY = 0
        local stepX = 0
        local stepY = -(cardWidth)*3
        for key = 1, bWeaveItemCount do
            local var = GameCommon.player[wChairID].WeaveItemArray[key]
            local content = ccui.Layout:create()
            if key == pos then
                node = content
            end
            GameCommon.player[wChairID].WeaveItemArray[key].node = content
            uiPanel_weaveItemArray:addChild(content)
            content:setContentSize(cc.size(cardWidth*3,size.height))
            content:setPosition(beganX + stepY*(key-1),beganY)
            local cbCardList = self:getWeaveItemArray(var)
            for k, v in pairs(cbCardList) do
                local card = nil
                if k < 4 and var.cbPublicCard == 2 and (Bit:_and(var.cbWeaveKind,GameCommon.WIK_GANG) ~= 0 or Bit:_and(var.cbWeaveKind,GameCommon.WIK_FILL) ~= 0) then
                    card = GameCommon:getDiscardCardAndWeaveItemArray(0,viewID)
                else
                    card = GameCommon:getDiscardCardAndWeaveItemArray(v,viewID)
                    if k == 2 and Bit:_and(var.cbWeaveKind,GameCommon.WIK_LEFT) ~= 0 then
                        card:setColor(cc.c3b(170,170,170))
                    elseif k == 2 and Bit:_and(var.cbWeaveKind,GameCommon.WIK_CENTER) ~= 0 then
                        card:setColor(cc.c3b(170,170,170))
                    elseif k == 2 and Bit:_and(var.cbWeaveKind,GameCommon.WIK_RIGHT) ~= 0 then
                        card:setColor(cc.c3b(170,170,170))
                    else
                    end
                end
                content:addChild(card)
                if k == 4 then
                    card:setScale(cardScale) 
                    card:setPosition(cardWidth/2+(2-1)*cardWidth,size.height/2+12)
                    card:setLocalZOrder(4)  
                else
                    card:setScale(cardScale) 
                    card:setPosition(cardWidth/2+(k-1)*cardWidth,size.height/2)
                    card:setLocalZOrder(3-k)      
                end
            end
        end
    elseif viewID == 4 then
        local cardScale = 1
        local cardWidth = 54 * cardScale
        local cardHeight = 53 * cardScale
        local beganX = 0
        local beganY = 0
        local stepX = 0
        local stepY = (cardHeight-20)*3
        for key = 1, bWeaveItemCount do
            local var = GameCommon.player[wChairID].WeaveItemArray[key]
            local content = ccui.Layout:create()
            if key == pos then
                node = content
            end
            GameCommon.player[wChairID].WeaveItemArray[key].node = content
            uiPanel_weaveItemArray:addChild(content)
            content:setContentSize(cc.size(size.width,(cardHeight-20)*3))
            content:setPosition(beganX,beganY + stepY*(key-1))
            content:setLocalZOrder(bWeaveItemCount-key)  
            local cbCardList = self:getWeaveItemArray(var)
            for k, v in pairs(cbCardList) do
                local card = nil
                if k < 4 and var.cbPublicCard == 2 and (Bit:_and(var.cbWeaveKind,GameCommon.WIK_GANG) ~= 0 or Bit:_and(var.cbWeaveKind,GameCommon.WIK_FILL) ~= 0) then
                    card = GameCommon:getDiscardCardAndWeaveItemArray(0,viewID)
                else
                    card = GameCommon:getDiscardCardAndWeaveItemArray(v,viewID)
                    if k == 2 and Bit:_and(var.cbWeaveKind,GameCommon.WIK_LEFT) ~= 0 then
                        card:setColor(cc.c3b(170,170,170))
                    elseif k == 2 and Bit:_and(var.cbWeaveKind,GameCommon.WIK_CENTER) ~= 0 then
                        card:setColor(cc.c3b(170,170,170))
                    elseif k == 2 and Bit:_and(var.cbWeaveKind,GameCommon.WIK_RIGHT) ~= 0 then
                        card:setColor(cc.c3b(170,170,170))
                    else
                    end
                end
                content:addChild(card)
                if k == 4 then
                    card:setScale(cardScale) 
                    card:setPosition(size.width/2,cardHeight/2+(2-1)*(cardHeight))
                    card:setLocalZOrder(4)  
                else
                    card:setScale(cardScale) 
                    card:setPosition(size.width/2,cardHeight/2+(k-1)*(cardHeight-20))
                    card:setLocalZOrder(3-k)   
                end 
            end
        end
    end
    return node
end

-------------------------------------------------------弃牌-----------------------------------------------------

--添加弃牌
function TableLayer:addDiscardCard(wChairID, cbDiscardCard)
    GameCommon.player[wChairID].cbDiscardCount = GameCommon.player[wChairID].cbDiscardCount + 1 
    GameCommon.player[wChairID].cbDiscardCard[GameCommon.player[wChairID].cbDiscardCount] = cbDiscardCard
    local viewID = GameCommon:getViewIDByChairID(wChairID)
    local node = self:setDiscardCard(wChairID, GameCommon.player[wChairID].cbDiscardCount, GameCommon.player[wChairID].cbDiscardCard)
    local pos = cc.p(node:getPosition())
    node:stopAllActions()
    node:setPosition(pos)
    self:addLastCardFlagEft(node)
    self.lastDiscardNode = node
    self.lastDiscardChariID = wChairID
    
    --[[
    if viewID == 1 then
        node:setPosition(cc.p(node:getParent():convertToNodeSpace(self.locationPos)))
        node:runAction(cc.Sequence:create(cc.MoveTo:create(0.1,pos), cc.CallFunc:create(function(sender,event) 
            --最后一个出的牌上添加箭标
            self:addLastCardFlagEft(node)
        end)))
    else
        local i = #GameCommon.player[wChairID].cardNode
        local spos = GameCommon.player[wChairID].cardNode[i].pt
        local uiPanel_handCard = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_handCard%d",viewID))
        spos = cc.p(uiPanel_handCard:convertToWorldSpace(spos))
        node:setPosition(cc.p(node:getParent():convertToNodeSpace(spos)))
        node:runAction(cc.Sequence:create(cc.MoveTo:create(0.1,pos), cc.CallFunc:create(function(sender,event) 
            --最后一个出的牌上添加箭标
            self:addLastCardFlagEft(node)
        end)))
    end
    --]]
end

--添加多个弃牌
function TableLayer:setDiscardCard(wChairID, cbDiscardCount, bDiscardCard)
    GameCommon.player[wChairID].cbDiscardCount = cbDiscardCount
    GameCommon.player[wChairID].cbDiscardCard = bDiscardCard
    
    local viewID = GameCommon:getViewIDByChairID(wChairID)
    local uiPanel_discardCard = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_discardCard%d",viewID))
    uiPanel_discardCard:removeAllChildren()
    local anchorPoint = uiPanel_discardCard:getAnchorPoint()
    local size = uiPanel_discardCard:getContentSize()
    local cbDiscardCount = GameCommon.player[wChairID].cbDiscardCount
    local bDiscardCard = GameCommon.player[wChairID].cbDiscardCard
    local maxRow = 10
    local lastNode = nil
    if viewID == 1 then
        local cardScale = 0.8
        local cardWidth = 55 * cardScale
        local cardHeight = 79 * cardScale
        local beganX = cardWidth/2
        local beganY = cardHeight/2
        local stepX = cardWidth
        local stepY = cardHeight-12
        for i = 1, cbDiscardCount do
            local row = math.floor((i-1)/maxRow)
            local line = (i-1)%maxRow
            local card = GameCommon:getDiscardCardAndWeaveItemArray(bDiscardCard[i],viewID)
            lastNode = card
            uiPanel_discardCard:addChild(card)
            card:setScale(cardScale)
            card:setPosition(beganX + stepX*line ,beganY + stepY*row)
            card:setLocalZOrder(cbDiscardCount-i)   
--            ccs.ArmatureDataManager:getInstance():addArmatureFileInfo("majiang/animation/hudepaitishi/hudepaitishi.ExportJson")
--            local armature = ccs.Armature:create("hudepaitishi")
--            armature:getAnimation():playWithIndex(0,-1,1)
--            armature:setAnchorPoint(cc.p(0.5,0.5))            
--            armature:setVisible(true)  
--            card:addChild(armature) 
--            armature:setPosition(armature:getParent():getContentSize().width/2,armature:getParent():getContentSize().height/2)     
        end
        
    elseif viewID == 2 then
        local cardScale = 1.1
        local cardWidth = 54 * cardScale
        local cardHeight = 50 * cardScale
        local beganX = cardWidth/2
        local beganY = size.height-cardHeight/2
        local stepX = cardWidth
        local stepY = -(cardHeight-19)
        for i = 1, cbDiscardCount do
            local row = (i-1)%maxRow
            local line = math.floor((i-1)/maxRow)
            local card = GameCommon:getDiscardCardAndWeaveItemArray(bDiscardCard[i],viewID)
            lastNode = card
            card:setScale(cardScale)
            uiPanel_discardCard:addChild(card)
            card:setPosition(beganX + stepX*line ,beganY + stepY*row)   
        end
        
    elseif viewID == 3 then
        local cardScale = 0.8
        local cardWidth = 55 * cardScale
        local cardHeight = 79 * cardScale
        local beganX = size.width - cardWidth/2
        local beganY = size.height - cardHeight/2
        local stepX = -cardWidth
        local stepY = -cardHeight+12
        for i = 1, cbDiscardCount do
            local row = math.floor((i-1)/maxRow)
            local line = (i-1)%maxRow
            local card = GameCommon:getDiscardCardAndWeaveItemArray(bDiscardCard[i],viewID)
            lastNode = card
            card:setScale(cardScale)
            uiPanel_discardCard:addChild(card)
            card:setPosition(beganX + stepX*line ,beganY + stepY*row)
        end
        
    elseif viewID == 4 then
        local cardScale = 1.1
        local cardWidth = 54 * cardScale
        local cardHeight = 50 * cardScale
        local beganX = size.width - cardWidth/2
        local beganY = cardHeight/2
        local stepX = -cardWidth
        local stepY = cardHeight-19
        for i = 1, cbDiscardCount do
            local row = (i-1)%maxRow
            local line = math.floor((i-1)/maxRow)
            local card = GameCommon:getDiscardCardAndWeaveItemArray(bDiscardCard[i],viewID)
            lastNode = card
            card:setScale(cardScale)
            uiPanel_discardCard:addChild(card)
            card:setPosition(beganX + stepX*line ,beganY + stepY*row)
            card:setLocalZOrder(cbDiscardCount-i)  
        end         
    end
    return lastNode
end

-------------------------------------------------------手牌-----------------------------------------------------
--设置手牌
function TableLayer:setHandCard(wChairID,cbCardCount,cbCardData)
    if GameCommon.tableConfig.wKindID == 68 or  GameCommon.tableConfig.wKindID == 63 or  GameCommon.tableConfig.wKindID == 67  then
        local isAllHongZhong = true
        for i = 1, cbCardCount do
            if cbCardData[i] ~= 0x31 then
                isAllHongZhong = false
                break
            end
        end
        --红中麻将，红中放左边
        local isFound = true
        while isAllHongZhong == false and isFound == true do
            isFound = false
            for i = cbCardCount, 1, -1 do
                if cbCardData[i] == 0x31 then
                    table.insert(cbCardData,1,0x31)
                    isFound = true
                end
                break
            end
        end
    end
    GameCommon.player[wChairID].cbCardCount = cbCardCount
    GameCommon.player[wChairID].cbCardData = cbCardData
    GameCommon.player[wChairID].cardNode = {}
    for i = 1, GameCommon.player[wChairID].cbCardCount do
        local data = {}
        if GameCommon.player[wChairID].cbCardData[i] == nil then
            GameCommon.player[wChairID].cbCardData[i] = 0
        end
        data.data = GameCommon.player[wChairID].cbCardData[i]
        data.pt = cc.p(0,0)
        data.node = nil
        table.insert(GameCommon.player[wChairID].cardNode,#GameCommon.player[wChairID].cardNode+1,data)
    end
end

--------------------------
--des:结束的时候手牌数据
--time:2018-08-29 11:47:27
--------------------------
function TableLayer:setHandEndData( wChairID,cbCardCount,cbCardData, huCard,huChairID)
    if huCard then
        if wChairID == huChairID then
            for i,v in ipairs(cbCardData) do
                if v == 0 then
                    table.insert( cbCardData,i,huCard)
                    break
                elseif i == cbCardCount then
                    table.insert( cbCardData,i+1,huCard)
                    break
                end
            end
            for k,card in ipairs(cbCardData) do
                if card == huCard then
                    table.remove( cbCardData,k )
                    break
                end
            end
        end
    end
    GameCommon.player[wChairID].cbCardCount = cbCardCount
    GameCommon.player[wChairID].cbCardData = cbCardData
    GameCommon.player[wChairID].cardNode = {}
    for i = 1, GameCommon.player[wChairID].cbCardCount do
        local data = {}
        if GameCommon.player[wChairID].cbCardData[i] == nil then
            GameCommon.player[wChairID].cbCardData[i] = 0
        end
        data.data = GameCommon.player[wChairID].cbCardData[i]
        data.pt = cc.p(0,0)
        data.node = nil
        table.insert(GameCommon.player[wChairID].cardNode,#GameCommon.player[wChairID].cardNode+1,data)
    end
end

--添加任意手牌
function TableLayer:addOneHandCard(wChairID, cbCard, pos)
    local viewID = GameCommon:getViewIDByChairID(wChairID)
    local uiPanel_handCard = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_handCard%d",viewID))
    --插入手牌中
    if GameCommon.tableConfig.wKindID == 68 or  GameCommon.tableConfig.wKindID == 63 or  GameCommon.tableConfig.wKindID == 67 and cbCard == 0x31 then
        --红中麻将，红中放左边
        table.insert(GameCommon.player[wChairID].cbCardData,1,cbCard)
    else
        local isInsert = false
        for i = 1, GameCommon.player[wChairID].cbCardCount do
            if cbCard < GameCommon.player[wChairID].cbCardData[i] and((GameCommon.tableConfig.wKindID ~= 68 and GameCommon.tableConfig.wKindID ~= 63 and   GameCommon.tableConfig.wKindID ~= 67) or GameCommon.player[wChairID].cbCardData[i] ~= 0x31) then
                table.insert(GameCommon.player[wChairID].cbCardData,i,cbCard)
                isInsert = true
                break
            end
        end
        if isInsert == false then
            GameCommon.player[wChairID].cbCardData[GameCommon.player[wChairID].cbCardCount+1] = cbCard
        end 
    end
    GameCommon.player[wChairID].cbCardCount = GameCommon.player[wChairID].cbCardCount + 1    
    local size = uiPanel_handCard:getContentSize()
    local data = {}
    data.data = cbCard
    data.pt = cc.p(0,0)
    if viewID == 1 then
        local cardScale = 0.9
        local cardWidth = 80 * cardScale
        local cardHeight = 116 * cardScale
        data.pt = cc.p(size.width + cardWidth/2 + 20,size.height/2)
    elseif viewID == 2 then
        local cardScale = 0.6
        local cardWidth = 102* cardScale
        local cardHeight = 93 * cardScale
        data.pt = cc.p(size.width/2,-15)
    elseif viewID == 3 then
        local cardScale = 0.6
        local cardWidth = 81 * cardScale
        local cardHeight = 118 * cardScale
        data.pt = cc.p(-cardWidth/2-10,size.height/2)
    else
        local cardScale = 0.6
        local cardWidth = 102* cardScale
        local cardHeight = 93 * cardScale
        data.pt = cc.p(size.width/2,size.height + 15)
    end
    data.node = nil
    if GameCommon.tableConfig.wKindID == 68  and cbCard == 0x31 then
        table.insert(GameCommon.player[wChairID].cardNode,1,data)
    elseif GameCommon.tableConfig.wKindID == 63 and cbCard == 0x31 then
        table.insert(GameCommon.player[wChairID].cardNode,1,data)
    elseif GameCommon.tableConfig.wKindID == 67 and cbCard == 0x31 then
        table.insert(GameCommon.player[wChairID].cardNode,1,data)
    else
        local isInsert = false
        for key, var in pairs(GameCommon.player[wChairID].cardNode) do
            if cbCard < var.data and ((GameCommon.tableConfig.wKindID ~= 68 and GameCommon.tableConfig.wKindID ~= 63 and GameCommon.tableConfig.wKindID ~= 67 ) or var.data ~= 0x31) then
                table.insert(GameCommon.player[wChairID].cardNode,key,data) 
                isInsert = true
                break
        	end
        end
        if isInsert == false then
            table.insert(GameCommon.player[wChairID].cardNode,#GameCommon.player[wChairID].cardNode+1,data) 
        end  
    end
end

--删除手牌
function TableLayer:removeHandCard(wChairID, cbCardData)
    local pos = nil
    if wChairID == GameCommon:getRoleChairID() and self.copyHandCard ~= nil then
        self.copyHandCard.targetNode:setColor(cc.c3b(255,255,255))
        self.copyHandCard:removeFromParent()
        self.copyHandCard = nil
    end
    local viewID = GameCommon:getViewIDByChairID(wChairID)
    local uiPanel_handCard = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_handCard%d",viewID))
    local items = uiPanel_handCard:getChildren()
    local foundNode = nil
    --优先找出牌的待出牌的节点
    if viewID == 4 then
        if #items >= 1 and items[1].data == cbCardData then
            foundNode = items[1]
        end
    else
        if #items >= 1 and items[#items].data == cbCardData then
            foundNode = items[#items]
        end
    end
    --遍历查找
    if foundNode == nil then
        for key, var in pairs(items) do
        	if var.data == cbCardData then
        	   foundNode = var
        	   break
        	end
        end
    end
    --都没找到删除待出牌的节点
    if foundNode == nil and #items >= 1 then
        if viewID == 4 then
            foundNode = items[1]
        else
            foundNode = items[#items]
        end
    end
    if foundNode ~= nil then
        pos = cc.p(foundNode:getParent():convertToWorldSpace(cc.p(foundNode:getPosition())))
        foundNode:removeFromParent()
--    else
--        return nil
    end
    local isFound = false
    for i = 1, GameCommon.player[wChairID].cbCardCount do
        if GameCommon.player[wChairID].cbCardData[i] == cbCardData then
            table.remove(GameCommon.player[wChairID].cbCardData,i)
            isFound = true
            break
        end
    end
    if isFound == false then
        GameCommon.player[wChairID].cbCardData[GameCommon.player[wChairID].cbCardCount] = 0
    end
    
    local isFound = false
    if #GameCommon.player[wChairID].cardNode >= 1 and GameCommon.player[wChairID].cardNode[#GameCommon.player[wChairID].cardNode].data == cbCardData then
        table.remove(GameCommon.player[wChairID].cardNode,#GameCommon.player[wChairID].cardNode)
        isFound = true
    end
    if isFound == false then
        for key, var in pairs(GameCommon.player[wChairID].cardNode) do
        	if var.data == cbCardData then
               table.remove(GameCommon.player[wChairID].cardNode,key)
        	   isFound = true
        	   break
        	end
        end
    end
    if isFound == false and #GameCommon.player[wChairID].cardNode >= 1 then
        table.remove(GameCommon.player[wChairID].cardNode,#GameCommon.player[wChairID].cardNode)
    end
    GameCommon.player[wChairID].cbCardCount = GameCommon.player[wChairID].cbCardCount - 1
    return pos
end

--更新手牌
function TableLayer:showHandCard(wChairID,effectsType,isShowEndCard)
    local viewID = GameCommon:getViewIDByChairID(wChairID)
    local uiPanel_handCard = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_handCard%d",viewID))
    uiPanel_handCard:stopAllActions()
    uiPanel_handCard:removeAllChildren()
    local items = uiPanel_handCard:getChildren()
    local size = uiPanel_handCard:getContentSize()
    local visibleSize = cc.Director:getInstance():getVisibleSize()
    local anchorPoint = uiPanel_handCard:getAnchorPoint()
    local index = 0
    local time = 0.1
    if viewID == 1 then
        local cardScale = 1
        local cardWidth = 86 * cardScale
        local cardHeight = 126 * cardScale
        local step = cardWidth
        local uiPanel_copyHandCard = ccui.Helper:seekWidgetByName(self.root,"Panel_copyHandCard")
        uiPanel_copyHandCard:removeAllChildren()
        self.copyHandCard = nil
        local began = (size.width - GameCommon.player[wChairID].cbCardCount * cardWidth) + cardWidth/2
        if GameCommon.waitOutCardUser == wChairID then
            began = began + step
        end
        for i = 1, #GameCommon.player[wChairID].cardNode do
            local card = GameCommon:GetCardHand(GameCommon.player[wChairID].cardNode[i].data,viewID)
        --    local liang = ccui.ImageView:create("game/game_baotingkuang.png")
            local flagNode = ccui.ImageView:create('common/ting.png')
            if GameCommon.mBaoTingCard ~= nil and GameCommon.mBaoTingCard[1] ~= 0 then              
                for j = 1 , 14 do
                    if GameCommon.mBaoTingCard[j] == GameCommon.player[wChairID].cardNode[i].data then                     
                        card:addChild(flagNode)
                        flagNode:setName('tp_card_flag')
                        local size = card:getContentSize()
                        flagNode:setPosition(size.width * 0.2, size.height * 0.70)
                    --    card:addChild(liang)
                    --    liang:setPosition(liang:getParent():getContentSize().width/2,liang:getParent():getContentSize().height/2+5)
                        break
                    end 
                 end 
            end 
            uiPanel_handCard:addChild(card)
            card:setScale(cardScale)
            card.data = GameCommon.player[wChairID].cardNode[i].data
            GameCommon.player[wChairID].cardNode[i].node = card
            if effectsType == 0 then--发牌
                if i == GameCommon.player[wChairID].cbCardCount and GameCommon.waitOutCardUser == wChairID then
                    card:setPosition(size.width + cardWidth/2 + 20,size.height/2)
                else
                    card:setPosition(began + step*(i-1),size.height/2)
                end
                GameCommon.player[wChairID].cardNode[i].pt = cc.p(card:getPosition())
                
            elseif effectsType == 1 then--添加 
                -- print("麻将距离：",i,GameCommon.player[wChairID].cbCardData[i],isShowEndCard,
                -- GameCommon.player[wChairID].cardNode[i].pt.x,GameCommon.player[wChairID].cardNode[i].pt)
                local pos = GameCommon.player[wChairID].cardNode[i].pt
                card:setPosition(pos)
                if pos.x > size.width then
                    Common:playGetCardAnim(card)
                end
            elseif effectsType == 3 then    
                local pos = GameCommon.player[wChairID].cardNode[i].pt
                card:setPosition(pos)
            else--整理
                local original = GameCommon.player[wChairID].cardNode[i].pt
                card:setPosition(original)
                if i == GameCommon.player[wChairID].cbCardCount and GameCommon.waitOutCardUser == wChairID then
                    GameCommon.player[wChairID].cardNode[i].pt = cc.p(size.width + cardWidth/2 + 20,size.height/2)
                else
                    GameCommon.player[wChairID].cardNode[i].pt = cc.p(began + step*(i-1),size.height/2)
                end
                if original.x > size.width and i ~= GameCommon.player[wChairID].cbCardCount then
                    card:runAction(cc.Sequence:create(
                    cc.MoveTo:create(0.05,cc.p(original.x,original.y+cardHeight)),
                    cc.MoveTo:create(0.05,cc.p(GameCommon.player[wChairID].cardNode[i].pt.x,original.y+cardHeight)),
                    cc.MoveTo:create(0.05,GameCommon.player[wChairID].cardNode[i].pt)
                    ))
                else
                    card:runAction(cc.MoveTo:create(0.2,GameCommon.player[wChairID].cardNode[i].pt))
                end
            end
            
            local uiImage_line = ccui.Helper:seekWidgetByName(self.root,"Image_line")
            uiImage_line:setVisible(false)
            local lineY = uiImage_line:getPositionY()
            card:setTouchEnabled(true)
            card:addTouchEventListener(function(sender,event) 
                if event == ccui.TouchEventType.began then   
                    uiImage_line:setVisible(false)                
                    if GameCommon.mBaoTingCard ~= nil and GameCommon.mBaoTingCard[1] ~= 0 then  
                        for i = 1, 14 do 
                            if card.data  ~= nil and card.data ~= 0x31 and card.data == GameCommon.mBaoTingCard[i] and GameCommon.mBTHuCard ~= nil then 
                                --NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_C_AloneBaoTing,"b",card.data)
                                self:huCardShow(0,i)
                            end 
                        end
                    end    
                    if self.copyHandCard ~= nil then
                        self.copyHandCard.targetNode:setColor(cc.c3b(255,255,255))
                        self.copyHandCard = nil
                    end
                    uiPanel_copyHandCard:removeAllChildren()
                    self.copyHandCard = nil
                elseif event == ccui.TouchEventType.moved then                
                    local pos = cc.pSub(self.locationBeganPos,self.locationPos)
                    if self.copyHandCard == nil and (math.abs(pos.x) > 30 or math.abs(pos.y) > 30) then
                        uiImage_line:setVisible(true)
                        self.copyHandCard = card:clone()
                        self.copyHandCard.targetNode = card
                        card:setColor(cc.c3b(170,170,170))
                        uiPanel_copyHandCard:addChild(self.copyHandCard)
                        self.copyHandCard:setPosition(self.locationPos)
                    elseif self.copyHandCard ~= nil then
                        self.copyHandCard:setPosition(self.locationPos)
                    end 
                else                    
                    if self.copyHandCard ~= nil then                       
                        uiPanel_copyHandCard:removeAllChildren()
                        self.copyHandCard = nil
                        card:setColor(cc.c3b(255,255,255))
                        if GameCommon.waitOutCardUser == GameCommon:getRoleChairID() and self.locationPos.y > lineY then
                            self.outData = {wChairID = wChairID, cbCardData = card.data, cardNode = card}
                            EventMgr:dispatch(EventType.EVENT_TYPE_OPERATIONAL_OUT_CARD, self.outData)
                            return
                        end
                    end
                    if self.locationPos.y <= lineY then
                        if GameCommon.waitOutCardUser == GameCommon:getRoleChairID() and card:getPositionY() > card:getParent():getContentSize().height/2 then
                            self.outData = {wChairID = wChairID, cbCardData = card.data, cardNode = card}
                            EventMgr:dispatch(EventType.EVENT_TYPE_OPERATIONAL_OUT_CARD, self.outData)
                            return
                        else
                            local items = uiPanel_handCard:getChildren()
                            for key, var in pairs(items) do
                                var:stopAllActions()
                                var:runAction(cc.MoveTo:create(0.1,GameCommon.player[wChairID].cardNode[key].pt))
                            end
                            card:stopAllActions()
                            card:runAction(cc.MoveTo:create(0.1,cc.p(GameCommon.player[wChairID].cardNode[i].pt.x,card:getParent():getContentSize().height/2+20)))
                            -- if GameCommon.mBaoTingCard ~= nil and GameCommon.mBaoTingCard[1] ~= 0 then  
                            --     for i = 1, 14 do 
                            --         if card.data  ~= nil and card.data ~= 0x31 and card.data == GameCommon.mBaoTingCard[i] and GameCommon.mBTHuCard ~= nil then 
                            --             --NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_C_AloneBaoTing,"b",card.data)
                            --             self:huCardShow(0,i)
                            --         end 
                            --     end
                            -- end    
                        end
                    end
                end
            end)
        end
                
    elseif viewID == 2 then
        local cardScale = 1
        local cardWidth = 24 * cardScale
        local cardHeight = 52 * cardScale
        local step = -(cardHeight - 20)
        local began = -(GameCommon.player[wChairID].cbCardCount-1) * step + cardHeight - cardHeight/2 + 20
        if GameCommon.waitOutCardUser == wChairID then
            began = began + step
        end
        for i = 1, #GameCommon.player[wChairID].cardNode do
            local card = GameCommon:GetCardHand(GameCommon.player[wChairID].cardNode[i].data,viewID)
            uiPanel_handCard:addChild(card)
            card:setScale(cardScale)
            card.data = GameCommon.player[wChairID].cardNode[i].data
            GameCommon.player[wChairID].cardNode[i].node = card
            if effectsType == 0 then--发牌
                if i == GameCommon.player[wChairID].cbCardCount and GameCommon.waitOutCardUser == wChairID then
                    card:setPosition(size.width/2,-15)
                else
                    card:setPosition(size.width/2,began + step*(i-1))
                end
                GameCommon.player[wChairID].cardNode[i].pt = cc.p(card:getPosition())
            
            elseif effectsType == 1 then--添加
                local pos = GameCommon.player[wChairID].cardNode[i].pt
                card:setPosition(pos)
                if pos.y < 0 then
                    card:setLocalZOrder(99)
                    Common:playGetCardAnim(card)
                end
                
            else--整理
                local original = GameCommon.player[wChairID].cardNode[i].pt
                card:setPosition(original)
                if i == GameCommon.player[wChairID].cbCardCount and GameCommon.waitOutCardUser == wChairID then
                    GameCommon.player[wChairID].cardNode[i].pt = cc.p(size.width/2,-15)
                else
                    GameCommon.player[wChairID].cardNode[i].pt = cc.p(size.width/2,began + step*(i-1))
                end
                if original.y < 0 and i ~= GameCommon.player[wChairID].cbCardCount then
                    card:runAction(cc.Sequence:create(
                        cc.MoveTo:create(0.05,cc.p(original.x + cardWidth,original.y)),
                        cc.MoveTo:create(0.05,cc.p(original.x + cardWidth,GameCommon.player[wChairID].cardNode[i].pt.y)),
                        cc.MoveTo:create(0.05,GameCommon.player[wChairID].cardNode[i].pt)
                    ))
                else
                    card:runAction(cc.MoveTo:create(0.2,GameCommon.player[wChairID].cardNode[i].pt))
                end               
            end
        end
    elseif viewID == 3 then
        local cardScale = 0.9
        local cardWidth = 52 * cardScale
        local cardHeight = 82 * cardScale
        local step = -cardWidth
        local began = -(GameCommon.player[wChairID].cbCardCount-1) * step + cardWidth - cardWidth/2 
        if GameCommon.waitOutCardUser == wChairID then
            began = began + step
        end
        for i = 1, #GameCommon.player[wChairID].cardNode do
            local card = GameCommon:GetCardHand(GameCommon.player[wChairID].cardNode[i].data,viewID)
            uiPanel_handCard:addChild(card)
            card:setScale(cardScale)
            card.data = GameCommon.player[wChairID].cardNode[i].data
            GameCommon.player[wChairID].cardNode[i].node = card
            if effectsType == 0 then--发牌
                if i == GameCommon.player[wChairID].cbCardCount and GameCommon.waitOutCardUser == wChairID then
                    card:setPosition(-cardWidth/2-10,size.height/2)
                    print('-------->>>>set',GameCommon.waitOutCardUser,wChairID)
                else
                    card:setPosition(began + step*(i-1),size.height/2)
                end
                GameCommon.player[wChairID].cardNode[i].pt = cc.p(card:getPosition())
                
            elseif effectsType == 1 then--添加
                local pos = GameCommon.player[wChairID].cardNode[i].pt
                card:setPosition(pos)
                if pos.x < 0 then
                    Common:playGetCardAnim(card)
                end
                
            else--整理
                local original = GameCommon.player[wChairID].cardNode[i].pt
                card:setPosition(original)
                if i == GameCommon.player[wChairID].cbCardCount and GameCommon.waitOutCardUser == wChairID then
                    GameCommon.player[wChairID].cardNode[i].pt = cc.p(-cardWidth/2-10,size.height/2)
                else
                    GameCommon.player[wChairID].cardNode[i].pt = cc.p(began + step*(i-1),size.height/2)
                end
                if original.x < 0 and i ~= GameCommon.player[wChairID].cbCardCount then
                    card:runAction(cc.Sequence:create(
                        cc.MoveTo:create(0.05,cc.p(original.x,original.y-cardHeight)),
                        cc.MoveTo:create(0.05,cc.p(GameCommon.player[wChairID].cardNode[i].pt.x,original.y-cardHeight)),
                        cc.MoveTo:create(0.05,GameCommon.player[wChairID].cardNode[i].pt)
                    ))
                else
                    card:runAction(cc.MoveTo:create(0.2,GameCommon.player[wChairID].cardNode[i].pt))
                end
            end
        end
        
    elseif viewID == 4 then
        local cardScale = 1
        local cardWidth = 24 * cardScale
        local cardHeight = 52 * cardScale
        local step = cardHeight - 20
        local began = size.height - (GameCommon.player[wChairID].cbCardCount-1) * step - cardHeight + cardHeight/2 - 20
        if GameCommon.waitOutCardUser == wChairID then
            began = began + step
        end
        for i = 1, #GameCommon.player[wChairID].cardNode do
            local card = GameCommon:GetCardHand(GameCommon.player[wChairID].cardNode[i].data,viewID)
            uiPanel_handCard:addChild(card)
--            card:setColor(cc.c3b(i*(255/#GameCommon.player[wChairID].cardNode),0,0))
            card:setLocalZOrder(GameCommon.player[wChairID].cbCardCount - i)
            card:setScale(cardScale)
            card.data = GameCommon.player[wChairID].cardNode[i].data
            GameCommon.player[wChairID].cardNode[i].node = card
            if effectsType == 0 then--发牌
                if i == GameCommon.player[wChairID].cbCardCount and GameCommon.waitOutCardUser == wChairID then
                    card:setPosition(size.width/2,size.height + 15)
                else
                    card:setPosition(size.width/2,began + step*(i-1))
                end
                GameCommon.player[wChairID].cardNode[i].pt = cc.p(card:getPosition())
            
            elseif effectsType == 1 then--添加
                local pos = GameCommon.player[wChairID].cardNode[i].pt
                card:setPosition(pos)
                if pos.y > size.height then
                    card:setLocalZOrder(-1)
                    Common:playGetCardAnim(card)
                end

            else--整理
                local original = GameCommon.player[wChairID].cardNode[i].pt
                card:setPosition(original)
                if i == GameCommon.player[wChairID].cbCardCount and GameCommon.waitOutCardUser == wChairID then
                    GameCommon.player[wChairID].cardNode[i].pt = cc.p(size.width/2,size.height + 15)
                else
                    GameCommon.player[wChairID].cardNode[i].pt = cc.p(size.width/2,began + step*(i-1))
                end
                if original.y > size.height and i ~= GameCommon.player[wChairID].cbCardCount then
                    card:runAction(cc.Sequence:create(
                        cc.MoveTo:create(0.05,cc.p(original.x-cardWidth,original.y)),
                        cc.MoveTo:create(0.05,cc.p(original.x-cardWidth,GameCommon.player[wChairID].cardNode[i].pt.y)),
                        cc.MoveTo:create(0.05,GameCommon.player[wChairID].cardNode[i].pt)
                    ))
                else
                    card:runAction(cc.MoveTo:create(0.2,GameCommon.player[wChairID].cardNode[i].pt))
                end
            end
        end
    end
end

function TableLayer:initUI()
    local visibleSize = cc.Director:getInstance():getVisibleSize()
    require("common.Common"):playEffect("game/pipeidonghua.mp3")
    local wKindID = GameCommon.tableConfig.wKindID
    --背景层
    local uiImage_watermark = ccui.Helper:seekWidgetByName(self.root,"Image_watermark")
    uiImage_watermark:loadTexture(StaticData.Games[wKindID].icon)
    uiImage_watermark:ignoreContentAdaptWithSize(true)
    local uiText_desc = ccui.Helper:seekWidgetByName(self.root,"Text_desc")
    uiText_desc:setString("")
    local uiText_time = ccui.Helper:seekWidgetByName(self.root,"Text_time")
    uiText_time:runAction(cc.RepeatForever:create(cc.Sequence:create(cc.CallFunc:create(function(sender,event) 
        local date = os.date("*t",os.time())
        uiText_time:setString(string.format("%d-%02d-%02d %02d:%02d:%02d",date.year,date.month,date.day,date.hour,date.min,date.sec))
    end),cc.DelayTime:create(1))))
    local uiImage_direction = ccui.Helper:seekWidgetByName(self.root,"Image_direction")
    uiImage_direction:setVisible(false)
    --卡牌层
    local uiImage_line = ccui.Helper:seekWidgetByName(self.root,"Image_line")
    uiImage_line:setVisible(false)
    local uiPanel_refreshHandCard = ccui.Helper:seekWidgetByName(self.root,"Panel_refreshHandCard")
    uiPanel_refreshHandCard:setTouchEnabled(false)
    uiPanel_refreshHandCard:addTouchEventListener(function(sender,event) 
        if event == ccui.TouchEventType.ended then
            -- if type(self.cotrolCardTPData) == 'table' then
            --     print("---------------报听触发3:") 
            --     self:setOutCardTPTips(self.normolTPData)
            -- end 
            self:showHandCard(GameCommon:getRoleChairID(),2)
        end
    end)
    --动画层

    local uiPanel_operation = ccui.Helper:seekWidgetByName(self.root,"Panel_operation")
    uiPanel_operation:removeAllChildren()
    uiPanel_operation:setVisible(false)
    
    --用户层
    for i = 1, 4 do
        local uiPanel_player = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_player%d",i))
        uiPanel_player:setVisible(false)
        local uiImage_avatar = ccui.Helper:seekWidgetByName(uiPanel_player,"Image_avatar")
        uiImage_avatar:loadTexture("common/hall_avatar.png")
        uiImage_avatar:addTouchEventListener(function(sender,event) 
            if event == ccui.TouchEventType.ended then
                for key, var in pairs(GameCommon.player) do
                    if GameCommon:getViewIDByChairID(var.wChairID) == i then
                        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER,NetMsgId.REQ_GR_USER_PLAYER_INFO,"d",var.dwUserID)
                        break
                    end
                end
            end
        end)     
        
        local uiText_Houdplate = ccui.Helper:seekWidgetByName(uiPanel_player,"Text_Houdplate")
        uiText_Houdplate:setVisible(false)      
        
        local uiImage_avatarFrame = ccui.Helper:seekWidgetByName(uiPanel_player,"Image_avatarFrame")
        local uiImage_laba = ccui.Helper:seekWidgetByName(uiPanel_player,"Image_laba")
        uiImage_laba:setVisible(false)
        local uiImage_banker = ccui.Helper:seekWidgetByName(uiPanel_player,"Image_banker")
        uiImage_banker:setVisible(false)
        local uiText_name = ccui.Helper:seekWidgetByName(uiPanel_player,"Text_name")
        uiText_name:setString("")
        local uiText_huXi = ccui.Helper:seekWidgetByName(uiPanel_player,"Text_huXi")
        uiText_huXi:setString("")
        local uiText_score = ccui.Helper:seekWidgetByName(uiPanel_player,"Text_score")
        uiText_score:setString("")
        local uiImage_ready = ccui.Helper:seekWidgetByName(uiPanel_player,"Image_ready")
        uiImage_ready:setVisible(false)
        local uiImage_chat = ccui.Helper:seekWidgetByName(uiPanel_player,"Image_chat")
        uiImage_chat:setVisible(false)
    end
    --飘分
    local uiPanel_piaoFen = ccui.Helper:seekWidgetByName(self.root,"Panel_piaoFen")
    uiPanel_piaoFen:setVisible(false)
    local uiListView_piaoFen = ccui.Helper:seekWidgetByName(self.root,"ListView_piaoFen")
    local items = uiListView_piaoFen:getItems()
    for key, var in pairs(items) do
        Common:addTouchEventListener(var,function() 
            if key == 1 then
                NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_C_PiaoFen,"b",1)
            elseif key == 2 then
                NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_C_PiaoFen,"b",2)
            elseif key == 3 then
                NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_C_PiaoFen,"b",3)
            else
                NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_C_PiaoFen,"b",0)
            end
        end)
    end
    
    
    --买飘
    local uiPanel_maipiao = ccui.Helper:seekWidgetByName(self.root,"Panel_maipiao")
    uiPanel_maipiao:setVisible(false)
    local uiListView_maipiao = ccui.Helper:seekWidgetByName(self.root,"ListView_maipiao")    
    local m_Maipiao = {}
    m_Maipiao.mai = 0
    m_Maipiao.piao = 0
    
    local uiButton_Buy = ccui.Helper:seekWidgetByName(self.root,"Button_Buy")          --买 
    local uiButton_Not = ccui.Helper:seekWidgetByName(self.root,"Button_Not")          --不买
    local uiButton_confirm = ccui.Helper:seekWidgetByName(self.root,"Button_confirm")  --确认
    local uiButton_cancel1 = ccui.Helper:seekWidgetByName(self.root,"Button_cancel1")    --取消
    
    local uiButton_piao1 = ccui.Helper:seekWidgetByName(self.root,"Button_piao1")        --飘一分 
    local uiButton_piao2 = ccui.Helper:seekWidgetByName(self.root,"Button_piao2")        --飘两分
    local uiButton_piao3 = ccui.Helper:seekWidgetByName(self.root,"Button_piao3")        --飘三分 
    local uiButton_piao0 = ccui.Helper:seekWidgetByName(self.root,"Button_piao0")        --不飘
    

    local uiImage_piao1 = ccui.Helper:seekWidgetByName(self.root,"Image_piao1")        --飘一分 
    local uiImage_piao2 = ccui.Helper:seekWidgetByName(self.root,"Image_piao2")        --飘两分
    local uiImage_piao3 = ccui.Helper:seekWidgetByName(self.root,"Image_piao3")        --飘三分 
    local uiImage_piao0 = ccui.Helper:seekWidgetByName(self.root,"Image_piao0")        --不飘
    local uiImage_Buy = ccui.Helper:seekWidgetByName(self.root,"Image_Buy")          --买 
    local uiImage_Not = ccui.Helper:seekWidgetByName(self.root,"Image_Not")          --不买
    uiImage_piao1:setVisible(false)
    uiImage_piao2:setVisible(false)
    uiImage_piao3:setVisible(false)
    uiImage_piao0:setVisible(false)
    uiImage_Buy:setVisible(false)
    uiImage_Not:setVisible(false)
    local function PiaoFen(type)
        if type == 1 then 
            uiImage_piao1:setVisible(true)
            uiImage_piao2:setVisible(false)
            uiImage_piao3:setVisible(false)
            uiImage_piao0:setVisible(false)  
            m_Maipiao.piao = 1
        elseif type == 2 then
            uiImage_piao1:setVisible(false)
            uiImage_piao2:setVisible(true)
            uiImage_piao3:setVisible(false)
            uiImage_piao0:setVisible(false)  
            m_Maipiao.piao = 2
        elseif type == 3 then
            uiImage_piao1:setVisible(false)
            uiImage_piao2:setVisible(false)
            uiImage_piao3:setVisible(true)
            uiImage_piao0:setVisible(false)  
            m_Maipiao.piao = 3
        elseif type == 0 then
            uiImage_piao1:setVisible(false)
            uiImage_piao2:setVisible(false)
            uiImage_piao3:setVisible(false)
            uiImage_piao0:setVisible(true)
            m_Maipiao.piao = 0
        end     
    end  
    Common:addTouchEventListener(uiButton_piao1,function() PiaoFen(1)end)
    Common:addTouchEventListener(uiButton_piao2,function() PiaoFen(2)end)
    Common:addTouchEventListener(uiButton_piao3,function() PiaoFen(3)end)
    Common:addTouchEventListener(uiButton_piao0,function() PiaoFen(0)end)
    
    local function BugOrNot(type)
        if type == 1 then 
            uiImage_Buy:setVisible(true)
            uiImage_Not:setVisible(false)  
            m_Maipiao.mai = 1
        elseif type == 0 then
            uiImage_Buy:setVisible(false)
            uiImage_Not:setVisible(true)
            m_Maipiao.mai = 0
        elseif type == 100 then 
            NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_C_MaiFen,"bb",m_Maipiao.piao,m_Maipiao.mai)
        elseif type == -1 then 
            NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_C_MaiFen,"bb",0,0)
        end     
    end  
    Common:addTouchEventListener(uiButton_Buy,function() BugOrNot(1)end)
    Common:addTouchEventListener(uiButton_Not,function() BugOrNot(0)end)
    Common:addTouchEventListener(uiButton_confirm,function() BugOrNot(100)end)
    Common:addTouchEventListener(uiButton_cancel1,function() BugOrNot(-1)end)
    
    
    --UI层
    local uiButton_menu = ccui.Helper:seekWidgetByName(self.root,"Button_menu")
    local uiPanel_function = ccui.Helper:seekWidgetByName(self.root,"Panel_function")
    uiPanel_function:setEnabled(false)
    Common:addTouchEventListener(uiButton_menu,function() 
        uiPanel_function:stopAllActions()
        uiPanel_function:runAction(cc.Sequence:create(cc.MoveTo:create(0.2,cc.p(-99,0)),cc.CallFunc:create(function(sender,event) 
            uiPanel_function:setEnabled(true)
        end)))
        uiButton_menu:stopAllActions()
        uiButton_menu:runAction(cc.ScaleTo:create(0.2,0))
    end)
    uiPanel_function:addTouchEventListener(function(sender,event)
        if event == ccui.TouchEventType.ended then
            uiPanel_function:stopAllActions()
            uiPanel_function:runAction(cc.Sequence:create(cc.CallFunc:create(function(sender,event) 
                uiPanel_function:setEnabled(false)
            end),cc.MoveTo:create(0.2,cc.p(0,0))))
            uiButton_menu:stopAllActions()
            uiButton_menu:runAction(cc.ScaleTo:create(0.2,1))
        end
    end)  
    local uiPanel_bg = ccui.Helper:seekWidgetByName(self.root,"Panel_bg")
    Common:addTouchEventListener(ccui.Helper:seekWidgetByName(self.root,"Button_skin"),function() 
        local UserDefault_MaJiangpaizhuo = cc.UserDefault:getInstance():getIntegerForKey(Default.UserDefault_MaJiangpaizhuo,0)
        UserDefault_MaJiangpaizhuo = UserDefault_MaJiangpaizhuo + 1
        if UserDefault_MaJiangpaizhuo < 0 or UserDefault_MaJiangpaizhuo > 2 then
            UserDefault_MaJiangpaizhuo = 0
        end
        cc.UserDefault:getInstance():setIntegerForKey(Default.UserDefault_MaJiangpaizhuo,UserDefault_MaJiangpaizhuo)
        uiPanel_bg:removeAllChildren()
        uiPanel_bg:addChild(ccui.ImageView:create(string.format("majiang/table/game_table_bg%d.jpg",UserDefault_MaJiangpaizhuo)))
    end)        
    local UserDefault_MaJiangpaizhuo = cc.UserDefault:getInstance():getIntegerForKey(Default.UserDefault_MaJiangpaizhuo,0)
    if UserDefault_MaJiangpaizhuo < 0 or UserDefault_MaJiangpaizhuo > 2 then
        UserDefault_MaJiangpaizhuo = 0
        cc.UserDefault:getInstance():setIntegerForKey(Default.UserDefault_MaJiangpaizhuo,UserDefault_MaJiangpaizhuo)
    end
    if UserDefault_MaJiangpaizhuo ~= 0 then
        uiPanel_bg:removeAllChildren()
        uiPanel_bg:addChild(ccui.ImageView:create(string.format("majiang/table/game_table_bg%d.jpg",UserDefault_MaJiangpaizhuo)))
    end
    
    Common:addTouchEventListener(ccui.Helper:seekWidgetByName(self.root,"Button_font"),function() 
        local UserDefault_MaJiangCard = nil 
        if CHANNEL_ID == 20 or CHANNEL_ID == 21 then 
            UserDefault_MaJiangCard = cc.UserDefault:getInstance():getIntegerForKey(Default.UserDefault_MaJiangCard,3)
        else
            UserDefault_MaJiangCard = cc.UserDefault:getInstance():getIntegerForKey(Default.UserDefault_MaJiangCard,0)
        end 
        UserDefault_MaJiangCard = UserDefault_MaJiangCard + 1
        if UserDefault_MaJiangCard < 0 or UserDefault_MaJiangCard > 3 then
            UserDefault_MaJiangCard = 0
        end
        cc.UserDefault:getInstance():setIntegerForKey(Default.UserDefault_MaJiangCard,UserDefault_MaJiangCard)

        --牌背字体
        if GameCommon.gameConfig.bPlayerCount ~= nil then 
            for i = 0 , GameCommon.gameConfig.bPlayerCount-1 do
                local wChairID = i
                if GameCommon.player ~= nil and GameCommon.player[wChairID] ~= nil then
                    self:showHandCard(wChairID,i)
                    self:setWeaveItemArray(wChairID, GameCommon.player[wChairID].bWeaveItemCount, GameCommon.player[wChairID].WeaveItemArray)
                    self:setDiscardCard(wChairID, GameCommon.player[wChairID].cbDiscardCount, GameCommon.player[wChairID].cbDiscardCard)
                end
            end
        end 
    end)
    
    
    local uiPanel_night = ccui.Helper:seekWidgetByName(self.root,"Panel_night")
    local UserDefault_MaJiangliangdu = cc.UserDefault:getInstance():getIntegerForKey(Default.UserDefault_MaJiangliangdu,0)
    if UserDefault_MaJiangliangdu == 0 then
        uiPanel_night:setVisible(false)
    else
        uiPanel_night:setVisible(true)
    end
    Common:addTouchEventListener(ccui.Helper:seekWidgetByName(self.root,"Button_settings"),function() 
        require("game.majiang.SettingsLayer"):create()
    end)
    local uiButton_expression = ccui.Helper:seekWidgetByName(self.root,"Button_expression")
    uiButton_expression:setPressedActionEnabled(true)
    local function onEventExpression(sender,event)
        if event == ccui.TouchEventType.ended then
            Common:palyButton()
            require("common.NewChatLayer"):create(GameCommon.tableConfig.wKindID,function(index) 
                NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_GF_USER_EXPRESSION,"ww",index,GameCommon:getRoleChairID())
            end, 
            function(index,contents)
                NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER,NetMsgId.REQ_GR_USER_SEND_CHAT,"dwbnsdns",
                    GameCommon:getRoleChairID(),index,GameCommon:getUserInfo(GameCommon:getRoleChairID()).cbSex,32,"",string.len(contents),string.len(contents),contents)
            end)
        end
    end
    uiButton_expression:addTouchEventListener(onEventExpression)
    local uiButton_ready = ccui.Helper:seekWidgetByName(self.root,"Button_ready")
    Common:addTouchEventListener(uiButton_ready,function() 
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER,NetMsgId.REQ_GR_USER_READY,"o",false)
    end) 
    local uiButton_Invitation = ccui.Helper:seekWidgetByName(self.root,"Button_Invitation")
    Common:addTouchEventListener(uiButton_Invitation,function() 
        local currentPlayerCount = 0
        for key, var in pairs(GameCommon.player) do
            currentPlayerCount = currentPlayerCount + 1
        end
        local player = "("
        for key, var in pairs(GameCommon.player) do
            if key == 0 then
                player = player..var.szNickName
            else
                player = player.."、"..var.szNickName
            end
        end
        player = player..")"
        local data = clone(UserData.Share.tableShareParameter[3])
        data.dwClubID = GameCommon.tableConfig.dwClubID
        data.szShareTitle = string.format(data.szShareTitle,StaticData.Games[GameCommon.tableConfig.wKindID].name,
            GameCommon.tableConfig.wTbaleID,GameCommon.tableConfig.wTableNumber,
            GameCommon.gameConfig.bPlayerCount,GameCommon.gameConfig.bPlayerCount-currentPlayerCount)..player
        data.szShareContent = GameDesc:getGameDesc(GameCommon.tableConfig.wKindID,GameCommon.gameConfig,GameCommon.tableConfig).." (点击加入游戏)"
        data.szShareUrl = string.format(data.szShareUrl,GameCommon.tableConfig.szGameID)
        if GameCommon.tableConfig.nTableType ~= TableType_ClubRoom then
            data.cbTargetType = Bit:_xor(data.cbTargetType,0x20)
        end
        require("app.MyApp"):create(data, handler(self, self.pleaseOnlinePlayer)):createView("ShareLayer")
    end)
    local uiButton_disbanded = ccui.Helper:seekWidgetByName(self.root,"Button_disbanded")
    Common:addTouchEventListener(uiButton_disbanded,function() 
        require("common.MsgBoxLayer"):create(1,nil,"是否确定解散房间？",function()
            NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER,NetMsgId.REQ_GR_DISMISS_TABLE,"")
        end)
    end)
    local uiButton_cancel = ccui.Helper:seekWidgetByName(self.root,"Button_cancel")  --取消按钮
    Common:addTouchEventListener(uiButton_cancel,function() 
        require("common.SceneMgr"):switchScene(require("app.MyApp"):create():createView("HallLayer"),SCENE_HALL) 
    end)  
    local uiButton_out = ccui.Helper:seekWidgetByName(self.root,"Button_out")
    Common:addTouchEventListener(uiButton_out,function() 
        require("common.MsgBoxLayer"):create(1,nil,"您确定离开房间?\n房主离开意味着房间被解散",function()
            NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER,NetMsgId.REQ_GR_LEAVE_TABLE_USER,"")
        end)
    end)  
        
    local uiButton_SignOut = ccui.Helper:seekWidgetByName(self.root,"Button_SignOut")
    Common:addTouchEventListener(uiButton_SignOut,function() 
        require("common.MsgBoxLayer"):create(1,nil,"您确定返回大厅?",function()
            require("common.SceneMgr"):switchScene(require("app.MyApp"):create():createView("HallLayer"),SCENE_HALL) 
        end)
    end) 
    if CHANNEL_ID == 6 or  CHANNEL_ID  == 7  or CHANNEL_ID == 8 or  CHANNEL_ID  == 9  then
    else
        uiButton_SignOut:setVisible(false)
        uiButton_out:setPositionX(visibleSize.width*0.36)       
        uiButton_Invitation:setPositionX(visibleSize.width*0.64)  
    end 
    
    local uiButton_position = ccui.Helper:seekWidgetByName(self.root,"Button_position")   -- 定位
    Common:addTouchEventListener(uiButton_position,function() 
        require("common.PositionLayer"):create(GameCommon.tableConfig.wKindID)
        --require("game.yongzhou.PositionLayer"):create(GameCommon.tableConfig.wKindID)
    end)
    local uiPanel_playerInfoBg = ccui.Helper:seekWidgetByName(self.root,"Panel_playerInfoBg")
    if GameCommon.tableConfig.wCurrentNumber == 0 and  GameCommon.tableConfig.nTableType > TableType_GoldRoom  then
    if CHANNEL_ID ~= 0 and CHANNEL_ID ~= 1 then
        uiPanel_playerInfoBg:setVisible(true) 
    else 
        uiPanel_playerInfoBg:setVisible(false)
    end          
    end
    local uiButton_return = ccui.Helper:seekWidgetByName(self.root,"Button_return")
    Common:addTouchEventListener(uiButton_return,function() 
        require("common.MsgBoxLayer"):create(1,nil,"您确定返回大厅?",function()
            require("common.SceneMgr"):switchScene(require("app.MyApp"):create():createView("HallLayer"),SCENE_HALL) 
        end)
    end)
    --结算层
    local uiPanel_end = ccui.Helper:seekWidgetByName(self.root,"Panel_end")
    uiPanel_end:setVisible(false)
    --胡牌提示 
    local uiPanel_hucardbg = ccui.Helper:seekWidgetByName(self.root,"Panel_hucardbg")    
    uiPanel_hucardbg:setVisible(false)  
    --灯光层
    local uiButton_voice = ccui.Helper:seekWidgetByName(self.root,"Button_voice")
    
    local uiButton_chakan = ccui.Helper:seekWidgetByName(self.root,"Button_chakan")
    uiButton_chakan:setVisible(false)  
    Common:addTouchEventListener(uiButton_chakan,function() 
        if  GameCommon.mBTHuCard~= {} and GameCommon.mBTHuCard[1] ~={} and GameCommon.mBTHuCard[1][1] ~=nil then          -- GameCommon.mBaoTingCard[i] = pBuffer.cbGangCard[i]    GameCommon.mHuCard~= {} and GameCommon.mHuCard [1] ~=nil
            self:huCardShow(0)
        else
            require("common.MsgBoxLayer"):create(0,nil,"您还未报听!!!")             
        end
    end)
        
    local uiText_title = ccui.Helper:seekWidgetByName(self.root,"Text_title")    
    if GameCommon.tableConfig.nTableType > TableType_GoldRoom then
        self:addVoice()
        local uiListView_function = ccui.Helper:seekWidgetByName(self.root,"ListView_function") 
        if  StaticData.Hide[CHANNEL_ID].btn10 == 0 then 
            uiListView_function:removeItem(uiListView_function:getIndex(uiButton_position))
            uiPanel_playerInfoBg:setVisible(false) 
        end 
        uiButton_cancel:setVisible(false)
        if GameCommon.gameState == GameCommon.GameState_Start  then
            local uiPanel_ready = ccui.Helper:seekWidgetByName(self.root,"Panel_ready")
            uiPanel_ready:setVisible(false)
            if StaticData.Hide[CHANNEL_ID].btn4 ~= 1 then
                uiButton_Invitation:setVisible(false)
                uiButton_out:setVisible(false)
            else
                uiButton_Invitation:setVisible(true)
                uiButton_out:setVisible(true)
            end

        elseif GameCommon.tableConfig.wCurrentNumber > 0 then
            -- local uiPanel_ready = ccui.Helper:seekWidgetByName(self.root,"Panel_ready")
            -- uiPanel_ready:setVisible(false)
            uiButton_Invitation:setVisible(false)
            uiButton_out:setVisible(false)
            uiButton_SignOut:setVisible(false)
        end 
        if StaticData.Hide[CHANNEL_ID].btn4 ~= 1 then
            uiButton_Invitation:setVisible(false)
            uiButton_out:setPositionX(visibleSize.width*0.5)   
        -- else
        --     uiButton_Invitation:setVisible(true)
        end
        uiText_title:setString(string.format("%s 房间号:%d 局数:%d/%d",StaticData.Games[GameCommon.tableConfig.wKindID].name,GameCommon.tableConfig.wTbaleID,GameCommon.tableConfig.wCurrentNumber,GameCommon.tableConfig.wTableNumber))

        ccs.ArmatureDataManager:getInstance():addArmatureFileInfo("game/dengdaihaoyou/dengdaihaoyou.ExportJson")
        local waitArmature=ccs.Armature:create("dengdaihaoyou")
        waitArmature:setPosition(-179.2,-158)
        if CHANNEL_ID == 6 or  CHANNEL_ID  == 7  or CHANNEL_ID == 8 or  CHANNEL_ID  == 9 then
            waitArmature:setPosition(0,-158)
        end 
        waitArmature:getAnimation():playWithIndex(0)
        uiButton_Invitation:addChild(waitArmature)   

    elseif GameCommon.tableConfig.nTableType == TableType_GoldRoom then            
        self:addVoice()
        uiPanel_playerInfoBg:setVisible(false)
        uiButton_ready:setVisible(false)
        uiButton_Invitation:setVisible(false)
        uiButton_out:setVisible(false)
        uiButton_SignOut:setVisible(false)
        local uiListView_function = ccui.Helper:seekWidgetByName(self.root,"ListView_function")
        uiListView_function:removeItem(uiListView_function:getIndex(uiButton_disbanded))
        uiListView_function:removeItem(uiListView_function:getIndex(uiButton_position))  
        local uiPanel_ready = ccui.Helper:seekWidgetByName(self.root,"Panel_ready")
--        uiPanel_ready:setVisible(false)
        uiButton_voice:setVisible(false)
        uiButton_expression:setVisible(false)
        if GameCommon.tableConfig.cbLevel == 2 then
            uiText_title:setString(string.format("%s 中级场 倍率 %d",StaticData.Games[GameCommon.tableConfig.wKindID].name,GameCommon.tableConfig.wCellScore))
        elseif GameCommon.tableConfig.cbLevel == 3 then
            uiText_title:setString(string.format("%s 高级场 倍率 %d",StaticData.Games[GameCommon.tableConfig.wKindID].name,GameCommon.tableConfig.wCellScore))
        else
            uiText_title:setString(string.format("%s 初级场 倍率 %d",StaticData.Games[GameCommon.tableConfig.wKindID].name,GameCommon.tableConfig.wCellScore))
        end                
        self:drawnout()        
        ccs.ArmatureDataManager:getInstance():addArmatureFileInfo("game/xunzhaoduishou/xunzhaoduishou.ExportJson")
        local waitArmature=ccs.Armature:create("xunzhaoduishou")
        waitArmature:setPosition(0,-158)
        waitArmature:getAnimation():playWithIndex(0)
        uiButton_cancel:addChild(waitArmature)
        
    elseif GameCommon.tableConfig.nTableType == TableType_SportsRoom then            
        self:addVoice()
        uiPanel_playerInfoBg:setVisible(false)
        uiButton_ready:setVisible(false)
        uiButton_Invitation:setVisible(false)
        uiButton_out:setVisible(false)
        uiButton_SignOut:setVisible(false)
        local uiListView_function = ccui.Helper:seekWidgetByName(self.root,"ListView_function")
        uiListView_function:removeItem(uiListView_function:getIndex(uiButton_disbanded))        
        if  StaticData.Hide[CHANNEL_ID].btn10 == 0 then 
            uiListView_function:removeItem(uiListView_function:getIndex(uiButton_position)) 
        end 
        local uiPanel_ready = ccui.Helper:seekWidgetByName(self.root,"Panel_ready")
--        uiPanel_ready:setVisible(false)
        uiButton_voice:setVisible(false)
        uiButton_expression:setVisible(false)
        uiText_title:setString(string.format("%s 竞技场",StaticData.Games[GameCommon.tableConfig.wKindID].name))

        self:drawnout()

        ccs.ArmatureDataManager:getInstance():addArmatureFileInfo("game/xunzhaoduishou/xunzhaoduishou.ExportJson")
        local waitArmature=ccs.Armature:create("xunzhaoduishou")
        waitArmature:setPosition(0,-158)
        waitArmature:getAnimation():playWithIndex(0)
        uiButton_cancel:addChild(waitArmature)
    else
        local uiPanel_ui = ccui.Helper:seekWidgetByName(self.root,"Panel_ui")
        uiPanel_ui:setVisible(false)
        uiText_title:setString(string.format("%s 牌局回放",StaticData.Games[GameCommon.tableConfig.wKindID].name))
    end
    
    --重启游戏
    local Button_reset = ccui.Helper:seekWidgetByName(self.root,"Button_reset")
    Button_reset:setPressedActionEnabled(true)
    local function onEventReset(sender,event)
        if event == ccui.TouchEventType.ended then
            Common:palyButton()
            require("common.SceneMgr"):switchScene(require("app.MyApp"):create(true,true):createView("LoginLayer"),SCENE_LOGIN)
        end
    end
    Button_reset:addTouchEventListener(onEventReset)
end

function TableLayer:BaoTingCardShow(pBuffer)
    GameCommon.mBaoTingCard = {}
    local isBaoting = false
    for i = 1, 14 do
        if pBuffer.cbBTCard[i] ~= 0 then
            GameCommon.mBaoTingCard[i] = pBuffer.cbBTCard[i]
            isBaoting = true
        end
    end         
    local uiButton_chakan = ccui.Helper:seekWidgetByName(self.root,"Button_chakan")
    if isBaoting == true then
        print("激活跑停牌")
        self:showHandCard(GameCommon:getRoleChairID(),3) --GameCommon.waitOutCardUser
        uiButton_chakan:setVisible(false)  
    else
        
        uiButton_chakan:setVisible(true)  
    end
    GameCommon.mBTHuCard = {}
    for i = 1, 14 do
        if pBuffer.mBTHuCard[i] ~= nil and pBuffer.mBTHuCard[i] ~= 0 then
            GameCommon.mBTHuCard[i]= {}
            for j = 1, 27 do
                if pBuffer.mBTHuCard[i][j]~= nil and pBuffer.mBTHuCard[i][j] ~= 0 then
                    GameCommon.mBTHuCard[i][j]=pBuffer.mBTHuCard[i][j]
                    print("+++++报停胡获取胡那些牌++++",i,j,pBuffer.mBTHuCard[i][j])
                end                
            end 
        end
    end 
    self:runAction(cc.Sequence:create(cc.DelayTime:create(0),cc.CallFunc:create(function(sender,event) EventMgr:dispatch(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK) end))) 
end

function TableLayer:huCardShow(event,data)
    local uiPanel_hucardbg = ccui.Helper:seekWidgetByName(self.root,"Panel_hucardbg")  
    
    uiPanel_hucardbg:addTouchEventListener(function(sender,event)
        if event == ccui.TouchEventType.ended then
            uiPanel_hucardbg:setScale(1)
            uiPanel_hucardbg:runAction(cc.Sequence:create(cc.DelayTime:create(0.1),cc.ScaleTo:create(0.3,0,0),cc.CallFunc:create(function() uiPanel_hucardbg:setVisible(false)  end)))            
        end
    end)  
    if data ~= nil then
        self:huCardUpShow(data)
    else
        self:huCardUpShow(1)
        data = 1
    end
-----统计剩余字牌
--   GameCommon.player[wChairID].cardNode[i].data    玩家手牌
--   GameCommon.player[wChairID].WeaveItemArray[key]  吃碰组合
--   GameCommon.player[wChairID].cbDiscardCard   弃牌数据
    
    if event == 1 then  
        uiPanel_hucardbg:setScale(1)
        uiPanel_hucardbg:runAction(cc.Sequence:create(cc.DelayTime:create(0.1),cc.ScaleTo:create(0.1,0,0))) 
        uiPanel_hucardbg:setVisible(false)
    else
        uiPanel_hucardbg:setVisible(true)
        uiPanel_hucardbg:setScale(0)
        uiPanel_hucardbg:runAction(cc.Sequence:create(cc.DelayTime:create(0.1),cc.ScaleTo:create(0.2,1.1,1),cc.ScaleTo:create(0.1,1),cc.CallFunc:create(function(sender,event) self:huCardUpShow(data) end)))       
    end  
    
end 


function TableLayer:huCardUpShowData()
    GameCommon.card = {}
    for i=0x01,0x31 do
        GameCommon.card[i] = 4
    end 
    if GameCommon.tableConfig.wKindID == 63 then 
        GameCommon.card[0x31] = 8
    end  
    if GameCommon.tableConfig.wKindID == 67 then   --王数判断    
        GameCommon.card[0x31] = 4
    end   
    for i = 0,3 do   
        if  GameCommon.player[i]~= nil and GameCommon.player[i].cbDiscardCard ~= nil then 
            for j= 1 ,#GameCommon.player[i].cbDiscardCard do
                if GameCommon.player[i].cbDiscardCard[j]~= nil and GameCommon.player[i].cbDiscardCard[j]~= 0 then 
                    GameCommon.card[ GameCommon.player[i].cbDiscardCard[j]] =GameCommon.card[ GameCommon.player[i].cbDiscardCard[j]]- 1 
                end 
            end 
        end --GameCommon.waitOutCardUser
    end 
    if GameCommon.player[GameCommon:getRoleChairID()]~= nil and  GameCommon.player[GameCommon:getRoleChairID()].cardNode~= nil then 
        local cardData = GameCommon.player[GameCommon:getRoleChairID()].cardNode
        for i = 1 ,#cardData do
            if cardData[i].data~= nil and cardData[i].data~= 0 then 
                GameCommon.card[cardData[i].data] = GameCommon.card[cardData[i].data]- 1 
            end 
        end
    end    
    for i = 0,3 do
        if   GameCommon.player[i]~= nil and GameCommon.player[i].WeaveItemArray~= nil then 
            for j = 1,#GameCommon.player[i].WeaveItemArray do 
                local WeaveItemArray = GameCommon.player[i].WeaveItemArray[j]
                if Bit:_and(WeaveItemArray.cbWeaveKind,GameCommon.WIK_GANG) ~= 0 then
                    GameCommon.card[WeaveItemArray.cbCenterCard] = 0             
                end              
                if Bit:_and(WeaveItemArray.cbWeaveKind,GameCommon.WIK_GANG) ~= 0 then
                    GameCommon.card[WeaveItemArray.cbCenterCard] = 0                       
                elseif Bit:_and(WeaveItemArray.cbWeaveKind,GameCommon.WIK_FILL) ~= 0 then        
                    GameCommon.card[WeaveItemArray.cbCenterCard] = 0  
                elseif Bit:_and(WeaveItemArray.cbWeaveKind,GameCommon.WIK_PENG) ~= 0 then
                    GameCommon.card[WeaveItemArray.cbCenterCard] = GameCommon.card[WeaveItemArray.cbCenterCard] - 3  
                elseif Bit:_and(WeaveItemArray.cbWeaveKind,GameCommon.WIK_LEFT) ~= 0 then
                    if (WeaveItemArray.cbCenterCard >= 49 and WeaveItemArray.cbCenterCard <= 55) and GameCommon.tableConfig.wKindID == 65 then
                        GameCommon.card[WeaveItemArray.wChiFengJianCard[1]] = GameCommon.card[WeaveItemArray.wChiFengJianCard[1]] - 1
                        GameCommon.card[WeaveItemArray.wChiFengJianCard[2]] = GameCommon.card[WeaveItemArray.wChiFengJianCard[2]] - 1
                        GameCommon.card[WeaveItemArray.wChiFengJianCard[3]] = GameCommon.card[WeaveItemArray.wChiFengJianCard[3]] - 1               
                    else
                        GameCommon.card[WeaveItemArray.cbCenterCard] = GameCommon.card[WeaveItemArray.cbCenterCard] - 1
                        GameCommon.card[WeaveItemArray.cbCenterCard+1] = GameCommon.card[WeaveItemArray.cbCenterCard+1] - 1
                        GameCommon.card[WeaveItemArray.cbCenterCard+2] = GameCommon.card[WeaveItemArray.cbCenterCard+2] - 1
                    end   
                elseif Bit:_and(WeaveItemArray.cbWeaveKind,GameCommon.WIK_CENTER) ~= 0 then
                    GameCommon.card[WeaveItemArray.cbCenterCard] = GameCommon.card[WeaveItemArray.cbCenterCard] - 1
                    GameCommon.card[WeaveItemArray.cbCenterCard+1] = GameCommon.card[WeaveItemArray.cbCenterCard+1] - 1
                    GameCommon.card[WeaveItemArray.cbCenterCard-1] = GameCommon.card[WeaveItemArray.cbCenterCard-1] - 1
                elseif Bit:_and(WeaveItemArray.cbWeaveKind,GameCommon.WIK_RIGHT) ~= 0 then
                    GameCommon.card[WeaveItemArray.cbCenterCard] = GameCommon.card[WeaveItemArray.cbCenterCard] - 1
                    GameCommon.card[WeaveItemArray.cbCenterCard-1] = GameCommon.card[WeaveItemArray.cbCenterCard-1] - 1
                    GameCommon.card[WeaveItemArray.cbCenterCard-2] = GameCommon.card[WeaveItemArray.cbCenterCard-2] - 1
                end
            end   
        end   
    end
end 

function TableLayer:huCardUpShow(data)
    -- if  #GameCommon.mHuCard >18 then 
    -- else
        self:huCardUpShowData()  
    -- end   
   -- GameCommon.cdTingData = data
-------- 
    local uiImage_hucard = ccui.Helper:seekWidgetByName(self.root,"Image_hucard")       
    local uiListView_allhucard = ccui.Helper:seekWidgetByName(self.root,"ListView_allhucard")  
    if not self.uiListView_hucard then
        self.uiListView_hucard = ccui.Helper:seekWidgetByName(self.root,"ListView_hucard")   
        self.uiListView_hucard:retain()  
    end  
        
    uiListView_allhucard:removeAllItems()  
    local uiListView_list0  = nil  
    local uiListView_list1  = nil 
    local uiListView_list2  = nil 
    if #GameCommon.mBTHuCard[data] >0 then 
        uiListView_list0 = self.uiListView_hucard:clone()    
        uiListView_allhucard:pushBackCustomItem(uiListView_list0)  
        if #GameCommon.mBTHuCard[data] >9 then 
            uiListView_list1 = self.uiListView_hucard:clone()    
            uiListView_allhucard:pushBackCustomItem(uiListView_list1)  
            if #GameCommon.mBTHuCard[data] >18 then 
                uiListView_list2 = self.uiListView_hucard:clone()    
                uiListView_allhucard:pushBackCustomItem(uiListView_list2)  
            end 
        end  
    end            
    for i = 1 ,#GameCommon.mBTHuCard[data] do   
        -- if GameCommon.gameConfig.bPlayerCount == 2 and  GameCommon.mHuCard[i] >=0x21 and GameCommon.mHuCard[i] <=0x29 then  
        -- else                   
            local card = nil  
            if GameCommon.mBTHuCard[data][i] ~= nil and GameCommon.mBTHuCard[data][i] ~= 0  then
                if GameCommon.isNoTongZi ~=nil and GameCommon.isNoTongZi == false and (GameCommon.mBTHuCard[data][i] >= 0x21 and GameCommon.mBTHuCard[data][i] < 0x30) then 
                else
                    card = GameCommon:GetHUCard(GameCommon.mBTHuCard[data][i])
                    print("+++++++++剩余扑克数量：",i,GameCommon.mBTHuCard[data][i],GameCommon.card[GameCommon.mBTHuCard[data][i]])
                    local uiAtlasLabel_num = ccui.TextAtlas:create(string.format("%d",GameCommon.card[GameCommon.mBTHuCard[data][i]]),"fonts/fonts_16.png",24,33,'.')
                    card:addChild(uiAtlasLabel_num)
                    uiAtlasLabel_num:setAnchorPoint(cc.p(0.5,0.5))
                    uiAtlasLabel_num:setPosition(70,18) 
                end 
            end
            if card ~= nil then
                card:setScale(0.6)             
                if i < 10 then             
                    uiListView_list0:pushBackCustomItem(card)
                elseif i >=10 and i <= 18 then             
                    uiListView_list1:pushBackCustomItem(card)
                elseif i > 18 then             
                    uiListView_list2:pushBackCustomItem(card)                                   
                end                  
            end 
        -- end         
    end  
    if GameCommon.tableConfig.wKindID == 68 or  GameCommon.tableConfig.wKindID == 63 or GameCommon.tableConfig.wKindID == 67 then
        local  card = GameCommon:GetHUCard(0x31)
        card:setScale(0.6)  
        if #GameCommon.mBTHuCard[data] >18  then        
            uiListView_list2:pushBackCustomItem(card)
        elseif #GameCommon.mBTHuCard[data] >9 and #GameCommon.mBTHuCard[data] <=18 then 
            uiListView_list1:pushBackCustomItem(card)
        elseif #GameCommon.mBTHuCard[data] <=9 and #GameCommon.mBTHuCard[data] >0 then 
            uiListView_list0:pushBackCustomItem(card)
        end
        if GameCommon.card[0x31] ~= nil and GameCommon.card[0x31] ~= 0 then 
            -- if  #GameCommon.mBTHuCard[data] >18 then 
            -- else
                local uiAtlasLabel_num = ccui.TextAtlas:create(string.format("%d",GameCommon.card[0x31]),"fonts/fonts_16.png",24,33,'.')
                card:addChild(uiAtlasLabel_num)
                uiAtlasLabel_num:setAnchorPoint(cc.p(0.5,0.5))
                uiAtlasLabel_num:setPosition(70,18)
            -- end
       end
    end
    if  uiListView_list0 ~= nil then 
        uiListView_list0:refreshView()
        uiListView_list0:setContentSize(cc.size(uiListView_list0:getInnerContainerSize().width,uiListView_list0:getInnerContainerSize().height)) 
        if  uiListView_list1 ~= nil then
            uiListView_list1:refreshView()
            uiListView_list1:setContentSize(cc.size(uiListView_list1:getInnerContainerSize().width,uiListView_list1:getInnerContainerSize().height)) 
            if uiListView_list2 ~= nil then 
                uiListView_list2:refreshView()
                uiListView_list2:setContentSize(cc.size(uiListView_list2:getInnerContainerSize().width,uiListView_list2:getInnerContainerSize().height))  
            end 
        end     
    end 
   
    if #uiListView_allhucard:getItems() > 0 then
        local height = 0
        local width = 0
        for key, var in pairs(uiListView_allhucard:getItems()) do
            height = height + var:getContentSize().height    
            width = uiListView_list0:getContentSize().width            
            if uiListView_list0:getContentSize().width < var:getContentSize().width then  
                width = var:getContentSize().width
            end     
        end           
        if #GameCommon.mBTHuCard[data] >=4 then 
            uiImage_hucard:setContentSize(cc.size(width,height+68))
        else
            uiImage_hucard:setContentSize(cc.size(388,70+68))            
        end 
        uiImage_hucard:setPosition(uiImage_hucard:getParent():getContentSize().width/2,uiImage_hucard:getParent():getContentSize().height-height/2)
        uiListView_allhucard:refreshView()--
        uiListView_allhucard:setContentSize(cc.size(width,height))
        uiListView_allhucard:setPosition(uiListView_allhucard:getParent():getContentSize().width/2,uiListView_allhucard:getParent():getContentSize().height/2+20)
    end
end

function TableLayer:drawnout()
    local uiImage_timedown = ccui.Helper:seekWidgetByName(self.root,"Image_timedown")
    uiImage_timedown:setVisible(true)
    local uiText_stack = ccui.Helper:seekWidgetByName(self.root,"Text_stack")
    uiText_stack:setVisible(false)
    
--    local uiAtlasLabel_timedown = ccui.Helper:seekWidgetByName(self.root,"AtlasLabel_timedown")
--    uiAtlasLabel_timedown:setPosition(uiAtlasLabel_timedown:getParent():getContentSize().width/2,uiAtlasLabel_timedown:getParent():getContentSize().height*0.56)
--    uiAtlasLabel_timedown:stopAllActions()
--    uiAtlasLabel_timedown:setString(0)
--    local function onEventTime(sender,event)
--        local currentTime = tonumber(uiAtlasLabel_timedown:getString())
--        print("时间：",uiAtlasLabel_timedown:getString(),currentTime)        
--        currentTime = currentTime + 1
--        uiAtlasLabel_timedown:setString(tostring(currentTime))
--    end
--    uiAtlasLabel_timedown:runAction(cc.RepeatForever:create(cc.Sequence:create(cc.DelayTime:create(1),cc.CallFunc:create(onEventTime)))) 
    
    
    local uiText__timedown = ccui.Helper:seekWidgetByName(self.root,"Text__timedown")
    uiText__timedown:setPosition(uiText__timedown:getParent():getContentSize().width/2,uiText__timedown:getParent():getContentSize().height*0.56)
    uiText__timedown:stopAllActions()
    uiText__timedown:setString("00:00:00")
    local currentTime = 0
    local function onEventTime(sender,event)   
        currentTime = currentTime + 1
        uiText__timedown:setString(string.format("%02d:%02d:%02d",math.floor(currentTime/(60*60)),math.floor(currentTime/60),math.floor(currentTime%60)))
    end
    uiText__timedown:runAction(cc.RepeatForever:create(cc.Sequence:create(cc.DelayTime:create(1),cc.CallFunc:create(onEventTime)))) 
    
    local uiPanel_outCardTips = ccui.Helper:seekWidgetByName(self.root,"Panel_outCardTips")
    uiPanel_outCardTips:removeAllChildren()
--    local uiImage_dir = ccui.Helper:seekWidgetByName(self.root,"Image_1")  
--    uiImage_dir:setRotation(0)
--    local uiImage_dir = ccui.Helper:seekWidgetByName(self.root,"Image_dir")
--    uiImage_dir:stopAllActions()
--    uiImage_dir:setVisible(true)
--    uiImage_dir:runAction(cc.RepeatForever:create(cc.Blink:create(1,1)))
end 


function TableLayer:updateGameState(state)
    GameCommon.gameState = state 
    local visibleSize = cc.Director:getInstance():getVisibleSize()
    if state == GameCommon.GameState_Init then
    elseif state == GameCommon.GameState_Start then
		require("common.SceneMgr"):switchOperation()
        local uiPanel_playerInfoBg = ccui.Helper:seekWidgetByName(self.root,"Panel_playerInfoBg")
        uiPanel_playerInfoBg:setVisible(false)
        local uiPanel_ready = ccui.Helper:seekWidgetByName(self.root,"Panel_ready")
        uiPanel_ready:setVisible(false)
        if GameCommon.tableConfig.wKindID == 67 or GameCommon.tableConfig.wKindID == 63 or GameCommon.tableConfig.wKindID == 68 or GameCommon.tableConfig.wKindID == 46 or GameCommon.tableConfig.wKindID == 50 and  StaticData.Hide[CHANNEL_ID].btn16 == 1  then 
            local uiButton_chakan = ccui.Helper:seekWidgetByName(self.root,"Button_chakan")
            -- if CHANNEL_ID == 0 or  CHANNEL_ID  == 1 then 
            --     uiButton_chakan:setVisible(false)  
            -- else
            --     uiButton_chakan:setVisible(true)  
            -- end 
        end
        if GameCommon.tableConfig.nTableType > TableType_GoldRoom then
            --距离报警  
--            local DistanceAlarm = cc.UserDefault:getInstance():getIntegerForKey("UserDefault_DistanceAlarm",0)
--            cc.UserDefault:getInstance():setIntegerForKey("UserDefault_DistanceAlarm",1)

            if GameCommon.tableConfig.wCurrentNumber ~= nil and GameCommon.tableConfig.wCurrentNumber == 1 and GameCommon.DistanceAlarm ~= 1  then
               if StaticData.Hide[CHANNEL_ID].btn16 ==1 then 
                GameCommon.DistanceAlarm = 1 
                if GameCommon.gameConfig.bPlayerCount ~= 2 then 
                    require("common.DistanceAlarm"):create(GameCommon)
                 end  
               end 
            end
            for i = 1, 4 do
                local uiPanel_player = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_player%d",i))
                local uiImage_ready = ccui.Helper:seekWidgetByName(uiPanel_player,"Image_ready")
                uiImage_ready:setVisible(false)
            end
        elseif GameCommon.tableConfig.nTableType == TableType_GoldRoom or GameCommon.tableConfig.nTableType == TableType_SportsRoom then
            local uiButton_expression = ccui.Helper:seekWidgetByName(self.root,"Button_expression")
            uiButton_expression:setVisible(true)
            local uiButton_voice = ccui.Helper:seekWidgetByName(self.root,"Button_voice")
            uiButton_voice:setVisible(true)
        end         
        local uiButton_cancel = ccui.Helper:seekWidgetByName(self.root,"Button_cancel")  --取消按钮
        uiButton_cancel:setVisible(false)
        local uiImage_timedown = ccui.Helper:seekWidgetByName(self.root,"Image_timedown")
        uiImage_timedown:setVisible(false)
        local uiImage_direction = ccui.Helper:seekWidgetByName(self.root,"Image_direction")
        uiImage_direction:setVisible(true)

        --在准备界面点击报错，修改进入牌桌才激活
        local uiPanel_refreshHandCard = ccui.Helper:seekWidgetByName(self.root,"Panel_refreshHandCard")
        uiPanel_refreshHandCard:setTouchEnabled(true)
    elseif state == GameCommon.GameState_Over then
        UserData.Game:addGameStatistics(GameCommon.tableConfig.wKindID)
    else
    
    end
end

--语音
function TableLayer:addVoice()
    self.tableVoice = {}
    local startVoiceTime = 0
    local maxVoiceTime = 15
    local intervalTimePackage = 0.1
    local fileName = "temp_voice.mp3"
    local uiButton_voice = ccui.Helper:seekWidgetByName(self.root,"Button_voice")
    local animVoice = cc.CSLoader:createNode("VoiceNode.csb")
    self:addChild(animVoice,120)
    local root = animVoice:getChildByName("Panel_root")
    local uiPanel_recording = ccui.Helper:seekWidgetByName(root,"Panel_recording")
    local uiPanel_cancel = ccui.Helper:seekWidgetByName(root,"Panel_cancel")
    local uiText_surplus = ccui.Helper:seekWidgetByName(root,"Text_surplus")
    animVoice:setVisible(false)

    --重置状态
    local duration = 0
    local function resetVoice()
        startVoiceTime = 0
        animVoice:stopAllActions()
        animVoice:setVisible(false)
        uiPanel_recording:setVisible(true)

        local uiImage_pro = ccui.Helper:seekWidgetByName(root,"Image_pro")
        uiImage_pro:removeAllChildren()
        local volumeMusic = cc.UserDefault:getInstance():getFloatForKey("UserDefault_Music",1)
        cc.SimpleAudioEngine:getInstance():setMusicVolume(volumeMusic)
        cc.SimpleAudioEngine:getInstance():setEffectsVolume(1)
        uiButton_voice:removeAllChildren()
        local node = require("common.CircleLoadingBar"):create("game/tablenew_23.png")
        node:setColor(cc.c3b(0,0,0))
        uiButton_voice:addChild(node)
        node:setPosition(node:getParent():getContentSize().width/2,node:getParent():getContentSize().height/2)
        node:start(1)
        uiButton_voice:setEnabled(false)
        uiButton_voice:stopAllActions()
        uiButton_voice:runAction(cc.Sequence:create(cc.DelayTime:create(1),cc.CallFunc:create(function(sender,event) 
            uiButton_voice:setEnabled(true)
        end)))
    end

    root:setTouchEnabled(true)
    root:addTouchEventListener(function(sender,event) 
        UserData.Game:cancelVoice()
        resetVoice() 
    end)

    local function onEventSendVoic(event)
        if self.root == nil then
            return
        end
        if cc.PLATFORM_OS_ANDROID == cc.Application:getInstance():getTargetPlatform() then
            if event == nil or string.len(event) <= 0 then
                return
            else
                event = Base64.decode(event)
            end
            local file = io.open(FileDir.dirVoice..fileName,"wb+")
            file:write(event)
            file:close()
        end
        if cc.FileUtils:getInstance():isFileExist(FileDir.dirVoice..fileName) == false then
            print("没有找到录音文件",FileDir.dirVoice..fileName)
            return
        end
        local fp = io.open(FileDir.dirVoice..fileName,"rb")
        local fileData = fp:read("*a")
        fp:close()

        local data = {}
        data.chirID = GameCommon:getRoleChairID()
        data.time = duration
        data.file = string.format("%d_%d.mp3",os.time(),UserData.User.userID)

        local fp = io.open(FileDir.dirVoice..data.file,"wb+")
        fp:write(fileData)
        fp:close()
        table.insert(self.tableVoice,#self.tableVoice + 1,data) 

        cc.FileUtils:getInstance():removeFile(FileDir.dirVoice..fileName)   --windows test

        local fileSize = string.len(fileData)
        local packSize = 1024
        local additional = fileSize%packSize
        if additional > 0 then
            additional = 1
        else
            additional = 0
        end
        local packCount = math.floor(fileSize/packSize) + additional
        local currentPos = 0
        for i = 1 , packCount do
            local periodData = string.sub(fileData,1,packSize)
            fileData = string.sub(fileData,packSize + 1)
            local periodSize = string.len(periodData)
            NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_GF_USER_VOICE,"wwwdddnsnf",GameCommon:getRoleChairID(),packCount,i,data.time,fileSize,periodSize,32,data.file,periodSize,periodData)
        end

    end

    local function onEventVoice(sender,event)
        if event == ccui.TouchEventType.began then
            startVoiceTime = 0
            uiButton_voice:setEnabled(false)
            animVoice:setVisible(true)
            cc.SimpleAudioEngine:getInstance():setMusicVolume(0) 
            cc.SimpleAudioEngine:getInstance():setEffectsVolume(0) 
            uiPanel_recording:setVisible(true)
            startVoiceTime = os.time()
            UserData.Game:startVoice(FileDir.dirVoice..fileName,maxVoiceTime,onEventSendVoic)

            local node = require("common.CircleLoadingBar"):create("common/yuying02.png")
            local uiImage_pro = ccui.Helper:seekWidgetByName(root,"Image_pro")
            uiImage_pro:removeAllChildren()
            uiImage_pro:addChild(node)
            node:setPosition(node:getParent():getContentSize().width/2,node:getParent():getContentSize().height/2)
            node:start(maxVoiceTime)

            local currentTime = 0
            uiText_surplus:stopAllActions()
            uiText_surplus:setString(string.format("还剩%d秒",maxVoiceTime - currentTime))
            uiText_surplus:runAction(cc.RepeatForever:create(cc.Sequence:create(cc.DelayTime:create(1),cc.CallFunc:create(function(sender,event) 
                currentTime = currentTime + 1
                if currentTime > maxVoiceTime then
                    uiText_surplus:stopAllActions()
                    return
                end
                uiText_surplus:setString(string.format("还剩%d秒",maxVoiceTime - currentTime))
            end))))

        elseif event == ccui.TouchEventType.ended then
            if startVoiceTime == 0 or os.time() - startVoiceTime < 1 then
                UserData.Game:cancelVoice()
                resetVoice()
                return
            end
            duration = os.time() - startVoiceTime
            resetVoice()
            UserData.Game:overVoice()
            --onEventSendVoic() --windows test
        elseif event == ccui.TouchEventType.canceled then   
            if startVoiceTime == 0 or os.time() - startVoiceTime < 1 then
                resetVoice()
                return
            end
            resetVoice()
            UserData.Game:cancelVoice()
        end
    end
    uiButton_voice:addTouchEventListener(onEventVoice)
    local function onEventPlayVoice(sender,event)
        if #self.tableVoice > 0 then
            local data = self.tableVoice[1]
            table.remove(self.tableVoice,1)
            if data.time > maxVoiceTime then
                data.time = maxVoiceTime
            end
            local viewID = GameCommon:getViewIDByChairID(data.chirID)
            local wanjia = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_player%d",viewID))
            local uiImage_laba = ccui.Helper:seekWidgetByName(wanjia,"Image_laba")
            local blinks = math.floor(data.time*2)+1
            uiImage_laba:stopAllActions()
            uiImage_laba:runAction(cc.Sequence:create(
                cc.Show:create(),
                cc.CallFunc:create(function(sender,event) 
                    require("common.Common"):playVoice(FileDir.dirVoice..data.file)
                end),
                cc.Blink:create(data.time,blinks) ,
                cc.Hide:create(),
                cc.DelayTime:create(1),
                cc.CallFunc:create(function(sender,event) 
                    cc.FileUtils:getInstance():removeFile(FileDir.dirVoice..data.file) 
                    onEventPlayVoice()
                end)
            ))

        else
            self:runAction(cc.Sequence:create(cc.DelayTime:create(0),cc.CallFunc:create(onEventPlayVoice)))
        end
    end
    onEventPlayVoice()
end

function TableLayer:OnUserChatVoice(event)
    if self.tableVoicePackages == nil then
        self.tableVoicePackages = {}
    end
    if self.tableVoicePackages[event.szFileName] == nil then
        self.tableVoicePackages[event.szFileName] = {}
    end
    self.tableVoicePackages[event.szFileName][event.wPackIndex] = event

    --组包
    if event.wPackCount == #self.tableVoicePackages[event.szFileName] then
        local fileData = ""
        for key, var in pairs(self.tableVoicePackages[event.szFileName]) do
            fileData = fileData..var.szPeriodData
        end 
        local data = {}
        data.chirID = self.tableVoicePackages[event.szFileName][1].wChairID
        data.time = self.tableVoicePackages[event.szFileName][1].dwTime
        data.file = self.tableVoicePackages[event.szFileName][1].szFileName
        local fp = io.open(FileDir.dirVoice..data.file,"wb+")
        fp:write(fileData)
        fp:close()
        table.insert(self.tableVoice,#self.tableVoice + 1,data)
        self.tableVoicePackages[event.szFileName] = nil
        print("插入一条语音...",fileData)
    end
end
    
function TableLayer:showPlayerPosition()   -- 显示玩家距离
    local wChairID = 0
    for key, var in pairs(GameCommon.player) do
        if var.dwUserID == GameCommon.dwUserID then
            wChairID = var.wChairID
            break
        end
    end    
    for wChairID = 1, 4 do
        local uiPanel_players = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_players%d",wChairID))
        local uiImage_avatar = ccui.Helper:seekWidgetByName(uiPanel_players,"Image_avatar")
        uiImage_avatar:loadTexture("common/common_dian1.png")
        local uiText_name = ccui.Helper:seekWidgetByName(uiPanel_players,"Text_name")
        uiText_name:setString("") 
        for i = wChairID+1 , 4 do 
            local  uiText_location = ccui.Helper:seekWidgetByName(self.root,string.format("Text_%dto%d",wChairID,i)) 
            uiText_location:setString("")       
        end 
    end  
    local viewID = GameCommon:getViewIDByChairID(wChairID)    
    for wChairID = 0, 3 do       
        if GameCommon.player[wChairID] ~= nil then
            local viewID = GameCommon:getViewIDByChairID(wChairID)
            local uiPanel_players = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_players%d",viewID))
            local uiPanel_playerInfo = ccui.Helper:seekWidgetByName(uiPanel_players,"Panel_playerInfo")
            uiPanel_playerInfo:setVisible(true)
            local uiImage_avatar = ccui.Helper:seekWidgetByName(uiPanel_players,"Image_avatar")
            uiImage_avatar:loadTexture("common/common_dian2.png")
            local uiText_name = ccui.Helper:seekWidgetByName(uiPanel_players,"Text_name")
            uiText_name:setString(GameCommon.player[wChairID].szNickName)
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
       
        end  

    end
end

function TableLayer:showPlayerInfo(dwUserID,dwShamUserID,dwUserip)       -- 查看玩家信息
     Common:palyButton()
     require("common.PersonalLayer"):create(GameCommon.tableConfig.wKindID,dwUserID,dwShamUserID)
     
end

function TableLayer:showChat(pBuffer)
	local viewID = GameCommon:getViewIDByChairID(pBuffer.dwUserID)
    local uiPanel_player = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_player%d",viewID))
    local uiImage_chat = ccui.Helper:seekWidgetByName(uiPanel_player,"Image_chat")
    local uiText_chat = ccui.Helper:seekWidgetByName(uiPanel_player,"Text_chat")
    uiText_chat:setString(pBuffer.szChatContent)
    uiImage_chat:setVisible(true)
    uiImage_chat:setScale(0)
    uiImage_chat:stopAllActions()
    uiImage_chat:runAction(cc.Sequence:create(cc.ScaleTo:create(0.1,1),cc.DelayTime:create(5),cc.Hide:create()))
    local wKindID = GameCommon.tableConfig.wKindID
    local Chat = nil
    if CHANNEL_ID == 4 or CHANNEL_ID == 5 then 
        Chat = require("common.Chat")[3]
    elseif CHANNEL_ID == 10 or CHANNEL_ID == 11 then
        Chat = require("common.Chat")[0]
    else
        if wKindID == 33 or wKindID == 34 or wKindID == 35 or wKindID == 36 or wKindID == 37 then
            Chat = require("common.Chat")[1]
        elseif wKindID == 47 or wKindID == 48 or wKindID == 49 then
            Chat = require("common.Chat")[2]
        else    
            Chat = require("common.Chat")[0]
        end
    end 
    local data = Chat[pBuffer.dwSoundID]
    if data ~= nil and data.sound[pBuffer.cbSex] ~= "" then
        require("common.Common"):playEffect(data.sound[pBuffer.cbSex])
    end
end

function TableLayer:showExperssion(pBuffer)
	local viewID = GameCommon:getViewIDByChairID(pBuffer.wChairID)
    local uiPanel_userTips = ccui.Helper:seekWidgetByName(self.root,"Panel_userTips")
    local uiPanel_userTipsPos = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_userTips%d",viewID))
    
    local anim = require("game.cdphz.Animation") [23]
	if anim then
		local id = math.mod(pBuffer.wIndex, 50)
		local data = anim[id]
		if data then
			local skeletonNode = cc.Node:create()
			-- if not skeletonNode then
				skeletonNode = sp.SkeletonAnimation:create(data.animFile .. '.json', data.animFile .. '.atlas')
				uiPanel_userTips:addChild(skeletonNode)
				skeletonNode:setName('cdskele_' .. pBuffer.wIndex)
			-- end
			skeletonNode:setPosition(uiPanel_userTipsPos:getPosition())
			skeletonNode:setAnimation(0, data.animName, false)
			skeletonNode:setVisible(true)

			local idx = 1
			skeletonNode:registerSpineEventHandler(function()
				idx = idx + 1
				if idx > 3 then
					-- skeletonNode:runAction(cc.Sequence:create(cc.DelayTime:create(0), cc.RemoveSelf:create()))
					skeletonNode:setVisible(false)
				else
					skeletonNode:setAnimation(0, data.animName, false)
				end
			end, sp.EventType.ANIMATION_COMPLETE)
			
			local sound = data.sound
			local soundData = nil
			local soundFile = ''
			if sound then				
				soundData = sound[0]				
				if soundData ~= nil then
					local player = GameCommon.player[pBuffer.wChairID]
					local csbSex = 0
					if player then
						csbSex = player.cbSex
					end
					soundFile = soundData[csbSex]
				end
			end			
			if soundFile and soundFile ~= "" then
				require("common.Common"):playEffect(soundFile)
			end
		end
    end
    
        -- local filename = ""
        -- if pBuffer.wIndex == 0 then
        --     filename = "biaoqing-kaixin"
        -- elseif pBuffer.wIndex == 1 then
        --     filename = "biaoqing-shengqi"
        -- elseif pBuffer.wIndex == 2 then
        --     filename = "biaoqing-xihuan"
        -- elseif pBuffer.wIndex == 3 then
        --     filename = "biaoqing-cool"
        -- elseif pBuffer.wIndex == 4 then
        --     filename = "biaoqing-jingdai"
        -- elseif pBuffer.wIndex == 5 then
        --     filename = "biaoqing-daku" 
        -- else
        --     return
        -- end
        
        -- require("common.Common"):playEffect(string.format("expression/sound/%s.mp3",filename))
        -- ccs.ArmatureDataManager:getInstance():addArmatureFileInfo(string.format("expression/animation/%s.ExportJson",filename))
        -- local  armature = ccs.Armature:create(filename)
        -- uiPanel_userTips:addChild(armature)
        -- armature:setScale(0.4)
        -- armature:getAnimation():playWithIndex(0)
        -- armature:setPosition(uiPanel_userTipsPos:getPosition())
        -- armature:runAction(cc.Sequence:create(cc.DelayTime:create(2),cc.RemoveSelf:create()))
end

function TableLayer:sendXiaoHu(cbOperateCode,tableCardData)
    local net = NetMgr:getGameInstance()
    if net.connected == false then
        return
    end
    if #tableCardData <= 0 then
        return
    end
    net.cppFunc:beginSendBuf(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_C_Xihu)
    net.cppFunc:writeSendBool(true,0)
    net.cppFunc:writeSendWORD(cbOperateCode,0)
    for key, var in pairs(tableCardData) do
        net.cppFunc:writeSendByte(var,0)
    end
    for i = #tableCardData+1, 14 do
        net.cppFunc:writeSendByte(0,0)
    end
    net.cppFunc:endSendBuf()
    net.cppFunc:sendSvrBuf()
end

function TableLayer:EVENT_TYPE_SKIN_CHANGE(event)
    local data = event._usedata
    if data ~= 3 then
        return
    end
    --背景
    local uiPanel_bg = ccui.Helper:seekWidgetByName(self.root,"Panel_bg")
    local UserDefault_MaJiangpaizhuo = cc.UserDefault:getInstance():getIntegerForKey(Default.UserDefault_MaJiangpaizhuo,0)
    if UserDefault_MaJiangpaizhuo < 0 or UserDefault_MaJiangpaizhuo > 2 then
        UserDefault_MaJiangpaizhuo = 0
        cc.UserDefault:getInstance():setIntegerForKey(Default.UserDefault_MaJiangpaizhuo,UserDefault_MaJiangpaizhuo)
    end
    uiPanel_bg:removeAllChildren()
    uiPanel_bg:addChild(ccui.ImageView:create(string.format("majiang/table/game_table_bg%d.jpg",UserDefault_MaJiangpaizhuo)))

    --亮度
    local uiPanel_night = ccui.Helper:seekWidgetByName(self.root,"Panel_night")
    local UserDefault_MaJiangliangdu = cc.UserDefault:getInstance():getIntegerForKey(Default.UserDefault_MaJiangliangdu,0)
    if UserDefault_MaJiangliangdu == 0 then
        uiPanel_night:setVisible(false)
    else
        uiPanel_night:setVisible(true)
    end
        
    --牌背字体
    for i = 0 , GameCommon.gameConfig.bPlayerCount-1 do
        local wChairID = i
        if GameCommon.player ~= nil and GameCommon.player[wChairID] ~= nil then
            self:showHandCard(wChairID,i)
            self:setWeaveItemArray(wChairID, GameCommon.player[wChairID].bWeaveItemCount, GameCommon.player[wChairID].WeaveItemArray)
            self:setDiscardCard(wChairID, GameCommon.player[wChairID].cbDiscardCount, GameCommon.player[wChairID].cbDiscardCard)
        end
    end
end

--结算动画
function TableLayer:endAction(pBuffer)              
    local zhaoNiaoNum = self:getZNNumOrTime(pBuffer.bZhaNiao)
    if zhaoNiaoNum <= 0 then
        return
    end

    local visibleSize = cc.Director:getInstance():getVisibleSize()
    local uiPanel_tipsCard = ccui.Helper:seekWidgetByName(self.root,"Panel_tipsCard")
    local size = uiPanel_tipsCard:getContentSize()
    local imgBG = ccui.ImageView:create("game/game_zhongliao.png")
    uiPanel_tipsCard:addChild(imgBG)
    imgBG:setPosition(imgBG:getParent():getContentSize().width/2,imgBG:getParent():getContentSize().height*0.57)
    imgBG:setScale(1.6)
    local index = 0
    local count = 0 
    for i = 1, 85 do
        local data = pBuffer.bZhaNiao[i]
        if data ~= 0 and  data ~= 255  then
            count = count + 1
        end 
    end 
    for i = 1, 85 do
        local data = pBuffer.bZhaNiao[i]
        if data ~= 0 and  data ~= 255  then
            index = index +1
            local cardScale = 1.3
            local cardWidth = 55 * cardScale
            local cardHeight = 85 * cardScale
            local stepX = cardWidth + 25
            local  beganX = visibleSize.width/2 - stepX*count/2 - cardWidth/2
            if   GameCommon.gameConfig.bMaType == 3 then  
                beganX = visibleSize.width/2 - stepX*count/2 - cardWidth/2
            end
            
            local beganY = size.height +cardHeight+30
            local card = GameCommon:getDiscardCardAndWeaveItemArray(data,1)
            uiPanel_tipsCard:addChild(card)
            card:setPosition(beganX + stepX*index ,beganY)                                 
            card:setScale(cardScale)        
            local value = Bit:_and(data,0x0F)
            card:runAction(cc.Sequence:create(cc.DelayTime:create(0.4*(index-1)+1),
            cc.CallFunc:create(function(sender,event) require("common.Common"):playEffect("majiang/table/get.mp3")  end ),                                      
            cc.MoveTo:create(0.2,cc.p(beganX + stepX*index,visibleSize.height/2-cardHeight/3-10)),
            cc.MoveTo:create(0.06,cc.p(beganX + stepX*index,visibleSize.height/2-cardHeight/3+10)),cc.MoveTo:create(0.06,cc.p(beganX + stepX*index,visibleSize.height/2-cardHeight/3)),
            cc.CallFunc:create(function(sender,event) 
            if value == 1 or value == 5 or value == 9 then
                local img = ccui.ImageView:create("majiang/table/endlyer_6.png")
                if  GameCommon.gameConfig.bMaType == 3 then  
                    img:setVisible(false)
                end                 
                card:addChild(img,1000)
                local scale = card:getContentSize().width / img:getContentSize().width
                img:setScale(scale)
                img:setPosition(img:getParent():getContentSize().width/2,img:getContentSize().height/2)
            end  
            end )))
           
        else
            break
        end
    end
end 

function TableLayer:EVENT_TYPE_SIGNAL(event)
    local time = event._usedata
    local uiImage_signal = ccui.Helper:seekWidgetByName(self.root,"Image_signal")
    local uiText_signal = ccui.Helper:seekWidgetByName(self.root,"Text_signal")
    if GameCommon.tableConfig.nTableType ~= TableType_Playback then
        if time <= 100 then
            uiImage_signal:loadTexture("common/xinghao4.png")
            uiText_signal:setColor(cc.c3b(140,255,25))
        elseif time <= 200 then
            uiImage_signal:loadTexture("common/xinghao3.png")
            uiText_signal:setColor(cc.c3b(219,255,0))
        elseif time <= 300 then
            uiImage_signal:loadTexture("common/xinghao2.png")
            uiText_signal:setColor(cc.c3b(255,191,0))
        else
            uiImage_signal:loadTexture("common/xinghao1.png")
            uiText_signal:setColor(cc.c3b(255,0,20))
        end
        if time < 0 then
            uiText_signal:setString("")
        else
            uiText_signal:setString(string.format("%dms",time))
        end
    else
        uiImage_signal:setVisible(false)
    end
end

function TableLayer:EVENT_TYPE_ELECTRICITY(event)
    local data = event._usedata
    local uiImage_Electricity = ccui.Helper:seekWidgetByName(self.root,"Image_Electricity")
    local uiLoadingBar_Electricity = ccui.Helper:seekWidgetByName(self.root,"LoadingBar_Electricity")
    if data <= 0.1 then
        uiLoadingBar_Electricity:setColor(cc.c3b(255,0,20))
    elseif data <= 0.2 then
        uiLoadingBar_Electricity:setColor(cc.c3b(255,191,0))
    else
        uiLoadingBar_Electricity:setColor(cc.c3b(140,255,25))
    end
    uiLoadingBar_Electricity:setPercent(data*100)
end


---
-- 添加当前最后出牌角标动作
-- @DateTime 2018-05-24
-- @param  node 当前最后出的牌节点
-- @return [description]
--
function TableLayer:addLastCardFlagEft(node)
    self:removeLastCardFlagEft()
    self.flagNode = ccui.ImageView:create('majiang/table/end_outcard_pos.png')
    node:addChild(self.flagNode)
    local size = node:getContentSize()
    local spos = cc.p(size.width / 2, size.height + 20)
    local epos = cc.p(size.width / 2, size.height)
    self.flagNode:setPosition(spos)
    local startMove = cc.MoveTo:create(0.3, epos)
    local reverseMove = cc.MoveTo:create(0.3, spos)
    local sequence = cc.Sequence:create(startMove, reverseMove)
    self.flagNode:runAction(cc.RepeatForever:create(sequence))

    local function onEventEnded(eventType)
        if eventType == "exit" then
            self.flagNode = nil
        end
    end
    self.flagNode:registerScriptHandler(onEventEnded)
end

---
-- 移除当前最后出牌角标动作
-- @DateTime 2018-05-24
-- @param  [description]
-- @return [description]
--
function TableLayer:removeLastCardFlagEft()
    if self.flagNode then
        self.flagNode:removeFromParent()
        self.flagNode = nil
    end
end

---
-- 吃，碰，杆等操作移除对应弃牌
-- @DateTime 2018-05-29
-- @param  [description]
-- @return [description]
--
function TableLayer:removeOperateDisCard()
    if not (self.lastDiscardChariID and self.lastDiscardNode) then
        return
    end

    GameCommon.player[self.lastDiscardChariID].cbDiscardCard[GameCommon.player[self.lastDiscardChariID].cbDiscardCount] = nil
    GameCommon.player[self.lastDiscardChariID].cbDiscardCount = GameCommon.player[self.lastDiscardChariID].cbDiscardCount - 1
    self.lastDiscardNode:removeFromParent()
    self.lastDiscardNode = nil
    self.lastDiscardChariID = nil
    self.lastSendCardChariID = nil
end

---
-- 获取抓鸟个数和动作时间
-- @DateTime 2018-05-30
-- @param  bufferData 抓鸟数据集合
-- @return number, time
--
function TableLayer:getZNNumOrTime(bufferData)
    if type(bufferData) ~= 'table' then
        return 0, 0
    end

    local index = 0
    for i = 1, 85 do
        local data = bufferData[i]
        if data ~= 0 and  data ~= 255  then
            index = index + 1
        end      
    end

    if index <= 0 then
        return 0, 0
    else
        return index, (0.4 * (index - 1) + 1 + 0.26) + 0.5
    end
end

--==============================--
--desc:表情互动
--time:2018-08-14 07:40:11
--@wChairID:
--@return 
--==============================--

function TableLayer:getViewWorldPosByChairID(wChairID)
	for key, var in pairs(GameCommon.player) do
		if wChairID == var.wChairID then
			local viewid = GameCommon:getViewIDByChairID(var.wChairID, true)
			local uiPanel_player = ccui.Helper:seekWidgetByName(self.root, string.format("Panel_player%d", viewid))
			local uiImage_avatar = ccui.Helper:seekWidgetByName(uiPanel_player, "Image_avatar")
			return uiImage_avatar:getParent():convertToWorldSpace(cc.p(uiImage_avatar:getPosition()))
		end
	end
end

function TableLayer:playSketlAnim(sChairID, eChairID, index,indexEx)

    local cusNode = cc.Director:getInstance():getNotificationNode()
    if not cusNode then
    	printInfo('global_node is nil!')
    	return
    end
    local arr = cusNode:getChildren()
    for i,v in ipairs(arr) do
        v:setVisible(false)
    end

	local Animation = require("game.huaihua.Animation")
	local AnimCnf = Animation[22]
	
	if not AnimCnf[index] then
		return
	end
    
    indexEx = indexEx or ''
	local skele_key_name = 'hhhudong_' .. index .. indexEx
	local spos = self:getViewWorldPosByChairID(sChairID)
	local epos = self:getViewWorldPosByChairID(eChairID)
	local image = ccui.ImageView:create(AnimCnf[index].imageFile .. '.png')
	self:addChild(image)
	image:setPosition(spos)
	local moveto = cc.MoveTo:create(0.6, cc.p(epos))
	local callfunc = cc.CallFunc:create(function()
		local path = AnimCnf[index].animFile
		local skeletonNode = cusNode:getChildByName(skele_key_name)
		if not skeletonNode then
			skeletonNode = sp.SkeletonAnimation:create(path .. '.json', path .. '.atlas', 1)
			cusNode:addChild(skeletonNode)
			skeletonNode:setName(skele_key_name)
		end
		skeletonNode:setPosition(epos)
		skeletonNode:setAnimation(0, 'animation', false)
		skeletonNode:setVisible(true)
		image:removeFromParent()

		skeletonNode:registerSpineEventHandler(function(event)
			skeletonNode:setVisible(false)
		end, sp.EventType.ANIMATION_END)
		
		local soundData = AnimCnf[index]
		local soundFile = ''
		if soundData then
			local sound = soundData.sound
			if sound then
				soundFile = sound[0]
			end
		end
		if soundFile ~= "" then
			require("common.Common"):playEffect(soundFile)
		end
	end)
	image:runAction(cc.Sequence:create(moveto, callfunc))
end

--表情互动
function TableLayer:playSkelStartToEndPos(sChairID, eChairID, index)
	self.isOpen = cc.UserDefault:getInstance():getBoolForKey('HHOpenUserEffect', true) --是否接受别人的互动
	
	if GameCommon.meChairID == sChairID then --我发出
		if sChairID == eChairID then
			for i, v in pairs(GameCommon.player or {}) do
				if v.wChairID ~= sChairID then
					self:playSketlAnim(sChairID, v.wChairID, index, v.wChairID)
				end
			end
		else
			self:playSketlAnim(sChairID, eChairID, index)
		end
	else
		if self.isOpen then
			if sChairID == eChairID then
				for i, v in pairs(GameCommon.player or {}) do
					if v.wChairID ~= sChairID then
						self:playSketlAnim(sChairID, v.wChairID, index, v.wChairID)
					end
				end
			else
				self:playSketlAnim(sChairID, eChairID, index)
			end
		end
	end
end

--邀请在线好友
function TableLayer:pleaseOnlinePlayer()
    local dwClubID = GameCommon.tableConfig.dwClubID
    require("common.SceneMgr"):switchOperation(require("app.MyApp"):create(dwClubID):createView("PleaseOnlinePlayerLayer"))
end

return TableLayer