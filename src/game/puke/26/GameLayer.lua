local StaticData = require("app.static.StaticData")
local Common = require("common.Common")
local EventType = require("common.EventType")
local EventMgr = require("common.EventMgr")
local NetMgr = require("common.NetMgr")
local EventType = require("common.EventType")
local NetMsgId = require("common.NetMsgId")
local GameCommon = require("game.puke.GameCommon")  
local UserData = require("app.user.UserData")
local Bit = require("common.Bit")
local GameDesc = require("common.GameDesc")

local TableLayer = require("game.puke.TableLayer")

local APPNAME = 'puke'
local GameLayer = class("GameLayer",function()
    return ccui.Layout:create()
end)

function GameLayer:create(...)
    local view = GameLayer.new()
    view:onCreate(...)
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

function GameLayer:onEnter()
    EventMgr:registListener(EventType.EVENT_TYPE_NET_RECV_MESSAGE,self,self.EVENT_TYPE_NET_RECV_MESSAGE)
    EventMgr:registListener(EventType.SUB_GR_MATCH_TABLE_ING,self,self.SUB_GR_MATCH_TABLE_ING)
    EventMgr:registListener(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK,self,self.EVENT_TYPE_CACEL_MESSAGE_BLOCK)
    EventMgr:registListener(EventType.SUB_GR_USER_ENTER,self,self.SUB_GR_USER_ENTER)
    if GameCommon.tableConfig.nTableType ~= TableType_Playback then
        self.scheduleUpdateObj = cc.Director:getInstance():getScheduler():scheduleScriptFunc(function(delta) self:update(delta) end, 0 ,false)
    end

end

function GameLayer:onExit()
    EventMgr:unregistListener(EventType.EVENT_TYPE_NET_RECV_MESSAGE,self,self.EVENT_TYPE_NET_RECV_MESSAGE)
    EventMgr:unregistListener(EventType.SUB_GR_MATCH_TABLE_ING,self,self.SUB_GR_MATCH_TABLE_ING)
    EventMgr:unregistListener(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK,self,self.EVENT_TYPE_CACEL_MESSAGE_BLOCK)
    EventMgr:unregistListener(EventType.SUB_GR_USER_ENTER,self,self.SUB_GR_USER_ENTER)
    if GameCommon.tableConfig.nTableType ~= TableType_Playback and self.scheduleUpdateObj then
        cc.Director:getInstance():getScheduler():unscheduleScriptEntry(self.scheduleUpdateObj)
    end
    
end

function GameLayer:onCleanup()

end

function GameLayer:onCreate(...)
    self:startGame(...)
end

function GameLayer:startGame(...)
    self:removeAllChildren()
    self:stopAllActions()
    local params = {...}
    GameCommon.dwUserID = params[1]
    GameCommon.tableConfig = params[2]
    GameCommon.playbackData = params[3]
    GameCommon.player = {}
    GameCommon.gameConfig = {}
    
    local visibleSize = cc.Director:getInstance():getVisibleSize()
    local csb = cc.CSLoader:createNode("GameLayerPaoDeKuai.csb")
    self:addChild(csb)
    self.root = csb:getChildByName("Panel_root")
    self.csb = csb       
    GameCommon:init()
    GameCommon.MAX_COUNT = 16
    self.tableLayer = TableLayer:create(self.root)
    self:addChild(self.tableLayer)
    self.tableLayer:initUI()
    self.tableLayer:updateGameState(GameCommon.GameState_Init)
    self.isRunningActions = false
    self.userMsgArray = {} --消息缓存
    GameCommon.regionSound = 0
    
    local uiButton_Invitation = ccui.Helper:seekWidgetByName(self.root,"Button_Invitation")
    if StaticData.Hide[CHANNEL_ID].btn4 ~= 1 then
        uiButton_Invitation:setVisible(false)
    end
    self:loadingPlayback()
end

function GameLayer:loadingPlayback()
    if GameCommon.tableConfig.nTableType ~= TableType_Playback then
        return
    end
    local uiPanel_end = ccui.Helper:seekWidgetByName(self.root,"Panel_end")
    uiPanel_end:setVisible(true)
    uiPanel_end:removeAllChildren()
    uiPanel_end:stopAllActions()
    local visibleSize = cc.Director:getInstance():getVisibleSize()
    local csb = cc.CSLoader:createNode("GameLayer_PlaybacLayer.csb")
    uiPanel_end:addChild(csb)
    local root = csb:getChildByName("Panel_root")
    local uiImage_bg = ccui.Helper:seekWidgetByName(root,"Image_bg")
    uiImage_bg:setPositionY(uiImage_bg:getPositionY()+70)
    local uiButton_return = ccui.Helper:seekWidgetByName(root,"Button_return")
    Common:addTouchEventListener(uiButton_return,function() 
        require("common.SceneMgr"):switchScene(require("app.MyApp"):create():createView("HallLayer"),SCENE_HALL) 
    end)
    local uiButton_play = ccui.Helper:seekWidgetByName(root,"Button_play")
    uiButton_play:setColor(cc.c3b(170,170,170))
    local uiButton_nextStep = ccui.Helper:seekWidgetByName(root,"Button_nextStep")
    Common:addTouchEventListener(uiButton_play,function(sender,event)
        uiButton_nextStep:setColor(cc.c3b(170,170,170))
        uiButton_play:setColor(cc.c3b(255,255,255))
        root:stopAllActions() 
        root:runAction(cc.RepeatForever:create(cc.Sequence:create(
            cc.DelayTime:create(0),
            cc.CallFunc:create(function(sender,event) self:update(0) end)
            )))
    end)
    Common:addTouchEventListener(uiButton_nextStep,function(sender,event) 
        uiButton_play:setColor(cc.c3b(170,170,170))
        uiButton_nextStep:setColor(cc.c3b(255,255,255))
        root:stopAllActions() 
        self:update()
    end)
    self:AnalysisPlaybackData()
end

function GameLayer:AnalysisPlaybackData()
    if GameCommon.playbackData == nil then
        return
    end
    local luaFunc = require("common.Serialize"):create("",0)
    for key, var in pairs(GameCommon.playbackData) do
        luaFunc:writeSendBuffer(var.cbData,var.wDataSize)
    end
    while 1 do
        local wIdentifier = luaFunc:readRecvWORD()           --类型标示
        local wDataSize = luaFunc:readRecvWORD()             --数据长度
        local mainCmdID = luaFunc:readRecvWORD()            --主命令码
        local subCmdID = luaFunc:readRecvWORD()             --子命令码
        print("回放标志:",wIdentifier,wDataSize,mainCmdID,subCmdID)
        if self:readBuffer(luaFunc,mainCmdID,subCmdID) == false then
            return
        end       
    end
end

function GameLayer:SUB_GR_MATCH_TABLE_ING(event)
    local data = event._usedata
    self:startGame(UserData.User.userID, data)
end

function GameLayer:EVENT_TYPE_NET_RECV_MESSAGE(event)
	local netID = event._usedata
	if netID ~= NetMgr.NET_GAME then
	   return
	end
    local netInstance = NetMgr:getGameInstance()
    local mainCmdID = netInstance.cppFunc:GetMainCmdID()
    local subCmdID = netInstance.cppFunc:GetSubCmdID()
    
    local luaFunc = netInstance.cppFunc
    self:readBuffer(luaFunc, mainCmdID, subCmdID)
end

function GameLayer:readBuffer(luaFunc, mainCmdID, subCmdID)
    local _tagMsg = {}
    _tagMsg.mainCmdID = mainCmdID
    _tagMsg.subCmdID = subCmdID
    _tagMsg.pBuffer = {}
    
    if mainCmdID == NetMsgId.MDM_GR_USER then   
       if subCmdID == NetMsgId.SUB_GR_USER_READY then
            --服务器广播用户准备
            local dwUserID = luaFunc:readRecvDWORD()         --用户id
            local wChairID = luaFunc:readRecvWORD()         --椅子号
            GameCommon.player[wChairID].bReady = true
            self:updatePlayerReady()
            return true
            
        elseif subCmdID == NetMsgId.SUB_GR_USER_STATISTICS then
            --好友房大结算
            _tagMsg.pBuffer.dwUserCount = luaFunc:readRecvDWORD()                       --用户总数
            _tagMsg.pBuffer.dwDataCount = luaFunc:readRecvDWORD()                       --数据条数
            _tagMsg.pBuffer.tScoreInfo = {}                                             --统计信息
            _tagMsg.pBuffer.bigWinner = 0
            _tagMsg.pBuffer.bigWinerScore = 0
            for i = 1, 8 do
                _tagMsg.pBuffer.tScoreInfo[i] = {}
                _tagMsg.pBuffer.tScoreInfo[i].dwUserID = luaFunc:readRecvDWORD()        --用户ID
                _tagMsg.pBuffer.tScoreInfo[i].player = GameCommon:getUserInfoByUserID(_tagMsg.pBuffer.tScoreInfo[i].dwUserID)
                _tagMsg.pBuffer.tScoreInfo[i].totalScore = 0
                _tagMsg.pBuffer.tScoreInfo[i].lScore = {}
                for j = 1, 20 do
                    _tagMsg.pBuffer.tScoreInfo[i].lScore[j] = luaFunc:readRecvLong()       --用户积分
                    _tagMsg.pBuffer.tScoreInfo[i].totalScore = _tagMsg.pBuffer.tScoreInfo[i].totalScore + _tagMsg.pBuffer.tScoreInfo[i].lScore[j]
                end
                if _tagMsg.pBuffer.tScoreInfo[i].totalScore > _tagMsg.pBuffer.bigWinerScore then
                    _tagMsg.pBuffer.bigWinner = _tagMsg.pBuffer.tScoreInfo[i].dwUserID
                    _tagMsg.pBuffer.bigWinerScore = _tagMsg.pBuffer.tScoreInfo[i].totalScore
                end
            end
            _tagMsg.pBuffer.dwTableOwnerID = luaFunc:readRecvDWORD()                    --房主ID
            _tagMsg.pBuffer.szOwnerName = luaFunc:readRecvString(32)                    --房主名字
            _tagMsg.pBuffer.szGameID = luaFunc:readRecvString(32)                    --结算唯一标志
            _tagMsg.pBuffer.tableConfig = GameCommon.tableConfig
            _tagMsg.pBuffer.gameConfig = GameCommon.gameConfig
            _tagMsg.pBuffer.gameDesc = GameDesc:getGameDesc(GameCommon.tableConfig.wKindID,GameCommon.gameConfig,GameCommon.tableConfig)
            _tagMsg.pBuffer.cbOrigin = luaFunc:readRecvByte() --解散原因
            
        elseif subCmdID == NetMsgId.SUB_GR_USER_CONNECT then
            local luaFunc = NetMgr:getGameInstance().cppFunc
            local dwUserID=luaFunc:readRecvDWORD()
            local wChairID=luaFunc:readRecvWORD()
            GameCommon.player[wChairID].cbOnline = 0
            self:updatePlayerOnline()
            return true
            
        elseif subCmdID == NetMsgId.SUB_GR_USER_OFFLINE then
            local luaFunc = NetMgr:getGameInstance().cppFunc
            local dwUserID=luaFunc:readRecvDWORD()
            local wChairID=luaFunc:readRecvWORD()
            GameCommon.player[wChairID].cbOnline = 0x06
            self:updatePlayerOnline()
            return true
            
        elseif subCmdID == NetMsgId.SUB_GR_USER_LEAVE then
            local luaFunc = NetMgr:getGameInstance().cppFunc
            local dwUserID=luaFunc:readRecvDWORD()
            local wChairID=luaFunc:readRecvWORD()
            if GameCommon.dwUserID == dwUserID then
                require("common.SceneMgr"):switchScene(require("app.MyApp"):create():createView("HallLayer"),SCENE_HALL) 
            else
                GameCommon.player[wChairID] = nil
                self:updatePlayerInfo()
                self:updatePlayerPosition()
            end
            return true
            
        elseif subCmdID == NetMsgId.RET_GR_USER_SET_POSITION then
            local luaFunc = NetMgr:getGameInstance().cppFunc
            local location = {}
            location.x = luaFunc:readRecvDouble()
            location.y = luaFunc:readRecvDouble()
            local dwUserID = luaFunc:readRecvDWORD()
            local wChairID = luaFunc:readRecvWORD()
            if GameCommon.player[wChairID] ~= nil then
                GameCommon.player[wChairID].location = location
            end
            return true
                
        elseif subCmdID == NetMsgId.SUB_GR_TABLE_STATUS then 
            GameCommon.tableConfig.wTableNumber = luaFunc:readRecvWORD()       --房间局数
            GameCommon.tableConfig.wCurrentNumber = luaFunc:readRecvWORD()    --当前局数
            local uiText_title = ccui.Helper:seekWidgetByName(self.root,"Text_title")
            local uiText_des = ccui.Helper:seekWidgetByName(self.root,"Text_des")
            local roomId = GameCommon.tableConfig.wTbaleID or 0
            local randCeil = GameCommon.tableConfig.wCurrentNumber or 0
            local randFloor = GameCommon.tableConfig.wTableNumber or 0
            uiText_title:setString(StaticData.Games[GameCommon.tableConfig.wKindID].name)
            uiText_des:setString(string.format("房间号:%d 局数:%d/%d",roomId,randCeil,randFloor))
            return true
            
        elseif subCmdID == NetMsgId.SUB_GR_DISMISS_TABLE_SUCCESS then
            if GameCommon.gameState ~= GameCommon.GameState_Init then
                require("common.MsgBoxLayer"):create(0,nil,"房间解散成功！") 
                self:runAction(cc.Sequence:create(cc.DelayTime:create(0),cc.CallFunc:create(function(sender,event) EventMgr:dispatch(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK) end)))
            else
                require("common.MsgBoxLayer"):create(2,nil,"房间解散成功！",function(sender,event) 
                    require("common.SceneMgr"):switchScene(require("app.MyApp"):create():createView("HallLayer"),SCENE_HALL) 
                end)   
            end
            return true
            
        elseif subCmdID == NetMsgId.SUB_GR_DISMISS_TABLE_STATE then
            local data = {}
            data.dwDisbandedTime = luaFunc:readRecvDWORD()
            data.wAdvocateDisbandedID = luaFunc:readRecvWORD()
            data.cbDisbandeState = {}
            for i = 1, 8 do
                data.cbDisbandeState[i] = luaFunc:readRecvByte()
            end
            data.dwUserIDALL = {}
            for i = 1, 8 do
                data.dwUserIDALL[i] = luaFunc:readRecvDWORD()
            end
            data.szNickNameALL = {}
            for i = 1, 8 do
                data.szNickNameALL[i] = luaFunc:readRecvString(32)
            end
            require("common.DissolutionLayer"):create(GameCommon:getRoleChairID(),GameCommon.player,data)
            return true
            
        elseif subCmdID == NetMsgId.SUB_GR_USER_COME then 
            --用户进入
            local data = {}
            data.dwUserID = luaFunc:readRecvDWORD()
            data.wChairID = luaFunc:readRecvWORD()
            data.szNickName = luaFunc:readRecvString(32)
            data.szPto = luaFunc:readRecvString(256)
            data.cbSex = luaFunc:readRecvByte()
            data.lScore = luaFunc:readRecvLong() 
            data.dwPlayAddr = luaFunc:readRecvDWORD() 
            data.cbOnline = luaFunc:readRecvByte() 
            data.bReady = luaFunc:readRecvBool() 
            data.location = {}
            data.location.x = luaFunc:readRecvDouble()
            data.location.y = luaFunc:readRecvDouble()
            data.other = nil
            data.bUserCardCount = 0
            data.cbCardData = nil
            data.bUserWarn = false
            printInfo(data)
            GameCommon.player[data.wChairID] = data
            if data.dwUserID == GameCommon.dwUserID or GameCommon.meChairID == nil then
                GameCommon.meChairID = data.wChairID
            end
            self:updatePlayerInfo()
            self:updatePlayerOnline()
            self:updatePlayerReady()
			self:updatePlayerPosition()
            return true

        elseif subCmdID == NetMsgId.SUB_GR_PLAYER_INFO then 
            --查看玩家信息
            _tagMsg.pBuffer.dwUserID = luaFunc:readRecvDWORD()
            _tagMsg.pBuffer.lWinCount = luaFunc:readRecvLong()  
            _tagMsg.pBuffer.lLostCount = luaFunc:readRecvLong()  
            _tagMsg.pBuffer.dwPlayTimeCount = luaFunc:readRecvDWORD()  
            _tagMsg.pBuffer.dwPlayAddr = luaFunc:readRecvDWORD() 
            _tagMsg.pBuffer.dwShamUserID = luaFunc:readRecvDWORD()
            self.tableLayer:showPlayerInfo(_tagMsg.pBuffer)
            return true
            
        elseif subCmdID == NetMsgId.SUB_GR_SEND_CHAT then
            --用户语言文字聊天
            _tagMsg.pBuffer.dwUserID = luaFunc:readRecvDWORD()
            _tagMsg.pBuffer.dwSoundID = luaFunc:readRecvWORD()
            _tagMsg.pBuffer.cbSex = luaFunc:readRecvByte()
            _tagMsg.pBuffer.szNickName = luaFunc:readRecvString(32)
            _tagMsg.pBuffer.dwChatLength = luaFunc:readRecvDWORD()
            _tagMsg.pBuffer.szChatContent = luaFunc:readRecvString(_tagMsg.pBuffer.dwChatLength)
            self.tableLayer:showChat(_tagMsg.pBuffer)
            return
            
        else
            print("not found this subCmdID : %d",subCmdID)
            return false
        end
        
    elseif mainCmdID == NetMsgId.MDM_GF_GAME then
        if subCmdID == NetMsgId.RET_SC_GAME_CONFIG then
            GameCommon.gameConfig = require("common.GameConfig"):getParameter(GameCommon.tableConfig.wKindID,luaFunc)
            local uiText_desc = ccui.Helper:seekWidgetByName(self.root,"Text_desc")
            uiText_desc:setString(GameDesc:getGameDesc(GameCommon.tableConfig.wKindID,GameCommon.gameConfig,GameCommon.tableConfig))
            return true
            
        elseif subCmdID == NetMsgId.SUB_S_GAME_START_PDK then
            _tagMsg.pBuffer.wCurrentUser = luaFunc:readRecvWORD()
            _tagMsg.pBuffer.cbCardData = {}
            for i = 1 , GameCommon.MAX_COUNT do
                _tagMsg.pBuffer.cbCardData[i] = luaFunc:readRecvByte()
            end
            _tagMsg.pBuffer.bStartCard = luaFunc:readRecvByte()
            _tagMsg.pBuffer.wChairID = luaFunc:readRecvWORD()
            
        elseif subCmdID == NetMsgId.REC_SUB_S_SHOW_CARD_PDK then
            _tagMsg.pBuffer.wCurrentUser = luaFunc:readRecvWORD()
            _tagMsg.pBuffer.cbCardData = {}
            for i = 1 , GameCommon.MAX_COUNT do
                _tagMsg.pBuffer.cbCardData[i] = luaFunc:readRecvByte()
            end
            _tagMsg.pBuffer.bStartCard = luaFunc:readRecvByte()
            _tagMsg.pBuffer.wChairID = luaFunc:readRecvWORD()

        elseif subCmdID == NetMsgId.SUB_S_USER_PASS_CARD_PDK then
            _tagMsg.pBuffer.bNewTurn = luaFunc:readRecvBool()
            _tagMsg.pBuffer.wPassUser = luaFunc:readRecvWORD()
            _tagMsg.pBuffer.wCurrentUser = luaFunc:readRecvWORD()

        elseif subCmdID == NetMsgId.SUB_S_WARN_INFO_PDK then
            _tagMsg.pBuffer.wWarnUser = luaFunc:readRecvWORD()
            _tagMsg.pBuffer.bWarn = luaFunc:readRecvByte()

        elseif subCmdID == NetMsgId.SUB_S_OUT_CARD_PDK then
            _tagMsg.pBuffer.bUserCardCount = luaFunc:readRecvByte()
            _tagMsg.pBuffer.wCurrentUser = luaFunc:readRecvWORD()
            _tagMsg.pBuffer.wOutCardUser = luaFunc:readRecvWORD()
            _tagMsg.pBuffer.bCardData = {}
            for i = 1 , GameCommon.MAX_COUNT do
                _tagMsg.pBuffer.bCardData[i] = luaFunc:readRecvByte()
            end
            

        elseif subCmdID == NetMsgId.SUB_S_GAME_END_PDK then
            _tagMsg.pBuffer.wWinUser = luaFunc:readRecvWORD()
            _tagMsg.pBuffer.lUserScore = {}
            for i=1,3 do
                _tagMsg.pBuffer.lUserScore[i] = luaFunc:readRecvLong()
            end
            _tagMsg.pBuffer.lGameScore = {}
            for i=1,3 do
                _tagMsg.pBuffer.lGameScore[i] = luaFunc:readRecvLong()
            end
            _tagMsg.pBuffer.bUserCardCount = {}
            for i=1,3 do
                _tagMsg.pBuffer.bUserCardCount[i] = luaFunc:readRecvByte()
            end
            _tagMsg.pBuffer.cbCardData = {}
            for i=1,3 do
                _tagMsg.pBuffer.cbCardData[i] = {}
                for j=1,GameCommon.MAX_COUNT do
                    _tagMsg.pBuffer.cbCardData[i][j] = luaFunc:readRecvByte()
                end
            end
            _tagMsg.pBuffer.cbBombCount = {}
            for i=1,3 do
                _tagMsg.pBuffer.cbBombCount[i] = luaFunc:readRecvByte()
            end
            _tagMsg.pBuffer.wChariIDred10 = luaFunc:readRecvWORD()
            _tagMsg.pBuffer.wChariIDAbandon = luaFunc:readRecvWORD()

            _tagMsg.pBuffer.cbFalseSpring = {}   -- 假春天参数
            for i=1,3 do
                _tagMsg.pBuffer.cbFalseSpring[i] = luaFunc:readRecvBool()
            end

            
        elseif subCmdID == NetMsgId.SUB_S_RESEDCARD_PDK then
            _tagMsg.pBuffer.bTurnUser = luaFunc:readRecvWORD()
            _tagMsg.pBuffer.bTurnCount = luaFunc:readRecvByte()
            _tagMsg.pBuffer.bTurnData = {}
            for i=1,GameCommon.MAX_COUNT do
                _tagMsg.pBuffer.bTurnData[i] = luaFunc:readRecvByte()
            end
            _tagMsg.pBuffer.bUserCardCount = luaFunc:readRecvByte()
            _tagMsg.pBuffer.bCardData = {}
            for i=1,GameCommon.MAX_COUNT do
                _tagMsg.pBuffer.bCardData[i] = luaFunc:readRecvByte()
            end
            
        elseif subCmdID == NetMsgId.SUB_S_SITFAILED then
            _tagMsg.pBuffer.wErrorCode = luaFunc:readRecvWORD()
            _tagMsg.pBuffer.lScore = luaFunc:readRecvLong()
            require("common.MsgBoxLayer"):create(2,nil , "您的金币不符" , function(sender,event) 
                require("common.SceneMgr"):switchScene(require("app.MyApp"):create():createView("HallLayer"),SCENE_HALL) 
            end)
            return true
            
        elseif subCmdID == NetMsgId.SUB_GF_USER_EXPRESSION then
            _tagMsg.pBuffer.wIndex = luaFunc:readRecvWORD()     --索引
            _tagMsg.pBuffer.wChairID = luaFunc:readRecvWORD()   --椅子号
            self.tableLayer:showExperssion(_tagMsg.pBuffer)
            return true
        elseif subCmdID == NetMsgId.SUB_GF_USER_EFFECTS then
            local wIndex = luaFunc:readRecvWORD()     --索引
            local wChairID = luaFunc:readRecvWORD()   --椅子号
            local wTargetD = luaFunc:readRecvWORD()   --目标
            self.tableLayer:playSkelStartToEndPos(wChairID,wTargetD,wIndex)        
        elseif subCmdID == NetMsgId.SUB_GF_USER_VOICE then
            _tagMsg.pBuffer.wChairID = luaFunc:readRecvWORD()               --座位号
            _tagMsg.pBuffer.wPackCount = luaFunc:readRecvWORD()             --包总数
            _tagMsg.pBuffer.wPackIndex = luaFunc:readRecvWORD()            --当前包索引
            _tagMsg.pBuffer.dwTime = luaFunc:readRecvDWORD()                --播放时长
            _tagMsg.pBuffer.dwFileSize = luaFunc:readRecvDWORD()            --文件总长度
            _tagMsg.pBuffer.dwPeriodSize = luaFunc:readRecvDWORD()          --文件一段长度
            _tagMsg.pBuffer.szFileName = luaFunc:readRecvString(32)         --文件名字
            _tagMsg.pBuffer.szPeriodData = luaFunc:readRecvBuffer(_tagMsg.pBuffer.dwPeriodSize) --文件数据
            self.tableLayer:OnUserChatVoice(_tagMsg.pBuffer)      
            return true
            
        else
            print("not found this subCmdID : %d",subCmdID)
            return false
        end
        
    elseif mainCmdID == NetMsgId.MDM_GF_FRAME then
        if subCmdID == NetMsgId.SUB_GF_SCENE then   
            _tagMsg.pBuffer.lBaseScore = luaFunc:readRecvLong()
            _tagMsg.pBuffer.wLastOutUser = luaFunc:readRecvWORD()
            _tagMsg.pBuffer.wCurrentUser = luaFunc:readRecvWORD()
            _tagMsg.pBuffer.bCardData = {}
            for i=1,GameCommon.MAX_COUNT do
                _tagMsg.pBuffer.bCardData[i] = luaFunc:readRecvByte()
            end
            _tagMsg.pBuffer.bUserCardCount = {}
            for i=1,3 do
                _tagMsg.pBuffer.bUserCardCount[i] = luaFunc:readRecvByte()
            end
            _tagMsg.pBuffer.bTurnCardCount = luaFunc:readRecvByte()
            _tagMsg.pBuffer.bTurnCardData = {}
            for i=1,GameCommon.MAX_COUNT do
                _tagMsg.pBuffer.bTurnCardData[i] = luaFunc:readRecvByte()
            end
            _tagMsg.pBuffer.bUserTrustee = {}
            for i=1,3 do
                _tagMsg.pBuffer.bUserTrustee[i] = luaFunc:readRecvBool()
            end
            _tagMsg.pBuffer.bUserWarn = {}
            for i=1,3 do
                _tagMsg.pBuffer.bUserWarn[i] = luaFunc:readRecvBool()
            end
            _tagMsg.pBuffer.lOutCardleftTime = luaFunc:readRecvLong()

            if GameCommon.isFriendsGame then
                _tagMsg.pBuffer.lUserScore = {}
                for i=1,3 do
                    _tagMsg.pBuffer.lUserScore[i] = luaFunc:readRecvLong()
                end
            end
			
        else
            print("not found this subCmdID : %d",subCmdID)
            return false
        end
    else
        
        return false
    end
    if self.userMsgArray == nil then 
        return false
    end
    table.insert(self.userMsgArray,#self.userMsgArray + 1,_tagMsg)
    
    print("当前消息数量:%d",#self.userMsgArray)
    printInfo(_tagMsg)
    return true
end

function GameLayer:EVENT_TYPE_CACEL_MESSAGE_BLOCK(event)
    self.isRunningActions = false
end

--消息队列
function GameLayer:update(delta)
    if self.isRunningActions then
        return
    end
    if self.userMsgArray == nil then
        return
    end
    if #self.userMsgArray <=0 then
        return
    end
    local _tagMsg = self.userMsgArray[1]
    self:OnGameMessageRun(_tagMsg)
    --删除动作
    table.remove(self.userMsgArray,1)
end

--消息执行
function GameLayer:OnGameMessageRun(_tagMsg)
    local mainCmdID = _tagMsg.mainCmdID
    local subCmdID = _tagMsg.subCmdID
    local pBuffer = _tagMsg.pBuffer
    
    if mainCmdID == NetMsgId.MDM_GR_USER then   
        if subCmdID == NetMsgId.SUB_GR_USER_STATISTICS then
            self:removeAllChildren()
            local path = self:requireClass('PDKGameRoomEnd')
            local box = require("app.MyApp"):create(pBuffer):createGame(path)
            self:addChild(box)
        else
            return print("error, not found this :",mainCmdID, subCmdID)
        end
        
    elseif mainCmdID == NetMsgId.MDM_GF_GAME then
        if subCmdID == NetMsgId.SUB_S_GAME_START_PDK then
            --开始游戏
            self.tableLayer:updateGameState(GameCommon.GameState_Start)
            local wChairID = pBuffer.wChairID
            for i = 0, 3 do
                if GameCommon.player[i] ~= nil then
                    GameCommon.player[i].bUserCardCount = GameCommon.MAX_COUNT
                end
            end
            GameCommon.wBankerUser = pBuffer.wCurrentUser
            self.tableLayer:setHandCard(wChairID,GameCommon.player[wChairID].bUserCardCount, pBuffer.cbCardData)
            
            local viewID = GameCommon:getViewIDByChairID(pBuffer.wCurrentUser)
            self.tableLayer:showHandCard(wChairID,1)         
            self:updateBankerUser()
            self:updatePlayerInfo()
            self:updatehandplate()
            self.tableLayer:doAction(NetMsgId.SUB_S_GAME_START_PDK,pBuffer)
            
        elseif subCmdID == NetMsgId.REC_SUB_S_SHOW_CARD_PDK then
            local wChairID = pBuffer.wChairID
            GameCommon.player[wChairID].bUserCardCount = GameCommon.MAX_COUNT
            self.tableLayer:setHandCard(wChairID,GameCommon.player[wChairID].bUserCardCount, pBuffer.cbCardData)
            self.tableLayer:showHandCard(wChairID,1)     
            self:runAction(cc.Sequence:create(cc.DelayTime:create(0),cc.CallFunc:create(function(sender,event) EventMgr:dispatch(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK) end)))
            
        elseif subCmdID == NetMsgId.SUB_S_USER_PASS_CARD_PDK then
            self.tableLayer:doAction(NetMsgId.SUB_S_USER_PASS_CARD_PDK,pBuffer)
                        
        elseif subCmdID == NetMsgId.SUB_S_WARN_INFO_PDK then
            self.tableLayer:doAction(NetMsgId.SUB_S_WARN_INFO_PDK,pBuffer)
            
        elseif subCmdID == NetMsgId.SUB_S_OUT_CARD_PDK then
            self.tableLayer:doAction(NetMsgId.SUB_S_OUT_CARD_PDK,pBuffer)
--            local viewID = GameCommon:getViewIDByChairID(pBuffer.wCurrentUser)
--            if viewID == 3 then 
--                local wChairID = GameCommon:getRoleChairID()
--                self.tableLayer:showHandCard(wChairID,0)
--            end 
            self:updatehandplate()

        elseif subCmdID == NetMsgId.SUB_S_GAME_END_PDK then             
            for i = 0 , GameCommon.gameConfig.bPlayerCount do
                if GameCommon.player[i] ~= nil then
                    GameCommon.player[i].lScore = GameCommon.player[i].lScore + pBuffer.lGameScore[i+1]
                    if GameCommon.tableConfig.nTableType == TableType_GoldRoom then
                        GameCommon.player[i].lScore = GameCommon.player[i].lScore - GameCommon.tableConfig.wCellScore/2
                        if GameCommon.player[i].lScore < 0 then
                            GameCommon.player[i].lScore = 0
                        end
                    end
                end
            end
            self:updatePlayerlScore()
            self.tableLayer:updateGameState(GameCommon.GameState_Over)
            self.tableLayer:doAction(NetMsgId.SUB_S_GAME_END_PDK, {wWinUser = pBuffer.wWinUser,bUserCardCount = pBuffer.bUserCardCount})
            for i = 1, GameCommon.gameConfig.bPlayerCount do
                self.tableLayer:setHandCard(i-1,pBuffer.bUserCardCount[i], pBuffer.cbCardData[i])
                self.tableLayer:showHandCard(i-1,1,true)
            end
            local uiPanel_end = ccui.Helper:seekWidgetByName(self.root,"Panel_end")
            local ListView_top = ccui.Helper:seekWidgetByName(self.root,"ListView_top")
            uiPanel_end:setVisible(true)
            uiPanel_end:removeAllChildren()
            uiPanel_end:stopAllActions()
            uiPanel_end:runAction(cc.Sequence:create(
                cc.DelayTime:create(1),
                cc.CallFunc:create(function(sender,event) 
                    if GameCommon.tableConfig.nTableType == TableType_SportsRoom then
                        pBuffer.wKindID =GameCommon.tableConfig.wKindID
                        uiPanel_end:addChild(require("common.SportsGameEndLayer"):create(pBuffer))  
                    else
                        ListView_top:setVisible(false)
                        uiPanel_end:addChild(require("game.puke.26.GameEndLayer"):create(pBuffer))
                    end 
                end),
                cc.DelayTime:create(20),
                cc.CallFunc:create(function(sender,event) 
                    if GameCommon.tableConfig.nTableType > TableType_GoldRoom then
                        if GameCommon.tableConfig.wTableNumber == GameCommon.tableConfig.wCurrentNumber then
                            EventMgr:dispatch(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK)
--                        else
--                            GameCommon:ContinueGame(GameCommon.tableConfig.cbLevel)
                        end
                    else
                        require("common.SceneMgr"):switchScene(require("app.MyApp"):create():createView("HallLayer"),SCENE_HALL) 
                    end
            end)))
                        
        elseif subCmdID == NetMsgId.SUB_S_RESEDCARD_PDK then
            local wChairID = GameCommon:getRoleChairID()
            GameCommon.player[wChairID].bUserCardCount = pBuffer.bUserCardCount
            self.tableLayer:setHandCard(wChairID,GameCommon.player[wChairID].bUserCardCount,pBuffer.bCardData)
            self.tableLayer:showHandCard(wChairID,0)
            
            if pBuffer.bTurnCount > 0 then
                local data = {
                    bUserCardCount = pBuffer.bTurnCount,
                    bCardData = pBuffer.bTurnData,
                    wCurrentUser = wChairID,
                    wOutCardUser = pBuffer.bTurnUser,
                    notDeleteCard = true,
                }
                self.tableLayer:doAction(NetMsgId.SUB_S_OUT_CARD_PDK,data)
            else 
                self:runAction(cc.Sequence:create(cc.DelayTime:create(0),cc.CallFunc:create(function(sender,event) EventMgr:dispatch(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK) end)))
            end   
        else 
            return print("error, not found this :",mainCmdID, subCmdID)
        end

    elseif mainCmdID == NetMsgId.MDM_GF_FRAME then
        if subCmdID == NetMsgId.SUB_GF_SCENE then
            --游戏重连
            self.tableLayer:updateGameState(GameCommon.GameState_Start)
            local wChairID = GameCommon:getRoleChairID()
            GameCommon.wBankerUser = pBuffer.wCurrentUser
            for i = 1, GameCommon.gameConfig.bPlayerCount do
                GameCommon.player[i-1].bUserWarn = pBuffer.bUserWarn[i]
                GameCommon.player[i-1].bUserCardCount = pBuffer.bUserCardCount[i]
            end
            self:updatehandplate()
            self.tableLayer:setHandCard(wChairID,GameCommon.player[wChairID].bUserCardCount,pBuffer.bCardData)
            self.tableLayer:showHandCard(wChairID,0)
            self:updateBankerUser()
            self:updatePlayerInfo()
            for i = 1, 3 do
                if pBuffer.bUserWarn[i] == true then
                    GameCommon:playAnimation(self.root,"报警",i-1)
                end
            end
            if pBuffer.bTurnCardCount > 0 then
                local data = {
                    bUserCardCount = pBuffer.bTurnCardCount,
                    bCardData = pBuffer.bTurnCardData,
                    wCurrentUser = pBuffer.wCurrentUser,
                    wOutCardUser = pBuffer.wLastOutUser,
                    notDeleteCard = true,
                }
                self.tableLayer:doAction(NetMsgId.SUB_S_OUT_CARD_PDK,data)
            else
                self.tableLayer:showCountDown(pBuffer.wCurrentUser)        
                self:runAction(cc.Sequence:create(cc.DelayTime:create(0),cc.CallFunc:create(function(sender,event) EventMgr:dispatch(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK) end)))
            end
             
        else
            return print("error, not found this :",mainCmdID, subCmdID)
        end
    else
        return print("error, not found this :",mainCmdID, subCmdID)
    end
    self.isRunningActions = true
    
end

function GameLayer:SUB_GR_USER_ENTER(event)
    local data = event._usedata
    self:startGame(UserData.User.userID, data)
    if self.tableLayer then
        self.tableLayer:setUserHeadCliping(data.node, data.img)
    end
end

--更新玩家信息
function GameLayer:updatePlayerInfo()
    if GameCommon.gameConfig == nil then
        return
    end
    local uiPanel_player = ccui.Helper:seekWidgetByName(self.root,"Panel_player")
    uiPanel_player:setVisible(true)
    for i = 1 , GameCommon.gameConfig.bPlayerCount do
        local wChairID = i - 1
        local viewID = GameCommon:getViewIDByChairID(wChairID)
        local uiPanel_player = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_player%d",viewID))
        uiPanel_player:setVisible(true)
        
        if GameCommon.player == nil or GameCommon.player[wChairID] == nil then
            local uiPanel_playerInfo = ccui.Helper:seekWidgetByName(uiPanel_player,"Panel_playerInfo")
            uiPanel_playerInfo:setVisible(false)
            local uiImage_avatar = ccui.Helper:seekWidgetByName(uiPanel_player,"Image_avatar")
           uiImage_avatar:loadTexture("common/hall_avatar.png")
            -- Common:setUserHeadCliping(uiImage_avatar)
        else
            print(wChairID, viewID,GameCommon.player[wChairID].szNickName)
            local uiPanel_playerInfo = ccui.Helper:seekWidgetByName(uiPanel_player,"Panel_playerInfo")
            uiPanel_playerInfo:setVisible(true)
            local uiImage_avatar = ccui.Helper:seekWidgetByName(uiPanel_player,"Image_avatar")
            Common:requestUserAvatar(GameCommon.player[wChairID].dwUserID,GameCommon.player[wChairID].szPto,uiImage_avatar,"img")
            local uiText_name = ccui.Helper:seekWidgetByName(uiPanel_player,"Text_name")
            uiText_name:setString(GameCommon.player[wChairID].szNickName)
            local Text_score = ccui.Helper:seekWidgetByName(uiPanel_player,"Text_score") 
            --个人添加
            local uiText_score = ccui.Helper:seekWidgetByName(uiPanel_player,"Text_score")
            local dwGold = Common:itemNumberToString(GameCommon.player[wChairID].lScore)
            uiText_score:setString(tostring(dwGold))             
        end
    end
    self.tableLayer:refreshTableInfo()
end

function GameLayer:updatePlayerlScore()
    if GameCommon.gameConfig == nil then
        return
    end
    for i = 1 , GameCommon.gameConfig.bPlayerCount do
        local wChairID = i-1
        local viewID = GameCommon:getViewIDByChairID(wChairID)
        local uiPanel_player = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_player%d",viewID))
        local uiText_score = ccui.Helper:seekWidgetByName(uiPanel_player,"Text_score")
        local dwGold = Common:itemNumberToString(GameCommon.player[wChairID].lScore)
        uiText_score:setString(tostring(dwGold))   
    end
end

function GameLayer:updateBankerUser()
    for i = 1 , GameCommon.gameConfig.bPlayerCount do
        local wChairID = i-1
        local viewID = GameCommon:getViewIDByChairID(wChairID)
        local uiPanel_player = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_player%d",viewID))
        local uiImage_banker = ccui.Helper:seekWidgetByName(uiPanel_player,"Image_banker")
--        if GameCommon.player[wChairID] ~= nil and GameCommon.player[wChairID].wChairID == GameCommon.wBankerUser then
--            uiImage_banker:setVisible(true)
--        else
            uiImage_banker:setVisible(false)
--        end 
    end
end

function GameLayer:updatePlayerReady()
    if GameCommon.gameConfig == nil then
        return
    end
    local uiPanel_player = ccui.Helper:seekWidgetByName(self.root,"Panel_player")
    for i = 1 , GameCommon.gameConfig.bPlayerCount do
        local wChairID = i-1
        if GameCommon.player ~= nil and GameCommon.player[wChairID] ~= nil then
            local viewID = GameCommon:getViewIDByChairID(wChairID)
            local uiPanel_player = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_player%d",viewID))
            local uiImage_ready = ccui.Helper:seekWidgetByName(uiPanel_player,"Image_ready")
            if GameCommon.player[wChairID].bReady == true then
            uiImage_ready:setVisible(true)
            else
                uiImage_ready:setVisible(false)
            end
                if  GameCommon.player[wChairID].dwUserID == GameCommon.dwUserID and GameCommon.player[wChairID].bReady == true or GameCommon.gameState == GameCommon.GameState_Start  then
            local uiButton_ready = ccui.Helper:seekWidgetByName(self.root,"Button_ready")
            uiButton_ready:setVisible(false)
                end            
        end     
    end
    --距离报警 
    if GameCommon.tableConfig.wCurrentNumber ~= nil and GameCommon.tableConfig.wCurrentNumber == 0 then
        GameCommon.DistanceAlarm = 0
    end
end

function GameLayer:updatePlayerOnline()
    if GameCommon.gameConfig == nil then
        return
    end
    local uiPanel_player = ccui.Helper:seekWidgetByName(self.root,"Panel_player")
    for i = 1 , GameCommon.gameConfig.bPlayerCount do
        local wChairID = i-1
        if GameCommon.player ~= nil and GameCommon.player[wChairID] ~= nil then
            local viewID = GameCommon:getViewIDByChairID(wChairID)
            local uiPanel_player = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_player%d",viewID))
            local uiImage_offline = ccui.Helper:seekWidgetByName(uiPanel_player,"Image_offline")
            local uiImage_avatar = ccui.Helper:seekWidgetByName(uiPanel_player,"Image_avatar")
            if GameCommon.player[wChairID].cbOnline == 0x06 then
                uiImage_offline:setVisible(true)
                uiImage_avatar:setColor(cc.c3b(170,170,170))
            else
                uiImage_offline:setVisible(false)
                uiImage_avatar:setColor(cc.c3b(255,255,255))
            end
        end     
    end
end

function GameLayer:updatehandplate()
    if  GameCommon.gameConfig == nil then
        return
    end
    if GameCommon.gameConfig.bShowCardCount == 0 then
        return
    end
    for i = 1 , GameCommon.gameConfig.bPlayerCount do
        local wChairID = i-1
        local viewID = GameCommon:getViewIDByChairID(wChairID)
        local uiPanel_player = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_player%d",viewID))
        local uiImage_paishu = ccui.Helper:seekWidgetByName(uiPanel_player,"Image_paishu")
        uiImage_paishu:setVisible(true)   
        local uiText_Houdplate = ccui.Helper:seekWidgetByName(uiPanel_player,"Text_Houdplate")
        if uiText_Houdplate == nil then
            return
        end
        if GameCommon.player[wChairID].bUserCardCount <= 3 then
            uiText_Houdplate:setTextColor(cc.c3b(255,40,40))              
        else
            uiText_Houdplate:setTextColor(cc.c3b(255,223,113))   
        end
        uiText_Houdplate:setString(string.format("%d",GameCommon.player[wChairID].bUserCardCount))
    end
end

function GameLayer:updatePlayerPosition()
    if GameCommon.tableConfig.nTableType > TableType_GoldRoom and GameCommon.tableConfig.wCurrentNumber == 0  then
        self.tableLayer:showPlayerPosition(GameCommon.tableConfig.wKindID)
    end
end

function GameLayer:requireClass(name)
	local path = string.format("game.%s.%s", APPNAME, name)
	return path
end

return GameLayer


