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
import hscriptBase.Expr.Error;
using StringTools;

typedef FlxGroupDynamic = FlxTypedGroup<Dynamic>;
typedef FlxTypedSpriteDynamicGroup = FlxTypedSpriteGroup<Dynamic>; 

class FunkinHaxe extends SScript
{
    public var isStage:Bool = false;
	public var scriptName:String;
	var expr:Expr;
	public function new(scriptName:String, ?isStage:Bool = false, ?preset:Bool = true)
	{
		//interp.errorHandler = _errorHandler;
		super(scriptName, preset);
		this.scriptName = scriptName;
		this.isStage = isStage;
		traces = false;
		trace('haxe file loaded succesfully:' + scriptName);

		parser.allowTypes = true;
	}
	
	override public function preset()
	{
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
                trace(e);
			}
			#end
		});

        set("import", function(libName:String, ?libPackage:String = '') {
			#if hscript
			try {
				var str:String = '';
				if(libPackage.length > 0)
					str = libPackage + '.';

				set(libName, Type.resolveClass(str + libName));
			}
			catch (e:Dynamic) {
				trace(e);
			}
			#end
		});
		
        set("makeLuaCharacter", function(tag:String, char:String, ?isPlayer:Bool = false, x:Float, y:Float) {
			tag = tag.replace('.', '');
			resetCharacterTag(tag);
			resetGroupTag(tag + 'Group');
			var leGroup:ModchartGroup = new ModchartGroup(x, y);
			var leCharacter:ModchartCharacter = new ModchartCharacter(x, y, char, isPlayer);
			PlayState.instance.startCharacterPos(leCharacter, !isPlayer);
			PlayState.instance.startCharacterLua(leCharacter.curCharacter);
			PlayState.instance.startCharacterHaxe(leCharacter.curCharacter);
            PlayState.instance.modchartCharacters.set(tag, leCharacter);
			PlayState.instance.modchartGroups.set(tag + 'Group', leGroup);
        });

        set("addLuaCharacter", function(tag:String, front:Bool = false, ?layersName:String = 'boyfriend') {
			if(PlayState.instance.modchartCharacters.exists(tag) && PlayState.instance.modchartGroups.exists(tag + 'Group')) {
				var shit:ModchartCharacter = PlayState.instance.modchartCharacters.get(tag);
				var shitGroup:ModchartGroup = PlayState.instance.modchartGroups.get(tag + 'Group');
				if(!shitGroup.wasAdded && !shit.wasAdded) {
					if(isStage)
					{
						if(front)
						{
							var layersCharacter:String = 'boyfriend';
							switch(layersName)
							{
								case 'gf'|'girlfriend':
									layersCharacter = 'gf';
								case 'dad'|'opponent':
									layersCharacter = 'dad';
							}
							Stage.instance.layers.get(layersCharacter).add(shitGroup);
						}
						else
						{
							Stage.instance.add(shitGroup);
						}
							
					}
					else
					{
						if(front)
						{
							PlayState.instance.add(shitGroup);
						}
	
						if(PlayState.instance.isDead)
						{
							GameOverSubstate.instance.insert(GameOverSubstate.instance.members.indexOf(GameOverSubstate.instance.boyfriend), shitGroup);
						}
						else
						{
							var position:Int = PlayState.instance.members.indexOf(PlayState.instance.gfGroup);
							if(PlayState.instance.members.indexOf(PlayState.instance.boyfriendGroup) < position) {
								position = PlayState.instance.members.indexOf(PlayState.instance.boyfriendGroup);
							} else if(PlayState.instance.members.indexOf(PlayState.instance.dadGroup) < position) {
								position = PlayState.instance.members.indexOf(PlayState.instance.dadGroup);
							}
							PlayState.instance.insert(position, shitGroup);
						}
					}
					shit.wasAdded = true;
					shitGroup.wasAdded = true;
					shitGroup.add(shit);
					//trace('added a thing: ' + tag);
				}
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
				if(!shit.wasAdded) {
					if(isStage)
					{
						if(front)
						{
							var layersCharacter:String = 'boyfriend';
							switch(layersName)
							{
								case 'gf'|'girlfriend':
									layersCharacter = 'gf';
								case 'dad'|'opponent':
									layersCharacter = 'dad';
							}
							Stage.instance.layers.get(layersCharacter).add(shit);
						}
						else
						{
							Stage.instance.add(shit);
						}
							
					}
					else
					{
						if(front)
						{
							getInstance().add(shit);
						}
	
						if(PlayState.instance.isDead)
						{
							GameOverSubstate.instance.insert(GameOverSubstate.instance.members.indexOf(GameOverSubstate.instance.boyfriend), shit);
						}
						else
						{
							var position:Int = PlayState.instance.members.indexOf(PlayState.instance.gfGroup);
							if(PlayState.instance.members.indexOf(PlayState.instance.boyfriendGroup) < position) {
								position = PlayState.instance.members.indexOf(PlayState.instance.boyfriendGroup);
							} else if(PlayState.instance.members.indexOf(PlayState.instance.dadGroup) < position) {
								position = PlayState.instance.members.indexOf(PlayState.instance.dadGroup);
							}
							PlayState.instance.insert(position, shit);
						}
					}
					shit.wasAdded = true;
					//trace('added a thing: ' + tag);
				}
			}
		});

		set("addLuaSpriteGroup", function(tag:String, front:Bool = false, ?layersName:String = 'boyfriend') {
			if(PlayState.instance.modchartGroups.exists(tag)) {
				var shit:ModchartGroup = PlayState.instance.modchartGroups.get(tag);
				if(!shit.wasAdded) {
					if(isStage)
					{
						if(front)
						{
							var layersCharacter:String = 'boyfriend';
							switch(layersName)
							{
								case 'gf'|'girlfriend':
									layersCharacter = 'gf';
								case 'dad'|'opponent':
									layersCharacter = 'dad';
							}
							Stage.instance.layers.get(layersCharacter).add(shit);
						}
						else
						{
							Stage.instance.add(shit);
						}
							
					}
					else
					{
						if(front)
						{
							getInstance().add(shit);
						}
	
						if(PlayState.instance.isDead)
						{
							GameOverSubstate.instance.insert(GameOverSubstate.instance.members.indexOf(GameOverSubstate.instance.boyfriend), shit);
						}
						else
						{
							var position:Int = PlayState.instance.members.indexOf(PlayState.instance.gfGroup);
							if(PlayState.instance.members.indexOf(PlayState.instance.boyfriendGroup) < position) {
								position = PlayState.instance.members.indexOf(PlayState.instance.boyfriendGroup);
							} else if(PlayState.instance.members.indexOf(PlayState.instance.dadGroup) < position) {
								position = PlayState.instance.members.indexOf(PlayState.instance.dadGroup);
							}
							PlayState.instance.insert(position, shit);
						}
					}
					shit.wasAdded = true;
					//trace('added a thing: ' + tag);
				}
			}
		});
		
        set("add", function(obj:FlxBasic, ?front:Bool = false, ?layersName:String = 'boyfriend') {

            if(isStage) {
                if(front)
                {
                    var layersCharacter:String = 'boyfriend';
                    switch(layersName)
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
            else
            {
                if(front)
                {
                    PlayState.instance.add(obj);
                }
                else
                {
                    if(PlayState.instance.isDead)
					{
						GameOverSubstate.instance.insert(GameOverSubstate.instance.members.indexOf(GameOverSubstate.instance.boyfriend), obj);
					}
					else
					{
						var position:Int = PlayState.instance.members.indexOf(PlayState.instance.gfGroup);
						if(PlayState.instance.members.indexOf(PlayState.instance.boyfriendGroup) < position) {
							position = PlayState.instance.members.indexOf(PlayState.instance.boyfriendGroup);
						} else if(PlayState.instance.members.indexOf(PlayState.instance.dadGroup) < position) {
							position = PlayState.instance.members.indexOf(PlayState.instance.dadGroup);
						}
						PlayState.instance.insert(position, obj);
					}
                }
            }
        });

		set("remove", function(obj:FlxBasic, ?front:Bool = false, ?layersName:String = 'boyfriend') {
            if(isStage) {
                if(front)
                {
                    var layersCharacter:String = 'boyfriend';
                    switch(layersName)
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
            else
            {
                if(front)
                {
                    PlayState.instance.remove(obj);
                }
                else
                {
                    if(PlayState.instance.isDead)
					{
						GameOverSubstate.instance.remove(obj);
					}
					else
					{
						PlayState.instance.remove(obj);
					}
                }
            }
        });
		
        set("setBlendMode", function(obj:FlxSprite, blend:String = '') {
            if(obj != null) {
				obj.blend = blendModeFromString(blend);
				return true;
			}
            return false;
        });

        set("setFormat", function(text:FlxText, font:String, size:Int = 8, color:String = 'white', ?alignment:String, ?borderStyle:String, borderColor:String = 'transparent', EmbeddedFont:Bool = true) {
            if(text != null) {
                text.setFormat(Paths.font(font), size, getFlxColorByString(color), getFlxTextAlignByString(alignment), getFlxTextBorderStyleByString(borderStyle), getFlxColorByString(borderColor));
				return true;
			}
            return false;
        });
	}

	public static function callThisScripts(moduleArray:Array<FunkinHaxe>, luaFile:String):Array<FunkinHaxe>
	{
		#if MODS_ALLOWED
		var luaToLoad:String = Paths.modFolders(luaFile + '.hx');
		if(sys.FileSystem.exists(luaToLoad))
		{
			moduleArray.push(new FunkinHaxe(luaToLoad));
		}
		else
		{
			luaToLoad = Paths.getPreloadPath(luaFile + '.hx');
			if(sys.FileSystem.exists(luaToLoad))
			{
				moduleArray.push(new FunkinHaxe(luaToLoad));
			}
		}
		#elseif sys
		var luaToLoad:String = Paths.getPreloadPath(luaFile + '.hx');
		if(OpenFlAssets.exists(luaToLoad))
		{
			moduleArray.push(new FunkinHaxe(luaToLoad));
		}
		#end

		if (moduleArray != null)
		{
			for (i in moduleArray)
			{
				i.call('create', []);
			}
		}

		return moduleArray;
	}
}