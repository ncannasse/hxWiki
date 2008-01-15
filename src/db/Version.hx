package db;
import mt.db.Types;

enum VersionChange {
	VContent;
	VDeleted;
	VName;
	VTitle;
}

class Version extends neko.db.Object {

	static function RELATIONS() {
		return [
			{ key : "eid", prop : "entry", manager : Entry.manager, lock : false },
			{ key : "uid", prop : "author", manager : User.manager, lock : false },
		];
	}
	public static var manager = new neko.db.Manager<Version>(Version);

	public var id : SId;
	public var date : SDateTime;
	public var entry(dynamic,dynamic) : Entry;
	public var author(dynamic,dynamic) : User;
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

	public override function toString() {
		return "v" + id + "#" + entry.get_path();
	}

}
