package objects;

import util.CoolUtil;
import meta.state.PlayState;
import animateatlas.AtlasFrameMaker;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.effects.FlxTrail;
import flixel.animation.FlxBaseAnimation;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.tweens.FlxTween;
import flixel.util.FlxSort;
import util.Section.SwagSection;
import util.Conductor;
#if MODS_ALLOWED
import sys.io.File;
import sys.FileSystem;
#end
import openfl.utils.AssetType;
import openfl.utils.Assets;
import haxe.Json;
import haxe.format.JsonParser;

using StringTools;

typedef CharacterFile = {
	var animations:Array<AnimArray>;
	var image:String;
	var scale:Float;
	var sing_duration:Float;
	var healthicon:String;
	var arrowSkin:String;
	var arrowStyle:String;
	var splashSkin:String;

	var position:Array<Float>;
	var camera_position:Array<Float>;

	var player_position:Array<Float>;
	var playerCamera_position:Array<Float>;

	var flip_x:Bool;
	var no_antialiasing:Bool;
	var healthbar_colors:Array<Int>;
	var isPlayerChar:Bool;
}

typedef AnimArray = {
	var anim:String;
	var name:String;
	var fps:Int;
	var loop:Bool;
	var indices:Array<Int>;
	var offsets:Array<Int>;
	var offsets_player:Array<Int>;
}

class Character extends FNFSprite
{
	public var animOffsets:Map<String, Array<Dynamic>>;
	public var animOffsetsPlayer:Map<String, Array<Dynamic>>;
	public var debugMode:Bool = false;

	public var isPlayer(default, set):Bool = false;
	public var wasPlayer(default, set):Bool = false;
	public var curCharacter:String = DEFAULT_CHARACTER;

	public var colorTween:FlxTween;
	public var holdTimer:Float = 0;
	public var heyTimer:Float = 0;
	public var specialAnim:Bool = false;
	public var animationNotes:Array<Dynamic> = [];
	public var stunned:Bool = false;
	public var singDuration:Float = 4; //Multiplier of how long a character holds the sing pose
	public var idleSuffix:String = '';
	public var danceIdle:Bool = false; //Character use "danceLeft" and "danceRight" instead of "idle"
	public var skipDance:Bool = false;

	public var healthIcon:String = 'face';
	public var arrowSkin:String = 'NOTE_assets';
	public var arrowStyle:String = 'base';
	public var splashSkin:String = 'noteSplashes';
	public var animationsArray:Array<AnimArray> = [];

	public var positionArray:Array<Float> = [0, 0];
	public var cameraPosition:Array<Float> = [0, 0];
	public var playerPositionArray:Array<Float> = [0, 0];
	public var playerCameraPosition:Array<Float> = [0, 0];

	public var hasMissAnimations:Bool = false;

	//Used on Character Editor
	public var imageFile:String = '';
	public var jsonScale:Float = 1;
	public var noAntialiasing:Bool = false;
	public var originalFlipX(default, set):Bool = false;
	public var healthColorArray:Array<Int> = [255, 0, 0];
	public var startedDeath:Bool = false;
	function set_isPlayer(value:Bool):Bool
	{
		return isPlayer = value;
	}
	function set_wasPlayer(value:Bool):Bool
	{
		return wasPlayer = value;
	}
	function set_originalFlipX(value:Bool):Bool
	{
		return originalFlipX = value;
	}
	public static var DEFAULT_CHARACTER:String = 'bf'; //In case a character is missing, it will use BF on its place
	public function new(x:Float, y:Float, ?character:String = 'bf', ?isPlayer:Bool = false)
	{
		super(x, y);

		#if (haxe >= "4.0.0")
		animOffsets = new Map();
		animOffsetsPlayer = new Map();
		#else
		animOffsets = new Map<String, Array<Dynamic>>();
		animOffsetsPlayer = new Map<String, Array<Dynamic>>();
		#end
		curCharacter = character;
		this.isPlayer = isPlayer;
		antialiasing = ClientPrefs.globalAntialiasing;
		var library:String = null;
		switch (curCharacter)
		{
			//case 'your character name in case you want to hardcode them instead':

			default:
				var characterBETADCIUPath:String = 'charactersBETADCIU/' + curCharacter + '.json';
				var characterPath:String = 'characters/' + curCharacter + '.json';

				#if MODS_ALLOWED
				var path:String = Paths.modFolders(characterPath);
				if (!FileSystem.exists(path)) {
					path = Paths.getPreloadPath(characterPath);
				}

				if (!FileSystem.exists(path))
				#else
				var path:String = Paths.getPreloadPath(characterPath);
				if (!Assets.exists(path))
				#end
				{
					path = Paths.getPreloadPath('characters/' + DEFAULT_CHARACTER + '.json'); //If a character couldn't be found, change him to BF just to prevent a crash
				}

				#if MODS_ALLOWED
				var rawJson = File.getContent(path);
				#else
				var rawJson = Assets.getText(path);
				#end

				var json:CharacterFile = cast Json.parse(rawJson);
				loadFrames(json.image);
				imageFile = json.image;

				if(json.scale != 1) {
					jsonScale = json.scale;
					setGraphicSize(Std.int(width * jsonScale));
					updateHitbox();
				}

				positionArray = json.position;
				cameraPosition = json.camera_position;

				if (json.player_position != null)
					playerPositionArray = json.player_position;
				else
					playerPositionArray = json.position;

				if (json.playerCamera_position != null)
					playerCameraPosition = json.playerCamera_position;
				else
					playerCameraPosition = json.camera_position;

				healthIcon = json.healthicon;
				singDuration = json.sing_duration;
				flipX = !!json.flip_x;
				if(json.no_antialiasing) {
					antialiasing = false;
					noAntialiasing = true;
				}

				if(json.arrowSkin != null)
					arrowSkin = json.arrowSkin;
				else
					arrowSkin = 'NOTE_assets';

				if(json.arrowStyle != null)
					arrowStyle = json.arrowStyle;
				else
					arrowStyle = 'base';

				if(json.splashSkin != null)
					splashSkin = json.splashSkin;
				else
					splashSkin = 'noteSplashes';

				if(json.isPlayerChar)
					wasPlayer = json.isPlayerChar;

				if(json.healthbar_colors != null && json.healthbar_colors.length > 2)
					healthColorArray = json.healthbar_colors;

				antialiasing = !noAntialiasing;
				if(!ClientPrefs.globalAntialiasing) antialiasing = false;

				animationsArray = json.animations;
				if(animationsArray != null && animationsArray.length > 0) {
					for (anim in animationsArray) {
						var animAnim:String = '' + anim.anim;
						var animName:String = '' + anim.name;
						var animFps:Int = anim.fps;
						var animLoop:Bool = !!anim.loop; //Bruh
						var animIndices:Array<Int> = anim.indices;
						if (animateAtlas != null) {
							if(animIndices != null && animIndices.length > 0) {
								animateAtlas.animation.addByIndices(animAnim, animName, animIndices, "", animFps, animLoop);
							} else {
								animateAtlas.animation.addByPrefix(animAnim, animName, animFps, animLoop);
							}
						}
						else
						{
							if(animIndices != null && animIndices.length > 0) {
								animation.addByIndices(animAnim, animName, animIndices, "", animFps, animLoop);
							} else {
								animation.addByPrefix(animAnim, animName, animFps, animLoop);
							}
						}

						if(isPlayer)
						{
							if(anim.offsets_player != null && anim.offsets_player.length > 1) {
								addOffsetPlayer(anim.anim, anim.offsets_player[0], anim.offsets_player[1]);
							}
							else if(anim.offsets != null && anim.offsets.length > 1) {
								addOffsetPlayer(anim.anim, anim.offsets[0], anim.offsets[1]);
							}
						}
						else
						{
							if(anim.offsets != null && anim.offsets.length > 1) {
								addOffset(anim.anim, anim.offsets[0], anim.offsets[1]);
							}
						}
					}
				} else {
					quickAnimAdd('idle', 'BF idle dance');
				}
		}
		originalFlipX = flipX;

		if(existsOffsets('singLEFTmiss') || existsOffsets('singDOWNmiss') || existsOffsets('singUPmiss') || existsOffsets('singRIGHTmiss')) hasMissAnimations = true;
		recalculateDanceIdle();
		dance();

		if (isPlayer)
		{
			flipX = !flipX;
			if (!wasPlayer)
				flipLeftRight();
		}
		else if (wasPlayer)
			flipLeftRight();


		switch(curCharacter)
		{
			case 'pico-speaker':
				skipDance = true;
				loadMappedAnims();
				playAnim("shoot1");
		}
	}

	public function flipLeftRight():Void
	{
		
		var animations:Array<Array<String>> = [
			//Default
			['singLEFT', 'singRIGHT'], 
			['singLEFTmiss', 'singRIGHTmiss'],
			['singLEFT-alt', 'singRIGHT-alt'], 
			//Loop
			['singLEFT-loop', 'singRIGHT-loop'], 
			['singLEFT-alt-loop', 'singRIGHT-alt-loop'], 
		];
		for (pair in animations) {
			// should always be in groups of two
			if (existsAnimation(pair[0]) && existsAnimation(pair[1])) {
				var firstAnim = animation.getByName(pair[0]).frames;
				var secondAnim = animation.getByName(pair[1]).frames;
				animation.getByName(pair[0]).frames = secondAnim;
				animation.getByName(pair[1]).frames = firstAnim;
				if(animateAtlas != null)	
				{
					var firstAtlasAnim = animateAtlas.animation.getByName(pair[0]).frames;
					var secondAtlasAnim = animateAtlas.animation.getByName(pair[1]).frames;
					animateAtlas.animation.getByName(pair[0]).frames = secondAtlasAnim;
					animateAtlas.animation.getByName(pair[1]).frames = firstAtlasAnim;
				}
			}
		}

	}

	override function update(elapsed:Float)
	{
		if(!debugMode)
		{
			if(heyTimer > 0)
			{
				heyTimer -= elapsed * PlayState.instance.playbackRate;
				if(heyTimer <= 0)
				{
					if(specialAnim && getAnimName() == 'hey' || getAnimName() == 'cheer')
					{
						specialAnim = false;
						dance();
					}
					heyTimer = 0;
				}
			} else if(specialAnim && isAnimFinished())
			{
				specialAnim = false;
				dance();
			}
			
			switch(curCharacter)
			{
				case 'pico-speaker':
					if(animationNotes.length > 0 && Conductor.songPosition > animationNotes[0][0])
					{
						var noteData:Int = 1;
						if(animationNotes[0][1] > 2) noteData = 3;

						noteData += FlxG.random.int(0, 1);
						playAnim('shoot' + noteData, true);
						animationNotes.shift();
					}
					if(animation.curAnim.finished) playAnim(animation.curAnim.name, false, false, animation.curAnim.frames.length - 3);
			}

			if (getAnimName().startsWith('sing'))
			{
				holdTimer += elapsed;
			}
			else
				holdTimer = 0;

			if (getAnimName().endsWith('miss') && isAnimFinished())
			{
				if(danceIdle)
					playAnim('danceLeft', true, false, 15);
				else
					playAnim('idle', true, false, 10);			
			}
		
			if (getAnimName() == 'firstDeath' && isAnimFinished() && startedDeath)
			{
				playAnim('deathLoop');
			}

			if(isAnimFinished() && existsAnimation(getAnimName() + '-loop'))
			{
				playAnim(getAnimName() + '-loop');
			}
		}
		super.update(elapsed);
	}

	public var danced:Bool = false;

	/**
	 * FOR GF DANCING SHIT
	 */
	public function dance()
	{
		if (!debugMode && !skipDance && !specialAnim)
		{
			if(danceIdle)
			{
				danced = !danced;

				if (danced)
					playAnim('danceRight' + idleSuffix);
				else
					playAnim('danceLeft' + idleSuffix);
			}
			else if(existsAnimation('idle' + idleSuffix)) {
					playAnim('idle' + idleSuffix);
			}
		}
	}
	

	public function getOffsets(AnimName:String):Dynamic
	{
		if(isPlayer)
			return animOffsetsPlayer.get(AnimName);
		return animOffsets.get(AnimName);
	}

	public function existsOffsets(AnimName:String):Bool
	{
		if(isPlayer)
			return animOffsetsPlayer.exists(AnimName);
		return animOffsets.exists(AnimName);
	}

	public override function playAnim(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0):Void
	{
		specialAnim = false;
		super.playAnim(AnimName, Force, Reversed, Frame);
		var daOffset = getOffsets(AnimName);
		if (existsOffsets(AnimName))
		{
			offset.set(daOffset[0], daOffset[1]);
		}
		else
			offset.set(0, 0);

		if (curCharacter.startsWith('gf'))
		{
			if (AnimName == 'singLEFT')
			{
				danced = true;
			}
			else if (AnimName == 'singRIGHT')
			{
				danced = false;
			}

			if (AnimName == 'singUP' || AnimName == 'singDOWN')
			{
				danced = !danced;
			}
		}
	}
	
	function loadMappedAnims():Void
	{
		var noteData:Array<SwagSection> = util.Song.loadFromJson('picospeaker', Paths.formatToSongPath(PlayState.SONG.song)).notes;
		for (section in noteData) {
			for (songNotes in section.sectionNotes) {
				animationNotes.push(songNotes);
			}
		}
		TankmenBG.animationNotes = animationNotes;
		animationNotes.sort(sortAnims);
	}

	function sortAnims(Obj1:Array<Dynamic>, Obj2:Array<Dynamic>):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1[0], Obj2[0]);
	}

	public var danceEveryNumBeats:Int = 2;
	private var settingCharacterUp:Bool = true;
	public function recalculateDanceIdle() {
		var lastDanceIdle:Bool = danceIdle;
		danceIdle = (existsAnimation('danceLeft' + idleSuffix) && existsAnimation('danceRight' + idleSuffix));

		if(settingCharacterUp)
		{
			danceEveryNumBeats = (danceIdle ? 1 : 2);
		}
		else if(lastDanceIdle != danceIdle)
		{
			var calc:Float = danceEveryNumBeats;
			if(danceIdle)
				calc /= 2;
			else
				calc *= 2;

			danceEveryNumBeats = Math.round(Math.max(calc, 1));
		}
		settingCharacterUp = false;
	}

	public function addOffset(name:String, x:Float = 0, y:Float = 0)
	{
		animOffsets[name] = [x, y];
	}

	
	public function addOffsetPlayer(name:String, x:Float = 0, y:Float = 0)
	{
		animOffsetsPlayer[name] = [x, y];
	}

	public function quickAnimAdd(name:String, anim:String)
	{
		animation.addByPrefix(name, anim, 24, false);
	}

	function loadScriptChar(char:String = 'bf')
	{
		var pushedChars:Array<String> = [];
	}
}
