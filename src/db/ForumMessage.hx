package db;
import sys.db.Types;

@:index(pid,mdate)
class ForumMessage extends sys.db.Object {

	public static var COLUMNS = ["ForumMessage.*","User.name as login", "User.realName as name", "Group.canModerateForum as isModerator"];
	public static var manager = new ForumMessageManager(ForumMessage);

	public var id : SId;
	public var uid : SInt;
	public var tid : SInt;
	public var pid : SNull<SInt>;
	public var date : SDateTime;
	public var mdate : SDateTime;
	public var title : SString<35>;
	public var content : SText;
	public var htmlContent : SText;
	public var isLocked : SBool;
	public var isSticky : SBool;
	public var replyCount : SInt;
	public var lastUid : SNull<SInt>;
	public var lastLogin : SString<20>;

	@:skip public var readed : Bool;
	@:skip public var login : String;
	@:skip public var isModerator : Bool;

	@:relation(uid)
	public var user : User;
	@:relation(tid)
	public var theme : ForumTheme;
	@:relation(pid,lock)
	public var parent : SNull<ForumMessage>;
	@:relation(lastUid)
	public var lastReply : SNull<User>;

	public function new(u) {
		super();
		user = u;
	}

	public function isThread() {
		return pid == null;
	}

	public function browse( start, limit ) {
		return manager.browseMessages(this,start,limit);
	}

	public function browsePosition( d : Date ) {
		if( d.getTime() >= mdate.getTime() )
			return replyCount - 1;
		return manager.browsePosition(this,d) + 1;
	}

	public function canReply( u : db.User ) {
		if( !isThread() )
			return false;
		// we allow not logged users to see the 'Reply' button
		if( u == null )
			return true;
		if( u.group.canModerateForum )
			return true;
		if( isLocked || autoLocked() )
			return false;
		return true;
	}

	public function autoLocked() {
		return (Date.now().getTime() - mdate.getTime()) > Config.FORUM_AUTOLOCK_DAYS * 24 * 60.0 * 60.0 * 1000.0;
	}

	override public function insert(){
		super.insert();
		try {
			App.database.request("INSERT INTO ForumSearch (id,pid, data) VALUES ("+id+","+(if( parent == null ) id else parent.id)+","+App.database.quote(user.name+" "+title+" "+content)+")");
		} catch( e : Dynamic ) {
			initSearchTable();
			throw "ForumSearch table created";
		}
	}

	override public function delete() {
		if( parent == null ) {
			manager.cleanupThread(this);
			App.database.request("DELETE FROM ForumSearch WHERE pid = "+id);
		} else
			App.database.request("DELETE FROM ForumSearch WHERE id = "+id);
		super.delete();
	}

	public function updateContent() {
		App.database.request("UPDATE ForumSearch SET data = "+App.database.quote(user.name+" "+title+" "+content)+" WHERE id = "+id);
	}

	public static function initSearchTable() {
		App.database.request("CREATE TABLE ForumSearch ( id int primary key, pid int not null, data text not null, fulltext key FS_Data(data), key FS_Pid(pid) ) ENGINE=MYISAM");
	}

	public static function search( text, u ) {
		var messages = manager.searchMessagesContaining(text);
		for( m in messages )
			if( !m.theme.canAccess(u) )
					messages.remove(m);
		return messages;
	}

}
