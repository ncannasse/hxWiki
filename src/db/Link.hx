package db;
import mt.db.Types;

class Link extends neko.db.Object {

	static var INDEXES = [["kind","priority"]];
	public static var manager = new LinkManager(Link);

	public var id : SId;
	public var title : STinyText;
	public var url : STinyText;
	public var kind : SInt;
	public var priority : SInt;

}

class LinkManager extends neko.db.Manager<Link> {

	public function list( kind : Int ) : List<{ title : String, url : String }> {
		return results("SELECT title, url FROM Link WHERE kind = "+kind+" ORDER BY priority DESC");
	}

}