package tannus.ds;

import tannus.math.TMath.*;

import haxe.extern.EitherType;

import haxe.macro.Expr;
import haxe.macro.Context;

import Reflect.*;
import Type;

import Slambda.fn;

using Lambda;
using tannus.ds.ArrayTools;
using haxe.macro.ExprTools;
using tannus.macro.MacroTools;

class SortingTools {
    public static macro function macDrillDown(comparisons: Array<ExprOf<Int>>):ExprOf<Int> {
        comparisons.reverse();
        var res:ExprOf<Int> = comparisons.reduceInit(function(res:ExprOf<Int>, e:ExprOf<Int>) {
            return macro switch ( $e ) {
                case 0: $res;
                case c: c;
            }
        });
        return res;
    }

    public static inline function comparison<T>(x:T, y:T):Lazy<Int> {
        return Lazy.ofFunc(function() {
            return compareAny(x, y);
        });
    }

    public static function drillDown(a: Array<Lazy<Int>>):Int {
        var n = 0;
        for (v in a) {
            n = v.get();
            if (n == 0)
                continue;
            else
                return n;
        }
        return 0;
    }

    /**
      * 
      */
    public static function compresolve(comparisonResults : Iterable<Int>):Int {
        var n:Int = 0, i:Iterator<Int> = comparisonResults.iterator();
        while (i.hasNext()) {
            n = i.next();
            if (n == 0) {
                continue;
            }
            else return n;
        }
        return n;
    }

    public static inline function comparePrims<T:EitherType<Float, String>>(x:T, y:T):Int return Reflect.compare(x, y);
    public static inline function compareDates(x:Date, y:Date):Int return comparePrims(x.getTime(), y.getTime());
    public static inline function compareIComparables<T:IComparable<T>>(x:T, y:T):Int return x.compareTo( y );
    public static inline function compareArrays<T>(x:Array<T>, y:Array<T>):Int return compareEnumValueParams(x, y);
    public static inline function compareAny<T>(x:T, y:T):Int {
        return compareEnumValueParam(x, y);
    }

	/**
	  * chain together any number of sorters, which will be evaluated in order
	  */
	public static function chain(sorters : Array<Void -> Int>):Int {
		for (f in sorters) {
			var n = f();
			if (n == 0) {
				continue;
			}
			else {
				return n;
			}
		}
		return 0;
	}

	public static inline function stringComparator(x:String, y:String):Void->Int {
		return compare.bind(x, y);
	}
	public static inline function numComparator<T:Float>(x:T, y:T):Void->Int {
		return compare.bind(x, y);
	}
	public static inline function dateComparator(x:Date, y:Date):Void->Int {
		return numComparator(x.getTime(), y.getTime());
	}
	public static inline function comparator<T:IComparable<T>>(x:T, y:T):Void->Int {
		return x.compareTo.bind( y );
	}
	public static inline function enumValueComparator<T:EnumValue>(x:T, y:T):Void->Int {
	    return compareEnumValues.bind(x, y);
	}

    /**
      * compare two enum values
      */
	public static function compareEnumValues<T:EnumValue>(x:T, y:T):Int {
	    if (Type.getEnum( x ) != Type.getEnum( y )) {
	        throw 'TypeError: Cannot compare enum values from two different enums';
	    }
        else {
            var id = compare(x.getIndex(), y.getIndex());
            if (id != 0) {
                return id;
            }
            else {
                var xp = x.getParameters(), yp = y.getParameters();
                if (xp.length == 0 && yp.length == 0) {
                    return 0;
                }
                else {
                    return compareEnumValueParams(xp, yp);
                }
            }
        }
	}

    /**
      * compare two arrays of enum value parameters
      */
	private static function compareEnumValueParams(x:Array<Dynamic>, y:Array<Dynamic>):Int {
	    var ld = compare(x.length, y.length);
	    if (ld != 0) {
	        return ld;
	    }
	    for (i in 0...x.length) {
	        var d = compareEnumValueParam(x[i], y[i]);
	        if (d != 0) {
	            return d;
	        }
	    }
	    return 0;
	}

    /**
      * compare two singular values from enum value parameters
      */
	private static function compareEnumValueParam(x:Dynamic, y:Dynamic):Int {
	    if (isEnumValue( x ) && isEnumValue( y )) {
	        return compareEnumValues(x, y);
	    }
        else if ((x is Array) && (y is Array)) {
            return compareEnumValueParams(x, y);
        }
        else if (isIComparable( x ) && isIComparable( y )) {
            return icompare(x, y);
        }
        else if (((x is String) || (x is Float)) && ((y is String) || (y is Float))) {
            return compare(x, y);
        }
        else {
            return compareAnon(x, y);
        }
	}

	/**
	  * compare two anonymous structures with one another
	  */
	public static function compareAnon(x:Dynamic, y:Dynamic):Int {
	    if (isObject( x ) && isObject( y )) {
	        var xkl = fields( x ), ykl = fields( y ), klc = compareEnumValueParams(xkl, ykl);
	        if (klc == 0) {
	            var xv:Dynamic, yv:Dynamic;
	            for (key in xkl) {
	                xv = getProperty(x, key);
	                yv = getProperty(y, key);
	                var vc = compareEnumValueParam(xv, yv);
	                if (vc == 0)
	                    continue;
                    else return vc;
	            }
	            return 0;
	        }
            else {
                return klc;
            }
	    }
        else throw 'Error: invalid arguments for SortingTools.compareAnon';
	}

	/**
	  * attempt to perform 'icomparison' on the two given objects
	  */
	private static function icompare(x:IComparable<Dynamic>, y:IComparable<Dynamic>):Int {
	    try {
	        var result:Dynamic = x.compareTo( y );
	        if (!Std.is(result, Int)) {
	            throw 'TypeError: NaN';
	        }
            else {
                return result;
            }
	    }
	    catch (error : Dynamic) {
	        return 0;
	    }
	}

    /**
      * attempts to determine whether [o] is an IComparable object
      */
    private static inline function isIComparable(o : Dynamic):Bool {
        return (isIComparable_safe( o ) || isIComparable_unsafe( o ));
    }
    private static inline function isIComparable_safe(o : Dynamic):Bool {
        return (o is IComparable);
    }
	private static function isIComparable_unsafe(o : Dynamic):Bool {
	    if (isObject( o )) {
	        return (hasField(o, 'compareTo') && isFunction(getProperty(o, 'compareTo')));
	    }
        else return false;
	}
}
