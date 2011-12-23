package com.lazyscope.stream
{
	[Event(name="cut", type="com.lazyscope.stream.StreamCollectionEvent")]
	
	import com.lazyscope.Util;
	import com.lazyscope.entry.BlogEntry;
	import com.lazyscope.entry.StreamEntry;
	
	import flash.events.Event;
	import flash.utils.clearTimeout;
	import flash.utils.setTimeout;
	
	import mx.collections.ArrayCollection;
	import mx.collections.Sort;
	import mx.collections.SortField;
	import mx.events.CollectionEvent;
	import mx.events.CollectionEventKind;
	
	public class StreamCollection extends ArrayCollection
	{
		public var minKey:String = Util.MAX_VALUE;
		public var maxKey:String = Util.MIN_VALUE;
		
		public var minmaxKey:String = null;
		public var uniqKey:String = null;
		
		public var userData:Object;
		public var maxCount:Number = -1;

		public function StreamCollection(source:Array=null, maxCount:Number = -1)
		{
			super(source);
			
			if (maxCount > -1)
				this.maxCount = maxCount;
			
			addEventListener(CollectionEvent.COLLECTION_CHANGE, function(event:CollectionEvent):void {
				var i:Number;
				//trace('changed', event.kind, event.items.length);
				if (event.kind == CollectionEventKind.ADD) {
					for (i=0; i < event.items.length; i++) {
						setMinMax(event.items[i]);
					}
					cut();
				}else if (event.kind == CollectionEventKind.REMOVE) {
					if (length <= 0) {
						minKey = Util.MAX_VALUE;
						maxKey = Util.MIN_VALUE;
					}
				}
			});
		}
		
		private var _cutTimer:uint;
		public function cut():void
		{
			clearTimeout(_cutTimer);
			_cutTimer = setTimeout(_cut, 100);
		}
		
		private function _cut():void
		{
			clearTimeout(_cutTimer);
			
			if (maxCount > -1) {
				while (length > maxCount) {
					//trace('cut', length, maxCount, length-1);
					var obj:Object = removeItemAt(length-1);
//trace('####', obj['published'], obj);
					if (obj && hasEventListener(StreamCollectionEvent.CUT))
						dispatchEvent(new StreamCollectionEvent(StreamCollectionEvent.CUT, obj));
				}
			}
		}
		
		public function setSort(sorts:Array, unique:Boolean=false):void
		{
			var sort:Sort = new Sort();
			sort.unique = unique;
			if (!sort.fields) sort.fields = new Array;
			
			for (var i:Number=0; i < sorts.length; i++) {
				var sf:SortField = new SortField(sorts[i][0]);
				sf.numeric = sorts[i][1];
				sf.descending = !sorts[i][2];
				
				sort.fields.push(sf);
			}
			this.sort = sort;
			refresh();
		}
		
		public function setMinMax(item:Object):void
		{
			if (minmaxKey && item[minmaxKey]) {
				minKey = Util.min(minKey, item[minmaxKey]);
				maxKey = Util.max(maxKey, item[minmaxKey]);
			}
		}
		
		public function removeSearchedItems(prop:String, search:Object):void
		{
			for (var i:Number=length; i--;) {
				var o:Object = getItemAt(i);
				try{
					if (o && o[prop] && o[prop] == search)
						removeItemAt(i);
				}catch(err:*) {}
			}
		}
		
		public function updateSearchedItems(prop:String, search:Object, newValues:Object):void
		{
			for (var i:Number=length; i--;) {
				var o:Object = getItemAt(i);
				try{
					if (o && o[prop] && o[prop] == search)
						for (var k:String in newValues)
							o[k] = newValues[k];
				}catch(err:*) {}
			}
		}
		
		public function isset(prop:String, search:Object):Boolean
		{
			for (var i:Number=length; i--;) {
				var o:Object = getItemAt(i);
				if (o && o[prop] && o[prop] == search)
					return true;
			}
			return false;
		}
		
		override public function addItemAt(item:Object, index:int):void
		{
			if (uniqKey && isset(uniqKey, item[uniqKey])) return;
			
			super.addItemAt(item, Math.min(length, index));
		}

		/*
		override public function removeItemAt(index:int):Object
		{
			var obj:Object = null;
			try{
				obj = super.removeItemAt(index);
				
				if (obj is StreamEntry)
					StreamEntry.cleanup(obj as StreamEntry);
				else if (obj is BlogEntry)
					BlogEntry.cleanup(obj as BlogEntry);
			}catch(error:Error) {
				trace('removeItemAt', error);
			}
			
			return obj;
		}
		
		override public function removeAll():void
		{
			super.removeAll();
			
			minKey = Util.MAX_VALUE;
			maxKey = Util.MIN_VALUE;
		}
		*/
	}
}