---------------
--   聊天
---------------
local HHChat = class("HHChat", cc.load("mvc").ViewBase)
local GameCommon = require("game.huaihua.GameCommon")
local NetMgr = require("common.NetMgr")
local EventType = require("common.EventType")
local NetMsgId = require("common.NetMsgId")
local Common = require("common.Common")
function HHChat:onConfig()
	self.widget = {
		{'head_2', 'onClickPage'},
		{'head_1', 'onClickPage'},
		{'scrollview_3'},
		{'scrollview_1'},
		{'templateemojj'},
		{'root'},
		{'mask'},
		{'text_template'},
		{'sendClick', 'onSendCall'},
		{'TextField'},
		{'ScrollView_2'},
		{'templateemojj_2'}
	}
	self.pageView = {}
end

function HHChat:onEnter()
end

function HHChat:onExit()
end

function HHChat:onCreate(params)
	self:initOnePage('head_2', 'page_2', handler(self, self.updatePageTwo))
	self:initOnePage('head_1', 'page_1', handler(self, self.updatePageOne))
	self:showPage('head_2') --显示1
	self.root:setPosition(display.width, 0)
	self:moveTo()
	self:initExpression()
	self:initLab()
	self:initLocalEmoji()
end

function HHChat:moveTo(...)
	self:moveBegin()
	self.mask:setTouchEnabled(true)
	self.mask:addTouchEventListener(function(sender, event)
		if event == ccui.TouchEventType.ended then
			if self.isMoveOver then
				self.isMoveOver = false
				self:moveBack()
			end
		end
	end)
end

function HHChat:moveBegin(...)
	self.isMoveOver = false
	local action = cc.MoveTo:create(0.3, cc.p(0, 0))
	local endCall = cc.CallFunc:create(function(...)
		self.isMoveOver = true
	end)
	local saction = cc.Sequence:create(action, endCall)
	self.root:runAction(saction)
end

function HHChat:moveBack(...)
	local action = cc.MoveTo:create(0.3, cc.p(display.width, 0))
	local endCall = cc.CallFunc:create(function(...)
		self:removeFromParent()
	end)
	local saction = cc.Sequence:create(action, endCall)
	self.root:runAction(saction)
end

function HHChat:initOnePage(headName, pageName, call)
	
	local btn = self:seekWidgetByNameEx(self.csb, headName)
	local press = self:seekWidgetByNameEx(btn, 'press')
	local page = self:seekWidgetByNameEx(self.csb, pageName)
	
	self.pageView[headName] = {press, page, call}
end

function HHChat:updatePageOne(...)
	
end

function HHChat:updatePageTwo(...)
	
end

function HHChat:onClickPage(sender)
	self:showPage(sender:getName())
end

function HHChat:showPage(headName)
	for k, v in pairs(self.pageView) do
		v[1]:setVisible(k == headName)
		v[2]:setVisible(k == headName)
	end
	
	local page = self.pageView[headName]
	if page then
		if page[3] then
			page[3]()
		end
	end
end

function HHChat:initExpression()
	local name = 'emotion%d0001.png'
	local imageName = 'huaihua/chat/emoji/'
	local viewSize = self.scrollview_1:getContentSize()
	for i = 1, 15 do
		local node = self.templateemojj:clone()
		node:setVisible(true)
		local path = string.format(imageName .. name, i)
		node:loadTextures(path, path)
		node:setName(i)
		local size = node:getSize()
		local row = math.floor((i - 1) / 3) -- 5行
		local colum =(i - 1) % 3  -- 3行
		local posx = 75 +((size.width + 30) * colum)
		local posy = viewSize.height - 70 -(size.height + 30) * row
		node:setPosition(posx, posy)
		self:addListener(node, handler(self, self.buttonCall))
		self.scrollview_1:addChild(node)
	end
end

function HHChat:initLab(...)
	local chat = require("game.huaihua.ChatConfig")
	self.text_template:setVisible(false)
	local viewSize = self.scrollview_3:getContentSize()
	for i = #chat, 1, - 1 do
		local item = self.text_template:clone()
		item:setVisible(true)
		local size = item:getSize()
		item:setPosition(size.width / 2, viewSize.height -(size.height + 10) *(i - 1) - 20)
		local des = item:getChildByName('des')
		item:setName(i)
		self.scrollview_3:addChild(item)
		self:addListener(item, handler(self, self.clickExpressLab))
		des:setString(chat[i].text)
	end
	
end

function HHChat:initLocalEmoji(...)
	local anim = require("game.huaihua.Animation") [23]
	local viewSize = self.ScrollView_2:getContentSize()
	for i = 1, #anim do
		local node = self.templateemojj_2:clone()
		node:setVisible(true)
		local scale = 1
		node:setScale(scale)
		local animData = anim[i]
		local path = ''
		if animData then
			path = animData.animFile
			node:loadTextures(path, path)
			node:ignoreContentAdaptWithSize(true)
		end
		node:setName(i + 100)
		local size = node:getSize()
		local row = math.floor((i - 1) / 4) -- 5行
		local colum =(i - 1) % 4  -- 3行
		local posx = 70 +((size.width * scale ) * colum)
		local posy =(viewSize.height - 70 -(size.height * scale ) * row)
		node:setPosition(posx, posy)
		self:addListener(node, handler(self, self.buttonCall))
		self.ScrollView_2:addChild(node)
	end
end

function HHChat:clickExpressLab(sender)
	if self.isMoveOver then
		self.isMoveOver = false
		self:moveBack()
	end
	local chat = require("game.huaihua.ChatConfig")
	local index = sender:getName() or 1
	local chatContent = chat[tonumber(index)]
	local contents = ''
	if chatContent then
		contents = chatContent.text
	end
	
	NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER, NetMsgId.REQ_GR_USER_SEND_CHAT, "dwbnsdns",
	GameCommon:getRoleChairID(), index, GameCommon:getUserInfo(GameCommon:getRoleChairID()).cbSex, 32, "", string.len(contents), string.len(contents), contents)
end

function HHChat:onSendCall(...)
	if self.isMoveOver then
		self.isMoveOver = false
		self:moveBack()
	end
	local contents = self.TextField:getString()
	if #contents == 0 then
		return
	end
	NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER, NetMsgId.REQ_GR_USER_SEND_CHAT, "dwbnsdns",
	GameCommon:getRoleChairID(), 0, GameCommon:getUserInfo(GameCommon:getRoleChairID()).cbSex, 32, "", string.len(contents), string.len(contents), contents)
end

function HHChat:buttonCall(sender)
	if self.isMoveOver then
		self.isMoveOver = false
		self:moveBack()
	end
	local index = sender:getName()
	NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME, NetMsgId.SUB_GF_USER_EXPRESSION, "ww", index, GameCommon:getRoleChairID())
end

function HHChat:addListener(btn, callback)
	btn:setPressedActionEnabled(true)
	btn:addTouchEventListener(function(sender, event)
		if event == ccui.TouchEventType.ended then
			Common:palyButton()
			if callback then
				callback(sender)
			end
		end
	end)
end


return HHChat 