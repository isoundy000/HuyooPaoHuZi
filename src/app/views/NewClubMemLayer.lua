--[[
*名称:NewClubMemLayer
*描述:成员界面
*作者:admin
*创建日期:2019-10-21 09:30:01
*修改日期:
]]

local EventMgr          = require("common.EventMgr")
local EventType         = require("common.EventType")
local NetMgr            = require("common.NetMgr")
local NetMsgId          = require("common.NetMsgId")
local StaticData        = require("app.static.StaticData")
local UserData          = require("app.user.UserData")
local Common            = require("common.Common")
local GameConfig        = require("common.GameConfig")

local MEMBER_NUM = 50 --成员每次请求数量

local NewClubMemLayer      = class("NewClubMemLayer", cc.load("mvc").ViewBase)

function NewClubMemLayer:onConfig()
    self.widget         = {
        {"Button_close", "onClose"},
        {"Text_memNum"},
        {"Text_onlineNum"},
        {"TextField_memID"},
        {"Button_findMem", "onFindMem"},
        {"Button_return", "onFindReturn"},
        {"ListView_mem"},
        {"ListView_find"},
        {"Image_find"},
        {"Image_item"},
    }
end

function NewClubMemLayer:onEnter()
	EventMgr:registListener(EventType.RET_GET_CLUB_MEMBER,self,self.RET_GET_CLUB_MEMBER)
	EventMgr:registListener(EventType.RET_GET_CLUB_MEMBER_FINISH,self,self.RET_GET_CLUB_MEMBER_FINISH)
	EventMgr:registListener(EventType.RET_FIND_CLUB_MEMBER ,self,self.RET_FIND_CLUB_MEMBER)
	EventMgr:registListener(EventType.RET_GET_CLUB_NOT_PARTNER_MEMBER ,self,self.RET_GET_CLUB_NOT_PARTNER_MEMBER)
    EventMgr:registListener(EventType.RET_GET_CLUB_NOT_PARTNER_MEMBER_FINISH ,self,self.RET_GET_CLUB_NOT_PARTNER_MEMBER_FINISH)
    EventMgr:registListener(EventType.RET_SETTINGS_CLUB_MEMBER ,self,self.RET_SETTINGS_CLUB_MEMBER)
    EventMgr:registListener(EventType.RET_SETTINGS_CLUB,self,self.RET_SETTINGS_CLUB)
    EventMgr:registListener(EventType.RET_REMOVE_CLUB_MEMBER,self,self.RET_REMOVE_CLUB_MEMBER)
    EventMgr:registListener(EventType.RET_CLUB_MEMBER_INFO ,self,self.RET_CLUB_MEMBER_INFO)
end

function NewClubMemLayer:onExit()
	EventMgr:unregistListener(EventType.RET_GET_CLUB_MEMBER,self,self.RET_GET_CLUB_MEMBER)
	EventMgr:unregistListener(EventType.RET_GET_CLUB_MEMBER_FINISH,self,self.RET_GET_CLUB_MEMBER_FINISH)
	EventMgr:unregistListener(EventType.RET_FIND_CLUB_MEMBER ,self,self.RET_FIND_CLUB_MEMBER)
	EventMgr:unregistListener(EventType.RET_GET_CLUB_NOT_PARTNER_MEMBER ,self,self.RET_GET_CLUB_NOT_PARTNER_MEMBER)
    EventMgr:unregistListener(EventType.RET_GET_CLUB_NOT_PARTNER_MEMBER_FINISH ,self,self.RET_GET_CLUB_NOT_PARTNER_MEMBER_FINISH)
    EventMgr:unregistListener(EventType.RET_SETTINGS_CLUB_MEMBER ,self,self.RET_SETTINGS_CLUB_MEMBER)
    EventMgr:unregistListener(EventType.RET_SETTINGS_CLUB,self,self.RET_SETTINGS_CLUB)
    EventMgr:unregistListener(EventType.RET_REMOVE_CLUB_MEMBER,self,self.RET_REMOVE_CLUB_MEMBER)
    EventMgr:unregistListener(EventType.RET_CLUB_MEMBER_INFO ,self,self.RET_CLUB_MEMBER_INFO)
end

function NewClubMemLayer:onCreate(param)
	self.clubData = param[1]
	self.userOffice = param[2]
	self.ListView_mem:addScrollViewEventListener(handler(self, self.listViewClubEventListen))
	self.Image_find:setVisible(true)
	self.ListView_mem:setVisible(true)
	self.ListView_find:setVisible(false)
    
    -- if self:isHasAdmin() then
    	self.memberReqState = 0 -- 0 请求中 1-请求结束 2--全部请求结束
    	self.curClubIndex = 0
        self:reqClubMember()
   --  else
   --      if self.userOffice == 2 then
   --          --普通成员
   --          self.Image_find:setVisible(false)
   --          self.ListView_mem:setVisible(false)
			-- self.ListView_find:setVisible(true)
   --          UserData.Guild:findClubMemInfo(self.clubData.dwClubID, UserData.User.userID)
   --      else
   --          --合伙人
   --          self.notPartnerMemState = 0
   --          self.notPartnerMemIdx = 1
   --          self:reqNotPartnerMember()
   --      end
   --  end
end

function NewClubMemLayer:onClose()
    self:removeFromParent()
end

function NewClubMemLayer:onFindMem()
	local playerid = tonumber(self.TextField_memID:getString())
    if playerid then
        -- if self:isHasAdmin() then
            UserData.Guild:reqClubMemberInfo(self.clubData.dwClubID, UserData.User.userID, 0, playerid, 1)
        -- else
        --     UserData.Guild:reqClubMemberInfo(self.clubData.dwClubID, UserData.User.userID, 2, playerid, 1)
        -- end
    else
        require("common.MsgBoxLayer"):create(0,nil,"玩家ID输入错误!")
    end
end

function NewClubMemLayer:onFindReturn()
    self.ListView_mem:setVisible(true)
    self.ListView_find:setVisible(false)
    self.Button_findMem:setVisible(true)
    self.Button_return:setVisible(false)
end

function NewClubMemLayer:listViewClubEventListen(sender, evenType)
	if evenType == ccui.ScrollviewEventType.scrollToBottom then
		-- if self:isHasAdmin() then
            if self.memberReqState == 1 then
                self.memberReqState = 0
                self:reqClubMember()
            end
        -- else
        --     if self.userOffice ~= 2 then
        --         --合伙人
        --         if self.notPartnerMemState == 1 then
        --             self.notPartnerMemState = 0
        --             self.notPartnerMemIdx = 1
        --             self:reqNotPartnerMember()
        --         end
        --     end
        -- end
    end
end

--------------------------------------------------
function NewClubMemLayer:reqClubMember()
    local startPos = self.curClubIndex + 1
    local endPos = startPos + MEMBER_NUM - 1
    UserData.Guild:getClubMember(self.clubData.dwClubID,startPos,endPos)
end

function NewClubMemLayer:reqNotPartnerMember()
    UserData.Guild:getClubNotPartnerMember(2, self.notPartnerMemIdx, self.clubData.dwClubID)
end

function NewClubMemLayer:isHasAdmin()
    return (self.clubData.dwUserID == UserData.User.userID) or self:isAdmin(UserData.User.userID)
end

function NewClubMemLayer:isAdmin(userid)
    for i,v in ipairs(self.clubData.dwAdministratorID or {}) do
        if v == userid then
            return true
        end
    end
    return false
end

function NewClubMemLayer:removeAdminInfo(userid)
    for i,v in ipairs(self.clubData.dwAdministratorID or {}) do
        if v == userid then
            self.clubData.dwAdministratorID[i] = 0
            break
        end
    end
end

function NewClubMemLayer:addMemItem(item, data)
	local Image_head = self:seekWidgetByNameEx(item, "Image_head")
    local Image_memFlag = self:seekWidgetByNameEx(item, 'Image_memFlag')
    local Text_state = self:seekWidgetByNameEx(item, "Text_state")
    local Text_name = self:seekWidgetByNameEx(item, "Text_name")
    local Text_id = self:seekWidgetByNameEx(item, "Text_id")
    local Text_remark = self:seekWidgetByNameEx(item, "Text_remark")
    local Text_joinTime = self:seekWidgetByNameEx(item, "Text_joinTime")
    local Text_lastTime = self:seekWidgetByNameEx(item, "Text_lastTime")
    local Text_partner = self:seekWidgetByNameEx(item, "Text_partner")
    Text_name:setColor(cc.c3b(131, 88, 45))
    Text_id:setColor(cc.c3b(131, 88, 45))
    Text_remark:setColor(cc.c3b(131, 88, 45))
    Text_joinTime:setColor(cc.c3b(131, 88, 45))
    Text_lastTime:setColor(cc.c3b(131, 88, 45))
    Text_partner:setColor(cc.c3b(131, 88, 45))
    Common:requestUserAvatar(data.dwUserID, data.szLogoInfo, Image_head, "img")
    Text_name:setString(Common:getShortName(data.szNickName, 14 , 7))

    if UserData.User.userID == self.clubData.dwUserID or self:isAdmin(UserData.User.userID)  then
        Text_id:setString(data.dwUserID)
    else
        Text_id:setString("******")
    end

    if data.szRemarks == "" or data.szRemarks == " " then
        Text_remark:setString('暂无')
    else
        Text_remark:setString(data.szRemarks)
    end

    if data.dwPartnerID ~= 0 then
        Text_partner:setVisible(true)
        Text_partner:setString(string.format('合伙人:%s(%d)', data.szPartnerNickName, data.dwPartnerID))
    else
        Text_partner:setVisible(false)
    end

    local time = os.date("*t", data.dwJoinTime)
    local joinTimeStr = string.format("加入时间:%d-%02d-%02d %02d:%02d:%02d",time.year,time.month,time.day,time.hour,time.min,time.sec)
    Text_joinTime:setString(joinTimeStr)
    local time = os.date("*t", data.dwLastLoginTime)
    local lastTimeStr = string.format("最近登入:%d-%02d-%02d %02d:%02d:%02d",time.year,time.month,time.day,time.hour,time.min,time.sec)
    Text_lastTime:setString(lastTimeStr)

    if data.cbOffice == 0 then
        Image_memFlag:setVisible(true)
        Image_memFlag:loadTexture('kwxclub/newclub_m22.png')
    elseif data.cbOffice == 1 then
        Image_memFlag:setVisible(true)
        Image_memFlag:loadTexture('kwxclub/newclub_m21.png')
    elseif data.cbOffice == 3 then
        Image_memFlag:setVisible(true)
        Image_memFlag:loadTexture('kwxclub/newclub_m23.png')
    else
        Image_memFlag:setVisible(false)
    end

    self.curOnlindeStatus = data.cbOnlineStatus
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

    if self:isHasAdmin() or (self.clubData.bIsPartnerRemoveMember and self.userOffice == 3) then
        item:setTouchEnabled(true)
        item:addClickEventListener(function() 
        	local node = require("app.MyApp"):create(data, self.clubData, self.userOffice):createView("NewClubMemberInfoLayer")
            self:addChild(node)
    	end)
    end
end

-------------------------------------------
--返回亲友圈成员列表
function NewClubMemLayer:RET_GET_CLUB_MEMBER(event)
    local data = event._usedata
    local item = self.Image_item:clone()
    self.ListView_mem:pushBackCustomItem(item)
    self.ListView_mem:refreshView()
    item:setName('member_' .. data.dwUserID)
	self:addMemItem(item, data)
end

--亲友群是否返回完成
function NewClubMemLayer:RET_GET_CLUB_MEMBER_FINISH( event )
    local data = event._usedata
    dump(data, 'RET_GET_CLUB_MEMBER_FINISH:')
    if data.isFinish then
        self.memberReqState = 2
    else
        self.memberReqState = 1
    end
    self.curClubIndex = self.curClubIndex + MEMBER_NUM
end

--返回查找亲友圈结果
function NewClubMemLayer:RET_FIND_CLUB_MEMBER(event)
    local data = event._usedata
    if data.lRet ~= 0 then 
        require("common.MsgBoxLayer"):create(0,nil,"亲友圈成员ID输入错误!")
        return
    end
    local item = self.Image_item:clone()
    self.ListView_find:pushBackCustomItem(item)
    self:addMemItem(item, data)
end

function NewClubMemLayer:RET_GET_CLUB_NOT_PARTNER_MEMBER(event)
    local data = event._usedata
    local item = self.Image_item:clone()
    self.ListView_mem:pushBackCustomItem(item)
    self.ListView_mem:refreshView()
    item:setName('member_' .. data.dwUserID)
	self:addMemItem(item, data)
end

function NewClubMemLayer:RET_GET_CLUB_NOT_PARTNER_MEMBER_FINISH(event)
    local data = event._usedata
    if data.isFinish then
        self.notPartnerMemState = 2
    else
        self.notPartnerMemState = 1
    end
    self.notPartnerMemIdx = self.notPartnerMemIdx + 1
end

--返回修改亲友圈成员
function NewClubMemLayer:RET_SETTINGS_CLUB_MEMBER(event)
    local data = event._usedata
    dump(data, 'RET_SETTINGS_CLUB_MEMBER:')
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
        elseif data.lRet == 100 then
            require("common.MsgBoxLayer"):create(0,nil,"对局中不能减少疲劳值")
        else
            require("common.MsgBoxLayer"):create(0,nil,"设置错误!")
        end
        return
    end

    if data.cbSettingsType == 0 then
        --禁赛
        local item = self.ListView_mem:getChildByName('member_' .. data.dwUserID)
        if item then
            local Text_state = self:seekWidgetByNameEx(item, "Text_state")
            Text_state:setColor(cc.c3b(255, 0, 0))
        	Text_state:setString('暂停娱乐')
        end
    elseif data.cbSettingsType == 1 then
        --恢复
        local item = self.ListView_mem:getChildByName('member_' .. data.dwUserID)
        if item then
        	local Text_state = self:seekWidgetByNameEx(item, "Text_state")
            if self.curOnlindeStatus == 1 then
		    	Text_state:setColor(cc.c3b(0, 128, 0))
		        Text_state:setString('在线')
		    elseif self.curOnlindeStatus == 2 or self.curOnlindeStatus == 0 then
		    	Text_state:setColor(cc.c3b(177, 177, 177))
		        Text_state:setString('离线')
		    elseif self.curOnlindeStatus == 100 then
		    	Text_state:setColor(cc.c3b(243, 130, 16))
		        Text_state:setString('对局中')
		    else
		        Text_state:setVisible(false)
		    end
        end
    elseif data.cbSettingsType == 2 then
        --修改备注
        local item = self.ListView_mem:getChildByName('member_' .. data.dwUserID)
        if item then
            local Text_remark = self:seekWidgetByNameEx(item, "Text_remark")
            if data.szRemarks == "" or data.szRemarks == " " then
                Text_remark:setString('暂无')
            else
                Text_remark:setString(data.szRemarks)
            end
            require("common.MsgBoxLayer"):create(0,nil,"修改备注成功")
        end
    end
end

--设置、取消管理员返回
function NewClubMemLayer:RET_SETTINGS_CLUB(event)
    local data = event._usedata
    if data.lRet ~= 0 then
        if data.lRet == 1 then
            require("common.MsgBoxLayer"):create(0,nil,"权限不足!")
        elseif data.lRet == 2 then
            require("common.MsgBoxLayer"):create(0,nil,"非合伙人和非合伙人成员才能设置为管理员!")
        elseif data.lRet == 3 then
            require("common.MsgBoxLayer"):create(0,nil,"管理员人数已达上限!")
        else
            require("common.MsgBoxLayer"):create(0,nil,"设置错误!")
        end
        return
    end

    if data.cbSettingsType == 0 then
        --设置管理员
        local item = self.ListView_mem:getChildByName('member_' .. data.dwTargetID)
        if item then
            local Image_memFlag = self:seekWidgetByNameEx(item, "Image_memFlag")
            Image_memFlag:setVisible(true)
            Image_memFlag:loadTexture('kwxclub/newclub_m21.png')
            self.clubData.dwAdministratorID = data.dwAdministratorID
        end
    elseif data.cbSettingsType == 1 then
        --取消管理员
        local item = self.ListView_mem:getChildByName('member_' .. data.dwTargetID)
        if item then
            local Image_memFlag = self:seekWidgetByNameEx(item, "Image_memFlag")
            Image_memFlag:setVisible(false)
            self.clubData.dwAdministratorID = data.dwAdministratorID
        end
    end
end

--返回剔除成员
function NewClubMemLayer:RET_REMOVE_CLUB_MEMBER(event)
    local data = event._usedata
    if data.lRet ~= 0 then
        require("common.MsgBoxLayer"):create(0,self,"踢出失败!")
        return
    end
    require("common.MsgBoxLayer"):create(0,self,"踢出成功!")
    self:removeAdminInfo(data.dwUserID)
    local item = self.ListView_mem:getChildByName('member_' .. data.dwUserID)
    if item then
        local index = self.ListView_mem:getIndex(item)
        self.ListView_mem:removeItem(index)
        self.ListView_mem:refreshView()
    end
end

function NewClubMemLayer:RET_CLUB_MEMBER_INFO(event)
    local data = event._usedata
    if data.dwClubID == 0 then
        require("common.MsgBoxLayer"):create(0,nil,"用户不存在!")
        return
    end
    
	self.ListView_find:removeAllItems()
    self.ListView_mem:setVisible(false)
    self.ListView_find:setVisible(true)
    self.Button_findMem:setVisible(false)
    self.Button_return:setVisible(true)
    local item = self.Image_item:clone()
    self.ListView_find:pushBackCustomItem(item)
    self:addMemItem(item, data)
end

return NewClubMemLayer