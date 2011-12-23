package com.lazyscope
{
	import flash.desktop.NativeApplication;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.text.TextField;
	import flash.utils.ByteArray;
	
	import flashx.textLayout.elements.Configuration;
	import flashx.textLayout.formats.TextLayoutFormat;
	
	import mx.controls.Alert;
	import mx.core.UIComponent;
	import mx.events.CloseEvent;
	import mx.formatters.DateFormatter;
	
	import spark.components.Image;
	import spark.primitives.BitmapImage;
	
	public class Util
	{
		public function Util()
		{
		}
		
		public static function getVersion():String
		{
			var descriptor:XML = NativeApplication.nativeApplication.applicationDescriptor;
			var ns:Namespace = descriptor.namespaceDeclarations()[0];
			return descriptor.ns::versionNumber;
		}
		
		public static function trim(s:String, whiteSpaceCollapse:Boolean=false):String
		{
			if (!s) return '';
			if (whiteSpaceCollapse)
				return s.replace(/\s+/, ' ').replace(/^\s+/, '').replace(/\s+$/, '');
			else
				return s.replace(/^\s+/, '').replace(/\s+$/, '');
		}
		
		public static function parseDate(text:String):Date {
			/* patterns
			Fri, 30 Jan 2009 07:12:00 +0000
			2009-01-29T23:12:00.001-08:00
			2010-09-11T16:50:29Z
			2009-01-29T23:12:00.001-08:00
			*/
			if (!text) return null;
			
			text = text
				.replace(/HAST/, 'UTC-1000').replace(/HADT/, 'UTC-0900').replace(/AKST/, 'UTC-0900').replace(/ASDT/, 'UTC-0800')
				.replace(/PST/, 'UTC-0800').replace(/PDT/, 'UTC-0700').replace(/MST/, 'UTC-0700').replace(/MDT/, 'UTC-0600')
				.replace(/CST/, 'UTC-0600').replace(/CDT/, 'UTC-0500').replace(/EST/, 'UTC-0500').replace(/EDT/, 'UTC-0400')
				.replace(/AST/, 'UTC-0400').replace(/ADT/, 'UTC-0300').replace(/NST/, 'UTC-0330').replace(/NDT/, 'UTC-0230');
			
			var txt:String = text.replace(/^(\d\d\d\d)\-(\d\d)\-(\d\d)\s*T(\d\d:\d\d:\d\d)(\.\d+)?\s*(.*)$/i, '$1/$2/$3 $4<$6>').replace(/<\s*([\+\-]\d\d):?(\d\d)>/i, ' GMT$1$2').replace(/<\s*Z>/, ' GMT-0000');
			var date:Date = new Date(txt);
			if (isNaN(date.getTime())) {
				date = DateFormatter.parseDateString(text);
			}
			
			/*
			var date:Date = DateFormatter.parseDateString(text);
			if (isNaN(date.getTime())) {
			text = text.replace(/^(\d\d\d\d)\-(\d\d)\-(\d\d)\s*T(\d\d:\d\d:\d\d)(\.\d+)?\s*(.*)$/i, '$1/$2/$3 $4<$6>');
			text = text.replace(/<\s*([\+\-]\d\d):?(\d\d)>/i, ' GMT$1$2');
			text = text.replace(/<\s*Z>/, ' GMT-0000');
			
			date = DateFormatter.parseDateString(text);
			if (isNaN(date.getTime())) {
			date = new Date(text);
			}
			}
			*/
			
			return date;
		}
		
		public static function htmlEntitiesDecode(text:String):String
		{
			if (!text) return '';
			return text.replace(/&[^;]{2,6};/g, function():String {
				return new XML(arguments[0]).toString();
				//return new XMLDocument(arguments[0]).firstChild.nodeValue;
			});
		}
		
		public static function toIntervalString(time:Number, now:Number=0):String {
			var date:Date=new Date();
			
			var sec:Number=(now > 0?now:Math.floor(date.getTime()/1000))-Math.floor(time);
			if (!sec || sec <= 0) return 'now';
			
			var tmp:Number;
			
			if (sec >= 60*60*24*7) {
				date.setTime(time*1000);
				return date2str(date, 'M d, Y');
			}else if (sec >= 60*60*24) {
				tmp=Math.floor(sec/(60*60*24));
				return tmp+(' day'+(tmp > 1?'s':'')+' ago');
			}else if (sec >= 60*60) {
				tmp=Math.floor(sec/(60*60));
				return tmp+(' hour'+(tmp > 1?'s':'')+' ago');
			}else if (sec >= 60) {
				tmp=Math.floor(sec/(60));
				return tmp+(' minute'+(tmp > 1?'s':'')+' ago');
			}else if (sec > 0)
				return sec+(' second'+(sec > 1?'s':'')+' ago');
			else
				return 'now';
		}
		
		public static function date2str(date:Date, format:String):String {
			var ret:String='';
			
			for (var i:Number=0; i < format.length; i++) {
				if (format.charAt(i) == '\\') continue;
				if (format.charAt(i-1) == '\\') {
					ret+=format.charAt(i);
					continue;
				}
				switch (format.charAt(i)) {
					case 'a':
						ret+=date.getHours() >= 12?'pm':'am';
						break;
					case 'A':
						ret+=date.getHours() >= 12?'PM':'AM';
						break;
					case 'd':
						ret+=lpad(date.getDate().toString(), 2, '0');
						break;
					case 'D':
						ret+=['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][date.getDay()];
						break;
					case 'l':
						ret+=['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][date.getDay()];
						break;
					case 'M':
						ret+=['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][date.getMonth()];
						break;
					case 'F':
						ret+=['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'][date.getMonth()];
						break;
					case 'h':
						var hour:Number=date.getHours();
						if (hour > 12) hour%=12;
						ret+=lpad((hour).toString(), 2, '0');
						break;
					case 'H':
						ret+=lpad(date.getHours().toString(), 2, '0');
						break;
					case 'i':
						ret+=lpad(date.getMinutes().toString(), 2, '0');
						break;
					case 'j':
						ret+=date.getDate().toString();
						break;
					case 'm':
						ret+=lpad(date.getMonth().toString(), 2, '0');
						break;
					case 's':
						ret+=lpad(date.getSeconds().toString(), 2, '0');
						break;
					case 'Y':
						ret+=date.getFullYear().toString();
						break;
					case 'y':
						//ret+=date.getYear().toString();
						ret+=lpad(((date.getFullYear())%100).toString(), 2, '0');
						break;
					default:
						ret+=format.charAt(i);
						break;
				}
			}
			return ret;
		}
		
		public static function int2str(num:Number):String
		{
			if (!num) return '0';
			var str:String = num.toString();
			if (num < 1) return str;
			
			var retStr:String = '';
			while (str.length > 3) {
				retStr = ',' + str.substr(-3) + retStr;
				str = str.substr(0, str.length-3);
			}
			
			return str + retStr;
		}
		
		public static function lpad(str:String, len:Number, append:String=' '):String {
			var ret:String=str;
			while (ret.length < len)
				ret=append+ret;
			return ret;
		}
		
		public static function extractImageURL(html:String, doHtmlEntitiesDecode:Boolean=false):Array
		{
			var result:Array = new Array;
			if (!html) return result;
			if (doHtmlEntitiesDecode)
				html = Util.htmlEntitiesDecode(html);
			var m:Array, k:Array;
			
			m = html.match(/<img\s[^>]*src="\s*(https?:\/\/[^"\s]+)\s*"/gim);
			if (m && m.length > 0) {
				for (var i:Number = 0; i < m.length && i < 3; i++) {
					k = m[i].match(/src="\s*(https?:\/\/[^"\s]+)\s*"/i);
					if (!k || result.indexOf(k[1]) >= 0) continue;
					result.push(k[1]);
				}
			}
			
			k = html.match(/https?:\/\/(www\.)?youtube\.com\/v\/([\da-zA-Z_\-]+)/i);
			if (k && k[2]) {
				var imgURL:String = 'http://img.youtube.com/vi/'+k[2]+'/hqdefault.jpg';
				if (result.indexOf(imgURL) < 0)
					result.push('http://img.youtube.com/vi/'+k[2]+'/hqdefault.jpg');
			}
			
			return result;
		}
		
		public static var _maxW:Number = 130;
		public static var _maxH:Number = 100;
		
		public static function calculateImgSize(w:Number, h:Number, maxW:Number, maxH:Number, crop:Boolean=false):Object
		{
			if (crop && w * 1.618 < h) {
				if (w > maxW) {
					h = h * maxW / w;
					w = maxW;
				}
				return {w:w, h:h, w2:w, h2:Math.min(h, maxH)};
			}
				
			if (w * maxH > h * maxW) {
				if (w > maxW) {
					h = h * maxW / w;
					w = maxW;
				}
			}else{
				if (h > maxH) {
					w = w * maxH / h;
					h = maxH;
				}
			}
			return {w:w, h:h, w2:w, h2:h};
		}
		
		public static function imgLoad(o:Object, img:BitmapImage, times:Number=1):Boolean {
			try{
				var maxW:Number = _maxW * times;
				var maxH:Number = _maxH * times;
				
				var w:Number = img.sourceWidth;
				var h:Number = img.sourceHeight;
				if ((w < 80 && h < 60) || w < 40 || h < 30) {
					return Util.imgError(o, img);
				}else{
					var _resized:Object = Util.calculateImgSize(w, h, maxW, maxH);
					w = _resized.w;
					h = _resized.h;
					img.width = w;
					img.height = h;
					
					if (img.parent) {
						img.parent.width = w;
						img.parent.height = h;
					}
					return true;
				}
			}catch(e:Error) {
				trace(e.getStackTrace(), 'imgLoad');
			}
			return true;
		}

		public static function imgError(o:Object, img:Object):Boolean {
			try{
				if (o.imageCandidates && o.imageCandidates.length > 0) {
					img.source = o.imageCandidates.shift();
					return false;
				}else{
					img.source = null;
					o.imageContainer.visible = o.imageContainer.includeInLayout = false;
				}
			}catch(e:Error) {
				trace(e.getStackTrace(), 'imgerror');
			}
			return true;
		}
		
		public static function showWarning(msg:String=null, title:String=null, base:Sprite=null, func:Function=null):void {
			if (base == null)
				base = Base.app;
			if (msg == null)
				msg = 'Sorry, something went wrong with Twitter.\nPlease try again later.';
			if (title == null)
				title = 'Notice';
			Alert.show(msg, title, Alert.OK, base, func, null, Alert.OK);

		}
		
		public static function readContent(fname:String):ByteArray
		{
			var f:File = new File(fname);
			if (!f.exists) return null;
			var fs:FileStream = new FileStream;
			
			try{
				fs.open(f, FileMode.READ);
				var d:ByteArray = new ByteArray;
				fs.readBytes(d);
				fs.close();
				return d;
			}catch(e:Error) {
				trace(e.getStackTrace(), 'readContent');
				fs.close();
			}
			return null;
		}
		
		public static function writeContent(fname:String, content:ByteArray):void
		{
			var f:File = new File(fname);
			var fs:FileStream = new FileStream;

			try{
				fs.open(f, FileMode.WRITE);
				fs.writeBytes(content);
			}catch(e:Error) {
				trace(e.getStackTrace(), 'writeContent');
			}
			fs.close();
		}
		
		public static function writeContent2(fname:String, content:String, charset:String=null):void
		{
			var f:File = new File(fname);
			var fs:FileStream = new FileStream;
			
			try{
				fs.open(f, FileMode.WRITE);
				fs.writeMultiByte(content, charset);
			}catch(e:Error) {
				trace(e.getStackTrace(), 'writeContent2');
			}
			fs.close();
		}
		
		public static var isShowingAlert:Boolean = false;
		
		private static function _deleteFileError(e:Event):void {}
		public static function deleteFile(fname:String):void
		{
			var f:File = new File(fname);
			if (f.exists) {
				f.addEventListener(IOErrorEvent.IO_ERROR, _deleteFileError, false, 0, true);
				f.addEventListener(SecurityErrorEvent.SECURITY_ERROR, _deleteFileError, false, 0, true);
				f.deleteFileAsync();
			}
		}
		
		public static const MAX_VALUE:String = '99999999999999999999';
		public static const MIN_VALUE:String = '0';
		
		public static function max(a:String, b:String):String
		{
			if (!a) return b;
			if (!b) return a;
			try {
				if (a.length > b.length) return a;
				if (a.length < b.length) return b;
				for (var i:Number=0; i < a.length; i++) {
					if (Number(a.charAt(i)) > Number(b.charAt(i))) return a;
					if (Number(a.charAt(i)) < Number(b.charAt(i))) return b;
				}
				return a;
			}catch(e:Error){
				trace('*!*!*!*!*!*', a, b);
				trace(e.getStackTrace(), 'Util.max');
			}
			return null;
		}
		public static function min(a:String, b:String):String
		{
			if (!a) return b;
			if (!b) return a;
			try {
				if (a.length < b.length) return a;
				if (a.length > b.length) return b;
				for (var i:Number=0; i < a.length; i++) {
					if (Number(a.charAt(i)) < Number(b.charAt(i))) return a;
					if (Number(a.charAt(i)) > Number(b.charAt(i))) return b;
				}
				return a;
			}catch(e:Error){
				trace('*!*!*!*!*!*', a, b);
				trace(e.getStackTrace(), 'Util.min');
			}
			return null;
		}
		
		
		public static function copyObject(sourceObj:Object):Object {
			if (!sourceObj) return null;
			var attributeName:String;
			var newObj:Object;
			newObj = new Object();
			for(attributeName in sourceObj) {
				if(sourceObj[attributeName] is Array) {                 //Array Item
					trace("Found Array:"+attributeName);
					newObj[attributeName]=copyArray(sourceObj[attributeName]);
				} else if(sourceObj[attributeName] is Object) {
					trace("Found Sub Object:"+attributeName);
					newObj[attributeName] = copyObject(sourceObj[attributeName]);
				} else {                 //real data element (not a reference)
					trace("Found Real Data Element:"+attributeName);
					newObj[attributeName] = sourceObj[attributeName];
				}
			}
			return newObj;
		}
		public static function copyArray(sArray:Array):Array {
			var tArray:Array=[];
			var numItems:Number=sArray.length;
			for(var i:Number=0; i < numItems; i++) {
				if(sArray[i] is Array) {
					trace("Found an array in index:"+i)
					tArray[i]=copyArray[sArray[i]];
				} else if (sArray[i] is Object) {
					trace("Found an object in index:"+i);
					tArray[i]=copyObject(sArray[i]);
				} else {                 //real data element (not a reference)
					trace("Found real data element in index:"+i)
					tArray[i]=sArray[i];
				}
			}
			return tArray;
		}
		
		public static var _styling:Configuration = null;
		public static function get styling():Configuration
		{
			if (_styling == null) {
			var _formatNormal:TextLayoutFormat = new TextLayoutFormat;
			_formatNormal.textDecoration = 'none';
			_formatNormal.color = 0x0279B4;
			var _formatHover:TextLayoutFormat = new TextLayoutFormat;
			_formatHover.textDecoration = 'underline';
//			_formatHover.color = 0x015EBD;
			_formatHover.color = 0x0279B4;
			
			_styling = new Configuration;
			_styling.defaultLinkNormalFormat = _formatNormal;
			_styling.defaultLinkHoverFormat = _formatHover;
			}
			return _styling;
		}
		
		public static function convertFromHTML(text:String):String
		{
			/* ref) http://www.utexas.edu/learn/html/spchar.html */
			
			// pre-substitution is required! (ex. &amp;ldquo;)
			text = text.replace(/&amp;?/g, '&');			// &
			
			// special cases (to distinguish them from real HTML tags)
			text = text.replace(/&gt;?/g, '&#8250;');		// > (*special character*)
			text = text.replace(/&lt;?/g, '&#8249;');		// < (*special character*)
			
			// punctuation
			text = text.replace(/&ndash;?/g, '&#8211;');	// –
			text = text.replace(/&mdash;?/g, '&#8212;');	// —
			text = text.replace(/&iexcl;?/g, '&#161;');		// ¡
			text = text.replace(/&iquest;?/g, '&#191;');	// ¿
			text = text.replace(/&quot;?/g, '&#34;');		// "
			text = text.replace(/&ldquo;?/g, '&#8220;');	// “
			text = text.replace(/&rdquo;?/g, '&#8221;');	// ”
			text = text.replace(/&lsquo;?/g, '&#8216;');	// ‘
			text = text.replace(/&rsquo;?/g, '&#8217;');	// ’
			text = text.replace(/&laquo;?/g, '&#171;');		// «
			text = text.replace(/&raquo;?/g, '&#187;');		// »
			text = text.replace(/&lsaquo;?/g, '&#8249;');	// &#8249; <
			text = text.replace(/&rsaquo;?/g, '&#8250;');	// &#8249; >
			text = text.replace(/&nbsp;?/g, '&#160;');		//   (blank)
			
			// symbols
			text = text.replace(/&cent;?/g, '&#162;');		// ¢
			text = text.replace(/&copy;?/g, '&#169;');		// ©
			text = text.replace(/&divide;?/g, '&#247;');	// ÷
			text = text.replace(/&micro;?/g, '&#181;');		// µ
			text = text.replace(/&middot;?/g, '&#183;');	// ·
			text = text.replace(/&para;?/g, '&#182;');		// ¶
			text = text.replace(/&plusmn;?/g, '&#177;');	// ±
			text = text.replace(/&euro;?/g, '&#8364;');		// €
			text = text.replace(/&pound;?/g, '&#163;');		// £
			text = text.replace(/&reg;?/g, '&#174;');		// ®
			text = text.replace(/&sect;?/g, '&#167;');		// §
			text = text.replace(/&trade;?/g, '&#153;');		// ™
			text = text.replace(/&yen;?/g, '&#165;');		// ¥
			
			// diacritics
			text = text.replace(/&aacute;?/g, '&#225;');	// á 
			text = text.replace(/&Aacute;?/g, '&#193;');	// Á
			text = text.replace(/&agrave;?/g, '&#224;');	// à
			text = text.replace(/&Agrave;?/g, '&#192;');	// À
			text = text.replace(/&acirc;?/g, '&#226;');		// â
			text = text.replace(/&Acirc;?/g, '&#194;');		// Â
			text = text.replace(/&aring;?/g, '&#229;');		// å 
			text = text.replace(/&Aring;?/g, '&#197;');		// Å
			text = text.replace(/&atilde;?/g, '&#227;');	// ã
			text = text.replace(/&Atilde;?/g, '&#195;');	// Ã
			text = text.replace(/&auml;?/g, '&#228;');		// ä
			text = text.replace(/&Auml;?/g, '&#196;');		// Ä
			text = text.replace(/&aelig;?/g, '&#230;');		// æ
			text = text.replace(/&AElig;?/g, '&#198;');		// Æ
			text = text.replace(/&ccedil;?/g, '&#231;');	// ç
			text = text.replace(/&Ccedil;?/g, '&#199;');	// Ç
			text = text.replace(/&eacute;?/g, '&#233;');	// é
			text = text.replace(/&Eacute;?/g, '&#201;');	// É
			text = text.replace(/&egrave;?/g, '&#232;');	// è 
			text = text.replace(/&Egrave;?/g, '&#200;');	// È
			text = text.replace(/&ecirc;?/g, '&#234;');		// ê
			text = text.replace(/&Ecirc;?/g, '&#202;');		// Ê
			text = text.replace(/&euml;?/g, '&#235;');		// ë
			text = text.replace(/&Euml;?/g, '&#203;');		// Ë
			text = text.replace(/&iacute;?/g, '&#237;');	// í
			text = text.replace(/&Iacute;?/g, '&#205;');	// Í
			text = text.replace(/&igrave;?/g, '&#236; ');	// ì 
			text = text.replace(/&Igrave;?/g, '&#204;');	// Ì
			text = text.replace(/&icirc;?/g, '&#238;');		// î
			text = text.replace(/&Icirc;?/g, '&#206;');		// Î
			text = text.replace(/&iuml;?/g, '&#239;');		// ï
			text = text.replace(/&Iuml;?/g, '&#207;');		// Ï
			text = text.replace(/&ntilde;?/g, '&#241;');	// ñ
			text = text.replace(/&Ntilde;?/g, '&#209;');	// Ñ
			text = text.replace(/&oacute;?/g, '&#243;');	// ó
			text = text.replace(/&Oacute;?/g, '&#211;');	// Ó
			text = text.replace(/&ograve;?/g, '&#242;');	// ò
			text = text.replace(/&Ograve;?/g, '&#210;');	// Ò
			text = text.replace(/&ocirc;?/g, '&#244;');		// ô
			text = text.replace(/&Ocirc;?/g, '&#212;');		// Ô
			text = text.replace(/&oslash;?/g, '&#248;');	// ø
			text = text.replace(/&Oslash;?/g, '&#216;');	// Ø
			text = text.replace(/&otilde;?/g, '&#245;');	// õ
			text = text.replace(/&Otilde;?/g, '&#213;');	// Õ
			text = text.replace(/&ouml;?/g, '&#246;');		// ö
			text = text.replace(/&Ouml;?/g, '&#214;');		// Ö
			text = text.replace(/&szlig;?/g, '&#223;');		// ß
			text = text.replace(/&uacute;?/g, '&#250;');	// ú
			text = text.replace(/&Uacute;?/g, '&#218;');	// Ú
			text = text.replace(/&ugrave;?/g, '&#249;');	// ù
			text = text.replace(/&Ugrave;?/g, '&#217;');	// Ù
			text = text.replace(/&ucirc;?/g, '&#251;');		// û
			text = text.replace(/&Ucirc;?/g, '&#219;');		// Û
			text = text.replace(/&uuml;?/g, '&#252;');		// ü
			text = text.replace(/&Uuml;?/g, '&#220;');		// Ü
			text = text.replace(/&yuml;?/g, '&#255;');		// ÿ
			
			var t:TextField = new TextField;
			t.htmlText = text;
			
			return t.text;
		}
	}
}