package vampire.feeding.client {

import com.threerings.flash.Vector2;
import com.whirled.contrib.simplegame.SimObjectRef;
import com.whirled.contrib.simplegame.resource.SwfResource;
import com.whirled.contrib.simplegame.tasks.*;
import com.whirled.contrib.simplegame.util.*;

import flash.display.DisplayObject;
import flash.display.MovieClip;
import flash.display.Sprite;
import flash.text.TextField;

import vampire.feeding.*;
import vampire.feeding.client.view.SpriteUtil;
import vampire.feeding.client.view.UIBits;

public class Cell extends CollidableObj
{
    public static const STATE_BIRTH :int = 0;
    public static const STATE_NORMAL :int = 1;
    public static const STATE_PREPARING_TO_EXPLODE :int = 2;

    public static function destroyCells (cellType :int = -1) :void
    {
        GameCtx.gameMode.destroyObjectsInGroup(getGroupName(cellType));
    }

    public static function getCellCount (cellType :int = -1) :int
    {
        return GameCtx.gameMode.getObjectRefsInGroup(getGroupName(cellType)).length;
    }

    public static function getCellCollision (obj :CollidableObj, cellType :int = -1) :Cell
    {
        // returns the first cell that collides with the given circle
        var cells :Array = GameCtx.gameMode.getObjectRefsInGroup(getGroupName(cellType));

        for each (var cellRef :SimObjectRef in cells) {
            var cell :Cell = cellRef.object as Cell;
            if (cell != null &&
                cell.canCollide &&
                cell.collidesWith(obj)) {
                return cell;
            }
        }

        return null;
    }

    public function Cell (type :int, beingBorn :Boolean, multiplier :int)
    {
        _radius = Constants.CELL_RADIUS;
        _type = type;
        _multiplier = multiplier;

        _moveCCW = Rand.nextBoolean(Rand.STREAM_GAME);

        _state = STATE_NORMAL;

        if (beingBorn) {
            if (type == Constants.CELL_RED) {
                birthRedCell();
            } else if (type == Constants.CELL_WHITE) {
                birthWhiteCell();
            }
        }

        if (type == Constants.CELL_WHITE) {
            // white cells explode after a bit of time
            var thisCell :Cell = this;
            addTask(new SerialTask(
                new TimedTask(Constants.WHITE_CELL_NORMAL_TIME.next()),
                new FunctionTask(function () :void {
                    _state = STATE_PREPARING_TO_EXPLODE;
                }),
                new TimedTask(Constants.WHITE_CELL_EXPLODE_TIME),
                new FunctionTask(function () :void {
                    GameObjects.createWhiteBurst(thisCell);
                })));
        }

        _sprite = SpriteUtil.createSprite();
        _movie = ClientCtx.instantiateMovieClip("blood", MOVIE_NAMES[type], true, true);
        _sprite.addChild(_movie);

        if (type == Constants.CELL_BONUS) {
            var text :String = "x" + _multiplier;
            var tf :TextField = UIBits.createText(text, 1, 0, 0xffffff);
            tf.x = -tf.width * 0.5;
            tf.y = -tf.height * 0.5;
            _sprite.addChild(tf);
        }

        if (_state == Cell.STATE_BIRTH) {
            // fade in
            this.alpha = 0;
            addTask(new AlphaTask(1, 0.4));
        }
    }

    override public function get displayObject () :DisplayObject
    {
        return _sprite;
    }

    override protected function destroyed () :void
    {
        SwfResource.releaseMovieClip(_movie);
        super.destroyed();
    }

    public function attachToCursor (cursor :PlayerCursor) :void
    {
        _attachedTo = cursor.ref;
        _attachedOffset = _loc.subtract(cursor.loc);
    }

    public function detachFromCursor () :void
    {
        _attachedTo = SimObjectRef.Null();
    }

    protected function birthRedCell () :void
    {
        _state = STATE_BIRTH;

        // When red cells are born, they burst out of the center of the heart
        _loc = Constants.GAME_CTR.clone();

        // fire out of the heart in a random direction
        var angle :Number = Rand.nextNumberRange(0, Math.PI * 2, Rand.STREAM_GAME);
        var distRange :NumRange = Constants.CELL_BIRTH_DISTANCE[Constants.CELL_RED];
        var dist :Number = distRange.next();
        var birthTarget :Vector2 = Vector2.fromAngle(angle, dist).addLocal(Constants.GAME_CTR);

        addTask(new SerialTask(
            LocationTask.CreateEaseOut(birthTarget.x, birthTarget.y, Constants.CELL_BIRTH_TIME),
            new FunctionTask(function () :void {
                _state = STATE_NORMAL;
            })));
    }

    protected function birthWhiteCell () :void
    {
        _state = STATE_BIRTH;

        // pick a random location on the outside of the board
        var angle :Number = Rand.nextNumberRange(0, Math.PI * 2, Rand.STREAM_GAME);
        var distRange :NumRange = Constants.CELL_BIRTH_DISTANCE[Constants.CELL_WHITE];
        var dist :Number = distRange.next();
        _loc = Vector2.fromAngle(angle, dist).addLocal(Constants.GAME_CTR);

        addTask(After(Constants.CELL_BIRTH_TIME,
            new FunctionTask(function () :void {
                _state = STATE_NORMAL;
            })));
    }

    override protected function update (dt :Number) :void
    {
        var cursor :PlayerCursor = _attachedTo.object as PlayerCursor;
        if (cursor != null) {
            _loc.x = cursor.x + _attachedOffset.x;
            _loc.y = cursor.y + _attachedOffset.y;

        } else if (_state == STATE_NORMAL) {
            // move around the heart
            var ctrImpulse :Vector2 = (this.movementType == MOVE_OUTWARDS ?
                _loc.subtract(Constants.GAME_CTR) :
                Constants.GAME_CTR.subtract(_loc));

            ctrImpulse.length = 2;

            var perpImpulse :Vector2 = ctrImpulse.getPerp(_moveCCW);
            perpImpulse.length = 3.5;

            var impulse :Vector2 = ctrImpulse.add(perpImpulse);
            impulse.length = SPEED_BASE * dt;

            _loc.x += impulse.x;
            _loc.y += impulse.y;

            _loc = GameCtx.clampLoc(_loc);
        }

        super.update(dt);

        this.displayObject.x = _loc.x;
        this.displayObject.y = _loc.y;
    }

    override public function getObjectGroup (groupNum :int) :String
    {
        switch (groupNum) {
        case 0:     return getGroupName(_type);
        case 1:     return getGroupName(-1);
        default:    return super.getObjectGroup(groupNum - 2);
        }
    }

    public function get type () :int
    {
        return _type;
    }

    public function get state () :int
    {
        return _state;
    }

    public function get multiplier () :int
    {
        return _multiplier;
    }

    public function get isRedCell () :Boolean
    {
        return _type == Constants.CELL_RED;
    }

    public function get isWhiteCell () :Boolean
    {
        return _type == Constants.CELL_WHITE;
    }

    protected function get canCollide () :Boolean
    {
        return true;
    }

    protected function get movementType () :int
    {
        return (_type == Constants.CELL_WHITE ? MOVE_INWARDS : MOVE_OUTWARDS);
    }

    protected static function getGroupName (cellType :int) :String
    {
        return (cellType < 0 ? "Cell" : "Cell_" + cellType);
    }

    protected var _type :int;
    protected var _state :int;
    protected var _multiplier :int;
    protected var _moveCCW :Boolean;
    protected var _attachedTo :SimObjectRef = SimObjectRef.Null();
    protected var _attachedOffset :Vector2;

    protected var _sprite :Sprite;
    protected var _movie :MovieClip;

    protected static const SPEED_BASE :Number = 5;
    protected static const SPEED_FOLLOW :Number = 7;

    protected static const MOVE_INWARDS :int = 0;
    protected static const MOVE_OUTWARDS :int = 1;

    protected static const MOVIE_NAMES :Array = [ "cell_red", "cell_white", "cell_bonus" ];
}

}