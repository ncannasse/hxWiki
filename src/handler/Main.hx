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
		case "file":
			doFile(request.getPathInfoPart(level++));
			return;
		case "":
			part = "index";
		default:
		}
		var path = new List();
		while( part != "" ) {
			path.add(Editor.normalize(part));
			part = request.getPathInfoPart(level++);
		}
		App.prepareTemplate("entry.mtt");
		this.request = request;
		doView(path);
	}

	override function initialize() {
		free("login",doLogin);
		free("map","map.mtt",doMap);
		free("setlang",doSetLang);
		free("history","entry.mtt",doHistory);
		logged("logout",doLogout);
		logged("edit","entry.mtt",doEdit);
		logged("delete",doDelete);
		logged("rename","entry.mtt",doRename);
		logged("title",doTitle);
		logged("upload",doUpload);
		logged("sublist",doSubList);
		logged("restore",doRestore);
	}

	function doLogin() {
		var user = request.get("user");
		var pass = request.get("pass");
		var url = request.get("url","/");
		var u = db.User.manager.search({ name : user, pass : pass },false).first();
		if( u == null )
			throw Action.Error(url,Text.get.err_unknown_user_pass);
		App.session.setUser(u);
		throw Action.Goto(url);
	}

	function doLogout() {
		App.session.delete();
		throw Action.Goto(request.get("url","/"));
	}

	function getEntry( ?path, lang ) {
		if( path == null ) path = request.get("path","").split("/");
		return db.Entry.get(Lambda.map(path,Editor.normalize),lang);
	}

	function getLang() {
		var l = db.Lang.manager.byCode(request.get("lang",""));
		if( l == null ) l = db.Lang.manager.get(App.session.lang,false);
		return l;
	}

	function updateContent( entry : db.Entry ) {
		var editor = createEditor(entry);
		var v = db.Version.manager.get(entry.vid);
		db.Dependency.manager.cleanup(entry);
		v.htmlContent = editor.format(v.content);
		v.update();
	}

	function contentChanged( entry : db.Entry ) {
		for( d in db.Dependency.manager.search({ eid : entry.id },false) ) {
			var e2 = d.target;
			if( e2 == null ) e2 = getEntry(d.path.split("/"),entry.lang);
			if( d.subs != null ) {
				var s = db.Dependency.manager.subSignature(e2);
				if( s != d.subs )
					return true;
			} else if( (e2.hasContent() ? e2.get_title() : null) != d.title )
				return true;
		}
		return false;
	}

	function doView( path : List<String> ) {
		// list available contents
		var langs = new Hash();
		var def = null;
		var cur = null;
		for( l in db.Lang.manager.all(false) ) {
			var vid = db.Entry.manager.resolve(path,l);
			if( vid != null ) {
				langs.set(l.code,vid);
				if( l.id == App.session.lang )
					cur = l;
			}
			if( l.code == Config.LANG )
				def = l;
		}
		// force lang
		if( cur == null && request.exists("lang") )
			cur = db.Lang.manager.byCode(request.get("lang"));

		// force version
		var version = null;
		if( request.exists("version") ) {
			version = db.Version.manager.get(request.getInt("version"),false);
			if( version != null ) {
				if( version.entry.get_path() != path.join("/") )
					version = null;
				else {
					cur = version.entry.lang;
					App.context.oldversion = version.entry.vid != version.id;
				}
			}
		}

		var entry = if( cur != null ) db.Entry.get(path,cur) else db.Entry.get(path,def);
		if( version == null )
			version = entry.version;
		var lang = entry.lang;
		App.langFlags = function(l) return langs.exists(l.code);
		App.langSelected = lang;
		if( !entry.hasContent() )
			entry.cleanup();
		else if( contentChanged(entry) )
			updateContent(entry);
		App.context.version = version;
		App.context.entry = entry;
	}

	function doHistory() {
		var entry = getEntry(getLang());
		App.context.entry = entry;
		App.context.history = db.Version.manager.history(entry);
	}

	function createEditor( entry : db.Entry ) {
		var lang = entry.lang;
		var config = {
			buttons : new Array(),
			text : Text.get.empty_text,
			name : "wikeditor",
			path : entry.get_path().split("/"),
			sid : App.session.sid,
			lang : lang.code,
			titles : new Hash(),
		};
		// fill titles cache
		for( d in db.Dependency.manager.search({ eid : entry.id },false) ) {
			var e = d.entry;
			if( e == null ) e = getEntry(d.path.split("/"),lang);
			config.titles.set(d.path,{ title : e.get_title(), exists : e.hasContent() });
		}

		var e = new Editor(config);
		e.addButton(Text.get.bold,"**");
		e.addButton(Text.get.italic,"//");
		e.addButton(Text.get.code,"''");
		e.addButton("H1","====== "," ======");
		e.addButton("H2","===== "," =====");
		e.addButton("H3","==== "," ====");
		e.addButton(Text.get.link,"[[","]]",Text.get.empty_link_text);
		e.addButton(Text.get.external_link,"[[","]]",Text.get.empty_external_link_text);
		var me = this;
		e.getTitle = function(path:Array<String>) {
			var entry2 = me.getEntry(path,lang);
			var dep = new db.Dependency();
			dep.entry = entry;
			dep.target = entry2;
			dep.path = path.join("/");
			dep.title = entry2.hasContent() ? entry2.get_title() : null;
			dep.insert();
			return dep.title;
		}
		e.getSubLinks = function(path) {
			var entry2 = me.getEntry(path,lang);
			var dep = new db.Dependency();
			dep.entry = entry;
			dep.target = entry2;
			dep.path = path.join("/");
			dep.subs = db.Dependency.manager.subSignature(entry2);
			dep.insert();
			return me.getSubLinks(entry2);
		}
		return e;
	}

	function doEdit() {
		var entry = getEntry(getLang());
		var editor = createEditor(entry);
		App.context.edit = true;
		App.context.entry = entry;
		App.context.editor = editor;
		App.langSelected = entry.lang;
		App.langFlags = function(l) return l == entry.lang;
		App.context.extensions = "*."+Text.get.allowed_extensions.split("|").join(";*.");
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
		} else if( entry.vid != null )
			v = db.Version.manager.get(entry.vid);
		if( v != null ) {
			db.Dependency.manager.cleanup(entry);
			v.htmlContent = editor.format(content);
			v.update();
		}
		entry.update();
		throw Action.Done(entry.getURL(),Text.get.entry_modified);
	}

	function doDelete() {
		// delete for all langs
		var entry = null;
		for( l in db.Lang.manager.all(false) ) {
			entry = getEntry(l);
			if( entry.id != null && entry.version != null ) {
				var entry = db.Entry.manager.get(entry.id);
				entry.markDeleted(App.user);
				entry.update();
				db.Dependency.manager.cleanup(entry);
			}
		}
		throw Action.Done(entry.getURL(),Text.get.entry_deleted);
	}

	function doRename() {
		var entry = getEntry(getLang());
		App.context.entry = entry;
		App.context.rename = true;
		var path = request.get("name","").split("/");
		if( !request.exists("submit") || path.length == 0 || entry.id == null )
			return;
		var name = Editor.normalize(path.pop());
		var parent = getEntry(path,entry.lang);
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
			db.Dependency.manager.renamed(entry);
			if( oldparent != null && parent != oldparent ) oldparent.cleanup();
			var v = new db.Version(entry,App.user);
			v.setChange(VName,old,entry.get_path());
			v.insert();
		}
		throw Action.Done(entry.getURL(),Text.get.entry_renamed);
	}

	function doMap() {
		var lang = getLang();
		App.langSelected = lang;
		App.context.roots = db.Entry.manager.getRoots(lang);
	}

	function doTitle() {
		var e = getEntry(getLang());
		if( e.hasContent() )
			neko.Lib.print(e.get_title());
	}

	function doSubList() {
		var a = getSubLinks(getEntry(getLang()));
		neko.Lib.print(haxe.Serializer.run(a));
	}

	function getSubLinks( e : db.Entry ) {
		if( e.id == null )
			return [];
		return Lambda.array(db.Entry.manager.search({ pid : e.id },false).map(function(e) return { url : e.getURL(), title : e.get_title() }));
	}

	function doFile( fname : String ) {
		var f = db.File.manager.search({ name : fname },false).first();
		if( f == null ) {
			neko.Web.setReturnCode(404);
			neko.Lib.print("404 - File not found '"+fname+"'");
			return;
		}
		var ch;
		try {
			ch = neko.io.File.write(neko.Web.getCwd()+"/file/"+f.name,true);
		} catch( e : Dynamic ) {
			neko.Sys.sleep(0.5); // wait for another process to write ?
			neko.Web.redirect(neko.Web.getURI()+"?retry="+Std.random(1000));
			return;
		}
		ch.write(f.content);
		ch.close();
		neko.Web.redirect(neko.Web.getURI()+"?reload=1");
	}

	static function readBits( s : String, pos : Int, nbits : Int ) {
		var base = pos >> 3;
		var n = 8 - (pos - (base << 3)); // number of bits to keep
		nbits -= n;
		var k = s.charCodeAt(base) & ((1 << n) - 1);
		if( nbits < 0 ) {
			k >>= -nbits;
			nbits = 0;
			return k;
		}
		while( nbits > 0 ) {
			var c = s.charCodeAt(++base);
			if( nbits >= 8 ) {
				k = (k << 8) | c;
				nbits -= 8;
			} else {
				k = (k << nbits) | (c >> (8 - nbits));
				nbits = 0;
			}
		}
		return k;
	}

	static function getSWFHeader( content : String ) {
		var compressed = switch( content.substr(0,3) ) {
		case "CWS": true;
		case "FWS": false;
		default: throw "Invalid SWF";
		}
		var buf;
		if( compressed ) {
			// uncompress a small amount of data
			buf = neko.Lib.makeString(64);
			var bytes = new neko.zip.Uncompress(15);
			bytes.run(content,8,buf,8);
			bytes.close();
		} else
			buf = content;
		var base = 8 * 8;
		var nbits = readBits(buf,base,5);
		base += 5 + nbits;
		var width = readBits(buf,base,nbits);
		base += nbits * 2;
		var height = readBits(buf,base,nbits);
		return { version : content.charCodeAt(4), width : Math.round(width / 20), height : Math.round(height / 20) };
	}

	function doUpload() {
		try {
			var datas = neko.Web.getMultipart(Std.parseInt(Config.get("max_allowed_upload","0")));
			var filename = datas.get("Filename");
			if( filename == null )
				throw "No filename defined";
			if( !~/^[ A-Za-z0-9._-]+$/.match(filename) )
				throw "Invalid filename "+filename;
			var ext = filename.split(".")[1];
			if( !Lambda.exists(Text.get.allowed_extensions.split("|"),function(x) return ext == x) )
				throw "Unsupported file extension "+ext;
			var f = db.File.manager.search({ name : filename },false).first();
			var content = datas.get("file");
			if( f != null ) {
				if( !request.exists("rewrite") && content != f.content )
					throw "File "+filename+" already exists with different content";
				f = db.File.manager.get(f.id,true);
			} else {
				f = new db.File();
				f.name = filename;
				f.update = f.insert;
			}
			f.content = content;
			f.update();
			neko.db.Manager.cnx.commit();
			try neko.FileSystem.deleteFile(neko.Web.getCwd()+"/file/"+filename) catch( e : Dynamic ) {};
			if( ext == "swf" ) {
				var h = getSWFHeader(content);
				filename += ":"+h.width+"x"+h.height;
			}
			neko.Lib.print(haxe.Serializer.run(filename));
		} catch( e : Dynamic ) {
			var s = new haxe.Serializer();
			s.serializeException(Std.string(e));
			neko.Lib.print(s.toString());
		}
	}

	function doSetLang() {
		var lang = db.Lang.manager.search({ code : request.get("lang") },false).first();
		if( lang == null )
			throw Action.Error(request.get("url"),Text.get.err_no_such_lang);
		App.session.lang = lang.id;
		throw Action.Goto(request.get("url")+"?lang="+lang.code);
	}

	function doRestore() {
		var e = getEntry(getLang());
		var v = db.Version.manager.get(request.getInt("version"),false);
		if( v == null || v.entry != e || v.getChange() != VContent )
			throw Action.Error(e.getURL(),Text.get.err_cant_restore);
		var e = db.Entry.manager.get(e.id);
		e.version = v;
		e.update();
		var v = new db.Version(e,App.user);
		v.setChange(VRestore,Std.string(e.vid),null);
		v.insert();
		throw Action.Goto(e.getURL());
	}

}