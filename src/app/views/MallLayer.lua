local EventMgr = require("common.EventMgr")
local EventType = require("common.EventType")
local NetMgr = require("common.NetMgr")
local StaticData = require("app.static.StaticData")
local UserData = require("app.user.UserData")
local Common = require("common.Common")
local Bit = require("common.Bit")
local HttpUrl = require("common.HttpUrl")

local MallLayer = class("MallLayer", cc.load("mvc").ViewBase)

function MallLayer:onEnter()
    EventMgr:registListener(EventType.EVENT_TYPE_RECHARGE_PAY_RESULT,self,self.EVENT_TYPE_RECHARGE_PAY_RESULT)
    EventMgr:registListener(EventType.RET_MALL_FIRST_CHARGE_RECORD,self,self.RET_MALL_FIRST_CHARGE_RECORD)
    EventMgr:registListener(EventType.SUB_CL_USER_INFO,self,self.SUB_CL_USER_INFO)

end

function MallLayer:onExit()
    EventMgr:unregistListener(EventType.EVENT_TYPE_RECHARGE_PAY_RESULT,self,self.EVENT_TYPE_RECHARGE_PAY_RESULT)
    EventMgr:unregistListener(EventType.RET_MALL_FIRST_CHARGE_RECORD,self,self.RET_MALL_FIRST_CHARGE_RECORD)
    EventMgr:unregistListener(EventType.SUB_CL_USER_INFO,self,self.SUB_CL_USER_INFO)

    if self.uiPanel_item then
        self.uiPanel_item:release()
        self.uiPanel_item = nil
    end
end

function MallLayer:onCreate(parames)
    local visibleSize = cc.Director:getInstance():getVisibleSize()
    local csb = cc.CSLoader:createNode("MallLayer.csb")
    self:addChild(csb)
    self.root = csb:getChildByName("Panel_root")
    self.csb = csb
    
   Common:addTouchEventListener(ccui.Helper:seekWidgetByName(self.root,"Button_return"),function() 
        self:removeFromParent()
    end)
    
    self.uiPanel_item = ccui.Helper:seekWidgetByName(self.root, "Panel_item");
    self.uiPanel_item:retain()
    local uiScrollView_contents = ccui.Helper:seekWidgetByName(self.root, "ScrollView_contents")
    uiScrollView_contents:removeAllChildren()

    local uiText_wx = ccui.Helper:seekWidgetByName(self.root, "Text_wx")
    Common:addTouchEventListener(ccui.Helper:seekWidgetByName(self.root, "Button_copy"), function()
        local btnName =  uiText_wx:getString()
        UserData.User:copydata(btnName)
        require("common.MsgBoxLayer"):create(0,nil,"复制成功")
    end)
    Common:addTouchEventListener(ccui.Helper:seekWidgetByName(self.root, "Button_gold"), function()
       self:showUI(0)
    end)
    Common:addTouchEventListener(ccui.Helper:seekWidgetByName(self.root, "Button_roomCard"), function()
       self:showUI(1)
    end)
    Common:addTouchEventListener(ccui.Helper:seekWidgetByName(self.root, "Button_yuanbao"), function()
       self:showUI(2)
    end)

    local uiPanel_pay = ccui.Helper:seekWidgetByName(self.root,"Panel_pay")
    uiPanel_pay:setVisible(false)
    uiPanel_pay:setTouchEnabled(true)
    uiPanel_pay:addTouchEventListener(function(sender,event)
        if event == ccui.TouchEventType.ended then
            uiPanel_pay:setVisible(false)
        end
    end)

    self:updateUserInfo()
    self:showUI(parames[1])
end

function MallLayer:showUI(dwMallID)
    dwMallID = dwMallID or 0
    local tableMall = {}
    if UserData.Mall.tableMallConfig[dwMallID] ~= nil then
        tableMall = clone(UserData.Mall.tableMallConfig[dwMallID])
    else
        return
    end

    local uiButton_gold = ccui.Helper:seekWidgetByName(self.root, "Button_gold")
    local uiButton_roomCard = ccui.Helper:seekWidgetByName(self.root, "Button_roomCard");
    local uiButton_yuanbao = ccui.Helper:seekWidgetByName(self.root, "Button_yuanbao");
    local uiScrollView_contents = ccui.Helper:seekWidgetByName(self.root, "ScrollView_contents")
    uiScrollView_contents:removeAllChildren()
    local size = uiScrollView_contents:getContentSize()
    local width = size.width/4
    local height = 252
    uiScrollView_contents:setInnerContainerSize(cc.size(size.width, height * math.floor(#tableMall/4)))
    
    if dwMallID == 0 then
        uiButton_gold:setBright(false)
        uiButton_roomCard:setBright(true)
        uiButton_yuanbao:setBright(true)
    elseif dwMallID == 1 then
        uiButton_gold:setBright(true)
        uiButton_roomCard:setBright(false)
        uiButton_yuanbao:setBright(true)
    else
        uiButton_gold:setBright(true)
        uiButton_roomCard:setBright(true)
        uiButton_yuanbao:setBright(false)
    end

    dump(tableMall, 'cxx::')
    
    for k,v in pairs(tableMall) do
        local item = self.uiPanel_item:clone()
        uiScrollView_contents:addChild(item)

        local col = (k-1) % 4
        local row = math.floor((k-1) / 4)
        local x = width/2 + col * width
        local y = size.height - height/2 - row * height
        item:setPosition(x, y)

        local uiImage_icon = ccui.Helper:seekWidgetByName(item, "Image_icon")
        local textureName = string.format("goods/%d.png",v.dwGoodsID)
        if cc.FileUtils:getInstance():isFileExist(textureName) then
            local texture = cc.Director:getInstance():getTextureCache():addImage(textureName)
            uiImage_icon:loadTexture(textureName)
            uiImage_icon:setContentSize(texture:getContentSizeInPixels()) 
        else
            uiImage_icon:setVisible(false)
        end
        local uiText_title = ccui.Helper:seekWidgetByName(item, "Text_title")
        uiText_title:setTextColor(cc.c3b(108,84,25))
        uiText_title:setString(v.szTitle)
        local uiText_money = ccui.Helper:seekWidgetByName(item, "Text_money")
        uiText_money:setTextColor(cc.c3b(0,0,0))
        uiText_money:setString(string.format("%d元",v.lPrice))
        local uiImage_first = ccui.Helper:seekWidgetByName(item, "Image_first")
        local uiText_first = ccui.Helper:seekWidgetByName(item, "Text_first")
        if dwMallID == 0 and UserData.Mall.tableMallFirstChargeRecord[v.dwGoodsID] ~= nil then
            uiImage_first:setVisible(true)
            uiText_first:setTextColor(cc.c3b(108,84,25))
            uiText_first:setString(v.szAddition)
        else
            uiImage_first:setVisible(false)
        end
        Common:addTouchEventListener(ccui.Helper:seekWidgetByName(item, "Button_buy"),function()
            self.goodsData = v
            -- local data = clone(UserData.Share.tableShareParameter[7])
            -- UserData.Mall:doPay(2,self.goodsData.dwGoodsID,UserData.User.userID,string.format(data.szShareUrl,self.goodsData.dwGoodsID,UserData.User.userID))
        
            local data = clone(UserData.Share.tableShareParameter[12])
            require("app.MyApp"):create(data):createView("ShareLayer") 
        end)
    end
end

function MallLayer:updateUserInfo()
    local uiImage_goldBg = ccui.Helper:seekWidgetByName(self.root,"Image_goldBg")
    local uiText_gold = ccui.Helper:seekWidgetByName(self.root,"Text_gold")
    local dwGold = Common:itemNumberToString(UserData.User.dwGold)   
    uiText_gold:setString(tostring(dwGold))
    local uiText_roomCard = ccui.Helper:seekWidgetByName(self.root,"Text_roomCard")
    uiText_roomCard:setString(string.format("%d",UserData.Bag:getBagPropCount(1003)))
end

function MallLayer:EVENT_TYPE_RECHARGE_PAY_RESULT(event)
    local data = event._usedata
    if data ~= 0 then
       closeLoadingAnimationLayer()
       require("common.MsgBoxLayer"):create(0,nil,"充值失败！")
       return
    end
    local goodsData = clone(self.goodsData)
    
    local tableReward = {}
    if goodsData.cbTargetUnit == 0 then
        table.insert(tableReward, #tableReward+1, {wPropID = 1001,dwPropCount = goodsData.lCount})
        if goodsData.lFirst > 0 and UserData.Mall.tableMallFirstChargeRecord[goodsData.dwGoodsID] ~= nil then
            table.insert(tableReward, #tableReward+1, {wPropID = 1001,dwPropCount = goodsData.lFirst})
        elseif goodsData.lGift > 0 then
            table.insert(tableReward, #tableReward+1, {wPropID = 1001,dwPropCount = goodsData.lGift})
        else
        end
        require("common.RewardLayer"):create("充值成功！",nil,tableReward)
    elseif goodsData.cbTargetUnit == 1 then
        table.insert(tableReward, #tableReward+1, {wPropID = 1003,dwPropCount = goodsData.lCount})
        if goodsData.lFirst > 0 and UserData.Mall.tableMallFirstChargeRecord[goodsData.dwGoodsID] ~= nil then
            table.insert(tableReward, #tableReward+1, {wPropID = 1003,dwPropCount = goodsData.lFirst})
        elseif goodsData.lGift > 0 then
            table.insert(tableReward, #tableReward+1, {wPropID = 1003,dwPropCount = goodsData.lGift})
        end
        require("common.RewardLayer"):create("充值成功！",nil,tableReward)
    elseif goodsData.cbTargetUnit == 5 then
        table.insert(tableReward, #tableReward+1, {wPropID = 1009,dwPropCount = goodsData.lCount})
        if goodsData.lFirst > 0 and UserData.Mall.tableMallFirstChargeRecord[goodsData.dwGoodsID] ~= nil then
            table.insert(tableReward, #tableReward+1, {wPropID = 1009,dwPropCount = goodsData.lFirst})
        elseif goodsData.lGift > 0 then
            table.insert(tableReward, #tableReward+1, {wPropID = 1009,dwPropCount = goodsData.lGift})
        end
        require("common.RewardLayer"):create("充值成功！",nil,tableReward)
        
    end

    UserData.User:sendMsgUpdateUserInfo(1)
    if goodsData.dwMallID == 0 then
        UserData.Mall:sendMsgGetRechargeRecord()
    end
end

function MallLayer:RET_MALL_FIRST_CHARGE_RECORD()
    self:showUI(0)
end

function MallLayer:SUB_CL_USER_INFO(event)
    self:updateUserInfo()
end

return MallLayer