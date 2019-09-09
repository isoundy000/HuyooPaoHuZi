---------------
--   大结算
---------------
local HHGameRoomEnd = class("HHGameRoomEnd", cc.load("mvc").ViewBase)
local StaticData = require("app.static.StaticData")
local UserData = require("app.user.UserData")
local Common = require("common.Common")
local EventMgr = require("common.EventMgr")
local EventType = require("common.EventType")
local GameCommon = require("game.huaihua.GameCommon")
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
function HHGameRoomEnd:onConfig()
	self.widget = {
		{'back', 'onBack'},
		{'lianjie', 'onHistory'},
		{'zhanji', 'onHistory'},
		{'fang_num'},
		{'listview'},
		{'template'},
		{'panel_end'},
		{'text_time'},
		{'text_club'},
		{'tishi_des'},
	}
end

function HHGameRoomEnd:onEnter()
	require("common.Common"):screenshot(FileName.battlefieldScreenshot)
end

function HHGameRoomEnd:onExit()
	
end

function HHGameRoomEnd:onCreate(params)
	self.pBuffer = params[1]
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

function HHGameRoomEnd:onBack(...)
	require("common.SceneMgr"):switchScene(require("app.MyApp"):create():createView("HallLayer"), SCENE_HALL)
end

function HHGameRoomEnd:onHistory(...)
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
	data.szGameID = self.pBuffer.szGameID
	data.isInClub = self:isClub(self.pBuffer);
    require("app.MyApp"):create(data):createView("ShareLayer")
end

function HHGameRoomEnd:onLianJie(...)
	--
end

function HHGameRoomEnd:isClub(...)
	return self.pBuffer.tableConfig.nTableType == TableType_ClubRoom and self.pBuffer.tableConfig.dwClubID ~= 0
end

function HHGameRoomEnd:playerInfo(...)
	self.listview:removeAllItems()
	local winner = self:getWinner(self.pBuffer)
	for i = 1, self.pBuffer.dwUserCount do
		local data = self.pBuffer.tScoreInfo[i]
		local isWinner = winner[data.dwUserID] or false
		self:createPlayerInfo(data, isWinner)
	end
	self.text_club:setString('亲友圈ID: ' .. self.pBuffer.tableConfig.dwClubID)
	self.text_club:setVisible(self:isClub())
	self.lianjie:setVisible(false)
end

function HHGameRoomEnd:createPlayerInfo(data, isWinner)
	if type(data) ~= 'table' then
		printError('NewClubLayer:addOnceClubItem data error')
		return
	end
	local item = self.template:clone()
	self.listview:insertCustomItem(item, 0)
	local name = self:seekWidgetByNameEx(item, "name")
	local id = self:seekWidgetByNameEx(item, "id")
	local banker = self:seekWidgetByNameEx(item, "banker")
	local endgame = self:seekWidgetByNameEx(item, "endgame")
	local image_player = self:seekWidgetByNameEx(item, 'image_player')
	local des = self:seekWidgetByNameEx(item, 'des')
	local Image_bigwinner = self:seekWidgetByNameEx(item, 'Image_bigwinner')
	Image_bigwinner:setVisible(isWinner)
	local playerID = self:disMissTableInfo(GameCommon.disMissData) or - 1
	name:setColor(cc.c3b(139, 105, 20))
	id:setColor(cc.c3b(139, 105, 20))
	des:setColor(cc.c3b(139, 105, 20))
	
	name:setString(data.player.szNickName)
	banker:setVisible(data.dwUserID == self.pBuffer.dwTableOwnerID)
	id:setString(string.format("ID %d", data.dwUserID))
	
	des:setString('积分 ' .. data.totalScore)
	if GameCommon.tableConfig.wCurrentNumber == GameCommon.tableConfig.wTableNumber then --正常结束
		endgame:setVisible(false)
	else
		endgame:setVisible(playerID == data.dwUserID)
	end
	Common:requestUserAvatar(data.dwUserID, data.player.szPto, image_player, "img")
	--
end

function HHGameRoomEnd:getWinner(pBuffer)
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

function HHGameRoomEnd:disMissTableInfo(data)
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

return HHGameRoomEnd 