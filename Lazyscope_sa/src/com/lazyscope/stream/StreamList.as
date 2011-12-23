package com.lazyscope.stream
{
	import com.lazyscope.Base;
	import com.lazyscope.control.FocusMarker;
	import com.lazyscope.control.FocusMarkerFloating;
	import com.lazyscope.entry.StreamEntry;
	import com.lazyscope.notifier.NotifyWindow;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.utils.*;
	
	import mx.collections.ArrayList;
	import mx.collections.Sort;
	import mx.collections.SortField;
	import mx.core.ClassFactory;
	import mx.core.IFactory;
	import mx.events.CollectionEvent;
	import mx.events.CollectionEventKind;
	
	import spark.components.Group;
	import spark.components.List;
	import spark.components.supportClasses.GroupBase;
	import spark.effects.Animate;
	import spark.effects.animation.MotionPath;
	import spark.effects.animation.SimpleMotionPath;
	import spark.effects.easing.Power;
	
	public class StreamList extends List
	{
		public static var _session:StreamList;
		public static const MAX_LIMIT:Number = 250;
		
		public var _mouseOver:Boolean = false;
		
		[Bindable]
		public var updateItem:StreamCollection = new StreamCollection;

		public function scroll(top:Number=0, noAnimate:Boolean = false, noValidation:Boolean=false):void
		{
			try{
				noAnimate = true;
			if (noAnimate) {
				scroller.viewport.verticalScrollPosition = top;
				//if (!noValidation) validateNow();
			}else{
				scrollTop.valueFrom = scroller.viewport.verticalScrollPosition;
				scrollTop.valueTo = top;
				if (animate.isPlaying)
					animate.stop();
				animate.target = scroller.viewport;
				animate.play();
			}
			}catch(e:Error) {
				trace(e.getStackTrace(), 'scroll streamlist');
			}
		}
		
		public static function getScrollTop(el:DisplayObject):Number
		{
			var top:Number = 0;
			
			while (el && el.name != 'StreamListInstance') {
				top += el.y;
				el = el.parent;
			}
			
			return top;
		}
		
		public static function findNextItem(el:DisplayObjectContainer):DisplayObject
		{
			try{
			el = findListItem(el);
			if (el && el.parent) {
				var idx:int = el.parent.getChildIndex(el);
				if (el.parent.numChildren <= idx+1)
					return null;
				var next:DisplayObject = el.parent.getChildAt(idx+1);
				return next;
			}
			}catch(e:Error) {
				trace(e.getStackTrace(), 'findNextItem streamlist');
			}
			return null;
		}
		
		public static function findListItem(el:DisplayObjectContainer):DisplayObjectContainer
		{
			try{
			var i:DisplayObjectContainer = null;
			while (el) {
				if (el.name.match(/^StreamItemRender/)) {
					i = el;
				}
				if (el.name == 'StreamListInstance')
					return i;
				el = el.parent;
			}
			}catch(e:Error) {
				trace(e.getStackTrace(), 'findListItem streamlist');
			}
			return i;
		}
		
		public static function session():StreamList
		{
			if (!StreamList._session)
				StreamList._session = new StreamList;
			return StreamList._session;
		}
		
		[bindable]
		public var data:StreamCollection;
		
		public var animate:Animate;
		public var scrollTop:SimpleMotionPath;
		
		public var streamUpdateBar:StreamUpdateBar;
		
		public function StreamList()
		{
			super();
			
			name = 'StreamListInstance';
			
			itemRendererFunction = itemRend;
			
			data = new StreamCollection;
			data.addEventListener(CollectionEvent.COLLECTION_CHANGE, dataChanged, false, -10, true);
			data.uniqKey = 'sid';
			
			var sort1:SortField = new SortField('sortk1');
			sort1.numeric = true;
			sort1.descending = true;
			var sort2:SortField = new SortField('published');
			sort2.numeric = true;
			sort2.descending = true;
			
			var sort:Sort = new Sort();
			sort.fields = [sort1, sort2];
			
			//data.maxCount = 100;
			data.sort = sort;
			dataProvider = data;
			data.refresh();
			
			addEventListener(MouseEvent.MOUSE_WHEEL, function(event:MouseEvent):void {
				try{
					event.preventDefault();
					if (event.delta == 0) return;
					var d:Number = event.delta;
					if (d > 0 && d > 3) d = 3;
					else if (d < 0 && d < -3) d = -3;
					scroller.viewport.verticalScrollPosition -= d * 15;
				}catch(e:Error) {
					trace(e.getStackTrace(), 'StreamList');
				}
			}, true, 100);
			
			StreamList._session = this;
			
			setStyle('borderVisible', false);
			setStyle('fontFamily', 'Arial');
			addEventListener(Event.ADDED_TO_STAGE, function(event:Event):void {
				scroller.setStyle('verticalScrollPolicy', 'on');
			});
			
			//cacheAsBitmap = true;
			
			scrollTop = new SimpleMotionPath('verticalScrollPosition');
			animate = new Animate;
			animate.duration = 500;
			//animate.easer = new Power(0.5, 3);
			animate.motionPaths = new Vector.<MotionPath>;
			animate.motionPaths.push(scrollTop);
			
			updateItem.maxCount = 250;
			updateItem.uniqKey = 'sid';
			updateItem.setSort([['published', true, false]]);
			updateItem.addEventListener(StreamCollectionEvent.CUT, updateItemCut, false, -10, true);
			//updateItem.addEventListener(CollectionEvent.COLLECTION_CHANGE, dataChanged, false, -10, true);
		}
		
		private function updateItemCut(event:StreamCollectionEvent):void
		{
			if (event.item && event.item is StreamEntry) {
				var se:StreamEntry = StreamEntry(event.item);
				se.destroy();
			}
		}
		
		private function dataChanged(event:CollectionEvent):void
		{
			//trace('dataChanged', event.kind);
			if (event.kind == CollectionEventKind.REMOVE) {
				for (var i:Number=0; i < event.items.length; i++) {
					var obj:Object = event.items[i];
					if (obj is StreamEntry) {
						var se:StreamEntry = StreamEntry(obj);
						se.destroy();
					}
				}
			}
		}
		
		private var factoryTwitter:ClassFactory = new ClassFactory(StreamItemRendererTwitter);
		private var factoryTwitterMessage:ClassFactory = new ClassFactory(StreamItemRendererTwitterMessage);
		private var factoryFavoriteLink:ClassFactory = new ClassFactory(StreamItemRendererFavoriteLink);
		private var factoryBlog:ClassFactory = new ClassFactory(StreamItemRendererBlog);
		public function itemRend(item:Object):IFactory
		{
			try{
			var e:StreamEntry = StreamEntry(item);
			switch (e.type) {
				case 'T':
					return factoryTwitter;
					break;
				case 'M':
					return factoryTwitterMessage;
					break;
				case 'FL':
					return factoryFavoriteLink;
					break;
				default:
					return factoryBlog;
					break;
			}
			}catch(e:Error) {
				trace(e.getStackTrace(), 'itemRend');
			}
			return null;
		}
		
		public function refresh(force:Boolean=false):void
		{
			if (animate.isPlaying)
				animate.stop();
			if (data.length > MAX_LIMIT || force) {
				scroll(0, true, true);
				//trace('refresh');
				while (data.length > MAX_LIMIT) {
					//trace('data.removeItemAt', data.length);
					try{
//trace('****', data.getItemAt(data.length-1)['type'], data.getItemAt(data.length-1)['published'], data.getItemAt(data.length-1));
						data.removeItemAt(data.length-1);
					}catch(e:Error) {
						trace(e.getStackTrace(), 'refresh');
					}
				}
			}
			//data.refresh();
			dispatchEvent(new MouseEvent(MouseEvent.MOUSE_WHEEL));
			
			//Base.stream.notifier.clear();
		}
		
		public function truncate():void
		{
			try{
				if (data.length > 0)
					data.removeAll();
			}catch(e:Error) {
				trace(e.getStackTrace(), 'truncate1');
			}
			
			try{
				data.refresh();
			
				if (_addItem.length > 0)
					_addItem.removeAll();
				if (updateItem.length > 0)
					updateItem.removeAll();
			}catch(e:Error) {
				trace(e.getStackTrace(), 'truncate2');
			}
		}
		
		public function hasData():Boolean
		{
			return (data.length > 0 || _addItem.length > 0 || updateItem.length > 0);
		}
		
		private var _addItem:ArrayList = new ArrayList;
		
		public var _addItemTimer:uint = 0;
		private var _addPhase:Number = 1;
		//private var _addItemUpdate:Boolean = false;
		public function addItem(item:StreamEntry, sortK1:Number = NaN):void
		{
			if (!item || !Base.twitter.ready) {
//				trace('************ NULL ITEM ************');
				return;
			}
			clearTimeout(_addItemTimer);
			
			try{
				item.isUpdated = isNaN(sortK1) || sortK1 > 1;
			
				/*
				if (!_addItemUpdate)
					_addItemUpdate = !!item.isUpdated;
				*/
				
				item.sortk1 = isNaN(sortK1)?_addPhase:sortK1;
				item.sortk2 = item.published ? item.published.getTime() : 0;
				if (isNaN(item.sortk2))
					item.sortk2 = -1;
				
				if (item.isUpdated) {
					if (data.length > 0) {		// filter out duplicated StreamEntry
						for (var i:Number = 0; i < 30 && i < data.length; i++) {
							try{
								if (i < data.length && data[i] && item.sid == data[i].sid) return;
								if (i >= data.length || !data[i]) break;
							}catch(e:Error){
								break;
							}
						}
					}
					
					if (item.type == 'T')
						StreamItemRendererTwitter.getContent(item, true);
					else if (item.type == 'M')
						StreamItemRendererTwitterMessage.getContent(item, true);
					
					updateItem.addItem(item);
					NotifyWindow.addUpdateCache(item);
				}else
					_addItem.addItem(item);
				
				_addItemTimer = setTimeout(importItem, 100);
			}catch(e:Error) {
				trace(e.getStackTrace(), 'addItem streamlist');
			}
		}
		
		public var focusMarkerFloatingEnabled:Boolean = false;
		public function importItem():void
		{
			try{
			if (!Base.twitter.ready) {
				if (_addItem.length > 0)
					_addItem.removeAll();
				if (updateItem.length > 0)
					updateItem.removeAll();
				return;
			}
			_addPhase++;
			
			var added:Boolean = _addItem.length > 0;
			if (added) {
				data.addAll(_addItem);
				_addItem.removeAll();
			}
			
			if (updateItem.length > 0 && scroller.viewport.verticalScrollPosition <= 10 && !streamUpdateBar.isStacked && !Base.updateStack) {
				/*
				if (added) {
					validate();
				}
				var curTop:Number = scroller.viewport.verticalScrollPosition;
				var curHeight:Number = scroller.viewport.contentHeight;
				
				/////////
				var idx:int = (StreamItemRenderer.focusedData && !Base.contentViewer.focused && curTop <= 10 && Base.contentContainer.parent.visible) ? data.getItemIndex(StreamItemRenderer.focusedData) : -1;
				if (_timerFocusMarkerFloating > 0) idx = 0;
				
//				var mouseOver:Boolean = _mouseOver;
				var mouseOver:Boolean = false;
				
				if (focusMarkerFloatingEnabled && !mouseOver && idx == 0) {
					FocusMarkerFloating.focusMarkerFloating.width = FocusMarker.focusMarker.width;
					FocusMarkerFloating.focusMarkerFloating.height = FocusMarker.focusMarker.height;
					FocusMarkerFloating.focusMarkerFloating.visible = true;
					try{
						if (StreamItemRenderer.focusedData && StreamItemRenderer.focusedData.renderer)
							StreamItemRenderer.focusedData.renderer.onFocusOut();
					}catch(err:Error) {
						trace(err.getStackTrace(), 'importItem');
					}
				}
				*/
				
				scroller.viewport.verticalScrollPosition = 0;
				
				var curCnt:Number = data.length;
				data.addAll(updateItem);
				
				if (data.length > 350)
					callLater(refresh);
				
				/*
				validate();
				
				scroller.viewport.verticalScrollPosition = curTop + (scroller.viewport.contentHeight - curHeight);
				
				if (!mouseOver && curTop <= 10 && Base.contentContainer.parent.visible) {
					if (data.length > 350) {
						callLater(refresh);
					}else
						scroll();
				}else if (!animate.isPlaying) {
				}
				*/
				
				
				/*
				///////////
				if (focusMarkerFloatingEnabled && !mouseOver && idx == 0) {
					if (_timerFocusMarkerFloating)
						clearTimeout(_timerFocusMarkerFloating);
					_timerFocusMarkerFloating = setTimeout(function():void{
						FocusMarkerFloating.focusMarkerFloating.visible = false;
						if (data.length > 0) {
							if (!animate.isPlaying)
								scroll();
							//validate();
							try{
								var _tmpStreamEntry:StreamEntry = StreamEntry(data.getItemAt(0));
								if (_tmpStreamEntry && _tmpStreamEntry.renderer)
									StreamItemRenderer.onFocusIn(_tmpStreamEntry.renderer, false);
							}catch(err:Error) {
								trace(err.getStackTrace(), 'importItem2');
							}
							_timerFocusMarkerFloating = 0;
//							var e:StreamEntry = StreamEntry(data.getItemAt(0));
//							if (e && e.renderer) {
//								e.renderer.onFocusIn(false);
//							}
						}
					}, 705);	// 1004 -> 705
				}
				*/
				
				updateItem.removeAll();
			}
			
			}catch(e:Error) {
				trace('importItem', e, e.getStackTrace());
			}
		}
		
		public function updateItemFlush():void
		{
			if (updateItem.length <= 0) return;
			try{
				data.addAll(updateItem);
				refresh(true);
			}catch(e:Error) {
				trace(e.getStackTrace(), 'updateItemFlush1');
			}
			
			try{
				validate();
			}catch(e:Error) {
				trace(e.getStackTrace(), 'updateItemFlush2');
			}
			
			setTimeout(focusReset, 10);
			try{
				if (updateItem.length > 0)
					updateItem.removeAll();
			}catch(e:Error) {
				trace(e.getStackTrace(), 'updateItemFlush4');
			}
		}
		
		public function focusReset():void
		{
			//try{
				if (data.length <= 0) return;
				var _tmpStreamEntry:StreamEntry = StreamEntry(data.getItemAt(0));
				if (_tmpStreamEntry && _tmpStreamEntry.renderer)
					StreamItemRenderer.onFocusIn(_tmpStreamEntry.renderer, false);
				/*
			}catch(e:Error) {
				trace(e.getStackTrace(), 'updateItemFlush3');
			}
				*/
		}
		
		private static var _timerFocusMarkerFloating:uint = 0;
		
		public function validate():void
		{
			try{
				if (dataGroup) dataGroup.validateDisplayList();
			}catch(e:Error) {
				trace(e.getStackTrace(), 'validate');
			}
		}
	}
}