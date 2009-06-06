package db;
import mt.db.Types;

import db.ForumBrowsing;

class ForumTheme extends neko.db.Object {

	public static var manager = new neko.db.Manager<ForumTheme>(ForumTheme);

	public var id : SId;
	public var path : SString<200>;

	public function browse( ?u, ?sticky, start, limit ) {
		return ForumMessage.manager.browse(this,u,sticky,start,limit);
	}

	public static function groupByDay( messages : List<ForumMessage> ) {
		var days = new List();
		var current = null;
		var curday = null;
		for( m in messages ) {
			var day = DateTools.format(m.mdate,"%Y-%m-%d");
			if( day != curday ) {
				curday = day;
				current = new List();
				days.add({ date : day, threads : current });
			}
			current.add(m);
		}
		return days;
	}

	public function canAccess( u : User ) {
		return true;
	}

	public override function toString() {
		return "#"+id+" "+path;
	}

}
