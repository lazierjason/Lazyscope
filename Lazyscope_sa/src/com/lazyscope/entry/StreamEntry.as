package com.lazyscope.entry
{
	import com.lazyscope.Base;
	import com.lazyscope.CachedImage;
	import com.lazyscope.stream.StreamItemRenderer;
	import com.lazyscope.stream.StreamItemRendererBlogInTwitter;
	import com.swfjunkie.tweetr.data.objects.DirectMessageData;
	import com.swfjunkie.tweetr.data.objects.StatusData;
	
	import flash.events.Event;
	import flash.utils.clearTimeout;
	import flash.utils.setTimeout;
	
	import spark.components.Group;
	import spark.components.VGroup;

	public class StreamEntry extends BlogEntry
	{
		public var sid:String;
		public var time_register:String;
		public var type:String;
		public var twitStatus:StatusData = null;
		public var twitMsg:DirectMessageData = null;
		public var twitMsgIsSent:Boolean = false;
		
		public var isUpdated:Boolean = false;
		
		public var child:VGroup = null;
		public var childRequesting:Boolean = false;
		public var renderer:StreamItemRenderer = null;
		
		public var sortk1:Number = -1;
		public var sortk2:Number = -1;
		
		public var linkID:Number = 0;

		public var imageElement:CachedImage = null;
		
		public var _todoLinkCount:Number = NaN;
		private var _cleanup:Boolean = false;
		
		override public function destroy():void
		{
			if (_cleanup) return;
			_cleanup = true;
			
			if (imageElement != null) {
				try{
					if (imageElement.parent)
						Group(imageElement.parent).removeElement(imageElement);
				}catch(e:Error) {
					//trace(e.getStackTrace(), 'cleanup1', type, link);
				}
				imageElement.source = null;
				imageElement = null;
			}
			try{
				if (child != null && child.numElements > 0) {
					for (var p:Number=0; p < child.numElements; p++) {
						var child:StreamItemRenderer = child.getElementAt(p) as StreamItemRenderer;
						if (child && child is StreamItemRenderer && child.data && child.data is StreamEntry) {
							var se2:StreamEntry = child.data as StreamEntry;
							se2.destroy();
						}
					}
					child.removeAllElements();
				}
			}catch(e:Error) {
				//trace(e.getStackTrace(), 'cleanup2', type, link);
			}
			child = null;
			if (renderer != null) {
				try{
					renderer.imageCandidates = null;
					if (renderer.spinners && renderer.spinners.numElements > 0)
						renderer.spinners.removeAllElements();
					if (renderer.data && renderer.data == null)
						renderer.data = null;
					renderer = null;
				}catch(e:Error) {
					//trace(e.getStackTrace(), 'cleanup3', type, link);
				}
			}
			//if (twitStatus) twitStatus.destroy();
			twitStatus = null;
			//if (twitMsg) twitMsg.destroy();
			twitMsg = null;
			
			super.destroy();
		}
		
		/*
		public static function cleanup(obj:StreamEntry):void
		{
			obj.twitStatus = null;
			obj.twitMsg = null;
			obj.imageElement = null;
			
			if (obj.child && obj.child.numElements > 0) {
				for (var i:Number=obj.child.numElements; i--;) {
					try{
						var o:Object = obj.child.getElementAt(i);
						o.data = null;
					}catch(err:Error){
						trace(err.getStackTrace());
					}
				}
				obj.child.removeAllElements();
			}
			
			obj.renderer = null;
			
			BlogEntry.cleanup(obj);
		}
		
		private var _clearTimer:uint;
		public function cancelClear(event:Event=null):void
		{
			//trace('cancelclear', imageElement, imageElement?imageElement.url:'');
			clearTimeout(_clearTimer);
		}
		
		public function clear(event:Event):void
		{
			clearTimeout(_clearTimer);
			//trace('clear', imageElement, imageElement?imageElement.url:'');
			_clearTimer = setTimeout(_clear, 100);
		}
		
		private function _clear():void
		{
			clearTimeout(_clearTimer);
			if (imageElement) {
				//trace('_clear', imageElement, imageElement.url);
				imageElement = null;
			}
		}
		*/
		
		public function StreamEntry()
		{
			super();
		}
		
		public static function twitter(status:StatusData, time_register:String=null):StreamEntry
		{
			if (!status || status.published <= 0) return null;
			var e:StreamEntry = new StreamEntry;
			
			e.sid = status.id + '1';
			e.type = 'T';
			e.time_register = time_register?time_register:'';
			e.twitStatus = status;
			e.published.setTime(status.published);
			
			return e;
		}
		
		public static function twitterMsg(msg:DirectMessageData, time_register:String=null):StreamEntry
		{
			if (!msg || msg.published <= 0) return null;
			var e:StreamEntry = new StreamEntry;
			
			e.sid = msg.id + '2';
			e.type = 'M';
			e.time_register = time_register?time_register:'';
			e.twitMsg = msg;
			e.published.setTime(msg.published);
			e.twitMsgIsSent = msg.senderId == Number(Base.twitter.userid);
			
			return e;
		}
		
		public static function blog(entry:BlogEntry, time_register:String=null):StreamEntry
		{
			if (!entry) return null;
			
			var e:StreamEntry = new StreamEntry;
			
			for (var i:Number=0; i < BlogEntry.keys.length; i++) {
				e[BlogEntry.keys[i]] = entry[BlogEntry.keys[i]];
			}
			
			e.sid = e.link;
			e.type = 'B';
			e.time_register = time_register?time_register:'';
			
			return e;
		}
		
		public static function favoriteLink(entry:FavoriteLink, time_register:String=null):StreamEntry
		{
			if (!entry) return null;
			
			var e:StreamEntry = new StreamEntry;
			
			for (var i:Number=0; i < FavoriteLink.keys.length; i++) {
				e[FavoriteLink.keys[i]] = entry[FavoriteLink.keys[i]];
			}
			
			e.sid = 'FL'+(e.link);
			e.type = 'FL';
			e.published.setTime(entry.published.getTime());
			e.time_register = time_register?time_register:'';
			
			return e;
		}
		
		override public function toString():String
		{
			return twitStatus?twitStatus.text:(twitMsg?twitMsg.text:link);
		}
	}
}