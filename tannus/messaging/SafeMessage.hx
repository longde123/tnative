package tannus.messaging;

import tannus.messaging.Message;
import tannus.messaging.MessageType;
import tannus.ds.Object;
import tannus.ds.Maybe;

class SafeMessage {
	/* Constructor Function */
	public function new(data : TSafe):Void {
		new Object(this).write( data );
	}

/* === Instance Fields === */

	public var id : String;
	public var sender_id : String;
	public var type : String;
	public var channel : String;
	public var meta : Object;
	public var data : Object;

	public var raw(get, set):TSafe;
	private inline function get_raw() {
		return {
			'id': id,
			'sender_id': sender_id,
			'type': type,
			'channel': channel,
			'meta': meta,
			'data': data
		};
	}
	private inline function set_raw(v : TSafe) {
		new Object(this).write( v );
		return raw;
	}

/* === Static Fields === */

	/**
	  * Determine whether a given Object is a SafeMessage
	  */
	public static inline function isSafeMessage(o : Object):Bool {
		var id:Maybe<Object> = o['id'];
		var sid:Maybe<Object> = o['sender_id'];
		var type:Maybe<Object> = o['type'];
		var channel:Maybe<Object> = o['channel'];
		
		return (
			(id.exists && id.value.istype(String)) &&
			(sid.exists && sid.value.istype(String)) &&
			(channel.exists && channel.value.istype(String)) &&
			(isMessageType(type))
		);
	}

	private static function isMessageType(o : Maybe<Object>):Bool {
		try {
			if (!o.exists || !o.value.istype(String)) {
				return false;
			}
			else {
				var type:MessageType = (cast haxe.Unserializer.run(cast o));
				switch (type) {
					case Normal, Reply, Broadcast:
						return true;

					default:
						return false;
				}
			}
		}
		catch (error : Dynamic) {
			return false;
		}
	}
}

typedef TSafe = {
	var id : String;
	var sender_id : String;
	var type : String;
	var channel : String;
	var meta : Object;
	var data : Object;
};
