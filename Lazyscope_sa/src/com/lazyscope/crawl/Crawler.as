package com.lazyscope.crawl
{
	import com.lazyscope.Base;
	import com.lazyscope.DB;
	import com.lazyscope.URL;
	import com.lazyscope.content.Content;
	import com.lazyscope.content.Readability;
	import com.lazyscope.entry.BlogEntry;
	
	import flash.data.SQLResult;
	import flash.data.SQLStatement;
	import flash.events.Event;
	import flash.events.HTTPStatusEvent;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SQLErrorEvent;
	import flash.events.SQLEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestHeader;
	import flash.utils.ByteArray;
	import flash.utils.clearTimeout;
	import flash.utils.setTimeout;
	
	import mx.utils.URLUtil;

	public class Crawler
	{
		//public var feedFunc:FeedFunc;
		public static var rh:Array = new Array(new URLRequestHeader('Referer', 'http://twitter.com/'));
		
		public function Crawler()
		{
			//feedFunc = ff;
		}
		
		public static function detectEncoding(html:String):String {
			try{
			var m:Array = html.match(/<meta([^>]+)/g);
			for (var i:Number=0; i < m.length; i++) {
				var c:Array = m[i].toString().match(/charset=['"]?([^ '"]+)/);
				if (c && c[1])
					return c[1].replace(/^\s*|\s*$/g, '');
			}
			}catch(e:Error) {
				trace(e.getStackTrace(), 'detectEncoding');
			}
			return null;
		}
		
		public static function _cookieEnalbed(url:String):Boolean
		{
			try{
				var host:String = URLUtil.getServerName(url);
				if (!host) return false;
//				if (host.match(/(facebook|myspace|twitter|foursquare)\.com$/i))
				if (host.match(/(nytimes|alltop)\.com$/i))
					return true;
			}catch(e:Error) {
				trace(e.getStackTrace(), '_cookieEnalbed');
			}
			return false;
		}
		
		public static function isBinaryFile(fname:String):Boolean
		{
			return fname.match(/\.(jpg|jpeg|gif|png|bmp|png|psd|zip|tar|gz|7z|rar|arj|air|tiff|swf|avi|mpg|wmv|wma|mp3|mp4|wav|pdf|doc|key)($|\?)/i)?true:false;
		}
		
		public static var downloadWorking:Number = 0;
		public static var downloadQueue:Array = new Array;
		public static function downloadURL(url:String, callback:Function, type:String = 'text', forceHTTP:Boolean = false, timeout:Number = 30, acceptBinary:Boolean=false):void
		{
			downloadQueue.push([url, callback, type, forceHTTP, timeout, acceptBinary]);
			downloadRun();
		}
		
		public static function downloadRun():void
		{
			if (downloadWorking > 4) {
				//trace('downloadWorking is', downloadWorking, downloadQueue.length);
				return;
			}
			
			var q:Array = downloadQueue.pop();
			if (!q) return;
			downloadWorking++;
			
			_downloadURL(q[0], q[1], q[2], q[3], q[4], q[5]);
		}
		
		public static function downloadJobEnd():void
		{
			downloadWorking--;
			downloadRun();
		}
		
		public static function _downloadURL(url:String, callback:Function, type:String = 'text', forceHTTP:Boolean = false, timeout:Number = 30, acceptBinary:Boolean=false):void
		{
			var tt:Number = new Date().getTime();
			//trace('downloadURL start: ', url);
			if (callback == null) {
				downloadJobEnd();
				return;
			}

			if (!Base.twitter.ready || (!acceptBinary && isBinaryFile(url))) {
				if (callback != null) {
					callback(URL.normalize(url), null, 403);
					callback=null;
				}
				downloadJobEnd();
				return;
			}
			
			try{
				var retry:Number = 0;
				var loader:URLLoader = new URLLoader;
				loader.dataFormat = type;
				var redirect:String = '';
				var httpStatus:int = -1;
				
				var request:URLRequest = new URLRequest(url);
				request.followRedirects = !forceHTTP;
				request.manageCookies = _cookieEnalbed(url);
				request.useCache = true;
				request.cacheResponse = true;
				request.requestHeaders = rh;
				request.idleTimeout = timeout * 1000;
			}catch(e:Error) {
				trace(e.getStackTrace(), '_downloadURL1');
				if (callback != null) {
					callback(URL.normalize(url), null, 403);
					callback=null;
				}
				downloadJobEnd();
				return;
			}
			
			var timer:uint;
			var timerFunc:Function = function():void {
				clearTimeout(timer);
				timer = setTimeout(function():void {
					if (!loader) return;
					//trace('downloadURL timeout!!!', url, timeout);
					
					loader.removeEventListener(Event.COMPLETE, fc);
					loader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, fe);
					loader.removeEventListener(IOErrorEvent.IO_ERROR, fe);
					loader.removeEventListener(HTTPStatusEvent.HTTP_RESPONSE_STATUS, fh);
					
					try{
						loader.close();
					}catch(e:Error) {
						trace(e.getStackTrace(), '_downloadURL2');
					}
					
					if (callback != null) {
						callback(URL.normalize(url), null, httpStatus);
						callback=null;
					}
					downloadJobEnd();
				}, timeout * 1000);
			};
			
			var fc:Function = function(event:Event):void {
				try{
				//trace('downloadURL COMPLETE: ', url);
				if (forceHTTP && redirect && redirect != '' && redirect != url && retry < 5) {
					//trace('downloadURL COMPLETE REDIRECT or RETRY: ', url, redirect, retry);
					
					timerFunc();
					
					redirect = redirect.replace(/^\s*https?:\/\//i, 'http://');
					//trace('downloadURL COMPLETE REDIRECT or RETRY2: ', url, redirect, retry);
					
					if (!acceptBinary && isBinaryFile(url)) {
						if (callback != null) {
							callback(URL.normalize(url), null, 403);
							callback=null;
						}
						downloadJobEnd();
						return;
					}

					if (url != redirect) {
						url = redirect;
						setTimeout(function():void {
							request.url = url;
							
							//trace('downloadURL RESTART: ', url, redirect, retry);
							request.manageCookies = _cookieEnalbed(url);
							loader.load(request);
						}, 0);
						retry++;
						return;
					}
				}
				
				//trace('downloadURL COMPLETE2: ', url, new Date().getTime()-tt);
				
				loader.removeEventListener(Event.COMPLETE, fc);
				loader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, fe);
				loader.removeEventListener(IOErrorEvent.IO_ERROR, fe);
				loader.removeEventListener(HTTPStatusEvent.HTTP_RESPONSE_STATUS, fh);

				clearTimeout(timer);
				if (callback != null) {
					if (redirect == '')
						callback(URL.normalize(url), loader.data, httpStatus);
					else
						callback(URL.normalize(redirect), loader.data, httpStatus);
				}
				downloadJobEnd();
				}catch(e:Error) {
					trace(e.getStackTrace(), '_downloadURL3');
				}
			};
			
			var fe:Function = function(event:Event):void {
				try{
					//trace('Crawler download error', event);
				//trace('downloadURL SECURITY_ERROR: ', url);
				
				loader.removeEventListener(Event.COMPLETE, fc);
				loader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, fe);
				loader.removeEventListener(IOErrorEvent.IO_ERROR, fe);
				loader.removeEventListener(HTTPStatusEvent.HTTP_RESPONSE_STATUS, fh);
				loader.removeEventListener(ProgressEvent.PROGRESS, fp);

				clearTimeout(timer);
				if (callback != null) {
					callback(URL.normalize(url), null, httpStatus);
					callback=null;
				}
				downloadJobEnd();
				}catch(e:Error) {
					trace(e.getStackTrace(), '_downloadURL4');
				}
			};
			
			var fp:Function = function(event:ProgressEvent):void {
				//trace('ProgressEvent.PROGRESS', event);
				if (event.bytesTotal > 1024*1024 || event.bytesLoaded > 1024*1024) {
					fe(event);
				} 
			};
			
			var fh:Function = function(event:HTTPStatusEvent):void {
				try{
				httpStatus = event.status;
				//trace(event);
				//trace('downloadURL HTTP_RESPONSE_STATUS: ', httpStatus, url);
				
				var r:String = event.responseURL;
				if (httpStatus != 200 && event.responseHeaders && event.responseHeaders.length > 0) {
					for (var i:Number=0; i < event.responseHeaders.length; i++) {
						if (event.responseHeaders[i].name && event.responseHeaders[i].name.toString().toLowerCase() == 'location') {
							r = event.responseHeaders[i].value;
							break;
						}
					}
				}
				
				if (r != url) {
					redirect = URLUtil.getFullURL(url, r);
					return;
				}
				
				for (i=0; i < event.responseHeaders.length; i++) {
					if (event.responseHeaders[i].name && event.responseHeaders[i].value && event.responseHeaders[i].name.toLowerCase() == 'content-type') {
						var type:String = event.responseHeaders[i].value.toString();
						//trace('content-type', type);
						if (type) {
							if ((!acceptBinary && type.match(/image\//i)) || type.match(/shockwave/)) {
								clearTimeout(timer);
								
								loader.removeEventListener(Event.COMPLETE, fc);
								loader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, fe);
								loader.removeEventListener(IOErrorEvent.IO_ERROR, fe);
								loader.removeEventListener(HTTPStatusEvent.HTTP_RESPONSE_STATUS, fh);
								loader.removeEventListener(ProgressEvent.PROGRESS, fp);
	
								loader.close();
								
								if (callback != null) {
									callback(URL.normalize(url), null, httpStatus);
									callback=null;
								}
								downloadJobEnd();
							}
						}
					}
				}
				}catch(e:Error) {
					trace(e.getStackTrace(), '_downloadURL5');
				}
			};

			loader.addEventListener(Event.COMPLETE, fc);
			loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, fe);
			loader.addEventListener(IOErrorEvent.IO_ERROR, fe);
			loader.addEventListener(HTTPStatusEvent.HTTP_RESPONSE_STATUS, fh);
			loader.addEventListener(ProgressEvent.PROGRESS, fp);
			
			if (forceHTTP)
				url = url.replace(/^\s*https?:\/\//i, 'http://');
			
			loader.load(request);
			timerFunc();
		}
		
		public function parseFeed(feedURLOrig:String, feedFunc:FeedFunc):void
		{
			try{
			var feedURL:String = feedURLOrig ? feedURLOrig.replace(/[\r\n\s]+/, '') : '';		// \r\nhttp://stopparkingticketsnow.com/?feed=rss2
			
			feedFunc.feedURL = feedURL;
			
			Crawler.downloadURL(feedURL, function(u:String, content:ByteArray, httpStatus:int):void {
				try{
				if (!content || content.length <= 0) {
					feedFunc.fail('no content', true);
					return WorkingQueue.session().finish(null);
				}
				feedFunc.log('feed load finish');

				var rawContent:String;
				var line:String = content.readMultiByte(Math.min(content.bytesAvailable, 200), 'UTF-8');
				content.position = 0;
				if (line) {
					var m:Array = line.match(/encoding="([^"]+)"/);
					if (m && m[1] && m[1].toString().toLowerCase() != 'utf-8') {
						rawContent = content.readMultiByte(content.length, m[1]);
					}
				}
				if (!rawContent)
					rawContent = content.readUTFBytes(content.length);
				
				var parser:Parser = Parser.getParser(rawContent);
				if (parser == null) {
					//trace(rawContent);
					if (feedFunc.rawBytes) {
						var url:String = feedFunc.urlEndpoint?feedFunc.urlEndpoint:feedFunc.url;
						if (feedFunc.httpStatus != 404 && Content.readabilityEnabled(url)) {
							feedFunc.log('Readability start1');
							var readability:Readability = new Readability(url);
							readability.analyzeHTML(url, feedFunc.rawBytes, function(entry:BlogEntry):void {
								if (entry) {
									feedFunc.success(entry);
								}else{
									feedFunc.fail('Readability fails!', true, true, true);
								}
							});
						}else{
							feedFunc.fail('Readability disabled');
						}
					}else{
						feedFunc.fail('unknown feed', true, true);
					}
					return WorkingQueue.session().finish(null);
				}
				
				parser.parse(feedFunc);
				}catch(e:Error) {
					trace(e.getStackTrace(), 'parseFeed1');
				}
			}, 'binary', true);
			
			feedFunc.log('feed load');
			}catch(e:Error) {
				trace(e.getStackTrace(), 'parseFeed2');
			}
		}
		
		public function start(feedFunc:FeedFunc):void
		{
			//feedFunc.fail('dummy');
			//return WorkingQueue.session().finish();
			
			var db:DB = DB.session();
			var sql:String = 'select url, url2, title from p4_fail_link where url=:url and time_register > :time';
			db.fetch(sql, {':url':feedFunc.url, ':time':Math.floor((new Date().getTime())/1000)-(60*60*24)}, function(event:SQLEvent):void {
				var stmt:SQLStatement = SQLStatement(event.target);
				var res:SQLResult = stmt.getResult();
				if (res == null || res.data == null || res.data.length <= 0)
					_start(feedFunc);
				else{
					feedFunc.title = res.data[0].title;
					feedFunc.urlEndpoint = res.data[0].url2;
					feedFunc.fail('fail_link');
					return WorkingQueue.session().finish(null);
				}
			}, function(event:SQLErrorEvent):void {
				_start(feedFunc);
			});
		}
		
		public function _start(feedFunc:FeedFunc):void
		{
			try{
			feedFunc.log('crawl start');
			
			var crawlFunc:Function=function(url:String, content:ByteArray):void {
				try{
				var feedURL:String = Feed.getFeedURL(content, url);
				if (feedURL == null) {
					//feedFunc.fail('no feed url', true, true);
					
					// Readability !!
					if (feedFunc.httpStatus != 404 && Content.readabilityEnabled(url)) {
						feedFunc.log('Readability start2');
						var readability:Readability = new Readability(url);
						readability.analyzeHTML(url, content, function(entry:BlogEntry):void {
							if (entry) {
								feedFunc.success(entry);
							}else{
								feedFunc.fail('Readability fails!', true, true, true);
							}
						});
					}else{
						feedFunc.fail('Readability disabled');
					}
					
					return WorkingQueue.session().finish(null);
				}
				
				parseFeed(feedURL, feedFunc);
				}catch(e:Error) {
					trace(e.getStackTrace(), '_start1');
				}
			};
			
			var fetchFail:Number = 0;
			var fetchFunc:Function = function(u:String, content:ByteArray, httpStatus:int):void {
				try{
				//trace('httpStatus', httpStatus);
				/*
				if (httpStatus == 404 && feedFunc.isUpdated && fetchFail < 5) {
					fetchFail++;
					setTimeout(function():void {
						Crawler.downloadURL(feedFunc.url, fetchFunc, 'binary', true);
					}, 2000);
					return;
				}
				*/
				
				if (!u || u.length <= 0 || content == null || content.bytesAvailable <= 0) {
					//fail
					feedFunc.fail('no content2', true);
					return WorkingQueue.session().finish(null);
				}
				
				feedFunc.rawBytes = content;
				feedFunc.httpStatus = httpStatus;
				
				if (u != feedFunc.url) {
					feedFunc.log('redirected: '+u);
					feedFunc.setURLEndpoint(u);
					
					Content.expectByURL(u, function(entry:BlogEntry):void {
						if (entry == null) {
							BlogEntry.getByURL(u, function(entry:BlogEntry):void {
								if (entry != null) {
									if (entry.link && feedFunc.url != entry.link && (!feedFunc.urlEndpoint || feedFunc.urlEndpoint != entry.link))
										feedFunc.setURLEndpoint(entry.link);
									feedFunc.success(entry);
									return WorkingQueue.session().finish(null);
								}
								//crawl
								crawlFunc(u, content);
							}, true, feedFunc.url, feedFunc);
						}else{
							feedFunc.success(entry, true, null, true);
							return WorkingQueue.session().finish(null);
						}
					});
				}else{
					//crawl
					crawlFunc(u, content);
				}
				}catch(e:Error) {
					trace(e.getStackTrace(), '_start2');
				}
			};
			
			Crawler.downloadURL(feedFunc.url, fetchFunc, 'binary', true);
			}catch(e:Error) {
				trace(e.getStackTrace(), '_start3');
			}
		}
	}
}