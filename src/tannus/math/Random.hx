package tannus.math;

import tannus.math.TMath;

class Random {
	/* Constructor Function */
	public function new(?seed:Int):Void {
		this.state = (seed != null ? seed : Math.floor(Math.random() * TMath.INT_MAX));
	}

/* === Instance Methods === */

	/**
	  * Increment the 'seed' of [this] Random-Number-Generator, and return it's integer value
	  */
	public function nextInt():Int {
		this.state = cast ((1103515245.0 * this.state + 12345) % TMath.INT_MAX);
		return this.state;
	}

	/**
	  * Increment [this]'s seed, and return it's float value
	  */
	public function nextFloat():Float {
		return (nextInt() / TMath.INT_MAX);
	}

	/**
	  * Set the seed to [value]
	  */
	public function reset(value : Int):Void {
		this.state = value;
	}

	/**
	  * Get a random integer between [min] and [max]
	  */
	public function randint(min:Int, max:Int):Int {
		return Math.floor(nextFloat() * (max - min + 1) + min);
	}

	/**
	  * Choose randomly between 'true' and 'false'
	  */
	public function randbool():Bool {
		return (randint(0, 1) == 1);
	}

	/**
	  * Choose an item from [set] at random
	  */
	public function choice<T>(set : Array<T>):T {
		return set[(randint(0, set.length - 1))];
	}

	/**
	  * "shuffle" [set] by randomly re-assigning the indices of each item
	  */
	public function shuffle <T> (set:Array<T>):Array<T> {
		var copy:Array<T> = set.copy();
		var result:Array<T> = new Array();

		while (copy.length != 1) {
			var el:T = choice(copy);
			copy.remove(el);
			result.push(el);
		}
		return result;
	}

/* === Instance Fields === */

	private var state : Int;

/* === Static Methods === */

	/**
	  * Get a random-seed from a String
	  */
	public static function stringSeed(seed : String):Random {
		var state:Int = 0;
		var ba = tannus.io.ByteArray.fromString(seed);
		for (bit in ba) {
			seed += bit.toInt();
		}
		return new Random(state);
	}
}
