package tannus.css;

import tannus.io.ByteArray;
import tannus.io.Byte;
import tannus.css.*;

class Writer {
	/* Constructor Function */
	public function new():Void {
		
	}

/* === Instance Methods === */

	/**
	  * Generate CSS Stylesheet
	  */
	public function generate(sheet : StyleSheet):ByteArray {
		reset();

		for (rule in sheet.rules) {
			writeRule( rule );
		}

		return buffer;
	}

	/**
	  * Write a Rule instance
	  */
	private function writeRule(rule : Rule):Void {
		var tab:String = '    ';
		writeln(rule.selector + ' {');

		for (prop in rule.properties) {
			writeln('$tab${prop.name}: ${prop.value};');
		}

		writeln( '}' );
	}

	/**
	  * Restore [this] to default
	  */
	private inline function reset():Void {
		buffer = new ByteArray();
	}

	/**
	  * Write to [buffer]
	  */
	private function write(what : ByteArray):Void {
		buffer.append( what );
	}

	/**
	  * Write data to [buffer], followed by newline
	  */
	private function writeln(data : ByteArray):Void {
		data.push( '\n' );
		buffer.append( data );
	}

/* === Instance Fields === */

	private var buffer : ByteArray;
}
