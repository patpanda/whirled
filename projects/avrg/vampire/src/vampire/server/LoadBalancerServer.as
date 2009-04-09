package vampire.server
{
import com.threerings.util.HashMap;
import com.threerings.util.HashSet;
import com.threerings.util.Log;
import com.whirled.contrib.simplegame.SimObject;
import com.whirled.contrib.simplegame.tasks.FunctionTask;
import com.whirled.contrib.simplegame.tasks.RepeatingTask;
import com.whirled.contrib.simplegame.tasks.SerialTask;
import com.whirled.contrib.simplegame.tasks.TimedTask;
import com.whirled.net.MessageReceivedEvent;

import flash.utils.ByteArray;

import vampire.net.messages.LoadBalancingMsg;

public class LoadBalancerServer extends SimObject
{
    public function LoadBalancerServer (server :GameServer)
    {
        _server = server;

        registerListener(_server.control.game, MessageReceivedEvent.MESSAGE_RECEIVED, handleMessage);
    }

    protected function handleMessage (evt :MessageReceivedEvent) :void
    {
        if (evt.name == LoadBalancingMsg.NAME) {
            log.debug("Received load balance request from " + evt.senderId);
            _playersRequestedRoomInfo.add(evt.senderId);
        }

    }

    override protected function update (dt:Number) :void
    {
        if (_playersRequestedRoomInfo.size() > 0) {
            log.debug("update", "_sortedRoomIds", _sortedRoomIds);

            var roomIds :Array = _sortedRoomIds.slice(0, 5);
            log.debug("update", "roomIds", roomIds);
            var roomNames :Array = roomIds.map(function (roomId :int, ...ignored) :String {
                if (_server.isRoom(roomId)) {
                    return _server.getRoom(roomId).name;
                }
                else {
                    return "";
                }
            });
            log.debug("update", "roomNames", roomNames);
//            var msgBytes :ByteArray = roomInfoMessage.toBytes();

            _playersRequestedRoomInfo.forEach(function (playerId :int) :void {
                //Only handle the message if the originating player exists.
                try {
                    if (_server.isPlayer(playerId)) {
                        var player :PlayerData = _server.getPlayer(playerId);
                        var roomInfoMessage :LoadBalancingMsg =
                            new LoadBalancingMsg(player.playerId, roomIds, roomNames);
                        log.debug("Sending " + player.name + " " + roomInfoMessage);
                        player.ctrl.sendMessage(LoadBalancingMsg.NAME, roomInfoMessage.toBytes());
                    }
                }
                catch(err :Error) {
                    log.error(err + "\n" + err.getStackTrace());
                }
            });
            _playersRequestedRoomInfo.clear();
        }
    }

    override protected function addedToDB () :void
    {
        super.addedToDB();
        //Set up the timed function using tasks.
        var serialTask :SerialTask = new SerialTask();
        serialTask.addTask(new TimedTask(ROOM_POPULATION_REFRESH_RATE));
        serialTask.addTask(new FunctionTask(refreshLowPopulationRoomData));
        addTask(new RepeatingTask(serialTask));
    }

    override protected function destroyed () :void
    {
        _server = null;
    }

    public function createLoadBalancingMsg (player :PlayerData) :void
    {

    }

    protected function refreshLowPopulationRoomData (...ignored) :void
    {
        var roomId2Players :HashMap = new HashMap();
        //Create the roomId to population map
        _server.rooms.forEach(function (roomId :int, room :Room) :void {
            if (!room.isStale && room.name != null) {
                roomId2Players.put(roomId, room.ctrl.getPlayerIds().length);
            }
        });
        //Sort the rooms ids.
        var roomIdsSorted :Array = sortRoomsToSendPlayers(roomId2Players);
        _sortedRoomIds = roomIdsSorted;
//        trace("refreshing room pops _sortedRoomIds=" + _sortedRoomIds);
        //Only take the best 6 rooms
//        roomIdsSorted = roomIdsSorted.slice(0, 6);
//        //Create the population array
//        var roomPopulations :Array = roomIdsSorted.map(function (roomId :int, ...ignored) :int {
//            return roomId2Players.get(roomId);
//        });
//        //Create the room name array
//        var roomNames :Array = roomIdsSorted.map(function (roomId :int, ...ignored) :String {
//            return _server.getRoom(roomId).name;
//        });
//
//        var newRoomPopulationData :Array = [roomIdsSorted, roomPopulations, roomNames];
//        //Update the room props.  This should all happen in the bundled server update,
//        //so should be reasonably efficient.
//        if (!ArrayUtil.equals(_lowPopulationRooms, newRoomPopulationData)) {
//            _lowPopulationRooms = newRoomPopulationData;
//            log.debug("sending to all rooms", "lowPopulationRooms", _lowPopulationRooms);
//            _server.rooms.forEach(function (roomId :int, room :Room) :void {
//                if (!room.isStale) {
//                    room.ctrl.props.set(Codes.ROOM_PROP_LOW_POPULATION_ROOMS,
//                        _lowPopulationRooms);
//                }
//            });
//        }
    }

    /**
     * An array of the form [[roomid1, roomid2, ..], [room1Population, room2Population, ...]]
     * Used by the client to find low population rooms
     */
    protected var _lowPopulationRooms :Array = [];

    protected static function sortRoomsToSendPlayers (roomId2PlayerCount :HashMap) :Array
    {
        var rooms :Array = roomId2PlayerCount.keys();
        //We want rooms with 3-6 occupants preferentially, then rooms with 1 person, then 7+
        var preferredRangeMin :int = 3;
        var preferredRangeMax :int = 6;

        //Exclude rooms with 2 or 0 players
        rooms = rooms.filter(function (roomId :int, ...ignored) :Boolean {
            if (roomId2PlayerCount.get(roomId) == 2 || roomId2PlayerCount.get(roomId) == 0) {
                return false;
            }
            return true;
        });

        var sortedRooms :Array = rooms.sort(function (roomId1 :int, roomId2 :int) :int {
            var r1 :int = roomId2PlayerCount.get(roomId1);
            var r2 :int = roomId2PlayerCount.get(roomId2);

            //Numbers are in the same band
            if ((r1 == 1 && r2 == 1) ||
                (r1 >= preferredRangeMin && r1 <= preferredRangeMax
                    && r2 >= preferredRangeMin && r2 <= preferredRangeMax) ||
                r1 > preferredRangeMax && r2 > preferredRangeMax) {

                if (r1 < r2) {
                    return -1;
                }
                else if (r1 == r2) {
                    return 0;
                }
                else {
                    return 1;
                }
            }
//            else
            //r1 is 1
            if (r1 == 1) {
                if (r2 == 1) {
                    return 0;
                }
                else if (r2 >= preferredRangeMin && r2 <= preferredRangeMax) {
                    return 1;
                }
                else {
                    return -1;
                }
            }
            //r1 is between [preferredRangeMin, preferredRangeMax]
            else if (r1 >= preferredRangeMin && r1 <= preferredRangeMax) {
                if (r2 == 1 || r2 > preferredRangeMax) {
                    return -1;
                }
                else {
                    if (r1 < r2) {
                        return -1;
                    }
                    else if (r1 == r2) {
                        return 0;
                    }
                    else {
                        return 1;
                    }
                }
            }
            //r1 is greater than preferredRangeMax
            else {
                if (r2 == 1 || (r2 >= preferredRangeMin && r2 <= preferredRangeMax)) {
                    return 1;
                }
                else {
                    if (r1 < r2) {
                        return -1;
                    }
                    else if (r1 == r2) {
                        return 0;
                    }
                    else {
                        return 1;
                    }
                }
            }


        });

        return sortedRooms;
    }
    protected var _server :GameServer;
    protected var _sortedRoomIds :Array = [];

    protected var _playersRequestedRoomInfo :HashSet = new HashSet();

    protected static const ROOM_POPULATION_REFRESH_RATE :Number = 5;
    protected static const log :Log = Log.getLog(LoadBalancerServer);

}
}