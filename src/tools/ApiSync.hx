package tools;

class Proxy extends haxe.remoting.Proxy<handler.RemotingApi> {
}

class ApiSync {

	public static function main() {
		var config = {
			host : "dev.hxwiki.com",
			port : 80,
			user : "ncannasse",
			pass : "test",
		};
		var url = "http://"+config.host+":"+config.port+"/wiki/remoting";
		var cnx = haxe.remoting.Connection.urlConnect(url);
		var api = new Proxy(cnx.api);
		if( config.user != null ) {
			var inf = api.login(config.user,config.pass);
			cnx = haxe.remoting.Connection.urlConnect(url+"?sid="+inf.sid);
			api = new Proxy(cnx.api);
		}
		trace( api.read(["protect"],"en") );
	}

}