package com.swfjunkie.tweetr.data.objects
{	
	import flashx.textLayout.conversion.TextConverter;
	import flashx.textLayout.elements.Configuration;
	import flashx.textLayout.elements.TextFlow;
	import flashx.textLayout.formats.TextLayoutFormat;

    /**
     * Twitter Status Data Object 
     * @author Sandro Ducceschi [swfjunkie.com, Switzerland]
     */
   
    public class StatusData
    {
		import com.lazyscope.Util;
        //--------------------------------------------------------------------------
        //
        //  Class variables
        //
        //--------------------------------------------------------------------------

		/*
		public static var _styling:Configuration = null;
		public function get styling():Configuration
		{
			if (_styling == null) {
				var _formatNormal:TextLayoutFormat = new TextLayoutFormat;
				_formatNormal.textDecoration = 'none';
//				_formatNormal.color = 0x0279B4;		// This is original color code.
				_formatNormal.color = 0x015EBD;
				var _formatHover:TextLayoutFormat = new TextLayoutFormat;
				_formatHover.textDecoration = 'underline';
				_formatHover.color = 0x015EBD;
				
				_styling = new Configuration;
				_styling.defaultLinkNormalFormat = _formatNormal;
				_styling.defaultLinkHoverFormat = _formatHover;
			}
			return _styling;
		}
		*/

        //--------------------------------------------------------------------------
        //
        //  Initialization
        //
        //--------------------------------------------------------------------------
        public function StatusData(createdAt:String = null, 
                                    id:String = null, 
                                    text:String = null,
                                    source:String = null,
                                    truncated:Boolean = false,
                                    inReplyToStatusId:String = null,
                                    inReplyToUserId:String = null,
                                    favorited:Boolean = false,
                                    inReplyToScreenName:String = null,
                                    user:UserData = null)
        {
            this.createdAt = createdAt;
			var d:Date = Util.parseDate(createdAt);
			this.published = this.publishedDisplay = d?d.getTime():-1;
            this.id = id;
            this.text = text?Util.htmlEntitiesDecode(text).replace(/http:\/\//g, ' http://').replace(/\s+/g, ' ').substr(0, 300):'';
            //this.text = text?text.replace(/\s+/g, ' ').replace(/^\s+|\s+$/g, ''):'';
			
			/*
			var tt:String = text;
			tt = tt.replace(/\b(https?:\/\/[^\s]+([^\.,!?"'\)\>\s]|$))/ig, '<a href="$1">$1</a>');								// link
			tt = tt.replace(/(\s|^)#([^\s]*([^\.,!?"'\)\>\s]|$))/ig, '$1<a href="http://twitter.com/#search?q=#$2">#$2</a>');	// hashtag
			tt = tt.replace(/([^\da-zA-Z_\-]|^)@([\da-zA-Z_\-]+)/ig, '$1@<a href="http://twitter.com/$2">$2</a>');								// user
			
			this.textFlow = TextConverter.importToFlow(tt, TextConverter.TEXT_FIELD_HTML_FORMAT);
			*/

			this.links = this.text.match(/\bhttps?:\/\/[^\s]+([^\.,!?"'\)\>\s]|$)/ig);
			if (this.links) {
				for (var i:Number=this.links.length; i--;)
					this.links[i] = this.links[i].replace(/[\.,!?"'\)\>\s]+$/, '');
			}
            this.source = source;
            this.truncated = truncated;
            this.inReplyToStatusId = inReplyToStatusId;
            this.inReplyToUserId = inReplyToUserId;
            this.favorited = favorited;
            this.inReplyToScreenName = inReplyToScreenName;
            this.user = user;
        }
        //--------------------------------------------------------------------------
        //
        //  Properties
        //
        //--------------------------------------------------------------------------
        
        public var createdAt:String;
		public var published:Number;
		public var publishedDisplay:Number;
        public var id:String;
        public var text:String;
        public var source:String;
        public var truncated:Boolean;
        public var inReplyToStatusId:String;
        public var inReplyToUserId:String;
        public var favorited:Boolean;
        public var inReplyToScreenName:String;
        public var retweetedStatus:StatusData;
        public var geoLat:Number;
        public var geoLong:Number;
        public var user:UserData;
		//public var textFlow:TextFlow;
		public var links:Array;
		public var retweetedByMe:Boolean = false;
		
		public function duplicate():StatusData
		{
			var s:StatusData = new StatusData;
			s.createdAt = createdAt;
			s.published = published;
			s.publishedDisplay = publishedDisplay;
			s.id = id;
			s.text = text;
			s.source = source;
			s.truncated = truncated;
			s.inReplyToStatusId = inReplyToStatusId;
			s.inReplyToUserId = inReplyToUserId;
			s.favorited = favorited;
			s.inReplyToScreenName = inReplyToScreenName;
			s.retweetedStatus = retweetedStatus ? retweetedStatus.duplicate() : null;
			s.geoLat = geoLat;
			s.geoLong = geoLong;
			s.user = user;
			s.links = links;
			s.retweetedByMe = retweetedByMe;
			return s;
		}
		
		public function destroy():void
		{
			links = null;
			if (retweetedStatus)
				retweetedStatus.destroy();
			retweetedStatus = null;
			if (user)
				user.destroy();
			user = null;
		}
        
        //--------------------------------------------------------------------------
        //
        //  API
        //
        //--------------------------------------------------------------------------
    }
}