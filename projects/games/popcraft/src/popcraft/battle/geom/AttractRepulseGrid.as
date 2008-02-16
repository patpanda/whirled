package popcraft.battle.geom {
    
import com.threerings.flash.Vector2;
    
public class AttractRepulseGrid extends CollisionGrid
{
    public function AttractRepulseGrid (boardWidth :int, boardHeight :int, cellSize :int, forceQueryRadius :Number)
    {
        super(boardWidth, boardHeight, cellSize);
    }
    
    /** Discover all the forces that apply to an object centered at the given location. */
    public function getForceForLoc (loc :Vector2, forceQueryRadius :Number, ignoreObj :CollisionObject) :Vector2
    {
        // cache some easy-to-compute values, just 'cause ActionScript is so slow
        
        var halfRadius :Number = forceQueryRadius * 0.5;
        var radiusSquared :Number = forceQueryRadius * forceQueryRadius;
        
        // generate coordinates for a rectangular section of our grid to search in
        
        var xMin :int = (loc.x - _halfRadius) * _cellSizeInv;
        var xMax :int = (loc.x + _halfRadius) * _cellSizeInv;
        
        var yMin :int = (loc.y - _halfRadius) * _cellSizeInv;
        var yMax :int = (loc.y + _halfRadius) * _cellSizeInv;
        
        xMin = Math.max(xMin, 0);
        xMax = clamp(xMax, xMin, _numCols - 1);
        
        yMin = Math.max(yMin, 0);
        yMax = clamp(yMax, yMin, _numRows - 1);
        
        var totalForce :Vector2 = new Vector2(0, 0);
        
        var cellLoc :Vector2 = new Vector2();
        
        for (var y :int = yMin; y <= yMax; ++y) {
            
            var rowStart :int = (y * _numCols);
            
            for (var x :int = xMin; x <= xMax; ++x) {
                
                // only consider this cell if it actually intersects
                // the given force query circle
                
                cellLoc.x = (x + 0.5) * _cellSize;
                cellLoc.y = (y + 0.5) * _cellSize;
                
                if (cellLoc.subtractLocal(loc).lengthSquared > radiusSquared) {
                    continue;
                }
                
                var cell :CollisionGridCell = _cells[rowStart + x];
                
                // add the forces of all the units inside the cell
                // @TODO
            }
        }
        
        return totalForce;
    }
    
    public static function clamp (val :Number, min :Number, max :Number) :Number
    {
        val = Math.max(val, min);
        return Math.min(val, max);
    }
    
}

}