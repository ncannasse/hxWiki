package db;
import mt.db.Types;

enum VersionChange {
	VContent;
	VDeleted;
	VName;
	VTitle;
	VRestore;
}

class Version extends neko.db.Object {

	static function RELATIONS() {
		return [
			{ key : "eid", prop : "entry", manager : Entry.manager, lock : false },
			{ key : "uid", prop : "author", manager : User.manager, lock : false },
		];
	}
	public static var manager = new VersionManager(Version);

	public var id : SId;
	public var date : SDateTime;
	public var entry(dynamic,dynamic) : Entry;
	public var author(dynamic,dynamic) : SNull<User>;
	public var code : SInt;
	public var content : SNull<SText>;
	public var htmlContent : SNull<SText>;

	public function new( e, u ) {
		super();
		date = Date.now();
		entry = e;
		author = u;
	}

	public function setChange( c : VersionChange, vold, vnew ) {
		code = Type.enumIndex(c);
		content = vold;
		htmlContent = vnew;
	}

	public function getChange() : VersionChange {
		return Reflect.field(VersionChange,Type.getEnumConstructs(VersionChange)[code]);
	}

	public override function toString() {
		return "v" + id + "#" + entry.get_path();
	}

	public function getPreview( maxSize : Int ) {
		var x;
		try {
			x = Xml.parse(htmlContent);
		} catch( e : Dynamic ) {
			return { html : "Could not parse Version#"+id, broken : false };
		}
		var buf = new StringBuf();
		var pos = [0];
		var broken = false;
		for( e in x ) {
			printPreview(e,buf,pos,maxSize);
			if( pos[0] >= maxSize ) {
				broken = true;
				break;
			}
		}
		return { html : buf.toString(), broken : broken };
	}

	function printPreview( x : Xml, buf : StringBuf, pos : Array<Int>, max : Int ) {
		var p = pos[0];
		if( p >= max ) return;
		switch( x.nodeType ) {
		case Xml.PCData:
			if( p + x.nodeValue.length >= max ) {
				buf.addSub(x.nodeValue,0,max - p);
				buf.add("...");
				pos[0] = max;
			} else {
				buf.add(x.nodeValue);
				pos[0] += x.nodeValue.length;
			}
		case Xml.CData:
			buf.add("<![CDATA[");
			if( p + x.nodeValue.length >= max ) {
				buf.addSub(x.nodeValue,0,max - p);
				buf.add("...");
				pos[0] = max;
			} else {
				buf.add(x.nodeValue);
				pos[0] += x.nodeValue.length;
			}
			buf.add("]]>");
		case Xml.Element:
			buf.add("<");
			buf.add(x.nodeName);
			for( a in x.attributes() ) {
				buf.add(" ");
				buf.add(a);
				buf.add("=\"");
				buf.add(x.get(a));
				buf.add("\"");
			}
			if( x.firstChild() == null ) {
				buf.add("/>");
				return;
			}
			buf.add(">");
			for( e in x ) {
				printPreview(e,buf,pos,max);
				if( pos[0] >= max )
					break;
			}
			buf.add("</");
			buf.add(x.nodeName);
			buf.add(">");
		default:
			buf.add(x.toString());
		}
	}

}

class VersionManager extends neko.db.Manager<Version> {

	public function history( e : List<Entry>, user : User, pos : Int, count : Int ) {
		var cond = (e == null || e.isEmpty())?"TRUE":"eid IN ("+e.map(function(e) return e.id).join(",")+")";
		if( user != null )
			cond += " AND uid = "+user.id;
		return objects("SELECT * FROM Version WHERE "+cond+" ORDER BY id DESC LIMIT "+pos+","+count,false);
	}

	public function previous( v : Version ) {
		var r = result("SELECT MAX(id) as id FROM Version WHERE eid = "+v.entry.id+" AND id < "+v.id+" AND code IN (0,4)");
		if( r == null || r.id == null )
			return null;
		var v = get(r.id,false);
		// retrieve content of restored version
		if( v.getChange() == VRestore )
			v = get(Std.parseInt(v.content),false);
		return v;
	}

}