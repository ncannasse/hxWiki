package db;
import sys.db.Types;

@:index(name,unique)
class User extends sys.db.Object {

	public var id : SId;
	public var name : SString<20>;
	public var gid : SInt;
	@:relation(gid)
	public var group : Group;
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
