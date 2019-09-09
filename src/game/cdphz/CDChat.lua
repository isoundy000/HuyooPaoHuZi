---------------
--   聊天
---------------
local CDChat = class("CDChat", cc.load("mvc").ViewBase)
local GameCommon = require("game.cdphz.GameCommon")
local NetMgr = require("common.NetMgr")
local EventType = require("common.EventType")
local NetMsgId = require("common.NetMsgId")
local EventMgr = require("common.EventMgr")
local Common = require("common.Common")
local MAXNUM = 20 --最大容量
function CDChat:onConfig()
	self.widget = {
		{'head_2', 'onClickPage'},
		{'head_1', 'onClickPage'},
		{'mask'},
		{'sendClick', 'onSendCall'},
		{'TextField'},
		{'chatlistview'},
		{'tempdes'},
		{'emTempLate'},
		{'templatelab'},
		{'head_2', 'onClickHead'},
		{'head_1', 'onClickHead'},
		{'page_1'},
		{'page_2'},
		{'templateTextEmoj'}
		
	}
	self.pageView = {}
	self.allButton = {}
end

function CDChat:onEnter()
	EventMgr:registListener('SUB_GR_SEND_CHAT', self, self.SUB_GR_SEND_CHAT)
	EventMgr:registListener('SUB_GF_USER_EXPRESSION', self, self.SUB_GF_USER_EXPRESSION)
end

function CDChat:onExit()
	EventMgr:unregistListener('SUB_GR_SEND_CHAT', self, self.SUB_GR_SEND_CHAT)
	EventMgr:unregistListener('SUB_GF_USER_EXPRESSION', self, self.SUB_GF_USER_EXPRESSION)
end

function CDChat:onCreate(params)
	self.tempdes:setVisible(false)
	self.templateTextEmoj:setVisible(false)
	self.usePage = nil
	self:addMaskListen()
	self:initEmSetting()
	self:initChatLab()
	self.page_1:setVisible(false)
	self.page_2:setVisible(false)
	self:showPage('page1_Button_1')
end

function CDChat:initEmSetting(...)
	--50 为了做分页给每页表情赋值一个id
	self:initOneEmjio('page1_Button_1', 'page1_ScrollView_1', 'press_1', 23, 0)
	self:initOneEmjio('page1_Button_2', 'page1_ScrollView_2', 'press_2', 24, 50)
end

function CDChat:showPage(name)
	for k, v in pairs(self.pageView) do
		v[1]:setVisible(k == name)
		v[2]:setVisible(k ~= name)
	end
end


--初始化表情 --page1_ScrollView_1
function CDChat:initOneEmjio(btnName, listName, press, index, start)
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
	local pessNode = self:seekWidgetByNameEx(self.csb, press)
	self.pageView[btnName] = {scrollview, pessNode}
end

--初始化 文本 从100开始
function CDChat:initChatLab(...)
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
		local posy = contentSize -(size.height + 5) * i
		node:setPosition(10, posy)
		self:addListener(node, handler(self, self.clickExpressLab))
		scrollview:addChild(node)
	end
end


function CDChat:addMaskListen(...)
	self.mask:setTouchEnabled(true)
	self.mask:addTouchEventListener(function(sender, event)
		if event == ccui.TouchEventType.ended then
			self:closeView()
		end
	end)
end

function CDChat:addPanelListen(item, call)
	item:setTouchEnabled(true)
	item:addTouchEventListener(function(sender, event)
		if event == ccui.TouchEventType.ended then
			if call then
				call(sender)
			end
		end
	end)
end

function CDChat:closeView(...)
	self:setVisible(false)
end

function CDChat:onSendCall(...)
	local contents = self.TextField:getString()
	if #contents == 0 then
		return
	end
	NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER, NetMsgId.REQ_GR_USER_SEND_CHAT, "dwbnsdns",
	GameCommon:getRoleChairID(), 0, GameCommon:getUserInfo(GameCommon:getRoleChairID()).cbSex, 32, "", string.len(contents), string.len(contents), contents)
	self:setVisible(false)
end

function CDChat:clickExpressLab(sender)
	
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
end

function CDChat:onClickHead(sender)
	local name = sender:getName()
	
	if name == 'head_1' then
		local isShow = self.page_1:isVisible()
		self.page_1:setVisible(not isShow)
		self:setUsetPage(self.page_1)
	elseif name == 'head_2' then
		local isShow = self.page_2:isVisible()
		self.page_2:setVisible(not isShow)
		self:setUsetPage(self.page_2)
	end
end

function CDChat:hidePage(page)
	local isShow = page:isVisible()
	page:setVisible(not isShow)
	self:setUsetPage(page)
end

function CDChat:setUsetPage(page)
	if self.usePage and self.usePage ~= page then
		self.usePage:setVisible(false)
	end
	self.usePage = page
end

function CDChat:buttonCall(sender)
	local index = sender:getName()
	self:hidePage(self.page_1)
	NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME, NetMsgId.SUB_GF_USER_EXPRESSION, "ww", index, GameCommon:getRoleChairID())
end

function CDChat:emButtonCall(sender)
	local name = sender:getName()
	self:showPage(name)
end


function CDChat:addListener(btn, callback)
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

function CDChat:addChat(name, content)
	local des = string.format("[%s]:%s", name, content)
	local item = self.tempdes:clone()
	item:setString(des)
	item:setVisible(true)
	item:setColor(cc.c3b(139, 105, 20))
	local count = self.chatlistview:getChildrenCount()
	if count > MAXNUM then
		self.chatlistview:removeItem(0)
	end
	self.chatlistview:pushBackCustomItem(item)
	self:runAction(cc.Sequence:create(cc.DelayTime:create(0), cc.CallFunc:create(function(sender, event)
		self.chatlistview:scrollToBottom(0.1, true)
	end)))
end

function CDChat:addEmoj(name, index)
	local node = self.templateTextEmoj:clone()
	node:setVisible(true)
	local pageIndex = math.floor(index / 50) + 1
	local animIndex
	if pageIndex == 1 then --第一页
		animIndex = 23
	elseif pageIndex == 2 then --第二页
		animIndex = 24
	end
	local anim
	if animIndex then
		anim = require("game.cdphz.Animation") [animIndex]
	end
	
	if anim then
		local id = math.mod(index, 50)
		local data = anim[id]
		if data then
			local image = node:getChildByName('image')
			image:loadTexture(data.pngPath)
			node:setString(string.format("[%s]:", name))
			node:setColor(cc.c3b(139, 105, 20))
			local textSize = node:getContentSize()
			local imageSize = image:getContentSize()
			image:setPosition(textSize.width + imageSize.width, imageSize.height / 3)
			local count = self.chatlistview:getChildrenCount()
			if count > MAXNUM then
				self.chatlistview:removeItem(0)
			end
			self:runAction(cc.Sequence:create(cc.DelayTime:create(0), cc.CallFunc:create(function(sender, event)
				self.chatlistview:scrollToBottom(0.1, true)
			end)))
			self.chatlistview:pushBackCustomItem(node)
		end
	end
end

function CDChat:SUB_GR_SEND_CHAT(event)
	local data = event._usedata
	if not data then
		return
	end
	local player = GameCommon:getUserInfo(data.dwUserID)
	if player then
		self:addChat(player.szNickName, data.szChatContent)
	end
end

function CDChat:SUB_GF_USER_EXPRESSION(event)
	local data = event._usedata
	if not data then
		return
	end
	local player = GameCommon:getUserInfo(data.wChairID)
	if player then
		self:addEmoj(player.szNickName, data.wIndex)
	end
end

return CDChat 