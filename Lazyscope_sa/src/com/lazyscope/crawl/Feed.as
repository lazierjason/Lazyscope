package com.lazyscope.crawl
{
	import com.lazyscope.Base;
	import com.lazyscope.DB;
	//import com.lazyscope.DataServer;
	import com.lazyscope.URL;
	import com.lazyscope.content.Content;
	import com.lazyscope.entry.Blog;
	import com.lazyscope.entry.BlogEntry;
	import com.lazyscope.entry.StreamEntry;
	import com.lazyscope.stream.StreamCollection;
	
	import flash.data.SQLResult;
	import flash.data.SQLStatement;
	import flash.events.SQLErrorEvent;
	import flash.events.SQLEvent;
	import flash.net.URLVariables;
	import flash.utils.ByteArray;
	import flash.utils.setTimeout;
	import flash.xml.XMLNode;
	
	import mx.utils.URLUtil;

	public class Feed extends Base
	{
		protected static var _session:Feed = null;
		
		public static function session():Feed
		{
			if (!Feed._session)
				Feed._session = new Feed;
			return Feed._session;
		}
		
		public function isSubscribed(feedlink:String):Blog
		{
			if (!feedlink) return null;
			if (blogList.length > 0) {
				for (var i:Number=blogList.length; i--;) {
					var blog:Blog = blogList[i];
					if (blog.feedlink == feedlink) {
						return blog;
					}
				}
			}
			return null;
		}
		
		public function isSubscribedByBlog(link:String):Blog
		{
			if (!link) return null;
			if (blogList.length > 0) {
				for (var i:Number=blogList.length; i--;) {
					var blog:Blog = blogList[i];
					if (blog.link == link) {
						return blog;
					}
				}
			}
			return null;
		}
		
		public function blogRegisterCallback(id:Number, blog:Blog, userData:Object=null, callback:Function=null, getContentFromServer:Boolean=true):void {
//trace('==========================');
//trace('id:', id);
//trace('blog.link', blog.link);
//trace('blog.feedlink', blog.feedlink);
//trace('blog.title', blog.title);
//trace('--------------------------');
			var val:URLVariables = new URLVariables;
			val.link = blog.link;
			val.feedlink = blog.feedlink;
			val.user = twitter.userid;
			//DataServer.requestQueuePush('BS', val.toString());
			
			var sql:String = 'REPLACE INTO p4_subscribe(user, feedlink) values(:user, :feedlink)';
			db.execute(sql, {':user':twitter.userid, ':feedlink':blog.feedlink}, function(event:SQLEvent):void {
				if (callback != null)
					callback(true, blog.link, userData);
				
				blogList.push(blog);
				
				var dataObj:Object = {type:7, name:blog.title, feedlink:blog.feedlink, data:blog, isNew:true};
				sidebar.removeSite(blog.feedlink);
				sidebar.addSite(dataObj);
				
				if (!Base.sidebar.stream.expanding)
					Base.sidebar.stream.expand(null, true);
				
				//// Not works
				//					try {
				//						var idx:Number = sidebar.siteList.data.getItemIndex(dataObj);
				//						if (idx >= 0) {
				//							sidebar.siteList.ensureIndexIsVisible(idx);
				//						}
				//					}catch(e:*){}
				
				if (getContentFromServer)
					getHostContentFromServer(blog.link, null, null, blog, true);
				
				notify('Successfully subscribed to <b>'+(blog.title)+'</b>');
			}, function(event:SQLErrorEvent):void {
				if (callback != null)
					callback(false, blog.link, userData);
			});
		}
		
		public function subscribe(blog:Blog, userData:Object=null, callback:Function=null, getContentFromServer:Boolean=true):void
		{
			trace('subscribe', blog.link);
			if (!blog) {
				if (callback != null)
					callback(false, blog.link, userData);
				return;
			}
			
			Blog.register(blog, function(id:Number):void {
				blogRegisterCallback(id, blog, userData, callback, getContentFromServer);
			}, true);
			
		}
		
		public function unsubscribe(b:Blog, userData:Object=null, callback:Function=null):void
		{
			trace('unsubscribe', b.link);
			if (!b) {
				if (callback != null)
					callback(false, b.link, userData);
				return;
			}
			
			var val:URLVariables = new URLVariables;
			val.link = b.link;
			val.feedlink = b.feedlink;
			val.user = twitter.userid;

			//DataServer.requestQueuePush('BU', val.toString());
			
			var sql:String = 'DELETE FROM p4_subscribe WHERE user=:user and feedlink=:feedlink';
			db.execute(sql, {':user':twitter.userid, ':feedlink':b.feedlink}, function(event:SQLEvent):void {
				if (callback != null)
					callback(true, b.link, userData);
				
				if (blogList.length > 0) {
					for (var i:Number=blogList.length; i--;) {
						var blog:Blog = blogList[i];
						if (blog.feedlink == b.feedlink) {
							notify('Successfully unsubscribed from <b>'+(blog.title)+'</b>');
							blogList.splice(i, 1);
							sidebar.removeSite(blog.feedlink);
						}
					}
				}
			}, function(event:SQLErrorEvent):void {
				if (callback != null)
					callback(false, b.link, userData);
			});
			
		}

		
		public function Feed()
		{
			DB.ready();
		}
		
		public function getContent(url:String, callback:Function, userData:Object=null, isUpdated:Boolean=false):void
		{
			if (!DB.ready())
			{
				setTimeout(getContent, 10, url, callback, userData);
				return;
			}
			
			if (!url) {
				callback(false, [url, url, 'url null', userData, null, false]);
				return;
			}
			
			//fail(url, url, 'dummy', userData, null, false);return;
			
			var claimURL:String = url;
			url = URL.normalize(url);

			if (!url) {
				callback(false, [url, url, 'url null', userData, null, false]);
				return;
			}

			Content.expectByURL(url, function(entry:BlogEntry):void {
				if (entry == null) {
					BlogEntry.getByURL(url, function(entry:BlogEntry):void {
						if (entry != null) {
							if (Crawler.isBinaryFile(entry.link)) {
								callback(false, [url, entry.link, 'binary file', userData, entry.title, false]);
								return;
							}
							Content.expect(entry);
							callback(true, [url, entry.link, entry, userData]);
							return;
						}

						if (!url) {
							callback(false, [url, url, 'url null', userData, null, false]);
							return;
						}

						var feedFunc:FeedFunc = new FeedFunc(url, callback, userData, claimURL, isUpdated);
						
						WorkingQueue.session().push(feedFunc);
						run();
					}, true);
				}else{
					Content.expect(entry);
					callback(true, [url, entry.link, entry, userData]);
				}
			});
		}
		
		public function registerFeed(url:String, callback:Function, getContentFromServer:Boolean=true):void
		{
			if (!url || url.length <= 0) {
				callback(null);
				return;
			}
			var ff:FeedFunc = new FeedFunc(url);
			ff.feedURL = url;
			
			var func:Function = function(parser:Parser):void {
				if (!parser || !parser.doc || !parser.doc.firstChild || !parser.doc.firstChild.firstChild) {
					trace('no parser');
					callback(null);
					return;
				}
				
				//parse
				var root:XMLNode = parser.getRootNode();
				if (!root || !root.firstChild) {
					trace('!root');
					callback(null);
					return;
				}
				
				var blog:Blog = parser.parseBlog(root.firstChild);
				if (!blog) {
					trace('!blog');
					callback(null);
					return;
				}
				
				if (!blog.feedlink)
					blog.feedlink = ff.feedURL;
				
				if (!blog.link && blog.feedlink)
					blog.link = blog.feedlink;
				if (!blog.link) {
					trace('!blog.link');
					callback(null);
					return;
				}
					
				subscribe(blog, null, function(res:Boolean, link:String, userData:Object=null):void {
					callback(blog);
				}, getContentFromServer);
			};
			
			Crawler.downloadURL(url, function(u:String, content:String, httpStatus:int):void {
				if (!content) {
					trace('!content1');
					callback(null);
					return;
				}
				
				var parser:Parser = Parser.getParser(content);
				if (parser)
					func(parser);
				else{
					var feedURL:String = Feed.getFeedURL(content, url);
					if (!feedURL) {
						trace('!feedURL');
						callback(null);
						return;
					}
					
					ff.feedURL = feedURL;
					
					Crawler.downloadURL(feedURL, function(u:String, content:String, httpStatus:int):void {
						if (!content) {
							trace('!content2');
							callback(null);
							return;
						}
						
						var parser:Parser = Parser.getParser(content);
						func(parser);
					}, 'text', true);
				}
			}, 'text', true);
		}
		
		public function run():void
		{
			var queue:WorkingQueue = WorkingQueue.session();
			if (queue.working > 3)
				return;
			
			var feedFunc:FeedFunc = queue.shift();
			if (feedFunc == null) {
				trace('queue empty');
				return;
			}

			trace('runrun!!!!!!!', feedFunc.url);
			
			feedFunc.log('working queue pop');
			
			BlogEntry.getByURL(feedFunc.url, function(entry:BlogEntry):void {
				
				feedFunc.log('BlogEntry.getByURL');
				
				if (entry != null) {
					if (entry.link && feedFunc.url != entry.link && (!feedFunc.urlEndpoint || feedFunc.urlEndpoint != entry.link))
						feedFunc.setURLEndpoint(entry.link);
					feedFunc.success(entry, true);
					return WorkingQueue.session().finish(null);
				}
				
				var crawler:Crawler = new Crawler;
				crawler.start(feedFunc);
			}, true, null, feedFunc);
		}
		
		public static function getFeedURL(contentObj:Object, url:String):String
		{
			var m:Array;
			
			var content:String = '';
			if (contentObj is ByteArray && contentObj != null && ByteArray(contentObj).length >= 0) {
				content = ByteArray(contentObj).readUTFBytes(ByteArray(contentObj).length);
			}else if (contentObj is String && contentObj != null && String(contentObj).length >= 0) {
				content = contentObj as String;
			}
			
			if (url && url.match(/^http:\/\//)) {
				var host:String = URLUtil.getServerName( url );
				if (host) {
					m = host.match(/^([^\.]+)\.(.+)$/);
					if (m && m[1] && m[1] != 'www') {
						switch (m[2]) {
							case 'wordpress.com': return 'http://'+m[1]+'.wordpress.com/feed';
							case 'blogspot.com': return 'http://'+m[1]+'.blogspot.com/feeds/posts/default';
							case 'livejournal.com': return 'http://'+m[1]+'.livejournal.com/data/atom';
							case 'tumblr.com': return 'http://'+m[1]+'.tumblr.com/rss';
							case 'vox.com': return 'http://'+m[1]+'.vox.com/library/posts/atom.xml';
							case 'xanga.com': return 'http://'+m[1]+'.xanga.com/rss';
							case 'tistory.com': return 'http://'+m[1]+'.tistory.com/rss';
							case 'blogsome.com': return 'http://'+m[1]+'.blogsome.com/feed';
							case 'blogs.nytimes.com': return 'http://'+m[1]+'.blogs.nytimes.com/feed';
						}
					}
				}
				
				if (host && content.match(/id="tumblr_controls"/)) {	// tumblr
					return 'http://'+host+'/rss';
				}
			}
			
			if (!content || content.length <= 0) return null;
			
			var links:Array = content.match(/<link([^>]+)>/misg);
			if (links)
			{
				var feedURL:Array = new Array;
				for (var i:Number=0; i < links.length; i++)
				{
					var l:String = links[i].toString();
					if (!l.match(/rel=["']alternate["']/i)) continue;
					var type:Array = l.match(/type="([^"]+)"/i);
					if (!type || type.length <= 0 || !type[1] || !type[1].match(/atom|rss/)) continue;
					if (l.match(/\b((comment)|(comentarios)|(komm?entar))/i)) continue;	// exclude comment feed
					var match:Array = l.match(/href="([^"]+)"/i);
					if (match != null && match.length > 0) {
						feedURL.push(match[1]);
					}
				}
				
				if (feedURL.length > 0)
				{
					var host2:String = URLUtil.getServerName(url);
					var fURL:String;
					for (i=0; i < feedURL.length; i++)
					{
						if (!feedURL[i]) continue;
						fURL = feedURL[i].replace(/[\s\r\n]+/g, '');
						if (fURL.match(/^https?:\/\//i))
							return feedURL[i];
						else if (fURL.match(/^\//))
							return 'http://'+host2+(feedURL[i]);
					}
				}
			}
			
			return null;
		}

		public function addBlogEntry(e:BlogEntry, isUpdated:Boolean=false, subscribedBlog:Blog = null):void
		{
			if (!e || !e.blog || !e.blog.link) return;
			
			var b:Blog = null;
			if (subscribedBlog)
				b = subscribedBlog;
			else if (e.blog)
				b = feed.isSubscribed(e.blog.feedlink);

			if (!b)
				return;
			
			if (!b.entries) {
				b.entries = new StreamCollection;
				b.entries.uniqKey = 'link';
				//b.entries.setSort([['link', true, false]], true);
				b.entries.setSort([['published', true, false]]);
				b.entries.maxCount = 30;
			}
			
			var exists:Boolean = b.entries.isset('link', e.link);
			if (!exists || isUpdated) {
				if (!exists) {
					//trace('e.link', e.link);
					b.entries.addItem(e);
				}
			
				//check filter
				if (filterType == 1 || (filterType == 7 && filterLink == b.feedlink)) {
					Content.expect(e);
					stream.stream.addItem(StreamEntry.blog(e), isUpdated?NaN:1);
				}
			}
		}

		public function getHostContentFromServer(link:String, callback:Function, fail:Function, blogInfo:Object, isUpdated:Boolean=false):void
		{
			if (fail != null) fail();		// stand-alone version
			
			/*
			var val:URLVariables = new URLVariables;
			val.link = link;
			DataServer.request('TL', val.toString(), function(res:URLVariables):void {
				if (res == null) {
					if (fail != null)
						fail();
					return;
				}
				
				var i:Number = 1;
				var arr:Array = new Array;
				while (res['entry'+i+'[link]']) {
					var entry:BlogEntry = new BlogEntry;
					entry.id = -1;
					entry.link = URL.normalize(res['entry'+i+'[link]']);
					entry.title = res['entry'+i+'[title]'];
					entry.description = res['entry'+i+'[description]']?res['entry'+i+'[description]'].replace(/^\s+|\s+$/g, ''):'';
					entry.content = res['entry'+i+'[content]'];
					entry.published.setTime(res['entry'+i+'[published]']+'000');
					if (res['entry'+i+'[category]'] != null)
						entry.category = res['entry'+i+'[category]'].toString().split('	');
					entry.image = res['entry'+i+'[image]'];
					entry.video = res['entry'+i+'[video]'];
					entry.confirm = res['entry'+i+'[confirm]'] == 't'?true:false;
					entry.source = 'lf';
					entry.service = res['entry'+i+'[service]'];
					
					Content.expect(entry);
					
					if (isUpdated) {
						var b:Blog = feed.isSubscribed(blogInfo.feedlink);
						if (b) {
							entry.blog = b;
							//BlogEntry.register(entry);
							addBlogEntry(entry, isUpdated, b);
						}
					}
					
					arr.push(entry);
					i++;
				}
				
				if (arr.length > 0 ) {
					if (callback != null)
						callback({data:arr}, blogInfo);
				}else{
					if (fail != null)
						fail();
				}
			}, true);
			*/
		}
		
		public function getHostContentFromDB(link:String, callback:Function, blogInfo:Object):void
		{
			var sql:String = 'SELECT b.id as blog_id, e.* FROM p4_blog b JOIN p4_blog_entry_rel r on b.id=r.blog_id join p4_blog_entry e on r.entry_id=e.id WHERE b.link=:link ORDER BY e.published desc LIMIT 20';
			db.execute(sql, {':link':link}, function(event:SQLEvent):void {
				var stmt:SQLStatement = SQLStatement(event.target);
				var res:SQLResult = stmt.getResult();
				
				if (res == null || res.data == null || res.data.length <= 0) {
					if (callback != null)
						callback(null, blogInfo);
					return;
				}
				
				var arr:Array = new Array;
				for (var i:Number=0; i < res.data.length; i++) {
					var entry:BlogEntry = new BlogEntry;
					entry.id = -1;
					entry.link = URL.normalize(res.data[i]['link']);
					entry.title = res.data[i]['title'];
					entry.description = res.data[i]['description']?res.data[i]['description'].replace(/^\s+|\s+$/g, ''):'';
					entry.content = res.data[i]['content'];
					entry.published.setTime(res.data[i]['published']+'000');
					if (res.data[i]['category'] != null)
						entry.category = res.data[i]['category'].toString().split('	');
					entry.image = res.data[i]['image'];
					entry.video = res.data[i]['video'];
					entry.confirm = res.data[i]['confirm'] ==  't'?true:false;
					entry.source = res.data[i]['source'];
					entry.service = res.data[i]['service'];
					entry.local = true;
					
					Content.expect(entry);
					
					arr.push(entry);
				}
				
				if (callback != null) {
					callback({data:arr}, blogInfo);
				}
				
			}, function(event:SQLErrorEvent):void {
				if (callback != null)
					callback(null, blogInfo);
			});
		}
	}
}