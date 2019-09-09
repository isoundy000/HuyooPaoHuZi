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
    local csb = cc.CSLoader:createNode("RoomCreateLayer40.csb")
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

    --选择人数
    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(0),"ListView_parameter"):getItems()
    Common:addCheckTouchEventListener(items,false,function(index) 
        -- 通过人数控制第二列选项（2人是否去牌 3人张数控制）   
        if index == 2 then 
            local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(1),"ListView_parameter"):getItems()
            local isHave = false
            for key, var in pairs(items) do
        		var:setColor(cc.c3b(255,255,255))
                var:setEnabled(true)
                if var:isBright() then
                    isHave = true
                end
            end
            
            if isHave == false then 
                items[2]:setBright(true)
                local uiText_desc = ccui.Helper:seekWidgetByName(items[2],"Text_desc")
                if uiText_desc ~= nil then 
                    uiText_desc:setTextColor(cc.c3b(238,105,40))
                end            
                items[1]:setBright(false)
                local uiText_desc = ccui.Helper:seekWidgetByName(items[1],"Text_desc")
                if uiText_desc ~= nil then 
                    uiText_desc:setTextColor(cc.c3b(140,102,57))
                end
            end
            local uiText_desc = ccui.Helper:seekWidgetByName(items[2],"Text_desc")
            if uiText_desc ~= nil then 
                uiText_desc:setString("21张")
            end
            local uiText_desc = ccui.Helper:seekWidgetByName(items[1],"Text_desc")
            if uiText_desc ~= nil then 
                uiText_desc:setString("15张")
            end

        elseif index == 1 then
            local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(1),"ListView_parameter"):getItems()
            local isHave = false
            for key, var in pairs(items) do
                var:setColor(cc.c3b(255,255,255))
                var:setEnabled(true)
                if var:isBright() then
                    isHave = true
                end
            end
            if isHave == false then 
                items[1]:setBright(true)
                local uiText_desc = ccui.Helper:seekWidgetByName(items[1],"Text_desc")
                if uiText_desc ~= nil then 
                    uiText_desc:setTextColor(cc.c3b(238,105,40))
                end            
                items[2]:setBright(false)
                local uiText_desc = ccui.Helper:seekWidgetByName(items[2],"Text_desc")
                if uiText_desc ~= nil then 
                    uiText_desc:setTextColor(cc.c3b(140,102,57))
                end
            end
            local uiText_desc = ccui.Helper:seekWidgetByName(items[1],"Text_desc")
            if uiText_desc ~= nil then 
                uiText_desc:setString("抽牌20张")
            end
            local uiText_desc = ccui.Helper:seekWidgetByName(items[2],"Text_desc")
            if uiText_desc ~= nil then 
                uiText_desc:setString("不抽底牌")
            end
        else
            local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(1),"ListView_parameter"):getItems()
            for key, var in pairs(items) do 
                var:setBright(false)
                var:setEnabled(false)
                local uiText_desc = ccui.Helper:seekWidgetByName(var,"Text_desc")
                if uiText_desc ~= nil then 
                    uiText_desc:setTextColor(cc.c3b(140,102,57))
                end
                var:setColor(cc.c3b(170,170,170))
            end 
        end
        --通过人数控制翻倍选项
        if index ~= 1 then 
            local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(11),"ListView_parameter"):getItems()        
            for key, var in pairs(items) do 
                var:setBright(false)
                var:setEnabled(false)
                local uiText_desc = ccui.Helper:seekWidgetByName(var,"Text_desc")
                if uiText_desc ~= nil then 
                    uiText_desc:setTextColor(cc.c3b(140,102,57))
                end
                var:setColor(cc.c3b(170,170,170))
            end 
            local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(12),"ListView_parameter"):getItems()        
            for key, var in pairs(items) do 
                var:setBright(false)
                var:setEnabled(false)
                local uiText_desc = ccui.Helper:seekWidgetByName(var,"Text_desc")
                if uiText_desc ~= nil then 
                    uiText_desc:setTextColor(cc.c3b(140,102,57))
                end
                var:setColor(cc.c3b(170,170,170))
            end
            local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(13),"ListView_parameter"):getItems()        
            for key, var in pairs(items) do 
                var:setBright(false)
                var:setEnabled(false)
                local uiText_desc = ccui.Helper:seekWidgetByName(var,"Text_desc")
                if uiText_desc ~= nil then 
                    uiText_desc:setTextColor(cc.c3b(140,102,57))
                end
                var:setColor(cc.c3b(170,170,170))
            end

            local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(14),"ListView_parameter"):getItems()        
            for key, var in pairs(items) do 
                var:setBright(false)
                var:setEnabled(false)
                local uiText_desc = ccui.Helper:seekWidgetByName(var,"Text_desc")
                if uiText_desc ~= nil then 
                    uiText_desc:setTextColor(cc.c3b(140,102,57))
                end
                var:setColor(cc.c3b(170,170,170))
            end
        else
            local isHave = false
            local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(11),"ListView_parameter"):getItems()        
            for key, var in pairs(items) do
        		var:setColor(cc.c3b(255,255,255))
                var:setEnabled(true)
                if var:isBright() then
                    isHave = true
                end
        	end
        	if isHave == false then
                items[2]:setBright(true)
                local uiText_desc = ccui.Helper:seekWidgetByName(items[2],"Text_desc")
                if uiText_desc ~= nil then 
                    uiText_desc:setTextColor(cc.c3b(238,105,40))
                end
            end
            local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(12),"ListView_parameter"):getItems()        
            for key, var in pairs(items) do
        		var:setColor(cc.c3b(255,255,255))
                var:setEnabled(true)
            end
            local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(13),"ListView_parameter"):getItems()        
            for key, var in pairs(items) do
        		var:setColor(cc.c3b(255,255,255))
                var:setEnabled(true)
            end
            
            local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(14),"ListView_parameter"):getItems()        
            for key, var in pairs(items) do
        		var:setColor(cc.c3b(255,255,255))
                var:setEnabled(true)

        	end
            items[1]:setBright(true)
            local uiText_desc = ccui.Helper:seekWidgetByName(items[1],"Text_desc")
            if uiText_desc ~= nil then 
                uiText_desc:setTextColor(cc.c3b(238,105,40))
            end
        end 
    end)
    if self.recordCreateParameter["bPlayerCount"] ~= nil and self.recordCreateParameter["bPlayerCount"] == 2 then
        items[1]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[1],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(238,105,40))
        end
    elseif self.recordCreateParameter["bPlayerCount"] ~= nil and self.recordCreateParameter["bPlayerCount"] == 3 then
        items[2]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[2],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(238,105,40))
        end
    else
        items[3]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[3],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(238,105,40))
        end
    end

    --2人选择亡牌  3人选择张数
    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(1),"ListView_parameter"):getItems()
    Common:addCheckTouchEventListener(items)
    if self.recordCreateParameter["bPlayerCount"] ~= nil and self.recordCreateParameter["bPlayerCount"] == 2 then
        if self.recordCreateParameter["bDeathCard"] ~= nil and self.recordCreateParameter["bDeathCard"] == 0 then
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
        local uiText_desc = ccui.Helper:seekWidgetByName(items[1],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setString("抽牌20张")
        end
        local uiText_desc = ccui.Helper:seekWidgetByName(items[2],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setString("不抽底牌")
        end
    elseif self.recordCreateParameter["bPlayerCount"] ~= nil and self.recordCreateParameter["bPlayerCount"] == 3 then
        if self.recordCreateParameter["bCardCount21"] ~= nil and self.recordCreateParameter["bCardCount21"] == 1 then
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
        local uiText_desc = ccui.Helper:seekWidgetByName(items[1],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setString("15张")
        end
        local uiText_desc = ccui.Helper:seekWidgetByName(items[2],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setString("21张")
        end
    else        
        for key, var in pairs(items) do 
            var:setBright(false)
            var:setEnabled(false)
            local uiText_desc = ccui.Helper:seekWidgetByName(var,"Text_desc")
            if uiText_desc ~= nil then 
                uiText_desc:setTextColor(cc.c3b(140,102,57))
            end
            var:setColor(cc.c3b(170,170,170))
        end 
    end

    
    --选择翻垛
    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(2),"ListView_parameter"):getItems()
    Common:addCheckTouchEventListener(items)
    if self.recordCreateParameter["FanXing"] ~= nil and self.recordCreateParameter["FanXing"]["bType"] == 3 then
        items[3]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[3],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(238,105,40))
        end
    elseif self.recordCreateParameter["FanXing"] ~= nil and self.recordCreateParameter["FanXing"]["bType"] == 2 then
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

    --选择局数
    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(3),"ListView_parameter"):getItems()
    Common:addCheckTouchEventListener(items, false, function(index)
		if index == 1 or index == 2 or index == 3 then
			local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(4), "ListView_parameter"):getItems()
			items[1]:setBright(false)
			local uiText_desc = ccui.Helper:seekWidgetByName(items[1], "Text_desc")
			if uiText_desc ~= nil then
				uiText_desc:setTextColor(cc.c3b(140,102,57))
            end

            local uiText_addition = ccui.Helper:seekWidgetByName(items[1],"Text_addition")
            if uiText_addition ~= nil then 
                uiText_addition:setTextColor(cc.c3b(140,102,57))
            end
		end
	end)

    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(4),"ListView_parameter"):getItems()
    Common:addCheckTouchEventListener(items, false, function(index)
		if index == 1 then
			local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(3), "ListView_parameter"):getItems()
            for key, var in pairs(items) do 
                var:setBright(false)
                local uiText_desc = ccui.Helper:seekWidgetByName(var, "Text_desc")
                if uiText_desc ~= nil then
                    uiText_desc:setTextColor(cc.c3b(140,102,57))
                end
                local uiText_addition = ccui.Helper:seekWidgetByName(var,"Text_addition")
                if uiText_addition ~= nil then 
                    uiText_addition:setTextColor(cc.c3b(140,102,57))
                end
            end 
		end
	end)
    --选择玩法
    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(5),"ListView_parameter"):getItems()
    Common:addCheckTouchEventListener(items)
    if self.recordCreateParameter["bSettlement"] ~= nil and self.recordCreateParameter["bSettlement"] == 2 then
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

    --选择胡息
    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(6),"ListView_parameter"):getItems()
    Common:addCheckTouchEventListener(items)
    if self.recordCreateParameter["bCanHuXi"] ~= nil and self.recordCreateParameter["bCanHuXi"] == 9 then
        items[2]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[2],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(238,105,40))
        end
    elseif self.recordCreateParameter["bCanHuXi"] ~= nil and self.recordCreateParameter["bCanHuXi"] == 15 then
        items[3]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[3],"Text_desc")
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
    --选择必胡
    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(7),"ListView_parameter"):getItems()
    Common:addCheckTouchEventListener(items)
    if self.recordCreateParameter["bHuType"] ~= nil and self.recordCreateParameter["bHuType"] == 1 then
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
    --名堂
    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(8),"ListView_parameter"):getItems()
    Common:addCheckTouchEventListener(items,true,function(index) 
        if index == 1 then       
            local target = items[index]
            if target:isBright() then
                local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(15), "ListView_parameter"):getItems()
                items[2]:setBright(true)
                items[2]:setVisible(true)
                local uiText_desc = ccui.Helper:seekWidgetByName(items[2], "Text_desc")
                if uiText_desc ~= nil then
                    uiText_desc:setTextColor(cc.c3b(238,105,40))
                end
            else
                local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(15), "ListView_parameter"):getItems()
                items[2]:setBright(false)
                items[2]:setVisible(false)
                local uiText_desc = ccui.Helper:seekWidgetByName(items[2], "Text_desc")
                if uiText_desc ~= nil then
                    uiText_desc:setTextColor(cc.c3b(140,102,57))
                end
            end
        end
    end)
    if self.recordCreateParameter["bFangPao"] == nil or self.recordCreateParameter["bFangPao"] == 1 then
        items[1]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[1],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(238,105,40))
        end
    end

    if self.recordCreateParameter["bStartTun"] == nil or self.recordCreateParameter["bStartTun"] == 2 then
        items[2]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[2],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(238,105,40))
        end
    end

    if self.recordCreateParameter["bYiWuShi"] ~= nil and self.recordCreateParameter["bYiWuShi"] == 1 then
        items[3]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[3],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(238,105,40))
        end
    end

    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(9),"ListView_parameter"):getItems()
    Common:addCheckTouchEventListener(items,true)
    if self.recordCreateParameter["dwMingTang"] == nil or Bit:_and(0x02,self.recordCreateParameter["dwMingTang"]) ~= 0 then
        items[1]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[1],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(238,105,40))
        end
    end
    if self.recordCreateParameter["bDelShowCardHu"] == nil or self.recordCreateParameter["bDelShowCardHu"] == 0 then
        items[2]:setBright(true)
	    local uiText_desc = ccui.Helper:seekWidgetByName(items[2],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(238,105,40))
        end
    end
    --飘胡
    if self.recordCreateParameter["bPiaoHu"] ~= nil and self.recordCreateParameter["bPiaoHu"] ~= 0 then
        items[3]:setBright(true)
	    local uiText_desc = ccui.Helper:seekWidgetByName(items[3],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(238,105,40))
        end
    end
    -- 天地胡
    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(10),"ListView_parameter"):getItems()
    Common:addCheckTouchEventListener(items,true)
    if self.recordCreateParameter["dwMingTang"] ~= nil and Bit:_and(0x0D00,self.recordCreateParameter["dwMingTang"]) ~= 0 then
        items[1]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[1],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(238,105,40))
        end
    end

    if self.recordCreateParameter["dwMingTang"] ~= nil and Bit:_and(0x0C0,self.recordCreateParameter["dwMingTang"]) ~= 0 then
        items[2]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[2],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(238,105,40))
        end
    end

    if self.recordCreateParameter["dwMingTang"] ~= nil and Bit:_and(0x20,self.recordCreateParameter["dwMingTang"]) ~= 0 then
        items[3]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[3],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(238,105,40))
        end
    end

    --选择加倍
    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(11),"ListView_parameter"):getItems()
    Common:addCheckTouchEventListener(items,false,function(index) 
		if index == 1 or index == 2 then
			local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(12), "ListView_parameter"):getItems()
			items[1]:setBright(false)
			local uiText_desc = ccui.Helper:seekWidgetByName(items[1], "Text_desc")
			if uiText_desc ~= nil then
				uiText_desc:setTextColor(cc.c3b(140,102,57))
			end
			items[2]:setBright(false)
			local uiText_desc = ccui.Helper:seekWidgetByName(items[2], "Text_desc")
			if uiText_desc ~= nil then
				uiText_desc:setTextColor(cc.c3b(140,102,57))
			end
		end   
        if index == 1 or index == 2  then
			local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(13), "ListView_parameter"):getItems()
			items[1]:setBright(false)
			local uiText_desc = ccui.Helper:seekWidgetByName(items[1], "Text_desc")
			if uiText_desc ~= nil then
				uiText_desc:setTextColor(cc.c3b(140,102,57))
			end
        end


        if index == 1 then
            local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(14),"ListView_parameter"):getItems()        
            for key, var in pairs(items) do 
                var:setBright(false)
                var:setEnabled(false)
                local uiText_desc = ccui.Helper:seekWidgetByName(var,"Text_desc")
                if uiText_desc ~= nil then 
                    uiText_desc:setTextColor(cc.c3b(140,102,57))
                end
                var:setColor(cc.c3b(170,170,170))
            end
        else
            local isHave = false
            local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(14),"ListView_parameter"):getItems()        
            for key, var in pairs(items) do
        		var:setColor(cc.c3b(255,255,255))
                var:setEnabled(true)
                if var:isBright() then
                    isHave = true
                end
            end     
            if isHave == false then
                items[1]:setBright(true)
                local uiText_desc = ccui.Helper:seekWidgetByName(items[1],"Text_desc")
                if uiText_desc ~= nil then 
                        uiText_desc:setTextColor(cc.c3b(238,105,40))
                end
            end
        	           
        end
        
    end)
    if self.recordCreateParameter["bPlayerCount"] ~= nil and self.recordCreateParameter["bPlayerCount"] ~= 2 then
        for key, var in pairs(items) do 
            var:setBright(false)
            var:setEnabled(false)
            local uiText_desc = ccui.Helper:seekWidgetByName(var,"Text_desc")
            if uiText_desc ~= nil then 
                uiText_desc:setTextColor(cc.c3b(140,102,57))
            end
            var:setColor(cc.c3b(170,170,170))
        end
    elseif self.recordCreateParameter["bPlayerCount"] ~= nil and self.recordCreateParameter["bPlayerCount"] == 2 then
        if ( self.recordCreateParameter["bMinLost"] ~= nil and  self.recordCreateParameter["bMinLostCell"] ~= nil  ) 
        and ( self.recordCreateParameter["bMinLost"] == 0 and  self.recordCreateParameter["bMinLostCell"] == 1  ) then
            items[1]:setBright(true)        
            local uiText_desc = ccui.Helper:seekWidgetByName(items[1],"Text_desc")
            if uiText_desc ~= nil then 
                uiText_desc:setTextColor(cc.c3b(238,105,40))
            end
        elseif self.recordCreateParameter["bMinLost"] ~= nil and self.recordCreateParameter["bMinLost"] == 10 then
            items[2]:setBright(true)        
            local uiText_desc = ccui.Helper:seekWidgetByName(items[2],"Text_desc")
            if uiText_desc ~= nil then 
                uiText_desc:setTextColor(cc.c3b(238,105,40))
            end
        end
    else
        for key, var in pairs(items) do 
            var:setBright(false)
            var:setEnabled(false)
            local uiText_desc = ccui.Helper:seekWidgetByName(var,"Text_desc")
            if uiText_desc ~= nil then 
                uiText_desc:setTextColor(cc.c3b(140,102,57))
            end
            var:setColor(cc.c3b(170,170,170))
        end
    end

    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(12),"ListView_parameter"):getItems()
    Common:addCheckTouchEventListener(items,false,function(index) 
		if index == 1 or index == 2 then
			local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(11), "ListView_parameter"):getItems()
			items[1]:setBright(false)
			local uiText_desc = ccui.Helper:seekWidgetByName(items[1], "Text_desc")
			if uiText_desc ~= nil then
				uiText_desc:setTextColor(cc.c3b(140,102,57))
			end
			items[2]:setBright(false)
			local uiText_desc = ccui.Helper:seekWidgetByName(items[2], "Text_desc")
			if uiText_desc ~= nil then
				uiText_desc:setTextColor(cc.c3b(140,102,57))
			end
		end   
        if index == 1 or index == 2  then
			local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(13), "ListView_parameter"):getItems()
			items[1]:setBright(false)
			local uiText_desc = ccui.Helper:seekWidgetByName(items[1], "Text_desc")
			if uiText_desc ~= nil then
				uiText_desc:setTextColor(cc.c3b(140,102,57))
			end
        end
        
        local isHave = false
        local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(14),"ListView_parameter"):getItems()        
        for key, var in pairs(items) do
            var:setColor(cc.c3b(255,255,255))
            var:setEnabled(true)
            if var:isBright() then
                isHave = true
            end
        end     
        if isHave == false then
            items[1]:setBright(true)
            local uiText_desc = ccui.Helper:seekWidgetByName(items[1],"Text_desc")
            if uiText_desc ~= nil then 
                uiText_desc:setTextColor(cc.c3b(238,105,40))
            end
        end                  
    end)

    if self.recordCreateParameter["bPlayerCount"] ~= nil and self.recordCreateParameter["bPlayerCount"] ~= 2 then
        for key, var in pairs(items) do 
            var:setBright(false)
            var:setEnabled(false)
            local uiText_desc = ccui.Helper:seekWidgetByName(var,"Text_desc")
            if uiText_desc ~= nil then 
                uiText_desc:setTextColor(cc.c3b(140,102,57))
            end
            var:setColor(cc.c3b(170,170,170))
        end
    elseif self.recordCreateParameter["bPlayerCount"] ~= nil and self.recordCreateParameter["bPlayerCount"] == 2 then
        if self.recordCreateParameter["bMinLost"] ~= nil and self.recordCreateParameter["bMinLost"] == 20 then
            items[1]:setBright(true)        
            local uiText_desc = ccui.Helper:seekWidgetByName(items[1],"Text_desc")
            if uiText_desc ~= nil then 
                uiText_desc:setTextColor(cc.c3b(238,105,40))
            end
        elseif self.recordCreateParameter["bMinLost"] ~= nil and self.recordCreateParameter["bMinLost"] == 30 then
            items[2]:setBright(true)        
            local uiText_desc = ccui.Helper:seekWidgetByName(items[2],"Text_desc")
            if uiText_desc ~= nil then 
                uiText_desc:setTextColor(cc.c3b(238,105,40))
            end
        end
    else
        for key, var in pairs(items) do 
            var:setBright(false)
            var:setEnabled(false)
            local uiText_desc = ccui.Helper:seekWidgetByName(var,"Text_desc")
            if uiText_desc ~= nil then 
                uiText_desc:setTextColor(cc.c3b(140,102,57))
            end
            var:setColor(cc.c3b(170,170,170))
        end
    end

    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(13),"ListView_parameter"):getItems()
    Common:addCheckTouchEventListener(items,false,function(index) 
		if index == 1  then
			local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(11), "ListView_parameter"):getItems()
			items[1]:setBright(false)
			local uiText_desc = ccui.Helper:seekWidgetByName(items[1], "Text_desc")
			if uiText_desc ~= nil then
				uiText_desc:setTextColor(cc.c3b(140,102,57))
			end
			items[2]:setBright(false)
			local uiText_desc = ccui.Helper:seekWidgetByName(items[2], "Text_desc")
			if uiText_desc ~= nil then
				uiText_desc:setTextColor(cc.c3b(140,102,57))
			end
        end   
        if index == 1  then
			local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(12), "ListView_parameter"):getItems()
			items[1]:setBright(false)
			local uiText_desc = ccui.Helper:seekWidgetByName(items[1], "Text_desc")
			if uiText_desc ~= nil then
				uiText_desc:setTextColor(cc.c3b(140,102,57))
			end
			items[2]:setBright(false)
			local uiText_desc = ccui.Helper:seekWidgetByName(items[2], "Text_desc")
			if uiText_desc ~= nil then
				uiText_desc:setTextColor(cc.c3b(140,102,57))
			end
        end      
        local isHave = false
        local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(14),"ListView_parameter"):getItems()        
        for key, var in pairs(items) do
            var:setColor(cc.c3b(255,255,255))
            var:setEnabled(true)
            if var:isBright() then
                isHave = true
            end
        end    
        if isHave == false then
            items[1]:setBright(true)
            local uiText_desc = ccui.Helper:seekWidgetByName(items[1],"Text_desc")
            if uiText_desc ~= nil then 
                uiText_desc:setTextColor(cc.c3b(238,105,40))
            end
        end                    
    end)
    if self.recordCreateParameter["bPlayerCount"] ~= nil and self.recordCreateParameter["bPlayerCount"] ~= 2 then
        for key, var in pairs(items) do 
            var:setBright(false)
            var:setEnabled(false)
            local uiText_desc = ccui.Helper:seekWidgetByName(var,"Text_desc")
            if uiText_desc ~= nil then 
                uiText_desc:setTextColor(cc.c3b(140,102,57))
            end
            var:setColor(cc.c3b(170,170,170))
        end
    elseif self.recordCreateParameter["bPlayerCount"] ~= nil and self.recordCreateParameter["bPlayerCount"] == 2 then
        if ( self.recordCreateParameter["bMinLost"] ~= nil and  self.recordCreateParameter["bMinLostCell"] ~= nil  ) 
        and ( self.recordCreateParameter["bMinLost"] == 0 and  self.recordCreateParameter["bMinLostCell"] ~= 1  ) then
            items[1]:setBright(true)        
            local uiText_desc = ccui.Helper:seekWidgetByName(items[1],"Text_desc")
            if uiText_desc ~= nil then 
                uiText_desc:setTextColor(cc.c3b(238,105,40))
            end
        end
    else
        for key, var in pairs(items) do 
            var:setBright(false)
            var:setEnabled(false)
            local uiText_desc = ccui.Helper:seekWidgetByName(var,"Text_desc")
            if uiText_desc ~= nil then 
                uiText_desc:setTextColor(cc.c3b(140,102,57))
            end
            var:setColor(cc.c3b(170,170,170))
        end
    end

    --选择倍数
    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(14),"ListView_parameter"):getItems()
    Common:addCheckTouchEventListener(items)
  
    if self.recordCreateParameter["bPlayerCount"] ~= nil and self.recordCreateParameter["bPlayerCount"] ~= 2 then
        for key, var in pairs(items) do 
            var:setBright(false)
            var:setEnabled(false)
            local uiText_desc = ccui.Helper:seekWidgetByName(var,"Text_desc")
            if uiText_desc ~= nil then 
                uiText_desc:setTextColor(cc.c3b(140,102,57))
            end
            var:setColor(cc.c3b(170,170,170))
        end
    elseif ( self.recordCreateParameter["bMinLost"] ~= nil and  self.recordCreateParameter["bMinLostCell"] ~= nil  ) 
    and ( self.recordCreateParameter["bMinLost"] == 0 and  self.recordCreateParameter["bMinLostCell"] == 1  ) then 
        for key, var in pairs(items) do 
            var:setBright(false)
            var:setEnabled(false)
            local uiText_desc = ccui.Helper:seekWidgetByName(var,"Text_desc")
            if uiText_desc ~= nil then 
                uiText_desc:setTextColor(cc.c3b(140,102,57))
            end
            var:setColor(cc.c3b(170,170,170))
        end
    elseif self.recordCreateParameter["bMinLostCell"] ~= nil and self.recordCreateParameter["bMinLostCell"] == 3 then
        items[2]:setBright(true)        
        local uiText_desc = ccui.Helper:seekWidgetByName(items[2],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(238,105,40))
        end
    elseif self.recordCreateParameter["bMinLostCell"] ~= nil and self.recordCreateParameter["bMinLostCell"] == 4 then
        items[3]:setBright(true)        
        local uiText_desc = ccui.Helper:seekWidgetByName(items[3],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(238,105,40))
        end  
    elseif self.recordCreateParameter["bMinLostCell"] ~= nil and self.recordCreateParameter["bMinLostCell"] == 2 then 
        items[1]:setBright(true)        
        local uiText_desc = ccui.Helper:seekWidgetByName(items[1],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(238,105,40))
        end
    else
        for key, var in pairs(items) do 
            var:setBright(false)
            var:setEnabled(false)
            local uiText_desc = ccui.Helper:seekWidgetByName(var,"Text_desc")
            if uiText_desc ~= nil then 
                uiText_desc:setTextColor(cc.c3b(140,102,57))
            end
            var:setColor(cc.c3b(170,170,170))
        end    
    end

    --随机庄
    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(15),"ListView_parameter"):getItems()
    Common:addCheckTouchEventListener(items,true)
    if self.recordCreateParameter["bStartBanker"] ~= nil and self.recordCreateParameter["bStartBanker"] == 1 then
        items[1]:setBright(false)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[1],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(140,102,57))
        end
    else
        items[1]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[1],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(238,105,40))
        end
    end
    if self.recordCreateParameter["bFangPao"] ~= nil and self.recordCreateParameter["bFangPao"] == 0 then 
        items[2]:setVisible(false)
        items[2]:setBright(false)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[2],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(140,102,57))
        end
    elseif self.recordCreateParameter["bStopCardGo"] == nil or self.recordCreateParameter["bStopCardGo"] ~= 0 then   --可胡示众牌
        items[2]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[2],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(238,105,40))
        end
    end


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
    local uiListView_parameter = uiListView_parameterList:getItem(3)
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
    if isFound == false and items[1]:isVisible() and self.recordCreateParameter["wGameCount"] == nil then
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

    local uiListView_parameter = uiListView_parameterList:getItem(4)
    uiListView_parameter:setVisible(true)
    local items = ccui.Helper:seekWidgetByName(uiListView_parameter,"ListView_parameter"):getItems()
    local isFound = false
    local data = self.tableFriendsRoomParams[4]
    if data then
        local uiText_desc = ccui.Helper:seekWidgetByName(items[1],"Text_desc")
        uiText_desc:setString(string.format("%d局",data.wGameCount))
        local uiText_addition = ccui.Helper:seekWidgetByName(items[1],"Text_addition")
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
            items[1]:setBright(true)
            isFound = true
            local uiText_desc = ccui.Helper:seekWidgetByName(items[1],"Text_desc")
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
        items[1]:setBright(false)
        items[1]:setVisible(false)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[1],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(140,102,57))
        end
        local uiText_addition = ccui.Helper:seekWidgetByName(items[1],"Text_addition")
        if uiText_addition ~= nil then 
        uiText_addition:setTextColor(cc.c3b(140,102,57))
        end
    end
end

function RoomCreateLayer:onEventCreate(nTableType)
    NetMgr:getGameInstance():closeConnect()
    local uiListView_parameterList = ccui.Helper:seekWidgetByName(self.root,"ListView_parameterList")
    local tableParameter = {}    
    
    --选择人数
    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(0),"ListView_parameter"):getItems()
    if items[1]:isBright() then
        tableParameter.bPlayerCount = 2
        tableParameter.bPlayerCountType = 0
    elseif items[2]:isBright() then
        tableParameter.bPlayerCount = 3
        tableParameter.bPlayerCountType = 0
    elseif items[3]:isBright() then
            tableParameter.bPlayerCount = 4
            tableParameter.bPlayerCountType = 1
    else
        return
    end

    --选择张数
    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(1),"ListView_parameter"):getItems()
    if tableParameter.bPlayerCount == 2 then 
        if items[1]:isBright() then
            tableParameter.bDeathCard = 1 
        elseif items[2]:isBright() then
            tableParameter.bDeathCard = 0
        end 
        tableParameter.bCardCount21 = 0
    elseif tableParameter.bPlayerCount == 3 then 
        if items[1]:isBright() then
            tableParameter.bCardCount21 = 0
        elseif items[2]:isBright() then
            tableParameter.bCardCount21 = 1
        end 
        tableParameter.bDeathCard = 0
    else        
        tableParameter.bDeathCard = 0
        tableParameter.bCardCount21 = 0
    end         


    --选择翻醒
    tableParameter.FanXing = {}
    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(2),"ListView_parameter"):getItems()
    if items[1]:isBright() then
        tableParameter.FanXing.bType = 0
        tableParameter.FanXing.bCount = 0
    elseif items[2]:isBright() then
        tableParameter.FanXing.bType = 2
        tableParameter.FanXing.bCount = 1
    elseif items[3]:isBright() then
        tableParameter.FanXing.bType = 3
        tableParameter.FanXing.bCount = 1
    else
        return
    end
    if tableParameter.FanXing.bType ~= 0 then
	tableParameter.FanXing.bAddTun = 1
    else
        tableParameter.FanXing.bAddTun = 0
    end

    --选择局数
    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(3),"ListView_parameter"):getItems()
    if items[1]:isBright() and self.tableFriendsRoomParams[1] then
        tableParameter.wGameCount = self.tableFriendsRoomParams[1].wGameCount
    elseif items[2]:isBright() and self.tableFriendsRoomParams[2] then
        tableParameter.wGameCount = self.tableFriendsRoomParams[2].wGameCount
    elseif items[3]:isBright() and self.tableFriendsRoomParams[3] then
        tableParameter.wGameCount = self.tableFriendsRoomParams[3].wGameCount
    end

    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(4),"ListView_parameter"):getItems()
    if items[1]:isBright() and self.tableFriendsRoomParams[4] then
        tableParameter.wGameCount = self.tableFriendsRoomParams[4].wGameCount
    end

    --结算囤数
    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(5),"ListView_parameter"):getItems()
    if items[1]:isBright() then
        tableParameter.bSettlement = 1
    elseif items[2]:isBright() then
        tableParameter.bSettlement = 2
    else
        return
    end
    --选择玩法
    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(6),"ListView_parameter"):getItems()
    if items[1]:isBright() then
        tableParameter.bCanHuXi = 6
    elseif items[2]:isBright() then
        tableParameter.bCanHuXi = 9
    elseif items[3]:isBright() then
        tableParameter.bCanHuXi = 15
    else
        return
    end
    --必胡选项
    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(7),"ListView_parameter"):getItems()
    if items[1]:isBright() then
        tableParameter.bHuType = 1
    elseif items[2]:isBright() then     --点炮必胡
        tableParameter.bHuType = 2
    else
        return
    end


    --名堂
    tableParameter.dwMingTang = 0x0
    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(8),"ListView_parameter"):getItems()

    if items[1]:isBright() then
        tableParameter.bFangPao = 1
    else
        tableParameter.bFangPao = 0
    end

    if items[2]:isBright() then
        tableParameter.bStartTun = 2
    else
        tableParameter.bStartTun = 1
    end

    if items[3]:isBright() then
        tableParameter.bYiWuShi = 1
    else
        tableParameter.bYiWuShi = 0
    end

    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(9),"ListView_parameter"):getItems() 
    if items[1]:isBright() then
        tableParameter.dwMingTang = Bit:_or(tableParameter.dwMingTang,0x02)
        tableParameter.dwMingTang = Bit:_or(tableParameter.dwMingTang,0x04)
        tableParameter.dwMingTang = Bit:_or(tableParameter.dwMingTang,0x08)
    end
    if items[2]:isBright() then
        tableParameter.bDelShowCardHu = 0
    else
        tableParameter.bDelShowCardHu = 1

    end

    if items[3]:isBright() then   -- 飘胡
        tableParameter.bPiaoHu = 1
    else
        tableParameter.bPiaoHu = 0
    end

    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(10),"ListView_parameter"):getItems() 
    if items[1]:isBright() then
        tableParameter.dwMingTang = Bit:_or(tableParameter.dwMingTang,0x0D00)
    end

    if items[2]:isBright() then
        tableParameter.dwMingTang = Bit:_or(tableParameter.dwMingTang,0x0C0)
    end
    if items[3]:isBright() then
        tableParameter.dwMingTang = Bit:_or(tableParameter.dwMingTang,0x20)
    end

    tableParameter.bMinLost = 0
    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(11),"ListView_parameter"):getItems() 
    if items[1]:isBright() then
        tableParameter.bMinLost = 0
    elseif items[2]:isBright() then
        tableParameter.bMinLost = 10
    end

    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(12),"ListView_parameter"):getItems() 
    if items[1]:isBright() then
        tableParameter.bMinLost = 20
    elseif items[2]:isBright() then
        tableParameter.bMinLost = 30
    end

    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(13),"ListView_parameter"):getItems() 
    if items[1]:isBright() then
        tableParameter.bMinLost = 0
    end

    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(14),"ListView_parameter"):getItems() 
    if items[1]:isBright() then
        tableParameter.bMinLostCell = 2
    elseif items[2]:isBright() then
        tableParameter.bMinLostCell = 3
    elseif items[3]:isBright() then
        tableParameter.bMinLostCell = 4
    else
        tableParameter.bMinLostCell = 1
    end 

    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(15),"ListView_parameter"):getItems()
    if items[1]:isBright() then
        tableParameter.bStartBanker = 0
    else
        tableParameter.bStartBanker = 1
    end

    if items[2]:isBright() then
        tableParameter.bStopCardGo = 1
    else
        tableParameter.bStopCardGo = 0
    end
    
    tableParameter.dwMingTang = Bit:_or(tableParameter.dwMingTang,0x01)   --默认自摸翻倍
    tableParameter.bLaiZiCount = 0
    tableParameter.bLiangPai = 0
    tableParameter.bSocreType = 0
    tableParameter.bMaxLost = 0
    self.nTableType = nTableType

   if self.showType ~= 2 and (nTableType == TableType_FriendRoom or nTableType == TableType_HelpRoom) then
        --普通创房和代开需要判断金币
        local uiListView_parameterList = ccui.Helper:seekWidgetByName(self.root,"ListView_parameterList")
        local uiListView_parameter = uiListView_parameterList:getItem(3)
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

            local uiListView_parameter = uiListView_parameterList:getItem(4)
            local items = ccui.Helper:seekWidgetByName(uiListView_parameter,"ListView_parameter"):getItems()
            if items[1]:isBright() then
                local data = self.tableFriendsRoomParams[4]
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