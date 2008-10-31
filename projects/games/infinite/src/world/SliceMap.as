package world
{
	import arithmetic.BoardCoordinates;
	import arithmetic.Vector;
	
	/**
	 * A slice map is a way of keeping track of a visited region within the map. 
	 */
	public class SliceMap
	{
		public function SliceMap()
		{
		}

		public function directionFrom (position:BoardCoordinates) :Vector
		{
			const found:Slice = _rows[position.y] as Slice;
			if (found == null) {
				return null;
			}
			return found.directionFrom(position.x);		
		} 		

		public function expandToInclude (position:BoardCoordinates) :void
		{
			//Log.debug ("expanding slicemap to include :"+position);
			const found:Slice = _rows[position.y] as Slice;
			if (found == null) {
				//Log.debug ("adding new row to slicemap");
				_rows[position.y] = new Slice(position.x, position.x);
			} else {
				_rows[position.y] = found.expandedToInclude(position.x);
			}
		}		

		protected var _rows:Array = new Array();
	}
}