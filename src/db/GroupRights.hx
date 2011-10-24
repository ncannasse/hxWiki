package db;
import sys.db.Types;

@:id(gid,path)
class GroupRights extends sys.db.Object {

	@:relation(gid)
	public var group : Group;
	public var gid : SInt;
	public var path : SString<200>;
	public var canView : SBool;
	public var canEdit : SBool;
	public var canCreate : SBool;
	public var canDelete : SBool;
	public var canComment : SBool;
	public var canReadComments : SBool;
	public var canDeleteComments : SBool;
	public var isBlog : SBool;
	public var isForum : SBool;

	public function new( g, path ) {
		super();
		this.group = g;
		this.path = path;
	}

}