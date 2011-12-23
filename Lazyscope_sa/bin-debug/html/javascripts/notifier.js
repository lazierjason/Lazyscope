var Notifier = {
	div: {},
	entries: null,
	index: 0,
	embeddedEntries: {},
	nowE: null,
	
	init: function() {
		//document.addEventListener('mousedown', Notifier.mousedown);
		//document.addEventListener('mouseup', Notifier.mouseup);
		
		this.div.container = document.getElementById('container');
		this.div.updateCount = document.getElementById('update-count');
		this.div.currentPage = document.getElementById('current-page');
		this.div.totalPage = document.getElementById('total-page');
		this.div.main = document.getElementById('main');
		this.refresh();
	},
	switchToMainWin: function() {
		if (_notifier)
			_notifier.switchToMainWindow();
	},
	clickContent: function(e) {
		if (_notifier) {
			_notifier.onClickContent(e);
			_notifier.switchToMainWindow();
		}
	},
	refresh: function() {
		if (_notifier && this.div.container) {
			_notifier.adjustHeight(this.div.container.scrollHeight);
		}
	},
	prev: function() {
		if (!this.entries || this.entries.length <= 0) return;
		this.showEntry(this.index ? this.index-1 : this.entries.length-1);
	},
	next: function() {
		if (!this.entries || this.entries.length <= 0) return;
		this.showEntry(this.index+1);
	},
	updateNotification: function(entries, embedded) {
		if (!entries || entries.length <= 0) return;
		this.div.totalPage.innerHTML = entries.length;
		this.div.updateCount.innerHTML = entries.length + ' update' + (entries.length > 1 ? 's' : '');
		this.entries = entries;
		this.embeddedEntries = embedded;
		this.showEntry(0, true);
	},
	refreshEntry: function() {
		this.showEntry(this.index);
	},
	showEntry: function(index, isNew) {
		if (!this.entries || this.entries.length <= 0) return;
		if (!index || index >= this.entries.length) index = 0;
		switch (this.entries[index].type) {
			case 'T':
				if (this.entries[index].twitStatus) {
					if (isNew || index != this.index || this.embeddedEntries[this.entries[index].twitStatus.id])
						this.showEntryTwitter(this.entries[index]);
				}
				break;
			case 'B':
				if (isNew || index != this.index)
					this.showEntryBlog(this.entries[index]);
				break;
			case 'M':
				if (this.entries[index].twitMsg) {
					if (isNew || index != this.index || this.embeddedEntries[this.entries[index].twitMsg.id])
						this.showEntryMessage(this.entries[index]);
				}
				break;
		}
		this.index = index;
		this.div.currentPage.innerHTML = index+1;
		
		window.setTimeout(function(){
			Notifier.refresh();
		}, 10);
	},
	
	showEntryTwitter: function(t) {
		var st = t.twitStatus.retweetedStatus ? t.twitStatus.retweetedStatus : t.twitStatus;
		
		var twText = st.text;
//		if (st.links.length > 0) {
//			var p;
//			for (var i = 0; i < st.links.length; i++) {
//				p = twText.indexOf(st.links[i]);
//				if (p < 0) continue;
//				twText = twText.substr(0, p) + '[LINK]' + twText.substr(p+st.links[i].length);
//			} 
//		}

		
		var html = '<div class="twitter">';
		html += '<img class="profile" src="'+st.user.profileImageUrl+'" />';
		html += '<div class="tw-msg">';
		html += '<strong>'+st.user.screenName+'</strong><br />';
		html += twText;
		if (t.twitStatus.retweetedStatus) {
			html += '<br />Retweeted by '+t.twitStatus.user.screenName;
		}
		html += '</div><div class="clear"></div>';
		
		var e = null;
		if (t.twitStatus.id) {
			e = this.embeddedEntries[t.twitStatus.id];
			if (e) {
				var m = e.link ? e.link.match(/^https?:\/\/(www\.)?([^\/]+)(\/|$)/) : null;
				var blogHost = m ? m[2] : '';
				//var description = e.displayDescription ? e.displayDescription : (e.description ? e.description : '');
				var description = (e.description ? e.description : '');

				html += '<div class="blog embedded">';
				
				if (e.title)
					html += '<div class="entry-title">'+(e.title.replace(/\s+/g, ' ').replace(/^\s+/, '').replace(/\s+$/, '').substr(0, 150))+'</div>';
				html += '<div class="description">';
				if (e.image)
					html += '<div class="thumb-wrap"><img class="thumb" src="'+e.image+'" /></div>';
				if (description)
					html += '<div class="entry-description">' + description.replace(/\s+/g, ' ').replace(/^\s+/, '').replace(/\s+$/, '').substr(0, 300) + '</div>';
				html += '</div>';
		
				html += '<div class="blog-info">';
				if (e.blog && e.blog.title)
					html += '<strong>'+e.blog.title+'</strong> ' + (blogHost ? ('('+blogHost+')') : '');
				else if (blogHost)
					html += '<strong>'+blogHost+'</strong>';
					
				html += '</div>';
			}
		}
		
		html += '</div>';

		this.div.main.innerHTML = html;
		this.attachImgLoadComplete();
		
		if (e) {
			var els = this.div.main.getElementsByClassName('blog embedded');
			if (els && els[0]) {
				var e2=e;
				els[0].onclick = function(){
					Notifier.clickContent(e2);
				};
			}
		}
	},
	
	showEntryMessage: function(t) {
		var msg = t.twitMsg;
		var html = '<div class="twitter">';
		html += '<img class="profile" src="'+(t.twitMsgIsSent ? msg.recipient.profileImageUrl : msg.sender.profileImageUrl)+'" />';
		html += '<div class="tw-msg">';
		html += (t.twitMsgIsSent ? 'To' : 'From')+' <strong>'+(t.twitMsgIsSent ? msg.recipientScreenName : msg.senderScreenName)+'</strong><br />';
		html += msg.text;
		html += '</div><div class="clear"></div>';
		
		var e = null;
		if (t.twitMsg.id) {
			e = this.embeddedEntries[t.twitMsg.id];
			if (e) {
				var m = e.link ? e.link.match(/^https?:\/\/(www\.)?([^\/]+)(\/|$)/) : null;
				var blogHost = m ? m[2] : '';
				//var description = e.displayDescription ? e.displayDescription : (e.description ? e.description : '');
				var description = (e.description ? e.description : '');

				html += '<div class="blog embedded">';
				
				if (e.title)
					html += '<div class="entry-title">'+e.title.replace(/\s+/g, ' ').replace(/^\s+/, '').replace(/\s+$/, '').substr(0, 150)+'</div>';
				html += '<div class="description">';
				if (e.image)
					html += '<div class="thumb-wrap"><img class="thumb" src="'+e.image+'" /></div>';
				if (description)
					html += '<div class="entry-description">' + description.replace(/\s+/g, ' ').replace(/^\s+/, '').replace(/\s+$/, '').substr(0, 300) + '</div>';
				html += '</div>';
		
				html += '<div class="blog-info">';
				if (e.blog && e.blog.title)
					html += '<strong>'+e.blog.title+'</strong> ' + (blogHost ? ('('+blogHost+')') : '');
				else if (blogHost)
					html += '<strong>'+blogHost+'</strong>';
					
				html += '</div>';
			}
		}
		
		html += '</div>';

		this.div.main.innerHTML = html;
		this.attachImgLoadComplete();
		
		if (e) {
			var els = this.div.main.getElementsByClassName('blog embedded');
			if (els && els[0]) {
				var e2=e;
				els[0].onclick = function(){
					Notifier.clickContent(e2);
				};
			}
		}
	},
	
	showEntryBlog: function(e) {
		var m = e.link ? e.link.match(/^https?:\/\/(www\.)?([^\/]+)(\/|$)/) : null;
		var blogHost = m ? m[2] : '';
		//var description = e.displayDescription ? e.displayDescription : (e.description ? e.description : '');
		var description = (e.description ? e.description : '');
			
		var html = '<div class="blog">';
		
		if (e.title)
			html += '<div class="entry-title">'+(e.title.replace(/\s+/g, ' ').replace(/^\s+/, '').replace(/\s+$/, '').substr(0, 150))+'</div>';
		html += '<div class="description">';
		if (e.image)
			html += '<div class="thumb-wrap"><img class="thumb" src="'+e.image+'" /></div>';
		if (description)
			html += '<div class="entry-description">' + description.replace(/\s+/g, ' ').replace(/^\s+/, '').replace(/\s+$/, '').substr(0, 300) + '</div>';
		html += '</div>';

		html += '<div class="blog-info">';
		if (e.blog && e.blog.title)
			html += '<strong>'+e.blog.title+'</strong> ' + (blogHost ? ('('+blogHost+')') : '');
		else if (blogHost)
			html += '<strong>'+blogHost+'</strong>';
			
		html += '</div>';
		
		this.div.main.innerHTML = html;
		this.attachImgLoadComplete();

		if (e) {
			var els = this.div.main.getElementsByClassName('blog');
			if (els && els[0]) {
				var e2=e;
				els[0].onclick = function(){
					Notifier.clickContent(e2);
				};
			}
		}
	},
	
	attachImgLoadComplete: function() {
		if (!this.div.main) return;
		var imgs = this.div.main.getElementsByTagName('IMG');
		if (!imgs || imgs.length <= 0) return;
		for (var i=0; i < imgs.length; i++) {
			imgs[i].onload = function(e){
				UtilImg.imgLoad(e);
				window.setTimeout(function(){
					Notifier.refresh();
				}, 10);
			};
			imgs[i].onerror = function(e){
				if (!UtilImg.imgError(e)) {
					var el = e ? e.target : null;
					if (el) el.style.display = 'none';
				}
				window.setTimeout(function(){
					Notifier.refresh();
				}, 10);
			};
		}
	}
}
