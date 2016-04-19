package tannus.mvc;

import tannus.storage.Storage;
import tannus.storage.Commit;

import tannus.ds.Async;
import tannus.ds.Delta;
import tannus.ds.Destructible;
import tannus.ds.Memory;
import tannus.ds.Object;
import tannus.io.Ptr;
import tannus.io.Signal;
import tannus.io.EventDispatcher;
import tannus.io.VoidSignal;

import tannus.mvc.Asset;
import tannus.mvc.Requirements;

import haxe.rtti.Meta;

class Model extends EventDispatcher implements Asset {
	/* Constructor Function */
	public function new():Void {
		super();

		change = new Signal();
		assets = new Array();
		readyReqs = new Requirements();
		_ready = new VoidSignal();
		_a = new Map();

		_bindMethodsToEvents();
	}

/* === Instance Methods === */

	/**
	  * Initialize [this] Model
	  */
	public function init(?cb : Void -> Void):Void {
		if (cb != null)
			onready( cb );
		
		readyReqs.meet(function() {
			sync(function() {
				_ready.fire();
			});
		});
	}

	/**
	  * Wait for [this] Model to be 'ready'
	  */
	public inline function onready(f : Void -> Void):Void {
		_ready.once( f );
	}

	/**
	  * Attach an Asset to [this] Model
	  */
	public inline function link(item : Asset):Void {
		assets.push( item );
	}

	/**
	  * Detach an Asset from [this] Model
	  */
	public inline function unlink(item : Asset):Void {
		assets.remove( item );
	}

	/**
	  * Delete [this] Model entirely
	  -------------------------------
	    would usually refer to the deletion and/or deactivation
	    of the thing the Model represents
	  */
	public function destroy():Void {
		for (a in assets) {
			a.destroy();
		}
	}

	/**
	  * Detach [this] Model
	  ----------------------
	    delete [this] Model instance, NOT the thing 
	    the Model represents
	  */
	public function detach():Void {
		for (a in assets) {
			a.detach();
		}
	}

	/**
	  * require that Task [t] have completed successfully before [this] Model is considered 'ready'
	  */
	private function require(name:String, task:Async):Void {
		readyReqs.add(name, task);
	}

	/**
	  * persist [this] Model's state
	  */
	public function sync(done : Void->Void):Void {
		done();
	}


	public function save():Void {
		sync(function() null);
	}

	/**
	  * Watch for changes
	  */
	public inline function watch<T>(f : ModelChange<T> -> Void):Void {
		change.on( f );
	}

	/**
	  * Watch a given key for changes
	  */
	public function watchKey(key:String, f:Void->Void):Void {
		change.on(function(c) {
			if (c.name == key) {
				f();
			}
		});
	}

	/**
	  * Get the value of an attribute of [this] Model
	  */
	public function getAttribute<T>(key : String):Null<T> {
		return untyped _a.get( key );//(storage.get(map_key( key )));
	}
	public inline function get<T>(k : String):Null<T> return getAttribute( k );

	/**
	  * Set the value of an attribute of [this] Model
	  */
	public function setAttribute<T>(key:String, value:T):T {
		var d = {name:key, value:new Delta(value, get(key))};
		_a.set(key, value);//storage.set(map_key(key), value);
		var curr = _a.get( key );
		change.call( d );
		return untyped curr;
	}
	public inline function set<T>(key:String, value:T):T return setAttribute(key, value);

	/**
	  * Get a Pointer to an attribute of [this] Model
	  */
	public function reference<T>(key : String):Ptr<T> {
		var ref:Ptr<Dynamic> = new Ptr(getAttribute.bind(key), setAttribute.bind(key, _));
		return (untyped ref);
	}

	/**
	  * Get an Attribute object for an attribute of [this] Model
	  */
	public inline function attribute<T>(key : String):Attribute<T> {
		return untyped new Attribute(this, key);
	}

	/**
	  * Check whether [this] Model has an attribute with the given name
	  */
	public function hasAttribute(name : String):Bool {
		return untyped _a.exists( name );//storage.exists(map_key( name ));
	}
	public inline function exists(key : String):Bool return hasAttribute(key);

	/**
	  * Delete the given attribute of [this] Model
	  */
	public function removeAttribute(name : String):Bool {
		return _a.remove( name );
	}
	public inline function remove(key : String):Bool return removeAttribute( key );

	/**
	  * Get an Array of the names of all attributes
	  */
	public function allAttributes():Array<String> {
		return [for (k in _a.keys()) k];
	}
	public inline function keys():Array<String> return allAttributes();

	/**
	  * Perform metadata-based event-binding
	  */
	private function _bindMethodsToEvents():Void {
		var cclass:Class<Model> = Type.getClass( this );
		
		var data:Object = Meta.getFields( cclass );
		for (name in data.keys) {
			var field:Object = data.get(name);
			if (field.exists('handle')) {
				var events:Array<String> = cast field.get('handle');
				var val:Dynamic = Reflect.getProperty(this, name);
				if (!Reflect.isFunction( val ))
					throw 'TypeError: Cannot bind field $name!';

				for (event in events) {
					if (!canDispatch( event )) {
						addSignal( event );
					}

					on(event, untyped val);
				}
			}
		}
	}


/* === Computed Instance Fields === */

	/**
	  * Storage object in use by [this] Model currently
	  */
	/*
	public var storage(default, set):Storage;
	private function set_storage(v : Storage):Storage {
		storage = v;

		// define the 'storage' requirement's Task as the intialization of [storage]
		readyReqs.add('storage', function(met) {
			v.init( met );
		});

		return storage;
	}
	*/

/* === Instance Fields === */

	/* objects 'attached' to [this] Model, to be deleted when [this] is */
	private var assets : Array<Asset>;

	/* signal fired when [storage] becomes usable */
	public var readyReqs : Requirements;
	
	/* a Signal fired when changes are made to [this] Model */
	public var change : Signal<ModelChange<Dynamic>>;

	/* signal fired when [this] Model becomes 'ready' */
	private var _ready : VoidSignal;

	/* a Map to store attribute values in */
	private var _a : Map<String, Dynamic>;
}

typedef ModelChange<T> = {
	var name : String;
	var value : Delta<T>;
};
