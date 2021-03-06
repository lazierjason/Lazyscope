package com.lazyscope.content
{
	import com.lazyscope.DB;
	//import com.lazyscope.DataServer;
	import com.lazyscope.Util;
	import com.lazyscope.crawl.Crawler;
	import com.lazyscope.entry.Blog;
	import com.lazyscope.entry.BlogEntry;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.HTMLUncaughtScriptExceptionEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.html.HTMLLoader;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	import flash.utils.setTimeout;
	
	import mx.utils.URLUtil;

	public class ReadabilityEx extends EventDispatcher
	{
		public var id:Number;
		private var html:HTMLLoader = null;
		private var _url:String;
		private var callback:Function;
		private var entry:BlogEntry;
		private var completed:Boolean;
		private var blog:Blog;
		private var fname:String;
		private var retry:Number;
		
		private var bt:Number;
		
		public var working:Boolean = false;
		
		private static var _code:String = null;
		private static function getCode():String
		{
			if (!ReadabilityEx._code) {
				var file:File = new File('app:///readability/__src.js');
				var fileStream:FileStream = new FileStream();
				fileStream.open(file, FileMode.READ);
				ReadabilityEx._code = fileStream.readMultiByte(file.size, File.systemCharset);
				fileStream.close();
			}
			return ReadabilityEx._code;
		}
		
		public function ReadabilityEx()
		{
			super();
		}
		
		public function run(url:String, content:ByteArray, callback:Function=null, e:BlogEntry=null, blog:Blog=null):void
		{
//			trace('Readability', id, 'run', url, callback);
			if (callback == null) {
				_finalize();
				return;
			}
			
			if (!html) {
				html = new HTMLLoader;
				
				html.useCache = true;
				html.visible = false;
				
				html.addEventListener(HTMLUncaughtScriptExceptionEvent.UNCAUGHT_SCRIPT_EXCEPTION, ignoreError, false, 0, true);
				html.addEventListener(Event.HTML_DOM_INITIALIZE, complete, false, 0, true);
				html.addEventListener(Event.COMPLETE, complete, false, 0, true);
			}
			
			working = true;
			bt = new Date().getTime();
			
			entry = e;
			this.blog = blog;
			
			_url = url;
			
			this.callback = callback;
			
			completed = false;
			
			fname = convertFile(content);
			
			analyzeHTML(url, fname);
		}
		
		private function convertFile(content:ByteArray):String
		{
			content.position = 0;
			var convert:String = '';
			for (var i:Number = content.length; i--;) {
				var c:uint = content.readUnsignedByte();
				convert += String.fromCharCode(c);
			}
			
			convert = convert.replace(/<(\/?)(iframe|script|frame)/gi, '<$1no$2 style="display:none;"').replace(/allowscriptaccess\s*=\s*['"]?always['"]?/i, 'allowscriptaccess="never"').replace(/value\s*=\s*['"]?always['"]?/i, 'value="never"').replace(/\s+on(error|load)/gi, ' no($1)');
			content.clear();
			for (i=0; i < convert.length; i++) {
				content.writeByte(convert.charCodeAt(i));
			}
			content.position = 0;
			
			var name:String = File.createTempFile().url+'.htm';
			Util.writeContent(name, content);

			return name;
		}
		
		private function finalize():void
		{
//			trace('Readability', id, 'finish', _url, new Date().getTime()-bt);
			
			html.cancelLoad();
			html.loadString('<html></html>');
			html.cancelLoad();

			if (fname != null) {
				try{
					Util.deleteFile(fname.replace(/\.htm$/, ''));
					Util.deleteFile(fname);
				}catch(error:Error) {
//					trace('Readability', id, error.getStackTrace(), 'analyzeHTML3');
				}
			}

			fname = null;
			blog = null;
			entry = null;
			callback = null;
			_url = null;
			
			setTimeout(_finalize, 100);
		}
		
		private function _finalize():void
		{
			working = false;
			dispatchEvent(new Event('finish'));
		}
		
		private function finish():void
		{
//			trace('Readability', id, 'finish____', _url);
			if (callback != null)
				callback(entry);
			
			finalize();
		}
		
		private function jsResult(link:String, title:String, content:String, imgLink:String):void {
//			trace('Readability', id, 'jsResult', _url);
			try{
				if (callback != null) {
					if (content) {
						if (!entry)
							entry = new BlogEntry;
						if (!entry.blog && blog)
							entry.blog = blog;
						entry.link = link?link:entry.link;
						entry.title = entry.title && entry.title != ''?entry.title:title;
						entry.image = entry.image && entry.image != ''?entry.image:imgLink;
						entry.content = content;
						entry.description = content.replace(/<[^>]+>/g, '').replace(/\s+/g, ' ').replace(/^\s+|\s+$/g, '');
						entry.published.setTime(-1);
						if (entry.description.length > 400)
							entry.description = entry.description.substr(0, 400).replace(/\s+[^\s]*$/, '...');
						entry.source = 'readability';
						
						DB.session().execute('insert into p4_readability(link, title, description, content, image, time_register, host) values(:link, :title, :description, :content, :image, :time_register, :host)', {
							':link': entry.link,
							':title': entry.title,
							':description': entry.description,
							':content': entry.content,
							':image': entry.image,
							':time_register': int(((new Date()).getTime())/1000),
							':host': entry.blog?entry.blog.link:null
						});
						
						//DataServer.request('RP', entry.toURLVariable()+(blog?'&entry[host]='+encodeURIComponent(blog.link):''));
					}
				}
			}catch(error:Error) {
//				trace('Readability', id, error.getStackTrace(), 'analyzeHTML6');
			}
//			trace('Readability', id, 'LF_loadFinish', content.length);
			finish();
		}
		
		private function complete(event:Event):void
		{
			if (completed) return;
//			trace('Readability', id, event, html.location);
			retry = 0;
			completed = true;
			if (event.type == Event.COMPLETE)
				complete2();
			else
				setTimeout(complete2, 10);
		}
		
		private function complete2():void
		{
			retry++;
			
			html.window.trace = trace;
			html.window._LF_resolveURL = URLUtil.getFullURL;
			html.window._LF_link = _url;			
			html.window.LF_loadFinish = jsResult;

//			trace('Readability', id, 'complete2', html.location);
			try{
				if (!html.window.document || retry >= 10)
					return finish();
				
				if (!html.window.document.body) {
					retry++;
					setTimeout(complete2, 100);
					return;
				}
			}catch(error:Error) {
//				trace('Readability', id, error.getStackTrace(), 'analyzeHTML4');
				return finish();
			}
			
			html.cancelLoad();
			
			try{
				var script:Object = html.window.document.createElement('SCRIPT');
				script.type = 'text/javascript';
				script.charset='UTF-8';
				script.textContent=getCode();
				html.window.document.documentElement.appendChild(script);
				//trace('Readability', id, html.window.document.documentElement.innerHTML);
			}catch(error:Error) {
//				trace('Readability', id, error.getStackTrace(), 'analyzeHTML7');
				return finish();
			}
		}
		
		private function ignoreError(event:HTMLUncaughtScriptExceptionEvent):void
		{
			html.cancelLoad();
			return finish();
//			trace('Readability', id, 'ignoreError', event);
			for (var i:Number=0; i < event.stackTrace.length; i++) {
//				trace('Readability', id, event.stackTrace[i].sourceURL, event.stackTrace[i].line, event.stackTrace[i].functionName);
			}
			event.preventDefault();
			event.stopPropagation();
		}
		
		private function analyzeHTML(url:String, fname:String):void
		{
//			trace('Readability', id, 'analyzeHTML start', url);
			
			if (Crawler.isBinaryFile(url) || !fname)
				return finish();
			
			try{
				html.load(new URLRequest(fname));
			}catch(error:Error) {
//				trace('Readability', id, error.getStackTrace(), 'analyzeHTML9');
				finish();
			}
		}
	}
}