local Common = require("common.Common")
local StaticData = require("app.static.StaticData")
local UserData = require("app.user.UserData")
local EventType = require("common.EventType")
local EventMgr = require("common.EventMgr")
local NetMgr = require("common.NetMgr")
local NetMsgId = require("common.NetMsgId")
local Default = require("common.Default")
local Bit = require("common.Bit")
local RoomCreateLayer = class("RoomCreateLayer", cc.load("mvc").ViewBase)

function RoomCreateLayer:onEnter()
end

function RoomCreateLayer:onExit()
end

function RoomCreateLayer:onCleanup()

end

function RoomCreateLayer:onCreate(parameter)
    local locationID = parameter[1]
    self.showType    = parameter[2]    --显示类型  0默认     1设置亲友圈参数  2亲友圈自定义创房 3竞技场设置玩法
    self.dwClubID = parameter[3]
    NetMgr:getGameInstance():closeConnect()
    self.tableFriendsRoomParams = nil
    local visibleSize = cc.Director:getInstance():getVisibleSize()
    local csb = cc.CSLoader:createNode("RoomCreateLayer.csb")
    self:addChild(csb)
    self.root = csb:getChildByName("Panel_root")
    Common:addTouchEventListener(ccui.Helper:seekWidgetByName(self.root,"Button_return"),function(sender,event) self:removeFromParent() end)
    
--    local uiText_roomCard = ccui.Helper:seekWidgetByName(self.root,"Text_roomCard")
--    uiText_roomCard:setString(string.format("%d",UserData.Bag:getBagPropCount(1003))) 
--    local uiButton_roomCardBg = ccui.Helper:seekWidgetByName(self.root,"Button_roomCardBg")  
--     
--    if CHANNEL_ID == 20 or CHANNEL_ID == 21  then     
--        uiButton_roomCardBg:setVisible(false)     
--    end 
--    local uiText_warning = ccui.Helper:seekWidgetByName(self.root,"Text_warning")    
--    uiText_warning:setVisible(false)
--    Common:addTouchEventListener(uiButton_roomCardBg,function()      
--      if StaticData.Hide[CHANNEL_ID].btn9 == 1 and  CHANNEL_ID ~= 16 and  CHANNEL_ID ~= 17 then  
--          require("common.SceneMgr"):switchOperation(require("app.MyApp"):create(2):createView("NewMallLayer")) 
--      else 
--          require("common.MsgBoxLayer"):create(2,nil,"请联系代理!")
--      end 
--    end)
--    if  CHANNEL_ID == 20 or CHANNEL_ID == 21 then 
--        local uiImage_roomCard = ccui.Helper:seekWidgetByName(self.root,"Image_roomCard")    
--        uiImage_roomCard:loadTexture("hall_6/hall_wowo_35.png")
--    end
--    local uiImage_title = ccui.Helper:seekWidgetByName(self.root,"Image_title")
    local uiListView_gameTypeBtn = ccui.Helper:seekWidgetByName(self.root,"ListView_gameTypeBtn")
    local uiListView_games = ccui.Helper:seekWidgetByName(self.root,"ListView_games")
    --  列表间距              uiListView_betting:setItemsMargin(10)
    local uiButton_zipai = ccui.Helper:seekWidgetByName(self.root,"Button_zipai")      
    local uiButton_majiang = ccui.Helper:seekWidgetByName(self.root,"Button_majiang")  
    local uiButton_puke = ccui.Helper:seekWidgetByName(self.root,"Button_puke")      
    local armature1 = ccui.Helper:seekWidgetByName(self.root,"Image_zipai")
    local armature2 = ccui.Helper:seekWidgetByName(self.root,"Image_majiang")
    local armature3 = ccui.Helper:seekWidgetByName(self.root,"Image_puke")
    local regionID = cc.UserDefault:getInstance():getIntegerForKey(Default.UserDefault_RegionID,0)
    if locationID == nil or locationID == 0 then
        for key, var in pairs(UserData.Game.talbeCommonGames) do
            if var ~= 51 and var ~= 53 then
                locationID = var
                break
            end
        end
    end

    local uiButton_iten = ccui.Helper:seekWidgetByName(self.root,"Button_iten")
    uiButton_iten:retain()
    uiButton_iten:setVisible(false)

    local uiPanel_parameter = ccui.Helper:seekWidgetByName(self.root,"Panel_parameter")
    local uiPanel_para = ccui.Helper:seekWidgetByName(self.root,"Panel_para")
    uiPanel_para:setVisible(false)
    local function showGameType(type)
        if type == 1 then
            uiButton_zipai:setBright(true)
            uiButton_majiang:setBright(false)
            uiButton_puke:setBright(false)    
            armature1:loadTexture( "newroom/newroom_paohuziliang.png")
            armature2:loadTexture( "newroom/newroom_majiangan.png")
            armature3:loadTexture( "newroom/newroom_paodekuaian.png")
        elseif type == 2 then
            uiButton_zipai:setBright(false)
            uiButton_majiang:setBright(false)
            uiButton_puke:setBright(true)
            armature1:loadTexture( "newroom/newroom_paohuzian.png")
            armature2:loadTexture( "newroom/newroom_majiangan.png")
            armature3:loadTexture( "newroom/newroom_paodekuailiang.png")
        elseif type == 3 then
            uiButton_zipai:setBright(false)
            uiButton_majiang:setBright(true)
            uiButton_puke:setBright(false)
            armature1:loadTexture( "newroom/newroom_paohuzian.png")
            armature2:loadTexture( "newroom/newroom_majiangliang.png")
            armature3:loadTexture( "newroom/newroom_paodekuaian.png")
        end
    uiListView_games:removeAllItems()
    local games = {}
    games = clone(UserData.Game.tableSortGames)
    local isFound = false
    local tableNiuNiuUserID = {
        [10013998]=1,[10015147]=1,[10024831]=1,[10037008]=1,[10025776]=1
    }
    for key, var in pairs(games) do
        local wKindID = tonumber(var)
        local data = StaticData.Games[wKindID]
        if UserData.Game.tableGames[wKindID] ~= nil and Bit:_and(data.friends,1) ~= 0  and (data.type == type or type == nil ) and (wKindID ~= 51 or locationID == 51 or tableNiuNiuUserID[UserData.User.userID] ~= nil) and (wKindID ~= 53 or locationID == 53 or tableNiuNiuUserID[UserData.User.userID] ~= nil) then
            local img1 = "newroom/createv2_zuoqieye_liang.png" 
            local img2 = "newroom/createv2_zuoqieye_putong.png" 
            local item = uiButton_iten:clone()
            item.wKindID = wKindID
            item:setBright(false)
            item:setVisible(true)
            local uiImage_icon1 = ccui.Helper:seekWidgetByName(item,"Image_icon1")
            local uiImage_icon2 = ccui.Helper:seekWidgetByName(item,"Image_icon2")
            uiImage_icon1:loadTexture(data.icon1)
            uiImage_icon2:loadTexture(data.icons)
            uiImage_icon1:setVisible(false)
            uiImage_icon2:setVisible(true)
            uiListView_games:pushBackCustomItem(item)
            item:setAnchorPoint(cc.p(0,0.5))
            Common:addTouchEventListener(item,function() self:showGameParameter(wKindID) end)
            if wKindID == locationID then
                isFound = true
            end
        end	
    end
    if isFound == true then
        local btn = self:showGameParameter(locationID)
        if btn ~= nil then
            btn:runAction(cc.Sequence:create(cc.DelayTime:create(0),cc.CallFunc:create(function(sender,event)
                --位置刷新
                uiListView_games:refreshView()
                local container = uiListView_games:getInnerContainer()
                local pos = cc.p(btn:getPosition())
                pos = cc.p(btn:getParent():convertToWorldSpace(pos))
                pos = cc.p(container:convertToNodeSpace(pos))
                local value = (1-pos.y/container:getContentSize().height)*100
                if value <= 5 then
                    value = 0
                elseif value >= 95 then
                    value = 100
                end
                uiListView_games:scrollToPercentVertical(value,1,true)
            end)))
        end
    else
        local item = uiListView_games:getItem(0)
        if item ~= nil then
            self:showGameParameter(item.wKindID)
        end
    end
    end 

    Common:addTouchEventListener(uiButton_zipai,function() showGameType(1) end)
    Common:addTouchEventListener(uiButton_puke,function() showGameType(2) end)
    Common:addTouchEventListener(uiButton_majiang,function() showGameType(3) end)
    if  #UserData.Game.tableSortGames <= 5 then  
        showGameType()
    else
        if locationID == nil or locationID == 0 or UserData.Game.tableGames[locationID] == nil then
            showGameType(1)
        else
            showGameType(StaticData.Games[locationID].type)
        end
    end

end

function RoomCreateLayer:showGameParameter(wKindID)
    local uiListView_games = ccui.Helper:seekWidgetByName(self.root,"ListView_games")
    local items = uiListView_games:getItems()
    local node = nil
    for key, var in pairs(items) do
        local uiImage_icon1 = ccui.Helper:seekWidgetByName(var,"Image_icon1")
        local uiImage_icon2 = ccui.Helper:seekWidgetByName(var,"Image_icon2")
    	if var.wKindID == wKindID then
    	   if var:isBright() then
    	       return nil
    	   end
    	   node = var
           var:setBright(true)
           uiImage_icon1:setVisible(true)
           uiImage_icon2:setVisible(false)
    	else
            var:setBright(false)
            uiImage_icon1:setVisible(false)
            uiImage_icon2:setVisible(true)
    	end
    end
    local uiPanel_parameter = ccui.Helper:seekWidgetByName(self.root,"Panel_parameter")
    uiPanel_parameter:removeAllChildren()
    local RoomCreateNode = require("app.MyApp"):create(wKindID,self.showType,self.dwClubID):createView(StaticData.Games[wKindID].luaCreateRoomFile)
    uiPanel_parameter:addChild(RoomCreateNode)
    return node
end

return RoomCreateLayer