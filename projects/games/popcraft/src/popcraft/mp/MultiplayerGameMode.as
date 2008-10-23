package popcraft.mp {

import com.whirled.contrib.simplegame.net.OnlineTickedMessageManager;
import com.whirled.contrib.simplegame.net.TickedMessageManager;
import com.whirled.contrib.simplegame.util.Rand;
import com.whirled.game.StateChangedEvent;

import popcraft.*;
import popcraft.battle.*;
import popcraft.data.*;

public class MultiplayerGameMode extends GameMode
{
    override public function get mapSettings () :MapSettingsData
    {
        return _mpSettings.mapSettings;
    }

    override protected function setup () :void
    {
        super.setup();

        // start the game when the GAME_STARTED event is received
        this.registerListener(AppContext.gameCtrl.game, StateChangedEvent.GAME_STARTED,
            function (...ignored) :void {
                startGame();
            });

        // we're ready!
        AppContext.gameCtrl.game.playerReady();
    }

    override protected function rngSeeded () :void
    {
        // Determine what the game's team arrangement is, and randomly choose an appropriate
        // MultiplayerSettingsData that fits that arrangement.

        var multiplayerArrangement :int = MultiplayerConfig.computeTeamArrangement();
        var potentialSettings :Array = AppContext.multiplayerSettings;
        potentialSettings = potentialSettings.filter(
            function (mpSettings :MultiplayerSettingsData, index :int, array :Array) :Boolean {
                return (mpSettings.arrangeType == multiplayerArrangement);
            });

        _mpSettings = Rand.nextElement(potentialSettings, Rand.STREAM_GAME);
    }

    override protected function createPlayers () :void
    {
        var teams :Array = MultiplayerConfig.teams;
        var handicaps :Array = MultiplayerConfig.handicaps;

        // In multiplayer games, base locations are arranged in order of team,
        // with larger teams coming before smaller ones. Populate a set of TeamInfo
        // structures with base locations so that we can put everyone in the correct place.
        var baseLocs :Array = GameContext.gameMode.mapSettings.baseLocs.slice();
        var teamSizes :Array = MultiplayerConfig.computeTeamSizes();
        var largestTeamSize :int = -1;
        for each (var teamSize :int in teamSizes) {
            if (teamSize > largestTeamSize) {
                largestTeamSize = teamSize;
            }
        }

        // get some information about the players in the game
        var numPlayers :int = SeatingManager.numExpectedPlayers;
        GameContext.localPlayerIndex = SeatingManager.localPlayerSeat;

        var workshopData :UnitData = GameContext.gameData.units[Constants.UNIT_TYPE_WORKSHOP];
        var workshopHealth :Number = workshopData.maxHealth;

        var playerDisplayDatas :Array = GameContext.gameData.playerDisplayDatas.values();

        // create PlayerInfo structures
        GameContext.playerInfos = [];
        for (var playerIndex :int = 0; playerIndex < numPlayers; ++playerIndex) {

            var teamId :int = teams[playerIndex];
            teamSize = teamSizes[teamId];
            var baseLoc :BaseLocationData = MapSettingsData.getNextBaseLocForTeam(baseLocs, teamId);

            // calculate the player's handicap
            var handicap :Number = 1;
            if (teamSize < largestTeamSize) {
                handicap = _mpSettings.smallerTeamHandicap;
            }
            if (handicaps[playerIndex]) {
                handicap *= Constants.HANDICAPPED_MULTIPLIER;
            }

            // choose a random color for this player
            var index :int = Rand.nextIntRange(0, playerDisplayDatas.length, Rand.STREAM_GAME);
            var playerDisplayData :PlayerDisplayData = playerDisplayDatas[index];
            playerDisplayDatas.splice(index, 1); // we're operating on a copy of the data
            var playerColor :uint = playerDisplayData.color;

            GameContext.playerInfos.push(GameContext.localPlayerIndex == playerIndex ?
                new LocalPlayerInfo(playerIndex, teamId, baseLoc, workshopHealth, workshopHealth,
                                    false, handicap, playerColor) :
                new PlayerInfo(playerIndex, teamId, baseLoc, workshopHealth, workshopHealth, false,
                                handicap, playerColor));
        }

        // init players
        for each (var playerInfo :PlayerInfo in GameContext.playerInfos) {
            playerInfo.init();
        }
    }

    override protected function createRandSeed () :uint
    {
        return MultiplayerConfig.randSeed;
    }

    override protected function createMessageManager () :TickedMessageManager
    {
        return new OnlineTickedMessageManager(AppContext.gameCtrl,
             SeatingManager.isLocalPlayerInControl, TICK_INTERVAL_MS);
    }

    override protected function handleGameOver () :void
    {
        fadeOutToMode(new MultiplayerGameOverMode(), FADE_OUT_TIME);

        GameContext.musicControls.fadeOut(FADE_OUT_TIME - 0.25);
        GameContext.sfxControls.fadeOut(FADE_OUT_TIME - 0.25);
    }

    protected var _mpSettings :MultiplayerSettingsData;
}

}
