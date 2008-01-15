package db;

/**
	Application specific session.
**/
class SessionData extends neko.db.Object {

	static var __rtti = null;

	public var user(dynamic,dynamic) : User;
	public var userName : String;
	public var notification : { error : Bool, text : String };

	public function setUser( u : User ) {
	}

}
