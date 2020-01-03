local EventMgr = require("common.EventMgr")
local EventType = require("common.EventType")
local NetMgr = require("common.NetMgr")
local NetMsgId = require("common.NetMsgId")
local StaticData = require("app.static.StaticData")
local UserData = require("app.user.UserData")
local Common = require("common.Common")
local Default = require("common.Default")
local GameDesc = require("common.GameDesc")
local GameConfig = require("common.GameConfig")

local InterfaceCreateRoomNode = class("InterfaceCreateRoomNode", cc.load("mvc").ViewBase)

function InterfaceCreateRoomNode:onEnter()
    EventMgr:registListener(EventType.SUB_CL_GAME_SERVER,self,self.SUB_CL_GAME_SERVER)
    EventMgr:registListener(EventType.EVENT_TYPE_CONNECT_GAME_FAILED,self,self.EVENT_TYPE_CONNECT_GAME_FAILED)
    EventMgr:registListener(EventType.SUB_GR_LOGON_SUCCESS,self,self.SUB_GR_LOGON_SUCCESS)
    EventMgr:registListener(EventType.SUB_CL_GAME_SERVER_ERROR,self,self.SUB_CL_GAME_SERVER_ERROR)
    EventMgr:registListener(EventType.SUB_GR_USER_ENTER,self,self.SUB_GR_USER_ENTER)
    EventMgr:registListener(EventType.SUB_GR_CREATE_TABLE_FAILED,self,self.SUB_GR_CREATE_TABLE_FAILED)
end

function InterfaceCreateRoomNode:onExit()
    EventMgr:unregistListener(EventType.SUB_CL_GAME_SERVER,self,self.SUB_CL_GAME_SERVER)
    EventMgr:unregistListener(EventType.EVENT_TYPE_CONNECT_GAME_FAILED,self,self.EVENT_TYPE_CONNECT_GAME_FAILED)
    EventMgr:unregistListener(EventType.SUB_GR_LOGON_SUCCESS,self,self.SUB_GR_LOGON_SUCCESS)
    EventMgr:unregistListener(EventType.SUB_CL_GAME_SERVER_ERROR,self,self.SUB_CL_GAME_SERVER_ERROR)
    EventMgr:unregistListener(EventType.SUB_GR_USER_ENTER,self,self.SUB_GR_USER_ENTER)
    EventMgr:unregistListener(EventType.SUB_GR_CREATE_TABLE_FAILED,self,self.SUB_GR_CREATE_TABLE_FAILED)
end

function InterfaceCreateRoomNode:onCreate(parameter)
    self.nTableType     = parameter[1]
    self.wTableSubType  = parameter[2]
    self.dwTargetID     = parameter[5]   
    if type(parameter[3]) == 'table' then
        self.wKindID        = parameter[3][1]
        self.wGameCount     = parameter[4][1]
        self.tableParameter = parameter[6][1]
    else
        self.wKindID        = parameter[3]
        self.wGameCount     = parameter[4]
        self.tableParameter = parameter[6]
    end

    NetMgr:getGameInstance():closeConnect()
    if self.nTableType >= TableType_GuildRoom and UserData.Guild.dwGuildID <= 0 then
        self:removeFromParent()
        require("common.MsgBoxLayer"):create(1,nil,"请先加入公会!")
        return
    end
    

    UserData.Game:sendMsgGetRoomInfo(self.wKindID, 2)
end

function InterfaceCreateRoomNode:SUB_GR_USER_ENTER(event)
    local data = event._usedata
    if data.nTableType == TableType_HelpRoom then
        self:removeFromParent()
        require("common.CreateRoomSuccessLayer"):create(data.wKindID,data.wTbaleID,data.wTableNumber,GameDesc:getGameDesc(data.wKindID,self.tableParameter))
        UserData.User:sendMsgUpdateUserInfo(1)
        NetMgr:getGameInstance():closeConnect()
        return
    end
    require("common.SceneMgr"):switchScene(require(StaticData.Games[data.wKindID].luaGameFile):create(UserData.User.userID,data),SCENE_GAME)
end

function InterfaceCreateRoomNode:SUB_GR_CREATE_TABLE_FAILED(event)
    self:removeFromParent()
    local errorID = event._usedata
    if errorID == 1 then
        require("common.MsgBoxLayer"):create(0,nil,"房间配置错误!")
    elseif errorID == 2 then
        require("common.MsgBoxLayer"):create(0,nil,"您的道具不足!")
    elseif errorID == 3 then
        require("common.MsgBoxLayer"):create(0,nil,"房间已满!")
    elseif errorID == 11 then
        require("common.MsgBoxLayer"):create(2,nil,"请先加入公会!")
    elseif errorID == 12 then
        require("common.MsgBoxLayer"):create(2,nil,"代理房卡不够不能创建!")
    elseif errorID == 13 then
        require("common.MsgBoxLayer"):create(2,nil,"未授权代开权限,请联系代理授权代开权限!")
    elseif errorID == 14 then
        require("common.MsgBoxLayer"):create(2,nil,"您已经达到代开房上限，不能再创建了!")
    elseif errorID == 15 then
        require("common.MsgBoxLayer"):create(2,nil,"该亲友圈不存在!",function()
            require("common.SceneMgr"):switchOperation()
            cc.UserDefault:getInstance():setIntegerForKey("UserDefault_NewClubID", 0)
        end)
    elseif errorID == 16 then
        require("common.MsgBoxLayer"):create(2,nil,"您已经不在该亲友圈了!")
    elseif errorID == 17 then
        require("common.MsgBoxLayer"):create(2,nil,"该亲友圈未设置玩法!")
    elseif errorID == 18 then
        require("common.MsgBoxLayer"):create(2,nil,"亲友圈群主房卡不够不能创建!")
    elseif errorID == 19 then
        require("common.MsgBoxLayer"):create(2,nil,"亲友圈房卡不够不能创建!")
    elseif errorID == 20 then
        require("common.MsgBoxLayer"):create(2,nil,"您已被群主暂停娱乐,请联系群主恢复!")
    elseif errorID == 21 then
        require("common.MsgBoxLayer"):create(2,nil,"您的疲劳值不够,请联系群主!")
    elseif errorID == 22 then
        require("common.MsgBoxLayer"):create(2,nil,"防沉迷配置错误,请联系群主重新设置!")
    elseif errorID == 23 then
        require("common.MsgBoxLayer"):create(2,nil,"亲友圈玩法不存在,请重新刷新亲友圈!")
    elseif errorID == 24 then
        require("common.MsgBoxLayer"):create(2,nil,"您的元宝不够,分享链接到微信购买！",function() 
            local data = clone(UserData.Share.tableShareParameter[12])
            require("app.MyApp"):create(data):createView("ShareLayer")
        end)
    elseif errorID == 25 then
        require("common.MsgBoxLayer"):create(2,nil,"防沉迷值已达下限!")
    elseif errorID == 30 then
        require("common.MsgBoxLayer"):create(2,nil,"该房间有距离限制,请开启定位!")
    else
        require("common.MsgBoxLayer"):create(2,nil,"请升级您的版本!")
    end
    NetMgr:getGameInstance():closeConnect()
end

function InterfaceCreateRoomNode:SUB_GR_LOGON_SUCCESS(event)
    if self.wKindID == 15 then
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER,NetMsgId.REQ_GR_CREATE_TABLE,"diwwwwdb",
            CHANNEL_ID,self.nTableType,self.wTableSubType,self.wKindID,self.wGameCount,1,self.dwTargetID,
            self.tableParameter.bPlayerCount)

    elseif self.wKindID == 16 then
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER,NetMsgId.REQ_GR_CREATE_TABLE,"diwwwwdbbbb",
            CHANNEL_ID,self.nTableType,self.wTableSubType,self.wKindID,self.wGameCount,1,self.dwTargetID,
            self.tableParameter.bPlayerCount,self.tableParameter.bSuccessive,self.tableParameter.bQiangHuPai,
            self.tableParameter.bLianZhuangSocre)     
    elseif self.wKindID == 17 then
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER,NetMsgId.REQ_GR_CREATE_TABLE,"diwwwwdbbbbbbwbbbbbbbbdbbb",
            CHANNEL_ID,self.nTableType,self.wTableSubType,self.wKindID,self.wGameCount,1,self.dwTargetID,
            self.tableParameter.FanXing.bType,self.tableParameter.FanXing.bCount,self.tableParameter.FanXing.bAddTun,
            self.tableParameter.bPlayerCountType,self.tableParameter.bPlayerCount,self.tableParameter.bLaiZiCount,
            self.tableParameter.bMaxLost,self.tableParameter.bYiWuShi,self.tableParameter.bLiangPai,self.tableParameter.bCanHuXi,self.tableParameter.bHuType,
            self.tableParameter.bFangPao,self.tableParameter.bSettlement,self.tableParameter.bStartTun,self.tableParameter.bSocreType,self.tableParameter.dwMingTang,
            self.tableParameter.bPiaoHu,self.tableParameter.bHongHu,self.tableParameter.bTurn) 
                   
    elseif self.wKindID == 21 then
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER,NetMsgId.REQ_GR_CREATE_TABLE,"diwwwwdbb",
            CHANNEL_ID,self.nTableType,self.wTableSubType,self.wKindID,self.wGameCount,1,self.dwTargetID,
            self.tableParameter.bPlayerCountType,self.tableParameter.bPlayerCount)
    
    elseif self.wKindID == 22 then
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER,NetMsgId.REQ_GR_CREATE_TABLE,"diwwwwdbbbbbbwbbbbbbbbd",
            CHANNEL_ID,self.nTableType,self.wTableSubType,self.wKindID,self.wGameCount,1,self.dwTargetID,
            self.tableParameter.FanXing.bType,self.tableParameter.FanXing.bCount,self.tableParameter.FanXing.bAddTun,
            self.tableParameter.bPlayerCountType,self.tableParameter.bPlayerCount,self.tableParameter.bLaiZiCount,self.tableParameter.bMaxLost,
            self.tableParameter.bYiWuShi,self.tableParameter.bLiangPai,self.tableParameter.bCanHuXi,self.tableParameter.bHuType,
            self.tableParameter.bFangPao,self.tableParameter.bSettlement,self.tableParameter.bStartTun,self.tableParameter.bSocreType,
            self.tableParameter.dwMingTang)
        
    elseif self.wKindID == 23 then
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER,NetMsgId.REQ_GR_CREATE_TABLE,"diwwwwdbbbbbbwbbbbbbbbd",
            CHANNEL_ID,self.nTableType,self.wTableSubType,self.wKindID,self.wGameCount,1,self.dwTargetID,
            self.tableParameter.FanXing.bType,self.tableParameter.FanXing.bCount,self.tableParameter.FanXing.bAddTun,
            self.tableParameter.bPlayerCountType,self.tableParameter.bPlayerCount,self.tableParameter.bLaiZiCount,
            self.tableParameter.bMaxLost,self.tableParameter.bYiWuShi,self.tableParameter.bLiangPai,self.tableParameter.bCanHuXi,self.tableParameter.bHuType,
            self.tableParameter.bFangPao,self.tableParameter.bSettlement,self.tableParameter.bStartTun,self.tableParameter.bSocreType,
            self.tableParameter.dwMingTang)
            
    elseif self.wKindID == 24 then
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER,NetMsgId.REQ_GR_CREATE_TABLE,"diwwwwdbbbbbbwbbbbbbbbdbbbbbb",
            CHANNEL_ID,self.nTableType,self.wTableSubType,self.wKindID,self.wGameCount,1,self.dwTargetID,
            self.tableParameter.FanXing.bType,self.tableParameter.FanXing.bCount,self.tableParameter.FanXing.bAddTun,
            self.tableParameter.bPlayerCountType,self.tableParameter.bPlayerCount,self.tableParameter.bLaiZiCount,
            self.tableParameter.bMaxLost,self.tableParameter.bYiWuShi,self.tableParameter.bLiangPai,self.tableParameter.bCanHuXi,self.tableParameter.bHuType,
            self.tableParameter.bFangPao,self.tableParameter.bSettlement,self.tableParameter.bStartTun,self.tableParameter.bSocreType,self.tableParameter.dwMingTang,
            self.tableParameter.bPiaoHu,self.tableParameter.bHongHu,self.tableParameter.bDelShowCardHu,self.tableParameter.bDeathCard,
            self.tableParameter.bStartBanker,self.tableParameter.bStopCardGo) 
            
    elseif self.wKindID == 33 then
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER,NetMsgId.REQ_GR_CREATE_TABLE,"diwwwwdbbbbbbwbbbbbbbbdb",
            CHANNEL_ID,self.nTableType,self.wTableSubType,self.wKindID,self.wGameCount,1,self.dwTargetID,
            self.tableParameter.FanXing.bType,self.tableParameter.FanXing.bCount,self.tableParameter.FanXing.bAddTun,self.tableParameter.bPlayerCountType,
            self.tableParameter.bPlayerCount,self.tableParameter.bLaiZiCount,self.tableParameter.bMaxLost,self.tableParameter.bYiWuShi,self.tableParameter.bLiangPai,
            self.tableParameter.bCanHuXi,self.tableParameter.bHuType,self.tableParameter.bFangPao,self.tableParameter.bSettlement,self.tableParameter.bStartTun,
            self.tableParameter.bSocreType,self.tableParameter.dwMingTang,self.tableParameter.bLimit)
    elseif self.wKindID == 16 then
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER,NetMsgId.REQ_GR_CREATE_TABLE,"diwwwwdbbbb",
            CHANNEL_ID,self.nTableType,self.wTableSubType,self.wKindID,self.wGameCount,1,self.dwTargetID,
            self.tableParameter.bPlayerCount,self.tableParameter.bSuccessive,self.tableParameter.bQiangHuPai,
            self.tableParameter.bLianZhuangSocre)           
    elseif self.wKindID == 20 then
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER,NetMsgId.REQ_GR_CREATE_TABLE,"diwwwwdbbbw",
            CHANNEL_ID,self.nTableType,self.wTableSubType,self.wKindID,self.wGameCount,1,self.dwTargetID,                 
            self.tableParameter.bPlayerCountType,self.tableParameter.bPlayerCount,self.tableParameter.bTotalHuXi,self.tableParameter.bMaxLost) 
    elseif self.wKindID == 25 or self.wKindID == 26  then
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER,NetMsgId.REQ_GR_CREATE_TABLE,"diwwwwdbbbbbbbbbb",
            CHANNEL_ID,self.nTableType,self.wTableSubType,self.wKindID,self.wGameCount,1,self.dwTargetID,
            self.tableParameter.bPlayerCount, self.tableParameter.bStartCard,self.tableParameter.bBombSeparation,self.tableParameter.bRed10,
            self.tableParameter.b4Add3,self.tableParameter.bShowCardCount,self.tableParameter.bSpringMinCount,self.tableParameter.bAbandon,self.tableParameter.bCheating,self.tableParameter.bFalseSpring)
    elseif self.wKindID == 27 then
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER,NetMsgId.REQ_GR_CREATE_TABLE,"diwwwwdbbbbbbwbbbbbbbbd",
            CHANNEL_ID,self.nTableType,self.wTableSubType,self.wKindID,self.wGameCount,1,self.dwTargetID,
            self.tableParameter.FanXing.bType,self.tableParameter.FanXing.bCount,self.tableParameter.FanXing.bAddTun,
            self.tableParameter.bPlayerCountType,self.tableParameter.bPlayerCount,self.tableParameter.bLaiZiCount,self.tableParameter.bMaxLost,self.tableParameter.bYiWuShi,self.tableParameter.bLiangPai,self.tableParameter.bCanHuXi,self.tableParameter.bHuType,
            self.tableParameter.bFangPao,self.tableParameter.bSettlement,self.tableParameter.bStartTun,self.tableParameter.bSocreType,self.tableParameter.dwMingTang)
    elseif self.wKindID == 34 then
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER,NetMsgId.REQ_GR_CREATE_TABLE,"diwwwwdbbbbbbwbbbbbbbbdb",
            CHANNEL_ID,self.nTableType,self.wTableSubType,self.wKindID,self.wGameCount,1,self.dwTargetID,
            self.tableParameter.FanXing.bType,self.tableParameter.FanXing.bCount,self.tableParameter.FanXing.bAddTun,
            self.tableParameter.bPlayerCountType,self.tableParameter.bPlayerCount,self.tableParameter.bLaiZiCount,self.tableParameter.bMaxLost,self.tableParameter.bYiWuShi,self.tableParameter.bLiangPai,self.tableParameter.bCanHuXi,self.tableParameter.bHuType,
            self.tableParameter.bFangPao,self.tableParameter.bSettlement,self.tableParameter.bStartTun,self.tableParameter.bSocreType,self.tableParameter.dwMingTang,self.tableParameter.bDouble)
    elseif self.wKindID == 35 then
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER,NetMsgId.REQ_GR_CREATE_TABLE,"diwwwwdbbbbbbwbbbbbbbbdb",
            CHANNEL_ID,self.nTableType,self.wTableSubType,self.wKindID,self.wGameCount,1,self.dwTargetID,
            self.tableParameter.FanXing.bType,self.tableParameter.FanXing.bCount,self.tableParameter.FanXing.bAddTun,self.tableParameter.bPlayerCountType,
            self.tableParameter.bPlayerCount,self.tableParameter.bLaiZiCount,self.tableParameter.bMaxLost,self.tableParameter.bYiWuShi,self.tableParameter.bLiangPai,
            self.tableParameter.bCanHuXi,self.tableParameter.bHuType,self.tableParameter.bFangPao,self.tableParameter.bSettlement,self.tableParameter.bStartTun,
            self.tableParameter.bSocreType,self.tableParameter.dwMingTang,self.tableParameter.bLimit)
            
    elseif self.wKindID == 36 then
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER,NetMsgId.REQ_GR_CREATE_TABLE,"diwwwwdbbbbbbwbbbbbbbbdb",
            CHANNEL_ID,self.nTableType,self.wTableSubType,self.wKindID,self.wGameCount,1,self.dwTargetID,
            self.tableParameter.FanXing.bType,self.tableParameter.FanXing.bCount,self.tableParameter.FanXing.bAddTun,self.tableParameter.bPlayerCountType,
            self.tableParameter.bPlayerCount,self.tableParameter.bLaiZiCount,self.tableParameter.bMaxLost,self.tableParameter.bYiWuShi,self.tableParameter.bLiangPai,
            self.tableParameter.bCanHuXi,self.tableParameter.bHuType,self.tableParameter.bFangPao,self.tableParameter.bSettlement,self.tableParameter.bStartTun,
            self.tableParameter.bSocreType,self.tableParameter.dwMingTang,self.tableParameter.bLimit)
      
    elseif self.wKindID == 31 then
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER,NetMsgId.REQ_GR_CREATE_TABLE,"diwwwwdbbbbbbwbbbbbbbbdbb",
            CHANNEL_ID,self.nTableType,self.wTableSubType,self.wKindID,self.wGameCount,1,self.dwTargetID,
            self.tableParameter.FanXing.bType,self.tableParameter.FanXing.bCount,self.tableParameter.FanXing.bAddTun,self.tableParameter.bPlayerCountType,
            self.tableParameter.bPlayerCount,self.tableParameter.bLaiZiCount,self.tableParameter.bMaxLost,self.tableParameter.bYiWuShi,self.tableParameter.bLiangPai,
            self.tableParameter.bCanHuXi,self.tableParameter.bHuType,self.tableParameter.bFangPao,self.tableParameter.bSettlement,self.tableParameter.bStartTun,
            self.tableParameter.bSocreType,self.tableParameter.dwMingTang,self.tableParameter.bLimit,self.tableParameter.bDeathCard)
                  
    elseif self.wKindID == 37 then
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER,NetMsgId.REQ_GR_CREATE_TABLE,"diwwwwdbbbbbbwbbbbbbbbdb",
            CHANNEL_ID,self.nTableType,self.wTableSubType,self.wKindID,self.wGameCount,1,self.dwTargetID,
            self.tableParameter.FanXing.bType,self.tableParameter.FanXing.bCount,self.tableParameter.FanXing.bAddTun,self.tableParameter.bPlayerCountType,
            self.tableParameter.bPlayerCount,self.tableParameter.bLaiZiCount,self.tableParameter.bMaxLost,self.tableParameter.bYiWuShi,self.tableParameter.bLiangPai,
            self.tableParameter.bCanHuXi,self.tableParameter.bHuType,self.tableParameter.bFangPao,self.tableParameter.bSettlement,self.tableParameter.bStartTun,
            self.tableParameter.bSocreType,self.tableParameter.dwMingTang,self.tableParameter.bLimit)
            
    elseif self.wKindID == 32 then
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER,NetMsgId.REQ_GR_CREATE_TABLE,"diwwwwdbbbbbbwbbbbbbbbdb",
            CHANNEL_ID,self.nTableType,self.wTableSubType,self.wKindID,self.wGameCount,1,self.dwTargetID,
            self.tableParameter.FanXing.bType,self.tableParameter.FanXing.bCount,self.tableParameter.FanXing.bAddTun,self.tableParameter.bPlayerCountType,
            self.tableParameter.bPlayerCount,self.tableParameter.bLaiZiCount,self.tableParameter.bMaxLost,self.tableParameter.bYiWuShi,self.tableParameter.bLiangPai,
            self.tableParameter.bCanHuXi,self.tableParameter.bHuType,self.tableParameter.bFangPao,self.tableParameter.bSettlement,self.tableParameter.bStartTun,
            self.tableParameter.bSocreType,self.tableParameter.dwMingTang,self.tableParameter.bLimit)
            
    elseif self.wKindID == 44 then
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER,NetMsgId.REQ_GR_CREATE_TABLE,"diwwwwdbbbbbbwbbbbbbbbdbbbb",
            CHANNEL_ID,self.nTableType,self.wTableSubType,self.wKindID,self.wGameCount,1,self.dwTargetID,
            self.tableParameter.FanXing.bType,self.tableParameter.FanXing.bCount,self.tableParameter.FanXing.bAddTun,
            self.tableParameter.bPlayerCountType,self.tableParameter.bPlayerCount,self.tableParameter.bLaiZiCount,self.tableParameter.bMaxLost,
            self.tableParameter.bYiWuShi,self.tableParameter.bLiangPai,self.tableParameter.bCanHuXi,self.tableParameter.bHuType,
            self.tableParameter.bFangPao,self.tableParameter.bSettlement,self.tableParameter.bStartTun,self.tableParameter.bSocreType,
            self.tableParameter.dwMingTang,self.tableParameter.bTurn,self.tableParameter.bPaoTips,self.tableParameter.bStartBanker,self.tableParameter.bDeathCard)
    elseif self.wKindID == 38 then
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER,NetMsgId.REQ_GR_CREATE_TABLE,"diwwwwdbbbbbbwbbbbbbbbdbb",
            CHANNEL_ID,self.nTableType,self.wTableSubType,self.wKindID,self.wGameCount,1,self.dwTargetID,
            self.tableParameter.FanXing.bType,self.tableParameter.FanXing.bCount,self.tableParameter.FanXing.bAddTun,
            self.tableParameter.bPlayerCountType,self.tableParameter.bPlayerCount,self.tableParameter.bLaiZiCount,self.tableParameter.bMaxLost,
            self.tableParameter.bYiWuShi,self.tableParameter.bLiangPai,self.tableParameter.bCanHuXi,self.tableParameter.bHuType,
            self.tableParameter.bFangPao,self.tableParameter.bSettlement,self.tableParameter.bStartTun,self.tableParameter.bSocreType,self.tableParameter.dwMingTang
            ,self.tableParameter.bFangPaoPay,self.tableParameter.bStartBanker)
            
    elseif self.wKindID == 39 then     
       NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER,NetMsgId.REQ_GR_CREATE_TABLE,"diwwwwdbbbbbbwbbbbbbbbdbbb",
            CHANNEL_ID,self.nTableType,self.wTableSubType,self.wKindID,self.wGameCount,1,self.dwTargetID,
            self.tableParameter.FanXing.bType,self.tableParameter.FanXing.bCount,self.tableParameter.FanXing.bAddTun,
            self.tableParameter.bPlayerCountType,self.tableParameter.bPlayerCount,self.tableParameter.bLaiZiCount,self.tableParameter.bMaxLost,
            self.tableParameter.bYiWuShi,self.tableParameter.bLiangPai,self.tableParameter.bCanHuXi,self.tableParameter.bHuType,
            self.tableParameter.bFangPao,self.tableParameter.bSettlement,self.tableParameter.bStartTun,self.tableParameter.bSocreType,self.tableParameter.dwMingTang
            ,self.tableParameter.bStartBanker,self.tableParameter.bCanSiShou,self.tableParameter.bCanJuShouZuoSheng)
    elseif self.wKindID == 40 then
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER,NetMsgId.REQ_GR_CREATE_TABLE,"diwwwwdbbbbbbwbbbbbbbbdbbbbbbbb",
            CHANNEL_ID,self.nTableType,self.wTableSubType,self.wKindID,self.wGameCount,1,self.dwTargetID,
            self.tableParameter.FanXing.bType,self.tableParameter.FanXing.bCount,self.tableParameter.FanXing.bAddTun,
            self.tableParameter.bPlayerCountType,self.tableParameter.bPlayerCount,self.tableParameter.bLaiZiCount,self.tableParameter.bMaxLost,self.tableParameter.bYiWuShi,
            self.tableParameter.bLiangPai,self.tableParameter.bCanHuXi,self.tableParameter.bHuType,self.tableParameter.bFangPao,
            self.tableParameter.bSettlement,self.tableParameter.bStartTun,self.tableParameter.bSocreType,self.tableParameter.dwMingTang
            ,self.tableParameter.bCardCount21,self.tableParameter.bMinLostCell,self.tableParameter.bMinLost,self.tableParameter.bDeathCard
            ,self.tableParameter.bStartBanker,self.tableParameter.bDelShowCardHu,self.tableParameter.bPiaoHu,self.tableParameter.bStopCardGo)
    elseif self.wKindID == 42 then
            NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER,NetMsgId.REQ_GR_CREATE_TABLE,"diwwwwdbwbbbb",
            CHANNEL_ID,self.nTableType,self.wTableSubType,self.wKindID,self.wGameCount,1,self.dwTargetID,
            self.tableParameter.numpep,self.tableParameter.mailiao,self.tableParameter.fanbei,self.tableParameter.jiabei,self.tableParameter.zimo,self.tableParameter.piaohua) 
    elseif self.wKindID == 43 then
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER,NetMsgId.REQ_GR_CREATE_TABLE,"diwwwwdbbbb",
            CHANNEL_ID,self.nTableType,self.wTableSubType,self.wKindID,self.wGameCount,1,self.dwTargetID,
            self.tableParameter.bPlayerCount,self.tableParameter.bCanHuXi,self.tableParameter.bChongFen,self.tableParameter.bFanBei)
    elseif self.wKindID == 68 then
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER,NetMsgId.REQ_GR_CREATE_TABLE,"diwwwwdbbbbbbbbbb",
            CHANNEL_ID,self.nTableType,self.wTableSubType,self.wKindID,self.wGameCount,1,self.dwTargetID,
            self.tableParameter.bPlayerCount,self.tableParameter.bMaType,self.tableParameter.bMaCount,self.tableParameter.bQGHu,
            self.tableParameter.bQGHuJM,self.tableParameter.bHuangZhuangHG,self.tableParameter.bQingSH,self.tableParameter.bJiePao,self.tableParameter.bNiaoType,self.tableParameter.bQiDui)
    elseif self.wKindID == 46 then
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER,NetMsgId.REQ_GR_CREATE_TABLE,"diwwwwdbbbbbbbbb",
            CHANNEL_ID,self.nTableType,self.wTableSubType,self.wKindID,self.wGameCount,1,self.dwTargetID,self.tableParameter.bPlayerCount,
            self.tableParameter.bMaType,self.tableParameter.bMaCount,self.tableParameter.bQGHu,self.tableParameter.bQGHuJM,
            self.tableParameter.bHuangZhuangHG,self.tableParameter.bQingSH,self.tableParameter.bJiePao,self.tableParameter.bQiDui)  
    elseif self.wKindID == 61 then
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER,NetMsgId.REQ_GR_CREATE_TABLE,"diwwwwdbbbbbbbb",
            CHANNEL_ID,self.nTableType,self.wTableSubType,self.wKindID,self.wGameCount,1,self.dwTargetID,self.tableParameter.bPlayerCount,
            self.tableParameter.bMaType,self.tableParameter.bMaCount,self.tableParameter.bQGHu,self.tableParameter.bQGHuJM,
            self.tableParameter.bHuangZhuangHG,self.tableParameter.bQingSH,self.tableParameter.bJiePao)   
    elseif self.wKindID == 47 then
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER,NetMsgId.REQ_GR_CREATE_TABLE,"diwwwwdbbbbbbwbbbbbbbbdbbb",
            CHANNEL_ID,self.nTableType,self.wTableSubType,self.wKindID,self.wGameCount,1,self.dwTargetID,
            self.tableParameter.FanXing.bType,self.tableParameter.FanXing.bCount,self.tableParameter.FanXing.bAddTun,
            self.tableParameter.bPlayerCountType,self.tableParameter.bPlayerCount,self.tableParameter.bLaiZiCount,self.tableParameter.bMaxLost,
            self.tableParameter.bYiWuShi,self.tableParameter.bLiangPai,self.tableParameter.bCanHuXi,self.tableParameter.bHuType,
            self.tableParameter.bFangPao,self.tableParameter.bSettlement,self.tableParameter.bStartTun,self.tableParameter.bSocreType,
            self.tableParameter.dwMingTang,self.tableParameter.bTurn,self.tableParameter.bDeathCard,self.tableParameter.bStartBanker)  
            
    elseif self.wKindID == 48 then
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER,NetMsgId.REQ_GR_CREATE_TABLE,"diwwwwdbbbbbbwbbbbbbbbdbbbbbbbb",
            CHANNEL_ID,self.nTableType,self.wTableSubType,self.wKindID,self.wGameCount,1,self.dwTargetID,
            self.tableParameter.FanXing.bType,self.tableParameter.FanXing.bCount,self.tableParameter.FanXing.bAddTun,
            self.tableParameter.bPlayerCountType,self.tableParameter.bPlayerCount,self.tableParameter.bLaiZiCount,self.tableParameter.bMaxLost,
            self.tableParameter.bYiWuShi,self.tableParameter.bLiangPai,self.tableParameter.bCanHuXi,self.tableParameter.bHuType,
            self.tableParameter.bFangPao,self.tableParameter.bSettlement,self.tableParameter.bStartTun,self.tableParameter.bSocreType,
            self.tableParameter.dwMingTang,self.tableParameter.bTurn,self.tableParameter.bPaoTips,self.tableParameter.bStartBanker,
            self.tableParameter.bSiQiHong,self.tableParameter.bDelShuaHou,self.tableParameter.bHuangFanAddUp,self.tableParameter.bTingHuAll,
            self.tableParameter.bDeathCard)  
            
    elseif self.wKindID == 49 then
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER,NetMsgId.REQ_GR_CREATE_TABLE,"diwwwwdbbbbbbwbbbbbbbbdbbbbb",
            CHANNEL_ID,self.nTableType,self.wTableSubType,self.wKindID,self.wGameCount,1,self.dwTargetID,
            self.tableParameter.FanXing.bType,self.tableParameter.FanXing.bCount,self.tableParameter.FanXing.bAddTun,
            self.tableParameter.bPlayerCountType,self.tableParameter.bPlayerCount,self.tableParameter.bLaiZiCount,self.tableParameter.bMaxLost,
            self.tableParameter.bYiWuShi,self.tableParameter.bLiangPai,self.tableParameter.bCanHuXi,self.tableParameter.bHuType,
            self.tableParameter.bFangPao,self.tableParameter.bSettlement,self.tableParameter.bStartTun,self.tableParameter.bSocreType,
            self.tableParameter.dwMingTang,self.tableParameter.bTurn,self.tableParameter.bDeathCard,self.tableParameter.bStartBanker,self.tableParameter.bHuangFanAddUp,self.tableParameter.STWK)  
             
     elseif self.wKindID == 50 then
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER,NetMsgId.REQ_GR_CREATE_TABLE,"diwwwwdbbbbbbbbbbbbbbbbb",
            CHANNEL_ID,self.nTableType,self.wTableSubType,self.wKindID,self.wGameCount,1,self.dwTargetID,
            self.tableParameter.bPlayerCount,
            self.tableParameter.bNiaoAdd,self.tableParameter.mNiaoCount,self.tableParameter.bLLSFlag,self.tableParameter.bQYSFlag,
            self.tableParameter.bWJHFlag,self.tableParameter.bDSXFlag,self.tableParameter.bBBGFlag,self.tableParameter.bSTFlag,
            self.tableParameter.bYZHFlag,self.tableParameter.bMQFlag,self.tableParameter.mZXFlag,self.tableParameter.mPFFlag,
            self.tableParameter.mZTSXlag,self.tableParameter.bJJHFlag,self.tableParameter.bWuTong,self.tableParameter.mMaOne)   
    
    elseif self.wKindID == 70 then
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER,NetMsgId.REQ_GR_CREATE_TABLE,"diwwwwdbbbbbbbbbbbbbbbbbbb",
            CHANNEL_ID,self.nTableType,self.wTableSubType,self.wKindID,self.wGameCount,1,self.dwTargetID,
            self.tableParameter.bPlayerCount,
            self.tableParameter.bNiaoAdd,self.tableParameter.mNiaoCount,self.tableParameter.bLLSFlag,self.tableParameter.bQYSFlag,
            self.tableParameter.bWJHFlag,self.tableParameter.bDSXFlag,self.tableParameter.bBBGFlag,self.tableParameter.bSTFlag,
            self.tableParameter.bYZHFlag,self.tableParameter.bMQFlag,self.tableParameter.mZXFlag,self.tableParameter.mPFFlag,
            self.tableParameter.mZTSXlag,self.tableParameter.bJJHFlag,self.tableParameter.bWuTong,self.tableParameter.mMaOne,
            self.tableParameter.mZTLLSFlag,self.tableParameter.mKGNPFlag)   
            
    elseif self.wKindID == 51 or self.wKindID == 55 or self.wKindID == 56 or self.wKindID == 57 or self.wKindID == 58 or self.wKindID == 59 then
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER,NetMsgId.REQ_GR_CREATE_TABLE,"diwwwwdbbbbbbbbbbbb",
            CHANNEL_ID,self.nTableType,self.wTableSubType,self.wKindID,self.wGameCount,1,self.dwTargetID,
            self.tableParameter.bPlayerCount,self.tableParameter.bBankerType,self.tableParameter.bMultiple,self.tableParameter.bBettingType,
            self.tableParameter.bSettlementType,self.tableParameter.bPush,self.tableParameter.bNoFlower,self.tableParameter.bCanPlayingJoin,
            self.tableParameter.bNiuType_Flush,self.tableParameter.bNiuType_Gourd,self.tableParameter.bNiuType_SameColor,self.tableParameter.bNiuType_Straight)
            
    elseif self.wKindID == 52 then
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER,NetMsgId.REQ_GR_CREATE_TABLE,"diwwwwdbbbbbb",
            CHANNEL_ID,self.nTableType,self.wTableSubType,self.wKindID,self.wGameCount,1,self.dwTargetID,
            self.tableParameter.bPlayerCount,
            self.tableParameter.bQGHu,self.tableParameter.bHuangZhuangHG,self.tableParameter.bJiePao,self.tableParameter.bHuQD,self.tableParameter.bMaCount)
            
    elseif self.wKindID == 53 then
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER,NetMsgId.REQ_GR_CREATE_TABLE,"diwwwwdbbbbbbb",
            CHANNEL_ID,self.nTableType,self.wTableSubType,self.wKindID,self.wGameCount,1,self.dwTargetID,
            self.tableParameter.bPlayerCount,self.tableParameter.bBankerType,self.tableParameter.bMultiple,self.tableParameter.bBettingType,
            self.tableParameter.bPush,self.tableParameter.bCanPlayingJoin,self.tableParameter.bExtreme)     
    elseif self.wKindID == 54 then
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER,NetMsgId.REQ_GR_CREATE_TABLE,"diwwwwdbbbbbbbbbbbbb",
            CHANNEL_ID,self.nTableType,self.wTableSubType,self.wKindID,self.wGameCount,1,self.dwTargetID,
            self.tableParameter.bPlayerCount,self.tableParameter.bHuType,self.tableParameter.bDHPlayFlag,self.tableParameter.bDFFlag,
            self.tableParameter.bDXPFlag,self.tableParameter.bBTHu,self.tableParameter.bQYMFlag,self.tableParameter.bQDJFFlag,
            self.tableParameter.bLLFlag,self.tableParameter.bQYSFlag,self.tableParameter.bZJJD,self.tableParameter.bGSKHJB,self.tableParameter.bQDFlag)    
    elseif self.wKindID == 60 then
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER,NetMsgId.REQ_GR_CREATE_TABLE,"diwwwwdbbbbbbwbbbbbbbbdb",
            CHANNEL_ID,self.nTableType,self.wTableSubType,self.wKindID,self.wGameCount,1,self.dwTargetID,
            self.tableParameter.FanXing.bType,self.tableParameter.FanXing.bCount,self.tableParameter.FanXing.bAddTun,
            self.tableParameter.bPlayerCountType,self.tableParameter.bPlayerCount,self.tableParameter.bLaiZiCount,self.tableParameter.bMaxLost,
            self.tableParameter.bYiWuShi,self.tableParameter.bLiangPai,self.tableParameter.bCanHuXi,self.tableParameter.bHuType,
            self.tableParameter.bFangPao,self.tableParameter.bSettlement,self.tableParameter.bStartTun,self.tableParameter.bSocreType,
            self.tableParameter.dwMingTang,self.tableParameter.bTurn) 
    elseif self.wKindID == 63 then
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER,NetMsgId.REQ_GR_CREATE_TABLE,"diwwwwdbbbbbbbbb",
            CHANNEL_ID,self.nTableType,self.wTableSubType,self.wKindID,self.wGameCount,1,self.dwTargetID,
            self.tableParameter.bPlayerCount,self.tableParameter.bMaType,self.tableParameter.bMaCount,self.tableParameter.bQGHu,
            self.tableParameter.bQGHuJM,self.tableParameter.bHuangZhuangHG,self.tableParameter.bQingSH,self.tableParameter.bJiePao,self.tableParameter.bNiaoType)
    elseif self.wKindID == 65 then
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER,NetMsgId.REQ_GR_CREATE_TABLE,"diwwwwdbbbb",
            CHANNEL_ID,self.nTableType,self.wTableSubType,self.wKindID,self.wGameCount,1,self.dwTargetID,
            self.tableParameter.bPlayerCount,self.tableParameter.bMaiPiaoCount,self.tableParameter.bDiCount,self.tableParameter.bHuangZhuangHG)     
    elseif self.wKindID == 67 then
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER,NetMsgId.REQ_GR_CREATE_TABLE,"diwwwwdbbbbbbbbbbbbbbbl",--l
            CHANNEL_ID,self.nTableType,self.wTableSubType,self.wKindID,self.wGameCount,1,self.dwTargetID,
            self.tableParameter.bPlayerCount,self.tableParameter.bMaType,self.tableParameter.bMaCount,self.tableParameter.bQGHu,
            self.tableParameter.bQGHuJM,self.tableParameter.bHuangZhuangHG,self.tableParameter.bQingSH,self.tableParameter.bJiePao,self.tableParameter.bNiaoType,
            self.tableParameter.bQingYiSe,self.tableParameter.bQiXiaoDui,self.tableParameter.bPPHu,self.tableParameter.bWuTong,self.tableParameter.mPFFlag,self.tableParameter.mDiFen,
            self.tableParameter.mJFCount) 
    elseif self.wKindID == 69 then
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER,NetMsgId.REQ_GR_CREATE_TABLE,"diwwwwdbbbbbbwbbbbbbbbdbbbbbbbbb",
            CHANNEL_ID,self.nTableType,self.wTableSubType,self.wKindID,self.wGameCount,1,self.dwTargetID,
            self.tableParameter.FanXing.bType,self.tableParameter.FanXing.bCount,self.tableParameter.FanXing.bAddTun,
            self.tableParameter.bPlayerCountType,self.tableParameter.bPlayerCount,self.tableParameter.bLaiZiCount,self.tableParameter.bMaxLost,
            self.tableParameter.bYiWuShi,self.tableParameter.bLiangPai,self.tableParameter.bCanHuXi,self.tableParameter.bHuType,
            self.tableParameter.bFangPao,self.tableParameter.bSettlement,self.tableParameter.bStartTun,self.tableParameter.bSocreType,
            self.tableParameter.dwMingTang,self.tableParameter.bTurn,self.tableParameter.bPaoTips,self.tableParameter.bStartBanker,
            self.tableParameter.bSiQiHong,self.tableParameter.bDelShuaHou,self.tableParameter.bHuangFanAddUp,self.tableParameter.bTingHuAll,
            self.tableParameter.bDeathCard,self.tableParameter.bPaPo)  

    else
    end
end

function InterfaceCreateRoomNode:SUB_CL_GAME_SERVER_ERROR(event)
    local data = event._usedata
    self:removeFromParent() 
    require("common.MsgBoxLayer"):create(0,nil,"创建房间失败！")  
    
end

function InterfaceCreateRoomNode:SUB_CL_GAME_SERVER(event)
    local data = event._usedata
    UserData.Game:sendMsgConnectGame(data)
end

function InterfaceCreateRoomNode:EVENT_TYPE_CONNECT_GAME_FAILED(event)
    local data = event._usedata
    self:removeFromParent()
    require("common.MsgBoxLayer"):create(0,nil,"连接游戏失败,请查看您的网络状态！")
end
return InterfaceCreateRoomNode