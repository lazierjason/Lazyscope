package com.lazyscope.crawl
{
	import com.lazyscope.entry.BlogEntry;
	
	import flash.events.Event;
	
	public class FeedFuncRequestEvent extends Event
	{
		public static const SUCCESS:String = 'success';
		public static const FAIL:String = 'fail';
		
		public var url:String;
		public var urlEndpoint:String;
		public var entry:BlogEntry;
		public var userData:Object;
		
		public var err:String;
		public var title:String;
		public var readabilityFail:Boolean = false;
		
		public var req:FeedFuncRequest;
		
		public function FeedFuncRequestEvent(type:String, url:String, urlEndpoint:String, userData:Object=null, req:FeedFuncRequest=null)
		{
			super(type, false, false);
			
			this.url = url;
			this.urlEndpoint = urlEndpoint;
			this.userData = userData;
			this.req = req;
		}
	}
}