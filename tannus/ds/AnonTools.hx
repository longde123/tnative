package tannus.ds;

import tannus.macro.MacroTools;
import tannus.io.*;

import Slambda.fn;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

using Lambda;
using Slambda;
using tannus.macro.MacroTools;
using haxe.macro.ExprTools;
using haxe.macro.TypeTools;

class AnonTools {
	/**
	  * 'with'
	  */
	public static macro function with<T>(o:ExprOf<T>, action:Expr) {
		var type = Context.typeof( o ).getClass();
		var map:Map<String, ClassField> = new Map();
		var list = type.fields.get();
		for (f in list) {
			map[f.name] = f;
		}
		var out:Expr = action;
		for (name in map.keys()) {
			var ident:Expr = macro $i{name};
			var field:Expr = {
				pos: Context.currentPos(),
				expr: ExprDef.EField(o, name)
			};
			out = withReplace(out, ident, field);
		}
		return out;
	}

#if macro

	private static function withReplace(e:Expr, x:Expr, y:Expr):Expr {
		if (e.expr.equals( x.expr )) {
			return y;
		}
		else {
			return e.map(wrMapper.bind(_, x, y));
		}
	}

	private static function wrMapper(e:Expr, x:Expr, y:Expr):Expr {
		switch ( e.expr ) {
			case EMeta(s, ee) if (s.name == 'ignore'):
				return ee;
			default:
				if (e.expr.equals( x.expr )) {
					return y;
				}
				else {
					return e.map(wrMapper.bind(_, x, y));
				}
		}
	}

#end
}