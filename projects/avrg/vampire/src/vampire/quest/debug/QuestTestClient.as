package vampire.quest.debug {

import com.threerings.util.Log;
import com.whirled.avrg.AVRGameControl;
import com.whirled.contrib.EventHandlerManager;
import com.whirled.contrib.ManagedTimer;
import com.whirled.contrib.TimerManager;
import com.whirled.contrib.simplegame.*;

import flash.display.Sprite;
import flash.events.Event;

import vampire.feeding.*;
import vampire.quest.*;
import vampire.quest.client.*;

public class QuestTestClient extends Sprite
{
    public function QuestTestClient ()
    {
        log.info("Starting QuestTestClient");

        //_events.registerListener(this, Event.UNLOAD, onQuit);
        _events.registerListener(this, Event.REMOVED_FROM_STAGE, onQuit);

        // Init simplegame
        var config :Config = new Config();
        config.hostSprite = this;
        _sg = new SimpleGame(config);
        _sg.ctx.mainLoop.pushMode(new AppMode());
        _sg.run();

        // Init props
        _gameCtrl = new AVRGameControl(this);
        var questData :PlayerQuestData = new PlayerQuestData(_gameCtrl.player.props);
        var stats :PlayerQuestStats = new PlayerQuestStats(_gameCtrl.player.props);

        FeedingClient.init(this, _gameCtrl);
        QuestClient.init(_gameCtrl, _sg, questData, stats);

        var waitLoop :ManagedTimer = _timerMgr.runForever(50,
            function (...ignored) :void {
                if (QuestClient.isReady) {
                    waitLoop.cancel();
                    start();
                }
            });
    }

    protected function start () :void
    {
        QuestClient.showDebugPanel(true);
        QuestClient.showQuestPanel(true);
    }

    protected function onQuit (...ignored) :void
    {
        _events.freeAllHandlers();
        _timerMgr.shutdown();
        QuestClient.shutdown();
    }

    protected var _gameCtrl :AVRGameControl;
    protected var _events :EventHandlerManager = new EventHandlerManager();
    protected var _timerMgr :TimerManager = new TimerManager();
    protected var _sg :SimpleGame;

    protected static var log :Log = Log.getLog(QuestTestClient);
}

}