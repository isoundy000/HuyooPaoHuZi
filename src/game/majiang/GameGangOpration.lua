local NetMgr = require("common.NetMgr")
local NetMsgId = require("common.NetMsgId")
local EventMgr = require("common.EventMgr")
local EventType = require("common.EventType")
local Common = require("common.Common")
local Bit = require("common.Bit")
local GameLogic = require("game.majiang.GameLogic")
local GameCommon = require("game.majiang.GameCommon")

local GameGangOpration = class("GameGangOpration",function()
    return ccui.Layout:create()
end)

function GameGangOpration:create(pBuffer,opTtype)
    local view = GameGangOpration.new()
    view:onCreate(pBuffer,opTtype)
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

function GameGangOpration:onEnter()
    
end

function GameGangOpration:onExit()
    if self.uiPanel_opration then
        self.uiPanel_opration:release()
        self.uiPanel_opration = nil
    end
end

function GameGangOpration:onCreate(pBuffer)
    local visibleSize = cc.Director:getInstance():getVisibleSize()
    local csb = cc.CSLoader:createNode("GameLayerMaJiang_Operation.csb")
    self:addChild(csb)
    self.root = csb:getChildByName("Panel_root")
    self.csb = csb
    GameCommon.IsOfHu =0
    local uiListView_Opration = ccui.Helper:seekWidgetByName(self.root,"ListView_Opration")
    uiListView_Opration:removeAllItems()
    uiListView_Opration:setVisible(true)
    local uiListView_OprationType = ccui.Helper:seekWidgetByName(self.root,"ListView_OprationType")
    self.uiPanel_opration = uiListView_OprationType:getItem(0)
    self.uiPanel_opration:retain()
    uiListView_OprationType:removeAllChildren()
    uiListView_OprationType:setVisible(false)    
    self:showOpration(pBuffer)   
    uiListView_Opration:refreshView()
    uiListView_Opration:setPositionX(cc.Director:getInstance():getVisibleSize().width*0.82-uiListView_Opration:getInnerContainerSize().width)
    uiListView_Opration:setDirection(ccui.ScrollViewDir.none)
end

function GameGangOpration:showOpration(pBuffer)

    -- pBuffer.tableChiCard = {} 
    -- pBuffer.tablePengCard = {} 
    -- pBuffer.tableGangCard = {}
    -- pBuffer.tableBuCard = {}
    -- pBuffer.tableHuCard = {}

    local cbOperateCard = pBuffer.cbActionCard
    local cbOperateCode = pBuffer.cbActionMask
    local mUserWCWDActionEx = 0
    local uiListView_Opration = ccui.Helper:seekWidgetByName(self.root,"ListView_Opration")
    --吃
    if pBuffer.tableChiCard[1]~= nil then
        -- if Bit:_and(cbOperateCode,GameCommon.WIK_LEFT) ~= 0 or Bit:_and(cbOperateCode,GameCommon.WIK_CENTER) ~= 0 or Bit:_and(cbOperateCode,GameCommon.WIK_RIGHT) ~= 0 then
        local img = "game/op_chi.png"
        local item = ccui.Button:create(img,img,img)
        uiListView_Opration:pushBackCustomItem(item)        
        Common:addTouchEventListener(item,function()             
            self:dealChi(pBuffer)
        end)
        -- end
    end 
    --碰
    if pBuffer.tablePengCard[1]~= nil then
        local img = "game/op_peng.png"
        local item = ccui.Button:create(img,img,img)
        uiListView_Opration:pushBackCustomItem(item)
        Common:addTouchEventListener(item,function() 
            self:dealPeng(pBuffer)
        end)
    end 
    --补
    if pBuffer.tableBuCard[1]~= nil then
        local img = "game/op_bu.png"
        local item = ccui.Button:create(img,img,img)
        uiListView_Opration:pushBackCustomItem(item)
        Common:addTouchEventListener(item,function() 
            self:dealBu(pBuffer)
        end)
    end
    --杠 
    if pBuffer.tableGangCard[1]~= nil then
        local img = "game/op_gang.png"
        local item = ccui.Button:create(img,img,img)
        uiListView_Opration:pushBackCustomItem(item)
        Common:addTouchEventListener(item,function() 
            self:dealGang(pBuffer)
        end)
    end 
    --胡
    if pBuffer.tableHuCard[1]~= nil then
        local img = "game/op_hu.png"
        local item = ccui.Button:create(img,img,img)
        uiListView_Opration:pushBackCustomItem(item)
        Common:addTouchEventListener(item,function() 
            self:dealHu(pBuffer)
        end)
        GameCommon.IsOfHu = 1
        ccs.ArmatureDataManager:getInstance():addArmatureFileInfo("game/xuanzhuanxing/xuanzhuanxing.ExportJson")
        local armature=ccs.Armature:create("xuanzhuanxing")
        armature:getAnimation():playWithIndex(0)
        item:addChild(armature)
        armature:setPosition(armature:getParent():getContentSize().width/2,armature:getParent():getContentSize().height/2)
    end 

    --必胡

    if pBuffer.tableBiHuCard[1]~= nil then
        local img = "game/op_hu.png"
        local item = ccui.Button:create(img,img,img)
        uiListView_Opration:pushBackCustomItem(item)
        Common:addTouchEventListener(item,function() 
            self:dealBiHu(pBuffer)
        end)
        GameCommon.IsOfHu = 1
        -- if GameCommon.tableConfig.wKindID == 50 or  GameCommon.tableConfig.wKindID == 70 then 
        --     self:runAction(cc.Sequence:create(cc.DelayTime:create(1),cc.CallFunc:create(function(sender,event) self:dealBiHu(pBuffer) end)))
        -- end 
        ccs.ArmatureDataManager:getInstance():addArmatureFileInfo("game/xuanzhuanxing/xuanzhuanxing.ExportJson")
        local armature=ccs.Armature:create("xuanzhuanxing")
        armature:getAnimation():playWithIndex(0)
        item:addChild(armature)
        armature:setPosition(armature:getParent():getContentSize().width/2,armature:getParent():getContentSize().height/2)
    else
        --过
        local img = "game/op_guo.png"
        local item = ccui.Button:create(img,img,img)
        uiListView_Opration:pushBackCustomItem(item)
        Common:addTouchEventListener(item,function() 
            if GameCommon.IsOfHu == 1 then
                require("common.MsgBoxLayer"):create(6,nil,"提示","是否放弃胡牌？",function()
                    NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_C_OPERATE_CARD,"wb",GameCommon.WIK_NULL,0)
                end)
            else                             
                NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_C_OPERATE_CARD,"wb",GameCommon.WIK_NULL,0)
            end       
        self:removeFromParent()
        end)
    end
    for key, var in pairs(uiListView_Opration:getItems()) do
        var:setScale(0.0)
        var:runAction(cc.Sequence:create(cc.Sequence:create(cc.ScaleTo:create(0.2, 0.8))))
    end
end

function GameGangOpration:dealChi(pBuffer)
    local wResumeUser = pBuffer.wResumeUser
    local tableActionCard = pBuffer.tableChiCard
    local uiListView_OprationType = ccui.Helper:seekWidgetByName(self.root,"ListView_OprationType")
    uiListView_OprationType:removeAllChildren()
    uiListView_OprationType:setVisible(true)
    local tableChiCard = {}
    if tableActionCard ~= nil then
        for key, var in pairs(tableActionCard) do    
            table.insert(tableChiCard,#tableChiCard+1,{cbWeaveKind =var.cbOperateCode,cbCenterCard = var.tableActionCard, cbPublicCard = 0,wProvideUser = wResumeUser})
        end
    end
    
    if #tableChiCard == 1 then
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_C_OPERATE_CARD,"wb",tableChiCard[1].cbWeaveKind,tableChiCard[1].cbCenterCard)
        self:removeFromParent()
    else
        local cardScale = 0.8
        local cardWidth = 60 * cardScale
        local cardHeight = 85 * cardScale
        local beganX = cardWidth/2
        local beganY = cardHeight/2
        local stepX = cardWidth*3
        local stepY = 0
        for key, var in pairs(tableChiCard) do
            local item = self.uiPanel_opration:clone()
            uiListView_OprationType:pushBackCustomItem(item)
            local cbCardList = {}
            if Bit:_and(var.cbWeaveKind,GameCommon.WIK_LEFT) ~= 0 then
                cbCardList = {var.cbCenterCard,var.cbCenterCard+1,var.cbCenterCard+2}
            elseif Bit:_and(var.cbWeaveKind,GameCommon.WIK_CENTER) ~= 0 then
                cbCardList = {var.cbCenterCard-1,var.cbCenterCard,var.cbCenterCard+1}
            elseif Bit:_and(var.cbWeaveKind,GameCommon.WIK_RIGHT) ~= 0 then
                cbCardList = {var.cbCenterCard-2,var.cbCenterCard-1,var.cbCenterCard}
            end
            for k, v in pairs(cbCardList) do
                local card = GameCommon:getDiscardCardAndWeaveItemArray(v)     
                item:addChild(card)
                card:setScale(cardScale) 
                card:setPosition(cardWidth/2+(k-1)*cardWidth+28,card:getParent():getContentSize().height/2)
                item:addTouchEventListener(function(sender,event)
                    if event == ccui.TouchEventType.ended then
                        Common:palyButton()
                        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_C_OPERATE_CARD,"wb",var.cbWeaveKind,var.cbCenterCard)              
                        self:removeFromParent()
                    end
                end)
            end
        end
        uiListView_OprationType:refreshView()
        uiListView_OprationType:setPositionX(cc.Director:getInstance():getVisibleSize().width*0.82-uiListView_OprationType:getInnerContainerSize().width)
        uiListView_OprationType:setDirection(ccui.ScrollViewDir.none)
    end
end

function GameGangOpration:dealPeng(pBuffer)
    local wResumeUser = pBuffer.wResumeUser
    local tableActionCard = pBuffer.tablePengCard
    local uiListView_OprationType = ccui.Helper:seekWidgetByName(self.root,"ListView_OprationType")
    uiListView_OprationType:removeAllChildren()
    uiListView_OprationType:setVisible(true)
    local tablePengCard = {}
    if tableActionCard ~= nil then
        for key, var in pairs(tableActionCard) do    
            table.insert(tablePengCard,#tablePengCard+1,{cbWeaveKind =var.cbOperateCode,cbCenterCard = var.tableActionCard, cbPublicCard = 0,wProvideUser = wResumeUser})
        end
    end

    if #tablePengCard == 1 then
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_C_OPERATE_CARD,"wb",tablePengCard[1].cbWeaveKind,tablePengCard[1].cbCenterCard)
        self:removeFromParent()
    else
        local cardScale = 0.8
        local cardWidth = 60 * cardScale
        local cardHeight = 85 * cardScale
        local beganX = cardWidth/2
        local beganY = cardHeight/2
        local stepX = cardWidth*3
        local stepY = 0
        for key, var in pairs(tablePengCard) do
            local item = self.uiPanel_opration:clone()
            uiListView_OprationType:pushBackCustomItem(item)
            local cbCardList = {var.cbCenterCard,var.cbCenterCard,var.cbCenterCard}
            for k, v in pairs(cbCardList) do
                local card = GameCommon:getDiscardCardAndWeaveItemArray(v)     
                item:addChild(card)
                card:setScale(cardScale) 
                card:setPosition(cardWidth/2+(k-1)*cardWidth+28,card:getParent():getContentSize().height/2)
                item:addTouchEventListener(function(sender,event)
                    if event == ccui.TouchEventType.ended then
                        Common:palyButton()
                        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_C_OPERATE_CARD,"wb",var.cbWeaveKind,var.cbCenterCard)
                        self:removeFromParent()
                    end
                end)
            end
        end
        uiListView_OprationType:refreshView()
        uiListView_OprationType:setPositionX(cc.Director:getInstance():getVisibleSize().width*0.82-uiListView_OprationType:getInnerContainerSize().width)
        uiListView_OprationType:setDirection(ccui.ScrollViewDir.none)
    end
end

function GameGangOpration:dealBu(pBuffer)
    local wResumeUser = pBuffer.wResumeUser
    local tableActionCard = pBuffer.tableBuCard
    local uiListView_OprationType = ccui.Helper:seekWidgetByName(self.root,"ListView_OprationType")
    uiListView_OprationType:removeAllChildren()
    uiListView_OprationType:setVisible(true)
    local tableWeaveItem = {}
    if tableActionCard ~= nil then
        for key, var in pairs(tableActionCard) do    
            table.insert(tableWeaveItem,#tableWeaveItem+1,{cbWeaveKind =var.cbOperateCode,cbCenterCard = var.tableActionCard, cbPublicCard = 0,wProvideUser = wResumeUser})
        end
    end
    if #tableWeaveItem == 1 then
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_C_OPERATE_CARD,"wb",tableWeaveItem[1].cbWeaveKind,tableWeaveItem[1].cbCenterCard)
        self:removeFromParent()
    else
        local cardScale = 0.8
        local cardWidth = 60 * cardScale
        local cardHeight = 85 * cardScale
        local beganX = cardWidth/2
        local beganY = cardHeight/2
        local stepX = cardWidth*3
        local stepY = 0
        for key, var in pairs(tableWeaveItem) do
            local item = self.uiPanel_opration:clone()
            uiListView_OprationType:pushBackCustomItem(item)
            for i = 1, 4 do
                local card = nil
                if var.cbPublicCard == 2 and i < 4 then
                    card = GameCommon:getDiscardCardAndWeaveItemArray(0)
                else
                    card = GameCommon:getDiscardCardAndWeaveItemArray(var.cbCenterCard)     
                end
                item:addChild(card)
                if i == 4 then
                    card:setScale(cardScale) 
                    card:setPosition(cardWidth/2+(2-1)*cardWidth+28,card:getParent():getContentSize().height/2+10)
                else
                    card:setScale(cardScale) 
                    card:setPosition(cardWidth/2+(i-1)*cardWidth+28,card:getParent():getContentSize().height/2)
                end
                item:addTouchEventListener(function(sender,event)
                    if event == ccui.TouchEventType.ended then
                        Common:palyButton()
                        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_C_OPERATE_CARD,"wb",var.cbWeaveKind,var.cbCenterCard)
                        self:removeFromParent()
                    end
                end)
            end
        end
        uiListView_OprationType:refreshView()
        uiListView_OprationType:setPositionX(cc.Director:getInstance():getVisibleSize().width*0.82-uiListView_OprationType:getInnerContainerSize().width)
        uiListView_OprationType:setDirection(ccui.ScrollViewDir.none)
    end
end

function GameGangOpration:dealGang(pBuffer)
    local wResumeUser = pBuffer.wResumeUser
    local tableActionCard = pBuffer.tableGangCard
    local uiListView_OprationType = ccui.Helper:seekWidgetByName(self.root,"ListView_OprationType")
    uiListView_OprationType:removeAllChildren()
    uiListView_OprationType:setVisible(true)
    local tableWeaveItem = {}
    if tableActionCard ~= nil then
        for key, var in pairs(tableActionCard) do    
            table.insert(tableWeaveItem,#tableWeaveItem+1,{cbWeaveKind =var.cbOperateCode,cbCenterCard = var.tableActionCard, cbPublicCard = 0,wProvideUser = wResumeUser})
        end
    end
    if #tableWeaveItem == 1 then
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_C_OPERATE_CARD,"wb",tableWeaveItem[1].cbWeaveKind,tableWeaveItem[1].cbCenterCard)
        self:removeFromParent()
    else
        local cardScale = 0.8
        local cardWidth = 60 * cardScale
        local cardHeight = 85 * cardScale
        local beganX = cardWidth/2
        local beganY = cardHeight/2
        local stepX = cardWidth*3
        local stepY = 0
        for key, var in pairs(tableWeaveItem) do
            local item = self.uiPanel_opration:clone()
            uiListView_OprationType:pushBackCustomItem(item)
            for i = 1, 4 do
                local card = nil
                if var.cbPublicCard == 2 and i < 4 then
                    card = GameCommon:getDiscardCardAndWeaveItemArray(0)
                else
                    card = GameCommon:getDiscardCardAndWeaveItemArray(var.cbCenterCard)     
                end
                item:addChild(card)
                if i == 4 then
                    card:setScale(cardScale) 
                    card:setPosition(cardWidth/2+(2-1)*cardWidth+28,card:getParent():getContentSize().height/2+10)
                else
                    card:setScale(cardScale) 
                    card:setPosition(cardWidth/2+(i-1)*cardWidth+28,card:getParent():getContentSize().height/2)
                end
                item:addTouchEventListener(function(sender,event)
                    if event == ccui.TouchEventType.ended then
                        Common:palyButton()
                        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_C_OPERATE_CARD,"wb",var.cbWeaveKind,var.cbCenterCard)
                        self:removeFromParent()
                    end
                end)
            end
        end
        uiListView_OprationType:refreshView()
        uiListView_OprationType:setPositionX(cc.Director:getInstance():getVisibleSize().width*0.82-uiListView_OprationType:getInnerContainerSize().width)
        uiListView_OprationType:setDirection(ccui.ScrollViewDir.none)
    end
end

function GameGangOpration:dealHu(pBuffer)
    local wResumeUser = pBuffer.wResumeUser
    local tableActionCard = pBuffer.tableHuCard
    local uiListView_OprationType = ccui.Helper:seekWidgetByName(self.root,"ListView_OprationType")
    uiListView_OprationType:removeAllChildren()
    uiListView_OprationType:setVisible(true)
    local tableHuCard = {}
    if tableActionCard ~= nil then
        for key, var in pairs(tableActionCard) do    
            table.insert(tableHuCard,#tableHuCard+1,{cbWeaveKind =var.cbOperateCode,cbCenterCard = var.tableActionCard, cbPublicCard = 0,wProvideUser = wResumeUser})
        end
    end

    if #tableHuCard == 1 then
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_C_OPERATE_CARD,"wb",GameCommon.WIK_CHI_HU,tableHuCard[1].cbCenterCard)
        self:removeFromParent()
    else
        local cardScale = 0.8
        local cardWidth = 60 * cardScale
        local cardHeight = 85 * cardScale
        local beganX = cardWidth/2
        local beganY = cardHeight/2
        local stepX = cardWidth*3
        local stepY = 0
        for key, var in pairs(tableHuCard) do
            local item = self.uiPanel_opration:clone()
            uiListView_OprationType:pushBackCustomItem(item)
            local card = GameCommon:getDiscardCardAndWeaveItemArray(var.cbCenterCard)     
            item:addChild(card)
            card:setScale(cardScale) 
            card:setPosition(cardWidth/2+(k-1)*cardWidth+28,card:getParent():getContentSize().height/2)
            item:addTouchEventListener(function(sender,event)
                if event == ccui.TouchEventType.ended then
                    Common:palyButton()
                    NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_C_OPERATE_CARD,"wb",GameCommon.WIK_CHI_HU,var.cbCenterCard)
                    self:removeFromParent()
                end
            end) 
        end
        uiListView_OprationType:refreshView()
        uiListView_OprationType:setPositionX(cc.Director:getInstance():getVisibleSize().width*0.82-uiListView_OprationType:getInnerContainerSize().width)
        uiListView_OprationType:setDirection(ccui.ScrollViewDir.none)
    end
   -- self:removeFromParent()    
end

function GameGangOpration:dealBiHu(pBuffer)
    local wResumeUser = pBuffer.wResumeUser
    local tableActionCard = pBuffer.tableBiHuCard
    local uiListView_OprationType = ccui.Helper:seekWidgetByName(self.root,"ListView_OprationType")
    uiListView_OprationType:removeAllChildren()
    uiListView_OprationType:setVisible(true)
    local tableHuCard = {}
    if tableActionCard ~= nil then
        for key, var in pairs(tableActionCard) do    
            table.insert(tableHuCard,#tableHuCard+1,{cbWeaveKind =var.cbOperateCode,cbCenterCard = var.tableActionCard, cbPublicCard = 0,wProvideUser = wResumeUser})
        end
    end

    NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_C_OPERATE_CARD,"wb",GameCommon.WIK_BIHU,tableHuCard[1].cbCenterCard)
    
    self:removeFromParent()  
end

return GameGangOpration