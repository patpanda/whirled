//
// $Id$

package ghostbusters.fight {

import flash.display.Sprite;
import flash.events.MouseEvent;

import com.threerings.util.CommandEvent;
import com.threerings.util.Controller;

import ghostbusters.Codes;
import ghostbusters.Game;
import ghostbusters.GameController;

public class FightController extends Controller
{
    public static const GHOST_ATTACKED :String = "GhostAttacked";
    public static const PLAYER_ATTACKED :String = "PlayerAttacked";

    public var panel :FightPanel;
    public var model :FightModel;

    public function FightController ()
    {
        model = new FightModel();
        panel = new FightPanel(model);
        model.init(panel);

        setControlledPanel(panel);
    }

    public function shutdown () :void
    {
    }

    public function lanternClicked () :void
    {
        panel.startGame();
    }

    public function handleGhostAttacked () :void
    {
        Game.control.playAvatarAction("Retaliate");
        panel.showGhostDamage();
        if (model.damageGhost(10)) {
            panel.showGhostDeath();
        }
    }

    public function handlePlayerAttacked () :void
    {
        Game.control.playAvatarAction("Reel");
        panel.showGhostAttack();
        if (model.damagePlayer(10)) {
            panel.showPlayerDeath();
        }
    }
}
}
