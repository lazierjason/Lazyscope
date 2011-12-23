package com.lazyscope.entry
{
	public class FavoriteLink
	{
		public var link:String;
		public var registered:Number;
		public var _published:Date;
		
		public static var keys:Array = new Array(
			'link', 'published'
		);
		
		public function FavoriteLink(link:String=null, registered:Number=0)
		{
			this.link = link;
			this.registered = registered;
			this._published = new Date;
			if (registered)
				published.setTime(registered);
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
	}
}