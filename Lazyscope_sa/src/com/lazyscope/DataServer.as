package com.lazyscope
{
	import flash.data.SQLResult;
	import flash.data.SQLStatement;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SQLErrorEvent;
	import flash.events.SQLEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.Socket;
	import flash.net.URLVariables;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	import flash.utils.clearTimeout;
	import flash.utils.setTimeout;
	
	public class DataServer
	{
		public static var _session:Array = new Array(new DataServer, new DataServer);
		public static var queue:Array = new Array;
		protected static var queueTimer:uint;
		
		protected var conn:Socket;
		
		private var id:Number = Math.random();
		
		private var seq:Number = 0;
		private var lastReq:ByteArray = null;
		private var lastReqCallback:Function;
		
		private var bufLen:Number = -1;
		private var buf:ByteArray;
		private var bt:Number;
		
		public var working:Number = -1;
		
		private var connectTimer:uint;
		private var retryTimer:uint;
		
		public function DataServer()
		{
			conn = new Socket;
			
			conn.timeout = 5000;
			
			conn.addEventListener(Event.CLOSE, closeHandler, false, 0, true);
			conn.addEventListener(Event.CONNECT, connectHandler, false, 0, true);
			conn.addEventListener(IOErrorEvent.IO_ERROR, errorHandler, false, 0, true);
			conn.addEventListener(SecurityErrorEvent.SECURITY_ERROR, errorHandler, false, 0, true);
			conn.addEventListener(ProgressEvent.SOCKET_DATA, socketDataHandler, false, 0, true);
			
			buf = new ByteArray;
			
			//setTimeout(connect, 3000);
			connect();
			
			if (!queueTimer)
				queueTimer = setTimeout(requestQueueProc, 1000);
		}
		

		public function __request():void
		{
			if (!conn.connected) {
				return;
			}
			
			if (lastReq == null || lastReq.length <= 0) {
				working = -1;
				run();
				return;
			}

			bufLen = -1;
			buf.clear();
			
			lastReq.position = 0;
			conn.writeBytes(lastReq);
			conn.flush();
			
			checkRetry();
//			trace('dataserver '+id+' sent', seq, lastReq.toString());
			bt = new Date().getTime();
		}

		public function checkConnectRetry():void
		{
			clearTimeout(connectTimer);
			connectTimer = setTimeout(reconnect, 10000);
		}
		
		public function checkRetry():void
		{
			clearTimeout(retryTimer);
			retryTimer = setTimeout(_checkRetry, 10000);
		}
		
		public function _checkRetry():void
		{
			var now:Number = new Date().getTime();
			if (working > 0 && working < now - 10000) {
				trace('ds timeout!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');
				reconnect();
			}
		}
		
		public function socketDataHandler(event:Event=null):void
		{
			checkRetry();
//			trace(id, this.seq, conn.bytesAvailable, bufLen);
			if (bufLen < 0)
			{
				if (conn.bytesAvailable < 8)
					return;
				
				bufLen = conn.readUnsignedInt();
				var seq:Number = conn.readUnsignedInt();
				if (bufLen <= 0 || bufLen > 1024*1024*8 || seq != this.seq)
				{
					//reset and re-request
//					trace(id, 'reset and re-request', bufLen, seq, this.seq);
					reconnect();
					return;
				}
			}
//			trace(id, this.seq, conn.bytesAvailable, bufLen);
			
			if (conn.bytesAvailable <= 0)
				return;
			
			var tmp:ByteArray = new ByteArray;
			conn.readBytes(tmp);
			buf.writeBytes(tmp);
			
			if (buf.length >= bufLen) {
				clearTimeout(retryTimer);
				
				buf.inflate();
//				trace('dataserver '+id+' recv '+(new Date().getTime()-bt));
				
				var res:String = buf.readUTFBytes(buf.length);
				buf.clear();
//				trace(id, this.seq, res.substr(0, 100));
				if (res != 'Error') {
					var vars:URLVariables = new URLVariables;
					if (res == 'OK') {
						vars.OK = 't';
					}else{
						try{
							vars.decode(res);
						}catch(e:Error) {
							trace(e.getStackTrace(), 'socketDataHandler');
							vars = null;
						}
					}
					
					if (lastReqCallback != null) {
						lastReqCallback(vars);
					}
				}else{
					if (lastReqCallback != null) {
						lastReqCallback(null);
					}
				}
				working = -1;
				lastReq = null;
				lastReqCallback = null;
				
				run();
			}
		}
		
		public function errorHandler(event:Event=null):void
		{
//			trace(id, event);
			
			working = -1;
			if (lastReqCallback != null) {
				lastReqCallback(null);
			}
			lastReq = null;
			lastReqCallback = null;
			
			reconnect();
			run();
		}
		
		public function connectHandler(event:Event=null):void
		{
//			trace(id, 'connectHandler');
			clearTimeout(connectTimer);
			
			if (working > 0 && lastReq != null && lastReq.length > 0) {
				__request();
			}else
				run();
		}
		
		public function closeHandler(event:Event=null):void
		{
//			trace(id, 'closeHandler');
			
			reconnect();
		}
		
		public function connect():void
		{
//			trace(id, 'connect');
			checkConnectRetry();
			conn.connect('ds.lazyscope.com', 29115);
		}
		
		public var reconnectTimer:uint;
		public function reconnect():void
		{
			clearTimeout(connectTimer);
			trace('reconnect requested');
			
			try{
				conn.close();
			}catch(e:Error) {
				trace(e.getStackTrace(), 'reconnect');
			}
			
			clearTimeout(reconnectTimer);
			reconnectTimer = setTimeout(connect, 500);
		}
		
		
		public static function request(cmd:String, request:String, callback:Function = null, highPriority:Boolean = false, noTimeout:Boolean = false):void
		{
			/*
			if (!connected) {
			setTimeout(this.request, 100, cmd, request, callback, highPriority);
			return;
			}
			*/
			
			var gz:ByteArray = new ByteArray;
			gz.writeUTFBytes(request);
			gz.deflate();
			
			var s:Number = uint(Math.random()*10000000);
			
			var q:ByteArray = new ByteArray;
			
			//trace('req', cmd, request);
			q.endian = Endian.BIG_ENDIAN;
			q.writeUnsignedInt(gz.length);
			q.writeUnsignedInt(s);
			q.writeUTFBytes(cmd);
			q.writeBytes(gz);
			q.position = 0;
			
//			trace(s, q.length, cmd, request?request.substr(0, 100):'');
			
			if (highPriority == true)
				queue.unshift([s, q, callback, noTimeout]);
			else
				queue.push([s, q, callback, noTimeout]);
			
			run();
		}
		
		public static function run():void
		{
			var ds:DataServer = null;
			
			for (var i:Number=_session.length; i--;) {
				if (DataServer(_session[i]).conn.connected && DataServer(_session[i]).working < 0) {
					//trace('DataServer(_session[i])', i);
					ds = DataServer(_session[i]);
					break;
				}
			}
			
			var q:Array;
			if (!ds)
				return;
			
			q=queue.shift();
			if (!q)
				return;
			
//			trace(q[0], q[1], q[2]);
			
			ds.working = new Date().getTime() + (q[3]?1000*1000:0);
			
			ds.seq = q[0];
			ds.lastReq = q[1];
			ds.lastReqCallback = q[2];
			
			ds.__request();
		}
		
		public static function requestQueuePush(cmd:String, req:String):void
		{
			var sql:String = 'INSERT INTO p4_ds_queue (time_register, cmd, req) VALUES(:time, :cmd, :req)';
			DB.session().execute(sql, {
				':time': new Date().getTime(),
				':cmd': cmd,
				':req': req
			}, null, null, true);
			
			requestQueueProc();
		}
		
		public static var requestQueueWorking:Boolean = false;
		public static function requestQueueProc():void
		{
			clearTimeout(queueTimer);
			queueTimer = setTimeout(requestQueueProc, 1000);
			
			if (!DB.ready()) {
				return;
			}
			if (requestQueueWorking) return;
			requestQueueWorking = true;

			var sql:String = 'SELECT * FROM p4_ds_queue ORDER BY time_register LIMIT 1';
			var db:DB = DB.session();
			
			db.execute(sql, null, _requestQueueProcSuccess, _requestQueueProcFail);
		}
		
		private static function _requestQueueProcSuccess(event:SQLEvent):void
		{
			var stmt:SQLStatement = SQLStatement(event.target);
			var res:SQLResult = stmt.getResult();
			if (res == null || res.data == null || res.data.length <= 0) {
				requestQueueWorking = false;
				return;
			}
			request(res.data[0].cmd, res.data[0].req, function(result:Object):void {
				var sql:String = 'DELETE FROM p4_ds_queue WHERE id='+(res.data[0].id);
				var db:DB = DB.session();
				db.execute(sql, null, null, null, true);
				requestQueueWorking = false;
				setTimeout(requestQueueProc, 10);
			}, true);
		}
		
		private static function _requestQueueProcFail(event:SQLErrorEvent):void
		{
			requestQueueWorking = false;
		}
	}
}


