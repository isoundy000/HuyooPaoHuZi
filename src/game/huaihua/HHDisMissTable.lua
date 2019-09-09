---------------
--   解散
---------------
local HHDisMissTable = class("HHDisMissTable", cc.load("mvc").ViewBase)
local GameCommon = require("game.huaihua.GameCommon")
local NetMgr = require("common.NetMgr")
local EventType = require("common.EventType")
local NetMsgId = require("common.NetMsgId")
local HHViewManager = require("game.huaihua.HHViewManager")
local ASSISTTIME = 180
function HHDisMissTable:onConfig()
	self.widget = {
		{'waite_time'},
		{'who_name'},
		{'name_state'},
		{'Button_agree', 'onAgreeCall'},
		{'Button_cancle', 'onCancleCall'},
		{'Panel_template'},
		{'ListView_chids'}
	}
end

function HHDisMissTable:onEnter()
	
end

function HHDisMissTable:onExit()
	if self.schedule then
		cc.Director:getInstance():getScheduler():unscheduleScriptEntry(self.schedule)
		self.schedule = nil
	end
end

function HHDisMissTable:onCreate(params)
	self.schedule = cc.Director:getInstance():getScheduler():scheduleScriptFunc(function(delta) self:update(delta) end, 1, false)
	self.passtime = ASSISTTIME
	self.isDisMiss = false
	self.count = 1
	self:setInfo(params)
end


function HHDisMissTable:onAgreeCall(...)
	NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER, NetMsgId.REQ_GR_DISMISS_TABLE_REPLY, "o", true)
end

function HHDisMissTable:onCancleCall(...)
	NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER, NetMsgId.REQ_GR_DISMISS_TABLE_REPLY, "o", false)
end

function HHDisMissTable:update(dt)
	self.passtime = self.passtime - dt
	if not self.isDisMiss then
		if self.passtime <= 0 then
			self.passtime = 0
			self.isDisMiss = true
		end
		self.waite_time:setString(math.floor(self.passtime))
	end
end

function HHDisMissTable:setInfo(params)
	local data = params[1]
	
	self.passtime = data.dwDisbandedTime
	self.waite_time:setString(string.format('%d', self.passtime))
	self:getCancleName(data)
end

function HHDisMissTable:popUpBox( name )
	local config = {
		content = name .. '拒绝解散房间',
		button1 = {'确定'},
	}
	HHViewManager.openBox(config)
end

--获取解散人的名
function HHDisMissTable:getCancleName(data)
	self.ListView_chids:removeAllChildren()
	local advocateName = ''
	local isOwner = false
	local player = GameCommon.player
	local charid = GameCommon:getRoleChairID()
	local uid = player[charid].dwUserID
	local playerId, name = self:disMissTableInfo(data)
	local isMine = uid == playerId
	self.Button_agree:setVisible(false)
	self.Button_cancle:setVisible(false)
	for i = 1, GameCommon.gameConfig.bPlayerCount do
		if data.dwUserIDALL[i] ~= 0 and player then
			if data.cbDisbandeState[i] == 1 then --不可操作
				if playerId ~= data.dwUserIDALL[i] then
					self:setString(data.szNickNameALL[i], '同意')
				end
				self:setOperateBtnState(false,data.dwUserIDALL[i]);
			elseif data.cbDisbandeState[i] == 2 then --拒绝
				self:setString(data.szNickNameALL[i], '拒绝')
				self:setOperateBtnState(false,data.dwUserIDALL[i]);
				self:runAction(cc.Sequence:create(cc.DelayTime:create(0), cc.CallFunc:create(function ( sender,event )
					self:popUpBox(data.szNickNameALL[i])
				end), cc.RemoveSelf:create()))
			else --还未操作
				if playerId ~= data.dwUserIDALL[i] then
					self:setString(data.szNickNameALL[i], '等待中')
				end
				self:setOperateBtnState(true,data.dwUserIDALL[i]);
			end
		end
	end
	
	if isMine then
		self.who_name:setString('您')
		self.name_state:setString('请等待!')
	else
		self.who_name:setString(name)
		self.name_state:setString('是否同意？')
	end
end

function HHDisMissTable:setOperateBtnState(isShow, playerid)
	local player = GameCommon.player
	local charid = GameCommon:getRoleChairID()
	local uid = player[charid].dwUserID
	if uid == playerid then
		self.Button_agree:setVisible(isShow)
		self.Button_cancle:setVisible(isShow)
	end
end

function HHDisMissTable:setString(name, state)
	local template = self.Panel_template:clone()
	local name_text = template:getChildByName('name')
	name_text:setString(name)
	name_text:setColor(cc.c3b(16,141,16))
	local state_text = template:getChildByName('name_state')
	state_text:setString(state)
	state_text:setColor(cc.c3b(255,255,255))
	self.ListView_chids:pushBackCustomItem(template)
end

function HHDisMissTable:disMissTableInfo(data)
	local disPlayerID = nil
	local advocateName = ''
	for i = 1, 3 do
		if data.dwUserIDALL[i] ~= 0 then
			if data.cbDisbandeState[i] == 1 then --已经同意
				if data.wAdvocateDisbandedID == i - 1 then
					disPlayerID = data.dwUserIDALL[i] --谁发起
					advocateName = data.szNickNameALL[i] --谁发起
					break
				end
			end
		end
	end
	return disPlayerID, advocateName
end


return HHDisMissTable 