package db;
import sys.db.Types;

class Comment extends sys.db.Object {

	public static var manager = new CommentManager(Comment);

	public var id : SId;
	@:relation(eid)
	public var entry : Entry;
	public var date : SDateTime;
	@:relation(uid)
	public var user : SNull<User>;
	public var userName : STinyText;
	public var userMail : STinyText;
	public var url : SNull<STinyText>;
	public var content : SText;
	public var htmlContent : SText;

}

class CommentManager extends sys.db.Manager<Comment> {

	public function browse( pos : Int, count : Int ) {
		return search(true, { orderBy : -date, limit : [pos,count] }, false);
	}

}