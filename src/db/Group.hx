package db;
import sys.db.Types;

@:index(name,unique)
class Group extends sys.db.Object {

	public var id : SId;
	public var name : SString<32>;

	public var canRegister : SBool;
	public var canUploadImage : SBool;
	public var canUploadSWF : SBool;
	public var canUploadOverwrite : SBool;
	public var canAccessDB : SBool;
	public var canModerateForum : SBool;
	public var canInsertHTML : SBool;
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