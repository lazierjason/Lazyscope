package com.lazyscope
{
	import mx.utils.URLUtil;
	
	public class URL
	{
		public var protocol:String;
		public var host:String;
		public var path:String;
		public var query:String;
		public var hash:String;
		public var urlOrig:String;
		
		public function URL(url:String = null)
		{
			if (url != null)
				this.setURL(url);
		}
		
		//
		//http://openstack.org/blog/2010/09/the-second-openstack-design-conference/?awesm=5ADtH&utm_medium=awe.sm-copypaste&utm_source=direct-awe.sm&utm_content=awesm-site
		
		public function setURL(urlOrig:String):URL
		{
			urlOrig = encodeURI(urlOrig);
			var url:String = urlOrig.replace(/^[\s\r\n]+/, '');
			
			url = url.replace(/(gawker|deadspin|kotaku|jezebel|io9|jalopnik|gizmodo|lifehacker)\.com\/#!/, '$1.com/');
			
			
			this.protocol = URLUtil.getProtocol( url ).toLowerCase();
			this.host = URLUtil.getServerName( url ).toLowerCase();
			this.path = '/';
			this.urlOrig = urlOrig; 
				
			var m:Array=url.match(/^[^:]+:\/{2,}[^\/\?#]+(\/[^\?#]*)?(\?[^#]+)?(#[^#]+)?/);
			//trace('MATCH:', m, url);
			if (!m) return this;	// TODO: invalid url - e.g.) /projects/1040581998/biocurious-a-hackerspace-for-biotech-the-community/posts
			this.path = m[1]?m[1]:'/';
			
			// for nytimes
			if (this.host.match(/nytimes.com$/)) {
				this.query = '';
				this.hash = '';
				return this;
			};
			
			if (m[2]) {
				this.query = m[2].toString().substr(1).replace(/(^|&)(utm_[^=]+|awe\.?sm[^=]*|_i_(referer|location))=[^&]+/g, '').replace(/(^|&)(source|src|mod)=(rss|feed|twitter|twt)[^=&]*/g, '').replace(/&+/, '&').replace(/^\s+|\s+$/g, '');
				//this.query = m[2].toString().substr(1).replace(/(^|&)(utm_[^=]+|awe\.?sm[^=]*)=[^&]+/g, '').replace(/&+/, '&').replace(/^\s+|\s+$/g, '');
				if (this.query == '&')
					this.query='';
			}else
				this.query = '';
			this.hash = m[3]?m[3].toString().substr(1):'';
			
			return this;
		}
		
		public static function resolve(targetUrl:String, baseUrl:String):String
		{
			if (!baseUrl) return targetUrl;
			if (!targetUrl) return '';
			//////// TODO: resolve URL!!! /////////
			return targetUrl;
		}
		
		public static function normalize(url:String):String
		{
			if (!url) return '';
			var u:URL = new URL(url);
			return u.normalize();
		}
		
		public function normalize(url:String=null):String
		{
			if (url != null)
				this.setURL(url);
			
			if (!this.host) return url;
			
			var protocol:String = this.protocol.match(/^http/)?'http':this.protocol;
			var host:String = this.host.replace(/^www\./, '');
			var path:String = '/'+(this.path.replace(/^\/+/, '').replace(/\/+$/, '').replace(/\/{2,}/g, '/').replace(/\s/, '+'));
			
			if (!host) {
				trace('*Invalid URL:', url);		// TODO: resolve URL
				return url;	// for invalid url
			}
			
			var m:Array = host.match(/(^|\.)((tumblr|youtube|youtube-nocookie|twitter|wikispaces|vimeo|delicious|flickr)\.com$)/i);
			if (m) {
				switch (m[2]) {
					case 'vimeo.com':
					case 'twitter.com':
					case 'delicious.com':
						m = path.match(/^\/([^\/\?\#]+)/);
						if (m) path = path.replace(/^\/([^\/\?\#]+)/, '/'+(m[1].toString().toLowerCase()));
						break;
					case 'youtube-nocookie':
					case 'youtube.com':
						host = 'youtube.com';
						m = path.match(/^\/user\/([^\/\?\#]+)/);
						if (m) path = path.replace(/^\/user\/([^\/\?\#]+)/, '/user/'+(m[1].toString().toLowerCase()));
						else if (path.match(/^\/watch/) && (m = query.match(/v=([^&]+)/))) {
							query = 'v='+m[1];
						}
						break;
					case 'flickr.com':
						m = path.match(/^\/people\/([^\/\?\#]+)/);
						if (m) path = path.replace(/^\/people\/([^\/\?\#]+)/, '/people/'+(m[1].toString()));
						else{
							m = path.match(/^\/photos\/([^\/\?\#]+)/);
							if (m) path = path.replace(/^\/photos\/([^\/\?\#]+)/, '/photos/'+(m[1].toString()));
						}
						break;
					case 'tumblr.com':
						path = path.replace(/^(\/post\/\d+)\/.+$/, '$1');
						break;
				}
			}
			
			switch (protocol) {
				case 'tag':
					return 'tag:'+(path?path.toLowerCase():(host?host.toLowerCase():''));
					break;
			}
			
			var token:Array = path.split(/\//);
			token.shift();
			for (var i:Number=0; i < token.length; i++) {
				if (token[i] == '.') {
					token.splice(i, 1);
					i--;
				}else if (token[i] == '..') {
					if (i > 0) {
						token.splice(i-1, 2);
						i-=2;
					}else{
						token.splice(i, 1);
						i--;
					}
				}
			}
			
			return URLUtil.getFullURL('http://'+host+'/', (token.join('/'))+(query?'?'+query:''));
		}
		
		public static function isValidPermalink(perma:String, host:String):Boolean
		{
			if (!perma || !host) return false;
			var _p:URL = new URL(perma);
			if (!_p || !_p.host) return false;
			var _h:URL = new URL(host);
			if (!_h || !_h.host) return false;
			
			var p:String = _p.host.replace(/^www\./, '');
			var h:String = _h.host.replace(/^www\./, '');
			
			return p.search(h) > -1;
		}
	}
}