package org.six3d.utils {
	import flash.display.Bitmap;	import flash.display.BitmapData;	import flash.display.DisplayObject;	import flash.display.GradientType;	import flash.display.SpreadMethod;	import flash.display.Sprite;	import flash.events.TimerEvent;	import flash.geom.Matrix;	import flash.utils.Timer;	
	public class Reflect {
		private var _bmp : BitmapData;
		private var _reflection : Bitmap;
		private var _gradient : Sprite;
		private var _bounds : Object;
		private var _timer : Timer;
		private var _target : Sprite;

		
		function Reflect( target : Sprite , ratio : Number = 255 , alpha : Number = 1 , updateTime : Number = 5 , dropOff : Number = 1 , distance : Number = 0 ){
			_target = target;
			
			//store the bounds of the reflection
			_bounds = new Object();
			_bounds.width = _target.width;
			_bounds.height = _target.height;
			
			//create the BitmapData that will hold a snapshot of the movie clip
			_bmp = new BitmapData(_bounds.width, _bounds.height, false, 0xFF0000);
			_bmp.draw(_target);
			
			_reflection = new Bitmap(_bmp);
			_reflection.scaleY = -1;
			_reflection.y = (_bounds.height*2) + distance;
			_target.addChild( _reflection );
			
			_gradient = new Sprite();
			_target.addChild( _gradient );
			
			//set the values for the gradient fill
		 	var colors:Array = [0xFF0000, 0x00FFFF];
		 	var alphas:Array = [alpha, 0]; // 0 - 1
		  	var ratios:Array = [0, ratio]; // 0 - 255
			//create the Matrix and create the gradient box
		  	var matr:Matrix = new Matrix();
		  	//set the height of the Matrix used for the gradient mask
			var matrixHeight:Number;
			if (dropOff <= 0) {
				matrixHeight = _bounds.height;
			} else {
				matrixHeight = _bounds.height/dropOff;
			}
			matr.createGradientBox(_bounds.width, matrixHeight, (90/180)*Math.PI, 0, 0);
		  	//create the gradient fill
			_gradient.graphics.beginGradientFill( GradientType.LINEAR , colors, alphas, ratios, matr, SpreadMethod.PAD );  
		    _gradient.graphics.drawRect(0,0,_bounds.width,_bounds.height);
			_gradient.graphics.endFill();
			//position the mask over the reflection clip			
			_gradient.y = _reflection.y - _reflection.height;
			//cache clip as a bitmap so that the gradient mask will function
			_gradient.cacheAsBitmap = true;
			_reflection.cacheAsBitmap = true;
			//set the mask for the reflection as the gradient mask
//			_reflection.mask = _gradient;
			
			//if we are updating the reflection for a video or animation do so here
			if(updateTime > -1){
				_timer = new Timer( updateTime );
				_timer.addEventListener( TimerEvent.TIMER , update );
				_timer.start();
			}
		}
		
		
		public function setBounds(w:Number,h:Number):void{
			//allows the user to set the area that the reflection is allowed
			//this is useful for clips that move within themselves
			_bounds.width = w;
			_bounds.height = h;
			_gradient.width = _bounds.width;
			redrawBMP();
		}
		public function redrawBMP():void {
			// redraws the bitmap reflection - Mim Gamiet [2006]
			_bmp.dispose();
			_bmp = new BitmapData(_bounds.width, _bounds.height, true, 0xFF0000);
			_bmp.draw(_target);
		}
		private function update( event : TimerEvent = null ):void {
			//updates the reflection to visually match the movie clip
			_bmp = new BitmapData(_bounds.width, _bounds.height, true, 0xFF0000);
			_bmp.draw(_target);
			_reflection.bitmapData = _bmp;
		}
		public function destroy():void{
			//provides a method to remove the reflection
			_target.removeChild(_reflection);
			_reflection = null;
			_bmp.dispose();
//			clearInterval(updateInt);
			if( _timer ) _timer.stop();
			_target.removeChild(_gradient);
		}
	}
}