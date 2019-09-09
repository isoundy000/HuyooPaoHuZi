local EventMgr = require("common.EventMgr")
local EventType = require("common.EventType")
local NetMgr = require("common.NetMgr")
local StaticData = require("app.static.StaticData")
local UserData = require("app.user.UserData")
local Common = require("common.Common")
local Default = require("common.Default")
local NetMsgId = require("common.NetMsgId")
local HttpUrl = require("common.HttpUrl")

local HallLayer = class("HallLayer", cc.load("mvc").ViewBase)

function HallLayer:onEnter()
    NetMgr:getGameInstance():closeConnect()
    EventMgr:registListener(EventType.SUB_CL_USER_INFO,self,self.SUB_CL_USER_INFO)
    EventMgr:registListener(EventType.EVENT_TYPE_WITH_NEW,self,self.EVENT_TYPE_WITH_NEW)
    EventMgr:registListener(EventType.EVENT_TYPE_EMAIL_NEW,self,self.EVENT_TYPE_EMAIL_NEW)
    EventMgr:registListener(EventType.RET_JOIN_GUILD,self,self.RET_JOIN_GUILD)      --加入公会
    EventMgr:registListener(EventType.EVENT_TYPE_EXTERNAL_START_GAME,self,self.EVENT_TYPE_EXTERNAL_START_GAME) 
    EventMgr:registListener(EventType.EVENT_TYPE_RECHARGE_365,self,self.EVENT_TYPE_RECHARGE_365)
    EventMgr:registListener(EventType.RET_SPORTS_STATE,self,self.RET_SPORTS_STATE)
    EventMgr:registListener(EventType.RET_CLUB_CHAT_BACK_RECORD, self, self.RET_CLUB_CHAT_BACK_RECORD)
    EventMgr:registListener(EventType.RET_NOTICE_GAME_START, self, self.RET_NOTICE_GAME_START)
    cc.Director:getInstance():getRunningScene():addChild(cc.CSLoader:createNode("EffectsLayer.csb"),0x10001,0x10001)
    
    local OperationLayer = cc.UserDefault:getInstance():getStringForKey("UserDefault_Operation","")
    if OperationLayer == "NewClubInfoLayer" then
        local dwClubID = cc.UserDefault:getInstance():getIntegerForKey("UserDefault_NewClubID", 0)
        if dwClubID ~= 0 then
            require("common.SceneMgr"):switchOperation(require("app.MyApp"):create():createView("NewClubInfoLayer"))
        end
    elseif OperationLayer ~= "" then
        require("common.SceneMgr"):switchOperation(require("app.MyApp"):create():createView(OperationLayer))
    end
    local gotoIndex = cc.UserDefault:getInstance():getIntegerForKey("record_hall",0)
    if gotoIndex == 1 then
        local box = require("app.MyApp"):create():createView('NewRecord')
        require("common.SceneMgr"):switchOperation(box)
    end

    UserData.User:sendMsgUpdateUserInfo(1) 
    UserData.Sports:getSportsState()
    UserData.Email:sendMsgRequestEmail()
    UserData.Chat:sendChat()
    self:createGlobalCustomNode()
    Common:voiceEventTracking("InitLogin",UserData.User.userID)
end

function HallLayer:onExit()
    EventMgr:unregistListener(EventType.SUB_CL_USER_INFO,self,self.SUB_CL_USER_INFO)
    EventMgr:unregistListener(EventType.EVENT_TYPE_WITH_NEW,self,self.EVENT_TYPE_WITH_NEW)
    EventMgr:unregistListener(EventType.EVENT_TYPE_EMAIL_NEW,self,self.EVENT_TYPE_EMAIL_NEW)
    EventMgr:unregistListener(EventType.RET_JOIN_GUILD,self,self.RET_JOIN_GUILD) 
    EventMgr:unregistListener(EventType.EVENT_TYPE_EXTERNAL_START_GAME,self,self.EVENT_TYPE_EXTERNAL_START_GAME) 
    EventMgr:unregistListener(EventType.EVENT_TYPE_RECHARGE_365,self,self.EVENT_TYPE_RECHARGE_365)
    EventMgr:unregistListener(EventType.RET_SPORTS_STATE,self,self.RET_SPORTS_STATE)
    EventMgr:unregistListener(EventType.RET_CLUB_CHAT_BACK_RECORD, self, self.RET_CLUB_CHAT_BACK_RECORD)
    EventMgr:unregistListener(EventType.RET_NOTICE_GAME_START, self, self.RET_NOTICE_GAME_START)
end

function HallLayer:onCreate(parames)
    if UserData.User.isFirstEnterHall == true then
        UserData.User.isFirstEnterHall = false
        EventMgr:dispatch(EventType.EVENT_TYPE_FIRST_ENTER_HALL)
    end
    if parames[1] == true then
        self:runAction(cc.Sequence:create(
            cc.DelayTime:create(1.0),
            cc.CallFunc:create(function(sender,event) 
                -- if StaticData.Hide[CHANNEL_ID].btn1 == 1 and UserData.Guild.dwGuildID == 0 and Common:isToday(cc.UserDefault:getInstance():getIntegerForKey(Default.UserDefault_Guil,0)) == false  then
                --     if CHANNEL_ID ~= 20 and  CHANNEL_ID ~= 21 then
                --         self:addChild(require("app.MyApp"):create():createView("GuilLayer"))   
                --     end
                -- end
                -- if StaticData.Hide[CHANNEL_ID].btn12 == 1 and Common:isToday(cc.UserDefault:getInstance():getIntegerForKey(string.format(Default.UserDefault_Sign,UserData.User.userID),0)) == false then
                --     self:addChild(require("app.MyApp"):create(1000):createView("WelfareLayer"))  
                -- end 

                --暂时屏蔽
                if  Common:isToday(cc.UserDefault:getInstance():getIntegerForKey(Default.UserDefault_TuHaoActivity,0)) == false then
                    require("common.SceneMgr"):switchOperation(require("app.MyApp"):create():createView("BouncedLayer")) 
                end 

            end)))
    end
 	 
    local visibleSize = cc.Director:getInstance():getVisibleSize()
    --local halllayer = StaticData.Channels[CHANNEL_ID].halllayer
    local csb = cc.CSLoader:createNode("PHZHallLayer.csb")
    self:addChild(csb)
    self.root = csb:getChildByName("Panel_root")
    self.csb = csb    
    self.showMode = 0
    local uiButton_return = ccui.Helper:seekWidgetByName(self.root,"Button_return")
    if uiButton_return ~= nil then
        Common:addTouchEventListener(uiButton_return,function()
            require("common.MsgBoxLayer"):create(1,nil,"您确定要退出游戏？",function() 
                NetMgr:getLogicInstance():closeConnect()
                require("common.SceneMgr"):switchScene(require("app.MyApp"):create(false,true):createView("LoginLayer"),SCENE_LOGIN)
                EventMgr:dispatch(EventType.EVENT_TYPE_EXIT_HALL)
            end)
        end)   
    end 

    local uiButton_Goldgame = ccui.Helper:seekWidgetByName(self.root,"Button_Goldgame")
    if uiButton_Goldgame ~= nil then
        Common:addTouchEventListener(uiButton_Goldgame,function()
            require("app.MyApp"):create(function() 
                require("common.SceneMgr"):switchOperation(require("app.MyApp"):create():createView("GoldGameLayer"))
            end):createView("InterfaceCheckRoomNode")
        end)
    end 
       
    --充值
    local uiButton_goldBg = ccui.Helper:seekWidgetByName(self.root,"Button_goldBg")
    if  uiButton_goldBg ~= nil and StaticData.Hide[CHANNEL_ID].btn20 == 1 then
        Common:addTouchEventListener(uiButton_goldBg,function()             
          --  require("common.SceneMgr"):switchOperation(require("app.MyApp"):create():createView("MallLayer")) 
            --require("common.SceneMgr"):switchOperation(require("app.MyApp"):create(2):createView("NewMallLayer")) 
            require("common.SceneMgr"):switchOperation(require("app.MyApp"):create(0):createView("MallLayer"))
        end)
        if StaticData.Hide[CHANNEL_ID].btn8 ~= 1 then
            uiButton_goldBg:setVisible(false)
        end
    elseif StaticData.Hide[CHANNEL_ID].btn20 ~= 1 then 
        uiButton_goldBg:setVisible(false)      
    end

    --购买元宝
    local Button_ybBg = ccui.Helper:seekWidgetByName(self.root,"Button_ybBg")
    Common:addTouchEventListener(Button_ybBg, function()             
        require("common.SceneMgr"):switchOperation(require("app.MyApp"):create(2):createView("MallLayer"))
    end)

    --邀请有礼
    local uiButton_invite = ccui.Helper:seekWidgetByName(self.root,"Button_invite")
    if StaticData.Hide[CHANNEL_ID].btn20 ~= 1 then
        uiButton_invite:setVisible(false)
    end
    if  uiButton_invite ~= nil then
        Common:addTouchEventListener(uiButton_invite,function() 
            --require("app.MyApp"):create(self.data):createView("DailyShareLayer") 
            require("common.SceneMgr"):switchOperation(require("app.MyApp"):create():createView("Recommend"))   
        end) 
    end 
    --代开
    local uiButton_proxy  = ccui.Helper:seekWidgetByName(self.root,"Button_proxy")
    if uiButton_proxy~= nil then 
        if StaticData.Hide[CHANNEL_ID].btn11 == 1 then         
            uiButton_proxy:setVisible(true)        
            Common:addTouchEventListener(uiButton_proxy,function()        
                require("common.SceneMgr"):switchOperation(require("app.MyApp"):create():createView("ProxyLayer"))
            end) 
        else
            uiButton_proxy:setVisible(false) 
        end 
    end 

    --福利
    -- local uiButton_welfare = ccui.Helper:seekWidgetByName(self.root,"Button_welfare")
    -- if uiButton_welfare~= nil then 
    --     Common:addTouchEventListener(uiButton_welfare,function()      
    --         require("common.SceneMgr"):switchOperation(require("app.MyApp"):create():createView("WelfareLayer"))
    --     end)
    --     if StaticData.Hide[CHANNEL_ID].btn3 ~= 1 then
    --         uiButton_welfare:setVisible(false)
    --     end
    -- end 

    --切换地区 地区显示
    local uiButton_region = ccui.Helper:seekWidgetByName(self.root,"Button_region") 
    if uiButton_region~= nil then  
        local regionID = cc.UserDefault:getInstance():getIntegerForKey(Default.UserDefault_RegionID,0)
        local uiImage_region = ccui.Helper:seekWidgetByName(self.root,"Image_region")
        uiImage_region:loadTexture(StaticData.Regions[regionID].nameImgs)
        Common:addTouchEventListener(uiButton_region,function() 
            require("common.SceneMgr"):switchOperation(require("app.MyApp"):create():createView("RegionLayer"))
        end)     
        if StaticData.Hide[CHANNEL_ID].btn6 == 0 then
            local uiImage_bgregion =  ccui.Helper:seekWidgetByName(self.root,"Image_bgregion")
            uiImage_bgregion:setVisible(false)
            uiButton_region:setVisible(false)
            uiImage_region:setVisible(false)
            local uiPanel_quick = ccui.Helper:seekWidgetByName(self.root,"Panel_quick")
            if CHANNEL_ID == 18 or CHANNEL_ID == 19 then     
                uiPanel_quick:setPositionX(uiPanel_quick:getParent():getContentSize().width*0.5)
            else
                uiPanel_quick:setPositionX(uiPanel_quick:getParent():getContentSize().width*0.506)
            end
        end
    end 

    --商城   
    local uiButton_mall = ccui.Helper:seekWidgetByName(self.root,"Button_mall")
    if uiButton_mall~= nil then 
        Common:addTouchEventListener(uiButton_mall,function() 
         --   require("common.SceneMgr"):switchOperation(require("app.MyApp"):create(2):createView("NewMallLayer")) 
            require("common.SceneMgr"):switchOperation(require("app.MyApp"):create():createView("MallLayer"))
        end)      
        if StaticData.Hide[CHANNEL_ID].btn8 ~= 1 and  StaticData.Hide[CHANNEL_ID].btn9 ~= 1 then 
            uiButton_mall:setVisible(false)
        end 
    end
  
 
    --公会
    -- local uiButton_guild = ccui.Helper:seekWidgetByName(self.root,"Button_guild")
    -- if uiButton_guild ~= nil then 
    --     if StaticData.Hide[CHANNEL_ID].btn1 ~= 1 then
    --         uiButton_guild:setVisible(false)
    --     end                       
    --     Common:addTouchEventListener(uiButton_guild,function()  
    --         if (CHANNEL_ID == 8 or CHANNEL_ID == 9 ) and UserData.Guild.dwGuildID ~= 0 then
    --             UserData.Share:openURL(StaticData.Channels[CHANNEL_ID].guildFunction)
    --         elseif CHANNEL_ID == 20 or CHANNEL_ID == 21 then             
    --             require("common.SceneMgr"):switchOperation(require("app.MyApp"):create():createView("GuilLayer_6"))
    --         else
    --             require("common.SceneMgr"):switchOperation(require("app.MyApp"):create():createView("GuilLayer"))
    --         end        
    --     end)              
    -- end

    --个人信息
    local uiButton_avatarBg = ccui.Helper:seekWidgetByName(self.root,"Button_avatarBg")
    if  uiButton_avatarBg ~= nil and StaticData.Hide[CHANNEL_ID].btn19 == 1 then 
        uiButton_avatarBg:addTouchEventListener(function(sender,event) 
            if event == ccui.TouchEventType.ended then    
                    Common:palyButton()        
                    require("common.SceneMgr"):switchOperation(require("app.MyApp"):create():createView("UserInfoLayer"))             
            end
        end)             
    end 

    --实名认证
    local uiButton_PerfectInfo = ccui.Helper:seekWidgetByName(self.root,"Button_PerfectInfo")
    if StaticData.Hide[CHANNEL_ID].btn20 ~= 1 then
        uiButton_PerfectInfo:setVisible(false)
    end
    if  uiButton_PerfectInfo ~= nil then 
        Common:addTouchEventListener(uiButton_PerfectInfo,function() 
        
            -- if CHANNEL_ID ~= 20 and CHANNEL_ID ~= 21 then 
                 require("common.SceneMgr"):switchOperation(require("app.MyApp"):create():createView("PerfectInfoLayer"))
            -- else
            --     require("common.SceneMgr"):switchOperation(require("app.MyApp"):create():createView("PerfectInfoLayer_6"))
            -- end 
        end)   
    end 


    --代理咨询
    local uiButton_DaiLi = ccui.Helper:seekWidgetByName(self.root,"Button_DaiLi")
    if StaticData.Hide[CHANNEL_ID].btn20 ~= 1 then
        uiButton_DaiLi:setVisible(false)
    end
    if  uiButton_DaiLi ~= nil and StaticData.Hide[CHANNEL_ID].btn20 == 1 then 
        Common:addTouchEventListener(uiButton_DaiLi,function() 
        
            -- if CHANNEL_ID ~= 20 and CHANNEL_ID ~= 21 then 
                require("common.SceneMgr"):switchOperation(require("app.MyApp"):create(2):createView("NewMallLayer")) 
            -- else
            --     require("common.SceneMgr"):switchOperation(require("app.MyApp"):create():createView("PerfectInfoLayer_6"))
            -- end 
        end)   
    end 
    
    --溆浦客服信息
    local uiPanel_bounced = ccui.Helper:seekWidgetByName(self.root,"Panel_bounced")
    if uiPanel_bounced ~= nil then 
        uiPanel_bounced:setVisible(false) 
        local uiPanel_Tel = ccui.Helper:seekWidgetByName(self.root,"Panel_Tel")
        local uiText_tel = ccui.Helper:seekWidgetByName(uiPanel_Tel,"Text_tel")
        if UserData.Share.tableCustomerParameter.szSettingInfo ~= nil then
            uiText_tel:setString(UserData.Share.tableCustomerParameter.szSettingInfo)
        end        
        Common:addTouchEventListener(ccui.Helper:seekWidgetByName(self.root,"Button_close"),function() 
            --设置
            uiPanel_bounced:setVisible(false)
        end)
    end
        
    --房卡转道具商城    
    local uiButton_roomCardBg = ccui.Helper:seekWidgetByName(self.root,"Button_roomCardBg")
    if uiButton_roomCardBg ~= nil and StaticData.Hide[CHANNEL_ID].btn20 == 1 then   
        uiButton_roomCardBg:setEnabled(true)
        Common:addTouchEventListener(uiButton_roomCardBg,function()             
            -- if CHANNEL_ID ~= 10 and  CHANNEL_ID ~= 11  then 
            --     if StaticData.Hide[CHANNEL_ID].btn8 ~= 0 then
           -- require("common.SceneMgr"):switchOperation(require("app.MyApp"):create(2):createView("MallLayer"))

            --require("common.SceneMgr"):switchOperation(require("app.MyApp"):create(2):createView("NewMallLayer")) 
            --     else 
            --         if uiPanel_bounced~= nil then 
            --             uiPanel_bounced:setVisible(true)
            --         end    
            --     end
            -- else
            --    require("common.MsgBoxLayer"):create(2,nil,"客服微信:tykf668") 
            -- end 

            require("common.SceneMgr"):switchOperation(require("app.MyApp"):create(1):createView("MallLayer"))
        end)    
        if StaticData.Hide[CHANNEL_ID].btn9 ~= 1 and CHANNEL_ID ~= 10 and  CHANNEL_ID ~= 11 and CHANNEL_ID ~= 4 and  CHANNEL_ID ~= 5 then
            uiButton_roomCardBg:setVisible(false)                      
        end
    elseif StaticData.Hide[CHANNEL_ID].btn20 ~= 1 then 
        uiButton_roomCardBg:setVisible(false)    
    end            

    if  CHANNEL_ID == 20 or CHANNEL_ID == 21 then 
            if uiButton_roomCardBg ~= nil then   
                uiButton_roomCardBg:setVisible(true)  
                uiButton_roomCardBg:setEnabled(false)
            end                        
            local uiImage_roomCard = ccui.Helper:seekWidgetByName(self.root,"Image_roomCard") 
            uiImage_roomCard:setEnabled(true)         
            uiImage_roomCard:addTouchEventListener(function(sender,event) 
            if event == ccui.TouchEventType.ended then 
                    Common:palyButton() 
                require("common.MsgBoxLayer"):create(2,nil,"客服微信：wwdp7777") 
                end 
            end)
     end 
     
    --邮件
    local uiButton_email = ccui.Helper:seekWidgetByName(self.root,"Button_email")
    if uiButton_email ~= nil then
        Common:addTouchEventListener(uiButton_email,function() 
           -- require("common.SceneMgr"):switchOperation(require("app.MyApp"):create():createView("EmailLayer"))
           --require("app.MyApp"):create():createView("News")   
           require("common.SceneMgr"):switchOperation(require("app.MyApp"):create():createView("News"))
        end)
        local uiImage_look = ccui.Helper:seekWidgetByName(self.root,"Image_look")
        uiImage_look:setVisible(false)
    end 
    --设置
    local uiButton_setting = ccui.Helper:seekWidgetByName(self.root,"Button_setting")
    if uiButton_setting ~= nil then
        Common:addTouchEventListener(uiButton_setting,function()             
            require("common.SceneMgr"):switchOperation(require("app.MyApp"):create():createView("SettingsLayer"))
        end)
    end    
    --游戏规则
    local uiButton_game = ccui.Helper:seekWidgetByName(self.root,"Button_game")
    if uiButton_game ~= nil then
        Common:addTouchEventListener(uiButton_game,function()      
            require("common.SceneMgr"):switchOperation(require("app.MyApp"):create():createView("GameplayLayer"))
        end)
    end  
    --战绩 
    local uiButton_record = ccui.Helper:seekWidgetByName(self.root,"Button_record")
    if uiButton_record ~= nil then
        Common:addTouchEventListener(uiButton_record,function() 
            local box = require("app.MyApp"):create():createView('NewRecord')
            require("common.SceneMgr"):switchOperation(box)
        end) 
    end
    if StaticData.Hide[CHANNEL_ID].btn20 ~= 1 then 
        uiButton_record:setVisible(false)    
    end    


    --亲友圈 
    local uiButton_club = ccui.Helper:seekWidgetByName(self.root,"Button_club")
    if uiButton_club ~= nil then
        Common:addTouchEventListener(uiButton_club,function()
            -- local dwClubID = cc.UserDefault:getInstance():getIntegerForKey("UserDefault_NewClubID", 0)
            -- if dwClubID ~= 0 then
                require("common.SceneMgr"):switchOperation(require("app.MyApp"):create():createView("NewClubInfoLayer"))
            -- else
            --     require("common.SceneMgr"):switchOperation(require("app.MyApp"):create():createView("NewClubLayer"))
            -- end
        end)
    end

    --创房、加入按钮处理       
    local uiButton_createFriendsRoom = ccui.Helper:seekWidgetByName(self.root,"Button_createFriendsRoom")
    if uiButton_createFriendsRoom ~= nil then
        Common:addTouchEventListener(uiButton_createFriendsRoom,function()  
            require("app.MyApp"):create(function() 
                require("common.SceneMgr"):switchOperation(require("app.MyApp"):create():createView("RoomCreateLayer"))
            end):createView("InterfaceCheckRoomNode")  
        end)
    end  
    local uiButton_joinFriendsRoom = ccui.Helper:seekWidgetByName(self.root,"Button_joinFriendsRoom")
    if uiButton_joinFriendsRoom ~= nil then
        Common:addTouchEventListener(uiButton_joinFriendsRoom,function() 
            require("app.MyApp"):create(function() 
                require("common.SceneMgr"):switchOperation(require("app.MyApp"):create():createView("RoomJoinLayer"))
            end):createView("InterfaceCheckRoomNode")
        end)
    end  


    --溆浦游戏创房
    local uiButton_xupu = ccui.Helper:seekWidgetByName(self.root,"Button_xupu")
    if uiButton_xupu ~= nil then
        Common:addTouchEventListener(uiButton_xupu,function()   
            require("app.MyApp"):create(function() 
                require("common.SceneMgr"):switchOperation(require("app.MyApp"):create(42):createView("RoomCreateLayer"))      
            end):createView("InterfaceCheckRoomNode")    
        end)
    end
    local uiButton_paohuzi = ccui.Helper:seekWidgetByName(self.root,"Button_paohuzi")
    if uiButton_paohuzi ~= nil then
        Common:addTouchEventListener(uiButton_paohuzi,function()   
            require("app.MyApp"):create(function() 
                require("common.SceneMgr"):switchOperation(require("app.MyApp"):create(43):createView("RoomCreateLayer"))      
            end):createView("InterfaceCheckRoomNode")            
        end)
    end
    local uiButton_majiang = ccui.Helper:seekWidgetByName(self.root,"Button_majiang")
    if uiButton_majiang ~= nil then
        Common:addTouchEventListener(uiButton_majiang,function()  
            require("app.MyApp"):create(function() 
                require("common.SceneMgr"):switchOperation(require("app.MyApp"):create(52):createView("RoomCreateLayer"))      
            end):createView("InterfaceCheckRoomNode")             
        end)
    end
    local uiButton_moregame = ccui.Helper:seekWidgetByName(self.root,"Button_moregame")
    if uiButton_moregame ~= nil then
        Common:addTouchEventListener(uiButton_moregame,function()  
            require("app.MyApp"):create(function() 
                require("common.SceneMgr"):switchOperation(require("app.MyApp"):create(25):createView("RoomCreateLayer"))      
            end):createView("InterfaceCheckRoomNode")             
        end)
    end 

    --竞技场
    local uiButton_sports = ccui.Helper:seekWidgetByName(self.root,"Button_sports")
    if uiButton_sports ~= nil then
        Common:addTouchEventListener(uiButton_sports,function() 
            require("common.SceneMgr"):switchOperation(require("app.MyApp"):create():createView("SportsLayer"))
        end) 
    end  
            
    --广播
    local uiPanel_broadcast = ccui.Helper:seekWidgetByName(self.root,"Panel_broadcast")
    local uiText_broadcast = ccui.Helper:seekWidgetByName(self.root,"Text_broadcast")
    local function showBroadcast(sender,event)
        if UserData.Notice.cycleBroadcast ~= nil and uiPanel_broadcast:isVisible() == false then
            local data = UserData.Notice.cycleBroadcast
            uiText_broadcast:setString(data.szBroadcastInfo)
            print(uiText_broadcast:getAutoRenderSize().width)
            local time = (uiText_broadcast:getParent():getContentSize().width + uiText_broadcast:getAutoRenderSize().width)/100
            uiText_broadcast:setPositionX(uiText_broadcast:getParent():getContentSize().width)
            uiText_broadcast:runAction(cc.MoveTo:create(time,cc.p(-uiText_broadcast:getAutoRenderSize().width,uiText_broadcast:getPositionY())))
            uiPanel_broadcast:runAction(cc.Sequence:create(cc.DelayTime:create(time),cc.Hide:create(),cc.DelayTime:create(5),cc.CallFunc:create(showBroadcast)))
            uiPanel_broadcast:setVisible(true)
            uiText_broadcast:setVisible(true)
        else
            uiPanel_broadcast:setVisible(false)
            uiPanel_broadcast:runAction(cc.Sequence:create(cc.DelayTime:create(1),cc.CallFunc:create(showBroadcast)))
        end
    end
    showBroadcast()

    --底排按钮排列距离
    -- if CHANNEL_ID ~= 18 and CHANNEL_ID ~= 19 and CHANNEL_ID ~= 20 and CHANNEL_ID ~= 21 and  CHANNEL_ID ~= 4 and CHANNEL_ID ~= 5 then
    --     local uiListView_function = ccui.Helper:seekWidgetByName(self.root,"ListView_function")                
    --     if #uiListView_function:getItems() == 8 then
    --     uiListView_function:setItemsMargin(109)
    --     end
    --     if #uiListView_function:getItems() == 7 then
    --     uiListView_function:setItemsMargin(130)
    --     end
    --     if #uiListView_function:getItems() == 6 then
    --     uiListView_function:setItemsMargin(168)
    --     end
    --     if #uiListView_function:getItems() == 5 then
    --     uiListView_function:setItemsMargin(190)
    --     end
    -- end

    --商务合作
    local uiButton_recruit = ccui.Helper:seekWidgetByName(self.root,"Button_recruit")
    if uiButton_recruit ~= nil then 
        Common:addTouchEventListener(uiButton_recruit,function() 
            require("common.SceneMgr"):switchOperation(require("app.MyApp"):create():createView("RecruitLayer"))
        end)
    end 
    local uiText_customer_1 = ccui.Helper:seekWidgetByName(self.root,"Text_customer_1") 
    if uiText_customer_1 ~= nil then    
        uiText_customer_1:setString(string.format("%s",StaticData.Channels[CHANNEL_ID].serviceVX_1))
        local uiText_customer_2 = ccui.Helper:seekWidgetByName(self.root,"Text_customer_2")
        uiText_customer_2:setString(string.format("%s",StaticData.Channels[CHANNEL_ID].serviceVX_2))                    
    end
    
    --大厅分享
    local uiButton_doshare = ccui.Helper:seekWidgetByName(self.root,"Button_doshare")
    if uiButton_doshare ~= nil then           
        Common:addTouchEventListener(uiButton_doshare,function() 
            local data = clone(UserData.Share.tableShareParameter[0])
            require("app.MyApp"):create(data):createView("ShareLayer")   
        end)  
    end 

    if StaticData.Hide[CHANNEL_ID].btn20 ~= 1 then 
        uiButton_doshare:setVisible(false)    
    end    

    --个人历史战绩
    local uiButton_historicalRecord = ccui.Helper:seekWidgetByName(self.root,"Button_historicalRecord")
    if uiButton_historicalRecord ~= nil then
        Common:addTouchEventListener(uiButton_historicalRecord,function() 
            local data = clone(UserData.Share.tableShareParameter[11])
            require("app.MyApp"):create(data):createView("ShareLayer")  
        end) 
    end 
    self:updateUserInfo()
end

--刷新个人信息
function HallLayer:SUB_CL_USER_INFO(event)
    self:updateUserInfo()
end

function HallLayer:updateUserInfo(event)
    local uiImage_avatar = ccui.Helper:seekWidgetByName(self.root,"Image_avatar")
    local uiText_name = ccui.Helper:seekWidgetByName(self.root,"Text_name")    
    uiText_name:setString(string.format("%s",UserData.User.szNickName))
    local uiButton_goldBg = ccui.Helper:seekWidgetByName(self.root,"Button_goldBg")
    local uiText_gold = ccui.Helper:seekWidgetByName(self.root,"Text_gold")     
    local dwGold = Common:itemNumberToString(UserData.User.dwGold)    
    if  uiText_gold ~=nil then 
        uiText_gold:setString(tostring(dwGold))
    end 
    local uiText_roomCard = ccui.Helper:seekWidgetByName(self.root,"Text_roomCard")    
    uiText_roomCard:setString(string.format("%d",UserData.Bag:getBagPropCount(1003)))   
    local uiText_ID = ccui.Helper:seekWidgetByName(self.root,"Text_ID")
    uiText_ID:setString(string.format("ID:%d",UserData.User.userID))
    Common:requestUserAvatar(UserData.User.userID,UserData.User.szLogoInfo,uiImage_avatar,"img")

    local Text_yuanbao = ccui.Helper:seekWidgetByName(self.root,"Text_yuanbao")    
    Text_yuanbao:setString(string.format("%d",UserData.Bag:getBagPropCount(1009)))

    if  CHANNEL_ID ~= 4 and CHANNEL_ID ~= 5  and CHANNEL_ID ~= 20 and CHANNEL_ID ~= 21 and self.sCircle~= nil then       
        local number = 2  
        if   UserData.Welfare.tableWelfare[1004] ~=nil and  UserData.Welfare.tableWelfare[1004].IsEnded == 1 then 
            number = number -1 
        end 
        if    UserData.Welfare.tableWelfare[1005] ~=nil and UserData.Welfare.tableWelfare[1005].IsEnded == 1 then 
            number = number -1 
        end          
        self.sCircle:removeAllChildren()
        local uiText_title = cc.Label:createWithSystemFont(number,"Arial",24)
        uiText_title:setAnchorPoint(cc.p(0.5,0.5))
        uiText_title:setTextColor(cc.c3b(255,255,255))
        self.sCircle:addChild(uiText_title)
        uiText_title:setPosition(uiText_title:getParent():getContentSize().width/2,uiText_title:getParent():getContentSize().height/2+3)--cc.p(uiText_title:getPosition()
        if number == 0 then 
            self.sCircle:setVisible(false)
        elseif  number > 0 then  
            self.sCircle:setVisible(true)
        end
    end                
end


function HallLayer:EVENT_TYPE_EXTERNAL_START_GAME(event)
    if UserData.User.externalAdditional ~= "" then
        require("common.SceneMgr"):switchOperation(require("app.MyApp"):create(tonumber(UserData.User.externalAdditional)):createView("RoomJoinLayer"))
    end
end

function HallLayer:EVENT_TYPE_WITH_NEW(event)
    local regionID = cc.UserDefault:getInstance():getIntegerForKey(Default.UserDefault_RegionID,0)
    local uiImage_region = ccui.Helper:seekWidgetByName(self.root,"Image_region")
    uiImage_region:loadTexture(StaticData.Regions[regionID].nameImgs)
    UserData.Game:loadGameData()
end

function HallLayer:EVENT_TYPE_EMAIL_NEW(event) 
    if  CHANNEL_ID == 18 or   CHANNEL_ID == 19 or  CHANNEL_ID == 20 or   CHANNEL_ID == 21 or  CHANNEL_ID == 4 or   CHANNEL_ID == 5 then 
       return  
    end 
    -- local uiImage_look = ccui.Helper:seekWidgetByName(self.root,"Image_look")
    -- local number = 0 
    -- if UserData.Email.tableEmail == nil then 
    --     return
    -- end 
    -- for i = 1 , #UserData.Email.tableEmail do
    --     if  UserData.Email.tableEmail[i].bRead == false then 
    --         number = number + 1
    --     end 
    -- end 
   
    -- if number > 0 then 
    --     uiImage_look:setVisible(true)
    -- else
    --     uiImage_look:setVisible(false)
    -- end 
    -- local uiText_number = ccui.Helper:seekWidgetByName(self.root,"Text_number")
    -- uiText_number:setString(number)
       
end

function HallLayer:EVENT_TYPE_RECHARGE_365(event)
    local ret = event._usedata
    local uiButton_topup = ccui.Helper:seekWidgetByName(self.root,"Button_topup")
    if ret == 0 then
        uiButton_topup:setVisible(false)
    else
        uiButton_topup:setVisible(true)
    end
end

function HallLayer:RET_JOIN_GUILD(event)
    local data = event._usedata  
    if CHANNEL_ID == 20 or  CHANNEL_ID == 21 then       
        if data.ret == 0 then   
            UserData.Guild.dwID = data.dwID
            UserData.Guild.dwGuildID = data.dwGuildID
            UserData.Guild.szGuildName = data.szGuildName
            UserData.Guild.szGuildNotice = data.szGuildNotice
            UserData.Guild.dwMemberCount = data.dwMemberCount
            UserData.Guild.dwPresidentID = data.dwPresidentID
            UserData.Guild.szPresidentName = data.szPresidentName
            UserData.Guild.szPresidentLogo = ""
            
--            if CHANNEL_ID ~= 8 and  CHANNEL_ID ~= 9 then      
--                require("common.RewardLayer"):create("公会",nil,{{wPropID = 1003,dwPropCount = 5 }})    
--            end 
            UserData.User:sendMsgUpdateUserInfo(1)   
        else 
            require("common.MsgBoxLayer"):create(0,nil,"请求失败！")          
        end
    end
end

function HallLayer:RET_SPORTS_STATE(event)
    local data = event._usedata
    local uiButton_sports = ccui.Helper:seekWidgetByName(self.root,"Button_sports")
    local uiImage_sports = ccui.Helper:seekWidgetByName(self.root,"Image_sports")
    if uiButton_sports == nil then
        return
    end
    if data.isOpenSports == true then
        uiButton_sports:setEnabled(true)
        if CHANNEL_ID ~= 20 and CHANNEL_ID ~= 21 then
             uiImage_sports:setVisible(false)
        end 
    else
        uiButton_sports:setEnabled(false)
        uiButton_sports:setVisible(false)
        if CHANNEL_ID ~= 20 and CHANNEL_ID ~= 21 then
            uiImage_sports:setVisible(true)
            uiImage_sports:loadTexture("common/hall_97.png")
        end 
    end
end


--@cxx add 骨骼动画ios上释放崩溃，所以这里做个全局保存
function HallLayer:createGlobalCustomNode()
    local scene = cc.Director:getInstance():getRunningScene()
    local node = cc.Director:getInstance():getNotificationNode()
    if not node then
        node = cc.Node:create()
        scene:addChild(node)
        cc.Director:getInstance():setNotificationNode(node)
        printInfo('create global_node ...')
    else
        local arr = node:getChildren()
        for i,v in ipairs(arr) do
            v:setVisible(false)
        end
    end
end

function HallLayer:RET_CLUB_CHAT_BACK_RECORD(event)
    local data = event._usedata
    require("common.SceneMgr"):switchTips(require("app.MyApp"):create(data):createView("PleaseReciveLayer"))
end

function HallLayer:RET_NOTICE_GAME_START(event)
    local data = event._usedata
    dump(data,'游戏人满:')
    require("common.MsgBoxLayer"):create(1, nil, "游戏人数已满,是否进入?", function()
        require("common.SceneMgr"):switchTips(require("app.MyApp"):create(data.dwTableID):createView("InterfaceJoinRoomNode"))
    end)
end

return HallLayer

