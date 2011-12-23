package com.lazyscope.content
{
	import com.lazyscope.URL;
	import com.lazyscope.crawl.Crawler;
	import com.lazyscope.entry.Blog;
	import com.lazyscope.entry.BlogEntry;
	import com.swfjunkie.tweetr.oauth.OAuth;
	
	import flash.events.DataEvent;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.filesystem.File;
	import flash.net.URLRequest;
	import flash.net.URLRequestHeader;
	import flash.net.URLVariables;
	import flash.system.System;

	public class Twitpic
	{
		public function Twitpic()
		{
		}
		
		public static function readabilityEnabled(url:URL):Boolean
		{
			var m:Array = url.path.match(/\/photos\/.+/);
			if (!m) {
				return true;
			}
			return false;
		}

		public static function fillContent(entry:BlogEntry):void
		{
			var m:Array;
			if (entry.content) {
				entry.title = entry.link;
				m = entry.content.match(/<img[^>]+>/);
				if (m) {
					entry.displayContent = '<a href="'+(entry.link)+'">'+(m[0].replace(/\/show\/thumb\/([^\.]+)(\.(jpg|png|gif))/g, '/show/full/$1$2'))+'</a><p>'+(entry.description)+'</p>';
					return;
				}
				
			}
			m = entry.link.match(/twitpic\.com\/([^\/]+)\/?$/);
			if (m) {
				entry.displayContent = '<a href="'+(entry.link)+'"><img src="http://twitpic.com/show/full/'+m[1]+'.jpg" /></a><p>'+(entry.description)+'</p>';
				return;
			}
		}
		
		public static function getXML(tpid:String, callback:Function=null):void
		{
			Crawler.downloadURL('http://twitpic.com/'+tpid+'.xml', function(u:String, body:String, httpStatus:int):void {
				if (!body) {
					if (callback != null) callback(null);
					return;
				}
				var xml:XML;
				try{
					xml = new XML(body);
					var list:XMLList = xml.child('errors');
					if (list != null && list.length() > 0) {
						if (callback != null) callback(null);
						return;
					}
					
					if (callback != null) callback(xml);
				}catch(e:Error) {
					trace(e.getStackTrace(), 'getXML twitpic');
					if (callback != null) callback(null);
				}
			});
		}
		
		public static function makeEntry(url:URL, callback:Function):void
		{
			if (url.path.match(/\/photos\/.+/)) {
				//user url
				if (callback != null) callback(null);
				return;
			}
			
			var m:Array = url.path.match(/\/([^\/]+)/);
			if (m) {
				Crawler.downloadURL('http://twitpic.com/'+m[1]+'.xml', function(u:String, body:String, httpStatus:int):void {
					if (!body) {
						if (callback != null) callback(null);
						return;
					}
					var xml:XML;
					try{
						xml = new XML(body);
						var list:XMLList = xml.child('errors');
						if (list != null && list.length() > 0) {
							//err
							if (callback != null) callback(null);
							return;
						}
						
						var entry:BlogEntry = new BlogEntry;
						var url:String = 'http://twitpic.com/'+(xml.short_id);
						
						entry.blog = new Blog('http://twitpic.com/photos/'+(xml.user.username), 'http://twitpic.com/photos/'+(xml.user.username)+'/feed.rss', xml.user.name, xml.user.bio, xml.user.avatar_url);
						
						entry.link = url;
						entry.title = (xml.user.username)+': '+url+' '+(xml.message);
						entry.content = (xml.user.username)+': '+(xml.message)+'<br /><a href="'+url+'"><img src="http://twitpic.com/show/thumb/'+(xml.short_id)+'.jpg" /></a>';
						entry.description = entry.content.replace(/<[^>]+>/g, '').replace(/^\s+|\s+$/g, '');
						entry.image = 'http://twitpic.com/show/thumb/'+(xml.short_id)+'.jpg';
						entry.published.setTime(Date.parse(xml.timestamp.toString().replace(/-/g, '/')));
						entry.source = 'API';
						entry.service = 'Twitpic';
						
						//trace('TWITPIC!!!!!!!!!!!!!!!', entry);
						
						if (callback != null)
							callback(entry);
					}catch(e:Error) {
						trace(e.getStackTrace(), 'makeEntry twitpic', body, httpStatus, u, url);
						//trace(body);
						if (callback != null) callback(null);
					}
					System.disposeXML(xml);
				});
			}else{
				if (callback != null) callback(null);
				return;
			}
		}
		
		public static function uploadPhoto(oauth:OAuth, callback:Function, f:File, message:String=null):void
		{
			var d:URLVariables = new URLVariables;
			
			/**** Please write down your Twitpic api-key ****/
			d.key = '********************************';
			
			if (message)
				d.message = message;
			
			var auth:URLVariables = new URLVariables(oauth.getSignedRequest('GET', 'https://api.twitter.com/1/account/verify_credentials.json', new URLVariables()));
			var authStr:Array = new Array;
			for (var k:String in auth) {
				if (k.substr(0, 6) == 'oauth_') {
					authStr.push(k+'="'+encodeURIComponent(auth[k])+'"');
				}
			}
			var r:URLRequest = new URLRequest('http://api.twitpic.com/2/upload.xml');
			r.method = 'POST';
			r.contentType = 'multipart/form-data';
			r.requestHeaders = new Array(
				new URLRequestHeader('X-Verify-Credentials-Authorization', 'OAuth realm="http://api.twitter.com/", '+(authStr.join(', '))),
				new URLRequestHeader('X-Auth-Service-Provider', 'https://api.twitter.com/1/account/verify_credentials.json')
			);
			r.data = d;

			var fc:Function = function(event:DataEvent):void {
				f.removeEventListener(DataEvent.UPLOAD_COMPLETE_DATA, fc);
				f.removeEventListener(IOErrorEvent.IO_ERROR, fe);
				f.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, fe);
				try{
					var xml:XML = new XML(event.data);
					if (xml && xml.url) {
						if (callback != null) {
							callback(xml.url);
						}
						return;
					}
				}catch(e:Error) {
					trace(e.getStackTrace(), 'uploadPhoto');
				}
				if (callback != null)
					callback(null);
			};
			
			var fe:Function = function(event:Event):void {
				f.removeEventListener(DataEvent.UPLOAD_COMPLETE_DATA, fc);
				f.removeEventListener(IOErrorEvent.IO_ERROR, fe);
				f.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, fe);
				if (callback != null)
					callback(null);
			};
			
			f.addEventListener(DataEvent.UPLOAD_COMPLETE_DATA, fc);
			f.addEventListener(IOErrorEvent.IO_ERROR, fe);
			f.addEventListener(SecurityErrorEvent.SECURITY_ERROR, fe);
			
			f.upload(r, 'media');
		}
	}
}