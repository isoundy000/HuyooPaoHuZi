local Bit = require("common.Bit")

local GameDesc = {}

function GameDesc:getGameDesc(wKindID,data,tableConfig)
    if not (wKindID and data) then
        return ""
    end

    local desc = ""
    if wKindID == 24 then      
       if data.bPlayerCount == 3 then
           desc = desc.."3人房"
       else
           desc = desc.."2人房"
       end    
       if data.bPlayerCount == 2 then
        if data.bDeathCard == 1 then
            desc = desc.."/抽牌20张"
        else
            desc = desc.."/不抽底牌"
        end
      end    
       if data.FanXing.bType == 1 then
           desc = desc.."/翻醒"
       elseif data.FanXing.bType == 2 then
           desc = desc.."/翻醒"
       elseif data.FanXing.bType == 3 then
           desc = desc.."/随醒"
       else
           desc = desc.."/不带醒"
       end      
       if data.bStartTun == 1 then
           desc = desc.."/带底2分"
       end
       if data.bYiWuShi == 1 then
           desc = desc.."/有一五十"
       end          
       if Bit:_and(data.dwMingTang,0x02) ~= 0 then
           desc = desc.."/红黑点"
       end
       if Bit:_and(data.dwMingTang,0x01) ~= 0 then
           desc = desc.."/自摸翻倍"
       end

       desc = desc.."\n"
       if data.bHuType == 1 then
           desc = desc.."/有胡必胡"
       elseif data.bHuType == 2 then
           desc = desc.."/点炮必胡"
       end
       if data.bPiaoHu == 1 then
           desc = desc.."/飘胡"
       end
       if data.bStopCardGo == 1 then
           desc = desc.."/冲招" 
       end    
       if Bit:_and(data.dwMingTang,0x0D00) ~= 0 then
           desc = desc.."/天地海底胡"
       end        
       if data.bDelShowCardHu == 1 then
           desc = desc.."/可胡示众牌"
       end
       if data.bStartBanker == 1 then
           desc = desc.."/首局房主坐庄"
       else
           desc = desc.."/首局随机坐庄"
       end                
    elseif wKindID == 27 then 
        if data.bLaiZiCount == 0 then
            desc = "无王"
        elseif data.bLaiZiCount == 1 then
            desc = "单王"
        elseif data.bLaiZiCount == 2 then
            desc = "双王"
        else
        end           
        if data.bPlayerCount == 2 then
            desc = desc.."/双人竞技"
        elseif data.bPlayerCount == 3 then
            desc = desc.."/3人房"
        elseif data.bPlayerCount == 4 then
            desc = desc.."/4人房"
        end
        if data.FanXing.bType == 1 then
            desc = desc.."/翻省"
        elseif data.FanXing.bType == 2 then
            desc = desc.."/翻省"
        elseif data.FanXing.bType == 3 then
            desc = desc.."/跟省"
        else
            desc = desc.."/不翻省"
        end
        if data.FanXing.bAddTun == 3 then
            desc = desc.."/一省三囤"
        elseif data.FanXing.bAddTun == 1 then
            desc = desc.."/一省一囤"
        else                
        end      
        if data.bMaxLost == 300 then
            desc = desc.."/300封顶"
        elseif data.bMaxLost == 600 then
            desc = desc.."/600封顶"
        end
        
    elseif wKindID == 34 then 
        if data.bLaiZiCount == 0 then
            desc = "无王"
        elseif data.bLaiZiCount == 1 then
            desc = "单王"
        elseif data.bLaiZiCount == 2 then
            desc = "双王"
        elseif data.bLaiZiCount == 3 then
            desc = "三王"
        else
        end             
        if data.bPlayerCount == 3 then
            desc = desc.."/3人房"
        elseif data.bPlayerCount == 2 then
            desc = desc.."/2人房"
        else
            desc = desc.."/4人房"
        end
        if data.FanXing.bType == 1 then
            desc = desc.."/翻省"
        elseif data.FanXing.bType == 2 then
            desc = desc.."/翻省"
        elseif data.FanXing.bType == 3 then
            desc = desc.."/跟省"
        else
            desc = desc.."/不翻省"
        end
        if data.FanXing.bType ~= 0 then 
            if data.bDouble == 1 then
                desc = desc.."/双省"
            else
                desc = desc.."/单省"
            end
        end 
        if data.FanXing.bAddTun == 3 then
            desc = desc.."/一省三囤"
        elseif data.FanXing.bAddTun == 1 then
            desc = desc.."/一省一囤"
        else                
        end      
        if data.bMaxLost == 300 then
            desc = desc.."/300封顶"
        elseif data.bMaxLost == 600 then
            desc = desc.."/600封顶"
        end
        if data.bDeathCard == 1 then
            desc = desc.."/亡牌"         
        end          
        if data.bHostedTime == 1 then
            desc = desc.."/一分钟托管"
        elseif data.bHostedTime == 2 then
            desc = desc.."/两分钟托管"
        elseif data.bHostedTime == 3 then
            desc = desc.."/三分钟托管"
        elseif data.bHostedTime == 5 then
            desc = desc.."/五分钟托管"
        elseif data.bHostedTime == 0 then
            desc = desc.."/无托管"
        end
     

        if data.bHostedSession == 1 then
            desc = desc.."/单局托管"
        elseif data.bHostedSession == 3 then
            desc = desc.."/三局托管"
        elseif data.bHostedSession >= 6 then
            desc = desc.."/全局托管"
        end
    elseif  wKindID == 36 then       
        if data.bPlayerCount == 3 then
            desc = desc.."3人房"
        elseif data.bPlayerCount == 4 then
            desc = desc.."4人(坐醒)"
--        elseif data.bPlayerCount == 2 then
--            desc = desc.."双人竞技"
        end
        desc = desc..string.format("/%d胡起胡",data.bCanHuXi) 
        if data.FanXing.bType == 1 then
            desc = desc.."/翻醒"
        elseif data.FanXing.bType == 2 then
            desc = desc.."/翻醒"
        elseif data.FanXing.bType == 3 then
            desc = desc.."/跟醒"
        else
            desc = desc.."/不翻醒"
        end
        if data.FanXing.bAddTun == 3 then
            desc = desc.."/一醒三囤"
        elseif data.FanXing.bAddTun == 2 then
            desc = desc.."/双醒"
        elseif data.FanXing.bAddTun == 1 then
            desc = desc.."/单醒"
        else                
        end  
--        if data.bLaiZiCount == 4 then 
--            if data.bLimit == 1 then
--                desc = desc.."/按番限胡"
--            elseif data.bLimit == 2 then
--                desc = desc.."/按王限胡"
--            end
--        end
--        if Bit:_and(data.dwMingTang,0x8) ~= 0 then
--            desc = desc.."/红转点"
--        end
        if Bit:_and(data.dwMingTang,0x10) ~= 0 then
            desc = desc.."/红转朱黑"
        end
        if Bit:_and(data.dwMingTang,0x01) ~= 0 then
            desc = desc.."/带底"
        end
        if data.bMaxLost == 300 then
            desc = desc.."/300封顶"
--        elseif data.bMaxLost == 600 then
--            desc = desc.."/600封顶"
        end
    elseif wKindID == 37 or wKindID == 33 or wKindID == 35 or wKindID == 36 then       
        if data.bPlayerCount == 3 then
            desc = desc.."3人房"
        elseif data.bPlayerCount == 4 then
            desc = desc.."4人房"
        elseif data.bPlayerCount == 2 then
            desc = desc.."双人竞技"
        end
        desc = desc..string.format("/%d胡起胡",data.bCanHuXi) 
        if data.FanXing.bType == 1 then
            desc = desc.."/翻省"
        elseif data.FanXing.bType == 2 then
            desc = desc.."/翻省"
        elseif data.FanXing.bType == 3 then
            desc = desc.."/跟省"
        else
            desc = desc.."/不翻省"
        end
        if data.FanXing.bAddTun == 3 then
            desc = desc.."/一省三囤"
        elseif data.FanXing.bAddTun == 2 then
            desc = desc.."/双省"
        elseif data.FanXing.bAddTun == 1 then
            desc = desc.."/单省"
        else                
        end  
        if data.bLaiZiCount == 4 then 
            if data.bLimit == 1 then
                desc = desc.."/按番限胡"
            elseif data.bLimit == 2 then
                desc = desc.."/按王限胡"
            end
        end
        if Bit:_and(data.dwMingTang,0x8) ~= 0 then
            desc = desc.."/红转点"
        end
        if Bit:_and(data.dwMingTang,0x10) ~= 0 then
            desc = desc.."/红转黑"
        end
        if Bit:_and(data.dwMingTang,0x01) ~= 0 then
            desc = desc.."/带底"
        end

        if data.bMaxLost == 300 then
            desc = desc.."/300封顶"
        elseif data.bMaxLost == 600 then
            desc = desc.."/600封顶"
        end

        if wKindID == 37 then
            if data.bSettlement == 1 then
                desc = desc.."/带一底"
            elseif data.bSettlement == 3 then
                desc = desc.."/带三底"
            elseif data.bSettlement == 5 then
                desc = desc.."/带五底"
            end
        end

        if data.bHostedTime == 1 then
            desc = desc.."/一分钟托管"
        elseif data.bHostedTime == 2 then
            desc = desc.."/两分钟托管"
        elseif data.bHostedTime == 3 then
            desc = desc.."/三分钟托管"
        elseif data.bHostedTime == 5 then
            desc = desc.."/五分钟托管"
        elseif data.bHostedTime == 0 then
            desc = desc.."/无托管"
        end

        if data.bHostedSession then
            if data.bHostedSession == 1 then
                desc = desc.."/单局托管"
            elseif data.bHostedSession == 3 then
                desc = desc.."/三局托管"
            elseif data.bHostedSession >= 6 then
                desc = desc.."/全局托管"
            end
        end
            
    elseif wKindID == 31 then   
        if data.bLaiZiCount == 1 then
            desc = desc.."单王"
        elseif data.bLaiZiCount == 2 then
            desc = desc.."双王"
        elseif data.bLaiZiCount == 3 then
            desc = desc.."三王"
        elseif data.bLaiZiCount == 4 then
            desc = desc.."四王"
        end    
        if data.bPlayerCount == 3 then
            desc = desc.."/3人房"
        elseif data.bPlayerCount == 4 then
            desc = desc.."/4人房"
        elseif data.bPlayerCount == 2 then
            desc = desc.."/双人竞技"
        end
        if data.bCanHuXi == 15 then
            desc = desc.."/15胡息"
        elseif data.bCanHuXi == 18 then
            desc = desc.."/18胡息"
        elseif data.bCanHuXi == 21 then
            desc = desc.."/21胡息"
        else                
        end 
        if data.FanXing.bType == 1 then
            desc = desc.."/翻省"
        elseif data.FanXing.bType == 2 then
            desc = desc.."/翻省"
        elseif data.FanXing.bType == 3 then
            desc = desc.."/跟省"
        else
            desc = desc.."/不翻省"
        end
        if data.FanXing.bAddTun == 3 then
            desc = desc.."/一省三囤"
        elseif data.FanXing.bAddTun == 2 then
            desc = desc.."/双省"
        elseif data.FanXing.bAddTun == 1 then
            desc = desc.."/单省"
        else                
        end  
        if data.bLaiZiCount == 4 then 
            if data.bLimit == 1 then
                desc = desc.."/按番限胡"
            elseif data.bLimit == 2 then
                desc = desc.."/按王限胡"
            end
        end
        if Bit:_and(data.dwMingTang,0x8) ~= 0 then
            desc = desc.."/红转点"
        end
        if Bit:_and(data.dwMingTang,0x10) ~= 0 then
            desc = desc.."/红转黑"
        end
        -- if Bit:_and(data.dwMingTang,0x01) ~= 0 then
        --     desc = desc.."/带底"
        -- end
        if data.bMaxLost == 300 then
            desc = desc.."/300封顶"
        elseif data.bMaxLost == 600 then
            desc = desc.."/600封顶"
        end

        if data.bSettlement == 1 then
            desc = desc.."/带一底"
        elseif data.bSettlement == 3 then
            desc = desc.."/带三底"
        elseif data.bSettlement == 5 then
            desc = desc.."/带五底"
        end
    
    elseif wKindID == 38 then        
       if data.bPlayerCount == 3 then
           desc = desc.."3人房"
       else
           desc = desc.."4人房"
       end
       if data.bCanHuXi == 15 then
           desc = desc.."/15胡息起胡"
       end

       if data.bSettlement == 1 then
           desc = desc.."/三息一囤"
       else            
           desc = desc.."/一息一囤"
       end 
       if data.FanXing.bType == 1 then
           desc = desc.."/翻醒"
       elseif data.FanXing.bType == 2 then
           desc = desc.."/翻醒"
       elseif data.FanXing.bType == 3 then
           desc = desc.."/随醒"
       else
           desc = desc.."/不翻醒"
       end        
       if Bit:_and(data.dwMingTang,0x01) ~= 0 then
           desc = desc.."/自摸翻倍"
       end
       if data.bStartTun == 2 then
           desc = desc.."/底分2分"
       end
       if Bit:_and(data.dwMingTang,0x02) ~= 0 then
           desc = desc.."/红黑点"
       end
       if data.bHuType == 1 then
           desc = desc.."/有胡必胡"
       elseif data.bHuType == 2 then
           desc = desc.."/放炮必胡"
       end

       if data.bStartBanker == 1 then
           desc = desc.."/首局房主坐庄"
       else
           desc = desc.."/首局随机坐庄"
       end
        
    elseif wKindID == 40 then         
        if data.bPlayerCount == 3 then
            desc = desc.."3人房"
        elseif data.bPlayerCount == 2 then
            desc = desc.."2人房"
        else
            desc = desc.."4人房"
        end
        if data.bYiWuShi == 1 then
            desc = desc.."/有一五十"
        end  
        if data.bFangPao == 1 then
            desc = desc.."/明偎" 
        else            
            desc = desc.."/暗偎"
        end 
        if data.bDelShowCardHu == 0 then
            desc = desc.."/可胡示众牌" 
        end
        if data.bStartTun == 2 then
            desc = desc.."/底分2分"
        end
        if data.bSettlement == 1 then
            desc = desc.."/三息一囤"
        else            
            desc = desc.."/一息一囤"
        end 
        if data.bCanHuXi == 6 then
            desc = desc.."/6息起胡"
        elseif data.bCanHuXi == 9 then
            desc = desc.."/9息起胡"
        elseif data.bCanHuXi == 15 then
            desc = desc.."/15息起胡"
        end   
        if data.FanXing.bType == 1 then
            desc = desc.."/翻醒"
        elseif data.FanXing.bType == 2 then
            desc = desc.."/翻醒"
        elseif data.FanXing.bType == 3 then
            desc = desc.."/随醒"
        else
            desc = desc.."/不带醒"
        end
        if data.FanXing.bAddTun == 3 then
            desc = desc.."/一垛三囤"   
        elseif data.FanXing.bAddTun == 1 then
            desc = desc.."/一垛一囤"
        else
        end

        desc = desc.."\n"

        if data.bPlayerCount == 2 then
            if data.bDeathCard == 1 then
                desc = desc.."/抽牌20张"
            else
                desc = desc.."/不抽底牌"
            end 
        end
        if data.bPiaoHu == 1 then
            desc = desc.."/飘胡"
        end 
        if data.bStopCardGo == 1 then
            desc = desc.."/冲招"
        end 
        if Bit:_and(data.dwMingTang,0x01) ~= 0 then
            desc = desc.."/自摸翻倍"
        end
        if Bit:_and(data.dwMingTang,0x02) ~= 0 then
            desc = desc.."/红黑点胡"
        end
        if Bit:_and(data.dwMingTang,0x20) ~= 0 then
            desc = desc.."/碰碰胡"
        end
        if Bit:_and(data.dwMingTang,0x40) ~= 0 then
            desc = desc.."/大小字胡"
        end
        if Bit:_and(data.dwMingTang,0x0D00) ~= 0 then
            desc = desc.."/天地海底胡"
        end
        if data.bHuType == 1 then
            desc = desc.."/有胡必胡"
        elseif data.bHuType == 2 then
            desc = desc.."/点炮必胡"
        end
        if data.bCardCount21 == 1 then
            desc = desc.."/21张"
        end 
        if data.bMinLostCell ~= 1   then  
            if data.bMinLost == 0 then 
                desc = desc.."/不限分加倍" 
            elseif data.bMinLost == 10 then   
                desc = desc.."/低于10分加倍" 
            elseif data.bMinLost == 20 then   
                desc = desc.."/低于20分加倍" 
            elseif data.bMinLost == 30 then   
                desc = desc.."/低于30分加倍" 
            end           
        end 

        if data.bMinLostCell == 1   then  
        elseif data.bMinLostCell == 2   then 
            desc = desc.."/翻2倍" 
        elseif data.bMinLostCell == 3   then   
            desc = desc.."/翻3倍"
        elseif data.bMinLostCell == 4   then   
            desc = desc.."/翻4倍"
        end  

        if data.bStartBanker == 1 then
            desc = desc.."/首局房主坐庄"
        else
            desc = desc.."/首局随机坐庄"
        end
    elseif wKindID == 44 then  
        desc = desc.."18胡息起胡，名堂15胡可胡"    
       if data.bPlayerCount == 3 then
           desc = desc.."/三人房"
       elseif data.bPlayerCount == 2 then
           desc = desc.."/2人PK"
       else
           desc = desc.."/4人(坐醒)"
       end
       
       -- if data.bCanHuXi == 15 then
       --     desc = desc.."/15胡息起胡" 
       -- elseif data.bCanHuXi == 18 then
       --     desc = desc.."/18胡息起胡"
       -- elseif data.bCanHuXi == 21 then
       --     desc = desc.."/21胡息起胡"
       -- end
       -- if Bit:_and(data.dwMingTang,0x01) ~= 0 then
       --     desc = desc.."/15胡可自摸"
       -- end
       if data.bDeathCard == 1 then
            desc = desc.."/去牌"
       end 
       if data.bMaxLost == 200 then
           desc = desc.."/200封顶"
       elseif data.bMaxLost == 600 then
           desc = desc.."/600封顶"
       end

        
     elseif wKindID == 39 then       
       if data.bPlayerCount == 3 then
           desc = desc.."3人房"
       else
           desc = desc.."2人PK"
       end
        -- if data.FanXing.bType == 3 then
        --     desc = desc.."/跟垛"
        -- else
        --     desc = desc.."/无垛"
        -- end
        if Bit:_and(data.dwMingTang,0x08) ~= 0 then
            desc = desc.."/一点红"
        else
            desc = desc.."/不带一点红"
        end
    --    if data.bFangPao == 1 then
    --        desc = desc.."/有冲招"
    --    else
    --        desc = desc.."/无冲招"
    --    end
       if data.bHuType == 2 then
           desc = desc.."/点炮必胡"
       end
       if data.bCanHuXi == 0 then
           desc = desc.."/无胡"
       else
           desc = desc.."/不带无胡"
       end
       
       if data.bCanJuShouZuoSheng == 1 then
        desc = desc.."/举手做声"
       end
       
       if data.bCanSiShou == 1 then
           desc = desc.."/允许弃牌"
       end

       if data.bStartBanker == 1 then
            desc = desc.."/首局房主坐庄"
        else
            desc = desc.."/首局随机坐庄"
        end
        
    elseif wKindID == 47 then       
        if data.bPlayerCount == 3 then
            desc = desc.."三人房"
        elseif data.bPlayerCount == 2 then
            desc = desc.."双人竞技"
        end
		if data.bPlayerCount == 2 then
        if data.bDeathCard == 1 then
            desc = desc.."/抽牌20张"
        else
            desc = desc.."/不抽底牌"
        end
      end
        -- if data.bCanHuXi == 15 then
        --     desc = desc.."/15胡息起胡"
        -- elseif data.bCanHuXi == 18 then
        --     desc = desc.."/18胡息起胡"
        -- elseif data.bCanHuXi == 21 then
        --     desc = desc.."/21胡息起胡"
        -- end
        if data.bStartTun == 1 then
            desc = desc.."/底分2分"
        elseif data.bStartTun == 2 then
            desc = desc.."/底分3分"
        elseif data.bStartTun == 3 then
            desc = desc.."/底分4分"
        elseif data.bStartTun == 4 then
            desc = desc.."/底分5分"
        else
            desc = desc.."/底分1分"
        end
        if data.bMaxLost == 100 then
            desc = desc.."/100封顶"
        elseif data.bMaxLost == 200  then
            desc = desc.."/200封顶"
        elseif data.bMaxLost == 300  then
            desc = desc.."/300封顶"
        elseif data.bMaxLost == 0  then
            desc = desc.."/不封顶"
        end
        if Bit:_and(data.dwMingTang,0x2000) ~= 0 then
            desc = desc.."/对对胡"
        end
        if data.bStartBanker == 1 then
            desc = desc.."/首局房主坐庄"
        else
            desc = desc.."/首局随机坐庄"
        end
        
    elseif wKindID == 48 then        
      if data.bPlayerCount == 3 then
          desc = desc.."三人"
      elseif data.bPlayerCount == 2 then
          desc = desc.."二人"
      end

      if data.bPlayerCount == 2 then
        if data.bDeathCard == 1 then
            desc = desc.."/抽牌20张"
        else
            desc = desc.."/不抽底牌"
        end
      end
      
      if Bit:_and(data.dwMingTang,0x04) ~= 0 then
         desc = desc.."/大团圆"
      end
      if Bit:_and(data.dwMingTang,0x08) ~= 0 then
         desc = desc.."/行行息"
      end
      if data.bDelShuaHou == 0 then
          desc = desc.."/耍猴"
      end
      if data.bTingHuAll == 1 then
        desc = desc .. "/听胡"
      end
      if data.bHuangFanAddUp == 1 then
        desc = desc .. "/黄番"
      end
      if Bit:_and(data.dwMingTang,0x8000) ~= 0 then
         desc = desc.."/假行行"
      end
      if data.bSiQiHong == 1 then
        desc = desc.."/四七红"
      end
      
      if data.bStartTun == 1 then
         desc = desc.."/底分2分"
      elseif data.bStartTun == 2 then
         desc = desc.."/底分3分"
      elseif data.bStartTun == 3 then
         desc = desc.."/底分4分"
      elseif data.bStartTun == 4 then
         desc = desc.."/底分5分"
      else
         desc = desc.."/底分1分"
      end

      if data.bMaxLost == 100 then
         desc = desc.."/100封顶"
      elseif data.bMaxLost == 200  then
         desc = desc.."/200封顶"
      elseif data.bMaxLost == 300  then
         desc = desc.."/300封顶"
      elseif data.bMaxLost == 0  then
         desc = desc.."/不封顶"
      end

      if data.bStartBanker == 1 then
         desc = desc.."/首局房主坐庄"
      else
         desc = desc.."/首局随机坐庄"
      end

    elseif wKindID == 49 then        
       if data.bPlayerCount == 3 then
           desc = desc.."三人房"
       elseif data.bPlayerCount == 2 then
           desc = desc.."双人竞技"
       end
	   if data.bPlayerCount == 2 then
        if data.bDeathCard == 1 then
            desc = desc.."/抽牌20张"
        else
            desc = desc.."/不抽底牌"
        end
      end
       if data.bStartTun == 1 then
           desc = desc.."/底分2分"
       elseif data.bStartTun == 2 then
           desc = desc.."/底分3分"
       elseif data.bStartTun == 3 then
           desc = desc.."/底分4分"
       elseif data.bStartTun == 4 then
           desc = desc.."/底分5分"
       else
           desc = desc.."/底分1分"
       end
       if data.bMaxLost == 100 then
           desc = desc.."/100封顶"
       elseif data.bMaxLost == 200  then
           desc = desc.."/200封顶"
       elseif data.bMaxLost == 300  then
           desc = desc.."/300封顶"
       elseif data.bMaxLost == 0  then
           desc = desc.."/不封顶"
       end
       if data.bStartBanker == 1 then
           desc = desc.."/首局房主坐庄"
       else
           desc = desc.."/首局随机坐庄"
       end
    elseif wKindID == 68 then         
        if data.bPlayerCount == 2 then
            desc = desc.."双人竞技"
        elseif data.bPlayerCount == 3 then
            desc = desc.."3人"
        else
            desc = desc.."4人"
        end
        if data.bMaType == 1 then
            desc = desc.."/一五九"
        elseif data.bMaType == 2 then
            desc = desc.."/窝窝鸟"
        elseif data.bMaType == 3 then
            desc = desc.."/一马全中"
        elseif data.bMaType == 6 then
            desc = desc.."/翻几奖几"
        else
            desc = desc.."/摸几奖几"
        end
        if data.bMaCount == 2 then
            desc = desc.."/2个马"
        elseif data.bMaCount == 4 then
            desc = desc.."/4个马"
        elseif data.bMaCount == 6 then
            desc = desc.."/6个马"
        elseif data.bMaCount == 8 then
            desc = desc.."/8个马"
        else

        end
        if data.bNiaoType == 1 then
            desc = desc.."/一马一分"
        elseif data.bNiaoType == 2 then
            desc = desc.."/一马两分"
        end
        if data.bQGHu == 1 then
            desc = desc.."/抢杠胡"
        else
            desc = desc.."/无抢杠胡"
        end
        if data.bQGHuJM == 1 then
            desc = desc.."/抢杠胡奖马"
        end
        if data.bHuangZhuangHG == 1 then
            desc = desc.."/黄庄荒杠"
        end
        if data.bJiePao == 1 then
            desc = desc.."/可接炮"
        end
        if data.bQingSH == 1 then
            desc = desc.."/清水胡"
        end
        if data.bQiDui == 1 then
            desc = desc.."/七对"
        end
    elseif wKindID == 25 then        
        if data.bPlayerCount == 3 then
            desc = desc.."3人房"
        else
            desc = desc.."2人(PK)"
        end
        if data.bStartCard ~= 0 then
            desc = desc.."/首局黑桃3必出"
        else
            desc = desc.."/首局黑桃3不必出"
        end  
        if data.bBombSeparation == 1 then
            desc = desc.."/炸弹可拆"
        end
        if data.bRed10 == 1 then
            desc = desc.."/红桃10扎鸟"
        end
        if data.b4Add3 == 1 then
            desc = desc.."/可4带3"
        end
        if data.bShowCardCount == 1 then
            desc = desc.."/显示牌数"
        end
        if data.bAbandon == 1 then
            desc = desc.."/放走包赔"
        end
        if data.bCheating == 1 then
            desc = desc.."/防作弊"
        end
        if data.bFalseSpring == 1 then
            desc = desc.."/假春天"
        end
        desc = desc..string.format("/%d张全关",data.bSpringMinCount)
                
    elseif wKindID == 26 then         
        if data.bPlayerCount == 3 then
            desc = desc.."3人房"
        else
            desc = desc.."2人(PK)"
        end
        if data.bStartCard ~= 0 then
            desc = desc.."/首局黑桃3必出"
        else
            desc = desc.."/首局黑桃3不必出"
        end  
        if data.bBombSeparation == 1 then
            desc = desc.."/炸弹可拆"
        end
        if data.bRed10 == 1 then
            desc = desc.."/红桃10扎鸟"
        end
        if data.b4Add3 == 1 then
            desc = desc.."/可4带3"
        end
        if data.bShowCardCount == 1 then
            desc = desc.."/显示牌数"
        end
        if data.bAbandon == 1 then
            desc = desc.."/放走包赔"
        end
        if data.bFalseSpring == 1 then
            desc = desc.."/假春天"
        end
        desc = desc..string.format("/%d张全关",data.bSpringMinCount)

    elseif wKindID == 46 then
        if data.bPlayerCount == 2 then
            desc = desc.."双人竞技"
        elseif data.bPlayerCount == 3 then
            desc = desc.."3人"
        else
            desc = desc.."4人"
        end
        if data.bMaType == 1 then
            desc = desc.."/一五九"
        elseif data.bMaType == 2 then
            desc = desc.."/窝窝鸟"
        elseif data.bMaType == 3 then
            desc = desc.."/一马全中"
        else
            desc = desc.."/摸几奖几"
        end
        if data.bMaCount == 2 then
            desc = desc.."/2个马"
        elseif data.bMaCount == 4 then
            desc = desc.."/4个马"
        elseif data.bMaCount == 6 then
            desc = desc.."/6个马"
        else

        end
        if data.bQGHu == 1 then
            desc = desc.."/抢杠胡"
        else
            desc = desc.."/无抢杠胡"
        end
        if data.bQGHuJM == 1 then
            desc = desc.."/抢杠胡奖马"
        end
        if data.bHuangZhuangHG == 1 then
            desc = desc.."/黄庄荒杠"
        end
        if data.bJiePao == 1 then
            desc = desc.."/可接炮"
        end
        if data.mNiaoType == 1 then
            desc = desc.."/一鸟一分"
        end
        if data.bQiDui == 1 then
            desc = desc.."/七对"
        end
    elseif wKindID == 50 then         
        if data.bPlayerCount == 2 then
            desc = desc.."双人竞技"
        elseif data.bPlayerCount == 3 then
            desc = desc.."3人"
        else
            desc = desc.."4人"
        end

        if data.bNiaoAdd == 1 then
            desc = desc.."/中鸟加分"
        elseif data.bNiaoAdd == 2 then
            desc = desc.."/中鸟翻倍"
        else
        end
        if data.mNiaoCount == 1 then
            desc = desc.."/1个鸟"
        elseif data.mNiaoCount == 2 then
            desc = desc.."/2个鸟"
        elseif data.mNiaoCount == 4 then
            desc = desc.."/4个鸟"
        elseif data.mNiaoCount == 6 then
            desc = desc.."/6个鸟"
        else
        end
        if data.bMQFlag == 1 then
            desc = desc.."/门清"
        end
        if data.mZXFlag == 1 then
            desc = desc.."/庄闲(算分)"
        end
        if data.bJJHFlag == 1 then
            desc = desc.."/假将胡"
        end
        if data.mPFFlag == 1 then
            desc = desc.."/漂分"
        end
    
        if data.bLLSFlag == 1 then
            desc = desc.."/六六顺"
        end
        if data.bQYSFlag == 1 then
            desc = desc.."/缺一色"
        end    
        desc = desc.."\n"
        if data.bWJHFlag == 1 then
            desc = desc.."/无将胡"
        end
        if data.bDSXFlag == 1 then
            desc = desc.."/大四喜"
        end
        if data.mZTSXlag == 1 then
            desc = desc.."/中途四喜"
        end
        if data.bBBGFlag == 1 then
            desc = desc.."/步步高"
        end
        if data.bSTFlag == 1 then
            desc = desc.."/三同"
        end
        if data.bYZHFlag == 1 then
            desc = desc.."/一枝花"
        end

        if data.bWuTong == 0 then
            desc = desc.."/去掉筒子"
        end

    elseif wKindID == 70 then         
        if data.bPlayerCount == 2 then
            desc = desc.."双人竞技"
        elseif data.bPlayerCount == 3 then
            desc = desc.."3人"
        else
            desc = desc.."4人"
        end

        if data.bNiaoAdd == 1 then
            desc = desc.."/中鸟加分"
        elseif data.bNiaoAdd == 2 then
            desc = desc.."/中鸟翻倍"
        else
        end
        if data.mNiaoCount == 1 then
            desc = desc.."/1个鸟"
        elseif data.mNiaoCount == 2 then
            desc = desc.."/2个鸟"
        elseif data.mNiaoCount == 4 then
            desc = desc.."/4个鸟"
        elseif data.mNiaoCount == 6 then
            desc = desc.."/6个鸟"
        else
        end
        if data.mKGNPFlag == 2 then
            desc = desc.."/开杠两张牌"
        elseif data.mKGNPFlag == 4 then
            desc = desc.."/开杠四张牌"
        elseif data.mKGNPFlag == 6 then
            desc = desc.."/开杠六张牌"
        else
        end
        if data.mMaOne == 1 then
            desc = desc.."/一鸟一分"
        elseif data.mMaOne == 2 then
            desc = desc.."/一鸟两分"
        end
        if data.bMQFlag == 1 then
            desc = desc.."/门清"
        end
        if data.mZXFlag == 1 then
            desc = desc.."/庄闲(算分)"
        end
        if data.bJJHFlag == 1 then
            desc = desc.."/假将胡"
        end
        if data.mPFFlag == 1 then
            desc = desc.."/漂分"
        end
        -- desc = desc.."\n"
        if data.bLLSFlag == 1 then
            desc = desc.."/六六顺"
        end
        if data.mZTLLSFlag == 1 then
            desc = desc.."/中途六六顺"
        end
        if data.bQYSFlag == 1 then
            desc = desc.."/缺一色"
        end
        if data.bWJHFlag == 1 then
            desc = desc.."/无将胡"
        end
        if data.bDSXFlag == 1 then
            desc = desc.."/大四喜"
        end
        if data.mZTSXlag == 1 then
            desc = desc.."/中途四喜"
        end
        if data.bBBGFlag == 1 then
            desc = desc.."/步步高"
        end
        if data.bSTFlag == 1 then
            desc = desc.."/三同"
        end
        if data.bYZHFlag == 1 then
            desc = desc.."/一枝花"
        end

        if data.bWuTong == 0 then
            desc = desc.."/去掉筒子"
        end
        
    elseif wKindID == 16 then    
        if data.bPlayerCount == 2 then
            desc = desc.."2人房"       
        elseif data.bPlayerCount == 3 then
            desc = desc.."3人房"
        else
            desc = desc.."4人房"
        end
        desc = desc.."\n"
        if data.bSuccessive == 0 then
            desc = desc.."中庄"
        elseif data.bSuccessive == 1 then 
            desc = desc.."无限连庄"
        end
        if data.bQiangHuPai == 1 then
            desc = desc.."/必胡"
        end
        if data.bLianZhuangSocre == 0 then
            desc = desc.."/中庄相加"
        elseif data.bLianZhuangSocre == 1 then 
            desc = desc.."/中庄乘二"
        end
        
    elseif wKindID == 60 then        
        if data.bPlayerCount == 3 then
            desc = desc.."3人房"
        elseif data.bPlayerCount == 2 then
            desc = desc.."双人竞技"
        elseif data.bPlayerCount == 4 then
            desc = desc.."4人坐省"
        end
        if data.bCanHuXi == 15 then
            desc = desc.."/15胡息起胡"
        elseif data.bCanHuXi == 18 then
            desc = desc.."/18胡息起胡"
        elseif data.bCanHuXi == 21 then
            desc = desc.."/21胡息起胡"
        end
        if data.bStartTun == 1 then
            desc = desc.."/倒一"
        elseif data.bStartTun == 3 then
            desc = desc.."/倒三"
        elseif data.bStartTun == 5 then
            desc = desc.."/倒五"
        elseif data.bStartTun == 8 then
            desc = desc.."/倒八"
        end
        if data.bTurn == 1 then
            desc = desc.."/轮庄"
        else
            desc = desc.."/抢庄"
        end 

    elseif wKindID == 67 then         
        if data.bPlayerCount == 2 then
            desc = desc.."双人竞技"
        elseif data.bPlayerCount == 3 then
            desc = desc.."3人"
        else
            desc = desc.."4人"
        end
        if data.bWuTong == 0 then
            desc = desc.."/没有筒子"
        end 
        if data.bMaType == 1 then
            desc = desc.."/一五九"
        elseif data.bMaType == 2 then
            desc = desc.."/窝窝鸟"
        elseif data.bMaType == 3 then
            desc = desc.."/一马全中"
        else
            desc = desc.."/摸几奖几"
        end
        if data.bMaCount == 2 then
            desc = desc.."/2个马"
        elseif data.bMaCount == 4 then
            desc = desc.."/4个马"
        elseif data.bMaCount == 6 then
            desc = desc.."/6个马"
        else

        end
        if data.bNiaoType == 1 then
            desc = desc.."/一马一分"
        elseif data.bNiaoType == 2 then
            desc = desc.."/一马两分"
        end
        if data.bQGHu == 1 then
            desc = desc.."/抢杠胡"
        else
            desc = desc.."/无抢杠胡"
        end
        if data.bQGHuJM == 1 then
            desc = desc.."/抢杠胡奖马"
        end
        if data.bHuangZhuangHG == 1 then
            desc = desc.."/黄庄荒杠"
        end
        if data.bJiePao == 1 then
            desc = desc.."/可接炮"
        end
        if data.bQingSH == 1 then
            desc = desc.."/两片"
        end  
        if data.bQingYiSe == 1 then
            desc = desc.."/清一色"
        end 
        if data.bQiXiaoDui == 1 then
            desc = desc.."/七对"
        end 
        if data.bPPHu == 1 then
            desc = desc.."/碰碰胡"
        end 
        if data.mJFCount == 100 then
            desc = desc.."/100封顶"
        elseif data.mJFCount == 200  then
            desc = desc.."/200封顶"
        elseif data.mJFCount == 300  then
            desc = desc.."/300封顶"
        elseif data.mJFCount == 0  then
            desc = desc.."/不封顶"
        end

    elseif wKindID == 69 then
      if data.bPaPo == 0 then
        desc = desc.."不爬坡"
      elseif data.bPaPo == 1 then
        desc = desc.."爬坡"
      elseif data.bPaPo == 2 then
        desc = desc.."持续爬坡"
      end

      if data.bStartTun == 1 then
         desc = desc.."/加一囤"
      end
      
      desc = desc..string.format("/%d胡起胡",data.bCanHuXi) 
    end 
    
    if tableConfig ~= nil and tableConfig.nTableType ~= nil then
        if tableConfig.nTableType >= TableType_GuildRoom then
        elseif tableConfig.nTableType == TableType_HelpRoom then
        elseif tableConfig.nTableType == TableType_ClubRoom and tableConfig.dwClubID ~= 0 then
            if wKindID == 69 then
              desc = string.format("(亲友圈[%d])\n",tableConfig.dwClubID)..desc
            else
              desc = string.format("(亲友圈[%d])",tableConfig.dwClubID)..desc
            end
        elseif tableConfig.nTableType == TableType_SportsRoom and tableConfig.dwClubID ~= 0 then
        else
        end
    end
    return desc    
end

return GameDesc