package com.lazyscope.twitter
{
	[Event(name="directMessage", type="com.lazyscope.twitter.TwitterStreamEvent")]
	[Event(name="status", type="com.lazyscope.twitter.TwitterStreamEvent")]
	[Event(name="favorite", type="com.lazyscope.twitter.TwitterStreamEvent")]
	[Event(name="mention", type="com.lazyscope.twitter.TwitterStreamEvent")]

	import air.net.SocketMonitor;
	
	import com.adobe.serialization.json.JSON;
	import com.lazyscope.Base;
	import com.lazyscope.Util;
	import com.lazyscope.stream.StreamCollection;
	import com.swfjunkie.tweetr.data.objects.DirectMessageData;
	import com.swfjunkie.tweetr.data.objects.ExtendedUserData;
	import com.swfjunkie.tweetr.data.objects.ListData;
	import com.swfjunkie.tweetr.data.objects.StatusData;
	import com.swfjunkie.tweetr.data.objects.UserData;
	import com.swfjunkie.tweetr.oauth.OAuth;
	import com.swfjunkie.tweetr.utils.TweetUtil;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.HTTPStatusEvent;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.events.StatusEvent;
	import flash.net.URLRequest;
	import flash.net.URLRequestHeader;
	import flash.net.URLStream;
	import flash.net.URLVariables;
	import flash.utils.clearTimeout;
	import flash.utils.setTimeout;
	
	import mx.collections.ArrayList;
	import mx.events.CollectionEvent;
	import mx.events.CollectionEventKind;
	
	public class TwitterStream extends EventDispatcher
	{
		private var sock:URLStream;
		private var _oauth:OAuth;
		private var checkTimer:uint;
		private var lastTime:Number;
		private var lastResponseTime:Number = NaN;
		
		public var tweet:StreamCollection = new StreamCollection;
		public var favorite:StreamCollection = new StreamCollection;
		public var mention:StreamCollection = new StreamCollection;
		public var dm:StreamCollection = new StreamCollection;
		public var list:StreamCollection = new StreamCollection;
		public var friend:ArrayList = new ArrayList;
		public var isFriendSet:Boolean = false;
		
		public static const LIST_MAX_LIMIT:Number = 1000;
		
		private var mon:SocketMonitor = new SocketMonitor('ds.lazyscope.com', 29115);
		
		public function networkChanged():void
		{
			if (oauth) {
				if (mon.running) return;
				mon.start();

				trace('[!] userStream networkChanged');
			}
		}
		
		public function get req():URLRequest
		{
			if (!oauth) return null;
			var r:URLRequest = new URLRequest('https://userstream.twitter.com/2/user.json');
			r.method = 'GET';
			r.authenticate = false;
			r.idleTimeout = 30000;
			
			if (oauth) {
				var auth:URLVariables = new URLVariables(oauth.getSignedRequest('GET', 'https://userstream.twitter.com/2/user.json', new URLVariables()));
				var authStr:Array = new Array;
				for (var k:String in auth) {
					if (k.substr(0, 6) == 'oauth_') {
						authStr.push(k+'="'+encodeURIComponent(auth[k])+'"');
					}
				}
				//trace('OAuth '+(authStr.join(', ')));
			}
			
			r.requestHeaders = new Array(new URLRequestHeader('Authorization', 'OAuth '+(authStr.join(','))));

			return r;
		}
		
		public function TwitterStream()
		{
			sock = new URLStream;
			
			sock.addEventListener(ProgressEvent.PROGRESS, socketData, false, 0, true);
			sock.addEventListener(HTTPStatusEvent.HTTP_RESPONSE_STATUS, sockConnected, false, 0, true);
			sock.addEventListener(Event.COMPLETE, errorHandler, false, 0, true);
			sock.addEventListener(IOErrorEvent.IO_ERROR, errorHandler, false, 0, true);
			sock.addEventListener(SecurityErrorEvent.SECURITY_ERROR, errorHandler, false, 0, true);
			sock.addEventListener(Event.CLOSE, closeHandler, false, 0, true);

			tweet.uniqKey = 'id';
			tweet.setSort([['published', true, false]]);
			tweet.maxCount = LIST_MAX_LIMIT;
			tweet.minmaxKey = 'id';
			tweet.userData = new TwitterStreamOption;
			tweet.addEventListener(CollectionEvent.COLLECTION_CHANGE, collectionChange, false, 0, true);
			
			favorite.uniqKey = 'id';
			favorite.setSort([['published', true, false]]);
			favorite.maxCount = LIST_MAX_LIMIT;
			favorite.minmaxKey = 'id';
			favorite.userData = new TwitterStreamOption;
			favorite.addEventListener(CollectionEvent.COLLECTION_CHANGE, collectionChange, false, 0, true);
			
			mention.uniqKey = 'id';
			mention.setSort([['published', true, false]]);
			mention.maxCount = LIST_MAX_LIMIT;
			mention.minmaxKey = 'id';
			mention.userData = new TwitterStreamOption;
			mention.addEventListener(CollectionEvent.COLLECTION_CHANGE, collectionChange, false, 0, true);
			
			dm.uniqKey = 'id';
			dm.setSort([['published', true, false]]);
			dm.maxCount = LIST_MAX_LIMIT;
			dm.minmaxKey = 'id';
			dm.userData = new TwitterStreamOption;
			dm.addEventListener(CollectionEvent.COLLECTION_CHANGE, collectionChange, false, 0, true);
			
			list.uniqKey = 'id';
			list.setSort([['published', true, false]]);
			list.maxCount = LIST_MAX_LIMIT;
			list.minmaxKey = 'id';
			list.userData = new TwitterStreamOption;
			list.addEventListener(CollectionEvent.COLLECTION_CHANGE, collectionChange, false, 0, true);
			
			mon.pollInterval = 500;
			mon.addEventListener(StatusEvent.STATUS, function(event:StatusEvent):void {
				if (mon.available) {
					trace('[!] userStream mon.available');
					mon.stop();
					reconnect(true);
				}
			});
		}
		
		public function collectionChange(event:CollectionEvent):void
		{
			if (event.kind == CollectionEventKind.REMOVE && event.items && event.items.length > 0) {
				for (var i:Number=0; i < event.items.length; i++) {
					var item:Object = event.items[i];
					if (!item) continue;
					/*
					if (item as StatusData)
						StatusData(item).destroy();
					else if (item as DirectMessageData)
						DirectMessageData(item).destroy();
					*/
				}
			}
		}
		
		public function set oauth(value:OAuth):void
		{
			if (_oauth == value || (_oauth && value && _oauth.oauthToken == value.oauthToken)) {
				return;
			}
			_oauth = value;
			reset();
		}
		
		public function get oauth():OAuth
		{
			return _oauth;
		}
		
		public function resetList():void
		{
			list.removeAll();
			list.userData.reset();
		}
		
		public function reset():void
		{
			lastResponseTime = NaN;
			
			tweet.removeAll();
			tweet.userData.reset();
			favorite.removeAll();
			favorite.userData.reset();
			mention.removeAll();
			mention.userData.reset();
			dm.removeAll();
			dm.userData.reset();
			
			resetList();
			
			friend.removeAll();
			isFriendSet = false;
		}
		
		public function closeHandler(event:Event):void
		{
			stop();
//trace('# userStream closeHandler', event);
		}
		
		public function errorHandler(event:Event):void
		{
//trace('# userStream errorHandler', event, event.type);
			stop();
			if (!isNaN(lastResponseTime) && lastResponseTime < (new Date().getTime())-(1000*120)) {
//trace('# no-connection-during-120sec REPAIR in errorHandler');
				Base.stream.twitterRepair();
				lastResponseTime = new Date().getTime();
			}
			
			if (isNaN(lastResponseTime))
				lastResponseTime = new Date().getTime();
			reconnect();
		}
		
		public static function parseStatus(node:Object, extended:Boolean=false):StatusData
		{
			if (node.target_object) node=node.target_object;
			var statusData:StatusData = new StatusData(
				node.created_at,
				node.id_str,
				TweetUtil.tidyTweet(node.text),
				node.source,
				TweetUtil.stringToBool(node.truncated),
				node.in_reply_to_status_id,
				node.in_reply_to_user_id,
				TweetUtil.stringToBool(node.favorited),
				node.in_reply_to_screen_name);
			
			if (node.retweeted_status)
				statusData.retweetedStatus = parseStatus(node.retweeted_status);
			
			var userData:UserData = new UserData(
				node.user.id,
				node.user.name,
				node.user.screen_name,
				node.user.location,
				node.user.description,
				node.user.profile_image_url,
				node.user.url,
				TweetUtil.stringToBool(node.user['protected']),
				node.user.followers_count
			); 
			
			if (extended) {
				var extendedData:ExtendedUserData = new ExtendedUserData(
					parseInt("0x"+node.user.profile_background_color),
					parseInt("0x"+node.user.profile_text_color),
					parseInt("0x"+node.user.profile_link_color),
					parseInt("0x"+node.user.profile_sidebar_fill_color),
					parseInt("0x"+node.user.profile_sidebar_border_color),
					node.user.friends_count,
					node.user.created_at,
					node.user.favourites_count,
					node.user.utc_offset,
					node.user.time_zone,
					node.user.profile_background_image_url,
					TweetUtil.stringToBool(node.user.profile_background_tile),
					TweetUtil.stringToBool(node.user.following),
					TweetUtil.stringToBool(node.user.notificactions),
					node.user.statuses_count,
					node.user.listed_count,
					TweetUtil.stringToBool(node.user.verified)
				);
				userData.extended = extendedData;
			}

			statusData.user = userData;
			return statusData;
		}
		
		public static function parseDirectMessage(node:Object, extended:Boolean=false):DirectMessageData
		{
			var directData:DirectMessageData = new DirectMessageData(
				node.id,
				node.sender_id,
				node.text,
				node.recipient_id,
				node.created_at,
				node.sender_screen_name,
				node.recipient_screen_name
			);

			var senderData:UserData = new UserData(
				node.sender.id,
				node.sender.name,
				node.sender.screen_name,
				node.sender.location,
				node.sender.description,
				node.sender.profile_image_url,
				node.sender.url,
				TweetUtil.stringToBool(node.sender['protected']),
				node.sender.followers_count
			);
				
			var recipientData:UserData = new UserData(
				node.recipient.id,
				node.recipient.name,
				node.recipient.screen_name,
				node.recipient.location,
				node.recipient.description,
				node.recipient.profile_image_url,
				node.recipient.url,
				TweetUtil.stringToBool(node.recipient['protected']),
				node.recipient.followers_count
			);         
			
			if (extended) {
				var senderExtendedData:ExtendedUserData = new ExtendedUserData(
					parseInt("0x"+node.sender.profile_background_color),
					parseInt("0x"+node.sender.profile_text_color),
					parseInt("0x"+node.sender.profile_link_color),
					parseInt("0x"+node.sender.profile_sidebar_fill_color),
					parseInt("0x"+node.sender.profile_sidebar_border_color),
					node.sender.friends_count,
					node.sender.created_at,
					node.sender.favourites_count,
					node.sender.utc_offset,
					node.sender.time_zone,
					node.sender.profile_background_image_url,
					TweetUtil.stringToBool(node.sender.profile_background_tile),
					TweetUtil.stringToBool(node.sender.following),
					TweetUtil.stringToBool(node.sender.notificactions),
					node.sender.statuses_count,
					node.sender.listed_count,
					TweetUtil.stringToBool(node.sender.verified)
				);
				senderData.extended = senderExtendedData;
			
				var recipientExtendedData:ExtendedUserData = new ExtendedUserData(
					parseInt("0x"+node.recipient.profile_background_color),
					parseInt("0x"+node.recipient.profile_text_color),
					parseInt("0x"+node.recipient.profile_link_color),
					parseInt("0x"+node.recipient.profile_sidebar_fill_color),
					parseInt("0x"+node.recipient.profile_sidebar_border_color),
					node.recipient.friends_count,
					node.recipient.created_at,
					node.recipient.favourites_count,
					node.recipient.utc_offset,
					node.recipient.time_zone,
					node.recipient.profile_background_image_url,
					TweetUtil.stringToBool(node.recipient.profile_background_tile),
					TweetUtil.stringToBool(node.recipient.following),
					TweetUtil.stringToBool(node.recipient.notificactions),
					node.recipient.statuses_count,
					node.recipient.listed_count,
					TweetUtil.stringToBool(node.recipient.verified)
				);
				recipientData.extended = recipientExtendedData;
			}
				
			directData.sender = senderData;
			directData.recipient = recipientData;
			
			return directData;
		}
		
		public function isFriend(id:String):Boolean
		{
			return friend.getItemIndex(id) >= 0 || Base.twitter.userid == id;
		}
		
		public function parse(str:String):void
		{
			if (!str) return;
			
			var arr:Array = str.split(/}[\r\n]{1,}/);
			if (arr.length <= 1)
				_parse(arr[0]);
			else{
				for (var i:Number=0; i < arr.length; i++) {
					if (arr[i])
						_parse(arr[i]+'}');
				}
			}
		}
		
		public function _parse(str:String):void
		{
			if (!str) return;
			str = str.replace(/^\s+|\s+$/, '');
			if (str.length <= 0) return;
			
			var i:Number;
			var statusData:StatusData;
			var statusData2:StatusData;
			
			try{
				var d:Object = JSON.decode(str);
				if (!d) return;
				
				if (d.event) {
					switch (d.event) {
						case 'follow':
							if (d.target && d.target.id_str)
								friend.addItem(d.target.id_str);
							break;
						case 'favorite':
							try{
								if (d.source.id_str != Base.twitter.userid) return;
							}catch(e:Error) {
								return;
							}
							statusData = parseStatus(d);
							if (statusData) {
								statusData2 = statusData.duplicate();
								statusData2.published = (new Date).getTime();
								favorite.addItem(statusData2);
								favorite.userData.lastID = Util.max(favorite.userData.lastID, statusData2.id);
								dispatchEvent(new TwitterStreamEvent(TwitterStreamEvent.FAVORITE, false, false, statusData2));
							}else{
								//statusData.destroy();
							}
							break;
					}
				}else if (d.direct_message) {
					try{
						var dmData:DirectMessageData = parseDirectMessage(d.direct_message);
						if (dmData) {
							dm.addItem(dmData);
							dm.userData.lastID = Util.max(dm.userData.lastID, dmData.id);
							dispatchEvent(new TwitterStreamEvent(TwitterStreamEvent.DIRECT_MESSAGE, false, false, null, dmData));
						}
					}catch(e:Error) {
						trace(e.getStackTrace(), '_parse1');
					}
				}else if (d.friends) {
					for (i=(d.friends as Array).length; i--;) {
						friend.addItem(d.friends[i].toString());
					}
					isFriendSet = true;
				}else if (d.id) {
//					trace('d.id', d.id);
					try{
						statusData = parseStatus(d);
						if (statusData) {
//							trace('statusData');
							if (statusData.favorited) {
								statusData2 = statusData.duplicate();
								statusData2.published = (new Date).getTime();
								favorite.addItem(statusData2);
								favorite.userData.lastID = Util.max(favorite.userData.lastID, statusData2.id);
								dispatchEvent(new TwitterStreamEvent(TwitterStreamEvent.FAVORITE, false, false, statusData2));
							}
							
							if (!statusData.retweetedStatus) {
								var reg:RegExp = new RegExp('@'+Base.twitter.screenName, 'i');
								if (statusData.text.match(reg)) {
									mention.addItem(statusData);
									mention.userData.lastID = Util.max(mention.userData.lastID, statusData.id);
									dispatchEvent(new TwitterStreamEvent(TwitterStreamEvent.MENTION, false, false, statusData));
								}
							}
							
							if (isFriend(statusData.user.id.toString())) {
								tweet.addItem(statusData);
								tweet.userData.lastID = Util.max(tweet.userData.lastID, statusData.id);
								dispatchEvent(new TwitterStreamEvent(TwitterStreamEvent.STATUS, false, false, statusData));
								//cookStatus(TwitterStreamEvent.STATUS, false, false, statusData);
							}
						}
					}catch(e:Error) {
						trace(e.getStackTrace(), '_parse2');
					}
				}

			}catch(e:Error) {
				trace(e.getStackTrace(), str, '_parse3');
			}
		}

		private function sockConnected(event:HTTPStatusEvent):void
		{
//trace('# sockConnected', event.status, lastResponseTime, lastTime, new Date().getTime());
			if (event.status == 200) {
				dispatchEvent(new Event('Connected'));
				
				clearTimeout(checkTimer);
				checkTimer = setTimeout(checkConnection, 1000*60);
				lastTime = new Date().getTime();
				if (!isNaN(lastResponseTime)) {
//trace('# reconnect REPAIR');
					Base.stream.twitterRepair();
				}
				lastResponseTime = lastTime;
			}else{
				stop();
				if (!isNaN(lastResponseTime) && lastResponseTime < (new Date().getTime())-(1000*120)) {
//trace('# no-connection-during-120sec REPAIR in sockConnected');
					Base.stream.twitterRepair();
					lastResponseTime = new Date().getTime();
				}
				
				if (isNaN(lastResponseTime))
					lastResponseTime = new Date().getTime();
				reconnect();
			}
		}
		
		private var buf:String = '';
		private function socketData(event:ProgressEvent):void
		{
			//trace('socketData', event);
			lastTime = new Date().getTime();
			//trace('socketData', event);
			buf += sock.readUTFBytes(sock.bytesAvailable);
			//trace('socketData', buf?buf.substr(0, 100):'');
//trace('@@', buf, typeof buf);
			var len:Number = Math.min(buf.length, 20);
			if (buf.substr(-1*len, len).match(/}\s*$/s)) {
				var _buf:String = buf;
				buf = '';
				parse(_buf);
				lastResponseTime = lastTime;
			}
		}
		
		public function checkConnection():void
		{
			clearTimeout(checkTimer);

//trace('**Check Connection - lastResponseTime:', lastResponseTime, new Date().getTime());
			if (!oauth || !sock.connected) {
				return;
			}
			
			checkTimer = setTimeout(checkConnection, 1000*60);
//			if (lastTime < (new Date().getTime())-(1000*30)) {
			if (lastTime < (new Date().getTime())-(1000*50)) {
				lastTime = new Date().getTime();
				trace('# userStream timeout');
				stop();
				reconnect();
			}
			
			if (!isNaN(lastResponseTime) && lastResponseTime < (new Date().getTime())-(1000*120)) {
				lastResponseTime = new Date().getTime();
//trace('# no-update-during-120sec REPAIR');
				Base.stream.twitterRepair();
				lastResponseTime = new Date().getTime();
			}
			
			if (isNaN(lastResponseTime))
				lastResponseTime = new Date().getTime();
		}
		
		private var timer:uint;
		public function reconnect(noWait:Boolean=false):void
		{
//trace('# userStream reconnect request', sock.connected);
			if (sock.connected) return;
			clearTimeout(timer);
			timer = setTimeout(_reconnect, 500, noWait);
		}
		
		public function _reconnect(noWait:Boolean=false):void
		{
			clearTimeout(timer);
			
			stop();
			if (noWait) {
				load();
			}else{
//trace('# userStream connect after 5 sec');
				setTimeout(function():void {
					if (!sock.connected)
						load();
				}, 5000);
			}
		}
		
		public function load():void
		{
			if (sock.connected) return;
			var r:URLRequest = req;
			if (r) {
//trace('# userStream load start');
				sock.load(r);
			}
		}
		
		public function start(oauth:OAuth):void
		{
			this.oauth = oauth;
			
			reconnect(true);
		}
		
		public function stop():void
		{
			buf = '';
			clearTimeout(checkTimer);
			try{
				if (sock.connected)
					sock.close();
				dispatchEvent(new Event('Close'));
			}catch(e:Error) {
				trace(e.getStackTrace(), 'stop twitter stream');
			}
//trace('# userStream stopped', sock.connected);
		}
		
		public function response(arr:Array, collection:StreamCollection):void
		{
			collection.userData.fetching = false;
			
			if (arr == null) {
				if (collection.minKey != Util.MAX_VALUE)		// collection.minKey < Number.MAX_VALUE
					collection.userData.EOL = true;
				return;
			}else if (!arr || arr.length <= 0) {
				collection.userData.EOL = true;
				return;
			}
			
			for (var i:Number=0; i < arr.length; i++) {
				if (!collection.isset('id', arr[i].id)) {
					collection.userData.lastID = Math.max(collection.userData.lastID, arr[i].id);
					collection.addItem(arr[i]);
				}
			}
		}
		
		public function isFetchEnabled(type:String):Boolean
		{
			var collection:StreamCollection = this[type];
			if (!collection || !collection.userData || collection.userData.fetching || collection.userData.EOL) return false;
			return true;
		}
		
		public function getCollection(type:String):StreamCollection
		{
			return this[type];
		}
		
		public function getStreamOption(type:String):TwitterStreamOption
		{
			var collection:StreamCollection = getCollection(type);
			if (collection && collection.userData)
				return collection.userData as TwitterStreamOption;
			return null;
		}
		
		public function getRecentItems(type:String, time:Number, limit:Number=50):ArrayList
		{
			var stream:StreamCollection = getCollection(type);
			if (!stream || stream.length <= 0) return null;
			
			var arr:ArrayList = new ArrayList;
			
			for (var i:Number=0; i < stream.length && limit > 0; i++) {
				var d:Object = stream.getItemAt(i);
				if (d && d.published && d.published <= time) {
					arr.addItem(d);
					limit--;
				}
			}
			
			return arr;
		}
		
		public function getLastItemTime(type:String):Number
		{
			var collection:StreamCollection = this[type];
			if (!collection || collection.length <= 0 || collection.length >= LIST_MAX_LIMIT) return -1;
			var item:Object = collection.getItemAt(Math.max(0, collection.length-20));
			if (item && item.published) {
				return item.published;
			}
			return -1;
		}
		
		public function fetch(type:String, callback:Function, option:Object=null):void
		{
			if (!option) option={};
			var collection:StreamCollection = this[type];
			if (!collection || !collection.userData || collection.userData.fetching || (!option.repair && collection.userData.EOL)) {
//trace('***** return fetch without processing *****');
				callback(null, collection?TwitterStreamOption(collection.userData):null, option);
				return;
			}
			if (!option.limit) option.limit=50;
			if (option.repair) {
//trace('***** [', collection.maxKey, '], [', Util.MIN_VALUE, ']', type);
				option.sinceID = collection.maxKey != Util.MIN_VALUE ? collection.maxKey : null;	// collection.maxKey > Number.MIN_VALUE
				if (!option.sinceID) {		// option.sinceID <= 0
					callback(null, collection?TwitterStreamOption(collection.userData):null, option);
					return;
				}
//				collection.userData.EOL = false;
			}
			
			var opt:TwitterStreamOption = collection.userData as TwitterStreamOption;
//trace('# userStream option.sinceID', type, option.sinceID);
			
			opt.fetching = true;
			
			var func:Function = function(arr:Array):void {
				response(arr, collection);
				callback(arr, opt, option);
			};
			
			switch (type) {
				case 'tweet':
//					Base.twitter.getHomeTimeline(func, option.sinceID, null, collection.minKey < Number.MAX_VALUE && !option.repair?collection.minKey-1:0, option.limit);
					Base.twitter.getHomeTimeline(func, option.sinceID, null, (collection.minKey != Util.MAX_VALUE && !option.repair)?collection.minKey:null, option.limit);
					break;
				case 'mention':
//					Base.twitter.getMentions(func, option.sinceID, null, collection.minKey < Number.MAX_VALUE && !option.repair?collection.minKey-1:0, option.limit);
					Base.twitter.getMentions(func, option.sinceID, null, (collection.minKey != Util.MAX_VALUE && !option.repair)?collection.minKey:null, option.limit);
					break;
				case 'list':
//					Base.twitter.getListStatuses(func, option.list.user.screenName, option.list.slug, null, collection.minKey < Number.MAX_VALUE?collection.minKey-1:0, option.limit);
					Base.twitter.getListStatuses(func, option.list.user.screenName, option.list.slug, null, (collection.minKey != Util.MAX_VALUE)?collection.minKey:null, option.limit);
					break;
				case 'dm':
					if (option && option.type == 'sent')
						Base.twitter.getSentDirectMessages(func, option.sinceID, false, option.limit);
					else
						Base.twitter.getReceivedDirectMessages(func, option.sinceID, false, option.limit);
					break;
				case 'favorite':
					if (isNaN(opt.page) || opt.page <= 0) opt.page=0;
					opt.page++;
//					trace('favorite', opt.page);
					Base.twitter.getFavorites(func, opt.page);
					break;
			}
		}
		
		public function listUpdate(callback:Function, li:ListData):void
		{
			if (list.userData.fetching || list.userData.EOL) {
				callback(null, TwitterStreamOption(list.userData), li);
				return;
			}
			var func:Function = function(arr:Array):void {
				response(arr, list);
				callback(arr, TwitterStreamOption(list.userData), li);
			};
			
			list.userData.EOL = false;
			
//			Base.twitter.getListStatuses(func, li.user.screenName, li.slug, list.maxKey > Number.MIN_VALUE?(list.maxKey+1).toString():'', 0, 50);
			Base.twitter.getListStatuses(func, li.user.screenName, li.slug, list.maxKey != Util.MIN_VALUE?list.maxKey:null, null, 50);
		}
	}
}