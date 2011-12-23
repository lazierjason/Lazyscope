package com.lazyscope.content
{
	import com.lazyscope.Util;
	
	import flash.events.Event;
	import flash.events.HTTPStatusEvent;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.net.URLRequestHeader;
	import flash.net.URLVariables;

	public class GoogleReader
	{
		public function GoogleReader()
		{
		}
		
		public static function getSessionID(id:String, pw:String, callback:Function=null):void
		{
			if (!id || !pw) {
				if (callback != null) callback(null);
				return;
			}
			
			var loader:URLLoader = new URLLoader;
			
			var fc:Function = function(event:Event):void {
				loader.removeEventListener(Event.COMPLETE, fc);
				loader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, fe);
				loader.removeEventListener(IOErrorEvent.IO_ERROR, fe);
				
				trace(loader.data);
				
				if (loader.data) {
					var res:String = Util.trim(String(loader.data)).replace(/\s+/g, '&');
					var val:URLVariables = new URLVariables(res);
					if (callback != null) callback(val);
					return;
				}
				if (callback != null) callback(null);
			};
			
			var fe:Function = function(event:Event):void {
				loader.removeEventListener(Event.COMPLETE, fc);
				loader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, fe);
				loader.removeEventListener(IOErrorEvent.IO_ERROR, fe);
				
				if (callback != null) callback(null);
			};
			
			var r:URLRequest = new URLRequest('https://www.google.com/accounts/ClientLogin');
			r.data = new URLVariables;
			r.data.accountType='GOOGLE';
			r.data.Email=id;
			r.data.Passwd=pw;
			r.data.service='reader';
			
			r.method = 'POST';
			r.manageCookies = false;
			
			loader.addEventListener(Event.COMPLETE, fc);
			loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, fe);
			loader.addEventListener(IOErrorEvent.IO_ERROR, fe);
			loader.dataFormat = URLLoaderDataFormat.TEXT;
			loader.load(r);
		}
		
		public static function getSubscriptionList(auth:URLVariables, id:String, callback:Function=null):void
		{
			var loader:URLLoader = new URLLoader;
			
			var fc:Function = function(event:Event):void {
				loader.removeEventListener(Event.COMPLETE, fc);
				loader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, fe);
				loader.removeEventListener(IOErrorEvent.IO_ERROR, fe);
				
				if (callback != null) callback(loader.data);
			};
			
			var fe:Function = function(event:Event):void {
				loader.removeEventListener(Event.COMPLETE, fc);
				loader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, fe);
				loader.removeEventListener(IOErrorEvent.IO_ERROR, fe);
				
				if (callback != null) callback(null);
			};
			
			var r:URLRequest = new URLRequest('http://www.google.com/reader/public/subscriptions/user/'+encodeURIComponent(id)+'/label/my-feeds');
//			var r:URLRequest = new URLRequest('http://www.google.com/reader/api/0/subscription/list');
			r.method = 'GET';
			r.manageCookies = false;
			r.requestHeaders = new Array(
				new URLRequestHeader('Authorization', 'GoogleLogin auth='+(auth.Auth))
			);
			
			loader.addEventListener(Event.COMPLETE, fc);
			loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, fe);
			loader.addEventListener(IOErrorEvent.IO_ERROR, fe);
			loader.dataFormat = URLLoaderDataFormat.BINARY;
			loader.load(r);
			
			
			
			
			
//				r.contentType = 'multipart/form-data';
//				r.requestHeaders = new Array(
//					new URLRequestHeader('X-Verify-Credentials-Authorization', 'OAuth realm="http://api.twitter.com/", '+(authStr.join(', '))),
//					new URLRequestHeader('X-Auth-Service-Provider', 'https://api.twitter.com/1/account/verify_credentials.json')
//				);
//				r.data = d;

			
			
			
//			var variables:URLVariables = new URLVariables();
//			var auth:URLVariables = new URLVariables(oauth.getSignedRequest('GET', 'https://www.google.com/accounts/ClientLogin?Email=storyofjason@gmail.com&Passwd=skehd301gh!', variables));
//			
//			
//			
//			
//			
//			
//			
//			
//			
//			
//			var url:String = 'http://www.google.com/reader/public/subscriptions/user/' + googleReaderID.text + '/label/my-feeds';
//			
//			Crawler.downloadURL(url, function(u:String, content:ByteArray, httpStatus:int):void {
//				if (content == null || httpStatus == 404) {
//					//fail
//					Util.isShowingAlert = true;
//					Alert.show('', 'No feed found!', Alert.OK, Base.app, function(event:CloseEvent):void{
//						Util.isShowingAlert = false;
//						container.enabled = true;
//						googleReaderID.getFocus();
//						googleReaderID.selectRange(0, googleReaderID.text.length);
//					});
//					return;
//				}
//				trace('=================================')
//				trace(content);
//				trace('---------------------------------');
//				trace(url);
//				
//				analyzeOPML(content);
//			}, 'binary');
			
			
			
		}
	}
}