package com.lazyscope.crawl
{
	import com.lazyscope.entry.Blog;
	import com.lazyscope.entry.BlogEntry;
	
	import flash.xml.XMLDocument;
	import flash.xml.XMLNode;
	
	public class Parser
	{
		public var doc:XMLDocument;
		
		//public var blog:Blog;
		//protected var entries:Array;
		protected var entryProcessed:Number;
		//protected var feedFunc:FeedFunc;
		
		public static function getFeedType(content:String):String {
			var head:String = content.substr(0, 1000);
			
			if (head.match(/<rss[^a-z]/i)) return 'rss';
			if (head.match(/<feed\s+[^>]*xmlns\s*=\s*['"][^>'"]*atom/i)) return 'atom';
			if (head.match(/<rdf\s+[^>]*xmlns\s*=\s*['"][^>'"]*rss/i)) return 'rss';
			if (head.match(/<rdf\s+[^>]*xmlns\s*=\s*['"][^>'"]*atom/i)) return 'atom';
			
			return '_unknown_feed_';
		}
		
		public static function getParser(content:String):Parser
		{
			var type:String = Parser.getFeedType(content);
			switch (type) {
				case 'rss':
					return Parser(new ParserRSS(content));
					break;
				case 'atom':
					return Parser(new ParserAtom(content));
					break;
			}
			return null;
		}
		
		public function Parser(content:String)
		{
			doc = new XMLDocument;
			doc.ignoreWhite = true;
			try{
				doc.parseXML(content);
			}catch(error:Error) {
				//trace(feedFunc.url, error.getStackTrace(), content);
			}
			
			//this.blog = new Blog;
			//this.blog.feedlink = feedFunc.feedURL;
			//this.entries = new Array;
		}
		
		//override
		public function getRootNode():XMLNode{return null;}
		public function parseBlog(node:XMLNode):Blog {return null;}
		public function parse(feedFunc:FeedFunc):void{}
		
		private function _returnEntry(entry:BlogEntry, feedFunc:FeedFunc):void
		{
			if (entry.content) {
				try{
					//trace('HTMLParser.HTMLtoDOM', entry.link);
					var content:Object = HTMLParser.HTMLtoDOM(entry.content);
					if (content && content.content) {
						entry.content = content.content;
						entry.image = content.image ? content.image : entry.image;
						entry.video = content.video ? content.video : entry.video;
					}
				}catch(e:Error) {
					trace(e.getStackTrace(), '_returnEntry parser');
				}
			}
			
			
//////// if you do not want to send it to server, then ...
//			entry.noRegister = true;
//			entry.blog = null;
			
			
			var parser:Parser = this;
			feedFunc.success(entry, true, function(id:Number):void {
				entryProcessed--;
				
				if (entryProcessed <= 0) {
					//epic end
					trace('fin!!!!!!!');
					feedFunc.checkFinish();
					feedFunc.log('all parser end');
					feedFunc.logFlush();
					return WorkingQueue.session().finish(parser);
				}
			});
		}
		
		public function returnEntry(entries:Array, feedFunc:FeedFunc):void
		{
			var entry:BlogEntry;
			entryProcessed = entries.length;
			for (var i:Number=0; i < entries.length; i++) {
				_returnEntry(BlogEntry(entries[i]), feedFunc);
			}
			
			feedFunc.log('convert req end');
		}
	}
}