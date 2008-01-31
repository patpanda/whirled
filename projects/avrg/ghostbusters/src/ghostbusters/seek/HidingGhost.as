//
// $Id$

package ghostbusters.seek {

import flash.display.DisplayObject;
import flash.display.MovieClip;
import flash.display.Sprite;

import flash.geom.Point;
import flash.geom.Rectangle;

import flash.utils.ByteArray;

import flash.events.Event;

import com.threerings.util.EmbeddedSwfLoader;
import com.threerings.util.Log;
import com.threerings.util.Random;

import ghostbusters.Codes;
import ghostbusters.GhostBase;
import ghostbusters.SplinePather;

public class HidingGhost extends GhostBase
{
    public function HidingGhost (speed :int)
    {
        super();

        _speed = speed;
        _pather = new SplinePather();
    }

    public function isIdle () :Boolean
    {
        return _pather.idle;
    }

    public function setSpeed (newSpeed :Number) :void
    {
        _pather.adjustRate(newSpeed / _speed);
        _speed = newSpeed;
    }

    public function nextFrame () :void
    {
        _pather.nextFrame();

        this.x = _pather.x;
        this.y = _pather.y;
    }

    public function newTarget (p :Point) :void
    {
        var dX :Number = p.x - _pather.x;
        var dY :Number = p.y - _pather.y;
        var d :Number = Math.sqrt(dX*dX + dY*dY);

        _pather.newTarget(p, d / _speed, true);
    }

    public function appear (callback :Function) :int
    {
        return handler.gotoScene(Codes.ST_GHOST_APPEAR, function () :String {
            callback();
            // stay in FIGHT state for the brief period until the entire SeekPanel disappears
            return Codes.ST_GHOST_FIGHT;
        });
    }

    public function hidden () :void
    {
        handler.gotoScene(Codes.ST_GHOST_HIDDEN, function () :String {
            return Codes.ST_GHOST_HIDDEN;
        });
    }

    override protected function mediaReady () :void
    {
        super.mediaReady();
     }

    protected var _pather :SplinePather;
    protected var _random :Random;

    protected var _speed :Number;
}
}
