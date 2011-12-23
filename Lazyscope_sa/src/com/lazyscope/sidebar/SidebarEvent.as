package com.lazyscope.sidebar
{
	import flash.events.Event;
	
	public class SidebarEvent extends Event
	{
		public static const SELECT:String = 'select';
		public static const BUTTON_CLICK:String = 'buttonClick';
		public static const EXPAND:String = 'expand';
		
		private var _firedTarget:Object;
		public function SidebarEvent(type:String, firedTarget:Object=null)
		{
			super(type);
			
			_firedTarget = firedTarget;
		}
		
		public function set firedTarget(value:Object):void
		{
			_firedTarget = value;
		}
		
		public function get firedTarget():Object
		{
			return _firedTarget?_firedTarget:target;
		}
	}
}