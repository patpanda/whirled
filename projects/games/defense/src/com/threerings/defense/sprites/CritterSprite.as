package com.threerings.defense.sprites {

import flash.geom.Point;

import com.threerings.defense.Level;
import com.threerings.defense.units.Critter;

public class CritterSprite extends UnitSprite
{
    public static const STATE_RIGHT :int = 0;
    public static const STATE_UP    :int = 1;
    public static const STATE_LEFT  :int = 2;
    public static const STATE_DOWN  :int = 3;
    
    public static const ALL_STATES :Array = [ STATE_RIGHT, STATE_UP, STATE_LEFT, STATE_DOWN ];
    
    public function CritterSprite (critter :Critter, level :Level)
    {
        super(critter, level);
        
        // shift tiles over some random number of pixels from the tile center
        _tileOffset = new Point(Math.random() * 10 - 5, Math.random() * 6 - 3);
    }

    public function get critter () :Critter
    {
        return _unit as Critter;
    }

    override public function recomputeCurrentState () :int
    {
        var walkDir :int = -1;
        var vel :Point = critter.vel;

        if (vel.x == 0 && vel.y == 0) {
            // we're stopped - just return the last known state
            return _currentState;
        }

        // we're moving! let's figure out where.
        if (Math.abs(vel.y) > Math.abs(vel.x)) {
            walkDir = (vel.y >= 0) ? STATE_DOWN : STATE_UP;
        } else {
            walkDir = (vel.x >= 0) ? STATE_RIGHT : STATE_LEFT;
        }

        return walkDir;
    }

    // from UnitSprite
    override protected function getMyZOrder (isFlying :Boolean = false) :Number
    {
        // the critter flag overrides any arguments
        return super.getMyZOrder(critter.isFlying);
    }
}
}
