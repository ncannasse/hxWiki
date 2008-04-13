package db;
import mt.db.Types;

class File extends neko.db.Object {

	static var INDEXES = [["name",true]];
	static function RELATIONS() {
		return [{ prop : "user", key : "uid", manager : User.manager, lock : false }];
	}
	public static var manager = new neko.db.Manager<File>(File);

	public var id : SId;
	public var user(dynamic,dynamic) : SNull<User>;
	public var name : STinyText;
	public var content : SBinary;

}