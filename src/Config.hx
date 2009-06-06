class Config {

	public static var DIR;

	static function initConfig() {
		var cwd = neko.Web.getCwd();
		DIR = cwd + "../";
		var data;
		try {
			data = neko.io.File.getContent(DIR+"config.xml");
		} catch( e : Dynamic ) {
			DIR = cwd + "cfg/";
			data = neko.io.File.getContent(DIR+"config.xml");
		}
		return Xml.parse(data).firstElement();
	}

	static var xml = initConfig();

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
	public static var TPL = DIR + "tpl/"+LANG+"/";

	public static function getSection( name : String ) {
		var e = xml.elementsNamed(name).next();
		if( e == null )
			return null;
		var b = new StringBuf();
		for( x in e )
			b.add(x.toString());
		return b.toString();
	}

}