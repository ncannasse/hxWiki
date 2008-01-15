class Config {

	static var xml = Xml.parse(neko.io.File.getContent(neko.Web.getCwd()+"../config.xml")).firstElement();

	public static function get( att : String, ?def ) {
		var v = xml.get(att);
		if( v == null )
			v = def;
		if( v == null )
			throw "Missing config attribute "+att;
		return v;
	}

	public static var LANG = get("lang");
	public static var DEBUG = get("debug","0") == "1";
	public static var TPL = neko.Web.getCwd()+"../tpl/"+LANG+"/";

}