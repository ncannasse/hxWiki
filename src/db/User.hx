package db;
import mt.db.Types;

class User extends neko.db.Object {

	static var INDEXES = [["name",true]];
	public static var manager = new neko.db.Manager<User>(User);

	public var id : SId;
	public var name : SString<20>;

	// prefs
	public var pass : SString<32>;
	public var email : SNull<SString<50>>;
	public var realName : STinyText;

	// rights
	public var isAdmin : SBool;

	public override function toString() {
		return "#"+id+" "+name;
	}

}
