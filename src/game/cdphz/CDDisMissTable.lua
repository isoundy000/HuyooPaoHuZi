---------------
--   解散
---------------
local CDDisMissTable = class("CDDisMissTable", cc.load("mvc").ViewBase)
local GameCommon = require("game.cdphz.GameCommon")
local NetMgr = require("common.NetMgr")
local EventType = require("common.EventType")
local NetMsgId = require("common.NetMsgId")
local ASSISTTIME = 180 --
function CDDisMissTable:onConfig()
	self.widget = {
		{'who_name'},
		{'name_auto'},
		{'Button_agree', 'onAgreeCall'},
		{'Button_cancle', 'onCancleCall'},
		{'close', 'onCloseCall'},
		{'ListView_state'},
		{'name_template'}
	}
end

function CDDisMissTable:onEnter()
	self.isRelease = false
end

function CDDisMissTable:onExit()
	if self.schedule then
		cc.Director:getInstance():getScheduler():unscheduleScriptEntry(self.schedule)
		self.schedule = nil
	end
	self.isRelease = true
end

function CDDisMissTable:onCreate(params)
	self.schedule = cc.Director:getInstance():getScheduler():scheduleScriptFunc(function(delta) self:update(delta) end, 1, false)
	self.passtime = ASSISTTIME
	self.isDisMiss = false
	self.isMine = false
	self.count = 1
	self:setInfo(params)
end

function CDDisMissTable:onAgreeCall(...)
	self:agree()

end

function CDDisMissTable:onCancleCall(...)
	if not self.isMine then
		NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER, NetMsgId.REQ_GR_DISMISS_TABLE_REPLY, "o", false)
	end
	self:safeRelease()
end

function CDDisMissTable:onCloseCall(...)
	self:safeRelease()
end

function CDDisMissTable:update(dt)
	self.passtime = self.passtime - dt
	if not self.isDisMiss then
		if self.passtime <= 0 then
			self.passtime = 0
			self.isDisMiss = true
		end
		self:updateTime()
	end
	if self.isDisMiss then
		self:safeRelease()
	end
end

function CDDisMissTable:setInfo(params)
	local data = params[1]
	
	self.passtime = data.dwDisbandedTime
	self:updateTime()
	self:initInfo(data)
end

function CDDisMissTable:updateTime(...)
	local name = string.format("将在%d秒之后自动同意", math.floor(self.passtime))
	self.name_auto:setString(name)
end

function CDDisMissTable:agree()
	if self.isMine then
		return
	end
	local unAgreeCall = function(...)
		NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER, NetMsgId.REQ_GR_DISMISS_TABLE_REPLY, "o", false)
	end
	local agreeCall = function(...)
		if not self.isDisMiss then
			NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER, NetMsgId.REQ_GR_DISMISS_TABLE_REPLY, "o", true)
		end
	end
	local config = {
		content = '是否同意解散房间？',
		closeState = 2,
		button1 = {'拒绝', unAgreeCall},
		button2 = {'同意', agreeCall}
	}
	self:openBox(config)
	self:safeRelease()
end

function CDDisMissTable:safeRelease( ... )
	if not self.isRelease then
		self:removeFromParent()
	end
end

function CDDisMissTable:openBox(params)
	local path = 'game.cdphz.CDNoticeBox'
	local box = require("app.MyApp"):create(params):createGame(path)
	require("common.SceneMgr"):switchTips(box)
end

--获取解散人的名
function CDDisMissTable:initInfo(data)
	self.ListView_state:removeAllChildren()
	local advocateName = ''
	local isOwner = false
	local player = GameCommon.player
	local charid = GameCommon:getRoleChairID()
	local uid = player[charid].dwUserID
	local playerId, name = self:disMissTableInfo(data)
	local isMine = uid == playerId
	self.isMine = isMine
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
				self:runAction(cc.Sequence:create(cc.DelayTime:create(1), cc.RemoveSelf:create()))
			else --还未操作
				if playerId ~= data.dwUserIDALL[i] then
					self:setString(data.szNickNameALL[i], '等待选择')
				end
				self:setOperateBtnState(true,data.dwUserIDALL[i]);
			end
		end
	end
	
	if isMine then
		self.who_name:setString('等待其他玩家投票。')
	else
		self.who_name:setString(name .. '申请解散房间')
	end
end


function CDDisMissTable:initBtn()
	self.Button_agree:setVisible(true)
	self.Button_cancle:setVisible(not self.isMine)
	if self.isMine then
		local des = self.Button_agree:getChildByName('des')
		des:setString('确定')
		self.Button_agree:setPosition(285,63)
	else
		local des = self.Button_agree:getChildByName('des')
		des:setString('同意')
		local des1 = self.Button_cancle:getChildByName('des')
		des1:setString('拒绝')
		self.Button_agree:setPosition(426,63)
		self.Button_cancle:setPosition(164,63)
	end
end

function CDDisMissTable:setOperateBtnState(isShow, playerid)
	local player = GameCommon.player
	local charid = GameCommon:getRoleChairID()
	local uid = player[charid].dwUserID
	if uid == playerid then
		self.Button_agree:setVisible(isShow)
		self.Button_cancle:setVisible(isShow)
	end
end

function CDDisMissTable:setString(name, state)
	local text = self.name_template:clone()
	text:setString(name .. state)
	text:setColor(cc.c3b(16,141,16))
	self.ListView_state:pushBackCustomItem(text)
end

function CDDisMissTable:disMissTableInfo(data)
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


return CDDisMissTable 