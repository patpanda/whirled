package com.threerings.brawler {

import flash.display.DisplayObject;
import flash.display.DisplayObjectContainer;
import flash.display.MovieClip;
import flash.display.Sprite;
import flash.events.Event;
import flash.geom.Point;
import flash.utils.getTimer;

import com.threerings.util.ArrayUtil;

import com.threerings.ezgame.StateChangedEvent;

import com.threerings.flash.MathUtil;

import com.threerings.brawler.actor.Actor;
import com.threerings.brawler.actor.Pawn;
import com.threerings.brawler.actor.Player;
import com.threerings.brawler.util.AnimationManager;
import com.threerings.brawler.util.BrawlerUtil;

/**
 * Depicts the state of the Brawler game.
 */
public class BrawlerView extends Sprite
{
    public function BrawlerView (disp :DisplayObject, ctrl :BrawlerController)
    {
        _ctrl = ctrl;

        // create the animation manager
        _animmgr = new AnimationManager(disp);
    }

    /**
     * Called by the controller when the SWF is done loading.
     */
    public function init () :void
    {
        // create the game display, fetching references to its various bits and bobs
        _game = new Game();
        _camera = _game["camera"];
        _background = _camera._zoom.bg;
        _ground = _background.ground;

        // compute the locations of the horizon and lip, which determine the perspective
        _horizon = _ground.y - 3*_ground.height;
        _lip = _ground.y + _ground.height;

        // create the hud view to wrap the existing hud
        var hud :MovieClip = _game["hud"] as MovieClip;
        var idx :int = _game.getChildIndex(hud);
        _game.removeChildAt(idx);
        _game.addChildAt(_hud = new HudView(_ctrl, this, hud), idx);

        // create and attach the cursor and goal
        _background.cursor_zone.addChild(_cursor = new Cursor());
        _cursor.visible = false;
        _background.cursor_zone.addChild(_goal = new Destination());
        _goal.visible = false;

        // if the game is in play, jump right into the main view; otherwise, show the preloader
        // display and wait for the game to start
        if (_ctrl.control.isInPlay()) {
            finishInit();
        } else {
            addChild(_preloader = new Preloader());
            _preloader["fade"].play();
            _ctrl.control.addEventListener(StateChangedEvent.GAME_STARTED,
                function (event :StateChangedEvent) :void {
                    removeChild(_preloader);
                    finishInit();
                });
        }
    }

    /**
     * Returns a reference to the animation manager.
     */
    public function get animmgr () :AnimationManager
    {
        return _animmgr;
    }

    /**
     * Returns a reference to the HUD view.
     */
    public function get hud () :HudView
    {
        return _hud;
    }

    /**
     * Returns a reference to the door to the next room.
     */
    public function get door () :DisplayObject
    {
        return _background.door_next;
    }

    /**
     * Returns a reference to the ground.
     */
    public function get ground () :MovieClip
    {
        return _ground;
    }

    /**
     * Returns the y coordinate of the center of the ground.
     */
    public function get groundCenterY () :Number
    {
        return _ground.y - _ground.height/2;
    }

    /**
     * Returns a reference to the cursor.
     */
    public function get cursor () :MovieClip
    {
        return _cursor;
    }

    /**
     * Checks whether the cursor is on (whether it's over a valid location).
     */
    public function get cursorOn () :Boolean
    {
        return _cursorOn;
    }

    /**
     * Returns the coordinates at which players start.
     */
    public function get playerStart () :Point
    {
        return new Point(100, _ground.y - _ground.height/2);
    }

    /**
     * Shows the goal marker at the specified position.
     */
    public function showGoal (x :Number, y :Number) :void
    {
        _goal.visible = true;
        _animmgr.play(_goal, "on");
        setPosition(_goal, x, y);
    }

    /**
     * Hides the goal marker.
     */
    public function hideGoal () :void
    {
        _animmgr.play(_goal, "off", false, function () :void {
            _goal.visible = false;
        });
    }

    /**
     * Plays a camera effect.
     */
    public function playCameraEffect (effect :String) :void
    {
        _animmgr.play(_camera, effect);
    }

    /**
     * Adds an actor to the scene.
     */
    public function addActor (actor :Actor) :void
    {
        _background.actors.addChild(actor);
        _actors.push(actor);
    }

    /**
     * Removes an actor from the scene.
     */
    public function removeActor (actor :Actor) :void
    {
        _background.actors.removeChild(actor);
        ArrayUtil.removeFirst(_actors, actor);
    }

    /**
     * Adds a transient sprite that will be removed after the specified amount of time (in seconds)
     * elapses.
     *
     * @param background if true, add this sprite to the background rather than the actor layer.
     */
    public function addTransient (
        sprite :Sprite, x :Number, y :Number, lifespan :Number = 1,
        background :Boolean = false) :void
    {
        (background ? _background : _background.actors).addChild(sprite);
        setPosition(sprite, x, y);
        _transients.push(new Transient(sprite, lifespan));
    }

    /**
     * Sets the position of the specified sprite and updates its scale accordingly.
     */
    public function setPosition (sprite :Sprite, x :Number, y :Number) :void
    {
        sprite.x = x;
        sprite.y = y;

        var scale :Number = getScale(y);
        sprite.scaleX = scale;
        sprite.scaleY = scale;

        // remove and reinsert the actor according to its sorted order
        if (!_background.actors.contains(sprite)) {
            return;
        }
        _background.actors.removeChild(sprite);
        for (var ii :int = 0; ii < _background.actors.numChildren; ii++) {
            if (scale <= _background.actors.getChildAt(ii).scaleX) {
                _background.actors.addChildAt(sprite, ii);
                return;
            }
        }
        _background.actors.addChild(sprite);
    }

    /**
     * Given a y coordinate in the local coordinate system, returns the corresponding scale.
     */
    public function getScale (y :Number) :Number
    {
        return (y <= _horizon) ? 0 : (y - _horizon) / (_lip - _horizon);
    }

    /**
     * Clamps a set of coordinates to the bounds of the ground region.
     */
    public function clampToGround (x :Number, y :Number) :Point
    {
        return new Point(
            MathUtil.clamp(x, 0, _ground.width),
            MathUtil.clamp(y, _ground.y - _ground.height, _ground.y));
    }

    /**
     * Exits the current room.
     */
    public function exitRoom (callback :Function) :void
    {
        // depict all the players moving out of the scene
        var tx :Number = _ground.width + 500;
        var ty :Number = groundCenterY;
        for each (var actor :Actor in _actors) {
            if (actor is Player) {
                (actor as Player).move(tx, ty, Pawn.WALK, false);
            }
        }
        // fade out
        _hud.fade("out", callback);
    }

    /**
     * Enters the current room.
     */
    public function enterRoom () :void
    {
        // set up the room
        updateRoom();

        // have all the players walk in
        var ty :Number = groundCenterY;
        for each (var actor :Actor in _actors) {
            if (actor is Player) {
                var player :Player = actor as Player;
                player.x = -150;
                player.y = ty;
                player.move(100, ty, Pawn.WALK, false);
            }
        }

        // fade in
        _hud.fade("in");
    }

    /**
     * Shows the results screen.
     */
    public function showResults () :void
    {

    }

    /**
     * Called when the game starts (or is determined to be already in play).
     */
    protected function finishInit () :void
    {
        // add the game display
        addChild(_game);

        // turn the camera effect off
        _camera.stop();

        // set up the first room
        updateRoom();

        // initialize the hud
        _hud.init();

        // start updating at every frame
        root.addEventListener(Event.ENTER_FRAME, handleEnterFrame);
    }

    /**
     * Called on every frame.
     */
    protected function handleEnterFrame (event :Event) :void
    {
        // compute the time elapsed since the last frame
        var ntimer :int = getTimer();
        var elapsed :Number = (ntimer - _timer) / 1000;
        _timer = ntimer;

        // increment the frame count
        _frameCount++;

        // perhaps do a per-second update
        var delta :Number = (_timer - _lastPerSecond) / 1000;
        if (delta >= 1.0) {
            updatePerSecond(delta);
            _lastPerSecond = _timer;
        }

        // notify the actors
        for each (var actor :Actor in _actors) {
            actor.enterFrame(elapsed);
        }

        // notify the controller
        _ctrl.enterFrame(elapsed);

        // update the camera position
        updateCamera(elapsed);

        // update the transient sprites
        updateTransients(elapsed);

        // update the locations of the background layers
        updateBackgroundLayers();

        // update the state of the cursor
        updateCursor();

        // update the hud
        _hud.enterFrame(elapsed);
    }

    /**
     * Called approximately once per second.
     *
     * @param elapsed the actual number of seconds elapsed since the last call.
     */
    protected function updatePerSecond (elapsed :Number) :void
    {
        // update the message per second measure
        _hud.updateMPS(Math.round(_ctrl.throttle.counter / elapsed));

        // update the throttle queue length display
        _hud.updateTBS();

        // update the frame rate measure
        _hud.updateFPS(Math.round(_frameCount / elapsed));
        _frameCount = 0;
    }

    /**
     * Updates the position of the camera.
     */
    protected function updateCamera (elapsed :Number) :void
    {
        // find out where we are
        var offset :Number = -_camera.x;

        // and where we'd like to be (clamped to the background limits)
        var goal :Number = _ctrl.self.x - Brawler.WIDTH/2;
        goal = MathUtil.clamp(goal, 0, _background.bg_1.width - Brawler.WIDTH);
        if (Math.abs(offset - goal) <= 1) {
            return; // close enough!
        }

        // approach at an exponential rate
        var f :Number = Math.exp(CAMERA_RATE * elapsed);
        var noffset :Number = BrawlerUtil.interpolate(offset, goal, f);

        // set the new offset
        _camera.x = -noffset;
    }

    /**
     * Updates the transient sprites.
     */
    protected function updateTransients (elapsed :Number) :void
    {
        for each (var transient :Transient in _transients) {
            if ((transient.lifespan -= elapsed) <= 0) {
                (_background.actors.contains(transient.sprite) ?
                    _background.actors : _background).removeChild(transient.sprite);
                ArrayUtil.removeFirst(_transients, transient);
            }
        }
    }

    /**
     * Updates the positions of the background layers.
     */
    protected function updateBackgroundLayers () :void
    {
        // determine the proportional offset of the camera (as determined by the base layer)
        var offset :Number = (-_camera.x) / (_background.bg_1.width - Brawler.WIDTH);

        // adjust the positions of the other layers according to their sizes
        for (var ii :int = 2; ii <= BACKGROUND_LAYERS; ii++) {
            var layer :MovieClip = _background["bg_" + ii];
            var loff :Number = offset * (layer.width - Brawler.WIDTH);
            layer.x = (-loff - _camera.x);
        }
    }

    /**
     * Updates the visibility and location of the cursor.
     */
    protected function updateCursor () :void
    {
        if (_ground.hitTestPoint(mouseX, mouseY)) {
            if (!_cursorOn) {
                _cursorOn = true;
                _cursor.visible = true;
                _animmgr.play(_cursor, "on");
            }
            var local :Point = _background.globalToLocal(new Point(mouseX, mouseY));
            setPosition(_cursor, local.x, local.y);

        } else if (_cursorOn) {
            _cursorOn = false;
            _animmgr.play(_cursor, "off", false, function () :void {
                _cursor.visible = false;
            });
        }
    }

    /**
     * Updates the ground and background layers to depict the current room.
     */
    protected function updateRoom () :void
    {
        var room :int = _ctrl.room;
        for (var ii :int = 1; ii <= BACKGROUND_LAYERS; ii++) {
            _background["bg_" + ii].gotoAndStop(room);
        }
        _ground.gotoAndStop(room);

        // update the hud
        _hud.updateRoom();

        // set up the door
        door.x = _ground.width
        door.height = _ground.height;
    }

    /** The Brawler controller. */
    protected var _ctrl :BrawlerController;

    /** Tracks animated clips. */
    protected var _animmgr :AnimationManager;

    /** Keeps the HUD up-to-date. */
    protected var _hud :HudView;

    /** The preloader display. */
    protected var _preloader :Sprite;

    /** The main game display. */
    protected var _game :Sprite;

    /** The game camera. */
    protected var _camera :MovieClip;

    /** The background. */
    protected var _background :MovieClip;

    /** The ground. */
    protected var _ground :MovieClip;

    /** The y coordinate of the horizon (at which sprites become points). */
    protected var _horizon :Number;

    /** The y coordinate of the lip (at which sprites becomes full-sized). */
    protected var _lip :Number;

    /** The cursor sprite. */
    protected var _cursor :MovieClip;

    /** Whether or not the cursor is currently "on" (or transitioning thereto). */
    protected var _cursorOn :Boolean = false;

    /** The player goal sprite. */
    protected var _goal :MovieClip;

    /** The actors in the view. */
    protected var _actors :Array = new Array();

    /** The transients in the view. */
    protected var _transients :Array = new Array();

    /** The time of the last frame. */
    protected var _timer :int = getTimer();

    /** The last time we did a per-second update. */
    protected var _lastPerSecond :int = _timer;

    /** The number of frames rendered in the last second. */
    protected var _frameCount :int = 0;

    /** The preloader display class. */
    [Embed(source="../../../../rsrc/raw.swf", symbol="_PRELOADER")]
    protected static const Preloader :Class;

    /** The game display class. */
    [Embed(source="../../../../rsrc/raw.swf", symbol="_GAME")]
    protected static const Game :Class;

    /** The ground cursor class. */
    [Embed(source="../../../../rsrc/raw.swf", symbol="cursor")]
    protected static const Cursor :Class;

    /** The player destination class. */
    [Embed(source="../../../../rsrc/raw.swf", symbol="destination")]
    protected static const Destination :Class;

    /** The number of background layers. */
    protected static const BACKGROUND_LAYERS :int = 5;

    /** The exponential rate at which the camera approaches its target position
     * (1/4 there after 1/30 of a second). */
    protected static const CAMERA_RATE :Number = 30 * Math.log(3/4);
}
}

import flash.display.Sprite;

class Transient
{
    /** The transient sprite. */
    public var sprite :Sprite;

    /** The transient's remaining lifespan. */
    public var lifespan :Number;

    public function Transient (sprite :Sprite, lifespan :Number)
    {
        this.sprite = sprite;
        this.lifespan = lifespan;
    }
}
