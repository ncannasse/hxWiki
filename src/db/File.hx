package db;
import mt.db.Types;

class File extends neko.db.Object {

	static function RELATIONS() {
		return [{ prop : "user", key : "uid", manager : User.manager, lock : false }];
	}
	public static var manager = new FileManager(File);

	public var id : SId;
	public var user(dynamic,dynamic) : SNull<User>;
	public var name : STinyText;
	public var content : SBinary;

}

class FileManager extends neko.db.Manager<File> {

	public function latest() : List<{ id : Int, uid : Int, name : String }> {
		return results("SELECT id, uid, name FROM File ORDER BY id DESC");
	}

}