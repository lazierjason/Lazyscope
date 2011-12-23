package com.lazyscope.account
{
	public interface IAccount
	{
		function get type():String;
		function get id():String;
		function get label():String;
		function get tooltip():String;
		function selected(context:String=null):void;
		function getImageSrc():String;
	}
}