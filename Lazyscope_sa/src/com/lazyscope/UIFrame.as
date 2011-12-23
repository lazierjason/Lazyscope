package com.lazyscope
{
	import flash.display.Screen;
	import flash.events.NativeWindowBoundsEvent;
	import flash.utils.clearTimeout;
	import flash.utils.setTimeout;
	
	import mx.controls.Alert;
	import mx.core.UIComponent;

	public class UIFrame
	{
		public static var app:Lazyscope_sa;

		public static const STREAM_WIDTH:Number = 375;
		public static const MIN_WIDE_SIZE:Number = 1000;
		public static const ADJUST_TOLERANCE:Number = 10;

		public static var miniMode:Boolean = true;
		
		private static var _nativeWindow_x:Number;
		private static var _nativeWindow_w:Number;
		private static var _notRealMoveResize:Boolean = false;
		private static var resizeTimer:uint;

		public function UIFrame()
		{
		}
		
		public static function saveAppWindow():void
		{
			if (!app) return;
			if (!app.visible) return;
			ConfigDB.set('lf_window_setting', String(_nativeWindow_x ? _nativeWindow_x : app.nativeWindow.x)+'_'+String(app.nativeWindow.y)+'_'+String(_nativeWindow_w ? _nativeWindow_w : MIN_WIDE_SIZE)+'_'+String(app.nativeWindow.height));
		}
		
		public static function initAppWindow(app:Lazyscope_sa):void
		{
			UIFrame.app = app;
			
			app.nativeWindow.addEventListener(NativeWindowBoundsEvent.RESIZE, function(event:NativeWindowBoundsEvent):void {
				if (app.nativeWindow && !_notRealMoveResize && app.width >= MIN_WIDE_SIZE) {
					_nativeWindow_w = app.width;
				}
			});
			app.nativeWindow.addEventListener(NativeWindowBoundsEvent.MOVE, function(event:NativeWindowBoundsEvent):void {
				if (app.nativeWindow && !_notRealMoveResize) {
					_nativeWindow_x = app.nativeWindow.x;
				}
			});

			
			var windowSettingStr:String = ConfigDB.get('lf_window_setting');
			if (!windowSettingStr) windowSettingStr = '';
			var m:Array = null;
			if (windowSettingStr && (m = windowSettingStr.match(/^(\d+)_(\d+)_(\d+)_(\d+)/))) {
				var __x:Number = Number(m[1]);
				var __y:Number = Number(m[2]);
				var __w:Number = Number(m[3]);
				var __h:Number = Number(m[4]);
				
				if (__x >= Screen.mainScreen.visibleBounds.x - ADJUST_TOLERANCE &&
					//						__x+__w <= Screen.mainScreen.visibleBounds.x+Screen.mainScreen.visibleBounds.width &&
					__x+(STREAM_WIDTH + (!Base.sidebar || Base.sidebar.visible?240:0)) <= Screen.mainScreen.visibleBounds.x+Screen.mainScreen.visibleBounds.width + ADJUST_TOLERANCE &&
					__y >= Screen.mainScreen.visibleBounds.y - ADJUST_TOLERANCE &&
					__y+__h <= Screen.mainScreen.visibleBounds.y+Screen.mainScreen.visibleBounds.height + ADJUST_TOLERANCE) {
					_x = __x;
					_y = __y;
					_w = __w;
					_h = __h;
					app.nativeWindow.x = __x;
					app.nativeWindow.y = __y;
					_nativeWindow_w = (__w < MIN_WIDE_SIZE ? MIN_WIDE_SIZE : __w);
					app.nativeWindow.height = __h;
					return;
				}
			}
			var _w:Number = Math.max(Math.min(Math.floor(Screen.mainScreen.visibleBounds.width * 0.9), 1200), app.minWidth);
			var _h:Number = Math.max(Math.min(Math.floor(Screen.mainScreen.visibleBounds.height * 0.8), 750), app.minHeight);
			var _x:Number = Screen.mainScreen.visibleBounds.x + Math.floor(Math.max(0, Screen.mainScreen.visibleBounds.width-_w)/2);
			var _y:Number = Screen.mainScreen.visibleBounds.y + Math.floor(Math.max(0, Screen.mainScreen.visibleBounds.height-_h)/2);
			app.nativeWindow.x = _x;
			app.nativeWindow.y = _y;
			_nativeWindow_w = _w;
			app.nativeWindow.height = _h;
		}
		
		public static function showContentFrame():void
		{
			Base.sidebar.visible = true;
			Base.topbar.btnFrame1.selected = !Base.sidebar.visible;
			Base.topbar.btnFrame3.selected = !Base.topbar.btnFrame1.selected;
			
			if (!app) return;
			if (!miniMode) return;
			miniMode = false;
		
//			if (resizeTimer)
//				clearTimeout(resizeTimer);
//			_notRealMoveResize = true;
//			
//			miniMode = false;
//			var nowNativeWindowX:Number = app.nativeWindow.x;
//			app.maxWidth = UIComponent.DEFAULT_MAX_WIDTH;
//			app.width = _nativeWindow_w;
//			
//			setTimeout(function():void{
//				app.nativeWindow.x = Math.min(nowNativeWindowX, Screen.mainScreen.visibleBounds.width-_nativeWindow_w);
//				//app.toolbar.btnFeedback.visible = app.toolbar.lineFeedback.visible = true;
//				resizeTimer = setTimeout(function():void {
//					_notRealMoveResize = false;
//				}, 500);
//				setTimeout(function():void {app.minWidth = MIN_WIDE_SIZE;}, 0);
//			}, 0);
			
			if (resizeTimer)
				clearTimeout(resizeTimer);
			_notRealMoveResize = true;
			resizeTimer = setTimeout(function():void {
				_notRealMoveResize = false;
			}, 100);
			
			_nativeWindow_x = app.nativeWindow.x;
			
			app.maxWidth = UIComponent.DEFAULT_MAX_WIDTH;
			app.width = _nativeWindow_w;
			app.validateNow();
			app.minWidth = MIN_WIDE_SIZE;
			
			var nowNativeWindowX:Number = app.nativeWindow.x;
			app.nativeWindow.x = Math.min(app.nativeWindow.x, Screen.mainScreen.visibleBounds.width-_nativeWindow_w);
			
		}
		
		public static function hideContentFrame():void
		{
			Base.sidebar.visible = false;
			Base.topbar.btnFrame1.selected = !Base.sidebar.visible;
			Base.topbar.btnFrame3.selected = !Base.topbar.btnFrame1.selected;
			
//			if (!app) return;
//			if (miniMode) return;
//
//			if (resizeTimer)
//				clearTimeout(resizeTimer);
//			_notRealMoveResize = true;
//			
//			miniMode = true;
//			app.viewer.focused = false;
//			app.minWidth = STREAM_WIDTH + (Base.sidebar.visible?Base.sidebar.width:0);
//			app.width = STREAM_WIDTH + (Base.sidebar.visible?Base.sidebar.width:0);
//			
//			setTimeout(function():void{
//				app.nativeWindow.x = Math.max(_nativeWindow_x, 0);
//				//app.toolbar.btnFeedback.visible = app.toolbar.lineFeedback.visible = false;
//				resizeTimer = setTimeout(function():void {_notRealMoveResize = false;}, 500);
//				setTimeout(function():void {app.maxWidth = STREAM_WIDTH + (Base.sidebar.visible?Base.sidebar.width:0);}, 0);
//			}, 0);
			
			
			if (!app) return;
			if (miniMode) return;
			miniMode = true;

			if (resizeTimer)
				clearTimeout(resizeTimer);
			_notRealMoveResize = true;
			resizeTimer = setTimeout(function():void {
				_notRealMoveResize = false;
			}, 100);
			
			app.viewer.focused = false;
			app.minWidth = STREAM_WIDTH + (Base.sidebar.visible?Base.sidebar.width:0);
			app.width = STREAM_WIDTH + (Base.sidebar.visible?Base.sidebar.width:0);
			app.validateNow();
			app.maxWidth = STREAM_WIDTH + (Base.sidebar.visible?Base.sidebar.width:0);
			app.nativeWindow.x = Math.max(_nativeWindow_x, 0);
		}

	}
}