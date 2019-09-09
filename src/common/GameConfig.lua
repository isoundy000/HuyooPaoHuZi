local Bit = require("common.Bit")

local GameConfig = {}

--解析参数
function GameConfig:getParameter(wKindID,luaFunc)
    local data = {}
    local haveReadByte = 0
    if wKindID == 15 then
        data.bPlayerCount = luaFunc:readRecvByte()                  --参与游戏的人数 3+1模式为3    
        haveReadByte = 1    --已读长度，每次增加或者减少都要修改该值，Byte1个字节 WORD2个字节 DWORD4个字节

    elseif wKindID == 16 then    
        data.bPlayerCount = luaFunc:readRecvByte()                    --参与游戏的人数 3+1模式为3
        data.bSuccessive = luaFunc:readRecvByte()                     --连庄选项 0：二连、1：无限连庄
        data.bQiangHuPai = luaFunc:readRecvByte()                     --制胡牌 0：不强胡、1：强胡
        data.bLianZhuangSocre = luaFunc:readRecvByte()                --连庄计分 0：加一倍、1：翻倍*2  
        haveReadByte = 4    --已读长度，每次增加或者减少都要修改该值，Byte1个字节 WORD2个字节 DWORD4个字节
        
    elseif wKindID == 21 then
        data.bPlayerCountType = luaFunc:readRecvByte()              --用户人数模式 0：默认3人   1：4人玩法  2：3人参与另外一人省
        data.bPlayerCount = luaFunc:readRecvByte()                  --参与游戏的人数 3+1模式为3    
        haveReadByte = 2    --已读长度，每次增加或者减少都要修改该值，Byte1个字节 WORD2个字节 DWORD4个字节
        
    elseif wKindID == 22 then
        data.FanXing = {}
        data.FanXing.bType = luaFunc:readRecvByte()                        --翻省    0默认没有反省  1上省  2下省  3跟省
        data.FanXing.bCount = luaFunc:readRecvByte()                       --翻省的次数
        data.FanXing.bAddTun = luaFunc:readRecvByte()                      --省算法, 一省三囤  单省    
        data.bPlayerCountType = luaFunc:readRecvByte()              --用户人数模式 0：默认3人   1：4人玩法  2：3人参与另外一人省
        data.bPlayerCount = luaFunc:readRecvByte()                  --参与游戏的人数 3+1模式为3
        data.bLaiZiCount = luaFunc:readRecvByte()                   --癞子数量 0 ~ 4个
        data.bMaxLost = luaFunc:readRecvWORD()                      --最大输
        data.bYiWuShi = luaFunc:readRecvByte()                      --是否有一五十吃法
        data.bLiangPai = luaFunc:readRecvByte()                     --是否亮牌
        data.bCanHuXi = luaFunc:readRecvByte()                      --起胡数  0 3 6 10 15  
        data.bHuType = luaFunc:readRecvByte()                       --胡牌类型  0自摸翻倍  1接炮
        data.bFangPao = luaFunc:readRecvByte()                      --是否有放跑功能
        data.bSettlement = luaFunc:readRecvByte()                   --结算是否按三胡一囤，否则一胡一囤
        data.bStartTun = luaFunc:readRecvByte()                     --囤数起始算法  0起始胡息一囤  1起始胡息二囤 210胡息三囤<=15胡息每多1胡息+1囤    
        data.bSocreType = luaFunc:readRecvByte()                    --0低分*囤数总和*名堂番数总和  1低分*囤数总和*名堂番数乘积
        data.dwMingTang = luaFunc:readRecvDWORD()                   --包含的名堂有哪些  
        haveReadByte = 20    --已读长度，每次增加或者减少都要修改该值，Byte1个字节 WORD2个字节 DWORD4个字节
        
    elseif wKindID == 23 then
        data.FanXing = {}
        data.FanXing.bType = luaFunc:readRecvByte()                        --翻省    0默认没有反省  1上省  2下省  3跟省
        data.FanXing.bCount = luaFunc:readRecvByte()                       --翻省的次数
        data.FanXing.bAddTun = luaFunc:readRecvByte()                      --省算法, 一省三囤  单省    
        data.bPlayerCountType = luaFunc:readRecvByte()              --用户人数模式 0：默认3人   1：4人玩法  2：3人参与另外一人省
        data.bPlayerCount = luaFunc:readRecvByte()                  --参与游戏的人数 3+1模式为3
        data.bLaiZiCount = luaFunc:readRecvByte()                   --癞子数量 0 ~ 4个
        data.bMaxLost = luaFunc:readRecvWORD()                      --最大输
        data.bYiWuShi = luaFunc:readRecvByte()                      --是否有一五十吃法
        data.bLiangPai = luaFunc:readRecvByte()                     --是否亮牌
        data.bCanHuXi = luaFunc:readRecvByte()                      --起胡数  0 3 6 10 15  
        data.bHuType = luaFunc:readRecvByte()                       --胡牌类型  0自摸翻倍  1接炮
        data.bFangPao = luaFunc:readRecvByte()                      --是否有放跑功能
        data.bSettlement = luaFunc:readRecvByte()                   --结算是否按三胡一囤，否则一胡一囤
        data.bStartTun = luaFunc:readRecvByte()                     --囤数起始算法  0起始胡息一囤  1起始胡息二囤 210胡息三囤<=15胡息每多1胡息+1囤    
        data.bSocreType = luaFunc:readRecvByte()                    --0低分*囤数总和*名堂番数总和  1低分*囤数总和*名堂番数乘积
        data.dwMingTang = luaFunc:readRecvDWORD()                   --包含的名堂有哪些   
        haveReadByte = 20    --已读长度，每次增加或者减少都要修改该值，Byte1个字节 WORD2个字节 DWORD4个字节
        
    elseif wKindID == 24 then
        data.FanXing = {}
        data.FanXing.bType = luaFunc:readRecvByte()                        --翻省    0默认没有反省  1上省  2下省  3跟省
        data.FanXing.bCount = luaFunc:readRecvByte()                       --翻省的次数
        data.FanXing.bAddTun = luaFunc:readRecvByte()                      --省算法, 一省三囤  单省    
        data.bPlayerCountType = luaFunc:readRecvByte()              --用户人数模式 0：默认3人   1：4人玩法  2：3人参与另外一人省
        data.bPlayerCount = luaFunc:readRecvByte()                  --参与游戏的人数 3+1模式为3
        data.bLaiZiCount = luaFunc:readRecvByte()                   --癞子数量 0 ~ 4个
        data.bMaxLost = luaFunc:readRecvWORD()                      --最大输
        data.bYiWuShi = luaFunc:readRecvByte()                      --是否有一五十吃法
        data.bLiangPai = luaFunc:readRecvByte()                     --是否亮牌
        data.bCanHuXi = luaFunc:readRecvByte()                      --起胡数  0 3 6 10 15  
        data.bHuType = luaFunc:readRecvByte()                       --胡牌类型  0:自摸 1:能胡必胡 2:放炮必胡
        data.bFangPao = luaFunc:readRecvByte()                      --是否有放跑功能
        data.bSettlement = luaFunc:readRecvByte()                   --结算是否按三胡一囤，否则一胡一囤
        data.bStartTun = luaFunc:readRecvByte()                     --囤数起始算法  0起始胡息一囤  1起始胡息二囤 210胡息三囤<=15胡息每多1胡息+1囤    
        data.bSocreType = luaFunc:readRecvByte()                    --0低分*囤数总和*名堂番数总和  1低分*囤数总和*名堂番数乘积
        data.dwMingTang = luaFunc:readRecvDWORD()                   --包含的名堂有哪些      
        data.bPiaoHu = luaFunc:readRecvByte()
        data.bHongHu = luaFunc:readRecvByte()   
        data.bDelShowCardHu = luaFunc:readRecvByte()
        data.bDeathCard = luaFunc:readRecvByte()                    --亡牌
        data.bStartBanker = luaFunc:readRecvByte()                    --随机庄
        data.bStopCardGo = luaFunc:readRecvByte()                    --随机庄
        haveReadByte = 26    --已读长度，每次增加或者减少都要修改该值，Byte1个字节 WORD2个字节 DWORD4个字节
        
    elseif wKindID == 33 then
        data.FanXing = {}
        data.FanXing.bType = luaFunc:readRecvByte()                        --翻省    0默认没有反省  1上省  2下省  3跟省
        data.FanXing.bCount = luaFunc:readRecvByte()                       --翻省的次数
        data.FanXing.bAddTun = luaFunc:readRecvByte()                      --省算法, 一省三囤  单省    
        data.bPlayerCountType = luaFunc:readRecvByte()              --用户人数模式 0：默认3人   1：4人玩法  2：3人参与另外一人省
        data.bPlayerCount = luaFunc:readRecvByte()                  --参与游戏的人数 3+1模式为3
        data.bLaiZiCount = luaFunc:readRecvByte()                   --癞子数量 0 ~ 4个
        data.bMaxLost = luaFunc:readRecvWORD()                      --最大输
        data.bYiWuShi = luaFunc:readRecvByte()                      --是否有一五十吃法
        data.bLiangPai = luaFunc:readRecvByte()                     --是否亮牌
        data.bCanHuXi = luaFunc:readRecvByte()                      --起胡数  0 3 6 10 15  
        data.bHuType = luaFunc:readRecvByte()                       --胡牌类型  0自摸翻倍  1接炮
        data.bFangPao = luaFunc:readRecvByte()                      --是否有放跑功能
        data.bSettlement = luaFunc:readRecvByte()                   --结算是否按三胡一囤，否则一胡一囤
        data.bStartTun = luaFunc:readRecvByte()                     --囤数起始算法  0起始胡息一囤  1起始胡息二囤 210胡息三囤<=15胡息每多1胡息+1囤    
        data.bSocreType = luaFunc:readRecvByte()                    --0低分*囤数总和*名堂番数总和  1低分*囤数总和*名堂番数乘积
        data.dwMingTang = luaFunc:readRecvDWORD()                   --包含的名堂有哪些             
        data.bLimit = luaFunc:readRecvByte()                        --限制条件 
        haveReadByte = 21    --已读长度，每次增加或者减少都要修改该值，Byte1个字节 WORD2个字节 DWORD4个字节
        
    elseif wKindID == 27 then
        data.FanXing = {}
        data.FanXing.bType = luaFunc:readRecvByte()                        --翻省    0默认没有反省  1上省  2下省  3跟省
        data.FanXing.bCount = luaFunc:readRecvByte()                       --翻省的次数
        data.FanXing.bAddTun = luaFunc:readRecvByte()                      --省算法, 一省三囤  单省    
        data.bPlayerCountType = luaFunc:readRecvByte()              --用户人数模式 0：默认3人   1：4人玩法  2：3人参与另外一人省
        data.bPlayerCount = luaFunc:readRecvByte()                  --参与游戏的人数 3+1模式为3
        data.bLaiZiCount = luaFunc:readRecvByte()                   --癞子数量 0 ~ 4个
        data.bMaxLost = luaFunc:readRecvWORD()                      --最大输
        data.bYiWuShi = luaFunc:readRecvByte()                      --是否有一五十吃法
        data.bLiangPai = luaFunc:readRecvByte()                     --是否亮牌
        data.bCanHuXi = luaFunc:readRecvByte()                      --起胡数  0 3 6 10 15  
        data.bHuType = luaFunc:readRecvByte()                       --胡牌类型  0自摸翻倍  1接炮
        data.bFangPao = luaFunc:readRecvByte()                      --是否有放跑功能
        data.bSettlement = luaFunc:readRecvByte()                   --结算是否按三胡一囤，否则一胡一囤
        data.bStartTun = luaFunc:readRecvByte()                     --囤数起始算法  0起始胡息一囤  1起始胡息二囤 210胡息三囤<=15胡息每多1胡息+1囤    
        data.bSocreType = luaFunc:readRecvByte()                    --0低分*囤数总和*名堂番数总和  1低分*囤数总和*名堂番数乘积
        data.dwMingTang = luaFunc:readRecvDWORD()                   --包含的名堂有哪些             
        haveReadByte = 20    --已读长度，每次增加或者减少都要修改该值，Byte1个字节 WORD2个字节 DWORD4个字节
        
    elseif wKindID == 34 then
        data.FanXing = {}
        data.FanXing.bType = luaFunc:readRecvByte()                        --翻省    0默认没有反省  1上省  2下省  3跟省
        data.FanXing.bCount = luaFunc:readRecvByte()                       --翻省的次数
        data.FanXing.bAddTun = luaFunc:readRecvByte()                      --省算法, 一省三囤  单省    
        data.bPlayerCountType = luaFunc:readRecvByte()              --用户人数模式 0：默认3人   1：4人玩法  2：3人参与另外一人省
        data.bPlayerCount = luaFunc:readRecvByte()                  --参与游戏的人数 3+1模式为3
        data.bLaiZiCount = luaFunc:readRecvByte()                   --癞子数量 0 ~ 4个
        data.bMaxLost = luaFunc:readRecvWORD()                      --最大输
        data.bYiWuShi = luaFunc:readRecvByte()                      --是否有一五十吃法
        data.bLiangPai = luaFunc:readRecvByte()                     --是否亮牌
        data.bCanHuXi = luaFunc:readRecvByte()                      --起胡数  0 3 6 10 15  
        data.bHuType = luaFunc:readRecvByte()                       --胡牌类型  0自摸翻倍  1接炮
        data.bFangPao = luaFunc:readRecvByte()                      --是否有放跑功能
        data.bSettlement = luaFunc:readRecvByte()                   --结算是否按三胡一囤，否则一胡一囤
        data.bStartTun = luaFunc:readRecvByte()                     --囤数起始算法  0起始胡息一囤  1起始胡息二囤 210胡息三囤<=15胡息每多1胡息+1囤    
        data.bSocreType = luaFunc:readRecvByte()                    --0低分*囤数总和*名堂番数总和  1低分*囤数总和*名堂番数乘积
        data.dwMingTang = luaFunc:readRecvDWORD()                   --包含的名堂有哪些             
        data.bDouble = luaFunc:readRecvByte()                       --单双省
        haveReadByte = 21    --已读长度，每次增加或者减少都要修改该值，Byte1个字节 WORD2个字节 DWORD4个字节
        
    elseif wKindID == 35 then
        data.FanXing = {}
        data.FanXing.bType = luaFunc:readRecvByte()                        --翻省    0默认没有反省  1上省  2下省  3跟省
        data.FanXing.bCount = luaFunc:readRecvByte()                       --翻省的次数
        data.FanXing.bAddTun = luaFunc:readRecvByte()                      --省算法, 一省三囤  单省    
        data.bPlayerCountType = luaFunc:readRecvByte()              --用户人数模式 0：默认3人   1：4人玩法  2：3人参与另外一人省
        data.bPlayerCount = luaFunc:readRecvByte()                  --参与游戏的人数 3+1模式为3
        data.bLaiZiCount = luaFunc:readRecvByte()                   --癞子数量 0 ~ 4个
        data.bMaxLost = luaFunc:readRecvWORD()                      --最大输
        data.bYiWuShi = luaFunc:readRecvByte()                      --是否有一五十吃法
        data.bLiangPai = luaFunc:readRecvByte()                     --是否亮牌
        data.bCanHuXi = luaFunc:readRecvByte()                      --起胡数  0 3 6 10 15  
        data.bHuType = luaFunc:readRecvByte()                       --胡牌类型  0自摸翻倍  1接炮
        data.bFangPao = luaFunc:readRecvByte()                      --是否有放跑功能
        data.bSettlement = luaFunc:readRecvByte()                   --结算是否按三胡一囤，否则一胡一囤
        data.bStartTun = luaFunc:readRecvByte()                     --囤数起始算法  0起始胡息一囤  1起始胡息二囤 210胡息三囤<=15胡息每多1胡息+1囤    
        data.bSocreType = luaFunc:readRecvByte()                    --0低分*囤数总和*名堂番数总和  1低分*囤数总和*名堂番数乘积
        data.dwMingTang = luaFunc:readRecvDWORD()                   --包含的名堂有哪些             
        data.bLimit = luaFunc:readRecvByte()                        --限制条件
        haveReadByte = 21    --已读长度，每次增加或者减少都要修改该值，Byte1个字节 WORD2个字节 DWORD4个字节
        
    elseif wKindID == 16 then    
        data.bPlayerCount = luaFunc:readRecvByte()                    --参与游戏的人数 3+1模式为3
        data.bSuccessive = luaFunc:readRecvByte()                     --连庄选项 0：二连、1：无限连庄
        data.bQiangHuPai = luaFunc:readRecvByte()                     --制胡牌 0：不强胡、1：强胡
        data.bLianZhuangSocre = luaFunc:readRecvByte()                --连庄计分 0：加一倍、1：翻倍*2  
        haveReadByte = 4    --已读长度，每次增加或者减少都要修改该值，Byte1个字节 WORD2个字节 DWORD4个字节
         
    elseif wKindID == 20 or wKindID == 19  or wKindID == 18 or wKindID == 17  then       
        data.bPlayerCountType = luaFunc:readRecvByte()              --用户人数模式 0：默认3人   1：4人玩法  2：3人参与另外一人省
        data.bPlayerCount = luaFunc:readRecvByte()                  --参与游戏的人数 3+1模式为3     
        data.bTotalHuXi = luaFunc:readRecvByte() 
        data.bMaxLost = luaFunc:readRecvWORD()
        haveReadByte = 5    --已读长度，每次增加或者减少都要修改该值，Byte1个字节 WORD2个字节 DWORD4个字节
        
    elseif wKindID == 25 or wKindID == 26 then 
        data.bPlayerCount = luaFunc:readRecvByte()          --参与游戏的人数   
        data.bStartCard = luaFunc:readRecvByte()            --首局出牌要求        0无要求  其他的对应的其他的牌
        data.bBombSeparation = luaFunc:readRecvByte()       --炸弹是否可拆      0不可拆  1可拆
        data.bRed10 = luaFunc:readRecvByte()                --红桃十可扎鸟      0无      1有
        data.b4Add3 = luaFunc:readRecvByte()                --是否可4带3        0无      1有
        data.bShowCardCount = luaFunc:readRecvByte()        --是否显示牌数量    0无      1有
        data.bSpringMinCount = luaFunc:readRecvByte()       --春天的最小数量    默认最多  否则其他值
        data.bAbandon = luaFunc:readRecvByte()              --放跑包赔           0无       1有     
        data.bCheating = luaFunc:readRecvByte()         --防作弊           0无       1有     
        data.bFalseSpring = luaFunc:readRecvByte()         --假春天            0无      1有   
        haveReadByte = 10    --已读长度，每次增加或者减少都要修改该值，Byte1个字节 WORD2个字节 DWORD4个字节
        
    elseif wKindID == 36 then
        data.FanXing = {}
        data.FanXing.bType = luaFunc:readRecvByte()                        --翻省    0默认没有反省  1上省  2下省  3跟省
        data.FanXing.bCount = luaFunc:readRecvByte()                       --翻省的次数
        data.FanXing.bAddTun = luaFunc:readRecvByte()                      --省算法, 一省三囤  单省    
        data.bPlayerCountType = luaFunc:readRecvByte()              --用户人数模式 0：默认3人   1：4人玩法  2：3人参与另外一人省
        data.bPlayerCount = luaFunc:readRecvByte()                  --参与游戏的人数 3+1模式为3
        data.bLaiZiCount = luaFunc:readRecvByte()                   --癞子数量 0 ~ 4个
        data.bMaxLost = luaFunc:readRecvWORD()                      --最大输
        data.bYiWuShi = luaFunc:readRecvByte()                      --是否有一五十吃法
        data.bLiangPai = luaFunc:readRecvByte()                     --是否亮牌
        data.bCanHuXi = luaFunc:readRecvByte()                      --起胡数  0 3 6 10 15  
        data.bHuType = luaFunc:readRecvByte()                       --胡牌类型  0自摸翻倍  1接炮
        data.bFangPao = luaFunc:readRecvByte()                      --是否有放跑功能
        data.bSettlement = luaFunc:readRecvByte()                   --结算是否按三胡一囤，否则一胡一囤
        data.bStartTun = luaFunc:readRecvByte()                     --囤数起始算法  0起始胡息一囤  1起始胡息二囤 210胡息三囤<=15胡息每多1胡息+1囤    
        data.bSocreType = luaFunc:readRecvByte()                    --0低分*囤数总和*名堂番数总和  1低分*囤数总和*名堂番数乘积
        data.dwMingTang = luaFunc:readRecvDWORD()                   --包含的名堂有哪些             
        data.bLimit = luaFunc:readRecvByte()                        --限制条件
        haveReadByte = 21    --已读长度，每次增加或者减少都要修改该值，Byte1个字节 WORD2个字节 DWORD4个字节
        
    elseif wKindID == 37 then
        data.FanXing = {}
        data.FanXing.bType = luaFunc:readRecvByte()                        --翻省    0默认没有反省  1上省  2下省  3跟省
        data.FanXing.bCount = luaFunc:readRecvByte()                       --翻省的次数
        data.FanXing.bAddTun = luaFunc:readRecvByte()                      --省算法, 一省三囤  单省    
        data.bPlayerCountType = luaFunc:readRecvByte()              --用户人数模式 0：默认3人   1：4人玩法  2：3人参与另外一人省
        data.bPlayerCount = luaFunc:readRecvByte()                  --参与游戏的人数 3+1模式为3
        data.bLaiZiCount = luaFunc:readRecvByte()                   --癞子数量 0 ~ 4个
        data.bMaxLost = luaFunc:readRecvWORD()                      --最大输
        data.bYiWuShi = luaFunc:readRecvByte()                      --是否有一五十吃法
        data.bLiangPai = luaFunc:readRecvByte()                     --是否亮牌
        data.bCanHuXi = luaFunc:readRecvByte()                      --起胡数  0 3 6 10 15  
        data.bHuType = luaFunc:readRecvByte()                       --胡牌类型  0自摸翻倍  1接炮
        data.bFangPao = luaFunc:readRecvByte()                      --是否有放跑功能
        data.bSettlement = luaFunc:readRecvByte()                   --结算是否按三胡一囤，否则一胡一囤
        data.bStartTun = luaFunc:readRecvByte()                     --囤数起始算法  0起始胡息一囤  1起始胡息二囤 210胡息三囤<=15胡息每多1胡息+1囤    
        data.bSocreType = luaFunc:readRecvByte()                    --0低分*囤数总和*名堂番数总和  1低分*囤数总和*名堂番数乘积
        data.dwMingTang = luaFunc:readRecvDWORD()                   --包含的名堂有哪些             
        data.bLimit = luaFunc:readRecvByte()                        --限制条件
        haveReadByte = 21    --已读长度，每次增加或者减少都要修改该值，Byte1个字节 WORD2个字节 DWORD4个字节
        
    elseif wKindID == 31 then
        data.FanXing = {}
        data.FanXing.bType = luaFunc:readRecvByte()                        --翻省    0默认没有反省  1上省  2下省  3跟省
        data.FanXing.bCount = luaFunc:readRecvByte()                       --翻省的次数
        data.FanXing.bAddTun = luaFunc:readRecvByte()                      --省算法, 一省三囤  单省    
        data.bPlayerCountType = luaFunc:readRecvByte()              --用户人数模式 0：默认3人   1：4人玩法  2：3人参与另外一人省
        data.bPlayerCount = luaFunc:readRecvByte()                  --参与游戏的人数 3+1模式为3
        data.bLaiZiCount = luaFunc:readRecvByte()                   --癞子数量 0 ~ 4个
        data.bMaxLost = luaFunc:readRecvWORD()                      --最大输
        data.bYiWuShi = luaFunc:readRecvByte()                      --是否有一五十吃法
        data.bLiangPai = luaFunc:readRecvByte()                     --是否亮牌
        data.bCanHuXi = luaFunc:readRecvByte()                      --起胡数  0 3 6 10 15  
        data.bHuType = luaFunc:readRecvByte()                       --胡牌类型  0自摸翻倍  1接炮
        data.bFangPao = luaFunc:readRecvByte()                      --是否有放跑功能
        data.bSettlement = luaFunc:readRecvByte()                   --结算是否按三胡一囤，否则一胡一囤
        data.bStartTun = luaFunc:readRecvByte()                     --囤数起始算法  0起始胡息一囤  1起始胡息二囤 210胡息三囤<=15胡息每多1胡息+1囤    
        data.bSocreType = luaFunc:readRecvByte()                    --0低分*囤数总和*名堂番数总和  1低分*囤数总和*名堂番数乘积
        data.dwMingTang = luaFunc:readRecvDWORD()                   --包含的名堂有哪些             
        data.bLimit = luaFunc:readRecvByte()                        --限制条件
        data.bDeathCard = luaFunc:readRecvByte()
        haveReadByte = 22    --已读长度，每次增加或者减少都要修改该值，Byte1个字节 WORD2个字节 DWORD4个字节
        
    elseif wKindID == 32 then
        data.FanXing = {}
        data.FanXing.bType = luaFunc:readRecvByte()                        --翻省    0默认没有反省  1上省  2下省  3跟省
        data.FanXing.bCount = luaFunc:readRecvByte()                       --翻省的次数
        data.FanXing.bAddTun = luaFunc:readRecvByte()                      --省算法, 一省三囤  单省    
        data.bPlayerCountType = luaFunc:readRecvByte()              --用户人数模式 0：默认3人   1：4人玩法  2：3人参与另外一人省
        data.bPlayerCount = luaFunc:readRecvByte()                  --参与游戏的人数 3+1模式为3
        data.bLaiZiCount = luaFunc:readRecvByte()                   --癞子数量 0 ~ 4个
        data.bMaxLost = luaFunc:readRecvWORD()                      --最大输
        data.bYiWuShi = luaFunc:readRecvByte()                      --是否有一五十吃法
        data.bLiangPai = luaFunc:readRecvByte()                     --是否亮牌
        data.bCanHuXi = luaFunc:readRecvByte()                      --起胡数  0 3 6 10 15  
        data.bHuType = luaFunc:readRecvByte()                       --胡牌类型  0自摸翻倍  1接炮
        data.bFangPao = luaFunc:readRecvByte()                      --是否有放跑功能
        data.bSettlement = luaFunc:readRecvByte()                   --结算是否按三胡一囤，否则一胡一囤
        data.bStartTun = luaFunc:readRecvByte()                     --囤数起始算法  0起始胡息一囤  1起始胡息二囤 210胡息三囤<=15胡息每多1胡息+1囤    
        data.bSocreType = luaFunc:readRecvByte()                    --0低分*囤数总和*名堂番数总和  1低分*囤数总和*名堂番数乘积
        data.dwMingTang = luaFunc:readRecvDWORD()                   --包含的名堂有哪些             
        data.bLimit = luaFunc:readRecvByte()                        --限制条件
        haveReadByte = 21    --已读长度，每次增加或者减少都要修改该值，Byte1个字节 WORD2个字节 DWORD4个字节
		
    elseif wKindID == 44 then
        data.FanXing = {}
        data.FanXing.bType = luaFunc:readRecvByte()                        --翻省    0默认没有反省  1上省  2下省  3跟省
        data.FanXing.bCount = luaFunc:readRecvByte()                       --翻省的次数
        data.FanXing.bAddTun = luaFunc:readRecvByte()                      --省算法, 一省三囤  单省    
        data.bPlayerCountType = luaFunc:readRecvByte()              --用户人数模式 0：默认3人   1：4人玩法  2：3人参与另外一人省
        data.bPlayerCount = luaFunc:readRecvByte()                  --参与游戏的人数 3+1模式为3
        data.bLaiZiCount = luaFunc:readRecvByte()                   --癞子数量 0 ~ 4个
        data.bMaxLost = luaFunc:readRecvWORD()                      --最大输
        data.bYiWuShi = luaFunc:readRecvByte()                      --是否有一五十吃法
        data.bLiangPai = luaFunc:readRecvByte()                     --是否亮牌
        data.bCanHuXi = luaFunc:readRecvByte()                      --起胡数  0 3 6 10 15  
        data.bHuType = luaFunc:readRecvByte()                       --胡牌类型  0自摸翻倍  1接炮
        data.bFangPao = luaFunc:readRecvByte()                      --是否有放跑功能
        data.bSettlement = luaFunc:readRecvByte()                   --结算是否按三胡一囤，否则一胡一囤
        data.bStartTun = luaFunc:readRecvByte()                     --囤数起始算法  0起始胡息一囤  1起始胡息二囤 210胡息三囤<=15胡息每多1胡息+1囤    
        data.bSocreType = luaFunc:readRecvByte()                    --0低分*囤数总和*名堂番数总和  1低分*囤数总和*名堂番数乘积
        data.dwMingTang = luaFunc:readRecvDWORD()                   --包含的名堂有哪些             
        data.bTurn = luaFunc:readRecvByte()
        data.bPaoTips = luaFunc:readRecvByte()
        data.bStartBanker = luaFunc:readRecvByte()
        data.bDeathCard = luaFunc:readRecvByte()
        haveReadByte = 24    --已读长度，每次增加或者减少都要修改该值，Byte1个字节 WORD2个字节 DWORD4个字节
        
    elseif wKindID == 50 then
        data.bPlayerCount = luaFunc:readRecvByte()
        data.bNiaoAdd = luaFunc:readRecvByte()
        data.mNiaoCount = luaFunc:readRecvByte()
        data.bLLSFlag = luaFunc:readRecvByte()
        data.bQYSFlag = luaFunc:readRecvByte()
        data.bWJHFlag = luaFunc:readRecvByte()
        data.bDSXFlag = luaFunc:readRecvByte()
        data.bBBGFlag = luaFunc:readRecvByte()
        data.bSTFlag = luaFunc:readRecvByte()
        data.bYZHFlag = luaFunc:readRecvByte()
        data.bMQFlag = luaFunc:readRecvByte()
        data.mZXFlag = luaFunc:readRecvByte()
        data.mPFFlag = luaFunc:readRecvByte()
        data.mZTSXlag = luaFunc:readRecvByte()
        data.bJJHFlag = luaFunc:readRecvByte()
        data.bWuTong = luaFunc:readRecvByte()
        data.mMaOne = luaFunc:readRecvByte()
        haveReadByte = 17    --已读长度，每次增加或者减少都要修改该值，Byte1个字节 WORD2个字节 DWORD4个字节
        
    elseif wKindID == 70 then
        data.bPlayerCount = luaFunc:readRecvByte()
        data.bNiaoAdd = luaFunc:readRecvByte()
        data.mNiaoCount = luaFunc:readRecvByte()
        data.bLLSFlag = luaFunc:readRecvByte()
        data.bQYSFlag = luaFunc:readRecvByte()
        data.bWJHFlag = luaFunc:readRecvByte()
        data.bDSXFlag = luaFunc:readRecvByte()
        data.bBBGFlag = luaFunc:readRecvByte()
        data.bSTFlag = luaFunc:readRecvByte()
        data.bYZHFlag = luaFunc:readRecvByte()
        data.bMQFlag = luaFunc:readRecvByte()
        data.mZXFlag = luaFunc:readRecvByte()
        data.mPFFlag = luaFunc:readRecvByte()
        data.mZTSXlag = luaFunc:readRecvByte()
        data.bJJHFlag = luaFunc:readRecvByte()
        data.bWuTong = luaFunc:readRecvByte()
        data.mMaOne  = luaFunc:readRecvByte()
        data.mZTLLSFlag  = luaFunc:readRecvByte()       
        data.mKGNPFlag  = luaFunc:readRecvByte()     
        haveReadByte = 19    --已读长度，每次增加或者减少都要修改该值，Byte1个字节 WORD2个字节 DWORD4个字节
           
    elseif wKindID == 51 or wKindID == 55 or wKindID == 56 or wKindID == 57 or wKindID == 58 or wKindID == 59 then
        data.bPlayerCount = luaFunc:readRecvByte()
        data.bBankerType = luaFunc:readRecvByte()
        data.bMultiple = luaFunc:readRecvByte()
        data.bBettingType = luaFunc:readRecvByte() 
        data.bSettlementType = luaFunc:readRecvByte() 
        data.bPush = luaFunc:readRecvByte()
        data.bNoFlower = luaFunc:readRecvByte()
        data.bCanPlayingJoin = luaFunc:readRecvByte()
        data.bNiuType_Flush = luaFunc:readRecvByte()
        data.bNiuType_Gourd = luaFunc:readRecvByte()
        data.bNiuType_SameColor = luaFunc:readRecvByte()
        data.bNiuType_Straight = luaFunc:readRecvByte()
        haveReadByte = 12    --已读长度，每次增加或者减少都要修改该值，Byte1个字节 WORD2个字节 DWORD4个字节
        
    elseif wKindID == 38 then
        data.FanXing = {}
        data.FanXing.bType = luaFunc:readRecvByte()                        --翻省    0默认没有反省  1上省  2下省  3跟省
        data.FanXing.bCount = luaFunc:readRecvByte()                       --翻省的次数
        data.FanXing.bAddTun = luaFunc:readRecvByte()                      --省算法, 一省三囤  单省    
        data.bPlayerCountType = luaFunc:readRecvByte()              --用户人数模式 0：默认3人   1：4人玩法  2：3人参与另外一人省
        data.bPlayerCount = luaFunc:readRecvByte()                  --参与游戏的人数 3+1模式为3
        data.bLaiZiCount = luaFunc:readRecvByte()                   --癞子数量 0 ~ 4个
        data.bMaxLost = luaFunc:readRecvWORD()                      --最大输
        data.bYiWuShi = luaFunc:readRecvByte()                      --是否有一五十吃法
        data.bLiangPai = luaFunc:readRecvByte()                     --是否亮牌
        data.bCanHuXi = luaFunc:readRecvByte()                      --起胡数  0 3 6 10 15  
        data.bHuType = luaFunc:readRecvByte()                       --胡牌类型  0:自摸 1:能胡必胡 2:放炮必胡
        data.bFangPao = luaFunc:readRecvByte()                      --是否有放跑功能
        data.bSettlement = luaFunc:readRecvByte()                   --结算是否按三胡一囤，否则一胡一囤
        data.bStartTun = luaFunc:readRecvByte()                     --囤数起始算法  0起始胡息一囤  1起始胡息二囤 210胡息三囤<=15胡息每多1胡息+1囤    
        data.bSocreType = luaFunc:readRecvByte()                    --0低分*囤数总和*名堂番数总和  1低分*囤数总和*名堂番数乘积
        data.dwMingTang = luaFunc:readRecvDWORD() 
        data.bFangPaoPay = luaFunc:readRecvByte()                   --放炮赔钱方式 0通赔  放炮赔两家钱
        data.bStartBanker = luaFunc:readRecvByte()                    --随机庄
        haveReadByte = 22    --已读长度，每次增加或者减少都要修改该值，Byte1个字节 WORD2个字节 DWORD4个字节
        
    elseif wKindID == 39 then
        data.FanXing = {}
        data.FanXing.bType = luaFunc:readRecvByte()                        --翻省    0默认没有反省  1上省  2下省  3跟省
        data.FanXing.bCount = luaFunc:readRecvByte()                       --翻省的次数
        data.FanXing.bAddTun = luaFunc:readRecvByte()                      --省算法, 一省三囤  单省    
        data.bPlayerCountType = luaFunc:readRecvByte()              --用户人数模式 0：默认3人   1：4人玩法  2：3人参与另外一人省
        data.bPlayerCount = luaFunc:readRecvByte()                  --参与游戏的人数 3+1模式为3
        data.bLaiZiCount = luaFunc:readRecvByte()                   --癞子数量 0 ~ 4个
        data.bMaxLost = luaFunc:readRecvWORD()                      --最大输
        data.bYiWuShi = luaFunc:readRecvByte()                      --是否有一五十吃法
        data.bLiangPai = luaFunc:readRecvByte()                     --是否亮牌
        data.bCanHuXi = luaFunc:readRecvByte()                      --起胡数  0 3 6 10 15  
        data.bHuType = luaFunc:readRecvByte()                       --胡牌类型  0自摸翻倍  1接炮
        data.bFangPao = luaFunc:readRecvByte()                      --是否有放跑功能
        data.bSettlement = luaFunc:readRecvByte()                   --结算是否按三胡一囤，否则一胡一囤
        data.bStartTun = luaFunc:readRecvByte()                     --囤数起始算法  0起始胡息一囤  1起始胡息二囤 210胡息三囤<=15胡息每多1胡息+1囤    
        data.bSocreType = luaFunc:readRecvByte()                    --0低分*囤数总和*名堂番数总和  1低分*囤数总和*名堂番数乘积
        data.dwMingTang = luaFunc:readRecvDWORD() 
        data.bStartBanker = luaFunc:readRecvByte()                    --随机庄
        data.bCanSiShou = luaFunc:readRecvByte()                    --能否弃牌
        data.bCanJuShouZuoSheng = luaFunc:readRecvByte()            --举手
        haveReadByte = 23    --已读长度，每次增加或者减少都要修改该值，Byte1个字节 WORD2个字节 DWORD4个字节

    elseif wKindID == 40 then 
        data.FanXing = {}
        data.FanXing.bType = luaFunc:readRecvByte()                        --翻省    0默认没有反省  1上省  2下省  3跟省
        data.FanXing.bCount = luaFunc:readRecvByte()                       --翻省的次数
        data.FanXing.bAddTun = luaFunc:readRecvByte()                      --省算法, 一省三囤  单省    
        data.bPlayerCountType = luaFunc:readRecvByte()              --用户人数模式 0：默认3人   1：4人玩法  2：3人参与另外一人省
        data.bPlayerCount = luaFunc:readRecvByte()                  --参与游戏的人数 3+1模式为3
        data.bLaiZiCount = luaFunc:readRecvByte()                   --癞子数量 0 ~ 4个
        data.bMaxLost = luaFunc:readRecvWORD()                      --最大输
        data.bYiWuShi = luaFunc:readRecvByte()                      --是否有一五十吃法
        data.bLiangPai = luaFunc:readRecvByte()                     --是否亮牌
        data.bCanHuXi = luaFunc:readRecvByte()                      --起胡数  0 3 6 10 15  
        data.bHuType = luaFunc:readRecvByte()                       --胡牌类型   0:自摸 1:能胡必胡 2:放炮必胡
        data.bFangPao = luaFunc:readRecvByte()                      --是否有放跑功能
        data.bSettlement = luaFunc:readRecvByte()                   --结算是否按三胡一囤，否则一胡一囤
        data.bStartTun = luaFunc:readRecvByte()                     --囤数起始算法  0起始胡息一囤  1起始胡息二囤 210胡息三囤<=15胡息每多1胡息+1囤    
        data.bSocreType = luaFunc:readRecvByte()                    --0低分*囤数总和*名堂番数总和  1低分*囤数总和*名堂番数乘积
        data.dwMingTang = luaFunc:readRecvDWORD() 
        data.bCardCount21 = luaFunc:readRecvByte()  
        data.bMinLostCell = luaFunc:readRecvByte()                 --//最小分 加番倍
        data.bMinLost = luaFunc:readRecvByte()  				    --//最小分
        data.bDeathCard = luaFunc:readRecvByte()  
        data.bStartBanker = luaFunc:readRecvByte()                    --随机庄
        data.bDelShowCardHu = luaFunc:readRecvByte()                    --随机庄
        data.bPiaoHu = luaFunc:readRecvByte()                    --飘胡
        data.bStopCardGo = luaFunc:readRecvByte()                    --冲招

        haveReadByte = 28    --已读长度，每次增加或者减少都要修改该值，Byte1个字节 WORD2个字节 DWORD4个字节
        
    elseif wKindID == 42 then
        data.numpep=luaFunc:readRecvByte() --    -- 代表4人玩 （ 写死）
        data.bPlayerCount = data.numpep
        data.mailiao=luaFunc:readRecvWORD()--    --买鸟数
        data.fanbei=luaFunc:readRecvByte() --    --1、2、4 翻倍底分、
        data.jiabei=luaFunc:readRecvByte() --    --庄家输赢做加减一倍底分、0无、1有
        data.zimo=luaFunc:readRecvByte()   --    --只准自摸胡牌  1.有  0.无            
        data.piaohua=luaFunc:readRecvByte()--    --1.有飘花、0.无飘花
        haveReadByte = 7    --已读长度，每次增加或者减少都要修改该值，Byte1个字节 WORD2个字节 DWORD4个字节
        
    elseif wKindID == 43 then
        data.bPlayerCount = luaFunc:readRecvByte()                  --参与游戏的人数 3+1模式为3
        data.bCanHuXi = luaFunc:readRecvByte()                      --起胡数  0 3 6 10 15  
        data.bChongFen = luaFunc:readRecvByte()
        data.bFanBei = luaFunc:readRecvByte()
        haveReadByte = 4    --已读长度，每次增加或者减少都要修改该值，Byte1个字节 WORD2个字节 DWORD4个字节
        
    elseif wKindID == 68 then
        data.bPlayerCount = luaFunc:readRecvByte()
        data.bMaType = luaFunc:readRecvByte()
        data.bMaCount = luaFunc:readRecvByte()
        data.bQGHu = luaFunc:readRecvByte()
        data.bQGHuJM = luaFunc:readRecvByte()
        data.bHuangZhuangHG = luaFunc:readRecvByte()
        data.bQingSH = luaFunc:readRecvByte()
        data.bJiePao = luaFunc:readRecvByte()
        data.bNiaoType = luaFunc:readRecvByte()             --1.一鸟一分、2.一鸟两分
        data.bQiDui = luaFunc:readRecvByte()
        data.bWuTong = luaFunc:readRecvByte()
        haveReadByte = 11    --已读长度，每次增加或者减少都要修改该值，Byte1个字节 WORD2个字节 DWORD4个字节
        
    elseif wKindID == 46 then
        data.bPlayerCount = luaFunc:readRecvByte()
        data.bMaType = luaFunc:readRecvByte()
        data.bMaCount = luaFunc:readRecvByte()
        data.bQGHu = luaFunc:readRecvByte()
        data.bQGHuJM = luaFunc:readRecvByte()
        data.bHuangZhuangHG = luaFunc:readRecvByte()
        data.bQingSH = luaFunc:readRecvByte()
        data.bJiePao = luaFunc:readRecvByte()
        data.bQiDui = luaFunc:readRecvByte()
        data.bWuTong = luaFunc:readRecvByte()
        haveReadByte = 10    --已读长度，每次增加或者减少都要修改该值，Byte1个字节 WORD2个字节 DWORD4个字节
        
    elseif wKindID == 61 then
        data.bPlayerCount = luaFunc:readRecvByte()
        data.bMaType = luaFunc:readRecvByte()
        data.bMaCount = luaFunc:readRecvByte()
        data.bQGHu = luaFunc:readRecvByte()
        data.bQGHuJM = luaFunc:readRecvByte()
        data.bHuangZhuangHG = luaFunc:readRecvByte()
        data.bQingSH = luaFunc:readRecvByte()
        data.bJiePao = luaFunc:readRecvByte()
        haveReadByte = 8    --已读长度，每次增加或者减少都要修改该值，Byte1个字节 WORD2个字节 DWORD4个字节
        
    elseif wKindID == 47 then
        data.FanXing = {}
        data.FanXing.bType = luaFunc:readRecvByte()                        --翻省    0默认没有反省  1上省  2下省  3跟省
        data.FanXing.bCount = luaFunc:readRecvByte()                       --翻省的次数
        data.FanXing.bAddTun = luaFunc:readRecvByte()                      --省算法, 一省三囤  单省    
        data.bPlayerCountType = luaFunc:readRecvByte()              --用户人数模式 0：默认3人   1：4人玩法  2：3人参与另外一人省
        data.bPlayerCount = luaFunc:readRecvByte()                  --参与游戏的人数 3+1模式为3
        data.bLaiZiCount = luaFunc:readRecvByte()                   --癞子数量 0 ~ 4个
        data.bMaxLost = luaFunc:readRecvWORD()                      --最大输
        data.bYiWuShi = luaFunc:readRecvByte()                      --是否有一五十吃法
        data.bLiangPai = luaFunc:readRecvByte()                     --是否亮牌
        data.bCanHuXi = luaFunc:readRecvByte()                      --起胡数  0 3 6 10 15  
        data.bHuType = luaFunc:readRecvByte()                       --胡牌类型  0自摸翻倍  1接炮
        data.bFangPao = luaFunc:readRecvByte()                      --是否有放跑功能
        data.bSettlement = luaFunc:readRecvByte()                   --结算是否按三胡一囤，否则一胡一囤
        data.bStartTun = luaFunc:readRecvByte()                     --囤数起始算法  0起始胡息一囤  1起始胡息二囤 210胡息三囤<=15胡息每多1胡息+1囤    
        data.bSocreType = luaFunc:readRecvByte()                    --0低分*囤数总和*名堂番数总和  1低分*囤数总和*名堂番数乘积
        data.dwMingTang = luaFunc:readRecvDWORD()                   --包含的名堂有哪些             
        data.bTurn = luaFunc:readRecvByte()
        data.bDeathCard =luaFunc:readRecvByte()                     --亡牌
        data.bStartBanker = luaFunc:readRecvByte()                    --随机庄
        haveReadByte = 23    --已读长度，每次增加或者减少都要修改该值，Byte1个字节 WORD2个字节 DWORD4个字节
        
    elseif wKindID == 48 then 
        data.FanXing = {}
        data.FanXing.bType = luaFunc:readRecvByte()                 --翻省    0默认没有反省  1上省  2下省  3跟省
        data.FanXing.bCount = luaFunc:readRecvByte()                --翻省的次数
        data.FanXing.bAddTun = luaFunc:readRecvByte()               --省算法, 一省三囤  单省    
        data.bPlayerCountType = luaFunc:readRecvByte()              --用户人数模式 0：默认3人   1：4人玩法  2：3人参与另外一人省(无用)
        data.bPlayerCount = luaFunc:readRecvByte()                  --参与游戏的人数 3+1模式为3
        data.bLaiZiCount = luaFunc:readRecvByte()                   --癞子数量 0 ~ 4个
        data.bMaxLost = luaFunc:readRecvWORD()                      --最大输
        data.bYiWuShi = luaFunc:readRecvByte()                      --是否有一五十吃法
        data.bLiangPai = luaFunc:readRecvByte()                     --是否亮牌
        data.bCanHuXi = luaFunc:readRecvByte()                      --起胡数  0 3 6 10 15  
        data.bHuType = luaFunc:readRecvByte()                       --胡牌类型  0自摸翻倍  1接炮
        data.bFangPao = luaFunc:readRecvByte()                      --是否有放跑功能
        data.bSettlement = luaFunc:readRecvByte()                   --结算是否按三胡一囤，否则一胡一囤
        data.bStartTun = luaFunc:readRecvByte()                     --囤数起始算法  0起始胡息一囤  1起始胡息二囤 210胡息三囤<=15胡息每多1胡息+1囤    
        data.bSocreType = luaFunc:readRecvByte()                    --0低分*囤数总和*名堂番数总和  1低分*囤数总和*名堂番数乘积
        data.dwMingTang = luaFunc:readRecvDWORD()                   --包含的名堂有哪些             
        data.bTurn = luaFunc:readRecvByte()
        data.bPaoTips = luaFunc:readRecvByte()
        data.bStartBanker = luaFunc:readRecvByte()
        data.bSiQiHong = luaFunc:readRecvByte()
        data.bDelShuaHou = luaFunc:readRecvByte()
        data.bHuangFanAddUp = luaFunc:readRecvByte()
        data.bTingHuAll = luaFunc:readRecvByte()
        data.bDeathCard = luaFunc:readRecvByte()                    --0 不抽低  1 抽牌20张 
        haveReadByte = 28    --已读长度，每次增加或者减少都要修改该值，Byte1个字节 WORD2个字节 DWORD4个字节
        
    elseif wKindID == 49 then 
        data.FanXing = {}
        data.FanXing.bType = luaFunc:readRecvByte()                        --翻省    0默认没有反省  1上省  2下省  3跟省
        data.FanXing.bCount = luaFunc:readRecvByte()                       --翻省的次数
        data.FanXing.bAddTun = luaFunc:readRecvByte()                      --省算法, 一省三囤  单省    
        data.bPlayerCountType = luaFunc:readRecvByte()              --用户人数模式 0：默认3人   1：4人玩法  2：3人参与另外一人省
        data.bPlayerCount = luaFunc:readRecvByte()                  --参与游戏的人数 3+1模式为3
        data.bLaiZiCount = luaFunc:readRecvByte()                   --癞子数量 0 ~ 4个
        data.bMaxLost = luaFunc:readRecvWORD()                      --最大输
        data.bYiWuShi = luaFunc:readRecvByte()                      --是否有一五十吃法
        data.bLiangPai = luaFunc:readRecvByte()                     --是否亮牌
        data.bCanHuXi = luaFunc:readRecvByte()                      --起胡数  0 3 6 10 15  
        data.bHuType = luaFunc:readRecvByte()                       --胡牌类型  0自摸翻倍  1接炮
        data.bFangPao = luaFunc:readRecvByte()                      --是否有放跑功能
        data.bSettlement = luaFunc:readRecvByte()                   --结算是否按三胡一囤，否则一胡一囤
        data.bStartTun = luaFunc:readRecvByte()                     --囤数起始算法  0起始胡息一囤  1起始胡息二囤 210胡息三囤<=15胡息每多1胡息+1囤    
        data.bSocreType = luaFunc:readRecvByte()                    --0低分*囤数总和*名堂番数总和  1低分*囤数总和*名堂番数乘积
        data.dwMingTang = luaFunc:readRecvDWORD()                   --包含的名堂有哪些             
        data.bTurn = luaFunc:readRecvByte()
        data.bDeathCard =luaFunc:readRecvByte()                     --亡牌
        data.bStartBanker = luaFunc:readRecvByte()                    --随机庄
        data.bHuangFanAddUp = luaFunc:readRecvByte()                    --黄番
        data.STWK = luaFunc:readRecvByte()                    --三五
        haveReadByte = 25    --已读长度，每次增加或者减少都要修改该值，Byte1个字节 WORD2个字节 DWORD4个字节
        
    elseif wKindID == 52 then
        data.bPlayerCount = luaFunc:readRecvByte()--参与游戏的人数           
        data.bQGHu = luaFunc:readRecvByte()--是否抢杠胡  0.不抢杠胡 1.抢杠胡
        data.bHuangZhuangHG = luaFunc:readRecvByte()--是否黄庄黄杠  0.不 1.是
        data.bJiePao = luaFunc:readRecvByte()--是否接炮   0.不接炮 1.接炮
        data.bHuQD = luaFunc:readRecvByte()--可胡七对  0.不  1.是
        data.bMaCount = luaFunc:readRecvByte()--马数 2、4、6 0 
        haveReadByte = 6    --已读长度，每次增加或者减少都要修改该值，Byte1个字节 WORD2个字节 DWORD4个字节
        
    elseif wKindID == 53 then
        data.bPlayerCount = luaFunc:readRecvByte()
        data.bBankerType = luaFunc:readRecvByte()
        data.bMultiple = luaFunc:readRecvByte()
        data.bBettingType = luaFunc:readRecvByte() 
        data.bPush = luaFunc:readRecvByte()
        data.bCanPlayingJoin = luaFunc:readRecvByte()
        data.bExtreme = luaFunc:readRecvByte()
        haveReadByte = 7    --已读长度，每次增加或者减少都要修改该值，Byte1个字节 WORD2个字节 DWORD4个字节
        
    elseif wKindID == 54 then   
        data.bPlayerCount = luaFunc:readRecvByte()  --参与游戏的人数
        data.bHuType = luaFunc:readRecvByte()       --胡牌类型--0.自摸胡<只能自摸胡牌> 1.点炮胡<可自摸、可点炮>
        data.bDHPlayFlag = luaFunc:readRecvByte()   --是否带混玩法-- 0.不带混 1.带混
        data.bDFFlag = luaFunc:readRecvByte()       --是否带风  0.不带风  1.带风
        data.bDXPFlag = luaFunc:readRecvByte()      --是否带下跑 0.不带下跑 1.带下跑<飘分>
        data.bBTHu = luaFunc:readRecvByte()         --是否报听胡  0.不报听胡 1.报听胡
        data.bQYMFlag = luaFunc:readRecvByte()      --是否缺一门 0.不需要缺一门 1.缺一门
        data.bQDJFFlag = luaFunc:readRecvByte()     --七对加分 0. 七对翻倍 1.
        data.bLLFlag = luaFunc:readRecvByte()       --是否连六  0.不连六 1.连六 
        data.bQYSFlag = luaFunc:readRecvByte()      --是否清一色 0.不清一色 1.清一色
        data.bZJJD = luaFunc:readRecvByte()         --是否庄家加底 0.不加 1.加
        data.bGSKHJB = luaFunc:readRecvByte()       --杠上花加倍 0.不杠上开花加倍 1.杠上开花加倍
        data.bQDFlag = luaFunc:readRecvByte()       --是否七对   0/1.
        haveReadByte = 13    --已读长度，每次增加或者减少都要修改该值，Byte1个字节 WORD2个字节 DWORD4个字节
        
    elseif wKindID == 60 then 
        data.FanXing = {}
        data.FanXing.bType = luaFunc:readRecvByte()                        --翻省    0默认没有反省  1上省  2下省  3跟省
        data.FanXing.bCount = luaFunc:readRecvByte()                       --翻省的次数
        data.FanXing.bAddTun = luaFunc:readRecvByte()                      --省算法, 一省三囤  单省    
        data.bPlayerCountType = luaFunc:readRecvByte()              --用户人数模式 0：默认3人   1：4人玩法  2：3人参与另外一人省
        data.bPlayerCount = luaFunc:readRecvByte()                  --参与游戏的人数 3+1模式为3
        data.bLaiZiCount = luaFunc:readRecvByte()                   --癞子数量 0 ~ 4个
        data.bMaxLost = luaFunc:readRecvWORD()                      --最大输
        data.bYiWuShi = luaFunc:readRecvByte()                      --是否有一五十吃法
        data.bLiangPai = luaFunc:readRecvByte()                     --是否亮牌
        data.bCanHuXi = luaFunc:readRecvByte()                      --起胡数  0 3 6 10 15  
        data.bHuType = luaFunc:readRecvByte()                       --胡牌类型  0自摸翻倍  1接炮
        data.bFangPao = luaFunc:readRecvByte()                      --是否有放跑功能
        data.bSettlement = luaFunc:readRecvByte()                   --结算是否按三胡一囤，否则一胡一囤
        data.bStartTun = luaFunc:readRecvByte()                     --囤数起始算法  0起始胡息一囤  1起始胡息二囤 210胡息三囤<=15胡息每多1胡息+1囤    
        data.bSocreType = luaFunc:readRecvByte()                    --0低分*囤数总和*名堂番数总和  1低分*囤数总和*名堂番数乘积
        data.dwMingTang = luaFunc:readRecvDWORD()                   --包含的名堂有哪些             
        data.bTurn = luaFunc:readRecvByte()
        haveReadByte = 21    --已读长度，每次增加或者减少都要修改该值，Byte1个字节 WORD2个字节 DWORD4个字节
        
    elseif wKindID == 63 then
        data.bPlayerCount = luaFunc:readRecvByte()
        data.bMaType = luaFunc:readRecvByte()
        data.bMaCount = luaFunc:readRecvByte()
        data.bQGHu = luaFunc:readRecvByte()
        data.bQGHuJM = luaFunc:readRecvByte()
        data.bHuangZhuangHG = luaFunc:readRecvByte()
        data.bQingSH = luaFunc:readRecvByte()
        data.bJiePao = luaFunc:readRecvByte()
        data.bNiaoType = luaFunc:readRecvByte()             --1.一鸟一分、2.一鸟两分
        haveReadByte = 9    --已读长度，每次增加或者减少都要修改该值，Byte1个字节 WORD2个字节 DWORD4个字节
        
    elseif wKindID == 65 then
        data.bPlayerCount = luaFunc:readRecvByte()
        data.bMaiPiaoCount = luaFunc:readRecvByte()
        data.bDiCount = luaFunc:readRecvByte()
        data.bHuangZhuangHG = luaFunc:readRecvByte()
        haveReadByte = 4    --已读长度，每次增加或者减少都要修改该值，Byte1个字节 WORD2个字节 DWORD4个字节
        
    elseif wKindID == 67 then
        data.bPlayerCount = luaFunc:readRecvByte()
        data.bMaType = luaFunc:readRecvByte()
        data.bMaCount = luaFunc:readRecvByte()
        data.bQGHu = luaFunc:readRecvByte()
        data.bQGHuJM = luaFunc:readRecvByte()
        data.bHuangZhuangHG = luaFunc:readRecvByte()
        data.bQingSH = luaFunc:readRecvByte()
        data.bJiePao = luaFunc:readRecvByte()
        data.bNiaoType = luaFunc:readRecvByte()             --1.一鸟一分、2.一鸟两分
        data.bQingYiSe = luaFunc:readRecvByte()
        data.bQiXiaoDui = luaFunc:readRecvByte()
        data.bPPHu = luaFunc:readRecvByte()             --1.一鸟一分、2.一鸟两分
        data.bWuTong = luaFunc:readRecvByte()  
        data.mPFFlag = luaFunc:readRecvByte() 
        data.mDiFen = luaFunc:readRecvByte()  
        data.mJFCount = luaFunc:readRecvLong()  --readRecvLong()    --积分上限 默认为0、自填为0~`1000

		haveReadByte = 19    --已读长度，每次增加或者减少都要修改该值，Byte1个字节 WORD2个字节 DWORD4个字节
		
	elseif wKindID == 69 then 
        data.FanXing = {}
        data.FanXing.bType = luaFunc:readRecvByte()                 --翻省    0默认没有反省  1上省  2下省  3跟省
        data.FanXing.bCount = luaFunc:readRecvByte()                --翻省的次数
        data.FanXing.bAddTun = luaFunc:readRecvByte()               --省算法, 一省三囤  单省    
        data.bPlayerCountType = luaFunc:readRecvByte()              --用户人数模式 0：默认3人   1：4人玩法  2：3人参与另外一人省(无用)
        data.bPlayerCount = luaFunc:readRecvByte()                  --参与游戏的人数 3+1模式为3
        data.bLaiZiCount = luaFunc:readRecvByte()                   --癞子数量 0 ~ 4个
        data.bMaxLost = luaFunc:readRecvWORD()                      --最大输
        data.bYiWuShi = luaFunc:readRecvByte()                      --是否有一五十吃法
        data.bLiangPai = luaFunc:readRecvByte()                     --是否亮牌
        data.bCanHuXi = luaFunc:readRecvByte()                      --起胡数  0 3 6 10 15  
        data.bHuType = luaFunc:readRecvByte()                       --胡牌类型  0自摸翻倍  1接炮
        data.bFangPao = luaFunc:readRecvByte()                      --是否有放跑功能
        data.bSettlement = luaFunc:readRecvByte()                   --结算是否按三胡一囤，否则一胡一囤
        data.bStartTun = luaFunc:readRecvByte()                     --囤数起始算法  0起始胡息一囤  1起始胡息二囤 210胡息三囤<=15胡息每多1胡息+1囤    
        data.bSocreType = luaFunc:readRecvByte()                    --0低分*囤数总和*名堂番数总和  1低分*囤数总和*名堂番数乘积
        data.dwMingTang = luaFunc:readRecvDWORD()                   --包含的名堂有哪些             
        data.bTurn = luaFunc:readRecvByte()
        data.bPaoTips = luaFunc:readRecvByte()
        data.bStartBanker = luaFunc:readRecvByte()
        data.bSiQiHong = luaFunc:readRecvByte()
        data.bDelShuaHou = luaFunc:readRecvByte()
        data.bHuangFanAddUp = luaFunc:readRecvByte()
        data.bTingHuAll = luaFunc:readRecvByte()
		data.bDeathCard = luaFunc:readRecvByte()                    --0 不抽低  1 抽牌20张 
		data.bPaPo = luaFunc:readRecvByte()
        haveReadByte = 29    --已读长度，每次增加或者减少都要修改该值，Byte1个字节 WORD2个字节 DWORD4个字节
        
    else
    
    end
    
    return data, haveReadByte
end

return GameConfig