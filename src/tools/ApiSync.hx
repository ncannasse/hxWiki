package tools;
import haxe.rtti.CType;

class Proxy extends haxe.remoting.Proxy<handler.RemotingApi> {
}

class ApiSync {

	static var FILES = [
		{ file : "flash8.xml", platform : "flash8" },
		{ file : "flash9.xml", platform : "flash" },
		{ file : "neko.xml", platform : "neko" },
		{ file : "js.xml", platform : "js" },
		{ file : "php.xml", platform : "php" },
		{ file : "cpp.xml", platform : "cpp" },
		{ file : "cs.xml", platform : "cs" },
		{ file : "java.xml", platform : "java" },
	];

	var api : Proxy;
	var current : StringBuf;
	var typeParams : Array<String>;
	var curPackage : String;
	var previousContent : String;
	var id : Int;

	function new(api) {
		this.api = api;
		id = 0;
	}

	function print(str) {
		current.add(str);
	}

	function keyword(str) {
		current.add("[kwd]"+str+"[/kwd] ");
	}

	function prefix( arr : Array<String>, path : String ) {
		var arr = arr.copy();
		for( i in 0...arr.length )
			arr[i] = path + "." + arr[i];
		return arr;
	}

	function formatPath( path : String ) {
		if( path.substr(0,7) == "flash8." )
			return "flash."+path.substr(7);
		var pack = path.split(".");
		if( pack.length > 1 && pack[pack.length-2].charAt(0) == "_" ) {
			pack.splice(-2,1);
			path = pack.join(".");
		}
		return path;
	}

	function makeRights(r) {
		return switch(r) {
		case RNormal: "default";
		case RNo: "null";
		case RMethod: "method";
		case RDynamic: "dynamic";
		case RInline: "inline";
		case RCall(m): m;
		}
	}

	function processPath( path : Path, ?params : List<CType> ) {
		print(makePath(path));
		if( params != null && !params.isEmpty() ) {
			print("<");
			for( t in params )
				processType(t);
			print(">");
		}
	}

	function display<T>( l : List<T>, f : T -> Void, sep : String ) {
		var first = true;
		for( x in l ) {
			if( first )
				first = false;
			else
				print(sep);
			f(x);
		}
	}

	function processType( t : CType ) {
		switch( t ) {
		case CUnknown:
			print("Unknown");
		case CEnum(path,params):
			processPath(path,params);
		case CClass(path,params):
			processPath(path,params);
		case CTypedef(path,params):
			processPath(path,params);
		case CFunction(args,ret):
			if( args.isEmpty() ) {
				processPath("Void");
				print(" -> ");
			}
			for( a in args ) {
				if( a.opt )
					print("?");
				if( a.name != null && a.name != "" )
					print(a.name+" : ");
				processTypeFun(a.t,true);
				print(" -> ");
			}
			processTypeFun(ret,false);
		case CAnonymous(fields):
			if( fields.isEmpty() ) {
				print("{}");
				return;
			}
			print("{ ");
			var me = this;
			display(fields,function(f) {
				me.print(f.name+" : ");
				me.processType(#if haxe_211 f.type #else f.t #end);
			},", ");
			print(" }");
		case CDynamic(t):
			if( t == null )
				processPath("Dynamic");
			else {
				var l = new List();
				l.add(t);
				processPath("Dynamic",l);
			}
		#if (haxe_211 || haxe3)
		case CAbstract(path,params):
			processPath(path,params);
		#end
		}
	}

	function processTypeFun( t : CType, isArg ) {
		var parent =  switch( t ) { case CFunction(_,_): true; case CEnum(n,_): isArg && n == "Void"; default : false; };
		if( parent )
			print("(");
		processType(t);
		if( parent )
			print(")");
	}


	function makeLink( path, ?title ) {
		return "[[/api/"+path.split(".").join("/")+ if( title == null ) "]]" else "|"+title+"]]";
	}

	function makePath( path ) {
		for( x in typeParams )
			if( x == path )
				return path.split(".").pop();
		return makeLink(path);
	}

	function processIndex( t : TypeTree, depth : String ) {
		switch( t ) {
		case TPackage(name,full,subs):
			var isPrivate = name.charAt(0) == "_";
			if( isPrivate || name == "Remoting" ) return;
			var uid = "pack"+(id++);
			print(depth+"[$clic:"+uid+"][pack]"+name+"[/pack][/$clic:"+uid+"] \n");
			depth = "  "+depth;
			print(depth+"[$id:"+uid+"]\n");
			for( x in subs )
				processIndex(x,depth);
			print(depth+"[/$id:"+uid+"]\n");
		default:
			var i = TypeApi.typeInfos(t);
			if( i.isPrivate || i.path == "@Main" || StringTools.endsWith(i.path,"__") )
				return;
			print(depth+makeLink(i.path)+"\n");
		}
	}

	function process( t, lang ) {
		try {
			processRun(t,lang);
		} catch( e : Dynamic ) {
			log("Error ("+Std.string(e)+"), retrying...");
			process(t,lang);
		}
	}

	function start() {
		current = new StringBuf();
		id = 0;
	}

	function processRun( t : TypeTree, lang : String ) {
		switch( t ) {
		case TPackage(name,full,subs):
			var path = full.split(".");
			if( full == "" ) path = [];
			path.unshift("api");

			if( !api.exists(path,lang) && lang != "en" ) {
				log("Skipping all "+full+" ["+lang+"]",true);
				return;
			}
			var prev = api.read(path,lang);
			previousContent = (prev == null) ? "" : prev.content;
			start();
			print("[api_index]\n\n");
			processDoc(null,"");
			print("\n\n");
			for( x in subs )
				processIndex(x,"  * ");
			current.add("\n[/api_index]");
			if( full != "flash.system" && api.write(path,lang,(name == "" ? "haXe API" : name),current.toString()) )
				log("Updating "+full+" ["+lang+"]");
			else
				log("Skipping "+full+" ["+lang+"]",true);
			// recurse
			var old = curPackage;
			curPackage = full;
			for( x in subs )
				process(x,lang);
			curPackage = old;
		default:
			var i = TypeApi.typeInfos(t);
			var path = i.path.split(".");
			var name = path[path.length-1];
			path.unshift("api");
			// get previous content
			var prev = api.read(path,lang);
			// only synchronize modified classes
			if( prev == null && lang != "en" ) {
				log("Skipping "+i.path+" ["+lang+"]",true);
				return;
			}
			previousContent = (prev == null) ? "" : prev.content;
			// set context
			typeParams = prefix(i.params,i.path);
			start();
			// build
			print("[api]\n\n");
			switch(t) {
			case TPackage(_,_,_):
				throw "assert";
			case TClassdecl(c):
				processClass(c);
			case TEnumdecl(e):
				processEnum(e);
			case TTypedecl(t):
				processTypedef(t);
			#if (haxe_211 || haxe3)
			case TAbstractdecl(a):
				processAbstract(a);
			#end
			}
			print("[/api]");
			// save
			if( api.write(path,lang,name,current.toString()) )
				log("Updating "+i.path+" ["+lang+"]");
			else
				log("Skipping "+i.path+" ["+lang+"]",true);
		}
	}

	function processInfos( t : TypeInfos ) {
		if( t.module != null )
			print('[mod]import '+t.module+'[/mod]\n');
		if( !t.platforms.isEmpty() ) {
			print('[pf]Available in ');
			display(t.platforms,print,", ");
			print('[/pf]\n');
		}
		processDoc(t.doc,"");
		print("\n");
	}

	function processClass( c : Classdef ) {
		// name
		print("[name]");
		if( c.isExtern )
			keyword("extern");
		if( c.isPrivate )
			keyword("private");
		if( c.isInterface )
			keyword("interface");
		else
			keyword("class");
		print(formatPath(c.path));
		if( c.params.length != 0 ) {
			print("<");
			print(c.params.join(", "));
			print(">");
		}
		print("[/name]\n");
		// inheritance
		if( c.superClass != null ) {
			print("[oop]extends ");
			processPath(c.superClass.path,c.superClass.params);
			print("[/oop]\n");
		}
		for( i in c.interfaces ) {
			print("[oop]implements ");
			processPath(i.path,i.params);
			print("[/oop]\n");
		}
		if( c.tdynamic != null ) {
			var d = new List();
			d.add(c.tdynamic);
			print("[oop]implements ");
			processPath("Dynamic",d);
			print("[/oop]\n");
		}
		// datas
		processInfos(c);
		// fields
		for( f in c.fields )
			processClassField(c.platforms,f,false);
		for( f in c.statics )
			processClassField(c.platforms,f,true);
	}

	function processClassField(platforms : Platforms,f : ClassField,stat) {
		if( !f.isPublic || f.isOverride )
			return;
		var oldParams = typeParams;
		if( f.params != null )
			typeParams = typeParams.concat(prefix(f.params,f.name));
		print('[field]');
		if( stat ) keyword("static");
		var isMethod = false;
		var isInline = (f.get == RInline && f.set == RNo);
		switch( f.type ) {
		case CFunction(args,ret):
			if( (f.get == RNormal && (f.set == RMethod || f.set == RDynamic)) || isInline ) {
				isMethod = true;
				if( f.set == RDynamic )
					keyword("dynamic");
				if( isInline )
					keyword("inline");
				keyword("function");
				print(f.name);
				if( f.params != null )
					print("<"+f.params.join(", ")+">");
				var space = args.isEmpty() ? "" : " ";
				print("("+space);
				var me = this;
				display(args,function(a) {
					if( a.opt )
						me.print("?");
					if( a.name != null && a.name != "" ) {
						me.print(a.name);
						me.print(" : ");
					}
					me.processType(a.t);
				},", ");
				print(space+") : ");
				processType(ret);
			}
		default:
		}
		if( !isMethod ) {
			if( isInline )
				keyword("inline");
			keyword("var");
			print(f.name);
			if( !isInline && (f.get != RNormal || f.set != RNormal) )
				print("("+makeRights(f.get)+","+makeRights(f.set)+")");
			print(" : ");
			processType(f.type);
		}
		if( f.platforms.length != platforms.length ) {
			print('[pf]Available in ');
			display(f.platforms,print,", ");
			print('[/pf]');
		}

		print("\n");
		var tag = stat ? " s_" + f.name : " _" + f.name;
		processDoc(f.doc,tag);
		print('[/field]\n\n');
		if( f.params != null )
			typeParams = oldParams;
	}


	function processEnum(e : Enumdef) {
		print("[name]");
		if( e.isExtern )
			keyword("extern");
		if( e.isPrivate )
			keyword("private");
		keyword("enum");
		print(formatPath(e.path));
		if( e.params.length != 0 ) {
			print("<");
			print(e.params.join(", "));
			print(">");
		}
		print('[/name]\n');
		processInfos(e);
		// constructors
		for( c in e.constructors ) {
			print('[construct]\n');
			print(c.name);
			if( c.args != null ) {
				print("(");
				var me = this;
				display(c.args,function(a) {
					if( a.opt )
						me.print("?");
					me.print(a.name);
					me.print(" : ");
					me.processType(a.t);
				},",");
				print(")");
			}
			print("\n");
			processDoc(c.doc," _"+c.name);
			print("[/construct]\n\n");
		}
	}

	#if (haxe_211 || haxe3)
	function processAbstract(a : Abstractdef) {
		print('[name]');
		if( a.isPrivate )
			keyword("private");
		keyword("abstract");
		print(formatPath(a.path));
		if( a.params.length != 0 ) {
			print("<");
			print(a.params.join(", "));
			print(">");
		}
		print('[/name]\n');
		processInfos(a);
	}
	#end
	
	function processTypedef(t : Typedef) {
		print('[name]');
		if( t.isPrivate )
			keyword("private");
		keyword("typedef");
		print(formatPath(t.path));
		if( t.params.length != 0 ) {
			print("<");
			print(t.params.join(", "));
			print(">");
		}
		print('[/name]\n');
		processInfos(t);
		if( t.platforms.length == 0 ) {
			processTypedefType(t.type,t.platforms,t.platforms);
			return;
		}
		var platforms = new List();
		for( p in t.platforms )
			platforms.add(p);
		for( p in t.types.keys() ) {
			var td = t.types.get(p);
			var support = new List();
			for( p2 in platforms )
				if( TypeApi.typeEq(td,t.types.get(p2)) ) {
					platforms.remove(p2);
					support.add(p2);
				}
			if( support.length == 0 )
				continue;
			processTypedefType(td,t.platforms,support);
		}
	}

	function processTypedefType(t,all:Platforms,platforms:Platforms) {
		switch( t ) {
		case CAnonymous(fields):
			print('[anon]\n\n');
			for( f in fields ) {
				processClassField(all,#if haxe_211 f #else {
					name : f.name,
					type : f.t,
					isPublic : true,
					isOverride : false,
					doc : null,
					get : RNormal,
					set : RNormal,
					params : null,
					platforms : platforms,
					#if haxe_211
					line : null,
					meta : [],
					#end
				} #end,false);
			}
			print('[/anon]\n');
		default:
			if( all.length != platforms.length ) {
				print('[pf]Defined in ');
				display(platforms,print,", ");
				print('[/pf]\n');
			}
			print('[tdef]= ');
			processType(t);
			print('[/tdef]\n');
		}
		print("\n");
	}

	function processDoc( doc : String, tag : String ) {
		print('[doc'+tag+']');
		var r = "\\[doc"+tag+"\\]([^\\0]*?)\\[/doc"+tag+"\\]";
		var rdoc = new EReg(r,"");
		if( rdoc.match(previousContent) && StringTools.trim(doc = rdoc.matched(1)) != ""  )
			print(doc);
		else if( doc == null || StringTools.trim(doc) == "" )
			print("\n");
		else {
			// unixify line endings
			doc = doc.split("\r\n").join("\n").split("\r").join("\n");
			// trim stars
			doc = ~/^([ \t]*)\*+/gm.replace(doc, "$1");
			doc = ~/\**[ \t]*$/gm.replace(doc, "");
			// remove single line returns
			doc = ~/\n[\t ]*([^\n])/g.replace(doc," $1");
			// change double lines into single ones
			doc = ~/\n[\t ]*\n/g.replace(doc,"\n");
			// code style
			doc = ~/[\[\]]/g.replace(doc,"''");
			// trim
			doc = StringTools.trim(doc);
			// print
			print("\n");
			print(doc);
			print("\n");
		}
		print('[/doc'+tag+']\n');
	}

	static function input( name, def ) {
		if( def != null )
			return def;
		neko.Lib.print(name+": ");
		return Sys.stdin().readLine();
	}

	static function log( msg, ?cr ) {
		while( msg.length < 70 )
			msg += " ";
		neko.Lib.print(msg + (cr ? "\r" : "\n"));
	}

	static function transformPackage( x : Xml ) {
		switch( x.nodeType ) {
		case Xml.Element:
			var p = x.get("path");
			if( p != null && p.substr(0,6) == "flash." )
				x.set("path","flash8." + p.substr(6));
			for( x in x.elements() )
				transformPackage(x);
		default:
		}
	}

	public static function main() {
		var args = neko.Sys.args();
		var host = input("Host",args[0]).split(":");
		var config = {
			host : host[0],
			port : if( host.length > 1 ) Std.parseInt(host[1]) else 80,
			user : input("User",args[1]),
			pass : input("Pass",args[2]),
		};
		var url = "http://"+config.host+":"+config.port+"/wiki/remoting";
		haxe.remoting.HttpConnection.TIMEOUT = 60;
		var cnx = haxe.remoting.HttpConnection.urlConnect(url);
		var api = new Proxy(cnx.api);
		if( config.user != null ) {
			var inf = api.login(config.user,config.pass);
			cnx = haxe.remoting.HttpConnection.urlConnect(url+"?sid="+inf.sid);
			api = new Proxy(cnx.api);
		}
		var s = new ApiSync(api);
		log("Reading files");
		var parser = new haxe.rtti.XmlParser();
		for( f in FILES ) {
			var data = neko.io.File.getContent(f.file);
			var x = Xml.parse(data).firstElement();
			if( f.platform == "flash8" )
				transformPackage(x);
			parser.process(x,f.platform);
		}
		parser.sort();
		log("Generating");
		for( l in api.getAllLangs() )
			s.process(TPackage("","",parser.root),l);
		log("Done");
	}

}