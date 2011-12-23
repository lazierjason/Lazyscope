package com.lazyscope.twitter
{
	public class TwitterStreamOption
	{
		public var requested:Boolean = false;
		public var EOL:Boolean = false;
		public var EOL2:Boolean = false;
		public var fetching:Boolean = false;
		public var fetching2:Boolean = false;
		public var lastID:Number;
		public var page:Number;
		
		public function TwitterStreamOption()
		{
		}
		
		public function reset():void
		{
			requested = EOL = EOL2 = fetching = fetching2 = false;
			lastID = page = NaN;
		}
	}
}