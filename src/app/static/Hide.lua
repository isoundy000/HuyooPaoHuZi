local Hide = {
    --id="渠道ID",btn1="公会",btn2="战绩",btn3="福利",btn4="好有房邀请按钮",btn5="大结算分享按钮",btn6="地区",
    --btn7="公会比赛活动",btn8="充值系统",btn9="有无房卡购买"，btn10="亲友圈与定位",btn11="代开 btn12=签到 btn13=竞技场",
    --btn14=闲聊分享,btn15=搓牌,btn16=距离报警,btn17=聊天室按钮,btn18=积分统计开关,btn19=个人信息弹框,btn20=微信商城弹跳

    [0]={ id=0, btn1=1, btn2=1, btn3=1, btn4=1, btn5=1, btn6=1, btn7=0, btn8=1, btn9=1,btn10=1,btn11=0,btn12=1,btn13=1,btn14=1,btn15=0,btn16=0,btn17=1,btn18=0,btn19=0,btn20=0}, 
    [1]={ id=1, btn1=1, btn2=1, btn3=1, btn4=1, btn5=1, btn6=1, btn7=0, btn8=1, btn9=1,btn10=1,btn11=0,btn12=1,btn13=1,btn14=1,btn15=0,btn16=0,btn17=1,btn18=0,btn19=0,btn20=0}, 
    [2]={ id=2, btn1=1, btn2=1, btn3=1, btn4=1, btn5=1, btn6=1, btn7=0, btn8=1, btn9=1,btn10=1,btn11=0,btn12=1,btn13=1,btn14=0,btn15=0,btn16=0,btn17=1,btn18=0,btn19=0,btn20=0}, 
    [3]={ id=3, btn1=1, btn2=1, btn3=1, btn4=1, btn5=1, btn6=1, btn7=0, btn8=1, btn9=1,btn10=1,btn11=0,btn12=1,btn13=1,btn14=1,btn15=0,btn16=0,btn17=1,btn18=0,btn19=0,btn20=0}, 
    [4]={ id=4, btn1=1, btn2=1, btn3=1, btn4=1, btn5=1, btn6=0, btn7=0, btn8=0, btn9=0,btn10=1,btn11=0,btn12=0,btn13=1,btn14=0,btn15=0,btn16=0,btn17=1,btn18=0,btn19=0,btn20=0}, 
    [5]={ id=5, btn1=1, btn2=1, btn3=1, btn4=1, btn5=1, btn6=0, btn7=0, btn8=0, btn9=0,btn10=1,btn11=0,btn12=0,btn13=1,btn14=0,btn15=0,btn16=0,btn17=1,btn18=0,btn19=0,btn20=0}, 
    [6]={ id=6, btn1=1, btn2=1, btn3=1, btn4=1, btn5=1, btn6=0, btn7=0, btn8=1, btn9=0,btn10=1,btn11=0,btn12=0,btn13=1,btn14=1,btn15=0,btn16=0,btn17=1,btn18=0,btn19=0,btn20=0}, 
    [7]={ id=7, btn1=1, btn2=1, btn3=1, btn4=1, btn5=1, btn6=0, btn7=0, btn8=1, btn9=0,btn10=1,btn11=0,btn12=0,btn13=1,btn14=1,btn15=0,btn16=0,btn17=1,btn18=0,btn19=0,btn20=0}, 
    [8]={ id=8, btn1=1, btn2=1, btn3=1, btn4=1, btn5=1, btn6=0, btn7=0, btn8=1, btn9=1,btn10=1,btn11=0,btn12=1,btn13=1,btn14=0,btn15=0,btn16=0,btn17=1,btn18=0,btn19=0,btn20=0}, 
    [9]={ id=9, btn1=1, btn2=1, btn3=1, btn4=1, btn5=1, btn6=0, btn7=0, btn8=1, btn9=1,btn10=1,btn11=0,btn12=1,btn13=1,btn14=0,btn15=0,btn16=0,btn17=1,btn18=0,btn19=0,btn20=0}, 
    [10]={ id=10, btn1=1, btn2=1, btn3=1, btn4=1, btn5=1, btn6=1, btn7=0, btn8=0, btn9=0,btn10=1,btn11=0,btn12=1,btn13=1,btn14=0,btn15=0,btn16=0,btn17=0,btn18=0,btn19=0,btn20=0}, 
    [11]={ id=11, btn1=1, btn2=1, btn3=1, btn4=1, btn5=1, btn6=1, btn7=0, btn8=0, btn9=0,btn10=1,btn11=0,btn12=1,btn13=1,btn14=0,btn15=0,btn16=0,btn17=0,btn18=0,btn19=0,btn20=0}, 
    [12]={ id=12, btn1=1, btn2=1, btn3=1, btn4=1, btn5=1, btn6=1, btn7=0, btn8=1, btn9=1,btn10=1,btn11=0,btn12=1,btn13=1,btn14=0,btn15=0,btn16=0,btn17=1,btn18=0,btn19=0,btn20=0}, 
    [13]={ id=13, btn1=1, btn2=1, btn3=1, btn4=1, btn5=1, btn6=1, btn7=0, btn8=1, btn9=1,btn10=1,btn11=0,btn12=1,btn13=1,btn14=0,btn15=0,btn16=0,btn17=1,btn18=0,btn19=0,btn20=0}, 
    [14]={ id=14, btn1=1, btn2=1, btn3=1, btn4=1, btn5=1, btn6=0, btn7=0, btn8=1, btn9=1,btn10=1,btn11=0,btn12=1,btn13=1,btn14=1,btn15=0,btn16=1,btn17=1,btn18=0,btn19=1,btn20=1}, 
    [15]={ id=15, btn1=1, btn2=1, btn3=1, btn4=1, btn5=1, btn6=0, btn7=0, btn8=1, btn9=1,btn10=1,btn11=0,btn12=1,btn13=1,btn14=1,btn15=0,btn16=1,btn17=1,btn18=0,btn19=1,btn20=1}, 
    [16]={ id=16, btn1=1, btn2=1, btn3=1, btn4=1, btn5=1, btn6=0, btn7=0, btn8=0, btn9=1,btn10=1,btn11=0,btn12=1,btn13=1,btn14=0,btn15=0,btn16=0,btn17=1,btn18=0,btn19=0,btn20=0}, 
    [17]={ id=17, btn1=1, btn2=1, btn3=1, btn4=1, btn5=1, btn6=0, btn7=0, btn8=0, btn9=1,btn10=1,btn11=0,btn12=1,btn13=1,btn14=0,btn15=0,btn16=0,btn17=1,btn18=0,btn19=0,btn20=0}, 
    [18]={ id=18, btn1=1, btn2=1, btn3=1, btn4=1, btn5=1, btn6=0, btn7=0, btn8=0, btn9=0,btn10=1,btn11=1,btn12=0,btn13=0,btn14=0,btn15=0,btn16=0,btn17=1,btn18=0,btn19=0,btn20=0}, 
    [19]={ id=19, btn1=1, btn2=1, btn3=1, btn4=1, btn5=1, btn6=0, btn7=0, btn8=0, btn9=0,btn10=1,btn11=1,btn12=0,btn13=0,btn14=0,btn15=0,btn16=0,btn17=1,btn18=0,btn19=0,btn20=0}, 
    [20]={ id=20, btn1=1, btn2=1, btn3=1, btn4=1, btn5=1, btn6=0, btn7=0, btn8=0, btn9=0,btn10=1,btn11=0,btn12=0,btn13=0,btn14=0,btn15=0,btn16=0,btn17=1,btn18=0,btn19=0,btn20=0}, 
    [21]={ id=21, btn1=1, btn2=1, btn3=1, btn4=1, btn5=1, btn6=0, btn7=0, btn8=0, btn9=0,btn10=1,btn11=0,btn12=0,btn13=0,btn14=0,btn15=0,btn16=0,btn17=1,btn18=0,btn19=0,btn20=0}, 
}

return Hide
