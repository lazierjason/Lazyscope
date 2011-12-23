package com.lazyscope.crawl
{
	import com.lazyscope.Base;
	import com.lazyscope.DB;
	//import com.lazyscope.DataServer;
	import com.lazyscope.content.Content;
	import com.lazyscope.content.Readability;
	import com.lazyscope.entry.Blog;
	import com.lazyscope.entry.BlogEntry;
	
	import flash.net.URLVariables;
	import flash.utils.ByteArray;
	import flash.utils.setTimeout;

	public class FeedFunc
	{
		public var feedURL:String;
		public var url:String;
		public var claimURL:String;
		public var urlEndpoint:String;
		public var urlReg:RegExp;
		
		public var _callback:Function = null;
		//public var _success:Function = null;
		//public var _fail:Function = null;
		public var userData:Object = null;
		public var successed:Boolean = false;
		public var httpStatus:int = -1;
		
		public var rawBytes:ByteArray;
		
		public var title:String;
		
		public var logs:Array = new Array;
		
		public var blog:Blog;
		
		public var isUpdated:Boolean = false;
		
		
		public function FeedFunc(url:String, callback:Function = null, userData:Object = null, claimURL:String = null, isUpdated:Boolean=false)
		{
			this.url = url;
			this.claimURL = claimURL;
			
			if (this.url)
				this.urlReg= new RegExp('^'+(this.url.replace(/\//g, '\/'))+'[\/\?]?', '');
			
			this._callback = callback;
			//this._fail = fail;
			this.userData = userData;
			this.isUpdated = isUpdated;
			
			log('created');
		}
		
		public function log(msg:String):void
		{
			return;
			if (logs) logs.push([new Date().getTime(), msg]);
		}
		
		public function logFlush():void
		{
			logs = null;return;
			if (!logs) return;
			var txt:String = '';
			
			var cur:Number = -1;
			for (var i:Number=0; i < logs.length; i++) {
				if (i > 0) {
					txt += (logs[i][0]-cur) + '		' + logs[i][1] + '\n';
				}
				cur = logs[i][0];
			}
			txt += 'Total: '+(cur - logs[0][0])+'\n';
			logs = null;
			trace(url, urlEndpoint, txt);
			//*/
		}
		
		public function setURLEndpoint(url:String):void
		{
			if (this.url == url) return;
			this.urlEndpoint = url;
			
			//insert redirect db
			var db:DB = DB.session();
			db.execute('INSERT INTO p4_redirect(from_url, to_url, time_register) VALUES(:from, :to, :time)', {
				':from':this.url,
				':to':url,
				':time':(new Date()).getTime()
			});
			
			var val:URLVariables = new URLVariables;
			val.f = this.url;
			val.t = this.urlEndpoint;
			//DataServer.request('RL', val.toString());
		}
		
		public function checkFinish():void
		{
			if (!successed) {
				if (httpStatus == 404) {
					fail('Readability fails (not found in feed, 404 not found)!', true);
					return;
				}
				
				// Readability !!
				if (_callback != null && Content.readabilityEnabled(urlEndpoint ? urlEndpoint : url)) {
					var readability:Readability = new Readability(urlEndpoint ? urlEndpoint : url);
					
					var func:Function = function(entry:BlogEntry):void {
						if (entry) {
							successed = true;
							
							log('success - readability');
							logFlush();
							
							//trace('success - readability!!!!!!!: ', entry.link, url, urlEndpoint);
							
							Content.expect(entry);
							if (_callback != null)
								_callback(true, [url, urlEndpoint?urlEndpoint:url, entry, userData]);
							
							destroy();
						}else{
							fail('Readability fails (not found in feed)!', true, false, true);
						}
					};
					
					if (rawBytes)
						readability.analyzeHTML(readability.url, rawBytes, func, null, blog);
					else
						readability.analyze(func, null, blog);
				}else
					fail('No Readability', true);
			}
		}
		
		public function isSuccessLink(link:String):Boolean
		{
			if (link == this.url || link == this.urlEndpoint) {
				return true;
			}
			return false;
		}
		
		public function success(entry:BlogEntry, insertDB:Boolean=false, insertCallback:Function=null, force:Boolean=false):void
		{
			/*
			if (this.urlEndpoint == null)
			this.urlEndpoint = entry.link;
			*/
			trace('success: ', entry.link, this.url, this.urlEndpoint);
			//trace(this._success);
			//trace(this.userData);
			
			if (entry.link == this.url || entry.link == this.urlEndpoint || force) {
				if (this._callback != null && !successed) {
					successed = true;
					
					if (Crawler.isBinaryFile(this.urlEndpoint?this.urlEndpoint:this.url)) {
						fail('binary file');
						return;
					}
					
					log('success');
					logFlush();
					
					trace('success!!!!!!!: ', entry.link, this.url, this.urlEndpoint);
					
					Content.expect(entry);
					_callback(true, [url, urlEndpoint?urlEndpoint:url, entry, userData]);
					
					destroy();
				}
				
				if (insertDB) {
					BlogEntry.register(entry, function(id:Number):void {
						if (insertCallback != null)
							insertCallback(id);
						trace('BlogEntry.register: '+id);
					});
				}else{
					if (insertCallback != null)
						insertCallback(entry.id);
				}
			}else{
				if (insertCallback != null)
					insertCallback(entry.id);
			}
			if (entry.source == 'rss' || entry.source == 'atom') {
				if (Base.stream)
					Base.stream.callLater(BlogEntry.sendToServer, [entry]);
			}
		}
		
		public function fail(err:String, noRepeat:Boolean=false, reportURL:Boolean=false, readabilityFail:Boolean=false):void
		{
			if (!title && rawBytes) {
				var rawContent:String = rawBytes.toString();
				var charset:String = Crawler.detectEncoding(rawContent);
				rawBytes.position = 0;
				if (charset && charset.toLowerCase() != 'utf-8')
					rawContent = rawBytes.readMultiByte(rawBytes.length, charset);
				
				title = HTMLParser.extractTitle(rawContent);
			}
			if (_callback != null) {
				_callback(false, [this.url, (this.urlEndpoint?this.urlEndpoint:this.url), (err+' '+this.url+' '+(this.urlEndpoint?this.urlEndpoint:'')), userData, title, readabilityFail]);
				destroy();
			}
			
			log('fail: '+err);
			logFlush();
			
			if (noRepeat) {
				//TODO: no repeat
				if (Base.twitter.ready) {
					var db:DB = DB.session();
					var sql:String = 'INSERT INTO p4_fail_link(url, url2, title, time_register, err) VALUES(:url, :url2, :title, :time_register, :err)';
					db.execute(sql, {':url':url, ':url2':urlEndpoint, ':title':title, ':time_register':Math.floor((new Date()).getTime()/1000), ':err':err});
				}
			}
			
			if (reportURL) {
				//TODO: report to server
			}
		}
		
		public function destroy():void
		{
			this._callback = null;
			setTimeout(function():void {
				blog = null;
				if (rawBytes != null) {
					rawBytes.clear();
					rawBytes = null;
				}
				userData = null;
				logs = null;
			}, 100);
		}
	}
}