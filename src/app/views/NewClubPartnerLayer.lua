--[[
*名称:NewClubPartnerLayer
*描述:合伙人界面
*作者:admin
*创建日期:2019-10-28 09:57:58
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

local NewClubPartnerLayer = class("NewClubPartnerLayer", cc.load("mvc").ViewBase)

function NewClubPartnerLayer:onConfig()
    self.widget         = {
        {"Button_close", "onClose"},
        {"Button_mem", "onMember"},
        {"Button_totalMem", "onTotalMem"},
        {"Button_earning", "onEarning"},
        {"Button_partner", "onPartner"},
        {"Button_totalPartner", "onTotalPartner"},
        {"Button_addPartner", "onAddPartner"},
        {"Text_timeNode"},
        {"Image_findNode"},
        {"TextField_memId"},
        {"Button_findMem", "onFindMem"},
        {"Button_findMemReturn", "onFindMemReturn"},
        {"Panel_partnerCount"},
        {"Image_partnerPageHead"},
        {"Text_partnerPageName"},
        {"Text_partnerPageID"},
        {"Button_partnerPageReturn", "onPartnerPageReturn"},
        {"Text_timeNode"},
        {"Image_left", "onImageLeft"},
        {"Image_right", "onImageRight"},
        {"Text_day_left"},
        {"Text_day_right"},
        {"Button_search", "onSearch"},
        {"Text_alljsFlag"},
        {"Text_playAllJS"},

        {"Panel_memList"},
        {"ListView_mem"},
        {"ListView_memFind"},
        {"Text_dyj_total"},
        {"Text_cy_total"},
        {"Text_yb_total"},
        {"Text_jf_total"},
        {"Image_memItem"},
        {"Panel_memTotal"},
        {"Image_totalFrame"},
        {"Image_memPushFrame"},
        {"Text_wj_alljt"},
        {"Text_wj_allFatiguesy"},
        {"Text_wj_allYuanBaosy"},
        {"Text_wj_alldyj"},
        {"Text_wj_cynum"},
        {"ListView_playerCount"},
        {"ListView_pushPlayerCount"},
        {"Panel_totalPushItem"},
        {"Panel_totalItem"},
        {"Panel_leaderGet"},
        {"Image_leaderFrame"},
        {"ListView_sy"},
        {"Text_sy_allcy"},
        {"Text_sy_allfk"},
        {"Text_sy_allFatigue"},
        {"Text_sy_allYuanbao"},
        {"Panel_leaderItem"},
        {"Panel_myPartner"},
        {"Text_partnerdyj"},
        {"Text_partnercy"},
        {"Text_partnernum"},
        {"Text_partneryb"},
        {"Button_returnLast", "onPartnerReturn"},
        {"Image_myPartner"},
        {"Text_fanliTitle"},
        {"Image_pushMyPartner"},
        {"ListView_myPartner"},
        {"ListView_findMyPartner"},
        {"ListView_pushMyPartner"},
        {"Image_myPartnerItem"},
        {"Image_myPartnerPushItem"},
        {"Panel_partnerTotal"},
        {"Image_partnerTotal"},
        {"Text_partner_rc"},
        {"Text_partner_fh"},
        {"Text_partner_yb"},
        {"Text_partner_plz"},
        {"Text_partner_dyj"},
        {"Text_partner_totalJf"},
        {"ListView_partnerTotal"},
        {"ListView_partnerPushTotal"},
        {"Image_partnerPushTotal"},
        {"Image_partnerMemTotal"},
        {"Text_partner_mem_fk"},
        {"Text_partner_mem_plz"},
        {"Text_partner_mem_yb"},
        {"Text_partner_mem_dyj"},
        {"Text_partner_mem_cy"},
        {"ListView_partnerMemTotal"},
        {"Image_partnerPushMemTotal"},
        {"ListView_partnerPushDes"},
        {"Panel_partnerItem"},
        {"Panel_partnerPushItem"},
        {"Panel_addParnter"},
        {"ListView_addParnter"},
        {"ListView_findAddParnter"},
        {"Image_parnterItem"},
        {"Button_importClub", "onImportClub"},
        {"Button_addMem", "onAddMem"},
    }
    self.curPartnerIdx = 1
    self.partnerReqState = 0
    self.searchNum = 0
    self.beganTime = Common:getStampDay(os.time() ,true)
    self.endTime = Common:getStampDay(os.time() ,false)
    self.playerCountPage = 1
    self.earningsPage = 1
    self.partnerCountPage = 1
    self.notPartnerMemIdx = 1
end

function NewClubPartnerLayer:onEnter()
	EventMgr:registListener(EventType.RET_GET_CLUB_STATISTICS_ALL ,self,self.RET_GET_CLUB_STATISTICS_ALL)
	EventMgr:registListener(EventType.RET_GET_CLUB_PARTNER ,self,self.RET_GET_CLUB_PARTNER)
    EventMgr:registListener(EventType.RET_GET_CLUB_PARTNER_FINISH ,self,self.RET_GET_CLUB_PARTNER_FINISH)
    EventMgr:registListener(EventType.RET_GET_CLUB_PARTNER_MEMBER ,self,self.RET_GET_CLUB_PARTNER_MEMBER)
    EventMgr:registListener(EventType.RET_GET_CLUB_PARTNER_MEMBER_FINISH ,self,self.RET_GET_CLUB_PARTNER_MEMBER_FINISH)
    EventMgr:registListener(EventType.RET_FIND_CLUB_PARTNER_MEMBER ,self,self.RET_FIND_CLUB_PARTNER_MEMBER)
    EventMgr:registListener(EventType.RET_REMOVE_CLUB_MEMBER,self,self.RET_REMOVE_CLUB_MEMBER)
    EventMgr:registListener(EventType.RET_CLUB_PLAYER_COUNT ,self,self.RET_CLUB_PLAYER_COUNT)
    EventMgr:registListener(EventType.RET_CLUB_PAGE_PLAYER_COUNT ,self,self.RET_CLUB_PAGE_PLAYER_COUNT)
    EventMgr:registListener(EventType.RET_CLUB_PAGE_PLAYER_COUNT_FINISH ,self,self.RET_CLUB_PAGE_PLAYER_COUNT_FINISH)
    EventMgr:registListener(EventType.RET_CLUB_PLAYER_COUNT_DETAILS ,self,self.RET_CLUB_PLAYER_COUNT_DETAILS)
    EventMgr:registListener(EventType.RET_CLUB_PLAYER_COUNT_DETAILS_FINISH ,self,self.RET_CLUB_PLAYER_COUNT_DETAILS_FINISH)
    EventMgr:registListener(EventType.RET_PARTNER_EARNINGS ,self,self.RET_PARTNER_EARNINGS)
    EventMgr:registListener(EventType.RET_PARTNER_PAGE_EARNINGS ,self,self.RET_PARTNER_PAGE_EARNINGS)
    EventMgr:registListener(EventType.RET_PARTNER_PAGE_EARNINGS_FINISH ,self,self.RET_PARTNER_PAGE_EARNINGS_FINISH)
    EventMgr:registListener(EventType.RET_SETTINGS_CLUB_MEMBER ,self,self.RET_SETTINGS_CLUB_MEMBER)
    EventMgr:registListener(EventType.RET_CLUB_PARTNER_COUNT ,self,self.RET_CLUB_PARTNER_COUNT)
    EventMgr:registListener(EventType.RET_CLUB_PAGE_PARTNER_COUNT ,self,self.RET_CLUB_PAGE_PARTNER_COUNT)
    EventMgr:registListener(EventType.RET_CLUB_PAGE_PARTNER_COUNT_FINISH ,self,self.RET_CLUB_PAGE_PARTNER_COUNT_FINISH)
    EventMgr:registListener(EventType.RET_CLUB_PARTNER_COUNT_DETAILS ,self,self.RET_CLUB_PARTNER_COUNT_DETAILS)
    EventMgr:registListener(EventType.RET_CLUB_PARTNER_COUNT_DETAILS_FINISH ,self,self.RET_CLUB_PARTNER_COUNT_DETAILS_FINISH)
    EventMgr:registListener(EventType.RET_GET_CLUB_NOT_PARTNER_MEMBER ,self,self.RET_GET_CLUB_NOT_PARTNER_MEMBER)
    EventMgr:registListener(EventType.RET_GET_CLUB_NOT_PARTNER_MEMBER_FINISH ,self,self.RET_GET_CLUB_NOT_PARTNER_MEMBER_FINISH)
    EventMgr:registListener(EventType.RET_FIND_CLUB_NOT_PARTNER_MEMBER ,self,self.RET_FIND_CLUB_NOT_PARTNER_MEMBER)
    EventMgr:registListener(EventType.RET_SETTINGS_CONFIG ,self,self.RET_SETTINGS_CONFIG)
end

function NewClubPartnerLayer:onExit()
	EventMgr:unregistListener(EventType.RET_GET_CLUB_STATISTICS_ALL ,self,self.RET_GET_CLUB_STATISTICS_ALL)
	EventMgr:unregistListener(EventType.RET_GET_CLUB_PARTNER ,self,self.RET_GET_CLUB_PARTNER)
    EventMgr:unregistListener(EventType.RET_GET_CLUB_PARTNER_FINISH ,self,self.RET_GET_CLUB_PARTNER_FINISH)
    EventMgr:unregistListener(EventType.RET_GET_CLUB_PARTNER_MEMBER ,self,self.RET_GET_CLUB_PARTNER_MEMBER)
    EventMgr:unregistListener(EventType.RET_GET_CLUB_PARTNER_MEMBER_FINISH ,self,self.RET_GET_CLUB_PARTNER_MEMBER_FINISH)
    EventMgr:unregistListener(EventType.RET_FIND_CLUB_PARTNER_MEMBER ,self,self.RET_FIND_CLUB_PARTNER_MEMBER)
    EventMgr:unregistListener(EventType.RET_REMOVE_CLUB_MEMBER,self,self.RET_REMOVE_CLUB_MEMBER)
    EventMgr:unregistListener(EventType.RET_CLUB_PLAYER_COUNT ,self,self.RET_CLUB_PLAYER_COUNT)
    EventMgr:unregistListener(EventType.RET_CLUB_PAGE_PLAYER_COUNT ,self,self.RET_CLUB_PAGE_PLAYER_COUNT)
    EventMgr:unregistListener(EventType.RET_CLUB_PAGE_PLAYER_COUNT_FINISH ,self,self.RET_CLUB_PAGE_PLAYER_COUNT_FINISH)
    EventMgr:unregistListener(EventType.RET_CLUB_PLAYER_COUNT_DETAILS ,self,self.RET_CLUB_PLAYER_COUNT_DETAILS)
    EventMgr:unregistListener(EventType.RET_CLUB_PLAYER_COUNT_DETAILS_FINISH ,self,self.RET_CLUB_PLAYER_COUNT_DETAILS_FINISH)
    EventMgr:unregistListener(EventType.RET_PARTNER_EARNINGS ,self,self.RET_PARTNER_EARNINGS)
    EventMgr:unregistListener(EventType.RET_PARTNER_PAGE_EARNINGS ,self,self.RET_PARTNER_PAGE_EARNINGS)
    EventMgr:unregistListener(EventType.RET_PARTNER_PAGE_EARNINGS_FINISH ,self,self.RET_PARTNER_PAGE_EARNINGS_FINISH)
    EventMgr:unregistListener(EventType.RET_SETTINGS_CLUB_MEMBER ,self,self.RET_SETTINGS_CLUB_MEMBER)
    EventMgr:unregistListener(EventType.RET_CLUB_PARTNER_COUNT ,self,self.RET_CLUB_PARTNER_COUNT)
    EventMgr:unregistListener(EventType.RET_CLUB_PAGE_PARTNER_COUNT ,self,self.RET_CLUB_PAGE_PARTNER_COUNT)
    EventMgr:unregistListener(EventType.RET_CLUB_PAGE_PARTNER_COUNT_FINISH ,self,self.RET_CLUB_PAGE_PARTNER_COUNT_FINISH)
    EventMgr:unregistListener(EventType.RET_CLUB_PARTNER_COUNT_DETAILS ,self,self.RET_CLUB_PARTNER_COUNT_DETAILS)
    EventMgr:unregistListener(EventType.RET_CLUB_PARTNER_COUNT_DETAILS_FINISH ,self,self.RET_CLUB_PARTNER_COUNT_DETAILS_FINISH)
    EventMgr:unregistListener(EventType.RET_GET_CLUB_NOT_PARTNER_MEMBER ,self,self.RET_GET_CLUB_NOT_PARTNER_MEMBER)
    EventMgr:unregistListener(EventType.RET_GET_CLUB_NOT_PARTNER_MEMBER_FINISH ,self,self.RET_GET_CLUB_NOT_PARTNER_MEMBER_FINISH)
    EventMgr:unregistListener(EventType.RET_FIND_CLUB_NOT_PARTNER_MEMBER ,self,self.RET_FIND_CLUB_NOT_PARTNER_MEMBER)
    EventMgr:unregistListener(EventType.RET_SETTINGS_CONFIG ,self,self.RET_SETTINGS_CONFIG)
end

function NewClubPartnerLayer:onCreate(param)
	self.clubData = param[1]
    local itype = param[2] or 1
	self:switchType(itype)
	self:updateInputStr()
	self.ListView_mem:addScrollViewEventListener(handler(self, self.listViewMyPlayerEventListen))
	self.ListView_playerCount:addScrollViewEventListener(handler(self, self.listViewPlayerCountEventListen))
	self.ListView_pushPlayerCount:addScrollViewEventListener(handler(self, self.listViewPlayerDetailsCountEventListen))
	self.ListView_sy:addScrollViewEventListener(handler(self, self.listViewEarningsEventListen))
	self.ListView_myPartner:addScrollViewEventListener(handler(self, self.listViewParnterEventListen))
	self.ListView_pushMyPartner:addScrollViewEventListener(handler(self, self.listViewParnterMemberEventListen))
	self.ListView_partnerTotal:addScrollViewEventListener(handler(self, self.listViewPartnerCountEventListen))
    self.ListView_partnerPushTotal:addScrollViewEventListener(handler(self, self.listViewPartnerCountDetailsEventListen))
    self.ListView_addParnter:addScrollViewEventListener(handler(self, self.listViewNotParnterMemberEventListen))

	if self.clubData.dwUserID == UserData.User.userID or self:isAdmin(UserData.User.userID) then
        self.Text_alljsFlag:setVisible(true)
    else
        self.Text_alljsFlag:setVisible(false)
        self.Button_importClub:setVisible(false)
    end

    if self:isAdmin(UserData.User.userID) then
        self.Button_earning:setVisible(false)
        self.Button_addPartner:setPositionY(264)
    end
    UserData.Guild:getPartnerConfig(UserData.User.userID, self.clubData.dwClubID)
end

function NewClubPartnerLayer:onClose()
    self:removeFromParent()
end

function NewClubPartnerLayer:onMember()
	self:switchType(1)
end

function NewClubPartnerLayer:onTotalMem()
	self:switchType(2)
end

function NewClubPartnerLayer:onEarning()
	self:switchType(3)
end

function NewClubPartnerLayer:onPartner()
	self:switchType(4)
end

function NewClubPartnerLayer:onTotalPartner()
	self:switchType(5)
end

function NewClubPartnerLayer:onAddPartner()
	self:switchType(6)
end

function NewClubPartnerLayer:onFindMem()
	if self.curPartnerPage == 1 then
        local dwUserID = tonumber(self.TextField_memId:getString())
        if dwUserID then
            local dwMinWinnerScore = 0
            if not self.pCurID then
                self.pCurID = UserData.User.userID
                if self:isAdmin(UserData.User.userID) then
                    self.pCurID = self.clubData.dwUserID
                end
            end
            UserData.Guild:findPartnerMember(self.clubData.dwClubID,self.pCurID,dwUserID,self.beganTime,self.endTime,dwMinWinnerScore)
        else
            require("common.MsgBoxLayer"):create(0,nil,"输入格式错误！")
        end
    elseif self.curPartnerPage == 4 then
        local dwUserID = tonumber(self.TextField_memId:getString())
        if dwUserID then
            local dwMinWinnerScore = 0
            self.pCurID = dwUserID
            UserData.Guild:findPartnerMember(self.clubData.dwClubID,dwUserID,dwUserID,self.beganTime,self.endTime,dwMinWinnerScore)
        else
            require("common.MsgBoxLayer"):create(0,nil,"输入格式错误！")
        end
    elseif self.curPartnerPage == 6 then
	    local dwUserID = tonumber(self.TextField_memId:getString())
	    if dwUserID then
	        UserData.Guild:findClubNotPartnerMember(self.clubData.dwClubID, UserData.User.userID, 1, dwUserID)
	    else
	    	require("common.MsgBoxLayer"):create(0,nil,"输入格式错误！")
	    end
    end
end

function NewClubPartnerLayer:onFindMemReturn()
	if self.curPartnerPage == 1 then
		self.ListView_mem:setVisible(true)
		self.ListView_memFind:setVisible(false)
		self.Button_findMem:setVisible(true)
		self.Button_findMemReturn:setVisible(false)
    elseif self.curPartnerPage == 4 then
        self.ListView_myPartner:setVisible(true)
        self.ListView_findMyPartner:setVisible(false)
        self.Button_findMem:setVisible(true)
        self.Button_findMemReturn:setVisible(false)
	elseif self.curPartnerPage == 6 then
		self.ListView_addParnter:setVisible(true)
		self.ListView_findAddParnter:setVisible(false)
		self.Button_findMem:setVisible(true)
        self.Button_findMemReturn:setVisible(false)
	end
	
end

function NewClubPartnerLayer:onPartnerPageReturn()
	if self.curPartnerPage == 2 then
        self.Image_totalFrame:setVisible(true)
        self.Image_memPushFrame:setVisible(false)
        self.Text_timeNode:setVisible(true)
        self.Image_findNode:setVisible(false)
        self.Panel_partnerCount:setVisible(false)

    elseif self.curPartnerPage == 5 then
        if self.Image_partnerPushTotal:isVisible() then
            self.Image_partnerTotal:setVisible(true)
            self.Image_partnerPushTotal:setVisible(false)
            self.Text_timeNode:setVisible(true)
            self.Image_findNode:setVisible(false)
            self.Panel_partnerCount:setVisible(false)
        elseif self.Image_partnerMemTotal:isVisible() then
            self.Image_partnerMemTotal:setVisible(false)
            self.Image_partnerPushTotal:setVisible(true)
        elseif self.Image_partnerPushMemTotal:isVisible() then
            self.Image_partnerPushMemTotal:setVisible(false)
            self.Image_partnerMemTotal:setVisible(true)
            Common:requestUserAvatar(self.curFindPartnerUser.dwUserID, self.curFindPartnerUser.szLogoInfo, self.Image_partnerPageHead, "img")
            self.Text_partnerPageName:setString(self.curFindPartnerUser.szNickName)
            self.Text_partnerPageID:setString('ID:' .. self.curFindPartnerUser.dwUserID)
        end
    	
    end
end

function NewClubPartnerLayer:onPartnerReturn()
	self.Image_findNode:setVisible(false)
	self.Image_myPartner:setVisible(true)
	self.Image_pushMyPartner:setVisible(false)
    self.Image_findNode:setVisible(true)
end

function NewClubPartnerLayer:onImportClub()
	local isMegeClub = true
    local node = require("app.MyApp"):create(self.clubData, isMegeClub):createView("NewClubParnterAddMemLayer")
    self:addChild(node)
end

function NewClubPartnerLayer:onAddMem()
    local node = require("app.MyApp"):create(self.clubData):createView("NewClubParnterAddMemLayer")
    self:addChild(node)
end

function NewClubPartnerLayer:onImageLeft()
	local timeNode = require("app.MyApp"):create(self.beganTime,handler(self,self.leftNodeChange)):createView("TimeNode")
    self.Image_left:addChild(timeNode)
    timeNode:setPosition(80,-90)
end

function NewClubPartnerLayer:onImageRight()
	local timeNode = require("app.MyApp"):create(self.endTime,handler(self,self.rightNodeChange)):createView("TimeNode")
    self.Image_right:addChild(timeNode)
    timeNode:setPosition(80,-90)
end

function NewClubPartnerLayer:leftNodeChange( time,stampMin,stampMax )
    self.Text_day_left:setString(time)
    self.beganTime = stampMin
end

function NewClubPartnerLayer:rightNodeChange( time,stampMin,stampMax )
    self.Text_day_right:setString(time)
    self.endTime = stampMax
end

function NewClubPartnerLayer:onSearch()
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

function NewClubPartnerLayer:research()
    if self.curPartnerPage == 1 then
        self.ListView_mem:removeAllItems()
        self.pCurID = UserData.User.userID
        if self:isAdmin(UserData.User.userID) then
            self.pCurID = self.clubData.dwUserID
        end
        self.partnerReqState = 0
        self.curPartnerIdx = 1
        self:reqClubPartner(self.pCurID)

    elseif self.curPartnerPage == 2 then
		self.ListView_playerCount:removeAllItems()
    	UserData.Guild:getClubAllPlayerCount(UserData.User.userID, self.clubData.dwClubID, self.beganTime, self.endTime)

    elseif self.curPartnerPage == 3 then
    	self.ListView_sy:removeAllItems()
        UserData.Guild:getPartnerAllEarnings(UserData.User.userID, self.clubData.dwClubID, self.beganTime, self.endTime)

    elseif self.curPartnerPage == 4 then
    	if self.Image_myPartner:isVisible() then
            --我的合伙人 
            self.ListView_myPartner:removeAllItems()
            self.partnerReqState = 0
            self.curPartnerIdx = 1
            self:reqClubPartner()
        else
            --某个合伙人名下成员
            self.ListView_pushMyPartner:removeAllItems()
            self.partnerReqState = 0
            self.curPartnerIdx = 1
            self:reqClubPartner(self.pCurID)
        end

    elseif self.curPartnerPage == 5 then
    	self.ListView_partnerTotal:removeAllItems()
        if self.clubData.dwUserID == UserData.User.userID or self:isAdmin(UserData.User.userID) then
            UserData.Guild:getClubAllPartnerCount(0, self.clubData.dwClubID, self.beganTime, self.endTime)
        else
            UserData.Guild:getClubAllPartnerCount(UserData.User.userID, self.clubData.dwClubID, self.beganTime, self.endTime)
        end

    end
end

function NewClubPartnerLayer:updateInputStr()
    local leftTime = self:getFrmatYear(self.beganTime)
    local rightTime = self:getFrmatYear(self.endTime)
    self.Text_day_left:setString(leftTime)
    self.Text_day_right:setString(rightTime)    
end

function NewClubPartnerLayer:getFrmatYear( time )
    return  (os.date('%Y',time).."-" .. os.date('%m',time).."-"..os.date('%d',time))
end

--请求亲友圈合伙人
function NewClubPartnerLayer:reqClubPartner(dwPartnerID)
    local dwMinWinnerScore = 0
    dwPartnerID = dwPartnerID or 0
    UserData.Statistics:req_statisticsManager(self.clubData.dwClubID, self.beganTime, self.endTime, dwMinWinnerScore)
    UserData.Guild:getClubPartner(self.clubData.dwClubID, dwPartnerID, self.beganTime, self.endTime, self.curPartnerIdx, dwMinWinnerScore)
end

--请求亲友圈合伙人成员
function NewClubPartnerLayer:reqClubPartnerMember()
    local dwMinWinnerScore = 0
    UserData.Guild:getClubPartnerMember(self.clubData.dwClubID, self.pCurID, 0, self.beganTime, self.endTime, self.pCurPage, dwMinWinnerScore)
end

--请求亲友圈非合伙人成员
function NewClubPartnerLayer:reqNotPartnerMember()
    local targetID = nil
    if self:isAdmin(UserData.User.userID) then
        targetID = self.clubData.dwUserID
    end
    UserData.Guild:getClubNotPartnerMember(2, self.notPartnerMemIdx, self.clubData.dwClubID, targetID)
end

-- 1成员列表 2成员统计 3我的收益 4我的合伙人 5合伙人统计 6添加合伙人
function NewClubPartnerLayer:switchType(itype)
	self.curPartnerPage = itype
	if itype == 1 then
		self.Button_mem:setBright(false)
		self.Button_totalMem:setBright(true)
		self.Button_earning:setBright(true)
		self.Button_partner:setBright(true)
		self.Button_totalPartner:setBright(true)
		self.Button_addPartner:setBright(true)
		self.Text_timeNode:setVisible(true)
		self.Image_findNode:setVisible(true)
		self.Panel_partnerCount:setVisible(false)
		self.Panel_memList:setVisible(true)
		self.Panel_memTotal:setVisible(false)
		self.Panel_leaderGet:setVisible(false)
		self.Panel_myPartner:setVisible(false)
		self.Panel_addParnter:setVisible(false)
		self.Panel_partnerTotal:setVisible(false)
		self.ListView_mem:setVisible(true)
    	self.ListView_memFind:setVisible(false)
		
	elseif itype == 2 then
		self.Button_mem:setBright(true)
		self.Button_totalMem:setBright(false)
		self.Button_earning:setBright(true)
		self.Button_partner:setBright(true)
		self.Button_totalPartner:setBright(true)
		self.Button_addPartner:setBright(true)
		self.Panel_memList:setVisible(false)
		self.Panel_memTotal:setVisible(true)
		self.Panel_leaderGet:setVisible(false)
		self.Panel_myPartner:setVisible(false)
		self.Panel_addParnter:setVisible(false)
		self.Panel_partnerTotal:setVisible(false)
		if not self.Image_memPushFrame:isVisible() then
			self.Text_timeNode:setVisible(true)
			self.Image_findNode:setVisible(false)
			self.Panel_partnerCount:setVisible(false)
		else
			self.Text_timeNode:setVisible(false)
			self.Image_findNode:setVisible(false)
			self.Panel_partnerCount:setVisible(true)
		end

	elseif itype == 3 then
		self.Button_mem:setBright(true)
		self.Button_totalMem:setBright(true)
		self.Button_earning:setBright(false)
		self.Button_partner:setBright(true)
		self.Button_totalPartner:setBright(true)
		self.Button_addPartner:setBright(true)
		self.Text_timeNode:setVisible(true)
		self.Image_findNode:setVisible(false)
		self.Panel_partnerCount:setVisible(false)
		self.Panel_memList:setVisible(false)
		self.Panel_memTotal:setVisible(false)
		self.Panel_leaderGet:setVisible(true)
		self.Panel_myPartner:setVisible(false)
		self.Panel_addParnter:setVisible(false)
		self.Panel_partnerTotal:setVisible(false)

        if self.clubData.dwUserID == UserData.User.userID then
            --群主
            local Text_2 = self.Image_leaderFrame:getChildByName('Text_2')
            local Text_3 = self.Image_leaderFrame:getChildByName('Text_3')
            local Text_4 = self.Image_leaderFrame:getChildByName('Text_4')
            local Text_5 = self.Image_leaderFrame:getChildByName('Text_5')
            Text_2:setString('亲友圈总\n人次')
            Text_3:setString('亲友圈总\n房卡费用')
            Text_4:setString('疲劳值总收益/合伙人\n总分成/盟主收益')
            Text_5:setString('元宝总收益/合伙人总\n分成/盟主收益')
        end

	elseif itype == 4 then
		self.Button_mem:setBright(true)
		self.Button_totalMem:setBright(true)
		self.Button_earning:setBright(true)
		self.Button_partner:setBright(false)
		self.Button_totalPartner:setBright(true)
		self.Button_addPartner:setBright(true)
		self.Panel_partnerCount:setVisible(false)
		self.Panel_memList:setVisible(false)
		self.Panel_memTotal:setVisible(false)
		self.Panel_leaderGet:setVisible(false)
		self.Panel_myPartner:setVisible(true)
		self.Panel_addParnter:setVisible(false)
		self.Panel_partnerTotal:setVisible(false)
		self.Text_timeNode:setVisible(true)
		if self.Image_pushMyPartner:isVisible() then
			self.Image_findNode:setVisible(false)
		else
			self.Image_findNode:setVisible(true)
		end
        if self.bDistributionModel ~= 2 then
            self.Text_fanliTitle:setVisible(false)
        else
            self.Text_fanliTitle:setVisible(true)
        end

	elseif itype == 5 then
		self.Button_mem:setBright(true)
		self.Button_totalMem:setBright(true)
		self.Button_earning:setBright(true)
		self.Button_partner:setBright(true)
		self.Button_totalPartner:setBright(false)
		self.Button_addPartner:setBright(true)
		self.Panel_memList:setVisible(false)
		self.Panel_memTotal:setVisible(false)
		self.Panel_leaderGet:setVisible(false)
		self.Panel_myPartner:setVisible(false)
		self.Panel_partnerTotal:setVisible(true)
		self.Panel_addParnter:setVisible(false)

		if self.Image_partnerTotal:isVisible() then
			self.Text_timeNode:setVisible(true)
			self.Image_findNode:setVisible(false)
			self.Panel_partnerCount:setVisible(false)
		else
			self.Text_timeNode:setVisible(false)
			self.Image_findNode:setVisible(false)
			self.Panel_partnerCount:setVisible(true)
		end

	elseif itype == 6 then
		self.Button_mem:setBright(true)
		self.Button_totalMem:setBright(true)
		self.Button_earning:setBright(true)
		self.Button_partner:setBright(true)
		self.Button_totalPartner:setBright(true)
		self.Button_addPartner:setBright(false)
		self.Text_timeNode:setVisible(false)
		self.Image_findNode:setVisible(true)
		self.Panel_partnerCount:setVisible(false)
		self.Panel_memList:setVisible(false)
		self.Panel_memTotal:setVisible(false)
		self.Panel_leaderGet:setVisible(false)
		self.Panel_myPartner:setVisible(false)
		self.Panel_partnerTotal:setVisible(false)
		self.Panel_addParnter:setVisible(true)
		self.ListView_addParnter:removeAllItems()
        self.notPartnerMemState = 0
        self.notPartnerMemIdx = 1
        self:reqNotPartnerMember()
		
	end
end

function NewClubPartnerLayer:insertOncePartnerMember(data, listView)
    local item = self.Image_memItem:clone()
    if listView then
    	listView = listView
    else
    	listView = self.ListView_mem
    end

    if self:isAdmin(UserData.User.userID) then
        if self.clubData.dwUserID == data.dwUserID then
            listView:insertCustomItem(item, 0)
        else
            listView:pushBackCustomItem(item)
        end
    else
        if data.dwUserID == UserData.User.userID then
            listView:insertCustomItem(item, 0)
        else
            listView:pushBackCustomItem(item)
        end
    end

    item:setName('PartnerMember_' .. data.dwUserID)
    local Image_head = ccui.Helper:seekWidgetByName(item, "Image_head")
    local Text_state = ccui.Helper:seekWidgetByName(item, "Text_state")
    local Text_name = ccui.Helper:seekWidgetByName(item, "Text_name")
    local Text_id = ccui.Helper:seekWidgetByName(item, "Text_id")
    local Text_dyjNum = ccui.Helper:seekWidgetByName(item, "Text_dyjNum")
    local Text_cyNum = ccui.Helper:seekWidgetByName(item, "Text_cyNum")
    local Text_ybNum = ccui.Helper:seekWidgetByName(item, "Text_ybNum")
    local Text_jfNum = ccui.Helper:seekWidgetByName(item, "Text_jfNum")
    local Button_stop = ccui.Helper:seekWidgetByName(item, "Button_stop")
    local Button_quit = ccui.Helper:seekWidgetByName(item, "Button_quit")
    local Button_add = ccui.Helper:seekWidgetByName(item, "Button_add")
    Text_name:setColor(cc.c3b(131, 88, 45))
    Text_id:setColor(cc.c3b(131, 88, 45))
    Text_dyjNum:setColor(cc.c3b(131, 88, 45))
    Text_cyNum:setColor(cc.c3b(131, 88, 45))
    Text_ybNum:setColor(cc.c3b(131, 88, 45))
    Text_jfNum:setColor(cc.c3b(131, 88, 45))

    Common:requestUserAvatar(data.dwUserID, data.szLogoInfo, Image_head, "img")
    Text_name:setString(data.szNickName)
    Text_id:setString(data.dwUserID)
    Text_dyjNum:setString(data.dwWinnerCount or 0)
    Text_cyNum:setString(data.dwGameCount or 0)
    Text_ybNum:setString(data.lYuanBaoCount or 0)
    Text_jfNum:setString(data.lScorePoint or 0)

    self:setStopPlayState(item, data.isProhibit, data.cbOnlineStatus)
    
    if data.dwUserID == UserData.User.userID then
    	Button_stop:setVisible(false)
	    Button_quit:setVisible(false)
	    Button_add:setVisible(true)
    else
    	Button_stop:setVisible(true)
	    Button_quit:setVisible(true)
	    Button_add:setVisible(false)
    end

    if self:isAdmin(UserData.User.userID) then
        if self.clubData.dwUserID == data.dwUserID then
            Button_stop:setVisible(false)
            Button_quit:setVisible(false)
            Button_add:setVisible(true)
        elseif data.dwUserID == UserData.User.userID then
            Button_stop:setVisible(false)
            Button_quit:setVisible(false)
            Button_add:setVisible(false)
        end
    end

    Common:addTouchEventListener(Button_stop, function()
		if Text_state:getString() ~= '暂停娱乐' then
			require("common.MsgBoxLayer"):create(1,self,"您确定将该成员禁赛?",function()
		        UserData.Guild:reqSettingsClubMember(0, data.dwClubID, data.dwUserID,0,"")
		        self:setStopPlayState(item, true, data.cbOnlineStatus)
		    end)
		else
			require("common.MsgBoxLayer"):create(1,self,"您确定将该成员恢复比赛?",function()
		        UserData.Guild:reqSettingsClubMember(1, data.dwClubID, data.dwUserID,0,"")
		        self:setStopPlayState(item, false, data.cbOnlineStatus)
		    end)
		end
    end)
   	Common:addTouchEventListener(Button_quit, function()
        require("common.MsgBoxLayer"):create(1,self,"您确定要踢出该成员？",function() 
            UserData.Guild:removeClubMember(data.dwClubID, data.dwUserID)
        end)
    end)
    Common:addTouchEventListener(Button_add, function()
    	local node = require("app.MyApp"):create(self.clubData):createView("NewClubParnterAddMemLayer")
    	self:addChild(node)
    end)
end

function NewClubPartnerLayer:setStopPlayState(item, isProhibit, cbOnlineStatus)
	local Button_stop = ccui.Helper:seekWidgetByName(item, "Button_stop")
	local Text_state = ccui.Helper:seekWidgetByName(item, "Text_state")
	if isProhibit then
    	local btnPath = 'kwxclub/club_partner_8.png'
        Button_stop:loadTextures(btnPath, btnPath, btnPath)
    else
    	local btnPath = 'kwxclub/club_partner_7.png'
        Button_stop:loadTextures(btnPath, btnPath, btnPath)
    end

    if isProhibit then
    	Text_state:setColor(cc.c3b(255, 0, 0))
        Text_state:setString('暂停娱乐')
    elseif cbOnlineStatus == 1 then
    	Text_state:setColor(cc.c3b(0, 128, 0))
        Text_state:setString('在线')
    elseif cbOnlineStatus == 2 or cbOnlineStatus == 0 then
    	Text_state:setColor(cc.c3b(177, 177, 177))
        Text_state:setString('离线')
    elseif cbOnlineStatus == 100 then
    	Text_state:setColor(cc.c3b(243, 130, 16))
        Text_state:setString('对局中')
    else
        Text_state:setVisible(false)
    end
end

function NewClubPartnerLayer:insertMyPartnerItme(data)
	local item = self.Image_myPartnerItem:clone()
    if self.ListView_findMyPartner:isVisible() then
        if self.pCurID == data.dwUserID then
            self.ListView_findMyPartner:removeAllItems()
            self.ListView_findMyPartner:pushBackCustomItem(item)
        end
    else
        self.ListView_myPartner:pushBackCustomItem(item)
    end
    item:setName('MyPartner_' .. data.dwUserID)
    local Image_head = ccui.Helper:seekWidgetByName(item, "Image_head")
    local Text_state = ccui.Helper:seekWidgetByName(item, "Text_state")
    local Text_name = ccui.Helper:seekWidgetByName(item, "Text_name")
    local Text_id = ccui.Helper:seekWidgetByName(item, "Text_id")
    local Text_sf = ccui.Helper:seekWidgetByName(item, "Text_sf")
    local Text_fl = ccui.Helper:seekWidgetByName(item, "Text_fl")
    local Button_des = ccui.Helper:seekWidgetByName(item, "Button_des")
    local Button_remove = ccui.Helper:seekWidgetByName(item, "Button_remove")
    local Button_set = ccui.Helper:seekWidgetByName(item, "Button_set")
    Text_name:setColor(cc.c3b(131, 88, 45))
    Text_id:setColor(cc.c3b(131, 88, 45))
    Text_sf:setColor(cc.c3b(131, 88, 45))
    Text_fl:setColor(cc.c3b(131, 88, 45))

    if self.bDistributionModel ~= 2 then
        Text_fl:setVisible(false)
        Button_set:setVisible(false)
    else
        Text_fl:setVisible(true)
        Button_set:setVisible(true)
    end

    if data.isProhibit then
    	Text_state:setColor(cc.c3b(255, 0, 0))
        Text_state:setString('暂停娱乐')
    elseif data.cbOnlineStatus == 1 then
    	Text_state:setColor(cc.c3b(0, 128, 0))
        Text_state:setString('在线')
    elseif data.cbOnlineStatus == 2 or data.cbOnlineStatus == 0 then
    	Text_state:setColor(cc.c3b(177, 177, 177))
        Text_state:setString('离线')
    elseif data.cbOnlineStatus == 100 then
    	Text_state:setColor(cc.c3b(243, 130, 16))
        Text_state:setString('对局中')
    else
        Text_state:setVisible(false)
    end

    Common:requestUserAvatar(data.dwUserID, data.szLogoInfo, Image_head, "img")
    Text_name:setString(data.szNickName)
    Text_id:setString(data.dwUserID)
    Text_sf:setString(data.dwPartnerLevel .. '级合伙人')
    Text_fl:setString(data.dwDistributionRatio .. '%')

    Common:addTouchEventListener(Button_set, function()
        self:addChild(require("app.MyApp"):create(data, self.userSelfPartnerData):createView("NewClubSetPercentLayer"))
    end)

    Common:addTouchEventListener(Button_des, function()
    	self.Image_findNode:setVisible(false)
		self.Image_myPartner:setVisible(false)
		self.Image_pushMyPartner:setVisible(true)
		self.ListView_pushMyPartner:removeAllItems()
    	self.pCurID = data.dwUserID
        self.partnerReqState = 0
        self.curPartnerIdx = 1
        self:reqClubPartner(self.pCurID)
    end)
   	Common:addTouchEventListener(Button_remove, function()
   		require("common.MsgBoxLayer"):create(1,nil,"您确定要解除合伙人？",function() 
            UserData.Guild:reqSettingsClubMember(4, data.dwClubID, data.dwUserID,0,"")
        end)
    end)
end

function NewClubPartnerLayer:insertMyPushPartnerItme(data)
    local item = self.Image_myPartnerPushItem:clone()
    self.ListView_pushMyPartner:pushBackCustomItem(item)
    item:setName('MyPushPartner_' .. data.dwUserID)
    local Image_head = ccui.Helper:seekWidgetByName(item, "Image_head")
    local Text_state = ccui.Helper:seekWidgetByName(item, "Text_state")
    local Text_id = ccui.Helper:seekWidgetByName(item, "Text_id")
    local Text_name = ccui.Helper:seekWidgetByName(item, "Text_name")
    local Text_dyjNum = ccui.Helper:seekWidgetByName(item, "Text_dyjNum")
    local Text_cyNum = ccui.Helper:seekWidgetByName(item, "Text_cyNum")
    local Text_playerNum = ccui.Helper:seekWidgetByName(item, "Text_playerNum")
    local Text_ybNum = ccui.Helper:seekWidgetByName(item, "Text_ybNum")
    local Button_pushCtr = ccui.Helper:seekWidgetByName(item, "Button_pushCtr")
    Text_name:setColor(cc.c3b(131, 88, 45))
    Text_id:setColor(cc.c3b(131, 88, 45))
    Text_dyjNum:setColor(cc.c3b(131, 88, 45))
    Text_cyNum:setColor(cc.c3b(131, 88, 45))
    Text_playerNum:setColor(cc.c3b(131, 88, 45))
    Text_ybNum:setColor(cc.c3b(131, 88, 45))

    if data.dwUserID == self.pCurID then
        if self.clubData.dwUserID == UserData.User.userID or self:isAdmin(UserData.User.userID) then
            local path = 'kwxclub/club_partner_6.png'
            Button_pushCtr:loadTextures(path, path, path)
            Common:addTouchEventListener(Button_pushCtr, function()
                --调配成员
                local leaderId = nil
                if self:isAdmin(UserData.User.userID) then
                    leaderId = self.clubData.dwUserID
                end
                local node = require("app.MyApp"):create(data, leaderId):createView("NewClubAllocationLayer")
                self:addChild(node)
            end)
        else
            Button_pushCtr:setVisible(false)
        end
    else
        local path = 'kwxclub/club_partner_9.png'
        Button_pushCtr:loadTextures(path, path, path)
        Common:addTouchEventListener(Button_pushCtr, function()
            --解绑成员
            require("common.MsgBoxLayer"):create(1,nil,"您确定要解绑成员？",function() 
                UserData.Guild:reqSettingsClubMember(10, data.dwClubID, data.dwUserID, data.dwPartnerID,"")
            end)
        end)
    end
    
    if data.isProhibit then
        Text_state:setColor(cc.c3b(255, 0, 0))
        Text_state:setString('暂停娱乐')
    elseif data.cbOnlineStatus == 1 then
        Text_state:setColor(cc.c3b(0, 128, 0))
        Text_state:setString('在线')
    elseif data.cbOnlineStatus == 2 or data.cbOnlineStatus == 0 then
        Text_state:setColor(cc.c3b(177, 177, 177))
        Text_state:setString('离线')
    elseif data.cbOnlineStatus == 100 then
        Text_state:setColor(cc.c3b(243, 130, 16))
        Text_state:setString('对局中')
    else
        Text_state:setVisible(false)
    end

    Common:requestUserAvatar(data.dwUserID, data.szLogoInfo, Image_head, "img")
    Text_name:setString(data.szNickName)
    Text_id:setString(data.dwUserID)
    Text_dyjNum:setString(data.dwWinnerCount or 0)
    Text_cyNum:setString(data.dwGameCount or 0)
    Text_ybNum:setString(data.lYuanBaoCount or 0)
    Text_playerNum:setString(data.dwPlayerCount or 0)
end

function NewClubPartnerLayer:isAdmin(userid)
    for i,v in ipairs(self.clubData.dwAdministratorID or {}) do
        if v == userid then
            return true
        end
    end
    return false
end

function NewClubPartnerLayer:listViewMyPlayerEventListen(sender, evenType)
    if evenType == ccui.ScrollviewEventType.scrollToBottom then
        if self.pReqState == 1 then
            self.pReqState = 0
            self:reqClubPartnerMember()
        end
    end
end

function NewClubPartnerLayer:listViewPlayerCountEventListen(sender, evenType)
    if evenType == ccui.ScrollviewEventType.scrollToBottom then
        if self.playerCountState == 1 then
            self.playerCountState = 0
            UserData.Guild:getClubPagePlayerCount(self.clubData.dwClubID, UserData.User.userID, self.beganTime, self.endTime, self.playerCountPage)
        end
    end
end

function NewClubPartnerLayer:listViewPlayerDetailsCountEventListen(sender, evenType)
    if evenType == ccui.ScrollviewEventType.scrollToBottom then
        if self.playerCountDetailsState == 1 then
            self.playerCountDetailsState = 0
            UserData.Guild:getClubPlayerCountDetails(self.clubData.dwClubID, UserData.User.userID, self.curSelLookDetailsPlayer, self.beganTime, self.endTime, self.playerCountDetailsPage)
        end
    end
end

function NewClubPartnerLayer:listViewEarningsEventListen(sender, evenType)
    if evenType == ccui.ScrollviewEventType.scrollToBottom then
        if self.earningsReqState == 1 then
            self.earningsReqState = 0
            UserData.Guild:getPartnerPageEarnings(self.clubData.dwClubID, UserData.User.userID, self.beganTime, self.endTime, self.earningsPage)
        end
    end
end

function NewClubPartnerLayer:listViewParnterEventListen(sender, evenType)
    if evenType == ccui.ScrollviewEventType.scrollToBottom then
        if self.partnerReqState == 1 then
            self.partnerReqState = 0
            self:reqClubPartner()
        end
    end
end

function NewClubPartnerLayer:listViewParnterMemberEventListen(sender, evenType)
    if evenType == ccui.ScrollviewEventType.scrollToBottom then
        if self.pReqState == 1 then
            self.pReqState = 0
            self:reqClubPartnerMember()
        end
    end
end

function NewClubPartnerLayer:listViewPartnerCountEventListen(sender, evenType)
    if evenType == ccui.ScrollviewEventType.scrollToBottom then
        if self.partnerCountState == 1 then
            self.partnerCountState = 0
            if self.clubData.dwUserID == UserData.User.userID or self:isAdmin(UserData.User.userID) then
                UserData.Guild:getClubPagePartnerCount(self.clubData.dwClubID, 0, self.beganTime, self.endTime, self.partnerCountPage)
            else
                UserData.Guild:getClubPagePartnerCount(self.clubData.dwClubID, UserData.User.userID, self.beganTime, self.endTime, self.partnerCountPage)
            end
        end
    end
end

function NewClubPartnerLayer:listViewPartnerCountDetailsEventListen(sender, evenType)
    if evenType == ccui.ScrollviewEventType.scrollToBottom then
        if self.partnerCountDetailsState == 1 then
            self.partnerCountDetailsState = 0
            if self.clubData.dwUserID == UserData.User.userID or self:isAdmin(UserData.User.userID) then
                UserData.Guild:getClubPartnerCountDetails(self.clubData.dwClubID, self.curSelLookDetailsPartner, 0, self.beganTime, self.endTime, self.partnerCountDetailsPage)
            else
                UserData.Guild:getClubPartnerCountDetails(self.clubData.dwClubID, UserData.User.userID, self.curSelLookDetailsPartner, self.beganTime, self.endTime, self.partnerCountDetailsPage)
            end
        end
    end
end

function NewClubPartnerLayer:listViewNotParnterMemberEventListen(sender, evenType)
    if evenType == ccui.ScrollviewEventType.scrollToBottom then
        if self.notPartnerMemState == 1 then
            self.notPartnerMemState = 0
            self:reqNotPartnerMember()
        end
    end
end

--------------------------------
--服务端返回
function NewClubPartnerLayer:RET_GET_CLUB_STATISTICS_ALL(event)
    local data = event._usedata
    dump(data)
    self.Text_playAllJS:setString(data.dwAllPeopleCount)
end

--返回亲友圈合伙人
function NewClubPartnerLayer:RET_GET_CLUB_PARTNER(event)
    local data = event._usedata
    dump(data)
    if data.lRet ~= 0 then
        require("common.MsgBoxLayer"):create(0,nil,"您还不是合伙人!")
        return
    end

    if self.isFirstEnter then
        self.isFirstEnter = false
        self.userSelfPartnerData = data

        if self.bDistributionModel == 0 then
            if self.clubData.dwUserID == UserData.User.userID or self:isAdmin(UserData.User.userID) then
                self.Button_addPartner:setVisible(true)
            else
                self.Button_addPartner:setVisible(false)
            end
        elseif self.bDistributionModel == 1 then
            self.Button_addPartner:setVisible(true)
        else
            if CHANNEL_ID == 26 or CHANNEL_ID == 27 then
                if data.dwPartnerLevel >= 3 then
                    self.Button_addPartner:setVisible(false)
                else
                    self.Button_addPartner:setVisible(true)
                end
            else
                if data.dwPartnerLevel >= 5 then
                    self.Button_addPartner:setVisible(false)
                else
                    self.Button_addPartner:setVisible(true)
                end
            end
        end
        return
    end

    if self.curPartnerPage == 1 then
    	--玩家列表
        -- self:insertOncePartnerMember(data)
        self.userSelfPartnerData = data
        self.Text_dyj_total:setString(data.dwWinnerCount)
        self.Text_cy_total:setString(data.dwGameCount)
        self.Text_yb_total:setString(data.lYuanBaoCount)
        self.Text_jf_total:setString(data.lScorePoint)
        self.pCurPage = 1
        self.pReqState = 0
        self:reqClubPartnerMember()
    elseif self.curPartnerPage == 4 then
    	--我的合伙人
    	if self.Image_myPartner:isVisible() then
    		if data.dwUserID ~= UserData.User.userID and self.clubData.dwUserID ~= data.dwUserID then
	    		self:insertMyPartnerItme(data)
	    	end

            if data.dwUserID == UserData.User.userID or self.clubData.dwUserID == data.dwUserID then
                self.userSelfPartnerData = data
            end
	    else
	    	-- 我的合伙人展开
			self.Text_partnerdyj:setString(data.dwWinnerCount)
			self.Text_partnercy:setString(data.dwGameCount)
			self.Text_partnernum:setString(data.dwPlayerCount)
			self.Text_partneryb:setString(data.lYuanBaoCount)
	    	self.pCurPage = 1
            self.pReqState = 0
            self:reqClubPartnerMember()
    	end
    end
end

function NewClubPartnerLayer:RET_GET_CLUB_PARTNER_FINISH(event)
    local data = event._usedata
    dump(data)
    if data.isFinish then
        self.partnerReqState = 2
    else
        self.partnerReqState = 1
    end
    self.curPartnerIdx = self.curPartnerIdx + 1
end

function NewClubPartnerLayer:RET_GET_CLUB_PARTNER_MEMBER(event)
    local data = event._usedata
    dump(data)
    if self.curPartnerPage == 1 then
        self:insertOncePartnerMember(data)
    elseif self.curPartnerPage == 4 then
    	self:insertMyPushPartnerItme(data)
    end
end

function NewClubPartnerLayer:RET_GET_CLUB_PARTNER_MEMBER_FINISH(event)
    local data = event._usedata
    dump(data)
    if data.isFinish then
        self.pReqState = 2
    else
        self.pReqState = 1
    end
    self.pCurPage = self.pCurPage + 1
end

function NewClubPartnerLayer:RET_FIND_CLUB_PARTNER_MEMBER(event)
    local data = event._usedata
    dump(data)
    if data.lRet ~= 0 then
    	require("common.MsgBoxLayer"):create(0,nil,"玩家ID不存在")
    	return
    end
    if self.curPartnerPage == 1 then
    	self.ListView_mem:setVisible(false)
    	self.ListView_memFind:setVisible(true)
    	self.Button_findMem:setVisible(false)
		self.Button_findMemReturn:setVisible(true)
		self.ListView_memFind:removeAllItems()
        self:insertOncePartnerMember(data, self.ListView_memFind)
    elseif self.curPartnerPage == 4 then
        self.ListView_myPartner:setVisible(false)
        self.ListView_findMyPartner:setVisible(true)
        self.Button_findMem:setVisible(false)
        self.Button_findMemReturn:setVisible(true)
        self:insertMyPartnerItme(data)
    end
end

--返回剔除成员
function NewClubPartnerLayer:RET_REMOVE_CLUB_MEMBER(event)
    local data = event._usedata
    dump(data)
    if data.lRet ~= 0 then
    	if data.lRet == 1 then
    		require("common.MsgBoxLayer"):create(0,self,"亲友圈不存在!")
    	elseif data.lRet == 2 then
    		require("common.MsgBoxLayer"):create(0,self,"该玩家不属于亲友圈成员!")
    	elseif data.lRet == 3 then
    		require("common.MsgBoxLayer"):create(0,self,"权限不足，非群主和管理员不能踢出!")
    	elseif data.lRet == 4 then
    		require("common.MsgBoxLayer"):create(0,self,"权限不足，该玩家不属于您的直属玩家!")
    	elseif data.lRet == 5 then
    		require("common.MsgBoxLayer"):create(0,self,"玩家疲劳值大于0不能踢出!")
    	elseif data.lRet == 6 then
    		require("common.MsgBoxLayer"):create(0,self,"权限不足，合伙人没有踢人权限!")
    	else
    		require("common.MsgBoxLayer"):create(0,self,"踢出失败code=" .. data.lRet)
    	end
        return
    end
    require("common.MsgBoxLayer"):create(0,self,"踢出成功.")
    
    local item = self.ListView_mem:getChildByName('PartnerMember_' .. data.dwUserID)
    if item then
        local index = self.ListView_mem:getIndex(item)
        self.ListView_mem:removeItem(index)
        self.ListView_mem:refreshView()
    end

    local item = self.ListView_memFind:getChildByName('PartnerMember_' .. data.dwUserID)
    if item then
        local index = self.ListView_mem:getIndex(item)
        self.ListView_memFind:removeItem(index)
        self.ListView_memFind:refreshView()
    end
end

function NewClubPartnerLayer:RET_CLUB_PLAYER_COUNT(event)
    local data = event._usedata
    dump(data)
    if data.lRet ~= 0 then
        require("common.MsgBoxLayer"):create(0,nil,"获取我的玩家统计失败！")
        return
    end

    if self.curPartnerPage == 2 then
        self.Text_wj_alljt:setString(data.dwTargetFatigueTip)
        self.Text_wj_allFatiguesy:setString(data.dwTargetFatigueIncome)
        self.Text_wj_allYuanBaosy:setString(data.dwTargetYuanBaoIncome)
        self.Text_wj_alldyj:setString(data.dwBigWinnerTime)
        self.Text_wj_cynum:setString(data.dwPeopleCount)
        self.playerCountPage = 1
        UserData.Guild:getClubPagePlayerCount(self.clubData.dwClubID, UserData.User.userID, self.beganTime, self.endTime, self.playerCountPage)

    elseif self.curPartnerPage == 5 then
        self.Text_partner_mem_fk:setString(data.dwTargetFatigueTip)
        self.Text_partner_mem_plz:setString(data.dwTargetFatigueIncome)
        self.Text_partner_mem_yb:setString(data.dwTargetYuanBaoIncome)
        self.Text_partner_mem_dyj:setString(data.dwBigWinnerTime)
        self.Text_partner_mem_cy:setString(data.dwPeopleCount)
        self.playerCountPage = 1
        UserData.Guild:getClubPagePlayerCount(self.clubData.dwClubID, self.curFindPartnerUser.dwUserID, self.partnerBeganTime, self.partnerEndTime, self.playerCountPage)
    end
end

function NewClubPartnerLayer:RET_CLUB_PAGE_PLAYER_COUNT(event)
    local data = event._usedata
    dump(data)
    local listView = self.ListView_playerCount
    if self.curPartnerPage == 5 then
        listView = self.ListView_partnerMemTotal
    end

    local item = self.Panel_totalItem:clone()
    if data.dwUserID == UserData.User.userID then
        listView:insertCustomItem(item, 0)
    else
        listView:pushBackCustomItem(item)
    end
    local Image_head = self:seekWidgetByNameEx(item, "Image_head")
    local Text_name = self:seekWidgetByNameEx(item, "Text_name")
    local Text_juntan = self:seekWidgetByNameEx(item, "Text_juntan")
    local Text_fatigue_sy = self:seekWidgetByNameEx(item, "Text_fatigue_sy")
    local Text_yuanbao_sy = self:seekWidgetByNameEx(item, "Text_yuanbao_sy")
    local Text_bigwincount = self:seekWidgetByNameEx(item, "Text_bigwincount")
    local Text_playcount = self:seekWidgetByNameEx(item, "Text_playcount")
    local Button_push = self:seekWidgetByNameEx(item, "Button_push")
    Text_name:setColor(cc.c3b(131, 88, 45))
    Text_juntan:setColor(cc.c3b(131, 88, 45))
    Text_fatigue_sy:setColor(cc.c3b(131, 88, 45))
    Text_yuanbao_sy:setColor(cc.c3b(131, 88, 45))
    Text_bigwincount:setColor(cc.c3b(131, 88, 45))
    Text_playcount:setColor(cc.c3b(131, 88, 45))

    Common:requestUserAvatar(data.dwUserID, data.szLogoInfo, Image_head, "img")
    Text_name:setString(data.szNickName)
    Text_juntan:setString(data.dwTargetFatigueTip)
    Text_fatigue_sy:setString(data.dwTargetFatigueIncome)
    Text_yuanbao_sy:setString(data.dwTargetYuanBaoIncome)
    Text_bigwincount:setString(data.dwBigWinnerTime)
    Text_playcount:setString(data.dwPeopleCount)

    Common:addTouchEventListener(Button_push,function()
        if self.curPartnerPage == 2 then
            self.Image_totalFrame:setVisible(false)
            self.Image_memPushFrame:setVisible(true)
            self.Text_timeNode:setVisible(false)
            self.Image_findNode:setVisible(false)
            self.Panel_partnerCount:setVisible(true)
            Common:requestUserAvatar(data.dwUserID, data.szLogoInfo, self.Image_partnerPageHead, "img")
            self.Text_partnerPageName:setString(data.szNickName)
            self.Text_partnerPageID:setString('ID:' .. data.dwUserID)

            self.ListView_pushPlayerCount:removeAllItems()
            self.curSelLookDetailsPlayer = data.dwUserID
            self.playerCountDetailsPage = 1
            UserData.Guild:getClubPlayerCountDetails(self.clubData.dwClubID, UserData.User.userID, data.dwUserID, self.beganTime, self.endTime, self.playerCountDetailsPage)
        else
            self.Image_partnerMemTotal:setVisible(false)
            self.Image_partnerPushMemTotal:setVisible(true)
            Common:requestUserAvatar(data.dwUserID, data.szLogoInfo, self.Image_partnerPageHead, "img")
            self.Text_partnerPageName:setString(data.szNickName)
            self.Text_partnerPageID:setString('ID:' .. data.dwUserID)

            self.ListView_partnerPushDes:removeAllItems()
            self.curSelLookDetailsPlayer = data.dwUserID
            self.playerCountDetailsPage = 1

            UserData.Guild:getClubPlayerCountDetails(self.clubData.dwClubID, self.curFindPartnerUser.dwUserID, data.dwUserID, self.partnerBeganTime, self.partnerEndTime, self.playerCountDetailsPage)
        end
    end)
end

function NewClubPartnerLayer:RET_CLUB_PAGE_PLAYER_COUNT_FINISH(event)
    local data = event._usedata
    dump(data)

    if data.isFinish then
        self.playerCountState = 2
    else
        self.playerCountState = 1
    end
    self.playerCountPage = self.playerCountPage + 1
end

function NewClubPartnerLayer:RET_CLUB_PLAYER_COUNT_DETAILS(event)
    local data = event._usedata
    dump(data)

    local listView = self.ListView_pushPlayerCount
    if self.curPartnerPage == 5 then
        listView = self.ListView_partnerPushDes
    end

    local item = self.Panel_totalPushItem:clone()
    listView:pushBackCustomItem(item)
    local Text_room = self:seekWidgetByNameEx(item, "Text_room")
    local Text_playName = self:seekWidgetByNameEx(item, "Text_playName")
    local Text_juntan = self:seekWidgetByNameEx(item, "Text_juntan")
    local Text_fitigueGet = self:seekWidgetByNameEx(item, "Text_fitigueGet")
    local Text_yuanbaoGet = self:seekWidgetByNameEx(item, "Text_yuanbaoGet")
    local Text_time = self:seekWidgetByNameEx(item, "Text_time")
    Text_room:setColor(cc.c3b(131, 88, 45))
    Text_playName:setColor(cc.c3b(131, 88, 45))
    Text_juntan:setColor(cc.c3b(131, 88, 45))
    Text_fitigueGet:setColor(cc.c3b(131, 88, 45))
    Text_yuanbaoGet:setColor(cc.c3b(131, 88, 45))
    Text_time:setColor(cc.c3b(131, 88, 45))
    Text_room:setString(data.dwTableID)

    local playwayIdx = self:getPlayerWayIdx(data.dwPlayID)
    if playwayIdx and self.clubData.szParameterName[playwayIdx] then
        Text_playName:setString(self.clubData.szParameterName[playwayIdx])
    else
        Text_playName:setString(StaticData.Games[data.wKindID].name)
    end
    Text_juntan:setString(data.dwTargetFatigueTip)
    Text_fitigueGet:setString(data.dwTargetFatigueIncome)
    Text_yuanbaoGet:setString(data.dwTargetYuanBaoIncome)
    Text_time:setString(os.date("%Y-%m-%d\n%H:%M:%S",data.dwCreateDate))
end

function NewClubPartnerLayer:getPlayerWayIdx(dwPlayID)
    for i,v in ipairs(self.clubData.dwPlayID or {}) do
        if v == dwPlayID then
            return i
        end
    end
    return nil;
end

function NewClubPartnerLayer:RET_CLUB_PLAYER_COUNT_DETAILS_FINISH(event)
    local data = event._usedata
    dump(data)
    
    if data.isFinish then
        self.playerCountDetailsState = 2
    else
        self.playerCountDetailsState = 1
    end
    self.playerCountDetailsPage = self.playerCountDetailsPage + 1
end

function NewClubPartnerLayer:RET_PARTNER_EARNINGS(event)
    local data = event._usedata
    dump(data)
    if data.lRet ~= 0 then
        require("common.MsgBoxLayer"):create(0,nil,"获取收益统计失败！")
        return 
    end

    if self.clubData.dwUserID == UserData.User.userID then
        self.Text_sy_allcy:setString(data.dwTotalPersonTime)
        self.Text_sy_allfk:setString(data.dwTotalFatigueTip)
        local strFatigue = data.dwTotalFatigueIncome .. '/' .. data.dwTotalFatigueIncome-data.dwFatigueIncome .. '/' .. data.dwFatigueIncome
        local strYuanBao = data.dwTotalYuanBaoIncome .. '/' .. data.dwTotalYuanBaoIncome-data.dwYuanBaoIncome .. '/' .. data.dwYuanBaoIncome
        self.Text_sy_allFatigue:setString(strFatigue)
        self.Text_sy_allYuanbao:setString(strYuanBao)
    else
        self.Text_sy_allcy:setString(data.dwPersonTime)
        self.Text_sy_allfk:setString(data.dwFatigueTip)
        self.Text_sy_allFatigue:setString(data.dwFatigueIncome)
        self.Text_sy_allYuanbao:setString(data.dwYuanBaoIncome)
    end
    self.earningsPage = 1
    UserData.Guild:getPartnerPageEarnings(self.clubData.dwClubID, UserData.User.userID, self.beganTime, self.endTime, self.earningsPage)
end

function NewClubPartnerLayer:RET_PARTNER_PAGE_EARNINGS(event)
    local data = event._usedata
    dump(data)

    local item = self.Panel_leaderItem:clone()
    self.ListView_sy:pushBackCustomItem(item)
    local Text_time = self:seekWidgetByNameEx(item, "Text_time")
    local Text_allcount = self:seekWidgetByNameEx(item, "Text_allcount")
    local Text_allRoomCard = self:seekWidgetByNameEx(item, "Text_allRoomCard")
    local Text_allFatigue = self:seekWidgetByNameEx(item, "Text_allFatigue")
    local Text_allYuanbao = self:seekWidgetByNameEx(item, "Text_allYuanbao")
    Text_time:setColor(cc.c3b(131, 88, 45))
    Text_allcount:setColor(cc.c3b(131, 88, 45))
    Text_allRoomCard:setColor(cc.c3b(131, 88, 45))
    Text_allFatigue:setColor(cc.c3b(131, 88, 45))
    Text_allYuanbao:setColor(cc.c3b(131, 88, 45))
    
    if self.clubData.dwUserID == UserData.User.userID then
        Text_time:setString(os.date("%Y-%m-%d",data.dwCreateDate))
        Text_allcount:setString(data.dwTotalPersonTime)
        Text_allRoomCard:setString(data.dwTotalFatigueTip)
        local strFatigue = data.dwTotalFatigueIncome .. '/' .. data.dwTotalFatigueIncome-data.dwFatigueIncome .. '/' .. data.dwFatigueIncome
        local strYuanBao = data.dwTotalYuanBaoIncome .. '/' .. data.dwTotalYuanBaoIncome-data.dwYuanBaoIncome .. '/' .. data.dwYuanBaoIncome
        Text_allFatigue:setString(strFatigue)
        Text_allYuanbao:setString(strYuanBao)
    else
        Text_time:setString(os.date("%Y-%m-%d",data.dwCreateDate))
        Text_allcount:setString(data.dwPersonTime)
        Text_allRoomCard:setString(data.dwFatigueTip)
        Text_allFatigue:setString(data.dwFatigueIncome)
        Text_allYuanbao:setString(data.dwYuanBaoIncome)
    end
end

function NewClubPartnerLayer:RET_PARTNER_PAGE_EARNINGS_FINISH(event)
    local data = event._usedata
    dump(data)

    if data.isFinish then
        self.earningsReqState = 2
    else
        self.earningsReqState = 1
    end
    self.earningsPage = self.earningsPage + 1
end

--返回修改亲友圈成员
function NewClubPartnerLayer:RET_SETTINGS_CLUB_MEMBER(event)
    local data = event._usedata
    dump(data)
    if data.lRet ~= 0 then
        if data.lRet == 1 then
            require("common.MsgBoxLayer"):create(0,nil,"亲友圈不存在!")
        elseif data.lRet == 2 then
            require("common.MsgBoxLayer"):create(0,nil,"亲友圈成员不存在!")
        elseif data.lRet == 3 then
            require("common.MsgBoxLayer"):create(0,nil,"亲友圈合伙人已达人数上限!")
        elseif data.lRet == 4 then
            require("common.MsgBoxLayer"):create(0,nil,"普通成员才可以设置为合伙人!")
        elseif data.lRet == 5 then
            require("common.MsgBoxLayer"):create(0,nil,"您的权限不足!")
        elseif data.lRet == 6 then
            require("common.MsgBoxLayer"):create(0,nil,"权限不足,只有合伙人才能设置!")
        elseif data.lRet == 7 then
            require("common.MsgBoxLayer"):create(0,nil,"合伙人疲劳值不足!")
        elseif data.lRet == 8 then
            require("common.MsgBoxLayer"):create(0,nil,"目标玩家疲劳值不足!")
        elseif data.lRet == 9 then
            require("common.MsgBoxLayer"):create(0,nil,"合伙人的疲劳值不够扣!")
        elseif data.lRet == 10 then
            require("common.MsgBoxLayer"):create(0,nil,"参数错误!")
        elseif data.lRet == 11 then
            require("common.MsgBoxLayer"):create(0,nil,"比例超过最大限!")
        elseif data.lRet == 12 then
            require("common.MsgBoxLayer"):create(0,nil,"超层级上限不能设置合伙人!")
        elseif data.lRet == 13 then
            require("common.MsgBoxLayer"):create(0,nil,"防沉迷不等于0不得设置!")
        elseif data.lRet == 100 then
            require("common.MsgBoxLayer"):create(0,nil,"对局中不能减少疲劳值!")
        else
            require("common.MsgBoxLayer"):create(0,nil,"设置错误! code=" .. data.lRet)
        end
        return
    end

    if data.cbSettingsType == 3 then
        --设置合伙人
        local item = self.ListView_addParnter:getChildByName('addpartner' .. data.dwUserID)
        if item then
            item:removeFromParent()
        end

        local item = self.ListView_findAddParnter:getChildByName('addpartner' .. data.dwUserID)
        if item then
            item:removeFromParent()
        end
        require("common.MsgBoxLayer"):create(0,nil,"添加合伙人成功!")

    elseif data.cbSettingsType == 4 then
        --取消合伙人
        local item = self.ListView_myPartner:getChildByName('MyPartner_' .. data.dwUserID)
        if item then
            item:removeFromParent()
            require("common.MsgBoxLayer"):create(0,nil,"解除合伙人成功!")
            self:research()
        end

        local item = self.ListView_findMyPartner:getChildByName('MyPartner_' .. data.dwUserID)
        if item then
            item:removeFromParent()
            require("common.MsgBoxLayer"):create(0,nil,"解除合伙人成功!")
            self:research()
        end

    elseif data.cbSettingsType == 5 then
        --调配成员
        self:insertMyPushPartnerItme(data)

    elseif data.cbSettingsType == 10 then
        --解绑
        local item = self.ListView_pushMyPartner:getChildByName('MyPushPartner_' .. data.dwUserID)
        if item then
            item:removeFromParent()
            require("common.MsgBoxLayer"):create(0,nil,"解绑成员成功!")
        end
    end
end

function NewClubPartnerLayer:RET_CLUB_PARTNER_COUNT(event)
    local data = event._usedata
    dump(data)

    if data.lRet ~= 0 then
        require("common.MsgBoxLayer"):create(0,nil,"获取合伙人统计失败！")
        return
    end
    self.Text_partner_rc:setString(data.dwPeopleCount)
    self.Text_partner_fh:setString(data.dwTargetFatigueTip)
    self.Text_partner_yb:setString(data.dwTargetYuanBaoIncome)
    self.Text_partner_plz:setString(data.dwTargetFatigueIncome)
    self.Text_partner_dyj:setString(data.dwBigWinnerTime)
    self.Text_partner_totalJf:setString(data.lTotalScorePoint)
    self.partnerCountPage = 1
    if self.clubData.dwUserID == UserData.User.userID or self:isAdmin(UserData.User.userID) then
        UserData.Guild:getClubPagePartnerCount(self.clubData.dwClubID, 0, self.beganTime, self.endTime, 1)
    else
        UserData.Guild:getClubPagePartnerCount(self.clubData.dwClubID, UserData.User.userID, self.beganTime, self.endTime, 1)
    end
end

function NewClubPartnerLayer:RET_CLUB_PAGE_PARTNER_COUNT(event)
    local data = event._usedata
    dump(data)

    local item = self.Panel_partnerItem:clone()
    if data.dwUserID == UserData.User.userID then
        self.ListView_partnerTotal:insertCustomItem(item, 0)
    else
        self.ListView_partnerTotal:pushBackCustomItem(item)
    end
    
    local Image_head = self:seekWidgetByNameEx(item, "Image_head")
    local Text_name = self:seekWidgetByNameEx(item, "Text_name")
    local Text_renci = self:seekWidgetByNameEx(item, "Text_renci")
    local Text_roomnum = self:seekWidgetByNameEx(item, "Text_roomnum")
    local Text_yuanbao = self:seekWidgetByNameEx(item, "Text_yuanbao")
    local Text_fagute = self:seekWidgetByNameEx(item, "Text_fagute")
    local Text_dyj = self:seekWidgetByNameEx(item, "Text_dyj")
    local Text_sorce = self:seekWidgetByNameEx(item, "Text_sorce")
    local Button_push = self:seekWidgetByNameEx(item, "Button_push")
    Text_name:setColor(cc.c3b(131, 88, 45))
    Text_renci:setColor(cc.c3b(131, 88, 45))
    Text_roomnum:setColor(cc.c3b(131, 88, 45))
    Text_yuanbao:setColor(cc.c3b(131, 88, 45))
    Text_fagute:setColor(cc.c3b(131, 88, 45))
    Text_dyj:setColor(cc.c3b(131, 88, 45))
    Text_sorce:setColor(cc.c3b(131, 88, 45))

    Common:requestUserAvatar(data.dwUserID, data.szLogoInfo, Image_head, "img")
    Text_name:setString(data.szNickName)
    Text_roomnum:setString(data.dwTargetFatigueTip)
    Text_fagute:setString(data.dwTargetFatigueIncome)
    Text_yuanbao:setString(data.dwTargetYuanBaoIncome)
    Text_dyj:setString(data.dwBigWinnerTime)
    Text_renci:setString(data.dwPeopleCount)
    Text_sorce:setString(data.lTotalScorePoint)

    Common:addTouchEventListener(Button_push,function()
        self.Image_partnerTotal:setVisible(false)
        self.Image_partnerPushTotal:setVisible(true)
        self.Text_timeNode:setVisible(false)
        self.Image_findNode:setVisible(false)
        self.Panel_partnerCount:setVisible(true)
        Common:requestUserAvatar(data.dwUserID, data.szLogoInfo, self.Image_partnerPageHead, "img")
        self.Text_partnerPageName:setString(data.szNickName)
        self.Text_partnerPageID:setString('ID:' .. data.dwUserID)

        self.ListView_partnerPushTotal:removeAllItems()
        self.curSelLookDetailsPartner = data.dwUserID
        self.partnerCountDetailsPage = 1
        self.partnerCountDetailsState = 0
        if self.clubData.dwUserID == UserData.User.userID or self:isAdmin(UserData.User.userID) then
            UserData.Guild:getClubPartnerCountDetails(self.clubData.dwClubID, data.dwUserID, 0, self.beganTime, self.endTime, 1)
        else
            UserData.Guild:getClubPartnerCountDetails(self.clubData.dwClubID, UserData.User.userID, data.dwUserID, self.beganTime, self.endTime, 1)
        end

        self.curFindPartnerUser = data
    end)
end

function NewClubPartnerLayer:RET_CLUB_PAGE_PARTNER_COUNT_FINISH(event)
    local data = event._usedata
    dump(data)

    if data.isFinish then
        self.partnerCountState = 2
    else
        self.partnerCountState = 1
    end
    self.partnerCountPage = self.partnerCountPage + 1
end

function NewClubPartnerLayer:RET_CLUB_PARTNER_COUNT_DETAILS(event)
    local data = event._usedata
    dump(data)

    local item = self.Panel_partnerPushItem:clone()
    self.ListView_partnerPushTotal:pushBackCustomItem(item)

    local Text_time = self:seekWidgetByNameEx(item, "Text_time")
    local Text_renci = self:seekWidgetByNameEx(item, "Text_renci")
    local Text_roomnum = self:seekWidgetByNameEx(item, "Text_roomnum")
    local Text_fitigue = self:seekWidgetByNameEx(item, "Text_fitigue")
    local Text_yuanbao = self:seekWidgetByNameEx(item, "Text_yuanbao")
    local Button_push = self:seekWidgetByNameEx(item, "Button_push")
    Text_time:setColor(cc.c3b(131, 88, 45))
    Text_renci:setColor(cc.c3b(131, 88, 45))
    Text_roomnum:setColor(cc.c3b(131, 88, 45))
    Text_fitigue:setColor(cc.c3b(131, 88, 45))
    Text_yuanbao:setColor(cc.c3b(131, 88, 45))
    Text_time:setString(os.date("%Y-%m-%d",data.dwCreateDate))
    Text_renci:setString(data.dwPersonTime)
    Text_yuanbao:setString(data.dwYuanBaoIncome)
    Text_roomnum:setString(data.dwFatigueTip)
    Text_fitigue:setString(data.dwFatigueIncome)

    Common:addTouchEventListener(Button_push,function()
        self.Image_partnerPushTotal:setVisible(false)
        self.Image_partnerMemTotal:setVisible(true)
        self.ListView_partnerMemTotal:removeAllItems()
        local year,month,day = Common:getYMDHMS(data.dwCreateDate)
        self.partnerBeganTime = os.time({year=year, month=month, day=day,hour=0, min=0, sec=0})
        self.partnerEndTime = os.time({year=year, month=month, day=day,hour=23, min=59, sec=59})
        UserData.Guild:getClubAllPlayerCount(data.dwUserID, data.dwClubID, self.partnerBeganTime, self.partnerEndTime)
    end)
end

function NewClubPartnerLayer:RET_CLUB_PARTNER_COUNT_DETAILS_FINISH(event)
    local data = event._usedata
    dump(data)

    if data.isFinish then
        self.partnerCountDetailsState = 2
    else
        self.partnerCountDetailsState = 1
    end
    self.partnerCountDetailsPage = self.partnerCountDetailsPage + 1
end

function NewClubPartnerLayer:RET_GET_CLUB_NOT_PARTNER_MEMBER(event)
    local data = event._usedata
   	dump(data)
    local item = self.Image_parnterItem:clone()
    self.ListView_addParnter:pushBackCustomItem(item)
    item:setName('addpartner' .. data.dwUserID)
    self:setNotParnterMemberItem(item ,data)
end

function NewClubPartnerLayer:setNotParnterMemberItem(item,data)
    local Image_head = ccui.Helper:seekWidgetByName(item, "Image_head")
    local Text_name = ccui.Helper:seekWidgetByName(item, "Text_name")
    local Text_note = ccui.Helper:seekWidgetByName(item, "Text_note")
    local Text_playerid = ccui.Helper:seekWidgetByName(item, "Text_playerid")
    local Text_joinTime = ccui.Helper:seekWidgetByName(item, "Text_joinTime")
    local Text_lastTime = ccui.Helper:seekWidgetByName(item, "Text_lastTime")
    local Button_memCotrol = ccui.Helper:seekWidgetByName(item, "Button_memCotrol")
    Text_name:setColor(cc.c3b(131, 88, 45))
    Text_note:setColor(cc.c3b(131, 88, 45))
    Text_playerid:setColor(cc.c3b(131, 88, 45))
    Text_joinTime:setColor(cc.c3b(131, 88, 45))
    Text_lastTime:setColor(cc.c3b(131, 88, 45))
    Common:requestUserAvatar(data.dwUserID, data.szLogoInfo, Image_head, "img")
    Text_name:setString(data.szNickName)
    if data.szRemarks == "" or data.szRemarks == " " then
        Text_note:setString('备注:暂无')
    else
        Text_note:setString('备注:' .. data.szRemarks)
    end
    Text_playerid:setString('ID:' .. data.dwUserID)
    local time = os.date("*t", data.dwJoinTime)
    local joinTimeStr = string.format("加入时间:%d-%02d-%02d %02d:%02d:%02d",time.year,time.month,time.day,time.hour,time.min,time.sec)
    Text_joinTime:setString(joinTimeStr)
    local time = os.date("*t", data.dwLastLoginTime)
    local lastTimeStr = string.format("最近登入:%d-%02d-%02d %02d:%02d:%02d",time.year,time.month,time.day,time.hour,time.min,time.sec)
    Text_lastTime:setString(lastTimeStr)

    Common:addTouchEventListener(Button_memCotrol,function()
        --添加合伙人
        require("common.MsgBoxLayer"):create(1,nil,"您确定要添加合伙人？",function() 
            UserData.Guild:reqSettingsClubMember(3, data.dwClubID, data.dwUserID,0,"")
        end)
    end)
end

function NewClubPartnerLayer:RET_GET_CLUB_NOT_PARTNER_MEMBER_FINISH(event)
    local data = event._usedata
    dump(data)
    if data.isFinish then
        self.notPartnerMemState = 2
    else
        self.notPartnerMemState = 1
    end
    self.notPartnerMemIdx = self.notPartnerMemIdx + 1
end

function NewClubPartnerLayer:RET_FIND_CLUB_NOT_PARTNER_MEMBER(event)
    local data = event._usedata
    dump(data)
    if data.dwUserID ~= 0 then
        self.ListView_addParnter:setVisible(false)
        self.ListView_findAddParnter:setVisible(true)
        self.Button_findMem:setVisible(false)
        self.Button_findMemReturn:setVisible(true)
        self.ListView_findAddParnter:removeAllItems()
        local item = self.Image_parnterItem:clone()
        self.ListView_findAddParnter:pushBackCustomItem(item)
        item:setName('addpartner' .. data.dwUserID)
        self:setNotParnterMemberItem(item ,data)
    else
        require("common.MsgBoxLayer"):create(0,nil,"玩家ID不存在!")
    end
end

-- 合伙人设置配置
function NewClubPartnerLayer:RET_SETTINGS_CONFIG(event)
    local data = event._usedata
    dump(data)
    if data.lRet ~= 0 then
        require("common.MsgBoxLayer"):create(0,nil,"获取亲友圈模式类型失败!")
        return 
    end
    self.bDistributionModel = data.bDistributionModel
    self.isFirstEnter = true
    local userId = UserData.User.userID
    if self:isAdmin(UserData.User.userID) then
        userId = self.clubData.dwUserID
    end
    self:reqClubPartner(userId)
end

return NewClubPartnerLayer