package tannus.media;

import tannus.ds.ThreeTuple;
import Math.*;
import tannus.math.TMath.*;
import tannus.ds.Comparable;

using StringTools;
using tannus.ds.StringUtils;
using tannus.math.TMath;

@:forward
abstract Duration (CDur) from CDur to CDur {
	/* Constructor Function */
	public function new(s:Int=0, m:Int=0, h:Int=0):Void {
		this = new CDur(s, m, h);
	}

	@:op(A == B)
	public inline function equals(other : Duration):Bool return this.equals( other );
	@:op(A + B)
	public inline function plus(other : Duration):Duration return this.plus( other );

	/**
	  * Cast [this] to a String
	  */
	@:to
	public inline function toString():String {
		return this.toString();
	}
	
	/**
	  * Cast [this] to an Int
	  */
	@:to
	public inline function toInt():Int {
		return this.totalSeconds;
	}

	/**
	  * cast [this] to a Float
	  */
	@:to
	public inline function toFloat():Float {
		return (this.totalSeconds + 0.0);
	}

	@:from
	public static inline function fromSecondsI(i : Int):Duration return CDur.fromSecondsI( i );
	@:from
	public static inline function fromSecondsF(n : Float):Duration return CDur.fromSecondsF( n );
	@:from
	public static inline function fromString(s : String):Duration return CDur.fromString( s );
}

class CDur implements Comparable<CDur> {
	/* Constructor Function */
	public function new(s:Int, m:Int, h:Int):Void {
		seconds = s;
		minutes = m;
		hours = h;
	}

/* === Instance Methods === */

	/**
	  * Convert [this] Duration into a human-readable String
	  */
	public function toString():String {
		var bits:Array<String> = new Array();
		bits.unshift(seconds+'');
		bits.unshift(minutes+'');
		if (hours > 0)
			bits.unshift(hours+'');
		bits = bits.map(function(s : String) {
			if (s.length < 2)
				s = ('0'.times(2 - s.length) + s);
			return s;
		});
		return bits.join(':');
	}

	/**
	  * check for equality between [this] and [other]
	  */
	public function equals(other : CDur):Bool {
		return (seconds == other.seconds && minutes == other.minutes && hours == other.hours);
	}

	/**
	  * get the sum of [this] and [other]
	  */
	public function plus(other : Duration):Duration {
		return fromSecondsI(totalSeconds + other.totalSeconds);
	}

/* === Computed Instance Fields === */

	public var totalHours(get, never):Int;
	private inline function get_totalHours():Int {
		return floor(hours + (minutes / 60.0));
	}

	public var totalMinutes(get, never):Int;
	private inline function get_totalMinutes():Int {
		return floor((60 * hours) + minutes + (seconds / 60.0));
	}

	public var totalSeconds(get, set):Int;
	private inline function get_totalSeconds():Int {
		return ((60 * 60 * hours) + (60 * minutes) + seconds);
	}
	private function set_totalSeconds(v : Int):Int {
		hours = floor(v / 3600);
		v = (v - hours * 3600);
		minutes = floor(v / 60);
		seconds = (v - minutes * 60);
		return totalSeconds;
	}

/* === Instance Fields === */

	public var seconds : Int;
	public var minutes : Int;
	public var hours : Int;

/* === Static Methods === */

	/**
	  * create a Duration from an Int
	  */
	public static function fromSecondsI(i : Int):Duration {
		var d = new Duration();
		d.totalSeconds = i;
		return d;
	}

	/**
	  * create a Duration from a Float
	  */
	public static inline function fromSecondsF(n : Float):Duration {
		return fromSecondsI(floor( n ));
	}

	/**
	  * create a Duration from a String
	  */
	public static function fromString(s : String):Duration {
		var data = s.trim().split(':').map( Std.parseInt );
		switch( data ) {
			case [s]:
				return new Duration( s );
			case [m, s]:
				return new Duration(s, m);
			case [h, m, s]:
				return new Duration(s, m, h);
			default:
				throw 'Invalid Duration string "$s"';
		}
	}
}

/**
  * Abstract class to represent to duration of some playable media (sound, video, slideshow, etc)
  */
abstract OldDuration (Dur) {
	/* Constructor Function */
	public inline function new(s:Int=0, m:Int=0, h:Int=0):Void {
		this = {
			'seconds' : s,
			'minutes' : m,
			'hours'   : h
		};
	}

/* === Instance Methods === */

	/**
	  * Convert [this] Duration into a nice, sexy String
	  */
	@:to
	public function toString():String {
		var bits:Array<String> = new Array();
		bits.unshift(seconds+'');
		bits.unshift(minutes+'');
		if (hours > 0)
			bits.unshift(hours+'');
		bits = bits.map(function(s : String) {
			if (s.length < 2)
				s = ('0'.times(2 - s.length) + s);
			return s;
		});
		return bits.join(':');
	}

	/**
	  * Obtain the 'sum' of [this] Duration, and another
	  */
	@:op(A + B)
	public inline function add(other : Duration):Duration {
		return new Duration((seconds + other.seconds), (minutes + other.minutes), (hours + other.hours));
	}

/* === Instance Fields === */

	/**
	  * Total Seconds of [this] Duration
	  */
	public var totalSeconds(get, set):Int;
	private inline function get_totalSeconds():Int {
		return ((60 * 60 * hours) + (60 * minutes) + seconds);
	}
	private inline function set_totalSeconds(v : Int):Int {
		hours = floor(v / 3600);
		v = (v - hours * 3600);
		minutes = floor(v / 60);
		seconds = (v - minutes * 60);
		return totalSeconds;
	}

	/**
	  * Total Minutes of [this] Duration
	  */
	public var totalMinutes(get, never):Float;
	private inline function get_totalMinutes():Float {
		var res:Float = 0;
		//- Hours
		res += (60 * hours);
		//- Minutes
		res += minutes;
		//- Seconds
		res += (seconds / 60.0);
		return res;
	}

	/**
	  * Total Hours
	  */
	public var totalHours(get, never):Float;
	private inline function get_totalHours():Float {
		var res:Float = 0;
		//- Hours
		res += hours;
		//- Minutes
		res += (totalMinutes / 60.0);
		return res;
	}

	/**
	  * Hours of [this] Duration
	  */
	public var hours(get, set):Int;
	private inline function get_hours() return this.hours;
	private inline function set_hours(nh) return (this.hours = nh);

	/**
	  * Minutes of [this] Duration
	  */
	public var minutes(get, set):Int;
	private inline function get_minutes() return this.minutes;
	private inline function set_minutes(nm) return (this.minutes = nm);

	/**
	  * Seconds of [this] Duration
	  */
	public var seconds(get, set):Int;
	private inline function get_seconds() return this.seconds;
	private inline function set_seconds(ns) return (this.seconds = ns);

/* === Static Methods === */

	/**
	  * Cast to Duration from Int
	  */
	@:from
	public static function fromSecondsI(i : Int):Duration {
		var d:Duration = new Duration();
		d.totalSeconds = i;
		return d;
	}

	/**
	  * From Float
	  */
	@:from
	public static function fromSecondsF(i : Float):Duration {
		var d:Duration = new Duration();
		d.totalSeconds = Math.floor( i );
		return d;
	}

	/**
	  * from String
	  */
	@:from
	public static function fromString(s : String):Duration {
		var data = s.trim().split(':').map( Std.parseInt );
		switch( data ) {
			case [s]:
				return new Duration( s );
			case [m, s]:
				return new Duration(s, m);
			case [h, m, s]:
				return new Duration(s, m, h);
			default:
				throw 'Invalid Duration string "$s"';
		}
	}
}

/**
  * Unerlying Type of Duration
  */
private typedef Dur = {
	var seconds : Int;
	var minutes : Int;
	var hours   : Int;
};
