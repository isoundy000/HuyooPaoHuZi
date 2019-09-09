---------------
--   大结算
---------------
local ZZGameRoomEnd = class("ZZGameRoomEnd", cc.load("mvc").ViewBase)
local StaticData = require("app.static.StaticData")
local UserData = require("app.user.UserData")
local Common = require("common.Common")
local EventMgr = require("common.EventMgr")
local EventType = require("common.EventType")
local GameCommon = require("game.zhuzhou.GameCommon")
local Base64 = require("common.Base64")

function ZZGameRoomEnd:onConfig()
	self.widget = {
		{'back', 'onBack'},
		{'zhanji','onHistory'},
		{'endtag'},--输赢
		{'fang_num'},
		{'text_time'},
		{'ListView_3'},
		{'ListView_4'},
		{'ListView_2'},
		{'template'},
		{'tishi_des'},
	}
end

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

function ZZGameRoomEnd:onEnter()
	require("common.Common"):screenshot(FileName.battlefieldScreenshot)
end

function ZZGameRoomEnd:onExit()
	
end

function ZZGameRoomEnd:onCreate(params)
	self.pBuffer = params[1]
	self.pBuffer.statistics = self.pBuffer.statistics or {}
	--self.scoreItem = {}
	-- for i=1,3 do
	-- 	local item = self:seekWidgetByNameEx(self.panel_end,'template_' .. i)
	-- 	table.insert( self.scoreItem,item)
	-- 	item:setVisible(false)
	-- end
	if self.pBuffer then
		self.fang_num:setString(self.pBuffer.tableConfig.wTbaleID)
		self.tishi_des:setString(endDes[self.pBuffer.cbOrigin])
	end
	
	local function onEventRefreshTime(sender, event)
		local date = os.date("*t", os.time())
		self.text_time:setString(string.format("%d-%02d-%02d %02d:%02d:%02d", date.year, date.month, date.day, date.hour, date.min, date.sec))
		--self.text_time:runAction(cc.Sequence:create(cc.DelayTime:create(1), cc.CallFunc:create(onEventRefreshTime)))
	end
	onEventRefreshTime()

	self:initPlayerInfo()
	self:updateTopInfo()
end

function ZZGameRoomEnd:onBack(...)
	require("common.SceneMgr"):switchScene(require("app.MyApp"):create():createView("HallLayer"), SCENE_HALL)
end

function ZZGameRoomEnd:onHistory(...)
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
	data.isInClub = self:isInClub(self.pBuffer);
    require("app.MyApp"):create(data):createView("ShareLayer")
end

function ZZGameRoomEnd:isInClub( pBuffer )
    return pBuffer.tableConfig.nTableType == TableType_ClubRoom and pBuffer.tableConfig.dwClubID ~= 0
end

--初始化成员信息
function  ZZGameRoomEnd:initPlayerInfo( ... )
	local listView = self.ListView_3
	if self.pBuffer.dwUserCount == 4 then
		listView = self.ListView_4
	elseif self.pBuffer.dwUserCount == 2 then
		listView = self.ListView_2
	end
	listView:setVisible(true)
	local dianpaoarry = self:getDianPaoWang(self.pBuffer) or {}
	local winner = self:getWinner(self.pBuffer)
	for i=1,self.pBuffer.dwUserCount do
		local data = self.pBuffer.tScoreInfo[i]
		local isWinner = winner[data.dwUserID] or false

		if self.pBuffer.tScoreInfo[i].totalScore >= 0 then 
			isWinner = true
		end 
		local item = self.template:clone()
		local name = self:seekWidgetByNameEx(item, "name")
		local id = self:seekWidgetByNameEx(item, "id")
		local Image_bigwinner = self:seekWidgetByNameEx(item, 'Image_bigwinner')
		local huxi_total_score = self:seekWidgetByNameEx(item,'huxi_total_score')
		local Image_hupai = self:seekWidgetByNameEx(item,'Image_hupai')
		local Image_zhongzhuang = self:seekWidgetByNameEx(item,'Image_zhongzhuang')
		local Image_dianpao = self:seekWidgetByNameEx(item,'Image_dianpao')
		local Image_big = self:seekWidgetByNameEx(item,'Image_big')
		local Image_end = self:seekWidgetByNameEx(item,'Image_end')
		local image_player_avater = self:seekWidgetByNameEx(item,'image_player_avater')
		local Image_dian_pao_wang = self:seekWidgetByNameEx(item,'Image_dian_pao_wang')
		local Image_bank = self:seekWidgetByNameEx(item,'Image_bank')
		Image_bigwinner:setVisible(isWinner)
		Image_big:setVisible(isWinner)
		Image_end:setVisible(not isWinner)
		local isBank = data.dwUserID == self.pBuffer.dwTableOwnerID
		Image_bank:setVisible(isBank)
		name:setString(data.player.szNickName)
		id:setString(string.format("ID %d", data.dwUserID))

		Common:requestUserAvatar(data.dwUserID, data.player.szPto, image_player_avater, "clip")

		local showEnd = {1,9,4}
		local statics = self.pBuffer.statistics[i] or {}

		for i=1,3 do
			local childItem =  self:seekWidgetByNameEx(item,'Image_hupai_' .. i)
			local score = self:seekWidgetByNameEx(childItem,'score')
			local Image_bg_big = self:seekWidgetByNameEx(childItem,'Image_bg_big')
			Image_bg_big:setVisible(isWinner)
			local index = showEnd[i]
			score:setString(statics[index] or 0)
		end
		Image_dian_pao_wang:setVisible(dianpaoarry[data.dwUserID] or false)

		huxi_total_score:setString(data.totalScore)

		listView:pushBackCustomItem(item)
		listView:refreshView()
	end


end

--更新顶部信息
function ZZGameRoomEnd:updateTopInfo( ... )
	local win = 'zhuzhou/ui/bigend/win_title.png'
	local lose = 'zhuzhou/ui/bigend/over_lose_title.png'
	local imagePath = win

	local wChairID = 0
	local viewID = GameCommon:getViewIDByChairID(wChairID)

	local data = self.pBuffer.tScoreInfo[viewID]
	if data then
		if data.totalScore < 0 then
			imagePath = lose
		end
		self.endtag:loadTexture(imagePath)
	end

	local data
	for i=1,self.pBuffer.dwUserCount do
		local _data = self.pBuffer.tScoreInfo[i]
		local isBank = _data.dwUserID == self.pBuffer.dwTableOwnerID
		if isBank then
			data = _data
		end
	end

	--创建者头像
	if data then
		local image_player_avater_1 = self:seekWidgetByNameEx(self.csb,'image_player_avater_1')
		Common:requestUserAvatar(data.dwUserID, data.player.szPto, image_player_avater_1, "clip")
		local Text__name_creater = self:seekWidgetByNameEx(self.csb,'Text__name_creater')
		Text__name_creater:setString(data.player.szNickName)
		local Text__name_id = self:seekWidgetByNameEx(self.csb,'Text__name_id')
		Text__name_id:setString(string.format("ID %d", data.dwUserID))
	end
end

function ZZGameRoomEnd:getDianPaoWang(pBuffer)
	if not pBuffer then
		return
	end
	local maxScore = 0
	local maxScoreArry = {}
	for i=1,self.pBuffer.dwUserCount  do
		local data = self.pBuffer.tScoreInfo[i]
		local _s = self.pBuffer.statistics[i]
		if not _s then
			return
		end
		if maxScore >= _s[4] then
			maxScore = _s[4]
		end
	end
	for i=1,self.pBuffer.dwUserCount  do
		
		if maxScore ~= 0 then
			local data = self.pBuffer.tScoreInfo[i]
			local _s = self.pBuffer.statistics[i]
			if maxScore == _s[4] then
				table.insert( maxScoreArry, data.dwUserID)
			end
		end
	end
	return maxScoreArry
end

function ZZGameRoomEnd:getWinner(pBuffer)
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

return ZZGameRoomEnd 