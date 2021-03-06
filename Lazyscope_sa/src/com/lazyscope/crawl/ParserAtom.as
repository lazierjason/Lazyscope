package com.lazyscope.crawl
{
	import com.lazyscope.URL;
	import com.lazyscope.Util;
	import com.lazyscope.entry.Blog;
	import com.lazyscope.entry.BlogEntry;
	
	import flash.xml.XMLNode;

	public class ParserAtom extends Parser
	{
		public function ParserAtom(content:String)
		{
			super(content);
		}
		
		public function getEntry(root:XMLNode, blog:Blog, feedFunc:FeedFunc):void
		{
			var node:XMLNode = root.firstChild;
			var entry:BlogEntry;
			var val:String;
			var entries:Array = new Array;
			
			feedFunc.log('ATOM - getEntry start');
			
			var now:Number = (new Date).getTime();
			
			while (node)
			{
				val=(node.firstChild?node.firstChild.nodeValue:node.nodeValue);
				switch (node.nodeName)
				{
					case 'entry':
						entry = ParserAtom.parseEntry(blog, node.firstChild);
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
			feedFunc.log('ATOM - getEntry end');
			
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
			
			var blog:Blog = new Blog;

			while (node)
			{
				if (!node.nodeName) {
					node = node.nextSibling;
					continue;
				}
				val=(node.firstChild?node.firstChild.nodeValue:node.nodeValue);
				switch (node.nodeName.replace(/^atom[0-9]+:/i, '')) {
					case 'title':
					case 'description':
						blog[node.nodeName] = val;
						break;
					case 'link':
						if (node.attributes && node.attributes.rel == 'alternate' && node.attributes.href)
							blog.link = URL.normalize(node.attributes.href);
						else if (!blog.link && node.attributes && node.attributes.rel != 'self' && node.attributes.rel != 'hub' && node.attributes.href)
							blog.link = URL.normalize(node.attributes.href);
						break;
					default:
						break;
				}
				node = node.nextSibling;
			}

			return blog;
		}
		
		override public function getRootNode():XMLNode
		{
			var root:XMLNode = doc.firstChild;
			
			if (root == null || root.nodeName != 'feed') {
				return null;
			}
			return root;
		}
		
		override public function parse(feedFunc:FeedFunc):void
		{
			var root:XMLNode = getRootNode();
			if (!root) {
				feedFunc.fail('invalid feed (atom)', true, true);
				return WorkingQueue.session().finish(this);
			}
			var node:XMLNode = root.firstChild;
			
			var entryNodes:Array = new Array;
			
			var blog:Blog = parseBlog(node);
			
			feedFunc.blog = blog;
			
			feedFunc.log('ATOM - blog parsed');
			
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
			entry.source = 'atom';
			
			var _link:String;
			
			while (node)
			{
				if (!node.nodeName) {
					node = node.nextSibling;
					continue;
				}
				
				var val:String=(node.firstChild?node.firstChild.nodeValue:node.nodeValue);
				_link = null;
				
				switch (node.nodeName.toLowerCase())
				{
					case 'title':
					case 'description':
						entry[node.nodeName.toLowerCase()] = val?val.replace(/^\s+|\s+$/g, ''):null;
						break;
					case 'content':
						//if (entry.content) break;
						entry.content = val?val.replace(/^\s+|\s+$/g, ''):null;
						if (!entry.content && node.firstChild) {
							var tmp:String = node.firstChild.toString();
							if (tmp)
								entry.content = tmp;
						}
						break;
					case 'summary':
						if (!entry.content)
							entry.content = val;
						break;
					case 'published':
						entry.published = Util.parseDate(val);
						break;
					case 'updated':
					case 'issued':
					case 'modified':
					case 'created':
						if (!entry.published)
							entry.published = Util.parseDate(val);
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
					case 'category':
					case 'dc:subject':
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
					//case 'author': break;	// author's name, uri, email
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
			entry.description = entry.description.replace(/<[^>]+>/g, '').replace(/^\s+|\s+$/g, '');
			if (entry.description.length > 400)
				entry.description = entry.description.substr(0, 400).replace(/\s+[^\s]*$/, '...');
			
			/*
			BlogEntry.getEntryID(entry.link, function(id:Number):void {
			if (id > 0)
			entry.id = id;
			returnEntry(entry);
			});
			*/
			
			//			
			//trace('------------------------------------------------------------');
			//trace('*LINK:',entry.link);
			//trace('*TITL:',entry.title);
			//trace('*TIME:',entry.published);
			//trace('*DESC:',entry.description);
			//trace('*CONT:',entry.content);
			//trace('*IMAG:',entry.image);
			//trace('*VIDE:',entry.video);
			//trace('****** BLOG *******');
			//trace('-URL:', entry.blog.link);
			//trace('-TIT:', entry.blog.title);
			//trace('------------------------------------------------------------');
			
			return entry;
		}
	}
}