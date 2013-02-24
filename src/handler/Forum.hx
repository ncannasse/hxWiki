package handler;

import db.ForumMessage;
import db.ForumTheme;

class ResultsBrowser<T> {

	public var page : Int;
	public var pages : Int;
	public var next : Int;
	public var prev : Int;
	public var size : Int;
	var index : Int;
	var browse : Int -> Int -> List<T>;

	public function new( count : Int, size : Int, browse : Int -> Int -> List<T>, ?defpos ) {
		this.size = size;
		this.browse = browse;
		page = App.request.getInt("page");
		if( page == null ) {
			if( defpos == null )
				page = 1;
			else
				page = Std.int(defpos()/size) + 1;
		}
		if( page < 1 )
			page = 1;
		prev = if( page > 1 ) page - 1 else null;
		if( count != null ) {
			pages = Math.ceil(count/size);
			if( pages == 0 )
				pages = 1;
		}
		next = if( pages == null || page < pages ) page + 1 else null;
		index = (page - 1) * size;
	}

	public function current() {
		return browse((page-1)*size,size);
	}

}

class Thread extends Handler<ForumMessage> {

	var path : String;
	var createEditor : Void -> Editor;

	public function new( path, createEditor ) {
		super();
		this.path = path;
		this.createEditor = createEditor;
	}

	override function findObject( id:Int, m:Bool ) : ForumMessage {
		var msg = db.ForumMessage.manager.get(id, m);
		if( msg == null || msg.pid != null )
			return null;
		if( !msg.theme.canAccess(App.user) )
			return null;
		return msg;
	}

	override function initialize() {
		free("objectDefault", "forum_thread.mtt", object(doShow, ReadOnly));
		logged("reply", "forum_post.mtt", object(doReply, ReadOnly));
		moderator("lock", object(doLock.bind(true)));
		moderator("unlock", object(doLock.bind(false)));
		moderator("move", object(doMove));
	}

	function doShow( thread:ForumMessage ){
		var prev = if( App.user == null ) null else db.ForumBrowsing.manager.search({ uid : App.user.id, mid : thread.id },false).first();
		var date = if( prev == null ) Date.now() else prev.date;
		var browser = new ResultsBrowser(
			thread.replyCount,
			Config.FORUM_MESSAGES_PER_PAGE,
			thread.browse,
			thread.browsePosition.bind(date)
		);
		var messages = browser.current();
		if( browser.page == 1 )
			messages.push(thread);
		if( !messages.isEmpty() && App.user != null ) {
			var m = messages.last();
			if( prev == null || prev.date.getTime() < m.date.getTime() )
				db.ForumBrowsing.set(App.user,thread,m.date);
		}
		App.context.thread = thread;
		App.context.theme = thread.theme;
		App.context.messages = messages;
		App.context.browser = browser;
	}

	function doLock( lock, thread:ForumMessage ){
		thread.isLock = lock;
		thread.update();
		throw Action.Goto(path+"/thread/"+thread.id);
	}

	function doReply( thread:ForumMessage ) {
		if( !thread.canReply(App.user) )
			throw Action.Error(path+"/"+thread.tid,Text.get.err_thread_locked);
		processPost(thread.theme,thread);
	}

	function checkCanPost( m : ForumMessage ) {
		if( m.parent == null && StringTools.trim(m.title) == "" ) {
			App.session.setError(Text.get.err_forum_title_empty);
			return false;
		}
		if( StringTools.trim(m.content).length < Config.FORUM_MIN_MSGLEN && !isModerator() ) {
			App.session.setError(Text.get.err_content_too_short);
			return false;
		}
		return true;
	}

	public function processPost( theme : ForumTheme, parent : ForumMessage, ?m ) {
		if( App.user.isBanned() )
			throw Action.Error(path,Text.get.err_forum_ban);
		var editor = createEditor();
		var isEdit = (m != null);
		if( m == null ) {
			m = new ForumMessage(App.user);
			m.parent = parent;
			m.theme = theme;
			m.title = "";
			m.content = "";
			m.date = Date.now();
			m.mdate = m.date;
		}
		m.content = App.request.get(editor.content, m.content);
		m.htmlContent = editor.format(m.content);
		var root = if( parent == null ) m else parent;
		var lock = isModerator() && App.request.exists("isLocked");
		// submit or preview
		if( App.request.exists("title") && parent == null ) {
			m.title = App.request.get("title");
			m.isSticky = (isModerator() && App.request.exists("isSticky"));
		}
		if( App.request.exists("submit") && checkCanPost(m) ) {
			if( root == m )
				root.isLock = lock;
			else if( lock != root.isLock ) {
				var r = db.ForumMessage.manager.get(root.id);
				r.isLock = lock;
				r.update();
			}
			if( isEdit ) {
				m.update();
				m.updateContent();
			} else if( parent == null ) {
				m.mdate = Date.now();
				m.lastUid = App.user.id;
				m.lastLogin = App.user.name;
				m.insert();
			} else {
				m.insert();
				parent = db.ForumMessage.manager.get(parent.id);
				parent.replyCount++;
				parent.mdate = m.date;
				parent.lastUid = App.user.id;
				parent.lastLogin = App.user.name;
				if( m.isLock )
					parent.isLock = true;
				if( parent.replyCount >= Config.FORUM_MAX_POST_PER_THREAD )
					parent.isLock = true;
				parent.update();
			}
			throw Action.Goto(path+"/thread/"+if( parent == null ) m.id else parent.id);
		}
		App.context.thread = parent;
		App.context.theme = theme;
		App.context.message = m;
		App.context.isLocked = root.isLock || lock;
		App.context.editor = editor;
		if( isEdit )
			App.context.action = path + "/message/"+m.id+"/edit";
		else if( parent != null )
			App.context.action = path + "/thread/"+parent.id+"/reply";
		else
			App.context.action = path + "/post";
	}


	function doMove( thread:ForumMessage ) {
		var t = db.ForumTheme.manager.get(App.request.getInt("target"),false);
		if( t != null ) {
			thread.theme = t;
			thread.update();
		}
		throw Action.Done(path+"/thread/"+thread.id,Text.get.forum_move_confirm);
	}

}

class Message extends Handler<ForumMessage> {

	var path : String;
	var thread : Thread;

	public function new(path,t) {
		super();
		this.path = path;
		thread = t;
	}

	override function findObject( id:Int, m:Bool ) : ForumMessage {
		return ForumMessage.manager.get(id, m);
	}

	override function initialize() {
		moderator("delete", null, object(doDelete));
		moderator("edit", "forum_post.mtt", object(doEdit));
	}

	function doDelete( m:ForumMessage ) {
		m.delete();
		if( m.isThread() )
			throw Action.Goto(path+"/"+m.tid+"?page="+App.request.getInt("page",1));
		var t = m.parent;
		t.replyCount--;
		var last = db.ForumMessage.manager.lastReply(t);
		if( last == null ) {
			t.lastUid = null;
			t.lastLogin = t.user.name;
			t.mdate = t.date;
		} else {
			t.lastUid = last.uid;
			t.lastLogin = last.user.name;
			t.mdate = last.date;
		}
		t.update();
		throw Action.Goto(path+"/thread/"+t.id+"?page="+App.request.getInt("page",1));
	}

	function doEdit( m : ForumMessage ) {
		thread.processPost(m.theme,m.parent,m);
	}

}

class Forum extends Handler<Void> {

	var theme : ForumTheme;
	var thread : Thread;

	public function new( theme : ForumTheme, createEditor ) {
		super();
		this.theme = theme;
		thread = new Thread("/"+theme.path,createEditor);
	}

	override function initialize() {
		free("thread", handler(thread));
		free("message", handler(new Message("/"+theme.path,thread)));
		free("default", "forum_main.mtt", doShowTheme );
		logged("post", "forum_post.mtt", doPost);
		logged("search", "forum_main.mtt", doSearch);
	}

	public function doShowTheme() {
		var browser = new ResultsBrowser(
			db.ForumMessage.manager.countThreads(theme),
			Config.FORUM_THREADS_PER_PAGE,
			theme.browse.bind(App.user,false)
		);
		var threads = ForumTheme.groupByDay(browser.current());
		if( browser.page == 1 ) {
			var sticks = theme.browse(App.user,true,0,100);
			if( !sticks.isEmpty() )
				threads.push({ date : null, threads : sticks });
		}
		App.context.theme = theme;
		App.context.threads = threads;
		App.context.browser = browser;
	}

	function doPost() {
		thread.processPost(theme,null);
	}

	function doSearch() {
		var threads = db.ForumMessage.search(App.request.get("search"),App.user);
		App.context.threads = db.ForumTheme.groupByDay(threads);
		App.context.browser = { page : 1 };
	}

}
