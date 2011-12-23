package com.lazyscope
{
	//[Event(name="cached", type="com.lazyscope.CachedImageEvent")]
	
	import flash.display.Bitmap;
	import flash.display.LoaderInfo;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLRequest;
	
	import spark.primitives.BitmapImage;
	
	public class CachedImage extends BitmapImage
	{
		public static const MAX_BYTES:Number = 1024 * 512;
		public static var cacheLoader:CacheImageLoader;
		public static function onError(event:Event):void
		{
			trace(event, 'CachedImage onError');
		}
		
		public function CachedImage()
		{
			super();

			smooth = true;
			clearOnLoad = true;
			//cachePolicy = 'on';
			
			if (!cacheLoader) {
				cacheLoader = new CacheImageLoader;
				cacheLoader.enableCaching = true;
				cacheLoader.maxCacheEntries = 30;
				cacheLoader.enableQueueing = true;
				cacheLoader.maxActiveRequests = 7;
			}
			contentLoader = cacheLoader;
			
			addEventListener(ProgressEvent.PROGRESS, progress, false, 0, true);
			addEventListener(IOErrorEvent.IO_ERROR, onError, false, 0, true);
			addEventListener(SecurityErrorEvent.SECURITY_ERROR, onError, false, 0, true);
		}
		
		private function progress(event:ProgressEvent):void
		{
			if (event.bytesLoaded > MAX_BYTES || event.bytesTotal > MAX_BYTES) {
				source = null;
				dispatchEvent(new IOErrorEvent(IOErrorEvent.IO_ERROR));
			}
		}
		
		override protected function contentComplete(content:Object):void
		{
			if (content is LoaderInfo) {
				var loaderInfo:LoaderInfo = content as LoaderInfo;
				if (loaderInfo.childAllowsParent && !(loaderInfo.content is Bitmap)) return;
			}
			
			super.contentComplete(content);
		}
		
		override public function set source(value:Object):void
		{
			var url:String = null;
			if (value is String) {
				url = value as String;
			}else if (value is URLRequest) {
				url = URLRequest(value).url;
			}
			
			if (url != null) {
				if (url.match(/^data:/i) || (url.match(/^https?:/i) && url.match(/file:/i))) {
					
					if (cacheLoader.numPendingQueue > 30) {
						trace('cacheLoader.numPendingQueue', cacheLoader.numPendingQueue);
						cacheLoader.removeAllQueueEntries();
					}
					
					super.source = null;
					return;
				}
			}
			
			super.source = value;
		}
		
		/*
		override public function set source(value:Object):void
		{
			_source = value;
			
			if (!value || noCustomDownload) {
				if (value)
					contentLoader = cacheLoader;
				super.source = value;
				return;
			}
			if (super.source == value || url == value) return;
			if (typeof value == 'string') {
				if (value.match(/^https?:\/\//i)) {
					url = value.replace(/^https?:\/\//i, 'http://');
					if (url.match(/\.swf($|\?)/)) return;
					
					var obj:Object = cacheLoader.getCacheEntry(url);
					if (obj) {
						super.source = obj;
					}else{
						super.source = null;
						eventDispatcher.addEventListener('cached', cached, false, 0, true);
						if (requested.getItemIndex(url) == -1) {
							//trace(url);
							requested.addItem(url);
							request(url);
						}
					}
					return;
				}else if (value.match(/^data:/i)) {
					super.source = null;
					url = null;
					return;
				}
			}
			super.source = value;
		}
		//*/
		
		/*
		public function cached(event:CachedImageEvent):void
		{
			if (event.url != url) return;
			//if (super.source) return;
			eventDispatcher.removeEventListener('cached', cached);
			
			var obj:Object = cacheLoader.getCacheEntry(url);
			if (obj) {
				super.source = obj;
			}
		}
		
		public function request(url:String):void
		{
			Crawler.downloadURL(url, function(u:String, c:ByteArray, h:Number):void {
				requested.removeItem(url);
				if (c && c.length > 0) {
					cacheLoader.addCacheEntry(url, c);
					eventDispatcher.dispatchEvent(new CachedImageEvent(CachedImageEvent.CACHED, url));
				}
			}, 'binary', true, 10, true);
		}
		*/
	}
}