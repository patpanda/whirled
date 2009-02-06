package bloodbloom.client {

import bloodbloom.*;

import com.threerings.flash.Vector2;

public class PlayerCursor extends CollidableObj
{
    public function PlayerCursor ()
    {
        super(Constants.CURSOR_RADIUS);
    }

    public function get moveTarget () :Vector2
    {
        return _moveTarget;
    }

    public function set moveTarget (val :Vector2) :void
    {
        _moveTarget = val;
    }

    public function getNextLoc (curLoc :Vector2, dt :Number) :Vector2
    {
        if (dt <= 0 || curLoc.similar(_moveTarget, 0.5)) {
            return curLoc.clone();
        }

        var newLoc :Vector2 = _moveTarget.subtract(curLoc);
        var targetDist :Number = newLoc.normalizeLocalAndGetLength();
        var moveDist :Number = this.speed * dt;
        newLoc.scaleLocal(Math.min(targetDist, moveDist));
        newLoc.addLocal(curLoc);

        return GameCtx.clampLoc(newLoc);
    }

    override protected function update (dt :Number) :void
    {
        super.update(dt);
        _loc = getNextLoc(_loc, dt);
    }

    protected function get speed () :Number
    {
        return 0;
    }

    protected var _moveTarget :Vector2 = new Vector2();
}

}
