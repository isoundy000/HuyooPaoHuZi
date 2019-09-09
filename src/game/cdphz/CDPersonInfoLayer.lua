--[[*名称:CDPersonInfoLayer
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
local GameCommon			= require("game.cdphz.GameCommon")

local AnimCnf = {
	{'cdzipai/face/quantao', 'cdzipai/anim/baodai'},
	{'cdzipai/face/daoshui', 'cdzipai/anim/daoshui'},
	{'cdzipai/face/fq', 'cdzipai/anim/fq'},
	{'cdzipai/face/yiduohua', 'cdzipai/anim/meigui008'},
	{'cdzipai/face/pengbei', 'cdzipai/anim/pengbei'},
	{'cdzipai/face/yibahua', 'cdzipai/anim/xianhua'},
}

local CDPersonInfoLayer	= class("CDPersonInfoLayer", cc.load("mvc").ViewBase)

function CDPersonInfoLayer:onConfig()
	self.widget			= {
		{"Image_bg"},
		{"Button_close", "onClose"},
		{"Image_avatar"},
		{"Text_name"},
		{"Text_id"},
		{"Text_ip"},
		{"Button_contol", "onControl"},
		{"Text_contol"},
		{"Text_goldNum"},
		{"ListView_disInfo"},
		{"Image_faceBg"},
		{"ListView_face"},
	}
end

function CDPersonInfoLayer:onEnter()
	
end

function CDPersonInfoLayer:onExit()
	cc.UserDefault:getInstance():setBoolForKey('CDOpenUserEffect', self.isOpen)
end

function CDPersonInfoLayer:onCreate(param)
	local data = param[1]
	self.tableObj = param[2]
	self.isOpen = cc.UserDefault:getInstance():getBoolForKey('CDOpenUserEffect', true)
	self:refreshUI(data)
end

function CDPersonInfoLayer:onClose()
	self:removeFromParent()
end

function CDPersonInfoLayer:onControl()
    self.isOpen = not self.isOpen
    self:setButtonBrightState(self.isOpen)
end


------------------------------------------------------------------------
--                            game logic                              --
------------------------------------------------------------------------
function CDPersonInfoLayer:refreshUI(data)
	Log.d(data)
	if type(data) ~= 'table' then
		printError('CDPersonInfoLayer:refreshUI data error')
		return
	end
	self:setButtonBrightState(self.isOpen)
	local playInfo = self:getPlayerInfoByUserID(data.dwUserID)
	if not playInfo then
		return
	end
	Common:requestUserAvatar(data.dwUserID, playInfo.szPto, self.Image_avatar, "img")
	self.Text_name:setString(playInfo.szNickName)
	self.Text_id:setString('ID:' .. data.dwUserID)
	self.Text_ip:setString('IP:' .. Common:ipint2str(data.dwPlayAddr))
	-- self.Text_goldNum:setString()
	self:setLocationInfo()
	if UserData.User.userID == data.dwUserID then
		self.Image_faceBg:setVisible(false)
	else
		self.Image_faceBg:setVisible(true)
		self:setFaceActions(data)
	end
end

function CDPersonInfoLayer:getPlayerInfoByUserID(dwUserID)
	for i, v in pairs(GameCommon.player or {}) do
		if v.dwUserID == dwUserID then
			return v
		end
	end
end

function CDPersonInfoLayer:setButtonBrightState(isBright)
	if isBright then
		local path = 'cdzipai/ui/setting_btn_on.png'
		self.Button_contol:loadTextures(path, path, path)
		self.Text_contol:setPositionX(47.5)
		self.Text_contol:setString('开')
	else
		local path = 'cdzipai/ui/setting_btn_off.png'
		self.Button_contol:loadTextures(path, path, path)
		self.Text_contol:setPositionX(86.5)
		self.Text_contol:setString('关')
	end
end

function CDPersonInfoLayer:setLocationInfo()
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

function CDPersonInfoLayer:setFaceActions(data)
	local faceArr = self.ListView_face:getChildren()
	for i, v in ipairs(faceArr) do
		v:setVisible(false)
	end
	local Animation = require("game.cdphz.Animation")
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
			--- 房
			local targetChair = nil		
			for key, info in pairs(GameCommon.player or {}) do
				if info.dwUserID ~= 0 and info.dwUserID == data.dwUserID then
					targetChair = info.wChairID
					break
				end
			end
			if targetChair then
				NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME, NetMsgId.SUB_GF_USER_EFFECTS, "www", i, GameCommon:getRoleChairID(), targetChair)
			end
			
			self:removeFromParent()
		end)
	end
end

-- function CDPersonInfoLayer:playSkelStartToEndPos(sUserID, eUserID, index)
--     local spos = self.tableObj:getViewWorldPosByUserID(sUserID)
--     local epos = self.tableObj:getViewWorldPosByUserID(eUserID)
--     local image = ccui.ImageView:create(AnimCnf[index][1] .. '.png')
--     self:addChild(image)
--     image:setPosition(spos)
--     local moveto = cc.MoveTo:create(0.6,cc.p(epos))
--     local callfunc = cc.CallFunc:create(function()
--         local path = AnimCnf[index][2]
--         local skeletonNode = sp.SkeletonAnimation:create(path .. '.json', path .. '.atlas', 0.6)
--         skeletonNode:setAnimation(0, 'animation', false)
--         self:addChild(skeletonNode)
--         skeletonNode:setPosition(epos)
--         image:setVisible(false)
--         skeletonNode:registerSpineEventHandler(function(event)  
--             self:runAction(cc.Sequence:create(cc.DelayTime:create(0),cc.CallFunc:create(function() 
--                 self:removeFromParent()
--             end)))
--         end, sp.EventType.ANIMATION_END)
--     end)
--     image:runAction(cc.Sequence:create(moveto, callfunc))
-- end
------------------------------------------------------------------------
--                            server rvc                              --
------------------------------------------------------------------------
return CDPersonInfoLayer 