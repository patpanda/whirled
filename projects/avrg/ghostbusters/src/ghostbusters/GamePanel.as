//
// $Id$

package ghostbusters {

import flash.display.DisplayObject;
import flash.display.Graphics;
import flash.display.MovieClip;
import flash.display.Shape;
import flash.display.SimpleButton;
import flash.display.Sprite;

import flash.events.Event;
import flash.events.MouseEvent;

import flash.utils.ByteArray;

import com.whirled.avrg.AVRGameControl;
import com.whirled.avrg.AVRGameControlEvent;
import com.whirled.avrg.AVRGamePlayerEvent;
import com.whirled.net.ElementChangedEvent;
import com.whirled.net.PropertyChangedEvent;

import com.threerings.flash.AnimationManager;
import com.threerings.flash.DisplayUtil;

import com.threerings.util.ArrayUtil;
import com.threerings.util.CommandEvent;

import ghostbusters.fight.FightPanel;
import ghostbusters.util.GhostModel;
import ghostbusters.util.PlayerModel;
import ghostbusters.seek.SeekPanel;

public class GamePanel extends Sprite
{
    // ghost states
    public static const ST_GHOST_HIDDEN :String = "hidden";
    public static const ST_GHOST_APPEAR :String = "appear_to_fighting";
    public static const ST_GHOST_FIGHT :String = "fighting";
    public static const ST_GHOST_REEL :String = "reel";
    public static const ST_GHOST_RETALIATE :String = "retaliate";
    public static const ST_GHOST_DEFEAT :String = "defeat_disappear";
    public static const ST_GHOST_TRIUMPH :String = "triumph_chase";

    // avatar states
    public static const ST_PLAYER_DEFAULT :String = "Default";
    public static const ST_PLAYER_FIGHT :String = "Fight";
    public static const ST_PLAYER_DEFEAT :String = "Defeat";

    public var hud :HUD;

    public function GamePanel ()
    {
        hud = new HUD();
        this.addChild(hud);

        new GameFrame(function (frame :GameFrame) :void {
            _frame = frame;
        });

        Game.control.room.props.addEventListener(
            PropertyChangedEvent.PROPERTY_CHANGED, roomPropertyChanged);

        Game.control.player.addEventListener(AVRGamePlayerEvent.COINS_AWARDED, coinsAwarded);

        var panel :GamePanel = this;
        new ClipHandler(ByteArray(new Content.PLAYER_DIED()), function (clip :MovieClip) :void {
            _revivePopup = clip;
            _revivePopup.x = 100;
            _revivePopup.y = 200;

            var button :SimpleButton =
                SimpleButton(DisplayUtil.findInHierarchy(clip, "revivebutton"));
            if (button == null) {
                Game.log.debug("Urk, cannot find revivebutton...");
                return;
            }
            button.addEventListener(MouseEvent.CLICK, function (event :Event) :void {
                CommandEvent.dispatch(panel, GameController.REVIVE);
            });

            checkPlayerHealth();
        });

        new ClipHandler(ByteArray(new Content.GHOST_DEFEATED()), function (clip :MovieClip) :void {
            _ghostDefeated = clip;
            _ghostDefeated.x = 300;
            _ghostDefeated.y = 200;

            var button :SimpleButton =
                SimpleButton(DisplayUtil.findInHierarchy(clip, "continuebutton"));
            if (button == null) {
                Game.log.debug("Urk, cannot find continuebutton...");
                return;
            }
            button.addEventListener(MouseEvent.CLICK, function (event :Event) :void {
                popdown(_ghostDefeated);
            });

        });
    }

    public function shutdown () :void
    {
        hud.shutdown();
    }

    override public function hitTestPoint (
        x :Number, y :Number, shapeFlag :Boolean = false) :Boolean
    {
        for (var ii :int = 0; ii < this.numChildren; ii ++) {
            if (this.getChildAt(ii).hitTestPoint(x, y, shapeFlag)) {
                return true;
            }
        }
        return false;
    }

    public function get ghost () :Ghost
    {
        return _ghost;
    }

    public function get subPanel () :DisplayObject
    {
        return _panel;
    }

    public function get seeking () :Boolean
    {
        return _seeking;
    }

    public function set seeking (seeking :Boolean) :void
    {
        _seeking = seeking;
        updateState();
    }

    public function unframeContent () :void
    {
        _frame.frameContent(null);
        this.removeChild(_frame);
    }

    public function frameContent (content :DisplayObject) :void
    {
        _frame.frameContent(content);

        this.addChild(_frame);

        _frame.x = (Game.stageSize.width - 100 - _frame.width) / 2;
        _frame.y = (Game.stageSize.height - _frame.height) / 2 - FRAME_DISPLACEMENT_Y;
    }

    public function reloadView () :void
    {
        hud.reloadView();
        checkPlayerHealth();
    }

    public function getClipClass () :Class
    {
        var id :String = GhostModel.getId();
        if (id != null) {
            var clip :Class = GHOST_CLIPS[id]
            if (clip != null) {
                return clip;
            }
            Game.log.debug("Erk, cannot find clip for id=" + id);
        }
        return null;
    }

    public function newGhost () :void
    {
        _ghost = null;
        var clip :Class = getClipClass();
        if (clip != null) {
            new Ghost(clip, function (g :Ghost) :void {
                _ghost = g;
                updateState();
            });
        }
    }

    protected function coinsAwarded (evt :AVRGameControlEvent) :void
    {
        var panel :GamePanel = this;
        var flourish :CoinFlourish = new CoinFlourish(evt.value as int, function () :void {
            AnimationManager.stop(flourish);
            panel.removeChild(flourish);
        });

        flourish.x = (Game.stageSize.width - flourish.width) / 2;
        flourish.y = 20;
        this.addChild(flourish);

        AnimationManager.start(flourish);
    }

    public function updateAvatarState () :void
    {
        var avatarState :String;

        if (PlayerModel.isDead(Game.ourPlayerId)) {
            avatarState = ST_PLAYER_DEFEAT;

        } else if (Game.state == Codes.STATE_SEEKING ||
                   Game.state == Codes.STATE_APPEARING) {
                avatarState = ST_PLAYER_DEFAULT;

        } else {
            avatarState = ST_PLAYER_FIGHT;

        }

        GameController.setAvatarState(avatarState);
    }

    protected function checkPlayerHealth () :void
    {
        if (_revivePopup == null) {
            // still loading; there will be another callback when it's done
            return;
        }

        if (!PlayerModel.isDead(Game.ourPlayerId)) {
            // possibly we were just revived, let's see
            if (_revivePopup.parent == this) {
                this.removeChild(_revivePopup);
            }
            // we're not dead
            return;
        }
        Game.log.debug("We seem to be quite dead.");
        popup(_revivePopup);
    }

    protected function popup (clip :MovieClip) :void
    {
        if (clip.parent != null) {
            Game.log.warning("Popup candidate already has a parent [popup=" + clip + "]");
            return;
        }
        this.addChild(clip);
    }

    protected function popdown (clip :MovieClip) :void
    {
        if (clip.parent != null) {
            Game.log.warning("Popup candidate already has a parent [popup=" + clip + "]");
            return;
        }
        this.addChild(clip);
    }

    protected function roomPropertyChanged (evt :PropertyChangedEvent) :void
    {
        if (evt.name == Codes.PROP_STATE) {
            _seeking = false;
            updateState();

            if (evt.newValue == Codes.STATE_GHOST_TRIUMPH) {
                popup(_ghostDefeated);
            }

        } else if (evt.name == Codes.DICT_GHOST) {
            newGhost();
        }
    }

    protected function roomElementChanged (evt :ElementChangedEvent) :void
    {
        var playerId :int = PlayerModel.parseProperty(Codes.DICT_PFX_PLAYER, evt.name);

        if (playerId == Game.ourPlayerId && evt.key == Codes.PROP_PLAYER_CUR_HEALTH) {
            checkPlayerHealth();
            updateAvatarState();
        }
    }

    protected function updateState () :void
    {
        var seekPanel :Boolean =
            ((Game.state == Codes.STATE_SEEKING && _seeking) ||
              Game.state == Codes.STATE_APPEARING);

        var fightPanel :Boolean =
            (Game.state == Codes.STATE_FIGHTING ||
             Game.state == Codes.STATE_GHOST_TRIUMPH ||
             Game.state == Codes.STATE_GHOST_DEFEAT);

        setPanel(seekPanel ? SeekPanel : (fightPanel ? FightPanel : null));

        updateAvatarState();
    }

    protected function setPanel (pClass :Class) :void
    {
        if (pClass != null && _panel is pClass) {
            return;
        }
        if (_panel != null) {
            this.removeChild(_panel);
            _panel = null;
        }
        if (pClass != null) {
            _panel = new pClass(_ghost);
            this.addChildAt(_panel, 0);
        }
    }

    protected var _seeking :Boolean = false;

    protected var _panel :DisplayObject;

    protected var _ghost :Ghost;

    protected var _frame :GameFrame;

    protected var _revivePopup :MovieClip;

    protected var _ghostDefeated :MovieClip;

    // maps ghost id to model
    protected static const GHOST_CLIPS :Object = {
      pinchy: Content.GHOST_PINCHER,
      duchess: Content.GHOST_DUCHESS,
      widow: Content.GHOST_WIDOW,
      demon: Content.GHOST_DEMON
    };

    protected static const FRAME_DISPLACEMENT_Y :int = 20;
}
}
