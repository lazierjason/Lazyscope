package com.lazyscope.crawl
{
	import com.lazyscope.URL;
	import com.lazyscope.Util;
	import com.lazyscope.entry.Blog;
	import com.lazyscope.entry.BlogEntry;
	
	import flash.xml.XMLNode;

	public class ParserRSS extends Parser
	{
		public function ParserRSS(content:String)
		{
			super(content);
		}

		public function getEntry(root:XMLNode, blog:Blog, feedFunc:FeedFunc):void
		{
			var node:XMLNode = root.firstChild;
			var entry:BlogEntry;
			var val:String;
			var entries:Array = new Array;
			
			feedFunc.log('RSS - getEntry start');
			
			var now:Number = (new Date).getTime();

			while (node)
			{
				val=(node.firstChild?node.firstChild.nodeValue:node.nodeValue);
				switch (node.nodeName)
				{
					case 'item':
						entry = ParserRSS.parseEntry(blog, node.firstChild);
						if (entry != null && entry.link && entry.link.match(/^https?:\/\//)) {
							
							if (!entry.published) {
								entry.published = new Date;
								entry.published.setTime(now);
								now -= 1000;
							}
							
							entries.push(entry);
						}
						break;
				}
				
				node = node.nextSibling;
			}
			feedFunc.log('RSS - getEntry end');
			
			if (!entries || entries.length <= 0) {
				//epic end (no entry in feed)
				feedFunc.fail('No entries in feed!', true);
				return WorkingQueue.session().finish(this);
			}else{
				return super.returnEntry(entries, feedFunc);
			}
		}
		
		override public function parseBlog(node:XMLNode):Blog
		{
			var val:String;
			var check:Number = 0;
			
			var blog:Blog = new Blog;

			while (node)
			{
				val=(node.firstChild?node.firstChild.nodeValue:node.nodeValue);
				switch (node.nodeName)
				{
					case 'title':
					case 'description':
						blog[node.nodeName] = val;
						check++;
						break;
					case 'link':
						blog[node.nodeName] = URL.normalize(val);
						check++;
						break;
				}
				
				if (check >= 3)
					break;
				node = node.nextSibling;
			}

			return blog;
		}
		
		override public function getRootNode():XMLNode
		{
			var root:XMLNode = doc.firstChild;
			if (root == null || root.nodeName != 'rss')
				return null;
				
			if (root.firstChild && root.firstChild.nodeName == 'channel')
				return root.firstChild;
			else
				if (root.childNodes.length > 1)
					for (var i:Number = 1; i < root.childNodes.length && i < 5; i++)
						if (root.childNodes[i] && root.childNodes[i].nodeName == 'channel')
							return root.childNodes[i];

			return null;
		}
		
		override public function parse(feedFunc:FeedFunc):void
		{
			var root:XMLNode = getRootNode();
			if (!root) {
				feedFunc.fail('invalid rss', true, true);
				return WorkingQueue.session().finish(this);
			}
			var node:XMLNode = root.firstChild;
			var entry:BlogEntry;

			var blog:Blog = parseBlog(node);
			
			feedFunc.blog = blog;
			
			feedFunc.log('RSS - blog parsed');
			
			var parser:Parser = this;
			Blog.getBlogID(blog.link, function(blogId:Number):void {
				if (blogId < 0) {
					Blog.register(blog, function(blogId:Number):void {
						if (blogId < 0) {
							trace('Blog.register error');
							feedFunc.fail('blog register error');
							return WorkingQueue.session().finish(parser);
						}
						getEntry(root, blog, feedFunc);
					});
				}else{
					blog.id = blogId;
					getEntry(root, blog, feedFunc);
				}
			});
		}
		
		public static function parseEntry(blog:Blog, node:XMLNode):BlogEntry
		{
			if (!node || !blog || !blog.link)
				return null;
			
			var entry:BlogEntry = new BlogEntry;
			entry.blog = blog;
			entry.source = 'rss';
			
			var _link:String;
			
			while (node)
			{
				if (!node.nodeName) {
					node = node.nextSibling;
					continue;
				}
				var val:String=(node.firstChild?node.firstChild.nodeValue:node.nodeValue);
				//				if (!val)
				//				{
				//					node = node.nextSibling;
				//					continue;
				//				}
				_link = null;
				
				switch (node.nodeName.toLowerCase())
				{
					case 'title':
					case 'description':
					case 'content':
						if (entry[node.nodeName.toLowerCase()]) break;
						entry[node.nodeName.toLowerCase()] = val;
						break;
					case 'link':
						if (node.attributes && node.attributes.rel == 'alternate' && node.attributes.href)
							_link = URL.normalize(node.attributes.href);
						else if (!entry.link && val)
							_link = URL.normalize(val);
						else if (!entry.link && node.attributes && node.attributes.href)
							_link = URL.normalize(node.attributes.href);
						
						if (_link && URL.isValidPermalink(_link, blog.link))
							entry.link = _link;
						break;
					case 'pheedo:origlink':
					case 'feedburner:origlink':
						_link = URL.normalize(val);
						
						if (_link && URL.isValidPermalink(_link, blog.link))
							entry.link = _link;
						break;
					case 'dc:title':
						entry.title = val;
						break;
					case 'dc:description':
						entry.description = val;
						break;
					case 'pubdate':
					case 'dcterms:issued':
					case 'dc:date':
					case 'dcterms:created':
					case 'dcterms:created':
						entry.published = Util.parseDate(val);
						break;
					case 'content:encoded':
					case 'body':
					case 'xhtml:body':
					case 'fullitem':
					case 'atom:summary':
						entry.content = val;
						break;
					case 'category':
					case 'dc:subject':
					case 'media:category':
					case 'media:keywords':
					case 'prism:category':
						if (val) {
							entry.category.push(val);
						}else if (node.attributes && node.attributes.term) {
							entry.category.push(node.attributes.term);
						}
						break;
					
					// image & video
					case 'media:thumbnail':
						if (!entry.image && node.attributes)
							entry.image = node.attributes.url;
						break;
					case 'media:content':
						if (!entry.image && node.attributes && node.attributes.url && node.attributes.medium == 'image' && !node.attributes.url.match(/gravatar.com\/avatar\//))
							entry.image = node.attributes.url;
						else if (!entry.video && node.attributes && node.attributes.url && node.attributes.medium == 'video')
							entry.video = node.attributes.url;
						break;
					case 'image':
					case 'rmcr:largeimage':
					case 'rmcr:smallimage':
						if (!entry.image)
							entry.image = val;
						break;
					case 'enclosure':
						if (node.attributes && node.attributes.type && node.attributes.url) {
							var mediaType:String = node.attributes.type.substr(0, 5).toLowerCase();
							switch (mediaType) {
								case 'image':
									entry.image = entry.image ? entry.image : node.attributes.url;
									break;
								case 'video':
									entry.video = entry.video ? entry.video : node.attributes.url;
									break;
								case 'audio':	// TODO later
								default:
									break;
							}
						}
						break;
					//case 'userurl': break;	// author's uri
					default:
						//trace(node.nodeName+': '+val);
						break;
				}
				
				node = node.nextSibling;
			}
			
			if (!entry.title || !entry.link)
				return null;
			
			if (!entry.content && entry.description)
				entry.content = entry.description;
			else if (entry.content && !entry.description)
				entry.description = entry.content;
			
			if (!entry.content) entry.content='';
			if (!entry.description) entry.description='';
			//entry.description = entry.description.replace(/<[^>]+>/g, '').substr(0, 400);	// TODO
			entry.description = entry.description.replace(/<[^>]+>/g, '');
			if (entry.description.length > 400)
				entry.description = entry.description.substr(0, 400).replace(/\s+[^\s]*$/, '...');
			
			return entry;
		}
	}
}