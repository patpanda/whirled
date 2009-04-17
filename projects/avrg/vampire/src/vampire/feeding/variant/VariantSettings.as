package vampire.feeding.variant {

// Settings that can be modified by game variants
public class VariantSettings
{
    public var variant :int;

    public var boardCreatesWhiteCells :Boolean;
    public var playerCreatesWhiteCells :Boolean;
    public var playerWhiteCellCreationTime :Number;
    public var playerCarriesWhiteCells :Boolean;
    public var canDropWhiteCells :Boolean;
    public var scoreCorruption :Boolean;
    public var normalCellBirthTime :Number;
    public var whiteCellBirthTime :Number;
    public var whiteCellNormalTime :Number;
    public var whiteCellExplodeTime :Number;
    public var normalCellSpeed :Number;
    public var whiteCellSpeed :Number;
}

}