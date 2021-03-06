package tannus.http;

import tannus.html.Win;
import tannus.io.EventDispatcher;
import tannus.io.ByteArray;
import tannus.io.VoidSignal;
import tannus.ds.Obj;

import js.html.XMLHttpRequest;
import js.html.XMLHttpRequestResponseType in Nrt;
import js.html.ArrayBuffer;
import js.html.Blob;
import js.html.Document;

import Slambda.fn;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;

@:expose( 'WebRequest' )
class WebRequest extends EventDispatcher {
	/* Constructor Function */
	public function new():Void {
		super();

		__checkEvents = false;

		req = new XMLHttpRequest();
		_listen();
	}

/* === Instance Methods === */

	/**
	  * Open [this] Request
	  */
	public inline function open(method:String, url:String):Void {
		req.open(method, url);
	}

	/**
	  * Send [this] Request
	  */
	public inline function send(?data : Dynamic):Void {
		req.send(untyped data);
	}

	/**
	  * Wait for the response, as a String
	  */
	public function loadAsText(cb : String -> Void):Void {
		responseType = TText;
		onres( cb );
	}

	/**
	  * Wait for the response, as a JSON object
	  */
	public function loadAsObject(cb : Obj -> Void):Void {
		responseType = TJson;
		onres(function(o : Dynamic) {
			cb(Obj.fromDynamic( o ));
		});
	}

	/**
	  * Wait for the response, as a Blob
	  */
	public function loadAsBlob(cb : Blob -> Void):Void {
		responseType = TBlob;
		onres( cb );
	}

	/**
	  * Wait for the response, as an ArrayBuffer
	  */
	public function loadAsArrayBuffer(cb : ArrayBuffer -> Void):Void {
		responseType = TArrayBuffer;
		onres( cb );
	}

	/**
	  * wait for the response, as a Document
	  */
	public function loadAsDocument(cb : Document -> Void):Void {
		responseType = TDoc;
		onres( cb );
	}

	/**
	  * wait for the response, as a ByteArray
	  */
	public function loadAsByteArray(cb : ByteArray -> Void):Void {
		loadAsArrayBuffer(function(ab) {
#if node
			cb(ByteArray.ofData((untyped __js__('Buffer'))( ab )));
#else
			cb(ByteArray.ofData( ab ));
#end
		});
	}

	/**
	  * wait for the request to finish, but don't retrieve the response data
	  */
	public inline function load(done : Void->Void):Void {
		onres(untyped done);
	}

	/**
	  * get a response header
	  */
	public inline function getResponseHeader(name : String):Null<String> return req.getResponseHeader( name );

	/**
	  * get all response headers
	  */
	public inline function getAllResponseHeadersRaw():Null<String> return req.getAllResponseHeaders();

	/**
	  * set a request header
	  */
	public inline function setRequestHeader(name:String, value:String):Void req.setRequestHeader(name, value);

	/**
	  * abort [this] request
	  */
	public inline function abort():Void req.abort();

	/**
	  * get a Map<String, String> of all response headers
	  */
	public function getAllResponseHeaders():Map<String, String> {
		var m = new Map();
		var s = getAllResponseHeadersRaw();
		if (s != null) {
			var lines = s.split( '\r\n' );
			for (line in lines) {
				var p = line.separate(':');
				m[p.before] = p.after;
			}
		}
		return m;
	}

	/**
	  * wait for a response
	  */
	private function onres(cb : Dynamic -> Void):Void {
		if ( complete ) {
			cb( req.response );
		}
		else {
			addSignal(eventName());
			once(eventName(), cb);
		}
	}

	/**
	  * listen to events on [req]
	  */
	private inline function listen():Void {
		req.onreadystatechange = readyStateChanged.bind();
	}

	/**
	  * called when the readyState of [req] changes
	  */
	private function readyStateChanged():Void {
		switch ( readyState ) {
			case HeadersReceived:
				//trace(req.getAllResponseHeaders());

			default:
				null;
		}
	}

	/**
	  * listen to events ocurring on [req]
	  */
	private function _listen():Void {
		/* request has finished loading */
		req.addEventListener('load', function(event) {
			complete = true;
			(untyped __js__('setTimeout'))(function() {
				done();
			}, 10);
		});

        /* utility function to forward events from [req] to [this] */
		function forward<T>(name:String, ?mapper:T->Dynamic):Void {
		    if (mapper == null) {
		        mapper = untyped fn( _ );
		    }
		    req.addEventListener(name, function(event : T) {
                dispatch(name, mapper( event ));
		    });
		}

        var pext:js.html.ProgressEvent->Dynamic = fn({
            type: _.type,
            lengthComputable: _.lengthComputable,
            loaded: _.loaded,
            total: _.total
        });

        forward('loadstart', pext);
        forward('loadend', pext);
        forward('progress', pext);
        forward('abort');
        forward('error', fn({
            type: _.type,
            detail: _.detail
        }));
        forward('timeout', pext);
        forward('readystatechange', function(evt) {
            return readyState;
        });
	}

	/**
	  * when [this] Request has completed
	  */
	private function done():Void {
		dispatch(eventName(), req.response);

	}

	/**
	  * Get the name of the event fired for each response-type
	  */
	private function eventName():String {
		return 'got-$responseType';
	}

	public function onTimeout(f : TimeoutEvent->Void):Void {
	    on('timeout', f);
	}

	public function onError(f : ErrorEvent->Void):Void {
	    on('error', f);
	}

	public function onLoadStart(f : LoadStartEvent->Void):Void {
	    on('loadstart', f);
	}

	public function onLoadEnd(f : LoadEndEvent->Void):Void {
	    on('loadend', f);
	}

	public function onAbort(f : AbortEvent->Void):Void {
	    on('abort', f);
	}

	public function onReadyStateChange(f : ReadyState->Void):Void {
	    on('readystatechange', f);
	}

	public function onResponseHeadersAvailable(f: Map<String, String> -> Void) {
	    function _check(rs: ReadyState) {
            switch rs {
                case Unsent, Opened:
                    once('readystatechange', _check);

                case HeadersReceived, Loading, Done:
                    return f(getAllResponseHeaders());
            }
        }
        _check( readyState );
	}

/* === Computed Instance Fields === */

	/* the ready state of [this] shit */
	public var readyState(get, never) : ReadyState;
	private inline function get_readyState():ReadyState return req.readyState;

	/* the response type of [this] shit */
	public var responseType(get, set):ResponseType;
	private inline function get_responseType():ResponseType return cast(req.responseType, String);
	private inline function set_responseType(v : ResponseType):ResponseType return untyped(req.responseType = cast v);

	public var status(get, never): Int;
	private inline function get_status() return req.status;

/* === Instance Fields === */

	private var req : XMLHttpRequest;
	private var complete : Bool = false;
}

@:enum
abstract ResponseType (String) from String to String {
	var TText = 'text';
	var TJson = 'json';
	var TArrayBuffer = 'arraybuffer';
	var TBlob = 'blob';
	var TDoc = 'document';

	@:from
	public static inline function fromString(v : String):ResponseType {
		return switch ( v ) {
			case '', 'text': TText;
			case 'json': TJson;
			case 'arraybuffer': TArrayBuffer;
			case 'blob': TBlob;
			case 'document': TDoc;
			default: TText;
		}
	}
}

@:enum
abstract ReadyState (Int) from Int to Int {
	var Unsent = 0;
	var Opened = 1;
	var HeadersReceived = 2;
	var Loading = 3;
	var Done = 4;
}

typedef Event = {
    type: String
};

typedef ProgressEvent = {
    >Event,
    lengthComputable: Bool,
    loaded: Int,
    total: Int
};

typedef LoadStartEvent = { > ProgressEvent, };
typedef LoadEndEvent = { > ProgressEvent, };
typedef AbortEvent = { > ProgressEvent, };
typedef TimeoutEvent = {>ProgressEvent, };
typedef ErrorEvent = {
    >Event,
    detail: Float
};
