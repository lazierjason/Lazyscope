package com.lazyscope.content
{
	import com.lazyscope.URL;
	import com.lazyscope.Util;
	import com.lazyscope.crawl.Crawler;
	import com.lazyscope.crawl.ParserAtom;
	import com.lazyscope.entry.Blog;
	import com.lazyscope.entry.BlogEntry;
	
	import flash.system.System;
	import flash.xml.XMLDocument;
	
	public class Youtube
	{
		public function Youtube()
		{
		}
		
		public static function readabilityEnabled(url:URL):Boolean
		{
			if (!url.path.match(/^\/watch/)) {
				return true;
			}
			return false;
		}
		
		public static function fillContent(entry:BlogEntry):void
		{
			var m:Array = entry.link.match(/\?v=([\da-zA-Z_\-]+)/);
			if (m) {
				entry.video = 'http://youtube.com/v/'+m[1];
				entry.image = 'http://img.youtube.com/vi/'+m[1]+'/hqdefault.jpg';
				var reg:RegExp = new RegExp('^'+(entry.title));
				//entry.displayDescription = new YoutubeRender;
				entry.displayContent = '<object width="560" height="340"><param name="movie" value="'+(entry.video)+'?fs=1&amp;hd=1"></param><param name="allowFullScreen" value="true"></param><param name="allowscriptaccess" value="always"></param><embed src="'+(entry.video)+'?fs=1&amp;hd=1" type="application/x-shockwave-flash" allowscriptaccess="always" allowfullscreen="true" width="560" height="340"></embed></object><p>'+(Util.htmlEntitiesDecode(entry.description).replace(/^[\s\r\n]+/g, '').replace(reg, '').replace(/From:[\r\n]+.*/s, '').replace(/^[\s\r\n]+/g, '').replace(/[\r\n]+/g, '<br />'))+'</p>';
			}
		}
		
		public static function makeEntry(url:URL, callback:Function):void
		{
			if (!url.path.match(/^\/watch/)) {
				if (callback != null) callback(null);
				return;
			}
			
			var m:Array = url.query.match(/v=([\da-zA-Z_\-]+)/);
			if (m) {
				var id:String = m[1];
				
				Crawler.downloadURL('http://gdata.youtube.com/feeds/api/videos/'+id, function(__t:String, body:String, httpStatus:int):void {
					if (!body) {
						if (callback != null) callback(null);
						return;
					}
					var xml:XML;
					try{
						xml = new XML(body);
						if (!xml) {
							if (callback != null) callback(null);
							return;
						}
						var ns:Namespace = xml.namespace();
						var media:Namespace = xml.namespace('media');
						if (!ns || !media || !xml.ns::published) {
							if (callback != null) callback(null);
							return;
						}
						var userid:String = xml.ns::author.ns::name.toString().toLowerCase();
						var blog:Blog = new Blog('http://youtube.com/user/'+(userid), 'http://gdata.youtube.com/feeds/base/users/'+userid+'/uploads?alt=rss&v=2&orderby=published', userid);
						var entry:BlogEntry = new BlogEntry;
						
						entry.blog = blog;
						entry.link = 'http://youtube.com/watch?v='+id;
						entry.source = 'API';
						entry.service = 'Youtube';
						entry.published.setTime(Util.parseDate(xml.ns::published));
						entry.title = xml.ns::title;
						entry.description = xml.ns::content?xml.ns::content.replace(/^\s+|\s+$/g, ''):'';
						entry.category = xml.media::group.media::keywords?xml.media::group.media::keywords.split(/\s+/):null;
						entry.video = 'http://youtube.com/v/'+id;
						entry.image = 'http://img.youtube.com/vi/'+id+'/hqdefault.jpg';
						
						if (callback != null)
							callback(entry);
					}catch(e:Error) {
						trace(e.getStackTrace(), 'makeEntry youtube', body);
						//trace(body);
						if (callback != null) callback(null);
					}
					System.disposeXML(xml);
				});
			}
		}
	}
}