---------------
--   聊天
---------------
local HYChat = class("HYChat", cc.load("mvc").ViewBase)
local GameCommon = require("game.hyphz.GameCommon")
local NetMgr = require("common.NetMgr")
local EventType = require("common.EventType")
local NetMsgId = require("common.NetMsgId")
local EventMgr = require("common.EventMgr")
local Common = require("common.Common")
local MAXNUM = 20 --最大容量
function HYChat:onConfig()
	self.widget = {
		{'mask'},
		{'sendClick', 'onSendCall'},
		{'TextField'},
		{'tempdes'},
		{'emTempLate'},
		{'templatelab'},
		{'head_2', 'onClickHead'},
		{'head_1', 'onClickHead'},
		{'page_1'},
		{'page_2'},
		{'templateTextEmoj'},
		{'head_2_child'},
		{'head_1_child'},
		
	}
	self.pageView = {}
	self.allButton = {}
end

function HYChat:onEnter()
	EventMgr:registListener('SUB_GR_SEND_CHAT', self, self.SUB_GR_SEND_CHAT)
	EventMgr:registListener('SUB_GF_USER_EXPRESSION', self, self.SUB_GF_USER_EXPRESSION)
end

function HYChat:onExit()
	EventMgr:unregistListener('SUB_GR_SEND_CHAT', self, self.SUB_GR_SEND_CHAT)
	EventMgr:unregistListener('SUB_GF_USER_EXPRESSION', self, self.SUB_GF_USER_EXPRESSION)
end

function HYChat:onCreate(params)
	self.tempdes:setVisible(false)
	self.templateTextEmoj:setVisible(false)
	self.usePage = nil
	self:addMaskListen()
	self:initEmSetting()
	self:initChatLab()
	self.page_1:setVisible(false)
	self.page_2:setVisible(false)

	self:showPage('head_1')
end

function HYChat:initEmSetting(...)
	--50 为了做分页给每页表情赋值一个id
	self:initOneEmjio('page1_Button_1', 'page1_ScrollView_1', 'press_1', 23, 0)
end

--初始化表情 --page1_ScrollView_1
function HYChat:initOneEmjio(btnName, listName, press, index, start)
	local scrollview = self:seekWidgetByNameEx(self.csb, listName)
	local viewSize = scrollview:getContentSize()
	local anim = require("game.cdphz.Animation") [index]
	self.emTempLate:setVisible(false)
	local y = self.emTempLate:getSize()
	local count = #anim
	local contentSize = 0
	
	contentSize = math.floor(count / 3) *(y.height) - 30
	
	if contentSize <= viewSize.height then
		contentSize = viewSize.height
	end
	scrollview:setInnerContainerSize(cc.size(viewSize.width, contentSize))
	for i = 1, count do
		local node = self.emTempLate:clone()
		node:setVisible(true)
		local path = anim[i].pngPath
		node:loadTextures(path, path)
		node:setName(i + start)
		node:ignoreContentAdaptWithSize(true)
		local size = node:getSize()
		local row = math.floor((i - 1) / 3) -- 5行
		local colum =(i - 1) % 3  -- 3行
		local posx = 50 +((size.width + 30) * colum)
		local posy = contentSize -(size.height / 2) *(row + 1) - 30 * row
		node:setPosition(posx, posy)
		self:addListener(node, handler(self, self.buttonCall))
		scrollview:addChild(node)
	end
	
	local btn = self:seekWidgetByNameEx(self.csb, btnName)
	if btn then
		self:addListener(btn, handler(self, self.emButtonCall))
	end
end

--初始化 文本 从100开始
function HYChat:initChatLab(...)
	local chat = require("game.cdphz.ChatConfig")
	local scrollview = self:seekWidgetByNameEx(self.csb, 'page2_ScrollView')
	local viewSize = scrollview:getContentSize()
	local imgPath = 'cdzipai/face/'
	self.templatelab:setVisible(false)
	local y = self.templatelab:getSize()
	local contentSize = #chat *(y.height + 5)
	scrollview:setInnerContainerSize(cc.size(viewSize.width, contentSize))
	for i = 1, #chat do
		local node = self.templatelab:clone()
		node:setVisible(true)
		node:setTitleText(chat[i].text)
		node:setName(100 + i)
		local size = node:getSize()
		local posy = contentSize + 50 -(size.height +10) * i 
		node:setPosition(10, posy)
		self:addListener(node, handler(self, self.clickExpressLab))
		scrollview:addChild(node)
	end
end


function HYChat:addMaskListen(...)
	self.mask:setTouchEnabled(true)
	self.mask:addTouchEventListener(function(sender, event)
		if event == ccui.TouchEventType.ended then
			self:closeView()
		end
	end)
end

function HYChat:addPanelListen(item, call)
	item:setTouchEnabled(true)
	item:addTouchEventListener(function(sender, event)
		if event == ccui.TouchEventType.ended then
			if call then
				call(sender)
			end
		end
	end)
end

function HYChat:closeView(...)
	self:setVisible(false)
end

function HYChat:onSendCall(...)
	local contents = self.TextField:getString()
	if #contents == 0 then
		return
	end
	NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER, NetMsgId.REQ_GR_USER_SEND_CHAT, "dwbnsdns",
	GameCommon:getRoleChairID(), 0, GameCommon:getUserInfo(GameCommon:getRoleChairID()).cbSex, 32, "", string.len(contents), string.len(contents), contents)
	self:setVisible(false)
	self:removeFromParent()
end

function HYChat:clickExpressLab(sender)
	
	local chat = require("game.cdphz.ChatConfig")
	local index = sender:getName() or 1
	local chatContent = chat[tonumber(index) - 100]
	local contents = ''
	if chatContent then
		contents = chatContent.text
	end
	self:hidePage(self.page_2)
	NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER, NetMsgId.REQ_GR_USER_SEND_CHAT, "dwbnsdns",
	GameCommon:getRoleChairID(), index, GameCommon:getUserInfo(GameCommon:getRoleChairID()).cbSex, 32, "", string.len(contents), string.len(contents), contents)
	self:removeFromParent()
end

function HYChat:onClickHead(sender)
	local name = sender:getName()
	
	self:showPage(name)
end

function HYChat:showPage( hedeName )
	if hedeName == 'head_1' then
		self.page_1:setVisible(true)
		self.page_2:setVisible(false)
		self:setUsetPage(self.page_1)
		self.head_1_child:setVisible(true)
		self.head_2_child:setVisible(false)
	elseif hedeName == 'head_2' then
		self.page_2:setVisible(true)
		self.page_1:setVisible(false)
		self:setUsetPage(self.page_2)
		self.head_1_child:setVisible(false)
		self.head_2_child:setVisible(true)
	end
end

function HYChat:hidePage(page)
	local isShow = page:isVisible()
	page:setVisible(not isShow)
	self:setUsetPage(page)
end

function HYChat:setUsetPage(page)
	if self.usePage and self.usePage ~= page then
		self.usePage:setVisible(false)
	end
	self.usePage = page
end

function HYChat:buttonCall(sender)
	local index = sender:getName()
	self:hidePage(self.page_1)
	NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME, NetMsgId.SUB_GF_USER_EXPRESSION, "ww", index, GameCommon:getRoleChairID())
	self:removeFromParent()
end

function HYChat:emButtonCall(sender)
	local name = sender:getName()
	self:showPage(name)
end


function HYChat:addListener(btn, callback)
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


function HYChat:SUB_GR_SEND_CHAT(event)

end

function HYChat:SUB_GF_USER_EXPRESSION(event)

end

return HYChat 