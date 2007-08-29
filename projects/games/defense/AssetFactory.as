package {

import mx.core.IFlexDisplayObject;

public class AssetFactory
{
    /** Returns a new shape for the specified tower. */
    public static function makeTower (type :int) :IFlexDisplayObject
    {
        switch (type) {
        case Tower.TYPE_SIMPLE: return IFlexDisplayObject(new _defaultTower());
        default:
            throw new Error("Unknown tower type: " + type);
            return null;
        }
    }
    
    [Embed(source="rsrc/tower.png")]
    private static const _defaultTower :Class;

    /** Returns the backdrop image. */
    public static function makeBackground () :IFlexDisplayObject
    {
        return IFlexDisplayObject(new _bg());
    }

    [Embed(source="rsrc/background.png")]
    private static const _bg :Class;
}
}
