package db;

/**
	Application specific session.
**/
@:skip class SessionData extends sys.db.Object {

	public var userName : String;
	public var lang : Int;
	public var notification : { error : Bool, text : String };

	public function setUser( u : User ) {
	}

}
