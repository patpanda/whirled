package popcraft {

import popcraft.battle.*;

import core.util.*;

import com.threerings.util.Assert;
import flash.geom.Point;

public class Constants
{
    public static const PLAYER_COLORS :Array = [
       uint(0xFF0000),
       uint(0x9FBCFF),
       uint(0x51FF7E),
       uint(0xFFE75F)
    ];

    /* Images */
    [Embed(source="../../rsrc/melee.png")]
    public static const IMAGE_MELEE :Class;

    [Embed(source="../../rsrc/ranged.png")]
    public static const IMAGE_RANGED :Class;

    [Embed(source="../../rsrc/base.png")]
    public static const IMAGE_BASE :Class;

    /* Puzzle stuff */
    public static const PIECE_CLEAR_TIMER_LENGTH :Number = 0.75;

    public static const MIN_GROUP_SIZE :int = 1; // no min group size right now

    public static const PUZZLE_COLS :int = 5;
    public static const PUZZLE_ROWS :int = 8;
    public static const PUZZLE_TILE_SIZE :int = 40;

    public static const CLEAR_VALUE_TABLE :IntValueTable =
        new IntValueTable( [-20, -10, 10, 20, 30, 20] );
             // group size:   1,   2,  3,  4,  5,  6+ = 50, 70, 90, ...

    /* Battle stuff */
    public static const BATTLE_COLS :int = 15;
    public static const BATTLE_ROWS :int = 15;
    public static const BATTLE_TILE_SIZE :int = 32;
    public static const BASE_ATTACK_RADIUS :int = 80; // max distance from base that base attacks can occur from

    /* Damage types */
    public static const DAMAGE_TYPE_MELEE :uint = 0;
    public static const DAMAGE_TYPE_PROJECTILE :uint = 1;
    public static const DAMAGE_TYPE_BASE :uint = 2; // bases damage units that attack them

    /* Resource types */

    // wow, I miss enums
    public static const RESOURCE_WOOD :uint = 0;
    public static const RESOURCE_GOLD :uint = 1;
    public static const RESOURCE_MANA :uint = 2;
    public static const RESOURCE_MORALE :uint = 3;
    public static const RESOURCE__LIMIT :uint = 4;

    public static const RESOURCE_TYPES :Array = [
        new ResourceType("brown", 0x885300),
        new ResourceType("gold", 0xF8F500),
        new ResourceType("blue", 0x00F8EF),
        new ResourceType("pink", 0xFF77BA)
    ];

    public static function getResource (type :uint) :ResourceType {
        Assert.isTrue(type < RESOURCE_TYPES.length);
        return (RESOURCE_TYPES[type] as ResourceType);
    }

    /* Units */

    public static const UNIT_TYPE_MELEE :uint = 0;
    public static const UNIT_TYPE_RANGED :uint = 1;

    public static const UNIT_TYPE__CREATURE_LIMIT :uint = 2;

    public static const UNIT_TYPE_BASE :uint = 2;

    public static const UNIT_CLASS_GROUND :uint = (1 << 0);
    public static const UNIT_CLASS_AIR :uint = (1 << 1);

    public static const UNIT_DATA :Array = [

            new UnitData (
                "melee"                     // name
                , [5,   0,  0,    0]        // resource costs (brown, gold, blue, pink)
                , IMAGE_MELEE               // image
                , 30, new IntRange(5, 25)   // wanderEvery, wanderRange
                , 64                        // move speed (pixels/second)
                , 100                       // health
                , new UnitArmor( [DAMAGE_TYPE_MELEE, 0.8, DAMAGE_TYPE_PROJECTILE, 0.7, DAMAGE_TYPE_BASE, 1] )   // armor
            )

            ,

            new UnitData (
                "ranged"                    // name
                , [0,   5,  0,    0]        // resource costs (brown, gold, blue, pink)
                , IMAGE_RANGED              // image
                , -1, new IntRange(0, 0)    // wanderEvery, wanderRange
                , 40                        // move speed (pixels/second)
                , 100                       // health
                , new UnitArmor( [DAMAGE_TYPE_MELEE, 1, DAMAGE_TYPE_PROJECTILE, 1, DAMAGE_TYPE_BASE, 1] )   // armor
            )

            ,

            // non-creature units must come after creature units

            new UnitData (
                "base"                      // name
                , [0,   0,  0,    0]        // resource costs (brown, gold, blue, pink)
                , IMAGE_BASE                // image
                , -1, new IntRange(0, 0)    // wanderEvery, wanderRange
                , 0                         // move speed (pixels/second)
                , 100                       // health
                , new UnitArmor( [DAMAGE_TYPE_MELEE, 1, DAMAGE_TYPE_PROJECTILE, 1, DAMAGE_TYPE_BASE, 1] )   // armor
            )
    ];

    /* Screen layout */
    public static const RESOURCE_DISPLAY_LOC :Point = new Point(0, 0);
    public static const PUZZLE_BOARD_LOC :Point = new Point(0, 50);
    public static const BATTLE_BOARD_LOC :Point = new Point(220, 20);

    public static const UNIT_BUTTON_LOCS :Array = [
        new Point(0, 400),
        new Point(50, 400)
    ];

    public static function getPlayerBaseLocations (numPlayers :uint) :Array // of Vector2s
    {
        switch (numPlayers) {
        case 2:
            return [ new Vector2(28, 240), new Vector2(452, 240) ];

        default:
            return [];
        }
    }
}

}
