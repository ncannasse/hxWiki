package db;
import sys.db.Types;

/**
	Database session class
**/
@:id(sid) @:index(uid,unique)
class Session extends SessionData {

	static var UID_CHARS = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";
	static var FIELDS = {
		var fl = Type.getInstanceFields(SessionData);
		for( x in Type.getInstanceFields(sys.db.Object) )
			fl.remove(x);
		#if php
		fl.remove("get_user");
		fl.remove("set_user");
		#end
		fl.remove("setUser");
		fl;
	}

	@:relation(uid)
	public var user : SNull<User>;
	public var sid : SString<32>;
	public var uid : SNull<SInt>;
	public var mtime : SDateTime;
	public var ctime : SDateTime;
	public var data : SBinary;

	public override function setUser( u : User ) {
		if( uid != u.id )
			manager.delete($user == u);
		user = u;
		super.setUser(u);
	}

	public function setError( err : String, ?params : Dynamic ) {
		notification = { error : true, text : Text.format(err,params) };
	}

	public function setMessage( msg : String, ?params : Dynamic ) {
		notification = { error : false, text : Text.format(msg,params) };
	}

	public override function update() {
		var o = {};
		for( f in FIELDS )
			Reflect.setField(o,f,Reflect.field(this,f));
		var oldData = data;
		data = neko.Lib.serialize(o);
		if( data != oldData )
			mtime = Date.now();
		super.update();
	}

	static function loadExisting( sid ) {
		if( sid == null )
			return null;
		var s = manager.get(sid,true);
		if( s == null )
			return null;
		var o;
		try {
			o = neko.Lib.unserialize(s.data);
		} catch( e : Dynamic ) {
			return null;
		}
		for( f in Reflect.fields(o) )
			Reflect.setField(s,f,Reflect.field(o,f));
		return s;
	}

	public static function initialize( sid : String ) {
		var s = loadExisting(sid);
		if( s != null )
			return s;
		s = new Session();
		s.sid = makeUniqueId(32);
		s.ctime = Date.now();
		s.userName = "";
		if( Std.random(1000) == 0 )
			cleanup(3);
		return s;
	}

	public static function makeUniqueId(n) {
		var nchars = UID_CHARS.length;
		var k = "";
		for( i in 0...n )
			k += UID_CHARS.charAt(Std.random(nchars));
		return k;
	}

	public static function cleanup( days : Int ) {
		manager.delete($mtime < $now() - $days(days));
	}
}
