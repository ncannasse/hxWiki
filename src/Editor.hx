#if js
import js.Dom.Textarea;
import js.Dom.Event;
import js.Dom.HtmlDom;
#end

typedef EditorButton = {
	id : Int,
	label : String,
	left : String,
	right : String,
	text : String,
}

class Editor {

	public static function normalize(name:String) {
		name = ~/[^a-z0-9.]+/g.replace(name.toLowerCase(), "_");
		while( StringTools.endsWith(name, "_") )
			name = name.substr(0, -1);
		return name;
	}

	static inline function isEmpty(s) {
		// empty string is for neko <= 1.7.0 compatibility
		return #if neko s == "" || s == null #else s == null #end;
	}

	public var content(default,null) : String;
	public var preview(default,null) : String;
	var config : {
		buttons : Array<EditorButton>,
		text : String,
		name : String,
		path : Array<String>,
		sid : String,
		lang : String,
		allowRaw : Bool,
		titles : Hash<{ exists : Bool, title : String }>,
		externLinkTarget : Null<String>,
	};
	var uniqueId : Int;
	var subcache : Hash<Array<{ title : String, url : String }>>;
	#if js
	var previewBlock : String;
	var uploadImage : Bool;
	var twait : haxe.Timer;
	var refresh : { latest : String, timestamp : Float, auto : Bool, changed : Bool };
	#end


	public function new(data) {
		#if js
		config = haxe.Unserializer.run(data);
		refresh = { latest : null, timestamp : 0., auto : true, changed : false };
		#else
		config = data;
		#end
		subcache = new Hash();
		content = config.name + "_content";
		preview = config.name + "_preview";
	}

	#if js

	public function getDocument() : Textarea {
		return cast js.Lib.document.getElementsByName(content)[0];
	}

	public function updatePreview() {
		var prev = js.Lib.document.getElementById(preview);
		var start = haxe.Timer.stamp();
		var data = getDocument().value;
		if( data == refresh.latest )
			return false;
		if( !refresh.auto && start - refresh.timestamp < .5 ) {
			refresh.timestamp = start;
			if( refresh.changed )
				return false;
			refresh.changed = true;
			if( twait == null ) {
				twait = new haxe.Timer(1000);
				twait.run = function() {
					twait.stop();
					twait = null;
					refresh.changed = false;
					updatePreview();
				};
			}
			return false;
		}
		refresh.changed = false;
		refresh.latest = data;
		prev.innerHTML = format(data);

		// in case we have a preview block to show/hide
		if( previewBlock != null )
			js.Lib.document.getElementById(previewBlock).style.display = StringTools.trim(data) == "" ? "none" : "";

		if( haxe.Timer.stamp() - start > 0.15 )
			refresh.auto = false;
		// execute generate JS scripts
		for( i in 1...uniqueId ) {
			var e = js.Lib.document.getElementById("js_"+i);
			if( e != null )
				js.Lib.eval(e.innerHTML);
		}
		refresh.timestamp = haxe.Timer.stamp();
		return false;
	}

	public function handleTab(e:Event) {
		if( e.keyCode != 9 || e.altKey || e.ctrlKey || e.shiftKey )
			return true;
		var sel = new js.Selection(getDocument());
		sel.insert("\t","","");
		return false;
	}


	public function initUpload(button,title,pattern,img) {
		var loaded = false;
		var but = js.Lib.document.getElementById(button);
		var target = button + "_swf";
		js.Lib.document.write('<div id="'+target+'"></div>');
		but.onmouseover = function(_) {
			if(loaded) return;
			loaded = true;
			var doc = js.Lib.document;
			var win = js.Lib.window;
			var swf = doc.getElementById(target);
			swf.style.position = "absolute";
			swf.style.left = "0px";
			swf.style.top = "0px";
			var p = getElementPosition(but);
			swf.style.width = p.width + "px";
			swf.style.height = p.height + "px";
			swf.style.zIndex = 10;
			var p2 = getElementPosition(swf);
			swf.style.top = (p.y - p2.y) + "px";
			swf.style.left = (p.x - p2.x) + "px";
			displayUpload(target,title,pattern,img);
		}
	}

	static function getElementPosition( o : HtmlDom ) {
		var ret = { x : 0, y : 0, width : o.offsetWidth, height : o.offsetHeight}
		var p = o;
		while(p != null) {
			if(p.offsetParent != null) {
				ret.x += p.offsetLeft - p.scrollLeft;
				ret.y += p.offsetTop - p.scrollTop;
			}
			else {
				ret.x += p.offsetLeft;
				ret.y += p.offsetTop;
			}
			p = p.offsetParent;
		}
		return ret;
	}


	function displayUpload( target, title, pattern, img ) {
		var params = {
			title : title,
			pattern : pattern,
			url : "/wiki/upload",
			bgcolor : 0x000000,
			fgcolor : 0xFFFFFF,
			color : 0x008000,
			object : config.name,
			sid : config.sid,
		};
		var swf = new js.SWFObject("/upload.swf","swf_upload",cast "100%",cast "100%","9","#FFFFFF");
		var params = Lambda.map(Reflect.fields(params),function(k) return k+"="+StringTools.urlEncode(Reflect.field(params,k)));
		swf.addParam("AllowScriptAccess","always");
		swf.addParam("wmode","transparent");
		swf.addParam("FlashVars",params.join("&"));
		swf.write(target);
		uploadImage = img;
		// init incoming connection
		var ctx = new haxe.remoting.Context();
		ctx.addObject("api",{ uploadResult : function(url) haxe.Timer.delay(callback(uploadResult,url),1), uploadError : uploadError });
		haxe.remoting.ExternalConnection.flashConnect(config.name,"upload",ctx);
	}

	public function spanAction( title ) {
		var span = js.Lib.window.prompt(title);
		if( span == null || !~/^([A-Za-z0-9_])+$/.match(span) )
			return false;
		var sel = new js.Selection(getDocument());
		var text = sel.get();
		if( text == "" ) text = config.text;
		sel.insert("["+span+"]",text,"[/"+span+"]");
		updatePreview();
		return false;
	}

	function uploadError( e : String ) {
		js.Lib.alert(e);
	}

	function uploadResult( url : String ) {
		var sel = new js.Selection(getDocument());
		var text = uploadImage ? "@" + url + "@" : "{{" + url + "}}";
		sel.insert(sel.get(),text,"");
		updatePreview();
	}

	#else

	public function extensions( l : Iterable<String> ) {
		return Lambda.map(l,function(e) return "*."+e).join(";");
	}

	public function initJS() {
		return '<script type="text/javascript">'+config.name+'=new Editor("'+haxe.Serializer.run(config)+'")</script>';
	}

	#end

	public function addButton( label, left, ?right, ?text ) {
		if( right == null ) right = left;
		config.buttons.push({ id : config.buttons.length, label : label, left : left, right : right, text : text });
	}

	public function buttonAction( b : EditorButton ) {
		#if js
		var sel = new js.Selection(getDocument());
		var text = sel.get();
		if( text == "" ) text = if( b.text == null ) config.text else b.text;
		sel.insert(b.left,text,b.right);
		updatePreview();
		return false;
		#else
		return 'return '+config.name+'.buttonAction('+config.name+'.config.buttons['+b.id+'])';
		#end
	}

	// ---------------- FORMAT ----------------

	public dynamic function getTitle( path : Array<String> ) {
		#if js
		var data = haxe.Http.requestUrl("/wiki/title?path="+path.join("/")+";lang="+config.lang);
		if( data == "" )
			return null;
		return StringTools.htmlEscape(data);
		#else
		return null;
		#end
	}

	function makePath( link : String ) {
		var parts = link.split("/");
		var path = Lambda.array(Lambda.map(parts,normalize));
		if( path[0] == "" ) { // absolute path
			path.shift();
			if( path.length == 0 ) path = config.path.copy();
		} else
			path = config.path.concat(path);
		return { path : path, title : parts[parts.length-1] };
	}

	function getInfos( link : String ) {
		var inf = link.split("|");
		var title = null;
		if( inf.length == 2 ) {
			link = inf[0];
			title = inf[1];
		}
		var parts = link.split("#");
		var anchor = null;
		if( parts.length > 1 ) {
			anchor = normalize(parts.pop());
			link = parts.join("#");
		}
		var p = makePath(link);
		var url = p.path.join("/");
		var inf = config.titles.get(url);
		if( inf == null ) {
			var t = getTitle(p.path);
			inf = (t == null) ? { title : p.title, exists : false } : { title : t, exists : true };
			config.titles.set(url,inf);
		}
		return {
			url : "/" + url + (anchor == null ? "" : "#"+anchor),
			title : if( title == null ) inf.title else title,
			exists : inf.exists,
		};
	}

	public dynamic function getSubLinks( path : Array<String> ) : Array<{ url : String, title : String }> {
		#if js
		return haxe.Unserializer.run( haxe.Http.requestUrl("/wiki/sublist?path="+path.join("/")+";lang="+config.lang) );
		#else
		return null;
		#end
	}

	function list( t : String ) : String {
		var r = ~/(^|<br\/>)([ \t]+)\* /;
		if( !r.match(t) )
			return t;
		var b = new StringBuf();
		var spaces = r.matched(2);
		var pos = r.matchedPos();
		b.addSub(t,0,pos.pos);
		t = t.substr(pos.pos + pos.len);
		b.add("<ul>");
		for( x in new EReg("<br/>"+spaces+"\\* ","g").split(t) )
			b.add("<li>"+list(x)+"</li>");
		b.add("</ul>");
		return b.toString();
	}

	function code( t : String, ?style : String ) : String {
		var cl = (style == null) ? '' : ' class="'+style+'"';
		if( t.charAt(0) == "\n" ) t = t.substr(1);
		if( t.charAt(t.length-1) == "\n" ) t = t.substr(0,t.length - 1);
		t = StringTools.replace(t,"\t","    ");
		t = StringTools.htmlEscape(t);
		switch( style ) {
		case "xml", "html":
			t = ~/(&lt;\/?)([a-zA-Z0-9:_]+)([^&]*?)(\/?&gt;)/.customReplace(t,function(r) {
				var tag = r.matched(2);
				var attr = ~/([a-zA-Z0-9:_]+)="([^"]*?)"/g.replace(r.matched(3),'<span class="att">$1</span><span class="kwd">=</span><span class="string">"$2"</span>');
				return '<span class="kwd">'+r.matched(1)+'</span><span class="tag">'+tag+'</span>'+attr+'<span class="kwd">'+r.matched(4)+'</span>';
			});
			t = ~/(&lt;!--(.*?)--&gt;)/g.replace(t,'<span class="comment">$1</span>');
		case "haxe":
			var tags = new Array();
			var untag = function(s,html) {
				return ~/##TAG([0-9]+)##/.customReplace(s,function(r) {
					var t = tags[Std.parseInt(r.matched(1))];
					return html ? t.html : t.old;
				});
			}
			var tag = function(c,s) {
				tags.push({ old : s, html : '<span class="'+c+'">'+untag(s,false)+'</span>' });
				return "##TAG"+(tags.length-1)+"##";
			};
			t = ~/\/\*((.|\n)*?)\*\//.customReplace(t,function(r) {
				return tag("comment",r.matched(0));
			});
			t = ~/"(\\"|[^"])*?"/.customReplace(t,function(r) {
				return tag("string",r.matched(0));
			});
			t = ~/'(\\'|[^'])*?'/.customReplace(t,function(r) {
				return tag("string",r.matched(0));
			});
			t = ~/\/\/[^\n]*/.customReplace(t,function(r) {
				return tag("comment",r.matched(0));
			});
			var kwds = [
				"function","class","var","if","else","while","do","for","break","continue","return",
				"extends","implements","import","switch","case","default","static","public","private",
				"try","catch","new","this","throw","extern","enum","in","interface","untyped","cast",
				"override","typedef","dynamic","package","callback","inline","using",
			];
			var types = [
				"Array","Bool","Class","Date","DateTools","Dynamic","Enum","Float","Hash","Int",
				"IntHash","IntIter","Iterable","Iterator","Lambda","List","Math","Null","Reflect",
				"Std","String","StringBuf","StringTools","Type","Void","Xml",
			];
			t = new EReg("\\b("+kwds.join("|")+")\\b","g").replace(t,'<span class="kwd">$1</span>');
			t = new EReg("\\b("+types.join("|")+")\\b","g").replace(t,'<span class="type">$1</span>');
			t = ~/\b([0-9.]+)\b/g.replace(t,'<span class="number">$1</span>');
			t = ~/([{}\[\]()])/g.replace(t,'<span class="op">$1</span>');
			t = untag(t, true);
		case "raw":
			if( config.allowRaw )
				return StringTools.htmlUnescape(t);
		default:
		}
		return '<pre'+cl+'>'+t+"</pre>";
	}

	static function makeSpans( t : String ) : String {
		return ~/\n*\[([A-Za-z0-9_ ]+)\]\n*([^<>]*?)\n*\[\/\1\]\n*/.customReplace(t,function(r) {
			return '<span class="'+r.matched(1)+'">'+makeSpans(r.matched(2))+'</span>';
		});
	}
	
	function makeTitle( titles : Hash<Bool>, code, str ) {
		var part = ~/[^a-z0-9]+/g.replace(str.toLowerCase(), "-");
		while( part.charCodeAt(0) == "-".code )
			part = part.substr(1);
		while( part.length > 0 && part.charCodeAt(part.length - 1) == "-".code )
			part = part.substr(0, part.length - 1);
		if( titles.exists(part) ) {
			var count = 2;
			while( titles.exists(part + "_" + count) )
				count++;
			part += "_" + count;
		}
		titles.set(part, true);
		return '<' + code + '><a href="#' + part + '" name="' + part + '">' + str + '</a></' + code + '>';
	}
	
	function paragraph( t : String ) : String {
		// unhtml
		t = StringTools.htmlEscape(t).split('"').join("&quot;");
		// span
		t = makeSpans(t);
		// newlines
		t = StringTools.replace(t,"\n","<br/>");
		// titles
		var titles = new Hash();
		titles.set("", true);
		t = ~/====== ?(.*?) ?======/g.customReplace(t,function(r) return makeTitle(titles,"h1",r.matched(1)));
		t = ~/===== ?(.*?) ?=====/g.customReplace(t,function(r) return makeTitle(titles,"h2",r.matched(1)));
		t = ~/==== ?(.*?) ?====/g.customReplace(t,function(r) return makeTitle(titles,"h3",r.matched(1)));
		// links
		var target = config.externLinkTarget == null ? "" : ' target="' + config.externLinkTarget + '"';
		t = ~/\[\[(https?:[^\]"]*?)\|(.*?)\]\]/g.replace(t,'<a href="$1" class="extern"'+target+'>$2</a>');
		t = ~/\[\[(https?:[^\]"]*?)\]\]/g.replace(t,'<a href="$1" class="extern"'+target+'>$1</a>');
		t = ~/\[\[([^\]]*?)\]\]/.customReplace(t,function(r) {
			var link = r.matched(1);
			if( link.substr(link.length-2,2) == "/*" ) {
				var path = makePath(link.substr(0,link.length-2)).path;
				var list = subcache.get(path.join("/"));
				if( list == null ) {
					list = getSubLinks(path);
					subcache.set(path.join("/"),list);
				}
				var str = '<ul class="subs">';
				for( i in list )
					str += '<li><a href="'+i.url+'" class="intern">'+i.title+'</a>';
				str += "</ul>";
				return str;
			}
			var i = getInfos(r.matched(1));
			var cl = i.exists ? "intern" : "broken";
			return '<a href="'+i.url+'" class="'+cl+'">'+i.title+'</a>';
		});
		// images / files
		t = ~/@([ A-Za-z0-9._-]+)@/g.replace(t,'<img src="/file/$1" alt="$1" class="intern"/>');
		t = ~/\{\{([ A-Za-z0-9._-]+)(|.*?)\}\}/.customReplace(t,function(r) {
			var link = r.matched(1);
			var ext = link.split(".").pop();
			var title = r.matched(2);
			if( title == null || title == "" ) title = link else title = title.substr(1);
			return '<a href="/file/'+link+'" class="file file_'+ext+'">'+title+'</a>';
		});
		t = ~/@([ A-Za-z0-9._-]+\.swf):([0-9]+)x([0-9]+)(:[^@]+)?@/.customReplace(t,function(r) {
			var id = uniqueId++;
			var str = '<div class="swf" id="swf_'+id+'" style="width : '+r.matched(2)+'px">['+r.matched(1)+']</div>';
			str += '<script type="text/javascript" id="js_'+id+'">';
			str += "var o = new js.SWFObject('/file/"+r.matched(1)+"','swfobj_"+id+"',"+r.matched(2)+","+r.matched(3)+",'9','#FFFFFF');";
			var params = r.matched(4);
			if( !isEmpty(params) ) {
				params = Lambda.map(params.substr(1).split("&amp;"),function(p) return Lambda.map(p.split("="),StringTools.urlEncode).join("=")).join("&");
				str += "o.addParam('FlashVars','"+params+"');";
			}
			str += "o.addParam('wmode','direct');";
			str += "o.write('swf_"+id+"');";
			str += "</script>";
			return str;
		});
		// lists
		t = list(t);
		// bold
		t = ~/\*\*([^<>]*?)\*\*/g.replace(t,"<b>$1</b>");
		// italic
		t = ~/\/\/([^<>]*?)\/\//g.replace(t,"<em>$1</em>");
		// code
		t = ~/''([^<>]*?)''/g.replace(t,"<code>$1</code>");
		return t;
	}

	public function format( t : String ) : String {
		uniqueId = 1;
		t = ~/\r\n?/g.replace(t,"\n");
		var b = new StringBuf();
		var codes = new Array();
		t = ~/<code( [a-zA-Z0-9]+)?>([^\0]*?)<\/code>/.customReplace(t,function(r) {
			var style = r.matched(1);
			var code = code(r.matched(2),isEmpty(style)?null:style.substr(1));
			codes.push(code);
			return "##CODE"+(codes.length-1)+"##";
		});
		var div_begin = ~/^\[(\/?[A-Za-z0-9_ ]+)\]/;
		var div_end = ~/\[(\/?[A-Za-z0-9_ ]+)\]$/;
		var pstack = new Array();
		for( t in ~/\n[ \t]*\n/g.split(t) ) {
			var p = paragraph(t);
			var after = "\n";
			while( div_begin.match(p) ) {
				var cl = div_begin.matched(1);
				if( cl.charAt(0) == "/" ) {
					cl = cl.substr(1);
					while( pstack.length > 0 ) {
						b.add("</div>");
						if( pstack.pop() == cl )
							break;
					}
				} else {
					pstack.push(cl);
					b.add('<div class="'+cl+'">');
				}
				p = div_begin.matchedRight();
			}
			while( div_end.match(p) ) {
				var cl = div_end.matched(1);
				if( cl.charAt(0) == "/" ) {
					cl = cl.substr(1);
					while( pstack.length > 0 ) {
						after += "</div>";
						if( pstack.pop() == cl )
							break;
					}
				} else {
					pstack.push(cl);
					after += '<div class="'+cl+'">';
				}
				p = div_end.matchedLeft();
			}
			switch( p.substr(0,3) ) {
			case "","<h1","<h2","<h3","<ul","<pr","##C","<sp":
				b.add(p);
			default:
				b.add("<p>");
				b.add(p);
				b.add("</p>");
			}
			b.add(after);
		}
		for( d in pstack )
			b.add("</div>");
		t = b.toString();
		// custom scripts
		var r = ~/(<ul>)?(<li>)?\[\$([a-z]+):([a-zA-Z0-9_]+)\]([^\0]*?)\[\/\$\3:\4\](<\/li>)?(<\/ul>)?/;
		var hasClic = false;
		while( r.match(t) ) {
			var tag = r.matched(4);
			var content = r.matched(5);
			// this is an ugly hack to extract script in first and last position of a list
			var pre = { ul : !isEmpty(r.matched(1)), li : !isEmpty(r.matched(2)) };
			var post = { ul : !isEmpty(r.matched(7)), li : !isEmpty(r.matched(6)) };
			var before = (pre.ul?"<ul>":"") + (pre.li?"<li>":"");
			var after = (post.li?"</li>":"") + (post.ul?"</ul>":"");
			if( pre.ul && pre.li && post.ul && post.li && StringTools.startsWith(content,"</li>") && StringTools.endsWith(content,"<li>") ) {
				before = "";
				after = "";
				content = "<ul>"+content.substr(5,content.length - 9)+"</ul>";
			}
			// end-of-hack
			var content = switch( r.matched(3) ) {
			case "clic":
				hasClic = true;
				'<a href="#" onclick="return JsTools.toggleCookie(\''+tag+'\')">'+content+'</a>';
			case "id":
				'<div id="'+tag+'" style="display : none">'+content+'</div>';
			default:
				"Unknown script "+r.matched(3);
			}
			t = r.matchedLeft() + before + content + after + r.matchedRight();
		}
		// replace unformated code parts
		for( i in 0...codes.length )
			t = StringTools.replace(t,"##CODE"+i+"##",codes[i]);
		// cleanup
		t = StringTools.replace(t, "<p><br/>", "<p>");
		t = StringTools.replace(t, "<br/></p>", "</p>");
		t = StringTools.replace(t, "<p></p>", "");
		t = StringTools.replace(t, "><p>", ">\n<p>");
		if( hasClic )
			t += '<script type="text/javascript">JsTools.toggleInit()</script>';
		return t;
	}


}