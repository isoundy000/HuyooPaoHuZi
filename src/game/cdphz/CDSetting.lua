---------------
--   设置界面
---------------
local Common = require("common.Common")
local EventMgr = require("common.EventMgr")
local EventType = require("common.EventType")
local Music = require("app.user.UserData").Music
local GameCommon = require("game.cdphz.GameCommon")
local CDSetting = class("CDSetting", cc.load("mvc").ViewBase)
function CDSetting:onConfig()
	self.widget = {
		{'head_2', 'onClickPage'},
		{'head_1', 'onClickPage'},
		{'close', 'onClose'},
		{'button_music','onMusicFunc'},
		{'button_effect','onEffectFunc'},
		{'button_eat_1','onEatFastFunc'},
		{'button_eat_2','onEatFastFunc'},
		{'button_tin_1','onTinFunc'},
		{'button_tin_2','onTinFunc'},
		{'button_lan_1','onLanguageFunc'},
		{'button_lan_2','onLanguageFunc'},
		{'button_fast_1','onFastSpeedFunc'},
		{'button_fast_2','onFastSpeedFunc'},
		{'button_fast_3','onFastSpeedFunc'},
		{'button_fast_4','onFastSpeedFunc'},
		{'button_size_1','onPaiSizeFunc'},
		{'button_size_2','onPaiSizeFunc'},
		{'button_size_3','onPaiSizeFunc'},
		{'button_xu_1','onXuFunc'},
		{'button_xu_2','onXuFunc'},
		{'button_select_1','onSelectPai'},
		{'button_select_2','onSelectPai'},
		{'button_select_3','onSelectPai'},
		{'button_bg_1','onBgChange'},
		{'button_bg_2','onBgChange'},
		{'button_bg_3','onBgChange'},
		{"slider_1"},
		{"slider_2"},

	}
	self.pageView = {}
end

function CDSetting:initValue()
	-- self.music			= cc.UserDefault:getInstance():getFloatForKey('CDmusic', 1) 			--音量    
	self.music			= Music:getVolumeMusic()  --音乐 
	self.effectMusic 	= Music:getVolumeSound()		--音效
	self.isMusic    	= cc.UserDefault:getInstance():getBoolForKey('CDisMusic', true) 
	self.isEffMusic  	= cc.UserDefault:getInstance():getBoolForKey('CDisEffMusic', true)  	--是否开启音效
	self.isFastEat   	= cc.UserDefault:getInstance():getBoolForKey('CDisFastEat', true) 	    -- 是否快速吃牌
	self.isOpenTin  	= cc.UserDefault:getInstance():getBoolForKey('CDisOpenTin', false) 		-- 开启听牌
	self.volumeSelect 	= cc.UserDefault:getInstance():getIntegerForKey('CDvolumeSelect', 1) 	--语音选择
	self.speed 			= cc.UserDefault:getInstance():getIntegerForKey('CDspeed', 2) 			--出牌速度
	self.paiSize 		= cc.UserDefault:getInstance():getIntegerForKey('CDpaiSize', 2) 		--牌大小
	self.lineHeight 	= cc.UserDefault:getInstance():getIntegerForKey('CDlineHeight', 0) 		-- 虚线选择
	self.bgNum 			= cc.UserDefault:getInstance():getIntegerForKey('CDzipaiBg', 1)			-- 字牌背景

	if GameCommon:isSelectCDGameType() then
		self.zipaiSelect = cc.UserDefault:getInstance():getIntegerForKey('CDzipaiSelect', 3) 	--字牌选择
	else
		self.zipaiSelect = cc.UserDefault:getInstance():getIntegerForKey('HYzipaiSelect', 1)
	end
end

function CDSetting:onCreate()
	self:initValue()
	self:initOnePage('head_2', 'page_2', handler(self, self.updatePageTwo))
	self:initOnePage('head_1', 'page_1', handler(self, self.updatePageOne))
	self:showPage('head_1') --显示1
end

function CDSetting:initOnePage(headName, pageName, call)
	local btn = self:seekWidgetByNameEx(self.csb, headName)
	local press = self:seekWidgetByNameEx(btn, 'press')
	local page = self:seekWidgetByNameEx(self.csb, pageName)
	self.pageView[headName] = {press, page, call}
end

function CDSetting:updatePageOne(...)
	self:registerSliderEvent()
	self:updateMusic()
	self:updateEffectMusic()
	self:updateEat()
	self:updateTin()
	self:updatePuTonHua()
	self:udpateFastSpeed()
end

function CDSetting:updatePageTwo(...)
	self:updatePai()
	self:updateBigLine()
	self:updateZiPaiNum()
	self:updateBgNum()
end

function CDSetting:showPage(headName)
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

function CDSetting:onClickPage(sender)
	self:showPage(sender:getName())
end

function CDSetting:onClose(...)
    self:saveSetting()
	EventMgr:dispatch(EventType.EVENT_TYPE_SKIN_CHANGE)
	GameCommon.language = self.volumeSelect
	self:removeFromParent()
end

--==============================--
--desc: 声音设置
--time:2018-07-06 04:25:54
--@return 
--==============================--
function CDSetting:onMusicFunc()
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

function CDSetting:onEffectFunc( ... )
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

function CDSetting:onEatFastFunc(sender)
	local btnName = sender:getName()
	if btnName == 'button_eat_1' then
		self.isFastEat = true
	else
		self.isFastEat = false
	end
	self:updateEat()
end

function CDSetting:onTinFunc(sender)
	local btnName = sender:getName()
	if btnName == 'button_tin_1' then
		self.isOpenTin = true
	else
		self.isOpenTin = false
	end
	self:updateTin()
end

function CDSetting:onLanguageFunc(sender)
	local btnName = sender:getName()
	if btnName == 'button_lan_1' then
		self.volumeSelect = 1
	else
		self.volumeSelect = 0
	end
	self:updatePuTonHua()
end

function CDSetting:onFastSpeedFunc( sender )
	local name = sender:getName()
	if name == 'button_fast_1' then
		self.speed = 1
	elseif name == 'button_fast_2' then
		self.speed = 2
	elseif name == 'button_fast_3' then
		self.speed = 3
	elseif name == 'button_fast_4' then
		self.speed = 4
	end
	self:udpateFastSpeed()
end

function CDSetting:udpateFastSpeed( ... )
	self:updateSelect(4,'button_fast_',self.speed)
end

function CDSetting:updatePuTonHua( ... )
	if self.volumeSelect == 1 then
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

function CDSetting:updateTin( ... )
	if self.isOpenTin then
		local press1 = self.button_tin_1:getChildByName('press')
		press1:setVisible(true)
		local press2 = self.button_tin_2:getChildByName('press')
		press2:setVisible(false)
	else
		local press1 = self.button_tin_1:getChildByName('press')
		press1:setVisible(false)
		local press2 = self.button_tin_2:getChildByName('press')
		press2:setVisible(true)
	end

	-- self.isOpenTin = false
	-- local press1 = self.button_tin_1:getChildByName('press')
	-- press1:setVisible(false)
	-- local press2 = self.button_tin_2:getChildByName('press')
	-- press2:setVisible(true)
	-- self.button_tin_1:setBright(false)
	-- self.button_tin_1:setEnabled(false)
	-- self.button_tin_1:setColor(cc.c3b(170,170,170))
	-- self.button_tin_2:setBright(false)
	-- self.button_tin_2:setEnabled(false)
	-- self.button_tin_2:setColor(cc.c3b(170,170,170))
end

function CDSetting:updateMusic( ... )
	local press = self.button_music:getChildByName('press')
	press:setVisible(not self.isMusic)
end

function CDSetting:updateEffectMusic( ... )
	local press = self.button_effect:getChildByName('press')
	press:setVisible(not self.isEffMusic)
end

function CDSetting:updateEat( ... )
	if self.isFastEat then
		local press1 = self.button_eat_1:getChildByName('press')
		press1:setVisible(true)
		local press2 = self.button_eat_2:getChildByName('press')
		press2:setVisible(false)
	else
		local press1 = self.button_eat_1:getChildByName('press')
		press1:setVisible(false)
		local press2 = self.button_eat_2:getChildByName('press')
		press2:setVisible(true)
	end
end

--==============================--
--desc: 画面设置
--time:2018-07-10 11:41:34
--==============================--
function CDSetting:onPaiSizeFunc( sender )
	local name = sender:getName()
	if name == 'button_size_1' then
		self.paiSize = 1
	elseif name == 'button_size_2' then
		self.paiSize = 2
	elseif name == 'button_size_3' then
		self.paiSize = 3
	end
	self:updatePai()
end

function CDSetting:onXuFunc(sender)
	local btnName = sender:getName()
	if btnName == 'button_xu_1' then
		self.lineHeight = 0
	else
		self.lineHeight = 1
	end
	self:updateBigLine()
end

function CDSetting:onSelectPai( sender )
	local name = sender:getName()
	if name == 'button_select_1' then
		self.zipaiSelect = 1
	elseif name == 'button_select_2' then
		self.zipaiSelect = 2
	elseif name == 'button_select_3' then
		self.zipaiSelect =3
	end
	self:updateZiPaiNum()
end

function CDSetting:onBgChange( sender )
	local name = sender:getName()
	if name == 'button_bg_1' then
		self.bgNum = 1
	elseif name == 'button_bg_2' then
		self.bgNum = 2
	elseif name == 'button_bg_3' then
		self.bgNum = 3
	end
	self:updateBgNum()
end

function CDSetting:updateBgNum( ... )
	self:updateSelect(3,'button_bg_',self.bgNum)
end

function CDSetting:updateZiPaiNum( ... )
	self:updateSelect(3,'button_select_',self.zipaiSelect)
end

function CDSetting:updateBigLine()
	if self.lineHeight == 0 then
		local press1 = self.button_xu_1:getChildByName('press')
		press1:setVisible(true)
		local press2 = self.button_xu_2:getChildByName('press')
		press2:setVisible(false)
	else
		local press1 = self.button_xu_1:getChildByName('press')
		press1:setVisible(false)
		local press2 = self.button_xu_2:getChildByName('press')
		press2:setVisible(true)
	end
end

function CDSetting:updatePai( ... )
	self:updateSelect(3,'button_size_',self.paiSize)
end

function CDSetting:updateSelect( count,nodeName,stand )
	for i=1,count do
		local name = nodeName .. i
		local press1 = self[name]:getChildByName('press')
		press1:setVisible(stand == i)
	end
end

function CDSetting:saveSetting( ... )
	--cc.UserDefault:getInstance():setFloatForKey('CDmusic',self.music)
	cc.UserDefault:getInstance():setBoolForKey('CDisMusic',self.isMusic)
--	Music:setVolumeSound(self.effectMusic)
	Music:saveVolume()
	cc.UserDefault:getInstance():setBoolForKey('CDisEffMusic',self.isEffMusic)
	cc.UserDefault:getInstance():setBoolForKey('CDisFastEat',self.isFastEat)
	cc.UserDefault:getInstance():setBoolForKey('CDisOpenTin',self.isOpenTin)
	cc.UserDefault:getInstance():setIntegerForKey('CDvolumeSelect',self.volumeSelect)
	cc.UserDefault:getInstance():setIntegerForKey('CDspeed',self.speed)
	cc.UserDefault:getInstance():setIntegerForKey('CDpaiSize',self.paiSize)
	cc.UserDefault:getInstance():setIntegerForKey('CDlineHeight',self.lineHeight)
    cc.UserDefault:getInstance():setIntegerForKey('CDzipaiBg',self.bgNum)

    if GameCommon:isSelectCDGameType() then
    	cc.UserDefault:getInstance():setIntegerForKey('CDzipaiSelect',self.zipaiSelect)
    else
		cc.UserDefault:getInstance():setIntegerForKey('HYzipaiSelect',self.zipaiSelect)
    end
end

function CDSetting:getDefaultValue( key,default )
    return cc.UserDefault:getInstance():getIntegerForKey(key,default)
end

function CDSetting:registerSliderEvent()
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

return CDSetting 