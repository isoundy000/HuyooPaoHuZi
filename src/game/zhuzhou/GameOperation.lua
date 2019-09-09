local NetMgr = require("common.NetMgr")
local NetMsgId = require("common.NetMsgId")
local EventMgr = require("common.EventMgr")
local EventType = require("common.EventType")
local Common = require("common.Common")
local Bit = require("common.Bit")
local GameCommon = require("game.zhuzhou.GameCommon")
local GameLogic = require("game.zhuzhou.GameLogic")

local GameOperation = class("GameOperation",function()
    return ccui.Layout:create()
end)

function GameOperation:create(opType,cbOperateCode,cbOperateCard,cbCardIndex,cbSubOperateCode)
    local view = GameOperation.new()
    view:onCreate(opType,cbOperateCode,cbOperateCard,cbCardIndex,cbSubOperateCode)
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

function GameOperation:onEnter()

end

function GameOperation:onExit()
    if self.uiPanel_item ~= nil then
        self.uiPanel_item:release()
        self.uiPanel_item = nil
    end
    if self.Button_operation ~= nil then
        self.Button_operation:release()
        self.Button_operation = nil
    end
    if self.uiListView_list ~= nil then
        self.uiListView_list:release()
        self.uiListView_list = nil
    end
    
end

function GameOperation:onCleanup()

end

function GameOperation:onCreate(opType,cbOperateCode,cbOperateCard,cbCardIndex,cbSubOperateCode)
    local visibleSize = cc.Director:getInstance():getVisibleSize()
    local csb = cc.CSLoader:createNode("GameLayerPengHuZhi_Operation.csb")
    self:addChild(csb)
    self.root = csb:getChildByName("Panel_root")
    self.csb = csb
    print("操作提示")
    printInfo(cbOperateCode)
    printInfo(cbOperateCard)
    printInfo(cbCardIndex)
    printInfo(cbSubOperateCode)
    self.cbOperateCode = cbOperateCode
    self.cbOperateCard = cbOperateCard
    self.cbCardIndex = cbCardIndex
    self.cbSubOperateCode = cbSubOperateCode
    self.operateClientData = {}
    
    local uiPanel_operation = ccui.Helper:seekWidgetByName(self.root,"Panel_operation")    
    local uiButton_chi = ccui.Helper:seekWidgetByName(self.root,"Button_chi")
    local uiButton_peng = ccui.Helper:seekWidgetByName(self.root,"Button_peng")
    local uiButton_hu = ccui.Helper:seekWidgetByName(self.root,"Button_hu")
    local uiButton_guo = ccui.Helper:seekWidgetByName(self.root,"Button_guo")
    local uiPanel_bg = ccui.Helper:seekWidgetByName(self.root,"Panel_bg")

    uiButton_chi:setBright(false)
    uiButton_chi:setEnabled(false) 
    uiButton_chi:setColor(cc.c3b(99,99,99))
    uiButton_peng:setBright(false)
    uiButton_peng:setEnabled(false) 
    uiButton_peng:setColor(cc.c3b(99,99,99))
    uiButton_hu:setBright(false)
    uiButton_hu:setEnabled(false) 
    uiButton_hu:setColor(cc.c3b(99,99,99))
    uiButton_guo:setBright(false)
    uiButton_guo:setEnabled(false) 
    uiButton_guo:setColor(cc.c3b(99,99,99))


    uiPanel_bg:setVisible(false)
    local uiListView_panel = ccui.Helper:seekWidgetByName(self.root,"ListView_panel")
    uiListView_panel:setVisible(false)
    self.uiListView_list = ccui.Helper:seekWidgetByName(self.root,"ListView_list")
    self.uiListView_list:retain()
    self.uiPanel_item = ccui.Helper:seekWidgetByName(self.root,"Panel_item")
    self.uiPanel_item:retain()
    local uiListView_card = ccui.Helper:seekWidgetByName(self.root,"ListView_card")
    self.uiListView_list:removeAllItems()
    uiListView_panel:removeAllItems()
    GameCommon.IsOfHu =0

    if opType == 1 then
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_C_ADD_BASE,"o",false) 
        self:removeFromParent()
    else
        if (Bit:_and(cbOperateCode,GameCommon.ACK_BIHU) ~= 0) then    
            if  GameCommon.tableConfig.wKindID == 39 or GameCommon.tableConfig.wKindID == 16  then       
                self:runAction(cc.Sequence:create(cc.DelayTime:create(1),cc.CallFunc:create(function(sender,event)  self:dealHu() uiPanel_operation:setVisible(false) end)))      
            end 
            GameCommon.IsOfHu = 1
            uiButton_hu:setColor(cc.c3b(255,255,255))
            uiButton_hu:setBright(true)
            uiButton_hu:setEnabled(true) 
            uiButton_hu:addTouchEventListener(function(sender,event) 
                if event == ccui.TouchEventType.ended then 
                    Common:palyButton() 
                    self:dealHu()
                end 
            end)
        else
            if (Bit:_and(cbOperateCode,GameCommon.ACK_CHI) ~= 0) or (Bit:_and(cbOperateCode,GameCommon.ACK_CHI_EX) ~= 0) then
                if Bit:_and(cbOperateCode,GameCommon.ACK_CHI_EX) ~= 0 then
                    self.operateClientData.cbOperateCode = GameCommon.ACK_CHI_EX
                else
                    self.operateClientData.cbOperateCode = GameCommon.ACK_CHI
                end
                uiButton_chi:setColor(cc.c3b(255,255,255))
                uiButton_chi:setBright(true)
                uiButton_chi:setEnabled(true) 
                uiButton_chi:addTouchEventListener(function(sender,event) 
                    if event == ccui.TouchEventType.ended then 
                        Common:palyButton() 
                        if GameCommon.IsOfHu == 1 then
                            require("common.MsgBoxLayer"):create(6,nil,"提示","是否放弃胡牌？",function()
                                self:dealChi()
                            end)
                        else                             
                            self:dealChi()
                        end   
                    end 
                end)
        
            end
            if Bit:_and(cbOperateCode,GameCommon.ACK_PENG) ~= 0  then
                uiButton_peng:setColor(cc.c3b(255,255,255))
                uiButton_peng:setBright(true)
                uiButton_peng:setEnabled(true) 

                uiButton_peng:addTouchEventListener(function(sender,event) 
      
                    if event == ccui.TouchEventType.ended then 
                        Common:palyButton() 
                        if GameCommon.IsOfHu == 1 then
                            require("common.MsgBoxLayer"):create(6,nil,"提示","是否放弃胡牌？",function()
                                self:dealPen()
                            end)
                        else                            
                            self:dealPen()
                        end                       
                    end 
                end)
            end
            if Bit:_and(cbOperateCode,GameCommon.ACK_CHIHU) ~= 0  then
                GameCommon.IsOfHu = 1
                uiButton_hu:setColor(cc.c3b(255,255,255))
                uiButton_hu:setBright(true)
                uiButton_hu:setEnabled(true) 
                uiButton_hu:addTouchEventListener(function(sender,event) 
                    if event == ccui.TouchEventType.ended then 
                        Common:palyButton() 
                        self:dealHu()
                    end 
                end)
                -- ccs.ArmatureDataManager:getInstance():addArmatureFileInfo("game/xuanzhuanxing/xuanzhuanxing.ExportJson")
                -- local armature=ccs.Armature:create("xuanzhuanxing")
                -- armature:getAnimation():playWithIndex(0)
                -- uiButton_hu:addChild(armature)
                -- armature:setPosition(armature:getParent():getContentSize().width/2,armature:getParent():getContentSize().height/2)
            end       
            if cbOperateCode ~= GameCommon.ACK_PAO then
                uiButton_guo:setColor(cc.c3b(255,255,255))
                uiButton_guo:setBright(true)
                uiButton_guo:setEnabled(true) 
                uiButton_guo:addTouchEventListener(function(sender,event) 
                    if event == ccui.TouchEventType.ended then 
                        Common:palyButton() 
                        if GameCommon.IsOfHu == 1 then
                            require("common.MsgBoxLayer"):create(6,nil,"提示","是否放弃胡牌？",function()
                                self:dealGuo()
                            end)
                        else                             
                            self:dealGuo()
                        end   
                    end 
                end)
            end
        end
    end
end

function GameOperation:dealChi()
    local uiListView_panel = ccui.Helper:seekWidgetByName(self.root,"ListView_panel")
    uiListView_panel:removeAllItems()
	uiListView_panel:setVisible(true)
    local uiPanel_bg = ccui.Helper:seekWidgetByName(self.root,"Panel_bg")
    uiPanel_bg:setVisible(true)    
    uiPanel_bg:addTouchEventListener(function(sender,event)
        if event == ccui.TouchEventType.ended then
            uiPanel_bg:setVisible(false)      
            uiListView_panel:setVisible(false)   
        end
    end) 

    --第一阶段
    local uiListViewList1 = nil
    local cbCardIndex1 = clone(self.cbCardIndex)
    local chiCounts , pChiCardInfo1 = GameLogic:GetActionChiCard(cbCardIndex1,self.cbOperateCard)
    if chiCounts > 0 then
        uiListViewList1 = self.uiListView_list:clone()
        uiListView_panel:pushBackCustomItem(uiListViewList1)
    end
    for i = 1 , chiCounts  do
        local item = self.uiPanel_item:clone()
        uiListViewList1:pushBackCustomItem(item)
        local uiButton_chi = ccui.Helper:seekWidgetByName(item,"Button_chi")
        uiButton_chi.cardIndex = {}
        local uiListView_card = ccui.Helper:seekWidgetByName(item,"ListView_card")
        
        for j = 1 , 3 do
            local card = GameCommon:GetCardHand(pChiCardInfo1[i].cbCardData[1][j])
            uiButton_chi.cardIndex[j] = pChiCardInfo1[i].cbCardData[1][j]
            uiButton_chi.cbChiKind = pChiCardInfo1[i].cbChiKind
            if uiButton_chi.cardIndex[j] == self.cbOperateCard then      
                if j == 1 then  
                    card:setColor(cc.c3b(150,150,150))                  
                elseif j == 2 then
                  if uiButton_chi.cardIndex[j-1] ~= uiButton_chi.cardIndex[j] then 
                        card:setColor(cc.c3b(150,150,150))  
                  end   
                else 
                    if uiButton_chi.cardIndex[j-1] ~= uiButton_chi.cardIndex[j] and uiButton_chi.cardIndex[j-2] ~= uiButton_chi.cardIndex[j]  then 
                        card:setColor(cc.c3b(150,150,150))  
                    end    
                end                
            end 
          
            if card ~= nil then
                card:setScale(0.9,0.8)
                uiListView_card:pushBackCustomItem(card)
            end
        end
        uiButton_chi:setPressedActionEnabled(true)
        uiButton_chi:addTouchEventListener(function(sender,event) 
            if event == ccui.TouchEventType.ended then 
                Common:palyButton() 
                --移除UI
                local items = uiListView_panel:getItems()
                for i = 2 , #items do
                    uiListView_panel:removeItem(1)
                end
                --变个颜色
                local items = uiListViewList1:getItems()
                for key, var in pairs(items) do
                    local btn = ccui.Helper:seekWidgetByName(var,"Button_chi")
                    if btn == sender then
                        btn:loadTextures("zipai/table/zipai_table_opbg.png","zipai/table/zipai_table_opbg.png","zipai/table/zipai_table_opbg.png")                       
                    else
                        if  btn ~= nil then 
                            btn:loadTextures("zipai/table/zipai_table_op.png","zipai/table/zipai_table_op.png","zipai/table/zipai_table_op.png")
                        end
                    end
                end
                --第二阶段
                self.operateClientData.cbChiKind = sender.cbChiKind
                self.operateClientData.cbBiKind1 = 0
                self.operateClientData.cbBiKind2 = 0
                local uiListViewList2 = nil
                local cbCardIndex2 = clone(cbCardIndex1)
                for i = 1 , 3 do
                    local idx = GameLogic:SwitchToCardIndex(sender.cardIndex[i])
                    cbCardIndex2[idx] = cbCardIndex2[idx] - 1
                end
                
                local chiCounts , pChiCardInfo2 = GameLogic:GetActionChiCard(cbCardIndex2,self.cbOperateCard)
                if chiCounts > 0 then
                    uiListViewList2 = self.uiListView_list:clone()
                    uiListView_panel:pushBackCustomItem(uiListViewList2)
                else
                    printInfo("发送吃的牌型")
                    if GameCommon.tableConfig.wKindID == 33 or GameCommon.tableConfig.wKindID == 34 or GameCommon.tableConfig.wKindID == 35 or GameCommon.tableConfig.wKindID == 36 or GameCommon.tableConfig.wKindID == 32 or GameCommon.tableConfig.wKindID == 37 or GameCommon.tableConfig.wKindID == 27 or GameCommon.tableConfig.wKindID == 31 then
                        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_C_OPERATE_CARD,"bwwbb",self.operateClientData.cbChiKind,self.operateClientData.cbOperateCode,0,self.operateClientData.cbBiKind1,self.operateClientData.cbBiKind2)
                    else
                        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_C_OPERATE_CARD,"bwbb",self.operateClientData.cbChiKind,self.operateClientData.cbOperateCode,self.operateClientData.cbBiKind1,self.operateClientData.cbBiKind2)
                    end
                    self:removeFromParent()
                end
                for i = 1 , chiCounts  do
                    local item = self.uiPanel_item:clone()

                    uiListViewList2:pushBackCustomItem(item)
                    local uiButton_chi = ccui.Helper:seekWidgetByName(item,"Button_chi")
                    uiButton_chi.cardIndex = {}
                    local uiListView_card = ccui.Helper:seekWidgetByName(item,"ListView_card")
                    for j = 1 , 3 do
                        local card = GameCommon:GetCardHand(pChiCardInfo2[i].cbCardData[1][j])
                        uiButton_chi.cardIndex[j] = pChiCardInfo2[i].cbCardData[1][j]
                        uiButton_chi.cbChiKind = pChiCardInfo2[i].cbChiKind                        
                        if uiButton_chi.cardIndex[j] == self.cbOperateCard then      
                            if j == 1 then  
                                card:setColor(cc.c3b(150,150,150))                  
                            elseif j == 2 then
                                if uiButton_chi.cardIndex[j-1] ~= uiButton_chi.cardIndex[j] then 
                                    card:setColor(cc.c3b(150,150,150))  
                                end   
                            else 
                                if uiButton_chi.cardIndex[j-1] ~= uiButton_chi.cardIndex[j] and uiButton_chi.cardIndex[j-2] ~= uiButton_chi.cardIndex[j]  then 
                                    card:setColor(cc.c3b(150,150,150))  
                                end    
                            end                
                        end 
                        
                        if card ~= nil then
                			card:setScale(0.9,0.8)
                            uiListView_card:pushBackCustomItem(card)
                        end
                    end
                    uiButton_chi:setPressedActionEnabled(true)
                    uiButton_chi:addTouchEventListener(function(sender,event) 
                        if event == ccui.TouchEventType.ended then 
                            Common:palyButton() 
                            
                            --移除UI
                            local items = uiListView_panel:getItems()
                            for i = 3 , #items do
                                uiListView_panel:removeItem(2)
                            end
                            --变个颜色
                            local items = uiListViewList2:getItems()
                            for key, var in pairs(items) do
                                local btn = ccui.Helper:seekWidgetByName(var,"Button_chi")
                                if btn == sender then
                                    btn:loadTextures("zipai/table/zipai_table_opbg.png","zipai/table/zipai_table_opbg.png","zipai/table/zipai_table_opbg.png")  
                                else
                                    if  btn ~= nil then 
                                        btn:loadTextures("zipai/table/zipai_table_op.png","zipai/table/zipai_table_op.png","zipai/table/zipai_table_op.png")  
                                    end 
                                end
                            end
                            --第三阶段
                            self.operateClientData.cbBiKind1 = sender.cbChiKind
                            self.operateClientData.cbBiKind2 = 0
                            local uiListViewList3 = nil
                            local cbCardIndex3 = clone(cbCardIndex2)
                            for i = 1 , 3 do
                                local idx = GameLogic:SwitchToCardIndex(sender.cardIndex[i])
                                cbCardIndex3[idx] = cbCardIndex3[idx] - 1
                            end

                            local chiCounts , pChiCardInfo3 = GameLogic:GetActionChiCard(cbCardIndex3,self.cbOperateCard)
                            if chiCounts > 0 then
                                uiListViewList3 = self.uiListView_list:clone()
                                uiListView_panel:pushBackCustomItem(uiListViewList3)
                            else
                                --发送吃的牌型
                                if GameCommon.tableConfig.wKindID == 33 or GameCommon.tableConfig.wKindID == 34 or GameCommon.tableConfig.wKindID == 35 or GameCommon.tableConfig.wKindID == 36 or GameCommon.tableConfig.wKindID == 32 or GameCommon.tableConfig.wKindID == 37 or GameCommon.tableConfig.wKindID == 27 or GameCommon.tableConfig.wKindID == 31 then
                                    NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_C_OPERATE_CARD,"bwwbb",self.operateClientData.cbChiKind,self.operateClientData.cbOperateCode,0,self.operateClientData.cbBiKind1,self.operateClientData.cbBiKind2)
                                else
                                    NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_C_OPERATE_CARD,"bwbb",self.operateClientData.cbChiKind,self.operateClientData.cbOperateCode,self.operateClientData.cbBiKind1,self.operateClientData.cbBiKind2)
                                end
                                self:removeFromParent()
                            end
                            for i = 1 , chiCounts  do
                                local item = self.uiPanel_item:clone()
                                uiListViewList3:pushBackCustomItem(item)
                                local uiButton_chi = ccui.Helper:seekWidgetByName(item,"Button_chi")
                                uiButton_chi.cardIndex = {}
                                local uiListView_card = ccui.Helper:seekWidgetByName(item,"ListView_card")
                                for j = 1 , 3 do
                                    local card = GameCommon:GetCardHand(pChiCardInfo3[i].cbCardData[1][j])
                                    uiButton_chi.cardIndex[j] = pChiCardInfo3[i].cbCardData[1][j]
                                    uiButton_chi.cbChiKind = pChiCardInfo3[i].cbChiKind
                                    
                                    if uiButton_chi.cardIndex[j] == self.cbOperateCard then      
                                        if j == 1 then  
                                            card:setColor(cc.c3b(150,150,150))                  
                                        elseif j == 2 then
                                            if uiButton_chi.cardIndex[j-1] ~= uiButton_chi.cardIndex[j] then 
                                                card:setColor(cc.c3b(150,150,150))  
                                            end   
                                        else 
                                            if uiButton_chi.cardIndex[j-1] ~= uiButton_chi.cardIndex[j] and uiButton_chi.cardIndex[j-2] ~= uiButton_chi.cardIndex[j]  then 
                                                card:setColor(cc.c3b(150,150,150))  
                                            end    
                                        end                
                                    end 
                                    
                                    if card ~= nil then
                						card:setScale(0.9,0.8)
                                        uiListView_card:pushBackCustomItem(card)
                                    end
                                end
                                uiButton_chi:setPressedActionEnabled(true)
                                uiButton_chi:addTouchEventListener(function(sender,event) 
                                    if event == ccui.TouchEventType.ended then 
                                        Common:palyButton() 
                                        self.operateClientData.cbBiKind2 = sender.cbChiKind
                                        printInfo("发送吃的牌型")
                                        if GameCommon.tableConfig.wKindID == 33 or GameCommon.tableConfig.wKindID == 34 or GameCommon.tableConfig.wKindID == 35 or GameCommon.tableConfig.wKindID == 36 or GameCommon.tableConfig.wKindID == 32 or GameCommon.tableConfig.wKindID == 37 or GameCommon.tableConfig.wKindID == 27 or GameCommon.tableConfig.wKindID == 31 then
                                            NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_C_OPERATE_CARD,"bwwbb",self.operateClientData.cbChiKind,self.operateClientData.cbOperateCode,0,self.operateClientData.cbBiKind1,self.operateClientData.cbBiKind2)
                                        else
                                            NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_C_OPERATE_CARD,"bwbb",self.operateClientData.cbChiKind,self.operateClientData.cbOperateCode,self.operateClientData.cbBiKind1,self.operateClientData.cbBiKind2)
                                        end
                                        self:removeFromParent()
                                    end 
                                end)
                            end  
                            if uiListViewList3 ~= nil then
                                uiListViewList3:refreshView()
                                uiListViewList3:setContentSize(cc.size(uiListViewList3:getInnerContainerSize().width,uiListViewList3:getInnerContainerSize().height))   
                                if #uiListView_panel:getItems() > 0 then
                                    local width = 0
                                    for key, var in pairs(uiListView_panel:getItems()) do
                                        width = width + var:getContentSize().width
                                    end
                                    uiListView_panel:refreshView()
                                    uiListView_panel:setContentSize(cc.size(width,uiListView_panel:getInnerContainerSize().height))
                                    uiListView_panel:setPositionX(cc.Director:getInstance():getVisibleSize().width/2)
                                else
                                    uiListView_panel:setVisible(false)
                                    print("吃牌错误!")
                                end
                            end
                        end 
                    end)
                end  
                if uiListViewList2 ~= nil then
                    uiListViewList2:refreshView()
                    uiListViewList2:setContentSize(cc.size(uiListViewList2:getInnerContainerSize().width,uiListViewList2:getInnerContainerSize().height))   
                    if #uiListView_panel:getItems() > 0 then
                        local width = 0
                        for key, var in pairs(uiListView_panel:getItems()) do
                            width = width + var:getContentSize().width
                        end
                        uiListView_panel:refreshView()
                        uiListView_panel:setContentSize(cc.size(width,uiListView_panel:getInnerContainerSize().height))
                        uiListView_panel:setPositionX(cc.Director:getInstance():getVisibleSize().width/2)
                    else
                        uiListView_panel:setVisible(false)
                        print("吃牌错误!")
                    end
                end
                
            end 
        end)
    end  
    if uiListViewList1 ~= nil then
        uiListViewList1:refreshView()
        uiListViewList1:setContentSize(cc.size(uiListViewList1:getInnerContainerSize().width,uiListViewList1:getInnerContainerSize().height))    
        if #uiListView_panel:getItems() > 0 then
            local width = 0
            for key, var in pairs(uiListView_panel:getItems()) do
                width = width + var:getContentSize().width
            end
            uiListView_panel:refreshView()
            uiListView_panel:setContentSize(cc.size(width,uiListView_panel:getInnerContainerSize().height))
            uiListView_panel:setPositionX(cc.Director:getInstance():getVisibleSize().width/2)
        else
            uiListView_panel:setVisible(false)
            print("吃牌错误!")
        end
    end

end

function GameOperation:dealPen()
    --发送消息
    if GameCommon.tableConfig.wKindID == 33 or GameCommon.tableConfig.wKindID == 34 or GameCommon.tableConfig.wKindID == 35 or GameCommon.tableConfig.wKindID == 36 or GameCommon.tableConfig.wKindID == 32 or GameCommon.tableConfig.wKindID == 37 or GameCommon.tableConfig.wKindID == 27 or GameCommon.tableConfig.wKindID == 31 then
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_C_OPERATE_CARD,"bwwbb",0,128,0,0,0)
    else
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_C_OPERATE_CARD,"bwbb",0,128,0,0)
    end
    
    self:removeFromParent()
end

function GameOperation:dealHu()
    --发送消息
    if GameCommon.tableConfig.wKindID == 33 or GameCommon.tableConfig.wKindID == 34 or GameCommon.tableConfig.wKindID == 35 or GameCommon.tableConfig.wKindID == 36 or GameCommon.tableConfig.wKindID == 32 or GameCommon.tableConfig.wKindID == 37 or GameCommon.tableConfig.wKindID == 27 or GameCommon.tableConfig.wKindID == 31 then
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_C_OPERATE_CARD,"bwwbb",0,256,0,0,0)
    else
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_C_OPERATE_CARD,"bwbb",0,256,0,0)
    end
    
    self:removeFromParent()
end

function GameOperation:dealGuo()
    --发送消息
    if GameCommon.tableConfig.wKindID == 33 or GameCommon.tableConfig.wKindID == 34 or GameCommon.tableConfig.wKindID == 35 or GameCommon.tableConfig.wKindID == 36 or GameCommon.tableConfig.wKindID == 32 or GameCommon.tableConfig.wKindID == 37 or GameCommon.tableConfig.wKindID == 27 or GameCommon.tableConfig.wKindID == 31 then
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_C_OPERATE_CARD,"bwwbb",self.cbOperateCard,0,0,0,0)
    else
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_C_OPERATE_CARD,"bwbb",self.cbOperateCard,0,0,0)
    end
    
    self:removeFromParent()
end

function GameOperation:dealWd()
    --发送消息
    if GameCommon.tableConfig.wKindID == 33 or GameCommon.tableConfig.wKindID == 34 or GameCommon.tableConfig.wKindID == 35 or GameCommon.tableConfig.wKindID == 36 or GameCommon.tableConfig.wKindID == 32 or GameCommon.tableConfig.wKindID == 37 or GameCommon.tableConfig.wKindID == 27 or GameCommon.tableConfig.wKindID == 31 then
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_C_OPERATE_CARD,"bwwbb",0,8,0x01,0,0)
    else
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_C_OPERATE_CARD,"bwbb",0,8,0,0)
    end
    
    self:removeFromParent()
end

function GameOperation:dealWc()
    --发送消息
    if GameCommon.tableConfig.wKindID == 33 or GameCommon.tableConfig.wKindID == 34 or GameCommon.tableConfig.wKindID == 35 or GameCommon.tableConfig.wKindID == 36 or GameCommon.tableConfig.wKindID == 32 or GameCommon.tableConfig.wKindID == 37 or GameCommon.tableConfig.wKindID == 27 or GameCommon.tableConfig.wKindID == 31 then
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_C_OPERATE_CARD,"bwwbb",0,8,0x02,0,0)
    else
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_C_OPERATE_CARD,"bwbb",0,16,0,0)
    end
    
    self:removeFromParent()
end
function GameOperation:deal3Wc()
    --发送消息
    if GameCommon.tableConfig.wKindID == 33 or GameCommon.tableConfig.wKindID == 34 or GameCommon.tableConfig.wKindID == 35 or GameCommon.tableConfig.wKindID == 36 or GameCommon.tableConfig.wKindID == 32 or GameCommon.tableConfig.wKindID == 37 or GameCommon.tableConfig.wKindID == 27 or GameCommon.tableConfig.wKindID == 31 then
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_C_OPERATE_CARD,"bwwbb",0,8,0x04,0,0)
    else

    end
    
    self:removeFromParent()
end

return GameOperation

