package tannus.display.backend.java;

import tannus.display.backend.java.*;
import tannus.display.TGraphics;

import tannus.graphics.Color;
import tannus.graphics.PathComponent;
import tannus.graphics.PathStyleAlteration;
import tannus.graphics.GraphicsPath;
import tannus.graphics.LineStyle;
import tannus.graphics.PathStyle;

import tannus.io.Signal;
import tannus.io.Pointer;

import tannus.geom.*;

import tannus.ds.Maybe;
import tannus.ds.Queue;
import tannus.ds.ActionStack;

import java.awt.Graphics;
import java.awt.Graphics2D;
import java.awt.geom.Line2D;

class PathRenderer {
	/* Constructor Function */
	public function new(owner : TannusGraphics):Void {
		graphics = owner;
		pathQ = new Queue();

		reset();
		__init();
	}

/* === Instance Methods === */

	/**
	  * Initialize [this] PathRenderer
	  */
	private inline function __init():Void {
		win.frameEvent.listen(function(_g : Graphics2D):Void {
			g = _g;


			drawAll();
		});
	}

	/**
	  * restore [this] to it's default state
	  */
	public inline function reset():Void {
		path = null;
		cursor = new Point();
		buffer = new ActionStack();
		styles = new PathStyle();
		_history = new Array();
	}

	/**
	  * Queue a path to be drawn
	  */
	public inline function draw(path : GraphicsPath):Void {
		pathQ.append( path );
	}

	/**
	  * Draw all paths in the Queue
	  */
	private inline function drawAll():Void {
		var pl = pathQ;

		while ( true ) {
			var _p:GraphicsPath = pl.pop();

			if (_p != null) {
				_draw( _p );
			}
			else {
				break;
			}
		}
	}

	/**
	  * Draw a path
	  */
	public function _draw(p : GraphicsPath):Void {
		reset();
		path = p;
		if (path.vectorized) {
			path = p.clone();
			path.devectorize();
		}

		var drawn:Bool = false;
		buffer.append(drawn = true);

		path.each(drawComponent.bind(_));

		if (!drawn) {
			buffer.call();
		}
	}

	/**
	  * Draw a path-component
	  */
	private function drawComponent(op : PathComponent):Void {
		switch ( op ) {
			case MoveTo( pos ):
				buffer.append({
					cursor = pos.clone();
				});

			case LineTo( pos ):
				buffer.append({
					g.drawLine(i(cursor.x), i(cursor.y), i(pos.x), i(pos.y));
					cursor = pos.clone();
				});

			case Rectangle( r ):
				buffer.append({
					g.drawRect(i(r.x), i(r.y), i(r.w), i(r.h));
				});

			case Ellipse( r ):
				buffer.append({
					g.drawOval(i(r.x), i(r.y), i(r.w), i(r.h));
				});
			
			case StyleAlteration( change ):
				buffer.append({
					styleChange( change );
				});

			/* == SubPath Operation == */
			case SubPath( sub ):
				buffer.append({
					sub.draw();
				});

			case StrokePath:
				syncStyles();
				buffer.call();

			default:
				throw 'PathError: Cannot handle $op!';
		}
	}

	/**
	  * Perform a Style Alteration
	  */
	private function styleChange(change : PathStyleAlteration):Void {
		switch (change) {
			case LineWidth( nwidth ):
				lineStyle.width = nwidth;

			case LineColor( color ):
				lineStyle.color = color;

			default:
				throw 'PathError: Cannot perform Style Alteration $change!';
		}

		syncStyles();
	}

	/**
	  * Style our Graphics2D object to match the styles of the current state
	  */
	private inline function syncStyles():Void {
		var stroke = new java.awt.BasicStroke(i(lineStyle.width));
		g.setStroke( stroke );
		g.setColor( lineStyle.color );
	}

	/**
	  * 'save' the current State of [this]
	  */
	public function save():Void {
		var currentState:PathState = new PathState(styles.clone(), buffer.clone());

		_history.push( currentState );

		buffer = new ActionStack();
	}

	/**
	  * 'restore' [this] to a previous State
	  */
	public function restore():Void {
		var prev:Maybe<PathState> = _history.pop();

		if (prev) {
			var state:PathState = (cast prev);
			styles = state.styles;
			buffer = state.buffer;
			syncStyles();
		}
	}

	/**
	  * Convert Float to Int
	  */
	private static inline function i(f : Float):Int {
		return Std.int( f );
	}

/* === Computed Fields === */

	/**
	  * The Window object
	  */
	private var win(get, never):Window;
	private inline function get_win():Window {
		return (graphics.win);
	}

	/**
	  * The current styling for drawn lines
	  */
	private var lineStyle(get, never):LineStyle;
	private inline function get_lineStyle():LineStyle {
		return (styles.lineStyle);
	}

/* === Instance Fields === */

	//- the TGraphics instance which spawned [this]
	private var graphics : TannusGraphics;

	//- the Graphics2D instance we're currently using
	private var g : Graphics2D;

	//- the GraphicsPath currently being drawn
	private var path : Null<GraphicsPath>;

	//- Queue of GraphicsPath's to be drawn
	private var pathQ : Queue<GraphicsPath>;

	//- the current 'cursor' position
	private var cursor : Point;

	//- An ActionStack of drawing operations, awaiting 'stroke' or 'fill' operations
	private var buffer : ActionStack;

	//- History Stack, to keep track of Style-States
	private var _history : Array<PathState>;

	//- the current styling for drawn paths
	private var styles : PathStyle;
}