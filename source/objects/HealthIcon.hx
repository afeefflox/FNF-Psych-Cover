package objects;
#if (HSCRIPT_ALLOWED && SScript >= "3.0.0")
import tea.SScript;
#end
import flixel.graphics.FlxGraphic;
import flixel.FlxSprite;
import openfl.utils.Assets as OpenFlAssets;
import util.script.FunkinHaxe;
import util.script.FunkinLua;
import util.script.Globals;
#if sys
import sys.FileSystem;
import sys.io.File;
#end
using StringTools;

class HealthIcon extends FlxSprite
{
	public var sprTracker:FlxSprite;
	private var isOldIcon:Bool = false;

	private var isWinner:Bool = false;
	private var isEmotionStuff:Bool = false;
	private var isNormal:Bool = true;

	public var haxeArray:Array<FunkinHaxe> = [];

	private var char:String = '';
	var isPlayer:Bool = false;


	public function new(char:String = 'bf', isPlayer:Bool = false, ?allowGPU:Bool = true)
	{
		super();
		isOldIcon = (char == char +'-old');
		this.isPlayer = isPlayer;
		changeIcon(char, null, allowGPU);
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
	public function changeIcon(char:String, ?newPlayer:Bool = null, ?allowGPU:Bool = false) {
		if (this.char != char || (newPlayer != null && newPlayer != isPlayer))
		{
			if (newPlayer != null)
				isPlayer = newPlayer;

			for (lua in haxeArray) {
				lua.call('destroy', []);
				if(lua != null) lua = null;
			}
			haxeArray = [];

			var characterBETADCIUPath:String = 'iconsBETADCIU/icon-' + char;
			var characterPath:String = 'icons/icon-' + char;

			if(Paths.fileExists('images/' + characterBETADCIUPath + '.png', IMAGE))
				loadIcon(characterBETADCIUPath, allowGPU);
			else if(Paths.fileExists('images/' + characterPath + '.png', IMAGE))
				loadIcon(characterPath, allowGPU);
			else
				loadIcon('icons/icon-face', allowGPU);

			call('changeIcon', [char, newPlayer]);

			set('icon', this);
			set('isPlayer', isPlayer);
			set('iconOffsets', iconOffsets);

			this.char = char;
					
		    antialiasing = ClientPrefs.globalAntialiasing;
			if(char.endsWith('-pixel')) {
				antialiasing = false;
			}
		}
	}

	function loadIcon(path:String, allowGPU:Bool = false)
	{
		var name:String = path;
		loadScript(path);
		var iconGraphic:FlxGraphic = Paths.image(path, allowGPU);
		switch(iconGraphic.width)
		{
			case 750:
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
			case 450:
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
			default:
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
	}

	function loadScript(name:String) {
		var scriptExts:Array<String> = ['hx', 'hxs', 'hscript', 'hxc'];
		#if HSCRIPT_ALLOWED
		for (ext in scriptExts)
		{
			#if MODS_ALLOWED
			var doPush:Bool = false;
			var scriptFile:String = name + '.$ext';
			var replacePath:String = Paths.modFolders(scriptFile);
			if(FileSystem.exists(replacePath))
			{
				scriptFile = replacePath;
				doPush = true;
			}
			else
			{
				scriptFile = Paths.getPreloadPath(scriptFile);
				if(FileSystem.exists(scriptFile))
					doPush = true;
			}
			#else
			scriptFile = Paths.getPreloadPath(scriptFile);
			if(Assets.exists(scriptFile)) doPush = true;
			#end
			
			if(doPush)
			{
				if(SScript.global.exists(scriptFile))
					doPush = false;

				if(doPush)
				{
					loadHaxe(scriptFile);
				}
			}
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

	public function call(funcToCall:String, args:Array<Dynamic> = null, ?ignoreStops:Bool = false, exclusions:Array<String> = null, excludeValues:Array<Dynamic> = null):Dynamic {
		var returnVal:Dynamic = FunkinLua.Function_Continue;

		#if HSCRIPT_ALLOWED
		if(exclusions == null) exclusions = new Array();
		if(excludeValues == null) excludeValues = new Array();
		excludeValues.push(FunkinLua.Function_Continue);

		var len:Int = haxeArray.length;
		if (len < 1)
			return returnVal;
		for(i in 0...len)
		{
			var script:FunkinHaxe = haxeArray[i];
			if(script == null || !script.exists(funcToCall) || exclusions.contains(script.origin))
				continue;

			var myValue:Dynamic = null;
			try
			{
				var callValue = script.call(funcToCall, args);
				if(!callValue.succeeded)
				{
					var e = callValue.exceptions[0];
					if(e != null)
						FunkinLua.luaTrace('ERROR (${script.origin}: ${callValue.calledFunction}) - ' + e.message.substr(0, e.message.indexOf('\n')), true, false, FlxColor.RED);
				}
				else
				{
					myValue = callValue.returnValue;
					if((myValue == FunkinLua.Function_StopHScript || myValue == FunkinLua.Function_StopAll) && !excludeValues.contains(myValue) && !ignoreStops)
					{
						returnVal = myValue;
						break;
					}
					
					if(myValue != null && !excludeValues.contains(myValue))
						returnVal = myValue;
				}
			}
		}
		#end

		return returnVal;
	}

	public function set(variable:String, arg:Dynamic, exclusions:Array<String> = null) {
		#if HSCRIPT_ALLOWED
		if(exclusions == null) exclusions = [];
		for (script in haxeArray) {
			if(exclusions.contains(script.origin))
				continue;

			script.set(variable, arg);
		}
		#end
	}

	function loadHaxe(file:String)
	{
		try
		{
			var newScript:FunkinHaxe = new FunkinHaxe(null, file, true);
			@:privateAccess
			if(newScript.parsingExceptions != null && newScript.parsingExceptions.length > 0)
			{
				@:privateAccess
				for (e in newScript.parsingExceptions)
					if(e != null)
					{
						if(PlayState.instance != null)
						{
							PlayState.instance.addTextToDebug('HealthIcon ERROR ON LOADING ($file): ${e.message.substr(0, e.message.indexOf('\n'))}', FlxColor.RED);
						}
					}
						
				newScript.destroy();
				return;
			}

			haxeArray.push(newScript);
			trace('initialized sscript interp successfully: $file');
		}
		catch(e:Dynamic)
		{
			var newScript:FunkinHaxe = cast (SScript.global.get(file), FunkinHaxe);
			if(PlayState.instance != null)
			{
				PlayState.instance.addTextToDebug('HealthIcon ERROR ($file) - ' + e.toString(), FlxColor.RED);
			}
			trace('HealthIcon ERROR ($file) - ' + e.toString());
			if(newScript != null)
			{
				newScript.active = false;
				haxeArray.remove(newScript);
			}
		}
	}
}
