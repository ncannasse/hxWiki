package db;
import mt.db.Types;

class File extends neko.db.Object {

	static var INDEXES = [["name",true]];
	public static var manager = new neko.db.Manager<File>(File);

	public var id : SId;
	public var name : STinyText;
	public var content : SBinary;

}