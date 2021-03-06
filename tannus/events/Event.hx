package tannus.events;

import tannus.io.Ptr;
import tannus.io.Signal;
import tannus.io.VoidSignal;
import tannus.ds.Maybe;

import tannus.geom.*;

@:allow(tannus.events.EventCreator)
class Event {
	/* Constructor Function */
	public function new(variety:String, bubbls:Bool=false):Void {
		type = variety;
		date = (Date.now().getTime());
		_bubbles = bubbls;
		_defaultPrevented = false;
		_cancelled = false;
		_propogationStopped = false;

		onCancelled = new VoidSignal();
		onDefaultPrevented = new VoidSignal();
		onPropogationStopped = new VoidSignal();
		_onCopy = new Signal();
	}

/* === Instance Methods === */

	/**
	  * Create and return a clone of [this] Event
	  */
	public function clone(deep:Bool = false):Event {
		var c = Reflect.copy( this );
		
		c.onCancelled = (deep ? onCancelled.clone() : new VoidSignal());
		c.onDefaultPrevented = (deep ? onDefaultPrevented.clone() : new VoidSignal());
		c.onPropogationStopped = (deep ? onPropogationStopped.clone() : new VoidSignal());

		_onCopy.call( c );

		return c;
	}

	/**
	  * Cancel [this] Event
	  */
	public function cancel():Void {
		_cancelled = true;
		onCancelled.fire();
	}

	/**
	  * Prevent the default action of [this] Event
	  */
	public function preventDefault():Void {
		_defaultPrevented = true;
		onDefaultPrevented.fire();
	}

	/**
	  * Stop the propogation of [this] Event
	  */
	public function stopPropogation():Void {
		_propogationStopped = true;
		onPropogationStopped.fire();
	}

	/**
	  * get the list of modifiers for [this] Event
	  */
	public function getModifiers():Array<EventMod> {
		return new Array();
	}

/* === Computed Instance Fields === */

	/**
	  * 'bubbles' field
	  */
	public var bubbles(get, never):Bool;
	private inline function get_bubbles() return (_bubbles);

	/* whether [this] Event has been cancelled */
	public var cancelled(get, never):Bool;
	private inline function get_cancelled():Bool return _cancelled;

	/**
	  * Whether [this] Event has had it's default action prevented
	  */
	public var defaultPrevented(get, never):Bool;
	private inline function get_defaultPrevented() return (_defaultPrevented);

	public var propogationStopped(get, never):Bool;
	private inline function get_propogationStopped():Bool return _propogationStopped;

/* === Instance Fields === */

	//- The type of Event [this] is
	public var type:String;

	//- The datetime of when [this] Event happened
	public var date:Float;

	//- Whether [this] Event bubbles
	private var _bubbles:Bool;

	//- Whether [this] Event has had it's default action prevented
	private var _defaultPrevented:Bool;

	// whether [this] Event has been cancelled
	private var _cancelled : Bool;

	// whether the propogation of [this] Event has been stopped
	private var _propogationStopped : Bool;

	//- Signal which fires when [this] Event's default action is prevented
	private var onDefaultPrevented : VoidSignal;

	//- Signal which fires when [this] Event's propogation is stopped
	private var onPropogationStopped : VoidSignal;

	//- Signal which fires when [this] Event gets cancelled
	private var onCancelled : VoidSignal;

	//- Signal fired when a clone of [this] Event is created, with that clone as the data
	private var _onCopy : Signal<Event>;
}
