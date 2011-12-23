package com.lazyscope.content
{
	import com.lazyscope.URL;
	import com.lazyscope.crawl.Crawler;
	import com.lazyscope.entry.BlogEntry;
	
	public class Instagram
	{
		public function Instagram()
		{
		}
		
		public static function fillContent(entry:BlogEntry):void
		{
			//entry.displayContent = entry.content;
		}
		
		public static function readabilityEnabled(url:URL):Boolean
		{
			if (!url.path.match(/^\/p\//)) {
				return true;
			}
			return false;
		}
		
		public static function makeEntry(url:URL, callback:Function):void
		{
			if (!url.path.match(/^\/p\//)) {
				if (callback != null) callback(null);
				return;
			}
			
			Crawler.downloadURL(url.urlOrig, function(u:String, html:String, httpStatus:Number):void {
				if (!html || httpStatus != 200) {
					if (callback != null) callback(null);
					return;
				}
				var m:Array;
				if (html && (m = html.match(/<meta property="og:image"\s+content="([^"]+)"/))) {
					var imageURL:String = m[1];
					m = html.match(/<meta property="og:title"\s+content="([^"]+)"/);
					var title:String = m ? m[1] : '';
					m = html.match(/<meta property="og:description"\s+content="([^"]+)"/);
					var description:String = m ? m[1] : '';
					m = html.match(/<img src="([^"]+)" class="profile-photo"/);
					var profileImageURL:String = m ? m[1] : '';
					
					var entry:BlogEntry = new BlogEntry;
					entry.link = url.urlOrig;
					entry.image = imageURL;
					entry.title = title;
					entry.content = '<a href="'+(entry.link)+'"><img src="'+imageURL+'" /></a><p>'+description+'</p>';
					entry.description = description;
					entry.source = 'web';
					entry.service = 'Instagram';
					if (callback != null) callback(entry);
				}else{
					if (callback != null) callback(null);
				}				
			});
		}
	}
}