package com.lazyscope
{
	import flash.data.SQLConnection;
	import flash.data.SQLMode;
	import flash.data.SQLResult;
	import flash.data.SQLStatement;
	import flash.desktop.NativeApplication;
	import flash.errors.SQLError;
	import flash.filesystem.File;
	import flash.utils.ByteArray;
	
	public class ConfigDB extends SQLConnection
	{
		protected static var _session:ConfigDB = null;
		
		public var init:Boolean = false;
		private var queue:Array;
		public var working:Boolean = false;
		
		public static function session():ConfigDB
		{
			if (!ConfigDB._session)
				ConfigDB._session = new ConfigDB;
			return ConfigDB._session;
		}
		
		public static function init():void
		{
			var tmp:ConfigDB = ConfigDB.session();
		}
		
		public static function get(k:String):String
		{
			var stmt:SQLStatement = ConfigDB.session().execute('select v from configs where k=:k', {':k':k});
			if (!stmt) return null;
			var res:SQLResult = stmt.getResult();
			return res && res.data && res.data[0]?res.data[0].v:null;
		}
		
		public static function set(k:String, v:String):void
		{
			ConfigDB.session().execute('replace into configs (k, v) values(:k, :v)', {':k':k, ':v':v});
		}
		
		public static function remove(k:String):void
		{
			ConfigDB.session().execute('delete from configs where k=:k', {':k':k});
		}
		
		public function execute(sql:String, param:Object=null):SQLStatement
		{
			var stmt:SQLStatement = new SQLStatement;
			stmt.sqlConnection = this;
			stmt.text = sql;
			
			if (param != null) {
				for (var k:String in param) {
					stmt.parameters[k] = param[k];
					//trace('stmt', k, param[k]);
				}
			}
			
			try{
				stmt.execute();
			}catch(error:SQLError) {
				trace(error.getStackTrace(), 'execute');
				return null;
			}
			return stmt;
		}
		
		public function ConfigDB()
		{
			super();
			
			_session = this;
			
			var folder:File = File.applicationStorageDirectory; 
			var dbFile:File = folder.resolvePath('config_v0.db');
			
			if (!dbFile.exists) {
				try{
					NativeApplication.nativeApplication.startAtLogin = true;
				}catch(e:Error) {
					trace(e.getStackTrace(), 'ConfigDB');
				}
			}
			
			var enc:ByteArray = new ByteArray;
			enc.writeMultiByte('LazierJasonScope', 'UTF-8');		// 16 chars
			
			open(dbFile, SQLMode.CREATE, false, 1024, enc);
			
			execute('CREATE TABLE IF NOT EXISTS configs(k text primary key, v text)');
		}
	}
}