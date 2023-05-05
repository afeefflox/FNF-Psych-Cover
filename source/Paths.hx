package;

import animateatlas.AtlasFrameMaker;
import flixel.math.FlxPoint;
import flixel.graphics.frames.FlxFrame.FlxFrameAngle;
import openfl.geom.Rectangle;
import flixel.math.FlxRect;
import haxe.xml.Access;
import openfl.system.System;
import flixel.FlxG;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.frames.FlxFramesCollection;
import openfl.utils.AssetType;
import openfl.utils.Assets as OpenFlAssets;
import lime.utils.Assets;
import flixel.FlxSprite;
#if sys
import sys.io.File;
import sys.FileSystem;
#end
import flixel.graphics.FlxGraphic;
import openfl.display.BitmapData;
import haxe.Json;

import flash.media.Sound;
import util.CoolUtil;

using StringTools;

class Paths
{
	inline public static var SOUND_EXT = #if web "mp3" #else "ogg" #end;
	inline public static var VIDEO_EXT = "mp4";

	#if MODS_ALLOWED
	public static var ignoreModFolders:Array<String> = [
		'characters',
		'custom_events',
		'custom_notetypes',
		'data',
		'songs',
		'music',
		'sounds',
		'shaders',
		'videos',
		'images',
		'stages',
		'weeks',
		'fonts',
		'scripts',
		'achievements'
	];
	#end

	public static function excludeAsset(key:String) {
		if (!dumpExclusions.contains(key))
			dumpExclusions.push(key);
	}

	public static var dumpExclusions:Array<String> =
	[
		'assets/music/freakyMenu.$SOUND_EXT',
		'assets/shared/music/breakfast.$SOUND_EXT',
		'assets/shared/music/tea-time.$SOUND_EXT',
	];
	/// haya I love you for the base cache dump I took to the max
	public static function clearUnusedMemory() {
		// clear non local assets in the tracked assets list
		for (key in currentTrackedAssets.keys()) {
			// if it is not currently contained within the used local assets
			if (!localTrackedAssets.contains(key)
				&& !dumpExclusions.contains(key)) {
				// get rid of it
				var obj = currentTrackedAssets.get(key);
				@:privateAccess
				if (obj != null) {
					openfl.Assets.cache.removeBitmapData(key);
					FlxG.bitmap._cache.remove(key);
					obj.destroy();
					currentTrackedAssets.remove(key);
				}
			}
		}
		// run the garbage collector for good measure lmfao
		System.gc();
	}

	// define the locally tracked assets
	public static var localTrackedAssets:Array<String> = [];
	public static function clearStoredMemory(?cleanUnused:Bool = false) {
		// clear anything not in the tracked assets list
		@:privateAccess
		for (key in FlxG.bitmap._cache.keys())
		{
			var obj = FlxG.bitmap._cache.get(key);
			if (obj != null && !currentTrackedAssets.exists(key)) {
				openfl.Assets.cache.removeBitmapData(key);
				FlxG.bitmap._cache.remove(key);
				obj.destroy();
			}
		}

		// clear all sounds that are cached
		for (key in currentTrackedSounds.keys()) {
			if (!localTrackedAssets.contains(key)
			&& !dumpExclusions.contains(key) && key != null) {
				//trace('test: ' + dumpExclusions, key);
				Assets.cache.clear(key);
				currentTrackedSounds.remove(key);
			}
		}
		// flags everything to be cleared out next unused memory clear
		localTrackedAssets = [];
		openfl.Assets.cache.clear("songs");
	}

	static public var currentModDirectory:String = '';
	static public var currentLevel:String;
	static public function setCurrentLevel(name:String)
	{
		currentLevel = name.toLowerCase();
	}

	public static function getPath(file:String, type:AssetType, ?library:Null<String> = null)
	{
		if (library != null)
			return getLibraryPath(file, library);

		return getPreloadPath(file);
	}

	static public function getLibraryPath(file:String, library = "preload")
	{
		return if (library == "preload" || library == "default") getPreloadPath(file); else getLibraryPathForce(file, library);
	}

	inline static function getLibraryPathForce(file:String, library:String)
	{
		return '$library:assets/$library/$file';
	}

	inline public static function getPreloadPath(file:String = '')
	{
		return 'assets/$file';
	}

	inline static public function file(file:String, type:AssetType = TEXT, ?library:String)
	{
		return getPath(file, type, library);
	}

	inline static public function txt(key:String, ?library:String)
	{
		return getPath('data/$key.txt', TEXT, library);
	}

	inline static public function xml(key:String, ?library:String)
	{
		return getPath('data/$key.xml', TEXT, library);
	}

	inline static public function json(key:String, ?library:String)
	{
		return getPath('data/$key.json', TEXT, library);
	}

	inline static public function shaderFragment(key:String, ?library:String)
	{
		return getPath('shaders/$key.frag', TEXT, library);
	}
	inline static public function shaderVertex(key:String, ?library:String)
	{
		return getPath('shaders/$key.vert', TEXT, library);
	}
	
	inline static public function lua(key:String, ?library:String)
	{
		#if MODS_ALLOWED
		var file:String = modFolders('$key.lua');
		if(FileSystem.exists(file)) {
			return file;
		}
		#end
		return getPath('$key.lua', TEXT, library);
	}

	static public function video(key:String)
	{
		#if MODS_ALLOWED
		var file:String = modsVideo(key);
		if(FileSystem.exists(file)) {
			return file;
		}
		#end
		return 'assets/videos/$key.$VIDEO_EXT';
	}

	inline static public function module(key:String, folder:String = 'scripts', ?library:String)
	{
		var extension = '.hx';
		var scriptExts:Array<String> = ['hx', 'hxs', 'hscript', 'hxc'];
		for (j in scriptExts)
		{
			if (fileExists('$folder/$key.$j', TEXT, library))
				extension = '.$j';
			else
				extension = '.hx';
		}
		#if MODS_ALLOWED
		var file:String = modFolders('$folder/$key' + extension);
		if(FileSystem.exists(file)) {
			return file;
		}
		else {
			return getPreloadPath('$folder/$key' + extension);
		}
		#else
		return getPreloadPath('$folder/$key' + extension);
		#end
		
	}

	static public function sound(key:String, ?library:String):Sound
	{
		var sound:Sound = returnSound('sounds', key, library);
		return sound;
	}

	inline static public function soundRandom(key:String, min:Int, max:Int, ?library:String)
	{
		return sound(key + FlxG.random.int(min, max), library);
	}

	inline static public function music(key:String, ?library:String):Sound
	{
		var file:Sound = returnSound('music', key, library);
		return file;
	}

	inline static public function voices(song:String):Any
	{
		var songKey:String = '${formatToSongPath(song)}/Voices';
		var voices = returnSound('songs', songKey);
		return voices;
	}

	inline static public function inst(song:String):Any
	{
		var songKey:String = '${formatToSongPath(song)}/Inst';
		var inst = returnSound('songs', songKey);
		return inst;
	}

	inline static public function songJson(jsonInput:String, ?folder:String)
	{
		var formattedFolder:String = Paths.formatToSongPath(folder);
		var formattedSong:String = Paths.formatToSongPath(jsonInput);
		#if MODS_ALLOWED
		var file:String = modsJson(formattedFolder + '/' + formattedSong);
		if(FileSystem.exists(file)) {
			return file;
		}
		#end
		return Paths.json(formattedFolder + '/' + formattedSong);
	}

	inline static public function image(key:String, ?library:String):FlxGraphic
	{
		// streamlined the assets process more
		var returnAsset:FlxGraphic = returnGraphic(key, library);
		return returnAsset;
	}

	static public function getTextFromFile(key:String, ?ignoreMods:Bool = false, ?library:String):String
	{
		#if sys
		#if MODS_ALLOWED
		if (!ignoreMods && FileSystem.exists(getModsPath(key, library)))
			return File.getContent(getModsPath(key, library));
		#end

		if (FileSystem.exists(getPreloadPath(key)))
			return File.getContent(getPreloadPath(key));

		if (currentLevel != null)
		{
			var levelPath:String = '';
			if(currentLevel != 'shared') {
				levelPath = getLibraryPathForce(key, currentLevel);
				if (FileSystem.exists(levelPath))
					return File.getContent(levelPath);
			}

			levelPath = getLibraryPathForce(key, 'shared');
			if (FileSystem.exists(levelPath))
				return File.getContent(levelPath);
		}
		#end
		return Assets.getText(getPath(key, TEXT, library));
	}

	inline static public function font(key:String)
	{
		#if MODS_ALLOWED
		var file:String = modsFont(key);
		if(FileSystem.exists(file)) {
			return file;
		}
		#end
		return 'assets/fonts/$key';
	}

	inline static public function fileExists(key:String, type:AssetType, ?ignoreMods:Bool = false, ?library:String)
	{
		#if MODS_ALLOWED
		if(FileSystem.exists(getModsPath(key, library))) {
			return true;
		}
		#end

		if(OpenFlAssets.exists(getPath(key, type, library))) {
			return true;
		}
		return false;
	}

	inline static public function getSparrowAtlas(key:String, ?library:String):FlxAtlasFrames
	{
		/*
		this one is good but uhh I'm gonna remove it since because there is some issue during loading this coding
		var i = 1;
		while (fileExists('images/$key/$i.xml',TEXT, false, library) && fileExists('images/$key/$i.png',IMAGE, false, library))
		{
			#if MODS_ALLOWED
			var imageLoaded:FlxGraphic = returnGraphic('$key/$i', library);
			var xmlExists:Bool = false;
			if(FileSystem.exists(modsXml('$key/$i', library))) {
				xmlExists = true;
			}
	
			FlxAtlasFrames.fromSparrow((imageLoaded != null ? imageLoaded : image('$key/$i', library)), (xmlExists ? File.getContent(modsXml('$key/$i', library)) : file('images/$key/$i.xml', library)));
			#else
			FlxAtlasFrames.fromSparrow(image('$key/$i', library), file('images/$key/$i.xml', library));
			#end
		}
		*/

		#if MODS_ALLOWED
		var imageLoaded:FlxGraphic = returnGraphic(key, library);
		var xmlExists:Bool = false;
		if(FileSystem.exists(modsXml(key, library))) {
			xmlExists = true;
		}

		return FlxAtlasFrames.fromSparrow((imageLoaded != null ? imageLoaded : image(key, library)), (xmlExists ? File.getContent(modsXml(key, library)) : file('images/$key.xml', library)));
		#else
		return FlxAtlasFrames.fromSparrow(image(key, library), file('images/$key.xml', library));
		#end
	}


	inline static public function getPackerAtlas(key:String, ?library:String)
	{
		/*
		var i = 1;
		while (fileExists('images/$key/$i.txt',TEXT, false, library) && fileExists('images/$key/$i.png',IMAGE, false, library))
		{
			#if MODS_ALLOWED
			var imageLoaded:FlxGraphic = returnGraphic('$key/$i', library);
			var xmlExists:Bool = false;
			if(FileSystem.exists(modsTxt('$key/$i', library))) {
				xmlExists = true;
			}
	
			FlxAtlasFrames.fromSpriteSheetPacker((imageLoaded != null ? imageLoaded : image('$key/$i', library)), (xmlExists ? File.getContent(modsTxt('$key/$i', library)) : file('images/$key/$i.xml', library)));
			#else
			FlxAtlasFrames.fromSpriteSheetPacker(image('$key/$i', library), file('images/$key/$i.txt', library));
			#end
		}
		*/

		#if MODS_ALLOWED
		var imageLoaded:FlxGraphic = returnGraphic(key, library);
		var txtExists:Bool = false;
		if(FileSystem.exists(modsTxt(key))) {
			txtExists = true;
		}

		return FlxAtlasFrames.fromSpriteSheetPacker((imageLoaded != null ? imageLoaded : image(key, library)), (txtExists ? File.getContent(modsTxt(key, library)) : file('images/$key.txt', library)));
		#else
		return FlxAtlasFrames.fromSpriteSheetPacker(image(key, library), file('images/$key.txt', library));
		#end
	}

	inline static public function getTexturePackerAtlas(key:String, ?library:String):FlxAtlasFrames
	{
		/*
		var i = 1;
		while (fileExists('images/$key/$i.json',TEXT, false, library) && fileExists('images/$key/$i.png',IMAGE, false, library))
		{
			#if MODS_ALLOWED
			var imageLoaded:FlxGraphic = returnGraphic('$key/$i', library);
			var xmlExists:Bool = false;
			if(FileSystem.exists(getModsPath('images/$key/$i.json', library))) {
				xmlExists = true;
			}
	
			FlxAtlasFrames.fromTexturePackerJson((imageLoaded != null ? imageLoaded : image('$key/$i', library)), (xmlExists ? File.getContent(getModsPath('images/$key/$i.json', library)) : file('images/$key/$i.xml', library)));
			#else
			FlxAtlasFrames.fromTexturePackerJson(image('$key/$i', library), file('images/$key/$i.json', library));
			#end
		}
		*/

		#if MODS_ALLOWED
		var imageLoaded:FlxGraphic = returnGraphic(key, library);
		var xmlExists:Bool = false;
		if(FileSystem.exists(getModsPath('images/$key.json', library))) {
			xmlExists = true;
		}

		return FlxAtlasFrames.fromTexturePackerJson((imageLoaded != null ? imageLoaded : image(key, library)), (xmlExists ? File.getContent(getModsPath('images/$key.json', library)) : file('images/$key.json', library)));
		#else
		return FlxAtlasFrames.fromTexturePackerJson(image(key, library), file('images/$key.json', library));
		#end
	}

	inline static public function formatToSongPath(path:String) {
		var invalidChars = ~/[~&\\;:<>#]/;
		var hideChars = ~/[.,'"%?!]/;

		var path = invalidChars.split(path.replace(' ', '-')).join("-");
		return hideChars.split(path).join("").toLowerCase();
	}

	// completely rewritten asset loading? fuck!
	public static var currentTrackedAssets:Map<String, FlxGraphic> = [];
	public static function returnGraphic(key:String, ?library:String) {
		#if MODS_ALLOWED
		var modKey:String = modsImages(key, library);
		if(FileSystem.exists(modKey)) {
			if(!currentTrackedAssets.exists(modKey)) {
				var newBitmap:BitmapData = BitmapData.fromFile(modKey);
				var newGraphic:FlxGraphic = FlxGraphic.fromBitmapData(newBitmap, false, modKey);
				newGraphic.persist = true;
				currentTrackedAssets.set(modKey, newGraphic);
			}
			localTrackedAssets.push(modKey);
			return currentTrackedAssets.get(modKey);
		}
		#end

		var path = getPath('images/$key.png', IMAGE, library);
		//trace(path);
		if (OpenFlAssets.exists(path, IMAGE)) {
			if(!currentTrackedAssets.exists(path)) {
				var newGraphic:FlxGraphic = FlxG.bitmap.add(path, false, path);
				newGraphic.persist = true;
				currentTrackedAssets.set(path, newGraphic);
			}
			localTrackedAssets.push(path);
			return currentTrackedAssets.get(path);
		}
		trace('oh no $key is returning null NOOOO');
		return null;
	}


	public static var currentTrackedSounds:Map<String, Sound> = [];
	public static function returnSound(path:String, key:String, ?library:String) {
		#if MODS_ALLOWED
		var file:String = modsSounds(path, key, library);
		if(FileSystem.exists(file)) {
			if(!currentTrackedSounds.exists(file)) {
				currentTrackedSounds.set(file, Sound.fromFile(file));
			}
			localTrackedAssets.push(key);
			return currentTrackedSounds.get(file);
		}
		#end
		// I hate this so god damn much
		var gottenPath:String = getPath('$path/$key.$SOUND_EXT', SOUND, library);
		gottenPath = gottenPath.substring(gottenPath.indexOf(':') + 1, gottenPath.length);
		// trace(gottenPath);
		if(!currentTrackedSounds.exists(gottenPath))
		#if MODS_ALLOWED
			currentTrackedSounds.set(gottenPath, Sound.fromFile('./' + gottenPath));
		#else
		{
			var folder:String = '';
			if(path == 'songs') folder = 'songs:';

			currentTrackedSounds.set(gottenPath, OpenFlAssets.getSound(folder + getPath('$path/$key.$SOUND_EXT', SOUND, library)));
		}
		#end
		localTrackedAssets.push(gottenPath);
		return currentTrackedSounds.get(gottenPath);
	}

	#if MODS_ALLOWED
	inline static public function mods(key:String = '') {
		return 'mods/' + key;
	}

	inline static public function modsFont(key:String) {
		return getModsPath('fonts/' + key);
	}

	inline static public function modsJson(key:String, ?library:String) {
		return getModsPath('data/' + key + '.json', library);
	}

	inline static public function modsVideo(key:String) {
		return getModsPath('videos/' + key + '.' + VIDEO_EXT);
	}

	inline static public function modsSounds(path:String, key:String, ?library:String) {
		return getModsPath(path + '/' + key + '.' + SOUND_EXT, library);
	}

	inline static public function modsImages(key:String, ?library:String) {
		return getModsPath('images/' + key + '.png', library);
	}

	inline static public function modsXml(key:String, ?library:String) {
		return getModsPath('images/' + key + '.xml', library);
	}

	inline static public function modsTxt(key:String, ?library:String) {
		return getModsPath('images/' + key + '.txt', library);
	}

	static public function modFolders(key:String) {
		if(currentModDirectory != null && currentModDirectory.length > 0) {
			var fileToCheck:String = mods(currentModDirectory + '/' + key);
			if(FileSystem.exists(fileToCheck)) {
				return fileToCheck;
			}
		}

		for(mod in getGlobalMods()){
			var fileToCheck:String = mods(mod + '/' + key);
			if(FileSystem.exists(fileToCheck))
				return fileToCheck;

		}
		return 'mods/' + key;
	}

	inline public static function getModsPath(file:String, ?library:Null<String>)
	{
		if (library != null)
			return getLibraryModsPath(file, library);
		return modFolders(file);
	}

	static public function getLibraryModsPath(file:String, library = "preload")
	{
		return if (library == "preload" || library == "default") modFolders(file); else getLibraryModsPathForce(file, library);
	}

	static public function getLibraryModsPathForce(key:String, library:String)
	{
		if (currentModDirectory != null && currentModDirectory.length > 0)
		{
			var fileToCheck:String = mods(currentModDirectory + '/$library/' + key);
			if (FileSystem.exists(fileToCheck))
			{
				return fileToCheck;
			}
		}

		for (mod in getGlobalMods())
		{
			var fileToCheck:String = mods(mod + '/$library/' + key);
			if (FileSystem.exists(fileToCheck))
				return fileToCheck;
		}
		return 'mods/$library/' + key;
	}

	public static var globalMods:Array<String> = [];

	static public function getGlobalMods()
		return globalMods;

	static public function pushGlobalMods() // prob a better way to do this but idc
	{
		globalMods = [];
		var path:String = 'modsList.txt';
		if(FileSystem.exists(path))
		{
			var list:Array<String> = CoolUtil.coolTextFile(path);
			for (i in list)
			{
				var dat = i.split("|");
				if (dat[1] == "1")
				{
					var folder = dat[0];
					var path = Paths.mods(folder + '/pack.json');
					if(FileSystem.exists(path)) {
						try{
							var rawJson:String = File.getContent(path);
							if(rawJson != null && rawJson.length > 0) {
								var stuff:Dynamic = Json.parse(rawJson);
								var global:Bool = Reflect.getProperty(stuff, "runsGlobally");
								if(global)globalMods.push(dat[0]);
							}
						} catch(e:Dynamic){
							trace(e);
						}
					}
				}
			}
		}
		return globalMods;
	}

	static public function getModDirectories():Array<String>
	{
		var list:Array<String> = [];
		var modsFolder:String = mods();
		if (FileSystem.exists(modsFolder))
		{
			for (folder in FileSystem.readDirectory(modsFolder))
			{
				var path = haxe.io.Path.join([modsFolder, folder]);
				if (sys.FileSystem.isDirectory(path) && !ignoreModFolders.contains(folder) && !list.contains(folder))
				{
					list.push(folder);
				}
			}
		}
		return list;
	}
	#end
}
