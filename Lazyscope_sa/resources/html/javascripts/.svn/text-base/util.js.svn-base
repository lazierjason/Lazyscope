var UtilDOM={
	prepend: function(parent, el) {
		if (parent.firstChild)
			parent.insertBefore(el, parent.firstChild);
		else
			parent.appendChild(el);
	},
	insertAfter: function(newEl, el) {
		if (el.nextSibling)
			el.parentNode.insertBefore(newEl, el.nextSibling);
		else
			el.parentNode.appendChild(newEl);
	}
};

var UtilImg={
	maxW: 130,
	maxH: 100,
	
	imgLoad: function(e) {
		var maxW = UtilImg.maxW;
		var maxH = UtilImg.maxH;
		
		var img = e ? e.target : null;
		if (!img || !img.parentNode || img.className != 'thumb') return false;
		
		var w = img.clientWidth;
		var h = img.clientHeight;
		if ((w < 80 && h < 60) || w < 40 || h < 30) {
			UtilImg.imgError(e);
			return false;
		}else{
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
			
			img.parentNode.style.width = img.style.width = w+'px';
			img.parentNode.style.height = img.style.height = h+'px';
			img.parentNode.style.marginRight = '10px';
			img.parentNode.style.marginBottom = '5px';
			img.parentNode.style.visibility = 'visible';
		}
		return true;
	},
	imgError: function(e) {
		var img = e ? e.target : null;
		if (!img || !img.parentNode || img.className != 'thumb') return false;
	
		if (img._candidates && img._candidates.length > 0) {
			img.src = img._candidates.shift();
		}else{
			var p = img.parentNode;
			p.removeChild(img);
			if (p.parentNode) p.parentNode.removeChild(p);
		}
		return true;
	}
};