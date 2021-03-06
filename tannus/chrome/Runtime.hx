package tannus.chrome;

import tannus.ds.Object;
import tannus.ds.Maybe;
import tannus.ds.ActionStack;
import tannus.io.Ptr;
import tannus.io.Signal;
import tannus.io.ByteArray;
import tannus.html.Win;

import haxe.Serializer;
import haxe.Unserializer;

class Runtime {
	/**
	  * Reload the App
	  */
	public static inline function reload():Void {
		lib.reload();
	}

	/**
	  * Sends a message to another application/extension
	  */
	public static function sendMessage(tid:String, data:Object, ?onresponse:Maybe<Object->Void>):Void {
		lib.sendMessage(tid, data, {}, function(response:Object) {
			if (onresponse) {
				var f:Object->Void = onresponse;
				f( response );
			}
		});
	}

	/**
	  * Listen for incoming message, without the convenience-wrapper
	  */
	public static function onMessageRaw(callb : Dynamic->MessageSender->Void):Void {
		lib.onMessage.addListener( callb );
	}

	/**
	  * Listen for incoming messages
	  */
	public static function onMessage(callb : Message->Void):Void {
		lib.onMessage.addListener(function(d:Dynamic, sendr:Dynamic, sendResponse:Dynamic->Void) {
			callb({
				'data'   : d,
				'sender' : (cast sendr),
				'respond': sendResponse
			});
		});
	}

	/**
	  * get a reference to the 'window' Object for the background page
	  */
	public static function getBackgroundPage(cb : Win -> Void):Void {
		if (_bg == null) {
			lib.getBackgroundPage(function( w ) {
				cb(_bg = w);
			});
		}
		else {
			cb( _bg );
		}
	}

	/**
	  * check whether we're currently running in the background page
	  */
	public static function isBackgroundPage(w:Win, cb:Bool->Void):Void {
		getBackgroundPage(function( bg ) {
			cb(w == bg);
		});
	}

	public static inline function inBackgroundPage(cb : Bool -> Void):Void {
		isBackgroundPage(Win.current, cb);
	}
	
	/**
	  * The ID of the current application/extension
	  */
	public static var id(get, never):String;
	private static inline function get_id() return (lib.id + '');

	/**
	  * asyncronous error message defined by some chrome-specific api in the event of an error
	  */
	public static var lastError(get, never):Null<String>;
	private static inline function get_lastError():Null<String> return lib.lastError;

	/**
	  * Reference to the object being used internally
	  */
	public static var lib(get, never):Dynamic;
	private static inline function get_lib():Dynamic return untyped __js__('chrome.runtime');
	
	private static var _bg : Null<Win>;
}

typedef Message = {
	var data : Object;
	var sender : MessageSender;
	var respond : Object -> Void;
};

typedef MessageSender = {
	@:optional
	var tab : Tab;
	@:optional
	var id : Maybe<String>;
	@:optional
	var url : Maybe<String>;
};
