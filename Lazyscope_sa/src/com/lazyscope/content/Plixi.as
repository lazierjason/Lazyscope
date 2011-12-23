package com.lazyscope.content
{
	import com.lazyscope.URL;
	import com.lazyscope.crawl.Crawler;
	import com.lazyscope.entry.BlogEntry;
	
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;

	public class Plixi
	{
		public function Plixi()
		{
		}
		
		public static function fillContent(entry:BlogEntry):void
		{
			entry.displayContent = entry.content;
		}
		
		public static function readabilityEnabled(url:URL):Boolean
		{
			var m:Array = url.path.match(/^\/p\/(\d+)/);
			if (!m) {
				return true;
			}
			return false;
		}
		
		public static function makeEntry(url:URL, callback:Function):void
		{
			var m:Array = url.path.match(/^\/p\/(\d+)/);
			if (!m) {
				if (callback != null) callback(null);
				return;
			}
			
			var apiURL:String = 'http://api.plixi.com/api/tpapi.svc/photos/'+m[1]+'?getuser=true';
			
			Crawler.downloadURL(apiURL, function(u:String, xml:String, httpStatus:Number):void {
				if (!xml || httpStatus != 200) {
					if (callback != null) callback(null);
					return;
				}

				var m:Array;
				if (xml && (m = xml.match(/<LargeImageUrl>([^<]+)/))) {
					var imageLarge:String = m ? m[1] : '';
					m = xml.match(/<SmallImageUrl>([^<]+)/);
					var imageSmall:String = m ? m[1] : '';
					m = xml.match(/<Message>([^<]+)/);
					var message:String = m ? m[1] : '';
					m = xml.match(/<ProfileImage>([^<]+)/);
					var profileImageURL:String = m ? m[1] : '';
					m = xml.match(/<ScreenName>([^<]+)/);
					var userName:String = m ? m[1] : '';
					
					var entry:BlogEntry = new BlogEntry;
					entry.link = url.urlOrig;
					entry.image = imageSmall;
					entry.title = userName+'\'s photo';
					entry.content = '<a href="'+(entry.link)+'"><img src="'+imageLarge+'" /></a><p>'+message+'</p><p><img src="'+profileImageURL+'" width="48" /> by '+userName+'</p>';
					entry.description = message.replace(/^\s+|\s+$/g, '');
					entry.source = 'API';
					entry.service = 'Plixi';
					if (callback != null) callback(entry);
				}else{
					if (callback != null) callback(null);
				}
			});
		}

	}
}