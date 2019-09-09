---------------
--   解散
---------------
local ZZDisMissTable = class("ZZDisMissTable", cc.load("mvc").ViewBase)
local GameCommon = require("game.zhuzhou.GameCommon")
local NetMgr = require("common.NetMgr")
local EventType = require("common.EventType")
local NetMsgId = require("common.NetMsgId")
local ASSISTTIME = 180
function ZZDisMissTable:onConfig()
	self.widget = {
		{'waite_time'},
		{'who_name'},
		{'name_state'},
		{'Panel_template'},
		{'ListView_chids'},
		{'Button_cancle','onCancleCall'},
		{'Button_agree','onAgreeCall'}
	}
end

function ZZDisMissTable:onEnter()
end

function ZZDisMissTable:onExit()
	if self.schedule then
		cc.Director:getInstance():getScheduler():unscheduleScriptEntry(self.schedule)
		self.schedule = nil
	end
end

function ZZDisMissTable:onCreate(params)
	self.schedule = cc.Director:getInstance():getScheduler():scheduleScriptFunc(function(delta) self:update(delta) end, 1, false)
	self.passtime = ASSISTTIME
	self.isDisMiss = false
	self.count = 1
	self:setInfo(params)
end


function ZZDisMissTable:onAgreeCall(...)
	NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER, NetMsgId.REQ_GR_DISMISS_TABLE_REPLY, "o", true)
end

function ZZDisMissTable:onCancleCall(...)
	NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER, NetMsgId.REQ_GR_DISMISS_TABLE_REPLY, "o", false)
end

function ZZDisMissTable:update(dt)
	self.passtime = self.passtime - dt
	if not self.isDisMiss then
		if self.passtime <= 0 then
			self.passtime = 0
			self.isDisMiss = true
			NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER, NetMsgId.REQ_GR_DISMISS_TABLE_REPLY, "o", true)
		end
		self.waite_time:setString(math.floor(self.passtime))
	end
end

function ZZDisMissTable:setInfo(params)
	local data = params[1]
	
	self.passtime = data.dwDisbandedTime
	self.waite_time:setString(string.format('%d', self.passtime))
	self:getCancleName(data)
end

--获取解散人的名
function ZZDisMissTable:getCancleName(data)
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
					self:setString(data.szNickNameALL[i],'同意解散')
				end
				self:setOperateBtnState(false,data.dwUserIDALL[i]);
			elseif data.cbDisbandeState[i] == 2 then --拒绝
				self:setString(data.szNickNameALL[i], '拒绝解散')
				self:setOperateBtnState(false,data.dwUserIDALL[i]);
				-- self:runAction(cc.Sequence:create(cc.DelayTime:create(1),cc.RemoveSelf:create()))
				self:runAction(cc.RemoveSelf:create())
			else --还未操作
				if playerId ~= data.dwUserIDALL[i] then
					self:setString(data.szNickNameALL[i], '等待选择')
				end
				self:setOperateBtnState(true,data.dwUserIDALL[i]);
			end
		end
	end
	
	if isMine then
		self.who_name:setString('您')
	else
		self.who_name:setString('玩家' .. name)
	end
	self.name_state:setString('等待其他玩家选择超过【180】秒未做选择')
end

function ZZDisMissTable:setOperateBtnState(isShow, playerid)
	local player = GameCommon.player
	local charid = GameCommon:getRoleChairID()
	local uid = player[charid].dwUserID
	if uid == playerid then
		self.Button_agree:setVisible(isShow)
		self.Button_cancle:setVisible(isShow)
	end
end

function ZZDisMissTable:setString(name, state)
	local template = self.Panel_template:clone()
	local name_text = template:getChildByName('name')
	name_text:setString('【' ..name .. '】' .. state)
	name_text:setColor(cc.c3b(211,145,23))
	self.ListView_chids:pushBackCustomItem(template)
end

function ZZDisMissTable:disMissTableInfo(data)
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


return ZZDisMissTable 