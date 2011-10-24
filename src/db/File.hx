package db;
import sys.db.Types;

class File extends sys.db.Object {

	public var id : SId;
	@:relation(uid)
	public var user : SNull<User>;
	public var name : STinyText;
	public var content : SBinary;

}
