package com.lazyscope.account
{
	import flash.events.Event;
	
	public class AccountTwitterEvent extends Event
	{
		public static var LISTS:String = 'lists';
		
		public var data:Object;
		public function AccountTwitterEvent(type:String, data:Object=null)
		{
			super(type);
			
			this.data = data;
		}
	}
}