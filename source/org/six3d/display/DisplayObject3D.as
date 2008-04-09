package org.six3d.display {	import org.six3d.display.Scene3D;	import org.six3d.geom.Angle;	import org.six3d.geom.Matrix3D;	import org.six3d.geom.Point3D;		/**	 * @author Robert Sköld, bob@six3d.org	 * TODO Z-ordering issue: if putting a text on top of a plane, it's still visible if the plane is rotated 	 */	public class DisplayObject3D extends DisplayObjectContainer3D {		private static var _instanceNum : int = 0;		protected var _render : Boolean = true;		protected var _matrix : Matrix3D;		protected var _concatMatrix : Matrix3D;		protected var _parent : DisplayObjectContainer3D;		protected var _motif : Array;				private var _visible : Boolean = true;		private var _y : Number = 0;		private var _x : Number = 0;		private var _z : Number = 0;		private var _scaleX : Number = 1;		private var _scaleY : Number = 1;		private var _scaleZ : Number = 1;		private var _rotationY : Number = 0;		private var _rotationX : Number = 0;		private var _rotationZ : Number = 0;		public function DisplayObject3D( name : String = null ) {			super();			name = name || "instance" + _instanceNum++;			sprite.name = name;			_matrix = new Matrix3D();			_concatMatrix = _matrix.clone();			_motif = new Array();		}				/**		 * Hook method, which is called when DisplayObject3D is added to the children list		 */		public function initialize() : void {}		public function get name() : String {			return sprite.name;		}		public function get depth() : int {			return parent.sprite.getChildIndex( sprite );		}		public function set depth( index : int ) : void {			parent.sprite.swapChildrenAt(depth, index);		}		public function get alpha() : Number {			return sprite.alpha;		}		public function set alpha( value : Number ) : void {			sprite.alpha = value;		}		public function get visible() : Boolean {			return _visible;		}		public function set visible( value : Boolean ) : void {			_visible = value;			askRendering(true);		}		public function set mask( do3d : DisplayObject3D ) : void {			sprite.mask = do3d.sprite;		}				public function get parent() : DisplayObjectContainer3D {			return _parent;		}		public function set parent( par : DisplayObjectContainer3D ) : void {			_parent = par;		}		public function get mouseX() : Number {			return _concatMatrix.getInverseCoordinates( scene.sprite.mouseX, scene.sprite.mouseY, scene.viewdistance).x;		}		public function get mouseY() : Number {			return _concatMatrix.getInverseCoordinates( scene.sprite.mouseX, scene.sprite.mouseY, scene.viewdistance).y;		}		public function get mouseXY() : Point3D {			return _concatMatrix.getInverseCoordinates( scene.sprite.mouseX, scene.sprite.mouseY, scene.viewdistance);		}		public function get x() : Number {			return _x;		}		public function set x(value : Number) : void {			_x = value;			askRendering(true);		}		public function get y() : Number {			return _y;		}		public function set y(value : Number) : void {			_y = value;			askRendering(true);		}		public function get z() : Number {			return _z;		}		public function set z(value : Number) : void {			_z = value;			askRendering(true);		}		public function set scale(value : Number) : void {			_scaleX = _scaleY = value;			askRendering(true);		}		public function get scaleX() : Number {			return _scaleX;		}		public function set scaleX(value : Number) : void {			_scaleX = value;			askRendering(true);		}		public function get scaleY() : Number {			return _scaleY;		}		public function set scaleY(value : Number) : void {			_scaleY = value;			askRendering(true);		}		public function get scaleZ() : Number {			return _scaleZ;		}		public function set scaleZ(value : Number) : void {			_scaleZ = value;			askRendering(true);		}		public function get rotationX() : Number {			return _rotationX;		}		public function set rotationX(value : Number) : void {			_rotationX = Angle.formatRotation(value);			askRendering(true);		}		public function get rotationY() : Number {			return _rotationY;		}		public function set rotationY(value : Number) : void {			_rotationY = Angle.formatRotation(value);			askRendering(true);		}		public function get rotationZ() : Number {			return _rotationZ;		}		public function set rotationZ(value : Number) : void {			_rotationZ = Angle.formatRotation(value);			askRendering(true);		}				public function get point() : Point3D {			return new Point3D( x , y , z );		}		public function get concatMatrix() : Matrix3D {			return _concatMatrix;		}		public override function askRendering( renderScene : Boolean = false ) : void {			if( scene && renderScene ) {				_render = true;				scene.addToQueue( this );			}			super.askRendering( renderScene );		}		public function lookAt( do3d : DisplayObject3D ) : void {			var position : Point3D = new Point3D( x, y, z);			var target : Point3D = new Point3D( do3d.x , do3d.y , do3d.z );			var zAxis : Point3D = Point3D.sub(target, position);			zAxis.normalize();			//			trace( "Self: " + position );//			trace( "Target: " + target );//			trace( zAxis , " " , zAxis.modulo );			if( zAxis.modulo > 0.1 ) {				var xAxis : Point3D = Point3D.cross(zAxis, new Point3D( 0 , 1 , 0 ) );				xAxis.normalize();				var yAxis : Point3D = Point3D.cross(zAxis, xAxis);				yAxis.normalize();				var look : Matrix3D = _matrix;				look.a = xAxis.x * _scaleX;				look.b = xAxis.y * _scaleX;				look.c = xAxis.z * _scaleX;							look.d = -yAxis.x * _scaleY;				look.e = -yAxis.y * _scaleY;				look.f = -yAxis.z * _scaleY;							look.g = zAxis.x * _scaleZ;				look.h = zAxis.y * _scaleZ;				look.i = zAxis.z * _scaleZ;												// TODO: Implement scale				askRendering( true );			} else {				trace("lookAt Error");			}		}				public override function render() : void {			if( !scene ) return;			if( !visible && sprite.visible ) {				sprite.visible = false;			} else if( visible ) {				if( !sprite.visible ) {					sprite.visible = true;				}				if( _render ) {					getMatrices();					sprite.graphics.clear();					var motif : Array = Motif.clone( _motif );					Motif.project(						motif, 						concatMatrix, 						scene.viewdistance					);					Motif.draw( sprite, motif );					_render = false;				}				// Render the children too (if there are any)				super.render();			}		}				protected function getMatrices() : void {			_matrix.createBox(scaleX, scaleY, scaleZ, Angle.degreesToRadians(rotationX), Angle.degreesToRadians(rotationY), Angle.degreesToRadians(rotationZ), x, y, z);			if( _parent == null || !( _parent is DisplayObject3D ) ) {				_concatMatrix = _matrix.clone();			} else {				_concatMatrix = DisplayObject3D( _parent ).concatMatrix.clone();				_concatMatrix.concat(_matrix);			}		}				public override function addEventListener( type : String , listener : Function , useCapture : Boolean = false , priority : int = 0 , useWeakReference : Boolean = true ) : void {			super.addEventListener( type , listener , useCapture , priority , useWeakReference );		}		public override function toString() : String {			return "[DisplayObject3D " + name + "]";		}	}}