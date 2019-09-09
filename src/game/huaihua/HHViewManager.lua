---------------
--   lua 视图打开管理
---------------
local HHViewManager = {}
local APPNAME = 'huaihua'
--==============================--
--desc: 二级弹框
--==============================--
function HHViewManager.openBox( params )
    HHViewManager.openView(params,'HHNoticeBox')
end

--==============================--
--desc:打开解散窗口
--==============================--
function HHViewManager.openDimissTable( params )
    HHViewManager.openView(params,'HHDisMissTable')
end

function HHViewManager.openView(params, name )
    local path = HHViewManager.requireClass(name)
    local box = require("app.MyApp"):create(params):createGame(path)

    require("common.SceneMgr"):switchTips(box)
end

function HHViewManager.requireClass( name )
    local path = string.format( "game.%s.%s",APPNAME ,name)
    return path
end

return HHViewManager