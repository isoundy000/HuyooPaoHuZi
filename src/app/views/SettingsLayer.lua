local EventMgr = require("common.EventMgr")
local EventType = require("common.EventType")
local NetMgr = require("common.NetMgr")
local StaticData = require("app.static.StaticData")
local UserData = require("app.user.UserData")
local Common = require("common.Common")
local Default = require("common.Default")
local HttpUrl = require("common.HttpUrl")
local SettingsLayer = class("SettingsLayer", cc.load("mvc").ViewBase)

function SettingsLayer:onEnter()
    
end

function SettingsLayer:onExit()
    
end

function SettingsLayer:onCreate(parames)
    local visibleSize = cc.Director:getInstance():getVisibleSize()
    local csb = cc.CSLoader:createNode("SettingsLayer.csb")
    self:addChild(csb)
    self.root = csb:getChildByName("Panel_root")
    self.csb = csb

    Common:addTouchEventListener(ccui.Helper:seekWidgetByName(self.root,"Button_return"),function() 
        UserData.Music:saveVolume()
        require("common.SceneMgr"):switchOperation()
    end)
    
    self:initSound()  
end

function SettingsLayer:initSound()

    --版本信息
    local uiText_edition = ccui.Helper:seekWidgetByName(self.root,"Text_edition")
    if require("loading.Update").version ~= "" then
        local versionInfo = string.format("v%s",require("loading.Update").version)
        versionInfo ="版本:".. versionInfo.."."..tostring(CHANNEL_ID)
        uiText_edition:setString(versionInfo)
    end       
    local uiButton_kai_1 = ccui.Helper:seekWidgetByName(self.root,"Button_kai_1")
    local uiButton_guan_1 = ccui.Helper:seekWidgetByName(self.root,"Button_guan_1")
    local items = {uiButton_kai_1, uiButton_guan_1}
    Common:addCheckTouchEventListener(items,false,function(index) 
        if index == 1 then
            UserData.Music:setVolumeSound(1)
        else  
            UserData.Music:setVolumeSound(0)          
        end
    end)
    local volumeSound = UserData.Music:getVolumeSound()
    if volumeSound > 0 then
        items[1]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[1],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(238,105,40))
        end
    else
        items[2]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[2],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(238,105,40))
        end
    end
    
    
    local uiButton_kai_2 = ccui.Helper:seekWidgetByName(self.root,"Button_kai_2")
    local uiButton_guan_2 = ccui.Helper:seekWidgetByName(self.root,"Button_guan_2")
    local items = {uiButton_kai_2, uiButton_guan_2}
    Common:addCheckTouchEventListener(items,false,function(index) 
        if index == 1 then
            UserData.Music:setVolumeMusic(1)
        else  
            UserData.Music:setVolumeMusic(0)          
        end
    end)
    local volumeMusic = UserData.Music:getVolumeMusic()
    if volumeMusic > 0 then
        items[1]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[1],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(238,105,40))
        end
    else
        items[2]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[2],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(238,105,40))
        end
    end
    
    local uiButton_kai_3 = ccui.Helper:seekWidgetByName(self.root,"Button_kai_3")
    local uiButton_guan_3 = ccui.Helper:seekWidgetByName(self.root,"Button_guan_3")
    local items = {uiButton_kai_3, uiButton_guan_3}
    Common:addCheckTouchEventListener(items,false,function(index) 
        if index == 1 then
            UserData.Music:setVolumeVoice(1)
        else  
            UserData.Music:setVolumeVoice(0)          
        end
    end)
    local volumeVoice = UserData.Music:getVolumeVoice()
    if volumeVoice > 0 then
        items[1]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[1],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(238,105,40))
        end
    else
        items[2]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[2],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(238,105,40))
        end
    end
    
    
    local uiButton_qingsong = ccui.Helper:seekWidgetByName(self.root,"Button_qingsong")
    local uiButton_huankuai = ccui.Helper:seekWidgetByName(self.root,"Button_huankuai")
    local uiButton_xiuxian = ccui.Helper:seekWidgetByName(self.root,"Button_xiuxian")
    local items = {uiButton_qingsong, uiButton_huankuai,uiButton_xiuxian}
    local Musictype = cc.UserDefault:getInstance():getFloatForKey("UserDefault_Musictype",1)

    Common:addCheckTouchEventListener(items,false,function(index) 
        if index == 1 then
            local mousic = string.format("achannel/%d/music%d.mp3",CHANNEL_ID,index)
            cc.UserDefault:getInstance():setFloatForKey("UserDefault_Musictype",index)
            cc.SimpleAudioEngine:getInstance():playMusic(mousic,true)
        elseif index == 2 then
            local mousic = string.format("achannel/%d/music%d.mp3",CHANNEL_ID,index)
            cc.UserDefault:getInstance():setFloatForKey("UserDefault_Musictype",index)
            cc.SimpleAudioEngine:getInstance():playMusic(mousic,true)     
        elseif index == 3 then
            local mousic = string.format("achannel/%d/music%d.mp3",CHANNEL_ID,index)
            cc.UserDefault:getInstance():setFloatForKey("UserDefault_Musictype",index)
            cc.SimpleAudioEngine:getInstance():playMusic(mousic,true)         
        end
    end)
    if Musictype == 1 then
        items[1]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[1],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(238,105,40))
        end
    elseif Musictype == 2 then
        items[2]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[2],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(238,105,40))
        end
    elseif Musictype == 3 then
        items[3]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[3],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(238,105,40))
        end
    end
    
    local uiImage_avatar = ccui.Helper:seekWidgetByName(self.root,"Image_avatar")
    Common:requestUserAvatar(UserData.User.userID,UserData.User.szLogoInfo,uiImage_avatar,"img")
     local uiText_name = ccui.Helper:seekWidgetByName(self.root,"Text_name")
    uiText_name:setString(string.format("昵称：%s",UserData.User.szNickName))
    local uiText_ID = ccui.Helper:seekWidgetByName(self.root,"Text_ID")
    uiText_ID:setString(string.format("账号：%d",UserData.User.userID))
    local uiButton_logout = ccui.Helper:seekWidgetByName(self.root,"Button_logout")
    Common:addTouchEventListener(uiButton_logout,function()        
            NetMgr:getLogicInstance():closeConnect()
            require("common.SceneMgr"):switchScene(require("app.MyApp"):create(false,false):createView("LoginLayer"),SCENE_LOGIN)
            EventMgr:dispatch(EventType.EVENT_TYPE_EXIT_HALL)
    end)
    local Update = require("loading.Update")
    local uiButton_Toreport = ccui.Helper:seekWidgetByName(self.root,"Button_Toreport")
    uiButton_Toreport:setVisible(false)
    Common:addTouchEventListener(uiButton_Toreport,function() 
--        if Update.version ~= Update.newVersion and  Update.version ~= nil then         
--            local versionInfoBB = string.format("当前最新版本为%s\n请更新到最新版本",Update.newVersion)                        
--            require("common.MsgBoxLayer"):create(1,nil,versionInfoBB,function() 
--                if resetPackageLoaded then
--                    resetPackageLoaded()
--                end
--                NetMgr:getLogicInstance():closeConnect()
--                EventMgr:dispatch(EventType.EVENT_TYPE_EXIT_HALL)    
--                local scene = cc.Director:getInstance():getRunningScene()
--                scene:removeAllChildren()
--                scene:addChild(require("loading.LoadingLayer"):create())
--            end)
--
--        else
--            require("common.MsgBoxLayer"):create(0,nil,string.format("已是最新版本，无需更新！！！"))
--        end   
    end)    
end




return SettingsLayer
