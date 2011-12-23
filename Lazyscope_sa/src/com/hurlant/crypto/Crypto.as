/**
 * Crypto
 * 
 * An abstraction layer to instanciate our crypto algorithms
 * Copyright (c) 2007 Henri Torgemane
 * 
 * See LICENSE.txt for full license information.
 */
package com.hurlant.crypto
{
	import com.hurlant.crypto.hash.HMAC;
	import com.hurlant.crypto.hash.IHash;
	import com.hurlant.crypto.hash.SHA1;
	import com.hurlant.crypto.rsa.RSAKey;
	import com.hurlant.util.Base64;
	
	/**
	 * A class to make it easy to use the rest of the framework.
	 * As a side-effect, using this class will cause most of the framework
	 * to be linked into your application, which is not always what you want.
	 * 
	 * If you want to optimize your download size, don't use this class.
	 * (But feel free to read it to get ideas on how to get the algorithm you want.)
	 */
	public class Crypto
	{
		private var b64:Base64; // we don't use it, but we want the swc to include it, so cheap trick.
		
		public function Crypto(){
		}
		
		/**
		 * Things that should work:
		 * "md5"
		 * "sha"
		 * "sha1"
		 * "sha224"
		 * "sha256"
		 */
		public static function getHash(name:String):IHash {
			switch(name) {
				case "sha": // let's hope you didn't mean sha-0
				case "sha1":
					return new SHA1;
			}
			return null;
		}
		
		/**
		 * Things that should work:
		 * "sha1"
		 * "md5-64"
		 * "hmac-md5-96"
		 * "hmac-sha1-128"
		 * "hmac-sha256-192"
		 * etc.
		 */
		public static function getHMAC(name:String):HMAC {
			var keys:Array = name.split("-");
			if (keys[0]=="hmac") keys.shift();
			var bits:uint = 0;
			if (keys.length>1) {
				bits = parseInt(keys[1]);
			}
			return new HMAC(getHash(keys[0]), bits);
		}
		
		/** mostly useless.
		 */
		public static function getRSA(E:String, M:String):RSAKey {
			return RSAKey.parsePublicKey(M,E);
		}
	}
}