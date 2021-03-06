package com.swfjunkie.tweetr.data.objects
{	
	import com.lazyscope.Util;

    /**
     * Direct Message Data Object 
     * @author Sandro Ducceschi [swfjunkie.com, Switzerland]
     */
   
    public class DirectMessageData
    {
        //--------------------------------------------------------------------------
        //
        //  Class variables
        //
        //--------------------------------------------------------------------------

        //--------------------------------------------------------------------------
        //
        //  Initialization
        //
        //--------------------------------------------------------------------------
        public function DirectMessageData( id:String = null,
                                           senderId:Number = 0,
                                           text:String = null,
                                           recipientId:Number = 0,
                                           createdAt:String = null,
                                           senderScreenName:String = null,
                                           recipientScreenName:String = null,
                                           sender:UserData = null,
                                           recipient:UserData = null ) 
        {
            this.id = id;
            this.senderId = senderId;
            this.text = text?Util.htmlEntitiesDecode(text).replace(/http:\/\//g, ' http://').replace(/\s+/g, ' ').substr(0, 300):'';
			this.links = this.text.match(/\bhttps?:\/\/[^\s]+([^\.,!?"'\)\>\s]|$)/ig);
			if (this.links) {
				for (var i:Number=this.links.length; i--;)
					this.links[i] = this.links[i].replace(/[\.,!?"'\)\>\s]+$/, '');
			}
            this.recipientId = recipientId;
            this.createdAt = createdAt;
			var d:Date = Util.parseDate(createdAt);
			this.published = d?d.getTime():-1;
            this.senderScreenName = senderScreenName;
            this.recipientScreenName = recipientScreenName;
            this.sender = sender;
            this.recipient = recipient;
        }
        //--------------------------------------------------------------------------
        //
        //  Properties
        //
        //--------------------------------------------------------------------------
        public var id:String;
        public var senderId:Number;
        public var text:String;
        public var recipientId:Number;
        public var createdAt:String;
		public var published:Number;
        public var senderScreenName:String;
        public var recipientScreenName:String;
        public var sender:UserData;
        public var recipient:UserData;
		public var links:Array;
        //--------------------------------------------------------------------------
        //
        //  API
        //
        //--------------------------------------------------------------------------
		
		public function destroy():void
		{
			links = null;
			if (sender)
				sender.destroy();
			sender = null;
			if (recipient)
				recipient.destroy();
			recipient = null;
		}
    }
}