--[[
*名称:NewClubDefendLayer
*描述:防沉迷记录
*作者:admin
*创建日期:2019-11-13 14:39:02
*修改日期:
]]

local EventMgr          = require("common.EventMgr")
local EventType         = require("common.EventType")
local NetMgr            = require("common.NetMgr")
local NetMsgId          = require("common.NetMsgId")
local StaticData        = require("app.static.StaticData")
local UserData          = require("app.user.UserData")
local Common            = require("common.Common")
local Default           = require("common.Default")
local GameConfig        = require("common.GameConfig")
local Log               = require("common.Log")

local NewClubDefendLayer = class("NewClubDefendLayer", cc.load("mvc").ViewBase)

function NewClubDefendLayer:onConfig()
    self.widget         = {
        {"Button_close", "onClose"},
        {"Button_defendList", "onDefendList"},
        {"Button_refreshTotal", "onRefreshTotal"},
        {"Button_limitList", "onLimitList"},
        {"Button_errorList", "onErrorList"},
        {"Button_twoTotal", "onTwoTotal"},
        {"Button_threeTotal", "onThreeTotal"},
        {"Button_purviewSet", "onPurviewSet"},
        {"Text_timeNode"},
        {"Image_left", "onImageLeft"},
        {"Image_right", "onImageRight"},
        {"Text_day_left"},
        {"Text_day_right"},
        {"Button_search", "onSearch"},
        {"Image_findNode"},
        {"TextField_memId"},
        {"Button_findMem", "onFindMem"},
        {"Image_bgFrame"},
        {"Panel_defendList"},
        {"Text_cmListTotal"},
        {"Button_cmLast", "onCMLast"},
        {"Image_cmList"},
        {"ListView_cmFloor1"},
        {"ListView_cmFloor2"},
        {"ListView_cmFloor3"},
        {"Panel_cmItem"},
        {"Panel_refreshTotal"},
        {"Image_refreshFrame"},
        {"Text_refreshTotalNum"},
        {"ListView_refreshList"},
        {"Image_refreshPushFrame"},
        {"ListView_refreshPushLog"},
        {"Button_refreshLast", "onRefreshLast"},
        {"Panel_refreshItem"},
        {"Panel_refreshPushItem"},
        {"Panel_limitList"},
        {"ListView_limit"},
        {"Panel_limitItem"},
        {"Panel_errorList"},
        {"Image_errorList"},
        {"ListView_error"},
        {"Image_errorPushList"},
        {"Text_errorNum"},
        {"ListView_errorPush"},
        {"Panel_errorPushItem"},
        {"Button_errorLast", "onErrorLast"},
        {"Panel_twoTotal"},
        {"Image_twoFrame"},
        {"Text_totalNum"},
        {"Text_noTotalNum"},
        {"ListView_twoTotal"},
        {"Image_twoPushFrame"},
        {"ListView_twoPushLog"},
        {"Button_twoLast", "onTwoLast"},
        {"Panel_twoTotalItem"},
        {"Panel_errorItem"},
    }
    self.searchNum = 0
    self.beganTime = Common:getStampDay(os.time() ,true)
    self.endTime = Common:getStampDay(os.time() ,false)
end

function NewClubDefendLayer:onEnter()
	EventMgr:registListener(EventType.RET_CLUB_ANTI_LIST,self,self.RET_CLUB_ANTI_LIST)
	EventMgr:registListener(EventType.RET_CLUB_ANTI_LIST_FINISH,self,self.RET_CLUB_ANTI_LIST_FINISH)
	EventMgr:registListener(EventType.RET_CLUB_SETTING_ANTI_MEMBER,self,self.RET_CLUB_SETTING_ANTI_MEMBER)
	EventMgr:registListener(EventType.RET_CLUB_ANTI_LIMIT,self,self.RET_CLUB_ANTI_LIMIT)
	EventMgr:registListener(EventType.RET_CLUB_SETTING_ANTI_LIMIT,self,self.RET_CLUB_SETTING_ANTI_LIMIT)
	EventMgr:registListener(EventType.RET_CLUB_ANTI_REFRESH_LOG,self,self.RET_CLUB_ANTI_REFRESH_LOG)
	EventMgr:registListener(EventType.RET_CLUB_ANTI_REFRESH_LOG_FINISH,self,self.RET_CLUB_ANTI_REFRESH_LOG_FINISH)
end

function NewClubDefendLayer:onExit()
	EventMgr:unregistListener(EventType.RET_CLUB_ANTI_LIST,self,self.RET_CLUB_ANTI_LIST)
	EventMgr:unregistListener(EventType.RET_CLUB_ANTI_LIST_FINISH,self,self.RET_CLUB_ANTI_LIST_FINISH)
	EventMgr:unregistListener(EventType.RET_CLUB_SETTING_ANTI_MEMBER,self,self.RET_CLUB_SETTING_ANTI_MEMBER)
	EventMgr:unregistListener(EventType.RET_CLUB_ANTI_LIMIT,self,self.RET_CLUB_ANTI_LIMIT)
	EventMgr:unregistListener(EventType.RET_CLUB_SETTING_ANTI_LIMIT,self,self.RET_CLUB_SETTING_ANTI_LIMIT)
	EventMgr:unregistListener(EventType.RET_CLUB_ANTI_REFRESH_LOG,self,self.RET_CLUB_ANTI_REFRESH_LOG)
	EventMgr:unregistListener(EventType.RET_CLUB_ANTI_REFRESH_LOG_FINISH,self,self.RET_CLUB_ANTI_REFRESH_LOG_FINISH)
end

function NewClubDefendLayer:onCreate(param)
	self.clubData = param[1]
	UserData.Guild:getClubAntiLimit(self.clubData.dwClubID, UserData.User.userID)
	self:switchType(1)
	self:updateInputStr()
	self.ListView_cmFloor1:addScrollViewEventListener(handler(self, self.listViewEventListen))
	self.ListView_cmFloor2:addScrollViewEventListener(handler(self, self.listViewEventListen))
	self.ListView_cmFloor3:addScrollViewEventListener(handler(self, self.listViewEventListen))
	self.ListView_refreshList:addScrollViewEventListener(handler(self, self.listViewEventListen))
	self.ListView_limit:addScrollViewEventListener(handler(self, self.listViewEventListen))
	self.ListView_error:addScrollViewEventListener(handler(self, self.listViewEventListen))
	self.ListView_errorPush:addScrollViewEventListener(handler(self, self.listViewEventListen))
	self.ListView_twoTotal:addScrollViewEventListener(handler(self, self.listViewEventListen))
	self.ListView_refreshPushLog:addScrollViewEventListener(handler(self, self.listViewRefreshPushLogEventListen))
	self.ListView_twoPushLog:addScrollViewEventListener(handler(self, self.listViewTwoPushEventListen))

	if UserData.User.userID == self.clubData.dwUserID or self:isAdmin(UserData.User.userID)  then
		self.Button_purviewSet:setVisible(true)
	else
		self.Button_purviewSet:setVisible(false)
	end
	self.Button_limitList:setVisible(false)
	self.Button_errorList:setVisible(false)
	self.Button_twoTotal:setVisible(false)
	self.Button_threeTotal:setVisible(false)
end

function NewClubDefendLayer:onClose()
    self:removeFromParent()
end

function NewClubDefendLayer:updateInputStr()
    local leftTime = self:getFrmatYear(self.beganTime)
    local rightTime = self:getFrmatYear(self.endTime)
    self.Text_day_left:setString(leftTime)
    self.Text_day_right:setString(rightTime)    
end

function NewClubDefendLayer:getFrmatYear( time )
    return  (os.date('%Y',time).."-" .. os.date('%m',time).."-"..os.date('%d',time))
end

function NewClubDefendLayer:onImageLeft()
	local timeNode = require("app.MyApp"):create(self.beganTime,handler(self,self.leftNodeChange)):createView("TimeNode")
    self.Image_left:addChild(timeNode)
    timeNode:setPosition(80,-90)
end

function NewClubDefendLayer:onImageRight()
	local timeNode = require("app.MyApp"):create(self.endTime,handler(self,self.rightNodeChange)):createView("TimeNode")
    self.Image_right:addChild(timeNode)
    timeNode:setPosition(80,-90)
end

function NewClubDefendLayer:leftNodeChange( time,stampMin,stampMax )
    self.Text_day_left:setString(time)
    self.beganTime = stampMin
end

function NewClubDefendLayer:rightNodeChange( time,stampMin,stampMax )
    self.Text_day_right:setString(time)
    self.endTime = stampMax
end

function NewClubDefendLayer:onSearch()
	if self.searchNum == 0 then
        self.searchNum = 5
        self:research()
        schedule(self.Button_search,function()
            self.searchNum = self.searchNum - 1
            if self.searchNum <= 0 then
                self.searchNum = 0
                self.Button_search:stopAllActions()
            end
        end,1)
    else
        require("common.MsgBoxLayer"):create(0,self,self.searchNum .. "秒之后查询")
    end
end

function NewClubDefendLayer:research()
	if self.curDefendPage == 2 then
		self.ListView_refreshList:removeAllItems()
		self.defendIndex = 1
		self.defendState = 0
		self.curSelUserID = UserData.User.userID
		self.curTargetID = tonumber(self.TextField_memId:getString()) or 0
		UserData.Guild:getClubAntiMemberInfo(self.clubData.dwClubID, self.curSelUserID, 1, self.curTargetID, self.beganTime, self.endTime, self.defendIndex)

	elseif self.curDefendPage == 5 then
		self.ListView_twoTotal:removeAllItems()
		self.defendIndex = 1
		self.defendState = 0
		self.curSelUserID = UserData.User.userID
		self.curTargetID = tonumber(self.TextField_memId:getString()) or 0
		UserData.Guild:getClubAntiMemberInfo(self.clubData.dwClubID, self.curSelUserID, 5, self.curTargetID, self.beganTime, self.endTime, self.defendIndex)

	elseif self.curDefendPage == 6 then
		self.ListView_twoTotal:removeAllItems()
		self.defendIndex = 1
		self.defendState = 0
		self.curSelUserID = UserData.User.userID
		self.curTargetID = tonumber(self.TextField_memId:getString()) or 0
		UserData.Guild:getClubAntiMemberInfo(self.clubData.dwClubID, self.curSelUserID, 6, self.curTargetID, self.beganTime, self.endTime, self.defendIndex)
	end
end

function NewClubDefendLayer:onFindMem()
	local dwUserID = tonumber(self.TextField_memId:getString())
	if not dwUserID then
		require("common.MsgBoxLayer"):create(0,nil,"输入玩家ID错误！")
		return
	end

	if self.curDefendPage == 1 then
		self:setCurSelFloorIdx(1)
		self.ListView_cmFloor1:removeAllItems()
		self.defendIndex = 1
		self.defendState = 0
		self.curSelUserID = UserData.User.userID
		self.curTargetID = dwUserID
		UserData.Guild:getClubAntiMemberInfo(self.clubData.dwClubID, self.curSelUserID, 0, self.curTargetID, 0, 0, self.defendIndex)
	elseif self.curDefendPage == 3 then
		self.ListView_refreshList:removeAllItems()
		self.defendIndex = 1
		self.defendState = 0
		self.curSelUserID = UserData.User.userID
		self.curTargetID = dwUserID
		UserData.Guild:getClubAntiMemberInfo(self.clubData.dwClubID, self.curSelUserID, 1, self.curTargetID, self.beganTime, self.endTime, self.defendIndex)
	elseif self.curDefendPage == 3 then
		self.ListView_limit:removeAllItems()
		self.defendIndex = 1
		self.defendState = 0
		self.curSelUserID = UserData.User.userID
		self.curTargetID = dwUserID
		UserData.Guild:getClubAntiMemberInfo(self.clubData.dwClubID, self.curSelUserID, 2, self.curTargetID, 0, 0, self.defendIndex)
	elseif self.curDefendPage == 4 then
		self.ListView_error:removeAllItems()
		self.defendIndex = 1
		self.defendState = 0
		self.curSelUserID = UserData.User.userID
		self.curTargetID = dwUserID
		UserData.Guild:getClubAntiMemberInfo(self.clubData.dwClubID, self.curSelUserID, 3, self.curTargetID, 0, 0, self.defendIndex)
	elseif self.curDefendPage == 5 then
		self.ListView_twoTotal:removeAllItems()
		self.defendIndex = 1
		self.defendState = 0
		self.curSelUserID = UserData.User.userID
		self.curTargetID = dwUserID
		UserData.Guild:getClubAntiMemberInfo(self.clubData.dwClubID, self.curSelUserID, 5, self.curTargetID, self.beganTime, self.endTime, self.defendIndex)
	elseif self.curDefendPage == 6 then
		self.ListView_twoTotal:removeAllItems()
		self.defendIndex = 1
		self.defendState = 0
		self.curSelUserID = UserData.User.userID
		self.curTargetID = dwUserID
		UserData.Guild:getClubAntiMemberInfo(self.clubData.dwClubID, self.curSelUserID, 6, self.curTargetID, self.beganTime, self.endTime, self.defendIndex)
	end
end

function NewClubDefendLayer:onDefendList()
	self:switchType(1)
end

function NewClubDefendLayer:onRefreshTotal()
	self:switchType(2)
end

function NewClubDefendLayer:onLimitList()
	self:switchType(3)
end

function NewClubDefendLayer:onErrorList()
	self:switchType(4)
end

function NewClubDefendLayer:onTwoTotal()
	self:switchType(5)
end

function NewClubDefendLayer:onThreeTotal()
	self:switchType(6)
end

function NewClubDefendLayer:onPurviewSet()
	self.clubData.curClubAntiLimit = self.curClubAntiLimit
	self:addChild(require("app.MyApp"):create(self.clubData, nil, 2, function(value) 
		UserData.Guild:setClubAntiLimit(self.clubData.dwClubID, UserData.User.userID, 0, value)
	end):createView("NewClubSetPercentLayer"))
end

function NewClubDefendLayer:onCMLast()
	local curIdx = self:getCurSelFloorIdx()
	local lastIdx = curIdx - 1
	if lastIdx <= 1 then
		self.Button_cmLast:setVisible(false)
	end
	self['ListView_cmFloor'..curIdx]:setVisible(false)
    self['ListView_cmFloor'..lastIdx]:setVisible(true)
end

function NewClubDefendLayer:onRefreshLast()
	self.Image_refreshFrame:setVisible(true)
	self.Image_refreshPushFrame:setVisible(false)
end

function NewClubDefendLayer:onErrorLast()
	self.Image_errorList:setVisible(true)
	self.Image_errorPushList:setVisible(false)
end

function NewClubDefendLayer:onTwoLast()
	self.Image_twoFrame:setVisible(true)
	self.Image_twoPushFrame:setVisible(false)
end

function NewClubDefendLayer:listViewEventListen(sender, evenType)
    if evenType == ccui.ScrollviewEventType.scrollToBottom then
        if self.defendState == 1 then
            self.defendState = 0
            local pageType = self.curDefendPage
            if self.curDefendPage <= 3 then
            	pageType = self.curDefendPage - 1
            elseif self.curDefendPage == 4 then
            	if not self.Image_errorPushList:isVisible() then
            		pageType = self.curDefendPage - 1
            	end
            end
            print('listViewEventListen::--->',self.clubData.dwClubID, self.curSelUserID, pageType, self.curTargetID, self.beganTime, self.endTime, self.defendIndex)
            UserData.Guild:getClubAntiMemberInfo(self.clubData.dwClubID, self.curSelUserID, pageType, self.curTargetID, self.beganTime, self.endTime, self.defendIndex)
        end
    end
end

function NewClubDefendLayer:listViewRefreshPushLogEventListen(sender, evenType)
	if evenType == ccui.ScrollviewEventType.scrollToBottom then
		if self.logPageState == 1 then
	    	self.logPageState = 0
	    	UserData.Guild:getClubAntiLog(self.clubData.dwClubID, self.curLogUserID, 0, self.beganTime, self.endTime, self.logPageIndex)
		end
	end
end

function NewClubDefendLayer:listViewTwoPushEventListen(sender, evenType)
	if evenType == ccui.ScrollviewEventType.scrollToBottom then
		if self.logPageState == 1 then
	    	self.logPageState = 0
	    	UserData.Guild:getClubAntiLog(self.clubData.dwClubID, self.curLogUserID, 1, self.beganTime, self.endTime, self.logPageIndex)
		end
	end
end

function NewClubDefendLayer:isAdmin(userid, adminData)
    adminData = adminData or self.clubData.dwAdministratorID
    for i,v in ipairs(adminData or {}) do
        if v == userid then
            return true
        end
    end
    return false
end

-- 1防沉迷列表 2刷新统计 3限制列表 4异常列表 5二级统计 6三级统计
function NewClubDefendLayer:switchType(itype)
	self.curDefendPage = itype
	local items = self.Image_bgFrame:getChildren()
	for i,v in ipairs(items) do
		v:setVisible(false)
	end

	if itype == 1 then
		self.Button_defendList:setBright(false)
		self.Button_refreshTotal:setBright(true)
		self.Button_limitList:setBright(true)
		self.Button_errorList:setBright(true)
		self.Button_twoTotal:setBright(true)
		self.Button_threeTotal:setBright(true)
		self.Panel_defendList:setVisible(true)
		self.Text_timeNode:setVisible(false)
		self.Button_cmLast:setVisible(false)
		self:setCurSelFloorIdx(1)
		self.ListView_cmFloor1:removeAllItems()
		self.defendIndex = 1
		self.defendState = 0
		self.curSelUserID = UserData.User.userID
		self.curTargetID = 0
		UserData.Guild:getClubAntiMemberInfo(self.clubData.dwClubID, self.curSelUserID, 0, self.curTargetID, 0, 0, self.defendIndex)
		
	elseif itype == 2 then
		self.Button_defendList:setBright(true)
		self.Button_refreshTotal:setBright(false)
		self.Button_limitList:setBright(true)
		self.Button_errorList:setBright(true)
		self.Button_twoTotal:setBright(true)
		self.Button_threeTotal:setBright(true)
		self.Panel_refreshTotal:setVisible(true)
		self.Image_refreshFrame:setVisible(true)
		self.Image_refreshPushFrame:setVisible(false)
		self.Text_timeNode:setVisible(true)
		self.ListView_refreshList:removeAllItems()
		self.defendIndex = 1
		self.defendState = 0
		self.curSelUserID = UserData.User.userID
		self.curTargetID = 0
		UserData.Guild:getClubAntiMemberInfo(self.clubData.dwClubID, self.curSelUserID, 1, self.curTargetID, self.beganTime, self.endTime, self.defendIndex)
	
	elseif itype == 3 then
		self.Button_defendList:setBright(true)
		self.Button_refreshTotal:setBright(true)
		self.Button_limitList:setBright(false)
		self.Button_errorList:setBright(true)
		self.Button_twoTotal:setBright(true)
		self.Button_threeTotal:setBright(true)
		self.Panel_limitList:setVisible(true)
		self.Text_timeNode:setVisible(false)
		self.ListView_limit:removeAllItems()
		self.defendIndex = 1
		self.defendState = 0
		self.curSelUserID = UserData.User.userID
		self.curTargetID = 0
		UserData.Guild:getClubAntiMemberInfo(self.clubData.dwClubID, self.curSelUserID, 2, self.curTargetID, 0, 0, self.defendIndex)

	elseif itype == 4 then
		self.Button_defendList:setBright(true)
		self.Button_refreshTotal:setBright(true)
		self.Button_limitList:setBright(true)
		self.Button_errorList:setBright(false)
		self.Button_twoTotal:setBright(true)
		self.Button_threeTotal:setBright(true)
		self.Panel_errorList:setVisible(true)
		self.Image_errorList:setVisible(true)
		self.Image_errorPushList:setVisible(false)
		self.Text_timeNode:setVisible(false)
		self.ListView_error:removeAllItems()
		self.defendIndex = 1
		self.defendState = 0
		self.curSelUserID = UserData.User.userID
		self.curTargetID = 0
		UserData.Guild:getClubAntiMemberInfo(self.clubData.dwClubID, self.curSelUserID, 3, self.curTargetID, 0, 0, self.defendIndex)

	elseif itype == 5 then
		self.Button_defendList:setBright(true)
		self.Button_refreshTotal:setBright(true)
		self.Button_limitList:setBright(true)
		self.Button_errorList:setBright(true)
		self.Button_twoTotal:setBright(false)
		self.Button_threeTotal:setBright(true)
		self.Panel_twoTotal:setVisible(true)
		self.Image_twoFrame:setVisible(true)
		self.Image_twoPushFrame:setVisible(false)
		self.Text_timeNode:setVisible(true)
		self.ListView_twoTotal:removeAllItems()
		self.defendIndex = 1
		self.defendState = 0
		self.curSelUserID = UserData.User.userID
		self.curTargetID = 0
		UserData.Guild:getClubAntiMemberInfo(self.clubData.dwClubID, self.curSelUserID, 5, self.curTargetID, self.beganTime, self.endTime, self.defendIndex)

	elseif itype == 6 then
		self.Button_defendList:setBright(true)
		self.Button_refreshTotal:setBright(true)
		self.Button_limitList:setBright(true)
		self.Button_errorList:setBright(true)
		self.Button_twoTotal:setBright(true)
		self.Button_threeTotal:setBright(false)
		self.Panel_twoTotal:setVisible(true)
		self.Image_twoFrame:setVisible(true)
		self.Image_twoPushFrame:setVisible(false)
		self.Text_timeNode:setVisible(true)
		self.ListView_twoTotal:removeAllItems()
		self.defendIndex = 1
		self.defendState = 0
		self.curSelUserID = UserData.User.userID
		self.curTargetID = 0
		UserData.Guild:getClubAntiMemberInfo(self.clubData.dwClubID, self.curSelUserID, 6, self.curTargetID, self.beganTime, self.endTime, self.defendIndex)
	end
end

function NewClubDefendLayer:getCurSelFloorIdx()
	local items = self.Image_cmList:getChildren()
	for i,v in ipairs(items) do
		if v:isVisible() then
			return i
		end
	end
	return 1
end

function NewClubDefendLayer:setCurSelFloorIdx(idx)
	local items = self.Image_cmList:getChildren()
	for i,v in ipairs(items) do
		if i == idx then
			v:setVisible(true)
		else
			v:setVisible(false)
		end
	end
end

function NewClubDefendLayer:selectPage_1(data)
	self.Text_cmListTotal:setString(data.iTotalAntiValue)
	local idx = self:getCurSelFloorIdx()
    local item = self.Panel_cmItem:clone()
    self['ListView_cmFloor'..idx]:pushBackCustomItem(item)
    self['ListView_cmFloor'..idx]:refreshView()
    item:setName('CMItem_' .. data.dwUserID .. '_' .. idx)
    local Image_head = self:seekWidgetByNameEx(item, "Image_head")
    local Text_name = self:seekWidgetByNameEx(item, "Text_name")
    local Text_id = self:seekWidgetByNameEx(item, "Text_id")
    local Text_cmNum = self:seekWidgetByNameEx(item, "Text_cmNum")
    local Text_partnerName = self:seekWidgetByNameEx(item, "Text_partnerName")
    local Text_partnerId = self:seekWidgetByNameEx(item, "Text_partnerId")
    local Button_qxSet = self:seekWidgetByNameEx(item, "Button_qxSet")
    local Button_refresh = self:seekWidgetByNameEx(item, "Button_refresh")
    local Button_zj = self:seekWidgetByNameEx(item, "Button_zj")
    local Button_push = self:seekWidgetByNameEx(item, "Button_push")
    Text_name:setColor(cc.c3b(131, 88, 45))
    Text_id:setColor(cc.c3b(131, 88, 45))
    Text_cmNum:setColor(cc.c3b(131, 88, 45))
    Text_partnerName:setColor(cc.c3b(131, 88, 45))
    Text_partnerId:setColor(cc.c3b(131, 88, 45))
    Button_qxSet:getChildren()[1]:setColor(cc.c3b(131, 88, 45))
    Button_refresh:getChildren()[1]:setColor(cc.c3b(131, 88, 45))
    Button_zj:getChildren()[1]:setColor(cc.c3b(131, 88, 45))
    Common:requestUserAvatar(data.dwUserID, data.szLogoInfo, Image_head, "img")
    Text_name:setString(data.szNickName)
    Text_id:setString(data.dwUserID)
    Text_cmNum:setString(data.iAntiValue)
    item.data = data

    if data.dwPartnerID == 0 then
    	Text_partnerName:setString(self.clubData.szNickName)
    	Text_partnerId:setString(self.clubData.dwUserID)
    else
    	Text_partnerName:setString(data.szPartnerNickName)
    	Text_partnerId:setString(data.dwPartnerID)
    end
    
    if data.dwPartnerLevel == 0 or (idx > 1 and data.dwUserID == self.curSelUserID) then
    	Button_push:setVisible(false)
    end

    if self.curPartnerLevel == 0 and not self:isAdmin(UserData.User.userID) then
    	Button_qxSet:setVisible(false)
    	Button_refresh:setVisible(false)
    	Button_push:setVisible(false)
    end

    Common:addTouchEventListener(Button_qxSet, function()
    	self:addChild(require("app.MyApp"):create(data, nil, 1, function(value) 
    		UserData.Guild:setClubAntiMember(self.clubData.dwClubID, UserData.User.userID, 0, data.dwUserID, value)
    	end):createView("NewClubSetPercentLayer"))
	end)

	Common:addTouchEventListener(Button_refresh, function()
		require("common.MsgBoxLayer"):create(1,nil,"您确定刷新沉迷值吗？",function() 
            UserData.Guild:setClubAntiMember(self.clubData.dwClubID, UserData.User.userID, 1, data.dwUserID, 0)
        end)
	end)

	Common:addTouchEventListener(Button_zj, function()
		local box = require("app.MyApp"):create(self.clubData,self:isAdmin(UserData.User.userID),data.dwUserID):createView('NewClubRecord')
    	self:addChild(box)
	end)

	Common:addTouchEventListener(Button_push, function()
		self.Button_cmLast:setVisible(true)
		local idx = idx+1
		self:setCurSelFloorIdx(idx)
		self['ListView_cmFloor'..idx]:removeAllItems()
		self.defendIndex = 1
		self.defendState = 0
		self.curSelUserID = data.dwUserID
		UserData.Guild:getClubAntiMemberInfo(self.clubData.dwClubID, self.curSelUserID, 0, 0, 0, 0, self.defendIndex)
	end)
end

function NewClubDefendLayer:selectPage_2(data)
	self.Text_refreshTotalNum:setString(data.iAllUserRefreshAntiValue)
    local item = self.Panel_refreshItem:clone()
    self.ListView_refreshList:pushBackCustomItem(item)
    self.ListView_refreshList:refreshView()
    item:setName('RefreshTotal_' .. data.dwUserID)
    local Image_head = self:seekWidgetByNameEx(item, "Image_head")
    local Text_name = self:seekWidgetByNameEx(item, "Text_name")
    local Text_id = self:seekWidgetByNameEx(item, "Text_id")
    local Text_refreshNum = self:seekWidgetByNameEx(item, "Text_refreshNum")
    local Button_push = self:seekWidgetByNameEx(item, "Button_push")
    Text_name:setColor(cc.c3b(131, 88, 45))
    Text_id:setColor(cc.c3b(131, 88, 45))
    Text_refreshNum:setColor(cc.c3b(131, 88, 45))
    Common:requestUserAvatar(data.dwUserID, data.szLogoInfo, Image_head, "img")
    Text_name:setString(data.szNickName)
    Text_id:setString(data.dwUserID)
    Text_refreshNum:setString(data.iRefreshAntiValue)
    item.data = data

    Common:addTouchEventListener(Button_push, function()
    	self.ListView_refreshPushLog:removeAllItems()
    	self.Image_refreshFrame:setVisible(false)
    	self.Image_refreshPushFrame:setVisible(true)
    	self.logPageIndex = 1
    	self.logPageState = 0
    	self.curLogUserID = data.dwUserID
    	UserData.Guild:getClubAntiLog(self.clubData.dwClubID, self.curLogUserID, 0, self.beganTime, self.endTime, self.logPageIndex)
	end)
end

function NewClubDefendLayer:selectPage_3(data)
    local item = self.Panel_limitItem:clone()
    self.ListView_limit:pushBackCustomItem(item)
    self.ListView_limit:refreshView()
    item:setName('LimitList_' .. data.dwUserID)
    local Image_head = self:seekWidgetByNameEx(item, "Image_head")
    local Text_name = self:seekWidgetByNameEx(item, "Text_name")
    local Text_id = self:seekWidgetByNameEx(item, "Text_id")
    local Text_cmNum = self:seekWidgetByNameEx(item, "Text_cmNum")
    local Text_partnerName = self:seekWidgetByNameEx(item, "Text_partnerName")
    local Text_partnerId = self:seekWidgetByNameEx(item, "Text_partnerId")
    local Button_cancelLimit = self:seekWidgetByNameEx(item, "Button_cancelLimit")
    Button_cancelLimit:getChildren()[1]:setColor(cc.c3b(131, 88, 45))
    Text_name:setColor(cc.c3b(131, 88, 45))
    Text_id:setColor(cc.c3b(131, 88, 45))
    Text_cmNum:setColor(cc.c3b(131, 88, 45))
    Text_partnerName:setColor(cc.c3b(131, 88, 45))
    Text_partnerId:setColor(cc.c3b(131, 88, 45))
    Common:requestUserAvatar(data.dwUserID, data.szLogoInfo, Image_head, "img")
    Text_name:setString(data.szNickName)
    Text_id:setString(data.dwUserID)
    Text_cmNum:setString(data.iAntiValue)
    item.data = data

    if data.dwPartnerID == 0 then
    	Text_partnerName:setString(self.clubData.szNickName)
    	Text_partnerId:setString(self.clubData.dwUserID)
    else
    	Text_partnerName:setString(data.szPartnerNickName)
    	Text_partnerId:setString(data.dwPartnerID)
    end

    Common:addTouchEventListener(Button_cancelLimit, function()
		require("common.MsgBoxLayer"):create(1,nil,"您确定刷新沉迷值吗？",function() 
            UserData.Guild:setClubAntiMember(self.clubData.dwClubID, UserData.User.userID, 1, data.dwUserID, 0)
        end)
	end)
end

function NewClubDefendLayer:selectPage_4(data)
	local item = self.Panel_errorItem:clone()
    self.ListView_error:pushBackCustomItem(item)
    self.ListView_error:refreshView()
    item:setName('ErrorList_' .. data.dwUserID)
    local Image_head = self:seekWidgetByNameEx(item, "Image_head")
    local Text_name = self:seekWidgetByNameEx(item, "Text_name")
    local Text_id = self:seekWidgetByNameEx(item, "Text_id")
    local Text_offer = self:seekWidgetByNameEx(item, "Text_offer")
    local Button_push = self:seekWidgetByNameEx(item, "Button_push")
    Text_name:setColor(cc.c3b(131, 88, 45))
    Text_id:setColor(cc.c3b(131, 88, 45))
    Text_offer:setColor(cc.c3b(131, 88, 45))
    Common:requestUserAvatar(data.dwUserID, data.szLogoInfo, Image_head, "img")
    Text_name:setString(data.szNickName)
    Text_id:setString(data.dwUserID)
    item.data = data

    if data.dwUserRole == 0 then
    	Text_offer:setString('圈主')
    elseif data.dwUserRole == 1 then
    	Text_offer:setString('管理员')
    elseif data.dwUserRole == 2 then
    	Text_offer:setString('普通成员')
    else
    	Text_offer:setString(string.format('%d级合伙人', data.dwPartnerLevel))
    end

    Common:addTouchEventListener(Button_push, function()
		self.Image_errorList:setVisible(false)
		self.Image_errorPushList:setVisible(true)
		self.ListView_errorPush:removeAllItems()
		self.defendIndex = 1
		self.defendState = 0
		self.curSelUserID = data.dwUserID
		self.curTargetID = 0
		UserData.Guild:getClubAntiMemberInfo(self.clubData.dwClubID, self.curSelUserID, 4, self.curTargetID, 0, 0, self.defendIndex)
	end)
end

function NewClubDefendLayer:selectPage_push_4(data)
	self.Text_errorNum:setString(data.iTotalAntiValue)
    local item = self.Panel_errorPushItem:clone()
    self.ListView_errorPush:pushBackCustomItem(item)
    self.ListView_errorPush:refreshView()
    item:setName('ErrorList_' .. data.dwUserID)
    local Image_head = self:seekWidgetByNameEx(item, "Image_head")
    local Text_name = self:seekWidgetByNameEx(item, "Text_name")
    local Text_id = self:seekWidgetByNameEx(item, "Text_id")
    local Text_num = self:seekWidgetByNameEx(item, "Text_num")
    local Text_lastTime = self:seekWidgetByNameEx(item, "Text_lastTime")
    local Button_qxSet = self:seekWidgetByNameEx(item, "Button_qxSet")
    local Button_refresh = self:seekWidgetByNameEx(item, "Button_refresh")
    Text_name:setColor(cc.c3b(131, 88, 45))
    Text_id:setColor(cc.c3b(131, 88, 45))
    Text_num:setColor(cc.c3b(131, 88, 45))
    Text_lastTime:setColor(cc.c3b(131, 88, 45))
    Button_qxSet:getChildren()[1]:setColor(cc.c3b(131, 88, 45))
    Button_refresh:getChildren()[1]:setColor(cc.c3b(131, 88, 45))
    Common:requestUserAvatar(data.dwUserID, data.szLogoInfo, Image_head, "img")
    Text_name:setString(data.szNickName)
    Text_id:setString(data.dwUserID)
    Text_num:setString(data.iAntiValue)
    local time = os.time() - data.dwLastLoginDate
    local day = math.floor(time / 86400)
    local hour = (time / 3600) % 24
    local min = (time / 60) % 60
    if day <= 0 then
    	Text_lastTime:setString(string.format("%d小时%d分钟前登录",hour, min))
    else
    	Text_lastTime:setString(string.format("%d天 %d小时%d分钟前登录",day, hour, min))
    end
    item.data = data

    Common:addTouchEventListener(Button_qxSet, function()
    	self:addChild(require("app.MyApp"):create(data, nil, 1, function(value) 
    		UserData.Guild:setClubAntiMember(self.clubData.dwClubID, UserData.User.userID, 0, data.dwUserID, value)
    	end):createView("NewClubSetPercentLayer"))
	end)

	Common:addTouchEventListener(Button_refresh, function()
		require("common.MsgBoxLayer"):create(1,nil,"您确定刷新沉迷值吗？",function() 
            UserData.Guild:setClubAntiMember(self.clubData.dwClubID, UserData.User.userID, 1, data.dwUserID, 0)
        end)
	end)
end

function NewClubDefendLayer:selectPage_5(data)
	self.Text_totalNum:setString(data.iAllUserRefreshAntiValue)
	self.Text_noTotalNum:setString(data.iTotalAntiValue)
    local item = self.Panel_twoTotalItem:clone()
    self.ListView_twoTotal:pushBackCustomItem(item)
    self.ListView_twoTotal:refreshView()
    item:setName('twoPartner_' .. data.dwUserID)
    local Image_head = self:seekWidgetByNameEx(item, "Image_head")
    local Text_name = self:seekWidgetByNameEx(item, "Text_name")
    local Text_id = self:seekWidgetByNameEx(item, "Text_id")
    local Text_refreshNum = self:seekWidgetByNameEx(item, "Text_refreshNum")
    local Text_noRefreshNum = self:seekWidgetByNameEx(item, "Text_noRefreshNum")
    local Button_push = self:seekWidgetByNameEx(item, "Button_push")
    Text_name:setColor(cc.c3b(131, 88, 45))
    Text_id:setColor(cc.c3b(131, 88, 45))
    Text_refreshNum:setColor(cc.c3b(131, 88, 45))
    Text_noRefreshNum:setColor(cc.c3b(131, 88, 45))
    Common:requestUserAvatar(data.dwUserID, data.szLogoInfo, Image_head, "img")
    Text_name:setString(data.szNickName)
    Text_id:setString(data.dwUserID)
    Text_refreshNum:setString(data.iRefreshAntiValue)
    Text_noRefreshNum:setString(data.iAntiValue)
    item.data = data
    Common:addTouchEventListener(Button_push, function()
    	self.Image_twoFrame:setVisible(false)
    	self.Image_twoPushFrame:setVisible(true)
    	self.ListView_twoPushLog:removeAllItems()
    	self.logPageIndex = 1
    	self.logPageState = 0
    	self.curLogUserID = data.dwUserID
    	UserData.Guild:getClubAntiLog(self.clubData.dwClubID, self.curLogUserID, 1, self.beganTime, self.endTime, self.logPageIndex)
	end)
end

function NewClubDefendLayer:RET_CLUB_ANTI_LIST(event)
    local data = event._usedata
    dump(data)

    if data.lRet ~= 0 then
    	require("common.MsgBoxLayer"):create(0,nil,"用户不存在！")
    	return
    end

    if self.curDefendPage == 1 then
    	self:selectPage_1(data)
    elseif self.curDefendPage == 2 then
    	self:selectPage_2(data)
    elseif self.curDefendPage == 3 then
    	self:selectPage_3(data)
    elseif self.curDefendPage == 4 then
    	if self.Image_errorPushList:isVisible() then
    		self:selectPage_push_4(data)
    	else
    		self:selectPage_4(data)
    	end
    elseif self.curDefendPage == 5 or self.curDefendPage == 6 then
    	self:selectPage_5(data)
    end
end

function NewClubDefendLayer:RET_CLUB_ANTI_LIST_FINISH(event)
	local data = event._usedata
    dump(data)
    if data.isFinish then
        self.defendState = 2
    else
        self.defendState = 1
    end
    self.defendIndex = self.defendIndex + 1
end

function NewClubDefendLayer:RET_CLUB_SETTING_ANTI_MEMBER(event)
	local data = event._usedata
    dump(data)
    if data.lRet ~= 0 then
    	require("common.MsgBoxLayer"):create(0,nil,"设置成员沉迷信息失败! code="..data.lRet)
    	return
    end

    if data.bOperatorType == 0 then
    	require("common.MsgBoxLayer"):create(0,nil,"设置成员沉迷值下限成功.")
    	local idx = self:getCurSelFloorIdx()
    	local item = self['ListView_cmFloor'..idx]:getChildByName('CMItem_' .. data.dwUserID .. '_' .. idx)
    	if item then
    		local Button_qxSet = self:seekWidgetByNameEx(item, "Button_qxSet")
    		Common:addTouchEventListener(Button_qxSet, function()
    			item.data.iAntiLimit = data.iAntiLimit
		    	self:addChild(require("app.MyApp"):create(item.data, nil, 1, function(value) 
		    		UserData.Guild:setClubAntiMember(self.clubData.dwClubID, UserData.User.userID, 0, data.dwUserID, value)
		    	end):createView("NewClubSetPercentLayer"))
	    	end)
    	end

    	local item = self.ListView_errorPush:getChildByName('ErrorList_' .. data.dwUserID)
    	if item then
    		local Button_qxSet = self:seekWidgetByNameEx(item, "Button_qxSet")
    		Common:addTouchEventListener(Button_qxSet, function()
    			item.data.iAntiLimit = data.iAntiLimit
		    	self:addChild(require("app.MyApp"):create(item.data, nil, 1, function(value) 
		    		UserData.Guild:setClubAntiMember(self.clubData.dwClubID, UserData.User.userID, 0, data.dwUserID, value)
		    	end):createView("NewClubSetPercentLayer"))
	    	end)
    	end
    else
    	require("common.MsgBoxLayer"):create(0,nil,"刷新成员沉迷值成功.")
    	local idx = self:getCurSelFloorIdx()
    	local item = self['ListView_cmFloor'..idx]:getChildByName('CMItem_' .. data.dwUserID .. '_' .. idx)
    	if item then
    		local Text_cmNum = self:seekWidgetByNameEx(item, "Text_cmNum")
    		local iTotalAntiValue = tonumber(self.Text_cmListTotal:getString())
    		local memAntiValue = tonumber(Text_cmNum:getString())
    		self.Text_cmListTotal:setString(iTotalAntiValue - memAntiValue)
    		Text_cmNum:setString(0)
    	end

    	local item = self.ListView_limit:getChildByName('LimitList_' .. data.dwUserID)
    	if item then
    		local Text_cmNum = self:seekWidgetByNameEx(item, "Text_cmNum")
    		Text_cmNum:setString(0)
    	end

    	local item = self.ListView_errorPush:getChildByName('ErrorList_' .. data.dwUserID)
    	if item then
    		local Text_num = self:seekWidgetByNameEx(item, "Text_num")
    		Text_num:setString(0)
    	end
    end
end

function NewClubDefendLayer:RET_CLUB_ANTI_LIMIT(event)
	local data = event._usedata
    dump(data)
    if data.lRet ~= 0 then
    	require("common.MsgBoxLayer"):create(0,nil,"获取亲友圈沉迷值下限失败! code="..data.lRet)
    	return
    end
    self.curClubAntiLimit = data.iAntiLimit
    self.curPartnerLevel = data.dwPartnerLevel

    if self.curPartnerLevel == 2 then
    	--二级合伙人
    	self.Button_limitList:setVisible(true)
		self.Button_errorList:setVisible(true)
		self.Button_twoTotal:setVisible(false)
		self.Button_threeTotal:setVisible(true)
    	self.Button_threeTotal:setPositionY(264)
    elseif self.curPartnerLevel > 2 then
    	--三级合伙人及以上
    	self.Button_limitList:setVisible(true)
		self.Button_errorList:setVisible(true)
		self.Button_twoTotal:setVisible(false)
		self.Button_threeTotal:setVisible(false)
    elseif self.curPartnerLevel == 0 and not self:isAdmin(UserData.User.userID) then
    	self.Button_limitList:setVisible(false)
    	self.Button_errorList:setVisible(false)
    	self.Button_twoTotal:setVisible(false)
    	self.Button_threeTotal:setVisible(false)
    else
    	self.Button_limitList:setVisible(true)
    	self.Button_errorList:setVisible(true)
    	self.Button_twoTotal:setVisible(true)
    	self.Button_threeTotal:setVisible(true)
    end
end

function NewClubDefendLayer:RET_CLUB_SETTING_ANTI_LIMIT(event)
	local data = event._usedata
    dump(data)
    if data.lRet ~= 0 then
    	require("common.MsgBoxLayer"):create(0,nil,"设置亲友圈沉迷值下限失败! code="..data.lRet)
    	return
    end
    require("common.MsgBoxLayer"):create(0,nil,"设置亲友圈沉迷值下限成功.")
    self.curClubAntiLimit = data.iAntiLimit
end

function NewClubDefendLayer:RET_CLUB_ANTI_REFRESH_LOG(event)
	local data = event._usedata
    dump(data)

    local item = self.Panel_refreshPushItem:clone()
    if self.curDefendPage == 2 then
    	self.ListView_refreshPushLog:pushBackCustomItem(item)
    	self.ListView_refreshPushLog:refreshView()
    else
    	self.ListView_twoPushLog:pushBackCustomItem(item)
    	self.ListView_twoPushLog:refreshView()
    end
    item:setName('AntiLog_' .. data.dwUserID)
    local Image_head = self:seekWidgetByNameEx(item, "Image_head")
    local Text_name = self:seekWidgetByNameEx(item, "Text_name")
    local Text_id = self:seekWidgetByNameEx(item, "Text_id")
    local Text_refreshNum = self:seekWidgetByNameEx(item, "Text_refreshNum")
    local Text_partnerName = self:seekWidgetByNameEx(item, "Text_partnerName")
    local Text_partnerId = self:seekWidgetByNameEx(item, "Text_partnerId")
    local Text_time = self:seekWidgetByNameEx(item, "Text_time")
    Text_name:setColor(cc.c3b(131, 88, 45))
    Text_id:setColor(cc.c3b(131, 88, 45))
    Text_refreshNum:setColor(cc.c3b(131, 88, 45))
    Text_partnerName:setColor(cc.c3b(131, 88, 45))
    Text_partnerId:setColor(cc.c3b(131, 88, 45))
    Text_time:setColor(cc.c3b(131, 88, 45))
    Common:requestUserAvatar(data.dwUserID, data.szLogoInfo, Image_head, "img")
    Text_name:setString(data.szNickName)
    Text_id:setString(data.dwUserID)
    Text_refreshNum:setString(data.iOldAntiValue)
    Text_partnerName:setString(data.szOpUserNickName)
    Text_partnerId:setString(data.dwOpUserID)
    local timeStr = os.date('%Y-%m-%d\n%H:%M:%S', data.dwCreateTime)
    Text_time:setString(timeStr)
end

function NewClubDefendLayer:RET_CLUB_ANTI_REFRESH_LOG_FINISH(event)
	local data = event._usedata
    dump(data)
    if data.isFinish then
        self.logPageState = 2
    else
        self.logPageState = 1
    end
    self.logPageIndex = self.logPageIndex + 1
end

return NewClubDefendLayer