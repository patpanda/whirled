package {

public class Codes
{
    public static const GAME_WIDTH :int = 700;
    public static const GAME_HEIGHT :int = 500;

    public static const PIXELS_PER_TILE :int = 20;
    public static const BG_PIXELS_PER_TILE :int = 5;

    public static const RADS_TO_DEGS :Number = 180.0/Math.PI;
    public static const DEGS_TO_RADS :Number = Math.PI/180.0;

    /** Color constants. */
    public static const BLACK :uint = uint(0x000000);
    public static const CYAN :uint = uint(0x00FFFF);
    public static const YELLOW :uint = uint(0xFFFF00);
    public static const RED :uint = uint(0xFF0000);
    public static const GREEN :uint = uint(0x00FF00);

    /** millis between screen refreshes. */
    public static const REFRESH_RATE :int = 50;

    /** How often we send updates to the server. */
    public static const FRAMES_PER_UPDATE :int = 3;
    public static const TIME_PER_UPDATE :int = 125;

    /** Game states. */
    public static const PRE_ROUND :int = 1;
    public static const IN_ROUND :int = 2;
    public static const POST_ROUND :int = 3;

    public static const SHIP_TYPE_WASP :WaspShipType = new WaspShipType();
    public static const SHIP_TYPE_RHINO :RhinoShipType = new RhinoShipType();
    public static const SHIP_TYPE_SAUCER :SaucerShipType = new SaucerShipType();
    public static const SHIP_TYPE_RAPTOR :RaptorShipType = new RaptorShipType();

    /** The different available types of ships. */
    public static const SHIP_TYPE_CLASSES :Array = [
        SHIP_TYPE_WASP,
        SHIP_TYPE_RHINO,
        SHIP_TYPE_SAUCER,
        SHIP_TYPE_RAPTOR,
    ];

    public static function getShipType (index :int) :ShipType
    {
        return (index >= 0 && index < SHIP_TYPE_CLASSES.length ? SHIP_TYPE_CLASSES[index] : null);
    }
}
}
