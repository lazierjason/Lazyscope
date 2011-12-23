package com.lazyscope
{
	import flash.data.SQLConnection;
	import flash.data.SQLMode;
	import flash.data.SQLStatement;
	import flash.errors.SQLError;
	import flash.events.SQLErrorEvent;
	import flash.events.SQLEvent;
	import flash.events.SQLUpdateEvent;
	import flash.filesystem.File;
	import flash.net.Responder;
	
	public class DB extends SQLConnection
	{
		protected static var _session:DB = null;
		
		public var init:Boolean = false;
		private var queue:Array;
		public var working:Boolean = false;
		
		public static function session():DB
		{
			if (!DB._session)
				DB._session = new DB;
			return DB._session;
		}

		public static function ready():Boolean
		{
			return DB.session().init;
		}

		private var changes:Object = {'all':0};
		public function DB()
		{
			super();
			
			queue = new Array;
			
			var folder:File = File.applicationStorageDirectory; 
			var dbFile:File = folder.resolvePath('ls_v00.db');
			
			var responder:Responder = new Responder(function():void {
				//cacheSize = 200;
				execute('CREATE TABLE IF NOT EXISTS p4_fail_link(url text, url2 text, title text, time_register int, err text)', null, function(event:SQLEvent):void {
					execute('CREATE INDEX IF NOT EXISTS p4_fail_link_idx1 on p4_fail_link(time_register, url, url2)');
				});
				execute('CREATE TABLE IF NOT EXISTS p4_redirect(from_url text not null primary key, to_url text not null, time_register int)');
				execute('CREATE TABLE IF NOT EXISTS p4_blog(id integer not null primary key AUTOINCREMENT, link text not null unique, feedlink text, title text, description text, profileimage text, time_last_crawl int not null default 0, time_last_view int not null default 0, time_last_update int not null default 0, cnt_update int not null default 0)');
				execute('CREATE TABLE IF NOT EXISTS p4_subscribe(user int, feedlink text, primary key(user, feedlink))');
				execute('CREATE TABLE IF NOT EXISTS p4_blog_entry_read(id integer not null primary key, time_last_read int not null default 0)');
				execute('CREATE TABLE IF NOT EXISTS p4_ds_queue(id integer not null primary key, time_register int not null default 0, cmd varchar(2), req text)');
				execute('CREATE TABLE IF NOT EXISTS p4_readability(id integer not null primary key AUTOINCREMENT, link text not null unique, title text, description text, content text, image text, time_register int, host text)');
				execute('CREATE TABLE IF NOT EXISTS p4_blog_entry(id integer not null primary key autoincrement, published int not null default 0, link text not null unique, title text, description text, content text, category text, image text, video text, confirm int not null default 0, source varchar(10))', null, function(event:SQLEvent):void {
					execute('CREATE INDEX IF NOT EXISTS p4_blog_entry_idx1 on p4_blog_entry(id, published)');
				});
				execute('CREATE TABLE IF NOT EXISTS p4_blog_entry_rel(blog_id integer not null, entry_id integer not null, primary key(blog_id, entry_id))');
				init = true;
			});
			
			openAsync(dbFile, SQLMode.CREATE, responder, true, 4096);
			
			addEventListener(SQLUpdateEvent.INSERT, function(event:SQLUpdateEvent):void {
				if (!changes[event.table])
					changes[event.table] = 0;
				changes[event.table]++;
				//trace(event.table, changes[event.table]);
				if (changes[event.table] > 50) {
					changes[event.table] = 0;
					
					switch (event.table) {
						case 'p4_blog_entry':
							execute('DELETE FROM p4_blog_entry_rel WHERE entry_id IN (SELECT id FROM p4_blog_entry ORDER BY id DESC LIMIT 10000 OFFSET 500)');
							execute('DELETE FROM p4_blog_entry WHERE id IN (SELECT id FROM p4_blog_entry ORDER BY id DESC LIMIT 10000 OFFSET 500)', null, function(event:SQLEvent):void {
								trace('db analyze1');
								analyze('p4_blog_entry_rel');
								analyze('p4_blog_entry');
							});
							break;
						case 'p4_redirect':
							execute('DELETE FROM p4_redirect WHERE from_url IN (SELECT from_url FROM p4_redirect ORDER BY time_register DESC LIMIT 10000 OFFSET 1000)', null, function(event:SQLEvent):void {
								trace('db analyze2');
								analyze('p4_redirect');
							});
							break;
						case 'p4_readability':
							execute('DELETE FROM p4_readability WHERE id IN (SELECT id FROM p4_readability ORDER BY id DESC LIMIT 10000 OFFSET 1000)', null, function(event:SQLEvent):void {
								trace('db analyze3');
								analyze('p4_readability');
							});
							break;
					}
				}
			});
		}
		public function fetch(sql:String, param:Object=null, funcSuccess:Function=null, funcError:Function=null, highPriority:Boolean=false):void
		{
			this.execute(sql, param, funcSuccess, funcError, highPriority);
		}
		
		public function execute(sql:String, param:Object=null, funcSuccess:Function=null, funcError:Function=null, highPriority:Boolean=false):void
		{
			if (highPriority)
				this.queue.unshift([sql, param, funcSuccess, funcError]);
			else
				this.queue.push([sql, param, funcSuccess, funcError]);
			this.run();
		}
		
		private function run():void
		{
			if (!this.working) {
				var q:Array = this.queue.shift();
				if (q != null) {
					this.working=true;
					_execute(q[0], q[1], q[2], q[3]);
				}
			}
		}
		
		private function _execute(sql:String, param:Object=null, funcSuccess:Function=null, funcError:Function=null):void
		{
/*
			if (funcError != null)
				funcError(new SQLErrorEvent(SQLErrorEvent.ERROR));
			
			working = false;
			run();

			return;
//*/
			var stmt:SQLStatement = new SQLStatement;
			stmt.sqlConnection = this;
			stmt.text = sql;
			
			//trace(sql);
			
			var fc:Function = function(event:SQLEvent):void {
				stmt.removeEventListener(SQLEvent.RESULT, fc);
				stmt.removeEventListener(SQLErrorEvent.ERROR, fe);
				
				if (funcSuccess != null)
					funcSuccess(event);
				working = false;
				run();
			};
			
			var fe:Function = function(event:SQLErrorEvent):void {
				stmt.removeEventListener(SQLEvent.RESULT, fc);
				stmt.removeEventListener(SQLErrorEvent.ERROR, fe);
				
				//trace(event);
				if (funcError != null)
					funcError(event);
				working = false;
				run();
			};
			
			stmt.addEventListener(SQLEvent.RESULT, fc);
			stmt.addEventListener(SQLErrorEvent.ERROR, fe);
			
			//trace(sql);
			if (param != null) {
				for (var k:String in param) {
					stmt.parameters[k] = param[k];
					//trace('stmt', k, param[k]);
				}
			}
			
			try{
				stmt.execute();
			}catch(error:SQLError) {
				trace(error.getStackTrace(), '_execute');
				if (funcError != null)
					funcError(null);
				working = false;
				run();
			}
		}
	}
}