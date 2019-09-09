---------------
--   二级弹框
---------------

local CDNoticeBox = class("CDNoticeBox", cc.load("mvc").ViewBase)

function CDNoticeBox:onConfig( )
    self.widget = {
        {'content'},
        {'close','onClose'},
        {'close_2','closeTwoCall'},
        {'close_1','closeOneCall'},
        {'close_2_des'},
        {'close_1_des'},
    }
end

---------------
-- content：内容
-- closeState: 1 显示 2 隐藏
-- close:func  --可填,可不填
-- button1 = {xx,func}   --填一个居中
-- button2 = {xx,func}
---------------
function CDNoticeBox:onCreate( params )
    self:setInfo(params)
end

function CDNoticeBox:setInfo( params )
    self.content:setString(params[1].content or '');
    self.btn1 = params[1].button1
    self.btn2 = params[1].button2
    self.closeCallFunc = params[1].close
    local center = nil
    if params[1].closeState then
        self.close:setVisible(params[1].closeState == 1)
    else
        self.close:setVisible(true);
    end


    self.close_2:setVisible(self.btn2 ~= nil)
    self.close_1:setVisible(self.btn1 ~= nil)
    if self.btn1 then
        self.close_1_des:setString(self.btn1[1] or '')
        center = self.close_1
        self.close_1:setPosition(167,72)
    end

    if self.btn2 then
        self.close_2_des:setString(self.btn2[1] or '')
        center = self.close_2
        self.close_2:setPosition(410,72 )
    end
    local isCenter = (not self.btn1 or not self.btn2)
    --居中
    if isCenter then
        center:setPosition(285,self.close_1:getPositionY())
    end
end

function CDNoticeBox:onClose( )
    if self.closeCallFunc then
        self.closeCallFunc()
    end
    if SceneMgr.sceneName ~= SCENE_HALL then
        self:removeFromParent()
    end
end

function CDNoticeBox:closeTwoCall()
    if self.btn2 then
        if self.btn2[2] then
            self.btn2[2]()
        end
    end
    if SceneMgr.sceneName ~= SCENE_HALL then
        self:removeFromParent()
    end
end


function CDNoticeBox:closeOneCall( )
    if self.btn1 then
        if self.btn1[2] then
            self.btn1[2]()
        end
    end
    if SceneMgr.sceneName ~= SCENE_HALL then
        local Common = require("common.Common")
        print("++++++++：",tolua.isnull(self) )
        if  tolua.isnull(self)  then
            return
        end         
        self:runAction(cc.Sequence:create(cc.DelayTime:create(0.1), cc.CallFunc:create(function(sender, event)
            if self:getParent()~= nil then
                self:removeFromParent()
            end 
        end)))
    end
end

return CDNoticeBox