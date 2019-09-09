---------------
--   设置界面
---------------
local Common = require("common.Common")
local EventMgr = require("common.EventMgr")
local EventType = require("common.EventType")
local UserData =  require("app.user.UserData")
local HHSetting = class("HHSetting", cc.load("mvc").ViewBase)
local Music = require("app.user.UserData").Music
local GameCommon = require("game.huaihua.GameCommon")
function HHSetting:onConfig()
	self.widget = {
		{'head_2', 'onClickPage'},
		{'head_1', 'onClickPage'},
		{'close', 'onClose'},
		{'button_music', 'onMusicCall'},
		{'button_effect', 'onMusicEffect'},
		{'button_stand', 'onLanguageCall'},
		{'button_local', 'onLanguageCall'},
		{'slider_1'}, --音乐
		{'slider_2'}, --音效
		{'button_bg_1', 'onLayoutCall'},
		{'button_bg_2', 'onLayoutCall'},
		{'button_layout_1', 'onLayoutPaiCall'},
		{'button_layout_2', 'onLayoutPaiCall'},
		{'button_layout_3', 'onLayoutPaiCall'},
		{'button_layout_4', 'onLayoutPaiCall'},
		{'button_1', 'onBgCall'},
		{'button_2', 'onBgCall'},
		{'button_3', 'onBgCall'},
		{'button_4', 'onBgCall'},
		{'button_tin', 'onTinCall'},
		{'button_eat_fast', 'onEatFastCall'}
	}
	self.pageView = {}
end

function HHSetting:initValue(...)
	self.music			= self:isPlayVoice(Music:getVolumeMusic())  --音乐 
    self.effectMusic	= self:isPlayVoice(Music:getVolumeSound())  --音效
    self.mahjongBg		= self:getDefaultValue('HHzipaiBg',1) 		-- 1-绿色 2-水墨 3-蓝绿 4-蓝色

	self.language		= cc.UserDefault:getInstance():getIntegerForKey('HHlanguage', 1)  	--语言 0-普通话 1-方言

	self.layout			= cc.UserDefault:getInstance():getIntegerForKey('HHlayout', 1) 		--布局 1 - 左边 0 右边
	self.paixing		= cc.UserDefault:getInstance():getIntegerForKey('HHpaixing', 1) 	--1 -大牌大 2-大牌小 3 -小牌大 4- 小牌小
	self.isOpenTin		= cc.UserDefault:getInstance():getBoolForKey('HHisOpenTin', true) 	--听牌
	self.isFastEat   	= cc.UserDefault:getInstance():getBoolForKey('HHisFastEat', false) 	-- 是否快速吃牌
end

function HHSetting:onCreate(params)
	self:initValue()
	self:initOnePage('head_2', 'page_2', handler(self, self.updatePageTwo))
	self:initOnePage('head_1', 'page_1', handler(self, self.updatePageOne))
	self:showPage('head_1') --显示1
	self:registerSliderEvent()
end

function HHSetting:registerSliderEvent( ... )
	--音乐
	local callFunc = function ( epsilon )
		self:musicChange(epsilon)
	end
	self:addSliderEvent(self.slider_1,callFunc)

	--音效
	local callFunc1 = function ( epsilon )
		self:effectChange(epsilon)
	end
	self:addSliderEvent(self.slider_2,callFunc1)
end


function HHSetting:musicChange( epsilon )
	Music:setVolumeMusic(epsilon)
	self.music = epsilon <= 0
	self:updateMusic()
end

function HHSetting:effectChange(epsilon )
	Music:setVolumeSound(epsilon)
	self.effectMusic = epsilon <= 0
	self:updateMusicEffect()
end

function HHSetting:isPlayVoice( voice )
	if voice <= 0 then
		return true
	else 
		return false
	end
end

function HHSetting:initOnePage(headName, pageName, call)
	
	local btn = self:seekWidgetByNameEx(self.csb, headName)
	local press = self:seekWidgetByNameEx(btn, 'press')
	local page = self:seekWidgetByNameEx(self.csb, pageName)
	
	self.pageView[headName] = {press, page, call}
end

function HHSetting:updatePageOne(...)
	self:updateMusic()
	self:updateSlider()
	self:updateMusicEffect()
	self:updateLanguage()
end

function HHSetting:updatePageTwo(...)
	self:updateLayout()
	self:updateLayoutPai()
	self:updateBgCall()
	self:updateTin()
	self:updateEatFast()
end

function HHSetting:showPage(headName)
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


function HHSetting:onClickPage(sender)
	self:showPage(sender:getName())
end

function HHSetting:onClose(...)
    self:saveSetting()
	EventMgr:dispatch(EventType.EVENT_TYPE_SKIN_CHANGE)
	EventMgr:dispatch('HHChangeLayout')
	GameCommon.language = self.language
	self:removeFromParent()
end

--==============================--
--desc: 声音设置
--time:2018-07-06 04:25:54
--@return 
--==============================--
function HHSetting:onMusicCall()
	self.music = not self.music
	if self.music then
		self.slider_1:setPercent(0)
		self:musicChange(0)
	else
		self.slider_1:setPercent(100)
		self:musicChange(1)
	end
	self:updateMusic()
end

function HHSetting:onMusicEffect()
	self.effectMusic = not self.effectMusic
	if self.effectMusic then
		self.slider_2:setPercent(0)
		self:effectChange(0)
	else
		self.slider_2:setPercent(100)
		self:effectChange(1)
	end
	self:updateMusicEffect()
end

function HHSetting:onLanguageCall(sender)
	local name = sender:getName()
	if name == 'button_stand' then
		self.language = 0
	elseif name == 'button_local' then
		self.language = 1
	end
	self:updateLanguage()
end

function HHSetting:updateSlider( ... )
	local value = self:getVoice(0,1,Music:getVolumeMusic()) * 100
	self.slider_1:setPercent(value )
	local value1 = self:getVoice(0,1,Music:getVolumeSound()) * 100
	self.slider_2:setPercent(value1)
end

function HHSetting:getVoice( min,max,cur )
	if cur >= max then
		cur = max
	elseif cur <= min then
		cur = min
	end
	return cur
end

function HHSetting:updateMusic(...)
	local press = self.button_music:getChildByName('press')
	press:setVisible(self.music)
end

function HHSetting:updateMusicEffect(...)
	local press = self.button_effect:getChildByName('press')
	press:setVisible(self.effectMusic)
end

function HHSetting:updateLanguage(...)
	local press1 = self.button_stand:getChildByName('press')
	local press2 = self.button_local:getChildByName('press')
	if self.language == 0 then
		press1:setVisible(true)
		press2:setVisible(false)
	else
		press1:setVisible(false)
		press2:setVisible(true)
	end
end

--------------------------------------画面设置---------------
function HHSetting:onLayoutCall(sender)
	local name = sender:getName()
	if name == 'button_bg_1' then
		self.layout = 1
	elseif name == 'button_bg_2' then
		self.layout = 0
	end
	self:updateLayout()
end

function HHSetting:onLayoutPaiCall(sender)
	local name = sender:getName()
	if name == 'button_layout_1' then
		self.paixing = 1
	elseif name == 'button_layout_2' then
		self.paixing = 2
	elseif name == 'button_layout_3' then
		self.paixing = 3
	elseif name == 'button_layout_4' then
		self.paixing = 4
	end
	self:updateLayoutPai()
end

function HHSetting:onBgCall(sender)
	local name = sender:getName()
	if name == 'button_1' then
		self.mahjongBg = 1
	elseif name == 'button_2' then
		self.mahjongBg = 2
	elseif name == 'button_3' then
		self.mahjongBg = 3
	elseif name == 'button_4' then
		self.mahjongBg = 4
	end
	self:updateBgCall()
end

function HHSetting:onTinCall(...)
	self.isOpenTin = not self.isOpenTin
	self:updateTin()
end

function HHSetting:onEatFastCall(...)
	self.isFastEat = not self.isFastEat
	self:updateEatFast()
end

function HHSetting:updateLayout()
	local press1 = self.button_bg_1:getChildByName('press')
	press1:setVisible(self.layout == 1)
	
	local press2 = self.button_bg_2:getChildByName('press')
	press2:setVisible(self.layout == 0)
end

function HHSetting:updateLayoutPai(...)
	for i = 1, 4 do
		local name = string.format("button_layout_%d", i)
		local press = self[name]:getChildByName('press')
		press:setVisible(false)
		if i == self.paixing then
			press:setVisible(true)
		end
	end
end

function HHSetting:updateBgCall(...)
	for i = 1, 4 do
		local name = string.format("button_%d", i)
		local press = self[name]:getChildByName('press')
		press:setVisible(false)
		if i == self.mahjongBg then
			press:setVisible(true)
		end
	end
end

function HHSetting:updateTin(...)
	local press1 = self.button_tin:getChildByName('press')
	press1:setVisible(not self.isOpenTin)
end

function HHSetting:updateEatFast(...)
	local press1 = self.button_eat_fast:getChildByName('press')
	press1:setVisible(not self.isFastEat)
end

function HHSetting:saveSetting( ... )
	cc.UserDefault:getInstance():setIntegerForKey('HHzipaiBg',self.mahjongBg)
	cc.UserDefault:getInstance():setIntegerForKey('HHlanguage',self.language)
	cc.UserDefault:getInstance():setIntegerForKey('HHlayout',self.layout)
	cc.UserDefault:getInstance():setIntegerForKey('HHpaixing',self.paixing)
	cc.UserDefault:getInstance():setBoolForKey('HHisOpenTin',self.isOpenTin)
	cc.UserDefault:getInstance():setBoolForKey('HHisFastEat',self.isFastEat)
	Music:saveVolume()
end

function HHSetting:getDefaultValue( key,default )
    return cc.UserDefault:getInstance():getIntegerForKey(key,default)
end

--添加slider event
function HHSetting:addSliderEvent(slider,callBack)
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

return HHSetting 