package db;
import mt.db.Types;

class Dependency extends neko.db.Object {

	static function RELATIONS() {
		return [
			{ prop : "entry", key : "eid", manager : Entry.manager, lock : false },
			{ prop : "target", key : "tid", manager : Entry.manager, lock : false },
		];
	}
	public static var manager = new DependencyManager(Dependency);

	public var id : SId;
	public var entry(dynamic,dynamic) : Entry;
	public var path : STinyText;
	public var title : SNull<STinyText>;
	public var subs : SNull<SString<32>>;
	public var target(dynamic,dynamic) : SNull<Entry>;

}

class DependencyManager extends neko.db.Manager<Dependency> {

	public function cleanup( e : Entry ) {
		execute("DELETE FROM Dependency WHERE eid = "+e.id);
	}

	public function subSignature( e : Entry ) {
		return execute("SELECT MD5(GROUP_CONCAT(CONCAT(name,'#',IFNULL(title,'')))) FROM Entry WHERE pid = "+e.id).getResult(0);
	}

	public function renamed( e : Entry ) {
		execute("UPDATE Dependency SET tid = NULL WHERE tid = "+e.id);
	}

	public function getBackLinks( e : Entry ) {
		return Entry.manager.objects("SELECT Entry.* FROM Dependency, Entry WHERE Entry.id = Dependency.eid AND path = "+quote(e.get_path()),false);
	}

}