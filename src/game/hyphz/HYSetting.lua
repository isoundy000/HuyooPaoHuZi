---------------
--   设置界面
---------------
local Common = require("common.Common")
local EventMgr = require("common.EventMgr")
local EventType = require("common.EventType")
local UserData =  require("app.user.UserData")
local HYSetting = class("HYSetting", cc.load("mvc").ViewBase)
local Music = require("app.user.UserData").Music
local GameCommon = require("game.hyphz.GameCommon")
function HYSetting:onConfig()
	self.widget = {
		{'head_2', 'onClickPage'},
		{'head_1', 'onClickPage'},
		{'head_3','onClickPage'},
		{'close', 'onClose'},
		{'button_bg_1','zixingCallFunc'},
		{'button_bg_2','zixingCallFunc'},
		{'button_speed_1','speedCallFunc'},
		{'button_speed_2','speedCallFunc'},
		{'button_speed_3','speedCallFunc'},
		{'button_size_1','sizeCallFunc'},
		{'button_size_2','sizeCallFunc'},
		{'slider_1'},
		{'slider_2'},
		{'Panel_h_1','doubleClick'},
		{'Panel_h_3','doubleClick'},
		{'Panel_h_2','doubleClick'},
		{'Panel_h_4','doubleClick'},
	}
	self.pageView = {}
end

function HYSetting:initValue(...)
	self.ziXing = self:getDefaultValue('HYZiXing',1) --1 小 2 大
	self.ziSize = self:getDefaultValue('HYZSize',1)  --1 普通 2 超大
	self.speed = self:getDefaultValue('HYSpeed',1)   --1 慢 2 快 3 极速

	self.hddh = self:getDefaultValue('HYHDDH',2) -- 1 关 2 开
	self.chat = self:getDefaultValue('HYCHAT',2) -- 1 关 2 开
	self.bfyy = self:getDefaultValue('HYBFYY',2) -- 1 关 2 开
	self.tpts = self:getDefaultValue('HYTPTS',2) -- 1 关 2 开
end

function HYSetting:onCreate(params)
	self:initValue()
	self:initOnePage('head_2', 'page_2', handler(self, self.updatePageTwo))
	self:initOnePage('head_1', 'page_1', handler(self, self.updatePageOne))
	self:initOnePage('head_3', 'page_3', handler(self, self.updatePageThree))
	self:showPage('head_1') --显示1
	self:registerSliderEvent()
end

function HYSetting:registerSliderEvent( ... )
	--音乐
	local callFunc = function ( epsilon )
		Music:setVolumeMusic(epsilon)
	end
	self:addSliderEvent(self.slider_2,callFunc)

	--音效
	local callFunc1 = function ( epsilon )
		Music:setVolumeSound(epsilon)
	end
	self:addSliderEvent(self.slider_1,callFunc1)
end


function HYSetting:initOnePage(headName, pageName, call)
	
	local btn = self:seekWidgetByNameEx(self.csb, headName)
	local press = self:seekWidgetByNameEx(btn, 'press')
	local page = self:seekWidgetByNameEx(self.csb, pageName)
	
	self.pageView[headName] = {press, page, call}
end

function HYSetting:updatePageThree( ... )
	self:updateHDDH(self.Panel_h_1,self.hddh)
	self:updateHDDH(self.Panel_h_2,self.chat)
	self:updateHDDH(self.Panel_h_4,self.tpts)
	self:updateHDDH(self.Panel_h_3,self.bfyy)
end

function HYSetting:updatePageOne(...)
	self:updateSpeed()
	self:updateZiSize()
	self:updateZiXing()
end

function HYSetting:updatePageTwo(...)
	self:updateSlider()
end

function HYSetting:showPage(headName)
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

function HYSetting:zixingCallFunc( sender )
	local name = sender:getName()
	if name == 'button_bg_1' then
		self.ziXing = 1
	elseif name == 'button_bg_2' then
		self.ziXing = 2
	end
	self:updateZiXing()
end

function HYSetting:speedCallFunc( sender )
	local name = sender:getName()
	if name == 'button_speed_1' then
		self.speed = 1
	elseif name == 'button_speed_2' then
		self.speed = 2
	elseif name == 'button_speed_3' then
		self.speed = 3 
	end
	self:updateSpeed()
end

function  HYSetting:sizeCallFunc( sender )
	local name = sender:getName()
	if name == 'button_size_1' then
		self.ziSize = 1
	elseif name == 'button_size_2' then
		self.ziSize = 2
	end
	self:updateZiSize()
end

function HYSetting:doubleClick( sender )
	local name = sender:getName()
	if name == 'Panel_h_1' then -- 互动动画
		self.hddh = self:getChangeValue(self.hddh)
		self:updateHDDH(sender,self.hddh)
	elseif name == 'Panel_h_2' then -- 显示聊天
		self.chat = self:getChangeValue(self.chat)
		self:updateHDDH(sender,self.chat)
	elseif name == 'Panel_h_3' then --播放语音
		self.bfyy = self:getChangeValue(self.bfyy)
		self:updateHDDH(sender,self.bfyy)
	elseif name == 'Panel_h_4' then --听牌提示
		self.tpts = self:getChangeValue(self.tpts)
		self:updateHDDH(sender,self.tpts)
	end
end

function HYSetting:getChangeValue( value )
	if value == 1 then
		value = 2
	else
		value = 1 
	end
	return value
end

function HYSetting:updateHDDH( panel,value )
	local Button_g = self:seekWidgetByNameEx(panel,'Button_g')
	local Button_k = self:seekWidgetByNameEx(panel,'Button_k')
	Button_g:setVisible(value == 1)
	Button_k:setVisible(value == 2)

end

function HYSetting:updateZiXing()
	for i=1,2 do
		local name = string.format("button_bg_%d", i)
		local press = self[name]:getChildByName('press')
		press:setVisible(false)
		if self.ziXing == i then
			press:setVisible(true)
		end
	end
end

function HYSetting:updateZiSize( ... )
	for i=1,2 do
		local name = string.format("button_size_%d", i)
		local press = self[name]:getChildByName('press')
		press:setVisible(false)
		if self.ziSize == i then
			press:setVisible(true)
		end
	end
end

function HYSetting:updateSlider( ... )
	local value = self:getVoice(0,1,Music:getVolumeMusic()) * 100
	self.slider_2:setPercent(value )
	local value1 = self:getVoice(0,1,Music:getVolumeSound()) * 100
	self.slider_1:setPercent(value1)
end


function HYSetting:updateSpeed( ... )
	for i=1,3 do
		local name = string.format("button_speed_%d", i)
		local press = self[name]:getChildByName('press')
		press:setVisible(false)
		if self.speed == i then
			press:setVisible(true)
		end
	end
end


function HYSetting:onClickPage(sender)
	self:showPage(sender:getName())
end

function HYSetting:onClose(...)
    self:saveSetting()
	self:removeFromParent()
	EventMgr:dispatch(EventType.EVENT_TYPE_SKIN_CHANGE)
end

function HYSetting:saveSetting( ... )
	cc.UserDefault:getInstance():setIntegerForKey('HYZiXing',self.ziXing)
	cc.UserDefault:getInstance():setIntegerForKey('HYZSize',self.ziSize)
	cc.UserDefault:getInstance():setIntegerForKey('HYSpeed',self.speed)

	cc.UserDefault:getInstance():setIntegerForKey('HYHDDH',self.hddh)
	cc.UserDefault:getInstance():setIntegerForKey('HYCHAT',self.chat)
	cc.UserDefault:getInstance():setIntegerForKey('HYBFYY',self.bfyy)
	cc.UserDefault:getInstance():setIntegerForKey('HYTPTS',self.tpts)
	Music:saveVolume()
end

function HYSetting:getDefaultValue( key,default )
    return cc.UserDefault:getInstance():getIntegerForKey(key,default)
end

function HYSetting:getVoice( min,max,cur )
	if cur >= max then
		cur = max
	elseif cur <= min then
		cur = min
	end
	return cur
end

--添加slider event
function HYSetting:addSliderEvent(slider,callBack)
	if slider then
		slider:addEventListener(function( sender,eventType )
			local epsilon = sender:getPercent() / 100
			if epsilon >= 0 or epsilon <= 1 then
				if callBack then
					callBack(epsilon)
				end
			end
		end)
	end
end

return HYSetting 