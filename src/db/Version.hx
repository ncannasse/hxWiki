package db;
import mt.db.Types;

enum VersionChange {
	VContent;
	VDeleted;
	VName;
	VTitle;
	VRestore;
}

class Version extends neko.db.Object {

	static function RELATIONS() {
		return [
			{ key : "eid", prop : "entry", manager : Entry.manager, lock : false },
			{ key : "uid", prop : "author", manager : User.manager, lock : false },
		];
	}
	public static var manager = new VersionManager(Version);

	public var id : SId;
	public var date : SDateTime;
	public var entry(dynamic,dynamic) : Entry;
	public var author(dynamic,dynamic) : SNull<User>;
	public var code : SInt;
	public var content : SNull<SText>;
	public var htmlContent : SNull<SText>;

	public function new( e, u ) {
		super();
		date = Date.now();
		entry = e;
		author = u;
	}

	public function setChange( c : VersionChange, vold, vnew ) {
		code = Type.enumIndex(c);
		content = vold;
		htmlContent = vnew;
	}

	public function getChange() : VersionChange {
		return Reflect.field(VersionChange,Type.getEnumConstructs(VersionChange)[code]);
	}

	public override function toString() {
		return "v" + id + "#" + entry.get_path();
	}

}

class VersionManager extends neko.db.Manager<Version> {

	public function history( e : List<Entry>, user : User, pos : Int, count : Int ) {
		var cond = (e == null || e.isEmpty())?"TRUE":"eid IN ("+e.map(function(e) return e.id).join(",")+")";
		if( user != null )
			cond += " AND uid = "+user.id;
		return objects("SELECT * FROM Version WHERE "+cond+" ORDER BY id DESC LIMIT "+pos+","+count,false);
	}

	public function previous( v : Version ) {
		var r = result("SELECT MAX(id) as id FROM Version WHERE eid = "+v.entry.id+" AND id < "+v.id+" AND code IN (0,4)");
		if( r == null )
			return null;
		var v = get(r.id,false);
		// retrieve content of restored version
		if( v.getChange() == VRestore )
			v = get(Std.parseInt(v.content),false);
		return v;
	}

}