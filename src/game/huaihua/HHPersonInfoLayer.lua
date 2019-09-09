--[[
*名称:HHPersonInfoLayer
*描述:个人信息
*作者:[]
*创建日期:2018-07-11 09:07:55
*修改日期:
]]

local EventMgr              = require("common.EventMgr")
local EventType             = require("common.EventType")
local NetMgr                = require("common.NetMgr")
local NetMsgId              = require("common.NetMsgId")
local StaticData            = require("app.static.StaticData")
local UserData              = require("app.user.UserData")
local Common                = require("common.Common")
local Default               = require("common.Default")
local GameConfig            = require("common.GameConfig")
local Log                   = require("common.Log")
local GameCommon            = require("game.huaihua.GameCommon") 

local AnimCnf = {
    {'huaihua/ui/info/quantao', 'huaihua/animation/baodai'},
    {'huaihua/ui/info/daoshui', 'huaihua/animation/daoshui'},
    {'huaihua/ui/info/fq', 'huaihua/animation/fq'},
    {'huaihua/ui/info/yiduohua', 'huaihua/animation/meigui008'},
    {'huaihua/ui/info/pengbei', 'huaihua/animation/pengbei'},
    {'huaihua/ui/info/yibahua', 'huaihua/animation/xianhua'},
}

local HHPersonInfoLayer     = class("HHPersonInfoLayer", cc.load("mvc").ViewBase)

function HHPersonInfoLayer:onConfig()
    self.widget             = {
        {"Image_bg"},
        {"Button_close", "onClose"},
        {"Image_avatar"},
        {"Text_name"},
        {"Text_id"},
        {"Button_contol", "onControl"},
        {"Image_faceBg"},
        {"ListView_face"},
    }
end

function HHPersonInfoLayer:onEnter()
end

function HHPersonInfoLayer:onExit()
    cc.UserDefault:getInstance():setBoolForKey('HHOpenUserEffect', self.isOpen)
end

function HHPersonInfoLayer:onCreate(param)
    local data = param[1]
    self.tableObj = param[2]
    self.isOpen = cc.UserDefault:getInstance():getBoolForKey('HHOpenUserEffect', true)
    self:refreshUI(data)
end

function HHPersonInfoLayer:onClose()
    self:removeFromParent()
end

function HHPersonInfoLayer:onControl()
    --是否开启
    self.isOpen = not self.isOpen
    self:updateControl()
end

function HHPersonInfoLayer:updateControl( ... )
    if not self.isOpen then
        local path = 'huaihua/ui/setting/switch_close.png'
        self.Button_contol:loadTextures(path, path, path)
    else
        local path = 'huaihua/ui/setting/switch_open.png'
        self.Button_contol:loadTextures(path, path, path)
    end
end

------------------------------------------------------------------------
--                            game logic                              --
------------------------------------------------------------------------
function HHPersonInfoLayer:refreshUI(data)
    Log.d(data)
    if type(data) ~= 'table' then
        printError('HHPersonInfoLayer:refreshUI data error')
        return
    end
    
    local playInfo = self:getPlayerInfoByUserID(data.dwUserID)
    if not playInfo then
        return
    end

    self:updateControl()

    Common:requestUserAvatar(data.dwUserID,playInfo.szPto,self.Image_avatar,"img")
    self.Text_name:setString(playInfo.szNickName)
    self.Text_id:setString('ID:' .. data.dwUserID)
    self:setFaceActions(data)
    self.Button_contol:setVisible(data.dwUserID == GameCommon.dwUserID)
    self:updateControl()

end

function HHPersonInfoLayer:getPlayerInfoByUserID(dwUserID)
    for i,v in pairs(GameCommon.player or {}) do
        if v.dwUserID == dwUserID then
            return v
        end
    end
end

function HHPersonInfoLayer:setFaceActions(data)
    local faceArr = self.ListView_face:getChildren()
    for i,v in ipairs(faceArr) do
        v:setVisible(false)
    end

    for i,v in ipairs(AnimCnf) do
        local item = faceArr[i]
        if not item then
            item = faceArr[1]:clone()
            self.ListView_face:pushBackCustomItem(item)
        end
        item:setVisible(true)
        local Image_faceIcon = ccui.Helper:seekWidgetByName(item,'Image_faceIcon')
        Image_faceIcon:loadTexture(v[1] .. '.png')

        Image_faceIcon:ignoreContentAdaptWithSize(true)

        item:setPressedActionEnabled(true)
        item:addClickEventListener(function()
            --- 房
            local targetChair = nil           
            for key,info in pairs(GameCommon.player or {}) do
                if info.dwUserID ~= 0 and info.dwUserID == data.dwUserID then
                    targetChair = info.wChairID
                   break
                end
            end
            local count = 0
            for k,v in pairs(GameCommon.player or {}) do
                count = count + 1
            end
            

            if count == 1 then
                require("common.MsgBoxLayer"):create(0,nil,"暂时无法发送")
                self:removeFromParent()
                return
            end
            if targetChair then
                 NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME, NetMsgId.SUB_GF_USER_EFFECTS, "www", i, GameCommon:getRoleChairID(),targetChair)
            end
            
            self:removeFromParent()
        end)
    end
end

------------------------------------------------------------------------
--                            server rvc                              --
------------------------------------------------------------------------

return HHPersonInfoLayer