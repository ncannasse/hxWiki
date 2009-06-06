package db;
import mt.db.Types;

class ForumBrowsing extends neko.db.Object {

	static var TABLE_IDS = ["uid","mid"];

	static function RELATIONS(){
		return [
			{ prop:"user", key:"uid", manager:User.manager, lock : false },
			{ prop:"thread", key:"mid", manager:ForumMessage.manager, lock : false }
		];
	}

	public static var manager = new neko.db.Manager<ForumBrowsing>(ForumBrowsing);

	public var date : SDateTime;
	public var user(dynamic,dynamic) : User;
	public var thread(dynamic,dynamic) : ForumMessage;

	public static function set( user:User, thread:ForumMessage, date : Date ) {
		var sdate = manager.quote(date.toString());
		neko.db.Manager.cnx.request("INSERT INTO ForumBrowsing (uid, mid, date) VALUES ("+user.id+", "+thread.id+", "+sdate+") ON DUPLICATE KEY UPDATE date = "+sdate);
	}

	public static function cleanup( user:User ) {
		neko.db.Manager.cnx.request("DELETE FROM ForumBrowsing WHERE uid = "+user.id);
	}

}
