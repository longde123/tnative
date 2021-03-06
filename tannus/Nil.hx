package tannus;

import Reflect.*;
import Type.*;

using StringTools;
using tannus.ds.StringUtils;
using tannus.ds.ArrayTools;
using tannus.FunctionTools;

@:native('Lin')
enum Nil {
    Nil;
}

class NilTools {
    public static function isNil(value: Dynamic):Bool {
        return (
            isEnumValue( value ) &&
            (value is Nil) &&
            ((value : Nil).match(Nil))
        );
    }

    public static function isNilly(value: Dynamic):Bool {
        return (
            (value == null) ||
            isNil( value ) ||
            (isMeasurable(value) && (measure(value) > 0))
        );
    }

    private static function isMeasurable(x: Dynamic):Bool {
        return (isObject(x) && hasField(x, 'length') && typeof(field(x, 'length')).match(TInt));
    }

    private static inline function measure(x: Dynamic):Int {
        return (field(x, 'length') : Int);
    }
}
