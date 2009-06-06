package db;
import mt.db.Types;

class User extends neko.db.Object {

	static var INDEXES = [["name",true]];
	static function RELATIONS() {
		return [{ prop : "group", key : "gid", manager : Group.manager, lock : false }];
	}
	public static var manager = new neko.db.Manager<User>(User);

	public var id : SId;
	public var name : SString<20>;
	public var gid : SInt;
	public var group(dynamic,dynamic) : Group;
	public var banEnding : SNull<SDateTime>;

	// prefs
	public var pass : SString<32>;
	public var email : SNull<SString<50>>;
	public var realName : STinyText;

	public function isBanned() {
		return banEnding != null && banEnding.getTime() > Date.now().getTime();
	}

	public override function toString() {
		return "#"+id+" "+name;
	}

}
