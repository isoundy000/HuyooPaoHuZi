--[[
*名称:NewClubSettingLayer
*描述:亲友圈设置
*作者:admin
*创建日期:2019-10-15 09:16:31
*修改日期:
]]

local EventMgr              = require("common.EventMgr")
local EventType             = require("common.EventType")
local NetMgr                = require("common.NetMgr")
local NetMsgId              = require("common.NetMsgId")
local StaticData            = require("app.static.StaticData")
local UserData              = require("app.user.UserData")
local Common                = require("common.Common")
local Bit 					= require("common.Bit")

local NewClubSettingLayer       = class("NewClubSettingLayer", cc.load("mvc").ViewBase)

function NewClubSettingLayer:onConfig()
    self.widget             = {
        {"Button_close", "onClose"},
        {"Button_base", "onBase"},
        {"Button_show", "onShow"},
        {"Button_hide", "onHide"},
        {"Button_partnerSet", "onPartnerSet"},
        {"Image_baseFrame"},
        {"Image_head"},
        {"TextField_name"},
        {"TextField_notice"},
        {"Button_modify", "onModify"},
        {"Button_liveClub", "onLiveClub"},
        {"Button_quitClub", "onQuitClub"},
        {"Image_showFrame"},
        {"Image_tableType1"},
        {"Image_tableType2"},
        {"Image_bgType1"},
        {"Image_bgType2"},
        {"Image_bgType3"},
        {"Image_bgType4"},
        {"Image_hideFrame"},
        {"ListView_hide"},
        {"Image_partnerFrame"},
        {"Image_one", "onOnePartner"},
        {"Image_two", "onMorePartner"},
        {"Image_three", "onThreePartner"},
        {"Button_oneSet", "onOneSet"},
        {"Text_one"},
        {"Text_oneValue"},
        {"Text_two"},
        {"Text_twoValue"},
        {"Button_twoSet", "onTwoSet"},
        {"Text_three"},
        {"Text_threeValue"},
        {"Button_threeSet", "onThreeSet"},
        {"Image_autoFatigue"},
        {"Image_autoYB"},
        {"Image_kick", "onPartnerKick"},
        {"Image_import", "onPartnerImport"},
        {"Image_leave", "onPartnerLeave"},
        {"Text_jtValue"},
        {"Button_jtSet", "onJTSet"},
        {"Button_save", "onPartnerSave"},

        {"Panel_oldMode"},
        {"Button_setPercent", "onSetPercent"},
    }
    self.curSelType = 0
end

function NewClubSettingLayer:onEnter()
	EventMgr:registListener(EventType.RET_REMOVE_CLUB,self,self.RET_REMOVE_CLUB)
	EventMgr:registListener(EventType.RET_QUIT_CLUB,self,self.RET_QUIT_CLUB)
	EventMgr:registListener(EventType.RET_SETTINGS_CLUB,self,self.RET_SETTINGS_CLUB)
	EventMgr:registListener(EventType.RET_SETTINGS_CONFIG ,self,self.RET_SETTINGS_CONFIG)
	EventMgr:registListener(EventType.RET_SETTINGS_PAPTNER ,self,self.RET_SETTINGS_PAPTNER)
end

function NewClubSettingLayer:onExit()
	EventMgr:unregistListener(EventType.RET_REMOVE_CLUB,self,self.RET_REMOVE_CLUB)
	EventMgr:unregistListener(EventType.RET_QUIT_CLUB,self,self.RET_QUIT_CLUB)
	EventMgr:unregistListener(EventType.RET_SETTINGS_CLUB,self,self.RET_SETTINGS_CLUB)
	EventMgr:unregistListener(EventType.RET_SETTINGS_CONFIG ,self,self.RET_SETTINGS_CONFIG)
	EventMgr:unregistListener(EventType.RET_SETTINGS_PAPTNER ,self,self.RET_SETTINGS_PAPTNER)
end

function NewClubSettingLayer:onCreate(param)
	self.clubData = param[1]
	self:switchType(0)
	if self.clubData.dwUserID == UserData.User.userID or self:isAdmin(UserData.User.userID) then
		self.Button_partnerSet:setVisible(true)
	else
		self.Button_partnerSet:setVisible(false)
	end

    if CHANNEL_ID == 26 or CHANNEL_ID == 27 then
        self.Button_partnerSet:setVisible(false)
    end
end

function NewClubSettingLayer:onClose()
    self:removeFromParent()
end

function NewClubSettingLayer:onBase()
	self:switchType(0)
end

function NewClubSettingLayer:onShow()
	self:switchType(1)
end

function NewClubSettingLayer:onHide()
	self:switchType(2)
end

function NewClubSettingLayer:onPartnerSet()
	self:switchType(3)
end

function NewClubSettingLayer:onModify()
	local isUseSave = false
	local nickName = self.TextField_name:getString()
    if nickName ~= "" and nickName ~= self.clubData.szClubName then
        NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_CLUB,NetMsgId.REQ_SETTINGS_CLUB3,"bdnsonsdod",
                3,self.clubData.dwClubID,32,nickName,false,256,"",0,false,0)
        isUseSave = true
    end

    local noticeStr = self.TextField_notice:getString()
    if noticeStr ~= self.clubData.szAnnouncement then
        NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_CLUB,NetMsgId.REQ_SETTINGS_CLUB3,"bdnsonsdod",
                5,self.clubData.dwClubID,32,nickName,false,256,noticeStr,0,false,0)
        isUseSave = true
    end

    if not isUseSave then
        require("common.MsgBoxLayer"):create(0,nil,"设置信息没有变化")
    end
end

function NewClubSettingLayer:onLiveClub()
	if self.clubData.dwUserID ~= UserData.User.userID then
        require("common.MsgBoxLayer"):create(1,nil,"您确定要退出亲友圈？",function() 
            UserData.Guild:quitClub(self.clubData.dwClubID)
        end)
    else
        require("common.MsgBoxLayer"):create(0,nil,"群主不能退出亲友圈")
    end
end

function NewClubSettingLayer:onQuitClub()
	require("common.MsgBoxLayer"):create(1,nil,"您确定要解散亲友圈？",function() 
        UserData.Guild:removeClub(self.clubData.dwClubID)
    end)
end

function NewClubSettingLayer:onOnePartner()
    self.Image_one:getChildByName('Image_light'):setVisible(true)
    self.Image_two:getChildByName('Image_light'):setVisible(false)
    self.Image_three:getChildByName('Image_light'):setVisible(false)
    self.Text_one:setVisible(true)
    self.Text_two:setVisible(false)
    self.Text_three:setVisible(false)
    self.Button_setPercent:setVisible(false)
end

function NewClubSettingLayer:onMorePartner()
    self.Image_one:getChildByName('Image_light'):setVisible(false)
    self.Image_two:getChildByName('Image_light'):setVisible(true)
    self.Image_three:getChildByName('Image_light'):setVisible(false)
    self.Text_one:setVisible(true)
    self.Text_two:setVisible(true)
    self.Text_three:setVisible(true)
    self.Button_setPercent:setVisible(false)
end

function NewClubSettingLayer:onThreePartner()
    self.Image_one:getChildByName('Image_light'):setVisible(false)
    self.Image_two:getChildByName('Image_light'):setVisible(false)
    self.Image_three:getChildByName('Image_light'):setVisible(true)
    self.Text_one:setVisible(false)
    self.Text_two:setVisible(false)
    self.Text_three:setVisible(false)
    self.Button_setPercent:setVisible(true)
end

function NewClubSettingLayer:onSetPercent()
    self:addChild(require("app.MyApp"):create(self.clubData, 4):createView("NewClubPartnerLayer"))
end

function NewClubSettingLayer:onOneSet()
    local node = require("app.MyApp"):create(0, 3, function(value)
        local twoStr = self.Text_twoValue:getString()
        local twoLen = string.len(twoStr)
        local threeStr = self.Text_threeValue:getString()
        local threeLen = string.len(threeStr)
        local twoValue = tonumber(string.sub(twoStr, 1, twoLen-1))
        local threeValue = tonumber(string.sub(threeStr, 1, threeLen-1))
        if value + twoValue + threeValue <= 100 then
            self.Text_oneValue:setString(value .. '%')
        else
            require("common.MsgBoxLayer"):create(0,nil,"总分成比例不能超过100%！")
        end
    end):createView("NewClubInputFatigueLayer")
    self:addChild(node)
end

function NewClubSettingLayer:onTwoSet()
    local node = require("app.MyApp"):create(0, 3, function(value) 
        local oneStr = self.Text_oneValue:getString()
        local oneLen = string.len(oneStr)
        local threeStr = self.Text_threeValue:getString()
        local threeLen = string.len(threeStr)
        local oneValue = tonumber(string.sub(oneStr, 1, oneLen-1))
        local threeValue = tonumber(string.sub(threeStr, 1, threeLen-1))
        if oneValue + value + threeValue <= 100 then
            self.Text_twoValue:setString(value .. '%')
        else
            require("common.MsgBoxLayer"):create(0,nil,"总分成比例不能超过100%！")
        end
    end):createView("NewClubInputFatigueLayer")
    self:addChild(node)
end

function NewClubSettingLayer:onThreeSet()
    local node = require("app.MyApp"):create(0, 3, function(value) 
        local oneStr = self.Text_oneValue:getString()
        local oneLen = string.len(oneStr)
        local twoStr = self.Text_twoValue:getString()
        local twoLen = string.len(twoStr)
        local oneValue = tonumber(string.sub(oneStr, 1, oneLen-1))
        local twoValue = tonumber(string.sub(twoStr, 1, twoLen-1))
        if oneValue + twoValue + value <= 100 then
            self.Text_threeValue:setString(value .. '%')
        else
            require("common.MsgBoxLayer"):create(0,nil,"总分成比例不能超过100%！")
        end
    end):createView("NewClubInputFatigueLayer")
    self:addChild(node)
end

function NewClubSettingLayer:onPartnerKick()
    if self.Image_kick:getChildByName('Image_light'):isVisible() then
        self.Image_kick:getChildByName('Image_light'):setVisible(false)
    else
        self.Image_kick:getChildByName('Image_light'):setVisible(true)
    end
end

function NewClubSettingLayer:onPartnerImport()
    if self.Image_import:getChildByName('Image_light'):isVisible() then
        self.Image_import:getChildByName('Image_light'):setVisible(false)
    else
        self.Image_import:getChildByName('Image_light'):setVisible(true)
    end
end

function NewClubSettingLayer:onPartnerLeave()
    if self.Image_leave:getChildByName('Image_light'):isVisible() then
        self.Image_leave:getChildByName('Image_light'):setVisible(false)
    else
        self.Image_leave:getChildByName('Image_light'):setVisible(true)
    end
end

function NewClubSettingLayer:onJTSet()
    local node = require("app.MyApp"):create(0, 3, function(value) 
        self.Text_jtValue:setString(value)
    end):createView("NewClubInputFatigueLayer")
    self:addChild(node)
end

function NewClubSettingLayer:onPartnerSave()
    local bMode = 0
    if self.Image_two:getChildByName('Image_light'):isVisible() then
        bMode = 1
    elseif self.Image_three:getChildByName('Image_light'):isVisible() then
        bMode = 2
    end

    local oneStr = self.Text_oneValue:getString()
    local oneLen = string.len(oneStr)
    local twoStr = self.Text_twoValue:getString()
    local twoLen = string.len(twoStr)
    local threeStr = self.Text_threeValue:getString()
    local threeLen = string.len(threeStr)
    local oneValue = tonumber(string.sub(oneStr, 1, oneLen-1))
    local twoValue = tonumber(string.sub(twoStr, 1, twoLen-1))
    local threeValue = tonumber(string.sub(threeStr, 1, threeLen-1))
    if bMode == 0 then
        twoValue = 0
        threeValue = 0
    end
    
    local isKick = false
    if self.Image_kick:getChildByName('Image_light'):isVisible() then
        isKick = true
    end

    local isImport = false
    if self.Image_import:getChildByName('Image_light'):isVisible() then
        isImport = true
    end

    local isLeave = false
    if self.Image_leave:getChildByName('Image_light'):isVisible() then
        isLeave = true
    end

    local jtValue = tonumber(self.Text_jtValue:getString())

    NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_CLUB,NetMsgId.REQ_SETTINGS_PARTNER, "dbbbboood", 
        self.clubData.dwClubID, bMode, oneValue, twoValue, threeValue, isKick, isImport, isLeave, jtValue)
end

function NewClubSettingLayer:switchType(itype)
	self.curSelType = itype
	if itype == 0 then
		self.Button_base:setBright(false)
		self.Button_show:setBright(true)
		self.Button_hide:setBright(true)
		self.Button_partnerSet:setBright(true)
		self.Image_baseFrame:setVisible(true)
		self.Image_showFrame:setVisible(false)
		self.Image_hideFrame:setVisible(false)
		self.Image_partnerFrame:setVisible(false)
		self:initBasePage()
	elseif itype == 1 then
		self.Button_base:setBright(true)
		self.Button_show:setBright(false)
		self.Button_hide:setBright(true)
		self.Button_partnerSet:setBright(true)
		self.Image_baseFrame:setVisible(false)
		self.Image_showFrame:setVisible(true)
		self.Image_hideFrame:setVisible(false)
		self.Image_partnerFrame:setVisible(false)
		self:initShowPage()
	elseif itype == 2 then
		self.Button_base:setBright(true)
		self.Button_show:setBright(true)
		self.Button_hide:setBright(false)
		self.Button_partnerSet:setBright(true)
		self.Image_baseFrame:setVisible(false)
		self.Image_showFrame:setVisible(false)
		self.Image_hideFrame:setVisible(true)
		self.Image_partnerFrame:setVisible(false)
		self:initHidePage()

	elseif itype == 3 then
		self.Button_base:setBright(true)
		self.Button_show:setBright(true)
		self.Button_hide:setBright(true)
		self.Button_partnerSet:setBright(false)
		self.Image_baseFrame:setVisible(false)
		self.Image_showFrame:setVisible(false)
		self.Image_hideFrame:setVisible(false)
		self.Image_partnerFrame:setVisible(true)
        self.Button_setPercent:setVisible(false)
		UserData.Guild:getPartnerConfig(UserData.User.userID, self.clubData.dwClubID)
	end

end

function NewClubSettingLayer:initBasePage()
	Common:requestUserAvatar(self.clubData.dwUserID, self.clubData.szLogoInfo, self.Image_head, "img")
    self.TextField_name:setString(self.clubData.szClubName)
    self.TextField_notice:setString(self.clubData.szAnnouncement)
    
    if self.clubData.dwUserID == UserData.User.userID then
		self.Button_quitClub:setVisible(true)
        self.Button_liveClub:setVisible(false)
        self.Button_modify:setVisible(true) 
    elseif self:isAdmin(UserData.User.userID) then
        self.Button_quitClub:setVisible(false)
        self.Button_liveClub:setVisible(true)
        self.Button_modify:setVisible(true) 
    else
        self.Button_quitClub:setVisible(false)
        self.Button_liveClub:setVisible(true)
        self.Button_modify:setVisible(false)
        self.Button_liveClub:setPositionX(self.Button_liveClub:getParent():getContentSize().width * 0.5)
        self.TextField_name:setTouchEnabled(false)
        self.TextField_name:setColor(cc.c3b(170,170,170))
        self.TextField_notice:setTouchEnabled(false)
        self.TextField_notice:setColor(cc.c3b(170,170,170))
    end

    if CHANNEL_ID == 26 or CHANNEL_ID == 27 then
        self.Button_liveClub:setVisible(false)
    end
end

function NewClubSettingLayer:initShowPage()
	local selectTable = cc.UserDefault:getInstance():getIntegerForKey('CurSelClubTable', 1)
	for i=1,2 do
		local item = self['Image_tableType' .. i]
		local Image_selLight = item:getChildByName('Image_selLight')
		if i == selectTable then
			Image_selLight:setVisible(true)
			self.lastSelTableBtn = Image_selLight
		else
			Image_selLight:setVisible(false)
		end

		item:setTouchEnabled(true)
	    item:addTouchEventListener(function(sender,event) 
	        if event == ccui.TouchEventType.ended then
	        	if self.lastSelTableBtn then
	        		self.lastSelTableBtn:setVisible(false)
	        	end
	        	self.lastSelTableBtn = Image_selLight
	        	Image_selLight:setVisible(true)
	        	cc.UserDefault:getInstance():setIntegerForKey('CurSelClubTable', i)
	        	EventMgr:dispatch(EventType.REFRESH_CLUB_BG,{table = i})
	        end
	    end)
	end


	local selectBg = cc.UserDefault:getInstance():getIntegerForKey('CurSelClubBg', 4)
	for i=1,4 do
		local item = self['Image_bgType' .. i]
		local Image_selLight = item:getChildByName('Image_selLight')
		if i == selectBg then
			Image_selLight:setVisible(true)
			self.lastSelBgBtn = Image_selLight
		else
			Image_selLight:setVisible(false)
		end

		item:setTouchEnabled(true)
	    item:addTouchEventListener(function(sender,event) 
	        if event == ccui.TouchEventType.ended then
	        	if self.lastSelBgBtn then
	        		self.lastSelBgBtn:setVisible(false)
	        	end
	        	self.lastSelBgBtn = Image_selLight
	        	Image_selLight:setVisible(true)
	        	cc.UserDefault:getInstance():setIntegerForKey('CurSelClubBg', i)
	        	EventMgr:dispatch(EventType.REFRESH_CLUB_BG,{bg = i})
	        end
	    end)
	end
end

function NewClubSettingLayer:initHidePage()
	local items = self.ListView_hide:getItems()
	if not (self.clubData.dwUserID == UserData.User.userID or self:isAdmin(UserData.User.userID)) then
       	for i,v in ipairs(items) do
       		if i > 2 then
       			v:removeFromParent()
       			v = nil
       		end
       	end
       	self.ListView_hide:setTouchEnabled(false)
    end

    if not (CHANNEL_ID == 26 or CHANNEL_ID == 27) then
        if items[8] then
            items[8]:removeFromParent()
        end
    end

	for i,v in ipairs(items) do
		local Image_selLeft = v:getChildByName('Image_selLeft')
		local Image_selRight = v:getChildByName('Image_selRight')
    	if i == 1 then
    		--桌子排序
    		local sortTable = cc.UserDefault:getInstance():getBoolForKey("Select_SortTable_Left", false)
    		if sortTable == true then
    			-- 空桌在前
    			Image_selLeft:getChildByName('Image_selLight'):setVisible(true)
				Image_selRight:getChildByName('Image_selLight'):setVisible(false)
    		else
    			-- 空桌在后
    			Image_selLeft:getChildByName('Image_selLight'):setVisible(false)
				Image_selRight:getChildByName('Image_selLight'):setVisible(true)
    		end

    	elseif i == 2 then
    		-- 隐藏玩法栏
    		local isShow = cc.UserDefault:getInstance():getBoolForKey("Is_Show_PlaywayLan", true)
    		if isShow == true then
    			Image_selLeft:getChildByName('Image_selLight'):setVisible(false)
				Image_selRight:getChildByName('Image_selLight'):setVisible(true)
    		else
    			Image_selLeft:getChildByName('Image_selLight'):setVisible(true)
				Image_selRight:getChildByName('Image_selLight'):setVisible(false)
    		end

    	elseif i == 3 then
    		 -- 亲友圈工作
    		if Bit:_and(0x01, self.clubData.bIsDisable) == 0x01 then
		        Image_selLeft:getChildByName('Image_selLight'):setVisible(false)
    			Image_selRight:getChildByName('Image_selLight'):setVisible(true)
		    else
		       	Image_selLeft:getChildByName('Image_selLight'):setVisible(true)
    			Image_selRight:getChildByName('Image_selLight'):setVisible(false)
		    end

		elseif i == 4 then
			-- 隐藏成员列表
		 	if Bit:_and(0x02, self.clubData.bIsDisable) == 0x02 then
		        Image_selLeft:getChildByName('Image_selLight'):setVisible(false)
    			Image_selRight:getChildByName('Image_selLight'):setVisible(true)
		    else
		       	Image_selLeft:getChildByName('Image_selLight'):setVisible(true)
    			Image_selRight:getChildByName('Image_selLight'):setVisible(false)
		    end

		elseif i == 5 then
			-- 隐藏亲友圈成员人数
    		if Bit:_and(0x04, self.clubData.bIsDisable) == 0x04 then
		        Image_selLeft:getChildByName('Image_selLight'):setVisible(false)
    			Image_selRight:getChildByName('Image_selLight'):setVisible(true)
		    else
		       	Image_selLeft:getChildByName('Image_selLight'):setVisible(true)
    			Image_selRight:getChildByName('Image_selLight'):setVisible(false)
		    end

		elseif i == 6 then
			-- 隐藏赠送
    		if Bit:_and(0x08, self.clubData.bIsDisable) == 0x08 then
		        Image_selLeft:getChildByName('Image_selLight'):setVisible(false)
    			Image_selRight:getChildByName('Image_selLight'):setVisible(true)
		    else
		       	Image_selLeft:getChildByName('Image_selLight'):setVisible(true)
    			Image_selRight:getChildByName('Image_selLight'):setVisible(false)
		    end

		elseif i == 7 then
			-- 隐藏扣费数量
    		if Bit:_and(0x10, self.clubData.bIsDisable) == 0x10 then
		        Image_selLeft:getChildByName('Image_selLight'):setVisible(false)
    			Image_selRight:getChildByName('Image_selLight'):setVisible(true)
		    else
		       	Image_selLeft:getChildByName('Image_selLight'):setVisible(true)
    			Image_selRight:getChildByName('Image_selLight'):setVisible(false)
		    end

        elseif i == 8 then
            -- 防沉迷开关
            if Bit:_and(0x20, self.clubData.bIsDisable) == 0x20 then
                Image_selLeft:getChildByName('Image_selLight'):setVisible(false)
                Image_selRight:getChildByName('Image_selLight'):setVisible(true)
            else
                Image_selLeft:getChildByName('Image_selLight'):setVisible(true)
                Image_selRight:getChildByName('Image_selLight'):setVisible(false)
            end

    	end

    	Image_selLeft:setTouchEnabled(true)
	    Image_selLeft:addTouchEventListener(function(sender,event) 
	        if event == ccui.TouchEventType.ended then
	        	Image_selLeft:getChildByName('Image_selLight'):setVisible(true)
	        	Image_selRight:getChildByName('Image_selLight'):setVisible(false)
	        	self:selectHideItem(i, true)
	        end
	    end)
	    Image_selRight:setTouchEnabled(true)
	    Image_selRight:addTouchEventListener(function(sender,event) 
	        if event == ccui.TouchEventType.ended then
	        	Image_selLeft:getChildByName('Image_selLight'):setVisible(false)
	        	Image_selRight:getChildByName('Image_selLight'):setVisible(true)
	        	self:selectHideItem(i, false)
	        end
	    end)  
	end
end

function NewClubSettingLayer:selectHideItem(index, isLeft)
	if index == 1 then
		cc.UserDefault:getInstance():setBoolForKey('Select_SortTable_Left', isLeft)
		EventMgr:dispatch(EventType.REFRESH_CLUB_BG,{isrefresh = true})
		require("common.MsgBoxLayer"):create(0,nil,"设置成功")

	elseif index == 2 then
		local isShow = not isLeft
		cc.UserDefault:getInstance():setBoolForKey('Is_Show_PlaywayLan', isShow)
		if isShow then
			EventMgr:dispatch(EventType.REFRESH_CLUB_BG,{bShowPlayway = 1})
		else
			EventMgr:dispatch(EventType.REFRESH_CLUB_BG,{bShowPlayway = 0})
		end
		require("common.MsgBoxLayer"):create(0,nil,"设置成功")

	elseif index == 3 then
		local bitVal = 0
		if isLeft then
			bitVal = Bit:_and(self.clubData.bIsDisable, 0xFE)
		else
			bitVal = Bit:_or(self.clubData.bIsDisable, 0x01)
		end
		NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_CLUB,NetMsgId.REQ_SETTINGS_CLUB3,"bdnsonsddd",
                6,self.clubData.dwClubID,32,nickName,false,256,"",0,bitVal,0)
	elseif index == 4 then
		local bitVal = 0
		if isLeft then
			bitVal = Bit:_and(self.clubData.bIsDisable, 0xFD)
		else
			bitVal = Bit:_or(self.clubData.bIsDisable, 0x02)
		end
		NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_CLUB,NetMsgId.REQ_SETTINGS_CLUB3,"bdnsonsddd",
                6,self.clubData.dwClubID,32,nickName,false,256,"",0,bitVal,0)

	elseif index == 5 then
		local bitVal = 0
		if isLeft then
			bitVal = Bit:_and(self.clubData.bIsDisable, 0xFB)
		else
			bitVal = Bit:_or(self.clubData.bIsDisable, 0x04)
		end
		NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_CLUB,NetMsgId.REQ_SETTINGS_CLUB3,"bdnsonsddd",
                6,self.clubData.dwClubID,32,nickName,false,256,"",0,bitVal,0)

	elseif index == 6 then
		local bitVal = 0
		if isLeft then
			bitVal = Bit:_and(self.clubData.bIsDisable, 0xF7)
		else
			bitVal = Bit:_or(self.clubData.bIsDisable, 0x08)
		end
		NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_CLUB,NetMsgId.REQ_SETTINGS_CLUB3,"bdnsonsddd",
                6,self.clubData.dwClubID,32,nickName,false,256,"",0,bitVal,0)

	elseif index == 7 then
		local bitVal = 0
		if isLeft then
			bitVal = Bit:_and(self.clubData.bIsDisable, 0xEF)
		else
			bitVal = Bit:_or(self.clubData.bIsDisable, 0x10)
		end
		NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_CLUB,NetMsgId.REQ_SETTINGS_CLUB3,"bdnsonsddd",
                6,self.clubData.dwClubID,32,nickName,false,256,"",0,bitVal,0)

    elseif index == 8 then
        local bitVal = 0
        if isLeft then
            bitVal = Bit:_and(self.clubData.bIsDisable, 0xDF)
        else
            bitVal = Bit:_or(self.clubData.bIsDisable, 0x20)
        end
        NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_CLUB,NetMsgId.REQ_SETTINGS_CLUB3,"bdnsonsddd",
                6,self.clubData.dwClubID,32,nickName,false,256,"",0,bitVal,0)

	end
end

function NewClubSettingLayer:isAdmin(userid, adminData)
    adminData = adminData or self.clubData.dwAdministratorID
    for i,v in ipairs(adminData or {}) do
        if v == userid then
            return true
        end
    end
    return false
end

----------------------------------------------
--亲友圈解散
function NewClubSettingLayer:RET_REMOVE_CLUB(event)
    local data = event._usedata
    if data.lRet ~= 0 then
        require("common.MsgBoxLayer"):create(0,nil,"解散亲友圈失败!")
        return
    end
    require("common.MsgBoxLayer"):create(0,nil,"解散亲友圈成功!")
    require("common.SceneMgr"):switchOperation()
    cc.UserDefault:getInstance():setIntegerForKey("UserDefault_NewClubID", 0)
end

--退出亲友圈
function NewClubSettingLayer:RET_QUIT_CLUB(event)
    local data = event._usedata
    if data.lRet ~= 0 then
        require("common.MsgBoxLayer"):create(0,nil,"退出亲友圈失败!")
        return
    end
    require("common.MsgBoxLayer"):create(0,nil,"退出亲友圈成功!")
    require("common.SceneMgr"):switchOperation()
    cc.UserDefault:getInstance():setIntegerForKey("UserDefault_NewClubID", 0)
end

--亲友圈设置返回
function NewClubSettingLayer:RET_SETTINGS_CLUB(event)
    local data = event._usedata
    dump(data)
    if data.lRet ~= 0 then
        require("common.MsgBoxLayer"):create(0,nil,"设置失败")
        return
    end
    require("common.MsgBoxLayer"):create(0,nil,"设置成功")
    UserData.Guild:refreshClub(data.dwClubID)
end

-- 合伙人设置配置
function NewClubSettingLayer:RET_SETTINGS_CONFIG(event)
    local data = event._usedata
    dump(data)
    if data.lRet ~= 0 then
        self.Image_partnerFrame:setVisible(false)
        require("common.MsgBoxLayer"):create(0,nil,"获取合伙人配置信息失败！")
        return 
    end

    if data.bDistributionModel == 0 then
        self.Image_one:getChildByName('Image_light'):setVisible(true)
        self.Image_two:getChildByName('Image_light'):setVisible(false)
        self.Image_three:getChildByName('Image_light'):setVisible(false)
        self.Text_one:setVisible(true)
        self.Text_two:setVisible(false)
        self.Text_three:setVisible(false)
        self.Button_setPercent:setVisible(false)
    elseif data.bDistributionModel == 1 then
        self.Image_one:getChildByName('Image_light'):setVisible(false)
        self.Image_two:getChildByName('Image_light'):setVisible(true)
        self.Image_three:getChildByName('Image_light'):setVisible(false)
        self.Text_one:setVisible(true)
        self.Text_two:setVisible(true)
        self.Text_three:setVisible(true)
        self.Button_setPercent:setVisible(false)
    else
        self.Image_one:getChildByName('Image_light'):setVisible(false)
        self.Image_two:getChildByName('Image_light'):setVisible(false)
        self.Image_three:getChildByName('Image_light'):setVisible(true)
        self.Text_one:setVisible(false)
        self.Text_two:setVisible(false)
        self.Text_three:setVisible(false)
        self.Button_setPercent:setVisible(true)
    end

    self.Text_oneValue:setString(data.bDistributionRatio1 .. '%')
    self.Text_twoValue:setString(data.bDistributionRatio2 .. '%')
    self.Text_threeValue:setString(data.bDistributionRatio3 .. '%')
    self.Image_autoFatigue:setColor(cc.c3b(170, 170, 170))
    self.Image_autoYB:setColor(cc.c3b(170, 170, 170))

    if data.bIsPartnerRemoveMember then
        self.Image_kick:getChildByName('Image_light'):setVisible(true)
    else
        self.Image_kick:getChildByName('Image_light'):setVisible(false)
    end

    if data.bIsPartnerImportMember then
        self.Image_import:getChildByName('Image_light'):setVisible(true)
    else
        self.Image_import:getChildByName('Image_light'):setVisible(false)
    end

    if data.bIsHaveFatigueNotLeave then
        self.Image_leave:getChildByName('Image_light'):setVisible(true)
    else
        self.Image_leave:getChildByName('Image_light'):setVisible(false)
    end

    self.Text_jtValue:setString(data.dwFatigueTip)
end

function NewClubSettingLayer:RET_SETTINGS_PAPTNER(event)
    local data = event._usedata
    if data.lRet ~= 0 then
        if data.lRet == 4 then
            require("common.MsgBoxLayer"):create(0,nil,"当前模式只支持三级，请取消三级以下的合伙人身份!")
        else
            require("common.MsgBoxLayer"):create(0,nil,"设置保存失败！ code="..data.lRet)
        end
        return
    end
    require("common.MsgBoxLayer"):create(0,nil,"设置保存成功！")
end

return NewClubSettingLayer