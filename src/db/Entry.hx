package db;
import mt.db.Types;
import db.Version.VersionChange;

class Entry extends neko.db.Object {

	static var INDEXES = [["pid","name",true]];
	static function RELATIONS() {
		return [
			{ key : "pid", prop : "parent", manager : Entry.manager, lock : false },
			{ key : "vid", prop : "version", manager : Version.manager, lock : false },
		];
	}
	public static var manager = new EntryManager(Entry);

	public var id : SId;
	public var name : SString<32>;
	public var pid : SNull<SInt>;
	public var parent(dynamic,dynamic) : SNull<Entry>;
	public var title : SNull<STinyText>;
	public var version(dynamic,dynamic) : SNull<Version>;

	public function childs() {
		return db.Entry.manager.getChilds(this);
	}

	public function list() {
		var l = new List();
		l.add(this);
		var p = parent;
		while( p != null ) {
			l.push(p);
			p = p.parent;
		}
		return l;
	}

	public function markDeleted( user ) {
		title = null;
		if( version == null )
			return;
		version = null;
		// deleted mark
		var v = new db.Version(this,user);
		v.setChange(VDeleted,"","");
		v.insert();
	}

	public function getURL() {
		return "/"+get_path();
	}

	public function get_title() {
		if( title == null )
			return name;
		return title;
	}

	public function get_path() {
		return list().map(function(e) { return e.name; }).join("/");
	}

	public function cleanup() {
		if( db.Version.manager.count({ eid : id }) > 0 || manager.count({ pid : id }) > 0 ) return;
		delete();
		if( parent != null ) parent.cleanup();
	}

	public override function insert() {
		if( parent != null && parent.id == null ) {
			parent.insert();
			parent = parent; // reassign id
		}
		super.insert();
	}

	public override function toString() {
		return id+"#"+get_path();
	}

	public static function get( path : List<String> ) {
		var entry : db.Entry = null;
		for( name in path ) {
			var e = db.Entry.manager.search({ name : name, pid : if( entry == null ) null else entry.id },false).first();
			if( e == null ) {
				e = new db.Entry();
				e.name = name;
				e.parent = entry;
			}
			entry = e;
		}
		return entry;
	}

}

class EntryManager extends neko.db.Manager<Entry> {

	public function getChilds( e : Entry ) {
		var cond = (e == null)?"pid IS NULL":"pid = "+e.id;
		return objects("SELECT * FROM Entry WHERE "+cond+" ORDER BY name",false);
	}
}
