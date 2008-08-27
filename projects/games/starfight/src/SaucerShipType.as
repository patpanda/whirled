package {

import flash.display.MovieClip;
import flash.media.Sound;
import flash.media.SoundTransform;
import flash.events.Event;

public class SaucerShipType extends ShipType
{
    public var secondaryHitPower :Number = 0.3;
    public var superShotCost :Number = 0.1;

    public var mineFriendly :Class, mineEnemy :Class, mineExplode :Class;
    public var mineSound :Sound, mineExplodeSound :Sound;

    public function SaucerShipType () :void
    {
        name = "Saucer";

        forwardAccel = 60.0;
        backwardAccel = 0.0;
        friction = 0.5;
        velThreshold = 5;
        turnRate = 180;
        turnAccel = 38;
        turnFriction = 0.02;
        turnThreshold = 180;

        hitPower = 0.09;

        primaryShotCost = 0.2;
        primaryPowerRecharge = 6.0;
        primaryShotRecharge = 0.1;
        primaryShotSpeed = 10;
        primaryShotLife = 0.1;
        primaryShotSize = 0.4;

        secondaryShotCost = 0.4;
        secondaryShotRecharge = 3;
        secondaryPowerRecharge = 30;
        secondaryShotLife = 90;
        secondaryShotSize = 0.3;

        armor = 0.8;
        size = 0.9;
    }

    override public function getPrimaryShotCost (ship :ShipSprite) :Number
    {
        return (ship.powerups & ShipSprite.SPREAD_MASK ? superShotCost : primaryShotCost);
    }

    override public function primaryShot (val :Array) :void
    {
        var ship :ShipSprite = AppContext.game.getShip(val[0]);
        if (ship == null) {
            return;
        }
        var ships :Array = AppContext.game.findShips(ship.boardX, ship.boardY, RANGE);

        var sound :Sound = (val[2] == ShotSprite.SUPER) ? supShotSound : shotSound;
        AppContext.game.playSoundAt(sound, ship.boardX, ship.boardY);

        // no one in range so shoot straight
        if (ships.length <= 1) {
            AppContext.game.addShot(new LaserShotSprite(ship.boardX, ship.boardY,
                ship.ship.rotation, RANGE, val[0], hitPower, primaryShotLife, val[1], -1));
            return;
        }

        for each (var tShip :ShipSprite in ships) {
            if (tShip.shipId == ship.shipId) {
                continue;
            }
            var dist :Number = Math.sqrt((tShip.boardX - ship.boardX)*(tShip.boardX-ship.boardX) +
                    (tShip.boardY-ship.boardY)*(tShip.boardY-ship.boardY));
            dist = Math.min(RANGE, dist);
            var angle :Number = Codes.RADS_TO_DEGS *
                    Math.atan2(tShip.boardY - ship.boardY, tShip.boardX - ship.boardX);
            AppContext.game.addShot(new LaserShotSprite(ship.boardX, ship.boardY,
                angle, dist, val[0], hitPower, primaryShotLife, val[1], tShip.shipId));
        }
    }

    override public function primaryShotMessage (ship :ShipSprite) :void
    {
        var type :int = (ship.powerups & ShipSprite.SPREAD_MASK) ?
            ShotSprite.SUPER : ShotSprite.NORMAL;

        var args :Array = new Array(3);
        args[0] = ship.shipId;
        args[1] = ship.shipType;
        args[2] = type;
        AppContext.game.fireShot(args);
    }

    override public function secondaryShotMessage (ship :ShipSprite) :Boolean
    {
        var args :Array = new Array(5);
        args[0] = ship.shipId;
        args[1] = ship.shipType;
        args[2] = Math.round(ship.boardX);
        args[3] = Math.round(ship.boardY);
        args[4] = secondaryHitPower;

        AppContext.game.sendMessage("secondary", args);
        return true;
    }

    override public function secondaryShot (val :Array) :void
    {
        AppContext.game.addMine(val[0], val[2], val[3], val[1], val[4]);
        AppContext.game.playSoundAt(mineSound, val[2], val[3]);
    }

    override protected function swfAsset () :Class
    {
        return SHIP;
    }

    override protected function successHandler () :void
    {
        super.successHandler();
        mineFriendly = getLoadedClass("mine_friendly");
        mineEnemy = getLoadedClass("mine_enemy");
        mineExplode = getLoadedClass("mine_explode");
        mineSound = Sound(new (getLoadedClass("mine_lay.wav"))());
        mineExplodeSound = Sound(new (getLoadedClass("mine_explode.wav"))());
    }

    protected static var RANGE :Number = 7;
    protected static var TARGET :Number = 12;

    [Embed(source="../rsrc/ships/xyru.swf", mimeType="application/octet-stream")]
    protected static var SHIP :Class;
}
}
