package db;
import sys.db.Types;

@:index(code,unique)
class Lang extends sys.db.Object {

	public static var manager = new LangManager(Lang);

	public var id : SId;
	public var code : SString<5>;
	public var name : SString<20>;

	public override function toString() {
		return "#"+id+" "+code;
	}
}

class LangManager extends sys.db.Manager<Lang> {

	public function byCode( code : String ) {
		return select($code == code,false);
	}

}