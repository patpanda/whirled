package popcraft.battle {

import com.whirled.contrib.core.*;
import com.whirled.contrib.core.objects.*;
import com.whirled.contrib.core.resource.*;
import com.whirled.contrib.core.tasks.*;
import com.whirled.contrib.core.util.*;

import popcraft.*;
import popcraft.battle.ai.*;
import popcraft.battle.geom.CollisionGrid;
import popcraft.util.*;

public class CreatureUnit extends Unit
{
    public static const GROUP_NAME :String = "CreatureUnit";

    public function CreatureUnit (unitType :uint, owningPlayerId :uint, collisionGrid :CollisionGrid)
    {
        super(unitType, owningPlayerId, collisionGrid);

        // start at our owning player's base's spawn loc
        var spawnLoc :Vector2 = GameMode.instance.getPlayerBase(_owningPlayerId).unitSpawnLoc;
        _sprite.x = spawnLoc.x;
        _sprite.y = spawnLoc.y;

    }
    
    public function setMovementDestination (dest :Vector2) :void
    {
        _destination = dest.clone();
    }
    
    public function stopMoving () :void
    {
        _destination = null;
    }
    
    public function get isMoving () :Boolean
    {
        return (_destination != null);
    }
    
    protected function handleMove (dt :Number) :void
    {
        if (this.isMoving) {
            var curLoc :Vector2 = new Vector2(this.x, this.y);
        
            // are we there yet?
            if (curLoc.similar(_destination, MOVEMENT_EPSILON)) {
                this.stopMoving();
            }
            
            var nextLoc :Vector2 = _destination.getSubtract(curLoc);
            
            var remainingDistance :Number = nextLoc.normalizeAndGetLength();
            
            // don't overshoot the destination
            var distance :Number = Math.min(this.unitData.baseMoveSpeed * dt, remainingDistance);
            
            // calculate our next location
            nextLoc.scale(distance);
            nextLoc.add(curLoc);
            
            // @TODO - collision checking goes here
            
            this.x = nextLoc.x;
            this.y = nextLoc.y;
        }
    }

    // from AppObject
    override public function get objectGroups () :Array
    {
        // every CreatureUnit is in the CreatureUnit.GROUP_NAME group
        if (null == g_groups) {
            // @TODO: make inherited groups easier to work with
            g_groups = new Array();
            g_groups.push(Unit.GROUP_NAME);
            g_groups.push(GROUP_NAME);
        }

        return g_groups;
    }

    // returns an enemy base.
    // @TODO: make this work with multiple bases and destroyed bases
    public function findEnemyBaseToAttack () :uint
    {
        var game :GameMode = GameMode.instance;
        
        var enemyBaseId :uint = 0;
        
        if (game.numPlayers > 1) {
            var enemyPlayerId :uint = game.getRandomEnemyPlayerId(_owningPlayerId);
            enemyBaseId = game.getPlayerBase(enemyPlayerId).id;
        }

        return enemyBaseId;
    }

    protected function get aiRoot () :AITask
    {
        return null;
    }

    override protected function update (dt :Number) :void
    {
        this.stopMoving();
        
        var aiRoot :AITask = this.aiRoot;
        if (null != aiRoot) {
            aiRoot.update(dt, this);
        }
        
        this.handleMove(dt);
        
        super.update(dt);
    }
    
    protected var _destination :Vector2 = null;
    
    protected static const MOVEMENT_EPSILON :Number = 0.01;

    protected static var g_groups :Array;
}

}
