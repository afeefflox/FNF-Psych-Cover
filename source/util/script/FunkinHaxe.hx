package util.script;

import flixel.graphics.frames.FlxFramesCollection;
import util.script.Globals.ModchartCharacter;
import util.script.Globals.ModchartGroup;

import flixel.FlxBasic;
import flixel.FlxG;
import util.script.Globals.*;
import meta.substate.PauseSubState;
import meta.state.*;
import meta.substate.*;

import objects.*;
import util.*;
import flixel.util.FlxColor;

import hscript.Parser;
import hscript.Interp;
import hscript.Expr;
import hscript.Expr.Error;

//**OpenFL & Lime related stuff**/
import lime.app.Application;
//**Flixel related stuff**/
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.system.FlxSound;
import flixel.system.FlxAssets;
import flixel.math.FlxMath;
import flixel.group.FlxGroup;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;
import flixel.addons.text.FlxTypeText;
import flixel.text.FlxText;
import flixel.util.FlxTimer;
import meta.state.editors.ChartingState.AttachedFlxText;
import flixel.animation.FlxAnimationController;
import flixel.math.FlxPoint;

using StringTools;
class FunkinHaxe 
{
    public static var Function_Stop:Dynamic = 1;
	public static var Function_Continue:Dynamic = 0;
	public static var Function_StopHaxe:Dynamic = 2;

    public var interp:Interp;
    public var superVar = {};
    public var scriptName:String = '';
    public var isStage:Bool = false;

    public function new(script:String, ?isStage:Bool = false) {
        scriptName = script;
        this.isStage = isStage;
        interp = new Interp();
        interp.errorHandler = errorHandler;
        for(k=>v in interp.variables) {
            Reflect.setField(superVar, k, v);
        }

        set("this", interp);
		set("super", superVar);

        set("Std", Std);
        set("Math", Math);
        set("StringTools", StringTools);
        set("Reflect", Reflect);
        //Flixel
        set("FlxG", FlxG);
        set("FlxSprite", FlxSprite);
        set("FlxBasic", FlxBasic);
        set("FlxCamera", FlxCamera);
        set("FlxEase", FlxEase);
        set("FlxTween", FlxTween);
        set("FlxSound", FlxSound);
        set("FlxMath", FlxMath);
        set("FlxText", FlxText);
        set("FlxTimer", FlxTimer);
        set('FlxColor', FlxColorHelper);
        //this Group by FlxBasic lol
        set("FlxGroup", FlxGroup);
        set("FlxTypedGroup", FlxTypedGroup);
        set("FlxSpriteGroup", FlxSpriteGroup);
        set("FlxTypedSpriteGroup", FlxTypedSpriteGroup);
        //Psych Engine Stuff
        set("GameOverSubstate", GameOverSubstate);
        set("Note", Note);
        set("Strumline", Strumline);
        set("Character", Character);
        set("Boyfriend", Character);
        set("PauseSubState", PauseSubState);
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
        if ((FlxG.state is PlayState))
        {
            set("PlayState", PlayState);
            set("game", PlayState.instance);
        }

        set("import", function(className:String) {
            var splitClassName = [for (e in className.split(".")) e.trim()];
            var realClassName = splitClassName.join(".");
            var cl = Type.resolveClass(realClassName);
            var en = Type.resolveEnum(realClassName);
            if (en != null) {
                // ENUM!!!!
                var enumThingy = {};
                for(c in en.getConstructors()) {
                    Reflect.setField(enumThingy, c, en.createByName(c));
                }
                set(splitClassName[splitClassName.length - 1], enumThingy);
            } else if (cl != null) {
                // CLASS!!!!
                set(splitClassName[splitClassName.length - 1], cl);
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
        set("makeLuaCharacter", function(tag:String, char:String, ?isPlayer:Bool = false, x:Float, y:Float) {
			tag = tag.replace('.', '');
			resetCharacterTag(tag);
			resetGroupTag(tag + 'Group');
			var leGroup:ModchartGroup = new ModchartGroup(x, y);
			var leCharacter:ModchartCharacter = new ModchartCharacter(0, 0, char, isPlayer);

			PlayState.instance.startCharacterPos(leCharacter, !isPlayer);
			PlayState.instance.startCharacterHaxe(leCharacter.curCharacter);
			PlayState.instance.startCharacterLua(leCharacter.curCharacter);
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
        set("setBlendMode", function(obj:FlxSprite, blend:String = '') {
            if(obj != null) {
				obj.blend = blendModeFromString(blend);
				return true;
			}
            return false;
        });

        set("copyFromAnimation", function(obj:FlxSprite, animation:FlxAnimationController) {
            if(obj != null) {
				obj.animation.copyFrom(animation);
				return true;
			}
            return false;
        });

        set("copyFromScale", function(obj:FlxSprite, scale:FlxPoint) {
            if(obj != null) {
				obj.scale.copyFrom(scale);
				return true;
			}
            return false;
        });

        set("loadFrames", function(obj:FlxSprite, frames:FlxFramesCollection) {
            if(obj != null) {
				obj.frames = frames;
				return true;
			}
            return false;
        });

        set("getFrames", function(obj:FlxSprite) {
            if(obj != null) {
				obj.frames;
			}
        });

        set("getAnimation", function(obj:FlxSprite) {
            if(obj != null) {
				obj.animation;
			}
        });

        set("setFormat", function(text:FlxText, font:String, size:Int = 8, color:String = 'white', ?alignment:String, ?borderStyle:String, borderColor:String = 'transparent', EmbeddedFont:Bool = true) {
            if(text != null) {
                text.setFormat(Paths.font(font), size, getFlxColorByString(color), getFlxTextAlignByString(alignment), getFlxTextBorderStyleByString(borderStyle), getFlxColorByString(borderColor));
				return true;
			}
            return false;
        });
        interp.execute(getExpressionFromPath(script, true));
        call('create', []);
        call('onCreate', []);
    }

    function getExpressionFromPath(path:String, critical:Bool = false):Expr {
        var ast:Expr = null;
        try {
            var content = sys.io.File.getContent(path);
            ast = getExpressionFromString(content, critical, path);
        } catch(ex) {
            PlayState.instance.addTextToDebug('Could not read the file at "$path".', FlxColor.RED);
        }
        return ast;
    }

    function getExpressionFromString(code:String, critical:Bool = false, ?path:String):Expr {
        if (code == null) return null;
        var parser = new Parser();
		parser.allowTypes = true;
        var ast:Expr = null;
		try {
			ast = parser.parseString(code, path);
		} catch(e:Error) {
            errorHandler(e);
		} catch(e) {
            errorHandler(new Error(ECustom(e.toString()), 0, 0, path, 0));
        }
        return ast;
    }

    public function call(func:String, ?args:Array<Dynamic>):Dynamic {
        #if hscript
        if (interp == null)
            return Function_Continue;
		if (interp.variables.exists(func)) {
            var f = interp.variables.get(func);
            if (Reflect.isFunction(f)) {
                if (args == null || args.length < 1)
                    return f();
                else
                    return Reflect.callMethod(null, f, args);
            }
		}
        #end
        return Function_Continue;
    }

    public function set(name:String, val:Dynamic) {
        interp.variables.set(name, val);
        @:privateAccess
        interp.locals.set(name, val);
    }

    public function get(name:String):Dynamic {
        if (@:privateAccess interp.locals.exists(name) && @:privateAccess interp.locals[name] != null) {
            @:privateAccess
            return interp.locals.get(name).r;
        } else if (interp.variables.exists(name))
            return interp.variables.get(name);

        return null;
    }

    public function stop() {
        if(interp == null) {
			return;
		}

		interp = null;
    }

    function errorHandler(error:Error) {
        var fn = '$scriptName:${error.line}: ';
        var err = error.toString();
        if (err.startsWith(fn)) err = err.substr(fn.length);
        PlayState.instance.addTextToDebug(fn, FlxColor.WHITE);
        PlayState.instance.addTextToDebug(err, FlxColor.RED);
    }
}