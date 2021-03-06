package com.lazyscope.crawl
{
	[Event(name="success", type="com.lazyscope.crawl.FeedFuncRequestEvent")]
	[Event(name="fail", type="com.lazyscope.crawl.FeedFuncRequestEvent")]
	
	import com.lazyscope.Base;
	import com.lazyscope.crawl.FeedFuncRequestEvent;
	import com.lazyscope.entry.BlogEntry;
	
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	
	public class FeedFuncRequest extends EventDispatcher
	{
		public var url:String;
		public var userData:Object;
		public var isUpdate:Boolean=false;
		public function FeedFuncRequest(url:String=null, u:Object=null, up:Boolean=false)
		{
			super();
			
			if (url)
				this.url = url;
			if (u)
				this.userData = u;
			if (up)
				this.isUpdate = up;
		}
		
		public function run():void
		{
			Base.feed.getContent(this.url, responder, userData, isUpdate);
			
			url = null;
			userData = null;
		}
		
		private function responder(res:Boolean, arg:Array):void
		{
			try{
				if (res)
					success(arg[0], arg[1], arg[2], arg[3]);
				else
					fail(arg[0], arg[1], arg[2], arg[3], arg[4], arg[5]);
				arg = null;
			}catch(e:Error){
				trace('*** responder in FeedFuncRequest', res);
				trace(arg);
			}
		}
		
		private function success(url:String, urlEndpoint:String, entry:BlogEntry, userData:Object):void
		{
			var event:FeedFuncRequestEvent = new FeedFuncRequestEvent(FeedFuncRequestEvent.SUCCESS, url, urlEndpoint, userData, this);
			event.entry = entry;
			
			dispatchEvent(event);
		}
		
		private function fail(url:String, urlEndpoint:String, err:String, userData:Object, title:String, readabilityFail:Boolean):void
		{
			var event:FeedFuncRequestEvent = new FeedFuncRequestEvent(FeedFuncRequestEvent.FAIL, url, urlEndpoint, userData, this);
			event.title = title;
			event.readabilityFail = readabilityFail;
			
			dispatchEvent(event);
		}
	}
}