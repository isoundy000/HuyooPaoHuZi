local StaticData = require("app.static.StaticData")
local EventType = require("common.EventType")
local EventMgr = require("common.EventMgr")
local UserData = require("app.user.UserData")
local Common = require("common.Common")
local GameCommon = require("game.yongzhou.GameCommon") 
local Base64 = require("common.Base64")

local FriendsRoomEndLayer = class("FriendsRoomEndLayer",function()
    return ccui.Layout:create()
end)

function FriendsRoomEndLayer:create(pBuffer)
    local view = FriendsRoomEndLayer.new()
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

function FriendsRoomEndLayer:onEnter()
    --保存游戏截屏
    -- local uiListView_function = ccui.Helper:seekWidgetByName(self.root,"ListView_function")
    -- uiListView_function:setVisible(false)
    local uiButton_return = ccui.Helper:seekWidgetByName(self.root,"Button_return")
    local uiButton_share = ccui.Helper:seekWidgetByName(self.root,"Button_share")
    if StaticData.Hide[CHANNEL_ID].btn5 ~= 1 then
        uiButton_share:setVisible(false)
    end
    -- uiListView_function:refreshView()
    -- uiListView_function:setContentSize(cc.size(uiListView_function:getInnerContainerSize().width,uiListView_function:getInnerContainerSize().height))
    -- uiListView_function:setPositionX(uiListView_function:getParent():getContentSize().width/2)
    
    self:runAction(cc.Sequence:create(cc.DelayTime:create(0),cc.CallFunc:create(function(sender,event) 
        require("common.Common"):screenshot(FileName.battlefieldScreenshot) 
    end)))
end
-- ,cc.DelayTime:create(0),cc.CallFunc:create(function() 
--         uiListView_function:setVisible(true)
--     end)
function FriendsRoomEndLayer:onExit()
end


local endDes = {
	[0] = '',
	[1] = '提示：该房间被房主解散',
	[2] = '提示：该房间被管理员解散',
	[3] = '提示：该房间投票解散',
	[4] = '提示：该房间因疲劳值不足被强制解散',
	[5] = '提示：该房间被官方系统强制解散',
	[6] = '提示：该房间因超时未开局被强制解散',
	[7] = '提示：该房间因超时投票解散',
}

function FriendsRoomEndLayer:onCreate(pBuffer)
    cc.Director:getInstance():getRunningScene():removeChildByTag(LAYER_TIPS)
    
    self.ShareName = string.format("%d.jpg",os.time())
    self.root = nil
    local visibleSize = cc.Director:getInstance():getVisibleSize()
    local csb = cc.CSLoader:createNode("YZFriendsRoomEndLayer.csb")
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
            dump(data,'fx--------xx------>>')
            require("app.MyApp"):create(data):createView("ShareLayer")
        end
    end
    uiButton_share:addTouchEventListener(onEventShare)
            
    local uiText_time = ccui.Helper:seekWidgetByName(self.root,"Text_time")
    -- local function onEventRefreshTime(sender,event)
        local date = os.date("*t",os.time())
        uiText_time:setString(string.format("%d.%02d.%02d %02d:%02d",date.year,date.month,date.day,date.hour,date.min))
    --     uiText_time:runAction(cc.Sequence:create(cc.DelayTime:create(1),cc.CallFunc:create(onEventRefreshTime)))
    -- end
    --onEventRefreshTime()
    -- local uiText_homeowner = ccui.Helper:seekWidgetByName(self.root,"Text_homeowner")
    -- uiText_homeowner:setString(string.format("房主:%s(%d)",pBuffer.szOwnerName,pBuffer.dwTableOwnerID))
    local desc = ""
    if pBuffer.tableConfig ~= nil and pBuffer.tableConfig.nTableType ~= nil then
        if pBuffer.tableConfig.nTableType == TableType_ClubRoom and pBuffer.tableConfig.dwClubID ~= 0 then
            desc = "(亲友圈)"
        elseif pBuffer.tableConfig.nTableType == TableType_SportsRoom and pBuffer.tableConfig.dwClubID ~= 0 then
            desc = "(竞技场次)"
        else
            desc = "(房主房)"
        end
    end
    
    local uiText_roomInfo = ccui.Helper:seekWidgetByName(self.root,"Text_roomInfo")
    uiText_roomInfo:setString(string.format("%s房间号:%d",desc,pBuffer.tableConfig.wTbaleID))
   
   
   
    -- local uiText_gameInfo = ccui.Helper:seekWidgetByName(self.root,"Text_gameInfo")
    -- if pBuffer.gameDesc ~= nil and pBuffer.gameDesc ~= "" then
    --     uiText_gameInfo:setString(string.format("%s",StaticData.Games[pBuffer.tableConfig.wKindID].name.." "..pBuffer.gameDesc))
    -- else
    --     uiText_gameInfo:setString(string.format("%s",StaticData.Games[pBuffer.tableConfig.wKindID].name))
    -- end
    
    if pBuffer.dwUserCount == 2 then
        local uiPanel_player = ccui.Helper:seekWidgetByName(self.root,"Panel_player3")
        uiPanel_player:removeFromParent()
        local uiPanel_player = ccui.Helper:seekWidgetByName(self.root,"Panel_player4")
        uiPanel_player:removeFromParent()
    elseif pBuffer.dwUserCount == 3 then
        local uiPanel_player = ccui.Helper:seekWidgetByName(self.root,"Panel_player2")
        uiPanel_player:removeFromParent()
        local uiPanel_player = ccui.Helper:seekWidgetByName(self.root,"Panel_player4")
        uiPanel_player:removeFromParent()
    else
        local uiPanel_player = ccui.Helper:seekWidgetByName(self.root,"Panel_player2")
        uiPanel_player:removeFromParent()
        local uiPanel_player = ccui.Helper:seekWidgetByName(self.root,"Panel_player3")
        uiPanel_player:removeFromParent()
    end
     
    local uiListView_payerInfo = ccui.Helper:seekWidgetByName(self.root,"ListView_payerInfo")
    local uiPanel_payerInfo = uiListView_payerInfo:getItem(0)
    uiPanel_payerInfo:retain()
    uiListView_payerInfo:removeAllItems()


    --人物信息
    for i = 1, pBuffer.dwUserCount do
        local item = uiPanel_payerInfo:clone()
        uiListView_payerInfo:pushBackCustomItem(item)
        local tScoreInfo = pBuffer.tScoreInfo[i]
        local uiImage_avatar = ccui.Helper:seekWidgetByName(item,"Image_avatar")
        Common:requestUserAvatar(tScoreInfo.dwUserID,tScoreInfo.player.szPto,uiImage_avatar,"img")
        local uiText_palyerName = ccui.Helper:seekWidgetByName(item,"Text_palyerName")
        uiText_palyerName:setString(tScoreInfo.player.szNickName)
        uiText_palyerName:setColor(cc.c3b(139,105,20))
        local uiText_id = ccui.Helper:seekWidgetByName(item,"Text_id")
        uiText_id:setString(string.format("ID:%d",tScoreInfo.dwUserID))
        uiText_id:setColor(cc.c3b(139,105,20))
        local uiImage_host = ccui.Helper:seekWidgetByName(item,"Image_host")
        if tScoreInfo.dwUserID == pBuffer.dwTableOwnerID then
            uiImage_host:setVisible(true)
        else
            uiImage_host:setVisible(false)
        end

        local uiImage_score = ccui.Helper:seekWidgetByName(item,"Image_score")
        uiImage_score:setVisible(false)
        if tScoreInfo.dwUserID == GameCommon.dwUserID  then
            uiImage_score:setVisible(true)
        end

        if tScoreInfo.dwUserID == pBuffer.bigWinner then
            local uiPanel_winner = ccui.Helper:seekWidgetByName(item,"Panel_winner")
            ccs.ArmatureDataManager:getInstance():addArmatureFileInfo("yongzhou/anim/dayingjiatubiao/dayingjiatubiao.ExportJson")
            local armature=ccs.Armature:create("dayingjiatubiao")
            armature:getAnimation():playWithIndex(0)
            uiPanel_winner:addChild(armature)
            armature:setPosition(armature:getParent():getContentSize().width/2,armature:getParent():getContentSize().height/2)
        end
        local uiBitmapFontLabel_integral = ccui.Helper:seekWidgetByName(item,"BitmapFontLabel_integral")
        if tScoreInfo.totalScore >= 0 then      
            uiBitmapFontLabel_integral:setFntFile("yongzhou/ui/friends/gameend_all5-export.fnt")
            uiBitmapFontLabel_integral:setString(string.format("+%d",tScoreInfo.totalScore))
        else            
            uiBitmapFontLabel_integral:setFntFile("yongzhou/ui/friends/gameend_all4-export.fnt")
            uiBitmapFontLabel_integral:setString(string.format("%d",tScoreInfo.totalScore))
        end       
        if pBuffer.tableConfig.wKindID == 20 then
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
        
        local uiListView_single = ccui.Helper:seekWidgetByName(item,"ListView_single")
        local uiPanel_single = uiListView_single:getItem(0)
        uiPanel_single:retain()

        uiListView_single:removeAllItems()
        local tScoreInfo = pBuffer.tScoreInfo[i]
        for j = 1, pBuffer.tableConfig.wTableNumber do
            local item_score = uiPanel_single:clone()
            uiListView_single:pushBackCustomItem(item_score)
            local uiPanel_info = ccui.Helper:seekWidgetByName(item_score,"Panel_info")
            local uiText_num = ccui.Helper:seekWidgetByName(uiPanel_info,"Text_num")
            uiText_num:setColor(cc.c3b(140,70,20))
            uiText_num:setString(string.format("第%d局",j))
            local uiText_score = ccui.Helper:seekWidgetByName(uiPanel_info,"Text_score")
            uiText_score:setColor(cc.c3b(140,70,20))   
            if tScoreInfo.lScore[j] > 0 then
                uiText_score:setString(string.format("+%d",tScoreInfo.lScore[j]))
            else
                uiText_score:setString(string.format("%d",tScoreInfo.lScore[j]))
            end
        end     
        uiPanel_single:release()
    end

    uiPanel_payerInfo:release()


end

function FriendsRoomEndLayer:isInClub( pBuffer )
    return pBuffer.tableConfig.nTableType == TableType_ClubRoom and pBuffer.tableConfig.dwClubID ~= 0
end

return FriendsRoomEndLayer
