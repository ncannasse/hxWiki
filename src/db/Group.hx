package db;
import mt.db.Types;

class Group extends neko.db.Object {

	static var INDEXES = [["name",true]];
	public static var manager = new neko.db.Manager<Group>(Group);

	public var id : SId;
	public var name : SString<32>;

	public var canUploadImage : SBool;
	public var canUploadSWF : SBool;
	public var canAccessDB : SBool;
	public var maxUploadSize : SInt;
	public var allowedFiles : STinyText;

	public function new(name) {
		super();
		this.name = name;
	}

	public override function toString() {
		return "#"+id+" "+name;
	}

}