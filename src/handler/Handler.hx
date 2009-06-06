package handler;

class Handler<T> extends mtwin.web.Handler<T> {

	override function prepareTemplate( t:String ) : Void {
		App.prepareTemplate(t);
	}

	override function isLogged() : Bool {
		return App.user != null;
	}

	override function isModerator() : Bool {
		return App.user != null && App.user.group.canModerateForum;
	}

}

