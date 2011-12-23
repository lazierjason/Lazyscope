package com.lazyscope.stream
{
	import com.lazyscope.Base;
	import com.lazyscope.control.FocusMarker;
	import com.lazyscope.control.PreviewBtn;
	import com.lazyscope.entry.StreamEntry;
	
	import flash.utils.setTimeout;
	
	import flashx.textLayout.events.FlowElementMouseEvent;
	
	import mx.managers.IFocusManagerComponent;
	
	import spark.components.Group;
	import spark.components.supportClasses.ItemRenderer;
	
	public class StreamItemRenderer extends ItemRenderer implements IFocusManagerComponent
	{
		protected var time:Number = -1;
		
		public var spinners:Group;
		
		public var imageCandidates:Array;
		
		static public var focusedData:StreamEntry = null;
		static public var selectedData:StreamEntry = null;
		//public static const bgcolor:Array = [0xFFFFFF];
		//public static const bgcolorN:Array = [0xF4FAFD];
		
		public function StreamItemRenderer()
		{
			super();
			
			width = 360;
			
			autoDrawBackground = false;
			
			//addEventListener(Event.REMOVED_FROM_STAGE, removed, false, 0, true);
			
			/*
			setStyle('alternatingItemColors', bgcolor);
			setStyle('selectionColor', 0xE4E4DA);
			setStyle('rollOverColor', 0xF4F1CA);
			*/
			
			//cacheAsBitmap = true;
		}
		
		/*
		private function removed(event:Event):void
		{
			if (super.data && super.data is StreamEntry && focusedData != super.data) {
				var se:StreamEntry = super.data as StreamEntry;
				se.renderer = null;
				if (se.child && se.child.numElements)
					se.child.removeAllElements();
				se.child = null;
			}
		}
		*/
		
		public function clearHighlight():void
		{
			if (!data) return;
			if (!Base.mouseMoving) return;
			
			var e:StreamEntry = data as StreamEntry;
			
			if (e.isUpdated) {
				if (opaqueBackground) opaqueBackground = null;
				//setStyle('alternatingItemColors', bgcolor);
				e.isUpdated = false;
				/*
				if (this is StreamItemRendererTwitter || this is StreamItemRendererTwitterMessage)
					StreamItemRendererTwitter.clearHighlight2(this);
				*/
			}
		}
		
		public function onOver():void
		{
			return;
			try{
				if (PreviewBtn.BTN) {
					PreviewBtn.BTN.toOpen = !selected;
					addElement(PreviewBtn.BTN);
				}
			}catch(e:Error){
				trace(e.getStackTrace(), 'onOver renderer');
			}
		}
		
		public function onOut():void
		{
			return;
			try{
				if (PreviewBtn.BTN) {
					removeElement(PreviewBtn.BTN);
				}
			}catch(e:Error){
				trace(e.getStackTrace(), 'onOut renderer');
			}
		}
		
		public static function onFocusIn(obj:StreamItemRenderer, toClear:Boolean = true, clearFocused:Boolean = false):void
		{
			try{
				if (obj && FocusMarker.focusMarker) {
					FocusMarker.addTo(obj);
					
					focusedData = selectedData = StreamEntry(obj.data);
					if (toClear)
						setTimeout(obj.clearHighlight, 500);
				}
			}catch(e:Error) {
				trace(e.getStackTrace(), 'onFocusIn itemrenderer');
			}
			
			if (clearFocused)
				Base.contentViewer.focused = false;
		}
		
		public function onFocusOut():void
		{
			try{
				if (FocusMarker.focusMarker) {
					FocusMarker.removeFrom(this);
					focusedData = selectedData = null;
				}
			}catch(e:Error) {
				trace(e.getStackTrace(), 'onFocusOut itemrenderer');
			}
		}

		public function onClick(forceOpen:Boolean = false):void
		{
			// To override
		}
		
		protected static function linkHandler(event:FlowElementMouseEvent):void
		{
			//				trace('================');
			//				trace(event);
			//				trace(event.flowElement);
			//				trace(event.flowElement.typeName);
			//				trace(event.flowElement['href']);
			//				trace('-----------------');
			
			Base.userViewer.displayUser(event.flowElement['href']);
			event.preventDefault();
			event.stopPropagation();
		}
	}
}