local EventMgr = require("common.EventMgr")
local EventType = require("common.EventType")
local NetMgr = require("common.NetMgr")
local NetMsgId = require("common.NetMsgId")
local UserData = require("app.user.UserData")
local Common = require("common.Common")
local StaticData = require("app.static.StaticData")
local NetMsgId = require("common.NetMsgId")

local SettingsLayer = class("SettingsLayer", function()
    return ccui.Layout:create()
end)

function SettingsLayer:create(wKindID)
    local view = SettingsLayer.new()
    view:onCreate()
    local function onEventHandler(eventType)  
        if eventType == "enter" then  
            view:onEnter() 
        elseif eventType == "exit" then
            view:onExit()
        elseif eventType == "cleanup" then
            view:onCleanup()
        end  
    end
    view:registerScriptHandler(onEventHandler)
    return view
end

function SettingsLayer:onEnter()

end

function SettingsLayer:onExit()
    
end

function SettingsLayer:onCleanup()
end

function SettingsLayer:onCreate()
    local visibleSize = cc.Director:getInstance():getVisibleSize()
    local csb = cc.CSLoader:createNode("YZSettingsLayer.csb")
    self:addChild(csb)
    self.root = csb:getChildByName("Panel_root")
    
    --self.csb = csb
    Common:addTouchEventListener(ccui.Helper:seekWidgetByName(self.root,"Button_return"),function() 
        UserData.Music:saveVolume()
        require("common.SceneMgr"):switchOperation()
    end)
    require("common.SceneMgr"):switchOperation(self)  
    local uiPanel_sound = ccui.Helper:seekWidgetByName(self.root,"Panel_sound") 
    
    self:initSound() 
end

function SettingsLayer:initSound()

    --版本信息
    local uiText_edition = ccui.Helper:seekWidgetByName(self.root,"Text_edition")
    if require("loading.Update").version ~= "" then
        local versionInfo = string.format("%s",require("loading.Update").version)
        versionInfo ="版本:".. versionInfo
        uiText_edition:setString(versionInfo)
    end       
    local uiButton_kai_1 = ccui.Helper:seekWidgetByName(self.root,"Button_kai_1")
    local volumeSound = UserData.Music:getVolumeSound()   

    Common:addTouchEventListener(uiButton_kai_1,function() 
        if volumeSound == 1 then
            UserData.Music:setVolumeSound(0) 
            uiButton_kai_1:setBright(false)
            volumeSound = 0
        else
            UserData.Music:setVolumeSound(1) 
            uiButton_kai_1:setBright(true)
            volumeSound = 1 
        end
    end)
    if volumeSound == 1 then
        uiButton_kai_1:setBright(true)
    else
        uiButton_kai_1:setBright(false)
    end
    

    local uiButton_kai_2 = ccui.Helper:seekWidgetByName(self.root,"Button_kai_2")
    local volumeMusic = UserData.Music:getVolumeMusic()   
    Common:addTouchEventListener(uiButton_kai_2,function() 
        if volumeMusic == 1 then
            UserData.Music:setVolumeMusic(0) 
            uiButton_kai_2:setBright(false)
            volumeMusic = 0 
        else
            UserData.Music:setVolumeMusic(1) 
            uiButton_kai_2:setBright(true)
            volumeMusic = 1 
        end
    end)
    if volumeMusic == 1 then
        uiButton_kai_2:setBright(true)
    else
        uiButton_kai_2:setBright(false)
    end

    local uiButton_logout = ccui.Helper:seekWidgetByName(self.root,"Button_logout")
    Common:addTouchEventListener(uiButton_logout,function()    
            UserData.Music:saveVolume()    
            NetMgr:getLogicInstance():closeConnect()
            require("common.SceneMgr"):switchScene(require("app.MyApp"):create(false,false):createView("LoginLayer"),SCENE_LOGIN)
            EventMgr:dispatch(EventType.EVENT_TYPE_EXIT_HALL)
    end)
           
    local uiImage_avatar = ccui.Helper:seekWidgetByName(self.root,"Image_avatar")
    Common:requestUserAvatar(UserData.User.userID,UserData.User.szLogoInfo,uiImage_avatar,"img")
     local uiText_name = ccui.Helper:seekWidgetByName(self.root,"Text_name")
    uiText_name:setString(string.format("%s",UserData.User.szNickName))
    local Update = require("loading.Update")    
end

return SettingsLayer
    