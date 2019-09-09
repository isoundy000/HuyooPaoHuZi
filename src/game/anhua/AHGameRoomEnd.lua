---------------
--   大结算
---------------
local AHGameRoomEnd = class("AHGameRoomEnd", cc.load("mvc").ViewBase)
local StaticData = require("app.static.StaticData")
local UserData = require("app.user.UserData")
local Common = require("common.Common")
local EventMgr = require("common.EventMgr")
local EventType = require("common.EventType")
local GameCommon = require("game.anhua.GameCommon")
local Base64 = require("common.Base64")

local endDes = {
	[0] = '',
	[1] = '提示：该房间被房主解散',
	[2] = '提示：该房间被管理员解散',
	[3] = '提示：该房间投票解散',
	[4] = '提示：该房间因疲劳值不足被强制解散',
	[5] = '提示：该房间被官方系统强制解散',
	[6] = '提示：该房间因超时未开局被强制解散',
	[7] = '提示：该房间因超时投票解散',
}

function AHGameRoomEnd:onConfig()
	self.widget = {
		{'back', 'onBack'},
		{'lianjie', 'onHistory'},
		{'zhanji', 'onHistory'},
		{'fang_num'},
		{'panel_end'},
		{'text_time'},
		{'text_club'},
		{'panel_end'},
		{'tishi_des'},
	}
end

function AHGameRoomEnd:onEnter()
	require("common.Common"):screenshot(FileName.battlefieldScreenshot)
end

function AHGameRoomEnd:onExit()
	
end

function AHGameRoomEnd:onCreate(params)
	self.pBuffer = params[1]
	self.scoreItem = {}
	for i=1,3 do
		local item = self:seekWidgetByNameEx(self.panel_end,'template_' .. i)
		table.insert( self.scoreItem,item)
		item:setVisible(false)
	end
	if self.pBuffer then
		self.fang_num:setString(self.pBuffer.tableConfig.wTbaleID)
		self.tishi_des:setString(endDes[self.pBuffer.cbOrigin])
		self:playerInfo()
	end
	
	local function onEventRefreshTime(sender, event)
		local date = os.date("*t", os.time())
		self.text_time:setString(string.format("%d-%02d-%02d %02d:%02d:%02d", date.year, date.month, date.day, date.hour, date.min, date.sec))
		--self.text_time:runAction(cc.Sequence:create(cc.DelayTime:create(1), cc.CallFunc:create(onEventRefreshTime)))
	end
	onEventRefreshTime()
end

function AHGameRoomEnd:onBack(...)
	require("common.SceneMgr"):switchScene(require("app.MyApp"):create():createView("HallLayer"), SCENE_HALL)
end

function AHGameRoomEnd:onHistory(...)
    local data = clone(UserData.Share.tableShareParameter[4])
    data.dwClubID = self.pBuffer.tableConfig.dwClubID
    data.szShareTitle = string.format("战绩分享-房间号:%d,局数:%d/%d",self.pBuffer.tableConfig.wTbaleID, self.pBuffer.tableConfig.wCurrentNumber, self.pBuffer.tableConfig.wTableNumber)
    data.szShareContent = ""
    local maxScore = 0
    for i = 1, 8 do
        if self.pBuffer.tScoreInfo[i].dwUserID ~= nil and self.pBuffer.tScoreInfo[i].dwUserID ~= 0 and self.pBuffer.tScoreInfo[i].totalScore > maxScore then 
            maxScore = self.pBuffer.tScoreInfo[i].totalScore
        end
    end
    for i = 1, 8 do
        if self.pBuffer.tScoreInfo[i].dwUserID ~= nil and self.pBuffer.tScoreInfo[i].dwUserID ~= 0 then
            if data.szShareContent ~= "" then
                data.szShareContent = data.szShareContent.."\n"
            end
            if maxScore ~= 0 and self.pBuffer.tScoreInfo[i].totalScore >= maxScore then
                data.szShareContent = data.szShareContent..string.format("【%s:%d(大赢家)】",self.pBuffer.tScoreInfo[i].player.szNickName,self.pBuffer.tScoreInfo[i].totalScore)
            else
                data.szShareContent = data.szShareContent..string.format("【%s:%d】",self.pBuffer.tScoreInfo[i].player.szNickName,self.pBuffer.tScoreInfo[i].totalScore)
            end
        end
    end
    data.szShareUrl = string.format(data.szShareUrl,self.pBuffer.szGameID)
	data.szShareImg = FileName.battlefieldScreenshot
	data.szGameID = self.pBuffer.szGameID;
	data.isInClub = self:isInClub(self.pBuffer);
    require("app.MyApp"):create(data):createView("ShareLayer")
end

function AHGameRoomEnd:isInClub( pBuffer )
    return pBuffer.tableConfig.nTableType == TableType_ClubRoom and pBuffer.tableConfig.dwClubID ~= 0
end

function AHGameRoomEnd:onLianJie(...)
	--
end

function AHGameRoomEnd:isClub(...)
	return self.pBuffer.tableConfig.nTableType == TableType_ClubRoom and self.pBuffer.tableConfig.dwClubID ~= 0
end

function AHGameRoomEnd:playerInfo(...)
	local winner = self:getWinner(self.pBuffer)
	for i = 1, self.pBuffer.dwUserCount do
		local data = self.pBuffer.tScoreInfo[i]
		local isWinner = winner[data.dwUserID] or false
		self:initGameEnd(i,data, isWinner)
	end
	self.text_club:setString('亲友圈ID: ' .. self.pBuffer.tableConfig.dwClubID)
	self.text_club:setVisible(self:isClub())
	self.lianjie:setVisible(false)
end

function AHGameRoomEnd:initGameEnd(index, data, isWinner )
	local item = self.scoreItem[index]
	if not item then
		return
	end
	local str,bigScore = self:getRecord(index,data)
	item:setVisible(true)
	local image_player = self:seekWidgetByNameEx(item, 'image_player')
	local name = self:seekWidgetByNameEx(item, "name")
	local banker = self:seekWidgetByNameEx(item, "banker")
	local id = self:seekWidgetByNameEx(item, "id")
	local score = self:seekWidgetByNameEx(item,'score')
	local total_score = self:seekWidgetByNameEx(item,'total_score')
	local total_score_1 = self:seekWidgetByNameEx(item,'total_score_1')
	local Image_bigwinner = self:seekWidgetByNameEx(item, 'Image_bigwinner')
	local zj = self:seekWidgetByNameEx(item,'zj')
	Common:requestUserAvatar(data.dwUserID, data.player.szPto, image_player, "img")
	name:setString(data.player.szNickName)
	banker:setVisible(data.dwUserID == self.pBuffer.dwTableOwnerID)
	id:setString(string.format("ID %d", data.dwUserID))
	score:setText(bigScore)
	zj:setText(str)
	if data.totalScore >= 0 then
		total_score_1:setText(data.totalScore)
	else
		total_score:setText(data.totalScore)
	end
	total_score_1:setVisible(data.totalScore >= 0)
	total_score:setVisible(data.totalScore < 0)
	Image_bigwinner:setVisible(isWinner)
end

function AHGameRoomEnd:getRecord(index,data)
	local win,lost,peace = 0,0,0

	local count = GameCommon.tableConfig.wCurrentNumber
	local bigScore = 0
	for i=1,count do
		if data.lScore[i] > 0 then
			win = win + 1
			if data.lScore[i] >= bigScore then
				bigScore = data.lScore[i]
			end
		elseif data.lScore[i] < 0 then
			lost = lost + 1
		else 
			peace = peace + 1
		end
	end
	local str = win .. '胜' .. lost .. '负' .. peace .. '平'

	return str,bigScore
end

function AHGameRoomEnd:getWinner(pBuffer)
	if not pBuffer then
		return
	end
	local max = - 1
	local score = - 1
	local winner = {}
	for i = 1, 8 do
		if not pBuffer.tScoreInfo[i] then
			score = - 1
		else
			score = pBuffer.tScoreInfo[i].totalScore or - 1
		end
		if score >= max then
			max = score
		end
	end
	for i = 1, 8 do
		if not pBuffer.tScoreInfo[i] then
			score = - 1
		else
			score = pBuffer.tScoreInfo[i].totalScore or - 1
		end
		if score == max and max > 0 then
			local id = pBuffer.tScoreInfo[i].dwUserID
			winner[id] = true
		end
	end
	return winner
end

function AHGameRoomEnd:disMissTableInfo(data)
	if not data then
		return nil
	end
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

return AHGameRoomEnd 