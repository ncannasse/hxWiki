/*
 * Copyright (c) 2006, Motion-Twin
 * All rights reserved.
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *   - Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 *   - Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY MOTION-TWIN "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE HAXE PROJECT CONTRIBUTORS BE LIABLE FOR
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 */

class Calendar {

	var month : Int;
	var year : Int;
	var entries : Array<Int>;
	var monthName : String;
	var shortDays : Array<String>;
	var entry : db.Entry;

	public function new( parent : db.Entry, ?year:Int, ?month:Int ){
		if (month == null && year == null){
			var now = Date.now();
			month = Std.parseInt(DateTools.format(now, "%m"));
			year = Std.parseInt(DateTools.format(now, "%Y"));
		}
		this.entry = parent;
		this.month = month;
		this.year = year;
		this.entries = db.Entry.manager.calendarEntries(parent,year,month);
		var d = Date.fromString(year+"-"+StringTools.lpad(Std.string(month),"0",2)+"-15");
		monthName = DateTools.format(d,"%B");
		shortDays = Text.get.short_days.split("|");
	}

	public function gotoDate( d:Int ) : String {
		return "year="+year+";month="+month+";day="+d;
	}

	public function next() : String {
		var y = year;
		var m = month+1;
		if( m > 12 ) {
			y++;
			m = 1;
		}
		return "year="+y+";month="+m;
	}

	public function previous() : String {
		var y = year;
		var m = month-1;
		if( m <= 0 ) {
			y--;
			m = 12;
		}
		return "year="+y+";month="+m;
	}

	public function getWeeks() : Array<Array<{day:Int, n:Int}>> {
		var first = Date.fromString(year+"-"+(if (month >= 10) Std.string(month) else "0"+month)+"-01 00:00:00");
		var days = DateTools.getMonthDays(first);
		var emptyDays = first.getDay() - 1;
		var result = new List();
		var week = new Array();
		var d = 1;
		var i = 0;
		for( z in 0...emptyDays )
			week[i++] = null;
		do {
			for( z in emptyDays...7 ) {
				week[i++] = {day:d, n:entries[d]};
				d++;
				if( i == 7 ) {
					i = 0;
					result.add(week);
					week = new Array();
				}
				if( d > days ) break;
			}
		} while (d <= days);
		if( week.length > 0 ) {
			while( week.length < 7 )
				week.push(null);
			result.add(week);
		}
		return Lambda.array(result);
	}
}
