class Config {

	public static var DIR;

	static function initConfig() {
		var cwd = neko.Web.getCwd();
		DIR = cwd + "../";
		var data;
		try {
			data = sys.io.File.getContent(DIR+"config.xml");
		} catch( e : Dynamic ) {
			DIR = cwd + "cfg/";
			data = sys.io.File.getContent(DIR+"config.xml");
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

	public static var USE_HTACCESS = get("htaccess","0") == "1";
	
	public static var FORUM_AUTOLOCK_DAYS = 180;
	public static var FORUM_MIN_MSGLEN = 10;
	public static var FORUM_THREADS_PER_PAGE = 20;
	public static var FORUM_MESSAGES_PER_PAGE = 15;
	public static var FORUM_CANT_POST_DAYS = 0;
	public static var FORUM_MAX_POST_PER_THREAD = 1000;
	
	public static function getSection( name : String, ?def : String ) {
		var e = xml.elementsNamed(name).next();
		if( e == null )
			return def;
		var b = new StringBuf();
		for( x in e )
			b.add(x.toString());
		return b.toString();
	}
	
}