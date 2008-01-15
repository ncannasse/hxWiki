private class AllTexts extends haxe.xml.Proxy<"tpl/en/texts.xml",String> {
}

class Text {

	static var FILE = "texts.xml";

	static var TEXTS = {
		var xml = Xml.parse(neko.io.File.getContent(Config.TPL+FILE)).firstElement();
		var h = new Hash();
		for( x in xml.elements() ) {
			var id = x.get("id");
			if( id == null )
				throw "Missing 'id' in "+FILE;
			if( h.exists(id) )
				throw "Duplicate id '"+id+"' in "+FILE;
			var buf = new StringBuf();
			for( c in x )
				buf.add(c.toString());
			h.set(id,buf.toString());
		}
		h;
	}

	public static var get = new AllTexts(TEXTS.get);
	public static function getText(id) { return TEXTS.get(id); }

	public static function format( t : String, ?params : Dynamic ) {
		if( params != null ) {
			for( f in Reflect.fields(params) )
				t = t.split("::"+f+"::").join(Std.string(Reflect.field(params,f)));
		}
		return t;
	}

}
