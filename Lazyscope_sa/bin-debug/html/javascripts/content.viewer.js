var $=function(id) {
	return document.getElementById(id);
};

var ContentViewer={
	mouseDownEl: null,
	init: function() {
		//document.addEventListener('mousedown', ContentViewer.mousedown);
		//document.addEventListener('mouseup', ContentViewer.mouseup);
	},
	/*
	mousedown: function(e) {
		mouseDownEl = e.target;
	},
	mouseup: function(e) {
		if (mouseDownEl == e.target) {
			//click
			ContentViewer.onClick(e);
		}
	},
	*/
	selectedContent: null,
	clear: function() {
		try{
		document.documentElement.scrollTop = document.body.scrollTop = 0;
		
		var div=$('yield');
		while (div.firstChild)
			div.removeChild(div.firstChild);
			
		var div=$('feed');
		while (div.firstChild)
			div.removeChild(div.firstChild);
			
		var div=$('feed-header');
		div.style.display='';
		div.innerHTML='';
		
		this.lastNode = null;
		
		var div=$('retry');
		div.style.display='none';
		}catch(e){}
	},
	showReadability: function(html) {
		try{
			ContentViewer.link='';
		
			var div=$('yield-content');
			if (!div) return;
			div.innerHTML = this.getRefinedContent(html);

			this.processImage(div);
		}catch(e){}
	},
	retry: function() {
		try{
		if (ContentViewer.link)
			window.retry(ContentViewer.link);
		}catch(e){}
	},
	link: '',
	openBrowser: function() {
		try{
		if (ContentViewer.link)
			linkClicked(ContentViewer.link);
		}catch(e){}
	},
	showLink: function(link, title, err, readabilityFail) {
		try{
		var div=$('yield');
		
		var _title = title ? title.replace(/<[^>]+>/g, '') : '';
		ContentViewer.link = link;
		
		var node=document.createElement('DIV');
		//var html='<h2><a class="btn-favorite" title="'+link+'"></a><a href="'+link+'">'+_title+'</a></h2>';
		var html='<h2><a href="'+link+'">'+_title+'</a></h2>';
		html+='<div class="permalink"><a href="'+link+'">'+link+'</a></div>';
		/*
		html+='<div class="info-line"><a class="btn-post"></a></div>';
		*/
		node.innerHTML = html;
		node.className = 'full-view content-selected';
		this.selectedContent = node;
		
		node._data = {'link':link, 'title':title, '_doNotSnapshot':true};
		
		/*
		try{
			node.getElementsByClassName('btn-post')[0].onclick = function(){toPost(link, _title);};
		}catch(e){};
		*/
			
		/*
		try{
			var btnFavorite = node.getElementsByClassName('btn-favorite')[0];
			if (btnFavorite)
				btnFavorite.onclick = function(){ContentViewer._toFavorite(btnFavorite);};
			if ((getFavoriteHash())[link]) btnFavorite.className += ' favorited';
		}catch(e){};
		*/
		
		div.appendChild(node);
		
		var elList=node.getElementsByTagName('A');
		if (elList) {
			for (var k=0; k<elList.length; k++) {
				var el=elList[k];
				if (el && el.href) {
					el.addEventListener('mousedown', function(event){
						linkClicked(event.target.href);
					});
				}
			}
		}
		

		
		var div=$('retry');
		div.style.display='block';
		
		$('retry_message').innerHTML=readabilityFail?'Lazyscope lets you view pure content. This page does not seem to be a content page. You can visit the site by opening it up in a new browser.':'Something went wrong. You can try again or open the page in a new browser.';
		$('retry_error').innerHTML=err?'Sorry, it didn\'t work at this time. Please visit the original site by clicking "Open in a browser" button.':'';
		}catch(e){}
	},
	
	getRefinedContent: function(c) {
		if (!c) return '';
		
		// youtube, hulu
		c = c.replace(/((value|src)=("|')https?:\/\/)www\./g, '$1');

		// for HTML special character		
		c = c.replace(/((^|>)[^<>]*)&amp;?/g, '$1&');
		
		return c;
	},
	
	getEmbeddedYoutubeIDs: function(node) {
		var hashTable = {};
		
		var els = node.getElementsByTagName('IFRAME');
		if (els && els.length > 0) {
			for (var i=els.length; i--;) {
				var src = els[i].src;
				if (!els[i] || !els[i].src) continue;
				var m = els[i].src.match(/^https?:\/\/(www\.)?youtube\.com\/embed\/([a-zA-Z0-9_\-]+)/);
				if (m && m[2])
					hashTable[m[2]] = true;
			}
		}

		var els = node.getElementsByTagName('EMBED');
		if (els && els.length > 0) {
			for (var i=els.length; i--;) {
				var src = els[i].src;
				if (!els[i] || !els[i].src) continue;
				var m = els[i].src.match(/^https?:\/\/(www\.)?youtube\.com\/v\/([a-zA-Z0-9_\-]+)/);
				if (m && m[2])
					hashTable[m[2]] = true;
			}
		}

		return hashTable;
	},
	
	addYoutubeVideo: function(el, id) {
		if (!el || !el.parentNode) return;
		if (el.parentNode.tagName && ['A', 'SPAN'].indexOf(el.parentNode.tagName) >= 0) {
			this.addYoutubeVideo(el.parentNode, id);
		}else{
			var srcURL = 'http://youtube.com/v/'+id;
			var node=document.createElement('DIV');
			node.className='_extra_embed_';
			node.innerHTML = '<object width="560" height="340"><param name="movie" value="'+srcURL+'?fs=1&amp;hd=1"></param><param name="allowFullScreen" value="true"></param><param name="allowscriptaccess" value="always"></param><embed src="'+srcURL+'?fs=1&amp;hd=1" type="application/x-shockwave-flash" allowscriptaccess="always" allowfullscreen="true" width="560" height="340"></embed></object>';
			UtilDOM.insertAfter(node, el);
		}
	},
	
	processImage: function(node) {
		var imgs = node.getElementsByTagName('IMG');
		if (imgs && imgs.length > 0) {
			var youtubeIDs = this.getEmbeddedYoutubeIDs(node);
			for (var i=imgs.length; i--;) {
				if (!imgs[i] || !imgs[i].src) continue;
				
				var m = imgs[i].src.match(/^https?:\/\/(i[0-9]+\.)?ytimg\.com\/vi\/([a-zA-Z0-9_\-]+)/);
				if (m && m[2] && !youtubeIDs[m[2]]) {
					this.addYoutubeVideo(imgs[i], m[2]);
					imgs[i].parentNode.removeChild(imgs[i]);
					youtubeIDs[m[2]] = true;
				}else{
					var m = imgs[i].src.match(/^https?:\/\/img\.youtube\.com\/vi\/([a-zA-Z0-9_\-]+)/);
					if (m && m[1] && !youtubeIDs[m[1]]) {
						this.addYoutubeVideo(imgs[i], m[1]);
						imgs[i].parentNode.removeChild(imgs[i]);
						youtubeIDs[m[1]] = true;
					}
				}
				if (imgs[i]) {
					imgs[i].onload = this.imgLoad;
					imgs[i].onerror = this.imgError;
				}
			}
		}else{
			try{
				var e=node._data;
				if (e.image && !e.video) {
					var el=document.createElement('DIV');
					el.className='_extra_embed_';
					var imgEl=document.createElement('IMG');
					imgEl.onload = this.imgLoad;
					imgEl.onerror = this.imgError;
					imgEl.src=e.image;
					el.appendChild(imgEl);
					
//					UtilDOM.prepend(node. el);
					node.appendChild(el);
					
					this.processImage(node);
				}
			}catch(e) {}
		}
	},
	
	report: function() {
		report(ContentViewer.showURL);
	},
	
	showURL: '',
	show: function(e) {
		try{
		if (!e || !e.link) return;
		
		ContentViewer.link='';
		ContentViewer.showURL = e.link;
		
		var div=$('yield');
		
		var m = e.link ? e.link.match(/^https?:\/\/(www\.)?([^\/]+)(\/|$)/) : null;
		var host = m ? m[2] : '';
		var infoLine = host?('from '+host+' '):'';
		var _title = e.title ? e.title.replace(/<[^>]+>/g, '') : '';
		var time = (e.published && e.published > 0) ? e.published.getTime() : 0;
		if (time > 0)
			infoLine += (infoLine?'| ':'') + Util.toIntervalString(time/1000)+' ';
		//infoLine += '<a class="btn-post"></a>';
		
		var node=document.createElement('DIV');
		var html='<div class="content-header">';
		//html+='<h2><a class="btn-favorite" title="'+e.link+'"></a><a href="'+(e.link)+'">'+_title+'</a></h2>';
		html+='<h2><a href="'+(e.link)+'">'+_title+'</a></h2>';
		html+='<div class="permalink"><a href="'+(e.link)+'">'+(e.link)+'</a></div>';
		html+='<div class="info-line">'+infoLine+'</div>';
		html+='</div>';
		
		/*
		//if (e.source == 'readability') {
			html+='<div class="report">Content not appearing correctly? <a class="reportLink" href="javascript:;">Click here to report!</a></div>';
		//}
		*/
		
		html+='<div id="yield-content">'+this.getRefinedContent(e.displayContent?e.displayContent:e.content)+'</div>';
		node.innerHTML = html;
		node.className = 'full-view content-selected';
		this.selectedContent = node;
		var nowNode = node;

		/*
		node.onclick = function() {
			if (ContentViewer.selectedContent)
				ContentViewer.selectedContent.className = ContentViewer.selectedContent.className.replace(/\s+content-selected/g, '');
			if (nowNode) {
				nowNode.className += ' content-selected';
				ContentViewer.selectedContent = nowNode;
			}
		};
		*/
		
		/*
		try{
			var btnFavorite = node.getElementsByClassName('btn-favorite')[0];
			if (btnFavorite)
				btnFavorite.onclick = function(){ContentViewer._toFavorite(btnFavorite);};
			if ((getFavoriteHash())[e.link]) btnFavorite.className += ' favorited';
		}catch(e){};
		*/

		node._data = e;
		
		this.processImage(node);
		
		/*
		try{
			node.getElementsByClassName('btn-post')[0].onclick = function(){toPost(e.link, _title, e);};
			node.getElementsByClassName('reportLink')[0].onclick = ContentViewer.report;
		}catch(e){};
		*/
		
		div.appendChild(node);
		
		var elList=node.getElementsByTagName('A');
		if (elList) {
			for (var k=0; k<elList.length; k++) {
				var el=elList[k];
				if (el && el.href) {
					el.addEventListener('mousedown', function(event){
						linkClicked(event.target.href);
					});
				}
			}
		}
		
		var div=$('feed-header');
		div.innerHTML='<div>Recent posts from <strong>'+(e.blog?(e.blog.title?e.blog.title.replace(/\s+/, ' ').replace(/<[^>]+>/g, ''):e.blog.link):(e.title?e.title.replace(/\s+/, ' ').replace(/<[^>]+>/g, ''):e.link))+'</strong></div>';
		}catch(e){}
	},
	
	addFeedEntry: function(e, imageCandidates) {
		try{
		if (!e || !e.link) return;
		
		var div=$('feed');

		var time = (e.published && e.published > 0) ? e.published.getTime() : 0;
		var _title = e.title ? e.title.replace(/<[^>]+>/g, '') : '';
		
		var node=document.createElement('DIV');
		node.className = 'feed-node';
		var html='<h3>'+(_title)+'</h3><div>'+(e.image?'<div class="thumb-wrap"><img class="thumb" src="'+(e.image)+'" /></div>':'')+('<div class="description">'+e.description+(time>0 ? ('<div class="info-line">'+Util.toIntervalString(time/1000)+'</div>') : '')+'</div>')+'</div>';
		node.innerHTML = html;
		
		var imgs = node.getElementsByTagName('IMG');
		if (imgs && imgs.length > 0) {
			var img = imgs[0];
			img._candidates = imageCandidates;
			img.onload = UtilImg.imgLoad;
			img.onerror = UtilImg.imgError;
		}
		
		node._data = e;
		/*
		node.onclick = ContentViewer.onNodeClick;
		*/
		
		div.appendChild(node);
		
		var elList=node.getElementsByTagName('A');
		if (elList) {
			for (var k=0; k<elList.length; k++) {
				var el=elList[k];
				if (el && el.href) {
					el.addEventListener('mousedown', function(event){
						linkClicked(event.target.href);
					});
				}
			}
		}
		

		var div=$('feed-header');
		div.style.display='block';
		}catch(e){}
	},
	onNodeClick: function(event) {
		try{
		var node = event.target;
		ContentViewer.expandFeedEntry(node);
		}catch(e){}
	},
	
	lastNode: null,
	expandFeedEntry: function(node) {
		try{
		while (node && node.className != 'feed-node') {
			node = node.parentNode;
		}
		
		if (node && node._data) {
			node.className += ' feed-view';
			var e=node._data;
			
			var m = e.link ? e.link.match(/^https?:\/\/(www\.)?([^\/]+)(\/|$)/) : null;
			var host = m ? m[2] : '';
			var infoLine = host?('from '+host):'';
			var time = (e.published && e.published > 0) ? e.published.getTime() : 0;
			if (time > 0)
				infoLine += (infoLine?' | ':'') + Util.toIntervalString(time/1000);
			infoLine += '<a class="btn-post"></a>';
			
			var _title = e.title ? e.title.replace(/<[^>]+>/g, '') : '';
			var html='<div class="content-header">';
			//html+='<h2><a class="btn-favorite" title="'+e.link+'"></a><a href="'+(e.link)+'">'+_title+'</a></h2>';
			html+='<h2><a href="'+(e.link)+'">'+_title+'</a></h2>';
			html+='<div class="permalink"><a href="'+(e.link)+'">'+(e.link)+'</a></div>';
			html+='<div class="info-line">'+infoLine+'</div>';
			html+='</div>';
			html+='<div>'+this.getRefinedContent(e.displayContent?e.displayContent:e.content)+'</div>';

			//node._data = null;
			node.innerHTML=html;

			if (this.selectedContent) this.selectedContent.className = this.selectedContent.className.replace(/\s+content-selected/g, '');
			node.className += ' content-selected';
			this.selectedContent = node;
			var nowNode = node;
			
			/*
			node.onclick = function() {
				if (ContentViewer.selectedContent)
					ContentViewer.selectedContent.className = ContentViewer.selectedContent.className.replace(/\s+content-selected/g, '');
				if (nowNode) {
					nowNode.className += ' content-selected';
					ContentViewer.selectedContent = nowNode;
				}
			};
			*/
		
			this.processImage(node);
			
			/*
			try{
				node.getElementsByClassName('btn-post')[0].onclick = function(){toPost(e.link, _title, e);};
			}catch(e){};
			*/
			
//			try{
//				var btnFavorite = node.getElementsByClassName('btn-favorite')[0];
//				if (btnFavorite)
//					btnFavorite.onclick = function(){ContentViewer._toFavorite(btnFavorite);};
//				if ((getFavoriteHash())[e.link]) btnFavorite.className += ' favorited';
//			}catch(e){};

			this.lastNode = node;
			this.doScroll(node.offsetTop+1);
			return true;
		}
		return false;
		}catch(e){}
	},
	
	_toFavorite: function(el) {
		if (!el.title) return;
		if (el.className.match(/favorited/)) {
			toFavorite(el.title, false);
			el.className = el.className.replace(/ favorited/, '');
		}else{
			toFavorite(el.title, true);
			el.className += ' favorited';
		}
	},
	
	onClick: function(event) {
		var el = event.target;
		if (!el) return;
		
		while (el && el.nodeName != 'A') {
			el = el.parentNode;
		}
		if (el && el.tagName == 'A') {
			if (el.href && el.href.match(/^https?:\/\//i)) {
				linkClicked(el.href);
			}
		    event.preventDefault();
		    event.stopPropagation();
		}
	},
	
	onKeyDown: function(event) {
		try{
		switch (event.keyCode) {
			case 33:
//				document.body.scrollTop -= document.documentElement.clientHeight-20;
				document.body.scrollTop -= document.documentElement.clientHeight;
			    event.preventDefault();
			    event.stopPropagation();
				break;
			case 34:
//				document.body.scrollTop += document.documentElement.clientHeight-20;
				document.body.scrollTop += document.documentElement.clientHeight;
			    event.preventDefault();
			    event.stopPropagation();
				break;
			case 32:	// spacebar
				var div = $('feed');
				if (div && div.childNodes && div.childNodes.length > 0) {
					var node = null;
					var isScrollEnd = (document.body.scrollTop + document.documentElement.clientHeight) >= document.documentElement.scrollHeight;
					for (var i=0; i < div.childNodes.length; i++) {
						if ((!isScrollEnd || !div.childNodes[i].className.match(/feed-view/)) && div.childNodes[i].offsetTop > document.body.scrollTop && div.childNodes[i].offsetTop < document.body.scrollTop + document.documentElement.clientHeight) {
							node = div.childNodes[i];
							break;
						}
					}
					if (node) {
						this.doScroll(node.offsetTop+1);
						if (!node.className.match(/feed-view/))
							this.expandFeedEntry(node);
						event.preventDefault();
						event.stopPropagation();
						break;
					}
				}
				
//				document.body.scrollTop += document.documentElement.clientHeight-20;
				document.body.scrollTop += document.documentElement.clientHeight;
			    event.preventDefault();
			    event.stopPropagation();
				break;
			case 13:	// enter
				if (this.selectedContent) {
					var e = this.selectedContent._data;
					if (e) {
						var _title = e.title ? e.title.replace(/<[^>]+>/g, '') : '';
						toPost(e.link, _title, (e._doNotSnapshot ? null : e));
					}
				}
				break;
		}
		}catch(e){}
	},
	
	onScroll: function(event) {
		if (event.wheelDelta == 0) return;
		
		var d = event.wheelDelta/120;
		//if (d > 0 && d > 3) d = 3;
		//else if (d < 0 && d < -3) d = -3;
		
		document.body.scrollTop -= (d*13);
		//this.doScroll(document.body.scrollTop - (event.wheelDelta/20));
		//this.doScroll(document.body.scrollTop - ((event.wheelDelta > 0?1:-1)*150));
	},
	
	doScroll: function(top) {
		scrollEffect.animate.stop();
		scrollEffect.scrollTop.valueFrom = document.body.scrollTop;
		scrollEffect.scrollTop.valueTo = top;
		scrollEffect.animate.play();
	},
	
	imgLoad: function(e) {
		var el = e ? e.target : null;
		if (el && el.style.display !== 'none' && el.clientHeight > 20) {
			var br=document.createElement('BR');
			if (el.nextSibling)
				el.parentNode.insertBefore(br, el.nextSibling);
			else
				el.parentNode.appendChild(br);
		}
	},
	imgError: function(e) {
		var el = e ? e.target : null;
		if (el) {
			if (!el.src.match(/^http:\/\/www\./i))
				el.src=el.src.replace(/^http:\/\//i, 'http://www.');
			else
				el.style.display = 'none';
		}
	}
};
