package db;
import sys.db.Types;

@:index(kind,priority)
class Link extends sys.db.Object {

	public var id : SId;
	public var title : SText;
	public var url : STinyText;
	public var kind : SInt;
	public var priority : SInt;

}
