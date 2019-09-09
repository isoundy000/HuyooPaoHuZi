--[[*名称:ZZPersonInfoLayer
*描述:个人信息
*作者:cxx
*创建日期:2018-07-06 14:07:55
*修改日期:
]]
local EventMgr			= require("common.EventMgr")
local EventType			= require("common.EventType")
local NetMgr				= require("common.NetMgr")
local NetMsgId			= require("common.NetMsgId")
local StaticData			= require("app.static.StaticData")
local UserData			= require("app.user.UserData")
local Common				= require("common.Common")
local Default			= require("common.Default")
local GameConfig			= require("common.GameConfig")
local Log				= require("common.Log")
local GameCommon			= require("game.zhuzhou.GameCommon")

local ZZPersonInfoLayer	= class("ZZPersonInfoLayer", cc.load("mvc").ViewBase)

function ZZPersonInfoLayer:onConfig()
	self.widget			= {
		{"Image_bg"},
		{"Panel_mask", "onClose"},
		{"Image_avatar"},
		{"Text_name"},
		{"Text_id"},
		{"Text_ip"},
		{"Text_goldNum"},
		{"ListView_disInfo"},
		{"Image_faceBg"},
		{"ListView_face"},
	}
end

function ZZPersonInfoLayer:onEnter()
	
end

function ZZPersonInfoLayer:onExit()
end

function ZZPersonInfoLayer:onCreate(param)
	local data = param[1]
	self.tableObj = param[2]
	self:refreshUI(data)
end

function ZZPersonInfoLayer:onClose()
	self:removeFromParent()
end


------------------------------------------------------------------------
--                            game logic                              --
------------------------------------------------------------------------
function ZZPersonInfoLayer:refreshUI(data)
	if type(data) ~= 'table' then
		printError('ZZPersonInfoLayer:refreshUI data error')
		return
	end
    local playInfo = self:getPlayerInfoByUserID(data.dwUserID)
    
	if not playInfo then
		return
    end
	Common:requestUserAvatar(data.dwUserID, playInfo.szPto, self.Image_avatar, "clip")
	self.Text_name:setString(playInfo.szNickName)
	self.Text_id:setString('ID:' .. data.dwUserID)
	self.Text_ip:setString('IP:' .. Common:ipint2str(data.dwPlayAddr))
	-- self.Text_goldNum:setString()
	self:setLocationInfo()
    self.Image_faceBg:setVisible(true)
    self:setFaceActions(data)
end

function ZZPersonInfoLayer:getPlayerInfoByUserID(dwUserID)
    for i, v in pairs(GameCommon.player or {}) do
		if v.dwUserID == dwUserID then
			return v
		end
	end
end


function ZZPersonInfoLayer:setLocationInfo()
	local desListArr = self.ListView_disInfo:getChildren()
	for i, v in ipairs(desListArr) do
		v:setVisible(false)
	end
	
	local myInfo = self:getPlayerInfoByUserID(UserData.User.userID)
	if not myInfo or myInfo.location.x < 0.1 then
		if desListArr[1] then
			desListArr[1]:setVisible(true)
			desListArr[1]:setString('未开启定位')
		end
		return
	end
	
	local distance = nil
	local idx = 0
	for i, v in pairs(GameCommon.player or {}) do
		if v.dwUserID ~= UserData.User.userID then
			idx = idx + 1
			if GameCommon.tableConfig.nTableType == TableType_GoldRoom or GameCommon.tableConfig.nTableType == TableType_SportsRoom then
				distance = math.random(1000, 300000)
			elseif v.location.x < 0.1 then
				distance = string.format("%s未开启定位", v.szNickName)
			else
				distance = GameCommon:GetDistance(myInfo.location, v.location)
			end
			if type(distance) == "number" then
				if distance > 1000 then
					distance = string.format("%d千米", distance / 1000)
				else
					distance = string.format("%d米", distance)
				end
				distance = '与' .. v.szNickName .. '(ID:' .. v.dwUserID .. ')相距' .. distance
			end
			local item = desListArr[idx]
			if not item then
				item = desListArr[1]:clone()
			end
			item:setVisible(true)
			item:setString(distance)
			item:setColor(cc.c3b(162,77,26))
			self.ListView_disInfo:pushBackCustomItem(item)
		end
	end
end

function ZZPersonInfoLayer:setFaceActions(data)
	local faceArr = self.ListView_face:getChildren()
	for i, v in ipairs(faceArr) do
		v:setVisible(false)
	end
	local Animation = require("game.zhuzhou.Animation")
	local AnimCnf = Animation[22]
	for i, v in ipairs(AnimCnf) do
		local item = faceArr[i]
		if not item then
			item = faceArr[1]:clone()
			self.ListView_face:pushBackCustomItem(item)
		end
		item:setVisible(true)
		local Image_faceIcon = ccui.Helper:seekWidgetByName(item, 'Image_faceIcon')
        Image_faceIcon:loadTexture(v.imageFile .. '.png')
		Image_faceIcon:ignoreContentAdaptWithSize(true)
		item:setPressedActionEnabled(true)
        item:addClickEventListener(function()
            
			local targetChair = nil		
			for key, info in pairs(GameCommon.player or {}) do
				if info.dwUserID ~= 0 and info.dwUserID == data.dwUserID then
					targetChair = info.wChairID
					break
				end
			end
            if targetChair then
                print('-->>>>sender',targetChair)
				NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME, NetMsgId.SUB_GF_USER_EFFECTS, "www", i, GameCommon:getRoleChairID(), targetChair)
			end
			
			self:removeFromParent()
		end)
	end
end

------------------------------------------------------------------------
--                            server rvc                              --
------------------------------------------------------------------------
return ZZPersonInfoLayer 