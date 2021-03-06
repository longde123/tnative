package tannus.async;

import tannus.ds.dict.DictKey;
import tannus.ds.Pair;
import tannus.ds.Lazy;
import tannus.ds.Ref;
import tannus.io.Signal;
import tannus.io.VoidSignal;

import tannus.async.Promise;
import tannus.async.Result;
import tannus.async.AsyncError;

import tannus.stream.Stream;

import haxe.ds.Option;
import haxe.ds.Either;
import haxe.Constraints.Function;
import haxe.extern.EitherType;

import Slambda.fn;

using Slambda;
using tannus.ds.ArrayTools;
using tannus.ds.IteratorTools;
using tannus.FunctionTools;
using tannus.async.Result;
using tannus.async.OptionTools;
using tannus.async.Asyncs;

/**
  a sequential, asynchronous 'feed' of data
 **/
class Feed<Item, Quality> {
    /* Constructor Function */
    public function new() {
        //hasBuffered = new VoidSignal();
        _onNext = new Array();
        buffer = new Array();
        ended = false;
    }

/* === Instance Methods === */

    public function add(token: FeedToken<Item, Quality>):Feed<Item, Quality> {
        push( token );
        return this;
    }

    public function adds(tokens: Iterable<FeedToken<Item, Quality>>):Feed<Item, Quality> {
        var target = this;
        for (token in tokens) {
            target = target.add( token );
        }
        return target;
    }

    public function post(post: FeedPost<Item, Quality>):Feed<Item, Quality> {
        //push(FeedToken.Post( post ));
        //return this;
        return add(Post( post ));
    }

    public function posts(posts: Array<FeedPost<Item, Quality>>):Feed<Item, Quality> {
        return adds([for (post in posts) Post(post)]);
    }

    public inline function put(item: FeedPost<Item, Quality>):Feed<Item, Quality> {
        return post( item );
    }

    public inline function puts(posts: Array<FeedPost<Item, Quality>>):Feed<Item, Quality> {
        return this.posts( posts );
    }

    public function pass():Feed<Item, Quality> {
        push(FeedToken.Pass);
        return this;
    }

    public function exception<Error>(error: Error):Feed<Item, Quality> {
        untyped {
            push(cast FeedToken.Exception(cast error));
        };
        return this;
    }

    @:native('_raise_')
    public inline function raise(error: Dynamic):Feed<Item, Quality> {
        return exception( error );
    }

    public function foot(last: Option<FeedPost<Item, Quality>>):Feed<Item, Quality> {
        push(FeedToken.Foot( last ));
        return this;
    }

    public function end():Feed<Item, Quality> {
        return foot(None);
    }

    /**
      push another FeedToken onto [this] Feed
     **/
    public function push(token: FeedToken<Item, Quality>) {
        if ( ended ) {
            throw 'Error: Cannot append $token to a Feed which has ended';
        }
        else {
            if (buffer.empty()) {
                if (!_onNext.empty()) {
                    var cbl = _onNext.copy();
                    _onNext = [];
                    for (f in cbl) {
                        f( token );
                    }
                }
                else {
                    buffer.push( token );
                }
            }
            else {
                buffer.push( token );
            }
        }
    }

    /**
      get a Promise for the next token in [this] Feed
     **/
    public function pop():Next<FeedToken<Item, Quality>> {
        if (buffer.hasContent()) {
            var tk = buffer.shift();
            switch tk {
                case null: throw 'assert';
                case _:
                    return Next.plainAsync( tk );
            }
        }
        else {
            return new Promise(function(yes, _) {
                onNext(function(tk: FeedToken<Item, Quality>) {
                    yes( tk );
                });
            });
        }
    }

    /**
      get the next token in [this] Feed
     **/
    public inline function next():Next<FeedToken<Item, Quality>> {
        return pop();
    }

    public inline function onNext(f: FeedToken<Item, Quality>->Void) {
        _onNext.push( f );
    }

    /**
      convert [this] Feed into a Stream
     **/
    public function stream():Stream<Item, Quality> {
        return Stream.feed( this );
    }

    /**
      defer [f] to the next execution stack
     **/
    public static inline function defer(f: Void->Void):Void {
        #if (js && nodejs)
            #if haxe4
            js.Syntax.code
            #else
            untyped __js__
            #end
            ('process.nextTick({0})', f);
        #else
            haxe.MainLoop.addThread( f );
        #end
    }

    /**
      delay [f] by [ms] milliseconds
     **/
    public static inline function wait(ms:Int, f:Void->Void):Void {
        haxe.Timer.delay(f, ms);
    }

/* === Instance Fields === */

    var buffer: Array<FeedToken<Item, Quality>>;
    var ended(default, null): Bool;
    var _onNext: Array<FeedToken<Item, Quality> -> Void>;
}

/**
  represents a 'token' item in a Feed<Item, Quality>
 **/
enum FeedToken<Item, Quality> {
    Post(item: FeedPost<Item, Quality>): FeedToken<Item, Quality>;
    Foot(last: Option<FeedPost<Item, Quality>>): FeedToken<Item, Quality>;
    Exception<Error>(e: Error): FeedToken<Item, Error>;
    Pass(): FeedToken<Item, Quality>;
}

/**
  the enumerated base-type for a FeedPost
 **/
enum FeedPostBase<Item, Quality> {
    PostPlain(item: Item): FeedPostBase<Item, Quality>;
    PostLazyPlain(item: Lazy<Item>): FeedPostBase<Item, Quality>;
    PostLazy(item: Lazy<FeedPost<Item, Quality>>): FeedPostBase<Item, Quality>;
    PostDeferred(item: Next<FeedPost<Item, Quality>>): FeedPostBase<Item, Quality>;
}

/**
  a 'post' in a Feed<Item, Q>
 **/
abstract FeedPost<Item, Q> (FeedPostBase<Item, Q>) from FeedPostBase<Item, Q> to FeedPostBase<Item, Q> {
    /* Constructor Function */
    public inline function new(post)
        this = post;

/* === Instance Methods === */

    @:to
    public function item():Next<Item> {
        switch type {
            case PostPlain(item):
                return Next.sync( item );

            case PostLazyPlain(_.get() => item):
                return Next.sync( item );

            case PostLazy(_.get() => post):
                return post.item();

            case PostDeferred(next):
                return next.flatMap.fn(_.item());
        }
    }

/* === Instance Fields === */

    public var type(get, never): FeedPostBase<Item, Q>;
    inline function get_type() return this;

/* === Casting / Factory Methods === */

    @:from
    public static function ofItem<T, Q>(item: T):FeedPost<T, Q> {
        return PostPlain( item );
    }

    @:from
    public static function ofLazyItem<T, Q>(item: Lazy<T>):FeedPost<T, Q> {
        return PostLazyPlain( item );
    }

    @:from
    public static function ofLazy<T, Q>(item: Lazy<FeedPost<T, Q>>):FeedPost<T, Q> {
        return PostLazy( item );
    }

    @:from
    public static function ofPromise<T, Q>(promise: Promise<FeedPost<T, Q>>):FeedPost<T, Q> {
        return PostDeferred( promise );
    }
}
