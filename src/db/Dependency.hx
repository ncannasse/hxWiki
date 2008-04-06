package db;
import mt.db.Types;

class Dependency extends neko.db.Object {

	static function RELATIONS() {
		return [{ prop : "entry", key : "eid", manager : Entry.manager, lock : false }];
	}
	public static var manager = new DependencyManager(Dependency);

	public var id : SId;
	public var entry(dynamic,dynamic) : Entry;
	public var path : STinyText;
	public var title : SNull<STinyText>;

}

class DependencyManager extends neko.db.Manager<Dependency> {

	public function cleanup( e : Entry ) {
		execute("DELETE FROM Dependency WHERE eid = "+e.id);
	}

}