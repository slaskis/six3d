package org.six3d.svg {	import flash.geom.Point;		import org.six3d.geom.CubicBezier;	import org.six3d.geom.QuadBezier;	import org.six3d.utils.StringUtil;			public class PathData {		private var _motif : Array;		private var _fill : Object;		private var _stroke : Object;		private var _rotation : Number;				private static var _lastP : Point;		private static var _lastC : Point;		private static var _firstP : Point;		private static var _length : uint;		private static var _current : Number;		/**	 	 * SVG Path Data Parser, takes a path node and parses it to Motif-friendly arrays. Or it takes just plain Path Data.	 	 * @author Robert Sköld, bob@six3d.org. Based on work by Helen Triolo		 * @example Node		 *	<path fill="#ED1C24" d="M60,106.1c-14.6,13.7-16.9,41.1-16.9,41.1c25.7-7,35.4-23.4,35.4-23.4C65.3,124.2,60,106.1,60,106.1z"/>		 * @example SVG Path Data string:		 *  "M231 364L176 1141V1466H399V1141L347 364H231ZM184 0V205H391V0H184Z"		 * @see http://www.w3.org/TR/SVG11/paths.html		 */		public function PathData( nodeOrData : * ) {			if( nodeOrData is XML ) {				parseAttributes( nodeOrData );				_motif = parseMotif( nodeOrData.@d );			} else if( nodeOrData is String ) {				_motif = parseMotif( nodeOrData );			} else {				throw new ArgumentError( "Not valid parameter. Needs to be XML or String" );			}		}				/**		 * Returns a Motif-formatted array		 * @return Array		 */				public function getMotifArray() : Array {			return _motif;		}		/**		 * Parses the XML node to get attributes like color and stroke		 * TODO Clean this method up		 * @param node (XML) SVG path node		 */			private function parseAttributes(node : XML) : void {			var color : Number;			if ( node.@fill.toString() != "" ) {				trace( node.@fill );				color = Colors.parse( node.@fill );				if( isNaN(color) ) {					_fill = { color: 0 , alpha: 0 };  // set invisible if undefined				} else {					_fill = { color: color , alpha: 1 };				}			} else _fill = { color: 0xffffff , alpha: 1 }; 					if ( node.@stroke.toString() != "" ) {				trace( node.@stroke );				color = Colors.parse( node.@stroke );				if( isNaN(color) ) {					_stroke = { color: 0 , alpha: 0 };  // set invisible if undefined				} else {					_stroke = { color: color , alpha: 1 };				}			} else _stroke = { color: 0 , width: 0 , alpha: 0 }; 					if( node.@["stroke-width"].toString() != "" ) {				trace( "strokewidth" );				_stroke.width = node.@["stroke-width"];			}				// if stroke and fill are both undefined, set fill to black 			if( node.@fill.toString() == "" && node.@stroke.toString() == "" ) {				_fill = { color: 0 , alpha: 1 };			}					if( node.@transform.toString() != "" ) {				trace( "transform" );				// parse for rotation specification				var trans : String = node.@transform as String;				if( trans.indexOf("rotate") > -1 ) _rotation = parseInt( trans.match(/-?\d+/)[0] );				else _rotation = 0;			} else _rotation = 0;		}		/**		 * Parses Path Data		 * @param d (String), the "d" attribute in the path node		 * @return a draw command formatted array, ex: [ "M" , 123 , 32 , "L" , 32 , 323 , "c" , 234 , 345 , 567 , 345 ]		 */		private function parse( d : String ) : Array {			var res : Array = new Array();			var m : Array = d.match(/([mltcqsvhza])([\d.\- ,])*/ig);			trace( m + "\n" );			for each( var a : String in m ) { 				// a = Q387 -113 347 -182				var values : Array = a.split(/[mltcqsvhza]|,| /ig);				values[0] = a.substr( 0 , 1 );				trace( a , "-" , values );				res = res.concat( values );			}			res.splice( -1 , 1 ); // Remove item after "Z"			return res;		}		/**		 * Parses SVG Path Data		 * TODO Add support for Illustrator formatted Path Data (ex: M60,106.1c-14.6,13.7-16.9,41.1-16.9,41.1c25.7-7,35.4-23.4,35.4-23.4C65.3,124.2,60,106.1,60,106.1z)		 * TODO Prepend with fill and stroke attributes		 * @param d (String), the "d" attribute in the path node		 * @return a motif formatted array, ex: [ "M" , [ 123 , 32 ] ], [ "L" , [ 32 , 323 ] ], [ "c" , [ 234 , 345 , 567 , 345 ] ] ]		 */		public static function parseMotif( d : String ) : Array {			d = cleanPathData( d );			_lastC = new Point();			_lastP = new Point();			var res : Array = new Array();			var m : Array = d.match(/([mltcqsvhza])([\d.\- ,])*/ig);//			trace( m + "\n" );			_length = m.length;			_current = 0;			for each( var a : String in m ) { 				// a = Q387 -113 347 -182				var type : String = a.substr( 0 , 1 );				var values : Array = a.match(/[-]?\d+/g);//				trace( type , values );				_current++;				parseType( type , values , res );			}			return res;		}				private static function cleanPathData( d : String ) : String {			d = d.replace( /\n/g , " " ); // strip \n from d			d = StringUtil.singleWhitespace( d );			d = StringUtil.trim( d );			return d;		}				/**		 * Converts the SVG Path arrays to Motif arrays, which can then be used by flash to draw.		 * @param type (String), SVG Path Data type, ex: "M" for moveTo or "c" for relative Cubic curve		 * @param values (Array), array of values for the type		 * @param results (Array), an array with motif formatted arrays, ex: [ "M" , [ 123 , 32 ] ]		 */		private static function parseType( type : String , values : Array , results : Array ) : void {			var c1 : Point; var c2 : Point; var p2 : Point;			var cb : CubicBezier; var qb : QuadBezier;			var arr : Array;			switch( type ) {				case "M": // M , [ x , y ]				case "L": // L , [ x , y ]					results.push( [ type , values ] );					if( !_firstP ) _firstP = new Point( values[0] , values[1] );					_lastP = new Point( values[0] , values[1] );					break;				case "m": // m , [ x+ , y+ ]				case "l": // l , [ x+ , y+ ]					_lastP = new Point( _lastP.x + values[0] , _lastP.y + values[1] );					results.push( [ type , [ _lastP.x , _lastP.y ] ] );					break;				case "H": // H , [ x , y ]					_lastP = new Point( values[0] , _lastP.y );					results.push( [ "L" , [ _lastP.x , _lastP.y ] ] );					break;				case "h": // h , [ x+ , y+ ]					_lastP = new Point( _lastP.x + values[0] , _lastP.y );					results.push( [ "L" , [ _lastP.x , _lastP.y ] ] );					break;				case "V": // V , [ y ]					_lastP = new Point( _lastP.x , values[0] );					results.push( [ "L" , [ _lastP.x , _lastP.y ] ] );					break;				case "v": // v , [ y+ ]					_lastP = new Point( _lastP.x , _lastP.y + values[0] );					results.push( [ "L" , [ _lastP.x , _lastP.y ] ] );					break;				case "Q": // Q , [ cx , cy , x , y ]					results.push( [ "C" , values ] );					_lastP = new Point( values[2] , values[3] );					_lastC = new Point( values[0] , values[1] );					break;				case "q": // q , [ cx+ , cy+ , x+ , y+ ]					_lastC = new Point( _lastP.x + values[0] , _lastP.y + values[1] );					_lastP = new Point( _lastP.x + values[2] , _lastP.y + values[3] );					results.push( [ "C" , [ _lastC.x , _lastC.y , _lastP.x , _lastP.y ] ] );					break;				case "T": // T , [ x , y ]					_lastC = new Point( _lastP.x + ( _lastP.x - _lastC.x ) , _lastP.y + ( _lastP.y - _lastC.y ) );					_lastP = new Point( values[0] , values[1] );					results.push( [ "C" , [ _lastC.x , _lastC.y , _lastP.x , _lastP.y ] ] );					break;				case "t": // t , [ x+ , y+ ]					_lastC = new Point( _lastP.x + ( _lastP.x - _lastC.x ) , _lastP.y + ( _lastP.y - _lastC.y ) );					_lastP = new Point( _lastP.x + values[0] , _lastP.x + values[1] );					results.push( [ "C" , [ _lastC.x , _lastC.y , _lastP.x , _lastP.y ] ] );					break;				case "C": // C , [ cx1 , cy1 , cx2 , cy2 , x , y ]					c1 = new Point( values[0] , values[1] );					c2 = new Point( values[2] , values[3] );					p2 = new Point( values[4] , values[5] );					cb = new CubicBezier( _lastP , c1 ,c2 , p2 );					arr = cb.getQuadBeziers();					while( arr.length > 0 ) {						qb = arr.shift() as QuadBezier;						results.push( [ "C" , qb.toPathArray() ] );					}					_lastP = p2;					_lastC = c2;					break;				case "c": // c , [ cx1+ , cy1+ , cx2+ , cy2+ , x+ , y+ ]					// TODO Test and make sure this returns correct values 					c1 = new Point( _lastP.x + values[0] , _lastP.y + values[1] );					c2 = new Point( _lastP.x + values[2] , _lastP.y + values[3] );					p2 = new Point( _lastP.x + values[4] , _lastP.y + values[5] );					cb = new CubicBezier( _lastP , c1 ,c2 , p2 );					arr = cb.getQuadBeziers();					while( arr.length > 0 ) {						qb = arr.shift() as QuadBezier;						results.push( [ "C" , qb.toPathArray() ] );					}					_lastP = p2;					_lastC = c2;					break;				case "S": // S , [ cx , cy , x , y ]					c1 = new Point( _lastP.x + ( _lastP.x - _lastC.x ) , _lastP.y + ( _lastP.y - _lastC.y ) );					c2 = new Point( values[0] , values[1] );					p2 = new Point( values[2] , values[3] );					cb = new CubicBezier( _lastP , c1 , c2 , p2 );					arr = cb.getQuadBeziers();					while( arr.length > 0 ) {						qb = arr.shift() as QuadBezier;						results.push( [ "C" , qb.toPathArray() ] );					}					_lastP = p2;					_lastC = c2;					break;				case "s": // s , [ cx+ , cy+ , x+ , y+ ]					// TODO Test and make sure this returns correct values 					c1 = new Point( _lastP.x + ( _lastP.x - _lastC.x ) , _lastP.y + ( _lastP.y - _lastC.y ) );					c2 = new Point( _lastP.x + values[0] , _lastP.y + values[1] );					p2 = new Point( _lastP.x + values[2] , _lastP.y + values[3] );					cb = new CubicBezier( _lastP , c1 , c2 , p2 );					arr = cb.getQuadBeziers();					while( arr.length > 0 ) {						qb = arr.shift() as QuadBezier;						results.push( [ "C" , qb.toPathArray() ] );					}					_lastP = p2;					_lastC = c2;					break;				case "Z": // z				case "z": // Z					if( _firstP.x != _lastP.x || _firstP.y != _lastP.y ) {						// TODO Find out when this should be used - according to SVG 1.1 Spec it should always be called? 						results.push([ "L" , [ _firstP.x , _firstP.y ] ]);					}					if( _current == _length ) { // Only call if it's the last "type"						results.push( [ "E" ] ); 					}					break;			}		}		/**		 * @method makeDrawCommands		 * @param commands (Array) array of svg draw commands (as output from extractCommands)		 * @description Convert svg draw commands to array of ASVDrawing commands: drawCmds		 *		private function makeDrawCommands( commands : Array ) : void {			var j : Number = 0;			var qc : Array;			var firstP : Object;			var lastP : Object;			var lastC : Object;			var cmd : String;					while (j < commands.length) {				cmd = commands[j++];				switch (cmd) {					case "M" :						// moveTo point						firstP = lastP = {x:Number(commands[j]) , y:Number(commands[j + 1])};						_commands.push([ 'F', [ _fill.color, _fill.alpha ] ]);						_commands.push([ 'S', [ _stroke.width, _stroke.color, _stroke.alpha ] ]);						_commands.push([ 'M', [ firstP.x, firstP.y ] ]);						j += 2;						if (j < commands.length && !isNaN(Number(commands[j]))) {  							while (j < commands.length && !isNaN(Number(commands[j]))) {								// if multiple points listed, add the rest as lineTo points								lastP = {x:Number(commands[j]) , y:Number(commands[j + 1])};								_commands.push([ 'L', [ lastP.x, lastP.y ] ]);								firstP = lastP;								j += 2;							}						}						break;									case "l" :						while (j < commands.length && !isNaN(Number(commands[j]))) {							lastP = {x:lastP.x + Number(commands[j]) , y:lastP.y + Number(commands[j + 1])};							_commands.push([ 'L', [ lastP.x, lastP.y ] ]);							firstP = lastP;							j += 2;						}						break;									case "L" :						while (j < commands.length && !isNaN(Number(commands[j]))) {							lastP = {x:Number(commands[j]) , y:Number(commands[j + 1])};							_commands.push([ 'L', [ lastP.x, lastP.y ] ]);												firstP = lastP;							j += 2;						}						break;									case "h" :						while (j < commands.length && !isNaN(Number(commands[j]))) {							lastP = {x:lastP.x + Number(commands[j]) , y:lastP.y};							_commands.push([ 'L', [ lastP.x, lastP.y ] ]);							firstP = lastP;							j += 1;						}						break;									case "H" :						while (j < commands.length && !isNaN(Number(commands[j]))) {							lastP = {x:Number(commands[j]) , y:lastP.y};							_commands.push([ 'L', [ lastP.x, lastP.y ] ]);							firstP = lastP;							j += 1;						}						break;									case "v" :						while (j < commands.length && !isNaN(Number(commands[j]))) {							lastP = {x:lastP.x , y:lastP.y + Number(commands[j])};							_commands.push([ 'L', [ lastP.x, lastP.y ] ]);							firstP = lastP;							j += 1;						}						break;									case "V" :						while (j < commands.length && !isNaN(Number(commands[j]))) {							lastP = {x:lastP.x , y:Number(commands[j])};							_commands.push([ 'L', [ lastP.x, lastP.y ] ]);							firstP = lastP;							j += 1;						}						break;						case "q" :						while (j < commands.length && !isNaN(Number(commands[j]))) {							// control is relative to lastP, not lastC							lastC = {x:lastP.x + Number(commands[j]) , y:lastP.y + Number(commands[j + 1])};							lastP = {x:lastP.x + Number(commands[j + 2]) , y:lastP.y + Number(commands[j + 3])};							_commands.push([ 'C', [ lastC.x, lastC.y, lastP.x, lastP.y ] ]);							firstP = lastP;							j += 4;						}						break;									case "Q" :						while (j < commands.length && !isNaN(Number(commands[j]))) {							lastC = {x:Number(commands[j]) , y:Number(commands[j + 1])};												lastP = {x:Number(commands[j + 2]) , y:Number(commands[j + 3])};							_commands.push([ 'C', [ lastC.x, lastC.y, lastP.x, lastP.y ] ]);							firstP = lastP;							j += 4;						}						break;						case "t" :						while (j < commands.length && !isNaN(Number(commands[j]))) {							// control is relative to lastP, not lastC							lastP = {x:lastP.x + Number(commands[j + 2]) , y:lastP.y + Number(commands[j + 3])};							_commands.push([ 'C', [ lastP.x + (lastP.x - lastC.x), lastP.y + (lastP.y - lastC.y), lastP.x, lastP.y ] ]);							lastC = {x:lastP.x + Number(commands[j]) , y:lastP.y + Number(commands[j + 1])};							firstP = lastP;							j += 4;						}						break;									case "T" :						while (j < commands.length && !isNaN(Number(commands[j]))) {										lastP = {x:Number(commands[j + 2]) , y:Number(commands[j + 3])};							_commands.push([ 'C', [ lastP.x + (lastP.x - lastC.x), lastP.y + (lastP.y - lastC.y), lastP.x, lastP.y ] ]);							lastC = {x:Number(commands[j]) , y:Number(commands[j + 1])};									firstP = lastP;							j += 4;						}						break;									case "c" :						while (j < commands.length && !isNaN(Number(commands[j]))) {							// don't save if c1.x=c1.y=c2.x=c2.y=0 							if (!Number(commands[j]) && !Number(commands[j + 1]) && !Number(commands[j + 2]) && !Number(commands[j + 3])) {							} else {								qc = [];								MathUtil.getQuadBez_RP({x:lastP.x , y:lastP.y}, {x:lastP.x + Number(commands[j]) , y:lastP.y + Number(commands[j + 1])}, {x:lastP.x + Number(commands[j + 2]) , y:lastP.y + Number(commands[j + 3])}, {x:lastP.x + Number(commands[j + 4]) , y:lastP.y + Number(commands[j + 5])}, 1, qc);								for (var ii = 0;ii < qc.length; ii++) {									_commands.push([ 'C', [ qc[ii].cx, qc[ii].cy, qc[ii].p2x, qc[ii].p2y ] ]);								}								lastC = {x:lastP.x + Number(commands[j + 2]) , y:lastP.y + Number(commands[j + 3])}								lastP = {x:lastP.x + Number(commands[j + 4]) , y:lastP.y + Number(commands[j + 5])};								firstP = lastP;							}							j += 6;						}						break;						case "C" :						do {							// don't save if c1.x=c1.y=c2.x=c2.y=0 							if (!Number(commands[j]) && !Number(commands[j + 1]) && !Number(commands[j + 2]) && !Number(commands[j + 3])) {							} else {								qc = [];								MathUtil.getQuadBez_RP({x:firstP.x , y:firstP.y}, {x:Number(commands[j]) , y:Number(commands[j + 1])}, {x:Number(commands[j + 2]) , y:Number(commands[j + 3])}, {x:Number(commands[j + 4]) , y:Number(commands[j + 5])}, 1, qc);								for (var ii = 0;ii < qc.length; ii++) {									_commands.push([ 'C', [ qc[ii].cx, qc[ii].cy, qc[ii].p2x, qc[ii].p2y ] ]);								}								lastC = {x:Number(commands[j + 2]) , y:Number(commands[j + 3])}								lastP = {x:Number(commands[j + 4]) , y:Number(commands[j + 5])};								firstP = lastP;							}							j += 6;						} while (j < commands.length && !isNaN(Number(commands[j])));						break;									case "s" :						while (j < commands.length && !isNaN(Number(commands[j]))) {							// don't save if c1.x=c1.y=c2.x=c2.y=0 							if (!Number(commands[j]) && !Number(commands[j + 1]) && !Number(commands[j + 2]) && !Number(commands[j + 3])) {							} else {								qc = [];								MathUtil.getQuadBez_RP({x:firstP.x , y:firstP.y}, {x:lastP.x + (lastP.x - lastC.x) , y:lastP.y + (lastP.y - lastC.y)}, {x:lastP.x + Number(commands[j]) , y:lastP.y + Number(commands[j + 1])}, {x:lastP.x + Number(commands[j + 2]) , y:lastP.y + Number(commands[j + 3])}, 1, qc);								for (var ii = 0;ii < qc.length; ii++) {									_commands.push([ 'C', [ qc[ii].cx, qc[ii].cy, qc[ii].p2x, qc[ii].p2y ] ]);								}								lastC = {x:lastP.x + Number(commands[j]) , y:lastP.y + Number(commands[j + 1])};								lastP = {x:lastP.x + Number(commands[j + 2]) , y:lastP.y + Number(commands[j + 3])};								firstP = lastP;							}							j += 4;						}						break;									case "S" :						while (j < commands.length && !isNaN(Number(commands[j]))) {							// don't save if c1.x=c1.y=c2.x=c2.y=0 							if (!Number(commands[j]) && !Number(commands[j + 1]) && !Number(commands[j + 2]) && !Number(commands[j + 3])) {							} else {								qc = [];								MathUtil.getQuadBez_RP({x:firstP.x , y:firstP.y}, {x:lastP.x + (lastP.x - lastC.x) , y:lastP.y + (lastP.y - lastC.y)}, {x:Number(commands[j]) , y:Number(commands[j + 1])}, {x:Number(commands[j + 2]) , y:Number(commands[j + 3])}, 1, qc);								for (var ii = 0;ii < qc.length; ii++) {									_commands.push([ 'C', [ qc[ii].cx, qc[ii].cy, qc[ii].p2x, qc[ii].p2y ] ]);								}								lastC = {x:Number(commands[j]) , y:Number(commands[j + 1])};								lastP = {x:Number(commands[j + 2]) , y:Number(commands[j + 3])};								firstP = lastP;							}							j += 4;						}						break;									case "z" :					case "Z" :						if (firstP.x != lastP.x || firstP.y != lastP.y) {							_commands.push([ 'L', [ firstP.x, firstP.y ] ]);						}						j++;						break;						} // end switch			}		}		 */	}}