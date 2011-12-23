package com.lazyscope
{
	import flash.events.Event;
	
	public class CachedImageEvent extends Event
	{
		public static const CACHED:String = 'cached';
		
		public var url:String;
		public function CachedImageEvent(type:String, url:String)
		{
			super(type);
			this.url = url;
		}
	}
}