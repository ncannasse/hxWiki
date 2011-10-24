package db;
import sys.db.Types;

@:id(uid,mid)
class ForumBrowsing extends sys.db.Object {

	public var date : SDateTime;
	@:relation(uid)
	public var user : User;
	@:relation(mid)
	public var thread : ForumMessage;

	public static function set( user:User, thread:ForumMessage, date : Date ) {
		var sdate = "'"+date.toString()+"'";
		sys.db.Manager.cnx.request("INSERT INTO ForumBrowsing (uid, mid, date) VALUES ("+user.id+", "+thread.id+", "+sdate+") ON DUPLICATE KEY UPDATE date = "+sdate);
	}

	public static function cleanup( user:User ) {
		manager.delete($user == user);
	}

}
