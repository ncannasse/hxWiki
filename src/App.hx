import mtwin.web.Handler;

class App {

	public static var database : neko.db.Connection;
	public static var session : db.Session;
	public static var user : db.User;
	public static var request : mtwin.web.Request;
	public static var context : Dynamic;
	public static var langFlags : db.Lang -> Bool;
	public static var langSelected : db.Lang;

	static var template : mtwin.templo.Loader;

	static function sendNoCacheHeaders() {
		try {
			neko.Web.setHeader("Cache-Control", "no-store, no-cache, must-revalidate");
			neko.Web.setHeader("Pragma", "no-cache");
			neko.Web.setHeader("Expires", "-1");
			neko.Web.setHeader("P3P", "CP=\"ALL DSP COR NID CURa OUR STP PUR\"");
			neko.Web.setHeader("Content-Type", "text/html; Charset=UTF-8");
			neko.Web.setHeader("Expires", "Mon, 26 Jul 1997 05:00:00 GMT");
		} catch( e : Dynamic ) {
		}
	}

	public static function prepareTemplate( t : String ) {
		mtwin.templo.Loader.OPTIMIZED = Config.DEBUG == false;
		mtwin.templo.Loader.BASE_DIR = Config.TPL;
		mtwin.templo.Loader.TMP_DIR = Config.TPL + "../tmp/";
		sendNoCacheHeaders();
		template = new mtwin.templo.Loader(t);
	}

	static function executeTemplate() {
		var result = template.execute(context);
		sendNoCacheHeaders();
		neko.Lib.print(result);
	}

	static function redirect( url:String ) {
		template = null;
		sendNoCacheHeaders();
		neko.Web.redirect(url);
	}

	static function initLang() {
		var ldata = neko.Web.getClientHeader("Accept-Language");
		var ldata = if( ldata == null ) [] else ldata.split(",");
		var r = ~/^ ?([a-z]+)(-[a-zA-Z]+)?(;.*)?$/;
		ldata.push(Config.LANG);
		for( l in ldata ) {
			if( !r.match(l) ) continue;
			var l = db.Lang.manager.byCode(r.matched(1));
			if( l != null ) return l.id;
		}
		return null;
	}

	static function mainLoop() {
		// init
		request = new mtwin.web.Request();
		context = {};
		var sid = request.get("sid");
		if( sid == null ) sid = neko.Web.getCookies().get("sid");
		session = db.Session.initialize(sid);
		if( session.data == null ) {
			try {
				session.lang = initLang();
				session.insert();
				neko.Web.setHeader("Set-Cookie", "sid="+session.sid+"; path=/");
			} catch( e : Dynamic ) {
				new handler.Main().setupDatabase();
				database.commit();
				throw "Database initialized";
			}
		}
		user = if( session.uid != null ) db.User.manager.get(session.uid) else null;
		langFlags = function(l) return true;
		langSelected = null;

		// execute
		var h = new handler.Main();
		var level = if( request.getPathInfoPart(0) == "index.n" ) 1 else 0;
		try {
			h.dispatch(request,level);
		} catch( e : ActionError ) {
			switch( e ) {
			case ActionReservedToLoggedUsers:
				session.setError(Text.get.err_must_login);
			case UnknownAction(a):
				session.setError(Text.get.err_unknown_action,{ action : StringTools.htmlEscape(neko.Web.getURI()) });
			default:
			}
			redirect("/");
		} catch( e : handler.Action ) {
			switch( e ) {
			case Goto(url):
				redirect(url);
			case Error(url,err,params):
				database.rollback();
				neko.db.Manager.cleanup();
				session = db.Session.initialize(sid);
				if( user != null ) user.sync();
				session.setError(err,params);
				session.update();
				redirect(url);
			case Done(url,conf,params):
				session.setMessage(conf,params);
				redirect(url);
			}
		}
		if( user != null )
			user.update();
		if( template != null )
			initContext();
		session.update();
		if( template != null )
			executeTemplate();
	}

	static function initDatabase( params : String ) {
		var m = ~/^mysql:\/\/(.*):(.*)@(.*):(.*)\/(.*)$/;
		if( !m.match(params) )
			throw "Invalid format "+params;
		return neko.db.Mysql.connect({
			user : m.matched(1),
			pass : m.matched(2),
			host : m.matched(3),
			port : Std.parseInt(m.matched(4)),
			database : m.matched(5),
			socket : null
		});
	}

	static function initContext() {
		context.user = user;
		context.session = session;
		context.request = request;
		context.config = {
			title : Config.get("title"),
			style : Config.get("style","default"),
		};
		if( database == null ) {
			context.links = function(_) return [];
			context.langs = [];
		} else {
			context.links = db.Link.manager.list;
			context.langs = db.Lang.manager.all(false);
		}
		context.uri = (request == null) ? "/" : request.getURI();
		context.lang_classes = function(l) {
			var f = if( langFlags == null ) true else langFlags(l);
			return (f ? "on" : "off") + ((l == langSelected) ? " current" : "");
		};
		if( session != null && session.notification != null ) {
			context.notification = session.notification;
			session.notification = null;
		}
		context.beginComment = "<!--";
		context.endIf = "<![endif]-->";
	}

	static function errorHandler( e : Dynamic ) {
		try {
			prepareTemplate("error.mtt");
			context = {};
			initContext();
			context.error = Std.string(e);
			context.stack = haxe.Stack.toString(haxe.Stack.exceptionStack());
			executeTemplate();
		} catch( e : Dynamic ) {
			neko.Lib.rethrow(e);
		}
	}

	static function cleanup() {
		if( database != null ) {
			database.close();
			database = null;
		}
		template = null;
		session = null;
		user = null;
		request = null;
		context = null;
		langFlags = null;
		langSelected = null;
	}

	static function main() {
		if( !neko.Sys.setTimeLocale(Text.get.locale1) )
			neko.Sys.setTimeLocale(Text.get.locale2);
		try {
			database = initDatabase(Config.get("db"));
		} catch( e : Dynamic ) {
			errorHandler(e);
			cleanup();
			return;
		}
		neko.db.Transaction.main(database, mainLoop, errorHandler);
		database = null; // already closed
		cleanup();
	}

}
