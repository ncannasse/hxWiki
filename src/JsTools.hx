import js.Dom;
import Editor;

class JsTools {

	static function submitForm( f : Form ) {
		var x = new js.XMLHttpRequest();
		x.open("POST",f.action,false);
		var vars = "";
		for( i in 0...f.elements.length ) {
			var e = f.elements[i];
			vars += StringTools.urlEncode(e.name)+"="+StringTools.urlEncode(e.value)+";";
		}
		vars += "chk=";
		vars += haxe.Md5.encode(vars);
		x.send(vars);
		try {
			var redirect = haxe.Unserializer.run(x.responseText);
			js.Lib.window.location = redirect;
		} catch( e : Dynamic ) {
			js.Lib.alert(Std.string(e));
		}
	}

	static function main() {
	}

}