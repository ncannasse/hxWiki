package db;
import mt.db.Types;

/**
	Database session class
**/
class Session extends SessionData {

	static function RELATIONS() {
		return [{ key : "uid", prop : "user", manager : User.manager }];
	}

	static var TABLE_IDS = ["sid"];
	static var INDEXES = [["uid",true]];
	static var UID_CHARS = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";
	static var manager = new neko.db.Manager<Session>(Session);

	public var sid : SString<32>;
	public var uid : SNull<SInt>;
	public var mtime : SDateTime;
	public var ctime : SDateTime;
	public var data : SBinary;

	public override function setUser( u : User ) {
		if( uid != u.id )
			App.database.request("DELETE FROM Session WHERE uid = "+u.id);
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
		var old = { __cache__ : untyped this.__cache__, sid : sid, uid : uid, mtime : mtime, ctime : ctime, __user : user };
		var oldData = this.data;
		for( f in Reflect.fields(old) )
			Reflect.deleteField(this,f);
		Reflect.deleteField(this,"data");
		data = neko.Lib.serialize(this);
		for( f in Reflect.fields(old) )
			Reflect.setField(this,f,Reflect.field(old,f));
		if( data != oldData )
			mtime = Date.now();
		super.update();
	}

	static function loadExisting( sid ) {
		if( sid == null )
			return null;
		var s = manager.getWithKeys({ sid : sid },true);
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
		App.database.request("DELETE FROM Session WHERE mtime < NOW() - INTERVAL "+days+" DAY");
	}
}
