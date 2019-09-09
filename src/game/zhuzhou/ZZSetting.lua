---------------
--   设置界面
---------------
local Common = require("common.Common")
local EventMgr = require("common.EventMgr")
local EventType = require("common.EventType")
local Music = require("app.user.UserData").Music
local GameCommon = require("game.zhuzhou.GameCommon")
local ZZSetting = class("ZZSetting", cc.load("mvc").ViewBase)
function ZZSetting:onConfig()
	self.widget = {
		{'close', 'onClose'},
		{'button_music','onMusicFunc'},
		{'button_effect','onEffectFunc'},
		{"slider_1"},
		{"slider_2"},
		{'button_lan_1','onLanguageFunc'},
		{'button_lan_2','onLanguageFunc'},

	}
end

function ZZSetting:initValue()  
	self.music			= Music:getVolumeMusic()  --音乐 
	self.effectMusic 	= Music:getVolumeSound()		--音效
	self.isMusic    	= cc.UserDefault:getInstance():getBoolForKey('ZZisMusic', true) 
	self.isEffMusic  	= cc.UserDefault:getInstance():getBoolForKey('ZZisEffMusic', true)  	--是否开启音效
	self.volumeSelect 	= cc.UserDefault:getInstance():getIntegerForKey('ZZvolumeSelect', 1) 	--语言选择
end

function ZZSetting:onCreate()
	self:initValue()
	self:updatePageOne()
end

function ZZSetting:updatePageOne(...)
	self:registerSliderEvent()
	self:updateMusic()
	self:updateEffectMusic()
	self:updatePuTonHua()
end

function ZZSetting:onLanguageFunc(sender)
	local btnName = sender:getName()
	if btnName == 'button_lan_1' then
		self.volumeSelect = 0
	else
		self.volumeSelect = 1
	end
	self:updatePuTonHua()
end

function ZZSetting:updatePuTonHua( ... )
	if self.volumeSelect == 0 then
		local press1 = self.button_lan_1:getChildByName('press')
		press1:setVisible(true)
		local press2 = self.button_lan_2:getChildByName('press')
		press2:setVisible(false)
	else
		local press1 = self.button_lan_1:getChildByName('press')
		press1:setVisible(false)
		local press2 = self.button_lan_2:getChildByName('press')
		press2:setVisible(true)
	end
end


function ZZSetting:onClose(...)
    self:saveSetting()
	GameCommon.language = self.volumeSelect
	GameCommon.regionSound = self.volumeSelect
	self:removeFromParent()
end

--==============================--
--desc: 声音设置
--time:2018-07-06 04:25:54
--@return 
--==============================--
function ZZSetting:onMusicFunc()
	self.isMusic = not self.isMusic
	if self.isMusic then
		self.music = 100
	else
		self.music = 0
	end
	Music:setVolumeMusic(self.music / 100)
	self.slider_1:setPercent(self.music)
	self:updateMusic()
end

function ZZSetting:onEffectFunc( ... )
	self.isEffMusic = not self.isEffMusic
	if self.isEffMusic then
		self.effectMusic = 100
	else
		self.effectMusic = 0
	end
	Music:setVolumeSound(self.effectMusic / 100)
	self.slider_2:setPercent(self.effectMusic)
	self:updateEffectMusic()
end

function ZZSetting:updateMusic( ... )
	local press = self.button_music:getChildByName('press')
	press:setVisible(not self.isMusic)
end

function ZZSetting:updateEffectMusic( ... )
	local press = self.button_effect:getChildByName('press')
	press:setVisible(not self.isEffMusic)
end


function ZZSetting:saveSetting( ... )
	cc.UserDefault:getInstance():setBoolForKey('ZZisMusic',self.isMusic)
	cc.UserDefault:getInstance():setIntegerForKey('ZZvolumeSelect',self.volumeSelect)
	Music:saveVolume()
	cc.UserDefault:getInstance():setBoolForKey('ZZisEffMusic',self.isEffMusic)
end

function ZZSetting:getDefaultValue( key,default )
    return cc.UserDefault:getInstance():getIntegerForKey(key,default)
end

function ZZSetting:registerSliderEvent()
	--音乐
	self.slider_1:setPercent(self.music * 100)
	self.slider_1:addEventListener(function(sender, eventType)
		local epsilon = sender:getPercent() / 100
		Music:setVolumeMusic(epsilon)
		self.music = epsilon
		if self.music > 0 then
			self.isMusic = true
		else
			self.isMusic = false
		end
		self:updateMusic()
	end)
	if self.music > 0 then
		self.isMusic = true
	else
		self.isMusic = false
	end
	self:updateMusic()

	--音效
	self.slider_2:setPercent(self.effectMusic * 100)
	self.slider_2:addEventListener(function(sender, eventType)
		local epsilon = sender:getPercent() / 100
		Music:setVolumeSound(epsilon)
		self.effectMusic = epsilon
		if self.effectMusic > 0 then
			self.isEffMusic = true
		else
			self.isEffMusic = false
		end
		self:updateEffectMusic()
	end)
	if self.effectMusic > 0 then
		self.isEffMusic = true
	else
		self.isEffMusic = false
	end
	self:updateEffectMusic()
end

return ZZSetting 