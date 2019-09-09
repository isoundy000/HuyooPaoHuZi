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


function DissolutionLayer:create(wChairID,player,data)
    local view = DissolutionLayer.new()
    view:onCreate(wChairID,player,data)
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

function DissolutionLayer:onCreate(wChairID,player,data)
    require("common.SceneMgr"):switchTips(self)
    local visibleSize = cc.Director:getInstance():getVisibleSize()
    local csb = cc.CSLoader:createNode("DissolutionLayer.csb")
    self:addChild(csb)
    self.root = csb:getChildByName("Panel_root")
    --进度动作
    local uiText_countdown = ccui.Helper:seekWidgetByName(self.root,"Text_countdown")
    uiText_countdown:setString(string.format("%02d:%02d",math.floor(data.dwDisbandedTime/60),data.dwDisbandedTime%60))
    self.uiLoadingBar_pro = ccui.Helper:seekWidgetByName(self.root,"LoadingBar")
    self.uiLoadingBar_pro:setPercent(data.dwDisbandedTime*0.56)
    uiText_countdown:runAction(cc.RepeatForever:create(cc.Sequence:create(
        cc.DelayTime:create(1),
        cc.CallFunc:create(function(sender,event) 
            uiText_countdown:setString(string.format("%02d:%02d",math.floor(data.dwDisbandedTime/60),data.dwDisbandedTime%60))
            self.uiLoadingBar_pro:setPercent(data.dwDisbandedTime*0.56)
            data.dwDisbandedTime = data.dwDisbandedTime - 1
            if data.dwDisbandedTime < 0 then
                data.dwDisbandedTime = 0
            end
         
           
        end)
    )))
    
    local uiListView_content = ccui.Helper:seekWidgetByName(self.root,"ListView_content")
    local uiPanel_player = uiListView_content:getItem(0)
    uiPanel_player:retain()
    uiListView_content:removeAllItems()
    local color = cc.c3b(0,0,0)
    local refuseName = ""
    local advocateName = ""
    local isSwitch = true
    local count = 0
    for i = 1, 8 do
      if data.wKindID ~= nil and data.wKindID  == 42 then 
            if data.dwUserIDALL[i] ~= 0 and player ~= nil and player[i] ~= nil then
                count = count + 1
                local item = uiPanel_player:clone()
                uiListView_content:pushBackCustomItem(item)
                local uiImage_avatar = ccui.Helper:seekWidgetByName(item,"Image_avatar")
                Common:requestUserAvatar(data.dwUserIDALL[i],player[i].szPto,uiImage_avatar,"img")
                local uiText_name = ccui.Helper:seekWidgetByName(item,"Text_name")
                uiText_name:setTextColor(color)
                uiText_name:setString(data.szNickNameALL[i])
                local uiImage_displayimg = ccui.Helper:seekWidgetByName(item,"Image_displayimg")
                if data.cbDisbandeState[i] == 1 then
                    uiImage_displayimg:loadTexture("common/Dissolution01.png")
                    uiImage_displayimg:setScale(1.1)
                    if data.wAdvocateDisbandedID == i-1 then
                        advocateName = data.szNickNameALL[i]
                    end
                elseif data.cbDisbandeState[i] == 2 then
                    uiImage_displayimg:loadTexture("common/Dissolution01.png")
                    refuseName = data.szNickNameALL[i]
                else
                    if i-1 == wChairID then
                        isSwitch = false
                    end
                    uiImage_displayimg:loadTexture("common/Dissolution02.png")
                    uiImage_displayimg:setScale(1,0.7)
                end
            end
      else 
        if data.dwUserIDALL[i] ~= 0 and player ~= nil and player[i-1] ~= nil then
            count = count + 1
            local item = uiPanel_player:clone()
            uiListView_content:pushBackCustomItem(item)
            local uiImage_avatar = ccui.Helper:seekWidgetByName(item,"Image_avatar")
            Common:requestUserAvatar(data.dwUserIDALL[i],player[i-1].szPto,uiImage_avatar,"img")
            local uiText_name = ccui.Helper:seekWidgetByName(item,"Text_name")
            uiText_name:setTextColor(color)
            uiText_name:setString(data.szNickNameALL[i])
            local uiImage_displayimg = ccui.Helper:seekWidgetByName(item,"Image_displayimg")
            if data.cbDisbandeState[i] == 1 then
                uiImage_displayimg:loadTexture("common/Dissolution01.png")
                uiImage_displayimg:setScale(1.1)
                if data.wAdvocateDisbandedID == i-1 then
                    advocateName = data.szNickNameALL[i]
                end
            elseif data.cbDisbandeState[i] == 2 then
                uiImage_displayimg:loadTexture("common/Dissolution01.png")
                refuseName = data.szNickNameALL[i]
            else
                if i-1 == wChairID then
                    isSwitch = false
                end
                uiImage_displayimg:loadTexture("common/Dissolution02.png")
                uiImage_displayimg:setScale(1,0.7)
            end
          end
       end 
       -- Common:requestUserAvatar(data.dwUserIDALL[i],player[i-1].szPto,uiImage_avatar,"img")
    end
    
    if advocateName ~= "" then
        local uiText_tips = ccui.Helper:seekWidgetByName(self.root,"Text_tips")
        uiText_tips:setString(string.format(uiText_tips:getString(),advocateName))
    end
    if refuseName ~= "" then
        self:runAction(cc.Sequence:create(cc.DelayTime:create(0),cc.RemoveSelf:create()))
        require("common.MsgBoxLayer"):create(2,nil,string.format("%s拒绝解散房间",refuseName)) 
    end
    local uiPanel_button = ccui.Helper:seekWidgetByName(self.root,"Panel_button")
    if isSwitch == true then
        uiPanel_button:setVisible(false)
    else
        local uiButton_agree = ccui.Helper:seekWidgetByName(self.root,"Button_agree")
        Common:addTouchEventListener(uiButton_agree,function() 
            NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER,NetMsgId.REQ_GR_DISMISS_TABLE_REPLY,"o",true)
        end)
        local uiButton_refuse = ccui.Helper:seekWidgetByName(self.root,"Button_refuse")
        Common:addTouchEventListener(uiButton_refuse,function() 
            NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER,NetMsgId.REQ_GR_DISMISS_TABLE_REPLY,"o",false)
        end)
    end
    
    local uiPanel_contents = ccui.Helper:seekWidgetByName(self.root,"Panel_contents")
    local margin = (uiPanel_contents:getContentSize().width-uiPanel_player:getContentSize().width*count)/(count+1)
    uiListView_content:refreshView()
    uiListView_content:setItemsMargin(margin)--间距
    uiListView_content:setContentSize(cc.size(uiPanel_player:getContentSize().width*count + margin*(count-1) ,uiPanel_contents:getContentSize().height))
    uiListView_content:setPositionX((uiPanel_contents:getContentSize().width - uiListView_content:getContentSize().width)/2)
  
    
    uiPanel_player:release()
end

return DissolutionLayer
    