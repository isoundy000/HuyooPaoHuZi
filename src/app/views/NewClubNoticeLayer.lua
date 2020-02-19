--[[
*名称:NewClubNoticeLayer
*描述:亲友圈消息
*作者:admin
*创建日期:2019-10-11 14:10:05
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

local MEMBER_NUM 		= 15

local NewClubNoticeLayer = class("NewClubNoticeLayer", cc.load("mvc").ViewBase)

function NewClubNoticeLayer:onConfig()
    self.widget         = {
        {"Button_close", "onClose"},
        {"Button_base", "onBase"},
        {"Button_admin", "onAdmin"},
        {"Button_disable", "onDisable"},
        {"Button_partner", "onPartner"},
        {"Button_check", "onCheck"},
        {"Button_input", "onInput"},
        {"Panel_record"},
        {"ListView_record"},
        {"Panel_check"},
        {"ListView_check"},
        {"Panel_input"},
        {"ListView_input"},
        {"Image_noInputTips"},
        {"Text_tips"},
        {"Panel_input"},
        {"Button_addMem", "onAddMem"},
        {"Image_inputFrame"},
        {"Panel_item"},
        {"Image_checkItem"},
        {"Image_inputItem"},
    }
    self.curInputMemID = 0
    self.isRecordOver = false   --记录请求是否结束
    self.curRecordEndTime = 0   --记录上次请求结束时间
end

function NewClubNoticeLayer:onEnter()
	EventMgr:registListener(EventType.RET_CLUB_CHECK_LIST,self,self.RET_CLUB_CHECK_LIST)
	EventMgr:registListener(EventType.RET_CLUB_CHECK_RESULT,self,self.RET_CLUB_CHECK_RESULT)
	EventMgr:registListener(EventType.RET_CLUB_GROUP_INVITE_LOG ,self,self.RET_CLUB_GROUP_INVITE_LOG)
	EventMgr:registListener(EventType.RET_CLUB_GROUP_INVITE_REPLY ,self,self.RET_CLUB_GROUP_INVITE_REPLY)
	EventMgr:registListener(EventType.RET_GET_CLUB_MEMBER_EX,self,self.RET_GET_CLUB_MEMBER_EX)
	EventMgr:registListener(EventType.RET_GET_CLUB_MEMBER_EX_FINISH	,self,self.RET_GET_CLUB_MEMBER_EX_FINISH)
	EventMgr:registListener(EventType.RET_ADD_CLUB_MEMBER,self,self.RET_ADD_CLUB_MEMBER)
	EventMgr:registListener(EventType.RET_GET_CLUB_OPERATE_RECORD,self,self.RET_GET_CLUB_OPERATE_RECORD)
    EventMgr:registListener(EventType.RET_GET_CLUB_OPERATE_RECORD_FINISH,self,self.RET_GET_CLUB_OPERATE_RECORD_FINISH)
end

function NewClubNoticeLayer:onExit()
	EventMgr:unregistListener(EventType.RET_CLUB_CHECK_LIST,self,self.RET_CLUB_CHECK_LIST)
	EventMgr:unregistListener(EventType.RET_CLUB_CHECK_RESULT,self,self.RET_CLUB_CHECK_RESULT)
	EventMgr:unregistListener(EventType.RET_CLUB_GROUP_INVITE_LOG ,self,self.RET_CLUB_GROUP_INVITE_LOG)
	EventMgr:unregistListener(EventType.RET_CLUB_GROUP_INVITE_REPLY ,self,self.RET_CLUB_GROUP_INVITE_REPLY)
	EventMgr:unregistListener(EventType.RET_GET_CLUB_MEMBER_EX,self,self.RET_GET_CLUB_MEMBER_EX)
	EventMgr:unregistListener(EventType.RET_GET_CLUB_MEMBER_EX_FINISH	,self,self.RET_GET_CLUB_MEMBER_EX_FINISH)
	EventMgr:unregistListener(EventType.RET_ADD_CLUB_MEMBER,self,self.RET_ADD_CLUB_MEMBER)
	EventMgr:unregistListener(EventType.RET_GET_CLUB_OPERATE_RECORD,self,self.RET_GET_CLUB_OPERATE_RECORD)
    EventMgr:unregistListener(EventType.RET_GET_CLUB_OPERATE_RECORD_FINISH,self,self.RET_GET_CLUB_OPERATE_RECORD_FINISH)
end

function NewClubNoticeLayer:onCreate(param)
	self.clubData = param[1]
	local isRedPoint = param[2]
	if isRedPoint then
		self:switchType(4)
	else
		self:switchType(0)
	end
	
	self:initNumberArea()
    self.ListView_input:addScrollViewEventListener(handler(self, self.listViewInputMember))
    self.ListView_record:addScrollViewEventListener(handler(self, self.recordEventListen))
end

function NewClubNoticeLayer:onClose()
    self:removeFromParent()
end

function NewClubNoticeLayer:onBase()
	self:switchType(0)
end

function NewClubNoticeLayer:onAdmin()
	self:switchType(1)
end

function NewClubNoticeLayer:onDisable()
	self:switchType(2)
end

function NewClubNoticeLayer:onPartner()
	self:switchType(3)
end

function NewClubNoticeLayer:onCheck()
	self:switchType(4)
end

function NewClubNoticeLayer:onInput()
	self:switchType(5)
end

function NewClubNoticeLayer:onAddMem()
    local id = ""
    for i = 1 , 8 do
        local numName = string.format("Text_number%d", i)
        local Text_number = ccui.Helper:seekWidgetByName(self.Image_inputFrame, numName)
        if Text_number:getString() == "" then
            break
        else
            id = id .. Text_number:getString()
        end
    end

    local playerId = tonumber(id)
    if not playerId then
        require("common.MsgBoxLayer"):create(0,nil,"输入玩家ID不正确!")
        return
    end
    UserData.Guild:addClubMember(self.clubData.dwClubID, playerId, UserData.User.userID)
    self.curInputMemID = tonumber(id)
end

-- itype 0 基础记录 1 管理员记录 2 禁赛记录 3 合伙人记录 4 审核 5 导入
function NewClubNoticeLayer:switchType(itype)
	self.curSelType = itype
	if itype == 0 then
		self.Button_base:setBright(false)
		self.Button_admin:setBright(true)
		self.Button_disable:setBright(true)
		self.Button_partner:setBright(true)
		self.Button_check:setBright(true)
		self.Button_input:setBright(true)
		self.Panel_record:setVisible(true)
		self.Panel_check:setVisible(false)
		self.Panel_input:setVisible(false)
	elseif itype == 1 then
		self.Button_base:setBright(true)
		self.Button_admin:setBright(false)
		self.Button_disable:setBright(true)
		self.Button_partner:setBright(true)
		self.Button_check:setBright(true)
		self.Button_input:setBright(true)
		self.Panel_record:setVisible(true)
		self.Panel_check:setVisible(false)
		self.Panel_input:setVisible(false)
	elseif itype == 2 then
		self.Button_base:setBright(true)
		self.Button_admin:setBright(true)
		self.Button_disable:setBright(false)
		self.Button_partner:setBright(true)
		self.Button_check:setBright(true)
		self.Button_input:setBright(true)
		self.Panel_record:setVisible(true)
		self.Panel_check:setVisible(false)
		self.Panel_input:setVisible(false)
	elseif itype == 3 then
		self.Button_base:setBright(true)
		self.Button_admin:setBright(true)
		self.Button_disable:setBright(true)
		self.Button_partner:setBright(false)
		self.Button_check:setBright(true)
		self.Button_input:setBright(true)
		self.Panel_record:setVisible(true)
		self.Panel_check:setVisible(false)
		self.Panel_input:setVisible(false)
	elseif itype == 4 then
		self.Button_base:setBright(true)
		self.Button_admin:setBright(true)
		self.Button_disable:setBright(true)
		self.Button_partner:setBright(true)
		self.Button_check:setBright(false)
		self.Button_input:setBright(true)
		self.Panel_record:setVisible(false)
		self.Panel_check:setVisible(true)
		self.Panel_input:setVisible(false)
		self.ListView_check:removeAllItems()
        UserData.Guild:getClubCheckList(self.clubData.dwClubID)
        UserData.Guild:sendClubGroupInviteLog(UserData.User.userID, self.clubData.dwClubID)
	elseif itype == 5 then
		self.Button_base:setBright(true)
		self.Button_admin:setBright(true)
		self.Button_disable:setBright(true)
		self.Button_partner:setBright(true)
		self.Button_check:setBright(true)
		self.Button_input:setBright(false)
		self.Panel_record:setVisible(false)
		self.Panel_check:setVisible(false)
		self.Panel_input:setVisible(true)
		self.inputMemberState = 0 --0 请求中 1 请求结束 2 全部请求结束
        self.curInputMemberIndex = 0
        self.ListView_input:removeAllItems()
        self:reqInputMember()
	end

	if itype < 4 then
		self.ListView_record:removeAllItems()
        UserData.Guild:getClubCotrolRecord(self.clubData.dwClubID, 0)
	end
end

function NewClubNoticeLayer:isAdmin(userid)
    for i,v in ipairs(self.clubData.dwAdministratorID or {}) do
        if v == userid then
            return true
        end
    end
    return false
end

function NewClubNoticeLayer:reqInputMember()
    local startPos = self.curInputMemberIndex + 1
    local endPos = startPos + MEMBER_NUM - 1
    UserData.Guild:getClubExMember(self.clubData.dwClubID, UserData.User.userID,startPos,endPos)
end

function NewClubNoticeLayer:listViewInputMember(sender, evenType)
    if evenType == ccui.ScrollviewEventType.scrollToBottom then
        if self.inputMemberState == 1 then
            self.inputMemberState = 0
            self:reqInputMember()
        end
	end
end

function NewClubNoticeLayer:recordEventListen(sender, evenType)
    if evenType == ccui.ScrollviewEventType.scrollToBottom then
        if self.isRecordOver == true then
            self.isRecordOver = false
            UserData.Guild:getClubCotrolRecord(self.clubData.dwClubID, self.curRecordEndTime)
        end
    end
end

--------------------------------------------------------
--消息返回
--------------------------------------------------------
function NewClubNoticeLayer:RET_CLUB_CHECK_LIST(event)
    local data = event._usedata
    local item = self.Image_checkItem:clone()
    item:setVisible(true)
    self.ListView_check:pushBackCustomItem(item)
    item:setName('check_' .. data.dwUserID)
    local Image_head = self:seekWidgetByNameEx(item, "Image_head")
    local Text_name = self:seekWidgetByNameEx(item, "Text_name")
    local Text_playerid = self:seekWidgetByNameEx(item, "Text_playerid")
    local Text_tille = self:seekWidgetByNameEx(item, "Text_tille")
    local Text_applytime = self:seekWidgetByNameEx(item, "Text_applytime")
    local Button_yes = self:seekWidgetByNameEx(item, "Button_yes")
    local Button_no = self:seekWidgetByNameEx(item, "Button_no")
    Text_name:setColor(cc.c3b(159, 103, 47))
    Text_playerid:setColor(cc.c3b(159, 103, 47))
    Text_applytime:setColor(cc.c3b(159, 103, 47))
    Text_tille:setColor(cc.c3b(159, 103, 47))
    Common:requestUserAvatar(data.dwUserID, data.szLogoInfo, Image_head, "img")
    Text_name:setString(data.szNickName)
    Text_playerid:setString('ID:' .. data.dwUserID)
    local time = os.date("*t", data.dwJoinTime)
    local joinTimeStr = string.format("%d-%02d-%02d %02d:%02d:%02d",time.year,time.month,time.day,time.hour,time.min,time.sec)
    Text_applytime:setString(joinTimeStr)

    if self.clubData.dwUserID ~= UserData.User.userID and not self:isAdmin(UserData.User.userID) then
        Button_yes:setVisible(false)
        Button_no:setVisible(false)
    else
        Button_yes:setVisible(true)
        Button_no:setVisible(true)
        Button_yes:setPressedActionEnabled(true)
        Button_yes:addClickEventListener(function(sender)
            UserData.Guild:checkClubResult(data.dwClubID,data.dwUserID,true)
        end)

        Button_no:setPressedActionEnabled(true)
        Button_no:addClickEventListener(function(sender)
            UserData.Guild:checkClubResult(data.dwClubID,data.dwUserID,false)
        end)
    end
end

function NewClubNoticeLayer:RET_CLUB_CHECK_RESULT(event)
    local data = event._usedata
    if data.lRet ~= 0 then
        if data.lRet == 1 then
            require("common.MsgBoxLayer"):create(0,self,"人数已满!")
        else
            require("common.MsgBoxLayer"):create(0,self,"请求失败!")
        end
        return
    end
    if data.isAgree == true then
        require("common.MsgBoxLayer"):create(0,self,"操作成功,请到成员列表查看.")
    else
        require("common.MsgBoxLayer"):create(0,self,"操作成功.")
    end

    local item = self.ListView_check:getChildByName('check_' .. data.dwUserID)
    if item then
        local index = self.ListView_check:getIndex(item)
        self.ListView_check:removeItem(index)
        self.ListView_check:refreshView()
    end
end

function NewClubNoticeLayer:RET_CLUB_GROUP_INVITE_LOG(event)
    local data = event._usedata
    if data.lRet ~= 0 or data.dwClubID == 0 then
        return
    end

    local item = self.Image_checkItem:clone()
    item:setVisible(true)
    self.ListView_check:pushBackCustomItem(item)
    item:setName('inviteLog_' .. data.dwClubID)
    local Image_head = self:seekWidgetByNameEx(item, "Image_head")
    local Text_name = self:seekWidgetByNameEx(item, "Text_name")
    local Text_playerid = self:seekWidgetByNameEx(item, "Text_playerid")
    local Text_tille = self:seekWidgetByNameEx(item, "Text_tille")
    local Text_applytime = self:seekWidgetByNameEx(item, "Text_applytime")
    local Button_yes = self:seekWidgetByNameEx(item, "Button_yes")
    local Button_no = self:seekWidgetByNameEx(item, "Button_no")
    Text_name:setColor(cc.c3b(165, 61, 9))
    Text_playerid:setColor(cc.c3b(165, 61, 9))
    Text_applytime:setColor(cc.c3b(165, 61, 9))
    Text_tille:setColor(cc.c3b(165, 61, 9))
    Common:requestUserAvatar(data.dwUserID, data.szClubLogoInfo, Image_head, "img")
    Text_name:setString(data.szClubName)
    Text_playerid:setString('圈ID:' .. data.dwClubID)
    local time = os.date("*t", data.dwCreateData)
    local sendTimeStr = string.format("%d-%02d-%02d %02d:%02d:%02d",time.year,time.month,time.day,time.hour,time.min,time.sec)
    Text_applytime:setString(sendTimeStr)
    Text_tille:setString('向您发起亲友圈合并')

    if self.clubData.dwUserID ~= UserData.User.userID and not self:isAdmin(UserData.User.userID) then
        Button_yes:setVisible(false)
        Button_no:setVisible(false)
    else
        Button_yes:setVisible(true)
        Button_no:setVisible(true)
        Button_yes:setPressedActionEnabled(true)
        Button_yes:addClickEventListener(function(sender)
            local des = string.format("您确定与(%s:%d)亲友圈合并,所有玩家将为(%s)成员,您将成为(%s)亲友圈的合伙人?", data.szClubName, data.dwTargetClubID, data.szClubName, data.szClubName)
            require("common.MsgBoxLayer"):create(1,nil,des,function() 
                UserData.Guild:sendClubGroupInviteReply(UserData.User.userID, self.clubData.dwClubID, data.dwClubID, true)
            end)
        end)

        Button_no:setPressedActionEnabled(true)
        Button_no:addClickEventListener(function(sender)
            require("common.MsgBoxLayer"):create(1,nil,"您确定要拒绝亲友圈合并？",function() 
                UserData.Guild:sendClubGroupInviteReply(UserData.User.userID, self.clubData.dwClubID, data.dwClubID, false)
            end)
        end)
    end
end

function NewClubNoticeLayer:RET_CLUB_GROUP_INVITE_REPLY(event)
    local data = event._usedata
    local item = self.ListView_check:getChildByName('inviteLog_' .. data.dwTargetClubID)
    if item then
        item:removeFromParent()
    end

    if data.lRet ~= 0 then
        if data.lRet == 1 then
            require("common.MsgBoxLayer"):create(0,self,"亲友圈不存在!")
        elseif data.lRet == 2 then
            require("common.MsgBoxLayer"):create(0,self,"目标亲友圈不存在!")
        elseif data.lRet == 3 then
            require("common.MsgBoxLayer"):create(0,self,"权限不足!")
        elseif data.lRet == 4 then
            require("common.MsgBoxLayer"):create(0,self,"没有被邀请过!")
        elseif data.lRet == 5 then
            local des = string.format("两边都有同一合伙人(%s:%d),请先移除合伙人关系!", data.szNickName, data.dwSamePartnerID)
            require("common.MsgBoxLayer"):create(1,nil,des,function()
            end)
        else
            require("common.MsgBoxLayer"):create(0,self,"合群失败!")
        end
        return
    end
    require("common.MsgBoxLayer"):create(0,self,"操作成功！")
end

function NewClubNoticeLayer:RET_GET_CLUB_MEMBER_EX(event)
    local data = event._usedata
    local item = self.Image_inputItem:clone()
    item:setVisible(true)
    self.ListView_input:pushBackCustomItem(item)
    item:setName('input_' .. data.dwUserID)
    local Image_head     = self:seekWidgetByNameEx(item, "Image_head")
    local Text_name      = self:seekWidgetByNameEx(item, "Text_name")
    local Text_clubID    = self:seekWidgetByNameEx(item, "Text_clubID")
    local Button_input   = self:seekWidgetByNameEx(item, "Button_input")
    Text_name:setColor(cc.c3b(165, 61, 9))
    Text_clubID:setColor(cc.c3b(165, 61, 9))
    Common:requestUserAvatar(data.dwUserID, data.szLogoInfo, Image_head, "img")
    Text_name:setString(data.szNickName)
    Text_clubID:setString('ID:' .. data.dwUserID)

    Button_input:setPressedActionEnabled(true)
    Button_input:addClickEventListener(function(sender)
        UserData.Guild:addClubMember(self.clubData.dwClubID, data.dwUserID, UserData.User.userID)
    end)
end

function NewClubNoticeLayer:RET_GET_CLUB_MEMBER_EX_FINISH(event)
    local data = event._usedata
    if data.isFinish then
        self.inputMemberState = 2
    else
        self.inputMemberState = 1
    end
    self.curInputMemberIndex = self.curInputMemberIndex + MEMBER_NUM
    local isShow = (self.ListView_input:getChildrenCount () <= 0)
    self.Image_noInputTips:setVisible(isShow)
end

function NewClubNoticeLayer:RET_ADD_CLUB_MEMBER(event)
    local data = event._usedata
    if data.lRet ~= 0 then
        if data.lRet == 1 then
            require("common.MsgBoxLayer"):create(0,self,"ID输入错误!")
        elseif data.lRet == 2 then
            require("common.MsgBoxLayer"):create(0,self,"该成员已在亲友圈内，请勿重复操作!")
        elseif data.lRet == 3 then
            require("common.MsgBoxLayer"):create(0,self,"玩家不存在!")
        elseif data.lRet == 4 then
            require("common.MsgBoxLayer"):create(0,self,"您没有权限导入！")
        elseif data.lRet == 5 then
            require("common.MsgBoxLayer"):create(0,self,"人数已满!")
        else
            require("common.MsgBoxLayer"):create(0,self,"请升级游戏版本!")
        end
        return
    end

    require("common.MsgBoxLayer"):create(0,self,"导入成功.")
    local item = self.ListView_input:getChildByName('input_' .. data.dwUserID)
    if item then
        local index = self.ListView_input:getIndex(item)
        self.ListView_input:removeItem(index)
        self.ListView_input:refreshView()
        local count = self.ListView_input:getChildrenCount()
        if count <= 0 then
            if self.inputMemberState == 1 then
                self.inputMemberState = 0
                self:reqInputMember()
            elseif self.inputMemberState == 2 then
            	self.Image_noInputTips:setVisible(true)
            end
        end
    end

    if self.curInputMemID == data.dwUserID then
    	self.curInputMemID = 0
    	self:resetNumber()
    end

    --合伙人添加成员
    -- if self.Image_partnerFrame:isVisible() then
    --     local event = {}
    --     event._usedata = data
    --     self:RET_GET_CLUB_PARTNER_MEMBER(event)
    -- end
end

function NewClubNoticeLayer:getRecordDes(data)
    local des = ""
    if data.cbType == 0 then
        des = string.format('设置【ID:%s】成管理员', data.szParameter)
    elseif data.cbType == 1 then
        des = string.format('取消【ID:%s】的管理员', data.szParameter)
    elseif data.cbType == 2 then
        local wKindID = tonumber(data.szParameter)
        des = '修改了玩法：' .. StaticData.Games[wKindID].name
    elseif data.cbType == 3 then
        des = '修改亲友圈昵称为：' .. data.szParameter
    elseif data.cbType == 4 then
        if data.szParameter == "1" then
            des = '开启了自定义房'
        else
            des = '关闭了自定义房'
        end
    elseif data.cbType == 5 then
        des = '修改了公告'
    
    elseif data.cbType == 20 then
        local wKindID = tonumber(data.szParameter)
        des = '添加了玩法：' .. StaticData.Games[wKindID].name
    elseif data.cbType == 21 then
        local wKindID = tonumber(data.szParameter)
        des = '删除了玩法：' .. StaticData.Games[wKindID].name
    elseif data.cbType == 22 then
        local wKindID = tonumber(data.szParameter)
        des = '修改玩法为：' .. StaticData.Games[wKindID].name
    
    elseif data.cbType == 100 then
        des = '创建了亲友圈：' .. data.szParameter
    elseif data.cbType == 101 then
        des = '退出了亲友圈'
    elseif data.cbType == 102 then
        des = string.format('解散了【%s】房间', data.szParameter)
    elseif data.cbType == 103 then
        des = string.format('导入成员【ID:%s】加入亲友圈', data.szParameter)
    elseif data.cbType == 104 then
        des = string.format('踢出成员【ID:%s】', data.szParameter)
    elseif data.cbType == 105 then
        des = string.format('同意成员【ID:%s】加入亲友圈', data.szParameter)
    elseif data.cbType == 106 then
        des = string.format('拒绝成员【ID:%s】加入亲友圈', data.szParameter)
    
    elseif data.cbType == 30 then
        des = '禁止了【ID:' .. data.szParameter .. '】比赛'
    elseif data.cbType == 31 then
        des = '恢复了【ID:' .. data.szParameter .. '】比赛'
    elseif data.cbType == 32 then
        local splitArr = Common:stringSplit(data.szParameter, "|")
        des = '修改【' .. splitArr[1] .. '】的备注为:' .. splitArr[2]
    elseif data.cbType == 33 then
        des = '设置【ID:' .. data.szParameter .. '】为合伙人'
    elseif data.cbType == 34 then
        des = '取消【ID:' .. data.szParameter .. '】合伙人'
    elseif data.cbType == 35 then
        des = '关联【' .. data.szParameter .. '】合伙人'
    elseif data.cbType == 36 then
        -- local splitArr = Common:stringSplit(data.szParameter, "|")
        -- des = '修改【ID:' .. splitArr[1] .. '】疲劳值为:' .. splitArr[2]
        des = '解绑【' .. data.szParameter .. '】合伙人'
    elseif data.cbType == 37 then
        local splitArr = Common:stringSplit(data.szParameter, "|")
        des = '合伙人' .. '(' .. data.szNickName .. ')【ID:' .. data.dwUserID .. '】'
        des = '修改成员【ID:' .. splitArr[1] .. '】疲劳值:' .. splitArr[2]
    elseif data.cbType == 38 then
        local splitArr = Common:stringSplit(data.szParameter, "|")
        des = '修改【ID:' .. splitArr[1] .. '】疲劳值为:' .. splitArr[2]
    end
    return des
end

function NewClubNoticeLayer:RET_GET_CLUB_OPERATE_RECORD(event)
    local data = event._usedata
    local item = self.Panel_item:clone()
    local Text_time = item:getChildByName('Text_time')
    local Text_office = item:getChildByName('Text_office')
    local Text_name = item:getChildByName('Text_name')
    local Text_id = item:getChildByName('Text_id')
    local Text_content = item:getChildByName('Text_content')
    Text_time:setColor(cc.c3b(131, 88, 45))
    Text_office:setColor(cc.c3b(131, 88, 45))
    Text_name:setColor(cc.c3b(131, 88, 45))
    Text_id:setColor(cc.c3b(131, 88, 45))
    Text_content:setColor(cc.c3b(131, 88, 45))
    local timeStr = os.date('%m-%d %H:%M', data.dwTime)
    Text_time:setString(timeStr)
    if self.clubData.dwUserID == data.dwUserID then
    	Text_office:setString('圈主')
    elseif self:isAdmin(data.dwUserID) then
    	Text_office:setString('管理员')
    else
        Text_office:setString('玩家')
    end
    Text_name:setString(data.szNickName)
    Text_id:setString(data.dwUserID)

    if self.curSelType == 0 and data.cbType ~= 0 and data.cbType ~= 1 
    	and data.cbType ~= 30 and data.cbType ~= 31 and data.cbType ~= 33 and data.cbType ~= 34 and data.cbType ~= 35 and data.cbType ~= 36 then
		--0 基础记录
        self.ListView_record:pushBackCustomItem(item)
        local des = self:getRecordDes(data)
        Text_content:setString(des)
    elseif self.curSelType == 1 and (data.cbType == 0 or data.cbType == 1) then
    	--1 管理员记录
        self.ListView_record:pushBackCustomItem(item)
        local des = self:getRecordDes(data)
        Text_content:setString(des)
	elseif self.curSelType == 2 and (data.cbType == 30 or data.cbType == 31) then
		--2 禁赛记录
        self.ListView_record:pushBackCustomItem(item)
        local des = self:getRecordDes(data)
        Text_content:setString(des)
	elseif self.curSelType == 3 and (data.cbType == 33 or data.cbType == 34 or data.cbType == 35 or data.cbType == 36) then
		--3 合伙人记录
        self.ListView_record:pushBackCustomItem(item)
        local des = self:getRecordDes(data)
        Text_content:setString(des)
    end
    self.curRecordEndTime = data.dwTime
end

function NewClubNoticeLayer:RET_GET_CLUB_OPERATE_RECORD_FINISH(event)
    local data = event._usedata
    if data.isEnd == false then
        self.isRecordOver = true
    else
        self.isRecordOver = false
    end
end

--------------------------------------------------------
--数字键盘
--------------------------------------------------------
function NewClubNoticeLayer:initNumberArea()
    self:resetNumber()

    local function onEventInput(sender,event)
        if event == ccui.TouchEventType.ended then
            Common:palyButton()
            local index = sender.index
            if index == 10 then
                self:resetNumber()
            elseif index == 11 then
                self:deleteNumber()
            else
                self:inputNumber(index)
            end
        end
    end

    for i = 0 , 11 do
        local btnName = string.format("Button_num%d", i)
        local Button_num = ccui.Helper:seekWidgetByName(self.Image_inputFrame, btnName)
        Button_num:setPressedActionEnabled(true)
        Button_num:addTouchEventListener(onEventInput)
        Button_num.index = i
    end
end

--重置数字
function NewClubNoticeLayer:resetNumber()
    for i = 1 , 8 do
        local numName = string.format("Text_number%d", i)
        local Text_number = ccui.Helper:seekWidgetByName(self.Image_inputFrame, numName)
        if Text_number then
            Text_number:setString("")
        end
    end
    self.Text_tips:setVisible(true)
end

--输入数字
function NewClubNoticeLayer:inputNumber(num)
    local roomNumber = ""
    for i = 1 , 8 do
        local numName = string.format("Text_number%d", i)
        local Text_number = ccui.Helper:seekWidgetByName(self.Image_inputFrame, numName)
        if Text_number:getString() == "" then
            Text_number:setString(tostring(num))
            roomNumber = roomNumber .. Text_number:getString()
            if i == 8 then
                -- UserData.Guild:addClubMember(self.clubData.dwClubID, tonumber(roomNumber), UserData.User.userID)
            end
            break
        else
            roomNumber = roomNumber .. Text_number:getString()
        end
    end
    self.Text_tips:setVisible(false)
end

--删除数字
function NewClubNoticeLayer:deleteNumber()
	local delIndex = 0
    for i = 8 , 1 , -1 do
        local numName = string.format("Text_number%d", i)
        local Text_number = ccui.Helper:seekWidgetByName(self.Image_inputFrame, numName)
        if Text_number:getString() ~= "" then
            Text_number:setString("")
            delIndex = i
            break
        end
    end
    if delIndex <= 1 then
    	self.Text_tips:setVisible(true)
    end
end

return NewClubNoticeLayer