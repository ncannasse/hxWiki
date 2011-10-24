package db;
import sys.db.Types;

class Dependency extends sys.db.Object {

	public static var manager = new DependencyManager(Dependency);

	public var id : SId;
	@:relation(eid)
	public var entry : Entry;
	public var path : STinyText;
	public var title : SNull<STinyText>;
	public var subs : SNull<SString<32>>;
	@:relation(tid,cascade)
	public var target : SNull<Entry>;

}

class DependencyManager extends sys.db.Manager<Dependency> {

	public function doCleanup( e : Entry ) {
		if( e != null ) delete($entry == e);
	}

	public function subSignature( e : Entry, edefault : Entry ) {
		return getCnx().request("SELECT MD5(GROUP_CONCAT(CONCAT(name,'#',IFNULL(title,'')))) FROM Entry WHERE pid IN ("+Std.string(e.id)+","+Std.string(edefault.id)+")").getResult(0);
	}

	public function renamed( e : Entry ) {
		getCnx().request("UPDATE Dependency SET tid = NULL WHERE tid = "+e.id);
	}

	public function translate( e : Entry ) {
		getCnx().request("UPDATE Dependency, Entry SET tid = "+e.id+" WHERE path = "+quote(e.get_path())+" AND Entry.lid = "+e.lang.id);
	}

	public function getBackLinks( e : Entry ) {
		return Entry.manager.unsafeObjects("SELECT Entry.* FROM Dependency, Entry WHERE Entry.id = Dependency.eid AND path = "+quote(e.get_path()),false);
	}

}