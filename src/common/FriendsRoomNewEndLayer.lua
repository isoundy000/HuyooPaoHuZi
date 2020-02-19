local StaticData = require("app.static.StaticData")
local EventType = require("common.EventType")
local EventMgr = require("common.EventMgr")
local UserData = require("app.user.UserData")
local Common = require("common.Common")
local NetMsgId = require("common.NetMsgId")
local NetMgr = require("common.NetMgr")
local Base64 = require("common.Base64")
local endDes = {
	[0] = '',
	[1] = '提示：该房间被房主解散',
	[2] = '提示：该房间被管理员解散',
	[3] = '提示：该房间投票解散',
	[4] = '提示：该房间因疲劳值不足被强制解散',
	[5] = '提示：该房间被官方系统强制解散',
	[6] = '提示：该房间因超时未开局被强制解散',
    [7] = '提示：该房间因超时投票解散',
    [8] = '提示：该房间因托管超时解散',
}
local FriendsRoomNewEndLayer = class("FriendsRoomNewEndLayer",function()
    return ccui.Layout:create()
end)

function FriendsRoomNewEndLayer:create(pBuffer)
    local view = FriendsRoomNewEndLayer.new()
    view:onCreate(pBuffer)
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

function FriendsRoomNewEndLayer:onEnter()
    EventMgr:registListener(EventType.REQ_GR_USER_CONTINUE_CLUB_FAILD,self,self.REQ_GR_USER_CONTINUE_CLUB_FAILD) 
    EventMgr:registListener(EventType.RET_CLUB_CHAT_BACK_RECORD, self, self.RET_CLUB_CHAT_BACK_RECORD)
    EventMgr:registListener(EventType.RET_MATCH_CLUB_TABLE, self, self.RET_MATCH_CLUB_TABLE)
    EventMgr:registListener(EventType.SUB_GR_CREATE_TABLE_FAILED,self,self.SUB_GR_CREATE_TABLE_FAILED)
    EventMgr:registListener(EventType.SUB_GR_JOIN_TABLE_FAILED,self,self.SUB_GR_JOIN_TABLE_FAILED)

    --保存游戏截屏
    local uiListView_function = ccui.Helper:seekWidgetByName(self.root,"ListView_function")
    uiListView_function:setVisible(false)
    local uiButton_return = ccui.Helper:seekWidgetByName(self.root,"Button_return")
    local uiButton_share = ccui.Helper:seekWidgetByName(self.root,"Button_share")
    if StaticData.Hide[CHANNEL_ID].btn5 ~= 1 then
        uiListView_function:removeItem(uiListView_function:getIndex(uiButton_share))
    end
    uiListView_function:refreshView()
    uiListView_function:setContentSize(cc.size(uiListView_function:getInnerContainerSize().width,uiListView_function:getInnerContainerSize().height))
    uiListView_function:setPositionX(uiListView_function:getParent():getContentSize().width/2)

    self:runAction(cc.Sequence:create(cc.DelayTime:create(0),cc.CallFunc:create(function(sender,event) 
        require("common.Common"):screenshot(FileName.battlefieldScreenshot) 
    end),cc.DelayTime:create(0),cc.CallFunc:create(function() 
        uiListView_function:setVisible(true)
    end)))
end

function FriendsRoomNewEndLayer:onExit()
    EventMgr:unregistListener(EventType.REQ_GR_USER_CONTINUE_CLUB_FAILD,self,self.REQ_GR_USER_CONTINUE_CLUB_FAILD) 
    EventMgr:unregistListener(EventType.RET_CLUB_CHAT_BACK_RECORD, self, self.RET_CLUB_CHAT_BACK_RECORD)
    EventMgr:unregistListener(EventType.RET_MATCH_CLUB_TABLE, self, self.RET_MATCH_CLUB_TABLE)
    EventMgr:unregistListener(EventType.SUB_GR_CREATE_TABLE_FAILED,self,self.SUB_GR_CREATE_TABLE_FAILED)
    EventMgr:unregistListener(EventType.SUB_GR_JOIN_TABLE_FAILED,self,self.SUB_GR_JOIN_TABLE_FAILED)
end

function FriendsRoomNewEndLayer:onCreate(pBuffer)
    self.tableConfig = pBuffer.tableConfig
    self.gameConfig = pBuffer.gameConfig
    self:setInviteUserID(pBuffer)
    cc.Director:getInstance():getRunningScene():removeChildByTag(LAYER_TIPS)

    self.ShareName = string.format("%d.jpg",os.time())
    self.root = nil
    local visibleSize = cc.Director:getInstance():getVisibleSize()
    local csb = cc.CSLoader:createNode("FriendsRoomNewEndLayer.csb")
    self:addChild(csb)
    self.root = csb:getChildByName("Panel_root")

    local tishi_des = ccui.Helper:seekWidgetByName(self.root,"tishi_des")
    tishi_des:setString(endDes[pBuffer.cbOrigin])

    local uiButton_return = ccui.Helper:seekWidgetByName(self.root,"Button_return")
    uiButton_return:setPressedActionEnabled(true)
    local function onEventReturn(sender,event)
        if event == ccui.TouchEventType.ended then
            Common:palyButton()
            require("common.SceneMgr"):switchScene(require("app.MyApp"):create():createView("HallLayer"),SCENE_HALL) 
        end
    end
    uiButton_return:addTouchEventListener(onEventReturn)

    local uiButton_share = ccui.Helper:seekWidgetByName(self.root,"Button_share")
    uiButton_share:setPressedActionEnabled(true)
    local function onEventShare(sender,event)
        if event == ccui.TouchEventType.ended then
            Common:palyButton()
            local data = clone(UserData.Share.tableShareParameter[4])
            data.dwClubID = pBuffer.tableConfig.dwClubID
            data.szShareTitle = string.format("战绩分享-房间号:%d,局数:%d/%d",pBuffer.tableConfig.wTbaleID, pBuffer.tableConfig.wCurrentNumber, pBuffer.tableConfig.wTableNumber)
            data.szShareContent = ""
            local maxScore = 0
            for i = 1, 8 do
                if pBuffer.tScoreInfo[i].dwUserID ~= nil and pBuffer.tScoreInfo[i].dwUserID ~= 0 and pBuffer.tScoreInfo[i].totalScore > maxScore then 
                    maxScore = pBuffer.tScoreInfo[i].totalScore
                end
            end
            for i = 1, 8 do
                if pBuffer.tScoreInfo[i].dwUserID ~= nil and pBuffer.tScoreInfo[i].dwUserID ~= 0 then
                    if data.szShareContent ~= "" then
                        data.szShareContent = data.szShareContent.."\n"
                    end
                    if maxScore ~= 0 and pBuffer.tScoreInfo[i].totalScore >= maxScore then
                        data.szShareContent = data.szShareContent..string.format("【%s:%d(大赢家)】",pBuffer.tScoreInfo[i].player.szNickName,pBuffer.tScoreInfo[i].totalScore)
                    else
                        data.szShareContent = data.szShareContent..string.format("【%s:%d】",pBuffer.tScoreInfo[i].player.szNickName,pBuffer.tScoreInfo[i].totalScore)
                    end
                end
            end
            data.szShareUrl = string.format(data.szShareUrl,pBuffer.szGameID)
            data.szShareImg = FileName.battlefieldScreenshot
            data.szGameID = pBuffer.szGameID
            data.isInClub = self:isInClub(pBuffer);
            require("app.MyApp"):create(data):createView("ShareLayer")
        end
    end
    uiButton_share:addTouchEventListener(onEventShare)

    local uiButton_continue = ccui.Helper:seekWidgetByName(self.root,"Button_continue")
    uiButton_continue:setVisible(true)
    uiButton_continue:setPressedActionEnabled(true)
    local function onEventContinue(sender,event)
        if event == ccui.TouchEventType.ended then
            Common:palyButton()
            UserData.Guild:sendMatchClubTable(UserData.User.userID, self.tableConfig.dwClubID, self.tableConfig.dwPlayID)
        end
    end
    uiButton_continue:addTouchEventListener(onEventContinue)

    if self.tableConfig.nTableType == 0 then
        local uiListView_function = ccui.Helper:seekWidgetByName(self.root,"ListView_function")
        uiListView_function:removeItem(uiListView_function:getIndex(uiButton_continue))
    end
    -- if CHANNEL_ID ~= 8 and CHANNEL_ID ~= 9 then     -- 黑岛渠道大结算继续按钮
    --     if self.tableConfig.dwClubID == 0 or self.tableConfig.cbLevel ~= 0 then
    --         local uiListView_function = ccui.Helper:seekWidgetByName(self.root,"ListView_function")
    --         uiListView_function:removeItem(uiListView_function:getIndex(uiButton_continue))
    --     end
    -- end 

    local uiText_time = ccui.Helper:seekWidgetByName(self.root,"Text_time")
    -- local function onEventRefreshTime(sender,event)
        local date = os.date("*t",os.time())
        uiText_time:setString(string.format("%d-%02d-%02d\n%02d:%02d:%02d",date.year,date.month,date.day,date.hour,date.min,date.sec))
    --     uiText_time:runAction(cc.Sequence:create(cc.DelayTime:create(1),cc.CallFunc:create(onEventRefreshTime)))
    -- end
    --onEventRefreshTime()
    local uiText_homeowner = ccui.Helper:seekWidgetByName(self.root,"Text_homeowner")
    uiText_homeowner:setString(string.format("房主:%s(%d)",pBuffer.szOwnerName,pBuffer.dwTableOwnerID))
    local uiText_roomInfo = ccui.Helper:seekWidgetByName(self.root,"Text_roomInfo")
    uiText_roomInfo:setString(string.format("局数:%d/%d\n房间号:%d",self.tableConfig.wCurrentNumber,self.tableConfig.wTableNumber,self.tableConfig.wTbaleID))
    local uiText_gameInfo = ccui.Helper:seekWidgetByName(self.root,"Text_gameInfo")
    if pBuffer.gameDesc ~= nil and pBuffer.gameDesc ~= "" then
        uiText_gameInfo:setString(string.format("%s",StaticData.Games[self.tableConfig.wKindID].name.." "..pBuffer.gameDesc))
    else
        uiText_gameInfo:setString(string.format("%s",StaticData.Games[self.tableConfig.wKindID].name))
    end

    if self.tableConfig.wKindID == 51 or self.tableConfig.wKindID == 53 or self.tableConfig.wKindID == 56 or self.tableConfig.wKindID == 57 or self.tableConfig.wKindID == 58 or self.tableConfig.wKindID == 59 then
        local uiPanel_player = ccui.Helper:seekWidgetByName(self.root,"Panel_player2")
        uiPanel_player:removeFromParent()
        local uiPanel_player = ccui.Helper:seekWidgetByName(self.root,"Panel_player3")
        uiPanel_player:removeFromParent()
        local uiPanel_player = ccui.Helper:seekWidgetByName(self.root,"Panel_player4")
        uiPanel_player:removeFromParent()
        local uiPanel_player = ccui.Helper:seekWidgetByName(self.root,"Panel_playerBa") 
        uiPanel_player:removeFromParent()
    elseif self.tableConfig.wKindID == 55  then
        local uiPanel_player = ccui.Helper:seekWidgetByName(self.root,"Panel_player2")
        uiPanel_player:removeFromParent()
        local uiPanel_player = ccui.Helper:seekWidgetByName(self.root,"Panel_player3")
        uiPanel_player:removeFromParent()
        local uiPanel_player = ccui.Helper:seekWidgetByName(self.root,"Panel_player4")
        uiPanel_player:removeFromParent()
        local uiPanel_player = ccui.Helper:seekWidgetByName(self.root,"Panel_playerNiu") 
        uiPanel_player:removeFromParent()      
    elseif pBuffer.dwUserCount == 2 then
        local uiPanel_player = ccui.Helper:seekWidgetByName(self.root,"Panel_player3")
        uiPanel_player:removeFromParent()
        local uiPanel_player = ccui.Helper:seekWidgetByName(self.root,"Panel_player4")
        uiPanel_player:removeFromParent()
        local uiPanel_player = ccui.Helper:seekWidgetByName(self.root,"Panel_playerNiu")
        uiPanel_player:removeFromParent()
        local uiPanel_player = ccui.Helper:seekWidgetByName(self.root,"Panel_playerBa")
        uiPanel_player:removeFromParent()
    elseif pBuffer.dwUserCount == 3 then
        local uiPanel_player = ccui.Helper:seekWidgetByName(self.root,"Panel_player2")
        uiPanel_player:removeFromParent()
        local uiPanel_player = ccui.Helper:seekWidgetByName(self.root,"Panel_player4")
        uiPanel_player:removeFromParent()
        local uiPanel_player = ccui.Helper:seekWidgetByName(self.root,"Panel_playerNiu")
        uiPanel_player:removeFromParent()
        local uiPanel_player = ccui.Helper:seekWidgetByName(self.root,"Panel_playerBa")
        uiPanel_player:removeFromParent()
    else
        local uiPanel_player = ccui.Helper:seekWidgetByName(self.root,"Panel_player2")
        uiPanel_player:removeFromParent()
        local uiPanel_player = ccui.Helper:seekWidgetByName(self.root,"Panel_player3")
        uiPanel_player:removeFromParent()
        local uiPanel_player = ccui.Helper:seekWidgetByName(self.root,"Panel_playerNiu")
        uiPanel_player:removeFromParent()
        local uiPanel_player = ccui.Helper:seekWidgetByName(self.root,"Panel_playerBa")
        uiPanel_player:removeFromParent()
    end

    if self.tableConfig.wKindID == 51 or self.tableConfig.wKindID == 53 or self.tableConfig.wKindID == 56 or self.tableConfig.wKindID == 57 or self.tableConfig.wKindID == 58 or self.tableConfig.wKindID == 59 then
        local index = 0
        for i = 1, 6 do
            local tScoreInfo = pBuffer.tScoreInfo[i]
            if tScoreInfo.player then
                index = index + 1
                local item = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_payerInfo%d",index))
                local uiImage_avatar = ccui.Helper:seekWidgetByName(item,"Image_avatar")
                local uiPanel_info = ccui.Helper:seekWidgetByName(item,"Panel_info")
                uiPanel_info:setVisible(true)
                Common:requestUserAvatar(tScoreInfo.dwUserID, tScoreInfo.player.szPto,uiImage_avatar,"img")
                local uiText_palyerName = ccui.Helper:seekWidgetByName(item,"Text_palyerName")
                uiText_palyerName:setString(tScoreInfo.player.szNickName)
                uiText_palyerName:setColor(cc.c3b(0,0,0))
                local uiText_id = ccui.Helper:seekWidgetByName(item,"Text_id")
                uiText_id:setString(string.format("%d",tScoreInfo.dwUserID))
                uiText_id:setColor(cc.c3b(0,0,0))
                local uiImage_host = ccui.Helper:seekWidgetByName(item,"Image_host")
                if tScoreInfo.dwUserID == pBuffer.dwTableOwnerID then
                    uiImage_host:setVisible(true)
                else
                    uiImage_host:setVisible(false)
                end
                if tScoreInfo.dwUserID == pBuffer.bigWinner then
                    local uiPanel_winner = ccui.Helper:seekWidgetByName(item,"Panel_winner")
                    ccs.ArmatureDataManager:getInstance():addArmatureFileInfo("friend_end/dayingjiatubiao.ExportJson")
                    local armature=ccs.Armature:create("dayingjiatubiao")
                    armature:getAnimation():playWithIndex(0)
                    uiPanel_winner:addChild(armature)
                    armature:setPosition(armature:getParent():getContentSize().width/2,armature:getParent():getContentSize().height/2)
                end
                -- local uiAtlasLabel_integral = ccui.Helper:seekWidgetByName(item,"AtlasLabel_integral")
                -- uiAtlasLabel_integral:setVisible(false)

                local uiText_result = ccui.Helper:seekWidgetByName(item,"Text_result")
                if tScoreInfo.totalScore >= 0 then
                    uiText_result:setColor(cc.c3b(175,49,52))
                    uiText_result:setString(string.format("+%d\n(赛:%0.2f)",tScoreInfo.totalScore,pBuffer.tWriteScoreArr[i]/100))
                else
                    uiText_result:setColor(cc.c3b(35,102,69))
                    uiText_result:setString(string.format("%d\n(赛:%0.2f)",tScoreInfo.totalScore,pBuffer.tWriteScoreArr[i]/100))
                end
            end  
        end
    elseif  self.tableConfig.wKindID == 55 then
        local index = 0
        for i = 1, 8 do
            local tScoreInfo = pBuffer.tScoreInfo[i]
            if tScoreInfo.player then
                index = index + 1
                local item = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_payerInfo%d",index))
                local uiImage_avatar = ccui.Helper:seekWidgetByName(item,"Image_avatar")
                local uiPanel_info = ccui.Helper:seekWidgetByName(item,"Panel_info")
                uiPanel_info:setVisible(true)
                Common:requestUserAvatar(tScoreInfo.dwUserID, tScoreInfo.player.szPto,uiImage_avatar,"img")
                local uiText_palyerName = ccui.Helper:seekWidgetByName(item,"Text_palyerName")
                uiText_palyerName:setString(tScoreInfo.player.szNickName)
                uiText_palyerName:setColor(cc.c3b(0,0,0))
                local uiText_id = ccui.Helper:seekWidgetByName(item,"Text_id")
                uiText_id:setString(string.format("%d",tScoreInfo.dwUserID))
                uiText_id:setColor(cc.c3b(0,0,0))
                local uiImage_host = ccui.Helper:seekWidgetByName(item,"Image_host")
                if tScoreInfo.dwUserID == pBuffer.dwTableOwnerID then
                    uiImage_host:setVisible(true)
                else
                    uiImage_host:setVisible(false)
                end
                if tScoreInfo.dwUserID == pBuffer.bigWinner then
                    local uiPanel_winner = ccui.Helper:seekWidgetByName(item,"Panel_winner")
                    ccs.ArmatureDataManager:getInstance():addArmatureFileInfo("friend_end/dayingjiatubiao.ExportJson")
                    local armature=ccs.Armature:create("dayingjiatubiao")
                    armature:getAnimation():playWithIndex(0)
                    uiPanel_winner:addChild(armature)
                    armature:setPosition(armature:getParent():getContentSize().width/2,armature:getParent():getContentSize().height/2)
                end

                local uiText_result = ccui.Helper:seekWidgetByName(item,"Text_result")
                if tScoreInfo.totalScore >= 0 then
                    uiText_result:setColor(cc.c3b(175,49,52))
                    uiText_result:setString(string.format("+%d\n(赛:%0.2f)",tScoreInfo.totalScore,pBuffer.tWriteScoreArr[i]/100))
                else
                    uiText_result:setColor(cc.c3b(35,102,69))
                    uiText_result:setString(string.format("%d\n(赛:%0.2f)",tScoreInfo.totalScore,pBuffer.tWriteScoreArr[i]/100))
                end
            end  
        end
    else 
        local uiListView_payerInfo = ccui.Helper:seekWidgetByName(self.root,"ListView_payerInfo")
        local uiPanel_payerInfo = uiListView_payerInfo:getItem(0)
        uiPanel_payerInfo:retain()
        uiListView_payerInfo:removeAllItems()
        local uiListView_single = ccui.Helper:seekWidgetByName(self.root,"ListView_single")
        local uiPanel_single = uiListView_single:getItem(0)
        uiPanel_single:retain()
        uiListView_single:removeAllItems()
        --人物信息
        for i = 1, pBuffer.dwUserCount do
            local item = uiPanel_payerInfo:clone()
            uiListView_payerInfo:pushBackCustomItem(item)
            local tScoreInfo = pBuffer.tScoreInfo[i]
            local uiImage_avatar = ccui.Helper:seekWidgetByName(item,"Image_avatar")
            Common:requestUserAvatar(tScoreInfo.dwUserID,tScoreInfo.player.szPto,uiImage_avatar,"img")
            local uiText_palyerName = ccui.Helper:seekWidgetByName(item,"Text_palyerName")
            uiText_palyerName:setString(tScoreInfo.player.szNickName)
            uiText_palyerName:setColor(cc.c3b(0,0,0))
            local uiText_id = ccui.Helper:seekWidgetByName(item,"Text_id")
            uiText_id:setString(string.format("%d",tScoreInfo.dwUserID))
            uiText_id:setColor(cc.c3b(0,0,0))
            local uiImage_host = ccui.Helper:seekWidgetByName(item,"Image_host")
            if tScoreInfo.dwUserID == pBuffer.dwTableOwnerID then
                uiImage_host:setVisible(true)
            else
                uiImage_host:setVisible(false)
            end
            if tScoreInfo.dwUserID == pBuffer.bigWinner then
                local uiPanel_winner = ccui.Helper:seekWidgetByName(item,"Panel_winner")
                ccs.ArmatureDataManager:getInstance():addArmatureFileInfo("friend_end/dayingjiatubiao.ExportJson")
                local armature=ccs.Armature:create("dayingjiatubiao")
                armature:getAnimation():playWithIndex(0)
                uiPanel_winner:addChild(armature)
                armature:setPosition(armature:getParent():getContentSize().width/2,armature:getParent():getContentSize().height/2)
            end
            local uiText_result = ccui.Helper:seekWidgetByName(item,"Text_result")
            if tScoreInfo.totalScore >= 0 then
                uiText_result:setColor(cc.c3b(175,49,52))
                uiText_result:setString(string.format("+%d\n(赛:%0.2f)",tScoreInfo.totalScore,pBuffer.tWriteScoreArr[i]/100))
            else
                uiText_result:setColor(cc.c3b(30,85,60))
                uiText_result:setString(string.format("%d\n(赛:%0.2f)",tScoreInfo.totalScore,pBuffer.tWriteScoreArr[i]/100))
            end

            if self.tableConfig.wKindID == 20 then
                local uiTotalHuXi = ccui.ImageView:create("zipai/table/endlayerzonghuxi.png")
                item:addChild(uiTotalHuXi)
                uiTotalHuXi:setPosition(-35,-100)
                local uiTextAtlas_TatalHuXi = nil
                if tScoreInfo.totalHuXi >= 0 then
                    uiTextAtlas_TatalHuXi = ccui.TextAtlas:create(string.format(".%d",tScoreInfo.totalHuXi),"record/rocord_shuzi1.png",22,29,".")
                else
                    uiTextAtlas_TatalHuXi = ccui.TextAtlas:create(string.format(".%d",tScoreInfo.totalHuXi),"record/rocord_shuzi2.png",22,29,".")
                end
                uiTotalHuXi:addChild(uiTextAtlas_TatalHuXi)
                uiTextAtlas_TatalHuXi:setPositionX(uiTextAtlas_TatalHuXi:getParent():getContentSize().width/2)
            end     
        end
        --积分信息
        for i = 1, pBuffer.dwDataCount do
            local item = uiPanel_single:clone()
            uiListView_single:pushBackCustomItem(item)
            for j = 1, pBuffer.dwUserCount do
                local uiPanel_info = ccui.Helper:seekWidgetByName(item,string.format("Panel_info%d",j))
                local uiText_num = ccui.Helper:seekWidgetByName(uiPanel_info,"Text_num")
                uiText_num:setColor(cc.c3b(0,0,0))
                uiText_num:setString(string.format("第%d局",i))
                local uiText_score = ccui.Helper:seekWidgetByName(uiPanel_info,"Text_score")
                uiText_score:setColor(cc.c3b(0,0,0))
                local tScoreInfo = pBuffer.tScoreInfo[j]
                if tScoreInfo.lScore[i] >= 0 then
                    uiText_score:setString(string.format("+%d",tScoreInfo.lScore[i]))
                else
                    uiText_score:setString(string.format("%d",tScoreInfo.lScore[i]))
                end
            end
        end
        uiPanel_payerInfo:release()
        uiPanel_single:release()
    end
end

function FriendsRoomNewEndLayer:isInClub( pBuffer )
    return pBuffer.tableConfig.nTableType == TableType_ClubRoom and pBuffer.tableConfig.dwClubID ~= 0
end

function FriendsRoomNewEndLayer:REQ_GR_USER_CONTINUE_CLUB_FAILD(event)
    local data = event._usedata

    if self.tableConfig.wKindID == 20 then
        --放炮罚类型的固定1局
        require("common.SceneMgr"):switchTips(require("app.MyApp"):create(-2,0,self.tableConfig.wKindID,1,self.tableConfig.dwClubID,self.gameConfig):createView("InterfaceCreateRoomNode"))
    else
        require("common.SceneMgr"):switchTips(require("app.MyApp"):create(-2,0,self.tableConfig.wKindID,self.tableConfig.wTableNumber,self.tableConfig.dwClubID,self.gameConfig):createView("InterfaceCreateRoomNode"))
    end
end

function FriendsRoomNewEndLayer:setInviteUserID(pBuffer)
    self.inviteID = {}
    for i = 1, 8 do
        local id = pBuffer.tScoreInfo[i].dwUserID
        if UserData.User.userID ~= id then
            if id ~= nil and id ~= 0 then 
                table.insert(self.inviteID, id)
            else
                table.insert(self.inviteID, 0)
            end
        end
    end
end

function FriendsRoomNewEndLayer:RET_CLUB_CHAT_BACK_RECORD(event)
    local data = event._usedata
    require("common.SceneMgr"):switchTips(require("app.MyApp"):create(data):createView("PleaseReciveLayer"))
end

function FriendsRoomNewEndLayer:RET_MATCH_CLUB_TABLE(event)
    local data = event._usedata
    dump(data)
    if data.lRet ~= 0 then
        require("common.MsgBoxLayer"):create(0,nil,"再来一局错误! code="..data.lRet)
        return;
    end

    if data.dwTableID ~= 0 then
        require("common.SceneMgr"):switchTips(require("app.MyApp"):create(data.dwTableID):createView("InterfaceJoinRoomNode"))
    else
        require("common.SceneMgr"):switchTips(require("app.MyApp"):create(-2,data.dwPlayID,data.wKindID,data.wGameCount,data.dwClubID,data.tableParameter):createView("InterfaceCreateRoomNode"))
    end
end

function FriendsRoomNewEndLayer:SUB_GR_CREATE_TABLE_FAILED(event)
    -- self:removeFromParent()
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
        require("common.MsgBoxLayer"):create(2,nil,"您的疲劳值不足,无法进入房间!")
    elseif errorID == 22 then
        require("common.MsgBoxLayer"):create(2,nil,"防沉迷配置错误,请联系群主重新设置!")
    elseif errorID == 23 then
        require("common.MsgBoxLayer"):create(2,nil,"亲友圈玩法不存在,请重新刷新亲友圈!")
    elseif errorID == 24 then
        require("common.MsgBoxLayer"):create(1,nil,"您的元宝不足,请及时充值!",function() 
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

function FriendsRoomNewEndLayer:SUB_GR_JOIN_TABLE_FAILED(event)
    local data = event._usedata
    -- self:removeFromParent()
    NetMgr:getGameInstance():closeConnect()
    UserData.User.externalAdditional = ""
    if data.wErrorCode == 1 then
        require("common.MsgBoxLayer"):create(0,nil,"该房间不存在!")
    elseif data.wErrorCode == 2 then
        require("common.MsgBoxLayer"):create(0,nil,"该房间人数已满!")
    elseif data.wErrorCode == 11 then
        require("common.MsgBoxLayer"):create(0,nil,"最后一局禁止加入!")
    elseif data.wErrorCode == 21 then
        require("common.MsgBoxLayer"):create(0,nil,"您不是该亲友圈不存在!")
    elseif data.wErrorCode == 22 then
        require("common.MsgBoxLayer"):create(0,nil,"您不是该亲友圈成员!")
    elseif data.wErrorCode == 23 then
        require("common.MsgBoxLayer"):create(0,nil,"您不是该亲友圈成员,正在审核中!")
    elseif data.wErrorCode == 24 then
        require("common.MsgBoxLayer"):create(0,nil,"您已被群主禁止娱乐,请联系群主恢复!")
    elseif data.wErrorCode == 25 then
        require("common.MsgBoxLayer"):create(2,nil,"防沉迷配置错误,请联系群主重新设置!")
    elseif data.wErrorCode == 26 then
        require("common.MsgBoxLayer"):create(2,nil,"您的疲劳值不足,无法进入房间!")
    elseif data.wErrorCode == 27 then
        require("common.MsgBoxLayer"):create(2,nil,"亲友圈玩法不存在,请重新刷新亲友圈!")
    elseif data.wErrorCode == 28 then
        require("common.MsgBoxLayer"):create(1,nil,"您的元宝不足,请及时充值!",function() 
            local data = clone(UserData.Share.tableShareParameter[12])
            require("app.MyApp"):create(data):createView("ShareLayer")
        end)
    elseif data.wErrorCode == 29 then
        require("common.MsgBoxLayer"):create(2,nil,"防沉迷值已达下限!")
    elseif data.wErrorCode == 30 then
        require("common.MsgBoxLayer"):create(2,nil,"该房间有距离限制,请开启定位!")
    elseif data.wErrorCode == 31 then
        require("common.MsgBoxLayer"):create(2,nil,"该房间有距离限制,您同其他成员距离太近!")
    else
        require("common.MsgBoxLayer"):create(0,nil,"请升级版本!")
    end
end

return FriendsRoomNewEndLayer
