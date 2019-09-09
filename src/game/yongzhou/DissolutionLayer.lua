local EventMgr = require("common.EventMgr")
local EventType = require("common.EventType")
local NetMgr = require("common.NetMgr")
local NetMsgId = require("common.NetMsgId")
local UserData = require("app.user.UserData")
local Common = require("common.Common")
local StaticData = require("app.static.StaticData")
local NetMsgId = require("common.NetMsgId")


local DissolutionLayer = class("DissolutionLayer", function()
    return ccui.Layout:create()
end)

function DissolutionLayer:create(...)
    local view = DissolutionLayer.new()
    view:onCreate(...)
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

function DissolutionLayer:onEnter()

end

function DissolutionLayer:onExit()

end

function DissolutionLayer:onCleanup()

end

function DissolutionLayer:onCreate(...)    
    require("common.SceneMgr"):switchTips(self)
    local visibleSize = cc.Director:getInstance():getVisibleSize()
    local csb = cc.CSLoader:createNode("YZMsgBoxLayer.csb")
    self:addChild(csb)
    self.root = csb:getChildByName("Panel_root")
    self.csb = csb
    local params = {...} 
    local uiPanel_ok = ccui.Helper:seekWidgetByName(self.root,"Panel_ok")
    local uiPanel_okCancel = ccui.Helper:seekWidgetByName(self.root,"Panel_okCancel")
    local uiPanel_agreeCancel = ccui.Helper:seekWidgetByName(self.root,"Panel_agreeCancel")
    local uiPanel_tips = ccui.Helper:seekWidgetByName(self.root,"Panel_tips")
    local uiPanel_Blackscreen = ccui.Helper:seekWidgetByName(self.root,"Panel_Blackscreen")

    local GameCommon = require("game.yongzhou.GameCommon") 
    uiPanel_ok:removeFromParent()
    uiPanel_okCancel:removeFromParent()
    uiPanel_agreeCancel:setVisible(true)
    uiPanel_tips:removeFromParent()
    local uiText_contents = ccui.Helper:seekWidgetByName(self.root,"Text_contents")
    uiText_contents:setString(params[1]) 
    local data = params[3]
    local advocateName = nil 
    local fqzName = ""
    local refuseName = ""
    for i = 1 , 8 do                  
        if data.wAdvocateDisbandedID == i-1 then
            advocateName = data.szNickNameALL[i]
        else
            if data.cbDisbandeState[i] == 1 then
                if data.szNickNameALL[i] ~="" then 
                    fqzName =  fqzName..data.szNickNameALL[i].."同意解散".."\n"
                end 
            elseif data.cbDisbandeState[i] == 0 then
                if data.szNickNameALL[i] ~="" then 
                    fqzName =  fqzName..data.szNickNameALL[i].."等待解散选择".."\n"
                end 
            end
        end 
        if data.cbDisbandeState[i] == 2 then
            refuseName = data.szNickNameALL[i]           
        end               
    end     
    
    if refuseName ~= "" then         
        self:runAction(cc.Sequence:create(cc.DelayTime:create(0),cc.RemoveSelf:create()))      
        require("game.yongzhou.MsgBoxLayer"):create(2,nil,string.format("%s拒绝解散房间",refuseName))     
    end
   --GameCommon.meChairID ==  data.wAdvocateDisbandedID or
    local uiText_countdown = ccui.Helper:seekWidgetByName(self.root,"Text_contents")
    -- if  data.cbDisbandeState[ GameCommon.meChairID+1 ] == 1 then 
        uiText_countdown:setString(string.format("%s申请解散房间，是否同意？(剩余%d秒) \n %s",advocateName,data.dwDisbandedTime,fqzName))
        advocateName= advocateName.."申请解散房间，是否同意？"       
    -- else
    --     uiText_countdown:setString(string.format("%s申请解散房间，是否同意？(剩余%d秒) ",advocateName,data.dwDisbandedTime)) 
    --     advocateName= advocateName.."申请解散房间，是否同意？"
    -- end 
    uiText_countdown:setTextColor(cc.c3b(17,47,73))

    uiText_countdown:runAction(cc.RepeatForever:create(cc.Sequence:create(
        cc.DelayTime:create(1),
        cc.CallFunc:create(function(sender,event) 
            -- if data.cbDisbandeState[ GameCommon.meChairID+1 ] == 1 then 
                uiText_countdown:setString(string.format("%s(剩余%d秒)\n %s",advocateName,data.dwDisbandedTime,fqzName))
            -- else
            --     uiText_countdown:setString(string.format("%s(剩余%d秒) ",advocateName,data.dwDisbandedTime))
            -- end 
            data.dwDisbandedTime = data.dwDisbandedTime - 1
            if data.dwDisbandedTime < 0 then
                data.dwDisbandedTime = 0
            end          
        end)
    )))

    local uiButton_agree = ccui.Helper:seekWidgetByName(self.root,"Button_agree")
    Common:addTouchEventListener(uiButton_agree,function()
        self:removeFromParent() 
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER,NetMsgId.REQ_GR_DISMISS_TABLE_REPLY,"o",true)
    end)
    local uiButton_refuse = ccui.Helper:seekWidgetByName(self.root,"Button_refuse")
    Common:addTouchEventListener(uiButton_refuse,function() 
        self:removeFromParent()
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER,NetMsgId.REQ_GR_DISMISS_TABLE_REPLY,"o",false)
    end)
    if data.cbDisbandeState[GameCommon.meChairID +1] == 1  then 
        uiButton_agree:setVisible(false)
        uiButton_refuse:setVisible(false)
    end          
    self.root:setTouchEnabled(true)
--    Common:playPopupAnim(uiPanel_agreeCancel)

end

return DissolutionLayer
