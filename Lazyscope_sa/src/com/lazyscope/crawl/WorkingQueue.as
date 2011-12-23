package com.lazyscope.crawl
{
	import flash.system.System;

	public class WorkingQueue
	{
		protected static var _session:WorkingQueue = null;
		
		public var working:Number;
		public var queue:Array;
		
		public static function session():WorkingQueue
		{
			if (!WorkingQueue._session)
				WorkingQueue._session = new WorkingQueue;
			return WorkingQueue._session;
		}
		
		public function WorkingQueue()
		{
			working = 0;
			queue = new Array;
		}
		
		public function push(q:FeedFunc):void
		{
			queue.push(q);
		}
		
		public function shift():FeedFunc
		{
			var q:FeedFunc = queue.shift();
			if (q != null) {
				working++;
				return q;
			}
			return null;
		}
		
		public function finish(parser:Parser):void
		{
			if (parser) {
				if (parser.doc) {
					parser.doc.removeNode();
					parser.doc = null;
				}
			}
			//trace('finfin!!!!!!!'+working);
			working--;
			//trace('finfin!!!!!!!'+working);
			Feed.session().run();
		}
	}
}