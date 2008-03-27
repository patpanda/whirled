package simon {

import com.threerings.util.ArrayUtil;
import com.threerings.util.Log;
import com.whirled.AVRGameControlEvent;

import flash.display.Sprite;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.events.TimerEvent;
import flash.utils.Timer;

public class Controller
{
    public function Controller (mainSprite :Sprite, model :Model)
    {
        _mainSprite = mainSprite;
        _model = model;
    }

    public function setup () :void
    {
        // timers
        _newRoundTimer = new Timer(Constants.NEW_ROUND_DELAY_S * 1000, 1);
        _newRoundTimer.addEventListener(TimerEvent.TIMER, handleNewRoundTimerExpired);

        // state change events
        _model.addEventListener(SharedStateChangedEvent.GAME_STATE_CHANGED, handleGameStateChange);
        _model.addEventListener(SharedStateChangedEvent.NEXT_PLAYER, handleCurPlayerChanged);
        _model.addEventListener(SharedStateChangedEvent.NEW_SCORES, handleNewScores);

        SimonMain.control.addEventListener(AVRGameControlEvent.PLAYER_LEFT, handlePlayerLeft);

        _mainSprite.addEventListener(Event.ENTER_FRAME, handleEnterFrame);

        // controllers
        _cloudController = new CloudViewController();
        _avatarController = new AvatarController();

        // each client maintains the concept of an expected state,
        // so that it is prepared to take over as the
        // authoritative client at any time.

        if (SimonMain.control.isConnected() && SimonMain.control.hasControl() && SimonMain.model.curState.gameState != SharedState.INVALID_STATE) {
            // try to reset the state when we first enter a game, in case
            // there's a current game in progress that isn't controlled by anybody
            _expectedState = new SharedState();
            this.applyStateChanges();
        } else {
            _expectedState = null;
            this.handleGameStateChange(null);
        }
    }

    public function destroy () :void
    {
        if (null != _rainbowController) {
            _rainbowController.destroy();
            _rainbowController = null;
        }

        _cloudController.destroy();
        _avatarController.destroy();

        _model.removeEventListener(SharedStateChangedEvent.GAME_STATE_CHANGED, handleGameStateChange);
        _model.removeEventListener(SharedStateChangedEvent.NEXT_PLAYER, handleCurPlayerChanged);
        _model.removeEventListener(SharedStateChangedEvent.NEW_SCORES, handleNewScores);

        SimonMain.control.removeEventListener(AVRGameControlEvent.PLAYER_LEFT, handlePlayerLeft);

        _mainSprite.removeEventListener(Event.ENTER_FRAME, handleEnterFrame);

        _newRoundTimer.removeEventListener(TimerEvent.TIMER, handleNewRoundTimerExpired);
    }

    protected function handleEnterFrame (e :Event) :void
    {
        this.update();
    }

    protected function handleQuitButtonClick (e :MouseEvent) :void
    {
        if (SimonMain.control.isConnected()) {
            SimonMain.control.deactivateGame();
        }
    }

    protected function update () :void
    {
        switch (SimonMain.model.curState.gameState) {
        case SharedState.WAITING_FOR_GAME_START:
            if (this.canStartGame) {
                this.startNextGame();
            }
            break;

        default:
            // do nothing;
            break;
        }

        this.applyStateChanges();

        this.updateStatusText();
    }

    protected function applyStateChanges () :void
    {
        if (null != _expectedState) {

            // trySetNewState is idempotent in the sense that
            // we can keep calling it until the state changes.
            // The state change we see will not necessarily
            // be what was requested (this client may not be in control)

            _model.trySetNewState(_expectedState);
        }

        if (null != _expectedScores) {

            // see above

            _model.trySetNewScores(_expectedScores);
        }
    }

    protected function handleGameStateChange (e :SharedStateChangedEvent) :void
    {
        // reset the expected state when the state changes
        _expectedState = null;

        if (null != _rainbowController) {
            _rainbowController.destroy();
            _rainbowController = null;
        }

        switch (_model.curState.gameState) {
        case SharedState.INVALID_STATE:
            // no game in progress. kick a new one off.
            this.setupFirstGame();
            break;

        case SharedState.WAITING_FOR_GAME_START:
            // in the "lobby", waiting for enough players to join
            if (this.canStartGame) {
                this.startNextGame();
            }
            break;

        case SharedState.PLAYING_GAME:
            // the game has started -- it's the first player's turn
            this.handleCurPlayerChanged(null);
            break;

        case SharedState.WE_HAVE_A_WINNER:
            this.handleGameOver();
            break;

        default:
            log.info("unrecognized gameState: " + _model.curState.gameState);
            break;
        }

        this.updateStatusText();
    }

    protected function handleCurPlayerChanged (e :SharedStateChangedEvent) :void
    {
        // reset the expected state when the state changes
        _expectedState = null;

        if (null != _rainbowController) {
            _rainbowController.destroy();
            _rainbowController = null;
        }

        if (SimonMain.model.curState.players.length == 0) {
            _expectedState = SimonMain.model.curState.clone();
            _expectedState.gameState = SharedState.WAITING_FOR_GAME_START;

            this.applyStateChanges();
        } else if (SimonMain.model.curState.players.length == 1 && SimonMain.minPlayersToStart > 1) {
            _expectedState = SimonMain.model.curState.clone();
            _expectedState.gameState = SharedState.WE_HAVE_A_WINNER;
            _expectedState.roundWinnerId = (_expectedState.players.length > 0 ? _expectedState.players[0] : 0);

            this.applyStateChanges();
        } else {
            // show the rainbow on the correct player
            _rainbowController = new RainbowController(SimonMain.model.curState.curPlayerOid);
        }
    }

    protected function handlePlayerLeft (e :AVRGameControlEvent) :void
    {
        // handle players who leave while playing the game

        var playerId :int = e.value as int;
        var index :int = SimonMain.model.curState.players.indexOf(playerId);
        if (index >= 0) {

            if (null == _expectedState) {
                _expectedState = SimonMain.model.curState.clone();
            }

            _expectedState.players = SimonMain.model.curState.players.slice();
            _expectedState.players.splice(index, 1);

            // was it this player's turn?
            if (_expectedState.curPlayerIdx >= _expectedState.players.length) {
                _expectedState.curPlayerIdx = 0;
            }

        }
    }

    protected function handleNewScores (e :SharedStateChangedEvent) :void
    {
        _expectedScores = null;
    }

    protected function handleGameOver () :void
    {
        // update scores
        if (_model.curState.roundWinnerId != 0) {
            _expectedScores = _model.curScores.clone();
            _expectedScores.incrementScore(_model.curState.roundWinnerId, new Date());
            this.applyStateChanges();

            // are you TEH WINNAR?
            if (_model.curState.roundWinnerId == SimonMain.localPlayerId && SimonMain.control.isConnected()) {
                SimonMain.control.quests.completeQuest("dummyString", null, 1);
                _avatarController.setAvatarState("Dance", Constants.AVATAR_DANCE_TIME, "Default");
            }
        }

        // start a new round soon
        this.startNewRoundTimer();
    }

    protected function updateStatusText () :void
    {
        var newStatusText :String;

        switch (_model.curState.gameState) {
        case SharedState.INVALID_STATE:
            newStatusText = "INVALID_STATE";
            break;

        case SharedState.WAITING_FOR_GAME_START:
            newStatusText = "Waiting to start (players: " + SimonMain.model.getPlayerOids().length + "/" + SimonMain.minPlayersToStart + ")";
            break;

        case SharedState.PLAYING_GAME:
            var curPlayerName :String = SimonMain.getPlayerName(_model.curState.curPlayerOid);
            newStatusText = "Playing game. " + curPlayerName + "'s turn.";
            break;

        case SharedState.WE_HAVE_A_WINNER:
            newStatusText = SimonMain.getPlayerName(_model.curState.roundWinnerId) + " is the winner!";
            break;

        default:
            log.info("unrecognized gameState: " + _model.curState.gameState);
            break;
        }

        if (newStatusText != _statusText) {
            log.info("** STATUS: " + newStatusText);
            _statusText = newStatusText;
        }
    }

    protected function setupFirstGame () :void
    {
        log.info("setupFirstGame()");

        _expectedState = new SharedState();
        _expectedState.gameState = SharedState.WAITING_FOR_GAME_START;

        this.applyStateChanges();
    }

    protected function get canStartGame () :Boolean
    {
        return (SimonMain.model.getPlayerOids().length >= SimonMain.minPlayersToStart);
    }

    protected function startNextGame () :void
    {
        log.info("startNextGame()");

        // set up for the next game state if we haven't already
        if (null == _expectedState || _expectedState.gameState != SharedState.PLAYING_GAME) {
            _expectedState = new SharedState();

            _expectedState.gameState = SharedState.PLAYING_GAME;
            _expectedState.curPlayerIdx = 0;

            // shuffle the player list
            var playerOids :Array = SimonMain.model.getPlayerOids();
            ArrayUtil.shuffle(playerOids, null);
            _expectedState.players = playerOids;
        }

        this.applyStateChanges();
    }

    protected function startNewRoundTimer () :void
    {
        _newRoundTimer.reset();
        _newRoundTimer.start();
    }

    protected function stopNewRoundTimer () :void
    {
        _newRoundTimer.stop();
    }

    protected function handleNewRoundTimerExpired (e :TimerEvent) :void
    {
        _expectedState = SimonMain.model.curState.clone();

        // push a new round update out
        _expectedState.gameState = SharedState.WAITING_FOR_GAME_START;
        _expectedState.players = [];
        _expectedState.pattern = [];
        _expectedState.roundId += 1;
        _expectedState.roundWinnerId = 0;

        this.applyStateChanges();
    }

    public function currentPlayerTurnSuccess (newNote :int) :void
    {
        _rainbowController.destroy();
        _rainbowController = null;

        _expectedState = SimonMain.model.curState.clone();
        _expectedState.pattern.push(newNote);

        _expectedState.curPlayerIdx =
            (_expectedState.curPlayerIdx < _expectedState.players.length - 1 ? _expectedState.curPlayerIdx + 1 : 0);

        this.applyStateChanges();
    }

    public function currentPlayerTurnFailure () :void
    {
        _rainbowController.destroy();
        _rainbowController = null;

        _expectedState = SimonMain.model.curState.clone();

        // the current player is out of the round
        _expectedState.players.splice(_expectedState.curPlayerIdx, 1);

        // move to the next player
        if (_expectedState.curPlayerIdx >= _expectedState.players.length - 1) {
            _expectedState.curPlayerIdx = 0;
        }

        this.applyStateChanges();
    }

    protected var _model :Model;
    protected var _expectedState :SharedState;
    protected var _expectedScores :ScoreTable;

    protected var _mainSprite :Sprite;
    protected var _statusText :String;

    protected var _cloudController :CloudViewController;
    protected var _rainbowController :RainbowController;
    protected var _avatarController :AvatarController;

    protected var _newRoundTimer :Timer;

    protected var log :Log = Log.getLog(this);

}

}
