package com.lazyscope.account
{
	import com.lazyscope.Base;
	import com.lazyscope.twitter.Twitter;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.utils.clearTimeout;
	import flash.utils.setTimeout;
	
	[Event(name="list", type="com.lazyscope.account.AccountTwitterEvent")]

	public class AccountTwitter extends EventDispatcher implements IAccount
	{
		public var data:Twitter;
		public function AccountTwitter(data:Twitter)
		{
			this.data = data;
		}
		
		public function get type():String
		{
			return 'Twitter';
		}
		
		public function get id():String
		{
			return data?'Twitter@'+(data.screenName):'Twitter';
		}
		
		public function get label():String
		{
			return data?data.screenName:'Twitter';
		}
		
		public function get tooltip():String
		{
			return data?('@'+data.screenName):'Twitter';
		}
		
		public function selected(context:String=null):void
		{
			
		}
		
		public function getImageSrc():String
		{
			return 'app:///icon/twitter.png';
			if (data && data.userid)
				return 'http://api.twitter.com/1/users/profile_image/'+(data.userid)+'.json?size=normal';
			else
				return null;
		}
		
		private function _setLists(subscription:Boolean, lists:Array):void
		{
			if (!lists) return;
			for (var i:Number=0; i < lists.length; i++)
				dispatchEvent(new AccountTwitterEvent(AccountTwitterEvent.LISTS, {type:subscription?5:4, name:lists[i].fullName, data:lists[i]}));
		}
		
		protected var timerTwitterListsMine:uint = 0;
		protected var timerTwitterListsSubscribe:uint = 0;
		
		public function getLists():void
		{
			if (timerTwitterListsMine)
				clearTimeout(timerTwitterListsMine);
			if (timerTwitterListsSubscribe)
				clearTimeout(timerTwitterListsSubscribe);
			fetchTwitterListsMine();
			fetchTwitterListsSubscribe();
		}
		
		protected function fetchTwitterListsMine():void
		{
			//my lists
			Base.twitter.getLists(false, function(res:Array):void {
				if (res != null)
					_setLists(false, res);
				else
					timerTwitterListsMine = setTimeout(fetchTwitterListsMine, 33333);
			});
		}
		protected function fetchTwitterListsSubscribe():void
		{
			//subscription
			Base.twitter.getLists(true, function(res:Array):void {
				if (res != null)
					_setLists(true, res);
				else
					timerTwitterListsSubscribe = setTimeout(fetchTwitterListsMine, 35555);
			});
		}
	}
}