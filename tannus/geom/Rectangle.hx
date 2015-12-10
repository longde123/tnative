package tannus.geom;

import tannus.geom.Point;
import tannus.geom.Area;
import tannus.geom.Shape;
import tannus.geom.Vertices;

import tannus.math.Percent;
import tannus.ds.EitherType in Either;

@:forward
abstract Rectangle (CRectangle) from CRectangle to CRectangle {
	/* Constructor Function */
	public inline function new(_x:Float=0, _y:Float=0, _width:Float=0, _height:Float=0):Void {
		this = new CRectangle(_x, _y, _width, _height);
	}

/* === Operators === */

	/* Equality Testing */
	@:op(A == B)
	public inline function eq(o : Rectangle):Bool {
		return this.equals( o );
	}

	/* Division */
	@:op(A / B)
	public inline function floatDiv(o : Float):Rectangle {
		return this.divide( o );
	}

	/* Division by Rectangle */
	@:op(A / B)
	public inline function rectDiv(r : Rectangle):Rectangle {
		return this.divide( r );
	}

/* === Type Casting === */

	#if flash
	
	/* To flash.geom.Rectangle */
	@:to
	public inline function toFlashRect():flash.geom.Rectangle {
		return new flash.geom.Rectangle(this.x, this.y, this.width, this.height);
	}

	/* From flash.geom.Rectangle */
	@:from
	public static inline function fromFlashRect(fr : flash.geom.Rectangle):Rectangle {
		return new Rectangle(fr.x, fr.y, fr.width, fr.height);
	}

	#end

	/**
	  * Create a Rectangle from an Array of Numbers
	  */
	@:from
	public static inline function fromArray<T : Float> (a : Array<T>):Rectangle {
		return new Rectangle(a[0], a[1], a[2], a[3]);
	}
}

class CRectangle implements Shape {
	public function new(_x:Float=0, _y:Float=0, _width:Float=0, _height:Float=0):Void {
		x = _x;
		y = _y;
		z = 0;
		width = _width;
		height = _height;
		depth = 0;
	}

/* === Instance Methods === */

	/**
	  * Creates and returns a clone of [this] Rectangle
	  */
	public function clone():Rectangle {
		var r:Rectangle = new Rectangle(x, y, width, height);
		r.z = z;
		r.depth = depth;
		return r;
	}

	/**
	  * Copies data from [other] onto [this]
	  */
	public function cloneFrom(other : Rectangle):Void {
		x = other.x;
		y = other.y;
		z = other.z;
		width = other.width;
		height = other.height;
		depth = other.depth;
	}

	/**
	  * Whether [other] Rectangle is equal to [this] one
	  */
	public function equals(other : Rectangle):Bool {
		return (
			x == other.x &&
			y == other.y &&
			z == other.z &&
			width == other.width &&
			height == other.height &&
			depth == other.depth
		);
	}

	/**
	  * Divide [this] Rectangle
	  */
	public function divide(div : Either<Float, Rectangle>):Rectangle {
		switch (div.type) {
			case Left( f ):
				return new Rectangle(x, y, w/f, h/f);

			case Right( r ):
				return new Rectangle(x, y, w/r.w, h/r.h);
		}
	}

	/**
	  * Whether [ox] and [oy] describe a point which is 'inside' [this] Rectangle
	  */
	public inline function contains(ox:Float, oy:Float):Bool {
		return (
			(ox > x && (ox < (x + w))) &&
			(oy > y && (oy < (y + h)))
		);
	}

	/**
	  * Whether [point] is 'inside' [this] Rectangle
	  */
	public inline function containsPoint(point : Point):Bool {
		return contains(point.x, point.y);
	}
	
	/**
	  * Whether [rect] is 'inside' [this] Rectangle
	  */
	public function containsRect(o : Rectangle):Bool {
		if (containsPoint(o.center)) {
			return true;
		}
		else {
			for (p in o.corners) {
				if (containsPoint( p )) {
					return true;
				}
			}
			return false;
		}
	}

	/**
	  * Vectorize [this] Rectangle
	  */
	public function vectorize(r : Rectangle):Rectangle {
		var pos:Point = topLeft.vectorize( r );
		var dim:Area = new Area(perc(w, r.w), perc(h, r.h));

		return new Rectangle(pos.x, pos.y, dim.width, dim.height);
	}

	/**
	  * Devectorize [this] Rectangle
	  */
	public function devectorize(r : Rectangle):Rectangle {
		var px:Percent = x, py:Percent = y, pw:Percent = w, ph:Percent = h;

		return new Rectangle(px.of(r.w), py.of(r.h), pw.of(r.w), ph.of(r.h));
	}

	/**
	  * Obtain [this] Rect's vertices
	  */
	public function getVertices():Vertices {
		var self:Rectangle = cast this;

		var verts = new Vertices([
			self.topLeft,
			self.topRight,
			self.bottomRight, 
			self.bottomLeft
		]);

		return verts;
	}

	/**
	  * Convert into a human-readable String
	  */
	public inline function toString():String {
		return 'Rectangle($x, $y, $w, $h)';
	}


/* === Computed Instance Fields === */

	/**
	  * The position of [this] Rectangle as a Point
	  */
	public var position(get, set):Point;
	private inline function get_position():Point {
		return new Point(x, y, z);
	}
	private inline function set_position(np : Point):Point {
		x = np.x;
		y = np.y;
		z = np.z;
		return position;
	}

	/**
	  * An Array of all corners of [this] Rectangle
	  */
	public var corners(get, never):Array<Point>;
	private function get_corners():Array<Point> {
		return [topLeft, topRight, bottomLeft, bottomRight];
	}

	/**
	  * [this] Rectangle's Area as a Float
	  */
	public var area(get, never):Float;
	private inline function get_area():Float {
		return (width * height);
	}

	/* the center of [this] Rectangle along the x-axis */
	public var centerX(get, set):Float;
	private inline function get_centerX():Float {
		return (x + (w / 2));
	}
	private inline function set_centerX(v : Float) {
		return (x = (v - (w / 2)));
	}

	/* the center of [this] Rectangle along the y-ayis */
	public var centerY(get, set):Float;
	private inline function get_centerY():Float {
		return (y + (h / 2));
	}
	private inline function set_centerY(v : Float) {
		return (y = (v - (h / 2)));
	}

	/**
	  * Point representing the 'center' of [this] Rectangle
	  */
	public var center(get, set):Point;
	private inline function get_center():Point {
		return new Point(centerX, centerY);
	}
	private function set_center(nc : Point):Point {
		centerX = nc.x;
		centerY = nc.y;
		return nc;
	}

	/**
	  * The top-right corner
	  */
	public var topRight(get, never):Point;
	private inline function get_topRight():Point {
		return new Point((x + width), y);
	} 
	/**
	  * The top-left corner
	  */
	public var topLeft(get, never):Point;
	private inline function get_topLeft():Point {
		return new Point(x, y);
	}

	/**
	  * The bottom-left corner
	  */
	public var bottomLeft(get, never):Point;
	private inline function get_bottomLeft():Point {
		return new Point(x, (y + height));
	}

	/**
	  * The bottom-right
	  */
	public var bottomRight(get, never):Point;
	private inline function get_bottomRight():Point {
		return new Point((x + width), (y + height));
	}

	/**
	  * Alias for 'width' as 'w'
	  */
	public var w(get, set):Float;
	private inline function get_w() return width;
	private inline function set_w(nw:Float) return (width = nw);

	/**
	  * Alias for 'height' as 'h'
	  */
	public var h(get, set):Float;
	private inline function get_h() return height;
	private inline function set_h(nh : Float) return (height = nh);

	/**
	  * Alias for 'depth' as 'd'
	  */
	public var d(get, set):Float;
	private inline function get_d() return depth;
	private inline function set_d(nd : Float) return (depth = nd);

/* === Instance Fields === */

	public var x:Float;
	public var y:Float;
	public var z:Float;
	public var width:Float;
	public var height:Float;
	public var depth:Float;

/* === Class Methods === */

	/**
	  * Shorthand to create a Percent
	  */
	private static inline function perc(what:Float, of:Float):Percent {
		return Percent.percent(what, of);
	}
}