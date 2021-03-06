package tannus.storage.core;

import tannus.ds.Promise;
import tannus.ds.promises.*;
import tannus.storage.core.QueryPromise;

/**
  * Base class for Database objects
  */
class Database {
	/* Constructor Function */
	public function new():Void {
		null;
	}

/* === Instance Methods === */

	/**
	  * Obtain a List of Table names
	  */
	public function tableList():ArrayPromise<String> {
		unimp();
		return Promise.create({
			throw 'Not Implemented!';
		}).array();
	}

	/**
	  * Obtain a connection to a given Table, by name
	  */
	public function table(name : String):Promise<Table> {
		unimp();
		return Promise.create({
			throw 'Not Implemented!';
		});
	}

	/**
	  * Start a Query on a given Table
	  */
	public function select(name : String):QueryPromise {
		return new QueryPromise(function(accept, reject) {
			table(name).then(function(tabl) {
				accept(tabl.get());
			}).unless(reject);
		});
	}

	/**
	  * Create a new table, with the given name
	  */
	public function createTable(name : String):Promise<Table> {
		unimp();
		return Promise.create({
			throw 'Not Implemented!';
		});
	}

	/**
	  * Delete a given Table, by name
	  */
	public function deleteTable(name : String):BoolPromise {
		unimp();
		return Promise.create({
			throw 'Not Implemented!';
		}).bool();
	}

	/**
	  * Determine whether [this] Database has a Table by the given name
	  */
	public function hasTable(name : String):BoolPromise {
		unimp();
		return Promise.create({
			throw 'Not Implemented!';
		}).bool();
	}

	/**
	  * Delete [this] Database
	  */
	public function delete():BoolPromise {
		unimp();
		return Promise.create({
			throw 'Not Implemented!';
		}).bool();
	}

	/**
	  * Throw an error
	  */
	private inline function error(msg : String):Void {
		throw 'DatabaseError: $msg';
	}

	/**
	  * Report a method as not implemented
	  */
	private inline function unimp():Void {
		error('Not Implemented!');
	}

	/**
	  * Report a method as not supported
	  */
	private inline function unsup():Void {
		error('Not Supported!');
	}

/* === Instance Fields === */

	/* The name of [this] Database */
	public var name : String;

/* === Static Methods === */
}
