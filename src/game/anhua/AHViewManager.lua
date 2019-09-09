---------------
--   lua 视图打开管理
---------------
local AHViewManager = {}
local APPNAME = 'anhua'
--==============================--
--desc: 二级弹框
--==============================--
function AHViewManager.openBox( params )
    AHViewManager.openView(params,'AHNoticeBox')
end

--==============================--
--desc:打开解散窗口
--==============================--
function AHViewManager.openDimissTable( params )
    AHViewManager.openView(params,'AHDisMissTable')
end

function AHViewManager.openView(params, name )
    local path = AHViewManager.requireClass(name)
    local box = require("app.MyApp"):create(params):createGame(path)

    require("common.SceneMgr"):switchTips(box)
end

function AHViewManager.requireClass( name )
    local path = string.format( "game.%s.%s",APPNAME ,name)
    return path
end

return AHViewManager