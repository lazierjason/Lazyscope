package com.lazyscope.twitter
{
	import com.swfjunkie.tweetr.data.objects.DirectMessageData;
	import com.swfjunkie.tweetr.data.objects.StatusData;
	
	import flash.events.Event;
	
	public class TwitterStreamEvent extends Event
	{
		public var statusData:StatusData;
		public var directMessageData:DirectMessageData;
		
		public static const DIRECT_MESSAGE:String = 'directMessage';
		public static const STATUS:String = 'status';
		public static const FAVORITE:String = 'favorite';
		public static const MENTION:String = 'mention';
		
		public function TwitterStreamEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false, status:StatusData=null, dm:DirectMessageData=null)
		{
			super(type, bubbles, cancelable);
			
			statusData = status;
			directMessageData = dm;
		}
	}
}