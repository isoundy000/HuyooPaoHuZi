local NetMgr = require("common.NetMgr")
local NetMsgId = require("common.NetMsgId")
local EventMgr = require("common.EventMgr")
local EventType = require("common.EventType")
local Common = require("common.Common")
local UserData = require("app.user.UserData")
local StaticData = require("app.static.StaticData")
local Default = require("common.Default")
local LocationSystem = require("common.LocationSystem")

local GameCommon = {
    -------------------------------------------------------------------------------
    --宏定义
    --动作定义
    ACK_NULL                    =0x0,                                   --空
    ACK_TI                      =0x1,                                   --提
    ACK_PAO                     =0x2,                                   --跑
    ACK_WEI                     =0x4,                                   --偎
    ACK_WD                      =0x8,                                   --王钓
    ACK_WC                      =0x10,                                  --王闯
    ACK_CHI                     =0x20,                                  --吃
    ACK_CHI_EX                  =0x40,                                  --吃
    ACK_PENG                    =0x80,                                  --碰
    ACK_CHIHU                   =0x100,                                 --胡
    ACK_BIHU				    =0x200,						           --必胡
    bFangPao                    = 1,                                   --0不能放跑  1能放炮
    
    PHZ_RULE_FANXING                    =0x0001,                     --回放翻省
    PHZ_RULE_GENXING                    =0x0002,                     --回放跟省
    PHZ_ALL_ACK                         =0xFFFFF,                    --公共比较
    --吃牌类型
    CK_NULL = 0,         --无效类型
    CK_XXD = 1,          --小小大搭
    CK_XDD = 2,          --小大大搭
    CK_EQS = 4,          --二七十吃
    CK_LEFT = 16,        --靠左对齐
    CK_CENTER = 32,      --居中对齐
    CK_RIGHT = 64,       --靠右对齐
    CK_YWS	=128,		--一五十吃
    --数值定义
    MAX_WEAVE = 7,       --最大组合
    MAX_INDEX = 20,      --最大索引
    MAX_COUNT = 21,      --最大数目
    MASK_COLOR = 240,    --花色掩码
    MASK_VALUE = 15,     --数值掩码
    --主要用于桌面显示
    ACK_CHOUWEI = 5,     --臭偎
    --牌间隔
    CARD_HUXI_HEIGHT = 40,
    CARD_HUXI_WIDTH = 40,
    CARD_COM_HEIGHT = 226,
    CARD_COM_WIDTH = 76,
    --游戏结束开始时间
    Game_end_time = 25.0,
    
    GameView_updataHuxi = 1,        --跟新胡息
    GameView_updataHardCard = 2,    --跟新手牌
    GameView_showOutCardTips = 3,   --显示出牌提示
    GameView_closeOutCardTips = 4,  --关闭出牌提示
    GameView_BegainMsg = 5,         --开始处理消息
    GameView_endMsg = 6,            --处理完消息了
    GameView_UpOpration = 7,        --更新操作超时
    GameView_OutOpration = 8,       --操作超时
    
    GameView_GamePaly=9,            --游戏装备

    ACTION_TIP = 1,                 --提示动作
    ACTION_TI_CARD = 2,             --提牌动作
    ACTION_PAO_CARD = 3,            --跑牌动作
    ACTION_WEI_CARD = 4,            --偎牌动作
    ACTION_PENG_CARD = 5,           --碰牌动作
    ACTION_HU_CARD = 6,             --胡牌动作
    ACTION_CHI_CARD = 7,            --吃牌动作
    ACTION_OUT_CARD = 8,            --出牌动作
    ACTION_SEND_CARD = 9,           --发牌动作
    ACTION_OPERATE_NOTIFY = 10,     --发牌动作
    ACTION_OUT_CARD_NOTIFY = 11,    --发牌动作
    ACTION_FANG_CARD = 12,          --翻省动作
    ACTION_VIEW_CARD = 13,          --表现动作
    ACTION_HUANG = 14,              --黄庄动作
    ACTION_WD = 15,                 --王钓动作
    ACTION_WC = 16,                 --王闯动作
    ACTION_3WC = 116,               --三王闯动作
    ACTION_SISHOU = 17,             --死守动作
    ACTION_WPei = 18,               --有王赔钱动作
    ACTION_ADDBASE=19,          --加倍动作
    ACTION_SHOW_CARD = 20,          --亮手牌
    ACTION_HUANG_PEI = 21,          --黄庄赔钱
    ACTION_WUFU_ADD_BASE = 22,      --五福报警
    ACTION_WUFU_ADD_BASE_VIEW = 23, --五福结果
    ACTION_DATUO_ADD_BASE = 24,      --打托
    ACTION_DATUO_ADD_BASE_VIEW = 25, --打托结果              
    
    Animition_chi = 0,          --吃
    Animition_peng = 1,         --碰
    Animition_hu = 2,           --胡
    Animition_ti = 3,           --提
    Animition_pao = 4,          --跑
    Animition_wei = 5,           --偎
    Animition_chouwei = 6,      --臭偎
    Animition_bi = 7,           --比
    Animition_wd = 8,           --王钓
    Animition_sishou = 9,       --死守
    Animition_wc = 10,          --王闯
    Animition_3wc = 110,        --三王闯
    Animition_fang = 11,        --翻省    
    Animition_Huang = 12,       --黄庄
    Animition_wpei = 13,        --王霸赔钱
    
    Animition_qing = 14,        --提变倾
    Animition_xiao = 15,        --偎变啸
    Animition_chouxiao = 16,    --臭啸
    Animition_xiahuo = 17,      --比变下火
    Animition_xiabi = 35,      --比变下比 （吃一个放一个）
    Animition_fangpao = 18,     --放炮
    --字牌变化
    Animition_sao = 19,         --煨变扫
    Animition_guosao = 20,      --臭喂变过扫
    Animition_saoquang = 21,    --提变扫穿
    Animition_tuo = 22,         --跑变开拓  
    
    Animition_addBase=23,       --加倍
    Animition_addBase_no=24,    --不加倍

    Animition_phz_pengshangd=25,--碰三大
    Animition_phz_pengsiq=26,       --碰四清

    Animition_phz_shaoshanp=27,     --扫三大
    Animition_phz_shaosiqing=28,      --扫四清

    Animition_phz_tilong=29,            --提龙
    Animition_phz_shuanglong=30,
    Animition_phz_xiaoqidui=31,
    Animition_phz_wufu=32,
    Animition_phz_tianhu=33,
    Animition_phz_dihu=34,

    Soundeffect_RunAction = 0,  --动作
    Soundeffect_RunCard = 1,    --卡牌
    Soundeffect_Huang = 2,      --黄庄
    Soundeffect_FangX = 3,      --翻省
    Soundeffect_getSz = 4,      --获取闪砖
    Soundeffect_getW = 5,       --摸到王牌
    
    timeAction_Null = 0,
    timeAction_OutCard = 1,
    timeAction_Opration = 2,
    CardData_WW = 33,
    
    leftalignment=1,
    centrealignment = 2,
    rightalignment = 3,
    
    CARDHEIGH = 90.0,
    CARDWIDTH = 95.0,
    BASEPOSITIONY = 55.0,
    BASEPOSITIONX = 50.0,
    
    ClientSockEvent_connectFaild = 1,                 --链接失败
    ClientSockEvent_connectError = 2,                 --网络错误
    ClientSockEvent_connectSucceed = 3,               --链接成功
    
    INVALID_TEAM = 65535,    --无效组号
    INVALID_TABLE = 65535,   --无效桌子
    INVALID_CHAIR = 65535,  
    INVALID_ID = 4294967295,
    Gamemode = {},                                     -- 游戏模式
    isfanxing = true,                             --true:翻省 ； false：跟省
    isGameEnd = false,                             -- true:游戏结束 ；false：游戏开始  （游戏预处理 ：控制解散好友房弹框）
    
    cbAllHuXiCount = nil ,                          --告胡子类型金币房总胡息
    EARTH_RADIUS = 6371.004 ,                     --地球半径   
    DistanceAlarm = 1 ,                 -- 距离判断（0：没有判断多，需要判断。1：判断过或不需要判断）
    IsOfHu = 0 ,                        -- 是否胡牌提醒
    -------------------------------------------------------------------------------
    meChairID = 0,

    reconnectCardInfo = {},   --保存当前手牌信息，断线重连恢复


    timedata = 0 ,
    DGCS = 0 ,
}

function GameCommon:init()
	    --数据
    self.regionSound = 0
    self.weiCardType = 0    --0明偎  1暗偎
    self.tiCardType = 0     --0明提  1暗提
    self.tagUserInfoList = {}
    self.wPlayerCount = 0
--    self.dwUserID = 0
    self.bIsMyTurn = false
    self.wufu= {}
    self.leftCardCount = 0
    self.cardStackWidth = 0
    self.handCardalignment = 0
    self.cbCardIndex = {}
    self.wBankerUser = -1
    self.bWeaveItemCount = {[1] = 0 , [2] = 0 , [3] = 0 , [4] = 0 }
    self.weaveItemArray = {}
    self.bUserCardCount = {}
    self.bellv = 0
--    self.meChairID = 0
    self.cbWWCout = 0
    self.cbWWCout_cb = {[1] = 0 , [2] = 0 , [3] = 0 }
    self.restart = false
    self.iscardcark = false
    self.wContinueWinCount = 0
    self.isFriendGameStart = false

    self.wBankerUser = 0
    self.bLeftCardCount = 0
    self.waitOutCardUser = nil
    
    self.GameState_Init = 0
    self.GameState_Start = 1
    self.GameState_Over = 2
    self.gameState = 0
    self.bIsHuangZhuang = false
    self.huangfanNum = 0
    self.language = 2--cc.UserDefault:getInstance():getIntegerForKey('CDvolumeSelect', 0)
    self.bIsSiShou = false
    self.bIsOutCardTips = false

end

function GameCommon:getViewIDByChairID(wChairID, isChangeView)
    local location = 1          --主角位置
    local wPlayerCount = self.gameConfig.bPlayerCount      --玩家人数
    local meChairID = self:getRoleChairID()     --主角的座位号
    local viewID = (wChairID + location - meChairID)%wPlayerCount
    if viewID == 0 then
        viewID = wPlayerCount
    end
    if self.gameConfig.bPlayerCount == 4 and StaticData.Games[self.tableConfig.wKindID].isZuoXing4 == 1 then
        local duijia = (GameCommon.wBankerUser - 1 + wPlayerCount - 1) % wPlayerCount
        local duijiadexiayijia = (duijia + wPlayerCount - 1)%wPlayerCount
        local duijiadeshangyijia = (duijia + 2 +wPlayerCount-1)%wPlayerCount
        local duijiaViewID = (duijia + location - meChairID)%wPlayerCount
        if duijiaViewID == 0 then
            duijiaViewID = wPlayerCount
        end
        
        if duijiaViewID == 1 then--自己就是坐省的时候
            if viewID == 3 then
                viewID = 1
            elseif viewID == 2 then
                viewID = 3
            elseif viewID == 4 then
                viewID = 2
            elseif viewID == 1 then
                viewID = 4
            end
            
        elseif duijiaViewID == 2 then
            if viewID == 2 then
                viewID = 4
            elseif viewID == 3 then
                viewID = 2
            elseif viewID == 4 then
                viewID = 3
            else
            end
        elseif duijiaViewID == 3 then
            if viewID == 3 then
                viewID = 4
            elseif viewID == 4 then
                viewID = 3
            else
            
            end
        else
        
        end
    end

    if isChangeView and wPlayerCount == 2 and viewID == 2 then
        --产品要求又还原
        -- viewID = 3
    end

    return viewID
end

function GameCommon:getRoleChairID()
    return self.meChairID
end


function GameCommon:getUserInfo(charID)   
    if self.player == nil or self.player[charID] == nil then
        return nil
    end
    for key, var in pairs(self.player) do
        if var.wChairID == charID then
            return var
        end
    end
    return nil
end

function GameCommon:getUserInfoByUserID(dwUserID)
    if self.player == nil then
        return nil
    end
    for key, var in pairs(self.player) do
        if var.dwUserID == dwUserID then
            return var
        end
    end
    return nil
end

function GameCommon:ContinueGame(cbLevel)
    NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER,NetMsgId.REQ_GR_USER_SET_POSITION,"aad",LocationSystem.pos.x, LocationSystem.pos.y, GameCommon.dwUserID)
    if GameCommon.tableConfig.nTableType > TableType_GoldRoom then
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER,NetMsgId.REQ_GR_USER_NEXT_GAME,"")
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER,NetMsgId.REQ_GR_USER_READY,"")
    elseif GameCommon.tableConfig.nTableType == TableType_GoldRoom then
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER,NetMsgId.REQ_GR_USER_CONTINUE_GAME,"b",cbLevel)
    elseif GameCommon.tableConfig.nTableType == TableType_SportsRoom then
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER,NetMsgId.REQ_GR_USER_CONTINUE_GAME_BY_SPORTS,"d",cbLevel)
    end

    --安全处理，保证下局开始前清理上局脏数据
    GameCommon.reconnectCardInfo = {}
end

-- 大数字转化
function GameCommon:itemNumberToString(num)  
    if num >= 1000000 then  
--        if num % 1000000 < 100000 then  
            return string.format("%d千公里", math.floor(num /1000000))  
--        else  
--            return string.format("%.1f千公里", (num - num % 100000)/1000000)  
--        end  
    elseif num >= 1000 then  
        if num % 1000 < 100 then  
            return string.format("%d公里", math.floor(num /1000))  
        else  
            return string.format("%.1f公里", (num - num % 100)/1000)  
        end  
    elseif num <= 1000 then   
        return string.format("%d米", num/1)  
    else
        return tostring("太远无法定位")  
    end  
end


function GameCommon:rad(d)
    return d* math.pi / 180.0
end 

function GameCommon:GetDistance(lat1,lat2)
    local radLat1 = self:rad(lat1.x)
    local radLat2 = self:rad(lat2.x)
    local a = radLat1 - radLat2
    local b = self:rad(lat1.y) - self:rad(lat2.y)
    local s = 2 * math.asin(math.sqrt(math.pow(math.sin(a/2),2) +math.cos(radLat1)*math.cos(radLat2)*math.pow(math.sin(b/2),2)))
    s = s * self.EARTH_RADIUS*1000
 --   s = math.round(s * 10000) / 10000  
    return s
end 

--手牌资源
function GameCommon:GetCardHand(data)
    local imgCardFrame = nil    
    local cardIndex = cc.UserDefault:getInstance():getIntegerForKey('HYZiXing', 1)

    if data == 0 then
        imgCardFrame = ccui.ImageView:create("hyphz/card/card_1/Card_miniature_000.png")
    elseif data==33 then
        
    elseif data <= 10 then
        if cardIndex == 1 then
            imgCardFrame = ccui.ImageView:create(string.format("hyphz/card/card_1/Card_half_Small_0%02d.png", data))
        else
            imgCardFrame = ccui.ImageView:create(string.format("hyphz/card/card_2/Card_half_Small_0%02d.png", data))
        end

    elseif data > 10 then
        if cardIndex == 1 then
            imgCardFrame = ccui.ImageView:create(string.format("hyphz/card/card_1/Card_half_Big_0%02d.png", data-16))
        else
            imgCardFrame = ccui.ImageView:create(string.format("hyphz/card/card_2/Card_half_Big_0%02d.png", data-16))
        end

    else
        assert(false)
    end
    imgCardFrame.data = data

    return imgCardFrame
end

--吃牌组合资源
function GameCommon:getSendOrOutCard(data, isSendCard)
    local cardIndex = cc.UserDefault:getInstance():getIntegerForKey('HYZiXing', 1)

    local imgBg = nil
    if isSendCard == true then
        imgBg = ccui.ImageView:create("hyphz/card/light_gold.png")
    else
        imgBg = cc.Layer:create()
        imgBg:setContentSize(157, 316)
    end

    local imgCard = nil
    if data == 0 then
        imgCard = ccui.ImageView:create("hyphz/card/card_1/Card_Big_000.png")

    elseif data==33 then
    
    elseif data <= 10 then
        if cardIndex == 1 then
            imgCard = ccui.ImageView:create(string.format("hyphz/card/card_%d/Card_Small_0%02d.png",1, data))
        else
            imgCard = ccui.ImageView:create(string.format("hyphz/card/card_%d/Card_Small_0%02d.png",2, data))
        end
        
    elseif data > 10 then
        if cardIndex == 1 then
            imgCard = ccui.ImageView:create(string.format("hyphz/card/card_%d/Card_Big_0%02d.png",1, data-16))
        else
            imgCard = ccui.ImageView:create(string.format("hyphz/card/card_%d/Card_Big_0%02d.png",2, data-16))
        end

    else
        assert(false)
    end

    imgBg:addChild(imgCard)
    imgCard:setScale(0.8)

    if isSendCard == true then
        local size = imgBg:getContentSize()
        imgCard:setPosition(size.width * 0.5, size.height * 0.5)
    end
    
    return imgBg
end

function GameCommon:getDiscardCardAndWeaveItemArrayAnimation(data)
    local cardIndex = nil
    if CHANNEL_ID == 9 or CHANNEL_ID == 8 then 
        cardIndex = cc.UserDefault:getInstance():getIntegerForKey(Default.UserDefault_ZiPaiCard,1)
    else
        cardIndex = cc.UserDefault:getInstance():getIntegerForKey(Default.UserDefault_ZiPaiCard,0)
    end
    local cardBgIndex =nil
    if CHANNEL_ID == 10 or CHANNEL_ID == 11 or CHANNEL_ID == 2 or CHANNEL_ID == 3  then 
        cardBgIndex = cc.UserDefault:getInstance():getIntegerForKey(Default.UserDefault_ZiPaiCardBg,1)
    else
        cardBgIndex = cc.UserDefault:getInstance():getIntegerForKey(Default.UserDefault_ZiPaiCardBg,0)
    end
    local imgCard = nil
    if data == 0 then
        if cardBgIndex ~= 0 then
            imgCard = ccui.ImageView:create("zipai/card_bg/card_bg1/card_bg_3.png")
        else
            imgCard = ccui.ImageView:create("zipai/card_bg/card_bg0/card_bg_3.png")
        end
    elseif data==33 then
        if cardIndex == 0 then
            imgCard = ccui.ImageView:create("zipai/card/card0/ww.png")
        elseif cardIndex == 1 then
            imgCard = ccui.ImageView:create("zipai/card/card1/ww.png")
        elseif cardIndex == 2 then
            imgCard = ccui.ImageView:create("zipai/card/card2/ww.png")
        elseif cardIndex == 3 then
            imgCard = ccui.ImageView:create("zipai/card/card3/ww.png")
        end
    elseif data <= 10 then
        if cardIndex == 0 then
            imgCard = ccui.ImageView:create(string.format("zipai/card/card0/dx%d.png",data))
        elseif cardIndex == 1 then
            imgCard = ccui.ImageView:create(string.format("zipai/card/card1/dx%d.png",data))
        elseif cardIndex == 2 then
            imgCard = ccui.ImageView:create(string.format("zipai/card/card2/dx%d.png",data))
        elseif cardIndex == 3 then
            imgCard = ccui.ImageView:create(string.format("zipai/card/card3/dx%d.png",data))
        end
    elseif data > 10 then
        if cardIndex == 0 then
            imgCard = ccui.ImageView:create(string.format("zipai/card/card0/dd%d.png",data-16))
        elseif cardIndex == 1 then
            imgCard = ccui.ImageView:create(string.format("zipai/card/card1/dd%d.png",data-16))
        elseif cardIndex == 2 then
            imgCard = ccui.ImageView:create(string.format("zipai/card/card2/dd%d.png",data-16))
        elseif cardIndex == 3 then
            imgCard = ccui.ImageView:create(string.format("zipai/card/card3/dd%d.png",data-16))
        end
    else
        assert(false)
    end
    return imgCard
end

--获取棋牌或者吃牌组合资源
function GameCommon:getDiscardCardAndWeaveItemArray(data)
    local cardIndex = cc.UserDefault:getInstance():getIntegerForKey('HYZiXing', 1)

    local imgCard = nil
    if data == 0 then
        imgCard = ccui.ImageView:create("hyphz/card/card_1/Card_miniature_000.png")
        
    elseif data==33 then
        imgCard = ccui.ImageView:create("hyphz/card/card_1/Card_miniature_Big_wang.png")

    elseif data <= 10 then
        if cardIndex == 1 then
            imgCard = ccui.ImageView:create(string.format("hyphz/card/card_1/Card_miniature_Small_0%02d.png", data))
        else
            imgCard = ccui.ImageView:create(string.format("hyphz/card/card_2/Card_miniature_Small_0%02d.png", data))
        end
        
    elseif data > 10 then
        if cardIndex == 1 then
            imgCard = ccui.ImageView:create(string.format("hyphz/card/card_1/Card_miniature_Big_0%02d.png", data - 16))
        else
            imgCard = ccui.ImageView:create(string.format("hyphz/card/card_2/Card_miniature_Big_0%02d.png", data - 16))
        end
        
    else
        assert(false)
    end
    imgCard.data = data
    return imgCard
end

function GameCommon:playAnimation(root, id, wChairID)
    local Animation = require("game.cdphz.Animation")
    if Animation[id] == nil then
        return
    end

    local AnimationData = Animation[id][self.language]
    if self.language ~= 0 then
        local wKindID = GameCommon.tableConfig.wKindID
        if wKindID == 47 or wKindID == 48 or wKindID == 49 or wKindID == 60 then
            AnimationData = Animation[id][1]
        end
    end

    if AnimationData == nil then
        return
    end
    if AnimationData.animFile ~= "" then
        local visibleSize = cc.Director:getInstance():getVisibleSize()
        local uiPanel_tipsCard = ccui.Helper:seekWidgetByName(root,"Panel_tipsCard")
        ccs.ArmatureDataManager:getInstance():addArmatureFileInfo(AnimationData.animFile)
        local armature = ccs.Armature:create(AnimationData.animName)
        uiPanel_tipsCard:addChild(armature)
        armature:setScale(1.5)
        armature:getAnimation():playWithIndex(0,-1,0)
        armature:runAction(cc.Sequence:create(
            cc.ScaleTo:create(0.1,1),
            cc.DelayTime:create(1.0),
            cc.FadeOut:create(1.0),
            cc.RemoveSelf:create()))
        if id == "黄庄" then
            armature:setPosition(visibleSize.width/2, visibleSize.height/2)
            require("common.Common"):playEffect("common/huangzhuang.mp3")
        elseif id == "翻省" or id == "跟省" then
            armature:setPosition(visibleSize.width/2, visibleSize.height/2)
            require("common.Common"):playEffect("common/fangx.mp3")     	 
        else		
            local viewID = GameCommon:getViewIDByChairID(wChairID, true)
            local Panel_tipsControlPos = ccui.Helper:seekWidgetByName(root,string.format("Panel_tipsControlPos%d",viewID))
            armature:setPosition(Panel_tipsControlPos:getPosition())

			if id == "胡"  and( CHANNEL_ID == 6 or CHANNEL_ID == 7) then
				require("common.Common"):playEffect("common/win.mp3")
			end 
        end
    end
    local soundFile = ""
    local player = GameCommon.player[wChairID]
    if wChairID ~= nil and player then
        local cbSex = player.cbSex
        soundFile = AnimationData.sound[cbSex]
    else
        soundFile = AnimationData.sound[0]
    end
    if soundFile ~= "" then
        require("common.Common"):playEffect(soundFile)
    end
end

function GameCommon:playCardCtlAnimation(root, id, wChairID)
    local viewID = GameCommon:getViewIDByChairID(wChairID, true)
    local Panel_tipsControlPos = ccui.Helper:seekWidgetByName(root,string.format("Panel_tipsControlPos%d",viewID))
    Panel_tipsControlPos:removeAllChildren()
    local node = ccui.ImageView:create(string.format('cdzipai/ui/cn_%d.png',id))
    Panel_tipsControlPos:addChild(node)
    node:setScale(0)
    local scale_1 = cc.ScaleTo:create(0.5, 1.5)
    local delay = cc.DelayTime:create(0.3)
    local scale_2 = cc.ScaleTo:create(0.3, 1)
    local callFunc = cc.CallFunc:create(function()
        node:removeFromParent()
    end)
    node:runAction(cc.Sequence:create(scale_1, delay, scale_2, callFunc))
end

function GameCommon:isSelectCDGameType()
    local wKindID = GameCommon.tableConfig.wKindID
    if wKindID == 47 or wKindID == 48 or wKindID == 49  or wkindID == 60 then
        return true
    else
        return false
    end
end

---
-- 递归遍历子节点
-- @DateTime 2018-06-13
-- @param  root 根节点 name 目标节点
-- @return node or nil
--
function GameCommon:seekWidgetByNameEx(root,name)
    local rootArr = root:getChildren()
    if rootArr then
        for i,v in ipairs(rootArr) do
            if v:getName() == name then
                return v
            end
            local res = self:seekWidgetByNameEx(v,name)
            if res then
                return res
            end
        end
    end
    return nil 
end

return GameCommon