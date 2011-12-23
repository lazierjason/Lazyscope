package com.lazyscope.content
{
	import com.lazyscope.URL;
	import com.lazyscope.crawl.Crawler;
	import com.lazyscope.entry.Blog;
	import com.lazyscope.entry.BlogEntry;
	
	import flash.system.System;

	public class Flickr
	{
		public function Flickr()
		{
		}
		
		public static function apiCall(method:String, param:String, callback:Function):void
		{
			/**** Please write down your Flickr api-key ****/
			var apiKey:String='********************************';
			
			var url:String='http://api.flickr.com/services/rest/?method='+method+'&format=rest&api_key='+apiKey+'&'+(param?param:'');
			Crawler.downloadURL(url, function(u:String, body:String, httpStatus:int):void {
				if (!body) {
					if (callback != null) callback(null);
					return;
				}
				try{
					var xml:XML = new XML(body);
					if (!xml) {
						callback(null);
						return;
					}
					
					var list:XMLList = xml.child('err');
					if (list != null && list.length() > 0 && list[0].code) {
						//err
						//trace(list[0].msg);
						callback(null);
						System.disposeXML(xml);
						return;
					}
					
					callback(xml);
				}catch(e:Error) {
					
				}
			});
		}
		
		public static function photoURL(photo:XML, size:String=null):String
		{
			return 'http://farm'+(photo.@farm)+'.static.flickr.com/'+(photo.@server)+'/'+(photo.@id)+'_'+(photo.@secret)+(size?'_'+size:'')+'.jpg';
		}
		
		public static function returnPhotos(user:String, id:String, callback:Function):void
		{
			apiCall('flickr.photos.getInfo', 'photo_id='+id, function(xml:XML):void {
				if (xml == null || !xml['photo']) {
					if (callback != null) callback(null);
					return;
				}
				
				try{
					var photo:XML = xml['photo'][0];
					
					var username:String = photo['owner'].@username.toString();
					var title:String = photo['title'].toString();
					var description:String = photo['description'].toString().replace(/^\s+|\s+$/g, '');
					var blog:Blog = new Blog(URL.normalize('http://flickr.com/photos/'+user+'/'), 'http://api.flickr.com/services/feeds/photos_public.gne?id='+(photo['owner'].@nsid.toString())+'&format=rss_200', username);
					
					var entry:BlogEntry = new BlogEntry;
					entry.blog = blog;
					entry.title = title;
					entry.image = photoURL(photo, 't');
					entry.description = username+' posted a photo: '+title+' '+description;
					entry.content = '<p><a href="http://www.flickr.com/people/'+user+'/">'+username+'</a> posted a photo:</p> <p><a href="http://www.flickr.com/photos/'+user+'/'+id+'/" title="'+title+'"><img src="'+photoURL(photo, 'm')+'" width="180" height="240" alt="'+title+'"></a></p>'+(description?' <p>'+description+'</p>':'');
					entry.link = URL.normalize('http://flickr.com/photos/'+user+'/'+id+'/');
					entry.published = new Date();
					entry.published.setTime(photo.@dateuploaded+'000');
					entry.source = 'API';
					entry.service = 'Flickr';
					
					var tags:XML = photo['tags']?photo['tags'][0]:null;
					if (tags) {
						for (var i:Number=0; i < tags['tag'].length(); i++) {
							entry.category.push(tags['tag'][i].toString());
						}
					}
					
					if (callback != null)
						callback(entry);
				}catch(e:Error) {
					trace(e.getStackTrace(), 'returnPhotos');
					if (callback != null) callback(null);
				}
				System.disposeXML(xml);
			});
		}
		
		public static function returnPhotoSets(user:String, id:String, callback:Function):void
		{
			apiCall('flickr.photosets.getInfo', 'photoset_id='+id, function(xml:XML):void {
				if (xml == null || !xml['photoset']) {
					if (callback != null) callback(null);
					return;
				}
				
				var set:Object={
					id: xml['photoset'].@id,
					title: xml['photoset'].title,
					description: xml['photoset'].description?xml['photoset'].description.toString().replace(/^\s+|\s+$/g, ''):''
				};
				
				apiCall('flickr.photosets.getPhotos', 'photoset_id='+id+'&per_page=9&extras=date_upload,owner_name', function(xml:XML):void {
					try{
						if (xml == null || !xml['photoset']) {
							if (callback != null) callback(null);
							return;
						}
						var setNode:XMLList = xml['photoset'];
						var photo:XMLList = setNode['photo'];
						if (!photo || photo.length() <= 0) {
							if (callback != null) callback(null);
							return;
						}
						
						var blog:Blog = new Blog(URL.normalize('http://flickr.com/photos/'+user+'/'), 'http://api.flickr.com/services/feeds/photos_public.gne?id='+(setNode.@owner.toString())+'&format=rss_200', setNode.@ownername.toString());
						Blog.register(blog, null, true);
						
						var entry:BlogEntry = new BlogEntry;
						entry.blog = blog;
						entry.title = set.title;
						entry.image = photoURL(photo[0], 't');
						entry.content = '<object height="427" width="500" type="application/futuresplash"><param value="&amp;offsite=true&amp;page_show_url=%2Fphotos%2F'+user+'%2Fsets%2F'+id+'%2Fshow%2F&amp;set_id='+id+'" name="flashvars"><param value="http://www.flickr.com/apps/slideshow/show.swf" name="movie"><param value="true" name="allowFullScreen"><param name="wmode" value="opaque"><embed height="427" width="500" flashvars="&amp;offsite=true&amp;page_show_url=%2Fphotos%2F'+user+'%2Fsets%2F'+id+'%2Fshow%2F&amp;set_id='+id+'" allowfullscreen="true" wmode="opaque" src="http://www.flickr.com/apps/slideshow/show.swf" type="application/futuresplash"></object> <p>'+(set.description.toString().replace(/\n/g, '<br />'))+'</p>';
						entry.description = set.description.toString().replace(/<[^>]+>/g, '');
						
						var fs:FlickrSetRender = new FlickrSetRender;
						fs.data = entry;
						fs.photos = photo;
						
						entry.displayDescription = fs;
						
						entry.link = URL.normalize('http://flickr.com/photos/'+user+'/sets/'+id+'/');
						entry.published = new Date();
						entry.published.setTime(photo[0].@dateupload+'000');
						entry.source = 'API';
						entry.service = 'Flickr';
						entry.noRegister = true;
						
						//trace(entry);
						
						if (callback != null)
							callback(entry);
					}catch(e:Error) {
						trace(e.getStackTrace(), 'returnPhotoSets');
						if (callback != null) callback(null);
					}
					
					System.disposeXML(xml);
				});
			});
		}
		
		public static function fillContent(entry:BlogEntry):void
		{
			if (entry.image && entry.link.match(/\/photos\/([^\/]+)\/([0-9]+)/i)) {
				var m:Array = entry.image.match(/\/\/farm([0-9]+).static.flickr.com\/([0-9a-zA-Z]+)\/([^_]+)_([^_\.]+)(_[a-z])?\./i);
				if (m) {
					var img:String = 'http://farm'+m[1]+'.static.flickr.com/'+m[2]+'/'+m[3]+'_'+m[4];
					//entry.displayDescription = new FlickrRender;
					
					entry.displayContent='<img src="'+img+'.jpg" /><p>'+(entry.description)+'</p>';
				}
			}
			entry.description = entry.description.replace(/<[^>]+>/g, '');
		}
		
		public static function readabilityEnabled(url:URL):Boolean
		{
			var m:Array = url.path.match(/^\/photos\/([^\/]+)\/(sets\/)?([0-9]+)/i);
			if (!m) {
				return true;
			}
			return false;
		}
			
		public static function makeEntry(url:URL, callback:Function):void
		{
			var m:Array = url.path.match(/^\/photos\/([^\/]+)\/(sets\/)?([0-9]+)/i);
			if (!m) {
				if (callback != null) callback(null);
				return;
			}
			
			var res:Object = null;
			if (m[2] == 'sets/') {
				//set
				returnPhotoSets(m[1], m[3], callback);
			}else{
				//photo
				returnPhotos(m[1], m[3], callback);
			}
		}
	}
}