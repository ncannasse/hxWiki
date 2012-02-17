import js.Dom;
import js.JQuery;
import Editor;

class JsTools {

	static function submitForm( f : Form ) {
		var x = new js.XMLHttpRequest();
		x.open("POST",f.action,false);
		var vars = "";
		for( i in 0...f.elements.length ) {
			var e = f.elements[i];
			if( e.name == "" )
				continue;
			vars += StringTools.urlEncode(e.name)+"="+StringTools.urlEncode(e.value)+"&";
		}
		vars += "chk=";
		vars += haxe.Md5.encode(vars);
		x.setRequestHeader("Content-Type","application/x-www-form-urlencoded");
		x.send(vars);
		try {
			var redirect = haxe.Unserializer.run(x.responseText);
			js.Lib.window.location = redirect;
		} catch( e : Dynamic ) {
			js.Lib.alert(Std.string(e));
		}
	}

	static var PREFIX = "haxe_api_";

	public static function toggle( id : String ) {
		var e = js.Lib.document.getElementById(id);
		if( e == null ) return false;
		e.style.display = (e.style.display == "none") ? "" : "none";
		return e.style.display != "none";
	}

	static function toggleInit() {
		for( c in js.Lib.document.cookie.split(';') ) {
			c = StringTools.trim(c.split("=")[0]);
			if( StringTools.startsWith(c,PREFIX) )
				toggle(c.substr(PREFIX.length));
		}
	}

	static function toggleCookie( id : String ) {
		js.Lib.document.cookie = PREFIX+id+"=show"+";path = /;expires=" + if( toggle(id) ) "Wed, 01-Jan-20 00:00:01 GMT" else "Sat, 01-Jan-00 00:00:01 GMT";
		return false;
	}

	static function main() {
	}

}