package {

import flash.geom.Point;
import flash.geom.Rectangle;
import mx.controls.Image;

public class TowerSprite extends Image
{
    public function TowerSprite (defref :TowerDef, board :Board)
    {
        _defref = defref;
        _board = board;
    }

    public function get defref () :TowerDef
    {
        return _defref;
    }

    public function set defref (newdef :TowerDef) :void
    {
        if (_defref != newdef) {
            _defref = newdef;
            if (_currentAssetType != _defref.type) { // let's not reload assets needlessly
                reloadAssets();
            }
        }
    }

    public function updateLocation () :void
    {
        var p :Point = _board.logicalToScreenPosition(_defref.x, _defref.y);
        this.x = p.x;
        this.y = p.y;
    }

    public function setValid (valid :Boolean) :void
    {
        this.alpha = valid ? 1.0 : 0.3;
    }

    public function reloadAssets () :void
    {
        this.source = AssetFactory.makeTower(_defref.type);
        this.scaleX = _board.squareWidth * _defref.width / source.width;
        this.scaleY = _board.squareHeight * _defref.height / source.height;
        _currentAssetType = _defref.type;
    }
    
    override protected function createChildren () :void
    {
        super.createChildren();
        reloadAssets();
        updateLocation();
    }

    protected var _currentAssetType :int;
    protected var _defref :TowerDef;
    protected var _board :Board;

}
}
