package handler;

enum Action {
	Goto( act:String );
	Error( act:String, error:String, ?params : Dynamic );
	Done( act:String, confirm:String, ?params : Dynamic );
}
