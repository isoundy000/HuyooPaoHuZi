local GameCommon = require("game.zhuzhou.GameCommon")
local Bit = require("common.Bit")
local StaticData = require("app.static.StaticData")
local EventType = require("common.EventType")
local EventMgr = require("common.EventMgr")
local GameLogic = require("game.zhuzhou.GameLogic")
local Common = require("common.Common")
local GameDesc = require("common.GameDesc")

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
    local csb = cc.CSLoader:createNode("GameLayerPengHuZhi_End.csb")
    self:addChild(csb)
    self.root = csb:getChildByName("Panel_root")    
    
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

    local uiText_title = ccui.Helper:seekWidgetByName(self.root,"Text_title")
    uiText_title:setString(StaticData.Games[GameCommon.tableConfig.wKindID].name)
    if  GameCommon.tableConfig.nTableType > TableType_GoldRoom then      
        uiText_title:setString(string.format("局:%d/%d",GameCommon.tableConfig.wCurrentNumber, GameCommon.tableConfig.wTableNumber))   
    end    
    local uiText_desc = ccui.Helper:seekWidgetByName(self.root,"Text_desc")
    uiText_desc:setString(GameDesc:getGameDesc(GameCommon.tableConfig.wKindID,GameCommon.gameConfig,GameCommon.tableConfig))
    local uiText_des = ccui.Helper:seekWidgetByName(self.root,"Text_des")   
    uiText_des:setString(string.format("房间号:%d",GameCommon.tableConfig.wTbaleID))
    if GameCommon.tableConfig.nTableType == TableType_GoldRoom then      
        if GameCommon.tableConfig.cbLevel == 2 then
            uiText_des:setString(string.format("中级场 倍率 %d",GameCommon.tableConfig.wCellScore))
        elseif GameCommon.tableConfig.cbLevel == 3 then
            uiText_des:setString(string.format("高级场 倍率 %d",GameCommon.tableConfig.wCellScore))
        else
            uiText_des:setString(string.format("初级场 倍率 %d",GameCommon.tableConfig.wCellScore))
        end
    end 
    GameCommon.playerEnd = {} 
    local index = 0
    for i = 1, 4 do    --获取手牌数据
        local cbCardIndex = {}
        for i = 1, 20 do
            cbCardIndex[i] = 0
        end
        local wChairID = i-1
        GameCommon.playerEnd[wChairID] = {}
        for j = 1, pBuffer.bCardCount[i] do
            index = index + 1
            local value = GameLogic:SwitchToCardIndex(pBuffer.bCardData[index])
            cbCardIndex[value] = cbCardIndex[value] + 1
        end
        local bUserCardCount = pBuffer.bCardCount[i]
        GameCommon.playerEnd[wChairID].cardStackInfo = GameLogic:sortHandCard(clone(cbCardIndex), 8, cc.p(0,32), 1)        
    end

    local uiListView_Player = ccui.Helper:seekWidgetByName(self.root,"ListView_Player") 
    
    for i = 1, 4 do
        local wChairID = i-1
        local viewID = GameCommon:getViewIDByChairID(wChairID,true)    
        local ShowPlayer = true  -- 控制是否是真实玩家
        if i > GameCommon.gameConfig.bPlayerCount then 
            viewID = i
            ShowPlayer = false   
        end 
        local root = ccui.Helper:seekWidgetByName(uiListView_Player,string.format("Panel_player%d",viewID))

        local uiImage_avatar = ccui.Helper:seekWidgetByName(root,"Image_avatar")
        uiImage_avatar:setVisible(ShowPlayer)       
        local uiAtlasLabel_num = ccui.Helper:seekWidgetByName(root,"AtlasLabel_num")
        local uiImage_fu = ccui.Helper:seekWidgetByName(root,"Image_fu")
        uiImage_fu:setVisible(false)
        local uiPanel_tricks = ccui.Helper:seekWidgetByName(root,"Panel_tricks")
        if pBuffer.lGameScore[i] < 0 then    
            uiImage_fu:setVisible(true)            
        end 

        if ShowPlayer == true then    --玩家信息  Image_avatar
            local uiImage_avatar = ccui.Helper:seekWidgetByName(root,"Image_avatar")
            local uiImage_img = ccui.Helper:seekWidgetByName(root,"Image_img")                      
            Common:requestUserAvatar(GameCommon.player[wChairID].dwUserID,GameCommon.player[wChairID].szPto,uiImage_img,"clip")       
         -- uiImage_avatar:addChild(img)    
         -- uiImage_img:setPosition(uiImage_img:getParent():getContentSize().width/2, uiImage_img:getParent():getContentSize().height/2) 
            local uiText_name = ccui.Helper:seekWidgetByName(root,"Text_name")       
            uiText_name:setString(string.format("%s",GameCommon.player[wChairID].szNickName)) 
            local uiText_ID = ccui.Helper:seekWidgetByName(root,"Text_ID")       
            uiText_ID:setString(string.format("ID:%s",GameCommon.player[wChairID].dwUserID)) 
            local uiImage_zhuang = ccui.Helper:seekWidgetByName(root,"Image_zhuang")
            if i == GameCommon.wBankerUser + 1 then
                uiImage_zhuang:setVisible(true)
                if GameCommon.wContinueWinCount < 1 then 
                    local textureName = "zhuzhou/table/zhuzhou_zhuang.png"
                    local texture = cc.TextureCache:getInstance():addImage(textureName)
                    uiImage_zhuang:loadTexture(textureName)
                    uiImage_zhuang:setContentSize(texture:getContentSizeInPixels())
                else
                    if GameCommon.tableConfig.bSuccessive == 0 then
                        local textureName = "zhuzhou/table/flag_zhongzhuang.png"
                        local texture = cc.TextureCache:getInstance():addImage(textureName)
                        uiImage_zhuang:loadTexture(textureName)
                        uiImage_zhuang:setContentSize(texture:getContentSizeInPixels())
                    else                    
                        local textureName = "zhuzhou/table/lag_zz_lz_bg.png"
                        local texture = cc.TextureCache:getInstance():addImage(textureName)
                        uiImage_zhuang:loadTexture(textureName)
                        uiImage_zhuang:setContentSize(texture:getContentSizeInPixels()) 
                        uiImage_zhuang:setVisible(true)
                        local uiText_LZ = ccui.TextAtlas:create(string.format("%d",GameCommon.wContinueWinCount),"zhuzhou/gameend/number2.png",21,30,'0') 
                        uiImage_zhuang:addChild(uiText_LZ)
                        uiText_LZ:setPosition(uiText_LZ:getParent():getContentSize().width/2,uiText_LZ:getParent():getContentSize().height/2-10)
                    end 
                end  
            else
                uiImage_zhuang:setVisible(false)
            end 
        end 

        if wChairID == pBuffer.wWinUser then 
           local img = ccui.ImageView:create("zhuzhou/gameend/huflag_bg.png")
           uiPanel_tricks:addChild(img)
           img:setPosition(img:getParent():getContentSize().width/2, img:getParent():getContentSize().height/2)
           local png = self:addimg(pBuffer)
           img:addChild(png)
           png:setPosition(png:getParent():getContentSize().width/2, png:getParent():getContentSize().height/2)
        end 
        if wChairID == pBuffer.wProvideUser then 
            local img = ccui.ImageView:create("zhuzhou/gameend/wz_fangpao.png")
            uiPanel_tricks:addChild(img)
            img:setPosition(img:getParent():getContentSize().width/2, img:getParent():getContentSize().height/2)
        end 
      --  wProvideUser

        uiAtlasLabel_num:setProperty(string.format("%d",pBuffer.lGameScore[i]),"zhuzhou/gameend/number2.png",21,30,'0')    
        local uiImage_hu = ccui.Helper:seekWidgetByName(root,"Image_hu")
        if pBuffer.lGameScore[i] >=100 then  
            uiImage_hu:setPositionX(60.00)
        end 
        if pBuffer.lGameScore[i] <=-100 then  
            uiImage_hu:setPositionX(70.00)
        elseif pBuffer.lGameScore[i] <=-10 then
            uiImage_hu:setPositionX(60.00)
        end 
        if GameCommon.tableConfig.nTableType == TableType_GoldRoom then
            uiImage_hu:setVisible(false)
        end
       
        local uiAtlasLabel_peng = ccui.TextAtlas:create(string.format("%d",pBuffer.lPengWeiTiPaoScore[i]),"zhuzhou/gameend/number2.png",21,30,'0')
        uiAtlasLabel_num:addChild(uiAtlasLabel_peng)
        uiAtlasLabel_peng:setPosition(160.00,15)

        if pBuffer.lPengWeiTiPaoScore[i] < 0 then         
            local di = cc.Sprite:create('zhuzhou/gameend/img_sub.png')
            uiAtlasLabel_peng:addChild(di)
            di:setPosition(-20.00,15)
        end 

        local uiAtlasLabel_hu = ccui.TextAtlas:create(string.format("%d",pBuffer.lHuScore[i]),"zhuzhou/gameend/number2.png",21,30,'0')
        uiAtlasLabel_num:addChild(uiAtlasLabel_hu)
        uiAtlasLabel_hu:setPosition(240.00,100)

        if pBuffer.lHuScore[i] < 0 then         
            local di = cc.Sprite:create('zhuzhou/gameend/img_sub.png')
            uiAtlasLabel_hu:addChild(di)
            di:setPosition(-20.00,15)
        end 

        local uiPanel_ShowCard = ccui.Helper:seekWidgetByName(root,"Panel_ShowCard")
        local cardScale = 0.5
        local cardWidth = 86 * cardScale
        local cardHeight = 104 * cardScale
        local stepX = cardWidth
        local stepY = cardHeight * 0.7
        local size = uiPanel_ShowCard:getContentSize()
        local beganX = 0
        local beganX_2 = 0
        local cardStackInfo =  GameCommon.playerEnd[wChairID].cardStackInfo
        for key, var in pairs(cardStackInfo) do            
            for k, v in pairs(var.cbCardData) do
                local card = GameCommon:GetCardHand(v.data)
                uiPanel_ShowCard:addChild(card)
                v.node = card
                card:setLocalZOrder(4-k)
                index = index + 1
                card:setPosition(beganX + key*stepX - cardWidth/2, stepY*(k-1) + cardHeight/2)
                card:setScale(cardScale)
                beganX_2 = beganX + key*stepX - cardWidth/2 + 20
            end
        end

        local num = pBuffer.HuCardInfo[i].cbWeaveCount       
        if ShowPlayer == true and  num ~= nil and  num ~= 0 then           
            local cardWidth = 78 * cardScale
            local cardHeight = 236 * cardScale
            local stepX = cardWidth            
            for WeaveItemIndex = 1 , pBuffer.HuCardInfo[i].cbWeaveCount do                               
                local WeaveItemArray= pBuffer.HuCardInfo[i].WeaveItemArray[WeaveItemIndex]            --组合扑克
                for i = 1 , WeaveItemArray.cbCardCount do
                    if WeaveItemArray.cbCardCount == 4 then 
                        print ("++++++WeaveItemArray.cbCardCount++++++++",WeaveItemIndex,WeaveItemArray.cbCardList[i])
                    end  
                    local data = WeaveItemArray.cbCardList[i]
                    local _spt = GameCommon:getSendOrOutCard(data)   
                    _spt:setPosition(beganX_2+30 + i*stepX - cardWidth/2 ,cardHeight/2)
                    _spt:setScale(cardScale)
                    uiPanel_ShowCard:addChild(_spt)                 
                end   

                local WeaveType=self:getSptWeaveType(WeaveItemArray.cbWeaveKind)
                if WeaveType then
                    WeaveType:setPosition(cc.p(beganX_2 + WeaveItemArray.cbCardCount*stepX*3/4,cardHeight))
                    uiPanel_ShowCard:addChild(WeaveType)
                end
                
                beganX_2 = beganX_2 + WeaveItemArray.cbCardCount*stepX + 20
            end 

        end
        if wChairID == pBuffer.wWinUser and pBuffer.cbHuCard ~= 0 then 
            local _spt=GameCommon:getSendOrOutCard(pBuffer.cbHuCard)
            local di = cc.Sprite:create('zhuzhou/table/card_out_card_bj.png')
            _spt:addChild(di)
            local size = _spt:getContentSize()
            di:setPosition(size.width / 2,size.height / 2)
            _spt:setPosition(beganX_2+60-cardWidth/2 ,cardHeight/2+30)
            _spt:setScale(0.6)
            uiPanel_ShowCard:addChild(_spt)  
        end 



    end

end

function GameEndLayer:addimg(pBuffer)
    self.MINGTANG_NULL		= 0x0000    --默认
	self.MINGTANG_7Dui		= 0x0001    --小七对
	self.MINGTANG_5Fu		= 0x0002    --五福
	self.MINGTANG_TianHu	= 0x0004    --天胡
	self.MINGTANG_DiHu		= 0x0008    --地胡
	self.MINGTANG_2Long		= 0x0010    --双龙
	self.MINGTANG_Sao4Qing	= 0x0020    --扫四清连胡
	self.MINGTANG_4Qing		= 0x0040    --四清连胡
	self.MINGTANG_Sao3Da	= 0x0080    --扫三大连胡
	self.MINGTANG_3Da		= 0x0100    --三大连胡
	self.MINGTANG_Ti		= 0x0200    --提起连胡
	self.MINGTANG_Pao		= 0x0400    --跑起连胡
	self.MINGTANG_Sao		= 0x0800    --扫胡
	self.MINGTANG_Peng		= 0x1000    --碰胡
	self.MINGTANG_Ping		= 0x2000    --平胡
    self.MINGTANG_MAX		= 0x2000+1      --默认
    print("+++++++++pBuffer++++++++++++",pBuffer.cbHuType)
    if pBuffer.cbHuType == 0 then   
        local di = cc.Sprite:create('zhuzhou/gameend/huflag_12.png')
        return di
    end
    if Bit:_and(pBuffer.cbHuType, self.MINGTANG_7Dui) ~= 0 then   
        local di = cc.Sprite:create('zhuzhou/gameend/huflag_2.png')
        return di
    end
    if Bit:_and(pBuffer.cbHuType, self.MINGTANG_5Fu) ~= 0 then   
        local di = cc.Sprite:create('zhuzhou/gameend/huflag_4.png')
        return di
    end
    if Bit:_and(pBuffer.cbHuType, self.MINGTANG_TianHu) ~= 0 then   
        local di = cc.Sprite:create('zhuzhou/gameend/huflag_0.png')
        return di
    end
    if Bit:_and(pBuffer.cbHuType, self.MINGTANG_DiHu) ~= 0 then   
        local di = cc.Sprite:create('zhuzhou/gameend/huflag_1.png')
        return di
    end
    if Bit:_and(pBuffer.cbHuType, self.MINGTANG_2Long) ~= 0 then   
        local di = cc.Sprite:create('zhuzhou/gameend/huflag_3.png')
        return di
    end
    if Bit:_and(pBuffer.cbHuType, self.MINGTANG_Sao4Qing) ~= 0 then   
        local di = cc.Sprite:create('zhuzhou/gameend/huflag_11.png')
        return di
    end
    if Bit:_and(pBuffer.cbHuType, self.MINGTANG_4Qing) ~= 0 then   
        local di = cc.Sprite:create('zhuzhou/gameend/huflag_7.png')
        return di
    end
    if Bit:_and(pBuffer.cbHuType, self.MINGTANG_Sao3Da) ~= 0 then   
        local di = cc.Sprite:create('zhuzhou/gameend/huflag_10.png')
        return di
    end
    if Bit:_and(pBuffer.cbHuType, self.MINGTANG_3Da) ~= 0 then   
        local di = cc.Sprite:create('zhuzhou/gameend/huflag_8.png')
        return di
    end
    
    if Bit:_and(pBuffer.cbHuType, self.MINGTANG_Ti) ~= 0 then   
        local di = cc.Sprite:create('zhuzhou/gameend/huflag_5.png')
        return di
    end    

    if Bit:_and(pBuffer.cbHuType, self.MINGTANG_Pao) ~= 0 then   
        local di = cc.Sprite:create('zhuzhou/gameend/huflag_6.png')
        return di
    end
    
    
    if Bit:_and(pBuffer.cbHuType, self.MINGTANG_Sao) ~= 0 then   
        local di = cc.Sprite:create('zhuzhou/gameend/huflag_13.png')
        return di
    end

    if Bit:_and(pBuffer.cbHuType, self.MINGTANG_Peng) ~= 0 then   
        local di = cc.Sprite:create('zhuzhou/gameend/huflag_9.png')
        return di
    end

    if Bit:_and(pBuffer.cbHuType, self.MINGTANG_Ping) ~= 0 then   
        local di = cc.Sprite:create('zhuzhou/gameend/huflag_12.png')
        return di
    end

    -- if Bit:_and(pBuffer.cbHuType, self.MINGTANG_Ping) ~= 0 then   
    --     local di = cc.Sprite:create('zhuzhou/gameend/huflag_12.png')
    --     return di
	-- end
end 

function GameEndLayer:getSptWeaveType(type)
    local sptname = ""
    if type == GameCommon.ACK_TI then
        sptname="zhuzhou/gameend/wz_tilong.png"
    elseif type == GameCommon.ACK_PAO then
        sptname="zhuzhou/gameend/wz_pao.png"
    elseif type == GameCommon.ACK_WEI then
        sptname="zhuzhou/gameend/wz_kan.png"
    elseif type == GameCommon.ACK_CHI then
        sptname="zhuzhou/gameend/wz_chi.png"
    elseif type == GameCommon.ACK_PENG then
        sptname="zhuzhou/gameend/wz_peng.png"
    else
       
    end
    return cc.Sprite:create(sptname)
    
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
            require("common.MsgBoxLayer"):create(2,nil,"您的金币不足,请前往商城充值!",function() require("common.SceneMgr"):switchOperation(require("app.MyApp"):create(2):createView("MallLayer")) end)
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
