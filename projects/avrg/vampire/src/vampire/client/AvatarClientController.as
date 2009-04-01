package vampire.client
{
    import com.threerings.flash.MathUtil;
    import com.threerings.flash.Vector2;
    import com.threerings.util.Log;
    import com.whirled.EntityControl;
    import com.whirled.avrg.AVRGameAvatar;
    import com.whirled.avrg.AVRGameControl;
    import com.whirled.avrg.AVRGameRoomEvent;
    import com.whirled.contrib.simplegame.ObjectMessage;
    import com.whirled.contrib.simplegame.SimObject;
    import com.whirled.contrib.simplegame.objects.SimpleTimer;
    import com.whirled.net.MessageReceivedEvent;

    import vampire.avatar.AvatarEndMovementNotifier;
    import vampire.data.VConstants;
    import vampire.net.messages.MovePredIntoPositionMsg;
    import vampire.net.messages.PlayerArrivedAtLocationMsg;


/**
 * The avatar
 */
public class AvatarClientController extends SimObject
{
    public function AvatarClientController (ctrl :AVRGameControl)
    {
        _ctrl = ctrl;
    }

    override public function get objectName () :String
    {
        return NAME;
    }

    override protected function addedToDB () :void
    {
        //If the avatar is changed, reset the callbacks.
        registerListener(_ctrl.room, AVRGameRoomEvent.AVATAR_CHANGED, handleAvatarChanged);
        //If we start moving, and we are in bared mode, change to default mode.
        registerListener(_ctrl.room, AVRGameRoomEvent.PLAYER_MOVED, handlePlayerMoved);
        registerListener(_ctrl.player, MessageReceivedEvent.MESSAGE_RECEIVED,
            handleMessageReceived);

        resetAvatarCallbackFunctions();
    }


    protected function get ourEntityId () :String
    {
        for each(var entityId :String in _ctrl.room.getEntityIds(EntityControl.TYPE_AVATAR)) {
            var entityUserId :int = int(_ctrl.room.getEntityProperty(EntityControl.PROP_MEMBER_ID, entityId));
            if(entityUserId == _ctrl.player.getPlayerId()) {
                return entityId;
            }
        }
        return null;
    }

    override protected function destroyed () :void
    {
        super.destroyed();
        //I don't know how the garbage collecter works with these objects,
        //so just to make sure, set our callback on the avatar to null
        if (_ctrl != null && _ctrl.isConnected()) {
            var setAvatarArrivedCallback :Function = _ctrl.room.getEntityProperty(
                AvatarEndMovementNotifier.ENTITY_PROPERTY_SET_AVATAR_ARRIVED_CALLBACK, ClientContext.ourEntityId) as Function;

            if(setAvatarArrivedCallback != null) {
                setAvatarArrivedCallback(null);
            }
        }
    }


    protected function handleMessageReceived (e :MessageReceivedEvent) :void
    {
        //After feeding, our avatar moves a little forward and closer to the screen,
        //so as not to be hidden if the avatars are similar.
        if (e.name == VConstants.NAMED_EVENT_MOVE_PREDATOR_AFTER_FEEDING) {

            var moveTimer :SimpleTimer = new SimpleTimer(2.5, function() :void {

                var location :Array = ClientContext.model.location;
                var hotspot :Array = ClientContext.model.hotspot;
                if (location != null && hotspot != null) {

                    var xDirection :Number = location[3] > 0 && location[3] <= 180 ? 1 : -1;
                    var widthLogical :Number = hotspot[0]/_ctrl.local.getRoomBounds()[0];

                    var xDistance :Number = xDirection * widthLogical / 3;

                    _ctrl.player.setAvatarLocation(
                        MathUtil.clamp(location[0] + xDistance, 0, 1),
                        location[1],
                        MathUtil.clamp(location[2] - 0.1, 0, 1), location[3]);
                }
            }, false);
            db.addObject(moveTimer);
        }
        //Before we start feeding, we move our avatar to stand directly behind the
        //target avatar.
        else if (e.name == MovePredIntoPositionMsg.NAME) {

            function convertStandardRads2GameDegrees(rad :Number) :Number
            {
                return MathUtil.toDegrees(MathUtil.normalizeRadians(rad + Math.PI / 2));
            }


            var movemsg :MovePredIntoPositionMsg = ClientContext.msg.deserializeMessage(
                e.name, e.value) as MovePredIntoPositionMsg;

            //If we are the first predator, we go directly behind the prey
            //Otherwise, take a a place
            var targetLocation :Array = movemsg.preyLocation;//ClientContext.model.getLocation(movemsg.preyId);
            var avatar :AVRGameAvatar = ClientContext.model.avatar;

            var targetX :Number;
            var targetY :Number;
            var targetZ :Number;

            //TODO: add the hotspot width /2, then test.
            var hotspot :Array = ClientContext.model.hotspot;
            var widthLogical :Number = hotspot[0]/_ctrl.local.getRoomBounds()[0];

            var distanceLogicalAwayFromPrey :Number = widthLogical / 3;




            var angleRadians :Number = new Vector2(targetLocation[0] - avatar.x,
                targetLocation[2] - avatar.z).angle;
            var degs :Number = convertStandardRads2GameDegrees(angleRadians);

            targetX = targetLocation[0] +
                VConstants.PREDATOR_LOCATIONS_RELATIVE_TO_PREY[movemsg.predIndex][0] *
                distanceLogicalAwayFromPrey;
            targetY = targetLocation[1] +
                VConstants.PREDATOR_LOCATIONS_RELATIVE_TO_PREY[movemsg.predIndex][1] *
                distanceLogicalAwayFromPrey;
            targetZ = targetLocation[2] +
                VConstants.PREDATOR_LOCATIONS_RELATIVE_TO_PREY[movemsg.predIndex][2] *
                distanceLogicalAwayFromPrey;

                ClientContext.ctrl.player.setAvatarLocation(targetX, targetY, targetZ, degs);
        }



    }

    protected function handlePlayerMoved (e :AVRGameRoomEvent) :void
    {
        var playerMovedId :int = int(e.value);
        if(playerMovedId == _ctrl.player.getPlayerId()) {
            if(ClientContext.model.state == VConstants.AVATAR_STATE_BARED) {
                ClientContext.controller.handleChangeState(VConstants.AVATAR_STATE_DEFAULT);
                ClientContext.model.setAvatarState(VConstants.AVATAR_STATE_DEFAULT);
            }
        }
    }

    protected function handleAvatarChanged (e :AVRGameRoomEvent) :void
    {
        checkForAvatarSwitch(e);
        checkForBaredModeViaAvatarMenu(e);
    }

    /**
    * If we change avatars, make sure to update the movement notification function
    */
    protected function checkForAvatarSwitch (e :AVRGameRoomEvent) :void
    {
        var playerAvatarChangedId :int = int(e.value);

        //We are care about our own avatar
        if(playerAvatarChangedId != _ctrl.player.getPlayerId()) {
            return;
        }

        //Get our entityId
        var currentEntityId :String;

        for each(var entityId :String in _ctrl.room.getEntityIds(EntityControl.TYPE_AVATAR)) {

            var entityUserId :int = int(_ctrl.room.getEntityProperty(EntityControl.PROP_MEMBER_ID, entityId));

            if(entityUserId == _ctrl.player.getPlayerId()) {
                currentEntityId = entityId;
                break;
            }

        }

        if(currentEntityId != _currentEntityId) {

            //Change our id for future reference.
            _currentEntityId = currentEntityId;

            //Connect to the new avatar
            resetAvatarCallbackFunctions();
        }

    }
    /**
    * We can go into 'bared' mode via the game HUD menu, or via the regular avatar menu.
    * Therefore, we must listen to changes in the avatar and check if we have gone into
    * bared mode.
    */
    protected function checkForBaredModeViaAvatarMenu (e :AVRGameRoomEvent) :void
    {
        var playerAvatarChangedId :int = int(e.value);

        //We are only allowed to change our own avatar.
        if(playerAvatarChangedId != _ctrl.player.getPlayerId()) {
            return;
        }

        //Do as if we have pushed the 'Bared" button.
        var avatar :AVRGameAvatar = _ctrl.room.getAvatarInfo(playerAvatarChangedId);
        if(avatar != null) {

            var isBared :Boolean = ClientContext.model.state == VConstants.PLAYER_STATE_BARED ||
                ClientContext.model.state == VConstants.PLAYER_STATE_FEEDING_PREY;
            //If we change our avatar to bared, but we are not in the bared player state.
            if(!isBared && avatar.state == VConstants.AVATAR_STATE_BARED) {
                ClientContext.controller.handleChangeState(VConstants.PLAYER_STATE_BARED);
            }
        }
    }

    protected function resetAvatarCallbackFunctions () :void
    {
        //Let's hear when the avatar arrived at a destination
        var setAvatarArrivedCallback :Function = _ctrl.room.getEntityProperty(
            AvatarEndMovementNotifier.ENTITY_PROPERTY_SET_AVATAR_ARRIVED_CALLBACK, ClientContext.ourEntityId) as Function;

        if(setAvatarArrivedCallback != null) {
            setAvatarArrivedCallback(avatarArrivedAtDestination);
        }
        else {
            log.error("The avatar did not provide the property=" +
                AvatarEndMovementNotifier.ENTITY_PROPERTY_SET_AVATAR_ARRIVED_CALLBACK);

            var t :SimpleTimer = new SimpleTimer(1, function () :void {
                resetAvatarCallbackFunctions();
            });
            db.addObject(t);
        }
    }

    protected function avatarArrivedAtDestination (playerId :int, location :Array) :void
    {
        if (!_ctrl.isConnected()) {
            return;
        }

        //If our player moved, inform the server.
        if (playerId == _ctrl.player.getPlayerId()) {
            var locationFromProps :Array = ClientContext.model.location;
            _ctrl.agent.sendMessage(PlayerArrivedAtLocationMsg.NAME,
                new PlayerArrivedAtLocationMsg(_ctrl.player.getPlayerId()).toBytes());

            //And if this is our avatar, and we have a target to stand behind,
            //make sure we are in the same orientation.
            if(_avatarIdToStandBehind != 0) {

                var targetEntityId :String = getEntityId(_avatarIdToStandBehind);

                var targetLocation :Array = _ctrl.room.getEntityProperty(
                    EntityControl.PROP_LOCATION_LOGICAL, targetEntityId) as Array;

                //If we are not the first predator, standing slightly behind the target, make
                //sure we are facing the same orientation as th target.  If we aren't the first
                //pred, face the target
                var distance :Number = MathUtil.distance(location[0], location[2], targetLocation[0], targetLocation[2]);
                if(distance <= MINIMUM_FIRST_TARGET_DISTANCE) {
                    var targetorientation :Number = Number(_ctrl.room.getEntityProperty(
                        EntityControl.PROP_ORIENTATION, targetEntityId));
                    _ctrl.player.setAvatarLocation(location[0], location[1], location[2], targetorientation);
                }
                else {
                    var faceTargetOrientation :Number = targetLocation[0] < location[0] ? 270 : 90;
                    _ctrl.player.setAvatarLocation(location[0], location[1], location[2], faceTargetOrientation);
                }

                //Reset our target
                _avatarIdToStandBehind = 0;
            }
        }

    }

    public function getEntityId (playerId :int) :String
    {
        for each(var entityId :String in _ctrl.room.getEntityIds(EntityControl.TYPE_AVATAR)) {

            var entityUserId :int = int(_ctrl.room.getEntityProperty(EntityControl.PROP_MEMBER_ID, entityId));

            if(entityUserId == playerId) {
                return entityId;
            }

        }
        return null;
    }

    override protected function receiveMessage (msg:ObjectMessage) :void
    {
        if (msg.name == GAME_MESSAGE_TARGETID) {
            _avatarIdToStandBehind = int(msg.data);
        }
    }

    protected var _ctrl :AVRGameControl;
    protected var _currentEntityId :String;

    /**
    * When the avatar moves to stand behind a target, upon arrival the avatar should stand
    * in the same orientation.
    */
    protected var _avatarIdToStandBehind :int;
    protected static const log :Log = Log.getLog(AvatarClientController);

    public static const NAME :String = "AvatarClientController";
    public static const GAME_MESSAGE_TARGETID :String = "GameMessage: TargetId";

    /**
    * When our avatar arrives at it's destination, and it has a target, check how far away
    * we are from the target location.  If we are below this distance, we must be the first
    * predator (standing directly behind the target).  If we are greater than this distance,
    * we must have our orientation changed to face the target.
    */
    public static const MINIMUM_FIRST_TARGET_DISTANCE :Number = MathUtil.distance(0, 0, VConstants.FEEDING_LOGICAL_X_OFFSET, VConstants.FEEDING_LOGICAL_Z_OFFSET) + 0.01;

}
}