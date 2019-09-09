local EventMgr = require("common.EventMgr")
local EventType = require("common.EventType")
local NetMgr = require("common.NetMgr")
local StaticData = require("app.static.StaticData")
local UserData = require("app.user.UserData")
local Common = require("common.Common")

local UserInfoLayer = class("UserInfoLayer", cc.load("mvc").ViewBase)

function UserInfoLayer:onEnter()
    EventMgr:registListener(EventType.SUB_CL_USER_INFO,self,self.SUB_CL_USER_INFO)
    self:updateUserInfo()
end

function UserInfoLayer:onExit()
    EventMgr:unregistListener(EventType.SUB_CL_USER_INFO,self,self.SUB_CL_USER_INFO)
end

function UserInfoLayer:onCreate(parames)
    local visibleSize = cc.Director:getInstance():getVisibleSize()
    local csb = cc.CSLoader:createNode("UserInfoLayer.csb")
    self:addChild(csb)
    self.root = csb:getChildByName("Panel_root")
    self.csb = csb

    local Image_bg = self.root:getChildByName("Image_bg")
    -- local callback = function()
    --     require("common.SceneMgr"):switchOperation()
    -- end
    -- Common:playPopupAnim(Image_bg, nil, callback)
    Common:addTouchEventListener(ccui.Helper:seekWidgetByName(self.root,"Button_return"),function() 
        -- Common:playExitAnim(Image_bg, callback)
        self:removeFromParent()
    end)

    local uiButton_copy = ccui.Helper:seekWidgetByName(self.root,"Button_copy")
    Common:addTouchEventListener(uiButton_copy,function()   
        local btnName = string.format("%d", UserData.User.userID)
        UserData.User:copydata(btnName)
        require("common.MsgBoxLayer"):create(0,nil,"复制成功")
    end)
end

--刷新个人信息
function UserInfoLayer:SUB_CL_USER_INFO(event)
    self:updateUserInfo()
end

function UserInfoLayer:updateUserInfo()
    local uiButton_avatar = ccui.Helper:seekWidgetByName(self.root,"Button_avatar")
    Common:requestUserAvatar(UserData.User.userID,UserData.User.szLogoInfo,uiButton_avatar,"btn")
    local uiText_name = ccui.Helper:seekWidgetByName(self.root,"Text_name")
    uiText_name:setString(UserData.User.szNickName)
    local uiImage_genderIcon = ccui.Helper:seekWidgetByName(self.root,"Image_genderIcon")
    if UserData.User.cbGender == 1 then
        uiImage_genderIcon:loadTexture("user/user_b.png")
    else
        uiImage_genderIcon:loadTexture("user/user_g.png")
    end
    local uiText_id = ccui.Helper:seekWidgetByName(self.root,"Text_id")
    uiText_id:setString(string.format("%d",UserData.User.userID))
    local uiText_ip = ccui.Helper:seekWidgetByName(self.root,"Text_ip")
    local addr = UserData.User.city
    if addr == "" then 
        uiText_ip:setString("玩家未定位地区")
    else 
        uiText_ip:setString(addr)
    end 
end


return UserInfoLayer
