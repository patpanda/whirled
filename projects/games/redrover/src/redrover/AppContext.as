package redrover {

import com.whirled.contrib.simplegame.MainLoop;
import com.whirled.contrib.simplegame.audio.AudioManager;
import com.whirled.contrib.simplegame.resource.ResourceManager;
import com.whirled.game.GameControl;

import flash.display.Sprite;


public class AppContext
{
    public static var mainSprite :Sprite;
    public static var mainLoop :MainLoop;
    public static var rsrcs :ResourceManager;
    public static var audio :AudioManager;
    public static var gameCtrl :GameControl;
    public static var levelMgr :LevelManager = new LevelManager();
}

}
