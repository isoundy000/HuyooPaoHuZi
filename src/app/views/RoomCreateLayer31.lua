local Common = require("common.Common")
local StaticData = require("app.static.StaticData")
local UserData = require("app.user.UserData")
local EventType = require("common.EventType")
local EventMgr = require("common.EventMgr")
local NetMgr = require("common.NetMgr")
local NetMsgId = require("common.NetMsgId")
local EventType = require("common.EventType")
local Bit = require("common.Bit")
local GameDesc = require("common.GameDesc")

local RoomCreateLayer = class("RoomCreateLayer", cc.load("mvc").ViewBase)

function RoomCreateLayer:onEnter()
    EventMgr:registListener(EventType.SUB_CL_FRIENDROOM_CONFIG,self,self.SUB_CL_FRIENDROOM_CONFIG)
    EventMgr:registListener(EventType.SUB_CL_FRIENDROOM_CONFIG_END,self,self.SUB_CL_FRIENDROOM_CONFIG_END)
end

function RoomCreateLayer:onExit()
    EventMgr:unregistListener(EventType.SUB_CL_FRIENDROOM_CONFIG,self,self.SUB_CL_FRIENDROOM_CONFIG)
    EventMgr:unregistListener(EventType.SUB_CL_FRIENDROOM_CONFIG_END,self,self.SUB_CL_FRIENDROOM_CONFIG_END)
end

function RoomCreateLayer:onCleanup()

end

function RoomCreateLayer:onCreate(parameter)
    self.wKindID  = parameter[1]
    self.showType = parameter[2]
    self.dwClubID = parameter[3]
    local visibleSize = cc.Director:getInstance():getVisibleSize()
    local csb = cc.CSLoader:createNode("RoomCreateLayer31.csb")
    self:addChild(csb)
    self.root = csb:getChildByName("Panel_root")
    self.recordCreateParameter = UserData.Game:readCreateParameter(self.wKindID)
    if self.recordCreateParameter == nil then
        self.recordCreateParameter = {}
    end
    local uiListView_create = ccui.Helper:seekWidgetByName(self.root,"ListView_create")
    uiListView_create:setEnabled(false)
    local uiButton_create = ccui.Helper:seekWidgetByName(self.root,"Button_create")
    Common:addTouchEventListener(uiButton_create,function() self:onEventCreate(0) end)
    local uiButton_guild = ccui.Helper:seekWidgetByName(self.root,"Button_guild")
    Common:addTouchEventListener(uiButton_guild,function() self:onEventCreate(1) end)
    local uiButton_help = ccui.Helper:seekWidgetByName(self.root,"Button_help")
    Common:addTouchEventListener(uiButton_help,function() self:onEventCreate(-1) end)
    local uiButton_settings = ccui.Helper:seekWidgetByName(self.root,"Button_settings")
    Common:addTouchEventListener(uiButton_settings,function() self:onEventCreate(-2) end)
    if self.showType ~= nil and self.showType == 1 then
        uiListView_create:removeItem(0)
        uiListView_create:removeItem(0)
        uiListView_create:removeItem(0)

    elseif self.showType ~= nil and self.showType == 3 then
        uiListView_create:removeItem(0)
        uiListView_create:removeItem(0)
        uiListView_create:removeItem(0)

    elseif self.showType ~= nil and self.showType == 2 then
        uiListView_create:removeItem(0)
        uiListView_create:removeItem(1)
        uiListView_create:removeItem(1)
    else
        uiListView_create:removeItem(3)
        uiListView_create:removeItem(0)

        if StaticData.Hide[CHANNEL_ID].btn11 ~= 1 then 
            uiListView_create:removeItem(uiListView_create:getIndex(uiButton_help))
        end  
    end
    uiListView_create:refreshView()
    uiListView_create:setContentSize(cc.size(uiListView_create:getInnerContainerSize().width,uiListView_create:getInnerContainerSize().height))
    uiListView_create:setPositionX(uiListView_create:getParent():getContentSize().width/2)

    local uiListView_parameterList = ccui.Helper:seekWidgetByName(self.root,"ListView_parameterList")
    --选择局数
    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(0),"ListView_parameter"):getItems()
    Common:addCheckTouchEventListener(items)

    --选择人数
    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(1),"ListView_parameter"):getItems()
    Common:addCheckTouchEventListener(items,false,function(index) 
        --2人房
        if index == 1 then
            local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(5),"ListView_parameter"):getItems()
            items[2]:setVisible(true)

            items[4]:setVisible(true)         
        else
            local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(5),"ListView_parameter"):getItems()
            items[2]:setVisible(false)
            items[2]:setBright(false)
            local uiText_desc = ccui.Helper:seekWidgetByName(items[2],"Text_desc")
            if uiText_desc ~= nil then 
                uiText_desc:setTextColor(cc.c3b(140,102,57))
            end
            items[4]:setVisible(false)
            items[4]:setBright(false)
            local uiText_desc = ccui.Helper:seekWidgetByName(items[4],"Text_desc")
            if uiText_desc ~= nil then 
                uiText_desc:setTextColor(cc.c3b(140,102,57))
            end 
        end
    end)
    if self.recordCreateParameter["bPlayerCount"] ~= nil and self.recordCreateParameter["bPlayerCount"] == 4 then
        items[3]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[3],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(238,105,40))
        end
    elseif self.recordCreateParameter["bPlayerCount"] ~= nil and self.recordCreateParameter["bPlayerCount"] == 2 then
        items[1]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[1],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(238,105,40))
        end
    else
        items[2]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[2],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(238,105,40))
        end
    end
    if self.showType == 3 then
        items[2]:setEnabled(false)
        items[2]:setColor(cc.c3b(170,170,170))
        if items[2]:isBright() then
            items[1]:setBright(true)
    	    local uiText_desc = ccui.Helper:seekWidgetByName(items[1],"Text_desc")
            if uiText_desc ~= nil then 
                uiText_desc:setTextColor(cc.c3b(238,105,40))
            end
        end
    end    
    --选择王数
    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(2),"ListView_parameter"):getItems()
    Common:addCheckTouchEventListener(items,false,function(index)             
        local uiButton_wangzimo = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(4),"Button_wangzimo")
        if index == 5 then
            local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(4),"ListView_parameter"):getItems()
            items[1]:setVisible(true)
            items[2]:setVisible(true)
            uiButton_wangzimo:setVisible(false)
        else      
            uiButton_wangzimo:setVisible(true)      
            local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(4),"ListView_parameter"):getItems()
            items[1]:setVisible(false)
            items[2]:setVisible(false)
            uiButton_wangzimo:setBright(true)
            local uiText_desc = ccui.Helper:seekWidgetByName(uiButton_wangzimo,"Text_desc")
            if uiText_desc ~= nil then 
                uiText_desc:setTextColor(cc.c3b(238,105,40))
            end
        end 
    end)
    if self.recordCreateParameter["bLaiZiCount"] ~= nil and self.recordCreateParameter["bLaiZiCount"] == 0 then
        items[1]:setBright(true)
    elseif self.recordCreateParameter["bLaiZiCount"] ~= nil and self.recordCreateParameter["bLaiZiCount"] == 1 then
        items[2]:setBright(true)
    elseif self.recordCreateParameter["bLaiZiCount"] ~= nil and self.recordCreateParameter["bLaiZiCount"] == 2 then
        items[3]:setBright(true)
    elseif self.recordCreateParameter["bLaiZiCount"] ~= nil and self.recordCreateParameter["bLaiZiCount"] == 3 then
        items[4]:setBright(true)
    else
        items[5]:setBright(true)
    end
    -- --选择胡息
    -- local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(3),"ListView_parameter"):getItems()
    -- Common:addCheckTouchEventListener(items)
    -- if self.recordCreateParameter["bCanHuXi"] ~= nil and self.recordCreateParameter["bCanHuXi"] == 18 then
    --     items[2]:setBright(true)
    -- elseif self.recordCreateParameter["bCanHuXi"] ~= nil and self.recordCreateParameter["bCanHuXi"] == 21 then
    --     items[3]:setBright(true)
    -- else
    --     items[1]:setBright(true)
    -- end
    --选择翻省
    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(3),"ListView_parameter"):getItems()
    Common:addCheckTouchEventListener(items)
    if self.recordCreateParameter["FanXing"] ~= nil and self.recordCreateParameter["FanXing"]["bType"] == 2 then
        items[2]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[2],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(238,105,40))
        end
    else
        items[1]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[1],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(238,105,40))
        end
    end
    --限胡
    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(4),"ListView_parameter"):getItems()
    Common:addCheckTouchEventListener(items)

    if self.recordCreateParameter["bLimit"] ~= nil and self.recordCreateParameter["bLimit"] == 2 then
        if items[2] ~= nil then 
            items[2]:setBright(true)
            local uiText_desc = ccui.Helper:seekWidgetByName(items[2],"Text_desc")
            if uiText_desc ~= nil then 
                uiText_desc:setTextColor(cc.c3b(238,105,40))
            end
        end
    else
        items[1]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[1],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(238,105,40))
        end
    end

    local uiButton_wangzimo = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(4),"Button_wangzimo")
    if self.recordCreateParameter["bLaiZiCount"] ~= nil and self.recordCreateParameter["bLaiZiCount"] ~= 4 then
        items[1]:setVisible(false)
        items[2]:setVisible(false)
        uiButton_wangzimo:setVisible(true) 
        uiButton_wangzimo:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(uiButton_wangzimo,"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(238,105,40))
        end
    else
        items[1]:setVisible(true)
        items[2]:setVisible(true)
        uiButton_wangzimo:setVisible(false)

    end 
    if self.showType == 3 then
        items[1]:setBright(true)        
        local uiText_desc = ccui.Helper:seekWidgetByName(items[1],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(238,105,40))
        end
        if items[2] ~= nil then 
            items[2]:setBright(false)
            items[2]:setEnabled(false)
            items[2]:setColor(cc.c3b(170,170,170))

            local uiText_desc = ccui.Helper:seekWidgetByName(items[2],"Text_desc")
            if uiText_desc ~= nil then 
                uiText_desc:setTextColor(cc.c3b(140,102,57))
            end
        end
    end
    --可选
    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(5),"ListView_parameter"):getItems()
    Common:addCheckTouchEventListener(items,true)

    if self.recordCreateParameter["bMaxLost"] ~= nil or self.recordCreateParameter["bMaxLost"] ~= 0 then
        items[1]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[1],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(238,105,40))
        end
    end

    if self.recordCreateParameter["bPlayerCount"] ~= nil and self.recordCreateParameter["bPlayerCount"] == 2 then
        if self.recordCreateParameter["bDeathCard"] ~= nil and self.recordCreateParameter["bDeathCard"] ~= 0 then
            items[2]:setBright(true)
            local uiText_desc = ccui.Helper:seekWidgetByName(items[2],"Text_desc")
            if uiText_desc ~= nil then 
                uiText_desc:setTextColor(cc.c3b(238,105,40))
            end
        end 
        if self.recordCreateParameter["bCanHuXi"] == nil or self.recordCreateParameter["bCanHuXi"] == 21 then
            items[4]:setBright(true)
            local uiText_desc = ccui.Helper:seekWidgetByName(items[3],"Text_desc")
            if uiText_desc ~= nil then 
                uiText_desc:setTextColor(cc.c3b(238,105,40))
            end
        end
    else
        items[2]:setVisible(false)
        items[4]:setVisible(false)
    end


    if self.recordCreateParameter["dwMingTang"] == nil or Bit:_and(0x01,self.recordCreateParameter["dwMingTang"]) ~= 0 then
        items[3]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[3],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(238,105,40))
        end
    end
    

    --单双醒
    local uiButton_shuangxing = ccui.Helper:seekWidgetByName(self.root,"Button_shuangxing")
    if self.recordCreateParameter["FanXing"] ~= nil and self.recordCreateParameter["FanXing"]["bAddTun"] == 2 then
        uiButton_shuangxing:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(uiButton_shuangxing,"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(238,105,40))
        end
    else
        uiButton_shuangxing:setBright(false)
        local uiText_desc = ccui.Helper:seekWidgetByName(uiButton_shuangxing,"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(140,102,57))
        end
    end
    Common:addTouchEventListener(uiButton_shuangxing,function() 
            if uiButton_shuangxing:isBright() then 
                uiButton_shuangxing:setBright(false)
                local uiText_desc = ccui.Helper:seekWidgetByName(uiButton_shuangxing,"Text_desc")
                if uiText_desc ~= nil then 
                    uiText_desc:setTextColor(cc.c3b(140,102,57))
                end
            else
                uiButton_shuangxing:setBright(true)
                local uiText_desc = ccui.Helper:seekWidgetByName(uiButton_shuangxing,"Text_desc")
                if uiText_desc ~= nil then 
                    uiText_desc:setTextColor(cc.c3b(238,105,40))
                end
            end 
    end)

    if self.showType == 3 then
        self.tableFriendsRoomParams = {[1] = {wGameCount = 1}}
        self:SUB_CL_FRIENDROOM_CONFIG_END()
    else
        UserData.Game:sendMsgGetFriendsRoomParam(self.wKindID)
    end
end

function RoomCreateLayer:SUB_CL_FRIENDROOM_CONFIG(event)
    local data = event._usedata
    if data.wKindID ~= self.wKindID then
        return
    end
    if self.tableFriendsRoomParams == nil then
        self.tableFriendsRoomParams = {}
    end
    self.tableFriendsRoomParams[data.dwIndexes] = data
end

function RoomCreateLayer:SUB_CL_FRIENDROOM_CONFIG_END(event)
    if self.tableFriendsRoomParams == nil then
        return
    end
    local uiListView_create = ccui.Helper:seekWidgetByName(self.root,"ListView_create")
    uiListView_create:setEnabled(true)
    local uiListView_parameterList = ccui.Helper:seekWidgetByName(self.root,"ListView_parameterList")
    local uiListView_parameter = uiListView_parameterList:getItem(0)
    uiListView_parameter:setVisible(true)
    local items = ccui.Helper:seekWidgetByName(uiListView_parameter,"ListView_parameter"):getItems()
    local isFound = false
    for key, var in pairs(items) do
        local data = self.tableFriendsRoomParams[key]
        if data then
            local uiText_desc = ccui.Helper:seekWidgetByName(var,"Text_desc")
            uiText_desc:setString(string.format("%d局",data.wGameCount))
            local uiText_addition = ccui.Helper:seekWidgetByName(var,"Text_addition")
            if data.dwExpendType == 1 then
                uiText_addition:setString(string.format("金币x%d",data.dwExpendCount))
            elseif data.dwExpendType == 2 then
                uiText_addition:setString(string.format("元宝x%d",data.dwExpendCount))
            elseif data.dwExpendType == 3 then
                uiText_addition:setString(string.format("(%sx%d)",StaticData.Items[data.dwSubType].name,data.dwExpendCount))   
            else
                uiText_addition:setString("(无消耗)")
            end
            if isFound == false and self.recordCreateParameter["wGameCount"] ~= nil and self.recordCreateParameter["wGameCount"] == data.wGameCount then
                var:setBright(true)
                isFound = true
                local uiText_desc = ccui.Helper:seekWidgetByName(var,"Text_desc")
                if uiText_desc ~= nil then 
                    uiText_desc:setTextColor(cc.c3b(238,105,40))
                end
                if uiText_addition ~= nil then 
                    uiText_addition:setTextColor(cc.c3b(238,105,40))
                end
            else
                uiText_desc:setTextColor(cc.c3b(140,102,57))
                uiText_addition:setTextColor(cc.c3b(140,102,57))
            end
    	else
    	   var:setBright(false)
           var:setVisible(false)
           local uiText_desc = ccui.Helper:seekWidgetByName(var,"Text_desc")
           if uiText_desc ~= nil then 
               uiText_desc:setTextColor(cc.c3b(140,102,57))
           end
           local uiText_addition = ccui.Helper:seekWidgetByName(var,"Text_addition")
           if uiText_addition ~= nil then 
            uiText_addition:setTextColor(cc.c3b(140,102,57))
           end
    	end
    end
    if isFound == false and items[1]:isVisible() then
        items[1]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[1],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(238,105,40))
        end
        local uiText_addition = ccui.Helper:seekWidgetByName(items[1],"Text_addition")
        if uiText_addition ~= nil then 
         uiText_addition:setTextColor(cc.c3b(238,105,40))
        end
    end
end

function RoomCreateLayer:onEventCreate(nTableType)
    NetMgr:getGameInstance():closeConnect()
    local uiListView_parameterList = ccui.Helper:seekWidgetByName(self.root,"ListView_parameterList")
    local tableParameter = {}
    --选择局数
    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(0),"ListView_parameter"):getItems()
    if items[1]:isBright() and self.tableFriendsRoomParams[1] then
        tableParameter.wGameCount = self.tableFriendsRoomParams[1].wGameCount
    elseif items[2]:isBright() and self.tableFriendsRoomParams[2] then
        tableParameter.wGameCount = self.tableFriendsRoomParams[2].wGameCount
    elseif items[3]:isBright() and self.tableFriendsRoomParams[3] then
        tableParameter.wGameCount = self.tableFriendsRoomParams[3].wGameCount
    else
        return
    end
  
    --选择人数
    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(1),"ListView_parameter"):getItems()
    if items[1]:isBright() then
        tableParameter.bPlayerCountType = 0
        tableParameter.bPlayerCount = 2
    elseif items[2]:isBright() then
        tableParameter.bPlayerCountType = 0
        tableParameter.bPlayerCount = 3
    elseif items[3]:isBright() then
        tableParameter.bPlayerCountType = 2
        tableParameter.bPlayerCount = 4
    else
        return
    end  
    --选择王数
    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(2),"ListView_parameter"):getItems()
    if items[1]:isBright() then
        tableParameter.bLaiZiCount = 0
    elseif items[2]:isBright() then
        tableParameter.bLaiZiCount = 1
    elseif items[3]:isBright() then
        tableParameter.bLaiZiCount = 2
    elseif items[4]:isBright() then
        tableParameter.bLaiZiCount = 3
    elseif items[5]:isBright() then
        tableParameter.bLaiZiCount = 4
    else
        return
    end    
    --选择翻省
    tableParameter.FanXing = {}
    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(3),"ListView_parameter"):getItems()
    if items[1]:isBright() then
        tableParameter.FanXing.bType = 3
        tableParameter.FanXing.bCount = 1
    elseif items[2]:isBright() then
        tableParameter.FanXing.bType = 2
        tableParameter.FanXing.bCount = 1
    end
    --翻省囤数
    if tableParameter.bLaiZiCount == 4 then
        local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(4),"ListView_parameter"):getItems()
        if items[1]:isBright() then
            tableParameter.bLimit = 1
        elseif items[2]:isBright() then
            tableParameter.bLimit =2 
        end
    else 
        tableParameter.bLimit = 0  
    end 
    
    --双醒  
    local uiButton_shuangxing = ccui.Helper:seekWidgetByName(self.root,"Button_shuangxing")
    if uiButton_shuangxing:isBright() then
        tableParameter.FanXing.bAddTun = 2
    else
        tableParameter.FanXing.bAddTun = 1
    end
    --名堂
    tableParameter.dwMingTang = 0xFFF
    tableParameter.dwMingTang = Bit:_xor(tableParameter.dwMingTang,0x10)
    tableParameter.dwMingTang = Bit:_xor(tableParameter.dwMingTang,0x08)
    tableParameter.dwMingTang = Bit:_xor(tableParameter.dwMingTang,0x01)
    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(5),"ListView_parameter"):getItems()
    if items[1]:isBright() then
        tableParameter.bMaxLost = 300
    else
        tableParameter.bMaxLost = 0
    end
    if items[2]:isBright() then
        tableParameter.bDeathCard = 1
    else
        tableParameter.bDeathCard = 0     
    end
    if items[3]:isBright() then
        tableParameter.dwMingTang = Bit:_or(tableParameter.dwMingTang,0x10)
        tableParameter.dwMingTang = Bit:_or(tableParameter.dwMingTang,0x08)
        tableParameter.dwMingTang = Bit:_or(tableParameter.dwMingTang,0x01)
    end
    if items[4]:isBright() then
        tableParameter.bCanHuXi = 21
    else
        tableParameter.bCanHuXi = 15
    end
    tableParameter.bYiWuShi = 0
    tableParameter.bLiangPai = 0
    tableParameter.bHuType = 0
    tableParameter.bFangPao = 0
    tableParameter.bSettlement = 0
    tableParameter.bStartTun = 0
    tableParameter.bSocreType = 1

    if self.showType ~= 2 and (nTableType == TableType_FriendRoom or nTableType == TableType_HelpRoom) then
        --普通创房和代开需要判断金币
        local uiListView_parameterList = ccui.Helper:seekWidgetByName(self.root,"ListView_parameterList")
        local uiListView_parameter = uiListView_parameterList:getItem(0)
        local items = ccui.Helper:seekWidgetByName(uiListView_parameter,"ListView_parameter"):getItems()
        for key, var in pairs(items) do
            if var:isBright() then
                local data = self.tableFriendsRoomParams[key]
                if data.dwExpendType == 0 then--无消耗
                elseif data.dwExpendType == 1 then--金币
                    if UserData.User.dwGold  < data.dwExpendCount then
                        if  StaticData.Hide[CHANNEL_ID].btn8 == 1 and StaticData.Hide[CHANNEL_ID].btn9 == 1  then
                            require("common.MsgBoxLayer"):create(1,nil,"您的金币不足,请前往商城充值？",function() require("common.SceneMgr"):switchOperation(require("app.MyApp"):create(2):createView("NewMallLayer")) end)
                        else
                            require("common.MsgBoxLayer"):create(1,nil,"您的金币不足，请联系代理购买！",function() require("common.SceneMgr"):switchOperation(require("app.MyApp"):create():createView("GuilLayer"))  end)
                        end
                        return
                end  
                elseif data.dwExpendType == 2 then--元宝
                    if UserData.User.dwIngot  < data.dwExpendCount then
                        if  StaticData.Hide[CHANNEL_ID].btn8 == 1 and StaticData.Hide[CHANNEL_ID].btn9 == 1  then
                            require("common.MsgBoxLayer"):create(1,nil,"您的元宝不足,请前往商城购买？",function() require("common.SceneMgr"):switchOperation(require("app.MyApp"):create(2):createView("NewMallLayer")) end)
                        else
                            require("common.MsgBoxLayer"):create(1,nil,"您的元宝不足，请联系代理购买！",function() require("common.SceneMgr"):switchOperation(require("app.MyApp"):create():createView("GuilLayer"))  end)
                        end
                        return
                end 
                elseif data.dwExpendType == 3 then--道具
                    local itemCount = UserData.Bag:getBagPropCount(data.dwSubType)
                    if itemCount < data.dwExpendCount then
                        if  StaticData.Hide[CHANNEL_ID].btn8 == 1 and StaticData.Hide[CHANNEL_ID].btn9 == 1  then
                            require("common.MsgBoxLayer"):create(1,nil,"您的道具不足,请前往商城购买?",function() require("common.SceneMgr"):switchOperation(require("app.MyApp"):create(2):createView("NewMallLayer")) end)
                        else
                            require("common.MsgBoxLayer"):create(0,nil,"您的道具不足!")
                        end
                        return
                    end
                else
                    return
                end
                break
            end
        end
    end

    UserData.Game:saveCreateParameter(self.wKindID,tableParameter)

    --亲友圈自定义创房
    if self.showType == 2 then
        local uiButton_create = ccui.Helper:seekWidgetByName(self.root,"Button_create")
        uiButton_create:removeAllChildren()
        uiButton_create:addChild(require("app.MyApp"):create(TableType_ClubRoom,1,self.wKindID,tableParameter.wGameCount,self.dwClubID,tableParameter):createView("InterfaceCreateRoomNode"))
        return
    end 
    --设置亲友圈   
    if nTableType == TableType_ClubRoom then
        EventMgr:dispatch(EventType.EVENT_TYPE_SETTINGS_CLUB_PARAMETER,{wKindID = self.wKindID,wGameCount = tableParameter.wGameCount,tableParameter = tableParameter})      
        return
    end

    local uiButton_create = ccui.Helper:seekWidgetByName(self.root,"Button_create")
    uiButton_create:removeAllChildren()
    uiButton_create:addChild(require("app.MyApp"):create(nTableType,0,self.wKindID,tableParameter.wGameCount,UserData.Guild.dwPresidentID,tableParameter):createView("InterfaceCreateRoomNode"))

end

return RoomCreateLayer

