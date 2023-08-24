package util.script;
import util.script.Globals.ModchartCharacter;
import util.script.Globals.ModchartGroup;
import util.script.Globals.ModchartGroupTyped;
import util.script.Globals.ModchartSprite;
import util.script.Globals.ModchartText;
import util.script.Globals.CustomSubstate;
import util.script.Globals.LuaTweenOptions;
import objects.Stage;
import meta.substate.*;
import meta.state.*;
import meta.state.freeplay.*;
import flixel.FlxObject;
import flixel.FlxBasic;
import flixel.util.FlxSave;
import flixel.addons.transition.FlxTransitionableState;
import util.DialogueBoxPsych;
import openfl.utils.Assets;
import Type.ValueType;
#if (!flash && sys)
import flixel.addons.display.FlxRuntimeShader;
#end
#if sys
import sys.FileSystem;
import sys.io.File;
#end

class FunkinUtil {
    public static function spriteFunction(funk:FunkinLua, isStage:Bool)
    {
        var lua = funk.lua;
        var game = PlayState.instance;

        Lua_helper.add_callback(lua, "loadGraphic", function(variable:String, image:String, ?gridX:Int = 0, ?gridY:Int = 0) {
			var split:Array<String> = variable.split('.');
			var spr:FlxSprite = Globals.getObjectDirectly(split[0]);
			var animated = gridX != 0 || gridY != 0;

			if(split.length > 1) {
				spr = Globals.getVarInArray(Globals.getPropertyLoop(split), split[split.length-1]);
			}

			if(spr != null && image != null && image.length > 0)
			{
				spr.loadGraphic(Paths.image(image), animated, gridX, gridY);
			}
		});

        Lua_helper.add_callback(lua, "loadFrames", function(variable:String, image:String, spriteType:String = "sparrow") {
			var split:Array<String> = variable.split('.');
			var spr:FlxSprite = Globals.getObjectDirectly(split[0]);
			if(split.length > 1) {
				spr = Globals.getVarInArray(Globals.getPropertyLoop(split), split[split.length-1]);
			}

			if(spr != null && image != null && image.length > 0)
			{
				Globals.loadFrames(spr, image, spriteType);
			}
		});

        Lua_helper.add_callback(lua, "getObjectOrder", function(obj:String) {
			var split:Array<String> = obj.split('.');
			var leObj:FlxBasic = Globals.getObjectDirectly(split[0]);
			if(split.length > 1) {
				leObj = Globals.getVarInArray(Globals.getPropertyLoop(split), split[split.length-1]);
			}

			if(leObj != null)
			{
				return Globals.getTargetInstance().members.indexOf(leObj);
			}
			FunkinLua.luaTrace("getObjectOrder: Object " + obj + " doesn't exist!", false, false, FlxColor.RED);
			return -1;
		});

		Lua_helper.add_callback(lua, "setObjectOrder", function(obj:String, position:Int) {
			var split:Array<String> = obj.split('.');
			var leObj:FlxBasic = Globals.getObjectDirectly(split[0]);
			if(split.length > 1) {
				leObj = Globals.getVarInArray(Globals.getPropertyLoop(split), split[split.length-1]);
			}

			if(leObj != null) {
				Globals.getTargetInstance().remove(leObj, true);
				Globals.getTargetInstance().insert(position, leObj);
				return;
			}
			FunkinLua.luaTrace("setObjectOrder: Object " + obj + " doesn't exist!", false, false, FlxColor.RED);
		});

        Lua_helper.add_callback(lua, "getMidpointX", function(variable:String) {
			var split:Array<String> = variable.split('.');
			var obj:FlxSprite = Globals.getObjectDirectly(split[0]);
			if(split.length > 1) {
				obj = Globals.getVarInArray(Globals.getPropertyLoop(split), split[split.length-1]);
			}
			if(obj != null) return obj.getMidpoint().x;

			return 0;
		});

		Lua_helper.add_callback(lua, "getMidpointY", function(variable:String) {
			var split:Array<String> = variable.split('.');
			var obj:FlxSprite = Globals.getObjectDirectly(split[0]);
			if(split.length > 1) {
				obj = Globals.getVarInArray(Globals.getPropertyLoop(split), split[split.length-1]);
			}
			if(obj != null) return obj.getMidpoint().y;

			return 0;
		});

		Lua_helper.add_callback(lua, "getGraphicMidpointX", function(variable:String) {
			var split:Array<String> = variable.split('.');
			var obj:FlxSprite = Globals.getObjectDirectly(split[0]);
			if(split.length > 1) {
				obj = Globals.getVarInArray(Globals.getPropertyLoop(split), split[split.length-1]);
			}
			if(obj != null) return obj.getGraphicMidpoint().x;

			return 0;
		});

		Lua_helper.add_callback(lua, "getGraphicMidpointY", function(variable:String) {
			var split:Array<String> = variable.split('.');
			var obj:FlxSprite = Globals.getObjectDirectly(split[0]);
			if(split.length > 1) {
				obj = Globals.getVarInArray(Globals.getPropertyLoop(split), split[split.length-1]);
			}
			if(obj != null) return obj.getGraphicMidpoint().y;

			return 0;
		});

		Lua_helper.add_callback(lua, "getScreenPositionX", function(variable:String, ?camera:String) {
			var split:Array<String> = variable.split('.');
			var obj:FlxSprite = Globals.getObjectDirectly(split[0]);
			if(split.length > 1) {
				obj = Globals.getVarInArray(Globals.getPropertyLoop(split), split[split.length-1]);
			}
			if(obj != null) return obj.getScreenPosition().x;

			return 0;
		});

		Lua_helper.add_callback(lua, "getScreenPositionY", function(variable:String, ?camera:String) {
			var split:Array<String> = variable.split('.');
			var obj:FlxSprite = Globals.getObjectDirectly(split[0]);
			if(split.length > 1) {
				obj = Globals.getVarInArray(Globals.getPropertyLoop(split), split[split.length-1]);
			}
			if(obj != null) return obj.getScreenPosition().y;

			return 0;
		});

        Lua_helper.add_callback(lua, "makeLuaSprite", function(tag:String, ?image:String = null, ?x:Float = 0, ?y:Float = 0) {
			tag = tag.replace('.', '');
			Globals.resetSpriteTag(tag);
			var leSprite:ModchartSprite = new ModchartSprite(x, y);
			if(image != null && image.length > 0)
			{
				leSprite.loadGraphic(Paths.image(image));
			}
			game.modchartSprites.set(tag, leSprite);
			leSprite.active = true;
		});

		Lua_helper.add_callback(lua, "makeAnimatedLuaSprite", function(tag:String, ?image:String = null, ?x:Float = 0, ?y:Float = 0, ?spriteType:String = "sparrow") {
			tag = tag.replace('.', '');
			Globals.resetSpriteTag(tag);
			var leSprite:ModchartSprite = new ModchartSprite(x, y);

			Globals.loadFrames(leSprite, image, spriteType);
			game.modchartSprites.set(tag, leSprite);
		});

        Lua_helper.add_callback(lua, "makeGraphic", function(obj:String, width:Int = 256, height:Int = 256, color:String = 'FFFFFF') {
			var spr:FlxSprite = Globals.getObjectDirectly(obj, false);
			if(spr != null) spr.makeGraphic(width, height, CoolUtil.colorFromString(color));
		});

		Lua_helper.add_callback(lua, "addAnimationByPrefix", function(obj:String, name:String, prefix:String, framerate:Int = 24, loop:Bool = true) {
			var obj:Dynamic = Globals.getObjectDirectly(obj, false);
			if(obj != null && obj.animation != null)
			{
				obj.animation.addByPrefix(name, prefix, framerate, loop);
				if(obj.animation.curAnim == null)
				{
					if(obj.playAnim != null) obj.playAnim(name, true);
					else obj.animation.play(name, true);
				}
				return true;
			}
			return false;
		});

		Lua_helper.add_callback(lua, "addAnimation", function(obj:String, name:String, frames:Array<Int>, framerate:Int = 24, loop:Bool = true) {
			var obj:Dynamic = Globals.getObjectDirectly(obj, false);
			if(obj != null && obj.animation != null)
			{
				obj.animation.add(name, frames, framerate, loop);
				if(obj.animation.curAnim == null) {
					obj.animation.play(name, true);
				}
				return true;
			}
			return false;
		});

		Lua_helper.add_callback(lua, "addAnimationByIndices", function(obj:String, name:String, prefix:String, indices:String, framerate:Int = 24, loop:Bool = false) {
			return Globals.addAnimByIndices(obj, name, prefix, indices, framerate, loop);
		});


        Lua_helper.add_callback(lua, "playAnim", function(obj:String, name:String, forced:Bool = false, ?reverse:Bool = false, ?startFrame:Int = 0)
		{
			var obj:Dynamic = Globals.getObjectDirectly(obj, false);
			if(obj.playAnim != null)
			{
				obj.playAnim(name, forced, reverse, startFrame);
				return true;
			}
			else
			{
				obj.animation.play(name, forced, reverse, startFrame);
				return true;
			}
			return false;
		});

		Lua_helper.add_callback(lua, "addOffset", function(obj:String, anim:String, x:Float, y:Float) {
			var obj:Dynamic = Globals.getObjectDirectly(obj, false);
			if(obj != null && obj.addOffset != null)
			{
				obj.addOffset(anim, x, y);
				return true;
			}
			return false;
		});

		Lua_helper.add_callback(lua, "setScrollFactor", function(obj:String, scrollX:Float, scrollY:Float) {
			if(game.getLuaObject(obj,false)!=null) {
				game.getLuaObject(obj,false).scrollFactor.set(scrollX, scrollY);
				return;
			}

			var object:FlxObject = Reflect.getProperty(Globals.getTargetInstance(), obj);
			if(object != null) {
				object.scrollFactor.set(scrollX, scrollY);
			}
		});

        Lua_helper.add_callback(lua, "addLuaSprite", function(tag:String, front:Bool = false, ?layersName:String = 'boyfriend') {
			if(game.modchartSprites.exists(tag)) {
				var shit:ModchartSprite = game.modchartSprites.get(tag);
                if(isStage)
					Globals.addCharacterLayer(shit, front, layersName);
                else
                {
                    if(front)
                        Globals.getTargetInstance().add(shit);
                    else
                    {
                        if(!game.isDead)
                            game.insert(game.members.indexOf(Globals.getLowestCharacterGroup()), shit);
                        else
                            GameOverSubstate.instance.insert(GameOverSubstate.instance.members.indexOf(GameOverSubstate.instance.boyfriend), shit);
                    }
                }
			}
		});

        Lua_helper.add_callback(lua, "setGraphicSize", function(obj:String, x:Int, y:Int = 0, updateHitbox:Bool = true) {
			if(game.getLuaObject(obj)!=null) {
				var shit:FlxSprite = game.getLuaObject(obj);
				shit.setGraphicSize(x, y);
				if(updateHitbox) shit.updateHitbox();
				return;
			}

			var split:Array<String> = obj.split('.');
			var poop:FlxSprite = Globals.getObjectDirectly(split[0]);
			if(split.length > 1) {
				poop = Globals.getVarInArray(Globals.getPropertyLoop(split), split[split.length-1]);
			}

			if(poop != null) {
				poop.setGraphicSize(x, y);
				if(updateHitbox) poop.updateHitbox();
				return;
			}
			FunkinLua.luaTrace('setGraphicSize: Couldnt find object: ' + obj, false, false, FlxColor.RED);
		});

        Lua_helper.add_callback(lua, "scaleObject", function(obj:String, x:Float, y:Float, updateHitbox:Bool = true) {
			if(game.getLuaObject(obj)!=null) {
				var shit:FlxSprite = game.getLuaObject(obj);
				shit.scale.set(x, y);
				if(updateHitbox) shit.updateHitbox();
				return;
			}

			var split:Array<String> = obj.split('.');
			var poop:FlxSprite = Globals.getObjectDirectly(split[0]);
			if(split.length > 1) {
				poop = Globals.getVarInArray(Globals.getPropertyLoop(split), split[split.length-1]);
			}

			if(poop != null) {
				poop.scale.set(x, y);
				if(updateHitbox) poop.updateHitbox();
				return;
			}
			FunkinLua.luaTrace('scaleObject: Couldnt find object: ' + obj, false, false, FlxColor.RED);
		});

        Lua_helper.add_callback(lua, "updateHitbox", function(obj:String) {
			if(game.getLuaObject(obj)!=null) {
				var shit:FlxSprite = game.getLuaObject(obj);
				shit.updateHitbox();
				return;
			}

			var poop:FlxSprite = Reflect.getProperty(Globals.getTargetInstance(), obj);
			if(poop != null) {
				poop.updateHitbox();
				return;
			}
			FunkinLua.luaTrace('updateHitbox: Couldnt find object: ' + obj, false, false, FlxColor.RED);
		});

		Lua_helper.add_callback(lua, "updateHitboxFromGroup", function(group:String, index:Int) {
			if(Std.isOfType(Reflect.getProperty(Globals.getTargetInstance(), group), FlxTypedGroup)) {
				Reflect.getProperty(Globals.getTargetInstance(), group).members[index].updateHitbox();
				return;
			}
			Reflect.getProperty(Globals.getTargetInstance(), group)[index].updateHitbox();
		});

        Lua_helper.add_callback(lua, "removeLuaSprite", function(tag:String, destroy:Bool = true) {
			if(!game.modchartSprites.exists(tag)) {
				return;
			}

			var pee:ModchartSprite = game.modchartSprites.get(tag);
			if(destroy) {
				pee.kill();
			}

			Globals.getTargetInstance().remove(pee, true);
			if(destroy) {
				pee.destroy();
				game.modchartSprites.remove(tag);
			}
		});

        Lua_helper.add_callback(lua, "luaSpriteExists", function(tag:String) {
			return game.modchartSprites.exists(tag);
		});

        Lua_helper.add_callback(lua, "setObjectCamera", function(obj:String, camera:String = '') {
			var real = game.getLuaObject(obj);
			if(real != null) {
				real.cameras = [Globals.cameraFromString(camera)];
				return true;
			}

			var split:Array<String> = obj.split('.');
			var spr:FlxSprite = Globals.getObjectDirectly(split[0]);
			if(split.length > 1) {
				spr = Globals.getVarInArray(Globals.getPropertyLoop(split), split[split.length-1]);
			}

			if(spr != null) {
				spr.cameras = [Globals.cameraFromString(camera)];
				return true;
			}
			FunkinLua.luaTrace("setObjectCamera: Object " + obj + " doesn't exist!", false, false, FlxColor.RED);
			return false;
		});

        Lua_helper.add_callback(lua, "setBlendMode", function(obj:String, blend:String = '') {
			var real = game.getLuaObject(obj);
			if(real != null) {
				real.blend = Globals.blendModeFromString(blend);
				return true;
			}

			var split:Array<String> = obj.split('.');
			var spr:FlxSprite = Globals.getObjectDirectly(split[0]);
			if(split.length > 1) {
				spr = Globals.getVarInArray(Globals.getPropertyLoop(split), split[split.length-1]);
			}

			if(spr != null) {
				spr.blend = Globals.blendModeFromString(blend);
				return true;
			}
			FunkinLua.luaTrace("setBlendMode: Object " + obj + " doesn't exist!", false, false, FlxColor.RED);
			return false;
		});

		Lua_helper.add_callback(lua, "screenCenter", function(obj:String, pos:String = 'xy') {
			var spr:FlxSprite = game.getLuaObject(obj);

			if(spr==null){
				var split:Array<String> = obj.split('.');
				spr = Globals.getObjectDirectly(split[0]);
				if(split.length > 1) {
					spr = Globals.getVarInArray(Globals.getPropertyLoop(split), split[split.length-1]);
				}
			}

			if(spr != null)
			{
				switch(pos.trim().toLowerCase())
				{
					case 'x':
						spr.screenCenter(X);
						return;
					case 'y':
						spr.screenCenter(Y);
						return;
					default:
						spr.screenCenter(XY);
						return;
				}
			}
			FunkinLua.luaTrace("screenCenter: Object " + obj + " doesn't exist!", false, false, FlxColor.RED);
		});

        Lua_helper.add_callback(lua, "objectsOverlap", function(obj1:String, obj2:String) {
			var namesArray:Array<String> = [obj1, obj2];
			var objectsArray:Array<FlxSprite> = [];
			for (i in 0...namesArray.length)
			{
				var real = game.getLuaObject(namesArray[i]);
				if(real!=null) {
					objectsArray.push(real);
				} else {
					objectsArray.push(Reflect.getProperty(Globals.getTargetInstance(), namesArray[i]));
				}
			}

			if(!objectsArray.contains(null) && FlxG.overlap(objectsArray[0], objectsArray[1]))
			{
				return true;
			}
			return false;
		});
        
		Lua_helper.add_callback(lua, "getPixelColor", function(obj:String, x:Int, y:Int) {
			var split:Array<String> = obj.split('.');
			var spr:FlxSprite = Globals.getObjectDirectly(split[0]);
			if(split.length > 1) {
				spr = Globals.getVarInArray(Globals.getPropertyLoop(split), split[split.length-1]);
			}

			if(spr != null) return spr.pixels.getPixel32(x, y);
			return FlxColor.BLACK;
		});
    }

    public static function soundFunction(funk:FunkinLua)
    {
        var lua = funk.lua;
        var game = PlayState.instance;
        Lua_helper.add_callback(lua, "playMusic", function(sound:String, volume:Float = 1, loop:Bool = false) {
			FlxG.sound.playMusic(Paths.music(sound), volume, loop);
		});

		Lua_helper.add_callback(lua, "playSound", function(sound:String, volume:Float = 1, ?tag:String = null) {
			if(tag != null && tag.length > 0) {
				tag = tag.replace('.', '');
				if(game.modchartSounds.exists(tag)) {
					game.modchartSounds.get(tag).stop();
				}
				game.modchartSounds.set(tag, FlxG.sound.play(Paths.sound(sound), volume, false, function() {
					game.modchartSounds.remove(tag);
					game.callOnLuas('onSoundFinished', [tag]);
				}));
				return;
			}
			FlxG.sound.play(Paths.sound(sound), volume);
		});

		Lua_helper.add_callback(lua, "stopSound", function(tag:String) {
			if(tag != null && tag.length > 1 && game.modchartSounds.exists(tag)) {
				game.modchartSounds.get(tag).stop();
				game.modchartSounds.remove(tag);
			}
		});

		Lua_helper.add_callback(lua, "pauseSound", function(tag:String) {
			if(tag != null && tag.length > 1 && game.modchartSounds.exists(tag)) {
				game.modchartSounds.get(tag).pause();
			}
		});

		Lua_helper.add_callback(lua, "resumeSound", function(tag:String) {
			if(tag != null && tag.length > 1 && game.modchartSounds.exists(tag)) {
				game.modchartSounds.get(tag).play();
			}
		});

		Lua_helper.add_callback(lua, "soundFadeIn", function(tag:String, duration:Float, fromValue:Float = 0, toValue:Float = 1) {
			if(tag == null || tag.length < 1) {
				FlxG.sound.music.fadeIn(duration, fromValue, toValue);
			} else if(game.modchartSounds.exists(tag)) {
				game.modchartSounds.get(tag).fadeIn(duration, fromValue, toValue);
			}

		});

		Lua_helper.add_callback(lua, "soundFadeOut", function(tag:String, duration:Float, toValue:Float = 0) {
			if(tag == null || tag.length < 1) {
				FlxG.sound.music.fadeOut(duration, toValue);
			} else if(game.modchartSounds.exists(tag)) {
				game.modchartSounds.get(tag).fadeOut(duration, toValue);
			}
		});

		Lua_helper.add_callback(lua, "soundFadeCancel", function(tag:String) {
			if(tag == null || tag.length < 1) {
				if(FlxG.sound.music.fadeTween != null) {
					FlxG.sound.music.fadeTween.cancel();
				}
			} else if(game.modchartSounds.exists(tag)) {
				var theSound:FlxSound = game.modchartSounds.get(tag);
				if(theSound.fadeTween != null) {
					theSound.fadeTween.cancel();
					game.modchartSounds.remove(tag);
				}
			}
		});

		Lua_helper.add_callback(lua, "getSoundVolume", function(tag:String) {
			if(tag == null || tag.length < 1) {
				if(FlxG.sound.music != null) {
					return FlxG.sound.music.volume;
				}
			} else if(game.modchartSounds.exists(tag)) {
				return game.modchartSounds.get(tag).volume;
			}
			return 0;
		});

		Lua_helper.add_callback(lua, "setSoundVolume", function(tag:String, value:Float) {
			if(tag == null || tag.length < 1) {
				if(FlxG.sound.music != null) {
					FlxG.sound.music.volume = value;
				}
			} else if(game.modchartSounds.exists(tag)) {
				game.modchartSounds.get(tag).volume = value;
			}
		});

		Lua_helper.add_callback(lua, "getSoundTime", function(tag:String) {
			if(tag != null && tag.length > 0 && game.modchartSounds.exists(tag)) {
				return game.modchartSounds.get(tag).time;
			}
			return 0;
		});

		Lua_helper.add_callback(lua, "setSoundTime", function(tag:String, value:Float) {
			if(tag != null && tag.length > 0 && game.modchartSounds.exists(tag)) {
				var theSound:FlxSound = game.modchartSounds.get(tag);
				if(theSound != null) {
					var wasResumed:Bool = theSound.playing;
					theSound.pause();
					theSound.time = value;
					if(wasResumed) theSound.play();
				}
			}
		});
    }

    public static function tweenFunction(funk:FunkinLua)
    {
        var lua = funk.lua;
		var game = PlayState.instance;
		var stage = Stage.instance;
        Lua_helper.add_callback(lua, "startTween", function(tag:String, vars:String, values:Any = null, duration:Float, options:Any = null) {
			var penisExam:Dynamic = Globals.tweenPrepare(tag, vars);
			if(penisExam != null) {
				if(values != null) {
					var myOptions:LuaTweenOptions = Globals.getLuaTween(options);
					game.modchartTweens.set(tag, FlxTween.tween(penisExam, values, duration, {
						type: myOptions.type,
						ease: myOptions.ease,
						startDelay: myOptions.startDelay,
						loopDelay: myOptions.loopDelay,

						onUpdate: function(twn:FlxTween) {
							if(myOptions.onUpdate != null) 
							{
								game.callOnLuas(myOptions.onUpdate, [tag, vars]);
								if(stage != null)
									stage.callOnLuas(myOptions.onUpdate, [tag, vars]);
							}
								
						},
						onStart: function(twn:FlxTween) {
							if(myOptions.onStart != null) 
							{
								game.callOnLuas(myOptions.onStart, [tag, vars]);
								if(stage != null)
									stage.callOnLuas(myOptions.onUpdate, [tag, vars]);
							}
								
							
						},
						onComplete: function(twn:FlxTween) {
							if(myOptions.onComplete != null)
							{
								game.callOnLuas(myOptions.onComplete, [tag, vars]);
								if(stage != null)
									stage.callOnLuas(myOptions.onUpdate, [tag, vars]);
							} 
							if(twn.type == FlxTweenType.ONESHOT || twn.type == FlxTweenType.BACKWARD) game.modchartTweens.remove(tag);
						}
					}));
				} else {
					FunkinLua.luaTrace('startTween: No values on 2nd argument!', false, false, FlxColor.RED);
				}
			} else {
				FunkinLua.luaTrace('startTween: Couldnt find object: ' + vars, false, false, FlxColor.RED);
			}
		});

        Lua_helper.add_callback(lua, "doTweenX", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String) {
			Globals.oldTweenFunction(tag, vars, {x: value}, duration, ease, 'doTweenX');
		});
		Lua_helper.add_callback(lua, "doTweenY", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String) {
			Globals.oldTweenFunction(tag, vars, {y: value}, duration, ease, 'doTweenY');
		});
		Lua_helper.add_callback(lua, "doTweenAngle", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String) {
			Globals.oldTweenFunction(tag, vars, {angle: value}, duration, ease, 'doTweenAngle');
		});
		Lua_helper.add_callback(lua, "doTweenAlpha", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String) {
			Globals.oldTweenFunction(tag, vars, {alpha: value}, duration, ease, 'doTweenAlpha');
		});
		Lua_helper.add_callback(lua, "doTweenZoom", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String) {
			Globals.oldTweenFunction(tag, vars, {zoom: value}, duration, ease, 'doTweenZoom');
		});

        Lua_helper.add_callback(lua, "doTweenColor", function(tag:String, vars:String, targetColor:String, duration:Float, ease:String) {
			var penisExam:Dynamic = Globals.tweenPrepare(tag, vars);
			if(penisExam != null) {
				var curColor:FlxColor = penisExam.color;
				curColor.alphaFloat = penisExam.alpha;
				game.modchartTweens.set(tag, FlxTween.color(penisExam, duration, curColor, CoolUtil.colorFromString(targetColor), {ease: Globals.getTweenEaseByString(ease),
					onComplete: function(twn:FlxTween) {
						game.modchartTweens.remove(tag);
						game.callOnLuas('onTweenCompleted', [tag, vars]);
						if(stage != null)
							stage.callOnLuas('onTweenCompleted', [tag, vars]);
					}
				}));
			} else {
				FunkinLua.luaTrace('doTweenColor: Couldnt find object: ' + vars, false, false, FlxColor.RED);
			}
		});

        Lua_helper.add_callback(lua, "noteTweenX", function(tag:String, note:Int, value:Dynamic, duration:Float, ease:String) {
			Globals.cancelTween(tag);
			if(note < 0) note = 0;
			var testicle:StrumNote = game.strumLineNotes.members[note % game.strumLineNotes.length];

			if(testicle != null) {
				game.modchartTweens.set(tag, FlxTween.tween(testicle, {x: value}, duration, {ease: Globals.getTweenEaseByString(ease),
					onComplete: function(twn:FlxTween) {
						game.callOnLuas('onTweenCompleted', [tag]);
						if(stage != null)
							stage.callOnLuas('onTweenCompleted', [tag,]);
						game.modchartTweens.remove(tag);
					}
				}));
			}
		});

		Lua_helper.add_callback(lua, "noteTweenY", function(tag:String, note:Int, value:Dynamic, duration:Float, ease:String) {
			Globals.cancelTween(tag);
			if(note < 0) note = 0;
			var testicle:StrumNote = game.strumLineNotes.members[note % game.strumLineNotes.length];

			if(testicle != null) {
				game.modchartTweens.set(tag, FlxTween.tween(testicle, {y: value}, duration, {ease: Globals.getTweenEaseByString(ease),
					onComplete: function(twn:FlxTween) {
						game.callOnLuas('onTweenCompleted', [tag]);
						if(stage != null)
							stage.callOnLuas('onTweenCompleted', [tag]);
						game.modchartTweens.remove(tag);
					}
				}));
			}
		});

		Lua_helper.add_callback(lua, "noteTweenAngle", function(tag:String, note:Int, value:Dynamic, duration:Float, ease:String) {
			Globals.cancelTween(tag);
			if(note < 0) note = 0;
			var testicle:StrumNote = game.strumLineNotes.members[note % game.strumLineNotes.length];

			if(testicle != null) {
				game.modchartTweens.set(tag, FlxTween.tween(testicle, {angle: value}, duration, {ease: Globals.getTweenEaseByString(ease),
					onComplete: function(twn:FlxTween) {
						game.callOnLuas('onTweenCompleted', [tag]);
						if(stage != null)
							stage.callOnLuas('onTweenCompleted', [tag]);
						game.modchartTweens.remove(tag);
					}
				}));
			}
		});

		Lua_helper.add_callback(lua, "noteTweenAlpha", function(tag:String, note:Int, value:Dynamic, duration:Float, ease:String) {
			Globals.cancelTween(tag);
			if(note < 0) note = 0;
			var testicle:StrumNote = game.strumLineNotes.members[note % game.strumLineNotes.length];

			if(testicle != null) {
				game.modchartTweens.set(tag, FlxTween.tween(testicle, {alpha: value}, duration, {ease: Globals.getTweenEaseByString(ease),
					onComplete: function(twn:FlxTween) {
						game.callOnLuas('onTweenCompleted', [tag]);
						if(stage != null)
							stage.callOnLuas('onTweenCompleted', [tag]);
						game.modchartTweens.remove(tag);
					}
				}));
			}
		});
        
		Lua_helper.add_callback(lua, "noteTweenDirection", function(tag:String, note:Int, value:Dynamic, duration:Float, ease:String) {
			Globals.cancelTween(tag);
			if(note < 0) note = 0;
			var testicle:StrumNote = game.strumLineNotes.members[note % game.strumLineNotes.length];

			if(testicle != null) {
				game.modchartTweens.set(tag, FlxTween.tween(testicle, {direction: value}, duration, {ease: Globals.getTweenEaseByString(ease),
					onComplete: function(twn:FlxTween) {
						game.callOnLuas('onTweenCompleted', [tag]);
						if(stage != null)
							stage.callOnLuas('onTweenCompleted', [tag]);
						game.modchartTweens.remove(tag);
					}
				}));
			}
		});

        Lua_helper.add_callback(lua, "cancelTween", function(tag:String) {
			Globals.cancelTween(tag);
		});
    }

    public static function reflectionFunction(funk:FunkinLua, isStage:Bool)
    {
        var lua:State = funk.lua;
		var game = PlayState.instance;
		Lua_helper.add_callback(lua, "getProperty", function(variable:String, ?allowMaps:Bool = false) {
			var split:Array<String> = variable.split('.');
			if(split.length > 1)
				return Globals.getVarInArray(Globals.getPropertyLoop(split, true, true, allowMaps), split[split.length-1], allowMaps);
			return Globals.getVarInArray(Globals.getTargetInstance(), variable, allowMaps);
		});

		Lua_helper.add_callback(lua, "setProperty", function(variable:String, value:Dynamic, allowMaps:Bool = false) {
			var split:Array<String> = variable.split('.');
			if(split.length > 1) {
				Globals.setVarInArray(Globals.getPropertyLoop(split, true, true, allowMaps), split[split.length-1], value, allowMaps);
				return true;
			}
			Globals.setVarInArray(Globals.getTargetInstance(), variable, value, allowMaps);
			return true;
		});

		Lua_helper.add_callback(lua, "getPropertyFromClass", function(classVar:String, variable:String, ?allowMaps:Bool = false) {
			var myClass:Dynamic = Type.resolveClass(classVar);
			if(myClass == null)
			{
				FunkinLua.luaTrace('getPropertyFromClass: Class $classVar not found', false, false, FlxColor.RED);
				return null;
			}

			var split:Array<String> = variable.split('.');
			if(split.length > 1) {
				var obj:Dynamic = Globals.getVarInArray(myClass, split[0], allowMaps);
				for (i in 1...split.length-1)
					obj = Globals.getVarInArray(obj, split[i], allowMaps);

				return Globals.getVarInArray(obj, split[split.length-1], allowMaps);
			}
			return Globals.getVarInArray(myClass, variable, allowMaps);
		});

		Lua_helper.add_callback(lua, "setPropertyFromClass", function(classVar:String, variable:String, value:Dynamic, ?allowMaps:Bool = false) {
			var myClass:Dynamic = Type.resolveClass(classVar);
			if(myClass == null)
			{
				FunkinLua.luaTrace('getPropertyFromClass: Class $classVar not found', false, false, FlxColor.RED);
				return null;
			}

			var split:Array<String> = variable.split('.');
			if(split.length > 1) {
				var obj:Dynamic = Globals.getVarInArray(myClass, split[0], allowMaps);
				for (i in 1...split.length-1)
					obj = Globals.getVarInArray(obj, split[i], allowMaps);

				Globals.setVarInArray(obj, split[split.length-1], value, allowMaps);
				return value;
			}
			Globals.setVarInArray(myClass, variable, value, allowMaps);
			return value;
		});

		Lua_helper.add_callback(lua, "getPropertyFromGroup", function(obj:String, index:Int, variable:Dynamic, ?allowMaps:Bool = false) {
			var split:Array<String> = obj.split('.');
			var realObject:Dynamic = null;
			if(split.length > 1)
				realObject = Globals.getPropertyLoop(split, true, false, allowMaps);
			else
				realObject = Reflect.getProperty(Globals.getTargetInstance(), obj);

			if(Std.isOfType(realObject, FlxTypedGroup))
			{
				var result:Dynamic = Globals.getGroupStuff(realObject.members[index], variable, allowMaps);
				return result;
			}

			var leArray:Dynamic = realObject[index];
			if(leArray != null) {
				var result:Dynamic = null;
				if(Type.typeof(variable) == ValueType.TInt)
					result = leArray[variable];
				else
					result = Globals.getGroupStuff(leArray, variable, allowMaps);
				return result;
			}
			FunkinLua.luaTrace("getPropertyFromGroup: Object #" + index + " from group: " + obj + " doesn't exist!", false, false, FlxColor.RED);
			return null;
		});

		Lua_helper.add_callback(lua, "setPropertyFromGroup", function(obj:String, index:Int, variable:Dynamic, value:Dynamic, ?allowMaps:Bool = false) {
			var split:Array<String> = obj.split('.');
			var realObject:Dynamic = null;
			if(split.length > 1)
				realObject = Globals.getPropertyLoop(split, true, false, allowMaps);
			else
				realObject = Reflect.getProperty(Globals.getTargetInstance(), obj);

			if(Std.isOfType(realObject, FlxTypedGroup)) {
				Globals.setGroupStuff(realObject.members[index], variable, value, allowMaps);
				return value;
			}

			var leArray:Dynamic = realObject[index];
			if(leArray != null) {
				if(Type.typeof(variable) == ValueType.TInt) {
					leArray[variable] = value;
					return value;
				}
				Globals.setGroupStuff(leArray, variable, value, allowMaps);
			}
			return value;
		});

		Lua_helper.add_callback(lua, "removeFromGroup", function(obj:String, index:Int, dontDestroy:Bool = false) {
			var groupOrArray:Dynamic = Reflect.getProperty(Globals.getTargetInstance(), obj);
			if(Std.isOfType(groupOrArray, FlxTypedGroup)) {
				var sex = groupOrArray.members[index];
				if(!dontDestroy)
					sex.kill();
				groupOrArray.remove(sex, true);
				if(!dontDestroy)
					sex.destroy();
				return;
			}
			groupOrArray.remove(groupOrArray[index]);
		});
		
		Lua_helper.add_callback(lua, "callMethod", function(funcToRun:String, ?args:Array<Dynamic> = null) {
			return Globals.callMethodFromObject(game, funcToRun, args);
			
		});

		Lua_helper.add_callback(lua, "callMethodFromClass", function(className:String, funcToRun:String, ?args:Array<Dynamic> = null) {
			return Globals.callMethodFromObject(Type.resolveClass(className), funcToRun, args);
		});

		Lua_helper.add_callback(lua, "createInstance", function(variableToSave:String, className:String, ?args:Array<Dynamic> = null) {
			variableToSave = variableToSave.trim().replace('.', '');
			if(!game.variables.exists(variableToSave))
			{
				if(args == null) args = [];
				var myType:Dynamic = Type.resolveClass(className);
		
				if(myType == null)
				{
					FunkinLua.luaTrace('createInstance: Variable $variableToSave is already being used and cannot be replaced!', false, false, FlxColor.RED);
					return false;
				}

				var obj:Dynamic = Type.createInstance(myType, args);
				if(obj != null)
					game.variables.set(variableToSave, obj);
				else
					FunkinLua.luaTrace('createInstance: Failed to create $variableToSave, arguments are possibly wrong.', false, false, FlxColor.RED);

				return (obj != null);
			}
			else FunkinLua.luaTrace('createInstance: Variable $variableToSave is already being used and cannot be replaced!', false, false, FlxColor.RED);
			return false;
		});

		Lua_helper.add_callback(lua, "addInstance", function(objectName:String, ?inFront:Bool = false, ?layersName:String = 'boyfriend') {
			if(game.variables.exists(objectName))
			{
				var obj:Dynamic = game.variables.get(objectName);

				if(isStage)
				{
					if(inFront)
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
				else
				{
					
					if (inFront)
						Globals.getTargetInstance().add(obj);
					else
					{
						if(!game.isDead)
							game.insert(game.members.indexOf(Globals.getLowestCharacterGroup()), obj);
						else
							GameOverSubstate.instance.insert(GameOverSubstate.instance.members.indexOf(GameOverSubstate.instance.boyfriend), obj);
					}
				}

			}
			else FunkinLua.luaTrace('addInstance: Can\'t add what doesn\'t exist~ ($objectName)', false, false, FlxColor.RED);
		});
    }

    public static function shaderFunction(funk:FunkinLua)
    {
		var lua = funk.lua;
		// shader shit
		funk.addLocalCallback("initLuaShader", function(name:String, ?glslVersion:Int = 120) {
			if(!ClientPrefs.shaders) return false;

			#if (!flash && MODS_ALLOWED && sys)
			return funk.initLuaShader(name, glslVersion);
			#else
			FunkinLua.luaTrace("initLuaShader: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			#end
			return false;
		});
		
		funk.addLocalCallback("setSpriteShader", function(obj:String, shader:String) {
			if(!ClientPrefs.shaders) return false;

			#if (!flash && MODS_ALLOWED && sys)
			if(!funk.runtimeShaders.exists(shader) && !funk.initLuaShader(shader))
			{
				FunkinLua.luaTrace('setSpriteShader: Shader $shader is missing!', false, false, FlxColor.RED);
				return false;
			}

			var split:Array<String> = obj.split('.');
			var leObj:FlxSprite = Globals.getObjectDirectly(split[0]);
			if(split.length > 1) {
				leObj = Globals.getVarInArray(Globals.getPropertyLoop(split), split[split.length-1]);
			}

			if(leObj != null) {
				var arr:Array<String> = funk.runtimeShaders.get(shader);
				leObj.shader = new FlxRuntimeShader(arr[0], arr[1]);
				return true;
			}
			#else
			FunkinLua.luaTrace("setSpriteShader: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			#end
			return false;
		});
		Lua_helper.add_callback(lua, "removeSpriteShader", function(obj:String) {
			var split:Array<String> = obj.split('.');
			var leObj:FlxSprite = Globals.getObjectDirectly(split[0]);
			if(split.length > 1) {
				leObj = Globals.getVarInArray(Globals.getPropertyLoop(split), split[split.length-1]);
			}

			if(leObj != null) {
				leObj.shader = null;
				return true;
			}
			return false;
		});


		Lua_helper.add_callback(lua, "getShaderBool", function(obj:String, prop:String) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = Globals.getShader(obj);
			if (shader == null)
			{
				FunkinLua.luaTrace("getShaderBool: Shader is not FlxRuntimeShader!", false, false, FlxColor.RED);
				return null;
			}
			return shader.getBool(prop);
			#else
			FunkinLua.luaTrace("getShaderBool: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return null;
			#end
		});
		Lua_helper.add_callback(lua, "getShaderBoolArray", function(obj:String, prop:String) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = Globals.getShader(obj);
			if (shader == null)
			{
				FunkinLua.luaTrace("getShaderBoolArray: Shader is not FlxRuntimeShader!", false, false, FlxColor.RED);
				return null;
			}
			return shader.getBoolArray(prop);
			#else
			FunkinLua.luaTrace("getShaderBoolArray: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return null;
			#end
		});
		Lua_helper.add_callback(lua, "getShaderInt", function(obj:String, prop:String) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = Globals.getShader(obj);
			if (shader == null)
			{
				FunkinLua.luaTrace("getShaderInt: Shader is not FlxRuntimeShader!", false, false, FlxColor.RED);
				return null;
			}
			return shader.getInt(prop);
			#else
			FunkinLua.luaTrace("getShaderInt: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return null;
			#end
		});
		Lua_helper.add_callback(lua, "getShaderIntArray", function(obj:String, prop:String) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = Globals.getShader(obj);
			if (shader == null)
			{
				FunkinLua.luaTrace("getShaderIntArray: Shader is not FlxRuntimeShader!", false, false, FlxColor.RED);
				return null;
			}
			return shader.getIntArray(prop);
			#else
			FunkinLua.luaTrace("getShaderIntArray: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return null;
			#end
		});
		Lua_helper.add_callback(lua, "getShaderFloat", function(obj:String, prop:String) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = Globals.getShader(obj);
			if (shader == null)
			{
				FunkinLua.luaTrace("getShaderFloat: Shader is not FlxRuntimeShader!", false, false, FlxColor.RED);
				return null;
			}
			return shader.getFloat(prop);
			#else
			FunkinLua.luaTrace("getShaderFloat: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return null;
			#end
		});
		Lua_helper.add_callback(lua, "getShaderFloatArray", function(obj:String, prop:String) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = Globals.getShader(obj);
			if (shader == null)
			{
				FunkinLua.luaTrace("getShaderFloatArray: Shader is not FlxRuntimeShader!", false, false, FlxColor.RED);
				return null;
			}
			return shader.getFloatArray(prop);
			#else
			FunkinLua.luaTrace("getShaderFloatArray: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return null;
			#end
		});


		Lua_helper.add_callback(lua, "setShaderBool", function(obj:String, prop:String, value:Bool) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = Globals.getShader(obj);
			if(shader == null)
			{
				FunkinLua.luaTrace("setShaderBool: Shader is not FlxRuntimeShader!", false, false, FlxColor.RED);
				return false;
			}
			shader.setBool(prop, value);
			return true;
			#else
			FunkinLua.luaTrace("setShaderBool: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return false;
			#end
		});
		Lua_helper.add_callback(lua, "setShaderBoolArray", function(obj:String, prop:String, values:Dynamic) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = Globals.getShader(obj);
			if(shader == null)
			{
				FunkinLua.luaTrace("setShaderBoolArray: Shader is not FlxRuntimeShader!", false, false, FlxColor.RED);
				return false;
			}
			shader.setBoolArray(prop, values);
			return true;
			#else
			FunkinLua.luaTrace("setShaderBoolArray: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return false;
			#end
		});
		Lua_helper.add_callback(lua, "setShaderInt", function(obj:String, prop:String, value:Int) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = Globals.getShader(obj);
			if(shader == null)
			{
				FunkinLua.luaTrace("setShaderInt: Shader is not FlxRuntimeShader!", false, false, FlxColor.RED);
				return false;
			}
			shader.setInt(prop, value);
			return true;
			#else
			FunkinLua.luaTrace("setShaderInt: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return false;
			#end
		});
		Lua_helper.add_callback(lua, "setShaderIntArray", function(obj:String, prop:String, values:Dynamic) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = Globals.getShader(obj);
			if(shader == null)
			{
				FunkinLua.luaTrace("setShaderIntArray: Shader is not FlxRuntimeShader!", false, false, FlxColor.RED);
				return false;
			}
			shader.setIntArray(prop, values);
			return true;
			#else
			FunkinLua.luaTrace("setShaderIntArray: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return false;
			#end
		});
		Lua_helper.add_callback(lua, "setShaderFloat", function(obj:String, prop:String, value:Float) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = Globals.getShader(obj);
			if(shader == null)
			{
				FunkinLua.luaTrace("setShaderFloat: Shader is not FlxRuntimeShader!", false, false, FlxColor.RED);
				return false;
			}
			shader.setFloat(prop, value);
			return true;
			#else
			FunkinLua.luaTrace("setShaderFloat: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return false;
			#end
		});
		Lua_helper.add_callback(lua, "setShaderFloatArray", function(obj:String, prop:String, values:Dynamic) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = Globals.getShader(obj);
			if(shader == null)
			{
				FunkinLua.luaTrace("setShaderFloatArray: Shader is not FlxRuntimeShader!", false, false, FlxColor.RED);
				return false;
			}

			shader.setFloatArray(prop, values);
			return true;
			#else
			FunkinLua.luaTrace("setShaderFloatArray: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return true;
			#end
		});

		Lua_helper.add_callback(lua, "setShaderSampler2D", function(obj:String, prop:String, bitmapdataPath:String) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = Globals.getShader(obj);
			if(shader == null)
			{
				FunkinLua.luaTrace("setShaderSampler2D: Shader is not FlxRuntimeShader!", false, false, FlxColor.RED);
				return false;
			}

			// trace('bitmapdatapath: $bitmapdataPath');
			var value = Paths.image(bitmapdataPath);
			if(value != null && value.bitmap != null)
			{
				// trace('Found bitmapdata. Width: ${value.bitmap.width} Height: ${value.bitmap.height}');
				shader.setSampler2D(prop, value.bitmap);
				return true;
			}
			return false;
			#else
			FunkinLua.luaTrace("setShaderSampler2D: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return false;
			#end
		});
    }

    public static function textFunctions(funk:FunkinLua)
    {
		var lua = funk.lua;
		var game:PlayState = PlayState.instance;
		Lua_helper.add_callback(lua, "makeLuaText", function(tag:String, text:String, width:Int, x:Float, y:Float) {
			tag = tag.replace('.', '');
			Globals.resetTextTag(tag);
			var leText:FlxText = new FlxText(x, y, width, text, 16);
			leText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			leText.cameras = [game.camHUD];
			leText.scrollFactor.set();
			leText.borderSize = 2;
			game.modchartTexts.set(tag, leText);
		});

		Lua_helper.add_callback(lua, "setTextString", function(tag:String, text:String) {
			var obj:FlxText = Globals.getTextObject(tag);
			if(obj != null)
			{
				obj.text = text;
				return true;
			}
			FunkinLua.luaTrace("setTextString: Object " + tag + " doesn't exist!", false, false, FlxColor.RED);
			return false;
		});
		Lua_helper.add_callback(lua, "setTextSize", function(tag:String, size:Int) {
			var obj:FlxText = Globals.getTextObject(tag);
			if(obj != null)
			{
				obj.size = size;
				return true;
			}
			FunkinLua.luaTrace("setTextSize: Object " + tag + " doesn't exist!", false, false, FlxColor.RED);
			return false;
		});
		Lua_helper.add_callback(lua, "setTextWidth", function(tag:String, width:Float) {
			var obj:FlxText = Globals.getTextObject(tag);
			if(obj != null)
			{
				obj.fieldWidth = width;
				return true;
			}
			FunkinLua.luaTrace("setTextWidth: Object " + tag + " doesn't exist!", false, false, FlxColor.RED);
			return false;
		});
		Lua_helper.add_callback(lua, "setTextBorder", function(tag:String, size:Int, color:String) {
			var obj:FlxText = Globals.getTextObject(tag);
			if(obj != null)
			{
				if(size > 0)
				{
					obj.borderStyle = OUTLINE;
					obj.borderSize = size;
				}
				else
					obj.borderStyle = NONE;
				obj.borderColor = CoolUtil.colorFromString(color);
				return true;
			}
			FunkinLua.luaTrace("setTextBorder: Object " + tag + " doesn't exist!", false, false, FlxColor.RED);
			return false;
		});
		Lua_helper.add_callback(lua, "setTextColor", function(tag:String, color:String) {
			var obj:FlxText = Globals.getTextObject(tag);
			if(obj != null)
			{
				obj.color = CoolUtil.colorFromString(color);
				return true;
			}
			FunkinLua.luaTrace("setTextColor: Object " + tag + " doesn't exist!", false, false, FlxColor.RED);
			return false;
		});
		Lua_helper.add_callback(lua, "setTextFont", function(tag:String, newFont:String) {
			var obj:FlxText = Globals.getTextObject(tag);
			if(obj != null)
			{
				obj.font = Paths.font(newFont);
				return true;
			}
			FunkinLua.luaTrace("setTextFont: Object " + tag + " doesn't exist!", false, false, FlxColor.RED);
			return false;
		});
		Lua_helper.add_callback(lua, "setTextItalic", function(tag:String, italic:Bool) {
			var obj:FlxText = Globals.getTextObject(tag);
			if(obj != null)
			{
				obj.italic = italic;
				return true;
			}
			FunkinLua.luaTrace("setTextItalic: Object " + tag + " doesn't exist!", false, false, FlxColor.RED);
			return false;
		});
		Lua_helper.add_callback(lua, "setTextAlignment", function(tag:String, alignment:String = 'left') {
			var obj:FlxText = Globals.getTextObject(tag);
			if(obj != null)
			{
				obj.alignment = LEFT;
				switch(alignment.trim().toLowerCase())
				{
					case 'right':
						obj.alignment = RIGHT;
					case 'center':
						obj.alignment = CENTER;
				}
				return true;
			}
			FunkinLua.luaTrace("setTextAlignment: Object " + tag + " doesn't exist!", false, false, FlxColor.RED);
			return false;
		});

		Lua_helper.add_callback(lua, "getTextString", function(tag:String) {
			var obj:FlxText = Globals.getTextObject(tag);
			if(obj != null && obj.text != null)
			{
				return obj.text;
			}
			FunkinLua.luaTrace("getTextString: Object " + tag + " doesn't exist!", false, false, FlxColor.RED);
			return null;
		});
		Lua_helper.add_callback(lua, "getTextSize", function(tag:String) {
			var obj:FlxText = Globals.getTextObject(tag);
			if(obj != null)
			{
				return obj.size;
			}
			FunkinLua.luaTrace("getTextSize: Object " + tag + " doesn't exist!", false, false, FlxColor.RED);
			return -1;
		});
		Lua_helper.add_callback(lua, "getTextFont", function(tag:String) {
			var obj:FlxText = Globals.getTextObject(tag);
			if(obj != null)
			{
				return obj.font;
			}
			FunkinLua.luaTrace("getTextFont: Object " + tag + " doesn't exist!", false, false, FlxColor.RED);
			return null;
		});
		Lua_helper.add_callback(lua, "getTextWidth", function(tag:String) {
			var obj:FlxText = Globals.getTextObject(tag);
			if(obj != null)
			{
				return obj.fieldWidth;
			}
			FunkinLua.luaTrace("getTextWidth: Object " + tag + " doesn't exist!", false, false, FlxColor.RED);
			return 0;
		});

		Lua_helper.add_callback(lua, "addLuaText", function(tag:String) {
			if(game.modchartTexts.exists(tag)) {
				var shit:FlxText = game.modchartTexts.get(tag);
				Globals.getTargetInstance().add(shit);
			}
		});
		Lua_helper.add_callback(lua, "removeLuaText", function(tag:String, destroy:Bool = true) {
			if(!game.modchartTexts.exists(tag)) {
				return;
			}

			var pee:FlxText = game.modchartTexts.get(tag);
			if(destroy) {
				pee.kill();
			}

			Globals.getTargetInstance().remove(pee, true);
			if(destroy) {
				pee.destroy();
				game.modchartTexts.remove(tag);
			}
		});        
    }

    public static function characterFunctions(funk:FunkinLua, isStage:Bool)
    {
        var lua = funk.lua;
		var game:PlayState = PlayState.instance;
        Lua_helper.add_callback(lua, "addCharacterToList", function(name:String, type:String) {
			var charType:Int = 0;
			switch(type.toLowerCase()) {
				case 'dad': charType = 1;
				case 'gf' | 'girlfriend': charType = 2;
			}
			game.addCharacterToList(name, charType);
		});

        Lua_helper.add_callback(lua, "getCharacterX", function(type:String) {
			switch(type.toLowerCase()) {
				case 'dad' | 'opponent':
					return game.dadGroup.x;
				case 'gf' | 'girlfriend':
					return game.gfGroup.x;
				default:
					return game.boyfriendGroup.x;
			}
		});
		Lua_helper.add_callback(lua, "setCharacterX", function(type:String, value:Float) {
			switch(type.toLowerCase()) {
				case 'dad' | 'opponent':
					game.dadGroup.x = value;
				case 'gf' | 'girlfriend':
					game.gfGroup.x = value;
				default:
					game.boyfriendGroup.x = value;
			}
		});
        
		Lua_helper.add_callback(lua, "getCharacterY", function(type:String) {
			switch(type.toLowerCase()) {
				case 'dad' | 'opponent':
					return game.dadGroup.y;
				case 'gf' | 'girlfriend':
					return game.gfGroup.y;
				default:
					return game.boyfriendGroup.y;
			}
		});

		Lua_helper.add_callback(lua, "setCharacterY", function(type:String, value:Float) {
			switch(type.toLowerCase()) {
				case 'dad' | 'opponent':
					game.dadGroup.y = value;
				case 'gf' | 'girlfriend':
					game.gfGroup.y = value;
				default:
					game.boyfriendGroup.y = value;
			}
		});

        Lua_helper.add_callback(lua, "makeLuaCharacter", function(tag:String, char:String, ?isPlayer:Bool = false, x:Float, y:Float) {
			tag = tag.replace('.', '');
			Globals.resetCharacterTag(tag);
			Globals.resetGroupTag(tag + 'Group');
			var leGroup:ModchartGroup = new ModchartGroup(x, y);
			var leCharacter:ModchartCharacter = new ModchartCharacter(x, y, char, isPlayer);
			game.startCharacterPos(leCharacter, !isPlayer);
			game.startCharacterScripts(leCharacter.curCharacter);
            game.modchartCharacters.set(tag, leCharacter);
			game.modchartGroups.set(tag + 'Group', leGroup);
        });

        Lua_helper.add_callback(lua, "addLuaCharacter", function(tag:String, front:Bool = false, ?layersName:String = 'boyfriend') {
			if(game.modchartCharacters.exists(tag) && game.modchartGroups.exists(tag + 'Group')) {
				var shit:ModchartCharacter = game.modchartCharacters.get(tag);
				var shitGroup:ModchartGroup = game.modchartGroups.get(tag + 'Group');

                if(isStage)
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
                        Globals.getTargetInstance().add(shitGroup);
                    else
                    {
                        if(!game.isDead)
                            game.insert(game.members.indexOf(Globals.getLowestCharacterGroup()), shitGroup);
                        else
                            GameOverSubstate.instance.insert(GameOverSubstate.instance.members.indexOf(GameOverSubstate.instance.boyfriend), shitGroup);
                    }
                }

                shitGroup.add(shit);
			}
        });
    }

    public static function otherFunctions(funk:FunkinLua)
    {
        var lua = funk.lua;
		var game = PlayState.instance;
		var stage = Stage.instance;

		Lua_helper.add_callback(lua, "mouseClicked", function(button:String) {
			var click:Bool = FlxG.mouse.justPressed;
			switch(button){
				case 'middle':
					click = FlxG.mouse.justPressedMiddle;
				case 'right':
					click = FlxG.mouse.justPressedRight;
			}
			return click;
		});

		Lua_helper.add_callback(lua, "mousePressed", function(button:String) {
			var press:Bool = FlxG.mouse.pressed;
			switch(button){
				case 'middle':
					press = FlxG.mouse.pressedMiddle;
				case 'right':
					press = FlxG.mouse.pressedRight;
			}
			return press;
		});

		Lua_helper.add_callback(lua, "mouseReleased", function(button:String) {
			var released:Bool = FlxG.mouse.justReleased;
			switch(button){
				case 'middle':
					released = FlxG.mouse.justReleasedMiddle;
				case 'right':
					released = FlxG.mouse.justReleasedRight;
			}
			return released;
		});

        Lua_helper.add_callback(lua, "runTimer", function(tag:String, time:Float = 1, loops:Int = 1) {
			Globals.cancelTimer(tag);
			game.modchartTimers.set(tag, new FlxTimer().start(time, function(tmr:FlxTimer) {
				if(tmr.finished) {
					game.modchartTimers.remove(tag);
				}
				game.callOnLuas('onTimerCompleted', [tag, tmr.loops, tmr.loopsLeft]);
				if(stage != null)
					stage.callOnLuas('onTimerCompleted', [tag, tmr.loops, tmr.loopsLeft]);
				
				//trace('Timer Completed: ' + tag);
			}, loops));
		});

		Lua_helper.add_callback(lua, "cancelTimer", function(tag:String) {
			Globals.cancelTimer(tag);
		});

        Lua_helper.add_callback(lua, "addScore", function(value:Int = 0) {
			game.songScore += value;
			game.RecalculateRating();
		});
		Lua_helper.add_callback(lua, "addMisses", function(value:Int = 0) {
			game.songMisses += value;
			game.RecalculateRating();
		});
		Lua_helper.add_callback(lua, "addHits", function(value:Int = 0) {
			game.songHits += value;
			game.RecalculateRating();
		});
		Lua_helper.add_callback(lua, "setScore", function(value:Int = 0) {
			game.songScore = value;
			game.RecalculateRating();
		});
		Lua_helper.add_callback(lua, "setMisses", function(value:Int = 0) {
			game.songMisses = value;
			game.RecalculateRating();
		});
		Lua_helper.add_callback(lua, "setHits", function(value:Int = 0) {
			game.songHits = value;
			game.RecalculateRating();
		});
		Lua_helper.add_callback(lua, "getScore", function() {
			return game.songScore;
		});
		Lua_helper.add_callback(lua, "getMisses", function() {
			return game.songMisses;
		});
		Lua_helper.add_callback(lua, "getHits", function() {
			return game.songHits;
		});

		Lua_helper.add_callback(lua, "setHealth", function(value:Float = 0) {
			game.health = value;
		});
		Lua_helper.add_callback(lua, "addHealth", function(value:Float = 0) {
			game.health += value;
		});
		Lua_helper.add_callback(lua, "getHealth", function() {
			return game.health;
		});

        Lua_helper.add_callback(lua, "FlxColor", function(color:String) return FlxColor.fromString(color));
		Lua_helper.add_callback(lua, "getColorFromName", function(color:String) return FlxColor.fromString(color));
		Lua_helper.add_callback(lua, "getColorFromString", function(color:String) return FlxColor.fromString(color));
		Lua_helper.add_callback(lua, "getColorFromHex", function(color:String) return FlxColor.fromString('#$color'));

        Lua_helper.add_callback(lua, "addCharacterToList", function(name:String, type:String) {
			var charType:Int = 0;
			switch(type.toLowerCase()) {
				case 'dad': charType = 1;
				case 'gf' | 'girlfriend': charType = 2;
			}
			game.addCharacterToList(name, charType);
		});
		Lua_helper.add_callback(lua, "precacheImage", function(name:String, ?allowGPU:Bool = true) {
			Paths.image(name, allowGPU);
		});
		Lua_helper.add_callback(lua, "precacheSound", function(name:String) {
			Paths.sound(name);
		});
		Lua_helper.add_callback(lua, "precacheMusic", function(name:String) {
			Paths.music(name);
		});

        Lua_helper.add_callback(lua, "triggerEvent", function(name:String, arg1:Dynamic, arg2:Dynamic) {
			var value1:String = arg1;
			var value2:String = arg2;
			game.triggerEventNote(name, value1, value2, Conductor.songPosition);
			//trace('Triggered event: ' + name + ', ' + value1 + ', ' + value2);
			return true;
		});

		Lua_helper.add_callback(lua, "startCountdown", function() {
			game.startCountdown();
			return true;
		});
		Lua_helper.add_callback(lua, "endSong", function() {
			game.KillNotes();
			game.endSong();
			return true;
		});
		Lua_helper.add_callback(lua, "restartSong", function(?skipTransition:Bool = false) {
			game.persistentUpdate = false;
			FlxG.camera.followLerp = 0;
			PauseSubState.restartSong(skipTransition);
			return true;
		});

        Lua_helper.add_callback(lua, "exitSong", function(?skipTransition:Bool = false) {
			if(skipTransition)
			{
				FlxTransitionableState.skipNextTransIn = true;
				FlxTransitionableState.skipNextTransOut = true;
			}

			PlayState.cancelMusicFadeTween();
			CustomFadeTransition.nextCamera = game.camOther;
			if(FlxTransitionableState.skipNextTransIn)
				CustomFadeTransition.nextCamera = null;

			if(PlayState.isStoryMode)
				MusicBeatState.switchState(new StoryMenuState());
			else if(PlayState.isBETADCIU)
				MusicBeatState.switchState(new BETADCIUState());
			else if(PlayState.isCover)
				MusicBeatState.switchState(new CoverState());
			else
				MusicBeatState.switchState(new FreeplayState());
			
			#if desktop DiscordClient.resetClientID(); #end

			FlxG.sound.playMusic(Paths.music('freakyMenu'));
			PlayState.changedDifficulty = false;
			PlayState.chartingMode = false;
			game.transitioning = true;
			FlxG.camera.followLerp = 0;
			Mods.loadTheFirstEnabledMod();
			return true;
		});
		Lua_helper.add_callback(lua, "getSongPosition", function() {
			return Conductor.songPosition;
		});

        Lua_helper.add_callback(lua, "cameraSetTarget", function(target:String) {
			var isDad:Bool = false;
			if(target == 'dad') {
				isDad = true;
			}
			game.moveCamera(isDad);
			return isDad;
		});
		Lua_helper.add_callback(lua, "cameraShake", function(camera:String, intensity:Float, duration:Float) {
			Globals.cameraFromString(camera).shake(intensity, duration);
		});

		Lua_helper.add_callback(lua, "cameraFlash", function(camera:String, color:String, duration:Float,forced:Bool) {
			Globals.cameraFromString(camera).flash(CoolUtil.colorFromString(color), duration, null,forced);
		});
		Lua_helper.add_callback(lua, "cameraFade", function(camera:String, color:String, duration:Float,forced:Bool) {
			Globals.cameraFromString(camera).fade(CoolUtil.colorFromString(color), duration, false,null,forced);
		});
		Lua_helper.add_callback(lua, "setRatingPercent", function(value:Float) {
			game.ratingPercent = value;
		});
		Lua_helper.add_callback(lua, "setRatingName", function(value:String) {
			game.ratingName = value;
		});
		Lua_helper.add_callback(lua, "setRatingFC", function(value:String) {
			game.ratingFC = value;
		});
		Lua_helper.add_callback(lua, "getMouseX", function(camera:String) {
			var cam:FlxCamera = Globals.cameraFromString(camera);
			return FlxG.mouse.getScreenPosition(cam).x;
		});
		Lua_helper.add_callback(lua, "getMouseY", function(camera:String) {
			var cam:FlxCamera = Globals.cameraFromString(camera);
			return FlxG.mouse.getScreenPosition(cam).y;
		});

        Lua_helper.add_callback(lua, "setHealthBarColors", function(leftHex:String, rightHex:String) {
			game.healthBar.createFilledBar(CoolUtil.colorFromString(leftHex), CoolUtil.colorFromString(rightHex));
			game.healthBar.updateBar();
		});
		Lua_helper.add_callback(lua, "setTimeBarColors", function(leftHex:String, rightHex:String) {
			game.timeBar.createFilledBar(CoolUtil.colorFromString(leftHex), CoolUtil.colorFromString(rightHex));
			game.timeBar.updateBar();
		});

        Lua_helper.add_callback(lua, "startDialogue", function(dialogueFile:String, music:String = null) {
			var path:String;
			#if MODS_ALLOWED
			path = Paths.modsJson(Paths.formatToSongPath(PlayState.SONG.song) + '/' + dialogueFile);
			if(!FileSystem.exists(path))
			#end
				path = Paths.json(Paths.formatToSongPath(PlayState.SONG.song) + '/' + dialogueFile);

            FunkinLua.luaTrace('startDialogue: Trying to load dialogue: ' + path);

			#if MODS_ALLOWED
			if(FileSystem.exists(path))
			#else
			if(Assets.exists(path))
			#end
			{
				var shit:DialogueFile = DialogueBoxPsych.parseDialogue(path);
				if(shit.dialogue.length > 0) {
					game.startDialogue(shit, music);
					FunkinLua.luaTrace('startDialogue: Successfully loaded dialogue', false, false, FlxColor.GREEN);
					return true;
				} else {
					FunkinLua.luaTrace('startDialogue: Your dialogue file is badly formatted!', false, false, FlxColor.RED);
				}
			} else {
				FunkinLua.luaTrace('startDialogue: Dialogue file not found', false, false, FlxColor.RED);
				if(game.endingSong) {
					game.endSong();
				} else {
					game.startCountdown();
				}
			}
			return false;
		});

        Lua_helper.add_callback(lua, "startVideo", function(videoFile:String) {
			#if VIDEOS_ALLOWED
			if(FileSystem.exists(Paths.video(videoFile))) {
				game.startVideo(videoFile);
				return true;
			} else {
				FunkinLua.luaTrace('startVideo: Video file not found: ' + videoFile, false, false, FlxColor.RED);
			}
			return false;

			#else
			if(game.endingSong) {
				game.endSong();
			} else {
				game.startCountdown();
			}
			return true;
			#end
		});

        Lua_helper.add_callback(lua, "keyboardJustPressed", function(name:String)
		{
			return Reflect.getProperty(FlxG.keys.justPressed, name);
		});
		Lua_helper.add_callback(lua, "keyboardPressed", function(name:String)
		{
			return Reflect.getProperty(FlxG.keys.pressed, name);
		});
		Lua_helper.add_callback(lua, "keyboardReleased", function(name:String)
		{
			return Reflect.getProperty(FlxG.keys.justReleased, name);
		});

		Lua_helper.add_callback(lua, "anyGamepadJustPressed", function(name:String)
		{
			return FlxG.gamepads.anyJustPressed(name);
		});
		Lua_helper.add_callback(lua, "anyGamepadPressed", function(name:String)
		{
			return FlxG.gamepads.anyPressed(name);
		});
		Lua_helper.add_callback(lua, "anyGamepadReleased", function(name:String)
		{
			return FlxG.gamepads.anyJustReleased(name);
		});

		Lua_helper.add_callback(lua, "gamepadAnalogX", function(id:Int, ?leftStick:Bool = true)
		{
			var controller = FlxG.gamepads.getByID(id);
			if (controller == null)
			{
				return 0.0;
			}
			return controller.getXAxis(leftStick ? LEFT_ANALOG_STICK : RIGHT_ANALOG_STICK);
		});
		Lua_helper.add_callback(lua, "gamepadAnalogY", function(id:Int, ?leftStick:Bool = true)
		{
			var controller = FlxG.gamepads.getByID(id);
			if (controller == null)
			{
				return 0.0;
			}
			return controller.getYAxis(leftStick ? LEFT_ANALOG_STICK : RIGHT_ANALOG_STICK);
		});
		Lua_helper.add_callback(lua, "gamepadJustPressed", function(id:Int, name:String)
		{
			var controller = FlxG.gamepads.getByID(id);
			if (controller == null)
			{
				return false;
			}
			return Reflect.getProperty(controller.justPressed, name) == true;
		});
		Lua_helper.add_callback(lua, "gamepadPressed", function(id:Int, name:String)
		{
			var controller = FlxG.gamepads.getByID(id);
			if (controller == null)
			{
				return false;
			}
			return Reflect.getProperty(controller.pressed, name) == true;
		});
		Lua_helper.add_callback(lua, "gamepadReleased", function(id:Int, name:String)
		{
			var controller = FlxG.gamepads.getByID(id);
			if (controller == null)
			{
				return false;
			}
			return Reflect.getProperty(controller.justReleased, name) == true;
		});

		Lua_helper.add_callback(lua, "keyJustPressed", function(name:String = '') {
			name = name.toLowerCase();
			switch(name) {
				case 'left': return game.controls.NOTE_LEFT_P;
				case 'down': return game.controls.NOTE_DOWN_P;
				case 'up': return game.controls.NOTE_UP_P;
				case 'right': return game.controls.NOTE_RIGHT_P;
				default: return game.controls.justPressed(name);
			}
			return false;
		});
		Lua_helper.add_callback(lua, "keyPressed", function(name:String = '') {
			name = name.toLowerCase();
			switch(name) {
				case 'left': return game.controls.NOTE_LEFT;
				case 'down': return game.controls.NOTE_DOWN;
				case 'up': return game.controls.NOTE_UP;
				case 'right': return game.controls.NOTE_RIGHT;
				default: return game.controls.pressed(name);
			}
			return false;
		});
		Lua_helper.add_callback(lua, "keyReleased", function(name:String = '') {
			name = name.toLowerCase();
			switch(name) {
				case 'left': return game.controls.NOTE_LEFT_R;
				case 'down': return game.controls.NOTE_DOWN_R;
				case 'up': return game.controls.NOTE_UP_R;
				case 'right': return game.controls.NOTE_RIGHT_R;
				default: return game.controls.justReleased(name);
			}
			return false;
		});

        Lua_helper.add_callback(lua, "initSaveData", function(name:String, ?folder:String = 'psychenginemods') {
			if(!game.modchartSaves.exists(name))
			{
				var save:FlxSave = new FlxSave();
				// folder goes unused for flixel 5 users. @BeastlyGhost
				save.bind(name, CoolUtil.getSavePath() + '/' + folder);
				game.modchartSaves.set(name, save);
				return;
			}
			FunkinLua.luaTrace('initSaveData: Save file already initialized: ' + name);
		});
		Lua_helper.add_callback(lua, "flushSaveData", function(name:String) {
			if(game.modchartSaves.exists(name))
			{
				game.modchartSaves.get(name).flush();
				return;
			}
			FunkinLua.luaTrace('flushSaveData: Save file not initialized: ' + name, false, false, FlxColor.RED);
		});
		Lua_helper.add_callback(lua, "getDataFromSave", function(name:String, field:String, ?defaultValue:Dynamic = null) {
			if(game.modchartSaves.exists(name))
			{
				var saveData = game.modchartSaves.get(name).data;
				if(Reflect.hasField(saveData, field))
					return Reflect.field(saveData, field);
				else
					return defaultValue;
			}
			FunkinLua.luaTrace('getDataFromSave: Save file not initialized: ' + name, false, false, FlxColor.RED);
			return defaultValue;
		});
		Lua_helper.add_callback(lua, "setDataFromSave", function(name:String, field:String, value:Dynamic) {
			if(game.modchartSaves.exists(name))
			{
				Reflect.setField(game.modchartSaves.get(name).data, field, value);
				return;
			}
			FunkinLua.luaTrace('setDataFromSave: Save file not initialized: ' + name, false, false, FlxColor.RED);
		});

		// File management
		Lua_helper.add_callback(lua, "checkFileExists", function(filename:String, ?absolute:Bool = false) {
			#if MODS_ALLOWED
			if(absolute)
			{
				return FileSystem.exists(filename);
			}

			var path:String = Paths.modFolders(filename);
			if(FileSystem.exists(path))
			{
				return true;
			}
			return FileSystem.exists(Paths.getPath('assets/$filename', TEXT));
			#else
			if(absolute)
			{
				return Assets.exists(filename);
			}
			return Assets.exists(Paths.getPath('assets/$filename', TEXT));
			#end
		});
		Lua_helper.add_callback(lua, "saveFile", function(path:String, content:String, ?absolute:Bool = false)
		{
			try {
				#if MODS_ALLOWED
				if(!absolute)
					File.saveContent(Paths.mods(path), content);
				else
				#end
					File.saveContent(path, content);

				return true;
			} catch (e:Dynamic) {
				FunkinLua.luaTrace("saveFile: Error trying to save " + path + ": " + e, false, false, FlxColor.RED);
			}
			return false;
		});
		Lua_helper.add_callback(lua, "deleteFile", function(path:String, ?ignoreModFolders:Bool = false)
		{
			try {
				#if MODS_ALLOWED
				if(!ignoreModFolders)
				{
					var lePath:String = Paths.modFolders(path);
					if(FileSystem.exists(lePath))
					{
						FileSystem.deleteFile(lePath);
						return true;
					}
				}
				#end

				var lePath:String = Paths.getPath(path, TEXT);
				if(Assets.exists(lePath))
				{
					FileSystem.deleteFile(lePath);
					return true;
				}
			} catch (e:Dynamic) {
				FunkinLua.luaTrace("deleteFile: Error trying to delete " + path + ": " + e, false, false, FlxColor.RED);
			}
			return false;
		});
		Lua_helper.add_callback(lua, "getTextFromFile", function(path:String, ?ignoreModFolders:Bool = false) {
			return Paths.getTextFromFile(path, ignoreModFolders);
		});
		Lua_helper.add_callback(lua, "directoryFileList", function(folder:String) {
			var list:Array<String> = [];
			#if sys
			if(FileSystem.exists(folder)) {
				for (folder in FileSystem.readDirectory(folder)) {
					if (!list.contains(folder)) {
						list.push(folder);
					}
				}
			}
			#end
			return list;
		});

		// String tools
		Lua_helper.add_callback(lua, "stringStartsWith", function(str:String, start:String) {
			return str.startsWith(start);
		});
		Lua_helper.add_callback(lua, "stringEndsWith", function(str:String, end:String) {
			return str.endsWith(end);
		});
		Lua_helper.add_callback(lua, "stringSplit", function(str:String, split:String) {
			return str.split(split);
		});
		Lua_helper.add_callback(lua, "stringTrim", function(str:String) {
			return str.trim();
		});

		// Randomization
		Lua_helper.add_callback(lua, "getRandomInt", function(min:Int, max:Int = FlxMath.MAX_VALUE_INT, exclude:String = '') {
			var excludeArray:Array<String> = exclude.split(',');
			var toExclude:Array<Int> = [];
			for (i in 0...excludeArray.length)
			{
				toExclude.push(Std.parseInt(excludeArray[i].trim()));
			}
			return FlxG.random.int(min, max, toExclude);
		});
		Lua_helper.add_callback(lua, "getRandomFloat", function(min:Float, max:Float = 1, exclude:String = '') {
			var excludeArray:Array<String> = exclude.split(',');
			var toExclude:Array<Float> = [];
			for (i in 0...excludeArray.length)
			{
				toExclude.push(Std.parseFloat(excludeArray[i].trim()));
			}
			return FlxG.random.float(min, max, toExclude);
		});
		Lua_helper.add_callback(lua, "getRandomBool", function(chance:Float = 50) {
			return FlxG.random.bool(chance);
		});
    }

	public static function deprecatedFunctions(funk:FunkinLua)
	{
		var game = PlayState.instance;
		var lua = funk.lua;
		// DEPRECATED, DONT MESS WITH THESE SHITS, ITS JUST THERE FOR BACKWARD COMPATIBILITY
		Lua_helper.add_callback(lua, "addAnimationByIndicesLoop", function(obj:String, name:String, prefix:String, indices:String, framerate:Int = 24) {
			FunkinLua.luaTrace("addAnimationByIndicesLoop is deprecated! Use addAnimationByIndices instead", false, true);
			return Globals.addAnimByIndices(obj, name, prefix, indices, framerate, true);
		});

		Lua_helper.add_callback(lua, "objectPlayAnimation", function(obj:String, name:String, forced:Bool = false, ?startFrame:Int = 0) {
			FunkinLua.luaTrace("objectPlayAnimation is deprecated! Use playAnim instead", false, true);
			if(game.getLuaObject(obj,false) != null) {
				game.getLuaObject(obj,false).animation.play(name, forced, false, startFrame);
				return true;
			}

			var spr:FlxSprite = Reflect.getProperty(Globals.getTargetInstance(), obj);
			if(spr != null) {
				spr.animation.play(name, forced, false, startFrame);
				return true;
			}
			return false;
		});
		Lua_helper.add_callback(lua, "characterPlayAnim", function(character:String, anim:String, ?forced:Bool = false) {
			FunkinLua.luaTrace("characterPlayAnim is deprecated! Use playAnim instead", false, true);
			switch(character.toLowerCase()) {
				case 'dad':
					if(game.dad.animOffsets.exists(anim))
						game.dad.playAnim(anim, forced);
				case 'gf' | 'girlfriend':
					if(game.gf != null && game.gf.animOffsets.exists(anim))
						game.gf.playAnim(anim, forced);
				default:
					if(game.boyfriend.animOffsets.exists(anim))
						game.boyfriend.playAnim(anim, forced);
			}
		});
		Lua_helper.add_callback(lua, "luaSpriteMakeGraphic", function(tag:String, width:Int, height:Int, color:String) {
			FunkinLua.luaTrace("luaSpriteMakeGraphic is deprecated! Use makeGraphic instead", false, true);
			if(game.modchartSprites.exists(tag))
				game.modchartSprites.get(tag).makeGraphic(width, height, CoolUtil.colorFromString(color));
		});
		Lua_helper.add_callback(lua, "luaSpriteAddAnimationByPrefix", function(tag:String, name:String, prefix:String, framerate:Int = 24, loop:Bool = true) {
			FunkinLua.luaTrace("luaSpriteAddAnimationByPrefix is deprecated! Use addAnimationByPrefix instead", false, true);
			if(game.modchartSprites.exists(tag)) {
				var cock:ModchartSprite = game.modchartSprites.get(tag);
				cock.animation.addByPrefix(name, prefix, framerate, loop);
				if(cock.animation.curAnim == null) {
					cock.animation.play(name, true);
				}
			}
		});
		Lua_helper.add_callback(lua, "luaSpriteAddAnimationByIndices", function(tag:String, name:String, prefix:String, indices:String, framerate:Int = 24) {
			FunkinLua.luaTrace("luaSpriteAddAnimationByIndices is deprecated! Use addAnimationByIndices instead", false, true);
			if(game.modchartSprites.exists(tag)) {
				var strIndices:Array<String> = indices.trim().split(',');
				var die:Array<Int> = [];
				for (i in 0...strIndices.length) {
					die.push(Std.parseInt(strIndices[i]));
				}
				var pussy:ModchartSprite = game.modchartSprites.get(tag);
				pussy.animation.addByIndices(name, prefix, die, '', framerate, false);
				if(pussy.animation.curAnim == null) {
					pussy.animation.play(name, true);
				}
			}
		});
		Lua_helper.add_callback(lua, "luaSpritePlayAnimation", function(tag:String, name:String, forced:Bool = false) {
			FunkinLua.luaTrace("luaSpritePlayAnimation is deprecated! Use playAnim instead", false, true);
			if(game.modchartSprites.exists(tag)) {
				game.modchartSprites.get(tag).animation.play(name, forced);
			}
		});
		Lua_helper.add_callback(lua, "setLuaSpriteCamera", function(tag:String, camera:String = '') {
			FunkinLua.luaTrace("setLuaSpriteCamera is deprecated! Use setObjectCamera instead", false, true);
			if(game.modchartSprites.exists(tag)) {
				game.modchartSprites.get(tag).cameras = [Globals.cameraFromString(camera)];
				return true;
			}
			FunkinLua.luaTrace("Lua sprite with tag: " + tag + " doesn't exist!");
			return false;
		});
		Lua_helper.add_callback(lua, "setLuaSpriteScrollFactor", function(tag:String, scrollX:Float, scrollY:Float) {
			FunkinLua.luaTrace("setLuaSpriteScrollFactor is deprecated! Use setScrollFactor instead", false, true);
			if(game.modchartSprites.exists(tag)) {
				game.modchartSprites.get(tag).scrollFactor.set(scrollX, scrollY);
				return true;
			}
			return false;
		});
		Lua_helper.add_callback(lua, "scaleLuaSprite", function(tag:String, x:Float, y:Float) {
			FunkinLua.luaTrace("scaleLuaSprite is deprecated! Use scaleObject instead", false, true);
			if(game.modchartSprites.exists(tag)) {
				var shit:ModchartSprite = game.modchartSprites.get(tag);
				shit.scale.set(x, y);
				shit.updateHitbox();
				return true;
			}
			return false;
		});
		Lua_helper.add_callback(lua, "getPropertyLuaSprite", function(tag:String, variable:String) {
			FunkinLua.luaTrace("getPropertyLuaSprite is deprecated! Use getProperty instead", false, true);
			if(game.modchartSprites.exists(tag)) {
				var killMe:Array<String> = variable.split('.');
				if(killMe.length > 1) {
					var coverMeInPiss:Dynamic = Reflect.getProperty(game.modchartSprites.get(tag), killMe[0]);
					for (i in 1...killMe.length-1) {
						coverMeInPiss = Reflect.getProperty(coverMeInPiss, killMe[i]);
					}
					return Reflect.getProperty(coverMeInPiss, killMe[killMe.length-1]);
				}
				return Reflect.getProperty(game.modchartSprites.get(tag), variable);
			}
			return null;
		});
		Lua_helper.add_callback(lua, "setPropertyLuaSprite", function(tag:String, variable:String, value:Dynamic) {
			FunkinLua.luaTrace("setPropertyLuaSprite is deprecated! Use setProperty instead", false, true);
			if(game.modchartSprites.exists(tag)) {
				var killMe:Array<String> = variable.split('.');
				if(killMe.length > 1) {
					var coverMeInPiss:Dynamic = Reflect.getProperty(game.modchartSprites.get(tag), killMe[0]);
					for (i in 1...killMe.length-1) {
						coverMeInPiss = Reflect.getProperty(coverMeInPiss, killMe[i]);
					}
					Reflect.setProperty(coverMeInPiss, killMe[killMe.length-1], value);
					return true;
				}
				Reflect.setProperty(game.modchartSprites.get(tag), variable, value);
				return true;
			}
			FunkinLua.luaTrace("setPropertyLuaSprite: Lua sprite with tag: " + tag + " doesn't exist!");
			return false;
		});
		Lua_helper.add_callback(lua, "musicFadeIn", function(duration:Float, fromValue:Float = 0, toValue:Float = 1) {
			FlxG.sound.music.fadeIn(duration, fromValue, toValue);
			FunkinLua.luaTrace('musicFadeIn is deprecated! Use soundFadeIn instead.', false, true);

		});
		Lua_helper.add_callback(lua, "musicFadeOut", function(duration:Float, toValue:Float = 0) {
			FlxG.sound.music.fadeOut(duration, toValue);
			FunkinLua.luaTrace('musicFadeOut is deprecated! Use soundFadeOut instead.', false, true);
		});
	}
}