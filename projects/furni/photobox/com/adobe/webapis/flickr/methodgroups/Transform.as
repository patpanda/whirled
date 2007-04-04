/*
Adobe Systems Incorporated(r) Source Code License Agreement
Copyright(c) 2005 Adobe Systems Incorporated. All rights reserved.
	
Please read this Source Code License Agreement carefully before using
the source code.
	
Adobe Systems Incorporated grants to you a perpetual, worldwide, non-exclusive,
no-charge, royalty-free, irrevocable copyright license, to reproduce,
prepare derivative works of, publicly display, publicly perform, and
distribute this source code and such derivative works in source or
object code form without any attribution requirements.
	
The name "Adobe Systems Incorporated" must not be used to endorse or promote products
derived from the source code without prior written permission.
	
You agree to indemnify, hold harmless and defend Adobe Systems Incorporated from and
against any loss, damage, claims or lawsuits, including attorney's
fees that arise or result from your use or distribution of the source
code.
	
THIS SOURCE CODE IS PROVIDED "AS IS" AND "WITH ALL FAULTS", WITHOUT
ANY TECHNICAL SUPPORT OR ANY EXPRESSED OR IMPLIED WARRANTIES, INCLUDING,
BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
FOR A PARTICULAR PURPOSE ARE DISCLAIMED. ALSO, THERE IS NO WARRANTY OF
NON-INFRINGEMENT, TITLE OR QUIET ENJOYMENT. IN NO EVENT SHALL MACROMEDIA
OR ITS SUPPLIERS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOURCE CODE, EVEN IF
ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

package com.adobe.webapis.flickr.methodgroups {
	
	import com.adobe.webapis.flickr.events.FlickrResultEvent;
	import com.adobe.webapis.flickr.*;
	import flash.events.Event;
	import flash.net.URLLoader;

	/**
	 * Broadcast as a result of the rotate method being called
	 *
	 * The event contains the following properties
	 *	success	- Boolean indicating if the call was successful or not
	 *	data - When success is true, an empty object
	 *		   When success is false, contains an "error" FlickrError instance
	 *
	 * @see #rotate
	 * @see com.adobe.service.flickr.FlickrError
	 * @langversion ActionScript 3.0
	 * @playerversion Flash 8.5
	 * @tiptext
	 */
	[Event(name="photosTransformRotate", 
		 type="com.adobe.webapis.flickr.events.FlickrResultEvent")]
	
	/**
	 * Contains the methods for the Transform method group in the Flickr API.
	 * 
	 * Even though the events are listed here, they're really broadcast
	 * from the FlickrService instance itself to make using the service
	 * easier.
	 */
	public class Transform {
	
		/** 
		 * A reference to the FlickrService that contains the api key
		 * and logic for processing API calls/responses
		 */
		private var _service:FlickrService;
	
		/**
		 * Construct a new Transform "method group" class
		 *
		 * @param service The FlickrService this method group
		 *		is associated with.
		 * @langversion ActionScript 3.0
		 * @playerversion Flash 8.5
		 * @tiptext
		 */
		public function Transform( service:FlickrService ) {
			_service = service;
		}
	
		/**
		 * Rotate a photo.
		 *
		 * This method requires authentication with WRITE permission.
		 *
		 * @param photo_id The id of the photo to rotate.
		 * @param degrees The amount of degrees by which to rotate the photo (clockwise)
		 *			from it's current orientation. Valid values are 90, 180 and 270.
		 * @see http://www.flickr.com/services/api/flickr.photos.transform.rotate.html
		 * @langversion ActionScript 3.0
		 * @playerversion Flash 8.5
		 * @tiptext
		 */
		public function rotate( photo_id:String, degrees:Number ):void {
			// Let the Helper do the work to invoke the method			
			MethodGroupHelper.invokeMethod( _service, rotate_result, 
								   "flickr.photos.transform.rotate", 
								   false,
								   new NameValuePair( "photo_id", photo_id ),
								   new NameValuePair( "degrees", degrees.toString() ) );
		}
		
		/**
		 * Capture the result of the rotate call, and dispatch
		 * the event to anyone listening.
		 *
		 * @param event The complete event generated by the URLLoader
		 * 			that was used to communicate with the Flickr API
		 *			from the invokeMethod method in MethodGroupHelper
		 */
		private function rotate_result( event:Event ):void {
			// Create a PHOTOS_TRANSFORM_ROTATE event
			var result:FlickrResultEvent = new FlickrResultEvent( FlickrResultEvent.PHOTOS_TRANSFORM_ROTATE );

			// Have the Helper handle parsing the result from the server - get the data
			// from the URLLoader which correspondes to the result from the API call
			MethodGroupHelper.processAndDispatch( _service, 
												  URLLoader( event.target ).data, 
												  result );
		}
		
	}	
	
}