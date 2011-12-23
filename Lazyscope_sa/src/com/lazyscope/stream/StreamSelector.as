package com.lazyscope.stream
{
	import com.lazyscope.Base;
	
	import mx.collections.ArrayCollection;
	import mx.collections.Sort;
	import mx.collections.SortField;
	import mx.core.ClassFactory;
	import mx.core.mx_internal;
	
	import spark.components.List;
	
	use namespace mx_internal;
	
	public class StreamSelector extends List
	{
		protected static var _session:StreamSelector = null;

		public static function session():StreamSelector
		{
			if (!StreamSelector._session)
				StreamSelector._session = new StreamSelector;
			return StreamSelector._session;
		}
		
		public function get data():ArrayCollection
		{
			return Base.selectorData;
		}

		public function StreamSelector()
		{
			super();
			
			_session = this;

			var sort:Sort = new Sort;
			var sf1:SortField = new SortField('type');
			sf1.numeric = true;
			sf1.descending = false;
			
			var sf2:SortField = new SortField('name');
			sf2.numeric = false;
			sf2.descending = false;
			
			sort.fields = [sf1, sf2];
			data.sort = sort;
			
			setStyle('borderVisible', false);

//			requireSelection = true;
			
			itemRenderer = new ClassFactory(StreamSelectorItem);
			dataProvider = data;
			
			labelField = 'name';
			
			truncate();
		}
		
		public function truncate():void
		{
			data.removeAll();
			data.refresh();
			
			data.addItem({type:1, name:'All subscriptions'});
			data.addItem({type:3, name:'Lists'});
			data.addItem({type:6, name:'Following blogs'});
			
			callLater(function():void {
				selectedIndex = 0;
			});
			
			alpha = 1;
		}
		
		public function addItem(item:Object):void
		{
			if (!item) return;
			if (item.type == 7 && item.data && item.data.feedlink)
				removeBlog(item.data.feedlink);
			data.addItem(item);
		}
		
		public function removeBlog(feedlink:String):void
		{
			for (var i:Number=data.length; i--;) {
				var obj:Object = data.getItemAt(i);
				if (!obj) continue;
				if (obj.type == 7 && obj.data.feedlink == feedlink) {
					data.removeItemAt(i);
					break;
				}
			}
		}
	}
}