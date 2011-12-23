package com.lazyscope.entry
{
	import com.lazyscope.DB;
	//import com.lazyscope.DataServer;
	import com.lazyscope.URL;
	import com.lazyscope.content.Readability;
	import com.lazyscope.content.ReadabilityPattern;
	import com.lazyscope.crawl.FeedFunc;
	
	import flash.data.SQLResult;
	import flash.data.SQLStatement;
	import flash.events.SQLErrorEvent;
	import flash.events.SQLEvent;
	import flash.net.URLVariables;
	
	import mx.containers.VBox;
	import mx.core.UIComponent;
	
	
	public class BlogEntry
	{
		public static var keys:Array = new Array(
			'blog', 'id', 'noRegister', 'link', 'title', 'description', 'published', 'category', 'image', 'video', 'confirm',
			'source', 'service', 'local', 'content', 'displayDescription', 'displayContent'
		);
		
		public var blog:Blog = null;
		
		public var id:Number = 0;
		
		public var noRegister:Boolean = false;
		
		public var link:String;
		public var title:String;
		public var description:String;
		public var _published:Date;
		public var category:Array;
		public var image:String;
		public var video:String;
		public var confirm:Boolean;
		public var source:String;
		public var service:String;
		public var local:Boolean = true;
		public var content:String;
		
		public var displayDescription:UIComponent;
		public var displayContent:String;

		public function destroy():void
		{
			blog = null;
			displayDescription = null;
			displayContent = null;
			published = null;
			category = null;
		}
		
		public function set published(value:Date):void
		{
			_published = value;
			if (!_published) {
				_published = new Date();
				_published.setTime(0);
			}else if (_published.getTime() <= 0)
				_published.setTime(0);
		}
		
		public function get published():Date
		{
			return _published;
		}
		
		public function BlogEntry()
		{
			this._published = new Date;
			this.category = new Array;
		}
		
		public function toURLVariable():String
		{
			var k:Array = new Array('published', 'link', 'title', 'description', 'content', 'category', 'image', 'video');
			var param:URLVariables = new URLVariables;
			
			for (var i:Number=0; i < k.length; i++) {
				if (this[k[i]] == null) continue;
				switch (k[i]) {
					case 'published':
						param['entry[time_published]'] = this.published ? Math.floor(this.published.getTime()/1000) : 0;
						if (isNaN(param['entry[time_published]']))
							param['entry[time_published]']=-1;
						break;
					case 'category':
						param['entry[category]'] = this.category.join('	');
						break;
					default:
						param['entry['+(k[i])+']'] = String(this[k[i]]);
						break;
				}
			}
			
			return param.toString();
		}
		
		public function toString():String
		{
			return link;
			return 'Title: '+title+'\nLink: '+link+'\nPubdate: '+published+'\nCategory: '+category.join(', ')+'\nDescription: '+description+'\nContent: '+content+'\nSource: '+source+'\nLocal: '+local+'\n\n';
		}
		
		public static function returnByURL(callback:Function, entry:BlogEntry):void
		{
			var url:String = entry.blog?entry.blog.link:entry.link;
			if (ReadabilityPattern.match(url))
				runPostMethod('RDBT', entry, callback);
			else if (Blog.postMethods[url])
				runPostMethod(Blog.postMethods[url], entry, callback);
			else
				callback(entry);
		}
		
		public static function getByURLFromRDBT(url:String, callback:Function, entry:BlogEntry=null, highPriority:Boolean = false, ff:FeedFunc=null):void
		{
			var db:DB = DB.session();
			
			var sql:String = 'select * from p4_readability where link=:url or link=(select to_url from p4_redirect where from_url=:url)';
			db.fetch(sql, {':url':url}, function(event:SQLEvent):void {
				if (ff) ff.log('getByURL - RDDB');
				var stmt:SQLStatement = SQLStatement(event.target);
				var res:SQLResult = stmt.getResult();
				
				if (res == null || res.data == null || res.data.length <= 0) {
					callback(null);
					return;
				}
				
				if (!entry) entry = new BlogEntry;
				
				entry.link = res.data[0].link ? res.data[0].link.replace(/^\s+/, '').replace(/\s+$/, '') : '';
				entry.title = entry.title && entry.title != ''?entry.title:res.data[0].title;
				entry.description = res.data[0].description?res.data[0].description.replace(/^\s+|\s+$/g, ''):'';
				entry.content = res.data[0].content;
				entry.published.setTime(-1);
				
				entry.image = entry.image ? entry.image.replace(/^\s+/, '').replace(/\s+$/, '') : '';
				entry.image = entry.image && entry.image != '' ? entry.image : (res.data[0].image ? res.data[0].image.replace(/^\s+/, '').replace(/\s+$/, '') : '');
				entry.source = 'readability';
				
				entry.local = true;
				
				if (res.data[0].host && res.data[0].host != '') {
					Blog.getByURL(res.data[0].host, function(b:Blog):void {
						if (b)
							entry.blog = b;
						callback(entry);
					});
				}else
					callback(entry);
			}, function(event:SQLErrorEvent):void {
				callback(null);
			}, highPriority);
		}
		
		public static function getByURL(url:String, callback:Function, highPriority:Boolean = false, urlEndPoint:String = null, ff:FeedFunc = null):void
		{
			var db:DB = DB.session();
			
			if (!url || url.length <= 0) {
				callback(null);
				return;
			}
			
			var DSFunc:Function = function():void {
				
				// stand-alone
				getByURLFromRDBT(url, callback, null, highPriority, ff);
				
				/*
				DataServer.request('TG', url+(urlEndPoint != null?'	#&#&#	'+urlEndPoint:''), function(vars:URLVariables=null):void {
					if (ff) ff.log('getByURL - DS');
					if (vars == null || vars.confirm == 'f') {
						//if (true || vars == null) {		// Not to use information from server!!
						getByURLFromRDBT(url, callback, null, highPriority, ff);
						//callback(null);
						return;
					}
					
					var entry:BlogEntry = new BlogEntry;
					
					if (vars.blog_link != null && vars.blog_link != '') {
						entry.blog = new Blog(URL.normalize(vars.blog_link), vars.blog_feedlink, vars.blog_title, vars.blog_description, vars.blog_profileimage);
						entry.blog.id = -1;
					}else{
						//TODO: dummy parent
						entry.blog = new Blog;
					}
					
					entry.id = -1;
					entry.link = URL.normalize(vars.link);
					entry.title = vars.title;
					entry.description = vars.description;
					entry.content = vars.content;
					entry.published = new Date;
					entry.published.setTime(Number(vars.published)*1000);
					if (vars.category != null)
						entry.category = vars.category.toString().split('	');
					entry.image = vars.image;
					entry.video = vars.video;
					entry.confirm = vars.confirm == 't'?true:false;
					entry.source = (vars.is_readability && vars.is_readability == 't')?'readability':'lf';
					entry.local = false;
					entry.service = vars.service;
					
					register(entry, function(id:Number):void {
						if (entry.source == 'readability' && vars.host) {
							Blog.getByURL(vars.host, function(b:Blog):void {
								if (b)
									entry.blog = b;
								returnByURL(callback, entry);
							});
						}else
							returnByURL(callback, entry);
					});
				}, highPriority);
				*/
			};
			
			var sql:String = "select b.id as blog_id, b.link as blog_link, b.feedlink as blog_feedlink, b.title as blog_title, b.description as blog_description, b.profileimage as blog_profileimage, e.* from p4_blog_entry e left join p4_blog_entry_rel r on e.id=r.entry_id left join p4_blog b on r.blog_id=b.id where e.link=:url or e.link=(select to_url from p4_redirect where from_url=:url)";
			db.fetch(sql, {':url':url}, function(event:SQLEvent):void {
				if (ff) ff.log('getByURL - DB');
				var stmt:SQLStatement = SQLStatement(event.target);
				var res:SQLResult = stmt.getResult();
				
				if (res == null || res.data == null || res.data.length <= 0) {
					//lazyscope request
					DSFunc();
				}else{
					var entry:BlogEntry = new BlogEntry;
					
					if (res.data[0].blog_link != null && res.data[0].blog_link != '') {
						entry.blog = new Blog(URL.normalize(res.data[0].blog_link), res.data[0].blog_feedlink, res.data[0].blog_title, res.data[0].blog_description, res.data[0].blog_profileimage);
						entry.blog.id = res.data[0].blog_id;
					}else{
						//TODO: dummy parent
						entry.blog = new Blog;
					}
					
					entry.id = res.data[0].id;
					entry.link = res.data[0].link;
					entry.title = res.data[0].title;
					entry.description = res.data[0].description;
					entry.content = res.data[0].content;
					entry.published = new Date;
					entry.published.setTime(Number(res.data[0].published)*1000);
					if (res.data[0].category != null)
						entry.category = res.data[0].category.toString().split('	');
					entry.image = res.data[0].image;
					entry.video = res.data[0].video;
					entry.confirm = res.data[0].confirm == 't'?true:false;
					entry.source = res.data[0].source;
					entry.service = 'blog';		// TODO: give a correct service type!
					
					entry.local = true;
					
					returnByURL(callback, entry);
					//callback(entry);
				}
			}, function(event:SQLErrorEvent):void {
				DSFunc();
			}, highPriority);
		}

		public static function runPostMethod(postMethod:String, entry:BlogEntry, callback:Function=null):void
		{
			switch (postMethod) {
				case 'RDBT':	//readability
					if (entry.source == 'readability') {
						if (callback != null)
							callback(entry);
					}else{
						getByURLFromRDBT(entry.link, function(e:BlogEntry):void {
							if (e) {
								//trace(entry.blog);
								if (callback != null)
									callback(e);
							}else{
								//trace(entry.blog);
								var r:Readability = new Readability(entry.link);
								r.analyze(callback, entry);
							}
						}, entry);
					}
					break;
				default:
					if (callback != null)
						callback(entry);
					break;
			}
		}

		public static function register(entry:BlogEntry, callback:Function=null):void
		{
			if (!entry.blog) {
				if (callback != null)
					callback(entry.id > 0?entry.id:-1);
				return;
			}
			if (entry.blog.id > 0) {
				BlogEntry.registerEntry(entry, callback);
			}else{
				if (entry.blog.link) {
					// register blog
					Blog.register(entry.blog, function(blogId:Number):void {
						if (blogId > 0) {
							entry.blog.id = blogId;
							BlogEntry.registerEntry(entry, callback);
						}else{
							Blog.getBlogID(entry.blog.link, function(blogId:Number):void {
								if (blogId > 0) {
									// register blog entry
									entry.blog.id = blogId;
									BlogEntry.registerEntry(entry, callback);
								}else{
									if (callback != null)
										callback(entry.id > 0?entry.id:-1);
								}
							});
						}
					});
				}else{
					if (callback != null)
						callback(entry.id > 0?entry.id:-1);
				}
			}
		}
		
		public static function getEntryID(link:String, callback:Function):void
		{
			var db:DB = DB.session();
			
			db.fetch('SELECT id FROM p4_blog_entry where link=:link', {':link':link}, function(event:SQLEvent):void {
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
		
		public static function registerEntry(entry:BlogEntry, callback:Function=null):void
		{
			if (entry.id > 0) {
				if (callback != null)
					callback(entry.id);
				return;
			}
			
			if (entry.noRegister || !entry.confirm) {
				if (callback != null) callback(-1);
				return;
			}
			
			var db:DB = DB.session();
			
			var sql:String = 'INSERT INTO p4_blog_entry(link, title, description, content, published, category, image, video, confirm, source) VALUES(:link, :title, :description, :content, :published, :category, :image, :video, :confirm, :source)';
			var param:Object={
				':link': entry.link,
					':title': entry.title,
					':description': entry.description,
					':content': entry.content,
					':published': entry.published ? Math.floor(entry.published.getTime()/1000) : 0,
					':category': entry.category.length > 0?entry.category.join('	'):null,
					':image': entry.image,
					':video': entry.video,
					':confirm': entry.confirm == true?1:0,
					':source': entry.source
			};
			if (!param[':published'] || param[':published'] > new Date().getTime()/1000)
				param[':published']=Math.floor(new Date().getTime()/1000);
			
			db.fetch(sql, param, function(event:SQLEvent):void {
				var stmt:SQLStatement = SQLStatement(event.target);
				var res:SQLResult = stmt.getResult();
				if (res == null || res.lastInsertRowID < 0) {
					//trace('blog entry insert fail??');
					BlogEntry.getEntryID(entry.link, function(id:Number):void {
						entry.id = id;
						if (callback != null)
							callback(id);
					});
				}else{
					//trace('blog entry insert success');
					entry.id = res.lastInsertRowID;
					if (callback != null)
						callback(res.lastInsertRowID);
					
					if (entry.blog != null && entry.blog.id > 0)
						db.execute('insert into p4_blog_entry_rel(blog_id, entry_id) values('+entry.blog.id+', '+entry.id+')');
					
					/*
					// sync to memory db
					if (Stream.session().streamType == 'all' || (Stream.session().streamType == 'blog' && Stream.session().streamBid == entry.blog.id)) {
					var time:Number=(new Date().getTime())-500;
					db.execute('insert into p4_stream(sid, published, time_register, type, entry_id) select e.id*10+2, e.published*1000, '+time+', \'B\', e.id from p4_subscribe b join p4_blog_entry_rel r on b.blog_id=r.blog_id join p4_blog_entry e on r.entry_id=e.id where b.user='+(Stream.session().twitter.userid)+' and e.id='+entry.id+' limit 1');
					}
					*/
					
					// send to server
					//sendToServer(entry);
				}
			}, function(event:SQLErrorEvent):void {
				//trace(event);
				BlogEntry.getEntryID(entry.link, function(id:Number):void {
					entry.id = id;
					if (callback != null)
						callback(id);
				});
			});
		}
		
		public static function sendToServer(e:BlogEntry):void
		{
			if (!e || !e.blog) return;
			/*
			var request:String = (e.blog == null?'':e.blog.toURLVariable())+'&'+e.toURLVariable();
			DataServer.request('TP', request, function():void {});
			*/
		}
	}
}