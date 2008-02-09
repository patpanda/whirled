package ghostbusters.fight {
    
import com.whirled.contrib.core.*;
import com.whirled.contrib.core.resource.*;
import com.whirled.contrib.core.util.*;

import flash.display.Sprite;
import flash.geom.Rectangle;

import ghostbusters.fight.common.*;
import ghostbusters.fight.lantern.*;
import ghostbusters.fight.ouija.*;
import ghostbusters.fight.plasma.*;
import ghostbusters.fight.potions.*;
    
public class MicrogamePlayer extends Sprite
{
    public function MicrogamePlayer (playerData :Object)
    {
        _playerData = playerData;
        
        if (null != MainLoop.instance) {
            MainLoop.instance.shutdown();
        }
        
        // clip games to the bounds of the player
        this.scrollRect = new Rectangle(0, 0, MicrogameConstants.GAME_WIDTH, MicrogameConstants.GAME_HEIGHT);
        
        new MainLoop(this);
        MainLoop.instance.run();
        
        Resources.instance.loadAll();
    }
    
    public function get weaponType () :WeaponType
    {
        return _weaponType;
    }
    
    public function set weaponType (type :WeaponType) :void
    {
        if (!type.equals(_weaponType)) {
            _weaponType = type;
            this.cancelCurrentGame();
        }
    }
    
    public function beginNextGame () :Microgame
    {
        if (null == _weaponType) {
            throw new Error("weaponType must be set before the games can begin!");
        }
        
        if (null != _currentGame) {
            _currentGame.end();
            _currentGame = null;
        }
        
        _currentGame = this.generateGame();
        
        if (!Resources.instance.isLoading) {
            _currentGame.begin();
        } else {
            // postpone the game beginning until loading has completed
            trace("pending game start until resources have completed loading");
            
            Resources.instance.resourceManager.addEventListener(ResourceLoadEvent.LOADED, beginPendingGame, false, 0, true);
        }
        
        return _currentGame;
    }
    
    protected function beginPendingGame (e :ResourceLoadEvent) :void
    {
        Resources.instance.resourceManager.removeEventListener(ResourceLoadEvent.LOADED, beginPendingGame);
        _currentGame.begin();
    }
    
    public function get currentGame () :Microgame
    {
        return _currentGame;
    }
    
    protected function generateGame () :MicrogameMode
    {
        var validDescriptors :Array = GAME_DESCRIPTORS.filter(isValidDescriptor);
        
        if (validDescriptors.length == 0) {
            throw new Error("No valid games for " + _weaponType);
        }
        
        var desc :MicrogameDescriptor = validDescriptors[Rand.nextIntRange(0, validDescriptors.length, Rand.STREAM_COSMETIC)];
        return desc.instantiateGame(_weaponType.level, _playerData);
        
        function isValidDescriptor(desc :MicrogameDescriptor, index :int, array :Array) :Boolean 
        {
            return (desc.weaponTypeName == _weaponType.name && desc.baseDifficulty <= _weaponType.level);
        }
    }
    
    public function cancelCurrentGame () :void
    {
        MainLoop.instance.popAllModes();
        _currentGame = null;
    }
    
    protected var _playerData :Object;
    protected var _weaponType :WeaponType;
    protected var _running :Boolean;
    protected var _currentGame :MicrogameMode;
    
    protected static const GAME_DESCRIPTORS :Array = [
    
        new MicrogameDescriptor(WeaponType.NAME_LANTERN,    0, HeartOfDarknessGame),
        
        new MicrogameDescriptor(WeaponType.NAME_OUIJA,      0, GhostWriterGame),
        new MicrogameDescriptor(WeaponType.NAME_OUIJA,      0, PictoGeistGame),
        new MicrogameDescriptor(WeaponType.NAME_OUIJA,      1, SpiritGuideGame),
        
        new MicrogameDescriptor(WeaponType.NAME_PLASMA,     0, SpiritShellGame),
        
        new MicrogameDescriptor(WeaponType.NAME_POTIONS,    0, HueAndCryGame),
        
    ];
}

}
