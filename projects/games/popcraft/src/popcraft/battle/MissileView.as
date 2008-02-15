package popcraft.battle {
    
import com.threerings.flash.Vector2;
import com.whirled.contrib.core.objects.SceneObject;
import com.whirled.contrib.core.tasks.*;

import flash.display.DisplayObject;
import flash.display.Shape;

import popcraft.*;

public class MissileView extends SceneObject
{
    public function MissileView (startLoc :Vector2, targetUnitId :uint, travelTime :Number)
    {
        _startLoc = startLoc.clone();
        _targetUnitId = targetUnitId;
        _travelTime = travelTime;
    }
    
    override public function get displayObject () :DisplayObject
    {
        return _shape;
    }
    
    override protected function update (dt :Number) :void
    {
        if (_done) {
            return;
        }
        
        var targetUnit :Unit = (GameMode.getNetObject(_targetUnitId) as Unit);
        
        if (null == targetUnit) {
            // our target's gone. die.
            this.destroySelf();
            return;
        }
        
        _elapsedTime += dt;
        _elapsedTime = Math.min(_elapsedTime, _travelTime);
        
        // draw a line from the start location to the missile's current location
        var drawTo :Vector2 = targetUnit.unitLoc.subtract(_startLoc).scaleLocal(_elapsedTime / _travelTime).addLocal(_startLoc);
        
        _shape.graphics.clear();
        _shape.graphics.lineStyle(1, COLOR);
        _shape.graphics.moveTo(_startLoc.x, _startLoc.y);
        _shape.graphics.lineTo(drawTo.x, drawTo.y);
        
        if (_elapsedTime == _travelTime) {
            
            // fade out and die
            this.addTask(new SerialTask(
                new AlphaTask(0, FADE_TIME),
                new SelfDestructTask()));
                
            _done = true;
        }
        
    }
    
    protected var _startLoc :Vector2;
    protected var _targetUnitId :uint;
    
    protected var _direction :Vector2; // unit vector
    
    protected var _totalDistance :Number;
    
    protected var _elapsedTime :Number = 0;
    protected var _travelTime :Number;
    
    protected var _done :Boolean;
    
    protected var _shape :Shape = new Shape();
    
    protected static const COLOR :uint = 0x000000;
    protected static const FADE_TIME :Number = 0.25;
    
}

}