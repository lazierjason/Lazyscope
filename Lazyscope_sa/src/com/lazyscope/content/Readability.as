package com.lazyscope.content
{
	import com.lazyscope.DB;
	//import com.lazyscope.DataServer;
	import com.lazyscope.Util;
	import com.lazyscope.crawl.Crawler;
	import com.lazyscope.entry.Blog;
	import com.lazyscope.entry.BlogEntry;
	
	import flash.events.Event;
	import flash.events.HTMLUncaughtScriptExceptionEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.html.HTMLLoader;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	import flash.utils.clearTimeout;
	import flash.utils.setTimeout;
	
	import mx.utils.URLUtil;

	public class Readability
	{
		public var url:String;
		private var urlEndpoint:String;
		public var callback:Function;
		public var title:String;
		private static var instances:Array = null;
		
		public function Readability(url:String)
		{
			this.url = url;
			this.urlEndpoint = null;
			
			if (instances == null) {
				instances = new Array;
				for (var i:Number=3; i--;) {
					var r:ReadabilityEx = new ReadabilityEx;
					r.id = i;
					r.addEventListener('finish', runNext, false, 0, true);
					instances.push(r);
				}
			}
		}
		
		public function analyze(callback:Function, e:BlogEntry=null, blog:Blog=null):void
		{
			this.callback = callback;
			var nowObj:Readability = this;
			Crawler.downloadURL(this.url, function(u:String, content:ByteArray, httpStatus:int):void {
				//trace(content);
				if (content == null || httpStatus == 404) {
					//fail
//					trace('NO CONTENT from Readability!');
					
					if (callback != null)
						callback(e);

					return;
				}
				
				if (u != nowObj.url) {
					//set urlEndpoint !!
					nowObj.urlEndpoint = u;
				}
				
				analyzeHTML(u, content, callback, e, blog);
			}, 'binary', true);
		}
		
		private static var queue:Array = new Array;
		public function analyzeHTML(url:String, content:ByteArray, callback:Function=null, e:BlogEntry=null, blog:Blog=null):void
		{
			queue.push([url, content, callback, e, blog]);
			
			runNext();
		}
		
		public static function runNext(event:Event=null):void
		{
//			trace('runNext', event);
			var instance:ReadabilityEx = null;
			for (var i:Number=0; i < instances.length; i++) {
				var r:ReadabilityEx = instances[i];
				if (r.working) continue;
				instance = r;
				break;
			}
			
			if (instance) {
				var q:Array = queue.shift();
				if (q && q[0]) {
					instance.working = true;
					instance.run(q[0], q[1], q[2], q[3], q[4]);
				}
			}else{
//				trace('Readability queue size', queue.length);
			}
		}
		
	}
}