package org.six3d.examples.news {	import flash.display.Sprite;	import flash.events.Event;	import flash.events.IOErrorEvent;	import flash.events.SecurityErrorEvent;	import flash.net.URLLoader;	import flash.net.URLRequest;	import flash.net.URLRequestMethod;		import org.six3d.display.DisplayObject3D;	import org.six3d.display.Scene3D;	import org.six3d.display.Text3D;	import org.six3d.typography.CompressedType;	import org.six3d.utils.FPSUtil;		import com.adobe.utils.XMLUtil;	import com.adobe.xml.syndication.rss.Item20;	import com.adobe.xml.syndication.rss.RSS20;		/**	 * @private	 * @author Robert Sköld, robert@bennybula.com	 */	public class NewsReader extends Sprite {		public static var RSS_URL : String = "http://rss.news.yahoo.com/rss/tech";		private var _scene : Scene3D;		private var _groups : Array = new Array( );		private var _root : DisplayObject3D;		public function NewsReader() {			stage.align = "TL";			stage.scaleMode = "noScale";						setupScene();			loadRSS();						new FPSUtil(this);		}		private function loadRSS() : void {			var request : URLRequest = new URLRequest( RSS_URL );			request.method = URLRequestMethod.GET;			var loader : URLLoader = new URLLoader();				loader.addEventListener( Event.COMPLETE , onDataLoad );			loader.addEventListener( IOErrorEvent.IO_ERROR , onIOError );			loader.addEventListener( SecurityErrorEvent.SECURITY_ERROR , onSecurityError );			loader.load( request );		}				private function onSecurityError( event : SecurityErrorEvent ) : void {			trace( "SecurityErrorEvent: Could not load feed because: " + event.text );		}		private function onIOError( event : IOErrorEvent ) : void {			trace( "onIOError: Could not load feed because: " + event.text );		}		private function onDataLoad( event : Event ) : void {			var data : String = String( URLLoader( event.target ).data );			if( !XMLUtil.isValidXML( data ) ) {				trace("Feed does not contain valid XML.");				return;			}				var rss : RSS20 = new RSS20();			rss.parse( data );							var items:Array = rss.items;			for each( var item : Item20 in items ) {				trace( item.title );				drawItem( item );				break;			}			addEventListener( Event.ENTER_FRAME , update );		}				private function drawItem( item : Item20 ) : void {			var group : DisplayObject3D = new DisplayObject3D();			group.x = Math.random() * 1000;			group.y = Math.random() * 1000;			group.z = Math.random() * 1000;			group.rotationY = Math.random() * 360;			_root.addChild( group );			drawText( item.title , 0 , 2 , group );			drawText( item.description , 30 , 1 , group );			_groups.push( group );		}		private function drawText( txt : String , y : int , size : int , parent : DisplayObject3D ) : Text3D {			var txt3d : Text3D = new Text3D();			txt3d.typography = new CompressedType( "fonts/georgia/georgia.far" );			txt3d.size = size;			txt3d.text = txt;			txt3d.y = y;			parent.addChild( txt3d );			return txt3d;		}		private function setupScene() : void {			var container : Sprite = new Sprite();			container.x = 250;			container.y = 200;			addChild(container);			_scene = new Scene3D( container );			_root = new DisplayObject3D( "root" );			_root.z = 100;			_scene.addChild( _root );		}				private function update(event : Event) : void {			for each( var group : DisplayObject3D in _groups ) {				group.rotationY += 2;				/*				var itr : Iterator = group.children.getIterator();				while( itr.hasNext() ) {					var child : DisplayObject3D = itr.next() as DisplayObject3D;					child.rotationY += 2;				}				*/			}		}	}}