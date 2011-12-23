package com.lazyscope.twitter
{
	import com.lazyscope.Base;
	import com.lazyscope.ConfigDB;
	import com.lazyscope.UIFrame;
	import com.swfjunkie.tweetr.Tweetr;
	import com.swfjunkie.tweetr.events.TweetEvent;
	import com.swfjunkie.tweetr.oauth.OAuth;
	import com.swfjunkie.tweetr.oauth.events.OAuthEvent;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.html.HTMLLoader;
	import flash.utils.clearTimeout;
	import flash.utils.setTimeout;
	
	import mx.managers.PopUpManager;
	
	public class Twitter extends EventDispatcher
	{
		public var oauth:OAuth;
		private var htmlLoader:HTMLLoader;
		
		public var loginWindow:TwitterXAuth;

		[Bindable] public var ready:Boolean = false;
		public var userid:String = '';
		public var screenName:String = '';

		private static var _session:Twitter = null;
		public static function session():Twitter
		{
			if (!Twitter._session)
				Twitter._session = new Twitter;
			return Twitter._session;
		}

		public function Twitter(target:IEventDispatcher=null)
		{
			super(target);
			
			_session = this;
			
			oauth = new OAuth;
			
			/**** Please write down your Twitter x-auth api info ****/
			oauth.consumerKey = '**********************';
			oauth.consumerKey = '*******************************************';
			
			//oauth.callbackURL = "http://www.lazyscope.com/twconnect";
			//oauth.pinlessAuth = true;
			
			oauth.addEventListener(OAuthEvent.COMPLETE, handleOAuthEvent, false, 0, true);
			oauth.addEventListener(OAuthEvent.ERROR, handleOAuthEvent, false, 0, true);
		}
		
		public function disconnect():void
		{
			ConfigDB.remove('lf_tw_oauth_token');
			ConfigDB.remove('lf_tw_oauth_secret');
			ConfigDB.remove('lf_tw_oauth_id');
			ConfigDB.remove('lf_tw_oauth_name');
			
			oauth.oauthToken = '';
			oauth.oauthTokenSecret = '';
			oauth.userId = '';
			oauth.username = '';
			this.ready = false;
			
			twitterInit();
			
			UIFrame.hideContentFrame();
			
			dispatchEvent(new Event(Event.CANCEL));
		}
		
		private var funcAuthorize:Function = null;
		public function authorize(callback:Function=null):void
		{
			funcAuthorize = callback;
			
			var oauth_token:String = ConfigDB.get('lf_tw_oauth_token');
			var oauth_secret:String = ConfigDB.get('lf_tw_oauth_secret');
			var oauth_id:String = ConfigDB.get('lf_tw_oauth_id');
			var oauth_name:String = ConfigDB.get('lf_tw_oauth_name');
			
			if (oauth_token != null && oauth_secret != null && oauth_id != null && oauth_name != null) {
				oauth.oauthToken = oauth_token;
				oauth.oauthTokenSecret = oauth_secret;
				oauth.userId = oauth_id;
				oauth.username = oauth_name;
				this.ready = true;
				twitterInit();
				
				dispatchEvent(new Event(Event.COMPLETE));
				
				if (funcAuthorize != null)
					callback();
			}else{
				if (!loginWindow) {
					loginWindow = new TwitterXAuth;
				}
				loginWindow.oauth = oauth;
				
				
				Base.contentContainer.callLater(function():void {
					PopUpManager.addPopUp(loginWindow, Base.app, true);
					PopUpManager.centerPopUp(loginWindow);
					
					loginWindow.password.text = '';
					if (loginWindow.username.text.length > 0)
						loginWindow.password.setFocus();
					else
						loginWindow.username.setFocus();
					loginWindow.error.text = '';
				});
			}
		}
		
		public function getLists(subscription:Boolean, callback:Function):void
		{
			if (!ready || !userid) {
				callback(null);
				return;
			}
			
			var twitter:Tweetr = new Tweetr;
			twitter.oAuth = oauth;
			
			var fc:Function = function(event:TweetEvent):void {
				twitter.removeEventListener(TweetEvent.COMPLETE, fc);
				twitter.removeEventListener(TweetEvent.FAILED, fe);
				
				callback(event.responseArray);
				twitter.destroy();
			};
			var fe:Function = function(event:TweetEvent):void{
				twitter.removeEventListener(TweetEvent.COMPLETE, fc);
				twitter.removeEventListener(TweetEvent.FAILED, fe);
				
				callback(null);
				twitter.destroy();
			};
			
			twitter.addEventListener(TweetEvent.COMPLETE, fc);
			twitter.addEventListener(TweetEvent.FAILED, fe);
			if (subscription)
				twitter.getListSubscriptions(userid);
			else
				twitter.getLists(userid);
		}
		
		public function getListStatuses(callback:Function, listUser:String, slug:String, since_id:String = null, max_id:String = null, count:Number = 0, page:Number = 0):void
		{
			if (!ready) return;
			if (!userid && !listUser) return;
			
			var twitter:Tweetr = new Tweetr;
			twitter.oAuth = oauth;
			
			var fc:Function = function(event:TweetEvent):void {
				twitter.removeEventListener(TweetEvent.COMPLETE, fc);
				twitter.removeEventListener(TweetEvent.FAILED, fe);
				
				callback(event.responseArray);
				twitter.destroy();
			};
			var fe:Function = function(event:TweetEvent):void{
				twitter.removeEventListener(TweetEvent.COMPLETE, fc);
				twitter.removeEventListener(TweetEvent.FAILED, fe);
				
				callback(null);
				twitter.destroy();
			};

			twitter.addEventListener(TweetEvent.COMPLETE, fc);
			twitter.addEventListener(TweetEvent.FAILED, fe);
			twitter.getListStatuses(slug, listUser?listUser:userid, since_id, max_id, count, page);
		}
		
		public function getHomeTimeline(callback:Function, since_id:String = null, since_date:String = null, max_id:String = null, count:Number = 0, page:Number = 0):void
		{
			if (!ready) return;
			
			var twitter:Tweetr = new Tweetr;
			twitter.oAuth = oauth;

			var fc:Function = function(event:TweetEvent):void {
				twitter.removeEventListener(TweetEvent.COMPLETE, fc);
				twitter.removeEventListener(TweetEvent.FAILED, fe);
				
				callback(event.responseArray);
				twitter.destroy();
			};
			var fe:Function = function(event:TweetEvent):void{
				twitter.removeEventListener(TweetEvent.COMPLETE, fc);
				twitter.removeEventListener(TweetEvent.FAILED, fe);
				
				callback(null);
				twitter.destroy();
			};
			
			twitter.addEventListener(TweetEvent.COMPLETE, fc);
			twitter.addEventListener(TweetEvent.FAILED, fe);
			twitter.getHomeTimeLine(since_id, since_date, max_id, count, page);
		}
		
		public function getUserTimeLine(callback:Function, id:String, since_id:String = null, since_date:String = null, max_id:String = null, page:Number = 0, count:Number = 0, extend:Boolean=false):void
		{
			if (!ready) return;
			
			var twitter:Tweetr = new Tweetr;
			twitter.oAuth = oauth;
			
			var fc:Function = function(event:TweetEvent):void {
				twitter.removeEventListener(TweetEvent.COMPLETE, fc);
				twitter.removeEventListener(TweetEvent.FAILED, fe);
				
				callback(event.responseArray);
				twitter.destroy();
			};
			var fe:Function = function(event:TweetEvent):void{
				twitter.removeEventListener(TweetEvent.COMPLETE, fc);
				twitter.removeEventListener(TweetEvent.FAILED, fe);
				
				callback(null);
				twitter.destroy();
			};
			
			twitter.addEventListener(TweetEvent.COMPLETE, fc);
			twitter.addEventListener(TweetEvent.FAILED, fe);
			twitter.getUserTimeLine(id, since_id, since_date, max_id, page, count, extend);
		}
		
		/*
		public function getFriends(callback:Function, id:String=null, cursor:String='-1'):void
		{
			if (!ready) return;
			
			var twitter:Tweetr = new Tweetr;
			twitter.oAuth = oauth;
			
			var fc:Function = function(event:TweetEvent):void {
				twitter.removeEventListener(TweetEvent.COMPLETE, fc);
				twitter.removeEventListener(TweetEvent.FAILED, fe);
				
				callback(event.responseArray, event.cursor);
				twitter.destroy();
			};
			var fe:Function = function(event:TweetEvent):void{
				twitter.removeEventListener(TweetEvent.COMPLETE, fc);
				twitter.removeEventListener(TweetEvent.FAILED, fe);
				
				callback(null);
				twitter.destroy();
			};
			
			twitter.addEventListener(TweetEvent.COMPLETE, fc);
			twitter.addEventListener(TweetEvent.FAILED, fe);
			twitter.getFriends(id, cursor);
		}
		*/
		
		public function getUserDetails(callback:Function, id:String):void
		{
			if (!ready) return;
			
			var twitter:Tweetr = new Tweetr;
			twitter.oAuth = oauth;
			
			var fc:Function = function(event:TweetEvent):void {
				twitter.removeEventListener(TweetEvent.COMPLETE, fc);
				twitter.removeEventListener(TweetEvent.FAILED, fe);
				
				callback(event.responseArray);
				twitter.destroy();
			};
			var fe:Function = function(event:TweetEvent):void{
				twitter.removeEventListener(TweetEvent.COMPLETE, fc);
				twitter.removeEventListener(TweetEvent.FAILED, fe);
				
				callback(null);
				twitter.destroy();
			};
			
			twitter.addEventListener(TweetEvent.COMPLETE, fc);
			twitter.addEventListener(TweetEvent.FAILED, fe);
			twitter.getUserDetails(id);
		}
		
		public function getStatus(callback:Function, id:String):void
		{
			if (!ready) return;
			
			var twitter:Tweetr = new Tweetr;
			twitter.oAuth = oauth;
			
			var fc:Function = function(event:TweetEvent):void {
				twitter.removeEventListener(TweetEvent.COMPLETE, fc);
				twitter.removeEventListener(TweetEvent.FAILED, fe);
				
				callback(event.responseArray);
				twitter.destroy();
			};
			var fe:Function = function(event:TweetEvent):void{
				twitter.removeEventListener(TweetEvent.COMPLETE, fc);
				twitter.removeEventListener(TweetEvent.FAILED, fe);
				
				callback(null);
				twitter.destroy();
			};
			
			twitter.addEventListener(TweetEvent.COMPLETE, fc);
			twitter.addEventListener(TweetEvent.FAILED, fe);
			twitter.getStatus(id);
		}
		
		public function showFriendshipByID(callback:Function, targetID:String, sourceID:String):void
		{
			if (!ready) return;
			
			var twitter:Tweetr = new Tweetr;
			twitter.oAuth = oauth;
			
			var fc:Function = function(event:TweetEvent):void {
				twitter.removeEventListener(TweetEvent.COMPLETE, fc);
				twitter.removeEventListener(TweetEvent.FAILED, fe);
				
				callback(event.responseArray);
				twitter.destroy();
			};
			var fe:Function = function(event:TweetEvent):void{
				twitter.removeEventListener(TweetEvent.COMPLETE, fc);
				twitter.removeEventListener(TweetEvent.FAILED, fe);
				
				callback(null);
				twitter.destroy();
			};
			
			twitter.addEventListener(TweetEvent.COMPLETE, fc);
			twitter.addEventListener(TweetEvent.FAILED, fe);
			twitter.showFriendshipById(targetID, sourceID);
		}
		
		public function getMentions(callback:Function, since_id:String = null, since_date:String = null, max_id:String = null, count:Number=0, page:Number = 0):void
		{
			if (!ready) return;
			
			var twitter:Tweetr = new Tweetr;
			twitter.oAuth = oauth;
			
			var fc:Function = function(event:TweetEvent):void {
				twitter.removeEventListener(TweetEvent.COMPLETE, fc);
				twitter.removeEventListener(TweetEvent.FAILED, fe);
				
				callback(event.responseArray);
				twitter.destroy();
			};
			var fe:Function = function(event:TweetEvent):void{
				twitter.removeEventListener(TweetEvent.COMPLETE, fc);
				twitter.removeEventListener(TweetEvent.FAILED, fe);
				
				callback(null);
				twitter.destroy();
			};
			
			twitter.addEventListener(TweetEvent.COMPLETE, fc);
			twitter.addEventListener(TweetEvent.FAILED, fe);
			twitter.getMentions(since_id, since_date, max_id, count, page);
		}
		
		public function getFavorites(callback:Function, page:Number = 1):void
		{
			if (!ready || !userid) return;
			
			var twitter:Tweetr = new Tweetr;
			twitter.oAuth = oauth;
			
			var fc:Function = function(event:TweetEvent):void {
				twitter.removeEventListener(TweetEvent.COMPLETE, fc);
				twitter.removeEventListener(TweetEvent.FAILED, fe);
				
				callback(event.responseArray);
				twitter.destroy();
			};
			var fe:Function = function(event:TweetEvent):void{
				twitter.removeEventListener(TweetEvent.COMPLETE, fc);
				twitter.removeEventListener(TweetEvent.FAILED, fe);
				
				callback(null);
				twitter.destroy();
			};
			
			twitter.addEventListener(TweetEvent.COMPLETE, fc);
			twitter.addEventListener(TweetEvent.FAILED, fe);
			twitter.getFavorites(userid, page);
		}
		
		public function getReceivedDirectMessages(callback:Function, id:Number = NaN, checkMode:Boolean=false, count:Number=0):void
		{
			if (!ready) return;
			
			var twitter:Tweetr = new Tweetr;
			twitter.oAuth = oauth;
			
			var fc:Function = function(event:TweetEvent):void {
				twitter.removeEventListener(TweetEvent.COMPLETE, fc);
				twitter.removeEventListener(TweetEvent.FAILED, fe);
				
				callback(event.responseArray);
				twitter.destroy();
			};
			var fe:Function = function(event:TweetEvent):void{
				twitter.removeEventListener(TweetEvent.COMPLETE, fc);
				twitter.removeEventListener(TweetEvent.FAILED, fe);
				
				callback(null);
				twitter.destroy();
			};
			
			twitter.addEventListener(TweetEvent.COMPLETE, fc);
			twitter.addEventListener(TweetEvent.FAILED, fe);
			twitter.getReceivedDirectMessages(id?id.toString():null, null, null, 0, count);
		}
		
		public function getSentDirectMessages(callback:Function, id:Number = NaN, checkMode:Boolean=false, count:Number=0):void
		{
			if (!ready) return;
			
			var twitter:Tweetr = new Tweetr;
			twitter.oAuth = oauth;
			
			var fc:Function = function(event:TweetEvent):void {
				twitter.removeEventListener(TweetEvent.COMPLETE, fc);
				twitter.removeEventListener(TweetEvent.FAILED, fe);
				
				callback(event.responseArray);
				twitter.destroy();
			};
			var fe:Function = function(event:TweetEvent):void{
				twitter.removeEventListener(TweetEvent.COMPLETE, fc);
				twitter.removeEventListener(TweetEvent.FAILED, fe);
				
				callback(null);
				twitter.destroy();
			};
			
			twitter.addEventListener(TweetEvent.COMPLETE, fc);
			twitter.addEventListener(TweetEvent.FAILED, fe);
			twitter.getSentDirectMessages(id?id.toString():null, null, null, 0, count);
		}
		
		public function updateStatus(callback:Function, status:String, inReplyTo:String = null):void
		{
			if (!ready) return;
			
			var twitter:Tweetr = new Tweetr;
			twitter.oAuth = oauth;
			
			var fc:Function = function(event:TweetEvent):void {
				twitter.removeEventListener(TweetEvent.COMPLETE, fc);
				twitter.removeEventListener(TweetEvent.FAILED, fe);
				
				//trace('*************');
				//trace('event.info', event.info);
				//trace('event.data', event.data);
				callback(event.responseArray);
				twitter.destroy();
			};
			var fe:Function = function(event:TweetEvent):void{
				twitter.removeEventListener(TweetEvent.COMPLETE, fc);
				twitter.removeEventListener(TweetEvent.FAILED, fe);
				
				callback(null);
				twitter.destroy();
			};
			
			twitter.addEventListener(TweetEvent.COMPLETE, fc);
			twitter.addEventListener(TweetEvent.FAILED, fe);
			//trace(status);
			twitter.updateStatus(status, inReplyTo);
		}
		
		public function destroyStatus(id:String, callback:Function=null):void
		{
			if (!ready) return;
			
			var twitter:Tweetr = new Tweetr;
			twitter.oAuth = oauth;
			
			var fc:Function = function(event:TweetEvent):void {
				twitter.removeEventListener(TweetEvent.COMPLETE, fc);
				twitter.removeEventListener(TweetEvent.FAILED, fe);
				
				callback(event.responseArray);
				twitter.destroy();
			};
			var fe:Function = function(event:TweetEvent):void{
				twitter.removeEventListener(TweetEvent.COMPLETE, fc);
				twitter.removeEventListener(TweetEvent.FAILED, fe);
				
				callback(null);
				twitter.destroy();
			};
			
			twitter.addEventListener(TweetEvent.COMPLETE, fc);
			twitter.addEventListener(TweetEvent.FAILED, fe);
			twitter.destroyStatus(id);
		}
		
		public function sendDirectMessage(callback:Function, text:String, userName:String):void
		{
			if (!ready) return;
			
			var twitter:Tweetr = new Tweetr;
			twitter.oAuth = oauth;
			
			var fc:Function = function(event:TweetEvent):void {
				twitter.removeEventListener(TweetEvent.COMPLETE, fc);
				twitter.removeEventListener(TweetEvent.FAILED, fe);
				
				callback(event.responseArray);
				twitter.destroy();
			};
			var fe:Function = function(event:TweetEvent):void{
				twitter.removeEventListener(TweetEvent.COMPLETE, fc);
				twitter.removeEventListener(TweetEvent.FAILED, fe);
				
				callback(null);
				twitter.destroy();
			};
			
			twitter.addEventListener(TweetEvent.COMPLETE, fc);
			twitter.addEventListener(TweetEvent.FAILED, fe);
			twitter.sendDirectMessage(text, userName);
		}
		
		public function destroyDirectMessage(id:String, callback:Function=null):void
		{
			if (!ready) return;
			
			var twitter:Tweetr = new Tweetr;
			twitter.oAuth = oauth;
			
			var fc:Function = function(event:TweetEvent):void {
				twitter.removeEventListener(TweetEvent.COMPLETE, fc);
				twitter.removeEventListener(TweetEvent.FAILED, fe);
				
				callback(event.responseArray);
				twitter.destroy();
			};
			var fe:Function = function(event:TweetEvent):void{
				twitter.removeEventListener(TweetEvent.COMPLETE, fc);
				twitter.removeEventListener(TweetEvent.FAILED, fe);
				
				callback(null);
				twitter.destroy();
			};
			
			twitter.addEventListener(TweetEvent.COMPLETE, fc);
			twitter.addEventListener(TweetEvent.FAILED, fe);
			twitter.destroyDirectMessage(id);
		}
		
		public function createFriendship(id:String, callback:Function=null):void
		{
			if (!ready) return;
			
			var twitter:Tweetr = new Tweetr;
			twitter.oAuth = oauth;
			
			var fc:Function = function(event:TweetEvent):void {
				twitter.removeEventListener(TweetEvent.COMPLETE, fc);
				twitter.removeEventListener(TweetEvent.FAILED, fe);
				
				callback(event.responseArray);
				twitter.destroy();
			};
			var fe:Function = function(event:TweetEvent):void{
				twitter.removeEventListener(TweetEvent.COMPLETE, fc);
				twitter.removeEventListener(TweetEvent.FAILED, fe);
				
				callback(null);
				twitter.destroy();
			};
			
			twitter.addEventListener(TweetEvent.COMPLETE, fc);
			twitter.addEventListener(TweetEvent.FAILED, fe);
			twitter.createFriendship(id);
		}
		
		public function destroyFriendship(id:String, callback:Function=null):void
		{
			if (!ready) return;
			
			var twitter:Tweetr = new Tweetr;
			twitter.oAuth = oauth;
			
			var fc:Function = function(event:TweetEvent):void {
				twitter.removeEventListener(TweetEvent.COMPLETE, fc);
				twitter.removeEventListener(TweetEvent.FAILED, fe);
				
				callback(event.responseArray);
				twitter.destroy();
			};
			var fe:Function = function(event:TweetEvent):void{
				twitter.removeEventListener(TweetEvent.COMPLETE, fc);
				twitter.removeEventListener(TweetEvent.FAILED, fe);
				
				callback(null);
				twitter.destroy();
			};
			
			twitter.addEventListener(TweetEvent.COMPLETE, fc);
			twitter.addEventListener(TweetEvent.FAILED, fe);
			twitter.destroyFriendship(id);
		}
		
		public function createFavorite(id:String, callback:Function=null):void
		{
			if (!ready) return;
			
			var twitter:Tweetr = new Tweetr;
			twitter.oAuth = oauth;
			
			var fc:Function = function(event:TweetEvent):void {
				twitter.removeEventListener(TweetEvent.COMPLETE, fc);
				twitter.removeEventListener(TweetEvent.FAILED, fe);
				
				callback(event.responseArray);
				twitter.destroy();
			};
			var fe:Function = function(event:TweetEvent):void{
				twitter.removeEventListener(TweetEvent.COMPLETE, fc);
				twitter.removeEventListener(TweetEvent.FAILED, fe);
				
				callback(null);
				twitter.destroy();
			};
			
			twitter.addEventListener(TweetEvent.COMPLETE, fc);
			twitter.addEventListener(TweetEvent.FAILED, fe);
			twitter.createFavorite(id);
		}
		
		public function destroyFavorite(id:String, callback:Function=null):void
		{
			if (!ready) return;
			
			var twitter:Tweetr = new Tweetr;
			twitter.oAuth = oauth;
			
			var fc:Function = function(event:TweetEvent):void {
				twitter.removeEventListener(TweetEvent.COMPLETE, fc);
				twitter.removeEventListener(TweetEvent.FAILED, fe);
				
				callback(event.responseArray);
				twitter.destroy();
			};
			var fe:Function = function(event:TweetEvent):void{
				twitter.removeEventListener(TweetEvent.COMPLETE, fc);
				twitter.removeEventListener(TweetEvent.FAILED, fe);
				
				callback(null);
				twitter.destroy();
			};
			
			twitter.addEventListener(TweetEvent.COMPLETE, fc);
			twitter.addEventListener(TweetEvent.FAILED, fe);
			twitter.destroyFavorite(id);
		}
		
		public function retweet(id:String, callback:Function=null):void
		{
			if (!ready) return;
			
			var twitter:Tweetr = new Tweetr;
			twitter.oAuth = oauth;
			
			var fc:Function = function(event:TweetEvent):void {
				twitter.removeEventListener(TweetEvent.COMPLETE, fc);
				twitter.removeEventListener(TweetEvent.FAILED, fe);
				
				callback(event.responseArray);
				twitter.destroy();
			};
			var fe:Function = function(event:TweetEvent):void{
				twitter.removeEventListener(TweetEvent.COMPLETE, fc);
				twitter.removeEventListener(TweetEvent.FAILED, fe);
				
				callback(null);
				twitter.destroy();
			};
			
			twitter.addEventListener(TweetEvent.COMPLETE, fc);
			twitter.addEventListener(TweetEvent.FAILED, fe);
			twitter.retweetStatus(id);
		}
		
		private function twitterInit():void
		{
			this.userid = oauth.userId;
			this.screenName = oauth.username;
		}
		
		private function handleOAuthEvent(event:OAuthEvent):void
		{
			if (event.type == OAuthEvent.COMPLETE)
			{
				ready = true;
				
				if (loginWindow)
					PopUpManager.removePopUp(loginWindow);
				//htmlLoader.stage.nativeWindow.close();
				
				twitterInit();
				
				dispatchEvent(new Event(Event.COMPLETE));
				
				//trace(oauth.oauthToken, oauth.oauthTokenSecret, oauth.userId, oauth.username);
				
				ConfigDB.set('lf_tw_oauth_token', oauth.oauthToken);
				ConfigDB.set('lf_tw_oauth_secret', oauth.oauthTokenSecret);
				ConfigDB.set('lf_tw_oauth_id', oauth.userId);
				ConfigDB.set('lf_tw_oauth_name', oauth.username);
				
				if (funcAuthorize != null)
					funcAuthorize();
			}else{
				ready = false;
			}
		}
	}
}