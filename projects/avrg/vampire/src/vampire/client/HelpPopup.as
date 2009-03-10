package vampire.client
{
    import com.threerings.flash.DisplayUtil;
    import com.threerings.util.Log;
    import com.whirled.contrib.avrg.DraggableSceneObject;

    import flash.display.DisplayObject;
    import flash.display.MovieClip;
    import flash.display.SimpleButton;
    import flash.display.Sprite;
    import flash.events.MouseEvent;
    import flash.geom.Rectangle;
    import flash.text.TextField;
    import flash.text.TextFormat;
    import flash.text.TextFormatAlign;

    import vampire.data.Logic;
    import vampire.feeding.Constants;
    import vampire.feeding.PlayerFeedingData;

    public class HelpPopup extends DraggableSceneObject
    {
        public function HelpPopup( startframe :String = "intro")
        {
            super(ClientContext.ctrl);

            _hudHelp = ClientContext.instantiateMovieClip("HUD", "popup_help", false);
            _displaySprite.addChild( _hudHelp );

            _lineageView = new LineageView();

            //Go to the first frame where all the buttons are.  Even though not all buttons are
            //visible there, obviously, however they need to be instantiated on the first frame
            //otherwise they cannot be 'found'.
            _hudHelp.gotoAndStop("intro");

            //Wire up the links on the left panel
            registerListener( SimpleButton(findSafely("to_default")), MouseEvent.CLICK,
                function( e :MouseEvent ) :void {
                    gotoFrame("default");
                });
            registerListener( SimpleButton(findSafely("to_bloodtype")), MouseEvent.CLICK,
                function( e :MouseEvent ) :void {
                    gotoFrame("bloodtype");
                });
            registerListener( SimpleButton(findSafely("menu_tofeedingonvamps")), MouseEvent.CLICK,
                function( e :MouseEvent ) :void {
                    gotoFrame("vamps");
                });
            registerListener( SimpleButton(findSafely("menu_tofeedinggame")), MouseEvent.CLICK,
                function( e :MouseEvent ) :void {
                    gotoFrame("feedinggame");
                });
            registerListener( SimpleButton(findSafely("menu_tointro")), MouseEvent.CLICK,
                function( e :MouseEvent ) :void {
                    gotoFrame("intro");
                });


            //Wire up the buttons
            registerListener( SimpleButton(findSafely("button_tofeedinggame")), MouseEvent.CLICK,
                function( e :MouseEvent ) :void {
                    gotoFrame("feedinggame");
                });
            registerListener( SimpleButton(findSafely("button_tolineage")), MouseEvent.CLICK,
                function( e :MouseEvent ) :void {
                    gotoFrame("lineage");
                });
            registerListener( SimpleButton(findSafely("button_tovamps")), MouseEvent.CLICK,
                function( e :MouseEvent ) :void {
                    gotoFrame("vamps");
                });
            registerListener( SimpleButton(findSafely("button_tomortals")), MouseEvent.CLICK,
                function( e :MouseEvent ) :void {
                    gotoFrame("mortals");
                });
            registerListener( SimpleButton(findSafely("button_tobloodbond")), MouseEvent.CLICK,
                function( e :MouseEvent ) :void {
                    gotoFrame("bloodbond");
                });
            registerListener( SimpleButton(findSafely("button_tomortals")), MouseEvent.CLICK,
                function( e :MouseEvent ) :void {
                    gotoFrame("mortals");
                });
            registerListener( SimpleButton(findSafely("button_tobloodtype")), MouseEvent.CLICK,
                function( e :MouseEvent ) :void {
                    gotoFrame("bloodtype");
                });
            registerListener( SimpleButton(findSafely("button_toinstructions")), MouseEvent.CLICK,
                function( e :MouseEvent ) :void {
                    gotoFrame("instructions");
                });
            registerListener( SimpleButton(findSafely("help_close")), MouseEvent.CLICK,
                function( e :MouseEvent ) :void {
                    destroySelf();
                });
            registerListener( SimpleButton(findSafely("button_recruit")), MouseEvent.CLICK,
                function( e :MouseEvent ) :void {
                    ClientContext.ctrl.local.showInvitePage("Join my Coven!", "" + ClientContext.ourPlayerId);
                });


            registerListener( SimpleButton(findSafely("help_back")), MouseEvent.CLICK,
                backButtonPushed);


            gotoFrame(startframe );


            init( new Rectangle(-_displaySprite.width/2, _displaySprite.height/2, _displaySprite.width, _displaySprite.height), 0, 0, 0, 100);
            centerOnViewableRoom();
        }



        protected function updateBloodStrainPage() :void
        {
            var feedingData :PlayerFeedingData = ClientContext.model.playerFeedingData;
            if( feedingData == null ) {
                log.error("updateBloodStrainPage, feedingData == null");
                return;
            }
            while(_bloodTypeOverlay.numChildren) { _bloodTypeOverlay.removeChildAt(0);}

            for( var i :int = 1; i < 13; i++) {
                var numberAsText :String = String(i);
                if( numberAsText.length == 1) {
                    numberAsText = "0" + numberAsText;
                }
                var textFieldName :String = "indicator_" + numberAsText;

                var tf :MovieClip = _hudHelp[textFieldName] as MovieClip;
                if( tf == null ) {
                    log.error(textFieldName + " is null");
                    continue;
                }

                if( Logic.getPlayerBloodStrain( ClientContext.ourPlayerId ) == i) {
                    tf.gotoAndStop(3);
                }

                if( Logic.getPlayerPreferredBloodStrain( ClientContext.ourPlayerId ) == i) {
                    tf.gotoAndStop(2);
                }

                TextField(tf["tally"]).text = "";
                var tally :TextField = TextField(tf["tally"]);

                var replacementTextField :TextField = new TextField();
                replacementTextField.text = feedingData.getStrainCount( i - 1 ) + " / " + Constants.MAX_COLLECTIONS_PER_STRAIN;
                replacementTextField.x = tally.x;
                replacementTextField.y = tally.y;
                replacementTextField.textColor = 0xffffff;

                var format :TextFormat = new TextFormat();
                format.size = 16;
                format.color = 0xffffff;
                format.align = TextFormatAlign.LEFT;
                format.bold = true;
                replacementTextField.setTextFormat( format );
                tf.addChild( replacementTextField);


                var starsignTextField :TextField = new TextField();
                starsignTextField.text = BLOOD_STRAIN_NAMES[i - 1];
                starsignTextField.x = tally.x - 130;
                starsignTextField.y = tally.y;

                var starSignformat :TextFormat = new TextFormat();
                starSignformat.size = 16;
                starSignformat.color = 0xffffff;
                starSignformat.align = TextFormatAlign.RIGHT;
                starSignformat.bold = true;
                starsignTextField.setTextFormat( starSignformat );
                tf.addChild( starsignTextField);
            }
        }

        override public function destroySelf():void
        {
            super.destroySelf();
            if( _lineageView != null && _lineageView.isLiveObject ) {
                _lineageView.destroySelf();

            }
        }

        override protected function addedToDB():void
        {

            db.addObject( _lineageView );
            if( _hudHelp.currentFrame == 2 ) {
                _hudHelp.addChild( _lineageView.displayObject );
            }
        }


//        protected function getFullCellSprite() :DisplayObject
//        {
//            var s :Shape = new Shape();
//            s.graphics.beginFill(0);
//            s.graphics.drawCircle(0, 0, 10 );
//            s.graphics.endFill();
//            return s;
//        }
//
//        protected function getEmptyCellSprite() :DisplayObject
//        {
//            var s :Shape = new Shape();
//            s.graphics.lineStyle(1);
//            s.graphics.drawCircle(0, 0, 10 );
//            return s;
//        }

        protected function findSafely (name :String) :DisplayObject
        {
            var o :DisplayObject = DisplayUtil.findInHierarchy(_displaySprite, name);
            if (o == null) {
                throw new Error("Cannot find object: " + name);
            }
            return o;
        }

        protected function removeExtraHelpPanels() :void
        {
            if( _hudHelp.contains( _bloodTypeOverlay ) ) {
                _hudHelp.removeChild( _bloodTypeOverlay );
            }

            if( _hudHelp.contains( _lineageView.displayObject ) ) {
                _hudHelp.removeChild( _lineageView.displayObject );
            }
        }

        public function gotoFrame( frame :String ) :void
        {
            if( frame == null) {
                frame = "default";
            }

            if( _frameHistory.length == 0 || _frameHistory[ _frameHistory.length - 1] != _hudHelp.currentFrame) {
                _frameHistory.push( _hudHelp.currentFrame );
            }

            _hudHelp.gotoAndStop(frame);

            removeExtraHelpPanels();

            switch( frame ) {
                case "bloodtype":
                    updateBloodStrainPage();
                    _hudHelp.addChild( _bloodTypeOverlay );
                    break;
                case "default":

                    //Center the lineage view on the anchor created for it.
                    var lineage_center :MovieClip = findSafely( "lineage_center") as MovieClip;
                    lineage_center.parent.addChild( _lineageView.displayObject );
                    _lineageView.x = lineage_center.x;
                    _lineageView.y = lineage_center.y - 20;

                default:
                    break;
            }
        }

        protected function backButtonPushed(...ignored) :void
        {
            if( _frameHistory.length > 0) {
                var nextFrame :int = _frameHistory.pop();
                _hudHelp.gotoAndStop( nextFrame );
                removeExtraHelpPanels();
            }
        }

//        override public function get displayObject () :DisplayObject
//        {
//            return _sceneObjectSprite;
//        }

        override public function get objectName () :String
        {
            return NAME;
        }

        protected var _hudHelp :MovieClip;
//        protected var _sceneObjectSprite :DraggableSprite;
//        protected var _sceneObjectSprite :Sprite;
        protected var _frameHistory :Array = new Array();
        protected var _bloodTypeOverlay :Sprite = new Sprite();

        protected var _lineageView :LineageView;

        public static const NAME :String = "HelpPopup";
        protected static const log :Log = Log.getLog( HelpPopup );

        protected static const BLOOD_STRAIN_NAMES :Array = [
            "Aries",
            "Taurus",
            "Gemini",
            "Cancer",
            "Leo",
            "Virgo",
            "Libra",
            "Scorpio",
            "Sagittarius",
            "Capricorn",
            "Aquarius",
            "Pisces"
        ];

    }
}