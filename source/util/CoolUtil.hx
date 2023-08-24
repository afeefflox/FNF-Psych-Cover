package util;

import flixel.FlxG;
import openfl.utils.Assets;
import lime.utils.Assets as LimeAssets;
import lime.utils.AssetLibrary;
import lime.utils.AssetManifest;
import flixel.system.FlxSound;
import meta.state.PlayState;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.graphics.frames.FlxAtlasFrames;
import animateatlas.AtlasFrameMaker;
import objects.Character;
import flixel.util.FlxSave;
import flixel.util.FlxColor;
import flixel.math.FlxMath;
#if sys
import sys.io.File;
import sys.FileSystem;
#else
import openfl.utils.Assets;
#end

using StringTools;

class CoolUtil
{

	inline public static function capitalize(text:String) {
		return text.charAt(0).toUpperCase() + text.substr(1).toLowerCase();
	}

	
	inline public static function quantize(f:Float, snap:Float){
		// changed so this actually works lol
		var m:Float = Math.fround(f * snap);
		trace(snap);
		return (m / snap);
	}
	
	//100 iq moment :/
	inline public static function boundTo(value:Float, min:Float, max:Float):Float {
		return FlxMath.bound(value, min, max);
	}

	public static function coolTextFile(path:String):Array<String>
	{
		var daList:Array<String> = [];
		#if sys
		if(FileSystem.exists(path)) daList = File.getContent(path).trim().split('\n');
		#else
		if(Assets.exists(path)) daList = Assets.getText(path).trim().split('\n');
		#end

		for (i in 0...daList.length)
		{
			daList[i] = daList[i].trim();
		}

		return daList;
	}
	public static function listFromString(string:String):Array<String>
	{
		var daList:Array<String> = [];
		daList = string.trim().split('\n');

		for (i in 0...daList.length)
		{
			daList[i] = daList[i].trim();
		}

		return daList;
	}

	inline public static function colorFromString(color:String):FlxColor
	{
		var hideChars = ~/[\t\n\r]/;
		var color:String = hideChars.split(color).join('').trim();
		if(color.startsWith('0x')) color = color.substring(color.length - 6);

		var colorNum:Null<FlxColor> = FlxColor.fromString(color);
		if(colorNum == null) colorNum = FlxColor.fromString('#$color');
		return colorNum != null ? colorNum : FlxColor.WHITE;
	}
	
	public static function dominantColor(sprite:flixel.FlxSprite):Int{
		var countByColor:Map<Int, Int> = [];
		for(col in 0...sprite.frameWidth){
			for(row in 0...sprite.frameHeight){
			  var colorOfThisPixel:Int = sprite.pixels.getPixel32(col, row);
				if(colorOfThisPixel != 0) {
					if(countByColor.exists(colorOfThisPixel))
						countByColor[colorOfThisPixel] = countByColor[colorOfThisPixel] + 1;
					else if(countByColor[colorOfThisPixel] != 13520687 - (2*13520687))
						countByColor[colorOfThisPixel] = 1;
				}
			}
		 }
		var maxCount = 0;
		var maxKey:Int = 0; //after the loop this will store the max color
		countByColor[FlxColor.BLACK] = 0;
		for(key in countByColor.keys()) {
			if(countByColor[key] >= maxCount) {
				maxCount = countByColor[key];
				maxKey = key;
			}
		}
		countByColor = [];
		return maxKey;
	}

	public static function numberArray(max:Int, ?min = 0):Array<Int>
	{
		var dumbArray:Array<Int> = [];
		for (i in min...max)
		{
			dumbArray.push(i);
		}
		return dumbArray;
	}

	//uhhhh does this even work at all? i'm starting to doubt
	public static function precacheSound(sound:String, ?library:String = null):Void {
		Paths.sound(sound, library);
	}

	public static function precacheMusic(sound:String, ?library:String = null):Void {
		Paths.music(sound, library);
	}

	public static function browserLoad(site:String) {
		#if linux
		Sys.command('/usr/bin/xdg-open', [site]);
		#else
		FlxG.openURL(site);
		#end
	}

	public static function loadFrames(key:String, ?library:String = null, SkipAtlasCheck:Bool = false):FlxFramesCollection {
		if (!SkipAtlasCheck && Paths.fileExists('images/$key/Animation.json', TEXT, false, library)
			&& Paths.fileExists('images/$key/spritemap.json', TEXT, false, library)
		    && Paths.fileExists('images/$key/spritemap.png', IMAGE, false, library))
		{
			return AtlasFrameMaker.construct(key, library);
		}
		else if (Paths.fileExists('images/$key.xml', TEXT, false, library) && Paths.fileExists('images/$key.png', IMAGE, false, library)) {
			return Paths.getSparrowAtlas(key, library);
		}
		else if (Paths.fileExists('images/$key.txt', TEXT, false, library) && Paths.fileExists('images/$key.png', IMAGE, false, library)) {
			return Paths.getPackerAtlas(key, library);
		}
		//**THIS IS NOT TEXTURE ATLAS**/
		else if (Paths.fileExists('images/$key.json', TEXT, false, library) && Paths.fileExists('images/$key.png', IMAGE, false, library)) {
			return Paths.getTexturePackerAtlas(key, library);
		}

		var graph:FlxGraphic = Paths.image(key, library);
		if (graph == null)
			return null;
		return graph.imageFrame;
	}

	inline public static function absoluteDirectory(file:String):Array<String>
	{
		if (!file.endsWith('/'))
			file = '$file/';


		var absolutePath:String = FileSystem.absolutePath(file);
		var directory:Array<String> = FileSystem.readDirectory(absolutePath);

		if (directory != null)
		{
			var dirCopy:Array<String> = directory.copy();

			for (i in dirCopy)
			{
				var index:Int = dirCopy.indexOf(i);
				var file:String = '$absolutePath$i';
				dirCopy.remove(i);
				dirCopy.insert(index, file);
			}

			directory = dirCopy;
		}

		return if (directory != null) directory else [];
	}

	public static function getSavePath(folder:String = 'psychcool'):String {
		@:privateAccess
		return #if (flixel < "5.0.0") folder #else FlxG.stage.application.meta.get('company')
			+ '/'
			+ FlxSave.validate(FlxG.stage.application.meta.get('file')) #end;
	}
}
