//
// $Id$

package ghostbusters.server {

import com.threerings.util.Log;

import com.whirled.net.MessageReceivedEvent;

import com.whirled.avrg.AVRGamePlayerEvent;
import com.whirled.avrg.PlayerServerSubControl;

import ghostbusters.data.Codes;

public class Player
{
    // avatar states
    public static const ST_PLAYER_DEFAULT :String = "Default";
    public static const ST_PLAYER_FIGHT :String = "Fight";
    public static const ST_PLAYER_DEFEAT :String = "Defeat";

    public static var log :Log = Log.getLog(Player);

    public function Player (ctrl :PlayerServerSubControl)
    {
        _ctrl = ctrl;
        _playerId = ctrl.getPlayerId();

        _ctrl.addEventListener(MessageReceivedEvent.MESSAGE_RECEIVED, handleMessage);
        _ctrl.addEventListener(AVRGamePlayerEvent.ENTERED_ROOM, enteredRoom);
        _ctrl.addEventListener(AVRGamePlayerEvent.LEFT_ROOM, leftRoom);

        _level = int(_ctrl.props.get(Codes.PROP_MY_LEVEL));
        if (_level == 0) {
            // this person has never played Ghosthunters before
            _level = 1;
            _ctrl.props.set(Codes.PROP_MY_LEVEL, _level, true);
            _health = _maxHealth = calculateMaxHealth();

        } else {
            _health = int(_ctrl.props.get(Codes.PROP_MY_HEALTH));
            _maxHealth = calculateMaxHealth();
        }
    }

    public function get ctrl () :PlayerServerSubControl
    {
        return _ctrl;
    }

    public function get playerId () :int
    {
        return _playerId;
    }

    public function get level () :int
    {
        return _level;
    }

    public function get health () :int
    {
        return _health;
    }

    public function get maxHealth () :int
    {
        return _maxHealth;
    }

    public function isDead () :Boolean
    {
        return _health == 0;
    }

    public function shutdown () :void
    {
        _ctrl.removeEventListener(AVRGamePlayerEvent.ENTERED_ROOM, enteredRoom);
        _ctrl.removeEventListener(AVRGamePlayerEvent.LEFT_ROOM, leftRoom);
    }

    public function damage (damage :int) :void
    {
        log.debug("Doing " + damage + " damage to a player with health " + _health);

        // let the clients in the room know of the attack
        _room.ctrl.sendMessage(Codes.SMSG_PLAYER_ATTACKED, _playerId);
        // play the reel animation for ourselves!
        _ctrl.playAvatarAction("Reel");

        setHealth(health - damage); // note: setHealth clamps this to [0, maxHealth]
    }

    public function heal (amount :int) :void
    {
        if (!isDead()) {
            setHealth(_health + amount); // note: setHealth clamps this to [0, maxHealth]
        }
    }

    public function roomStateChanged () :void
    {
        updateAvatarState();
    }

    protected function enteredRoom (evt :AVRGamePlayerEvent) :void
    {
        _room = Server.getRoom(int(evt.value));
        _room.playerEntered(this);
        updateAvatarState();
    }

    protected function leftRoom (evt :AVRGamePlayerEvent) :void
    {
        var evtRoom :Room = Server.getRoom(int(evt.value));
        if (evtRoom.roomId != _room.roomId) {
            log.warning("Unexpected leftRoom event [event.roomId=" +
                evtRoom.roomId + ", _roomId=" + _room.roomId + "]");
        }

        _room.playerLeft(this);
        _room = null;
    }

    protected function handleMessage (event: MessageReceivedEvent) :void
    {
        var msg :String = event.name;

        // handle messages that make (at least some) sense even if we're between rooms
        if (msg == Codes.CMSG_PLAYER_REVIVE) {
            setHealth(_maxHealth);
        }

        // if we're nowhere, drop out
        if (_room == null) {
            return;
        }

        if (msg == Codes.CMSG_GHOST_ZAP) {
            if (_room.checkState(Codes.STATE_SEEKING)) {
                _room.ghostZap(this);
            }

        } else if (msg == Codes.CMSG_MINIGAME_RESULT) {
            if (_room.checkState(Codes.STATE_FIGHTING)) {
                var bits :Array = event.value as Array;
                if (bits != null) {
                    _room.minigameCompletion(this, Boolean(bits[0]), int(bits[1]), int(bits[2]));
                }
            }

        } else if (msg == Codes.CMSG_LANTERN_POS) {
            _room.updateLanternPos(_playerId, event.value as Array);
        }
    }

    protected function updateAvatarState () :void
    {
        if (isDead()) {
            _ctrl.setAvatarState(ST_PLAYER_DEFEAT);

        } else if (_room.state == Codes.STATE_SEEKING || _room.state == Codes.STATE_APPEARING) {
            _ctrl.setAvatarState(ST_PLAYER_DEFAULT);

        } else {
            _ctrl.setAvatarState(ST_PLAYER_FIGHT);
        }
    }

    protected function setHealth (health :int) :void
    {
        // update our runtime state
        _health = Math.max(0, Math.min(health, _maxHealth));

        // persist it, too
        _ctrl.props.set(Codes.PROP_MY_HEALTH, _health, true);

        // if we just died, update our state
        if (_health == 0) {
            _ctrl.setAvatarState(ST_PLAYER_DEFEAT);
        }

        // and if we're in a room, update the room properties
        if (_room != null) {
            _room.playerHealthUpdated(this);
        }
    }

    protected function calculateMaxHealth () :int
    {
        // level 1 has 1 health, after that a 25% gain per level
        return 100 * (Math.pow(1.25, _level));
    }

    protected var _ctrl :PlayerServerSubControl;
    protected var _room :Room;

    protected var _playerId :int;
    protected var _level :int;
    protected var _health :int;
    protected var _maxHealth :int;
}
}
