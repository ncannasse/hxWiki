
class Uploader {

	static var f : flash.net.FileReference;
	static var cnx : haxe.remoting.Connection;
	static var params : Dynamic;

	static function main() {
		var mc = flash.Lib.current;
		var stage = mc.stage;
		stage.scaleMode = flash.display.StageScaleMode.NO_SCALE;
		params = mc.loaderInfo.parameters;
		try {
			cnx = haxe.remoting.ExternalConnection.jsConnect(params.object,null);
		} catch( e : Dynamic ) {
			trace(e);
		}
		mc.graphics.beginFill(0,0);
		mc.graphics.drawRect(0,0,1000,1000);
		stage.addEventListener(flash.events.MouseEvent.CLICK,function(_) browse());
	}

	static function browse() {
		f = new flash.net.FileReference();
		f.addEventListener("select",onBrowseSelect);
		f.browse([new flash.net.FileFilter(params.title,params.pattern)]);
	}

	static function onBrowseSelect( e : flash.events.Event ) {
		f.addEventListener("uploadCompleteData",onUploadComplete);
		f.addEventListener("progress",onUploadProgress);
		var rq = new flash.net.URLRequest(params.url);
		var vars = new flash.net.URLVariables();
		vars.sid = params.sid;
		rq.data = vars;
		f.upload(rq,"file");
	}

	static function onUploadProgress( e : flash.events.ProgressEvent ) {
		var stage = flash.Lib.current.stage;
		var w = stage.stageWidth;
		var h = stage.stageHeight;
		var g = flash.Lib.current.graphics;
		g.clear();
		g.beginFill(Std.parseInt(params.bgcolor));
		g.drawRect(0,0,w,h);
		g.endFill();
		g.beginFill(Std.parseInt(params.fgcolor));
		g.drawRect(1,1,(w-2),(h-2));
		g.endFill();
		g.beginFill(Std.parseInt(params.color));
		g.drawRect(1,1,(w - 2) * e.bytesLoaded / e.bytesTotal,h-2);
		g.endFill();
	}

	static function onUploadComplete( e : flash.events.DataEvent ) {
		var url;
		try {
			url = haxe.Unserializer.run(e.data);
			flash.Lib.current.graphics.clear();
			cnx.api.uploadResult.call([url]);
		} catch( err : Dynamic ) {
			var estr = Std.string(err);
			var m = "Invalid char";
			if( estr.substr(0,m.length) == m )
				estr += " in "+e.data;
			cnx.api.uploadError.call([estr]);
		}
	}

}