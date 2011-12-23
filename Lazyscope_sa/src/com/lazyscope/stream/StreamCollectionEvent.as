package com.lazyscope.stream
{
	import flash.events.Event;
	
	public class StreamCollectionEvent extends Event
	{
		public static const CUT:String = 'CUT';
		
		public var item:Object;
		public function StreamCollectionEvent(type:String, item:Object)
		{
			super(type);
			this.item = item;
		}
	}
}