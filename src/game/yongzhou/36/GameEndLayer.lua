local GameCommon = require("game.yongzhou.GameCommon")
local Bit = require("common.Bit")
local StaticData = require("app.static.StaticData")
local EventType = require("common.EventType")
local EventMgr = require("common.EventMgr")
local GameLogic = require("game.yongzhou.GameLogic")
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
    self.PHZ_HT_NO = 0              --NULL
    self.PHZ_HT_ZIMO = 1              --自　摸   自己摸出的牌胡了                                                                                                                                (X 2倍)
    self.PHZ_HT_HONGHU = 2              --红　胡   红字>=10                                                                                                                                          (X 2倍)
    self.PHZ_HT_DIANHU = 4              --点胡    只有一张红字                                                                                                                                          (X 3倍)
    self.PHZ_HT_HONGZHUANDIAN  = 0x0008              --红转点
    self.PHZ_HT_HONGZHUANHEI =0x0010              --红转黑
    self.PHZ_HT_HEIWU = 32              --黑乌    红字＝0，即全部是黑字                                                                                                                         (X 4倍)
    self.PHZ_HT_WD = 64              --王钓                                                                                                                                                                    (X 4倍)
    self.PHZ_HT_WDW = 128              --王钓王                                                                                                                                                               (X 8倍)
    self.PHZ_HT_WC = 256              --王闯 
    self.PHZ_HT_WCW = 0x0200              --王闯王 
    self.PHZ_HT_3WC = 0x0400              --三王闯
    self.PHZ_HT_3WCW = 0x0800              --三王闯王 
    local visibleSize = cc.Director:getInstance():getVisibleSize()
    local csb = cc.CSLoader:createNode("YZGameLayerZiPai_End.csb")
    self:addChild(csb)
    self.root = csb:getChildByName("Panel_root")   

    self.root:setPositionY(visibleSize.height*3/2)
    self.root:runAction(cc.MoveTo:create(0.5,cc.p(visibleSize.width/2, visibleSize.height/2)))
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
    local uiPanel_look = ccui.Helper:seekWidgetByName(self.root,"Panel_look")
    local uiButton_look = ccui.Helper:seekWidgetByName(self.root,"Button_look")
    GameCommon.uiPanel_showEndCard:setVisible(false)
    Common:addTouchEventListener(uiButton_look,function() 
        if uiPanel_look:isVisible() then
            uiPanel_look:setVisible(false)
            uiButton_look:setBright(false)
            GameCommon.uiPanel_showEndCard:setVisible(true)
        else
            uiPanel_look:setVisible(true)
            uiButton_look:setBright(true)
            GameCommon.uiPanel_showEndCard:setVisible(false)
        end
    end)    
    local  integral = nil
	self.WPnumber = 0
	local number = 0
    for i=1 , GameCommon.gameConfig.bPlayerCount do
        if number < pBuffer.lGameScore[i] then 
            number = pBuffer.lGameScore[i]
        end
        print("玩家得分",pBuffer.lGameScore[i],number)    
    end  

    local uiPanel_result = ccui.Helper:seekWidgetByName(self.root,"Panel_result")
    local viewID = GameCommon:getViewIDByChairID(pBuffer.wWinUser)
    
    local uiImage_bg = ccui.Helper:seekWidgetByName(self.root,"Image_bg")
    if viewID == 1 then
        uiImage_bg:loadTexture("yongzhou/ui/yongzhou_gameendying.png")
    end 
    ccs.ArmatureDataManager:getInstance():addArmatureFileInfo("yongzhou/anim/jiesuanshuying/jiesuanshuying.ExportJson")
    local waitArmature=ccs.Armature:create("jiesuanshuying")
    waitArmature:setPosition(0,-100)            
    if GameCommon.gameConfig.bPlayerCount == 3 then        
        if viewID == 2 then --上家赢      
            waitArmature:getAnimation():playWithIndex(2)
            uiPanel_result:addChild(waitArmature)
        elseif viewID == 1 then --自己赢  
            waitArmature:getAnimation():playWithIndex(0)
            uiPanel_result:addChild(waitArmature) 
        elseif viewID == 3 then --下家赢    
            waitArmature:getAnimation():playWithIndex(1)
            uiPanel_result:addChild(waitArmature)   
        else
            --无放炮
        end       
    elseif GameCommon.gameConfig.bPlayerCount == 4 then             
        if viewID == 2 then --上家赢     
            waitArmature:getAnimation():playWithIndex(2)
            uiPanel_result:addChild(waitArmature)
        elseif viewID == 1 then --自己赢    
            waitArmature:getAnimation():playWithIndex(0)
            uiPanel_result:addChild(waitArmature)
        elseif viewID == 4 then --下家赢
            waitArmature:getAnimation():playWithIndex(1)
            uiPanel_result:addChild(waitArmature)
        elseif viewID == 3 then  --对家赢 
            waitArmature:getAnimation():playWithIndex(3)
            uiPanel_result:addChild(waitArmature)
        else
            --无放炮
        end
    elseif GameCommon.gameConfig.bPlayerCount == 2 then     
        if viewID == 1 then --自己赢 
            waitArmature:getAnimation():playWithIndex(0)
            uiPanel_result:addChild(waitArmature)
        else
            waitArmature:getAnimation():playWithIndex(3)
            uiPanel_result:addChild(waitArmature)
        end
    end   

    local uiText_beilv = ccui.Helper:seekWidgetByName(self.root,"Text_beilv")
    uiText_beilv:setString(string.format("倍率：%d",pBuffer.wBeilv))
    local uiText_xiaohao = ccui.Helper:seekWidgetByName(self.root,"Text_xiaohao")
    uiText_xiaohao:setString(string.format("本局消耗：%d",pBuffer.lGameTax))


    local uiText_room = ccui.Helper:seekWidgetByName(self.root,"Text_room")
    local uiText_num = ccui.Helper:seekWidgetByName(self.root,"Text_num")
    uiText_room:setVisible(false)
    uiText_num:setVisible(false)
    if GameCommon.tableConfig.nTableType ~= TableType_GoldRoom then
        uiText_beilv:setVisible(false)
        uiText_xiaohao:setVisible(false)
        if GameCommon.tableConfig.nTableType >= TableType_GoldRoom then    
            uiText_room:setString(string.format("房间号：%d",GameCommon.tableConfig.wTbaleID)) 
            uiText_num:setString(string.format("局数：%d/%d",GameCommon.tableConfig.wCurrentNumber,GameCommon.tableConfig.wTableNumber))
            uiText_room:setVisible(true)   
            uiText_num:setVisible(true)
        end
    else
        uiText_beilv:setVisible(true)
        uiText_xiaohao:setVisible(true)
    end
    
    --结算信息
    local uiListView_info = ccui.Helper:seekWidgetByName(self.root,"ListView_info")
    local uiPanel_defaultInfo = ccui.Helper:seekWidgetByName(self.root,"Panel_defaultInfo")
    uiPanel_defaultInfo:retain()
    uiListView_info:removeAllItems()
    
    local item = uiPanel_defaultInfo:clone()
    local uiImage_name = ccui.Helper:seekWidgetByName(item,"Image_name")
    uiImage_name = ccui.ImageView:create("yongzhou/ui/yongzhou_gameend2.png")
    item:addChild(uiImage_name)
    uiImage_name:setAnchorPoint(cc.p(0,0.5))
    uiImage_name:setPosition(0,uiImage_name:getParent():getContentSize().height/2)
    local uiAtlasLabel_num = ccui.TextAtlas:create(string.format("%d",pBuffer.HuCardInfo.cbHuXiCount),"yongzhou/ui/yongzhou_gameendnum.png",17,24,'0')
    item:addChild(uiAtlasLabel_num)
    uiAtlasLabel_num:setAnchorPoint(cc.p(1,0.5))
    uiAtlasLabel_num:setPosition(uiAtlasLabel_num:getParent():getContentSize().width,uiAtlasLabel_num:getParent():getContentSize().height/2)
    uiListView_info:pushBackCustomItem(item)
    
    local item = uiPanel_defaultInfo:clone()
    local uiImage_name = ccui.Helper:seekWidgetByName(item,"Image_name")
    uiImage_name = ccui.ImageView:create("yongzhou/ui/yongzhou_gameend1.png")
    item:addChild(uiImage_name)
    uiImage_name:setAnchorPoint(cc.p(0,0.5))
    uiImage_name:setPosition(0,uiImage_name:getParent():getContentSize().height/2)
    local uiAtlasLabel_num = ccui.TextAtlas:create(string.format("%d",pBuffer.wFanCount),"yongzhou/ui/yongzhou_gameendnum.png",17,24,'0')
    item:addChild(uiAtlasLabel_num)
    uiAtlasLabel_num:setAnchorPoint(cc.p(1,0.5))
    uiAtlasLabel_num:setPosition(uiAtlasLabel_num:getParent():getContentSize().width,uiAtlasLabel_num:getParent():getContentSize().height/2)
    uiListView_info:pushBackCustomItem(item)
    
    local item = uiPanel_defaultInfo:clone()
    local uiImage_name = ccui.Helper:seekWidgetByName(item,"Image_name")
    uiImage_name = ccui.ImageView:create("yongzhou/ui/yongzhou_gameend3.png")
    item:addChild(uiImage_name)
    uiImage_name:setAnchorPoint(cc.p(0,0.5))
    uiImage_name:setPosition(0,uiImage_name:getParent():getContentSize().height/2)
    local uiAtlasLabel_num = ccui.TextAtlas:create(string.format("%d",pBuffer.wTun),"yongzhou/ui/yongzhou_gameendnum.png",17,24,'0')
    item:addChild(uiAtlasLabel_num)
    uiAtlasLabel_num:setAnchorPoint(cc.p(1,0.5))
    uiAtlasLabel_num:setPosition(uiAtlasLabel_num:getParent():getContentSize().width,uiAtlasLabel_num:getParent():getContentSize().height/2)
    uiListView_info:pushBackCustomItem(item)
    
    local item = uiPanel_defaultInfo:clone()
    local uiImage_name = ccui.Helper:seekWidgetByName(item,"Image_name")
    uiImage_name = ccui.ImageView:create("yongzhou/ui/yongzhou_gameend4.png")
    item:addChild(uiImage_name)
    uiImage_name:setAnchorPoint(cc.p(0,0.5))
    uiImage_name:setPosition(0,uiImage_name:getParent():getContentSize().height/2)
    local uiAtlasLabel_num = ccui.TextAtlas:create(string.format("%d",pBuffer.wTun*pBuffer.wFanCount),"yongzhou/ui/yongzhou_gameendnum.png",17,24,'0')
    item:addChild(uiAtlasLabel_num)
    uiAtlasLabel_num:setAnchorPoint(cc.p(1,0.5))
    uiAtlasLabel_num:setPosition(uiAtlasLabel_num:getParent():getContentSize().width,uiAtlasLabel_num:getParent():getContentSize().height/2)
    uiListView_info:pushBackCustomItem(item)
    uiPanel_defaultInfo:release()
    local ListView_Characterbox = nil
	local ListView_Characterbox4 = ccui.Helper:seekWidgetByName(self.root,"ListView_Characterbox4")
    ListView_Characterbox4:setVisible(false)    
    local ListView_Characterbox3 = ccui.Helper:seekWidgetByName(self.root,"ListView_Characterbox3")
    ListView_Characterbox3:setVisible(false)
    local ListView_Characterbox2 = ccui.Helper:seekWidgetByName(self.root,"ListView_Characterbox2")
    ListView_Characterbox2:setVisible(false)
    
    if GameCommon.gameConfig.bPlayerCount == 3 then
        ListView_Characterbox3:setVisible(true)
        ListView_Characterbox = ListView_Characterbox3
    elseif GameCommon.gameConfig.bPlayerCount == 4 then
        ListView_Characterbox4:setVisible(true)
        ListView_Characterbox = ListView_Characterbox4
    elseif GameCommon.gameConfig.bPlayerCount == 2 then
        ListView_Characterbox2:setVisible(true)
        ListView_Characterbox = ListView_Characterbox2
    end 
    for key, var in pairs(GameCommon.player) do    
        local viewID = GameCommon:getViewIDByChairID(var.wChairID)           
        local root = ccui.Helper:seekWidgetByName(ListView_Characterbox,string.format("Panel_Characterbox%d",viewID))
        local uiImage_avatar = ccui.Helper:seekWidgetByName(root,"Image_avatar")
        Common:requestUserAvatar(var.dwUserID,var.szPto,uiImage_avatar,"img") 
        local uiText_name = ccui.Helper:seekWidgetByName(root,"Text_name")       
        uiText_name:setString(string.format("%s",var.szNickName)) 
        local uiText_ID = ccui.Helper:seekWidgetByName(root,"Text_ID")       
        uiText_ID:setString(string.format("ID:%s",var.dwUserID)) 
        local uiAtlasLabel_money = ccui.Helper:seekWidgetByName(root,"Text_money")
        if GameCommon.tableConfig.nTableType == TableType_GoldRoom or GameCommon.tableConfig.nTableType  == TableType_SportsRoom then
            uiText_ID:setVisible(false)
        end
        local dwGold = Common:itemNumberToString(pBuffer.lGameScore[var.wChairID + 1])   
        if pBuffer.lGameScore[var.wChairID + 1] > 0 then 
            uiAtlasLabel_money:setString('+' ..tostring(dwGold))
        else      
            uiAtlasLabel_money:setString(tostring(dwGold))
        end      
    --    uiAtlasLabel_money:setString(string.format("%d",pBuffer.lGameScore[var.wChairID+1] ))
       
        if var.wChairID == GameCommon.meChairID then 
            uiText_name:setColor(cc.c3b(255,255,0))
            uiAtlasLabel_money:setColor(cc.c3b(255,255,0))
        end 

        if GameCommon.gameConfig.bPlayerCount == 4 then
            local uiImage_banker = ccui.Helper:seekWidgetByName(root,"Image_banker")
            uiImage_banker:setVisible(false)
            local duijia = (GameCommon.wBankerUser - 1 + GameCommon.gameConfig.bPlayerCount - 1) % GameCommon.gameConfig.bPlayerCount
            if var.wChairID == duijia then
                uiImage_banker:loadTexture("yongzhou/ui/yongzhou_zuoxing.png")
                local texture = cc.TextureCache:getInstance():addImage("yongzhou/ui/yongzhou_zuoxing.png")
                uiImage_banker:setContentSize(texture:getContentSizeInPixels())
                uiImage_banker:setVisible(true)
            end
        end
    end
    self:showPaiXing(pBuffer)
    self:showMingTang(pBuffer)
    self:showDiPai(pBuffer)
    local uiText_time = ccui.Helper:seekWidgetByName(self.root,"Text_time")
    -- uiText_time:runAction(cc.RepeatForever:create(cc.Sequence:create(cc.CallFunc:create(function(sender,event) 
        local date = os.date("*t",os.time())
        uiText_time:setString(string.format("%d-%d-%d %02d:%02d:%02d",date.year,date.month,date.day,date.hour,date.min,date.sec))
    -- end),cc.DelayTime:create(1))))
end

--显示牌型和眼牌
function GameEndLayer:showPaiXing(pBuffer)
    local uiListView_weave = ccui.Helper:seekWidgetByName(self.root,"ListView_weave")
    local uiPanel_defaultWeave = ccui.Helper:seekWidgetByName(self.root,"Panel_defaultWeave")
    uiPanel_defaultWeave:retain()
    uiListView_weave:removeAllChildren()
    local WWdata = {}
    WWdata[1]=pBuffer.HuCardInfo.cbWWData[1]
    WWdata[2]=pBuffer.HuCardInfo.cbWWData[2]
    
     print("手排",pBuffer.HuCardInfo.cbWeaveCount )
    for WeaveItemIndex = 1 , pBuffer.HuCardInfo.cbWeaveCount do
        local item = uiPanel_defaultWeave:clone()
        local   WeaveItemArray= clone(pBuffer.HuCardInfo.WeaveItemArray[WeaveItemIndex] )           --组合扑克
        for i = 1 , WeaveItemArray.cbCardCount do
            local data = WeaveItemArray.cbCardList[i]
            local _spt=GameCommon:getDiscardCardAndWeaveItemArray(data)
            _spt:setPosition(cc.p(0,(i-1)*GameCommon.CARD_HUXI_HEIGHT))
            _spt:setAnchorPoint(cc.p(0,0))
            item:addChild(_spt,10-(i-1))
        end

        local WeaveType=self:getSptWeaveType(WeaveItemArray.cbWeaveKind)
        WeaveType:setPosition(cc.p(GameCommon.CARD_HUXI_WIDTH*0.5,5*GameCommon.CARD_HUXI_HEIGHT))
        item:addChild(WeaveType)

        local huxicout=GameLogic:GetWeaveHuXi(clone(WeaveItemArray))
        local Weavecout=cc.Label:createWithSystemFont(string.format("%d",huxicout), "Arial", 30)
        Weavecout:setPosition(cc.p(GameCommon.CARD_HUXI_WIDTH*0.5,-GameCommon.CARD_HUXI_HEIGHT + 20))
        item:addChild(Weavecout)

        uiListView_weave:pushBackCustomItem(item)
    end
    uiPanel_defaultWeave:release()
    --眼牌
    if pBuffer.HuCardInfo.cbWeaveCount <= 6 and pBuffer.HuCardInfo.cbCardEye ~=0 then
        local item = uiPanel_defaultWeave:clone()
        for i = 1 , 2 do
            local data = pBuffer.HuCardInfo.cbCardEye
            if i <= pBuffer.HuCardInfo.cbCountWWInCardEye then
                data = GameCommon.CardData_WW
            end
            local _spt=GameCommon:getDiscardCardAndWeaveItemArray(data)
            _spt:setPosition(cc.p(0,i*GameCommon.CARD_HUXI_HEIGHT-40))
            _spt:setAnchorPoint(cc.p(0,0))
            item:addChild(_spt)
        end
        uiListView_weave:pushBackCustomItem(item)
    end 
end

--显示名堂
function GameEndLayer:showMingTang(pBuffer)
    local uiListView_player = ccui.Helper:seekWidgetByName(self.root,"ListView_player")
    local uiPanel_defaultPalyer = ccui.Helper:seekWidgetByName(self.root,"Panel_defaultPalyer")
    uiPanel_defaultPalyer:retain()
    uiListView_player:removeAllItems() 
    local imageView = ccui.ImageView:create("yongzhou/ui/yongzhou_endwbw.png")
    --王牌    
    for  i =1 , 4 do
        if(pBuffer.HuCardInfo.cbWWData[i]~=0) then      
            self.WPnumber = self.WPnumber +1
            local _spt=GameCommon:getDiscardCardAndWeaveItemArray(pBuffer.HuCardInfo.cbWWData[i])
            _spt:setPosition(cc.p(134+40*self.WPnumber,22))
            imageView:addChild(_spt)           
        end
    end
    if self.WPnumber == 0 then 
        imageView:setVisible(false)
    end 
    uiListView_player:pushBackCustomItem(imageView)
    self.WPnumber = 0
    --翻省
    for i = 1, 2 do
        if pBuffer.fanXing[i].cbShengCard ~= 0 then
            if GameCommon.gameConfig.FanXing.bType == 1 or GameCommon.gameConfig.FanXing.bType == 2 then
                local item = uiPanel_defaultPalyer:clone()
                self:createMingTang(item,"fanxing",pBuffer.fanXing[i].cbShengCout,"+")
                local _spt=GameCommon:getDiscardCardAndWeaveItemArray(pBuffer.fanXing[i].cbShengCard)
                _spt:setPosition(cc.p(100,20))
                item:addChild(_spt)
                uiListView_player:pushBackCustomItem(item)        
            elseif GameCommon.gameConfig.FanXing.bType == 3 then 
                local item = uiPanel_defaultPalyer:clone()
                self:createMingTang(item,"genxing",pBuffer.fanXing[i].cbShengCout,"+")
                local _spt=GameCommon:getDiscardCardAndWeaveItemArray(pBuffer.fanXing[i].cbShengCard)
                _spt:setPosition(cc.p(100,20))
                item:addChild(_spt)
                uiListView_player:pushBackCustomItem(item)

            end
        end
    end
    if Bit:_and(pBuffer.wType , self.PHZ_HT_ZIMO) ~=0 then
        local item = uiPanel_defaultPalyer:clone()
        self:createMingTang(item,"zimo")
        uiListView_player:pushBackCustomItem(item)
    end
    
    if Bit:_and(pBuffer.wType , self.PHZ_HT_HONGZHUANHEI) ~=0 then
        local item = uiPanel_defaultPalyer:clone()
        self:createMingTang(item,"hongzhuanhei")
        uiListView_player:pushBackCustomItem(item)
    end
    
    if Bit:_and(pBuffer.wType , self.PHZ_HT_HONGZHUANDIAN) ~=0 then
        local item = uiPanel_defaultPalyer:clone()
        self:createMingTang(item,"hongzhuandian")
        uiListView_player:pushBackCustomItem(item)
    end
    
    if Bit:_and(pBuffer.wType , self.PHZ_HT_HONGHU) ~=0 then
        local item = uiPanel_defaultPalyer:clone()
        self:createMingTang(item,"honghu")
        uiListView_player:pushBackCustomItem(item)
    end

    if Bit:_and(pBuffer.wType , self.PHZ_HT_DIANHU) ~=0 then
        local item = uiPanel_defaultPalyer:clone()
        self:createMingTang(item,"dianhu")
        uiListView_player:pushBackCustomItem(item)
    end

    if Bit:_and(pBuffer.wType , self.PHZ_HT_HEIWU) ~=0 then
        local item = uiPanel_defaultPalyer:clone()
        self:createMingTang(item,"heihu")
        uiListView_player:pushBackCustomItem(item)
    end

    if Bit:_and(pBuffer.wType , self.PHZ_HT_WD) ~=0 then
        local item = uiPanel_defaultPalyer:clone()
        self:createMingTang(item,"wwwangdiao")
        uiListView_player:pushBackCustomItem(item)
    end

    if Bit:_and(pBuffer.wType , self.PHZ_HT_WDW) ~=0 then
        local item = uiPanel_defaultPalyer:clone()
        self:createMingTang(item,"wwwangdiaowang")
        uiListView_player:pushBackCustomItem(item)
    end

    if Bit:_and(pBuffer.wType , self.PHZ_HT_WC) ~=0 then
        local item = uiPanel_defaultPalyer:clone()
        self:createMingTang(item,"wwwangchuang")
        uiListView_player:pushBackCustomItem(item)
    end
    if Bit:_and(pBuffer.wType , self.PHZ_HT_WCW) ~=0 then  --王闯王
        local item = uiPanel_defaultPalyer:clone()
        self:createMingTang(item,"wwwcw")
        uiListView_player:pushBackCustomItem(item)
    end
    if Bit:_and(pBuffer.wType , self.PHZ_HT_3WC) ~=0 then  --三王闯
        local item = uiPanel_defaultPalyer:clone()
        self:createMingTang(item,"ww3wc")
        uiListView_player:pushBackCustomItem(item)
    end
    if Bit:_and(pBuffer.wType , self.PHZ_HT_3WCW) ~=0 then --三王闯王
        local item = uiPanel_defaultPalyer:clone()
        self:createMingTang(item,"ww3wcw")
        uiListView_player:pushBackCustomItem(item)
    end
    uiPanel_defaultPalyer:release()
end

 function GameEndLayer:createMingTang(item,mingTang,num,numType)
    local uiImage_name = ccui.ImageView:create(string.format("yongzhou/ui/yongzhou_%s.png",mingTang))
    item:addChild(uiImage_name)
    uiImage_name:setAnchorPoint(cc.p(0,0.5))--uiImage_name:getParent():getContentSize().width*0.2
    uiImage_name:setPosition(cc.p(0,uiImage_name:getParent():getContentSize().height/2))

    if num ~= nil then 
        local uiAtlasLabel_num = ccui.TextAtlas:create(string.format("%d",num),"yongzhou/ui/yongzhou_endfont.png",19,26,'0')
        item:addChild(uiAtlasLabel_num)
        uiAtlasLabel_num:setAnchorPoint(cc.p(0,0.5))
        uiAtlasLabel_num:setPosition(cc.p(uiAtlasLabel_num:getParent():getContentSize().width*0.585,uiAtlasLabel_num:getParent():getContentSize().height/2))
    end 
end

--显示底牌
function GameEndLayer:showDiPai(pBuffer)
    local visibleSize = cc.Director:getInstance():getVisibleSize()
    local uiListView_diPai1 = ccui.Helper:seekWidgetByName(self.root,"ListView_diPai1")
    local uiListView_diPai2 = ccui.Helper:seekWidgetByName(self.root,"ListView_diPai2")
    local uiPanel_diPai = ccui.Helper:seekWidgetByName(self.root,"Panel_diPai")    
    local width= 62.00
    local num = 0
    local height = 42 
    for i = 1, pBuffer.bLeftCardCount do
        if pBuffer.bLeftCardData[i] ~= 0 then
            local item = GameCommon:getDiscardCardAndWeaveItemArray(pBuffer.bLeftCardData[i])
            if i<= 21 then
                uiListView_diPai1:pushBackCustomItem(item)      
                num = num + 1         
            else
                uiListView_diPai2:pushBackCustomItem(item)
                uiPanel_diPai:setPosition(visibleSize.width*0.5,visibleSize.height*0.4049)
                --uiListView_diPai2:setPositionX(66.00)
            end
        end
    end
    width = width + num*42 
    uiListView_diPai1:setContentSize(width,height)

end

function GameEndLayer:getSptWeaveType(type)

    local sptname = ""
    if type == GameCommon.ACK_TI then
        sptname="yongzhou/ui/endlayer14.png"
    elseif type == GameCommon.ACK_PAO then
        sptname="yongzhou/ui/endlayer9.png"
    elseif type == GameCommon.ACK_WEI then
        sptname="yongzhou/ui/endlayer7.png"
    elseif type == GameCommon.ACK_CHI then
        sptname="yongzhou/ui/endlayer8.png"
    elseif type == GameCommon.ACK_PENG then
        sptname="yongzhou/ui/endlayer10.png"
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
            require("common.MsgBoxLayer"):create(2,nil,"您的金币不足,请前往商城充值!",function() require("common.SceneMgr"):switchOperation(require("app.MyApp"):create(2):createView("NewMallLayer")) end)
        else
            require("common.MsgBoxLayer"):create(1,nil,"您的金币不足,请联系代理购买！",function() require("common.SceneMgr"):switchOperation(require("app.MyApp"):create():createView("GuilLayer"))  end)
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
