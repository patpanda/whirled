package world
{
	import arithmetic.BoardCoordinates;
	
	import flash.events.IEventDispatcher;
	
	/**
	 * This is the principal interface used to access the shared world.  In standalone, a local
	 * implementation will be provided, otherwise an implementation which communicated with the
	 * server via messages will be used.
	 */
	public interface ClientWorld extends IEventDispatcher
	{	
		/**
		 * Return a human readable string describing the type of this world.
		 */	
		function get worldType () :String
		
		/**
		 * A request from the specified client to enter the world.
		 */
		function enter (client:WorldClient) :void
		
		/**
		 * Return the id of this client.
		 */
		function get clientId () :int
		
		/**
		 * Propose to the world that the player be moved to the coordinates supplied.
		 */
		function proposeMove (coords:BoardCoordinates) :void		
	}
}