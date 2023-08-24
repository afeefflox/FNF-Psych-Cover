package util.script;

import flixel.FlxG;
import meta.state.editors.ChartingState.AttachedFlxText;
import meta.substate.GameOverSubstate;
#if hscript
import hscriptBase.Parser;
import hscriptBase.Interp;
import hscriptBase.Expr;
#end
import meta.state.PlayState;
import objects.*;
import util.*;
import util.script.Globals.*;
import util.script.Globals.ModchartCharacter;
import util.script.Globals.ModchartGroup;
import util.script.Globals.ModchartGroupTyped;
import util.script.Globals.ModchartSprite;
import util.script.Globals.ModchartText;
import util.script.Globals.CustomSubstate;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.util.FlxColor;
import flixel.FlxBasic;
import flixel.FlxSprite;
import flixel.text.FlxText;
using StringTools;
import tea.SScript;

typedef FlxGroupDynamic = FlxTypedGroup<Dynamic>;
typedef FlxTypedSpriteDynamicGroup = FlxTypedSpriteGroup<Dynamic>; 

#if HSCRIPT_ALLOWED
class FunkinHaxe extends SScript
{
	

    public var isStage:Bool = false;
	public var scriptName:String;
	public var origin:String;
	public var parentLua:FunkinLua;
	public function new(?parent:FunkinLua, ?scriptName:String, ?isStage:Bool = false)
	{
		if (scriptName == null)
			scriptName = '';
		
		//interp.errorHandler = _errorHandler;
		super(scriptName, false, false);
		this.scriptName = scriptName;
		this.isStage = isStage;
		parentLua = parent;

		if (parent != null)
			origin = parent.scriptName;
		if (scriptFile != null && scriptFile.length > 0)
			origin = scriptFile;
		preset();
		execute();
	}
	
	override function preset()
	{
		super.preset();

        set("Std", Std);
        set("Math", Math);
        set("StringTools", StringTools);
        set("Reflect", Reflect);

		//Flixel
        set("FlxG", flixel.FlxG);
        set("FlxSprite", flixel.FlxSprite);
        set("FlxBasic", flixel.FlxBasic);
        set("FlxCamera", flixel.FlxCamera);
        set("FlxEase", flixel.tweens.FlxEase);
        set("FlxTween", flixel.tweens.FlxTween);
        set("FlxSound", flixel.system.FlxSound);
        set("FlxMath", flixel.math.FlxMath);
        set("FlxText", flixel.text.FlxText);
        set("FlxTimer", flixel.util.FlxTimer);
        set('FlxColor', util.FlxColorHelper);
		
        //Psych Engine Stuff
        set("GameOverSubstate", meta.substate.GameOverSubstate);
        set("Note", Note);
        set("Strumline", Strumline);
        set("Character", Character);
        set("Boyfriend", Character);
        set("PauseSubState", meta.substate.PauseSubState);
        set("Paths", Paths);
        set("Conductor", Conductor);
        set("CoolUtil", CoolUtil);
        set("Alphabet", Alphabet);
        set("TypedAlphabet", TypedAlphabet);
        set("Stage", Stage);
        set("HealthIcon", HealthIcon);
        set("BGSprite", BGSprite);
        set("AttachedText", AttachedText);
        set("AttachedFlxText", AttachedFlxText);
        set("AttachedSprite", AttachedSprite);
        set("ClientPrefs", ClientPrefs);
        set("ColorSwap", ColorSwap);
		set("Globals", Globals);
		set('CustomSubstate', util.script.Globals.CustomSubstate);
		#if (!flash && sys)
		set('FlxRuntimeShader', flixel.addons.display.FlxRuntimeShader);
		#end
		set('ShaderFilter', openfl.filters.ShaderFilter);
		set('StringTools', StringTools);
        if ((FlxG.state is PlayState))
        {
            set("PlayState", PlayState);
            set("game", PlayState.instance);
        }

		set('parentLua', parentLua);
		set('buildTarget', FunkinLua.getBuildTarget());
		set('customSubstate', CustomSubstate.instance);
		set('customSubstateName', CustomSubstate.name);
		set('this', this);

		set('Function_Stop', FunkinLua.Function_Stop);
		set('Function_Continue', FunkinLua.Function_Continue);
		set('Function_StopLua', FunkinLua.Function_StopLua); //doesnt do much cuz HScript has a lower priority than Lua
		set('Function_StopHScript', FunkinLua.Function_StopHScript);
		set('Function_StopAll', FunkinLua.Function_StopAll);

		set('setVar', function(name:String, value:Dynamic)
		{
			PlayState.instance.variables.set(name, value);
		});

		set('getVar', function(name:String)
		{
			var result:Dynamic = null;
			if(PlayState.instance.variables.exists(name)) result = PlayState.instance.variables.get(name);
			return result;
		});

		set('removeVar', function(name:String)
		{
			if(PlayState.instance.variables.exists(name))
			{
				PlayState.instance.variables.remove(name);
				return true;
			}
			return false;
		});

		set("addHaxeLibrary", function(libName:String, ?libPackage:String = '') {
			#if hscript
			try {
				var str:String = '';
				if(libPackage.length > 0)
					str = libPackage + '.';

				set(libName, Type.resolveClass(str + libName));
			}
			catch (e:Dynamic) {
				var msg:String = e.message.substr(0, e.message.indexOf('\n'));
				if(parentLua != null)
				{
					FunkinLua.lastCalledScript = parentLua;
					msg = origin + ":" + parentLua.lastCalledFunction + " - " + msg;
				}
				else msg = '$origin - $msg';
				FunkinLua.luaTrace(msg, parentLua == null, false, FlxColor.RED);
			}
			#end
		});

		set('debugPrint', function(text:String, ?color:FlxColor = null) {
			if(color == null) color = FlxColor.WHITE;
			PlayState.instance.addTextToDebug(text, color);
		});

		set('createGlobalCallback', function(name:String, func:Dynamic)
		{
			#if LUA_ALLOWED
			for (script in PlayState.instance.luaArray)
				if(script != null && script.lua != null && !script.closed)
					Lua_helper.add_callback(script.lua, name, func);
			#end
			FunkinLua.customFunctions.set(name, func);
		});

		set('createCallback', function(name:String, func:Dynamic, ?funk:FunkinLua = null)
		{
			if(funk == null) funk = parentLua;
			
			if(parentLua != null) funk.addLocalCallback(name, func);
			else FunkinLua.luaTrace('createCallback ($name): 3rd argument is null', false, false, FlxColor.RED);
		});
		
        set("makeLuaCharacter", function(tag:String, char:String, ?isPlayer:Bool = false, x:Float, y:Float) {
			tag = tag.replace('.', '');
			resetCharacterTag(tag);
			resetGroupTag(tag + 'Group');
			var leGroup:ModchartGroup = new ModchartGroup(x, y);
			var leCharacter:ModchartCharacter = new ModchartCharacter(x, y, char, isPlayer);
			PlayState.instance.startCharacterPos(leCharacter, !isPlayer);
			PlayState.instance.startCharacterScripts(leCharacter.curCharacter);
            PlayState.instance.modchartCharacters.set(tag, leCharacter);
			PlayState.instance.modchartGroups.set(tag + 'Group', leGroup);
        });

        set("addLuaCharacter", function(tag:String, front:Bool = false, ?layersName:String = 'boyfriend') {
			if(PlayState.instance.modchartCharacters.exists(tag) && PlayState.instance.modchartGroups.exists(tag + 'Group')) {
				var shit:ModchartCharacter = PlayState.instance.modchartCharacters.get(tag);
				var shitGroup:ModchartGroup = PlayState.instance.modchartGroups.get(tag + 'Group');
				if(isStage)
					Globals.addCharacterLayer(shit, front, layersName);
				else
				{
					if(front)
						Globals.getTargetInstance().add(shit);
					else
					{
						if(!PlayState.instance.isDead)
							PlayState.instance.insert(PlayState.instance.members.indexOf(Globals.getLowestCharacterGroup()), shit);
						else
							GameOverSubstate.instance.insert(GameOverSubstate.instance.members.indexOf(GameOverSubstate.instance.boyfriend), shit);
					}
				}

				shitGroup.add(shit);
			}
        });

		set("makeLuaGroup", function(tag:String) {
			tag = tag.replace('.', '');
			resetGroupTypedTag(tag);
			var leGroup:ModchartGroupTyped = new ModchartGroupTyped();
			PlayState.instance.modchartGroupTypes.set(tag, leGroup);
			leGroup.forEach(function(leSprite:Dynamic) {
				call('onEachGroup', [tag]);
			});
		});

		set("makeLuaSpriteGroup", function(tag:String, x:Float, y:Float) {
			tag = tag.replace('.', '');
			resetGroupTag(tag);
			var leGroup:ModchartGroup = new ModchartGroup(x, y);
			PlayState.instance.modchartGroups.set(tag, leGroup);
			leGroup.forEach(function(leSprite:FlxSprite) {
				call('onEachGroup', [tag]);
			});
		});
		

		set("addGroup", function(group:String, obj:FlxBasic) {
			if(PlayState.instance.getLuaGroup(group) !=null) {
				if(obj !=null) {
					PlayState.instance.getLuaGroup(group).add(obj);
				}
				return true;
			}
			return false;
		});

		set("insertGroup", function(group:String, obj:FlxBasic, position:Int) {
			if(PlayState.instance.getLuaGroup(group) !=null) {
				if(obj !=null) {
					PlayState.instance.getLuaGroup(group).insert(position, obj);
				}
				return true;
			}
			return false;
		});

		set("addLuaGroup", function(tag:String, front:Bool = false, ?layersName:String = 'boyfriend') {
			if(PlayState.instance.modchartGroupTypes.exists(tag)) {
				var shit:ModchartGroupTyped = PlayState.instance.modchartGroupTypes.get(tag);
				if(isStage)
					Globals.addCharacterLayer(shit, front, layersName);
				else
				{
					if(front)
						Globals.getTargetInstance().add(shit);
					else
					{
						if(!PlayState.instance.isDead)
							PlayState.instance.insert(PlayState.instance.members.indexOf(Globals.getLowestCharacterGroup()), shit);
						else
							GameOverSubstate.instance.insert(GameOverSubstate.instance.members.indexOf(GameOverSubstate.instance.boyfriend), shit);
					}
				}
			}
		});

		set("addLuaSpriteGroup", function(tag:String, front:Bool = false, ?layersName:String = 'boyfriend') {
			if(PlayState.instance.modchartGroups.exists(tag)) {
				var shit:ModchartGroup = PlayState.instance.modchartGroups.get(tag);
				if(isStage)
					Globals.addCharacterLayer(shit, front, layersName);
				else
				{
					if(front)
						Globals.getTargetInstance().add(shit);
					else
					{
						if(!PlayState.instance.isDead)
							PlayState.instance.insert(PlayState.instance.members.indexOf(Globals.getLowestCharacterGroup()), shit);
						else
							GameOverSubstate.instance.insert(GameOverSubstate.instance.members.indexOf(GameOverSubstate.instance.boyfriend), shit);
					}
				}
			}
		});
		
        set("add", function(obj:FlxBasic, ?front:Bool = false, ?layersName:String = 'boyfriend') {
			if(isStage)
				Globals.addCharacterLayer(obj, front, layersName);
			else
			{
				if(front)
					Globals.getTargetInstance().add(obj);
				else
				{
					if(!PlayState.instance.isDead)
						PlayState.instance.insert(PlayState.instance.members.indexOf(Globals.getLowestCharacterGroup()), obj);
					else
						GameOverSubstate.instance.insert(GameOverSubstate.instance.members.indexOf(GameOverSubstate.instance.boyfriend), obj);
				}
			}
        });

		set("remove", function(obj:FlxBasic, ?front:Bool = false, ?layersName:String = 'boyfriend') {
			if(isStage)
				Globals.removeCharacterLayer(obj, front, layersName);
			else
			{
				if(!PlayState.instance.isDead)
					PlayState.instance.remove(obj);
				else
					GameOverSubstate.instance.remove(obj);
			}
        });

		set('addBehindGF', function(obj:FlxBasic) PlayState.instance.addBehindGF(obj));
		set('addBehindDad', function(obj:FlxBasic) PlayState.instance.addBehindDad(obj));
		set('addBehindBF', function(obj:FlxBasic) PlayState.instance.addBehindBF(obj));
		set('insert', function(pos:Int, obj:FlxBasic) PlayState.instance.insert(pos, obj));
	}
	
	override public function destroy()
	{
		origin = null;
		parentLua = null;

		super.destroy();
	}
}
#end

//If hscript were working
class HScript
{
	public static var parser:Parser = new Parser();
	public var interp:Interp;
	public var variables(get, never):Map<String, Dynamic>;
	public var parentLua:FunkinLua;
	public function get_variables()
	{
		return interp.variables;
	}

	public static function initHaxeModuleCode(parent:FunkinLua)
	{
		if(parent.hscript == null)
		{
			trace('initializing haxe interp for: ${parent.scriptName}');
			parent.hscript = new HScript(parent);
		}
	}

	public function new(?parent:FunkinLua)
	{
		interp = new Interp();
		interp.variables.set('FlxG', FlxG);
		interp.variables.set('FlxSprite', FlxSprite);
		interp.variables.set('FlxCamera', FlxCamera);
		interp.variables.set('FlxTimer', FlxTimer);
		interp.variables.set('FlxTween', FlxTween);
		interp.variables.set('FlxEase', FlxEase);
		interp.variables.set('PlayState', PlayState);
		interp.variables.set('game', PlayState.instance);
		interp.variables.set('Paths', Paths);
		interp.variables.set('Conductor', Conductor);
		interp.variables.set('ClientPrefs', ClientPrefs);
		interp.variables.set('Character', Character);
		interp.variables.set('FlxColor', util.FlxColorHelper);
		interp.variables.set('Alphabet', Alphabet);
		interp.variables.set('CustomSubstate', CustomSubstate);
		#if (!flash && sys)
		interp.variables.set('FlxRuntimeShader', flixel.addons.display.FlxRuntimeShader);
		#end
		interp.variables.set('ShaderFilter', openfl.filters.ShaderFilter);
		interp.variables.set('StringTools', StringTools);
		interp.variables.set('parentLua', parentLua);
		interp.variables.set('buildTarget', FunkinLua.getBuildTarget());

		interp.variables.set('setVar', function(name:String, value:Dynamic)
		{
			PlayState.instance.variables.set(name, value);
		});

		interp.variables.set('getVar', function(name:String)
		{
			var result:Dynamic = null;
			if(PlayState.instance.variables.exists(name)) result = PlayState.instance.variables.get(name);
			return result;
		});
		interp.variables.set('removeVar', function(name:String)
		{
			if(PlayState.instance.variables.exists(name))
			{
				PlayState.instance.variables.remove(name);
				return true;
			}
			return false;
		});

		interp.variables.set('debugPrint', function(text:String, ?color:FlxColor = null) {
			if(color == null) color = FlxColor.WHITE;
			PlayState.instance.addTextToDebug(text, color);
		});

		interp.variables.set('createGlobalCallback', function(name:String, func:Dynamic)
		{
			#if LUA_ALLOWED
			for (script in PlayState.instance.luaArray)
				if(script != null && script.lua != null && !script.closed)
					Lua_helper.add_callback(script.lua, name, func);
			#end
			FunkinLua.customFunctions.set(name, func);
		});

		interp.variables.set('createGlobalCallback', function(name:String, func:Dynamic)
		{
			#if LUA_ALLOWED
			for (script in PlayState.instance.luaArray)
				if(script != null && script.lua != null && !script.closed)
					Lua_helper.add_callback(script.lua, name, func);
			#end
			FunkinLua.customFunctions.set(name, func);
		});

		interp.variables.set('createCallback', function(name:String, func:Dynamic, ?funk:FunkinLua = null)
		{
			if(funk == null) funk = parentLua;
			if(parentLua != null) funk.addLocalCallback(name, func);
			else FunkinLua.luaTrace('createCallback ($name): 3rd argument is null', false, false, FlxColor.RED);
		});
	}

	public function execute(codeToRun:String):Dynamic
	{
		@:privateAccess
		HScript.parser.line = 1;
		HScript.parser.allowTypes = true;
		return interp.execute(HScript.parser.parseString(codeToRun));
	}

	public static function implement(funk:FunkinLua)
	{
		funk.addLocalCallback("runHaxeCode", function(codeToRun:String) {
			var retVal:Dynamic = null;

			#if hscript
			initHaxeModuleCode(funk);
			try {
				retVal = funk.hscript.execute(codeToRun);
			}
			catch (e:Dynamic) {
				FunkinLua.luaTrace(funk.scriptName + ":" + funk.lastCalledFunction + " - " + e, false, false, FlxColor.RED);
			}
			#else
			FunkinLua.luaTrace("runHaxeCode: HScript isn't supported on this platform!", false, false, FlxColor.RED);
			#end

			if(retVal != null && !isOfTypes(retVal, [Bool, Int, Float, String, Array])) retVal = null;
			if(retVal == null) Lua.pushnil(funk.lua);
			return retVal;
		});

		funk.addLocalCallback("addHaxeLibrary", function(libName:String, ?libPackage:String = '') {
			initHaxeModuleCode(funk);
			try {
				var str:String = '';
				if(libPackage.length > 0)
					str = libPackage + '.';

				funk.hscript.variables.set(libName, Type.resolveClass(str + libName));
			}
			catch (e:Dynamic) {
				FunkinLua.luaTrace(funk.scriptName + ":" + funk.lastCalledFunction + " - " + e, false, false, FlxColor.RED);
			}
		});
	}
}