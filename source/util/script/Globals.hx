package util.script;

import flixel.group.FlxSpriteGroup;
import objects.HealthIcon;
import objects.Character;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.group.FlxGroup;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import animateatlas.AtlasFrameMaker;
import flixel.FlxCamera;
import flixel.text.FlxText.FlxTextAlign;
import flixel.text.FlxText.FlxTextFormat;
import Type.ValueType;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween.FlxTweenType;
import flixel.FlxSprite;
import flixel.FlxBasic;
import flixel.FlxObject;
import flixel.util.FlxTimer;
import openfl.display.BlendMode;
import meta.state.*;
import meta.substate.*;
import flixel.FlxG;
import MusicBeat;
import flixel.util.FlxSave;
import flixel.math.FlxMath;
import openfl.utils.Assets;
import objects.Stage;
#if sys
import sys.FileSystem;
import sys.io.File;
#end
#if (!flash && sys)
import flixel.addons.display.FlxRuntimeShader;
#end

#if LUA_ALLOWED
import llua.Lua;
import llua.LuaL;
import llua.State;
import llua.Convert;
#end

#if hscript
import hscript.Parser;
import hscript.Interp;
import hscript.Expr;
#end
import haxe.Exception;
import haxe.Constraints;

using StringTools;

typedef LuaTweenOptions = {
	type:FlxTweenType,
	startDelay:Float,
	onUpdate:Null<String>,
	onStart:Null<String>,
	onComplete:Null<String>,
	loopDelay:Float,
	ease:EaseFunction
}


class CallbackHandler
{
	#if LUA_ALLOWED
	public static inline function call(l:State, fname:String):Int
	{
		try
		{
			//trace('calling $fname');
			var cbf:Dynamic = Lua_helper.callbacks.get(fname);

			//Local functions have the lowest priority
			//This is to prevent a "for" loop being called in every single operation,
			//so that it only loops on reserved/special functions
			if(cbf == null) 
			{
				//trace('looping thru scripts');
				for (script in PlayState.instance.luaArray)
					if(script != null && script.lua == l)
					{
						//trace('found script');
						cbf = script.callbacks.get(fname);
						break;
					}
			}
			
			if(cbf == null) return 0;

			var nparams:Int = Lua.gettop(l);
			var args:Array<Dynamic> = [];

			for (i in 0...nparams) {
				args[i] = Convert.fromLua(l, i + 1);
			}

			var ret:Dynamic = null;
			/* return the number of results */

			ret = Reflect.callMethod(null,cbf,args);

			if(ret != null){
				Convert.toLua(l, ret);
				return 1;
			}
		}
		catch(e:Dynamic)
		{
			if(Lua_helper.sendErrorsToLua) {LuaL.error(l, 'CALLBACK ERROR! ${if(e.message != null) e.message else e}');return 0;}
			trace(e);
			throw(e);
		}
		return 0;
	}
	#end
}

class Globals {

	public static inline function getInstance()
	{
		return PlayState.instance.isDead ? GameOverSubstate.instance : PlayState.instance;
	}

	public static inline function getTargetInstance()
	{
		return PlayState.instance.isDead ? GameOverSubstate.instance : PlayState.instance;
	}

	public static function addAnimByIndices(obj:String, name:String, prefix:String, indices:String, framerate:Int = 24, loop:Bool = false)
	{
		var strIndices:Array<String> = indices.trim().split(',');
		var die:Array<Int> = [];
		for (i in 0...strIndices.length) {
			die.push(Std.parseInt(strIndices[i]));
		}

		if(PlayState.instance.getLuaObject(obj, false)!=null) {
			var pussy:FlxSprite = PlayState.instance.getLuaObject(obj, false);
			pussy.animation.addByIndices(name, prefix, die, '', framerate, loop);
			if(pussy.animation.curAnim == null) {
				pussy.animation.play(name, true);
			}
			return true;
		}

		var pussy:FlxSprite = Reflect.getProperty(getInstance(), obj);
		if(pussy != null) {
			pussy.animation.addByIndices(name, prefix, die, '', framerate, loop);
			if(pussy.animation.curAnim == null) {
				pussy.animation.play(name, true);
			}
			return true;
		}
		return false;
	}

	public static function addCharacterLayer(obj:FlxBasic, ?front:Bool = false, ?layersName:String = 'boyfriend')
	{
		if(front)
		{
			var layersCharacter:String = 'boyfriend';
			switch(layersName.toLowerCase().trim()) 
			{
				case 'gf'|'girlfriend':
					layersCharacter = 'gf';
				case 'dad'|'opponent':
					layersCharacter = 'dad';
			}
			Stage.instance.layers.get(layersCharacter).add(obj);
		}
		else
		{
			Stage.instance.add(obj);
		}
	}

	public static function removeCharacterLayer(obj:FlxBasic, ?front:Bool = false, ?layersName:String = 'boyfriend')
	{
		if(front)
		{
			var layersCharacter:String = 'boyfriend';
			switch(layersName.toLowerCase().trim()) 
			{
				case 'gf'|'girlfriend':
					layersCharacter = 'gf';
				case 'dad'|'opponent':
					layersCharacter = 'dad';
			}
			Stage.instance.layers.get(layersCharacter).remove(obj);
		}
		else
		{
			Stage.instance.remove(obj);
		}
	}

	public static function getProperty(variable:String, ?allowMaps:Bool = false) {
		var split:Array<String> = variable.split('.');
		if(split.length > 1)
			return getVarInArray(getPropertyLoop(split, true, true, allowMaps), split[split.length-1], allowMaps);
		return getVarInArray(getTargetInstance(), variable, allowMaps);
	}

	public static function setProperty(variable:String, value:Dynamic, ?allowMaps:Bool = false) {
		var split:Array<String> = variable.split('.');
		if(split.length > 1) {
			setVarInArray(getPropertyLoop(split, true, true, allowMaps), split[split.length-1], value, allowMaps);
		}
		setVarInArray(getTargetInstance(), variable, value, allowMaps);
	}

	public static inline function getLowestCharacterGroup():FlxSpriteGroup
	{
		var group:FlxSpriteGroup = PlayState.instance.gfGroup;
		var pos:Int = PlayState.instance.members.indexOf(group);

		var newPos:Int = PlayState.instance.members.indexOf(PlayState.instance.boyfriendGroup);
		if(newPos < pos)
		{
			group = PlayState.instance.boyfriendGroup;
			pos = newPos;
		}
		
		newPos = PlayState.instance.members.indexOf(PlayState.instance.dadGroup);
		if(newPos < pos)
		{
			group = PlayState.instance.dadGroup;
			pos = newPos;
		}
		return group;
	}

	//Better optimized than using some getProperty shit or idk
	public static function cameraFromString(cam:String):FlxCamera {
		switch(cam.toLowerCase().trim()) {
			case 'camhud' | 'hud': return PlayState.instance.camHUD;
			case 'camother' | 'other': return PlayState.instance.camOther;
		}
		return PlayState.instance.camGame;
	}

	public static function blendModeFromString(blend:String):BlendMode {
		switch(blend.toLowerCase().trim()) {
			case 'add': return ADD;
			case 'alpha': return ALPHA;
			case 'darken': return DARKEN;
			case 'difference': return DIFFERENCE;
			case 'erase': return ERASE;
			case 'hardlight': return HARDLIGHT;
			case 'invert': return INVERT;
			case 'layer': return LAYER;
			case 'lighten': return LIGHTEN;
			case 'multiply': return MULTIPLY;
			case 'overlay': return OVERLAY;
			case 'screen': return SCREEN;
			case 'shader': return SHADER;
			case 'subtract': return SUBTRACT;
		}
		return NORMAL;
	}

	
	public static function getFlxColorByString(?color:String = ''):FlxColor {
		switch(color.toLowerCase().trim()) {
			case 'transparent': return FlxColor.TRANSPARENT;
			case 'white': return FlxColor.WHITE;
			case 'gray': return FlxColor.GRAY;
			case 'black': return FlxColor.BLACK;
			case 'green': return FlxColor.GREEN;
			//Lime is Better than green lol
			case 'lime': return FlxColor.LIME;
			case 'yellow': return FlxColor.YELLOW;
			case 'orange': return FlxColor.ORANGE;
			case 'red': return FlxColor.RED;
			case 'purple': return FlxColor.PURPLE;
			case 'blue': return FlxColor.BLUE;
			case 'brown': return FlxColor.BROWN;
			case 'pink': return FlxColor.PINK;
			case 'magenta': return FlxColor.MAGENTA;
			case 'cyan': return FlxColor.CYAN;
		}
		return FlxColor.TRANSPARENT;
	}

	public static function getFlxTextAlignByString(?alignment:String = ''):FlxTextAlign {
		switch(alignment.toLowerCase().trim()) {
			case 'left': return FlxTextAlign.LEFT;
			case 'center': return FlxTextAlign.CENTER;
			case 'right': return FlxTextAlign.RIGHT;
			case 'justify': return FlxTextAlign.JUSTIFY;
		}
		return FlxTextAlign.LEFT;
	}

	public static function getFlxTextBorderStyleByString(?alignment:String = ''):FlxTextBorderStyle {
		switch(alignment.toLowerCase().trim()) {
			//umm none it just default sooooo
			default: return FlxTextBorderStyle.NONE;
			case 'shadow': return FlxTextBorderStyle.SHADOW;
			case 'outline': return FlxTextBorderStyle.OUTLINE;
			case 'outline_fast': return FlxTextBorderStyle.OUTLINE_FAST;
			case 'outlineFast': return FlxTextBorderStyle.OUTLINE_FAST;
		}
		return FlxTextBorderStyle.NONE;
	}


	public static function getLuaTween(options:Dynamic) {
		return {
			type: getTweenTypeByString(options.type),
			startDelay: options.startDelay,
			onUpdate: options.onUpdate,
			onStart: options.onStart,
			onComplete: options.onComplete,
			loopDelay: options.loopDelay,
			ease: getTweenEaseByString(options.ease)
		};
	}

	public static function getTweenTypeByString(?type:String = '') {
		switch(type.toLowerCase().trim())
		{
			case 'backward': return FlxTweenType.BACKWARD;
			case 'looping': return FlxTweenType.LOOPING;
			case 'persist': return FlxTweenType.PERSIST;
			case 'pingpong': return FlxTweenType.PINGPONG;
		}
		return FlxTweenType.ONESHOT;
	}

	public static function oldTweenFunction(tag:String, vars:String, tweenValue:Any, duration:Float, ease:String, funcName:String)
	{
		#if LUA_ALLOWED
		var target:Dynamic = tweenPrepare(tag, vars);
		if(target != null) {
			PlayState.instance.modchartTweens.set(tag, FlxTween.tween(target, tweenValue, duration, {ease: getTweenEaseByString(ease),
				onComplete: function(twn:FlxTween) {
					PlayState.instance.modchartTweens.remove(tag);
					PlayState.instance.callOnLuas('onTweenCompleted', [tag, vars]);
					if(Stage.instance != null)
						Stage.instance.callOnLuas('onTweenCompleted', [tag, vars]);
				}
			}));
		} else {
			FunkinLua.luaTrace('$funcName: Couldnt find object: $vars', false, false, FlxColor.RED);
		}
		#end
	}


	public static function getTweenEaseByString(?ease:String = '') {
		switch(ease.toLowerCase().trim()) {
			case 'backin': return FlxEase.backIn;
			case 'backinout': return FlxEase.backInOut;
			case 'backout': return FlxEase.backOut;
			case 'bouncein': return FlxEase.bounceIn;
			case 'bounceinout': return FlxEase.bounceInOut;
			case 'bounceout': return FlxEase.bounceOut;
			case 'circin': return FlxEase.circIn;
			case 'circinout': return FlxEase.circInOut;
			case 'circout': return FlxEase.circOut;
			case 'cubein': return FlxEase.cubeIn;
			case 'cubeinout': return FlxEase.cubeInOut;
			case 'cubeout': return FlxEase.cubeOut;
			case 'elasticin': return FlxEase.elasticIn;
			case 'elasticinout': return FlxEase.elasticInOut;
			case 'elasticout': return FlxEase.elasticOut;
			case 'expoin': return FlxEase.expoIn;
			case 'expoinout': return FlxEase.expoInOut;
			case 'expoout': return FlxEase.expoOut;
			case 'quadin': return FlxEase.quadIn;
			case 'quadinout': return FlxEase.quadInOut;
			case 'quadout': return FlxEase.quadOut;
			case 'quartin': return FlxEase.quartIn;
			case 'quartinout': return FlxEase.quartInOut;
			case 'quartout': return FlxEase.quartOut;
			case 'quintin': return FlxEase.quintIn;
			case 'quintinout': return FlxEase.quintInOut;
			case 'quintout': return FlxEase.quintOut;
			case 'sinein': return FlxEase.sineIn;
			case 'sineinout': return FlxEase.sineInOut;
			case 'sineout': return FlxEase.sineOut;
			case 'smoothstepin': return FlxEase.smoothStepIn;
			case 'smoothstepinout': return FlxEase.smoothStepInOut;
			case 'smoothstepout': return FlxEase.smoothStepInOut;
			case 'smootherstepin': return FlxEase.smootherStepIn;
			case 'smootherstepinout': return FlxEase.smootherStepInOut;
			case 'smootherstepout': return FlxEase.smootherStepOut;
		}
		return FlxEase.linear;
	}

	public static function setVarInArray(instance:Dynamic, variable:String, value:Dynamic, allowMaps:Bool = false):Any
	{
		var splitProps:Array<String> = variable.split('[');
		if(splitProps.length > 1)
		{
			var target:Dynamic = null;
			if(PlayState.instance.variables.exists(splitProps[0]))
			{
				var retVal:Dynamic = PlayState.instance.variables.get(splitProps[0]);
				if(retVal != null)
					target = retVal;
			}
			else target = Reflect.getProperty(instance, splitProps[0]);

			for (i in 1...splitProps.length)
			{
				var j:Dynamic = splitProps[i].substr(0, splitProps[i].length - 1);
				if(i >= splitProps.length-1) //Last array
					target[j] = value;
				else //Anything else
					target = target[j];
			}
			return target;
		}

		if(allowMaps && isMap(instance))
		{
			//trace(instance);
			instance.set(variable, value);
			return value;
		}

		if(PlayState.instance.variables.exists(variable))
		{
			PlayState.instance.variables.set(variable, value);
			return value;
		}
		Reflect.setProperty(instance, variable, value);
		return value;
	}

	public static function getVarInArray(instance:Dynamic, variable:String, allowMaps:Bool = false):Any
	{
		var splitProps:Array<String> = variable.split('[');
		if(splitProps.length > 1)
		{
			var target:Dynamic = null;
			if(PlayState.instance.variables.exists(splitProps[0]))
			{
				var retVal:Dynamic = PlayState.instance.variables.get(splitProps[0]);
				if(retVal != null)
					target = retVal;
			}
			else
				target = Reflect.getProperty(instance, splitProps[0]);

			for (i in 1...splitProps.length)
			{
				var j:Dynamic = splitProps[i].substr(0, splitProps[i].length - 1);
				target = target[j];
			}
			return target;
		}
		
		if(allowMaps && isMap(instance))
		{
			//trace(instance);
			return instance.get(variable);
		}

		if(PlayState.instance.variables.exists(variable))
		{
			var retVal:Dynamic = PlayState.instance.variables.get(variable);
			if(retVal != null)
				return retVal;
		}
		return Reflect.getProperty(instance, variable);
	}

    public static inline function getTextObject(name:String):FlxText
	{
		return PlayState.instance.modchartTexts.exists(name) ? PlayState.instance.modchartTexts.get(name) : Reflect.getProperty(PlayState.instance, name);
	}

	public static function setGroupStuff(leArray:Dynamic, variable:String, value:Dynamic, ?allowMaps:Bool = false) {
		var split:Array<String> = variable.split('.');
		if(split.length > 1) {
			var obj:Dynamic = Reflect.getProperty(leArray, split[0]);
			for (i in 1...split.length-1)
				obj = Reflect.getProperty(obj, split[i]);

			leArray = obj;
			variable = split[split.length-1];
		}
		if(allowMaps && isMap(leArray)) leArray.set(variable, value);
		else Reflect.setProperty(leArray, variable, value);
		return value;
	}
	public static function getGroupStuff(leArray:Dynamic, variable:String, ?allowMaps:Bool = false) {
		var split:Array<String> = variable.split('.');
		if(split.length > 1) {
			var obj:Dynamic = Reflect.getProperty(leArray, split[0]);
			for (i in 1...split.length-1)
				obj = Reflect.getProperty(obj, split[i]);

			leArray = obj;
			variable = split[split.length-1];
		}

		if(allowMaps && isMap(leArray)) return leArray.get(variable);
		return Reflect.getProperty(leArray, variable);
	}

    public static function loadFrames(spr:FlxSprite, image:String, spriteType:String, ?library:String)
	{
		switch(spriteType.toLowerCase().trim())
		{
			case "texture" | "textureatlas" | "tex":
				spr.frames = AtlasFrameMaker.construct(image, library);

			case "texture_noaa" | "textureatlas_noaa" | "tex_noaa":
				spr.frames = AtlasFrameMaker.construct(image, library, null, true);

			case "packer" | "packeratlas" | "pac":
				spr.frames = Paths.getPackerAtlas(image, library);

			default:
				spr.frames = Paths.getSparrowAtlas(image, library);
		}
	}

	public static function isMap(variable:Dynamic)
	{
		if(variable.exists != null && variable.keyValueIterator != null) return true;
		return false;
	}

	public static function callMethodFromObject(classObj:Dynamic, funcStr:String, args:Array<Dynamic> = null)
	{
		if(args == null) args = [];

		var split:Array<String> = funcStr.split('.');
		var funcToRun:Function = null;
		var obj:Dynamic = classObj;
		//trace('start: $obj');
		if(obj == null)
		{
			return null;
		}

		for (i in 0...split.length)
		{
			obj = getVarInArray(obj, split[i].trim());
			//trace(obj, split[i]);
		}

		funcToRun = cast obj;
		//trace('end: $obj');
		return funcToRun != null ? Reflect.callMethod(obj, funcToRun, args) : null;
	}


	//MODCHART
	public static function resetTextTag(tag:String) {
		if(!PlayState.instance.modchartTexts.exists(tag)) {
			return;
		}

		var target:FlxText = PlayState.instance.modchartTexts.get(tag);
		target.kill();
		PlayState.instance.remove(target, true);
		target.destroy();
		PlayState.instance.modchartTexts.remove(tag);
	}

    public static function resetSpriteTag(tag:String) {
		if(!PlayState.instance.modchartSprites.exists(tag)) {
			return;
		}

		var target:ModchartSprite = PlayState.instance.modchartSprites.get(tag);
		target.kill();
		PlayState.instance.remove(target, true);
		target.destroy();
		PlayState.instance.modchartSprites.remove(tag);
	}

	public static function cancelTween(tag:String) {
		if(PlayState.instance.modchartTweens.exists(tag)) {
			PlayState.instance.modchartTweens.get(tag).cancel();
			PlayState.instance.modchartTweens.get(tag).destroy();
			PlayState.instance.modchartTweens.remove(tag);
		}
	}

	public static function resetGroupTag(tag:String) {
		if(!PlayState.instance.modchartSprites.exists(tag)) {
			return;
		}

		var target:ModchartGroup = PlayState.instance.modchartGroups.get(tag);
		target.kill();
		PlayState.instance.remove(target, true);
		target.destroy();
		PlayState.instance.modchartGroups.remove(tag);
	}

	public static function resetGroupTypedTag(tag:String) {
		if(!PlayState.instance.modchartGroupTypes.exists(tag)) {
			return;
		}

		var target:ModchartGroupTyped = PlayState.instance.modchartGroupTypes.get(tag);
		target.kill();
		PlayState.instance.remove(target, true);
		target.destroy();
		PlayState.instance.modchartGroupTypes.remove(tag);
	}

	public static function resetCharacterTag(tag:String) {
		if(!PlayState.instance.modchartCharacters.exists(tag)) {
			return;
		}

		var target:ModchartCharacter = PlayState.instance.modchartCharacters.get(tag);
		target.kill();
		PlayState.instance.remove(target, true);
		target.destroy();
		PlayState.instance.modchartCharacters.remove(tag);
	}

	public static function resetHealthIconTag(tag:String) {
		if(!PlayState.instance.modchartHealthIcons.exists(tag)) {
			return;
		}

		var target:ModchartHealthIcon = PlayState.instance.modchartHealthIcons.get(tag);
		target.kill();
		PlayState.instance.remove(target, true);
		target.destroy();
		PlayState.instance.modchartHealthIcons.remove(tag);
	}

	public static function cancelTimer(tag:String) {
		if(PlayState.instance.modchartTimers.exists(tag)) {
			var theTimer:FlxTimer = PlayState.instance.modchartTimers.get(tag);
			theTimer.cancel();
			theTimer.destroy();
			PlayState.instance.modchartTimers.remove(tag);
		}
	}

	public static function tweenPrepare(tag:String, vars:String) {
		cancelTween(tag);
		var variables:Array<String> = vars.split('.');
		var sexyProp:Dynamic = getObjectDirectly(variables[0]);
		if(variables.length > 1) sexyProp = getVarInArray(getPropertyLoop(variables), variables[variables.length-1]);
		return sexyProp;
	}

	
	public static function getObjectDirectly(objectName:String, ?checkForTextsToo:Bool = true, ?allowMaps:Bool = false):Dynamic
	{
		switch(objectName)
		{
			case 'this' | 'instance' | 'game':
				return PlayState.instance;
			
			default:
				var obj:Dynamic = PlayState.instance.getLuaObject(objectName, checkForTextsToo);
				if(obj == null) obj = getVarInArray(getTargetInstance(), objectName, allowMaps);
				return obj;
		}
	}

	
	public static function getPropertyLoop(split:Array<String>, ?checkForTextsToo:Bool = true, ?getProperty:Bool=true, ?allowMaps:Bool = false):Dynamic
	{
		var obj:Dynamic = getObjectDirectly(split[0], checkForTextsToo);
		var end = split.length;
		if(getProperty) end = split.length-1;

		for (i in 1...end) obj = getVarInArray(obj, split[i], allowMaps);
		return obj;
	}



	public static function isOfTypes(value:Any, types:Array<Dynamic>)
	{
		for (type in types)
		{
			if(Std.isOfType(value, type)) return true;
		}
		return false;
	}

	#if (!flash && sys)
	public static function getShader(obj:String):FlxRuntimeShader
	{
		var split:Array<String> = obj.split('.');
		var target:FlxSprite = null;
		if(split.length > 1) target = getVarInArray(getPropertyLoop(split), split[split.length-1]);
		else target = getObjectDirectly(split[0]);

		if(target == null)
		{
			FunkinLua.luaTrace('Error on getting shader: Object $obj not found', false, false, FlxColor.RED);
			return null;
		}
		return cast (target.shader, FlxRuntimeShader);
	}
	#end
}


class ModchartSprite extends FlxSprite
{
	public var wasAdded:Bool = false;
	public var animOffsets:Map<String, Array<Float>> = new Map<String, Array<Float>>();
	//public var isInFront:Bool = false;

	public function new(?x:Float = 0, ?y:Float = 0)
	{
		super(x, y);
		antialiasing = ClientPrefs.globalAntialiasing;
	}
}

class ModchartText extends FlxText
{
	public var wasAdded:Bool = false;
	public function new(x:Float, y:Float, text:String, width:Float)
	{
		super(x, y, width, text, 16);
		setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		cameras = [PlayState.instance.camHUD];
		scrollFactor.set();
		borderSize = 2;
	}
}

class DebugLuaText extends FlxText
{
	public var disableTime:Float = 6;
	public function new() {
		super(10, 10, 0, '', 16);
		setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scrollFactor.set();
		borderSize = 1;
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
		disableTime -= elapsed;
		if(disableTime < 0) disableTime = 0;
		if(disableTime < 1) alpha = disableTime;
		if(alpha == 0 || y >= FlxG.height) kill();
	}
}

class CustomSubstate extends MusicBeatSubstate
{
	public static var name:String = 'unnamed';
	public static var instance:CustomSubstate;

	public static function implement(funk:FunkinLua)
	{
		#if LUA_ALLOWED
		var lua = funk.lua;
		Lua_helper.add_callback(lua, "openCustomSubstate", openCustomSubstate);
		Lua_helper.add_callback(lua, "closeCustomSubstate", closeCustomSubstate);
		Lua_helper.add_callback(lua, "insertToCustomSubstate", insertToCustomSubstate);
		#end
	}
	
	public static function openCustomSubstate(name:String, ?pauseGame:Bool = false)
	{
		if(pauseGame)
		{
			FlxG.camera.followLerp = 0;
			PlayState.instance.persistentUpdate = false;
			PlayState.instance.persistentDraw = true;
			PlayState.instance.paused = true;
			if(FlxG.sound.music != null) {
				FlxG.sound.music.pause();
				PlayState.instance.vocals.pause();
			}
		}
		PlayState.instance.openSubState(new CustomSubstate(name));
		PlayState.instance.setOnHaxes('customSubstate', instance);
		PlayState.instance.setOnHaxes('customSubstateName', name);
	}

	public static function closeCustomSubstate()
	{
		if(instance != null)
		{
			PlayState.instance.closeSubState();
			instance = null;
			return true;
		}
		return false;
	}

	public static function insertToCustomSubstate(tag:String, ?pos:Int = -1)
	{
		if(instance != null)
		{
			var tagObject:FlxObject = cast (PlayState.instance.variables.get(tag), FlxObject);
			if(tagObject == null) tagObject = cast (PlayState.instance.modchartSprites.get(tag), FlxObject);

			if(tagObject != null)
			{
				if(pos < 0) instance.add(tagObject);
				else instance.insert(pos, tagObject);
				return true;
			}
		}
		return false;
	}

	override function create()
	{
		instance = this;

		PlayState.instance.callOnScripts('onCustomSubstateCreate', [name]);
		super.create();
		PlayState.instance.callOnScripts('onCustomSubstateCreatePost', [name]);
	}
	
	public function new(name:String)
	{
		CustomSubstate.name = name;
		super();
		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
	}
	
	override function update(elapsed:Float)
	{
		PlayState.instance.callOnScripts('onCustomSubstateUpdate', [name, elapsed]);
		super.update(elapsed);
		PlayState.instance.callOnScripts('onCustomSubstateUpdatePost', [name, elapsed]);
	}

	override function destroy()
	{
		PlayState.instance.callOnScripts('onCustomSubstateDestroy', [name]);
		name = 'unnamed';

		PlayState.instance.setOnHaxes('customSubstate', null);
		PlayState.instance.setOnHaxes('customSubstateName', name);
		super.destroy();
	}
}

class ModchartCharacter extends Character
{
	public var wasAdded:Bool = false;
	public function new(x:Float, y:Float, ?character:String = 'bf', ?isPlayer:Bool = false)
	{
		super(x, y, character, isPlayer);
	}
}

class ModchartGroupTyped extends FlxTypedGroup<Dynamic>
{
	public var wasAdded:Bool = false;
	public function new(maxSize:Int = 0)
	{
		super(maxSize);
	}
}

class ModchartGroup extends FlxSpriteGroup
{
	public var wasAdded:Bool = false;
	public function new(?x:Float = 0, ?y:Float = 0, ?maxSize:Int = 0)
	{
		super(x, y, maxSize);
	}	
}

class ModchartHealthIcon extends HealthIcon
{
	public var wasAdded:Bool = false;
	public function new(?char:String, ?isPlayer:Bool = false)
	{
		super(char, isPlayer);
	}
}

