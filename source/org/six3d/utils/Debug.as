/*
 * Copyright 2007 (c) Vladimir Bodurov
 * http://blog.bodurov.com
 * 
 * Tracer 1.1 Sep 09, 2007
 */
package org.six3d.utils {
	import flash.events.StatusEvent;
	import flash.net.LocalConnection;
		public class Debug extends Object {
		
		private static var __FlashTracer_DoNotBroadcast:Boolean = false;
		public static function get DoNotBroadcast():Boolean{
			return __FlashTracer_DoNotBroadcast;
		}
		public static function set DoNotBroadcast(val:Boolean):void{
			__FlashTracer_DoNotBroadcast = val;
		}
		
		
		private static var __FlashTracer_DoNotTrace:Boolean = false;
		public static function get DoNotTrace():Boolean{
			return __FlashTracer_DoNotTrace;
		}
		public static function set DoNotTrace(val:Boolean):void{
			__FlashTracer_DoNotTrace = val;
		}
		
		
		
		public static function get stack():String{
			var str:String = "";
			try {
				throw new Error();
			} catch (e:Error) {
				var limiter:String = "\n";
				var stack:String = e.getStackTrace();
				var frames:Array = stack.split("\n\tat");
				frames.shift();//"Error" string
				frames.shift();//this t.stack method
				str = frames.join(limiter);
			}
			return str;
		}
		
		
		public static function str(...arguments):void{
			var strValue:String = arguments.join(" | ");
			if(!__FlashTracer_DoNotTrace){
				trace(strValue);
			}
			if(!__FlashTracer_DoNotBroadcast){
				dispatch(strValue);
			}
		}
		
		public static function lev(...arguments):String{
			var objVal:Object = (arguments.length > 0)?arguments[0]:null;
			var levels:Number = (arguments.length > 1)?Number(arguments[1]):Tracer.MAX_NUMBER_LEVELS;
			var titleVal:String = "";
			if(isNaN(levels)){
				titleVal = arguments[1];
				levels = Tracer.MAX_NUMBER_LEVELS;
			}
			titleVal += (arguments.length > 2)?arguments[2]:"";
			for(var i:Number = 3; i < arguments.length; i++) titleVal += " | " + arguments[i];

			var tr:Tracer = new Tracer(objVal,titleVal,__FlashTracer_DoNotTrace,levels);
			var strData:String = tr.getInfo();
			if(!__FlashTracer_DoNotBroadcast){
				dispatch(strData);
			}
			return strData;
		}
		
		public static function obj(...arguments):String{
			var objVal:Object = (arguments.length > 0)?arguments[0]:null;
			var titleVal:String = (arguments.length > 1)?arguments[1]:"";
			for(var i:Number = 2; i < arguments.length; i++) titleVal += " | " + arguments[i];

			var tr:Tracer = new Tracer(objVal,titleVal,__FlashTracer_DoNotTrace, Tracer.MAX_NUMBER_LEVELS);
			var strData:String = tr.getInfo();
			if(!__FlashTracer_DoNotBroadcast){
				dispatch(strData);
			}
			return strData;
		}
		
		private static function dispatch(strData:String):void{
			localConnection.send("__FlashTracer", "Add", strData);
		}
		
		private static var _localConnection:LocalConnection = null;
		private static function get localConnection():LocalConnection{
			if(_localConnection === null){
				_localConnection =  new LocalConnection();
				_localConnection.addEventListener(StatusEvent.STATUS, function(evt:Object){});
			}
			return _localConnection;
		}
		
	}
}
import flash.utils.describeType;
import flash.utils.getQualifiedClassName;
class Tracer extends Object{
	
	public static const MAX_NUMBER_LEVELS:Number = 255;
	
	private var _object:Object = null;
	private var _title:String;
	private var _supressTrace:Boolean;
	private var _allowedDepth:Number;
	private var _info:StringBuilder;
	private var _indent:Number = 0;
	private var _prevIndent:Number = -1;
	private var _usedObjects:Array;
	
	public static var indentCache:Object = new Object();
	
	private static const PRIMITIVES:Array = ["String", "Number", "Boolean", "Date", "int", "uint"];
	
	private static const INDENT_CHAR:String = "\t";
	
	
	public function Tracer(object:Object, title:String = "", supressTrace:Boolean = false, allowedDepth:Number =  Tracer.MAX_NUMBER_LEVELS){
		this._object = object;
		this._title = title;
		this._supressTrace = supressTrace;
		this._allowedDepth = allowedDepth;
		this._info = new StringBuilder();
		this._usedObjects = new Array();

		this.parse(this._object);
	}
	
	private function parse(object:Object, name:String = "", isInsideCollection:Boolean = false):void{
		if(Tracer.isPrimitive(object)){
			this.parseLiteral(object, name, isInsideCollection);
		}else if(Tracer.isCollectionObject(object)){
			this.parseHierarchicalStructure(object, name, true, isInsideCollection);
		}else if(Tracer.hasProperties(object)){
			this.parseHierarchicalStructure(object, name, false, isInsideCollection);
		}else{
			this.parseLiteral(object, name, isInsideCollection);
		}
	}
	private static function isPrimitive(object:Object):Boolean{
		var name:String = getQualifiedClassName(object);
		for each(var primitive:String in PRIMITIVES){
			if(name === primitive){
				return true;
			}
		}
		return false;
	}
	private static function isCollectionObject(object:Object):Boolean{
		return (object is Array);
	}
	private static function hasProperties(object:Object):Boolean{return true;
		for(var each in object){
			return true;
		}
		for each(var xml:XML in describeType(object).accessor){
			return true;
		}
		return false;
	}
	private static function objectToString(object:Object):String{
		if(object is String){
			return "\""+object.toString().split("\"").join("\\\"")+"\"";
		}else if(object is Date){
			return "Date.parse(\""+object+"\")";
		}else{
			return object.toString();
		}
	}
	private function parseLiteral(object:Object, name:String, isInsideCollection:Boolean = false):void{
		if(object == null) this.appendString(this.generatePropertyName(name)+"null");
		else this.appendString(this.generatePropertyName(name, isInsideCollection)+Tracer.objectToString(object));
	}
	private function generatePropertyName(name:String, isInsideCollection:Boolean = false):String{
		if(name == ""){
			return "";
		}
		if(isInsideCollection){
			return "/*" + name + "*/";
		}else{
			return name + ": ";
		}
	}
	private function getStartLimiter(isCollection:Boolean):String{
		return (isCollection)?"[":"{";
	}
	private function getEndLimiter(isCollection:Boolean):String{
		return (isCollection)?"]":"}";
	}
	private function addObjectToUsed(object:Object):void{
		this._usedObjects.push(object);
	}
	private function isUsed(object:Object):Boolean{
		for each(var value:* in this._usedObjects){
			if(object === value){
				return true;
			}
		}
		return false;
	}
	private function parseHierarchicalStructure(object:Object, name:String, isCollection:Boolean, isInsideCollection:Boolean):void{
		if(object == null){
			this.parseLiteral(object, name);
			return;
		}		
		
		this.appendString(this.generatePropertyName(name, isInsideCollection)+this.getStartLimiter(isCollection));
		this._indent++;
		if(this._indent < this._allowedDepth){
			if(!this.isUsed(object)){
				this.addObjectToUsed(object);
				if(isCollection){
					this.parseCollection(object);
				}else{
					this.parseProperties(object);
				}
			}else{
				this.appendString("/*!!!-Recursion - call to already traced object '"+object+"' !!!*/");
			}
		}else{
			this.appendString("/*!!!-The maximum limit of "+this._indent+" levels to trace has been reached-!!!*/");
		}
		this._indent--;
		this.appendString(this.getEndLimiter(isCollection));
	}
	private function parseCollection(object:Object):void{
		var index:Number = 0;
		for each(var value:* in object){
		  this.parse(value, (index++).toString(), true);
		}
		if(index === 0){
			this._prevIndent++;
		}
	}
	private function parseProperties(object:Object):void{
		for(var name:String in object){
			try{
				this.parse(object[name], name);
			}catch(e:Error){
				this.appendString(nameAttribute + ": null /*!!!-"+e+"-!!!*/");
			}
		}
		for each(var xmlAccs:XML in describeType(object).accessor){
			var nameAttribute:String = xmlAccs.@name;
			try{
				if(object[nameAttribute] == null || object[nameAttribute] == undefined || !object[nameAttribute].propertyIsEnumerable()){
					this.parse(object[nameAttribute], nameAttribute);
				}
			}catch(e:Error){
				this.appendString(nameAttribute + ": null /*!!!-"+e+"-!!!*/");
			}
		}
		for each(var xmlVar:XML in describeType(object).variable){
			try{
				if(object[xmlVar.@name] == null || object[xmlVar.@name] == undefined || !object[xmlVar.@name].propertyIsEnumerable()){
					this.parse(object[xmlVar.@name], xmlVar.@name);
				}
			}catch(e:Error){
				this.appendString(nameAttribute + ": null /*!!!-"+e+"-!!!*/");
			}
		}
	}
	private function traceInfo(info:String):void{
		trace(info);
	}
	private function appendString(object:Object):void{
		this._info.append(this.getIndent()+object);
	}
	private function getIndent():String{
		if(Tracer.indentCache[this._indent] == undefined){
			var sb:StringBuilder = new StringBuilder();
			for(var i:uint = 0; i < this._indent; i++){
				sb.append(Tracer.INDENT_CHAR);
			}
			Tracer.indentCache[this._indent] = "\n"+sb.toString();
		}
		var isSibling = (this._prevIndent == this._indent);
		this._prevIndent = this._indent;
		return ((isSibling)?",":"")+Tracer.indentCache[this._indent];
	}
	public function getInfo():String{
		var info:String = this.infoToString();
		if(!this._supressTrace){
			this.traceInfo(info);
		}
		return info;
	}
	private function infoToString():String{
		var sb:StringBuilder = new StringBuilder();
		sb.append("-------------------------");
		if(this._title != null && this._title != ""){
			sb.append("\n"+this._title);
		}
		sb.append("\nObject type is: ["+getQualifiedClassName(this._object)+"]");
		sb.append("\nObject content is: ");
		sb.append(this._info.toString());
		sb.append("\n-------------------------\n");
		return sb.toString();
	}
}



class StringBuilder{
		
	private var _array:Array;
	
	public function StringBuilder(){
		this._array = [];
	}
	
	public function append(string:String):StringBuilder{
		this._array.push(string);
		return this;
	}
	
	public function appendFormat(string:String, ...arguments):StringBuilder{
		this._array.push(StringBuilder.formatString(string, arguments));
		return this;
	}
	
	public static function formatString(...arguments):String{
		var len = arguments.length;
		if(len==0) return "";
		else if(len==1) return arguments[0];
		
		var str:String = arguments[0];
		var arrData:Array;
		if(typeof(arguments[1]) == "object"){
			arrData = arguments[1];
		}else{
			arrData = new Array();
			for(var j:uint = 1; j < arguments.length; j++){
				arrData.push( arguments[j] );
			}
		}
	
		for(var i:uint = 0; i < arrData.length; i++){
			str = str.split("{"+i+"}").join(arrData[i]);
		}
		return str;
	}
	
	public function toString():String{
		return this._array.join("");
	}
}