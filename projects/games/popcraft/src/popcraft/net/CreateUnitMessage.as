package popcraft.net {

import com.whirled.contrib.simplegame.net.*;

public class CreateUnitMessage
    implements Message
{
    public var unitType :uint;
    public var owningPlayer :uint;

    public function CreateUnitMessage (unitType :uint, owningPlayer :uint)
    {
        this.unitType = unitType;
        this.owningPlayer = owningPlayer;
    }

    public function get name () :String
    {
        return messageName;
    }

    public function toString () :String
    {
        return "[CreateUnit. playerId: " + owningPlayer + ". unitType: " + unitType + "]";
    }

    public static function createFactory () :MessageFactory
    {
        return new CreateUnitMessageFactory();
    }

    public static function get messageName () :String
    {
        return "CreateUnit";
    }
}

}

import com.whirled.contrib.simplegame.net.*;
import popcraft.net.CreateUnitMessage;
import flash.utils.ByteArray;
import flash.errors.EOFError;
import com.threerings.util.Log;

class CreateUnitMessageFactory
    implements MessageFactory
{
    public function serializeForNetwork (message :Message) :Object
    {
        var msg :CreateUnitMessage = (message as CreateUnitMessage);

        var ba :ByteArray = new ByteArray();
        ba.writeByte(msg.unitType);
        ba.writeByte(msg.owningPlayer);

        return ba;
    }

    public function deserializeFromNetwork (obj :Object) :Message
    {
        var msg :CreateUnitMessage;

        var ba :ByteArray = obj as ByteArray;
        if (null == ba) {
            log.warning("received non-ByteArray message");
        } else {
            try {
                var unitType :int = ba.readByte();
                var owningPlayer :int = ba.readByte();

                msg = new CreateUnitMessage(unitType, owningPlayer);

            } catch (err :EOFError) {
                log.warning("received bad data");
            }
        }

        return msg;
    }

    protected static const log :Log = Log.getLog(CreateUnitMessageFactory);
}

