package vampire.client
{
import com.threerings.flash.MathUtil;
import com.threerings.flash.SimpleTextButton;
import com.threerings.util.ArrayUtil;
import com.threerings.util.ClassUtil;
import com.threerings.util.Command;
import com.threerings.util.Log;
import com.whirled.avrg.AVRGameAvatar;
import com.whirled.avrg.AVRGameRoomEvent;
import com.whirled.contrib.simplegame.AppMode;
import com.whirled.contrib.simplegame.objects.SimpleTimer;
import com.whirled.net.MessageReceivedEvent;

import flash.events.MouseEvent;

import vampire.avatar.AvatarGameBridge;
import vampire.avatar.VampireAvatarHUDOverlay;
import vampire.client.events.LineageUpdatedEvent;
import vampire.client.events.PlayerArrivedAtLocationEvent;
import vampire.data.Lineage;
import vampire.data.VConstants;
import vampire.feeding.FeedingClient;
import vampire.net.messages.FeedRequestMsg;
import vampire.net.messages.NonPlayerIdsInRoomMsg;

public class MainGameMode extends AppMode
{
    public function MainGameMode()
    {
        super();
    }

    override protected function enter() :void
    {
        modeSprite.visible = true;
        log.debug("Starting " + ClassUtil.tinyClassName( this ));

        //Add intro panel if we're a new player
        if( ClientContext.isNewPlayer) {
            ClientContext.controller.handleShowIntro("intro");
            ClientContext.isNewPlayer = false;
        }
        else {
            log.debug("We're NOT a new player");
        }

        //Let's hear when the avatar arrived at a destination
//


    }

    protected function updateNonPlayerIds(...ignored ) :void
    {
        if( _currentNonPlayerIds == null ) {
            _currentNonPlayerIds = new Array();
        }

        var npIds :Array = ClientContext.getNonPlayerIds();
        npIds.sort();

        var roomId :int = ClientContext.ctrl.room.getRoomId();

        if( !ArrayUtil.equals( _currentNonPlayerIds, npIds ) ) {
            var msg :NonPlayerIdsInRoomMsg = new NonPlayerIdsInRoomMsg(
                ClientContext.ourPlayerId, npIds, roomId );
    //        log.debug("Sending " + msg);
            ClientContext.ctrl.agent.sendMessage( msg.name, msg.toBytes() );
            _currentNonPlayerIds = npIds;
        }



//        trace( ClientContext.ourPlayerId + " our inviter=" + ClientContext.ctrl.local.getInviterMemberId());
    }

    override protected function setup() :void
    {
        //Set the game mode where all game objects are added.
        ClientContext.gameMode = this;

        modeSprite.visible = false;
        super.setup();

        ClientContext.model = new GameModel();
        addObject( ClientContext.model );
        ClientContext.model.setup();

        if( VConstants.LOCAL_DEBUG_MODE) {

            var lineage :Lineage = new Lineage();
                lineage.setPlayerSire(1, 2);
                lineage.setPlayerSire(3, 1);
                lineage.setPlayerSire(4, 1);
                lineage.setPlayerSire(5, 1);
                lineage.setPlayerSire(6, 5);
                lineage.setPlayerSire(7, 6);
                lineage.setPlayerSire(8, 6);
                lineage.setPlayerSire(9, 1);
                lineage.setPlayerSire(10, 1);
                lineage.setPlayerSire(11, 1);
                lineage.setPlayerSire(12, 1);
                lineage.setPlayerSire(13, 1);
                lineage.setPlayerSire(14, 1);
            var msg :LineageUpdatedEvent = new LineageUpdatedEvent(lineage, ClientContext.ourPlayerId);
            ClientContext.model.lineage = lineage;
            ClientContext.model.dispatchEvent( msg );
        }



        //If this player hasn't played before, automatically show the help.
        if( ClientContext.model.isNewPlayer() ) {
//            addObject(  new HelpPopup(), modeSprite );
        }

//        _feedingGameDraggableSprite = new DraggableSceneObject(ClientContext.ctrl);
//        modeSprite.addChild( _feedingGameDraggableSprite.displayObject );

        //If we start moving, and we are in bared mode, change to default mode.
        registerListener(ClientContext.ctrl.room, AVRGameRoomEvent.PLAYER_MOVED, handlePlayerMoved);

        //If we go into bared mode via the avatar menu, update the game too.
        registerListener(ClientContext.ctrl.room,
            AVRGameRoomEvent.AVATAR_CHANGED, handleAvatarChanged);

        registerListener(ClientContext.model,
            PlayerArrivedAtLocationEvent.PLAYER_ARRIVED, handlePlayerArrivedAtLocation);

        //Move our avatar a while after feeding
//        registerListener(ClientContext.ctrl.player, MessageReceivedEvent.MESSAGE_RECEIVED, function(
//            e :MessageReceivedEvent) :void {
//
//
//            });

        //If the game server says no more feeding, leave predator action



        FeedingClient.init( modeSprite, ClientContext.ctrl );

        _events.registerListener(ClientContext.ctrl.player, MessageReceivedEvent.MESSAGE_RECEIVED,
            handleMessageReceived);

        //Create the overlay for individual avatars
        ClientContext.avatarOverlay = new VampireAvatarHUDOverlay( ClientContext.ctrl );
        addSceneObject( ClientContext.avatarOverlay, modeSprite );
        //And pass to the server player arrival events, if we are moving to feed.
        //This lets the server know that we have moved into position, and the game can
//        //start.
//        registerListener( ClientContext.avatarOverlay, PlayerArrivedAtLocationEvent.PLAYER_ARRIVED,
//            function(...ignored) :void {
//                if( ClientContext.model.state == VConstants.GAME_MODE_MOVING_TO_FEED_ON_NON_PLAYER ||
//                    ClientContext.model.state == VConstants.AVATAR_STATE_MOVING_TO_FEED ) {
//
//                        ClientContext.ctrl.agent.sendMessage(
//                            PlayerArrivedAtLocationEvent.PLAYER_ARRIVED );
//                    }
//            });

        _hud = new HUD();
        addSceneObject( _hud, modeSprite );
        ClientContext.hud = _hud;


        trace(ClientContext.ourPlayerId + " setting avatar state from game beginning");
        ClientContext.model.setAvatarState( VConstants.AVATAR_STATE_DEFAULT );


        //Every X seconds, check the non-player ids, updating the server if changed.
        var nonPlayerIdTimer :SimpleTimer = new SimpleTimer(2, updateNonPlayerIds, true, "npTimer");
        addObject( nonPlayerIdTimer );





        //Add a debug panel for admins
        if( ClientContext.isAdmin(ClientContext.ourPlayerId) || VConstants.LOCAL_DEBUG_MODE ) {
            var debug :SimpleTextButton = new SimpleTextButton("debug");
            Command.bind( debug, MouseEvent.CLICK, VampireController.SHOW_DEBUG );
            modeSprite.addChild( debug );
        }


    }

    protected function handlePlayerMoved( e :AVRGameRoomEvent ) :void
    {
        var playerMovedId :int = int( e.value );
        if( playerMovedId == ClientContext.ourPlayerId) {
            if( ClientContext.model.state == VConstants.AVATAR_STATE_BARED ) {
                ClientContext.controller.handleChangeState( VConstants.AVATAR_STATE_DEFAULT );
                ClientContext.model.setAvatarState( VConstants.AVATAR_STATE_DEFAULT );
            }
        }
    }

    protected function handlePlayerArrivedAtLocation( e :PlayerArrivedAtLocationEvent ) :void
    {
        trace("MainGameMode, handlePlayerArrivedAtLocation");
        if( ClientContext.model.state == VConstants.PLAYER_STATE_MOVING_TO_FEED ) {
            trace("Sending player arrived event");
            ClientContext.ctrl.agent.sendMessage( PlayerArrivedAtLocationEvent.PLAYER_ARRIVED );
        }
    }

    /**
    * We can go into 'bared' mode via the game HUD menu, or via the regular avatar menu.
    * Therefore, we must listen to changes in the avatar and check if we have gone into
    * bared mode.
    */
    protected function handleAvatarChanged( e :AVRGameRoomEvent ) :void
    {
        var playerAvatarChangedId :int = int( e.value );

        //We are only allowed to change our own avatar.
        if( playerAvatarChangedId != ClientContext.ourPlayerId ) {
            return;
        }

        //Do as if we have pushed the 'Bared" button.
        var avatar :AVRGameAvatar = ClientContext.ctrl.room.getAvatarInfo( playerAvatarChangedId );
        if( avatar != null) {

            var isBared :Boolean = ClientContext.model.state == VConstants.PLAYER_STATE_BARED ||
                ClientContext.model.state == VConstants.PLAYER_STATE_FEEDING_PREY;
            //If we change our avatar to bared, but we are not in the bared player state.
            if( !isBared && avatar.state == VConstants.AVATAR_STATE_BARED ) {
                ClientContext.controller.handleChangeState( VConstants.PLAYER_STATE_BARED );
            }
        }
    }

    protected function handleMessageReceived (e :MessageReceivedEvent) :void
    {
        if (e.name == "StartClient") {
            var gameId :int = e.value as int;
            log.info("Received StartClient message", "gameId", gameId);

            if (_feedingGameClient != null) {
                log.warning("Received StartFeeding message while already in game");
            } else {
                _feedingGameClient = FeedingClient.create( gameId, ClientContext.model.playerFeedingData, onGameComplete);

                modeSprite.addChild(_feedingGameClient);
            }
        }
        else if( e.name == VConstants.NAMED_EVENT_MOVE_PREDATOR_AFTER_FEEDING ) {

            //Humans practising don't need to move.
            if( !ClientContext.model.isVampire() ) {
                return;
            }

            var moveTimer :SimpleTimer = new SimpleTimer( 2.5, function() :void {

                var location :Array = ClientContext.model.location;
                if( location != null ) {
                    ClientContext.ctrl.player.setAvatarLocation(
                        MathUtil.clamp( location[0] + 0.1,0,1),
                        location[1],
                        MathUtil.clamp( location[2] - 0.1,0,1), location[3]);
                }
            }, false);
            addObject( moveTimer );
        }
        else if( e.name == FeedRequestMsg.NAME ) {
            var msg :FeedRequestMsg =
                ClientContext.msg.deserializeMessage( e.name, e.value) as FeedRequestMsg;

            trace("got " + FeedRequestMsg.NAME);
            var fromPlayerName :String = ClientContext.getPlayerName( msg.playerId );
            var popup :PopupQuery = new PopupQuery( ClientContext.ctrl,
                    "RequestFeed" + msg.playerId,
                    fromPlayerName + " would like to feed on you.",
                    [VampireController.FEED_REQUEST_ACCEPT, VampireController.FEED_REQUEST_DENY],
                    [msg.playerId, msg.playerId]);

            if( getObjectNamed( popup.objectName) == null) {
                addSceneObject( popup, modeSprite );
            }

        }
    }




    protected function onGameComplete () :void
    {
        log.info(ClientContext.ourPlayerId + " onGameComplete(), Feeding complete, setting avatar state to default");//, "completedSuccessfully", completedSuccessfully);

        trace(ClientContext.ourPlayerId + " setting avatar state from game complete");
        ClientContext.model.setAvatarState( VConstants.AVATAR_STATE_DEFAULT );
        if( _feedingGameClient.playerData != null ) {
            log.info(_feedingGameClient.playerData);
            ClientContext.ctrl.agent.sendMessage( VConstants.NAMED_EVENT_UPDATE_FEEDING_DATA,
                _feedingGameClient.playerData.toBytes() );
        }
        else {
            log.error("onGameComplete(), _feedingGameClient.playerData==null");
        }
        _feedingGameClient.shutdown();

        //Remove game after getting the feeding data, feeding data is nulled after stage removal.
        if( _feedingGameClient.parent != null ){
            _feedingGameClient.parent.removeChild( _feedingGameClient )
        }
        _feedingGameClient = null;
        //Reset the overlay
//        ClientContext.avatarOverlay.setDisplayMode( VampireAvatarHUDOverlay.DISPLAY_MODE_OFF );

    }

//    protected function avatarArrivedAtDestination(...ignored) :void
//    {
//        if( !ClientContext.ctrl.isConnected()) {
//            trace("avatarArrivedAtDestination, ctrl null, setting callback null");
//            var setCallback :Function = ClientContext.ctrl.room.getEntityProperty(
//            AvatarGameBridge.ENTITY_PROPERTY_SET_AVATAR_ARRIVED_CALLBACK, ClientContext.ourEntityId) as Function;
//            if( setCallback != null) {
//                setCallback( null );
//            }
//            return;
//        }
//
//
//        trace("Game knows avatar stopped!!!!");
//        if( ClientContext.model.state == VConstants.PLAYER_STATE_MOVING_TO_FEED ) {
//            trace("Sending player arrived event");
//            ClientContext.ctrl.agent.sendMessage( PlayerArrivedAtLocationEvent.PLAYER_ARRIVED );
//        }
//
//    }







    override protected function exit() :void
    {
        modeSprite.visible = false;
        log.warning("!!! " + ClassUtil.tinyClassName(this) + "exiting.  Is this what we want??");

        //Remove the avatar callback
        var setCallback :Function = ClientContext.ctrl.room.getEntityProperty(
        AvatarGameBridge.ENTITY_PROPERTY_SET_AVATAR_ARRIVED_CALLBACK, ClientContext.ourEntityId) as Function;
        if( setCallback != null) {
            setCallback( null );
        }
    }

    override protected function destroy() :void
    {
        super.destroy();

        //Remove the avatar callback
        var setCallback :Function = ClientContext.ctrl.room.getEntityProperty(
        AvatarGameBridge.ENTITY_PROPERTY_SET_AVATAR_ARRIVED_CALLBACK, ClientContext.ourEntityId) as Function;
        if( setCallback != null) {
            setCallback( null );
        }
    }

    protected var _hud :HUD;

    protected var _feedingGameClient :FeedingClient;

    protected var _currentNonPlayerIds :Array;


    protected static const log :Log = Log.getLog( MainGameMode );
}
}