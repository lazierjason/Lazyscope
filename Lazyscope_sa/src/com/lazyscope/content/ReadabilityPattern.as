package com.lazyscope.content
{
	import com.lazyscope.DataServer;
	
	import mx.utils.URLUtil;

	public class ReadabilityPattern
	{
		public static var reg:RegExp;
		public static function match(url:String):Boolean
		{
			if (!url) return false;
			if (!reg) {
				//reg = new RegExp('(^|\.)(wired\.com|wsj\.com|huffingtonpost\.com|telegraph\.co\.uk|bbc\.co\.uk|time\.com|nytimes\.com|lifehacker\.com|tmz\.com|businessweek\.com|abcnews\.go\.com)', 'i');
				reg = new RegExp('(^|\.)(wired\.com|wsj\.com|huffingtonpost\.com|telegraph\.co\.uk|bbc\.co\.uk|time\.com|nytimes\.com|tmz\.com|businessweek\.com|abcnews\.go\.com)', 'i');
				
				//request to server
				//DataServer.request('RG', url+(urlEndPoint != null?'	#&#&#	'+urlEndPoint:''), function(vars:URLVariables=null):void {
			}

			var r:Array = URLUtil.getServerName(url).match(reg);
			//trace(url, r);
			return r && r[0] && r[0].length > 0 ? true : false;
		}
		
		public function ReadabilityPattern()
		{
		}
	}
}