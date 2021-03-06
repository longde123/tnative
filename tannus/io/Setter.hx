package tannus.io;

import haxe.macro.Expr;

using tannus.macro.MacroTools;

@:callable
abstract Setter<T> (Set<T>) from Set<T> {
	/* Constructor Function */
	public inline function new(f : Set<T>):Void {
		this = f;
	}

/* === Instance Fields === */

	/**
	  * Assign the value, as a field
	  */
	public var v(never, set):T;
	private inline function set_v(nv : T):T {
		return this( nv );
	}

/* === Instance Methods === */

	/**
	  * Wrap [this] Setter in another setter
	  */
	public inline function wrap(f : SetWrap<T>):Void {
		var self = this;
		this = function (v : T):T {
			return f(self, v);
		};
	}

	/**
	  * Wrap another Setter around [this]
	  */
	@:op(A += B)
	public function attach(other : Setter<T>):Setter<T> {
		wrap(function(s, val) {
			other.set( val );
			return s.set( val );
		});
		return new Setter(this);
	}

	/**
	  * Apply a transformation to [this] Setter
	  */
	public function transform<O>(f : O->T):Setter<O> {
		return new Setter(function(o : O):O {
			set(f( o ));
			return o;
		});
	}

    @:to
    @:keep
    //@:native('noreturn')
	public static function noreturn<T>(self: Setter<T>):T -> Void {
		return (function(x: T):Void {
		    self( x );
		    return ;
		});
	}

	/**
	  * Assign the value
	  */
	@:op(A &= B)
	public inline function set(v : T):T {
		return (this( v ));
	}

	/**
	  * Transform [this] Setter, macro-style
	  */
	public macro function map<O>(self:ExprOf<Setter<T>>, f:Expr):ExprOf<Setter<O>> {
		var tfunc:Expr = f.mapUnderscoreTo('o');
		tfunc = (macro function( o ) {
			$self.set( $tfunc );
			return o;
		});
		return macro new tannus.io.Setter( $tfunc );
	}

/* === Class Methods === */

	public static macro function create<T> (val : ExprOf<T>):ExprOf<Setter<T>> {
		return macro new tannus.io.Setter(function(v) {
			return ($val = v);
		});
	}
}

/* Alias to the underlying type */
private typedef Set<T> = T -> T;

private typedef SetWrap<T> = Setter<T> -> T -> T;
