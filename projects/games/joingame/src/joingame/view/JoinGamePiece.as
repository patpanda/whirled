package joingame.view
{
    import com.whirled.contrib.simplegame.objects.*;
    import com.whirled.contrib.simplegame.resource.*;
    import com.whirled.contrib.simplegame.tasks.*;
    
    import flash.display.DisplayObject;
    import flash.display.MovieClip;
    import flash.display.Shape;
    import flash.display.Sprite;
    
    import joingame.*;
    
    public class JoinGamePiece extends SceneObject
    {

        public function JoinGamePiece(size:int = Constants.PUZZLE_TILE_SIZE, type: int = Constants.PIECE_TYPE_NORMAL, colorcode: int = -1)
        {
            super();
            
            if (null == SWF_CLASSES)
            {
                SWF_CLASSES = [];
                var swf :SwfResource = (ResourceManager.instance.getResource("puzzlePieces") as SwfResource);
                for each (var className :String in SWF_CLASS_NAMES)
                {
                    SWF_CLASSES.push(swf.getClass(className));
                }
                
                SWF_CLASSES_HORIZ = [];
                for each (className in SWF_CLASS_NAMES_HORIZ)
                {
                    SWF_CLASSES_HORIZ.push(swf.getClass(className));
                }
                
                SWF_CLASSES_VERT = [];
                for each (className in SWF_CLASS_NAMES_VERT)
                {
                    SWF_CLASSES_VERT.push(swf.getClass(className));
                }
            }
        
        
//            boardIndex = index;
//            _sprite = new Sprite();
//            mouseEnabled = false;

            _sprite = new Sprite();
            _sprite.mouseEnabled = false;
            _sprite.mouseChildren = false;
            
            _size = size;
            _color = colorcode;
            
//            if(colorcode >= 0 && colorcode < Constants.PIECE_COLORS_ARRAY.length)
//            { 
//                _color = Constants.PIECE_COLORS_ARRAY[colorcode];
//            }
//            else
//            {
//                _color = Constants.PIECE_COLORS_ARRAY[randomNumber(0,Constants.PIECE_COLORS_ARRAY.length - 1)];
//            }
            _type = type;
            
            updateImage();
            
        }
        public function randomizeColor(): void
        {
            _color = Constants.PIECE_COLORS_ARRAY[randomNumber(0,Constants.PIECE_COLORS_ARRAY.length - 1)];
            updateImage();
        }


    override public function get displayObject () :DisplayObject
    {
        return _sprite;
    }
    
    /** Called once per update tick. (Subclasses can override this to do something useful.) */
    override protected function update (dt :Number) :void
    {
//        trace(" updating piece via db");
    }

   /** 
    * Generate a random number
    * @return Random Number
    * @error throws Error if low or high is not provided
    */  
    protected function randomNumber(low:Number=NaN, high:Number=NaN):Number
    {
        var low:Number = low;
        var high:Number = high;
    
        if(isNaN(low))
        {
        throw new Error("low must be defined");
        }
        if(isNaN(high))
        {
        throw new Error("high must be defined");
        }
    
        return Math.round(Math.random() * (high - low)) + low;
    }
        
    public function get boardIndex () :int
    {
        return _boardIndex;
    }

    public function set boardIndex (newIndex :int) :void
    {
        _boardIndex = newIndex;
    }
    
    public function get color () :int
    {
        return _color;
    }

    public function set color (newColor :int) :void
    {
        _color = newColor;
        
        
        
             // load the piece classes if they aren't already loaded
//        if (null == SWF_CLASSES)
//        {
//            SWF_CLASSES = [];
//            var swf :SwfResource = (ResourceManager.instance.getResource("puzzlePieces") as SwfResource);
//            for each (var className :String in SWF_CLASS_NAMES)
//            {
//                SWF_CLASSES.push(swf.getClass(className));
//            }
//        }


//        trace("SWF_CLASSES.length=" + SWF_CLASSES.length);
//        _type = newtype;

        var pieceClass :Class = SWF_CLASSES[_color];
        var pieceMovie :MovieClip = new pieceClass();
        pieceMovie.mouseEnabled = false;
        pieceMovie.mouseChildren = false;
//        this._size = pieceMovie
//        pieceMovie.x = -(pieceMovie.width * 0.5);
//        pieceMovie.y = -(pieceMovie.height * 0.5);

        pieceMovie.cacheAsBitmap = true;

//        _sprite = new Sprite();
//        _sprite.mouseChildren = false;
//        _sprite.mouseEnabled = false;

        _pieceMovie = pieceMovie;
//        if(ANIMATED_PIECES){
//            this.addChild(pieceMovie);
//        }
//        
        
        
        
        updateImage();
    }
    
    
    public function convertToEmpty() :void
    {
        this.type = Constants.PIECE_TYPE_EMPTY;
        trace("!!!!!!! convertToEmpty " + _boardIndex);
    }
    
    
    public function get type() :int
    {
        return _type;
    }

    public function set size (newsize :int) :void
    {
        _size = newsize;
        updateImage();    
    }
    public function get size () :int
    {
        return _size;
    }
    
    public function updateImage(): void
    {
        if( _pieceMovie != null && _sprite.contains( _pieceMovie) )
        {
            _sprite.removeChild( _pieceMovie);        
        }
        
        if(_type == Constants.PIECE_TYPE_DEAD)
        {
//            _sprite.graphics.clear();
//            _sprite.graphics.beginFill( 0xab6300, 1 );            
//            _sprite.graphics.drawRect( 0 , 0 , _size, _size );
//            _sprite.graphics.beginFill( 0x69635c, 1 );    
//            _sprite.graphics.drawRect( 5 , 5 , _size-10, _size-10 );
//            _sprite.graphics.endFill();
            
            
            
            var pieceClass :Class = SWF_CLASSES[0];
            var pieceMovie :MovieClip = new pieceClass();
            pieceMovie.mouseEnabled = false;
            pieceMovie.mouseChildren = false;
            pieceMovie.cacheAsBitmap = true;
            _pieceMovie = pieceMovie;
            _sprite.addChild(_pieceMovie);
        
        
        }
        else if(_type == Constants.PIECE_TYPE_EMPTY)
        {
            _sprite.graphics.clear();
//            _sprite.graphics.beginFill( Constants.PIECE_COLOR_EMPTY, 0 ); 
            _sprite.graphics.lineStyle(1, Constants.PIECE_COLOR_EMPTY, 1 );            
            _sprite.graphics.drawRect( 0 , 0 , _size, _size );
//            _sprite.graphics.endFill();
        }
        else if(_type == Constants.PIECE_TYPE_NORMAL)
        {
            _sprite.graphics.clear();
//            if(_pieceMovie != null)
//            {
//                addChild(_pieceMovie);
//            }
            if(ANIMATED_PIECES){
                if(_pieceMovie != null){
                    _sprite.addChild(_pieceMovie);
                }
            }
            else{
                _sprite.graphics.beginFill( Constants.PIECE_COLORS_ARRAY[_color], 1 );            
                _sprite.graphics.drawRect( 0 , 0 , _size , _size );
                _sprite.graphics.endFill();
            }
            
        }
        else if(_type == Constants.PIECE_TYPE_INACTIVE)
        {
            _sprite.graphics.clear();
            _sprite.graphics.beginFill( 1, 0.3 );   
//            _sprite.graphics.lineStyle(1, Constants.PIECE_COLOR_EMPTY, 0 );         
            _sprite.graphics.drawRect( 0 , 0 , _size, _size );
            _sprite.graphics.endFill();
        }
        else if(_type == Constants.PIECE_TYPE_POTENTIALLY_DEAD)
        {
//            if(_pieceMovie != null)
//            {
//                addChild(_pieceMovie);
//            }
            
            if(ANIMATED_PIECES){
                _sprite.addChild(_pieceMovie);
            }
            else{
                _sprite.graphics.beginFill( Constants.PIECE_COLORS_ARRAY[_color], 1 );            
                _sprite.graphics.drawRect( 0 , 0 , _size , _size );
                _sprite.graphics.endFill();
            }
            
            
            
            var opaqueCover :Shape = new Shape();
            opaqueCover.graphics.beginFill( Constants.PIECE_COLOR_POTENTIALLY_DEAD, 0.3 );            
            opaqueCover.graphics.drawRect( 0 , 0 , _size, _size );
            opaqueCover.graphics.endFill();
            _sprite.addChild(opaqueCover);
        }
//        if(_pieceMovie != null) {
//            _pieceMovie.scaleX = 1.0;
//            _pieceMovie.scaleY = 1.0;
//            _pieceMovie.scaleX = _size / _pieceMovie.width;
//            _pieceMovie.scaleY = _size / _pieceMovie.height;
//            trace("now piece height=" + _pieceMovie.height);
//        }
        
    }
    public function set type (newtype :int) :void
    {
        if(newtype >= 0 && newtype <= Constants.PIECE_TYPE_POTENTIALLY_DEAD) 
        {
            _type = newtype;
        }
        else
            trace("JoinGamePiece, set type not known="+newtype);
        updateImage();
    }
    
    public function convertToDeadIfLegal() :Boolean
    {
        if(_type ==Constants.PIECE_TYPE_POTENTIALLY_DEAD || _type ==Constants.PIECE_TYPE_NORMAL) 
        {
            _type =Constants.PIECE_TYPE_DEAD;
            updateImage();
            return true;
        }
        return false;
    }
//    public function get x () :int
//    {
//        return _sprite.x;
//    }
//    
//    public function get x () :int
//    {
//        return _sprite.x;
//    }
    
//    public function update(): void
//    {
//        graphics.clear();
//        graphics.beginFill( _color, 1 );            
//        graphics.drawRect( 0 , 0 , _size, _size );
//        graphics.endFill();
//    }


    override public function toString(): String
    {
        return " [Piece index="+_boardIndex.toString() + ", color=" + color + ", type=" + type + "]";
    }
    
    public function convertToNormal() :void
    {
        this.type = Constants.PIECE_TYPE_NORMAL;
    }
    
    public function toHorizontalJoin() :void 
    {
        var pieceClass :Class = SWF_CLASSES_HORIZ[_color];
        var pieceMovie :MovieClip = new pieceClass();
        pieceMovie.mouseEnabled = false;
        pieceMovie.mouseChildren = false;
        pieceMovie.cacheAsBitmap = true;
        _pieceMovie = pieceMovie;
        updateImage();
    }
    
    public function toVerticalJoin() :void 
    {
        var pieceClass :Class = SWF_CLASSES_VERT[_color];
        var pieceMovie :MovieClip = new pieceClass();
        pieceMovie.mouseEnabled = false;
        pieceMovie.mouseChildren = false;
        pieceMovie.cacheAsBitmap = true;
        _pieceMovie = pieceMovie;
        updateImage();
        
    }
    
//    public function get resourceType () :int
//    {
//        return _resourceType;
//    }

//    public function set resourceType (newType :int) :void
//    {
//        // load the piece classes if they aren't already loaded
//        if (null == SWF_CLASSES) {
//            SWF_CLASSES = [];
//            var swf :SwfResource = (ResourceManager.instance.getResource("puzzlePieces") as SwfResource);
//            for each (var className :String in SWF_CLASS_NAMES) {
//                SWF_CLASSES.push(swf.getClass(className));
//            }
//        }
//
//        _resourceType = newType;
//
//        var pieceClass :Class = SWF_CLASSES[newType];
//        var pieceMovie :MovieClip = new pieceClass();
//
//        pieceMovie.x = -(pieceMovie.width * 0.5);
//        pieceMovie.y = -(pieceMovie.height * 0.5);
//
//        pieceMovie.cacheAsBitmap = true;
//
//        _sprite = new Sprite();
//        _sprite.mouseChildren = false;
//        _sprite.mouseEnabled = false;
//
//        _sprite.addChild(pieceMovie);
//    }

        protected var _boardIndex :int;
        private var _type :int;
        private var _pieceMovie :MovieClip;
        
        
        protected var _sprite :Sprite;
        
        
        protected static var SWF_CLASSES :Array;
        protected static const SWF_CLASS_NAMES :Array = [ "piece_00", "piece_01", "piece_02", "piece_03", "piece_04", "piece_05" ];
        
        protected static var SWF_CLASSES_HORIZ :Array;
        protected static const SWF_CLASS_NAMES_HORIZ :Array = [ "piece_00_horiz", "piece_01_horiz", "piece_02_horiz", "piece_03_horiz", "piece_04_horiz", "piece_05_horiz" ];
        
        protected static var SWF_CLASSES_VERT :Array;
        protected static const SWF_CLASS_NAMES_VERT :Array = [ "piece_00_vert", "piece_01_vert", "piece_02_vert", "piece_03_vert", "piece_04_vert", "piece_05_vert" ];
        
        private var _color:int;
        private var _size:int;
        
        
        public static const ANIMATED_PIECES :Boolean = true;
        
//    protected var _resourceType :int;

//    protected static var SWF_CLASSES :Array;
//    protected static const SWF_CLASS_NAMES :Array = [ "A", "B", "C", "D" ];







//        public static constConstants.PIECE_TYPE_NORMAL :int = 0;
//        public static constConstants.PIECE_TYPE_DEAD :int = 1;
//        public static constConstants.PIECE_TYPE_EMPTY :int = 2;
//        public static constConstants.PIECE_TYPE_INVISIBLE :int = 3;
//        public static constConstants.PIECE_TYPE_POTENTIALLY_DEAD :int = 4;
//        
//        public static const COLOR_DEAD :int = 0x747474;
//        public static const COLOR_EMPTY :int = 0xffffff;
//        public static const COLOR_POTENTIALLY_DEAD :int = 0x999999;
//        
//        public static constConstants.PIECE_COLORS_ARRAY:Array = new Array(0x1add25, 0xf2ab11, 0x1161f2, 0xf211ab, 0x00dcff);
        
        
    }
}