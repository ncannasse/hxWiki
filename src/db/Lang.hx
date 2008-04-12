package db;
import mt.db.Types;

class Lang extends neko.db.Object {

	static var INDEXES = [["code",true]];
	public static var manager = new LangManager(Lang);

	public var id : SId;
	public var code : SString<5>;
	public var name : SString<20>;

	public override function toString() {
		return "#"+id+" "+code;
	}
}

class LangManager extends neko.db.Manager<Lang> {

	public function byCode( code ) {
		return object("SELECT * FROM Lang WHERE code = "+quote(code),false);
	}

}