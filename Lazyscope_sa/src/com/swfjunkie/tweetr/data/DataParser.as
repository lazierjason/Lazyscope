package com.swfjunkie.tweetr.data
{
    import com.swfjunkie.tweetr.data.objects.CursorData;
    import com.swfjunkie.tweetr.data.objects.DirectMessageData;
    import com.swfjunkie.tweetr.data.objects.ExtendedUserData;
    import com.swfjunkie.tweetr.data.objects.HashData;
    import com.swfjunkie.tweetr.data.objects.ListData;
    import com.swfjunkie.tweetr.data.objects.RelationData;
    import com.swfjunkie.tweetr.data.objects.StatusData;
    import com.swfjunkie.tweetr.data.objects.UserData;
    import com.swfjunkie.tweetr.utils.TweetUtil;
    
    /**
     * Static Class doing nothing more than Parsing to Data Objects
     * @author Sandro Ducceschi [swfjunkie.com, Switzerland]
     */
     
    public class DataParser 
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
        //--------------------------------------------------------------------------
        //
        //  Variables
        //
        //--------------------------------------------------------------------------
        //--------------------------------------------------------------------------
        //
        //  Properties
        //
        //--------------------------------------------------------------------------
        //--------------------------------------------------------------------------
        //
        //  Additional getters and setters
        //
        //--------------------------------------------------------------------------
        //--------------------------------------------------------------------------
        //
        // Overridden API
        //
        //--------------------------------------------------------------------------
        //--------------------------------------------------------------------------
        //
        //  API
        //
        //--------------------------------------------------------------------------
        /**
         * Parses a Status XML to StatusData Objects
         * @param xml        The XML Response from Twitter
         * @return An Array filled with StatusData's
         */ 
        public static function parseStatuses(xml:XML, extended:Boolean=false):Array
        {
            var statusData:StatusData;
            var userData:UserData;
            var array:Array = [];
            var list:XMLList = xml.status;
			if (!list) return array;

            var n:Number = list.length();
			if (n == 0) {
				if (xml.id != undefined && xml.created_at != undefined) {
					//updated status
					statusData = parseStatus(xml, extended);
					array.push(statusData);
				}
				return array;
			}
			
			var node:XML;
			if (n == 1) {
				node = list[0];
				//trace(list[0], node);
				statusData = parseStatus(node, extended);
                array.push(statusData);
			}else{
	            for (var i:int = 0; i < n; i++)
	            {
	                node = list[i];
	                statusData = parseStatus(node, extended);
	                array.push(statusData);
	            }
			}
            return array;
        }
        
        /**
         * Parses a Direct Message XML to DirectMessageData Objects
         * @param xml        The XML Response from Twitter
         * @return An Array filled with DirectMessageData's
         */ 
        public static function parseDirectMessages(xml:XML, extended:Boolean=false):Array
        {
            var senderData:UserData;
            var recipientData:UserData;
            var directData:DirectMessageData;
            var array:Array = [];
            var list:XMLList = xml.direct_message;
			
			if (!list) return array;
			
            var n:Number = list.length();
			if (n == 0) return array;
			
            for (var i:Number = 0; i < n; i++)
            {
                var node:XML = list[i] as XML;
				
                directData = new DirectMessageData(
                                                    node.id,
                                                    node.sender_id,
                                                    node.text,
                                                    node.recipient_id,
                                                    node.created_at,
                                                    node.sender_screen_name,
                                                    node.recipient_screen_name
                                                  );
				
				senderData = new UserData(
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
                
				recipientData = new UserData(
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
                array.push(directData);
            }
            return array;   
        }
        
         /**
         * Parses a User XML to either UserData or ExtendedUserData Objects
         * @param xml        The XML Response from Twitter
         * @param extended   Should extended User Element be retrieved
         * @return An Array filled with either UserData or ExtendedUserData Objects
         */ 
        public static function parseUserInfos(xml:XML, extended:Boolean = true):Array
        {
            var statusData:StatusData;
            var userData:UserData;
            var extendedData:ExtendedUserData;
            var array:Array = [];
            var list:XMLList = xml..user;
            var n:Number = (list.length() == 0) ? 1 : list.length();
            
            for (var i:Number = 0; i < n; i++)
            {
                var node:XML = (n > 1) ? list[i] as XML : xml;
                if (node.id.toString() == "")
                    node = list[i] as XML;
                
                if (node)
                {
                    statusData = new StatusData(node.status.created_at,
                                                node.status.id,
                                                TweetUtil.tidyTweet(node.status.text),
                                                node.status.source,
                                                TweetUtil.stringToBool(node.status.truncated),
                                                node.status.in_reply_to_status_id,
                                                node.status.in_reply_to_user_id,
                                                TweetUtil.stringToBool(node.status.favorited),
                                                node.status.in_reply_to_screen_name);
                
                    userData = new UserData(node.id,
                                            node.name,
                                            node.screen_name,
                                            node.location,
                                            node.description,
                                            node.profile_image_url,
                                            node.url,
                                            TweetUtil.stringToBool(node['protected']),
                                            node.followers_count);
                                                                              
                    userData.lastStatus= statusData;
                    
                    if (extended)
                    {
                        extendedData = new ExtendedUserData(
                                                            parseInt("0x"+node.profile_background_color),
                                                            parseInt("0x"+node.profile_text_color),
                                                            parseInt("0x"+node.profile_link_color),
                                                            parseInt("0x"+node.profile_sidebar_fill_color),
                                                            parseInt("0x"+node.profile_sidebar_border_color),
                                                            node.friends_count,
                                                            node.created_at,
                                                            node.favourites_count,
                                                            node.utc_offset,
                                                            node.time_zone,
                                                            node.profile_background_image_url,
                                                            TweetUtil.stringToBool(node.profile_background_tile),
                                                            TweetUtil.stringToBool(node.following),
                                                            TweetUtil.stringToBool(node.notificactions),
                                                            node.statuses_count,
                                                            node.listed_count,
															TweetUtil.stringToBool(node.user.verified)
                                                            );
                        userData.extended = extendedData;
                    }
                    array.push(userData);
                }
            }
            return array;   
        }
        
        /**
         * Parses a Relation XML to an Array
         * @param xml        The XML Response from Twitter
         * @return An Array with a source and a target RelationData
         */
        public static function parseRelationship(xml:XML):Array
        {
            var array:Array = [];
            
            var target:RelationData = new RelationData();
            target.type = RelationData.RELATION_TYPE_TARGET;
            target.id = parseFloat(xml.target.id);
            target.screenName = xml.target.screen_name;
            target.following = TweetUtil.stringToBool(xml.target.following);
            target.followedBy = TweetUtil.stringToBool(xml.target.followed_by);
            target.notificationsEnabled = TweetUtil.stringToBool(xml.target.notifications_enabled);
            
            var source:RelationData = new RelationData();
            source.type = RelationData.RELATION_TYPE_SOURCE;
            source.id = parseFloat(xml.source.id);
            source.screenName = xml.source.screen_name;
            source.following = TweetUtil.stringToBool(xml.source.following);
            source.followedBy = TweetUtil.stringToBool(xml.source.followed_by);
            source.notificationsEnabled = TweetUtil.stringToBool(xml.source.notifications_enabled);
            
            array.push(target);
            array.push(source);
            return array;
        }
        
        /**
         * Parses a ID XML to an Array
         * @param xml        The XML Response from Twitter
         * @return An Array filled numeric Id's
         */ 
        public static function parseIds(xml:XML):Array
        {
            var array:Array = [];
            var list:XMLList = xml..id;
            var n:Number = (list.length() == 0) ? 1 : list.length();
            
            for (var i:Number = 0; i < n; i++)
            {
                var node:XML = (n > 1) ? list[i] as XML : xml;
                array.push(Number(node));
            }
            return array;
        }
        
        /**
         * Parses a List XML to an Array
         * @param xml   The XML Response from twitter
         * @return An Array filled with ListDatas
         */ 
        public static function parseLists(xml:XML):Array
        {
            var listData:ListData;
            var userData:UserData;
            var extendedData:ExtendedUserData;
            var array:Array = [];
            var list:XMLList = xml..list;
            var n:Number = (list.length() == 0) ? 1 : list.length();
            
            for (var i:Number = 0; i < n; i++)
            {
                var node:XML = (n > 1) ? list[i] as XML : xml;
                
                if (node.id.toString() == "")
                    node = list[i] as XML;
                
                if (node)
                {
                    listData = new ListData();
                    listData.id = parseFloat(node.id);
                    listData.name = node.name;
                    listData.fullName = node.full_name;
                    listData.slug = node.slug;
                    listData.description = node.description;
                    listData.subscriberCount = parseFloat(node.subscriber_count);
                    listData.memberCount = parseFloat(node.member_count);
                    listData.uri = node.uri;
                    listData.isPublic = (node.mode == "public") ? true : false;
                    
                    
                    userData = new UserData(node.user.id,
                        node.user.name,
                        node.user.screen_name,
                        node.user.location,
                        node.user.description,
                        node.user.profile_image_url,
                        node.user.url,
                        TweetUtil.stringToBool(node.user['protected']),
                        node.user.followers_count);
                    
                    listData.user = userData;
                    
                    extendedData = new ExtendedUserData(
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
                    )
                    userData.extended = extendedData;
                    array.push(listData);
                }
            }
            return array;
        }
        
        
        /**
         * Parses Cursor Information if the response supplied by twitter contains it.
         * @param xml        The XML Response from Twitter
         * @return A CursorData Object
         */ 
        public static function parseCursor(xml:XML):CursorData
        {
            if (xml..next_cursor.toString() != "" && xml.previous_cursor.toString() != "")
//                return new CursorData(parseFloat(xml..next_cursor.toString()), parseFloat(xml.previous_cursor.toString()));
                return new CursorData(xml..next_cursor.toString(), xml.previous_cursor.toString());
            return null;
        }
        
        
        /**
         * Parses a Hash XML to HashData Objects
         * @param xml  The XML Response from Twitter
         * @return An Array filled with HashData Objects
         */ 
        public static function parseHash(xml:XML):Array
        {
            var array:Array = [];
            var hashData:HashData = new HashData();
            hashData.hourlyLimit = xml['hourly-limit'];
            hashData.remainingHits = xml['remaining-hits'];
            hashData.resetTimeInSeconds = xml['reset-time-in-seconds'];
            hashData.request = xml['request'];
            hashData.error = xml['error'];
            
            array.push(hashData);
            return array;   
        }
        
        
        /**
         * Parses out Boolean value from a <code>hasFriendship</code> Request
         * @param xml  The XML Response from Twitter
         * @return A Boolean value
         */ 
        public static function parseBoolean(xml:XML):Array
        {
            var array:Array = [];
            array.push(TweetUtil.stringToBool(xml.toString()));
            return array;   
        }
        
        
        
        //--------------------------------------------------------------------------
        //
        //  Overridden methods: _SuperClassName_
        //
        //--------------------------------------------------------------------------
        
        //--------------------------------------------------------------------------
        //
        //  Methods
        //
        //--------------------------------------------------------------------------
        
        private static function parseStatus(node:XML, extended:Boolean=false):StatusData
        {
            var statusData:StatusData = new StatusData(node.created_at,
				node.id,
                TweetUtil.tidyTweet(node.text),
				node.source,
                TweetUtil.stringToBool(node.truncated),
				node.in_reply_to_status_id,
				node.in_reply_to_user_id,
                TweetUtil.stringToBool(node.favorited),
				node.in_reply_to_screen_name);
            
            if (node.retweeted_status.hasComplexContent())
                statusData.retweetedStatus = parseStatus(node.retweeted_status[0] as XML);
            
            if (node.geo.hasComplexContent())
            {
                namespace point = "http://www.georss.org/georss";
                use namespace point;
                var points:Array = String(node.geo.point).split(" ");
                statusData.geoLat = parseFloat(points[0]);
                statusData.geoLong = parseFloat(points[1]);
            }

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
        
        //--------------------------------------------------------------------------
        //
        //  Broadcasting
        //
        //--------------------------------------------------------------------------
        
        //--------------------------------------------------------------------------
        //
        //  Eventhandling
        //
        //--------------------------------------------------------------------------
    }
}