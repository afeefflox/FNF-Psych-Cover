package meta.state.editors;

import util.CoolUtil;
import animateatlas.AtlasFrameMaker;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.effects.FlxTrail;
import flixel.animation.FlxBaseAnimation;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.tweens.FlxTween;
import flixel.util.FlxSort;
#if MODS_ALLOWED
import sys.io.File;
import sys.FileSystem;
#end
import openfl.utils.AssetType;
import openfl.utils.Assets;
import haxe.Json;
import haxe.format.JsonParser;
import objects.Character.CharacterFile;
import objects.Character.AnimArray;
import objects.FNFSprite;

using StringTools;

class FakeCharacter extends FNFSprite
{
    public var animOffsets:Map<String, Array<Dynamic>>;
	public var animOffsetsPlayer:Map<String, Array<Dynamic>>;

	public var isPlayer(default, set):Bool = false;
	public var wasPlayer(default, set):Bool = false;
	public var curCharacter:String = 'bf';

    public var animationsArray:Array<AnimArray> = [];

	public var positionArray:Array<Float> = [0, 0];
	public var cameraPosition:Array<Float> = [0, 0];
	public var playerPositionArray:Array<Float> = [0, 0];
	public var playerCameraPosition:Array<Float> = [0, 0];

	public var jsonScale:Float = 1;
	public var noAntialiasing:Bool = false;
	public var originalFlipX(default, set):Bool = false;
	public var danceIdle:Bool = false; //Character use "danceLeft" and "danceRight" instead of "idle"


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
			}
		}

	}

    public function new()
    {
		super();

		#if (haxe >= "4.0.0")
		animOffsets = new Map();
		animOffsetsPlayer = new Map();
		#else
		animOffsets = new Map<String, Array<Dynamic>>();
		animOffsetsPlayer = new Map<String, Array<Dynamic>>();
		#end

		
		this.isPlayer = isPlayer;
		antialiasing = ClientPrefs.globalAntialiasing;
    }

    public function setCharacter(character:String, ?isPlayer:Bool = false):FakeCharacter
    {
        curCharacter = character;
        switch (curCharacter)
        {
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
					return setCharacter('bf');
				}

				#if MODS_ALLOWED
				var rawJson = File.getContent(path);
				#else
				var rawJson = Assets.getText(path);
				#end

				var json:CharacterFile = cast Json.parse(rawJson);
				frames = CoolUtil.loadFrames(json.image);

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

				flipX = !!json.flip_x;
				if(json.no_antialiasing) {
					antialiasing = false;
					noAntialiasing = true;
				}

				if(json.isPlayerChar)
					wasPlayer = json.isPlayerChar;

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

        
		if (isPlayer)
		{
			flipX = !flipX;
			if (!curCharacter.startsWith('bf'))
				flipLeftRight();
		}
		else if (curCharacter.startsWith('bf'))
			flipLeftRight();

		recalculateDanceIdle();
		dance();
		return this;
    }

	public var danced:Bool = false;
	public function dance()
	{
		if(danceIdle)
		{
			danced = !danced;

			if (danced)
				playAnim('danceRight');
			else
				playAnim('danceLeft');
		}
		else if(existsAnimation('idle')) {
				playAnim('idle');
		}
	}

    override function update(elapsed:Float)
    {
        if(isAnimFinished() && existsAnimation(getAnimName() + '-loop'))
		{
			playAnim(getAnimName() + '-loop');
		}
        super.update(elapsed);
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

	public var danceEveryNumBeats:Int = 2;
	private var settingCharacterUp:Bool = true;
	public function recalculateDanceIdle() {
		var lastDanceIdle:Bool = danceIdle;
		danceIdle = (existsAnimation('danceLeft') && existsAnimation('danceRight'));

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
}