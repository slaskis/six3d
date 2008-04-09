package org.six3d.typography {	import flash.events.Event;	import flash.net.URLRequest;	import flash.system.System;		import org.six3d.typography.LoadedType;	import org.vanrijkom.far.FarEvent;	import org.vanrijkom.far.FarStream;	/**	 * @author Robert Sköld, bob@six3d.org	 */	public class CompressedType extends LoadedType {
		public function CompressedType( url : String = null ) {			super( url );		}				public override function load( request : URLRequest = null ) : void {			if( !request && _url ) request = new URLRequest( _url );			_memory = System.totalMemory;			var loader : FarStream = new FarStream();			loader.addEventListener(FarEvent.ITEM_UNCOMPRESSED , onFARComplete);			loader.load( request );		}				private function onFARComplete( event : FarEvent ) : void {			var stream : FarStream = event.target as FarStream;			var svg : XML = new XML( stream.itemAt( 0 ).data.toString() );			parseFont( svg );			trace( "Memory font loading took: " + ( System.totalMemory - _memory ) );			dispatchEvent( new Event( Event.COMPLETE ) );		}
	}}