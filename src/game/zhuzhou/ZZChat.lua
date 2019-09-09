---------------
--   聊天
---------------
local ZZChat = class("ZZChat", cc.load("mvc").ViewBase)
local GameCommon = require("game.zhuzhou.GameCommon")
local NetMgr = require("common.NetMgr")
local EventType = require("common.EventType")
local NetMsgId = require("common.NetMsgId")
local Common = require("common.Common")
function ZZChat:onConfig()
	self.widget = {
		{'ListView_chat'},
		{'scrollview_1'},
		{'templateemojj'},
		{'root'},
		{'mask'},
		{'text_template'},
		{'templateemojj_2'}
	}
	self.pageView = {}
end

function ZZChat:onEnter()
end

function ZZChat:onExit()
end

function ZZChat:onCreate(params)
	self:showPage('head_2') --显示1
	self:moveTo()
	self:initExpression()
	self:initLab()
end

function ZZChat:moveTo(...)
	self.mask:setTouchEnabled(true)
	self.mask:addTouchEventListener(function(sender, event)
		if event == ccui.TouchEventType.ended then
			self:moveBack()
		end
	end)
end


function ZZChat:moveBack(...)
	self:removeFromParent()
end


function ZZChat:onClickPage(sender)
	self:showPage(sender:getName())
end

function ZZChat:showPage(headName)
	for k, v in pairs(self.pageView) do
		--v[1]:setVisible(k == headName)
		--v[2]:setVisible(k == headName)
	end
	
	local page = self.pageView[headName]
	if page then
		if page[3] then
			page[3]()
		end
	end
end

--表情
function ZZChat:initExpression()
	local name = 'biaoqing_%d.png'
	local imageName = 'zhuzhou/ui/chat/'
	local viewSize = self.scrollview_1:getContentSize()
	for i = 1, 12 do
		local node = self.templateemojj:clone()
		node:setVisible(true)
		node:ignoreContentAdaptWithSize(true)
		local path = string.format(imageName .. name, i)
		node:loadTextures(path, path)
		node:setName(i)
		local size = node:getSize()
		local row = math.floor((i - 1) / 3) -- 5行
		local colum =(i - 1) % 3  -- 3行
		local posx = 55 +((size.width + 15) * colum)
		local posy = viewSize.height - 50 -(size.height + 30) * row
		node:setPosition(posx, posy)
		self:addListener(node, handler(self, self.buttonCall))
		self.scrollview_1:addChild(node)
	end
end

--文本提示
function ZZChat:initLab(...)
	local chat = require("game.zhuzhou.ChatConfig")
	self.text_template:setVisible(false)
	for i = 1, #chat do
		local item = self.text_template:clone()
		item:setVisible(true)
		item:setSwallowTouches(true)
		local des = item:getChildByName('des')
		item:setName(i)
		self:addListener(item, handler(self, self.clickExpressLab))
		des:setString(chat[i].text)
		des:setColor(cc.c3b(99, 73, 41))
		self.ListView_chat:pushBackCustomItem(item)
		self.ListView_chat:refreshView()
	end

end


function ZZChat:clickExpressLab(sender)
	local chat = require("game.zhuzhou.ChatConfig")
	local index = sender:getName() or 1
	local chatContent = chat[tonumber(index)]
	local contents = ''
	if chatContent then
		contents = chatContent.text
	end
	NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER, NetMsgId.REQ_GR_USER_SEND_CHAT, "dwbnsdns",
	GameCommon:getRoleChairID(), tonumber(index), GameCommon:getUserInfo(GameCommon:getRoleChairID()).cbSex, 32, "", string.len(contents), string.len(contents), contents)
	self:moveBack()
end

function ZZChat:onSendCall(...)
	local contents = self.TextField:getString()
	if #contents == 0 then
		return
	end
	NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER, NetMsgId.REQ_GR_USER_SEND_CHAT, "dwbnsdns",
	GameCommon:getRoleChairID(), 0, GameCommon:getUserInfo(GameCommon:getRoleChairID()).cbSex, 32, "", string.len(contents), string.len(contents), contents)
	self:moveBack()
end

function ZZChat:buttonCall(sender)
	self:moveBack()
	local index = sender:getName()
	NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME, NetMsgId.SUB_GF_USER_EXPRESSION, "ww", index, GameCommon:getRoleChairID())
end

function ZZChat:addListener(btn, callback)
	btn:addTouchEventListener(function(sender, event)
		if event == ccui.TouchEventType.ended then
			Common:palyButton()
			if callback then
				callback(sender)
			end
		end
	end)
end


return ZZChat 