package db;
import sys.db.Types;

@:id(path)
class EntryConfig extends sys.db.Object {

	public var path : SString<200>;
	public var isBlog : SBool;
	public var isForum : SBool;
	public var cssClass : Null<STinyText>;
	public var designMTT : Null<STinyText>;
	public var layout : Null<SText>;

}