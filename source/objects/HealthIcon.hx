package objects;

import flixel.graphics.FlxGraphic;
import flixel.FlxSprite;
import openfl.utils.Assets as OpenFlAssets;
import util.script.FunkinHaxe;
import util.script.Globals;
#if sys
import sys.FileSystem;
#end
using StringTools;

class HealthIcon extends FlxSprite
{
	public var sprTracker:FlxSprite;
	private var isOldIcon:Bool = false;

	private var isWinner:Bool = false;
	private var isEmotionStuff:Bool = false;
	private var isNormal:Bool = true;

	public var initialWidth:Float = 0;
	public var initialHeight:Float = 0;
	public var haxeArray:Array<FunkinHaxe> = [];

	public var offsetX = 0;
	public var offsetY = 0;

	private var char:String = '';
	var isPlayer:Bool = false;


	public function new(char:String = 'bf', isPlayer:Bool = false)
	{
		super();
		isOldIcon = (char == char +'-old');
		this.isPlayer = isPlayer;
		changeIcon(char);
		scrollFactor.set();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (sprTracker != null)
			setPosition(sprTracker.x + sprTracker.width + 12, sprTracker.y - 30);
	}

	public function swapOldIcon(char:String) {
		if(isOldIcon = !isOldIcon) 
			changeIcon(char + '-old');
		else 
			changeIcon(char);
	}

	private var iconOffsets:Array<Float> = [0, 0];
	public function changeIcon(char:String, ?newPlayer:Bool = null) {
		if (this.char != char || (newPlayer != null && newPlayer != isPlayer))
		{
			if (newPlayer != null)
				isPlayer = newPlayer;
			
			offsetX = 0;
			offsetY = 0;
			for (lua in haxeArray) {
				lua.call('onDestroy', []);
				lua.call('destroy', []);
				#if hscript
				if(lua != null) lua = null;
				#end
			}
			haxeArray = [];

			var name:String = 'icons/' + char;
			if(!Paths.fileExists('images/' + name + '.png', IMAGE)) name = 'icons/icon-' + char; //Older versions of psych engine's support
			if(!Paths.fileExists('images/' + name + '.png', IMAGE)) name = 'icons/icon-face'; //Prevents crash from missing icon
			loadScript(name);
			call('changeIcon', [char, newPlayer]);
			set('icon', this);
			set('isPlayer', isPlayer);
			set('offsetX', offsetX);
			set('offsetY', offsetY);
			set('iconOffsets', iconOffsets);
			var iconGraphic:FlxGraphic = Paths.image(name);
			if(iconGraphic.width == 450)
			{
				loadGraphic(iconGraphic, true, Std.int(iconGraphic.width / 3), iconGraphic.height);
				iconOffsets[0] = (width - 150) / 2;
				iconOffsets[1] = (width - 150) / 2;
				iconOffsets[2] = (width - 150) / 2;
				updateHitbox();
		
				animation.add('icon', [0, 1, 2], 0, false, isPlayer);
				animation.play('icon');
				isWinner = true;
				isEmotionStuff = false;
				isNormal = false;
			}
			else if (iconGraphic.width == 750)
			{
				loadGraphic(iconGraphic, true, Std.int(iconGraphic.width / 5), iconGraphic.height);
				iconOffsets[0] = (width - 150) / 2;
				iconOffsets[1] = (width - 150) / 2;
				iconOffsets[2] = (width - 150) / 2;
				iconOffsets[3] = (width - 150) / 2;
				iconOffsets[4] = (width - 150) / 2;
				updateHitbox();
				animation.add('icon', [0, 1, 2, 3, 4], 0, false, isPlayer);
				animation.play('icon');
				isWinner = false;
				isEmotionStuff = true;
				isNormal = false;
			}
			else if (iconGraphic.width == 300)
			{
				loadGraphic(iconGraphic, true, Std.int(iconGraphic.width / 2), iconGraphic.height);
				iconOffsets[0] = (width - 150) / 2;
				iconOffsets[1] = (width - 150) / 2;
				updateHitbox();
		
				animation.add('icon', [0, 1], 0, false, isPlayer);
				animation.play('icon');
				isWinner = false;
				isEmotionStuff = false;
				isNormal = true;
			}
			animation.play('icon');
			this.char = char;

			initialWidth = width;
			initialHeight = height;

			antialiasing = ClientPrefs.globalAntialiasing;
			if(char.endsWith('-pixel')) {
				antialiasing = false;
			}
		}
	}

	function loadScript(name:String) {
		var doPush:Bool = false;
		var hxFile:String = 'images/' + name + '.hx';
		#if MODS_ALLOWED
		if(FileSystem.exists(Paths.modFolders(hxFile))) {
			hxFile = Paths.modFolders(hxFile);
			doPush = true;
		} else {
			hxFile = Paths.getPreloadPath(hxFile);
			if(FileSystem.exists(hxFile)) {
				doPush = true;
			}
		}

		if(doPush)
		{
			var haxeScript:FunkinHaxe = new FunkinHaxe(hxFile);
			haxeArray.push(haxeScript);
		}
		#end
	}

	override function updateHitbox()
	{
		super.updateHitbox();
		offset.x = iconOffsets[0];
		offset.y = iconOffsets[1];
		call('updateHitbox', []);
		set('offset', offset);
	}

	public function updateAnims(health:Float)
	{
		if(isWinner)
		{
			if (health < 20)
				animation.curAnim.curFrame = 1;
			else if (health > 80)
				animation.curAnim.curFrame = 2;
			else
				animation.curAnim.curFrame = 0;
		}
		else if(isEmotionStuff)
		{
			if (health < 20)
				animation.curAnim.curFrame = 1;
			else if (health > 20 && health < 30)
				animation.curAnim.curFrame = 2;
			else if (health > 70 && health < 80)
				animation.curAnim.curFrame = 3;
			else if (health > 80)
				animation.curAnim.curFrame = 4;
			else
				animation.curAnim.curFrame = 0;
		}
		else if(isNormal)
		{
			if (health < 20)
				animation.curAnim.curFrame = 1;
			else
				animation.curAnim.curFrame = 0;
		}

		call('updateAnims', [health]);
	}

	public function getCharacter():String {
		return char;
	}

	public function call(event:String, args:Array<Dynamic>)
	{
		if (haxeArray != null)
		{
			for (i in haxeArray)
				i.call(event, args);
		}
	}

	public function set(variable:String, arg:Dynamic)
	{
		for (script in haxeArray)
		{
			script.set(variable, arg);
		}
	}
}
