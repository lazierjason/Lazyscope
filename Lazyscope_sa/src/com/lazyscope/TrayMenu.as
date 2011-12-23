package com.lazyscope
{
	import flash.desktop.InteractiveIcon;
	import flash.desktop.NativeApplication;
	import flash.desktop.SystemTrayIcon;
	import flash.events.InvokeEvent;
	import flash.events.ScreenMouseEvent;
	import flash.system.Capabilities;
	
	import mx.events.FlexNativeMenuEvent;
	
	import spark.components.Image;

	public class TrayMenu
	{
		//public static var menu:FlexNativeMenu;
		public static var app:Lazyscope;
		
		[Bindable] public static var trayMenuData:Array = [{'label':'Open'}, {'label':'Quit'}];
		
		
		public function TrayMenu()
		{
		}
		
		public static function onTrayMenuItemClick(event:FlexNativeMenuEvent):void
		{
			var el:Object = event.item;
			if (el) {
				switch (el.label) {
					case 'Open':
						TrayMenu.app.onShowWindow();
						break;
					case 'Quit':
						TrayMenu.app.quit();
						break;
				}
			}
		}
		
		public static function initMenu(app:Lazyscope, trayIcon:Image):void
		{
			if (Capabilities.os.substr(0, 3).toLowerCase() != 'mac') return;
			
			TrayMenu.app = app;
			
			if (NativeApplication.supportsDockIcon)
				NativeApplication.nativeApplication.addEventListener(InvokeEvent.INVOKE, app.onShowWindow, false, 0, true);
			/*
			else if (NativeApplication.supportsSystemTrayIcon)
				SystemTrayIcon(NativeApplication.nativeApplication.icon).addEventListener(ScreenMouseEvent.CLICK, app.onShowWindow, false, 0, true);
			
			menu = new FlexNativeMenu;
			menu.showRoot = false;
			menu.addEventListener(FlexNativeMenuEvent.ITEM_CLICK, onTrayMenuItemClick, false, 0, true);
			
			if (NativeApplication.supportsSystemTrayIcon) {
				var icon:InteractiveIcon; 
				icon = NativeApplication.nativeApplication.icon;
				
				SystemTrayIcon(icon).bitmaps = new Array(trayIcon.bitmapData); 
				SystemTrayIcon(icon).tooltip = 'Lazyscope';
				
				menu.dataProvider = trayMenuData;
				
				app.systemTrayIconMenu = menu;
			}
			
			if (Capabilities.os.substr(0, 3).toLowerCase() == 'mac') {
				var pref:NativeMenuItem = new NativeMenuItem('Preferences');
				pref.keyEquivalent = ',';
				pref.addEventListener(Event.SELECT, function(event:Event):void {
				PreferenceWindow.show();
				}, false, 0, true);
				NativeMenuItem(NativeApplication.nativeApplication.menu.items[0]).submenu.addItemAt(pref, 1);
			}
			*/
		}
		
	}
}