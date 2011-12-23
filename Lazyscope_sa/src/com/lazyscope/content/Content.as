package com.lazyscope.content
{
	import com.lazyscope.Base;
	import com.lazyscope.URL;
	import com.lazyscope.entry.BlogEntry;

	public class Content
	{
		public static function readabilityEnabled(u:String):Boolean
		{
			var url:URL = new URL(u);
			if (!url.host
				|| url.host == 'apps.facebook.com'
				|| url.host.match(/(www\.)?foursquare.com/)
				|| (url.host.match(/(www\.)?facebook.com/) && url.path.match(/^\/pages/i))
				
				|| (url.path && url.path.match(/(log-?in)|(sign-?in)|(sign-?up)/i))
			)
				return false;

			var type:String = getServiceType(url.host);
			if (type == null)
				return true;
			
			switch (type) {
				case 'Flickr':
					return Flickr.readabilityEnabled(url);
					break;
				case 'Twitpic':
					return Twitpic.readabilityEnabled(url);
					break;
				case 'Youtube':
					return Youtube.readabilityEnabled(url);
					break;
				case 'Yfrog':
					return Yfrog.readabilityEnabled(url);
					break;
				case 'Plixi':
					return Plixi.readabilityEnabled(url);
					break;
				case 'Instagram':
					return Instagram.readabilityEnabled(url);
					break;
			}
			return true;
		}
		
		public static function expectByURL(u:String, callback:Function):void
		{
			var url:URL = new URL(u);
			if (!url.host) {
				if (callback != null) callback(null);
				return;
			}

			var func:Function = function(entry:BlogEntry):void {
				if (entry != null) {
					//BlogEntry.register(entry, function(id:Number):void {
						if (callback != null) callback(entry);
						//trace('BlogEntry.sendToServer(entry);', entry.link, entry.blog);
						BlogEntry.sendToServer(entry);
					//});
				}else if (callback != null) callback(null);
			};
			
			var type:String = getServiceType(url.host);
			if (type == null) {
				if (callback != null) callback(null);
				return;
			}
			
			switch (type) {
				case 'Flickr':
					Flickr.makeEntry(url, func);
					break;
				case 'Twitpic':
					Twitpic.makeEntry(url, func);
					break;
				case 'Youtube':
					Youtube.makeEntry(url, func);
					break;
				case 'Yfrog':
					Yfrog.makeEntry(url, func);
					break;
				case 'Plixi':
					Plixi.makeEntry(url, func);
					break;
				case 'Instagram':
					Instagram.makeEntry(url, func);
					break;
				default:
					if (callback != null) callback(null);
					break;
			}
		}
		
		public static function expect(entry:BlogEntry):void
		{
			if (entry.image)
				entry.image = entry.image.replace(/(^\s+)|(\s+$)/g, '');
			
			if (entry.displayContent != null || entry.displayDescription != null) {
				return;
			}
			
			//if (!entry.service || entry.service == 'blog') {
				var url:URL = new URL(entry.link);
				
				if (!url.host) {
					return;
				}
				
//				if (entry.link && entry.link.match(/^https?:\/\/(www\.)?instagr\.am\/p\//)) {	// instagram picture
//					Instagram.fillContent(entry);
//					return;
//				}
				
				var type:String = getServiceType(url.host);
				if (type == null) {
					var m:Array;
					if (entry.video && !entry.image && (m = entry.video.match(/youtube(-nocookie)?\.com\/v\/([\da-zA-Z_\-]+)/i))) {
						entry.image='http://img.youtube.com/vi/'+(m[2])+'/hqdefault.jpg';
					}
					
					return;
				}
				
				entry.service=type;
			//}
			//trace('entry.service', entry.link, entry.service);
			
			switch (entry.service) {
				case 'Flickr':
					Flickr.fillContent(entry);
					break;
				case 'Twitpic':
					Twitpic.fillContent(entry);
					break;
				case 'Youtube':
					Youtube.fillContent(entry);
					break;
				case 'Yfrog':
					Yfrog.fillContent(entry);
					break;
				case 'Instagram':
					Instagram.fillContent(entry);
					break;
				case 'Plixi':
					Plixi.fillContent(entry);
					break;
			}
		}
		
		public static function getServiceType(host:String):String
		{
			var m:Array = host.match(/(\.|^)(youtube|vimeo|flickr|twitpic|yfrog|plixi)\.com$/);
			if (m && m[2]) {
				return (m[2].toString().substr(0, 1).toUpperCase()) + (m[2].toString().substr(1));
			}
			
			m = host.match(/instagr\.am$/);
			if (m)
				return 'Instagram';
			
			return null;
			
			if (host.match(/([^\/]+\.)*youtube\.com$/)) return 'Youtube';
			if (host.match(/([^\/]+\.)*vimeo\.com$/)) return 'Vimeo';
			if (host.match(/([^\/]+\.)*flickr\.com$/)) return 'Flickr';
			if (host.match(/([^\/]+\.)*twitpic\.com$/)) return 'Twitpic';
			if (host.match(/([^\/]+\.)*yfrog\.com$/)) return 'Yfrog';
			
			return null;
			
			if (host.match(/([^\/]+\.)?facebook\.com(\/|$)/)) return 'Facebook';
			if (host.match(/([^\/]+\.)?twitter\.com(\/|$)/)) return 'Twitter';
			if (host.match(/([^\/]+\.)?myspace\.com(\/|$)/)) return 'Myspace';
			if (host.match(/([^\/]+\.)?brightkite\.com(\/|$)/)) return 'Brightkite';
			if (host.match(/([^\/]+\.)?delicious\.com(\/|$)/)) return 'Delicious';
			if (host.match(/([^\/]+\.)?(lastfm\.com|last\.fm)(\/|$)/)) return 'Lastfm';
			if (host.match(/([^\/]+\.)?tumblr\.com(\/|$)/)) return 'Tumblr';
			if (host.match(/([^\/]+\.)?typepad\.com(\/|$)/)) return 'Typepad';
			if (host.match(/([^\/]+\.)?wordpress\.com(\/|$)/)) return 'Wordpress';
			if (host.match(/([^\/]+\.)?twitgoo\.com(\/|$)/)) return 'Twitgoo';
			
			return null;
		}
	}
}