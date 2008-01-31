package handler;
import db.Version.VersionChange;

class Main extends Handler<Void> {

	public function dispatch( request : mtwin.web.Request, level ) {
		var part = request.getPathInfoPart(level++);
		switch( part ) {
		case "wiki":
			execute(request,level);
			return;
		case "db":
			mt.db.Admin.handler();
			return;
		case "":
			part = "index";
		default:
		}
		var path = new List();
		while( part != "" ) {
			path.add(normalize(part));
			part = request.getPathInfoPart(level++);
		}
		var entry = db.Entry.get(path);
		App.prepareTemplate("entry.mtt");
		this.request = request;
		doView(entry);
	}

	override function initialize() {
		free("login",doLogin);
		logged("logout",doLogout);
		logged("edit","entry.mtt",doEdit);
		logged("delete",doDelete);
		logged("rename","entry.mtt",doRename);
		free("map","map.mtt",doMap);
	}

	function doLogin() {
		var user = request.get("user");
		var pass = request.get("pass");
		var u = db.User.manager.search({ name : user, pass : pass },false).first();
		if( u == null )
			throw Action.Error("/",Text.get.err_unknown_user_pass);
		App.session.setUser(u);
		throw Action.Goto("/");
	}

	function doLogout() {
		App.session.delete();
		throw Action.Goto("/");
	}

	function normalize(name:String) {
		return ~/[^a-z0-9.]+/g.replace(name.toLowerCase(),"_");
	}

	function getEntry( ?path ) {
		if( path == null ) path = request.get("path").split("/");
		return db.Entry.get(Lambda.map(path,normalize));
	}

	function doView( entry : db.Entry ) {
		App.context.version = entry.version;
		if( request.exists("version") ) {
			var version = db.Version.manager.search({ id : request.getInt("version"), eid : entry.id },false).first();
			if( version != null && version != entry.version ) {
				App.context.version = version;
				App.context.oldversion = true;
			}
		}
		if( request.exists("history") )
			App.context.history = db.Version.manager.search({ eid : entry.id },false);
		if( entry.version == null ) entry.cleanup();
		App.context.entry = entry;
	}

	function createEditor() {
		var config = {
			empty_text : Text.get.empty_text,
			name : "editor",
		};
		var e = new Editor(config);
		e.addButton(Text.get.bold,"**");
		e.addButton(Text.get.italic,"//");
		e.addButton(Text.get.code,"''");
		e.addButton("H1","====== "," ======");
		e.addButton("H2","===== "," =====");
		e.addButton("H3","==== "," ====");
		e.addButton(Text.get.link,"[[","]]");
		e.addButton(Text.get.external_link,"[[","]]",Text.get.empty_link_text);
		return e;
	}

	function doEdit() {
		var editor = createEditor();
		var entry = getEntry();
		App.context.edit = true;
		App.context.entry = entry;
		App.context.editor = editor;
		if( !request.exists("submit") )
			return;
		// edit
		var content = request.get(editor.content);
		var entry = if( entry.id == null ) { entry.insert(); entry; } else db.Entry.manager.get(entry.id);
		var oldTitle = entry.title;
		entry.title = StringTools.trim(request.get("title",entry.name));
		if( entry.title == entry.name || entry.title == "" ) entry.title = null;
		if( entry.title != oldTitle ) {
			entry.update();
			var v = new db.Version(entry,App.user);
			v.setChange(VTitle,oldTitle,entry.title);
			v.insert();
		}
		var v = null;
		if( StringTools.trim(content).length == 0 )
			entry.markDeleted(App.user);
		else if( entry.version == null || entry.version.content != content ) {
			v = new db.Version(entry,App.user);
			v.content = content;
			v.insert();
			entry.version = v;
		} else if( entry.version != null )
			v = db.Version.manager.get(entry.version.id);
		if( v != null ) {
			v.htmlContent = editor.format(content);
			v.update();
		}
		entry.update();
		throw Action.Done(entry.getURL(),Text.get.entry_modified);
	}

	function doDelete() {
		var entry = getEntry();
		if( entry.id != null && entry.version != null ) {
			var entry = db.Entry.manager.get(entry.id);
			entry.markDeleted(App.user);
			entry.update();
		}
		throw Action.Done(entry.getURL(),Text.get.entry_deleted);
	}

	function doRename() {
		var entry = getEntry();
		App.context.entry = entry;
		App.context.rename = true;
		var path = request.get("name","").split("/");
		if( !request.exists("submit") || path.length == 0 || entry.id == null )
			return;
		var name = normalize(path.pop());
		var parent = getEntry(path);
		if( parent != null && parent.id == null ) parent.insert();
		// check that target does not already exists
		if( db.Entry.manager.count({ pid : parent == null ? null : parent.id, name : name }) > 0 )
			throw Action.Error("/wiki/rename?path="+entry.get_path(),Text.get.err_cant_rename_entry);
		// check that we don't create a recursive entry
		var x = parent;
		while( x != null ) {
			if( x == entry )
				throw Action.Error("/wiki/rename?path="+entry.get_path(),Text.get.err_cant_rename_rec);
			x = x.parent;
		}
		if( name != entry.name || parent != entry.parent ) {
			var old = entry.get_path();
			var oldparent = entry.parent;
			var entry = db.Entry.manager.get(entry.id);
			entry.name = name;
			entry.parent = parent;
			entry.update();
			if( oldparent != null && parent != oldparent ) oldparent.cleanup();
			var v = new db.Version(entry,App.user);
			v.setChange(VName,old,entry.get_path());
			v.insert();
		}
		throw Action.Done(entry.getURL(),Text.get.entry_renamed);
	}

	function doMap() {
		App.context.roots = db.Entry.manager.getChilds(null);
	}

}