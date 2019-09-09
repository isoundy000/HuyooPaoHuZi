local NetMgr = require("common.NetMgr")
local NetMsgId = require("common.NetMsgId")
local EventMgr = require("common.EventMgr")
local EventType = require("common.EventType")
local Common = require("common.Common")
local Bit = require("common.Bit")
local GameCommon = require("game.yongzhou.GameCommon")
local GameLogic = require("game.yongzhou.GameLogic")

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
    local csb = cc.CSLoader:createNode("YZGameLayer_Operation.csb")
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
    self.Button_operation = ccui.Helper:seekWidgetByName(self.root,"Button_operation")
    self.Button_operation:retain()
    uiPanel_operation:removeAllChildren()
    local uiPanel_bg = ccui.Helper:seekWidgetByName(self.root,"Panel_bg")
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
        -- local item = self.Button_operation:clone()   -- 五福报警按钮及其功能
        -- local textureName = "game/op_wufu.png"
        -- local texture = cc.TextureCache:getInstance():addImage(textureName)
        -- item:loadTextures(textureName,textureName,textureName)
        -- item:setContentSize(texture:getContentSizeInPixels())  
        -- item:setPressedActionEnabled(true)
        -- uiPanel_operation:addChild(item)
        -- item:addTouchEventListener(function(sender,event) 
        --     if event == ccui.TouchEventType.ended then 
        --         Common:palyButton() 
        --         NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_C_ADD_BASE,"o",true) 
        --         self:removeFromParent()
        --     end 
        -- end)
        -- local item = self.Button_operation:clone() 
        -- local textureName = "game/op_wufuno.png"
        -- local texture = cc.TextureCache:getInstance():addImage(textureName)
        -- item:loadTextures(textureName,textureName,textureName)
        -- item:setContentSize(texture:getContentSizeInPixels())  
        -- item:setPressedActionEnabled(true)
        -- uiPanel_operation:addChild(item)
        -- item:addTouchEventListener(function(sender,event) 
        --     if event == ccui.TouchEventType.ended then 
        --         Common:palyButton() 
        --         NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_C_ADD_BASE,"o",false) 
        --         self:removeFromParent()
        --     end 
        -- end)
    elseif opType == 2 then
        -- local item = self.Button_operation:clone()  --打陀按钮及其功能
        -- local textureName = "game/op_datuo.png"
        -- local texture = cc.TextureCache:getInstance():addImage(textureName)
        -- item:loadTextures(textureName,textureName,textureName)
        -- item:setContentSize(texture:getContentSizeInPixels())  
        -- item:setPressedActionEnabled(true)
        -- uiPanel_operation:addChild(item)
        -- item:addTouchEventListener(function(sender,event) 
        --     if event == ccui.TouchEventType.ended then 
        --         Common:palyButton() 
        --         NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_C_ADD_BASE,"o",true) 
        --         self:removeFromParent()
        --     end 
        -- end)
        -- local item = self.Button_operation:clone()
        -- local textureName = "game/op_datuono.png"
        -- local texture = cc.TextureCache:getInstance():addImage(textureName)
        -- item:loadTextures(textureName,textureName,textureName)
        -- item:setContentSize(texture:getContentSizeInPixels())     
        -- item:setPressedActionEnabled(true)
        -- uiPanel_operation:addChild(item)
        -- item:addTouchEventListener(function(sender,event) 
        --     if event == ccui.TouchEventType.ended then 
        --         Common:palyButton() 
        --         NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_C_ADD_BASE,"o",false) 
        --         self:removeFromParent()
        --     end 
        -- end)     
    else
        if (Bit:_and(cbOperateCode,GameCommon.ACK_BIHU) ~= 0) then
            local item = self.Button_operation:clone()
            item:loadTextures("yongzhou/ui/yongzhou_hu.png","yongzhou/ui/yongzhou_hu.png","yongzhou/ui/yongzhou_hu.png")
            item:setPressedActionEnabled(true)
            if  GameCommon.tableConfig.wKindID == 39 or GameCommon.tableConfig.wKindID == 16  then       
                self:runAction(cc.Sequence:create(cc.DelayTime:create(1),cc.CallFunc:create(function(sender,event)  self:dealHu() item:setVisible(false) end)))      
            end 
            uiPanel_operation:addChild(item)
            item:addTouchEventListener(function(sender,event) 
                if event == ccui.TouchEventType.ended then 
                    Common:palyButton() 
                    self:dealHu()
                end 
            end)
            GameCommon.IsOfHu = 1
            ccs.ArmatureDataManager:getInstance():addArmatureFileInfo("yongzhou/anim/button_effects/button_effects.ExportJson")
            local armature=ccs.Armature:create("button_effects")
            armature:getAnimation():playWithIndex(1)
            item:addChild(armature)
            armature:setPosition(armature:getParent():getContentSize().width/2,armature:getParent():getContentSize().height/2)  
        else
            if (Bit:_and(cbOperateCode,GameCommon.ACK_CHI) ~= 0) or (Bit:_and(cbOperateCode,GameCommon.ACK_CHI_EX) ~= 0) then
                if Bit:_and(cbOperateCode,GameCommon.ACK_CHI_EX) ~= 0 then
                    self.operateClientData.cbOperateCode = GameCommon.ACK_CHI_EX
                else
                    self.operateClientData.cbOperateCode = GameCommon.ACK_CHI
                end
                local item = self.Button_operation:clone()
                item:loadTextures("yongzhou/ui/yongzhou_chi.png","yongzhou/ui/yongzhou_chi.png","yongzhou/ui/yongzhou_chi.png")
                item:setPressedActionEnabled(true)
                uiPanel_operation:addChild(item)
                item:addTouchEventListener(function(sender,event) 
                    if event == ccui.TouchEventType.ended then 
                        Common:palyButton() 
                        self:dealChi()
                    end 
                end)

                ccs.ArmatureDataManager:getInstance():addArmatureFileInfo("yongzhou/anim/button_effects/button_effects.ExportJson")
                local armature=ccs.Armature:create("button_effects")
                armature:getAnimation():playWithIndex(0)
                item:addChild(armature)
                armature:setPosition(armature:getParent():getContentSize().width/2,armature:getParent():getContentSize().height/2)  
          
            end
            if Bit:_and(cbOperateCode,GameCommon.ACK_PENG) ~= 0  then
                local item = self.Button_operation:clone()
                item:loadTextures("yongzhou/ui/yongzhou_peng.png","yongzhou/ui/yongzhou_peng.png","yongzhou/ui/yongzhou_peng.png")
                item:setPressedActionEnabled(true)
                uiPanel_operation:addChild(item)
                item:addTouchEventListener(function(sender,event) 
                    if event == ccui.TouchEventType.ended then 
                        Common:palyButton() 
                        self:dealPen()
                    end 
                end)
                ccs.ArmatureDataManager:getInstance():addArmatureFileInfo("yongzhou/anim/button_effects/button_effects.ExportJson")
                local armature=ccs.Armature:create("button_effects")
                armature:getAnimation():playWithIndex(0)
                item:addChild(armature)
                armature:setPosition(armature:getParent():getContentSize().width/2,armature:getParent():getContentSize().height/2)  
            end
            if Bit:_and(cbOperateCode,GameCommon.ACK_CHIHU) ~= 0  then
                local item = self.Button_operation:clone()
                item:loadTextures("yongzhou/ui/yongzhou_hu.png","yongzhou/ui/yongzhou_hu.png","yongzhou/ui/yongzhou_hu.png")
                item:setPressedActionEnabled(true)
                uiPanel_operation:addChild(item)
                item:addTouchEventListener(function(sender,event) 
                    if event == ccui.TouchEventType.ended then 
                        Common:palyButton() 
                        self:dealHu()
                    end 
                end)
                GameCommon.IsOfHu = 1
                if GameCommon.tableConfig.wKindID == 33 or GameCommon.tableConfig.wKindID == 34 or GameCommon.tableConfig.wKindID == 35 or GameCommon.tableConfig.wKindID == 36 or GameCommon.tableConfig.wKindID == 32 or GameCommon.tableConfig.wKindID == 37 or GameCommon.tableConfig.wKindID == 27 or GameCommon.tableConfig.wKindID == 31 then
                    if Bit:_and(cbSubOperateCode,0x0800) ~= 0  then
                        local img = ccui.ImageView:create("yongzhou/ui/end_play_3wcw.png")
                        item:addChild(img)
                        img:setPosition(img:getParent():getContentSize().width/2,img:getParent():getContentSize().height)
                    elseif Bit:_and(cbSubOperateCode,0x0400) ~= 0  then
                        local img = ccui.ImageView:create("yongzhou/ui/end_play_3wc.png")
                        item:addChild(img)
                        img:setPosition(img:getParent():getContentSize().width/2,img:getParent():getContentSize().height)
                    elseif Bit:_and(cbSubOperateCode,0x0200) ~= 0  then
                        local img = ccui.ImageView:create("yongzhou/ui/end_play_wcw.png")
                        item:addChild(img)
                        img:setPosition(img:getParent():getContentSize().width/2,img:getParent():getContentSize().height)
                    elseif Bit:_and(cbSubOperateCode,0x0100) ~= 0  then
                        local img = ccui.ImageView:create("yongzhou/ui/end_play_wangchuang.png")
                        item:addChild(img)
                        img:setPosition(img:getParent():getContentSize().width/2,img:getParent():getContentSize().height)
                    elseif Bit:_and(cbSubOperateCode,0x0080) ~= 0  then
                        local img = ccui.ImageView:create("yongzhou/ui/end_play_wangdiaowang.png")
                        item:addChild(img)
                        img:setPosition(img:getParent():getContentSize().width/2,img:getParent():getContentSize().height)
                    elseif Bit:_and(cbSubOperateCode,0x0040) ~= 0  then
                        local img = ccui.ImageView:create("yongzhou/ui/end_play_wangdiao.png")
                        item:addChild(img)
                        img:setPosition(img:getParent():getContentSize().width/2,img:getParent():getContentSize().height)
                    else
                    end
                    if Bit:_and(cbSubOperateCode,0x0002) ~= 0  then
                        local img = ccui.ImageView:create("yongzhou/ui/end_play_honghu.png")
                        item:addChild(img)
                        img:setPosition(img:getParent():getContentSize().width/2,img:getParent():getContentSize().height)
                    elseif Bit:_and(cbSubOperateCode,0x0004) ~= 0  then
                        local img = ccui.ImageView:create("yongzhou/ui/end_play_dianhu.png")
                        item:addChild(img)
                        img:setPosition(img:getParent():getContentSize().width/2,img:getParent():getContentSize().height)
                    elseif Bit:_and(cbSubOperateCode,0x0008) ~= 0  then
                        local img = ccui.ImageView:create("yongzhou/ui/end_play_hongzhuandian.png")
                        item:addChild(img)
                        img:setPosition(img:getParent():getContentSize().width/2,img:getParent():getContentSize().height)
                    elseif Bit:_and(cbSubOperateCode,0x0010) ~= 0  then
                        local img = ccui.ImageView:create("yongzhou/ui/end_play_hongzhuanhei.png")
                        item:addChild(img)
                        img:setPosition(img:getParent():getContentSize().width/2,img:getParent():getContentSize().height)
                    elseif Bit:_and(cbSubOperateCode,0x0020) ~= 0  then
                        local img = ccui.ImageView:create("yongzhou/ui/end_play_heihu.png")
                        item:addChild(img)
                        img:setPosition(img:getParent():getContentSize().width/2,img:getParent():getContentSize().height)
                    else
                    end
                    local tableTemp = item:getChildren()
                    for key, var in pairs(tableTemp) do
                        var:setPosition(var:getParent():getContentSize().width/2,var:getParent():getContentSize().height + (key-1) * 33)
                    end
                    
                end
                ccs.ArmatureDataManager:getInstance():addArmatureFileInfo("yongzhou/anim/button_effects/button_effects.ExportJson")
                local armature=ccs.Armature:create("button_effects")
                armature:getAnimation():playWithIndex(1)
                item:addChild(armature)
                armature:setPosition(armature:getParent():getContentSize().width/2,armature:getParent():getContentSize().height/2)  
            end
            if Bit:_and(cbOperateCode,GameCommon.ACK_WD) ~= 0  then
                if GameCommon.tableConfig.wKindID == 33 or GameCommon.tableConfig.wKindID == 34 or GameCommon.tableConfig.wKindID == 35 or GameCommon.tableConfig.wKindID == 36 or GameCommon.tableConfig.wKindID == 32 or GameCommon.tableConfig.wKindID == 37 or GameCommon.tableConfig.wKindID == 27 or GameCommon.tableConfig.wKindID == 31 then
                    if Bit:_and(cbSubOperateCode,0x04) ~= 0  then
                        --4王 三王闯
                        local item = self.Button_operation:clone()
                        item:loadTextures("yongzhou/ui/yongzhou_wangzha.png","yongzhou/ui/yongzhou_wangzha.png","yongzhou/ui/yongzhou_wangzha.png")
                        item:setPressedActionEnabled(true)
                        uiPanel_operation:addChild(item)
                        item:addTouchEventListener(function(sender,event) 
                            if event == ccui.TouchEventType.ended then 
                                Common:palyButton() 
                                self:deal3Wc()
                            end 
                        end)
                        ccs.ArmatureDataManager:getInstance():addArmatureFileInfo("yongzhou/anim/button_effects/button_effects.ExportJson")
                        local armature=ccs.Armature:create("button_effects")
                        armature:getAnimation():playWithIndex(1)
                        item:addChild(armature)
                        armature:setPosition(armature:getParent():getContentSize().width/2,armature:getParent():getContentSize().height/2)  
                    end
                    if Bit:_and(cbSubOperateCode,0x02) ~= 0  then
                        --4王 王闯
                        local item = self.Button_operation:clone()
                        item:loadTextures("yongzhou/ui/yongzhou_wangchuang.png","yongzhou/ui/yongzhou_wangchuang.png","yongzhou/ui/yongzhou_wangchuang.png")
                        item:setPressedActionEnabled(true)
                        uiPanel_operation:addChild(item)
                        item:addTouchEventListener(function(sender,event) 
                            if event == ccui.TouchEventType.ended then 
                                Common:palyButton() 
                                self:dealWc()
                            end 
                        end)
                        ccs.ArmatureDataManager:getInstance():addArmatureFileInfo("yongzhou/anim/button_effects/button_effects.ExportJson")
                        local armature=ccs.Armature:create("button_effects")
                        armature:getAnimation():playWithIndex(1)
                        item:addChild(armature)
                        armature:setPosition(armature:getParent():getContentSize().width/2,armature:getParent():getContentSize().height/2)  
                    end
                    if Bit:_and(cbSubOperateCode,0x01) ~= 0  then
                        --4王 王钓
                        local item = self.Button_operation:clone()
                        item:loadTextures("yongzhou/ui/yongzhou_wangdiao.png","yongzhou/ui/yongzhou_wangdiao.png","yongzhou/ui/yongzhou_wangdiao.png")
                        item:setPressedActionEnabled(true)
                        uiPanel_operation:addChild(item)
                        item:addTouchEventListener(function(sender,event) 
                            if event == ccui.TouchEventType.ended then 
                                Common:palyButton() 
                                self:dealWd()
                            end 
                        end)
                        ccs.ArmatureDataManager:getInstance():addArmatureFileInfo("yongzhou/anim/button_effects/button_effects.ExportJson")
                        local armature=ccs.Armature:create("button_effects")
                        armature:getAnimation():playWithIndex(1)
                        item:addChild(armature)
                        armature:setPosition(armature:getParent():getContentSize().width/2,armature:getParent():getContentSize().height/2)  
                    end
                else
                    local item = self.Button_operation:clone()
                    item:loadTextures("yongzhou/ui/yongzhou_wangdiao.png","yongzhou/ui/yongzhou_wangdiao.png","yongzhou/ui/yongzhou_wangdiao.png")
                    item:setPressedActionEnabled(true)
                    uiPanel_operation:addChild(item)
                    item:addTouchEventListener(function(sender,event) 
                        if event == ccui.TouchEventType.ended then 
                            Common:palyButton() 
                            self:dealWd()
                        end 
                    end)
                    ccs.ArmatureDataManager:getInstance():addArmatureFileInfo("yongzhou/anim/button_effects/button_effects.ExportJson")
                    local armature=ccs.Armature:create("button_effects")
                    armature:getAnimation():playWithIndex(1)
                    item:addChild(armature)
                    armature:setPosition(armature:getParent():getContentSize().width/2,armature:getParent():getContentSize().height/2)  
                end
            end
            if Bit:_and(cbOperateCode,GameCommon.ACK_WC) ~= 0 then
                local item = self.Button_operation:clone()
                item:loadTextures("yongzhou/ui/yongzhou_wangchuang.png","yongzhou/ui/yongzhouwangchuang.png","yongzhou/ui/yongzhou_wangchuang.png")
                item:setPressedActionEnabled(true)
                uiPanel_operation:addChild(item)
                item:addTouchEventListener(function(sender,event) 
                    if event == ccui.TouchEventType.ended then 
                        Common:palyButton() 
                        self:dealWc()
                    end 
                end)
                ccs.ArmatureDataManager:getInstance():addArmatureFileInfo("yongzhou/anim/button_effects/button_effects.ExportJson")
                local armature=ccs.Armature:create("button_effects")
                armature:getAnimation():playWithIndex(1)
                item:addChild(armature)
                armature:setPosition(armature:getParent():getContentSize().width/2,armature:getParent():getContentSize().height/2)  
            end
            
            if Bit:_and(cbOperateCode,GameCommon.ACK_PAO) ~= 0 then
                --跑牌提示
                local item = self.Button_operation:clone()
                item:loadTextures("yongzhou/ui/yongzhou_pao.png","yongzhou/ui/yongzhou_pao.png","yongzhou/ui/yongzhou_pao.png")
                item:setPressedActionEnabled(true)                
                uiPanel_operation:addChild(item)
                item:addTouchEventListener(function(sender,event) 
                    if event == ccui.TouchEventType.ended then 
                        Common:palyButton() 
                        self:dealGuo()
                    end 
                end)
            end
            if cbOperateCode ~= GameCommon.ACK_PAO then
                local item = self.Button_operation:clone()
                item:loadTextures("yongzhou/ui/yongzhou_guo.png","yongzhou/ui/yongzhou_guo.png","yongzhou/ui/yongzhou_guo.png")
                item:setPressedActionEnabled(true)                 
                uiPanel_operation:addChild(item)
                item:addTouchEventListener(function(sender,event) 
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
    local items = uiPanel_operation:getChildren()
    local interval = 20
    local width = items[1]:getContentSize().width
    local beganPos = (uiPanel_operation:getContentSize().width -  #items * width - (#items-1)*interval)/2 + width/2
    for key, var in pairs(items) do
        var:setPosition(beganPos + (key-1)*(width + interval), uiPanel_operation:getContentSize().height/2)
    end
end

function GameOperation:dealChi()
    local uiListView_panel = ccui.Helper:seekWidgetByName(self.root,"ListView_panel")
    uiListView_panel:removeAllItems()
	uiListView_panel:setVisible(true)
    -- local uiPanel_bg = ccui.Helper:seekWidgetByName(self.root,"Panel_bg")
    -- uiPanel_bg:setVisible(true)    
    -- uiPanel_bg:addTouchEventListener(function(sender,event)
    --     if event == ccui.TouchEventType.ended then
    --         uiPanel_bg:setVisible(false)      
    --         uiListView_panel:setVisible(false)   
    --     end
    -- end) 

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
        uiButton_chi:runAction(cc.Sequence:create(cc.MoveBy:create(0.05,cc.p(-15, 0)),cc.MoveBy:create(0.05, cc.p(15, 0))))
        uiButton_chi.cardIndex = {}
        local uiListView_card = ccui.Helper:seekWidgetByName(item,"ListView_card")
        
        for j = 1 , 3 do
            local card = GameCommon:GetCardHand(pChiCardInfo1[i].cbCardData[1][j])
            uiButton_chi.cardIndex[j] = pChiCardInfo1[i].cbCardData[1][j]
            uiButton_chi.cbChiKind = pChiCardInfo1[i].cbChiKind
            if uiButton_chi.cardIndex[j] == self.cbOperateCard then      
                if j == 1 then  
                    card:setColor(cc.c3b(200,200,200))                  
                elseif j == 2 then
                  if uiButton_chi.cardIndex[j-1] ~= uiButton_chi.cardIndex[j] then 
                        card:setColor(cc.c3b(200,200,200))  
                  end   
                else 
                    if uiButton_chi.cardIndex[j-1] ~= uiButton_chi.cardIndex[j] and uiButton_chi.cardIndex[j-2] ~= uiButton_chi.cardIndex[j]  then 
                        card:setColor(cc.c3b(200,200,200))  
                    end    
                end                
            end 
          
            if card ~= nil then
                card:setScale(0.52,0.49)
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
                        btn:loadTextures("yongzhou/ui/yongzhou_opbg.png","yongzhou/ui/yongzhou_opbg.png","yongzhou/ui/yongzhou_opbg.png")                       
                    else
                        if  btn ~= nil then 
                            btn:loadTextures("yongzhou/ui/yongzhou_op.png","yongzhou/ui/yongzhou_op.png","yongzhou/ui/yongzhou_op.png")
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
                    uiButton_chi:runAction(cc.Sequence:create(cc.MoveBy:create(0.05,cc.p(-15, 0)),cc.MoveBy:create(0.05, cc.p(15, 0))))
                    uiButton_chi.cardIndex = {}
                    local uiListView_card = ccui.Helper:seekWidgetByName(item,"ListView_card")
                    for j = 1 , 3 do
                        local card = GameCommon:GetCardHand(pChiCardInfo2[i].cbCardData[1][j])
                        uiButton_chi.cardIndex[j] = pChiCardInfo2[i].cbCardData[1][j]
                        uiButton_chi.cbChiKind = pChiCardInfo2[i].cbChiKind                        
                        if uiButton_chi.cardIndex[j] == self.cbOperateCard then      
                            if j == 1 then  
                                card:setColor(cc.c3b(200,200,200))                
                            elseif j == 2 then
                                if uiButton_chi.cardIndex[j-1] ~= uiButton_chi.cardIndex[j] then 
                                    card:setColor(cc.c3b(200,200,200))    
                                end   
                            else 
                                if uiButton_chi.cardIndex[j-1] ~= uiButton_chi.cardIndex[j] and uiButton_chi.cardIndex[j-2] ~= uiButton_chi.cardIndex[j]  then 
                                    card:setColor(cc.c3b(200,200,200))    
                                end    
                            end                
                        end 
                        
                        if card ~= nil then
                            card:setScale(0.52,0.49)
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
                                    btn:loadTextures("yongzhou/ui/yongzhou_opbg.png","yongzhou/ui/yongzhou_opbg.png","yongzhou/ui/yongzhou_opbg.png")                       
                                else
                                    if  btn ~= nil then 
                                        btn:loadTextures("yongzhou/ui/yongzhou_op.png","yongzhou/ui/yongzhou_op.png","yongzhou/ui/yongzhou_op.png")
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
                                uiButton_chi:runAction(cc.Sequence:create(cc.MoveBy:create(0.05,cc.p(-15, 0)),cc.MoveBy:create(0.05, cc.p(15, 0))))
                                uiButton_chi.cardIndex = {}
                                local uiListView_card = ccui.Helper:seekWidgetByName(item,"ListView_card")
                                for j = 1 , 3 do
                                    local card = GameCommon:GetCardHand(pChiCardInfo3[i].cbCardData[1][j])
                                    uiButton_chi.cardIndex[j] = pChiCardInfo3[i].cbCardData[1][j]
                                    uiButton_chi.cbChiKind = pChiCardInfo3[i].cbChiKind
                                    
                                    if uiButton_chi.cardIndex[j] == self.cbOperateCard then      
                                        if j == 1 then  
                                            card:setColor(cc.c3b(200,200,200))                
                                        elseif j == 2 then
                                            if uiButton_chi.cardIndex[j-1] ~= uiButton_chi.cardIndex[j] then 
                                                card:setColor(cc.c3b(200,200,200))    
                                            end   
                                        else 
                                            if uiButton_chi.cardIndex[j-1] ~= uiButton_chi.cardIndex[j] and uiButton_chi.cardIndex[j-2] ~= uiButton_chi.cardIndex[j]  then 
                                                card:setColor(cc.c3b(200,200,200))    
                                            end    
                                        end                
                                    end 
                                    
                                    if card ~= nil then
                                        card:setScale(0.52,0.49)
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
                                    uiListView_panel:setPositionX(cc.Director:getInstance():getVisibleSize().width/2-100)
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
                        uiListView_panel:setPositionX(cc.Director:getInstance():getVisibleSize().width/2-100)
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
            uiListView_panel:setPositionX(cc.Director:getInstance():getVisibleSize().width/2-100)
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


--==============================--
--desc:托管自动碰跑胡
--time:2018-09-20 03:24:55
--@cbOperateCode:操作类型
--@isSelf:是否为自己
--@return 
--==============================--
function GameOperation:Tuoguan_Status(pBuffer)
    --托管碰胡
    self:initButtonStatus()
    local cbOperateCode = pBuffer.cbActionMask
    local _node = nil

    local Cout = 1
    local size = cc.Director:getInstance():getWinSize()
    local Opration_width = 150
    --胡牌
    if Bit:_and(cbOperateCode,GameCommon.WIK_CHI_HU) ~= 0 then
         self:dealHu() 
         return
    end
    --杠牌
    -- if Bit:_and(cbOperateCode,GameCommon.WIK_GANG) ~= 0 then
    --     if GameCommon.wKindID == 27 then
    --         self:dealGang() 
    --     else
    --         self:dealBu_tuoguan() 
    --         return
    --     end
    -- end
    --碰牌
    if Bit:_and(cbOperateCode,GameCommon.WIK_PENG) ~= 0 then
        self:dealPen() 
        return
    end
    self:dealGuo()
    return
end

return GameOperation

