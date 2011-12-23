package com.lazyscope.entry
{
	import com.lazyscope.DB;
	//import com.lazyscope.DataServer;
	import com.lazyscope.URL;
	import com.lazyscope.stream.StreamCollection;
	
	import flash.data.SQLResult;
	import flash.data.SQLStatement;
	import flash.events.SQLErrorEvent;
	import flash.events.SQLEvent;
	import flash.net.URLVariables;

	public class Blog
	{
		public static var postMethods:Object = {};
		
		public var id:Number;
		public var link:String;
		public var feedlink:String;
		public var title:String;
		public var description:String;
		public var profileimage:String;
		
		public var entries:StreamCollection;
		
		public var requested:Boolean = false;
		
		public function Blog(link:String=null, feedlink:String=null, title:String=null, description:String=null, profileimage:String=null)
		{
			this.id = -1;
			this.link = link;
			this.feedlink = feedlink;
			this.title = title;
			this.description = description;
			this.profileimage = profileimage;
		}
		
		public function toURLVariable():String
		{
			var k:Array = new Array('link', 'feedlink', 'title', 'description', 'profileimage');
			var param:URLVariables = new URLVariables;
			
			for (var i:Number=0; i < k.length; i++) {
				if (this[k[i]] == null) continue;
				param['blog['+(k[i])+']'] = this[k[i]];
			}
			
			return param.toString();
		}
		
		public function toString():String
		{
			return link;
			return 'Title: '+title+'\nLink: '+link+'\nFeed link: '+feedlink+'\nDescription: '+description+'\nProfile image: '+profileimage+'\n\n\n';
		}
		
		public static function getByURL(url:String, callback:Function, highPriority:Boolean = false):void
		{
			var db:DB = DB.session();
			
			/*
			var DSFunc:Function = function():void {
				DataServer.request('BG', url, function(vars:URLVariables=null):void {
					if (vars == null) {
						//if (true || vars == null) {		// Not to use information from server!!
						callback(null);
						return;
					}
					
					if (vars.link != null && vars.link != '') {
						var blog:Blog = new Blog(URL.normalize(vars.link), vars.feedlink, vars.title, vars.description, vars.profileimage);
						blog.id = -1;
					}else{
						//error
						callback(null);
						return;
					}
					
					register(blog, function(id:Number):void {
						blog.id = id;
						callback(blog);
					});
				}, highPriority);
			};
			*/
			
			var sql:String = "select * from p4_blog where link=:url or link=(select to_url from p4_redirect where from_url=:url)";
			db.fetch(sql, {':url':url}, function(event:SQLEvent):void {
				var stmt:SQLStatement = SQLStatement(event.target);
				var res:SQLResult = stmt.getResult();
				
				/*
				if (res == null || res.data == null || res.data.length <= 0) {
					//lazyscope request
					DSFunc();
				}else{
					var blog:Blog = new Blog(URL.normalize(res.data[0].link), res.data[0].feedlink, res.data[0].title, res.data[0].description, res.data[0].profileimage);
					blog.id = res.data[0].id;
					
					callback(blog);
				}
				*/
				
				// stand-alone
				var blog:Blog = new Blog(URL.normalize(res.data[0].link), res.data[0].feedlink, res.data[0].title, res.data[0].description, res.data[0].profileimage);
				blog.id = res.data[0].id;
				
				callback(blog);
				
			}, function(event:SQLErrorEvent):void {
				//DSFunc();
			});
		}
		
		public static function getBlogID(link:String, callback:Function):void
		{
			var db:DB = DB.session();
			
			db.fetch('SELECT id FROM p4_blog where link=:link', {':link':URL.normalize(link)}, function(event:SQLEvent):void {
				var stmt:SQLStatement = SQLStatement(event.target);
				var res:SQLResult = stmt.getResult();
				if (res == null || res.data == null || res.data.length <= 0)
					callback(-1);
				else
					callback(Number(res.data[0].id));
			}, function(event:SQLErrorEvent):void {
				//trace(event);
				callback(-1);
			});
		}
		
		public static function register(blog:Blog, callback:Function=null, force2DataServer:Boolean=false):void {
			var db:DB = DB.session();
			
			if (blog.link == null || blog.link.length <= 0) {
				if (callback != null)
					callback(-1);
				return;
			}
			
			db.fetch('INSERT INTO p4_blog (link, feedlink, title, description, profileimage) VALUES(:link, :feedlink, :title, :description, :profileimage)', {':link':URL.normalize(blog.link), ':feedlink':blog.feedlink, ':title':blog.title, ':description':blog.description, ':profileimage':blog.profileimage}, function(event:SQLEvent):void {
				var stmt:SQLStatement = SQLStatement(event.target);
				var res:SQLResult = stmt.getResult();
				if (res == null || res.lastInsertRowID < 0) {
					if (callback != null)
						callback(-1);
				}else{
					blog.id = res.lastInsertRowID;
					if (callback != null)
						callback(res.lastInsertRowID);
					
					/*
					if (force2DataServer) {
						// send to server
						var request:String = blog.toURLVariable();
						DataServer.request('TP', request, function():void {});
					}
					*/
				}
			}, function(event:SQLErrorEvent):void {
//trace('****** blog.link:', blog.link);
//trace('****** blog.feedlink:', blog.feedlink);
				//trace(event);
				if (callback != null)
					callback(-1);
			});
		}
		
		public static function postMethodResponse(res:URLVariables):void
		{
			if (!res) return;
			var i:Number = 0;
			
			while (res['blog'+i+'[link]']) {
				postMethods[res['blog'+i+'[link]']] = res['blog'+i+'[post_method]'];
				
				i++;
			}
		}
	}
}