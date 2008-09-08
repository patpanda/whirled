package joingame {

import com.whirled.contrib.simplegame.*;
import com.whirled.contrib.simplegame.audio.*;
import com.whirled.contrib.simplegame.resource.*;
import com.whirled.game.GameControl;

import flash.display.Sprite;

//import popcraft.data.*;
//import popcraft.sp.LevelManager;

//Copied and modified from popcraft
public class AppContext
{
    public static var mainSprite :Sprite;
    public static var mainLoop :MainLoop;
    public static var gameCtrl :GameControl;
//    public static var levelMgr :LevelManager;
    public static var randStreamPuzzle :uint;
//    public static var globalPlayerStats :PlayerStats;

//    public static function get defaultGameData () :GameData
//    {
//        var dataRsrc :GameDataResource = ResourceManager.instance.getResource("defaultGameData") as GameDataResource;
//        return dataRsrc.gameData;
//    }

//    public static function get levelProgression () :LevelProgressionData
//    {
//        var dataRsrc :GameDataResource = ResourceManager.instance.getResource("defaultGameData") as GameDataResource;
//        return dataRsrc.levelProgression;
//    }

//    public static function get multiplayerSettings () :Array
//    {
//        var dataRsrc :GameDataResource = ResourceManager.instance.getResource("defaultGameData") as GameDataResource;
//        return dataRsrc.multiplayerSettings;
//    }

//    public static function get gameVariants () :Array
//    {
//        var variantResource :GameVariantsResource = ResourceManager.instance.getResource("gameVariants") as GameVariantsResource;
//        return variantResource.variants;
//    }

    public static function LOG(s: String): void
    {
        if(false && gameCtrl != null && gameCtrl.local != null && gameCtrl.net.isConnected())
        {
            gameCtrl.local.feedback(s);
        }
        else
        {
            trace(s);
        }
    }
}

}
