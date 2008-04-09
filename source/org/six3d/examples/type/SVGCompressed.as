package org.six3d.examples.type {
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.net.URLRequest;
	
	import org.six3d.display.DisplayObject3D;
	import org.six3d.display.Scene3D;
	import org.six3d.display.Text3D;
	import org.six3d.typography.CompressedType;
	import org.six3d.utils.FPSUtil;	

	/**
	 * @private
	 * @author Robert Sköld, bob@six3d.org
	 */
	public class SVGCompressed extends Sprite {
		
		private var _scene : Scene3D;
		private var _root : DisplayObject3D;

		public function SVGCompressed() {
			stage.align = "TL";
			stage.scaleMode = "noScale";
			
			setupScene();
			loadType();
			
			new FPSUtil( this );
		}

		private function setupScene() : void {
			var container : Sprite = new Sprite();
			container.x = 250;
			container.y = 200;
			addChild( container );
			_scene = new Scene3D( container );
			_root = _scene.addChild( new DisplayObject3D( "root" ) );
		}
		
		private function loadType() : void {
			var type : CompressedType = new CompressedType();
			type.addEventListener(Event.COMPLETE , onTypeLoaded );
			type.load( new URLRequest( "fonts/arial/arial.far" ) );
		}
		
		private function onTypeLoaded( event : Event ) : void {
			var arial : CompressedType = event.target as CompressedType;
			var text : Text3D = new Text3D();
			text.typography = arial;
			text.size = 5;
			text.text = "HELLO ARIAL WORLD!";
			_root.addChild( text );
			
			addEventListener( Event.ENTER_FRAME , rotate);
		}
		
		private function rotate(event : Event) : void {
			_root.rotationY = ( mouseX - 225 ) / 10;
			_root.rotationX = -( mouseY - 200 ) / 10;
		}
	}
}
