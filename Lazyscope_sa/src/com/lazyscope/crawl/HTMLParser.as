package com.lazyscope.crawl
{
	import com.lazyscope.Util;
	
	import flash.xml.XMLDocument;
	import flash.xml.XMLNode;
	import flash.xml.XMLNodeType;

	public class HTMLParser
	{
		public static var startTag:RegExp = /^<(\w+)((?:\s+\w+(?:\s*=\s*(?:(?:"[^"]*")|(?:'[^']*')|[^>\s]+))?)*)\s*(\/?)>/;
		public static var endTag:RegExp = /^<\/(\w+)[^>]*>/;
		public static var attr:RegExp = /(\w+)(?:\s*=\s*(?:(?:"((?:\\.|[^"])*)")|(?:'((?:\\.|[^'])*)')|([^>\s]+)))?/g;
		
		public static var empty:Object = makeMap('area,base,basefont,br,col,frame,hr,img,input,isindex,link,meta,param,embed');
		public static var block:Object = makeMap('address,applet,blockquote,button,center,dd,del,dir,div,dl,dt,fieldset,form,frameset,hr,iframe,ins,isindex,li,map,menu,noframes,noscript,object,ol,p,pre,script,table,tbody,td,tfoot,th,thead,tr,ul');
		public static var inline:Object = makeMap('a,abbr,acronym,applet,b,basefont,bdo,big,br,button,cite,code,del,dfn,em,font,i,iframe,img,input,ins,kbd,label,map,object,q,s,samp,script,select,small,span,strike,strong,sub,sup,textarea,tt,u,var');
		public static var closeSelf:Object = makeMap('colgroup,dd,dt,li,options,p,td,tfoot,th,thead,tr');
		public static var fillAttrs:Object = makeMap('checked,compact,declare,defer,disabled,ismap,multiple,nohref,noresize,noshade,nowrap,readonly,selected');
		public static var special:Object = makeMap('script,style');
		
		public static var denyTag:RegExp = /^(span|font|basefont|base|dfn|link|input|menu)$/i;
		public static var blackList:RegExp = /^(applet|frameset|iframe|frame|script|head|map|meta|style|select|option|comment)$/i;
		public static var denyImg:RegExp = /feeds2\.feedburner\.com|feedads\.g\.doubleclick\.net|res1\.blogblog\.com|hits\.guardian\.co\.uk|ads\.guardian\.co\.uk|www\.assoc\-amazon\.com|adserver\.3digit\.de|pheedo.com\/img\.phdo|pheedo\.com\/images\/mm\/|stats\.wordpress\.com\/b\.gif|rss\.feedsportal\.com\/|da\.feedsportal\.com\/r\/|feeds\.wordpress\.com\/1\.0\/|res1\.blogblog\.com\/tracker\/|d\.techcrunch\.com\/ck\.php|d1\.openx\.org\/ck\.php|feeds\.directnews\.co\.uk\/feedtrack\/|feeds\.feedburner\.com\/\~ff|feeds\.feedburner\.com\/\~r\/|reblog\.zemanta\.com\/zemified\/|\/wp\-content\/plugins\/|api\.tweetmeme\.com\/imagebutton\.gif/i;
		
		public function HTMLParser()
		{
		}
		
		public static function HTMLParse(html:String, handler:Object):void
		{
			if (html) {
				html = html.replace(/(<\/?)(\w+)/g, function():String {
					return arguments[1]+(arguments[2].toLowerCase());
				});
			}
			
			var index:Number, chars:Boolean, match:Array, stack:Array = [], last:String = html;
			stack.last = function():Object {
				if (stack.length > 0)
					return stack[stack.length-1];
				return null;
			};
			
			var parseStartTag:Function = function(tag:String, tagName:String, rest:String, unary:String=null, dummy1:Object=null, dummy2:Object=null, dummy3:Object=null, dummy4:Object=null):void {
				var bunary:Boolean;
				
				if (block[tagName]) {
					while (stack.last() && inline[stack.last()]) {
						parseEndTag("", stack.last());
					}
				}
				
				if ( closeSelf[ tagName ] && stack.last() == tagName ) {
					parseEndTag( "", tagName );
				}
				
				bunary = empty[ tagName ] || !!unary;
				
				if ( !bunary )
					stack.push( tagName );
				
				if ( handler.start ) {
					var attrs:Array = [];
					
					rest.replace(attr, function(match:Object, name:String):void {
						var value:String = arguments[2] ? arguments[2] :
						arguments[3] ? arguments[3] :
						arguments[4] ? arguments[4] :
						fillAttrs[name] ? name : "";
						
						attrs.push({
							name: name,
							value: value,
							escaped: value.replace(/(^|[^\\])"/g, '$1\\\"') //"
						});
					});
					
					if ( handler.start )
						handler.start( tagName, attrs, bunary );
				}
			};
			
			var parseEndTag:Function = function(tag:String=null, tagName:String=null, dummy1:Object=null, dummy2:Object=null):void {
				// If no tag name is provided, clean shop
				var pos:Number;
				if ( !tagName )
					pos = 0;
					
					// Find the closest opened tag of the same type
				else
					for ( pos = stack.length - 1; pos >= 0; pos-- )
						if ( stack[ pos ] == tagName )
							break;
				
				if ( pos >= 0 ) {
					// Close all the open elements, up the stack
					for ( var i:Number = stack.length - 1; i >= pos; i-- )
						if ( handler.end )
							handler.end( stack[ i ] );
					
					// Remove the open elements from the stack
					stack.length = pos;
				}
			};
			
			while ( html ) {
				chars = true;
				
				// Make sure we're not in a script or style element
				if ( !stack.last() || !special[ stack.last() ] ) {
					
					// Comment
					if ( html.indexOf("<!--") == 0 ) {
						index = html.indexOf("-->");
						
						if ( index >= 0 ) {
							if ( handler.comment )
								handler.comment( html.substring( 4, index ) );
							html = html.substring( index + 3 );
							chars = false;
						}else{
							html = '';
							chars = false;
						}
						
						// end tag
					} else if ( html.indexOf("</") == 0 ) {
						match = html.match( endTag );
						
						if ( match ) {
							html = html.substring( match[0].length );
							match[0].replace( endTag, parseEndTag );
							chars = false;
						}else{
							index = html.indexOf(">");
							if (index > -1) {
								html = html.substring( index+1 );
								chars = false;
							}else{
								break;
							}
						}
						
						// start tag
					} else if ( html.indexOf("<") == 0 ) {
						match = html.match( startTag );
						if ( match ) {
							html = html.substring( match[0].length );
							match[0].replace( startTag, parseStartTag );
							chars = false;
						}else{
							index = html.indexOf(">");
							if (index > -1) {
								html = html.substring( index+1 );
								chars = false;
							}else{
								break;
							}
						}
					}
					
					if ( chars ) {
						index = html.indexOf("<");
						
						var text:String = index < 0 ? html : html.substring( 0, index );
						html = index < 0 ? "" : html.substring( index );
						if ( handler.chars )
							handler.chars( text );
					}
				}else{
					index = html.indexOf('</'+(stack.last()));
					if (index > -1) {
						index = html.indexOf('>', index);
						if (index > -1)
							html = html.substr(index + 1);
					}else{
						if ( handler.chars )
							handler.chars( html );
						html = '';
					}
					
					parseEndTag( "", stack.last() );
				}
				
				if ( html == last )
					throw "Parse Error: " + html;
				last = html;
			}
			
			// Clean up any remaining tags
			parseEndTag();
		}
		
		public static function HTMLtoDOM(html:String, noStrict:Boolean=false):Object
		{
			var tt:Number = new Date().getTime();
			
			var doc:XMLDocument = new XMLDocument;
			doc.nodeName = 'HTML';
			var head:XMLNode = doc.createElement('head');
			var title:XMLNode = doc.createElement('title');
			var body:XMLNode = doc.createElement('body');
			doc.appendChild(head);
			head.appendChild(title);
			doc.appendChild(body);
			
			var data:Object = {images:[], videos:[], content:''};

			var curParentNode:XMLNode = body;
			
			var one:Object = {html:doc, head:head, title:title, body:body};
			var structure:Object = {
				link: 'head',
				base: 'head'
			};

			var elems:Array = [];
			var mc:Array;
			
			HTMLParse(html, {
				start: function(tagName:String, attrs:Array, unary:Boolean):void {
					if (tagName.match(denyTag)) return;
					
					// If it's a pre-built element, then we can ignore
					// its construction
					if ( one[tagName] ) {
						curParentNode = one[tagName];
						return;
					}
					
					var elem:XMLNode = doc.createElement(tagName);
					
					for (var attr:String in attrs) {
						if (noStrict) {
							switch (attrs[attr].name) {
								case 'style':
								case 'id':
								case 'class':
									elem.attributes[attrs[attr].name] = attrs[attr].value;
									break;
							}
						}else if (attrs[attr].name == 'style') {
							if (!attrs[attr].value) continue;
							var cssText:String = '';
							var css:Array = attrs[attr].value.split(/;/);
							for (var i:Number=0; i < css.length; i++) {
								var st:Array = css[i].toString().split(/:/, 2);
								if (!st || !st[0] || !st[1]) continue;
								switch (st[0]) {
									case 'float':
									case 'clear':
									case 'display':
									case 'text-align':
									case 'margin':
									case 'matgin-top':
									case 'margin-bottom':
									case 'margin-left':
									case 'margin-right':
										cssText += css[i]+';';
										break;
								}
							}
							if (cssText)
								elem.attributes['style'] = cssText;
							continue;
						}
						
						switch (tagName) {
							case 'a':
								switch (attrs[attr].name) {
									case 'href':
									case 'title':
										elem.attributes[attrs[attr].name] = attrs[attr].value;
										break;
								}
								break;
							case 'object':
							case 'img':
								switch (attrs[attr].name) {
									case 'width':
									case 'height':
									case 'src':
									case 'title':
									case 'alt':
									case 'align':
									case 'type':
									case 'data':
										elem.attributes[attrs[attr].name] = attrs[attr].value;
										break;
									case 'class':
										if (attrs[attr].value && (mc=attrs[attr].value.match(/align(right|left|center)/i))) {
											elem.attributes[attrs[attr].name] = 'align'+(mc[1].toLowerCase());
										}
										break;
								}
								break;
							case 'param':
								switch (attrs[attr].name) {
									case 'name':
									case 'value':
										elem.attributes[attrs[attr].name] = attrs[attr].value;
										break;
								}
								break;
							case 'embed':
								switch (attrs[attr].name) {
									case 'src':
										if (attrs[attr].value && attrs[attr].value.match(/\.swf|youtube\.com|hulu\.com|brightcove\.com/i)) {
											elem.attributes['type'] = 'application/x-shockwave-flash';
										}
										
										var tmp:Array = attrs[attr].value.match(/^http:\/\/(www\.)?youtube(\-nocookie)?\.com\/v\/([a-zA-Z0-9_\-]+)/i);
										if (tmp) {
											data.images.push('http://img.youtube.com/vi/'+(tmp[3])+'/hqdefault.jpg');
										}
									case 'width':
									case 'height':
									case 'align':
									case 'flashvars':
									case 'type':
										elem.attributes[attrs[attr].name] = attrs[attr].value;
										break;
								}
								break;
							default:
								switch (attrs[attr].name) {
									case 'colspan':
									case 'rowspan':
									case 'border':
									case 'cellpadding':
									case 'cellspacing':
									case 'title':
									case 'alt':
									case 'summary':
									case 'align':
									case 'valign':
									case 'span':
									case 'bgcolor':
										elem.attributes[attrs[attr].name] = attrs[attr].value;
										break;
								}
								break;
						}
					}
					
					if (tagName == 'object' || tagName == 'embed')
						elem.attributes['allowscriptaccess'] = 'never';
					else if (tagName == 'param' && elem.attributes['name'] == 'allowscriptaccess')
						elem.attributes['value'] = 'never';

					
					if ( structure[tagName] && typeof one[structure[ tagName ]] != "boolean" )
						one[structure[tagName]].appendChild(elem);
					else if (curParentNode)
						curParentNode.appendChild( elem );
					
					if (!unary) {
						elems.push( elem );
						curParentNode = elem;
					}
				},
				end: function(tag:String):void {
					if (tag.match(denyTag)) return;
					
					elems.pop();
					
					// Init the new parentNode
					curParentNode = elems[elems.length-1];
					if (!curParentNode) curParentNode = body;
				},
				chars: function(text:String):void {
					curParentNode.appendChild( doc.createTextNode( Util.htmlEntitiesDecode(text) ) );
				},
				comment: function(text:String):void {
					// create comment node
				}
			});
			
			//trace('public class HTMLParser check1 '+(new Date().getTime()-tt));

			for (var i:Number=body.childNodes.length; i--;) {
				var n:XMLNode = body.childNodes[i];
				if (!n || n.nodeType == XMLNodeType.TEXT_NODE) continue;
				trimElement(n, data);
			}
			
			//trace('public class HTMLParser check2 '+(new Date().getTime()-tt));
			
			var str:String = body.toString().replace(/^\s*<body>/, '').replace(/<\/body>\s*$/, '').replace(/<(\w+)([^\/]*)\/>/g, trimElements);
			
			data.content = str;
			data.title = title.toString().replace(/<\/?title[^>]*>/g, '');
			
			//trace('public class HTMLParser check3 '+(new Date().getTime()-tt));
			
			body.removeNode();
			title.removeNode();
			head.removeNode();
			body = head = title = null;
			html = null;
			
			data.video = data.videos.length > 0 ? data.videos[data.videos.length-1] : null;
			data.image = data.images.length > 0 ? data.images[data.images.length-1] : null;
			
			//trace('public class HTMLParser success '+(new Date().getTime()-tt));
			
			return data;
		}
		
		public static function trimElements():String
		{
			if (!empty[arguments[1]])
				return '';
			return arguments[0];
		}
		
		public static function trimElement(n:XMLNode, data:Object):void
		{
			if (n.nodeName && n.nodeName.match(blackList)) {
				n.removeNode();
				return;
			}
			
			if (n.attributes && n.attributes['style'] && n.attributes['style'].toString().match(/display\s*:\s*none/i)) {
				n.removeNode();
				return;
			}
			
			if (n.nodeName == 'img') {
				if (!n.attributes['src'] || n.attributes['src'].match(denyImg) || n.attributes['width'] == '1' || n.attributes['height'] == '1') {
					n.removeNode();
					return;
				}
				data.images.push(n.attributes['src']);
			}
			
			if (n.nodeName == 'param' && n.attributes['name']) {
				switch (n.attributes['name'].toString().toLowerCase()) {
					case 'allowscriptaccess':
						n.attributes['value'] = 'never';
						break;
					case 'src':
					case 'movie':
						data.videos.push(n.attributes['value']);
						break;
				}
			}
			
			if (n.childNodes && n.childNodes.length > 0) {
				for (var i:Number=n.childNodes.length; i--;) {
					var c:XMLNode = n.childNodes[i];
					if (!c) continue;
					trimElement(c, data);
				}
			}
			
			if ((n.nodeName == 'a' || n.nodeName == 'textarea') && (!n.childNodes || n.childNodes.length <= 0)) {
				n.removeNode();
				return;
			}
		}
		
		public static function makeMap(str:String):Object
		{
			var ret:Object = {};
			var arr:Array = str.split(/,/);
			for (var i:Number=0; i < arr.length; i++)
				ret[arr[i]]=true;
			
			return ret;
		}
		
		public static function extractTitle(html:String):String
		{
			if (!html) return '';
			var m:Array = html.match(/<title[^>]*>([^<]+)/i);
			if (m && m[1]) return m[1];
			return '';
		}
	}
}