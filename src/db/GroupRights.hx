package db;
import mt.db.Types;

class GroupRights extends neko.db.Object {

	static var TABLE_IDS = ["gid","path"];
	static function RELATIONS() {
		return [{ prop : "group", key : "gid", manager : Group.manager, lock : false }];
	}
	public static var manager = new neko.db.Manager<GroupRights>(GroupRights);

	public var group(dynamic,dynamic) : Group;
	public var gid : SInt;
	public var path : SString<200>;
	public var canView : SBool;
	public var canEdit : SBool;
	public var canCreate : SBool;
	public var canDelete : SBool;

	public function new( g, path ) {
		super();
		this.group = g;
		this.path = path;
	}

}