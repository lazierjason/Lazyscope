package com.lazyscope
{
	import flash.utils.setInterval;
	import flash.utils.setTimeout;
	
	import mx.binding.utils.ChangeWatcher;
	import mx.events.PropertyChangeEvent;
	
	import spark.core.ContentCache;
	
	public class CacheImageLoader extends ContentCache
	{
		public var alertPendingQueue:Number = 0;
		public function CacheImageLoader()
		{
			super();
		}
		
		public function get numPendingQueue():Number
		{
			return requestQueue.length;
		}
	}
}