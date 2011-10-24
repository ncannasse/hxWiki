package db;

class ForumMessageManager extends sys.db.Manager<ForumMessage> {

	override function make( m : ForumMessage ) {
		m.readed = m.readed != null;
	}

	override public function unsafeGet( id:Dynamic, ?lock:Bool ) : ForumMessage {
		if (lock == null) lock = true;
		return unsafeObject("SELECT "+ForumMessage.COLUMNS.join(",")+" FROM ForumMessage LEFT JOIN User ON ForumMessage.uid = User.id LEFT JOIN `Group` ON Group.id = User.gid WHERE ForumMessage.id = "+id+(if (lock) " FOR UPDATE" else ""), lock);
	}

	public function browse( t : ForumTheme, ?u : User, ?sticky : Bool, start : Int, limit : Int ) {
		var rstick = if( sticky == null ) "" else " AND isSticky = "+if( sticky ) 1 else 0;
		if( u == null ) {
			var rq = "
				SELECT "+ForumMessage.COLUMNS.join(",")+" FROM ForumMessage
				LEFT JOIN User ON ForumMessage.uid=User.id
				LEFT JOIN `Group` ON Group.id = User.gid
				WHERE ForumMessage.tid="+t.id+" AND ForumMessage.pid IS NULL "+rstick+"
				ORDER BY ForumMessage.mdate DESC
				LIMIT "+start+","+limit;
			return unsafeObjects(rq,false);
		}
		var rq = "
			SELECT "+ForumMessage.COLUMNS.join(",")+", IF ((ForumBrowsing.date >= ForumMessage.mdate), 1, NULL) AS readed
			FROM ForumMessage
				LEFT JOIN User ON ForumMessage.uid = User.id
				LEFT JOIN `Group` ON Group.id = User.gid
				LEFT JOIN ForumBrowsing ON ForumBrowsing.mid = ForumMessage.id AND ForumBrowsing.uid = "+u.id+"
			WHERE
				ForumMessage.tid="+t.id+" AND ForumMessage.pid IS NULL "+rstick+"
			ORDER BY ForumMessage.mdate DESC LIMIT "+start+","+limit;
		return unsafeObjects(rq,false);
	}

	public function browseMessages( t : ForumMessage, start : Int, limit : Int ) {
		var rq = "
			SELECT "+ForumMessage.COLUMNS.join(",")+" FROM ForumMessage
			LEFT JOIN User ON ForumMessage.uid = User.id
			LEFT JOIN `Group` ON Group.id = User.gid
			WHERE ForumMessage.pid = " + t.id + "
			ORDER BY ForumMessage.mdate
			LIMIT "+start+","+limit;
		return unsafeObjects(rq,false);
	}

	public function browsePosition( t : ForumMessage, d : Date ) {
		return count($parent == t && $date < d);
	}

	public function lastReply( t : ForumMessage ) {
		return select($parent == t, { orderBy : -id, limit : 1 },false);
	}

	public function countThreads( theme : ForumTheme ) {
		return count($parent == null && $theme == theme);
	}

	public function cleanupThread( t : ForumMessage ) {
		if( t != null ) delete($parent == t);
	}

	public function cleanupUser( u : User ) {
		function execute(rq) return getCnx().request(rq);
		// delete topics
		var pids = execute("SELECT id FROM ForumMessage WHERE uid = "+u.id+" AND pid IS NULL").results().map(function(r) return r.id);
		if( !pids.isEmpty() )
			execute("DELETE FROM ForumMessage WHERE pid IN ("+pids.join(",")+")");
		// delete messages
		execute("CREATE TEMPORARY TABLE TmpMessages SELECT pid, COUNT(*) as count FROM ForumMessage WHERE uid = "+u.id+" GROUP BY pid");
		execute("UPDATE ForumMessage, TmpMessages SET replyCount = replyCount - count WHERE ForumMessage.id = TmpMessages.pid");
		execute("DROP TEMPORARY TABLE TmpMessages");
		execute("DELETE FROM ForumMessage WHERE uid = "+u.id);
	}

	public function searchMessagesContaining( search:String ) : List<ForumMessage> {
		var ml = new List();
		var ids = getCnx().request("SELECT pid, COUNT(*) as m FROM ForumSearch WHERE MATCH(data) AGAINST ("+quote(search)+" IN BOOLEAN MODE) GROUP BY pid ORDER BY m DESC LIMIT 0,30").results();
		if( ids.length == 0 )
			return ml;
		var rq = "
			SELECT "+ForumMessage.COLUMNS.join(",")+" FROM ForumMessage
			LEFT JOIN User ON ForumMessage.uid = User.id
			LEFT JOIN `Group` ON Group.id = User.gid
			WHERE ForumMessage.id IN ("+ids.map(function(x) return x.pid).join(",")+")
		";
		var _ = unsafeObjects(rq,false); // will be cached
		for( x in ids ) {
			var m = get(x.pid,false);
			if( m != null )
				ml.add(m);
		}
		return ml;
	}

}
