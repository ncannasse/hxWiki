package handler;

class RemotingApi {

	var main : handler.Main;

	public function new(m) {
		main = m;
	}

	static function getLang( lang ) {
		var l = db.Lang.manager.byCode(lang);
		if( l == null )
			throw "Unknown lang "+lang;
		return l;
	}

	public function login( user : String, pass : String ) : { sid : String, uid : Int } {
		var u = db.User.manager.search({ name : user, pass : Main.encodePass(pass) },false).first();
		if( u == null )
			throw "Invalid user name or password";
		App.session.setUser(u);
		return { sid : App.session.sid, uid : u.id };
	}

	public function getLangs( path : Array<String> ) : Array<String> {
		var langs = new Array();
		var path = Lambda.list(path);
		for( l in db.Lang.manager.all(false) ) {
			var vid = db.Entry.manager.resolve(path,l);
			if( vid != null )
				langs.push(l.code);
		}
		return langs;
	}

	public function read( path : Array<String>, lang : String ) : Null<{ title : String, content : String }> {
		var e = main.getEntry(path,getLang(lang));
		if( !e.hasContent() )
			return null;
		if( !main.getRights(e).canView )
			throw "You can't read this content";
		return { title : e.get_title(), content : e.version.content };
	}

	public function write( path : Array<String>, lang : String, title : String, content : String ) : Bool {
		var e = main.getEntry(path,getLang(lang));
		var r = main.getRights(e);
		if( !e.hasContent() && !r.canCreate )
			throw "You can't create this content";
		if( !r.canEdit )
			throw "You can't edit this content";
		return main.processEdit(e,main.createEditor(e,false),title,content);
	}

}