package redrover.server {

import com.whirled.game.GameControl;

import redrover.SeatingManager;

public class ServerCtx
{
    public static var gameCtrl :GameControl;
    public static var seatingMgr :SeatingManager = new SeatingManager();
}

}