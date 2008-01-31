#if js
import js.Dom.Textarea;
import js.Dom.Event;
#end

typedef EditorButton = {
	id : Int,
	label : String,
	left : String,
	right : String,
	text : String,
}

class Editor {

	public var content(default,null) : String;
	public var preview(default,null) : String;
	var config : {
		buttons : Array<EditorButton>,
		text : String,
		name : String,
	};

	public function new(data) {
		#if js
		config = haxe.Unserializer.run(data);
		#else true
		config = {
			buttons : new Array(),
			text : data.empty_text,
			name : data.name,
		};
		#end
		content = config.name + "_content";
		preview = config.name + "_preview";
	}

	#if js

	public function getDocument() : Textarea {
		return cast js.Lib.document.getElementsByName(content)[0];
	}

	public function updatePreview() {
		var prev = js.Lib.document.getElementById(preview);
		prev.innerHTML = format(getDocument().value);
		return false;
	}

	public function handleTab(e:Event) {
		if( e.keyCode != 9 )
			return true;
		var sel = new js.Selection(getDocument());
		sel.insert("\t","","");
		return false;
	}

	#else true

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
		#else true
		return 'return '+config.name+'.buttonAction(editor.config.buttons['+b.id+'])';
		#end
	}

	// ---------------- FORMAT ----------------

	public function getInfos( link : String ) {
		return {
			url : "/"+link,
			title : link,
		};
	}

	function list( t : String ) : String {
		var me = this;
		return ~/(^|<br\/>)(( +)\* (.*?)(<br\/>|$))+/.customReplace(t,function(r) {
			var b = new StringBuf();
			var rspaces = ~/(^|<br\/>)( +)/;
			rspaces.match(t);
			var spaces = rspaces.matched(2);
			var pos = rspaces.matchedPos();
			t = t.substr(pos.len + pos.pos + 2);
			var b = new StringBuf();
			b.add("<ul>");
			for( x in new EReg("<br/>"+spaces+"\\* ","g").split(t) )
				b.add("<li>"+me.list(x)+"</li>");
			b.add("</ul>");
			return b.toString();
		});
	}

	function code( t : String, ?style : String ) : String {
		var cl = (style == null) ? '' : ' class="'+style+'"';
		if( t.charAt(0) == "\n" ) t = t.substr(1);
		if( t.charAt(t.length-1) == "\n" ) t = t.substr(0,t.length - 1);
		t = StringTools.replace(t,"\t","    ");
		t = StringTools.htmlEscape(t);
		switch( style ) {
		case "xml":
			var me = this;
			t = ~/(&lt;\/?)([a-zA-Z0-9:]+)([^&]*?)(\/?&gt;)/.customReplace(t,function(r) {
				var tag = r.matched(2);
				var attr = ~/([a-zA-Z0-9:]+)="(.*?)"/g.replace(r.matched(3),'<span class="att">$1</span><span class="kwd">=</span><span class="string">"$2"</span>');
				return '<span class="kwd">'+r.matched(1)+'</span><span class="tag">'+tag+'</span>'+attr+'<span class="kwd">'+r.matched(4)+'</span>';
			});
			t = ~/(&lt;!--(.*?)--&gt;)/g.replace(t,'<span class="comment">$1</span>');
		case "haxe":
			var tags = new Array();
			var tag = function(c,s) { tags.push('<span class="'+c+'">'+s+'</span>'); return "##TAG"+(tags.length-1)+"##"; };
			t = ~/"[^"]*?"/.customReplace(t,function(r) {
				return tag("string",r.matched(0));
			});
			t = ~/'[^']*?'/.customReplace(t,function(r) {
				return tag("string",r.matched(0));
			});
			t = ~/\/\/[^\n]*/.customReplace(t,function(r) {
				return tag("comment",r.matched(0));
			});
			t = ~/\/\*((.|\n)*?)\*\//.customReplace(t,function(r) {
				return tag("comment",r.matched(0));
			});
			var kwds = [
				"function","var","class","if","else","while","do","for","break","continue","return",
				"extends","implements","import","switch","case","default","static","public","private",
				"try","catch","new","this","throw","extern","enum","in","interface","untyped","cast",
				"override","typedef","f9dynamic","package","callback","inline",
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
			for( i in 0...tags.length )
				t = StringTools.replace(t,"##TAG"+i+"##",tags[i]);
		default:
		}
		return '<pre'+cl+'>'+t+"</pre>";
	}

	function paragraph( t : String ) : String {
		var me = this;
		// unhtml
		t = StringTools.htmlEscape(t);
		// newlines
		t = StringTools.replace(t,"\n","<br/>");
		// titles
		t = ~/====== ?(.*?) ?======/g.replace(t,"<h1>$1</h1>");
		t = ~/===== ?(.*?) ?=====/g.replace(t,"<h2>$1</h2>");
		t = ~/==== ?(.*?) ?====/g.replace(t,"<h3>$1</h3>");
		// links
		t = ~/\[\[([^\]]*?)\|(.*?)\]\]/g.replace(t,'<a href="$1">$2</a>');
		t = ~/\[\[(.*?)\]\]/.customReplace(t,function(r) {
			var i = me.getInfos(r.matched(1));
			return '<a href="'+i.url+'">'+i.title+'</a>';
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
		t = StringTools.replace(t,"\r\n","\n");
		var me = this;
		var b = new StringBuf();
		var codes = new Array();
		t = ~/<code( [a-zA-Z0-9]+)?>((.|\n)*?)<\/code>/.customReplace(t,function(r) {
			var style = r.matched(1);
			var code = me.code(r.matched(2),(style == null)?null:style.substr(1));
			codes.push(code);
			return "##CODE"+(codes.length-1)+"##";
		});
		for( t in ~/\n[ \t]*\n/g.split(t) ) {
			var p = paragraph(t);
			switch( p.substr(0,3) ) {
			case "<h1","<h2","<h3","<ul","<pr","##C":
				b.add(p);
			default:
				b.add("<p>");
				b.add(p);
				b.add("</p>");
			}
			b.add("\n");
		}
		t = b.toString();
		for( i in 0...codes.length )
			t = StringTools.replace(t,"##CODE"+i+"##",codes[i]);
		// cleanup
		t = StringTools.replace(t, "<p><br/>", "<p>");
		t = StringTools.replace(t, "<br/></p>", "</p>");
		t = StringTools.replace(t, "<p></p>", "");
		t = StringTools.replace(t, "><p>", ">\n<p>");
		return t;
	}


}