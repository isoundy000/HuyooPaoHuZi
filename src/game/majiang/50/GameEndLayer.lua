local GameCommon = require("game.majiang.GameCommon")
local Bit = require("common.Bit")
local StaticData = require("app.static.StaticData")
local GameLogic = require("game.majiang.GameLogic")
local Common = require("common.Common")
local EventMgr = require("common.EventMgr")
local EventType = require("common.EventType")
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
    local visibleSize = cc.Director:getInstance():getVisibleSize()
    local csb = cc.CSLoader:createNode("GameLayerMaJiang_End.csb")
    self:addChild(csb)
    self.root = csb:getChildByName("Panel_root")
    local uiButton_return = ccui.Helper:seekWidgetByName(self.root,"Button_return")
    uiButton_return:setPressedActionEnabled(true)
    if GameCommon.tableConfig.nTableType > TableType_GoldRoom then
        uiButton_return:setVisible(false)
    end
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
    local visibleSize = cc.Director:getInstance():getVisibleSize()
    ccs.ArmatureDataManager:getInstance():addArmatureFileInfo("game/wuguidonghua/wuguidonghua.ExportJson")
    local armature2=ccs.Armature:create("wuguidonghua")
    armature2:getAnimation():playWithIndex(0)
    local uiImage_bjkuang = ccui.Helper:seekWidgetByName(self.root,"Image_bjkuang")
    uiImage_bjkuang:addChild(armature2,100)
    armature2:setPosition(0,armature2:getParent():getContentSize().height)
    armature2:runAction(cc.MoveTo:create(20,cc.p(1280,armature2:getPositionY())))
    
    --显示桌面、显示结算
    local uiPanel_look = ccui.Helper:seekWidgetByName(self.root,"Panel_look")
    local uiButton_look = ccui.Helper:seekWidgetByName(self.root,"Button_look")
    Common:addTouchEventListener(uiButton_look,function() 
        if uiPanel_look:isVisible() then
            uiPanel_look:setVisible(false)
            uiButton_look:setBright(false)
        else
            uiPanel_look:setVisible(true)
            uiButton_look:setBright(true)
        end
    end)   
    local uiText_info = ccui.Helper:seekWidgetByName(self.root,"Text_info")
    if GameCommon.tableConfig.nTableType == TableType_GoldRoom then
        uiText_info:setString(string.format("倍率 %d\n消耗%d",pBuffer.lCellScore,pBuffer.lGameTax))
    else
        uiText_info:setString("")
    end
    local uiImage_result = ccui.Helper:seekWidgetByName(self.root,"Image_biaoti") 
    local textureName = nil
    if pBuffer.wWinner[GameCommon:getRoleChairID()+1] == true then
        textureName = "common/common_end1.png"   
    else
        textureName = "common/common_end2.png"       
    end
    local texture = cc.Director:getInstance():getTextureCache():addImage(textureName)
    uiImage_result:loadTexture(textureName)
    uiImage_result:setContentSize(texture:getContentSizeInPixels())   
    
    local uiText_mingtang = ccui.Helper:seekWidgetByName(self.root,"Text_mingtang")
    uiText_mingtang:setString("抓鸟")
    
    local maxRow = 3
    local uiPanel_zhong = ccui.Helper:seekWidgetByName(self.root,"Panel_zhong")
    local size = uiPanel_zhong:getContentSize()
    for i, data in pairs(pBuffer.bZhaNiao) do
        if data ~= 0 and  data ~= 255  then
            local cardScale = 1
            local cardWidth = 55 * cardScale
            local cardHeight = 85 * cardScale
            local stepX = cardWidth + 5
            local stepY = -(cardHeight+12)
            local beganX = (size.width-stepX*3)/2+cardWidth/2
            local beganY = size.height - 50
            local size = cc.size(cardWidth,cardHeight)
            local card = GameCommon:getDiscardCardAndWeaveItemArray(data,1)
            uiPanel_zhong:addChild(card)
            card:setScale(cardScale)
            local row = math.floor((i-1)/maxRow)
            local line = (i-1)%maxRow
            card:setPosition(beganX + stepX*line ,beganY + stepY*row)  
        else
            break
        end
    end
    
    local uiListView_player = ccui.Helper:seekWidgetByName(self.root,"ListView_player")
    local uiPanel_itemWin = ccui.Helper:seekWidgetByName(self.root,"Panel_itemWin")
    uiPanel_itemWin:retain()
    uiListView_player:removeAllItems()
    
    --显示中码信息
    local tableShowZhongMa = {}
    for i = 1,GameCommon.gameConfig.bPlayerCount do
        local wChairID = i-1    
        if pBuffer.wProvideUser < GameCommon.gameConfig.bPlayerCount then
            if pBuffer.wProvideUser == wChairID and pBuffer.wWinner[i] == true then
                for j = 1, 4 do
                    tableShowZhongMa[j] = true
                end
                break
            elseif pBuffer.wWinner[i] == true then
                tableShowZhongMa[i] = true
                
            elseif pBuffer.wProvideUser == wChairID and pBuffer.wWinner[i] == false then
                tableShowZhongMa[i] = true
                
            else

            end
        end
    end
    for i = 1,GameCommon.gameConfig.bPlayerCount do
        local wChairID = i-1    
        local var = GameCommon.player[wChairID]
        local viewID = GameCommon:getViewIDByChairID(wChairID)            
        local item = uiPanel_itemWin:clone()
        uiListView_player:pushBackCustomItem(item)
        local uiImage_avatar = ccui.Helper:seekWidgetByName(item,"Image_avatar")
        Common:requestUserAvatar(var.dwUserID,var.szPto,uiImage_avatar,"img")
        local uiText_name = ccui.Helper:seekWidgetByName(item,"Text_name")
        uiText_name:setString(string.format("%s\n%d",var.szNickName,var.dwUserID))
        if GameCommon.tableConfig.nTableType == TableType_GoldRoom or GameCommon.tableConfig.nTableType  == TableType_SportsRoom then
            uiText_name:setString(string.format("%s",var.szNickName))
        end 
        uiText_name:setTextColor(cc.c3b(0,0,0))
        local uiImage_zhuang = ccui.Helper:seekWidgetByName(item,"Image_zhuang")
        if i == GameCommon.wBankerUser + 1 then
            uiImage_zhuang:setVisible(true)
        else
            uiImage_zhuang:setVisible(false)
        end
        local uiImage_piaoFen = ccui.Helper:seekWidgetByName(item,"Image_piaoFen")
       
        if  pBuffer.mPiaoCount[wChairID+1] == 0 then
            --uiImage_piaoFen:loadTexture("game/mj_piaofen_1.png")
        else
            uiImage_piaoFen:loadTexture(string.format("game/pukenew_score_%s.png",pBuffer.mPiaoCount[i]))
        end
        
        local uiListView_mingTang = ccui.Helper:seekWidgetByName(item,"ListView_mingTang")
        self:showMingTang(uiListView_mingTang, pBuffer.wChiHuKind[i],pBuffer.wSpecialKind[i])
        local uiImage_zhongMa = ccui.Helper:seekWidgetByName(item,"Image_zhongMa")  
        uiImage_zhongMa:setVisible(tableShowZhongMa[i])   
        local uiText_zhongnumber = ccui.Helper:seekWidgetByName(item,"Text_zhongnumber")
        uiText_zhongnumber:setString(string.format("x%d",pBuffer.cbZhanNiaoCount[wChairID+1]))--中马数量
        uiText_zhongnumber:setTextColor(cc.c3b(95,8,0))
        local uiImage_dice = ccui.Helper:seekWidgetByName(item,"Image_dice")
        if pBuffer.wDiceCount[wChairID+1] > 0 then
            local uiText_dice = ccui.Helper:seekWidgetByName(item,"Text_dice")
            uiText_dice:setString(string.format("x%d",pBuffer.wDiceCount[wChairID+1]))--骰子数量
            uiText_dice:setTextColor(cc.c3b(95,8,0))
        else
            uiImage_dice:setVisible(false)
        end  
        local uiImage_winType = ccui.Helper:seekWidgetByName(item,"Image_winType")
        if pBuffer.wProvideUser < GameCommon.gameConfig.bPlayerCount then
            if pBuffer.wProvideUser == wChairID and pBuffer.wWinner[i] == true then
                local textureName = "majiang/table/end_zimo.png"
                local texture = cc.Director:getInstance():getTextureCache():addImage(textureName)
                uiImage_winType:loadTexture(textureName)
                uiImage_winType:setContentSize(texture:getContentSizeInPixels())
            elseif pBuffer.wWinner[i] == true then
                local textureName = "majiang/table/end_hupai.png"
                local texture = cc.Director:getInstance():getTextureCache():addImage(textureName)
                uiImage_winType:loadTexture(textureName)
                uiImage_winType:setContentSize(texture:getContentSizeInPixels())
            elseif pBuffer.wProvideUser == wChairID and pBuffer.wWinner[i] == false then
                local textureName = "majiang/table/end_fangpao.png"
                local texture = cc.Director:getInstance():getTextureCache():addImage(textureName)
                uiImage_winType:loadTexture(textureName)
                uiImage_winType:setContentSize(texture:getContentSizeInPixels())
            else
                uiImage_winType:setVisible(false)
            end
        else
            uiImage_winType:setVisible(false)
        end
        
        local uiListView_card = ccui.Helper:seekWidgetByName(item,"ListView_card")
        for j = 1, pBuffer.cbWeaveItemCount[i] do
            local content = self:getWeaveItemArray(pBuffer.WeaveItemArray[i][j])
            uiListView_card:pushBackCustomItem(content)
        end
        if pBuffer.wProvideUser < GameCommon.gameConfig.bPlayerCount and pBuffer.wProvideUser == wChairID and pBuffer.wWinner[i] == true then
            --自摸
        else
            for j = 15, 16 do
                pBuffer.cbCardData[i][j] = pBuffer.cbChiHuCard[i][j-14]
            end
        end
        local tableMark = {[1] = false, [2] = false}
        for key, var in pairs(pBuffer.cbCardData[i]) do
            local data = var
            if data ~= 0 then
                local cardScale = 0.8
                local cardWidth = 55 * cardScale
                local cardHeight = 85 * cardScale
                local size = cc.size(cardWidth,cardHeight)
                local content = ccui.Layout:create()
                content:setContentSize(size)
                uiListView_card:pushBackCustomItem(content)
                local card = GameCommon:getDiscardCardAndWeaveItemArray(data,1)
                content:addChild(card)
                card:setScale(cardScale)
                card:setPosition(size.width/2,size.height/2)
                if key > 14 then
                    ccs.ArmatureDataManager:getInstance():addArmatureFileInfo("majiang/animation/hudepaitishi/hudepaitishi.ExportJson")
                    local armature = ccs.Armature:create("hudepaitishi")
                    armature:getAnimation():playWithIndex(0,-1,1)
                    armature:setAnchorPoint(cc.p(0,0))
                    armature:setPosition(0,2)
                    card:addChild(armature)
                    armature:setScale(cardScale - 0.1, cardScale)
                elseif pBuffer.wProvideUser < GameCommon.gameConfig.bPlayerCount and pBuffer.wProvideUser == wChairID and pBuffer.wWinner[i] == true then
                    for i = 1, 2 do
                        if data == pBuffer.cbChiHuCard[wChairID+1][i] and tableMark[i] == false then
                            tableMark[i] = true
                            ccs.ArmatureDataManager:getInstance():addArmatureFileInfo("majiang/animation/hudepaitishi/hudepaitishi.ExportJson")
                            local armature = ccs.Armature:create("hudepaitishi")
                            armature:getAnimation():playWithIndex(0,-1,1)
                            armature:setAnchorPoint(cc.p(0,0))
                            armature:setPosition(0,2)
                            card:addChild(armature)
                            armature:setScale(cardScale - 0.1, cardScale)
                        end
                    end
                end
            end
        end
        local uiAtlasLabel_score = ccui.Helper:seekWidgetByName(item,"AtlasLabel_score")
        if pBuffer.lGameScore[i] < 0 then       
            uiAtlasLabel_score:setProperty(string.format(".%d",pBuffer.lGameScore[i]),"fonts/fonts_12.png",26,45,'.')              
        elseif  pBuffer.lGameScore[i] > 0 then
            uiAtlasLabel_score:setProperty(string.format(".%d",pBuffer.lGameScore[i]),"fonts/fonts_13.png",26,45,'.')
        else
            uiAtlasLabel_score:setProperty(string.format(".%d",pBuffer.lGameScore[i]),"fonts/fonts_13.png",26,45,'.')
        end
    end
    uiPanel_itemWin:release()
end

function GameEndLayer:getWeaveItemArray(var)
    
    local cardScale = 0.8
    local cardWidth = 55 * cardScale
    local cardHeight = 85 * cardScale
    local size = cc.size(cardWidth*3+5,cardHeight)
    local content = ccui.Layout:create()
    content:setContentSize(size)
    local cbCardList = {}
    if Bit:_and(var.cbWeaveKind,GameCommon.WIK_GANG) ~= 0 then
        cbCardList = {var.cbCenterCard,var.cbCenterCard,var.cbCenterCard,var.cbCenterCard}
    elseif Bit:_and(var.cbWeaveKind,GameCommon.WIK_FILL) ~= 0 then
        cbCardList = {var.cbCenterCard,var.cbCenterCard,var.cbCenterCard,var.cbCenterCard}
    elseif Bit:_and(var.cbWeaveKind,GameCommon.WIK_PENG) ~= 0 then
        cbCardList = {var.cbCenterCard,var.cbCenterCard,var.cbCenterCard}
    elseif Bit:_and(var.cbWeaveKind,GameCommon.WIK_LEFT) ~= 0 then
        cbCardList = {var.cbCenterCard,var.cbCenterCard+1,var.cbCenterCard+2}
    elseif Bit:_and(var.cbWeaveKind,GameCommon.WIK_CENTER) ~= 0 then
        cbCardList = {var.cbCenterCard-1,var.cbCenterCard,var.cbCenterCard+1}
    elseif Bit:_and(var.cbWeaveKind,GameCommon.WIK_RIGHT) ~= 0 then
        cbCardList = {var.cbCenterCard-1,var.cbCenterCard-2,var.cbCenterCard}
    else
        assert(false,"吃牌类型错误")
    end
    for k, v in pairs(cbCardList) do
        local card = nil
        if k < 4 and var.cbPublicCard == 2 and (Bit:_and(var.cbWeaveKind,GameCommon.WIK_GANG) ~= 0 or Bit:_and(var.cbWeaveKind,GameCommon.WIK_FILL) ~= 0) then
            card = GameCommon:getDiscardCardAndWeaveItemArray(0,1)
        else
            card = GameCommon:getDiscardCardAndWeaveItemArray(v,1)
            if k == 1 and Bit:_and(var.cbWeaveKind,GameCommon.WIK_LEFT) ~= 0 then
                card:setColor(cc.c3b(170,170,170))
            elseif k == 2 and Bit:_and(var.cbWeaveKind,GameCommon.WIK_CENTER) ~= 0 then
                card:setColor(cc.c3b(170,170,170))
            elseif k == 3 and Bit:_and(var.cbWeaveKind,GameCommon.WIK_RIGHT) ~= 0 then
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
    return content
end

function GameEndLayer:showMingTang(uiListView_mingTang,wChiHuKind,wSpecialKind)
    --小胡牌型
    local CHK_PING_HU                 = 0x0001                                  --平胡类型
    local CHK_SIXI_HU                 = 0x0002                                  --四喜胡牌
    local CHK_BANBAN_HU               = 0x0004                                  --板板胡牌
    local CHK_LIULIU_HU               = 0x0008                                  --六六顺牌
    local CHK_QUEYISE_HU              = 0x0010                                  --缺一色牌
    local CHK_BUBUGAO_HU              = 0x0020                                  --步步高牌
    local CHK_SANTONG_HU              = 0x0040                                  --三同牌
    local CHK_YIZHIHUA_HU             = 0x0080                                  --一枝花牌
    local CHK_ZTSX_HU                 = 0x0100                                  --中途四喜

    if Bit:_and(wSpecialKind,CHK_SIXI_HU) ~= 0 then
        local item = ccui.ImageView:create("majiang/table/mingtang_sixi.png")
        uiListView_mingTang:pushBackCustomItem(item)
    end
    if Bit:_and(wSpecialKind,CHK_BANBAN_HU) ~= 0 then
        local item = ccui.ImageView:create("majiang/table/mingtang_wujianghu.png")
        uiListView_mingTang:pushBackCustomItem(item)
    end
    if Bit:_and(wSpecialKind,CHK_LIULIU_HU) ~= 0 then
        local item = ccui.ImageView:create("majiang/table/mingtang_liuliushun.png")
        uiListView_mingTang:pushBackCustomItem(item)
    end
    if Bit:_and(wSpecialKind,CHK_QUEYISE_HU) ~= 0 then
        local item = ccui.ImageView:create("majiang/table/mingtang_queyise.png")
        uiListView_mingTang:pushBackCustomItem(item)
    end
    if Bit:_and(wSpecialKind,CHK_BUBUGAO_HU) ~= 0 then
        local item = ccui.ImageView:create("majiang/table/mingtang_bubugao.png")
        uiListView_mingTang:pushBackCustomItem(item)
    end
    if Bit:_and(wSpecialKind,CHK_SANTONG_HU) ~= 0 then
        local item = ccui.ImageView:create("majiang/table/mingtang_santong.png")
        uiListView_mingTang:pushBackCustomItem(item)
    end
    if Bit:_and(wSpecialKind,CHK_YIZHIHUA_HU) ~= 0 then
        local item = ccui.ImageView:create("majiang/table/mingtang_yizhihua.png")
        uiListView_mingTang:pushBackCustomItem(item)
    end
    if Bit:_and(wSpecialKind,CHK_ZTSX_HU) ~= 0 then
        local item = ccui.ImageView:create("majiang/table/mingtang_sixi.png")
        uiListView_mingTang:pushBackCustomItem(item)
    end
    
    --大胡牌型
    local CHK_PENG_PENG               = 0x0002                                  --碰碰胡
    local CHK_JIANG_JIANG             = 0x0004                                  --将将胡
    local CHR_QING_YI_SE              = 0x0008                                  --清一色
    local CHR_QUAN_QIU_REN            = 0x0010                                  --全求人
    local CHR_HAIDI                   = 0x0020                                  --海底胡           --权位
    local CHK_QI_XIAO_DUI             = 0x0040                                  --七小对
    local CHK_QI_XIAO_DUI_HAO         = 0x0080                                  --豪华七小对
    local CHR_GANG                    = 0x0100                                  --杠上开花          --权位
    local CHR_GANG_SHUANG             = 0x0200                                  --双杠上花          --权位
    local CHR_QI_XIAO_DUI_CHAO_HAO    = 0x0400                                  --超豪华七小对        --权位
    local CHR_QI_XIAO_DUI_CHAO_CHAO   = 0x0800                                  --超超豪华七小对   --权位
    local CHR_QIANG_GANG_HU           = 0x1000                                  --抢杠胡
    local CHR_MENQING_HU              = 0x2000                                  --门清 

    if Bit:_and(wChiHuKind,CHK_PENG_PENG) ~= 0 then
        local item = ccui.ImageView:create("majiang/table/mingtang_pengpenghu.png")
        uiListView_mingTang:pushBackCustomItem(item)
    end
    if Bit:_and(wChiHuKind,CHK_JIANG_JIANG) ~= 0 then
        local item = ccui.ImageView:create("majiang/table/mingtang_jiangjianghu.png")
        uiListView_mingTang:pushBackCustomItem(item)
    end
    if Bit:_and(wChiHuKind,CHR_QING_YI_SE) ~= 0 then
        local item = ccui.ImageView:create("majiang/table/mingtang_qingyise.png")
        uiListView_mingTang:pushBackCustomItem(item)
    end
    if Bit:_and(wChiHuKind,CHR_QUAN_QIU_REN) ~= 0 then
        local item = ccui.ImageView:create("majiang/table/mingtang_quanqiuren.png")
        uiListView_mingTang:pushBackCustomItem(item)
    end
    if Bit:_and(wChiHuKind,CHR_HAIDI) ~= 0 then
        local item = ccui.ImageView:create("majiang/table/mingtang_haidehu.png")
        uiListView_mingTang:pushBackCustomItem(item)
    end
    if Bit:_and(wChiHuKind,CHK_QI_XIAO_DUI) ~= 0 then
        local item = ccui.ImageView:create("majiang/table/mingtang_qixiaodui.png")
        uiListView_mingTang:pushBackCustomItem(item)
    end
    if Bit:_and(wChiHuKind,CHK_QI_XIAO_DUI_HAO) ~= 0 then
        local item = ccui.ImageView:create("majiang/table/mingtang_haohuaqixiaodui.png")
        uiListView_mingTang:pushBackCustomItem(item)
    end
    if Bit:_and(wChiHuKind,CHR_GANG) ~= 0 or Bit:_and(wChiHuKind,CHR_GANG_SHUANG) ~= 0 then
        local item = ccui.ImageView:create("majiang/table/mingtang_gangshangkaihua.png")
        uiListView_mingTang:pushBackCustomItem(item)
    end
    if Bit:_and(wChiHuKind,CHR_QI_XIAO_DUI_CHAO_HAO) ~= 0 then
        local item = ccui.ImageView:create("majiang/table/mingtang_chaohaohuaqixiaodui.png")
        uiListView_mingTang:pushBackCustomItem(item)
    end
    if Bit:_and(wChiHuKind,CHR_QI_XIAO_DUI_CHAO_CHAO) ~= 0 then
        local item = ccui.ImageView:create("majiang/table/mingtang_shuanghaohuaqixiaodui.png")
        uiListView_mingTang:pushBackCustomItem(item)
    end
    if Bit:_and(wChiHuKind,CHR_QIANG_GANG_HU) ~= 0 then
        local item = ccui.ImageView:create("majiang/table/mingtang_qiangganghu.png")
        uiListView_mingTang:pushBackCustomItem(item)
    end
    if Bit:_and(wChiHuKind,CHR_MENQING_HU) ~= 0 then
        local item = ccui.ImageView:create("majiang/table/mingtang_menqing.png")
        uiListView_mingTang:pushBackCustomItem(item)
    end
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
