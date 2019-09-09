local GameCommon = require("game.cdphz.GameCommon")
local EventType = require("common.EventType")
local EventMgr = require("common.EventMgr")
local NetMgr = require("common.NetMgr")
local NetMsgId = require("common.NetMsgId")
local Bit = require("common.Bit")
local StaticData = require("app.static.StaticData")
local Common = require("common.Common")
local GameLogic = require("game.cdphz.GameLogic")
local UserData = require("app.user.UserData")
local Base64 = require("common.Base64")

local GameEndLayer = class("GameEndLayer", function()
	return ccui.Layout:create()
end)


--位置设置
local Pos = {
	[2] = {
		cc.p(105, 410),
		cc.p(105, 120),
	},
	[3] = {
		cc.p(105, 410),
		cc.p(105, 120),
		cc.p(990, 120),
	},
	[4] = {
		cc.p(105, 410),
		cc.p(105, 120),
		cc.p(585, 120),
		cc.p(990, 120),
	}
}


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
    EventMgr:registListener(EventType.CUS_GAMEENDlAYER_CLIENT,self,self.CUS_GAMEENDlAYER_CLIENT)

    self:runAction(cc.Sequence:create(cc.DelayTime:create(0), cc.CallFunc:create(function(sender, event)
        require("common.Common"):screenshot(FileName.battlefieldScreenshot)
    end)))
end

function GameEndLayer:onExit()
    EventMgr:unregistListener(EventType.SUB_GR_MATCH_TABLE_FAILED,self,self.SUB_GR_MATCH_TABLE_FAILED)
    EventMgr:unregistListener(EventType.CUS_GAMEENDlAYER_CLIENT,self,self.CUS_GAMEENDlAYER_CLIENT)
end

function GameEndLayer:onCleanup()

end

--更新人物信息
function GameEndLayer:updatePlayerInfo(pBuffer)
	local pos = Pos[GameCommon.gameConfig.bPlayerCount]
	local index = 1
	local itemCache = {}
	for i = 1, GameCommon.gameConfig.bPlayerCount do
		local item = self.playerInfo_template:clone()
		self.panel_look:addChild(item)
		itemCache[i] = item
		item:setPosition(pos[i])
	end
	
	local index = 2
	for key, var in pairs(GameCommon.player) do
		local item = nil
		if var.wChairID == pBuffer.wWinUser then --赢家
			item = itemCache[1]
			local dwGold = Common:itemNumberToString(pBuffer.lGameScore[var.wChairID + 1])   
			self.text_total:setString('共计:' ..tostring(dwGold))
		else
			item = itemCache[index]
			index = index + 1
		end
		local avatar = ccui.Helper:seekWidgetByName(item, "Image_avatar")
		Common:requestUserAvatar(var.dwUserID, var.szPto, avatar, 'img')
		local Image_zhuang = ccui.Helper:seekWidgetByName(item, "Image_zhuang")
		local isZhuang = var.wChairID == GameCommon.wBankerUser
		Image_zhuang:setVisible(isZhuang)
		local name = ccui.Helper:seekWidgetByName(item, "Text_name")	
		name:setString(var.szNickName)
		self:setTextColor(name)
		local score = ccui.Helper:seekWidgetByName(item, "Text_score")
		self:setTextColor(score)
		if pBuffer.lGameScore[var.wChairID + 1] < 0 then 			
			local dwGold = Common:itemNumberToString(pBuffer.lGameScore[var.wChairID + 1])   
			score:setString(tostring(dwGold))
		else
			if pBuffer.lGameScore[var.wChairID + 1] == 0 then
				score:setString(0)
			else
				local dwGold = Common:itemNumberToString(pBuffer.lGameScore[var.wChairID + 1])   
				score:setString('+' ..tostring(dwGold))
			end
		end
	end
end

--更新结算信息
function GameEndLayer:updateEndInfo(pBuffer)
	--胡息
	local huxi = string.format("胡息:%d", pBuffer.HuCardInfo.cbHuXiCount)
	self:insertInfo(huxi)
	
	--囤数
	local tunshu = string.format("囤数:%d", pBuffer.wTun)
	self:insertInfo(tunshu)
end

function GameEndLayer:insertInfo(des)
	local list = nil
	local count = self.listview_info:getChildrenCount()
	if count <= 4 then
		list = self.listview_info
	else
		list = self.listview_player
	end
	local item = self.content_template:clone()
	item:setVisible(true)
	local text = item:getChildByName('des')
	self:setTextColor(text)
	text:setString(des)
	list:pushBackCustomItem(item)
end

function GameEndLayer:onCreate(pBuffer)
	local csb = cc.CSLoader:createNode("CDGameEndZiPai.csb")
	self:addChild(csb)
	self.root = csb:getChildByName("Panel_root")
	
	self.playerInfo_template = ccui.Helper:seekWidgetByName(self.root, 'panel_playerInfo') --模板
	
	self.content_template = ccui.Helper:seekWidgetByName(self.root, 'content_template')
	self.content_template:setVisible(false)
	
	self.listview_info = ccui.Helper:seekWidgetByName(self.root, 'ListView_info')
	
	self.listview_player = ccui.Helper:seekWidgetByName(self.root, 'ListView_player')

	self.Panel_fanxing = ccui.Helper:seekWidgetByName(self.root, 'Panel_fanxing')
	self.Panel_fanxing:setVisible(false)

	self.image_show = ccui.Helper:seekWidgetByName(self.root, 'image_show')
	self.image_show:setVisible(false)

	self.text_total = ccui.Helper:seekWidgetByName(self.root, 'Text_total')

	local uiButton_return = ccui.Helper:seekWidgetByName(self.root, "Button_dissolve")
	uiButton_return:setPressedActionEnabled(true)
	local function onEventReturn(sender, event)
		if event == ccui.TouchEventType.ended then
			Common:palyButton()
			NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER, NetMsgId.REQ_GR_DISMISS_TABLE, "")
		end
	end
	uiButton_return:addTouchEventListener(onEventReturn)
	local uiButton_continue = ccui.Helper:seekWidgetByName(self.root, "Button_continue")
	uiButton_continue:setPressedActionEnabled(true)
	local function onEventContinue(sender, event)
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
				require("common.SceneMgr"):switchScene(require("app.MyApp"):create():createView("HallLayer"), SCENE_HALL)
			end		
		end
	end
	uiButton_continue:addTouchEventListener(onEventContinue)
	
	if GameCommon.iscardcark == true then
		uiButton_continue:setVisible(false)
	end

		------------结束
		local isPlayBack = GameCommon.tableConfig.nTableType == TableType_Playback
		local button_exit = ccui.Helper:seekWidgetByName(self.root, "Button_exit")
		button_exit:setPressedActionEnabled(true)
		local function onExitEnd(sender, event)
			if event == ccui.TouchEventType.ended then
				Common:palyButton()
				require("common.SceneMgr"):switchScene(require("app.MyApp"):create():createView("HallLayer"), SCENE_HALL)
			end
		end
		button_exit:addTouchEventListener(onExitEnd)
		button_exit:setVisible(isPlayBack)
		uiButton_continue:setVisible(not isPlayBack)

	local uiPanel_look = ccui.Helper:seekWidgetByName(self.root, "Panel_look")
	self.panel_look = uiPanel_look 
	local uiButton_look = ccui.Helper:seekWidgetByName(self.root, "Button_look")
	Common:addTouchEventListener(uiButton_look, function()
		if uiPanel_look:isVisible() then
			uiPanel_look:setVisible(false)
		else
			uiPanel_look:setVisible(true)
		end
	end)
	
	local uiAtlasLabel_jb = ccui.Helper:seekWidgetByName(self.root, "AtlasLabel_jb")
	local uiImage_iconjb = ccui.Helper:seekWidgetByName(self.root, "Image_iconjb")
	uiAtlasLabel_jb:setVisible(false)
	uiImage_iconjb:setVisible(false)
	local integral = nil
	self.WPnumber = 0
	local number = 0
	--pBuffer.lGameScore[var.wChairID+1]
	for i = 1, GameCommon.gameConfig.bPlayerCount do
		if number < pBuffer.lGameScore[i] then
			number = pBuffer.lGameScore[i]
		end
		print("玩家得分", pBuffer.lGameScore[i], number)	
	end
	uiAtlasLabel_jb:setString(string.format(".%d", number))
	if GameCommon.tableConfig.nTableType ~= TableType_GoldRoom or GameCommon.iscardcark == true then
		uiImage_iconjb:loadTexture("game/game_table_score.png")
	else
		-- uiImage_iconjb:setVisible(true)
	end
	--    if pBuffer.lGameScore[i]  <= 0 then
	--            uiAtlasLabel_jb:setProperty(string.format(".%d",integral),"fonts/fonts_12.png",26,45,'.')
	--    end
	local uiPanel_result = ccui.Helper:seekWidgetByName(self.root, "Panel_result")
	local uiImage_result = ccui.Helper:seekWidgetByName(self.root, "Image_result")
	local viewID = GameCommon:getViewIDByChairID(pBuffer.wWinUser)
	local textureName = nil
	if viewID == 1 then --自己胜
		textureName = "cdzipai/ui/title2.png"
	else
		textureName = "cdzipai/ui/title1.png"	
	end
	local texture = cc.Director:getInstance():getTextureCache():addImage(textureName)
	uiImage_result:loadTexture(textureName)
	uiImage_result:setContentSize(texture:getContentSizeInPixels())
	
	
	self:updatePlayerInfo(pBuffer)

	self:updateEndInfo(pBuffer)
	
	self:showPaiXing(pBuffer)
	self:showMingTang(pBuffer)
	self:showDiPai(pBuffer)
	self:share(pBuffer)
end

function GameEndLayer:updateFanXing( name,num ,data)
	self.Panel_fanxing:setVisible(true)

	local text = self.Panel_fanxing:getChildByName('des')
	text:setString(name)
	local numText = self.Panel_fanxing:getChildByName('num')
	numText:setString(num)

	local _spt = GameCommon:GetCardHand(data)
	_spt:setScale(0.5)
	self.Panel_fanxing:addChild(_spt)
	_spt:setPosition(109,21)
end

function GameEndLayer:share(pBuffer)
	local uiButton_share = ccui.Helper:seekWidgetByName(self.root, "Button_share")
	uiButton_share:setPressedActionEnabled(true)
	local function onEventShare(sender, event)
		if event == ccui.TouchEventType.ended then
			Common:palyButton()
            local data = clone(UserData.Share.tableShareParameter[6])
            data.szShareImg = FileName.battlefieldScreenshot
            require("app.MyApp"):create(data):createView("ShareLayer")
		end
	end
	uiButton_share:addTouchEventListener(onEventShare)
end

function GameEndLayer:setTextColor( text,color )
	if text then
		text:setColor(cc.c3b(176,74,34))
	end
end

--显示牌型和眼牌
function GameEndLayer:showPaiXing(pBuffer)
    local uiListView_weave = ccui.Helper:seekWidgetByName(self.root, "ListView_weave")
	local uiPanel_defaultWeave = ccui.Helper:seekWidgetByName(self.root, "Panel_defaultWeave")
	uiListView_weave:removeAllChildren()
	for WeaveItemIndex = 1, pBuffer.HuCardInfo.cbWeaveCount do
		local item = uiPanel_defaultWeave:clone()
		local list_child = item:getChildByName('ListView_child')
		local WeaveItemArray = pBuffer.HuCardInfo.WeaveItemArray[WeaveItemIndex]            --组合扑克
		for i = 1, WeaveItemArray.cbCardCount do
			local data = WeaveItemArray.cbCardList[i]
			local _spt = GameCommon:GetCardHand(data)
			list_child:pushBackCustomItem(_spt)
		end
		local typeName = item:getChildByName('des')
		self:setTextColor(typeName)
		local WeaveType = self:getSptWeaveType(WeaveItemArray.cbWeaveKind)
		typeName:setString(WeaveType)

		local huxicout = GameLogic:GetWeaveHuXi(clone(WeaveItemArray))
		local huxiNum = item:getChildByName('num')
		self:setTextColor(huxiNum)
		huxiNum:setString(huxicout)
		local count = list_child:getChildrenCount()
		local enPosy = 20
		if count >= 4 then
			enPosy = -20
		end
		huxiNum:setPosition(cc.p(25, enPosy))
		uiListView_weave:pushBackCustomItem(item)
	end
	--眼牌
	if pBuffer.HuCardInfo.cbWeaveCount <= 6 and pBuffer.HuCardInfo.cbCardEye ~= 0 then
		local item = uiPanel_defaultWeave:clone()
		local list_child = item:getChildByName('ListView_child')
		local typeName = item:getChildByName('des')
		self:setTextColor(typeName)
		typeName:setString('对')
		local huxiNum = item:getChildByName('num')
		self:setTextColor(huxiNum)
		huxiNum:setString(0)
		huxiNum:setPosition(cc.p(25, 20))
		for i = 0, 1 do
			local data = pBuffer.HuCardInfo.cbCardEye
			local _spt = GameCommon:GetCardHand(data)
			list_child:pushBackCustomItem(_spt)
		end
		uiListView_weave:pushBackCustomItem(item)
	end
end

--显示名堂
function GameEndLayer:showMingTang(pBuffer)
    self.PHZ_HT_ZIMO = 1              --自　摸   自己摸出的牌胡了    加1囤
    self.PHZ_HT_HONGHU = 2              --红　胡   ①红字=4只；②红字=7只；③红字>10只 and <13只                                                                  (X 2倍)
    self.PHZ_HT_ZHENGDIANHU = 4              --点胡    只有一张红字                                                                                                                                          (X 3倍)
    self.PHZ_HT_HONGWU = 16              --红乌    红字＞＝13                                                                                                                                              (X 4倍)
    self.PHZ_HT_HEIWU = 32              --黑乌    红字＝0，即全部是黑字                                                                                                                         (X 5倍)
    self.PHZ_HT_DUIDUIHU = 64              --对对胡   全部对子                                                                                                                                                (X 4倍)
    self.PHZ_HT_DA = 128              --胡牌时，玩家的牌中，大字>=18只  X6（以18只为基数（6番），每多1只大字加1番）                          (x 6倍)
    self.PHZ_HT_XIAO = 256              --胡牌时，玩家的牌中，小字>=16只 X 8（以16只为基数（8番），每多1只小字加1番）                          (x 8倍)
    self.PHZ_HT_HAIDI = 512              --玩家所胡的牌是墩中最后的一只牌  平胡加1番，名堂胡加2番                                                                     (X 4倍)
    self.PHZ_HT_TIANHU = 1024              --庄家或闲家所胡的牌为亮张牌 不加番，但息数×2；如果又是名堂胡，则先计算息数，再计算底数，     (X 4倍)
    self.PHZ_HT_TINGHU                       = 0x0800              --听胡(6) 起上来.玩家手中的牌有≥15息不进牌直接胡的（只要进牌不打牌出去的）                      (X 6倍)
    self.PHZ_HT_SHUAHOU                      = 0x1000              --耍猴(8) 玩家手中的牌打的只剩一只单调胡牌的  番数：8番                                        (X 8倍)
    self.PHZ_HT_HUANGFAN                     = 0x2000              --黄番(Na)    黄庄了.下把牌继续打所有番番一倍（只适合开房）
    self.PHZ_HT_MEIYIDI                      = 0x08                --没一底(Na)胡牌加一囤
    self.PHZ_HT_TUANYUAN                     = 0x4000              --团圆(6) 就是跑了两个相同的牌就是团圆  比喻：跑了大捌又跑了小八就是团圆了 (X 8倍)
    self.PHZ_HT_HANGHANGXINGJ                = 0x8000              --行行息(8)   行息分真假行行息真行行息就是吃碰的牌行行都有息  就是真行行息 （7行都有息） (X 8倍) 
    self.PHZ_HT_HANGHANGXINGZ                = 0x10000             --行行息(6)   假行行息就是跑牌了的有一对麻将或单吊的就是假行行息（6行都有息）(X 6倍) 
	self.PHZ_HT_ZHUOXIAOSAN                  = 0x20000             --捉小三(8)   自摸小三胡牌（X 8倍）
	self.PHZ_HT_SIQIHONG					 = 0x40000             --四七红 2番
	self.PHZ_HT_HANGHANGXINGJ4               = 0x80000			   --假行行息 4番


    -- 变量定义 
    local wHZCount = 0 
    local wDZCount = 0
    local wXZCount = 0
    local bIsDDH = true
    local sdata = {
        wTun = 0 ,          --囤
        wType = 0 ,         --数据
        wFanCount = 0,      --翻
    }
    --组合牌类型
    for cbIndex = 1 , pBuffer.HuCardInfo.cbWeaveCount do
        --变量定义
        local cbWeaveKind = pBuffer.HuCardInfo.WeaveItemArray[cbIndex].cbWeaveKind
        local cbWeaveCardCount = pBuffer.HuCardInfo.WeaveItemArray[cbIndex].cbCardCount

        --合法验证
        if cbWeaveKind ~= 0 then
            --组合内统计
            for cbCardIndex = 1 , cbWeaveCardCount do
                if pBuffer.HuCardInfo.WeaveItemArray[cbIndex].cbCardList[cbCardIndex] ~= 0 then
                    --大小字统计
                    if Bit:_and(pBuffer.HuCardInfo.WeaveItemArray[cbIndex].cbCardList[cbCardIndex] , GameCommon.MASK_COLOR) == 16 then
                        wDZCount = wDZCount + 1
                    else 
                        wXZCount = wXZCount + 1
                    end

                    --红字统计
                    if Bit:_and(pBuffer.HuCardInfo.WeaveItemArray[cbIndex].cbCardList[cbCardIndex] , GameCommon.MASK_VALUE)==2 
                        or Bit:_and(pBuffer.HuCardInfo.WeaveItemArray[cbIndex].cbCardList[cbCardIndex] , GameCommon.MASK_VALUE)==7 
                        or Bit:_and(pBuffer.HuCardInfo.WeaveItemArray[cbIndex].cbCardList[cbCardIndex] , GameCommon.MASK_VALUE)==10 then
                        wHZCount = wHZCount + 1
                    end
                end
            end
            --对对胡判断
            if cbWeaveKind== GameCommon.ACK_CHI or cbWeaveKind==GameCommon.ACK_CHI_EX then
                bIsDDH=false
            end
        end
    end
    --眼牌
    if pBuffer.HuCardInfo.cbCardEye~=0 then
        for  i=1 , 2 do
            --大小字统计
            if Bit:_and(pBuffer.HuCardInfo.cbCardEye , GameCommon.MASK_COLOR) == 16 then
                wDZCount = wDZCount + 1

            else 

                wXZCount = wXZCount + 1
            end
            --红字统计
            if Bit:_and(pBuffer.HuCardInfo.cbCardEye , GameCommon.MASK_VALUE)==2  
                or Bit:_and(pBuffer.HuCardInfo.cbCardEye, GameCommon.MASK_VALUE)==7 
                or Bit:_and(pBuffer.HuCardInfo.cbCardEye, GameCommon.MASK_VALUE)==10 then

                wHZCount = wHZCount + 1
            end
        end
    end
    --胡牌类型大字胡，小胡子，红乌需要计算基数
    if wHZCount>=10 then
        local str = string.format( "红胡:%d番",3 +wHZCount-10 )
		self:insertInfo(str)
    end
    if wDZCount >= 18 and wDZCount < 27 then
        local str = string.format( "大字胡:%d番",8+wDZCount-18)
		self:insertInfo(str)

    elseif wXZCount >= 16 and wXZCount < 27 then
        local str = string.format( "小字胡:%d番",10+wXZCount-16)
		self:insertInfo(str)
    end

    --自摸判断
    if Bit:_and(pBuffer.wType,self.PHZ_HT_ZIMO)~= 0 then
        local str = string.format( "自摸:+%d囤",1 )
		self:insertInfo(str)
		self.image_show:setVisible(true)
		self.image_show:loadTexture('cdzipai/ui/tu.png')
		self.image_show:ignoreContentAdaptWithSize(true)
        
    end 
    --捉小三
    if Bit:_and(pBuffer.HuCardInfo.wDType,self.PHZ_HT_ZHUOXIAOSAN) ~= 0 then
        local str = string.format( "捉小三:%d番",8)
		self:insertInfo(str)
    end
    --点胡
    if Bit:_and(pBuffer.wType,self.PHZ_HT_ZHENGDIANHU) ~= 0 then
        local str = string.format( "点胡:%d番",6)
		self:insertInfo(str)
        
    end
    if Bit:_and(pBuffer.wType,self.PHZ_HT_HEIWU) ~= 0 then
        local str = string.format( "黑胡:%d番",8)
		self:insertInfo(str)
    end
    --团圆
    if Bit:_and(pBuffer.wType,self.PHZ_HT_TUANYUAN) ~= 0 then
        local str = string.format( "团圆:%d番",8)
		self:insertInfo(str)
    end
    --行行息（真假）
    if Bit:_and(pBuffer.HuCardInfo.wDType,self.PHZ_HT_HANGHANGXINGZ) ~= 0 then
        local str = string.format( "行行息:%d番",8)
		self:insertInfo(str)
    end
    --对对胡=没有吃进的组合、手中没有单牌
    if Bit:_and(pBuffer.wType,self.PHZ_HT_DUIDUIHU) ~= 0 then
        local str = string.format( "对对胡:%d番",8)
		self:insertInfo(str)
    end

    --天胡和海底
    if Bit:_and(pBuffer.wType , self.PHZ_HT_HAIDI) ~= 0 then
        local str = string.format( "海底胡:%d番",6)
		self:insertInfo(str)
    end
    if Bit:_and(pBuffer.wType,self.PHZ_HT_TINGHU) ~= 0 then
        local str = string.format( "听胡:%d番",6)
		self:insertInfo(str)
    end
    if Bit:_and(pBuffer.wType,self.PHZ_HT_SHUAHOU) ~= 0 then
        local str = string.format( "耍猴:%d番",8)
		self:insertInfo(str)
	end
	
	if Bit:_and(pBuffer.wType,self.PHZ_HT_HUANGFAN) ~= 0 then
        local str = string.format( "黄番:x%d倍",pBuffer.cbHuangFanCount + 1)
		self:insertInfo(str)
	end

	if Bit:_and(pBuffer.HuCardInfo.wDType,self.PHZ_HT_SIQIHONG) ~= 0 then
		local str = string.format( "四七红:%d番",2)
		self:insertInfo(str)
	end
	if Bit:_and(pBuffer.HuCardInfo.wDType,self.PHZ_HT_HANGHANGXINGJ4) ~= 0 then
		local str = string.format( "假行行息:%d番",4)
		self:insertInfo(str)
	end

end

--显示底牌
function GameEndLayer:showDiPai(pBuffer)
	local uiListView_diPai1 = ccui.Helper:seekWidgetByName(self.root, "ListView_diPai1")
	local uiListView_diPai2 = ccui.Helper:seekWidgetByName(self.root, "ListView_diPai2")
	for i = 1, pBuffer.bLeftCardCount do
		if pBuffer.bLeftCardDataEx[i] ~= 0 then
			local item = GameCommon:GetCardHand(pBuffer.bLeftCardDataEx[i])
			if i <= 17 then
				uiListView_diPai1:pushBackCustomItem(item)
			else
				uiListView_diPai2:pushBackCustomItem(item)
			end
		end
	end
	if pBuffer.bLeftCardCount > 17 then
		uiListView_diPai1:setPosition(cc.p(-90,72))
		uiListView_diPai2:setPosition(cc.p(-90,3))
	else
		uiListView_diPai1:setPosition(cc.p(-90,57))
	end
end

function GameEndLayer:getSptWeaveType(type)
	local sptname = ""
	if type == GameCommon.ACK_TI then
		sptname = "提"
	elseif type == GameCommon.ACK_PAO then
		sptname = "跑"
	elseif type == GameCommon.ACK_WEI then
		sptname = "偎"
	elseif type == GameCommon.ACK_CHI then
		sptname = "吃"
	elseif type == GameCommon.ACK_PENG then
		sptname = "碰"
	else
		
	end
	return sptname
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

function GameEndLayer:CUS_GAMEENDlAYER_CLIENT(event)
	local uiPanel_look = ccui.Helper:seekWidgetByName(self.root, "Panel_look")
	uiPanel_look:setVisible(true)
end

return GameEndLayer
