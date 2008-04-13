package db;
import mt.db.Types;
import db.Version.VersionChange;

class Entry extends neko.db.Object {

	static var INDEXES = [["pid","name",true]];
	static function RELATIONS() {
		return [
			{ key : "pid", prop : "parent", manager : Entry.manager, lock : false },
			{ key : "vid", prop : "version", manager : Version.manager, lock : false },
			{ key : "lid", prop : "lang", manager : Lang.manager, lock : false },
		];
	}
	public static var manager = new EntryManager(Entry);

	public var id : SId;
	public var name : SString<32>;
	public var pid : SNull<SInt>;
	public var parent(dynamic,dynamic) : SNull<Entry>;
	public var title : SNull<STinyText>;
	public var vid : SNull<SInt>;
	public var version(dynamic,dynamic) : SNull<Version>;
	public var lang(dynamic,dynamic) : Lang;
	public var lid : SInt;

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
		return "/"+get_path()+"?lang="+lang.code;
	}

	public function get_title() {
		if( title == null )
			return name;
		return title;
	}

	public function get_path() {
		return list().map(function(e) { return e.name; }).join("/");
	}

	public function hasContent() {
		return vid != null;
	}

	public function cleanup() {
		if( id == null ) return;
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

	public static function get( path : List<String>, lang : Lang ) {
		var entry : db.Entry = null;
		for( name in path ) {
			var e = db.Entry.manager.search({ name : name, pid : if( entry == null ) null else entry.id, lid : lang.id },false).first();
			if( e == null ) {
				e = new db.Entry();
				e.lang = lang;
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
		return objects("SELECT * FROM Entry WHERE pid = "+e.id+" ORDER BY name",false);
	}

	public function getRoots( l : Lang ) {
		return objects("SELECT * FROM Entry WHERE pid IS NULL AND lid = "+l.id+" ORDER BY name",false);
	}

	public function resolve( path : List<String>, lang : Lang ) {
		var eid = null;
		var vid = null;
		for( name in path ) {
			var r = result("SELECT id, vid FROM Entry WHERE name = "+quote(name)+" AND lid = "+lang.id+" AND pid "+((eid == null)?"IS NULL":"= "+eid));
			if( r == null )
				return null;
			eid = r.id;
			vid = r.vid;
		}
		return vid;
	}

	public function updateSearchContent( e : Entry ) {
		try {
			if( e.version == null )
				execute("DELETE FROM Search WHERE id = "+e.id);
			else {
				var content = quote(e.get_title()+" "+e.version.content);
				execute("INSERT INTO Search (id,data) VALUES ("+e.id+","+content+") ON DUPLICATE KEY UPDATE data = "+content);
			}
		} catch( err : Dynamic ) {
			execute("CREATE TABLE Search ( id int primary key, data text not null, fulltext key Search_data(data) ) TYPE=MYISAM");
			updateSearchContent(e);
		}
	}

	public function searchExpr( expr : String, pos : Int, count : Int ) : List<Entry> {
		return results("SELECT id FROM Search WHERE MATCH(data) AGAINST ("+quote(expr)+" IN BOOLEAN MODE) LIMIT "+pos+","+count).map(function(r) return db.Entry.manager.get(r.id,false));
	}

}
