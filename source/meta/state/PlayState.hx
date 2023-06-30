package meta.state;


import MusicBeat;
import animateatlas.AtlasFrameMaker;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxSubState;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.effects.FlxTrail;
import flixel.addons.effects.FlxTrailArea;
import flixel.addons.effects.chainable.FlxEffectSprite;
import flixel.addons.effects.chainable.FlxWaveEffect;
import flixel.addons.transition.FlxTransitionableState;
import flixel.animation.FlxAnimationController;
import flixel.effects.particles.FlxEmitter;
import flixel.effects.particles.FlxParticle;
import flixel.graphics.FlxGraphic;
import flixel.graphics.atlas.FlxAtlas;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxBar;
import flixel.util.FlxCollision;
import flixel.util.FlxColor;
import flixel.util.FlxSave;
import flixel.util.FlxSort;
import flixel.util.FlxStringUtil;
import flixel.util.FlxTimer;
import haxe.Json;
import lime.utils.Assets;
import meta.state.editors.CharacterEditorState;
import meta.state.editors.ChartingState;
import meta.state.freeplay.*;
import meta.substate.CustomFadeTransition;
import meta.substate.GameOverSubstate;
import meta.substate.PauseSubState;
import objects.AttachedSprite;
import objects.BGSprite;
import objects.Character;
import objects.HealthIcon;
import objects.Note.EventNote;
import objects.Note;
import objects.NoteSplash;
import objects.PhillyGlow;
import objects.Stage;
import objects.Strumline.StaticNote;
import objects.Strumline;
import objects.TankmenBG;
import openfl.Lib;
import openfl.display.BlendMode;
import openfl.display.StageQuality;
import openfl.events.KeyboardEvent;
import openfl.filters.BitmapFilter;
import openfl.utils.Assets as OpenFlAssets;
import util.Achievements;
import util.Conductor;
import util.CoolUtil;
import util.CutsceneHandler;
import util.DialogueBox;
import util.DialogueBoxPsych;
import util.Highscore;
import util.Section.SwagSection;
import util.Song.SwagSong;
import util.Song;
import util.StageData;
import util.WeekData;
import util.WeekDataAlt;
import util.script.FunkinHaxe;
import util.script.FunkinLua;
import util.script.Globals.*;
import util.script.Globals;
import StrumNote;
#if LUA_ALLOWED
import llua.Lua;
import llua.LuaL;
import llua.State;
import llua.Convert;
#end
using StringTools;
#if desktop
import Discord.DiscordClient;
#end
#if !flash 
import flixel.addons.display.FlxRuntimeShader;
import openfl.filters.ShaderFilter;
#end

#if sys
import sys.FileSystem;
import sys.io.File;
#end

#if VIDEOS_ALLOWED
import vlc.MP4Handler;
#end


class PlayState extends MusicBeatState
{
	public static var STRUM_X = 42;
	public static var STRUM_X_MIDDLESCROLL = -278;

	public static var ratingStuff:Array<Dynamic> = [
		['You Suck!', 0.2], //From 0% to 19%
		['Shit', 0.4], //From 20% to 39%
		['Bad', 0.5], //From 40% to 49%
		['Bruh', 0.6], //From 50% to 59%
		['Meh', 0.69], //From 60% to 68%
		['Nice', 0.7], //69%
		['Good', 0.8], //From 70% to 79%
		['Great', 0.9], //From 80% to 89%
		['Sick!', 1], //From 90% to 99%
		['Perfect!!', 1] //The value on this one isn't used actually, since Perfect is always "1"
	];

	//event variables
	private var isCameraOnForcedPos:Bool = false;

	#if (haxe >= "4.0.0")
	public var stageMap:Map<String, Stage> = new Map<String, Stage>();
	public var boyfriendMap:Map<String, Character> = new Map<String, Character>();
	public var dadMap:Map<String, Character> = new Map<String, Character>();
	public var gfMap:Map<String, Character> = new Map<String, Character>();
	public var characterMap:Map<String, Character> = new Map<String, Character>();
	public var variables:Map<String, Dynamic> = new Map<String, Dynamic>();
	public var modchartTweens:Map<String, FlxTween> = new Map<String, FlxTween>();
	public var modchartSprites:Map<String, ModchartSprite> = new Map<String, ModchartSprite>();
	public var modchartGroups:Map<String, ModchartGroup> = new Map<String, ModchartGroup>();
	public var modchartGroupTypes:Map<String, ModchartGroupTyped> = new Map<String, ModchartGroupTyped>();
	public var modchartCharacters:Map<String, ModchartCharacter> = new Map<String, ModchartCharacter>();
	public var modchartHealthIcons:Map<String, ModchartHealthIcon> = new Map<String, ModchartHealthIcon>();
	public var modchartTimers:Map<String, FlxTimer> = new Map<String, FlxTimer>();
	public var modchartSounds:Map<String, FlxSound> = new Map<String, FlxSound>();
	public var modchartTexts:Map<String, ModchartText> = new Map<String, ModchartText>();
	public var modchartSaves:Map<String, FlxSave> = new Map<String, FlxSave>();
	#else
	public var stageMap:Map<String, Stage> = new Map();
	public var boyfriendMap:Map<String, Boyfriend> = new Map();
	public var dadMap:Map<String, Character> = new Map();
	public var gfMap:Map<String, Character> = new Map();
	public var variables:Map<String, Dynamic> = new Map();
	public var modchartTweens:Map<String, FlxTween> = new Map();
	public var modchartSprites:Map<String, ModchartSprite> = new Map();
	public var modchartTimers:Map<String, FlxTimer> = new Map();
	public var modchartSounds:Map<String, FlxSound> = new Map();
	public var modchartTexts:Map<String, ModchartText> = new Map();
	public var modchartSaves:Map<String, FlxSave> = new Map();
	public var modchartGroups:Map<String, ModchartGroup> = new Map();
	public var modchartGroupTypes:Map<String, ModchartGroupTyped> = new Map();
	public var modchartCharacters:Map<String, ModchartCharacter> = new Map();
	public var modchartHealthIcons:Map<String, ModchartHealthIcon> = new Map();
	#end

	public var BF_X:Float = 770;
	public var BF_Y:Float = 100;
	public var DAD_X:Float = 100;
	public var DAD_Y:Float = 100;
	public var GF_X:Float = 400;
	public var GF_Y:Float = 130;

	public var songSpeedTween:FlxTween;
	public var songSpeed(default, set):Float = 1;
	public var songSpeedType:String = "multiplicative";
	public var noteKillOffset:Float = 350;

	public var playbackRate(default, set):Float = 1;

	public var stageGroup:FlxTypedGroup<FlxBasic>;
	public var boyfriendGroup:FlxSpriteGroup;
	public var dadGroup:FlxSpriteGroup;
	public var gfGroup:FlxSpriteGroup;

	public var boyfriendLayer:FlxTypedGroup<FlxBasic>;
	public var dadLayer:FlxTypedGroup<FlxBasic>;
	public var gfLayer:FlxTypedGroup<FlxBasic>;

	public static var curStage:String = '';
	public static var isPixelStage:Bool = false;
	public static var SONG:SwagSong = null;
	public static var isStoryMode:Bool = false;
	public static var isBETADCIU:Bool = false;
	public static var isCover:Bool = false;
	public static var storyWeek:Int = 0;
	public static var storyPlaylist:Array<String> = [];
	public static var storyDifficulty:Int = 1;

	public var spawnTime:Float = 2000;

	public var vocals:FlxSound;

	public var vocalsDad:Array<FlxSound> = [];
	public var vocalsBoyfriend:Array<FlxSound> = [];

	public var stage:Stage = null;
	public var dad:Character = null;
	public var gf:Character = null;
	public var boyfriend:Character = null;


	public var notes:FlxTypedGroup<Note>;
	public var fakeNotes:FlxTypedGroup<Note>;
	public var unspawnNotes:Array<Note> = [];
	public var unspawnFakeNotes:Array<Note> = [];
	public var eventNotes:Array<EventNote> = [];

	public var boyfriendArrowSkin:String = null;
	public var boyfriendArrowStyle:String = null;

	public var dadArrowSkin:String = null;
	public var dadArrowStyle:String = null;

	public var gfArrowSkin:String = null;
	public var gfArrowStyle:String = null;

	public var momArrowSkin:String = null;
	public var momArrowStyle:String = null;

	private var strumLine:FlxSprite;

	//Handles the new epic mega sexy cam code that i've done
	public var camFollow:FlxPoint;
	public var camFollowPos:FlxObject;
	private static var prevCamFollow:FlxPoint;
	private static var prevCamFollowPos:FlxObject;

	public var strumLineNotes:FlxTypedGroup<StrumNote>;
	public var fakeStrumLineNotes:FlxTypedGroup<StrumNote>;
	
	public var opponentStrums:StrumLineNote;
	public var playerStrums:StrumLineNote;
	public var opponentFakeStrums:StrumLineNote;
	public var playerFakeStrums:StrumLineNote;

	public var grpNoteSplashes:FlxTypedGroup<NoteSplash>;

	public var camZooming:Bool = false;
	public var camZoomingMult:Float = 1;
	public var camZoomingDecay:Float = 1;
	private var curSong:String = "";

	public var gfSpeed:Int = 1;
	public var health:Float = 1;
	public var combo:Int = 0;

	private var healthBarBG:AttachedSprite;
	public var healthBar:FlxBar;
	var songPercent:Float = 0;

	private var timeBarBG:AttachedSprite;
	public var timeBar:FlxBar;

	public var ratingsData:Array<Rating> = [];
	public var sicks:Int = 0;
	public var goods:Int = 0;
	public var bads:Int = 0;
	public var shits:Int = 0;

	private var generatedMusic:Bool = false;
	public var endingSong:Bool = false;
	public var startingSong:Bool = false;
	private var updateTime:Bool = true;
	public static var changedDifficulty:Bool = false;
	public static var chartingMode:Bool = false;

	//Gameplay settings
	public var healthGain:Float = 1;
	public var healthLoss:Float = 1;
	public var instakillOnMiss:Bool = false;
	public var cpuControlled:Bool = false;
	public var opponentControlled:Bool = false;
	public var practiceMode:Bool = false;
	public var showcaseMode:Bool = false;

	public var botplaySine:Float = 0;
	public var botplayTxt:FlxText;

	public var iconP1:HealthIcon;
	public var iconP2:HealthIcon;
	public var camHUD:FlxCamera;
	public var camGame:FlxCamera;
	public var camOther:FlxCamera;
	
	public var cameraSpeed:Float = 1;

	var dialogue:Array<String> = ['blah blah blah', 'coolswag'];
	var dialogueJson:DialogueFile = null;
	var stageData:StageFile = null;

	var dadbattleBlack:BGSprite;
	var dadbattleLight:BGSprite;
	var dadbattleSmokes:FlxSpriteGroup;

	var blammedLightsBlack:FlxSprite;
	var phillyWindowEvent:BGSprite;
	var phillyGlowGradient:PhillyGlowGradient;
	public var phillyGlowParticles:FlxTypedGroup<PhillyGlowParticle>;

	public var songScore:Int = 0;
	public var songHits:Int = 0;
	public var songMisses:Int = 0;
	public var scoreTxt:FlxText;
	var timeTxt:FlxText;
	var scoreTxtTween:FlxTween;

	public static var campaignScore:Int = 0;
	public static var campaignMisses:Int = 0;
	public static var seenCutscene:Bool = false;
	public static var deathCounter:Int = 0;

	public var defaultCamZoom:Float = 1.05;

	// how big to stretch the pixel art assets
	public static var daPixelZoom:Float = 6;
	private var singAnimations:Array<String> = ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT'];

	public var inCutscene:Bool = false;
	public var skipCountdown:Bool = false;
	var songLength:Float = 0;

	public var boyfriendCameraOffset:Array<Float> = null;
	public var opponentCameraOffset:Array<Float> = null;
	public var girlfriendCameraOffset:Array<Float> = null;

	#if desktop
	// Discord RPC variables
	var storyDifficultyText:String = "";
	var detailsText:String = "";
	var detailsPausedText:String = "";
	#end

	//Achievement shit
	var keysPressed:Array<Bool> = [];
	var boyfriendIdleTime:Float = 0.0;
	var boyfriendIdled:Bool = false;

	// Lua shit
	public static var instance:PlayState;
	public var luaArray:Array<FunkinLua> = [];
	public var haxeArray:Array<FunkinHaxe> = [];
	private var luaDebugGroup:FlxTypedGroup<DebugLuaText>;
	public var introSoundsSuffix:String = 'base/';

	// Debug buttons
	private var botplayKeys:Array<FlxKey>;
	private var debugKeysChart:Array<FlxKey>;
	private var debugKeysCharacter:Array<FlxKey>;

	// Less laggy controls
	private var keysArray:Array<Dynamic>;
	private var controlArray:Array<String>;

	var precacheList:Map<String, String> = new Map<String, String>();
	
	// stores the last judgement object
	public static var lastRating:FlxSprite;
	// stores the last combo sprite object
	public static var lastCombo:FlxSprite;
	// stores the last combo score objects in an array
	public static var lastScore:Array<FlxSprite> = [];

	override public function create()
	{
		//trace('Playback Rate: ' + playbackRate);
		Paths.clearStoredMemory();

		// for lua
		instance = this;

		debugKeysChart = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_1'));
		debugKeysCharacter = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_2'));
		botplayKeys = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('botplay'));
		PauseSubState.songName = null; //Reset to default
		playbackRate = ClientPrefs.getGameplaySetting('songspeed', 1);

		keysArray = [
			ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_left')),
			ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_down')),
			ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_up')),
			ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_right'))
		];

		controlArray = [
			'NOTE_LEFT',
			'NOTE_DOWN',
			'NOTE_UP',
			'NOTE_RIGHT'
		];

		//Ratings
		ratingsData.push(new Rating('sick')); //default rating

		var rating:Rating = new Rating('good');
		rating.ratingMod = 0.7;
		rating.score = 200;
		rating.noteSplash = false;
		ratingsData.push(rating);

		var rating:Rating = new Rating('bad');
		rating.ratingMod = 0.4;
		rating.score = 100;
		rating.noteSplash = false;
		ratingsData.push(rating);

		var rating:Rating = new Rating('shit');
		rating.ratingMod = 0;
		rating.score = 50;
		rating.noteSplash = false;
		ratingsData.push(rating);

		// For the "Just the Two of Us" achievement
		for (i in 0...keysArray.length)
		{
			keysPressed.push(false);
		}

		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		// Gameplay settings
		healthGain = ClientPrefs.getGameplaySetting('healthgain', 1);
		healthLoss = ClientPrefs.getGameplaySetting('healthloss', 1);
		instakillOnMiss = ClientPrefs.getGameplaySetting('instakill', false);
		practiceMode = ClientPrefs.getGameplaySetting('practice', false);
		cpuControlled = ClientPrefs.getGameplaySetting('botplay', false);
		opponentControlled = ClientPrefs.getGameplaySetting('opponentplay', false);
		showcaseMode = ClientPrefs.getGameplaySetting('showcase', false);

		// var gameCam:FlxCamera = FlxG.camera;
		camGame = new FlxCamera();
		camHUD = new FlxCamera();
		camOther = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		camOther.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.add(camOther, false);
		grpNoteSplashes = new FlxTypedGroup<NoteSplash>();
		dadbattleSmokes = new FlxSpriteGroup();

		FlxG.cameras.setDefaultDrawTarget(camGame, true);
		CustomFadeTransition.nextCamera = camOther;

		persistentUpdate = true;
		persistentDraw = true;

		if (SONG == null)
			SONG = Song.loadFromJson('test', 'test');

		Conductor.mapBPMChanges(SONG);
		Conductor.changeBPM(SONG.bpm);

		#if desktop
		storyDifficultyText = CoolUtil.difficulties[storyDifficulty];

		// String that contains the mode defined here so it isn't necessary to call changePresence for each mode
		if (isStoryMode)
		{
			detailsText = "Story Mode: " + WeekData.getCurrentWeek().weekName;
		}
		else
		{
			detailsText = "Freeplay";
		}

		// String for when the game is paused
		detailsPausedText = "Paused - " + detailsText;
		#end

		GameOverSubstate.resetVariables();
		var songName:String = Paths.formatToSongPath(SONG.song);

		curStage = SONG.stage;
		//trace('stage is: ' + curStage);
		if(SONG.stage == null || SONG.stage.length < 1) {
			switch (songName)
			{
				case 'spookeez' | 'south' | 'monster':
					curStage = 'spooky';
				case 'pico' | 'blammed' | 'philly' | 'philly-nice':
					curStage = 'philly';
				case 'milf' | 'satin-panties' | 'high':
					curStage = 'limo';
				case 'cocoa' | 'eggnog':
					curStage = 'mall';
				case 'winter-horrorland':
					curStage = 'mallEvil';
				case 'senpai' | 'roses':
					curStage = 'school';
				case 'thorns':
					curStage = 'schoolEvil';
				case 'ugh' | 'guns' | 'stress':
					curStage = 'tank';
				default:
					curStage = 'stage';
			}
		}
		SONG.stage = curStage;
		GameOverSubstate.resetVariables();
		switch(curStage)
		{
			case 'school'|'schoolEvil':
				GameOverSubstate.characterName = 'bf-pixel-dead';
				GameOverSubstate.deathSoundName = 'stages/pixel/fnf_loss_sfx';
				GameOverSubstate.loopSoundName = 'stages/pixel/gameOver';
				GameOverSubstate.endSoundName = 'stages/pixel/gameOverEnd';
			case 'tank':
				if(songName == 'stress')
					GameOverSubstate.characterName = 'bf-holding-gf-dead';
				else
					GameOverSubstate.characterName = 'bf-dead';
		}

		loadStageData(curStage);
		stageGroup = new FlxTypedGroup<FlxBasic>();

		boyfriendLayer = new FlxTypedGroup<FlxBasic>();
		gfLayer = new FlxTypedGroup<FlxBasic>();
		dadLayer = new FlxTypedGroup<FlxBasic>();

		boyfriendGroup = new FlxSpriteGroup(BF_X, BF_Y);
		dadGroup = new FlxSpriteGroup(DAD_X, DAD_Y);
		gfGroup = new FlxSpriteGroup(GF_X, GF_Y);

		if(isPixelStage) {
			introSoundsSuffix = 'pixel/';
		}

		add(stageGroup);

		add(gfGroup); //Needed for blammed lights
		add(gfLayer);

		add(dadGroup);
		add(dadLayer);

		
		add(boyfriendGroup);
		add(boyfriendLayer);

		

		#if LUA_ALLOWED
		luaDebugGroup = new FlxTypedGroup<DebugLuaText>();
		luaDebugGroup.cameras = [camOther];
		add(luaDebugGroup);
		#end

		var scriptExts:Array<String> = ['hx', 'hxs', 'hscript', 'hxc'];

		// "GLOBAL" SCRIPTS
		
		var filesPushed:Array<String> = [];
		var foldersToCheck:Array<String> = [Paths.getPreloadPath('scripts/')];

		#if MODS_ALLOWED
		foldersToCheck.insert(0, Paths.mods('scripts/'));
		if(Paths.currentModDirectory != null && Paths.currentModDirectory.length > 0)
			foldersToCheck.insert(0, Paths.mods(Paths.currentModDirectory + '/scripts/'));

		for(mod in Paths.getGlobalMods())
			foldersToCheck.insert(0, Paths.mods(mod + '/scripts/'));
		#end

		for (folder in foldersToCheck)
		{
			if(FileSystem.exists(folder))
			{
				for (file in FileSystem.readDirectory(folder))
				{
					#if LUA_ALLOWED
					if(file.endsWith('.lua') && !filesPushed.contains(file))
					{
						luaArray.push(new FunkinLua(folder + file));
						filesPushed.push(file);

						for (i in luaArray)
						{
							i.call('onCreate', []);
						}
					}
					#end

					for (ext in scriptExts)
					{
						if(file.endsWith('.$ext') && !filesPushed.contains(file))
						{
							haxeArray.push(new FunkinHaxe(folder + file));
							filesPushed.push(file);
							for (i in haxeArray)
							{
								i.call('create', []);
							}
						}
					}
				}
			}
		}

		
		var filesPushed:Array<String> = [];
		var foldersToCheck:Array<String> = [Paths.getPreloadPath('data/' + Paths.formatToSongPath(SONG.song) + '/')];

		#if MODS_ALLOWED
		foldersToCheck.insert(0, Paths.mods('data/' + Paths.formatToSongPath(SONG.song) + '/'));
		if(Paths.currentModDirectory != null && Paths.currentModDirectory.length > 0)
			foldersToCheck.insert(0, Paths.mods(Paths.currentModDirectory + '/data/' + Paths.formatToSongPath(SONG.song) + '/'));

		for(mod in Paths.getGlobalMods())
			foldersToCheck.insert(0, Paths.mods(mod + '/data/' + Paths.formatToSongPath(SONG.song) + '/' ));// using push instead of insert because these should run after everything else
		#end

		for (folder in foldersToCheck)
		{
			if(FileSystem.exists(folder))
			{
				for (file in FileSystem.readDirectory(folder))
				{
					#if LUA_ALLOWED
					if(file.endsWith('.lua') && !filesPushed.contains(file))
					{
						luaArray.push(new FunkinLua(folder + file));
						filesPushed.push(file);
						for (i in luaArray)
						{
							i.call('onCreate', []);
						}
					}
					#end

					for (ext in scriptExts)
					{
						if(file.endsWith('.$ext') && !filesPushed.contains(file))
						{
							haxeArray.push(new FunkinHaxe(folder + file));
							filesPushed.push(file);
							for (i in haxeArray)
							{
								i.call('create', []);
							}
						}
					}
				}
			}
		}

		callLocalVariables();

		stage = new Stage(curStage);
		stageGroup.add(stage);
		gfLayer.add(stage.layers.get('gf'));
		dadLayer.add(stage.layers.get('dad'));
		boyfriendLayer.add(stage.layers.get('boyfriend'));

		var gfVersion:String = SONG.gfVersion;
		if(gfVersion == null || gfVersion.length < 1)
		{
			switch (curStage)
			{
				case 'limo':
					gfVersion = 'gf-car';
				case 'mall' | 'mallEvil':
					gfVersion = 'gf-christmas';
				case 'school' | 'schoolEvil':
					gfVersion = 'gf-pixel';
				case 'tank':
					gfVersion = 'gf-tankmen';
				default:
					gfVersion = 'gf';
			}

			switch(Paths.formatToSongPath(SONG.song))
			{
				case 'stress':
					gfVersion = 'pico-speaker';
			}
			SONG.gfVersion = gfVersion; //Fix for the Chart Editor
		}

		if (!stageData.hide_girlfriend)
		{
			gf = new Character(0, 0, gfVersion);
			startCharacterPos(gf);
			gf.scrollFactor.set(0.95, 0.95);
			gfGroup.add(gf);
			startCharacterLua(gf.curCharacter);
			startCharacterHaxe(gf.curCharacter);
		}

		dad = new Character(0, 0, SONG.player2);
		startCharacterPos(dad, true);
		dadGroup.add(dad);
		startCharacterLua(dad.curCharacter);
		startCharacterHaxe(dad.curCharacter);

		boyfriend = new Character(0, 0, SONG.player1, true);
		startCharacterPos(boyfriend);
		boyfriendGroup.add(boyfriend);
		startCharacterLua(boyfriend.curCharacter);
		startCharacterHaxe(boyfriend.curCharacter);

		var camPos:FlxPoint = new FlxPoint(girlfriendCameraOffset[0], girlfriendCameraOffset[1]);
		if(gf != null)
		{
			camPos.x += gf.getGraphicMidpoint().x + gf.cameraPosition[0];
			camPos.y += gf.getGraphicMidpoint().y + gf.cameraPosition[1];
		}

		if(dad.curCharacter.startsWith('gf')) {
			dad.setPosition(GF_X, GF_Y);
			if(gf != null)
				gf.visible = false;
		}

		switch(curStage)
		{
			case 'schoolEvil':
				var evilTrail = new FlxTrail(dad, null, 4, 24, 0.3, 0.069); //nice
				addBehindDad(evilTrail);
		}


		stage.createPost();

		if (stage.sendMessage)
		{
			if (stage.messageText.length > 1)
				addTextToDebug(stage.messageText, FlxColor.WHITE);
		}

		var file:String = Paths.json(songName + '/dialogue'); //Checks for json/Psych Engine dialogue
		if (OpenFlAssets.exists(file)) {
			dialogueJson = DialogueBoxPsych.parseDialogue(file);
		}

		var file:String = Paths.txt(songName + '/' + songName + 'Dialogue'); //Checks for vanilla/Senpai dialogue
		if (OpenFlAssets.exists(file)) {
			dialogue = CoolUtil.coolTextFile(file);
		}
		var doof:DialogueBox = new DialogueBox(false, dialogue);
		// doof.x += 70;
		// doof.y = FlxG.height * 0.5;
		doof.scrollFactor.set();
		doof.finishThing = startCountdown;
		doof.nextDialogueThing = startNextDialogue;
		doof.skipDialogueThing = skipDialogue;

		Conductor.songPosition = -5000 / Conductor.songPosition;

		strumLine = new FlxSprite(ClientPrefs.middleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X, 50).makeGraphic(FlxG.width, 10);
		if(ClientPrefs.downScroll) strumLine.y = FlxG.height - 150;
		strumLine.scrollFactor.set();

		var showTime:Bool = (ClientPrefs.timeBarType != 'Disabled');
		timeTxt = new FlxText(STRUM_X + (FlxG.width / 2) - 248, 19, 400, "", 32);
		timeTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		timeTxt.scrollFactor.set();
		timeTxt.alpha = 0;
		timeTxt.borderSize = 2;
		timeTxt.visible = showTime;
		if(ClientPrefs.downScroll) timeTxt.y = FlxG.height - 44;

		if(ClientPrefs.timeBarType == 'Song Name')
		{
			timeTxt.text = SONG.song;
		}
		updateTime = showTime;

		timeBarBG = new AttachedSprite('timeBar');
		timeBarBG.x = timeTxt.x;
		timeBarBG.y = timeTxt.y + (timeTxt.height / 4);
		timeBarBG.scrollFactor.set();
		timeBarBG.alpha = 0;
		timeBarBG.visible = showTime;
		timeBarBG.color = FlxColor.BLACK;
		timeBarBG.xAdd = -4;
		timeBarBG.yAdd = -4;
		add(timeBarBG);

		timeBar = new FlxBar(timeBarBG.x + 4, timeBarBG.y + 4, LEFT_TO_RIGHT, Std.int(timeBarBG.width - 8), Std.int(timeBarBG.height - 8), this,
			'songPercent', 0, 1);
		timeBar.scrollFactor.set();
		timeBar.createFilledBar(0xFF000000, 0xFFFFFFFF);
		timeBar.numDivisions = 800; //How much lag this causes?? Should i tone it down to idk, 400 or 200?
		timeBar.alpha = 0;
		timeBar.visible = showTime;
		add(timeBar);
		add(timeTxt);
		timeBarBG.sprTracker = timeBar;
		fakeStrumLineNotes = new FlxTypedGroup<StrumNote>();
		add(fakeStrumLineNotes);

		strumLineNotes = new FlxTypedGroup<StrumNote>();
		add(strumLineNotes);

		add(grpNoteSplashes);

		if(ClientPrefs.timeBarType == 'Song Name')
		{
			timeTxt.size = 24;
			timeTxt.y += 3;
		}

		var splash:NoteSplash = new NoteSplash(100, 100, 0);
		grpNoteSplashes.add(splash);
		splash.alpha = 0.0;

		generateSong(SONG.song);


		opponentStrums = new StrumLineNote([dad], true);
		opponentStrums.autoplay = !opponentControlled;

		playerStrums = new StrumLineNote([boyfriend], false);
		playerStrums.autoplay = (cpuControlled || opponentControlled);

		opponentFakeStrums = new StrumLineNote([gf], true);
		playerFakeStrums = new StrumLineNote([getLuaCharacter('mom')], true);

		generateStaticArrows(0, dadArrowSkin, dadArrowStyle);
		generateStaticArrows(1, boyfriendArrowSkin, boyfriendArrowStyle);
		generateStaticFakeArrows(0, gfArrowSkin, gfArrowStyle);
		generateStaticFakeArrows(1, momArrowSkin, momArrowStyle);

		// After all characters being loaded, it makes then invisible 0.01s later so that the player won't freeze when you change characters
		// add(strumLine);

		camFollow = new FlxPoint();
		camFollowPos = new FlxObject(0, 0, 1, 1);

		snapCamFollowToPos(camPos.x, camPos.y);
		if (prevCamFollow != null)
		{
			camFollow = prevCamFollow;
			prevCamFollow = null;
		}
		if (prevCamFollowPos != null)
		{
			camFollowPos = prevCamFollowPos;
			prevCamFollowPos = null;
		}
		add(camFollowPos);

		FlxG.camera.follow(camFollowPos, LOCKON, 1);
		// FlxG.camera.setScrollBounds(0, FlxG.width, 0, FlxG.height);
		FlxG.camera.zoom = defaultCamZoom;
		FlxG.camera.focusOn(camFollow);

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

		FlxG.fixedTimestep = false;

		healthBarBG = new AttachedSprite('healthBar');
		healthBarBG.y = FlxG.height * 0.89;
		healthBarBG.screenCenter(X);
		healthBarBG.scrollFactor.set();
		healthBarBG.visible = !ClientPrefs.hideHud;
		healthBarBG.xAdd = -4;
		healthBarBG.yAdd = -4;
		add(healthBarBG);
		if(ClientPrefs.downScroll) healthBarBG.y = 0.11 * FlxG.height;

		healthBar = new FlxBar(healthBarBG.x + 4, healthBarBG.y + 4, RIGHT_TO_LEFT, Std.int(healthBarBG.width - 8), Std.int(healthBarBG.height - 8), this,
			'health', 0, 2);
		healthBar.scrollFactor.set();
		// healthBar
		healthBar.visible = !ClientPrefs.hideHud;
		healthBar.alpha = ClientPrefs.healthBarAlpha;
		add(healthBar);
		healthBarBG.sprTracker = healthBar;

		iconP1 = new HealthIcon(boyfriend.healthIcon, true);
		iconP1.y = healthBar.y - 75;
		iconP1.visible = !ClientPrefs.hideHud;
		iconP1.alpha = ClientPrefs.healthBarAlpha;
		add(iconP1);

		iconP2 = new HealthIcon(dad.healthIcon, false);
		iconP2.y = healthBar.y - 75;
		iconP2.visible = !ClientPrefs.hideHud;
		iconP2.alpha = ClientPrefs.healthBarAlpha;
		add(iconP2);

		if(opponentControlled)
		{
			iconP2.changeIcon(boyfriend.healthIcon);
			iconP1.changeIcon(dad.healthIcon);
		}
		else
		{
			iconP2.changeIcon(dad.healthIcon);
			iconP1.changeIcon(boyfriend.healthIcon);
		}
		reloadHealthBarColors();

		scoreTxt = new FlxText(0, healthBarBG.y + 36, FlxG.width, "", 20);
		scoreTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scoreTxt.scrollFactor.set();
		scoreTxt.borderSize = 1.25;
		scoreTxt.visible = !ClientPrefs.hideHud;
		add(scoreTxt);

		botplayTxt = new FlxText(400, timeBarBG.y + 55, FlxG.width - 800, "BOTPLAY", 32);
		botplayTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		botplayTxt.scrollFactor.set();
		botplayTxt.borderSize = 1.25;
		botplayTxt.visible = cpuControlled;
		add(botplayTxt);
		if(ClientPrefs.downScroll) {
			botplayTxt.y = timeBarBG.y - 78;
		}

		moveCameraSection();

		strumLineNotes.cameras = [camHUD];
		fakeStrumLineNotes.cameras = [camHUD];
		fakeNotes.cameras = [camHUD];
		notes.cameras = [camHUD];
		grpNoteSplashes.cameras = [camHUD];
		healthBar.cameras = [camHUD];
		healthBarBG.cameras = [camHUD];
		iconP1.cameras = [camHUD];
		iconP2.cameras = [camHUD];
		scoreTxt.cameras = [camHUD];
		botplayTxt.cameras = [camHUD];
		timeBar.cameras = [camHUD];
		timeBarBG.cameras = [camHUD];
		timeTxt.cameras = [camHUD];
		doof.cameras = [camHUD];

		// if (SONG.song == 'South')
		// FlxG.camera.alpha = 0.7;
		// UI_camera.zoom = 1;

		// cameras = [FlxG.cameras.list[1]];
		startingSong = true;
		
		
		for (notetype in noteTypeMap.keys())
		{
			FunkinHaxe.callThisScripts(haxeArray, 'custom_notetypes/' + notetype);
			#if LUA_ALLOWED
			FunkinLua.callThisScripts(luaArray, 'custom_notetypes/' + notetype);
			#end
		}
		for (event in eventPushedMap.keys())
		{
			FunkinHaxe.callThisScripts(haxeArray, 'custom_events/' + event);
			#if LUA_ALLOWED
			FunkinLua.callThisScripts(luaArray, 'custom_events/' + event);
			#end
		}
		noteTypeMap.clear();
		noteTypeMap = null;
		eventPushedMap.clear();
		eventPushedMap = null;

		if(eventNotes.length > 1)
		{
			for (event in eventNotes) event.strumTime -= eventNoteEarlyTrigger(event);
			eventNotes.sort(sortByTime);
		}

		var daSong:String = Paths.formatToSongPath(curSong);
		if (isStoryMode && !seenCutscene)
		{
			switch (daSong)
			{
				case "monster":
					var whiteScreen:FlxSprite = new FlxSprite(0, 0).makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.WHITE);
					add(whiteScreen);
					whiteScreen.scrollFactor.set();
					whiteScreen.blend = ADD;
					camHUD.visible = false;
					snapCamFollowToPos(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);
					inCutscene = true;

					FlxTween.tween(whiteScreen, {alpha: 0}, 1, {
						startDelay: 0.1,
						ease: FlxEase.linear,
						onComplete: function(twn:FlxTween)
						{
							camHUD.visible = true;
							remove(whiteScreen);
							startCountdown();
						}
					});
					FlxG.sound.play(Paths.soundRandom('stages/spooky/thunder_', 1, 2));
					if(gf != null) gf.playAnim('scared', true);
					boyfriend.playAnim('scared', true);

				case "winter-horrorland":
					var blackScreen:FlxSprite = new FlxSprite().makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
					add(blackScreen);
					blackScreen.scrollFactor.set();
					camHUD.visible = false;
					inCutscene = true;

					FlxTween.tween(blackScreen, {alpha: 0}, 0.7, {
						ease: FlxEase.linear,
						onComplete: function(twn:FlxTween) {
							remove(blackScreen);
						}
					});
					FlxG.sound.play(Paths.sound('stages/mall/Lights_Turn_On'));
					snapCamFollowToPos(400, -2050);
					FlxG.camera.focusOn(camFollow);
					FlxG.camera.zoom = 1.5;

					new FlxTimer().start(0.8, function(tmr:FlxTimer)
					{
						camHUD.visible = true;
						remove(blackScreen);
						FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, 2.5, {
							ease: FlxEase.quadInOut,
							onComplete: function(twn:FlxTween)
							{
								startCountdown();
							}
						});
					});
				case 'senpai' | 'roses' | 'thorns':
					if(daSong == 'roses') FlxG.sound.play(Paths.sound('stages/school/ANGRY_TEXT_BOX'));
					schoolIntro(doof);

				case 'ugh' | 'guns' | 'stress':
					tankIntro();

				default:
					startCountdown();
			}
			seenCutscene = true;
		}
		else
		{
			startCountdown();
		}
		RecalculateRating();

		//PRECACHING MISS SOUNDS BECAUSE I THINK THEY CAN LAG PEOPLE AND FUCK THEM UP IDK HOW HAXE WORKS
		if(ClientPrefs.hitsoundVolume > 0) precacheList.set('hitsound', 'sound');
		precacheList.set('missnote1', 'sound');
		precacheList.set('missnote2', 'sound');
		precacheList.set('missnote3', 'sound');

		if (PauseSubState.songName != null) {
			precacheList.set(PauseSubState.songName, 'music');
		} else if(ClientPrefs.pauseMusic != 'None') {
			precacheList.set(Paths.formatToSongPath(ClientPrefs.pauseMusic), 'music');
		}

		precacheList.set('alphabet', 'image');
	
		#if desktop
		// Updating Discord Rich Presence.
		DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
		#end

		if(!ClientPrefs.controllerMode)
		{
			FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
			FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		}
		callOnLuas('onCreatePost', []);
		callOnHaxes('createPost', []);


		/*
		if (stage.sendMessage)
		{
			if (stage.messageText.length > 1)
				addTextToDebug(stage.messageText, FlxColor.WHITE);
		}
		*/

		super.create();

		cacheCountdown();
		cachePopUpScore();
		for (key => type in precacheList)
		{
			//trace('Key $key is type $type');
			switch(type)
			{
				case 'image':
					Paths.image(key);
				case 'sound':
					Paths.sound(key);
				case 'music':
					Paths.music(key);
			}
		}
		Paths.clearUnusedMemory();
		
		CustomFadeTransition.nextCamera = camOther;
		if(eventNotes.length < 1) checkEventNote();

		if(showcaseMode)
		{
			for (i in 0...strumLineNotes.members.length)
			{
				strumLineNotes.members[i].alpha = 0;
			}
			for (i in 0...fakeStrumLineNotes.members.length)
			{
				fakeStrumLineNotes.members[i].alpha = 0;
			}
			for (i in 0...grpNoteSplashes.length)
			{
				grpNoteSplashes.members[i].alpha = 0;
			}
			healthBar.alpha = 0;
			healthBarBG.alpha = 0;
			iconP1.alpha = 0;
			iconP2.alpha = 0;
			scoreTxt.alpha = 0;
			botplayTxt.visible = true;
			botplayTxt.text = 'SHOWCASE';
			timeBar.alpha = 0;
			timeBarBG.alpha = 0;
			timeTxt.alpha = 0;
			
			playerStrums.autoplay = true;
		}
	}

	function loadCharacterData()
	{
		if(SONG.arrowSkin.length > 1)
		{
			boyfriendArrowSkin = SONG.arrowSkin;
			dadArrowSkin = SONG.arrowSkin;
			gfArrowSkin = SONG.arrowSkin;
			momArrowSkin = SONG.arrowSkin;
		}
		else
		{
			boyfriendArrowSkin = boyfriend.arrowSkin;
			dadArrowSkin = dad.arrowSkin;
			if(gf != null)
				gfArrowSkin = gf.arrowSkin;
			else
				gfArrowSkin = dad.arrowSkin;
			
			if(getLuaCharacter('mom') != null)
			{
				momArrowSkin = getLuaCharacter('mom').arrowSkin;
			}
			else
			{
				momArrowSkin = boyfriend.arrowSkin;
			}
		}
		if (SONG.arrowStyle.length > 1)
		{
			boyfriendArrowStyle = SONG.arrowStyle;
			dadArrowStyle = SONG.arrowStyle;
			gfArrowStyle = SONG.arrowStyle;
			momArrowStyle = SONG.arrowStyle;
		}
		else
		{
			boyfriendArrowStyle = boyfriend.arrowStyle;
			dadArrowStyle = dad.arrowStyle;
			if(gf != null)
				gfArrowStyle = gf.arrowStyle;
			else
				gfArrowStyle = dad.arrowStyle;
			if(getLuaCharacter('mom') != null)
			{
				momArrowSkin = getLuaCharacter('mom').arrowSkin;
			}
			else
			{
				momArrowSkin = boyfriend.arrowStyle;
			}
		}
	}


	function createStage(newStage:String, ?swap:Bool = false)
	{
		if(boyfriendLayer != null)
		{
			var i:Int = boyfriendLayer.members.length-1;
			while(i >= 0) {
				var memb:FlxBasic = boyfriendLayer.members[i];
				if(memb != null) {
					memb.kill();
					boyfriendLayer.remove(memb);
					memb.destroy();
				}
				--i;
			}
		}

		if(dadLayer != null)
		{
			var i:Int = dadLayer.members.length-1;
			while(i >= 0) {
				var memb:FlxBasic = dadLayer.members[i];
				if(memb != null) {
					memb.kill();
					dadLayer.remove(memb);
					memb.destroy();
				}
				--i;
			}
		}

		if(gfLayer != null)
		{
			var i:Int = gfLayer.members.length-1;
			while(i >= 0) {
				var memb:FlxBasic = gfLayer.members[i];
				if(memb != null) {
					memb.kill();
					gfLayer.remove(memb);
					memb.destroy();
				}
				--i;
			}
		}


		if(stageGroup != null)
		{
			var i:Int = stageGroup.members.length-1;
			while(i >= 0) {
				var memb:FlxBasic = stageGroup.members[i];
				if(memb != null) {
					memb.kill();
					stageGroup.remove(memb);
					memb.destroy();
				}
				--i;
			}
		}

		loadStageData(newStage, swap);

		stage = new Stage(newStage);
		stageGroup.add(stage);
		gfLayer.add(stage.layers.get('gf'));
		dadLayer.add(stage.layers.get('dad'));
		boyfriendLayer.add(stage.layers.get('boyfriend'));
	}
	

	function loadStageData(stage:String, ?sawp:Bool = false)
	{
		stageData = StageData.getStageFile(stage);
		if(stageData == null) { //Stage couldn't be found, create a dummy stage for preventing a crash
			stageData = {
				directory: "",
				defaultZoom: 0.9,
				isPixelStage: false,

				boyfriend: [770, 100],
				girlfriend: [400, 130],
				opponent: [100, 100],
				hide_girlfriend: false,

				camera_boyfriend: [0, 0],
				camera_opponent: [0, 0],
				camera_girlfriend: [0, 0],
				camera_speed: 1
			};
		}

		defaultCamZoom = stageData.defaultZoom;
		isPixelStage = stageData.isPixelStage;
		BF_X = stageData.boyfriend[0];
		BF_Y = stageData.boyfriend[1];
		GF_X = stageData.girlfriend[0];
		GF_Y = stageData.girlfriend[1];
		DAD_X = stageData.opponent[0];
		DAD_Y = stageData.opponent[1];

		if(boyfriendGroup != null && dadGroup != null && gfGroup != null)
		{
			if(sawp)
			{
				boyfriendGroup.setPosition(DAD_X, DAD_Y);
				dadGroup.setPosition(BF_X, BF_Y);
			}
			else
			{
				boyfriendGroup.setPosition(BF_X, BF_Y);
				dadGroup.setPosition(DAD_X, DAD_Y);
			}
			gfGroup.setPosition(GF_X, GF_Y);
		}

		if(stageData.camera_speed != null)
			cameraSpeed = stageData.camera_speed;

		boyfriendCameraOffset = stageData.camera_boyfriend;
		if(boyfriendCameraOffset == null) //Fucks sake should have done it since the start :rolling_eyes:
			boyfriendCameraOffset = [0, 0];

		opponentCameraOffset = stageData.camera_opponent;
		if(opponentCameraOffset == null)
			opponentCameraOffset = [0, 0];

		girlfriendCameraOffset = stageData.camera_girlfriend;
		if(girlfriendCameraOffset == null)
			girlfriendCameraOffset = [0, 0];
	}
	

	#if (!flash && sys)
	public var runtimeShaders:Map<String, Array<String>> = new Map<String, Array<String>>();
	public function createRuntimeShader(name:String):FlxRuntimeShader
	{
		if(!ClientPrefs.shaders) return new FlxRuntimeShader();

		#if (!flash && MODS_ALLOWED && sys)
		if(!runtimeShaders.exists(name) && !initLuaShader(name))
		{
			FlxG.log.warn('Shader $name is missing!');
			return new FlxRuntimeShader();
		}

		var arr:Array<String> = runtimeShaders.get(name);
		return new FlxRuntimeShader(arr[0], arr[1]);
		#else
		FlxG.log.warn("Platform unsupported for Runtime Shaders!");
		return null;
		#end
	}

	public function initLuaShader(name:String, ?glslVersion:Int = 120)
	{
		if(!ClientPrefs.shaders) return false;

		if(runtimeShaders.exists(name))
		{
			FlxG.log.warn('Shader $name was already initialized!');
			return true;
		}

		var foldersToCheck:Array<String> = [Paths.mods('shaders/')];
		if(Paths.currentModDirectory != null && Paths.currentModDirectory.length > 0)
			foldersToCheck.insert(0, Paths.mods(Paths.currentModDirectory + '/shaders/'));

		for(mod in Paths.getGlobalMods())
			foldersToCheck.insert(0, Paths.mods(mod + '/shaders/'));
		
		for (folder in foldersToCheck)
		{
			if(FileSystem.exists(folder))
			{
				var frag:String = folder + name + '.frag';
				var vert:String = folder + name + '.vert';
				var found:Bool = false;
				if(FileSystem.exists(frag))
				{
					frag = File.getContent(frag);
					found = true;
				}
				else frag = null;

				if (FileSystem.exists(vert))
				{
					vert = File.getContent(vert);
					found = true;
				}
				else vert = null;

				if(found)
				{
					runtimeShaders.set(name, [frag, vert]);
					//trace('Found shader $name!');
					return true;
				}
			}
		}
		FlxG.log.warn('Missing shader $name .frag AND .vert files!');
		return false;
	}
	#end

	function set_songSpeed(value:Float):Float
	{
		if(generatedMusic)
		{
			var ratio:Float = value / songSpeed; //funny word huh
			for (note in notes) note.resizeByRatio(ratio);
			for (note in notes) note.resizeByRatio(ratio);
			for (note in unspawnNotes) note.resizeByRatio(ratio);
			for (note in unspawnFakeNotes) note.resizeByRatio(ratio);
		}
		songSpeed = value;
		noteKillOffset = 350 / songSpeed;
		return value;
	}

	function set_playbackRate(value:Float):Float
	{
		if(generatedMusic)
		{
			if(vocals != null) vocals.pitch = value;
			if(vocalsBoyfriend != null)
			{
				for(boyfriend in vocalsBoyfriend)
				{
					boyfriend.pitch = value;
				}
			}
			if(vocalsDad != null)
			{
				for(dad in vocalsDad)
				{
					dad.pitch = value;
				}
			}
			FlxG.sound.music.pitch = value;
		}
		playbackRate = value;
		FlxAnimationController.globalSpeed = value;
		trace('Anim speed: ' + FlxAnimationController.globalSpeed);
		Conductor.safeZoneOffset = (ClientPrefs.safeFrames / 60) * 1000 * value;
		setOnLuas('playbackRate', playbackRate);
		setOnHaxes('playbackRate', playbackRate);
		return value;
	}

	public function addTextToDebug(text:String, color:FlxColor) {
		luaDebugGroup.forEachAlive(function(spr:DebugLuaText) {
			spr.y += 20;
		});

		if(luaDebugGroup.members.length > 34) {
			var blah = luaDebugGroup.members[34];
			blah.destroy();
			luaDebugGroup.remove(blah);
		}
		luaDebugGroup.insert(0, new DebugLuaText(text, luaDebugGroup, color));
	}

	public function reloadHealthBarColors() {
		var dadColor:FlxColor = FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]);
		var boyfriendColor:FlxColor = FlxColor.fromRGB(boyfriend.healthColorArray[0], boyfriend.healthColorArray[1], boyfriend.healthColorArray[2]);
		if(opponentControlled)
			healthBar.createFilledBar(boyfriendColor, dadColor);
		else
			healthBar.createFilledBar(dadColor, boyfriendColor);

		healthBar.updateBar();
	}

	public function addCharacterToList(newCharacter:String, type:Int, ?isPlayer:Bool = false) {
		switch(type) {
			case 0:
				if(!boyfriendMap.exists(newCharacter)) {
					var newBoyfriend:Character = new Character(0, 0, newCharacter, !isPlayer);
					boyfriendMap.set(newCharacter, newBoyfriend);
					boyfriendGroup.add(newBoyfriend);
					startCharacterPos(newBoyfriend);
					newBoyfriend.alpha = 0.00001;
					startCharacterLua(newBoyfriend.curCharacter);
					startCharacterHaxe(newBoyfriend.curCharacter);
				}

			case 1:
				if(!dadMap.exists(newCharacter)) {
					var newDad:Character = new Character(0, 0, newCharacter, isPlayer);
					dadMap.set(newCharacter, newDad);
					dadGroup.add(newDad);
					startCharacterPos(newDad, true);
					newDad.alpha = 0.00001;
					startCharacterLua(newDad.curCharacter);
					startCharacterHaxe(newDad.curCharacter);
				}

			case 2:
				if(gf != null && !gfMap.exists(newCharacter)) {
					var newGf:Character = new Character(0, 0, newCharacter, isPlayer);
					newGf.scrollFactor.set(0.95, 0.95);
					gfMap.set(newCharacter, newGf);
					gfGroup.add(newGf);
					startCharacterPos(newGf);
					newGf.alpha = 0.00001;
					startCharacterLua(newGf.curCharacter);
					startCharacterHaxe(newGf.curCharacter);
				}
			case 3:
				addCharacterLuaToList(newCharacter, 'mom', !isPlayer);
		}
	}

	public function addCharacterLuaToList(newCharacter:String, type:String, ?isPlayer:Bool = false) {
		if(modchartGroups.exists(type + 'Group') && modchartCharacters.exists(type)) {
			var shitGroup:ModchartGroup = modchartGroups.get(type + 'Group');
			var shit:ModchartCharacter = modchartCharacters.get(type);
			if(!characterMap.exists(newCharacter + 'new')) {
				var newChar:ModchartCharacter = new ModchartCharacter(0, 0, newCharacter, isPlayer);
				characterMap.set(newCharacter, newChar);
				shitGroup.add(newChar);
				startCharacterPos(newChar, !isPlayer);
				newChar.alpha = 0.00001;
				startCharacterLua(newChar.curCharacter);
				startCharacterHaxe(newChar.curCharacter);
			}
		}
	}


	public function startCharacterLua(name:String)
	{
		#if LUA_ALLOWED
		var doPush:Bool = false;
		var luaFile:String = 'characters/' + name + '.lua';
		#if MODS_ALLOWED
		if(FileSystem.exists(Paths.modFolders(luaFile))) {
			luaFile = Paths.modFolders(luaFile);
			doPush = true;
		} else {
			luaFile = Paths.getPreloadPath(luaFile);
			if(FileSystem.exists(luaFile)) {
				doPush = true;
			}
		}
		#else
		luaFile = Paths.getPreloadPath(luaFile);
		if(Assets.exists(luaFile)) {
			doPush = true;
		}
		#end

		if(doPush)
		{
			for (script in luaArray)
			{
				if(script.scriptName == luaFile) return;
			}
			luaArray.push(new FunkinLua(luaFile));
		}
		#end
	}

	public function startCharacterHaxe(name:String)
	{
		var scriptExts:Array<String> = ['hx', 'hxs', 'hscript', 'hxc'];
		var doPush:Bool = false;
		for (ext in scriptExts)
		{
			var luaFile:String = 'characters/' + name + '.$ext';
			#if MODS_ALLOWED
			if(FileSystem.exists(Paths.modFolders(luaFile))) {
				luaFile = Paths.modFolders(luaFile);
				doPush = true;
			} else {
				luaFile = Paths.getPreloadPath(luaFile);
				if(FileSystem.exists(luaFile)) {
					doPush = true;
				}
			}
			#else
			luaFile = Paths.getPreloadPath(luaFile);
			if(Assets.exists(luaFile)) {
				doPush = true;
			}
			#end
	
			if(doPush)
			{
				for (script in haxeArray)
				{
					if(script.scriptName == luaFile) return;
				}
				haxeArray.push(new FunkinHaxe(luaFile));
			}
		}

	}
	public var skipArrowStartTween:Bool = false; //for lua
	public var keyAmonut:Int = 4;
	private function generateStaticArrows(player:Int, arrowSkin:String, arrowStyle:String):Void
	{
		for (i in 0...keyAmonut)
		{
			var targetAlpha:Float = 1;
			var playerSwap:Int = 1;
			switch(player)
			{
				default:
					if(!opponentControlled && !ClientPrefs.opponentStrums) targetAlpha = 0;
					else if(!opponentControlled && ClientPrefs.middleScroll) targetAlpha = 0.35;
				case 1:
					if(opponentControlled && !ClientPrefs.opponentStrums) targetAlpha = 0;
					else if(opponentControlled && ClientPrefs.middleScroll) targetAlpha = 0.35;
			}

			switch(player)
			{
				default:
					if(opponentControlled && ClientPrefs.middleScroll) 
						playerSwap = 1;
					else 
						playerSwap = 0;
				case 1:
					if(opponentControlled && ClientPrefs.middleScroll) 
						playerSwap = 0;
					else 
						playerSwap = 1;
			}
			
			var babyArrow:StrumNote = new StrumNote(ClientPrefs.middleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X, strumLine.y, i, playerSwap, arrowSkin, arrowStyle);
			babyArrow.downScroll = ClientPrefs.downScroll;
			if (!isStoryMode && !skipArrowStartTween)
			{
				//babyArrow.y -= 10;
				babyArrow.alpha = 0;
				FlxTween.tween(babyArrow, {/*y: babyArrow.y + 10,*/ alpha: targetAlpha}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * i)});
			}
			else
			{
				babyArrow.alpha = targetAlpha;
			}

			switch(player)
			{
				default:
					if(!opponentControlled && ClientPrefs.middleScroll)
					{
						babyArrow.x += 310;
						if(i > 1) { //Up and Right
							babyArrow.x += FlxG.width / 2 + 25;
						}
					}
					opponentStrums.add(babyArrow);
				case 1:
					if(opponentControlled && ClientPrefs.middleScroll)
					{
						babyArrow.x += 310;
						if(i > 1) { //Up and Right
							babyArrow.x += FlxG.width / 2 + 25;
						}
					}

					playerStrums.add(babyArrow);
			}

			strumLineNotes.add(babyArrow);
			babyArrow.postAddedToGroup();			
		}
	}

	private function generateStaticFakeArrows(player:Int, arrowSkin:String, arrowStyle:String):Void
	{
		for (i in 0...keyAmonut)
		{
			var targetAlpha:Float = 0;
			var babyArrow:StrumNote = new StrumNote(ClientPrefs.middleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X, strumLine.y, i, player, arrowSkin, arrowStyle);
			babyArrow.downScroll = ClientPrefs.downScroll;
			if (!isStoryMode && !skipArrowStartTween)
			{
				//babyArrow.y -= 10;
				babyArrow.alpha = 0;
				FlxTween.tween(babyArrow, {/*y: babyArrow.y + 10,*/ alpha: targetAlpha}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * i)});
			}
			else
			{
				babyArrow.alpha = targetAlpha;
			}

			if (player == 1)
			{
				playerFakeStrums.add(babyArrow);
			}
			else
			{
				if(ClientPrefs.middleScroll)
				{
					babyArrow.x += 310;
					if(i > 1) { //Up and Right
						babyArrow.x += FlxG.width / 2 + 25;
					}
				}
				opponentFakeStrums.add(babyArrow);
			}

			fakeStrumLineNotes.add(babyArrow);
			babyArrow.postAddedToGroup();			
		}
	}

	public function getLuaGroup(tag:String):Dynamic {
		if(modchartGroupTypes.exists(tag)) return modchartGroupTypes.get(tag);
		if(modchartGroups.exists(tag)) return modchartGroups.get(tag);
		return null;
	}


	public function getLuaObject(tag:String, text:Bool=true):Dynamic {
		if(modchartGroupTypes.exists(tag)) return modchartGroupTypes.get(tag);
		if(modchartGroups.exists(tag)) return modchartGroups.get(tag);
		if(modchartHealthIcons.exists(tag)) return modchartHealthIcons.get(tag);
		if(modchartCharacters.exists(tag)) return modchartCharacters.get(tag);
		if(modchartSprites.exists(tag)) return modchartSprites.get(tag);
		if(text && modchartTexts.exists(tag)) return modchartTexts.get(tag);
		if(variables.exists(tag)) return variables.get(tag);
		return null;
	}

	public function getLuaCharacter(tag:String, text:Bool=true):Character {
		if(modchartCharacters.exists(tag)) return modchartCharacters.get(tag);
		return null;
	}

	public function startCharacterPos(char:Character, ?gfCheck:Bool = false) {
		if(gfCheck && char.curCharacter.startsWith('gf')) { //IF DAD IS GIRLFRIEND, HE GOES TO HER POSITION
			char.setPosition(GF_X, GF_Y);
			char.scrollFactor.set(0.95, 0.95);
			char.danceEveryNumBeats = 2;
		}
		if(char.isPlayer)
		{
			char.x += char.playerPositionArray[0];
			char.y += char.playerPositionArray[1];
		}
		else
		{
			char.x += char.positionArray[0];
			char.y += char.positionArray[1];
		}

	}

	public function startVideo(name:String)
	{
		#if VIDEOS_ALLOWED
		inCutscene = true;

		var filepath:String = Paths.video(name);
		#if sys
		if(!FileSystem.exists(filepath))
		#else
		if(!OpenFlAssets.exists(filepath))
		#end
		{
			FlxG.log.warn('Couldnt find video file: ' + name);
			startAndEnd();
			return;
		}

		var video:MP4Handler = new MP4Handler();
		video.playVideo(filepath);
		video.finishCallback = function()
		{
			startAndEnd();
			return;
		}
		#else
		FlxG.log.warn('Platform not supported!');
		startAndEnd();
		return;
		#end
	}

	function startAndEnd()
	{
		if(endingSong)
			endSong();
		else
			startCountdown();
	}

	var dialogueCount:Int = 0;
	public var psychDialogue:DialogueBoxPsych;
	//You don't have to add a song, just saying. You can just do "startDialogue(dialogueJson);" and it should work
	public function startDialogue(dialogueFile:DialogueFile, ?song:String = null):Void
	{
		// TO DO: Make this more flexible, maybe?
		if(psychDialogue != null) return;

		if(dialogueFile.dialogue.length > 0) {
			inCutscene = true;
			precacheList.set('dialogue', 'sound');
			precacheList.set('dialogueClose', 'sound');
			psychDialogue = new DialogueBoxPsych(dialogueFile, song);
			psychDialogue.scrollFactor.set();
			if(endingSong) {
				psychDialogue.finishThing = function() {
					psychDialogue = null;
					endSong();
				}
			} else {
				psychDialogue.finishThing = function() {
					psychDialogue = null;
					startCountdown();
				}
			}
			psychDialogue.nextDialogueThing = startNextDialogue;
			psychDialogue.skipDialogueThing = skipDialogue;
			psychDialogue.cameras = [camHUD];
			add(psychDialogue);
		} else {
			FlxG.log.warn('Your dialogue file is badly formatted!');
			if(endingSong) {
				endSong();
			} else {
				startCountdown();
			}
		}
	}

	function schoolIntro(?dialogueBox:DialogueBox):Void
	{
		inCutscene = true;
		var black:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
		black.scrollFactor.set();
		add(black);

		var red:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, 0xFFff1b31);
		red.scrollFactor.set();

		var senpaiEvil:FlxSprite = new FlxSprite();
		senpaiEvil.frames = Paths.getSparrowAtlas('stages/school/senpaiCrazy');
		senpaiEvil.animation.addByPrefix('idle', 'Senpai Pre Explosion', 24, false);
		senpaiEvil.setGraphicSize(Std.int(senpaiEvil.width * 6));
		senpaiEvil.scrollFactor.set();
		senpaiEvil.updateHitbox();
		senpaiEvil.screenCenter();
		senpaiEvil.x += 300;

		var songName:String = Paths.formatToSongPath(SONG.song);
		if (songName == 'roses' || songName == 'thorns')
		{
			remove(black);

			if (songName == 'thorns')
			{
				add(red);
				camHUD.visible = false;
			}
		}

		new FlxTimer().start(0.3, function(tmr:FlxTimer)
		{
			black.alpha -= 0.15;

			if (black.alpha > 0)
			{
				tmr.reset(0.3);
			}
			else
			{
				if (dialogueBox != null)
				{
					if (Paths.formatToSongPath(SONG.song) == 'thorns')
					{
						add(senpaiEvil);
						senpaiEvil.alpha = 0;
						new FlxTimer().start(0.3, function(swagTimer:FlxTimer)
						{
							senpaiEvil.alpha += 0.15;
							if (senpaiEvil.alpha < 1)
							{
								swagTimer.reset();
							}
							else
							{
								senpaiEvil.animation.play('idle');
								FlxG.sound.play(Paths.sound('stages/school/Senpai_Dies'), 1, false, null, true, function()
								{
									remove(senpaiEvil);
									remove(red);
									FlxG.camera.fade(FlxColor.WHITE, 0.01, true, function()
									{
										add(dialogueBox);
										camHUD.visible = true;
									}, true);
								});
								new FlxTimer().start(3.2, function(deadTime:FlxTimer)
								{
									FlxG.camera.fade(FlxColor.WHITE, 1.6, false);
								});
							}
						});
					}
					else
					{
						add(dialogueBox);
					}
				}
				else
					startCountdown();

				remove(black);
			}
		});
	}

	function tankIntro()
	{
		var cutsceneHandler:CutsceneHandler = new CutsceneHandler();

		var songName:String = Paths.formatToSongPath(SONG.song);
		dadGroup.alpha = 0.00001;
		camHUD.visible = false;
		//inCutscene = true; //this would stop the camera movement, oops

		var tankman:FlxSprite = new FlxSprite(-20, 320);
		tankman.frames = Paths.getSparrowAtlas('stages/tank/cutscenes/' + songName);
		tankman.antialiasing = ClientPrefs.globalAntialiasing;
		addBehindDad(tankman);
		cutsceneHandler.push(tankman);

		var tankman2:FlxSprite = new FlxSprite(16, 312);
		tankman2.antialiasing = ClientPrefs.globalAntialiasing;
		tankman2.alpha = 0.000001;
		cutsceneHandler.push(tankman2);
		var gfDance:FlxSprite = new FlxSprite(gf.x - 107, gf.y + 140);
		gfDance.antialiasing = ClientPrefs.globalAntialiasing;
		cutsceneHandler.push(gfDance);
		var gfCutscene:FlxSprite = new FlxSprite(gf.x - 104, gf.y + 122);
		gfCutscene.antialiasing = ClientPrefs.globalAntialiasing;
		cutsceneHandler.push(gfCutscene);
		var picoCutscene:FlxSprite = new FlxSprite(gf.x - 849, gf.y - 264);
		picoCutscene.antialiasing = ClientPrefs.globalAntialiasing;
		cutsceneHandler.push(picoCutscene);
		var boyfriendCutscene:FlxSprite = new FlxSprite(boyfriend.x + 5, boyfriend.y + 20);
		boyfriendCutscene.antialiasing = ClientPrefs.globalAntialiasing;
		cutsceneHandler.push(boyfriendCutscene);

		cutsceneHandler.finishCallback = function()
		{
			var timeForStuff:Float = Conductor.crochet / 1000 * 4.5;
			FlxG.sound.music.fadeOut(timeForStuff);
			FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, timeForStuff, {ease: FlxEase.quadInOut});
			moveCamera(true);
			startCountdown();

			dadGroup.alpha = 1;
			camHUD.visible = true;
			boyfriend.animation.finishCallback = null;
			gf.animation.finishCallback = null;
			gf.dance();
		};

		camFollow.set(dad.x + 280, dad.y + 170);
		switch(songName)
		{
			case 'ugh':
				cutsceneHandler.endTime = 12;
				cutsceneHandler.music = 'DISTORTO';
				precacheList.set('wellWellWell', 'sound');
				precacheList.set('killYou', 'sound');
				precacheList.set('bfBeep', 'sound');

				var wellWellWell:FlxSound = new FlxSound().loadEmbedded(Paths.sound('stages/tank/wellWellWell'));
				FlxG.sound.list.add(wellWellWell);

				tankman.animation.addByPrefix('wellWell', 'TANK TALK 1 P1', 24, false);
				tankman.animation.addByPrefix('killYou', 'TANK TALK 1 P2', 24, false);
				tankman.animation.play('wellWell', true);
				FlxG.camera.zoom *= 1.2;

				// Well well well, what do we got here?
				cutsceneHandler.timer(0.1, function()
				{
					wellWellWell.play(true);
				});

				// Move camera to BF
				cutsceneHandler.timer(3, function()
				{
					camFollow.x += 750;
					camFollow.y += 100;
				});

				// Beep!
				cutsceneHandler.timer(4.5, function()
				{
					boyfriend.playAnim('singUP', true);
					boyfriend.specialAnim = true;
					FlxG.sound.play(Paths.sound('stages/tank/bfBeep'));
				});

				// Move camera to Tankman
				cutsceneHandler.timer(6, function()
				{
					camFollow.x -= 750;
					camFollow.y -= 100;

					// We should just kill you but... what the hell, it's been a boring day... let's see what you've got!
					tankman.animation.play('killYou', true);
					FlxG.sound.play(Paths.sound('stages/tank/killYou'));
				});

			case 'guns':
				cutsceneHandler.endTime = 11.5;
				cutsceneHandler.music = 'stages/tank/DISTORTO';
				tankman.x += 40;
				tankman.y += 10;
				precacheList.set('stages/tank/tankSong2', 'sound');

				var tightBars:FlxSound = new FlxSound().loadEmbedded(Paths.sound('stages/tank/tankSong2'));
				FlxG.sound.list.add(tightBars);

				tankman.animation.addByPrefix('tightBars', 'TANK TALK 2', 24, false);
				tankman.animation.play('tightBars', true);
				boyfriend.animation.curAnim.finish();

				cutsceneHandler.onStart = function()
				{
					tightBars.play(true);
					FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom * 1.2}, 4, {ease: FlxEase.quadInOut});
					FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom * 1.2 * 1.2}, 0.5, {ease: FlxEase.quadInOut, startDelay: 4});
					FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom * 1.2}, 1, {ease: FlxEase.quadInOut, startDelay: 4.5});
				};

				cutsceneHandler.timer(4, function()
				{
					gf.playAnim('sad', true);
					gf.animation.finishCallback = function(name:String)
					{
						gf.playAnim('sad', true);
					};
				});

			case 'stress':
				cutsceneHandler.endTime = 35.5;
				tankman.x -= 54;
				tankman.y -= 14;
				gfGroup.alpha = 0.00001;
				boyfriendGroup.alpha = 0.00001;
				camFollow.set(dad.x + 400, dad.y + 170);
				FlxTween.tween(FlxG.camera, {zoom: 0.9 * 1.2}, 1, {ease: FlxEase.quadInOut});
				precacheList.set('stressCutscene', 'sound');

				tankman2.frames = Paths.getSparrowAtlas('stages/tank/cutscenes/stress2');
				addBehindDad(tankman2);

				if (!ClientPrefs.lowQuality)
				{
					gfDance.frames = Paths.getSparrowAtlas('stages/tank/characters/gfTankmen');
					gfDance.animation.addByPrefix('dance', 'GF Dancing at Gunpoint', 24, true);
					gfDance.animation.play('dance', true);
					addBehindGF(gfDance);
				}

				gfCutscene.frames = Paths.getSparrowAtlas('stages/tank/cutscenes/stressGF');
				gfCutscene.animation.addByPrefix('dieBitch', 'GF STARTS TO TURN PART 1', 24, false);
				gfCutscene.animation.addByPrefix('getRektLmao', 'GF STARTS TO TURN PART 2', 24, false);
				gfCutscene.animation.play('dieBitch', true);
				gfCutscene.animation.pause();
				addBehindGF(gfCutscene);
				if (!ClientPrefs.lowQuality)
				{
					gfCutscene.alpha = 0.00001;
				}

				picoCutscene.frames = AtlasFrameMaker.construct('stages/tank/cutscenes/stressPico');
				picoCutscene.animation.addByPrefix('anim', 'Pico Badass', 24, false);
				addBehindGF(picoCutscene);
				picoCutscene.alpha = 0.00001;

				boyfriendCutscene.frames = Paths.getSparrowAtlas('characters/BOYFRIEND');
				boyfriendCutscene.animation.addByPrefix('idle', 'BF idle dance', 24, false);
				boyfriendCutscene.animation.play('idle', true);
				boyfriendCutscene.animation.curAnim.finish();
				addBehindBF(boyfriendCutscene);

				var cutsceneSnd:FlxSound = new FlxSound().loadEmbedded(Paths.sound('stages/tank/stressCutscene'));
				FlxG.sound.list.add(cutsceneSnd);

				tankman.animation.addByPrefix('godEffingDamnIt', 'TANK TALK 3', 24, false);
				tankman.animation.play('godEffingDamnIt', true);

				var calledTimes:Int = 0;
				var zoomBack:Void->Void = function()
				{
					var camPosX:Float = 630;
					var camPosY:Float = 425;
					camFollow.set(camPosX, camPosY);
					camFollowPos.setPosition(camPosX, camPosY);
					FlxG.camera.zoom = 0.8;
					cameraSpeed = 1;

					calledTimes++;
				}

				cutsceneHandler.onStart = function()
				{
					cutsceneSnd.play(true);
				};

				cutsceneHandler.timer(15.2, function()
				{
					FlxTween.tween(camFollow, {x: 650, y: 300}, 1, {ease: FlxEase.sineOut});
					FlxTween.tween(FlxG.camera, {zoom: 0.9 * 1.2 * 1.2}, 2.25, {ease: FlxEase.quadInOut});

					gfDance.visible = false;
					gfCutscene.alpha = 1;
					gfCutscene.animation.play('dieBitch', true);
					gfCutscene.animation.finishCallback = function(name:String)
					{
						if(name == 'dieBitch') //Next part
						{
							gfCutscene.animation.play('getRektLmao', true);
							gfCutscene.offset.set(224, 445);
						}
						else
						{
							gfCutscene.visible = false;
							picoCutscene.alpha = 1;
							picoCutscene.animation.play('anim', true);

							boyfriendGroup.alpha = 1;
							boyfriendCutscene.visible = false;
							boyfriend.playAnim('bfCatch', true);
							boyfriend.animation.finishCallback = function(name:String)
							{
								if(name != 'idle')
								{
									boyfriend.playAnim('idle', true);
									boyfriend.animation.curAnim.finish(); //Instantly goes to last frame
								}
							};

							picoCutscene.animation.finishCallback = function(name:String)
							{
								picoCutscene.visible = false;
								gfGroup.alpha = 1;
								picoCutscene.animation.finishCallback = null;
							};
							gfCutscene.animation.finishCallback = null;
						}
					};
				});

				cutsceneHandler.timer(17.5, function()
				{
					zoomBack();
				});

				cutsceneHandler.timer(19.5, function()
				{
					tankman2.animation.addByPrefix('lookWhoItIs', 'TANK TALK 3', 24, false);
					tankman2.animation.play('lookWhoItIs', true);
					tankman2.alpha = 1;
					tankman.visible = false;
				});

				cutsceneHandler.timer(20, function()
				{
					camFollow.set(dad.x + 500, dad.y + 170);
				});

				cutsceneHandler.timer(31.2, function()
				{
					boyfriend.playAnim('singUPmiss', true);
					boyfriend.animation.finishCallback = function(name:String)
					{
						if (name == 'singUPmiss')
						{
							boyfriend.playAnim('idle', true);
							boyfriend.animation.curAnim.finish(); //Instantly goes to last frame
						}
					};

					camFollow.set(boyfriend.x + 280, boyfriend.y + 200);
					cameraSpeed = 12;
					FlxTween.tween(FlxG.camera, {zoom: 0.9 * 1.2 * 1.2}, 0.25, {ease: FlxEase.elasticOut});
				});

				cutsceneHandler.timer(32.2, function()
				{
					zoomBack();
				});
		}
	}

	var startTimer:FlxTimer;
	var finishTimer:FlxTimer = null;

	// For being able to mess with the sprites on Lua
	public var countdownReady:FlxSprite;
	public var countdownSet:FlxSprite;
	public var countdownGo:FlxSprite;
	public static var startOnTime:Float = 0;

	function cacheCountdown()
	{
		var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
		introAssets.set('default', ['ready', 'set', 'go']);
		introAssets.set('pixel', ['pixelUI/ready-pixel', 'pixelUI/set-pixel', 'pixelUI/date-pixel']);

		var introAlts:Array<String> = introAssets.get('default');
		if (isPixelStage) introAlts = introAssets.get('pixel');
		
		for (asset in introAlts)
			Paths.image(asset);
		
		Paths.sound('intro3' + introSoundsSuffix);
		Paths.sound('intro2' + introSoundsSuffix);
		Paths.sound('intro1' + introSoundsSuffix);
		Paths.sound('introGo' + introSoundsSuffix);
	}

	public function startCountdown():Void
	{
		if(startedCountdown) {
			callOnLuas('onStartCountdown', []);
			callOnHaxes('startCountdown', []);
			return;
		}

		inCutscene = false;
		var ret:Dynamic = callOnLuas('onStartCountdown', [], false);
		callOnHaxes('startCountdown', []);
		if(ret != FunkinLua.Function_Stop) {
			if (skipCountdown || startOnTime > 0) skipArrowStartTween = true;

			for (i in 0...playerStrums.length) {
				setOnLuas('defaultPlayerStrumX' + i, playerStrums.members[i].x);
				setOnLuas('defaultPlayerStrumY' + i, playerStrums.members[i].y);

				setOnHaxes('defaultPlayerStrumX' + i, playerStrums.members[i].x);
				setOnHaxes('defaultPlayerStrumY' + i, playerStrums.members[i].y);
			}
			for (i in 0...opponentStrums.length) {
				setOnLuas('defaultOpponentStrumX' + i, opponentStrums.members[i].x);
				setOnLuas('defaultOpponentStrumY' + i, opponentStrums.members[i].y);

				setOnHaxes('defaultOpponentStrumX' + i, opponentStrums.members[i].x);
				setOnHaxes('defaultOpponentStrumY' + i, opponentStrums.members[i].y);
				//if(ClientPrefs.middleScroll) opponentStrums.members[i].visible = false;
			}

			startedCountdown = true;
			Conductor.songPosition = -Conductor.crochet * 5;
			setOnLuas('startedCountdown', true);
			callOnLuas('onCountdownStarted', []);
			callOnHaxes('countdownStarted', []);

			var swagCounter:Int = 0;

			if(startOnTime < 0) startOnTime = 0;

			if (startOnTime > 0) {
				clearNotesBefore(startOnTime);
				setSongTime(startOnTime - 350);
				return;
			}
			else if (skipCountdown)
			{
				setSongTime(0);
				return;
			}

			startTimer = new FlxTimer().start(Conductor.crochet / 1000 / playbackRate, function(tmr:FlxTimer)
			{
				if (gf != null && tmr.loopsLeft % Math.round(gfSpeed * gf.danceEveryNumBeats) == 0 && gf.animation.curAnim != null && !gf.animation.curAnim.name.startsWith("sing") && !gf.stunned)
				{
					gf.dance();
				}
				if (tmr.loopsLeft % boyfriend.danceEveryNumBeats == 0 && boyfriend.animation.curAnim != null && !boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.stunned)
				{
					boyfriend.dance();
				}
				if (tmr.loopsLeft % dad.danceEveryNumBeats == 0 && dad.animation.curAnim != null && !dad.animation.curAnim.name.startsWith('sing') && !dad.stunned)
				{
					dad.dance();
				}

				var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
				introAssets.set('default', ['ready', 'set', 'go']);
				introAssets.set('pixel', ['pixelUI/ready-pixel', 'pixelUI/set-pixel', 'pixelUI/date-pixel']);

				var introAlts:Array<String> = introAssets.get('default');
				var antialias:Bool = ClientPrefs.globalAntialiasing;
				if(isPixelStage) {
					introAlts = introAssets.get('pixel');
					antialias = false;
				}

				stage.beatHit();

				switch (swagCounter)
				{
					case 0:
						FlxG.sound.play(Paths.sound(introSoundsSuffix + 'intro3'), 0.6);
					case 1:
						countdownReady = new FlxSprite().loadGraphic(Paths.image(introAlts[0]));
						countdownReady.cameras = [camHUD];
						countdownReady.scrollFactor.set();
						countdownReady.updateHitbox();

						if (PlayState.isPixelStage)
							countdownReady.setGraphicSize(Std.int(countdownReady.width * daPixelZoom));

						countdownReady.screenCenter();
						countdownReady.antialiasing = antialias;
						insert(members.indexOf(notes), countdownReady);
						FlxTween.tween(countdownReady, {/*y: countdownReady.y + 100,*/ alpha: 0}, Conductor.crochet / 1000, {
							ease: FlxEase.cubeInOut,
							onComplete: function(twn:FlxTween)
							{
								remove(countdownReady);
								countdownReady.destroy();
							}
						});
						FlxG.sound.play(Paths.sound(introSoundsSuffix + 'intro2'), 0.6);
					case 2:
						countdownSet = new FlxSprite().loadGraphic(Paths.image(introAlts[1]));
						countdownSet.cameras = [camHUD];
						countdownSet.scrollFactor.set();

						if (PlayState.isPixelStage)
							countdownSet.setGraphicSize(Std.int(countdownSet.width * daPixelZoom));

						countdownSet.screenCenter();
						countdownSet.antialiasing = antialias;
						insert(members.indexOf(notes), countdownSet);
						FlxTween.tween(countdownSet, {/*y: countdownSet.y + 100,*/ alpha: 0}, Conductor.crochet / 1000, {
							ease: FlxEase.cubeInOut,
							onComplete: function(twn:FlxTween)
							{
								remove(countdownSet);
								countdownSet.destroy();
							}
						});
						FlxG.sound.play(Paths.sound(introSoundsSuffix + 'intro1'), 0.6);
					case 3:
						countdownGo = new FlxSprite().loadGraphic(Paths.image(introAlts[2]));
						countdownGo.cameras = [camHUD];
						countdownGo.scrollFactor.set();

						if (PlayState.isPixelStage)
							countdownGo.setGraphicSize(Std.int(countdownGo.width * daPixelZoom));

						countdownGo.updateHitbox();

						countdownGo.screenCenter();
						countdownGo.antialiasing = antialias;
						insert(members.indexOf(notes), countdownGo);
						FlxTween.tween(countdownGo, {/*y: countdownGo.y + 100,*/ alpha: 0}, Conductor.crochet / 1000, {
							ease: FlxEase.cubeInOut,
							onComplete: function(twn:FlxTween)
							{
								remove(countdownGo);
								countdownGo.destroy();
							}
						});
						FlxG.sound.play(Paths.sound(introSoundsSuffix + 'introGo'), 0.6);
					case 4:
				}
				/*
				notes.forEachAlive(function(note:Note) {
					if(ClientPrefs.opponentStrums || note.mustPress)
					{
						note.copyAlpha = false;
						note.alpha = note.multAlpha;
						if(ClientPrefs.middleScroll && !note.mustPress) {
							note.alpha *= 0.35;
						}
					}
				});
				*/

				callOnLuas('onCountdownTick', [swagCounter]);
				callOnHaxes('countdownTick', [swagCounter]);
				swagCounter += 1;
				// generateSong('fresh');
			}, 5);
		}
	}

	public function addBehindGF(obj:FlxObject)
	{
		insert(members.indexOf(gfGroup), obj);
	}
	public function addBehindBF(obj:FlxObject)
	{
		insert(members.indexOf(boyfriendGroup), obj);
	}
	public function addBehindDad (obj:FlxObject)
	{
		insert(members.indexOf(dadGroup), obj);
	}

	public function addBehind (objThing:FlxObject, obj:FlxObject)
	{
		insert(members.indexOf(objThing), obj);
	}

	public function clearNotesBefore(time:Float)
	{
		var i:Int = unspawnNotes.length - 1;
		while (i >= 0) {
			var daNote:Note = unspawnNotes[i];
			if(daNote.strumTime - 350 < time)
			{
				daNote.active = false;
				daNote.visible = false;
				daNote.ignoreNote = true;

				daNote.kill();
				unspawnNotes.remove(daNote);
				daNote.destroy();
			}
			--i;
		}

		i = notes.length - 1;
		while (i >= 0) {
			var daNote:Note = notes.members[i];
			if(daNote.strumTime - 350 < time)
			{
				daNote.active = false;
				daNote.visible = false;
				daNote.ignoreNote = true;

				daNote.kill();
				notes.remove(daNote, true);
				daNote.destroy();
			}
			--i;
		}

		var f:Int = unspawnFakeNotes.length - 1;
		while (i >= 0) {
			var daNote:Note = unspawnFakeNotes[i];
			if(daNote.strumTime - 350 < time)
			{
				daNote.active = false;
				daNote.visible = false;
				daNote.ignoreNote = true;

				daNote.kill();
				unspawnFakeNotes.remove(daNote);
				daNote.destroy();
			}
			--i;
		}

		f = fakeNotes.length - 1;
		while (i >= 0) {
			var daNote:Note = fakeNotes.members[i];
			if(daNote.strumTime - 350 < time)
			{
				daNote.active = false;
				daNote.visible = false;
				daNote.ignoreNote = true;

				daNote.kill();
				fakeNotes.remove(daNote, true);
				daNote.destroy();
			}
			--i;
		}
	}

	public function updateScore(miss:Bool = false)
	{
		scoreTxt.text = 'Score: ' + songScore
		+ ' | Misses: ' + songMisses
		+ ' | Rating: ' + ratingName
		+ (ratingName != '?' ? ' (${Highscore.floorDecimal(ratingPercent * 100, 2)}%) - $ratingFC' : '');

		if(ClientPrefs.scoreZoom && !miss)
		{
			if(scoreTxtTween != null) {
				scoreTxtTween.cancel();
			}
			scoreTxt.scale.x = 1.075;
			scoreTxt.scale.y = 1.075;
			scoreTxtTween = FlxTween.tween(scoreTxt.scale, {x: 1, y: 1}, 0.2, {
				onComplete: function(twn:FlxTween) {
					scoreTxtTween = null;
				}
			});
		}
		callOnLuas('onUpdateScore', [miss]);
		callOnHaxes('updateScore', [miss]);
	}

	public function setSongTime(time:Float)
	{
		if(time < 0) time = 0;

		FlxG.sound.music.pause();
		vocals.pause();

		if(vocalsBoyfriend != null)
		{
			for(boyfriend in vocalsBoyfriend)
			{
				boyfriend.pause();
			}
		}

		if(vocalsDad != null)
		{
			for(dad in vocalsDad)
			{
				dad.pause();
			}
		}

		FlxG.sound.music.time = time;
		FlxG.sound.music.pitch = playbackRate;
		FlxG.sound.music.play();

		if (Conductor.songPosition <= vocals.length)
		{
			vocals.time = time;
			vocals.pitch = playbackRate;
		}
		vocals.play();

		if(vocalsBoyfriend != null)
		{
			for(boyfriend in vocalsBoyfriend)
			{
				if (Conductor.songPosition <= boyfriend.length)
				{
					boyfriend.time = time;
					boyfriend.pitch = playbackRate;
				}
				boyfriend.play();
			}
		}

		if(vocalsDad != null)
		{
			for(dad in vocalsDad)
			{
				if (Conductor.songPosition <= dad.length)
				{
					dad.time = time;
					dad.pitch = playbackRate;
				}
				dad.play();
			}
		}
		Conductor.songPosition = time;
		songTime = time;
	}

	function startNextDialogue() {
		dialogueCount++;
		callOnLuas('onNextDialogue', [dialogueCount]);
		callOnHaxes('nextDialogue', [dialogueCount]);
	}

	function skipDialogue() {
		callOnLuas('onSkipDialogue', [dialogueCount]);
		callOnHaxes('skipDialogue', [dialogueCount]);
	}

	var previousFrameTime:Int = 0;
	var lastReportedPlayheadPosition:Int = 0;
	var songTime:Float = 0;

	function startSong():Void
	{
		if (Paths.formatToSongPath(SONG.song) != 'tutorial')
			camZooming = true;

		startingSong = false;

		previousFrameTime = FlxG.game.ticks;
		lastReportedPlayheadPosition = 0;

		FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song), 1, false);
		FlxG.sound.music.pitch = playbackRate;
		FlxG.sound.music.onComplete = finishSong.bind();
		if(vocals != null)
		{
			vocals.play();
		}
		

		if(vocalsBoyfriend != null)
		{
			for(boyfriend in vocalsBoyfriend)
			{
				boyfriend.play();
			}
		}

		if(vocalsDad != null)
		{
			for(dad in vocalsDad)
			{
				dad.play();
			}
		}

		if(startOnTime > 0)
		{
			setSongTime(startOnTime - 500);
		}
		startOnTime = 0;

		if(paused) {
			//trace('Oopsie doopsie! Paused sound');
			FlxG.sound.music.pause();
			if(vocals != null)
			{
				vocals.pause();
			}

			if(vocalsBoyfriend != null)
			{
				for(boyfriend in vocalsBoyfriend)
				{
					boyfriend.pause();
				}
			}

			if(vocalsDad != null)
			{
				for(dad in vocalsDad)
				{
					dad.pause();
				}
			}
		}

		// Song duration in a float, useful for the time left feature
		songLength = FlxG.sound.music.length;
		FlxTween.tween(timeBar, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
		FlxTween.tween(timeTxt, {alpha: 1}, 0.5, {ease: FlxEase.circOut});

		#if desktop
		// Updating Discord Rich Presence (with Time Left)
		DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter(), true, songLength);
		#end
		setOnLuas('songLength', songLength);
		setOnHaxes('songLength', songLength);
		callOnLuas('onSongStart', []);
		callOnHaxes('songStart', []);
	}

	var debugNum:Int = 0;
	private var noteTypeMap:Map<String, Bool> = new Map<String, Bool>();
	private var eventPushedMap:Map<String, Bool> = new Map<String, Bool>();
	private function generateSong(dataPath:String):Void
	{
		// FlxG.log.add(ChartParser.parse());
		songSpeedType = ClientPrefs.getGameplaySetting('scrolltype','multiplicative');

		switch(songSpeedType)
		{
			case "multiplicative":
				songSpeed = SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed', 1);
			case "constant":
				songSpeed = ClientPrefs.getGameplaySetting('scrollspeed', 1);
		}

		var songData = SONG;
		Conductor.changeBPM(songData.bpm);

		curSong = songData.song;
		loadCharacterData();

		if (SONG.needsVoices)
		{
			//Wow Funkelion Moment I think Monika outdated exe already made lol
			var songKeyDad:String = '${Paths.formatToSongPath(curSong)}/Voices' + songData.player2.toUpperCase();
			var songKeyBF:String = '${Paths.formatToSongPath(curSong)}/Voices' + songData.player1.toUpperCase();
			var songKeyGF:String = '${Paths.formatToSongPath(curSong)}/Voices' + songData.gfVersion.toUpperCase();

			var songKeyDadNormal:String = '${Paths.formatToSongPath(curSong)}/VoicesDAD';
			var songKeyBFNormal:String = '${Paths.formatToSongPath(curSong)}/VoicesBF';
			var songKeyGFNormal:String = '${Paths.formatToSongPath(curSong)}/VoicesGF';
			var songKeyMOMNormal:String = '${Paths.formatToSongPath(curSong)}/VoicesMOM';

			if(Paths.fileExists(songKeyDad + '.' + Paths.SOUND_EXT, SOUND, false, 'songs') && Paths.fileExists(songKeyBF + '.' + Paths.SOUND_EXT, SOUND, false, 'songs'))
			{
				var customGF:FlxSound = null;
				if(Paths.fileExists(songKeyGF + '.' + Paths.SOUND_EXT, SOUND, false, 'songs'))
					customGF = new FlxSound().loadEmbedded(Paths.returnSound('songs', songKeyGF)); 
				else
					customGF = new FlxSound();

				var customMOM:FlxSound = null;
				if(Paths.fileExists(songKeyMOMNormal + '.' + Paths.SOUND_EXT, SOUND, false, 'songs'))
					customMOM = new FlxSound().loadEmbedded(Paths.returnSound('songs', songKeyMOMNormal)); 
				else
					customMOM = new FlxSound();

				vocalsDad.push(new FlxSound().loadEmbedded(Paths.returnSound('songs', songKeyDad)));
				vocalsBoyfriend.push(new FlxSound().loadEmbedded(Paths.returnSound('songs', songKeyBF)));
	
				vocalsDad.push(customGF);
				vocalsBoyfriend.push(customGF);

				vocalsDad.push(customMOM);
				vocalsBoyfriend.push(customMOM);
			}
			else if(Paths.fileExists(songKeyDadNormal + '.' + Paths.SOUND_EXT, SOUND, false, 'songs') && Paths.fileExists(songKeyBFNormal + '.' + Paths.SOUND_EXT, SOUND, false, 'songs'))
			{
				var customGF:FlxSound = null;
				if(Paths.fileExists(songKeyGFNormal + '.' + Paths.SOUND_EXT, SOUND, false, 'songs'))
					customGF = new FlxSound().loadEmbedded(Paths.returnSound('songs', songKeyGFNormal)); 
				else
					customGF = new FlxSound();

				var customMOM:FlxSound = null;
				if(Paths.fileExists(songKeyMOMNormal + '.' + Paths.SOUND_EXT, SOUND, false, 'songs'))
					customMOM = new FlxSound().loadEmbedded(Paths.returnSound('songs', songKeyMOMNormal)); 
				else
					customMOM = new FlxSound();

				vocalsDad.push(new FlxSound().loadEmbedded(Paths.returnSound('songs', songKeyDadNormal)));
				vocalsBoyfriend.push(new FlxSound().loadEmbedded(Paths.returnSound('songs', songKeyBFNormal)));
	
				vocalsDad.push(customGF);
				vocalsBoyfriend.push(customGF);

				vocalsDad.push(customMOM);
				vocalsBoyfriend.push(customMOM);
			}
			else
			{
				vocals = new FlxSound().loadEmbedded(Paths.voices(PlayState.SONG.song));
			}
		}
		else
		{
			vocals = new FlxSound();
		}

		if(vocalsBoyfriend != null)
		{
			for(boyfriend in vocalsBoyfriend)
			{
				boyfriend.pitch = playbackRate;
				FlxG.sound.list.add(boyfriend);
			}
		}

		if(vocalsDad != null)
		{
			for(dad in vocalsDad)
			{
				dad.pitch = playbackRate;
				FlxG.sound.list.add(dad);
			}
		}
			
		if(vocals != null)
		{
			vocals.pitch = playbackRate;
			FlxG.sound.list.add(vocals);
		}

		FlxG.sound.list.add(new FlxSound().loadEmbedded(Paths.inst(PlayState.SONG.song)));

		fakeNotes = new FlxTypedGroup<Note>();
		add(fakeNotes);

		notes = new FlxTypedGroup<Note>();
		add(notes);


		var noteData:Array<SwagSection>;
		var rmtjData:Array<SwagSection> = null;
		// NEW SHIT
		noteData = songData.notes;

		var playerCounter:Int = 0;

		var daBeats:Int = 0; // Not exactly representative of 'daBeats' lol, just how much it has looped

		var songName:String = Paths.formatToSongPath(SONG.song);
		var songOther:String = Paths.json(songName + '/$songName-other');
		#if MODS_ALLOWED
		if (FileSystem.exists(Paths.modsJson(songName + '/$songName-other')) || FileSystem.exists(songOther)) {
		#else
		if (OpenFlAssets.exists(songOther)) {
		#end
		    rmtjData = Song.loadFromJson(songName + '-other', songName).notes;
		}

		var file:String = Paths.json(songName + '/events');
		#if MODS_ALLOWED
		if (FileSystem.exists(Paths.modsJson(songName + '/events')) || FileSystem.exists(file)) {
		#else
		if (OpenFlAssets.exists(file)) {
		#end
			var eventsData:Array<Dynamic> = Song.loadFromJson('events', songName).events;
			for (event in eventsData) //Event Notes
			{
				for (i in 0...event[1].length)
				{
					var newEventNote:Array<Dynamic> = [event[0], event[1][i][0], event[1][i][1], event[1][i][2]];
					var subEvent:EventNote = {
						strumTime: newEventNote[0] + ClientPrefs.noteOffset,
						event: newEventNote[1],
						value1: newEventNote[2],
						value2: newEventNote[3]
					};
					eventNotes.push(subEvent);
					eventPushed(subEvent);
				}
			}
		}

		if(rmtjData != null)
		{
			for (section in rmtjData)
			{
				for (songNotes in section.sectionNotes)
				{
					var daStrumTime:Float = songNotes[0];
					var daNoteData:Int = Std.int(songNotes[1] % 4);
		
					var gottaHitNote:Bool = section.mustHitSection;
		
					if (songNotes[1] > 3)
					{
						gottaHitNote = !section.mustHitSection;
					}
		
					var oldNote:Note;
					if (unspawnFakeNotes.length > 0)
						oldNote = unspawnFakeNotes[Std.int(unspawnFakeNotes.length - 1)];
					else
						oldNote = null;
		
					var swagNote:Note = new Note(daStrumTime, daNoteData, oldNote);
					if(gottaHitNote)
					{
						swagNote.texture = momArrowSkin;
						swagNote.style = momArrowStyle;
					}
					else
					{
						swagNote.texture = gfArrowSkin;
						swagNote.style = gfArrowSkin;
					}
					swagNote.mustPress = gottaHitNote;
					swagNote.alpha = 0.45;
					swagNote.sustainLength = songNotes[2];
					swagNote.gfNote = (section.gfSection && (songNotes[1]<4));
					swagNote.noteType = songNotes[3];
					if(!Std.isOfType(songNotes[3], String)) swagNote.noteType = meta.state.editors.ChartingState.noteTypeList[songNotes[3]]; //Backward compatibility + compatibility with Week 7 charts
					swagNote.scrollFactor.set();
					var susLength:Float = swagNote.sustainLength;
					susLength = susLength / Conductor.stepCrochet;
					unspawnFakeNotes.push(swagNote);
					swagNote.x += FlxG.width / 2; // general offset
		
					var floorSus:Int = Math.floor(susLength);
					if(floorSus > 0) {
						for (susNote in 0...floorSus+1)
						{
							oldNote = unspawnFakeNotes[Std.int(unspawnFakeNotes.length - 1)];
	
							var sustainNote:Note = new Note(daStrumTime + (Conductor.stepCrochet * susNote) + (Conductor.stepCrochet / FlxMath.roundDecimal(songSpeed, 2)), daNoteData, oldNote, true);
							if(gottaHitNote)
							{
								sustainNote.texture = momArrowSkin;
								sustainNote.style = momArrowStyle;
							}
							else
							{
								sustainNote.texture = gfArrowSkin;
								sustainNote.style = gfArrowSkin;
							}
							sustainNote.alpha = 0.45;
							sustainNote.mustPress = gottaHitNote;
							sustainNote.gfNote = (section.gfSection && (songNotes[1]<4));
							sustainNote.noteType = swagNote.noteType;
							sustainNote.scrollFactor.set();
							swagNote.tail.push(sustainNote);
							sustainNote.parent = swagNote;
							unspawnFakeNotes.push(sustainNote);
							if (sustainNote.mustPress)
							{
								sustainNote.x += FlxG.width / 2; // general offset
							}
							else if(ClientPrefs.middleScroll)
							{
								sustainNote.x += 310;
								if(daNoteData > 1) //Up and Right
								{
									sustainNote.x += FlxG.width / 2 + 25;
								}
							}
						}
					}

					if (swagNote.mustPress)
					{
						swagNote.x += FlxG.width / 2; // general offset
					}
					else if(ClientPrefs.middleScroll)
					{
						swagNote.x += 310;
						if(daNoteData > 1) //Up and Right
						{
							swagNote.x += FlxG.width / 2 + 25;
						}
					}
					
							
					if(!noteTypeMap.exists(swagNote.noteType)) {
						noteTypeMap.set(swagNote.noteType, true);
					}
		
					daBeats += 1;
				}
		
				for (event in songData.events) //Event Notes
				{
					for (i in 0...event[1].length)
					{
						var newEventNote:Array<Dynamic> = [event[0], event[1][i][0], event[1][i][1], event[1][i][2]];
						var subEvent:EventNote = {
							strumTime: newEventNote[0] + ClientPrefs.noteOffset,
							event: newEventNote[1],
							value1: newEventNote[2],
							value2: newEventNote[3]
						};
						subEvent.strumTime -= eventNoteEarlyTrigger(subEvent);
						eventNotes.push(subEvent);
						eventPushed(subEvent);
					}
				}
			}


		}


		for (section in noteData)
		{
			for (songNotes in section.sectionNotes)
			{
				var daStrumTime:Float = songNotes[0];
				var daNoteData:Int = Std.int(songNotes[1] % 4);

				var gottaHitNote:Bool = section.mustHitSection;

				if (songNotes[1] > 3)
				{
					gottaHitNote = !section.mustHitSection;
				}

				var oldNote:Note;
				if (unspawnNotes.length > 0)
					oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
				else
					oldNote = null;

				var swagNote:Note = new Note(daStrumTime, daNoteData, oldNote);
				if(gottaHitNote)
				{
					swagNote.texture = boyfriendArrowSkin;
					swagNote.style = boyfriendArrowStyle;
				}
				else
				{
					swagNote.texture = dadArrowSkin;
					swagNote.style = dadArrowStyle;
				}
				swagNote.mustPress = gottaHitNote;
				swagNote.sustainLength = songNotes[2];
				swagNote.gfNote = (section.gfSection && (songNotes[1]<4));
				swagNote.noteType = songNotes[3];
				if(!Std.isOfType(songNotes[3], String)) swagNote.noteType = meta.state.editors.ChartingState.noteTypeList[songNotes[3]]; //Backward compatibility + compatibility with Week 7 charts

				swagNote.scrollFactor.set();

				var susLength:Float = swagNote.sustainLength;

				susLength = susLength / Conductor.stepCrochet;
				unspawnNotes.push(swagNote);

				var floorSus:Int = Math.floor(susLength);
				if(floorSus > 0) {
					for (susNote in 0...floorSus+1)
					{
						oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];

						var sustainNote:Note = new Note(daStrumTime + (Conductor.stepCrochet * susNote) + (Conductor.stepCrochet / FlxMath.roundDecimal(songSpeed, 2)), daNoteData, oldNote, true);
						sustainNote.mustPress = gottaHitNote;
						if(gottaHitNote)
						{
							sustainNote.texture = boyfriendArrowSkin;
							sustainNote.style = boyfriendArrowStyle;
						}
						else
						{
							sustainNote.texture = dadArrowSkin;
							sustainNote.style = dadArrowStyle;
						}
						sustainNote.gfNote = (section.gfSection && (songNotes[1]<4));
						sustainNote.noteType = swagNote.noteType;
						sustainNote.scrollFactor.set();
						swagNote.tail.push(sustainNote);
						sustainNote.parent = swagNote;
						unspawnNotes.push(sustainNote);
						if (sustainNote.mustPress)
							sustainNote.x += FlxG.width / 2; // general offset
						else if(ClientPrefs.middleScroll)
						{
							sustainNote.x += 310;
							if(daNoteData > 1) //Up and Right
							{
								sustainNote.x += FlxG.width / 2 + 25;
							}	
						}
					}
				}

				if (swagNote.mustPress)
					swagNote.x += FlxG.width / 2; // general offset
				else if(ClientPrefs.middleScroll)
				{
					swagNote.x += 310;
					if(daNoteData > 1) //Up and Right
					{
						swagNote.x += FlxG.width / 2 + 25;
					}
				}


			
				if(!noteTypeMap.exists(swagNote.noteType)) {
					noteTypeMap.set(swagNote.noteType, true);
				}
			}
			daBeats += 1;
		}
		for (event in songData.events) //Event Notes
		{
			for (i in 0...event[1].length)
			{
				var newEventNote:Array<Dynamic> = [event[0], event[1][i][0], event[1][i][1], event[1][i][2]];
				var subEvent:EventNote = {
					strumTime: newEventNote[0] + ClientPrefs.noteOffset,
					event: newEventNote[1],
					value1: newEventNote[2],
					value2: newEventNote[3]
				};
				eventNotes.push(subEvent);
				eventPushed(subEvent);
			}
		}

		// trace(unspawnNotes.length);
		// playerCounter += 1;

		unspawnNotes.sort(sortByTime);
		generatedMusic = true;
	}

	//Don't use these thing it won't work because FlxBasic is hard
	function addStageToList(value:String)
	{
		var newStage:Stage = new Stage(value);
		stageMap.set(value, newStage);
		stageGroup.add(newStage);

		gfLayer.add(newStage.layers.get('gf'));
		dadLayer.add(newStage.layers.get('dad'));
		boyfriendLayer.add(newStage.layers.get('boyfriend'));

		for(i in 0...newStage.length)
		{
			newStage.members[i].visible = false;
		}

		for(i in 0...newStage.layers.get('boyfriend').length)
		{
			newStage.layers.get('boyfriend').members[i].visible = false;
		}

		for(i in 0...newStage.layers.get('gf').length)
		{
			newStage.layers.get('gf').members[i].visible = false;
		}

		for(i in 0...newStage.layers.get('dad').length)
		{
			newStage.layers.get('dad').members[i].visible = false;
		}

		for(i in 0...newStage.layers.get('foreground').length)
		{
			newStage.layers.get('foreground').members[i].visible = false;
		}
	}

	function eventPushed(event:EventNote) {
		switch(event.event) {
			case 'Change Character':
				var charType:Int = 0;
				switch(event.value1.toLowerCase()) {
					case 'bf' | 'boyfriend'|'0':
						charType = 0;
					case 'gf' | 'girlfriend'|'2':
						charType = 2;
					case 'dad' | 'opponent'|'1':
						charType = 1;
					case 'mom' | 'opponent2'|'3':
						charType = 3;
					default:
						charType = 4;
				}

				var newCharacter:String = event.value2;
				switch(charType)
				{
					case 4:
						addCharacterLuaToList(event.value2, event.value1, event.value1.contains('flip'));
					default:
						addCharacterToList(newCharacter, charType, event.value1.contains('flip'));
				}
			case 'Change Stage':
				//addStageToList(event.value1);

				var newStage:Stage = new Stage(event.value1);
			case 'Dadbattle Spotlight':
				dadbattleBlack = new BGSprite(null, -800, -400, 0, 0);
				dadbattleBlack.makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
				dadbattleBlack.alpha = 0.25;
				dadbattleBlack.visible = false;
				add(dadbattleBlack);
				setOnHaxes('dadbattleBlack', dadbattleBlack);

				dadbattleLight = new BGSprite('stages/stage/spotlight', 400, -400);
				dadbattleLight.alpha = 0.375;
				dadbattleLight.blend = ADD;
				dadbattleLight.visible = false;
				setOnHaxes('dadbattleLight', dadbattleLight);

				dadbattleSmokes.alpha = 0.7;
				dadbattleSmokes.blend = ADD;
				dadbattleSmokes.visible = false;
				setOnHaxes('dadbattleSmokes', dadbattleSmokes);
				add(dadbattleLight);
				add(dadbattleSmokes);

				var offsetX = 200;
				var smokeLeft:BGSprite = new BGSprite('stages/stage/smoke', -1550 + offsetX, 660 + FlxG.random.float(-20, 20), 1.2, 1.05);
				smokeLeft.setGraphicSize(Std.int(smokeLeft.width * FlxG.random.float(1.1, 1.22)));
				smokeLeft.updateHitbox();
				smokeLeft.velocity.x = FlxG.random.float(15, 22);
				smokeLeft.active = true;
				dadbattleSmokes.add(smokeLeft);
				setOnHaxes('smokeLeft', smokeLeft);

				var smokeRight:BGSprite = new BGSprite('stages/stage/smoke', 1550 + offsetX, 660 + FlxG.random.float(-20, 20), 1.2, 1.05);
				smokeRight.setGraphicSize(Std.int(smokeRight.width * FlxG.random.float(1.1, 1.22)));
				smokeRight.updateHitbox();
				smokeRight.velocity.x = FlxG.random.float(-15, -22);
				smokeRight.active = true;
				smokeRight.flipX = true;
				dadbattleSmokes.add(smokeRight);
				setOnHaxes('smokeRight', smokeRight);


			case 'Philly Glow':
				blammedLightsBlack = new FlxSprite(FlxG.width * -0.5, FlxG.height * -0.5).makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
				blammedLightsBlack.visible = false;
				if(stage.curStage == 'philly')
				{
					stage.add(blammedLightsBlack);
				}
				else
				{
					var position:Int = members.indexOf(gfGroup);
					if(members.indexOf(boyfriendGroup) < position) {
						position = members.indexOf(boyfriendGroup);
					} else if(members.indexOf(dadGroup) < position) {
						position = members.indexOf(dadGroup);
					}
					insert(position, blammedLightsBlack);
				}
				

				phillyWindowEvent = new BGSprite('stages/philly/window', -10, 0, 0.3, 0.3);
				phillyWindowEvent.setGraphicSize(Std.int(phillyWindowEvent.width * 0.85));
				phillyWindowEvent.updateHitbox();
				phillyWindowEvent.visible = false;
				insert(members.indexOf(blammedLightsBlack) + 1, phillyWindowEvent);


				phillyGlowGradient = new PhillyGlowGradient(-400, 225); //This shit was refusing to properly load FlxGradient so fuck it
				phillyGlowGradient.visible = false;
				insert(members.indexOf(blammedLightsBlack) + 1, phillyGlowGradient);
				if(!ClientPrefs.flashing) phillyGlowGradient.intendedAlpha = 0.7;

				precacheList.set('stages/philly/particle', 'image'); //precache particle image
				phillyGlowParticles = new FlxTypedGroup<PhillyGlowParticle>();
				phillyGlowParticles.visible = false;
				insert(members.indexOf(phillyGlowGradient) + 1, phillyGlowParticles);
		}

		if(!eventPushedMap.exists(event.event)) {
			eventPushedMap.set(event.event, true);
		}
		callOnLuas('eventPushed', [event.event, event.value1, event.value2]);
		callOnHaxes('eventPushed', [event.event, event.value1, event.value2]);
	}

	function eventNoteEarlyTrigger(event:EventNote):Float {
		var returnedValue:Null<Float> = callOnLuas('eventEarlyTrigger', [event.event, event.value1, event.value2, event.strumTime], [], [0]);
		callOnHaxes('eventEarlyTrigger', [event.event, event.value1, event.value2, event.strumTime]);
		if(returnedValue != null && returnedValue != 0 && returnedValue != FunkinLua.Function_Continue) {
			return returnedValue;
		}

		switch(event.event) {
			case 'Kill Henchmen': //Better timing so that the kill sound matches the beat intended
				return 280; //Plays 280ms before the actual position
		}
		return 0;
	}

	function sortByTime(Obj1:Dynamic, Obj2:Dynamic):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	override function openSubState(SubState:FlxSubState)
	{
		if (paused)
		{
			if (FlxG.sound.music != null)
			{
				FlxG.sound.music.pause();
				if(vocals != null)
				{
					vocals.pause();
				}
			}

			if(vocalsDad != null)
			{
				for(dad in vocalsDad)
				{
					dad.pause();
				}
			}
			if(vocalsBoyfriend != null)
			{
				for(boyfriend in vocalsBoyfriend)
				{
					boyfriend.pause();
				}
			}

			if (startTimer != null && !startTimer.finished)
				startTimer.active = false;
			if (finishTimer != null && !finishTimer.finished)
				finishTimer.active = false;
			if (songSpeedTween != null)
				songSpeedTween.active = false;

			var chars:Array<Character> = [boyfriend, gf, dad];
			for (char in chars) {
				if(char != null && char.colorTween != null) {
					char.colorTween.active = false;
				}
			}

			for (tween in modchartTweens) {
				tween.active = false;
			}
			for (timer in modchartTimers) {
				timer.active = false;
			}
		}

		super.openSubState(SubState);
	}

	override function closeSubState()
	{
		if (paused)
		{
			if (FlxG.sound.music != null && !startingSong)
			{
				resyncVocals();
			}

			if (startTimer != null && !startTimer.finished)
				startTimer.active = true;
			if (finishTimer != null && !finishTimer.finished)
				finishTimer.active = true;
			if (songSpeedTween != null)
				songSpeedTween.active = true;

			var chars:Array<Character> = [boyfriend, gf, dad];
			for (char in chars) {
				if(char != null && char.colorTween != null) {
					char.colorTween.active = true;
				}
			}

			for (tween in modchartTweens) {
				tween.active = true;
			}
			for (timer in modchartTimers) {
				timer.active = true;
			}
			paused = false;
			callOnLuas('onResume', []);
			callOnHaxes('resume', []);

			#if desktop
			if (startTimer != null && startTimer.finished)
			{
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter(), true, songLength - Conductor.songPosition - ClientPrefs.noteOffset);
			}
			else
			{
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
			}
			#end
		}

		super.closeSubState();
	}

	override public function onFocus():Void
	{
		#if desktop
		if (health > 0 && !paused)
		{
			if (Conductor.songPosition > 0.0)
			{
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter(), true, songLength - Conductor.songPosition - ClientPrefs.noteOffset);
			}
			else
			{
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
			}
		}
		#end

		super.onFocus();
	}

	override public function onFocusLost():Void
	{
		#if desktop
		if (health > 0 && !paused)
		{
			DiscordClient.changePresence(detailsPausedText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
		}
		#end

		super.onFocusLost();
	}

	function resyncVocals():Void
	{
		if(finishTimer != null) return;
		if(vocalsDad != null)
		{
			for(dad in vocalsDad)
			{
				dad.pause();
				if (Conductor.songPosition <= dad.length)
				{
					dad.time = Conductor.songPosition;
					dad.pitch = playbackRate;
				}
				dad.play();
			}
		}
		if(vocalsBoyfriend != null)
		{
			for(boyfriend in vocalsBoyfriend)
			{
				boyfriend.pause();
				if (Conductor.songPosition <= boyfriend.length)
				{
					boyfriend.time = Conductor.songPosition;
					boyfriend.pitch = playbackRate;
				}
				boyfriend.play();
			}
		}

		if(vocals != null)
		{
			vocals.pause();
			if (Conductor.songPosition <= vocals.length)
			{
				vocals.time = Conductor.songPosition;
				vocals.pitch = playbackRate;
			}
			vocals.play();
		}

		FlxG.sound.music.play();
		FlxG.sound.music.pitch = playbackRate;
		Conductor.songPosition = FlxG.sound.music.time;
	}

	public var paused:Bool = false;
	public var canReset:Bool = true;
	var startedCountdown:Bool = false;
	var canPause:Bool = true;
	var limoSpeed:Float = 0;

	override public function update(elapsed:Float)
	{
		if (FlxG.keys.justPressed.F9 && iconP1 != null)
		{
			iconP1.swapOldIcon(boyfriend.healthIcon);
		}
		callOnLuas('onUpdate', [elapsed]);
		callOnHaxes('update', [elapsed]);
		stage.update(elapsed);

		if(!inCutscene) {
			var lerpVal:Float = CoolUtil.boundTo(elapsed * 2.4 * cameraSpeed * playbackRate, 0, 1);
			camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));
			if(!startingSong && !endingSong && boyfriend.animation.curAnim != null && boyfriend.animation.curAnim.name.startsWith('idle')) {
				boyfriendIdleTime += elapsed;
				if(boyfriendIdleTime >= 0.15) { // Kind of a mercy thing for making the achievement easier to get as it's apparently frustrating to some playerss
					boyfriendIdled = true;
				}
			} else {
				boyfriendIdleTime = 0;
			}
		}

		super.update(elapsed);

		setOnLuas('curDecStep', curDecStep);
		setOnLuas('curDecBeat', curDecBeat);

		setOnHaxes('curDecStep', curDecStep);
		setOnHaxes('curDecBeat', curDecBeat);

		if(botplayTxt.visible) {
			botplaySine += 180 * elapsed;
			botplayTxt.alpha = 1 - Math.sin((Math.PI * botplaySine) / 180);
		}

		if (FlxG.keys.anyJustPressed(botplayKeys))
		{
			if(opponentControlled)
			{
				opponentStrums.autoplay = !opponentStrums.autoplay;
				botplayTxt.visible = !botplayTxt.visible;
			}
			else
			{
				playerStrums.autoplay = !playerStrums.autoplay;
				botplayTxt.visible = !botplayTxt.visible;
			}

		}

		if (controls.PAUSE && startedCountdown && canPause)
		{
			var ret:Dynamic = callOnLuas('onPause', [], false);
			callOnHaxes('pause', []);
			if(ret != FunkinLua.Function_Stop) {
				openPauseMenu();
			}
		}

		if (FlxG.keys.anyJustPressed(debugKeysChart) && !endingSong && !inCutscene)
		{
			openChartEditor();
		}

		// FlxG.watch.addQuick('VOL', vocals.amplitudeLeft);
		// FlxG.watch.addQuick('VOLRight', vocals.amplitudeRight);

		var mult:Float = FlxMath.lerp(1, iconP1.scale.x, CoolUtil.boundTo(1 - (elapsed * 9 * playbackRate), 0, 1));
		iconP1.scale.set(mult, mult);
		iconP1.updateHitbox();

		var mult:Float = FlxMath.lerp(1, iconP2.scale.x, CoolUtil.boundTo(1 - (elapsed * 9 * playbackRate), 0, 1));
		iconP2.scale.set(mult, mult);
		iconP2.updateHitbox();

		var iconOffset:Int = 26;

		iconP1.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01)) + (150 * iconP1.scale.x - 150) / 2 - iconOffset;
		iconP2.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01)) - (150 * iconP2.scale.x) / 2 - iconOffset * 2;

		var mult:Float = FlxMath.lerp(1, iconP1.scale.x, CoolUtil.boundTo(1 - (elapsed * 9 * playbackRate), 0, 1));
		iconP1.scale.set(mult, mult);
		iconP1.updateHitbox();

		var mult:Float = FlxMath.lerp(1, iconP2.scale.x, CoolUtil.boundTo(1 - (elapsed * 9 * playbackRate), 0, 1));
		iconP2.scale.set(mult, mult);
		iconP2.updateHitbox();

		var iconOffset:Int = 26;

		iconP1.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01)) + (150 * iconP1.scale.x - 150) / 2 - iconOffset;
		iconP2.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01)) - (150 * iconP2.scale.x) / 2 - iconOffset * 2;

		iconP1.updateAnims(healthBar.percent);
		iconP2.updateAnims(100 - healthBar.percent);

		if (FlxG.keys.anyJustPressed(debugKeysCharacter) && !endingSong && !inCutscene) {
			persistentUpdate = false;
			paused = true;
			cancelMusicFadeTween();
			MusicBeatState.switchState(new CharacterEditorState(SONG.player2));
		}
		
		if (startedCountdown)
		{
			Conductor.songPosition += FlxG.elapsed * 1000 * playbackRate;
		}

		if (startingSong)
		{
			if (startedCountdown && Conductor.songPosition >= 0)
				startSong();
			else if(!startedCountdown)
				Conductor.songPosition = -Conductor.crochet * 5;
		}
		else
		{
			if (!paused)
			{
				songTime += FlxG.game.ticks - previousFrameTime;
				previousFrameTime = FlxG.game.ticks;

				// Interpolation type beat
				if (Conductor.lastSongPos != Conductor.songPosition)
				{
					songTime = (songTime + Conductor.songPosition) / 2;
					Conductor.lastSongPos = Conductor.songPosition;
					// Conductor.songPosition += FlxG.elapsed * 1000;
					// trace('MISSED FRAME');
				}

				if(updateTime) {
					var curTime:Float = Conductor.songPosition - ClientPrefs.noteOffset;
					if(curTime < 0) curTime = 0;
					songPercent = (curTime / songLength);

					var songCalc:Float = (songLength - curTime);
					if(ClientPrefs.timeBarType == 'Time Elapsed') songCalc = curTime;

					var secondsTotal:Int = Math.floor(songCalc / 1000);
					if(secondsTotal < 0) secondsTotal = 0;

					if(ClientPrefs.timeBarType != 'Song Name')
						timeTxt.text = FlxStringUtil.formatTime(secondsTotal, false);
				}
			}

			// Conductor.lastSongPos = FlxG.sound.music.time;
		}

		if (camZooming)
		{
			FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125 * camZoomingDecay * playbackRate), 0, 1));
			camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125 * camZoomingDecay * playbackRate), 0, 1));
		}

		FlxG.watch.addQuick("secShit", curSection);
		FlxG.watch.addQuick("beatShit", curBeat);
		FlxG.watch.addQuick("stepShit", curStep);

		// RESET = Quick Game Over Screen
		if (!ClientPrefs.noReset && controls.RESET && canReset && !inCutscene && startedCountdown && !endingSong)
		{
			health = 0;
			trace("RESET = True");
		}
		doDeathCheck();

		if (unspawnNotes[0] != null)
		{
			var time:Float = spawnTime;
			if(songSpeed < 1) time /= songSpeed;
			if(unspawnNotes[0].multSpeed < 1) time /= unspawnNotes[0].multSpeed;

			while (unspawnNotes.length > 0 && unspawnNotes[0].strumTime - Conductor.songPosition < time)
			{
				var dunceNote:Note = unspawnNotes[0];
				notes.insert(0, dunceNote);
				dunceNote.spawned=true;
				callOnLuas('onSpawnNote', [notes.members.indexOf(dunceNote), dunceNote.noteData, dunceNote.noteType, dunceNote.isSustainNote]);
				callOnHaxes('spawnNote', [dunceNote]);
				var index:Int = unspawnNotes.indexOf(dunceNote);
				unspawnNotes.splice(index, 1);
			}
		}

		if (unspawnFakeNotes[0] != null)
		{
			var time:Float = spawnTime;
			if(songSpeed < 1) time /= songSpeed;
			if(unspawnFakeNotes[0].multSpeed < 1) time /= unspawnFakeNotes[0].multSpeed;

			while (unspawnFakeNotes.length > 0 && unspawnFakeNotes[0].strumTime - Conductor.songPosition < time)
			{
				var dunceNote:Note = unspawnFakeNotes[0];
				fakeNotes.insert(0, dunceNote);
				dunceNote.spawned=true;
				callOnLuas('onSpawnNote', [fakeNotes.members.indexOf(dunceNote), dunceNote.noteData, dunceNote.noteType, dunceNote.isSustainNote]);
				callOnHaxes('spawnNote', [dunceNote]);
				var index:Int = unspawnFakeNotes.indexOf(dunceNote);
				unspawnFakeNotes.splice(index, 1);
			}
		}

		if (generatedMusic)
		{
			if(!inCutscene)
			{
				if(!playerStrums.autoplay) {
					keyShit();
				}
				else if(boyfriend.animation.curAnim != null && boyfriend.holdTimer > Conductor.stepCrochet * (0.0011 / FlxG.sound.music.pitch) * boyfriend.singDuration && boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.animation.curAnim.name.endsWith('miss')) {
					boyfriend.dance();
				}
	
				if(!opponentStrums.autoplay) {
					keyShit();
				}
				else if(dad.animation.curAnim != null && dad.holdTimer > Conductor.stepCrochet * (0.0011 / FlxG.sound.music.pitch) * dad.singDuration && dad.animation.curAnim.name.startsWith('sing') && !dad.animation.curAnim.name.endsWith('miss')) {
					dad.dance();
				}
	
				if(gf != null && gf.animation.curAnim != null && gf.holdTimer > Conductor.stepCrochet * (0.0011 / FlxG.sound.music.pitch) * gf.singDuration && gf.animation.curAnim.name.startsWith('sing') && !gf.animation.curAnim.name.endsWith('miss')) {
					gf.dance();
				}


				if(startedCountdown)
				{
					noteCall();
					notefakeCall();
				}
				else
				{
					notes.forEachAlive(function(daNote:Note)
					{
						daNote.canBeHit = false;
						daNote.wasGoodHit = false;
					});

					fakeNotes.forEachAlive(function(daNote:Note)
					{
						daNote.canBeHit = false;
						daNote.wasGoodHit = false;
					});
				}
			}

		}

		checkEventNote();


		#if debug
		if(!endingSong && !startingSong) {
			if (FlxG.keys.justPressed.ONE) {
				KillNotes();
				FlxG.sound.music.onComplete();
			}
			if(FlxG.keys.justPressed.TWO) { //Go 10 seconds into the future :O
				setSongTime(Conductor.songPosition + 10000);
				clearNotesBefore(Conductor.songPosition);
			}
		}
		#end

		setOnLuas('cameraX', camFollowPos.x);
		setOnLuas('cameraY', camFollowPos.y);
		setOnLuas('botPlay', cpuControlled);
		callOnLuas('onUpdatePost', [elapsed]);

		setOnHaxes('cameraX', camFollowPos.x);
		setOnHaxes('cameraY', camFollowPos.y);
		setOnHaxes('botPlay', cpuControlled);
		callOnHaxes('updatePost', [elapsed]);
	}

	function notefakeCall()
	{
		var fakeCrochet:Float = (60 / SONG.bpm) * 1000;
		fakeNotes.forEachAlive(function(daNote:Note)
		{
			var strumGroup:StrumLineNote = playerFakeStrums;
			if(!daNote.mustPress) strumGroup = opponentFakeStrums;

			var strumX:Float = strumGroup.members[daNote.noteData].x;
			var strumY:Float = strumGroup.members[daNote.noteData].y;
			var strumAngle:Float = strumGroup.members[daNote.noteData].angle;
			var strumDirection:Float = strumGroup.members[daNote.noteData].direction;
			var strumAlpha:Float = strumGroup.members[daNote.noteData].alpha;
			var strumScroll:Bool = strumGroup.members[daNote.noteData].downScroll;

			strumX += daNote.offsetX;
			strumY += daNote.offsetY;
			strumAngle += daNote.offsetAngle;
			strumAlpha *= daNote.multAlpha;

			if (strumScroll) //Downscroll
				daNote.distance = (0.45 * (Conductor.songPosition - daNote.strumTime) * songSpeed * daNote.multSpeed);
			else
				daNote.distance = (-0.45 * (Conductor.songPosition - daNote.strumTime) * songSpeed * daNote.multSpeed);


			var angleDir = strumDirection * Math.PI / 180;
			if (daNote.copyAngle)
				daNote.angle = strumDirection - 90 + strumAngle;

			if(daNote.copyAlpha)
				daNote.alpha = strumAlpha;

			if(daNote.copyX)
				daNote.x = strumX + Math.cos(angleDir) * daNote.distance;

			if(daNote.copyY)
			{
				daNote.y = strumY + Math.sin(angleDir) * daNote.distance;

				//Jesus fuck this took me so much mother fucking time AAAAAAAAAA
				if(strumScroll && daNote.isSustainNote)
				{
					if (daNote.animation.curAnim != null && daNote.animation.curAnim.name.endsWith('end')) {
						daNote.y += 10.5 * (fakeCrochet / 400) * 1.5 * songSpeed + (46 * (songSpeed - 1));
						daNote.y -= 46 * (1 - (fakeCrochet / 600)) * songSpeed;
						switch(daNote.style)
						{
							default:
								daNote.y -= 19;
							case 'pixel':
								daNote.y += 8 + (6 - daNote.originalHeightForCalcs) * PlayState.daPixelZoom;
						}
					}
					daNote.y += (Note.swagWidth / 2) - (60.5 * (songSpeed - 1));
					daNote.y += 27.5 * ((SONG.bpm / 100) - 1) * (songSpeed - 1);
				}
			}

			mainFakeControls(daNote, strumGroup);
			
			var center:Float = strumY + Note.swagWidth / 2;
			if(strumGroup.members[daNote.noteData].sustainReduce && daNote.isSustainNote && (daNote.mustPress || !daNote.ignoreNote) && 
				(!daNote.mustPress || (daNote.wasGoodHit || (daNote.prevNote.wasGoodHit && !daNote.canBeHit))))
			{
				if (strumScroll)
				{
					if(daNote.y - daNote.offset.y * daNote.scale.y + daNote.height >= center)
					{
						var swagRect = new FlxRect(0, 0, daNote.frameWidth, daNote.frameHeight);
						swagRect.height = (center - daNote.y) / daNote.scale.y;
						swagRect.y = daNote.frameHeight - swagRect.height;

						daNote.clipRect = swagRect;
					}
				}
				else
				{
					if (daNote.y + daNote.offset.y * daNote.scale.y <= center)
					{
						var swagRect = new FlxRect(0, 0, daNote.width / daNote.scale.x, daNote.height / daNote.scale.y);
						swagRect.y = (center - daNote.y) / daNote.scale.y;
						swagRect.height -= swagRect.y;

						daNote.clipRect = swagRect;
					}
				}
			}

			// Kill extremely late notes and cause misses
			if (Conductor.songPosition > noteKillOffset + daNote.strumTime)
			{
				if (!strumGroup.autoplay &&!daNote.ignoreNote && !endingSong && (daNote.tooLate || !daNote.wasGoodHit)) {
					noteMiss(daNote, strumGroup.characters);
				}

				daNote.active = false;
				daNote.visible = false;

				daNote.kill();
				notes.remove(daNote, true);
				daNote.destroy();
			}
		});
		
	}

	function noteCall()
	{
		var fakeCrochet:Float = (60 / SONG.bpm) * 1000;
		notes.forEachAlive(function(daNote:Note)
		{
			var strumGroup:StrumLineNote = playerStrums;
			if(!daNote.mustPress) strumGroup = opponentStrums;

			var strumX:Float = strumGroup.members[daNote.noteData].x;
			var strumY:Float = strumGroup.members[daNote.noteData].y;
			var strumAngle:Float = strumGroup.members[daNote.noteData].angle;
			var strumDirection:Float = strumGroup.members[daNote.noteData].direction;
			var strumAlpha:Float = strumGroup.members[daNote.noteData].alpha;
			var strumScroll:Bool = strumGroup.members[daNote.noteData].downScroll;

			strumX += daNote.offsetX;
			strumY += daNote.offsetY;
			strumAngle += daNote.offsetAngle;
			strumAlpha *= daNote.multAlpha;

			if (strumScroll) //Downscroll
				daNote.distance = (0.45 * (Conductor.songPosition - daNote.strumTime) * songSpeed * daNote.multSpeed);
			else
				daNote.distance = (-0.45 * (Conductor.songPosition - daNote.strumTime) * songSpeed * daNote.multSpeed);

			var angleDir = strumDirection * Math.PI / 180;
			if (daNote.copyAngle)
				daNote.angle = strumDirection - 90 + strumAngle;

			if(daNote.copyAlpha)
				daNote.alpha = strumAlpha;

			if(daNote.copyX)
				daNote.x = strumX + Math.cos(angleDir) * daNote.distance;

			if(daNote.copyY)
			{
				daNote.y = strumY + Math.sin(angleDir) * daNote.distance;

				//Jesus fuck this took me so much mother fucking time AAAAAAAAAA
				if(strumScroll && daNote.isSustainNote)
				{
					//Idk Wtf is problem this stupid sustain note code bruh
					if (daNote.animation.curAnim != null && daNote.animation.curAnim.name.endsWith('end')) {
						daNote.y += 10.5 * (fakeCrochet / 400) * 1.5 * songSpeed + (46 * (songSpeed - 1));
						daNote.y -= 46 * (1 - (fakeCrochet / 600)) * songSpeed;
						switch(daNote.style)
						{
							case 'pixel':
								daNote.y += 8 + (6 - daNote.originalHeightForCalcs) * PlayState.daPixelZoom;
							default:
								daNote.y -= 19;
						}
						daNote.y += (Note.swagWidth / 2) - (60.5 * (songSpeed - 1));
						daNote.y += 27.5 * ((SONG.bpm / 100) - 1) * (songSpeed - 1);
					}
				}
			}

			mainControls(daNote, strumGroup);

			var center:Float = strumY + Note.swagWidth / 2;
			if(strumGroup.members[daNote.noteData].sustainReduce && daNote.isSustainNote && (daNote.mustPress || !daNote.ignoreNote) &&
                (!daNote.mustPress || (daNote.wasGoodHit || (daNote.prevNote.wasGoodHit && !daNote.canBeHit))))
			{
				if (strumScroll)
				{
					if(daNote.y - daNote.offset.y * daNote.scale.y + daNote.height >= center)
					{
						var swagRect = new FlxRect(0, 0, daNote.frameWidth, daNote.frameHeight);
						swagRect.height = (center - daNote.y) / daNote.scale.y;
						swagRect.y = daNote.frameHeight - swagRect.height;
						daNote.clipRect = swagRect;
					}
				}
				else
				{
					if (daNote.y + daNote.offset.y * daNote.scale.y <= center)
					{
						var swagRect = new FlxRect(0, 0, daNote.width / daNote.scale.x, daNote.height / daNote.scale.y);
						swagRect.y = (center - daNote.y) / daNote.scale.y;
						swagRect.height -= swagRect.y;
						daNote.clipRect = swagRect;
					}
				}
			}

			if (Conductor.songPosition > noteKillOffset + daNote.strumTime)
			{
				if (!strumGroup.autoplay &&!daNote.ignoreNote && !endingSong && (daNote.tooLate || !daNote.wasGoodHit)) {
					noteMiss(daNote, strumGroup.characters);
				}

				daNote.active = false;
				daNote.visible = false;

				daNote.kill();
				notes.remove(daNote, true);
				daNote.destroy();
			}
		});
	}

	function openPauseMenu()
	{
		persistentUpdate = false;
		persistentDraw = true;
		paused = true;

		if(FlxG.sound.music != null) {
			FlxG.sound.music.pause();
			if(vocalsBoyfriend != null)
			{
				for(boyfriend in vocalsBoyfriend)
				{
					boyfriend.pause();
				}
			}
			if(vocalsDad != null)
			{
				for(dad in vocalsDad)
				{
					dad.pause();
				}
			}
			if(vocals != null)
			{
				vocals.pause();
			}
		}
		openSubState(new PauseSubState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
		//}

		#if desktop
		DiscordClient.changePresence(detailsPausedText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
		#end
	}

	function openChartEditor()
	{
		persistentUpdate = false;
		paused = true;
		cancelMusicFadeTween();
		MusicBeatState.switchState(new ChartingState());
		chartingMode = true;

		#if desktop
		DiscordClient.changePresence("Chart Editor", null, null, true);
		#end
	}

	public var isDead:Bool = false; //Don't mess with this on Lua!!!
	function doDeathCheck(?skipHealthCheck:Bool = false) {
		if (((skipHealthCheck && instakillOnMiss) || health <= 0) && !practiceMode && !isDead && !opponentControlled)
		{
			var ret:Dynamic = callOnLuas('onGameOver', [], false);
			callOnHaxes('gameOver', []);
			if(ret != FunkinLua.Function_Stop) {
				boyfriend.stunned = true;
				deathCounter++;

				paused = true;
				if(vocalsBoyfriend != null)
				{
					for(boyfriend in vocalsBoyfriend)
					{
						boyfriend.stop();
					}
				}
				if(vocalsDad != null)
				{
					for(dad in vocalsDad)
					{
						dad.stop();
					}
				}
				if(vocals != null)
				{
					vocals.stop();
				}
				FlxG.sound.music.stop();

				persistentUpdate = false;
				persistentDraw = false;
				for (tween in modchartTweens) {
					tween.active = true;
				}
				for (timer in modchartTimers) {
					timer.active = true;
				}
				openSubState(new GameOverSubstate(boyfriend.getScreenPosition().x - boyfriend.playerPositionArray[0], boyfriend.getScreenPosition().y - boyfriend.playerPositionArray[1], boyfriend.isPlayer, camFollowPos.x, camFollowPos.y));
					
				
				#if desktop
				// Game Over doesn't get his own variable because it's only used here
				DiscordClient.changePresence("Game Over - " + detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
				#end
				isDead = true;
				return true;
			}
		}
		if (((skipHealthCheck && instakillOnMiss) || health <= 0) && !practiceMode && !isDead && opponentControlled)
		{
			var ret:Dynamic = callOnLuas('onGameOver', [], false);
			callOnHaxes('gameOver', []);
			if(ret != FunkinLua.Function_Stop) {
				boyfriend.stunned = true;
				deathCounter++;

				paused = true;
				if(vocalsBoyfriend != null)
				{
					for(boyfriend in vocalsBoyfriend)
					{
						boyfriend.stop();
					}
				}
				if(vocalsDad != null)
				{
					for(dad in vocalsDad)
					{
						dad.stop();
					}
				}
				if(vocals != null)
				{
					vocals.stop();
				}
				FlxG.sound.music.stop();

				persistentUpdate = false;
				persistentDraw = false;
				for (tween in modchartTweens) {
					tween.active = true;
				}
				for (timer in modchartTimers) {
					timer.active = true;
				}
				openSubState(new GameOverSubstate(dad.getScreenPosition().x - dad.positionArray[0], dad.getScreenPosition().y - dad.positionArray[1], dad.isPlayer, camFollowPos.x, camFollowPos.y));
				
				#if desktop
				// Game Over doesn't get his own variable because it's only used here
				DiscordClient.changePresence("Game Over - " + detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP1.getCharacter());
				#end
				isDead = true;
				return true;
			}
		}
		return false;
	}

	public function checkEventNote() {
		while(eventNotes.length > 0) {
			var leStrumTime:Float = eventNotes[0].strumTime;
			if(Conductor.songPosition < leStrumTime) {
				return;
			}

			var value1:String = '';
			if(eventNotes[0].value1 != null)
				value1 = eventNotes[0].value1;

			var value2:String = '';
			if(eventNotes[0].value2 != null)
				value2 = eventNotes[0].value2;

			triggerEventNote(eventNotes[0].event, value1, value2);
			eventNotes.shift();
		}
	}

	public function getControl(key:String) {
		var pressed:Bool = Reflect.getProperty(controls, key);
		//trace('Control result: ' + pressed);
		return pressed;
	}

	public function triggerEventNote(eventName:String, value1:String, value2:String) {
		switch(eventName) {
			case 'Dadbattle Spotlight':
				var val:Null<Int> = Std.parseInt(value1);
				if(val == null) val = 0;

				switch(Std.parseInt(value1))
				{
					case 1, 2, 3: //enable and target dad
						if(val == 1) //enable
						{
							dadbattleBlack.visible = true;
							dadbattleLight.visible = true;
							dadbattleSmokes.visible = true;
							defaultCamZoom += 0.12;
						}

						var who:Character = dad;
						if(val > 2) who = boyfriend;
						//2 only targets dad
						dadbattleLight.alpha = 0;
						new FlxTimer().start(0.12, function(tmr:FlxTimer) {
							dadbattleLight.alpha = 0.375;
						});
						dadbattleLight.setPosition(who.getGraphicMidpoint().x - dadbattleLight.width / 2, who.y + who.height - dadbattleLight.height + 50);

					default:
						dadbattleBlack.visible = false;
						dadbattleLight.visible = false;
						defaultCamZoom -= 0.12;
						FlxTween.tween(dadbattleSmokes, {alpha: 0}, 1, {onComplete: function(twn:FlxTween)
						{
							dadbattleSmokes.visible = false;
						}});
				}

			case 'Hey!':
				var value:Int = 2;
				switch(value1.toLowerCase().trim()) {
					case 'bf' | 'boyfriend' | '0':
						value = 0;
					case 'gf' | 'girlfriend' | '1':
						value = 1;
					case 'dad' | 'opponent' | '2':
						value = 2;
					default:
						value = 3;
				}

				var time:Float = Std.parseFloat(value2);
				if(Math.isNaN(time) || time <= 0) time = 0.6;

				if(value != 0) {
					if(dad.curCharacter.startsWith('gf')) { //Tutorial GF is actually Dad! The GF is an imposter!! ding ding ding ding ding ding ding, dindinding, end my suffering
						dad.playAnim('cheer', true);
						dad.specialAnim = true;
						dad.heyTimer = time;
					} else if (gf != null) {
						gf.playAnim('cheer', true);
						gf.specialAnim = true;
						gf.heyTimer = time;
					}
				}
				if(value != 1) {
					boyfriend.playAnim('hey', true);
					boyfriend.specialAnim = true;
					boyfriend.heyTimer = time;
				}

				if(value != 2) {
					dad.playAnim('hey', true);
					dad.specialAnim = true;
					dad.heyTimer = time;
				}

				if(value != 3 && getLuaCharacter(value1) != null) {
					getLuaCharacter(value1).playAnim('hey', true);
					getLuaCharacter(value1).specialAnim = true;
					getLuaCharacter(value1).heyTimer = time;
				}

			case 'Set GF Speed':
				var value:Int = Std.parseInt(value1);
				if(Math.isNaN(value) || value < 1) value = 1;
				gfSpeed = value;

			case 'Add Camera Zoom':
				if(ClientPrefs.camZooms && FlxG.camera.zoom < 1.35) {
					var camZoom:Float = Std.parseFloat(value1);
					var hudZoom:Float = Std.parseFloat(value2);
					if(Math.isNaN(camZoom)) camZoom = 0.015;
					if(Math.isNaN(hudZoom)) hudZoom = 0.03;

					FlxG.camera.zoom += camZoom;
					camHUD.zoom += hudZoom;
				}

			case 'Play Animation':
				//trace('Anim to play: ' + value1);
				var char:Character = null;
				switch(value2.toLowerCase().trim()) {
					case 'dad' | 'opponent'| '0':
						char = dad;
					case 'gf' | 'girlfriend'| '2':
						char = gf;
					case 'bf' | 'boyfriend' | '1':
						char = boyfriend;
					default:
						char = getLuaCharacter(value2);
				}

				if (char != null)
				{
					char.playAnim(value1, true);
					char.specialAnim = true;
				}

			case 'Camera Follow Pos':
				if(camFollow != null)
				{
					var val1:Float = Std.parseFloat(value1);
					var val2:Float = Std.parseFloat(value2);
					if(Math.isNaN(val1)) val1 = 0;
					if(Math.isNaN(val2)) val2 = 0;

					isCameraOnForcedPos = false;
					if(!Math.isNaN(Std.parseFloat(value1)) || !Math.isNaN(Std.parseFloat(value2))) {
						camFollow.x = val1;
						camFollow.y = val2;
						isCameraOnForcedPos = true;
					}
				}

			case 'Alt Idle Animation':
				var char:Character = null;
				switch(value1.toLowerCase().trim()) {
					case 'dad' | 'opponent'| '0':
						char = dad;
					case 'gf' | 'girlfriend'| '2':
						char = gf;
					case 'bf' | 'boyfriend' | '1':
						char = boyfriend;
					default:
						char = getLuaCharacter(value2);
				}

				if (char != null)
				{
					char.idleSuffix = value2;
					char.recalculateDanceIdle();
				}

			case 'Screen Shake':
				var valuesArray:Array<String> = [value1, value2];
				var targetsArray:Array<FlxCamera> = [camGame, camHUD];
				for (i in 0...targetsArray.length) {
					var split:Array<String> = valuesArray[i].split(',');
					var duration:Float = 0;
					var intensity:Float = 0;
					if(split[0] != null) duration = Std.parseFloat(split[0].trim());
					if(split[1] != null) intensity = Std.parseFloat(split[1].trim());
					if(Math.isNaN(duration)) duration = 0;
					if(Math.isNaN(intensity)) intensity = 0;

					if(duration > 0 && intensity != 0) {
						targetsArray[i].shake(intensity, duration);
					}
				}


			case 'Change Character':
				var charType:Int = 0;
				switch(value1.toLowerCase().trim()) {
					case 'bf' | 'boyfriend' | '0':
						charType = 0;
					case 'gf' | 'girlfriend'| '2':
						charType = 2;
					case 'dad' | 'opponent'| '1':
						charType = 1;
					case 'mom' | 'opponent2'| '3':
						charType = 3;
					default:
						charType = 4;
				}

				switch(charType) {
					case 0:
						if(boyfriend.curCharacter != value2) {
							if(!boyfriendMap.exists(value2)) {
								addCharacterToList(value2, charType, value1.contains('flip'));
							}

							var lastAlpha:Float = boyfriend.alpha;
							boyfriend.alpha = 0.00001;
							boyfriend = boyfriendMap.get(value2);
							boyfriend.alpha = lastAlpha;
							if(opponentControlled)
							    iconP2.changeIcon(boyfriend.healthIcon);
							else
								iconP1.changeIcon(boyfriend.healthIcon);
							changeSkin('playerStrums', boyfriendMap.get(value2));
						}
						setOnLuas('boyfriendName', boyfriend.curCharacter);

					case 1:
						if(dad.curCharacter != value2) {
							if(!dadMap.exists(value2)) {
								addCharacterToList(value2, charType, value1.contains('flip'));
							}

							var wasGf:Bool = dad.curCharacter.startsWith('gf');
							var lastAlpha:Float = dad.alpha;
							dad.alpha = 0.00001;
							dad = dadMap.get(value2);
							if(!dad.curCharacter.startsWith('gf')) {
								if(wasGf && gf != null) {
									gf.visible = true;
								}
							} else if(gf != null) {
								gf.visible = false;
							}
							dad.alpha = lastAlpha;
							if(opponentControlled)
								iconP1.changeIcon(dad.healthIcon);
							else
								iconP2.changeIcon(dad.healthIcon);
							changeSkin('opponentStrums', dadMap.get(value2));
						}
						setOnLuas('dadName', dad.curCharacter);

					case 2:
						if(gf != null)
						{
							if(gf.curCharacter != value2)
							{
								if(!gfMap.exists(value2))
								{
									addCharacterToList(value2, charType, value1.contains('flip'));
								}

								var lastAlpha:Float = gf.alpha;
								gf.alpha = 0.00001;
								gf = gfMap.get(value2);
								gf.alpha = lastAlpha;
								changeSkin('opponentFakeStrums', gfMap.get(value2));
							}
							setOnLuas('gfName', gf.curCharacter);
						}
					case 3:
						var mom = getLuaCharacter('mom');
						if(mom.curCharacter != value2) {
							if(!characterMap.exists(value2)) {
								addCharacterToList(value2, charType, !value1.contains('flip'));
							}

							var lastAlpha:Float = mom.alpha;
							mom.alpha = 0.00001;
							mom = characterMap.get(value2);
							mom.alpha = lastAlpha;
							changeSkin('playerFakeStrums', characterMap.get(value2));
						}
						setOnLuas('momName', mom.curCharacter);
					case 4:
						var luaCharacter = getLuaCharacter(value1);
						if(luaCharacter.curCharacter != value2) {
							if(!characterMap.exists(value2)) {
								if(luaCharacter.isPlayer)
									addCharacterToList(value2, charType, !value1.contains('flip'));
								else
									addCharacterToList(value2, charType, value1.contains('flip'));
								
							}
							var lastAlpha:Float = luaCharacter.alpha;
							luaCharacter.alpha = 0.00001;
							luaCharacter = characterMap.get(value2);
							luaCharacter.alpha = lastAlpha;
						}
				}

				if(opponentControlled)
					{
						iconP2.changeIcon(boyfriend.healthIcon);
						iconP1.changeIcon(dad.healthIcon);
					}
					else
					{
						iconP2.changeIcon(dad.healthIcon);
						iconP1.changeIcon(boyfriend.healthIcon);
					}
				reloadHealthBarColors();


			case 'Change Character to Sing':
				var strumLine:StrumLineNote = null;
				switch(value1.toLowerCase().trim()) {
					case 'bf' | 'boyfriend' | '0':
						strumLine = playerStrums;
					case 'gf' | 'girlfriend'| '2':
						strumLine = opponentFakeStrums;
					case 'dad' | 'opponent'| '1':
						strumLine = opponentStrums;
					case 'mom' | 'opponent2'| '3':
						strumLine = playerFakeStrums;
				}

				var char:Character = null;
				switch(value1.toLowerCase().trim()) {
					case 'dad' | 'opponent'| '0':
						char = dad;
					case 'gf' | 'girlfriend'| '2':
						char = gf;
					case 'bf' | 'boyfriend' | '1':
						char = boyfriend;
					default:
						char = getLuaCharacter(value2);
				}

				if(strumLine != null && char != null)
				{
					strumLine.characters = [char];
				}
				
			case 'Change Scroll Speed':
				if (songSpeedType == "constant")
					return;
				var val1:Float = Std.parseFloat(value1);
				var val2:Float = Std.parseFloat(value2);
				if(Math.isNaN(val1)) val1 = 1;
				if(Math.isNaN(val2)) val2 = 0;

				var newValue:Float = SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed', 1) * val1;

				if(val2 <= 0)
				{
					songSpeed = newValue;
				}
				else
				{
					songSpeedTween = FlxTween.tween(this, {songSpeed: newValue}, val2 / playbackRate, {ease: FlxEase.linear, onComplete:
						function (twn:FlxTween)
						{
							songSpeedTween = null;
						}
					});
				}

			case 'Set Property':
				if(value1 != null)
				{
					var killMe:Array<String> = value1.split('.');
					if(killMe.length > 1) {
						Globals.setVarInArray(Globals.getPropertyLoopThingWhatever(killMe, true, true), killMe[killMe.length-1], value2);
					} else {
						Globals.setVarInArray(this, value1, value2);
					}
				}
			case 'Change Stage':
				//Yeah these code were bad and bug
				if(curStage != value1) {
					var swapp:Bool = false;
					switch(value2)
					{
						case 'true':
							swapp = true;
						default:
							swapp = false;
					}
					createStage(value1, swapp);
					curStage = value1;
				}

		}
		stage.triggerEventStage(eventName, [value1, value2]);
		callOnLuas('onEvent', [eventName, value1, value2]);
		callOnHaxes('event', [eventName, value1, value2]);
	}

	function changeSkin(strumline:String, character:Character)
	{
		switch(strumline)
		{
			case 'playerStrums':
				playerStrums.characters = [character];
				for (i in 0...unspawnNotes.length) //Added this before it too late
				{
					var daNote:Note = unspawnNotes[i];
					if(daNote.mustPress && (daNote.noteType == '' || daNote.noteType == 'Alt Animation' || daNote.noteType == 'No Animation' || daNote.noteType == 'GF Sing') && SONG.arrowStyle.length < 1 && SONG.arrowSkin.length < 1) //Prevent avoid the notetype stuff
					{
						daNote.texture = character.arrowSkin;
						daNote.style = character.arrowStyle;
						daNote.noteSplashTexture = character.splashSkin;
					}
				}
				for (i in 0...notes.members.length)
				{
					var daNote:Note = notes.members[i];
					if(daNote.mustPress && (daNote.noteType == '' || daNote.noteType == 'Alt Animation' || daNote.noteType == 'No Animation' || daNote.noteType == 'GF Sing') && SONG.arrowStyle.length < 1 && SONG.arrowSkin.length < 1) //Prevent avoid the notetype stuff
					{
						daNote.texture = character.arrowSkin;
						daNote.style = character.arrowStyle;
						daNote.noteSplashTexture = character.splashSkin;
					}
				}
				for (i in 0...playerStrums.members.length)
				{
					var strums:StrumNote = playerStrums.members[i];
					if(SONG.arrowStyle.length < 1 && SONG.arrowSkin.length < 1)
					{
						strums.texture = character.arrowSkin;
						strums.style = character.arrowStyle;
					}
				}
			case 'opponentStrums':
				opponentStrums.characters = [character];
				for (i in 0...unspawnNotes.length) //Added this before it too late
				{
					var daNote:Note = unspawnNotes[i];
					if(!daNote.mustPress && (daNote.noteType == '' || daNote.noteType == 'Alt Animation' || daNote.noteType == 'No Animation' || daNote.noteType == 'GF Sing') && SONG.arrowStyle.length < 1 && SONG.arrowSkin.length < 1) //Prevent avoid the notetype stuff
					{
						daNote.texture = character.arrowSkin;
						daNote.style = character.arrowStyle;
					}
				}
				for (i in 0...notes.members.length)
				{
					var daNote:Note = notes.members[i];
					if(!daNote.mustPress && (daNote.noteType == '' || daNote.noteType == 'Alt Animation' || daNote.noteType == 'No Animation' || daNote.noteType == 'GF Sing') && SONG.arrowStyle.length < 1 && SONG.arrowSkin.length < 1) //Prevent avoid the notetype stuff
					{
						daNote.texture = character.arrowSkin;
						daNote.style = character.arrowStyle;
					}
				}
				for (i in 0...opponentStrums.members.length)
				{
					var strums:StrumNote = opponentStrums.members[i];
					if(SONG.arrowStyle.length < 1 && SONG.arrowSkin.length < 1)
					{
						strums.texture = character.arrowSkin;
						strums.style = character.arrowStyle;
					}
				}
			case 'opponentFakeStrums':
				opponentFakeStrums.characters = [character];
				for (i in 0...unspawnFakeNotes.length) //Added this before it too late
				{
					var daNote:Note = unspawnFakeNotes[i];
					if(!daNote.mustPress && (daNote.noteType == '' || daNote.noteType == 'Alt Animation' || daNote.noteType == 'No Animation' || daNote.noteType == 'GF Sing') && SONG.arrowStyle.length < 1 && SONG.arrowSkin.length < 1) //Prevent avoid the notetype stuff
					{
						daNote.texture = character.arrowSkin;
						daNote.style = character.arrowStyle;
					}
				}
				for (i in 0...fakeNotes.members.length)
				{
					var daNote:Note = fakeNotes.members[i];
					if(!daNote.mustPress && (daNote.noteType == '' || daNote.noteType == 'Alt Animation' || daNote.noteType == 'No Animation' || daNote.noteType == 'GF Sing') && SONG.arrowStyle.length < 1 && SONG.arrowSkin.length < 1) //Prevent avoid the notetype stuff
					{
						daNote.texture = character.arrowSkin;
						daNote.style = character.arrowStyle;
					}
				}
				for (i in 0...opponentFakeStrums.members.length)
				{
					var strums:StrumNote = opponentFakeStrums.members[i];
					if(SONG.arrowStyle.length < 1 && SONG.arrowSkin.length < 1)
					{
						strums.texture = character.arrowSkin;
						strums.style = character.arrowStyle;
					}
				}
			case 'playerFakeStrums':
				playerFakeStrums.characters = [character];
				for (i in 0...unspawnFakeNotes.length) //Added this before it too late
				{
					var daNote:Note = unspawnFakeNotes[i];
					if(!daNote.mustPress && (daNote.noteType == '' || daNote.noteType == 'Alt Animation' || daNote.noteType == 'No Animation' || daNote.noteType == 'GF Sing') && SONG.arrowStyle.length < 1 && SONG.arrowSkin.length < 1) //Prevent avoid the notetype stuff
					{
						daNote.texture = character.arrowSkin;
						daNote.style = character.arrowStyle;
					}
				}
				for (i in 0...fakeNotes.members.length)
				{
					var daNote:Note = fakeNotes.members[i];
					if(!daNote.mustPress && (daNote.noteType == '' || daNote.noteType == 'Alt Animation' || daNote.noteType == 'No Animation' || daNote.noteType == 'GF Sing') && SONG.arrowStyle.length < 1 && SONG.arrowSkin.length < 1) //Prevent avoid the notetype stuff
					{
						daNote.texture = character.arrowSkin;
						daNote.style = character.arrowStyle;
					}
				}
				for (i in 0...playerFakeStrums.members.length)
				{
					var strums:StrumNote = playerFakeStrums.members[i];
					if(SONG.arrowStyle.length < 1 && SONG.arrowSkin.length < 1)
					{
						strums.texture = character.arrowSkin;
						strums.style = character.arrowStyle;
					}
				}
		}
	}

	function moveCameraSection():Void {
		if(SONG.notes[curSection] == null) return;

		if (gf != null && SONG.notes[curSection].gfSection)
		{
			camFollow.set(gf.getMidpoint().x, gf.getMidpoint().y);
			camFollow.x += gf.cameraPosition[0] + girlfriendCameraOffset[0];
			camFollow.y += gf.cameraPosition[1] + girlfriendCameraOffset[1];
			tweenCamIn();
			callOnLuas('onMoveCamera', ['gf']);
			callOnHaxes('moveCamera', ['gf']);
			return;
		}

		if (!SONG.notes[curSection].mustHitSection)
		{
			moveCamera(true);
			callOnLuas('onMoveCamera', ['dad']);
			callOnHaxes('moveCamera', ['dad']);
		}
		else
		{
			moveCamera(false);
			callOnLuas('onMoveCamera', ['boyfriend']);
			callOnHaxes('moveCamera', ['boyfriend']);
		}
	}

	var cameraTwn:FlxTween;
	public function moveCamera(isDad:Bool)
	{
		if(isDad)
		{
			if(opponentStrums != null)
			{
				for(character in opponentStrums.characters)
				{
					if(character.isPlayer)
					{
						camFollow.set(character.getMidpoint().x + 150, character.getMidpoint().y - 100);
						camFollow.x += character.playerCameraPosition[0] + opponentCameraOffset[0];
						camFollow.y += character.playerCameraPosition[1] + opponentCameraOffset[1];
					}
					else
					{
						camFollow.set(character.getMidpoint().x + 150, character.getMidpoint().y - 100);
						camFollow.x += character.cameraPosition[0] + opponentCameraOffset[0];
						camFollow.y += character.cameraPosition[1] + opponentCameraOffset[1];
					}
				}

			}
			else
			{
				if(dad.isPlayer)
				{
					camFollow.set(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);
					camFollow.x += dad.playerCameraPosition[0] + opponentCameraOffset[0];
					camFollow.y += dad.playerCameraPosition[1] + opponentCameraOffset[1];
				}
				else
				{
					camFollow.set(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);
					camFollow.x += dad.cameraPosition[0] + opponentCameraOffset[0];
					camFollow.y += dad.cameraPosition[1] + opponentCameraOffset[1];
				}
			}
			tweenCamIn();
		}
		else
		{
			if(playerStrums != null)
			{
				for(character in playerStrums.characters)
				{
					if(character.isPlayer)
					{
						camFollow.set(character.getMidpoint().x - 100, character.getMidpoint().y - 100);
						camFollow.x -= character.playerCameraPosition[0] - boyfriendCameraOffset[0];
						camFollow.y += character.playerCameraPosition[1] + boyfriendCameraOffset[1];
					}
					else
					{
						camFollow.set(character.getMidpoint().x - 100, character.getMidpoint().y - 100);
						camFollow.x -= character.cameraPosition[0] - boyfriendCameraOffset[0];
						camFollow.y += character.cameraPosition[1] + boyfriendCameraOffset[1];
					}
				}

			}
			else
			{
				if(boyfriend.isPlayer)
				{
					camFollow.set(boyfriend.getMidpoint().x - 100, boyfriend.getMidpoint().y - 100);
					camFollow.x -= boyfriend.playerCameraPosition[0] - boyfriendCameraOffset[0];
					camFollow.y += boyfriend.playerCameraPosition[1] + boyfriendCameraOffset[1];
				}
				else
				{
					camFollow.set(boyfriend.getMidpoint().x - 100, boyfriend.getMidpoint().y - 100);
					camFollow.x -= boyfriend.cameraPosition[0] - boyfriendCameraOffset[0];
					camFollow.y += boyfriend.cameraPosition[1] + boyfriendCameraOffset[1];
				}
			}
			tweenCamIn(1);
		}
	}

	function tweenCamIn(?zoom:Float = 1.3) {
		if (Paths.formatToSongPath(SONG.song) == 'tutorial' && cameraTwn == null && FlxG.camera.zoom != 1.3) {
			cameraTwn = FlxTween.tween(FlxG.camera, {zoom: 1.3}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut, onComplete:
				function (twn:FlxTween) {
					cameraTwn = null;
				}
			});
		}
	}

	function snapCamFollowToPos(x:Float, y:Float) {
		camFollow.set(x, y);
		camFollowPos.setPosition(x, y);
	}

	public function finishSong(?ignoreNoteOffset:Bool = false):Void
	{
		var finishCallback:Void->Void = endSong; //In case you want to change it in a specific song.

		updateTime = false;
		FlxG.sound.music.volume = 0;
		if(vocals != null)
		{
			vocals.volume = 0;
			vocals.pause();
		}

		if(vocalsBoyfriend != null)
		{
			for(boyfriend in vocalsBoyfriend)
			{
				boyfriend.volume = 0;
				boyfriend.pause();
			}
		}
		if(vocalsDad != null)
		{
			for(dad in vocalsDad)
			{
				dad.volume = 0;
				dad.pause();
			}
		}
		if(ClientPrefs.noteOffset <= 0 || ignoreNoteOffset) {
			finishCallback();
		} else {
			finishTimer = new FlxTimer().start(ClientPrefs.noteOffset / 1000, function(tmr:FlxTimer) {
				finishCallback();
			});
		}
	}


	public var transitioning = false;
	public function endSong():Void
	{
		//Should kill you if you tried to cheat
		if(!startingSong) {
			notes.forEach(function(daNote:Note) {
				if(daNote.strumTime < songLength - Conductor.safeZoneOffset) {
					health -= 0.05 * healthLoss;
				}
			});

			for (daNote in unspawnNotes) {
				if(daNote.strumTime < songLength - Conductor.safeZoneOffset) {
					health -= 0.05 * healthLoss;
				}
			}

			fakeNotes.forEach(function(daNote:Note) {
				if(daNote.strumTime < songLength - Conductor.safeZoneOffset) {
					health -= 0.05 * healthLoss;
				}
			});

			for (daNote in unspawnFakeNotes) {
				if(daNote.strumTime < songLength - Conductor.safeZoneOffset) {
					health -= 0.05 * healthLoss;
				}
			}


			if(doDeathCheck()) {
				return;
			}
		}

		timeBarBG.visible = false;
		timeBar.visible = false;
		timeTxt.visible = false;
		canPause = false;
		endingSong = true;
		camZooming = false;
		inCutscene = false;
		updateTime = false;

		deathCounter = 0;
		seenCutscene = false;

		#if ACHIEVEMENTS_ALLOWED
		if(achievementObj != null) {
			return;
		} else {
			var achieve:String = checkForAchievement(['week1_nomiss', 'week2_nomiss', 'week3_nomiss', 'week4_nomiss',
				'week5_nomiss', 'week6_nomiss', 'week7_nomiss', 'ur_bad',
				'ur_good', 'hype', 'two_keys', 'toastie', 'debugger']);

			if(achieve != null) {
				startAchievement(achieve);
				return;
			}
		}
		#end

		var ret:Dynamic = callOnLuas('onEndSong', [], false);
		callOnHaxes('endSong', []);
		if(ret != FunkinLua.Function_Stop && !transitioning) {
			if (SONG.validScore)
			{
				#if !switch
				var percent:Float = ratingPercent;
				if(Math.isNaN(percent)) percent = 0;
				Highscore.saveScore(SONG.song, songScore, storyDifficulty, percent);
				#end
			}
			playbackRate = 1;

			if (chartingMode)
			{
				openChartEditor();
				return;
			}

			if (isStoryMode)
			{
				campaignScore += songScore;
				campaignMisses += songMisses;

				storyPlaylist.remove(storyPlaylist[0]);

				if (storyPlaylist.length <= 0)
				{
					WeekData.loadTheFirstEnabledMod();
					FlxG.sound.playMusic(Paths.music('freakyMenu'));

					cancelMusicFadeTween();
					if(FlxTransitionableState.skipNextTransIn) {
						CustomFadeTransition.nextCamera = null;
					}
					MusicBeatState.switchState(new StoryMenuState());

					// if ()
					if(!ClientPrefs.getGameplaySetting('practice', false) && !ClientPrefs.getGameplaySetting('botplay', false)) {
						StoryMenuState.weekCompleted.set(WeekData.weeksList[storyWeek], true);

						if (SONG.validScore)
						{
							Highscore.saveWeekScore(WeekData.getWeekFileName(), campaignScore, storyDifficulty);
						}

						FlxG.save.data.weekCompleted = StoryMenuState.weekCompleted;
						FlxG.save.flush();
					}
					changedDifficulty = false;
				}
				else
				{
					var difficulty:String = CoolUtil.getDifficultyFilePath();

					trace('LOADING NEXT SONG');
					trace(Paths.formatToSongPath(PlayState.storyPlaylist[0]) + difficulty);

					var winterHorrorlandNext = (Paths.formatToSongPath(SONG.song) == "eggnog");
					if (winterHorrorlandNext)
					{
						var blackShit:FlxSprite = new FlxSprite(-FlxG.width * FlxG.camera.zoom,
							-FlxG.height * FlxG.camera.zoom).makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.BLACK);
						blackShit.scrollFactor.set();
						add(blackShit);
						camHUD.visible = false;

						FlxG.sound.play(Paths.sound('stages/mall/Lights_Shut_off'));
					}

					FlxTransitionableState.skipNextTransIn = true;
					FlxTransitionableState.skipNextTransOut = true;

					prevCamFollow = camFollow;
					prevCamFollowPos = camFollowPos;

					PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0] + difficulty, PlayState.storyPlaylist[0]);
					FlxG.sound.music.stop();

					if(winterHorrorlandNext) {
						new FlxTimer().start(1.5, function(tmr:FlxTimer) {
							cancelMusicFadeTween();
							LoadingState.loadAndSwitchState(new PlayState());
						});
					} else {
						cancelMusicFadeTween();
						LoadingState.loadAndSwitchState(new PlayState());
					}
				}
			}
			else if(isBETADCIU)
			{
				trace('WENT BACK TO BETADCIU??');
				WeekDataAlt.loadTheFirstEnabledMod();
				cancelMusicFadeTween();
				if(FlxTransitionableState.skipNextTransIn) {
					CustomFadeTransition.nextCamera = null;
				}
				MusicBeatState.switchState(new BETADCIUState());
				FlxG.sound.playMusic(Paths.music('freakyMenu'));
				changedDifficulty = false;
			}
			else if(isCover)
			{
				trace('WENT BACK TO COVER??');
				WeekDataAlt.loadTheFirstEnabledMod();
				cancelMusicFadeTween();
				if(FlxTransitionableState.skipNextTransIn) {
					CustomFadeTransition.nextCamera = null;
				}
				MusicBeatState.switchState(new CoverState());
				FlxG.sound.playMusic(Paths.music('freakyMenu'));
				changedDifficulty = false;
			}
			else
			{
				trace('WENT BACK TO FREEPLAY??');
				WeekData.loadTheFirstEnabledMod();
				cancelMusicFadeTween();
				if(FlxTransitionableState.skipNextTransIn) {
					CustomFadeTransition.nextCamera = null;
				}
				MusicBeatState.switchState(new FreeplayState());
				FlxG.sound.playMusic(Paths.music('freakyMenu'));
				changedDifficulty = false;
			}
			transitioning = true;
		}
	}

	#if ACHIEVEMENTS_ALLOWED
	var achievementObj:AchievementObject = null;
	function startAchievement(achieve:String) {
		achievementObj = new AchievementObject(achieve, camOther);
		achievementObj.onFinish = achievementEnd;
		add(achievementObj);
		trace('Giving achievement ' + achieve);
	}
	function achievementEnd():Void
	{
		achievementObj = null;
		if(endingSong && !inCutscene) {
			endSong();
		}
	}
	#end

	public function KillNotes() {
		while(notes.length > 0) {
			var daNote:Note = notes.members[0];
			daNote.active = false;
			daNote.visible = false;

			daNote.kill();
			notes.remove(daNote, true);
			daNote.destroy();
		}

		while(fakeNotes.length > 0) {
			var daNote:Note = fakeNotes.members[0];
			daNote.active = false;
			daNote.visible = false;

			daNote.kill();
			fakeNotes.remove(daNote, true);
			daNote.destroy();
		}
		unspawnNotes = [];
		unspawnFakeNotes = [];
		eventNotes = [];
	}

	public var totalPlayed:Int = 0;
	public var totalNotesHit:Float = 0.0;

	public var showCombo:Bool = false;
	public var showComboNum:Bool = true;
	public var showRating:Bool = true;

	private function cachePopUpScore()
	{
		var pixelShitPart1:String = '';
		var pixelShitPart2:String = '';
		if (isPixelStage)
		{
			pixelShitPart1 = 'pixelUI/';
			pixelShitPart2 = '-pixel';
		}

		Paths.image("judegetment/" + pixelShitPart1 + "sick-fc" + pixelShitPart2);
		Paths.image("judegetment/" + pixelShitPart1 + "sick" + pixelShitPart2);
		Paths.image("judegetment/" + pixelShitPart1 + "good" + pixelShitPart2);
		Paths.image("judegetment/" + pixelShitPart1 + "bad" + pixelShitPart2);
		Paths.image("judegetment/" + pixelShitPart1 + "shit" + pixelShitPart2);
		Paths.image("combo/" + pixelShitPart1 + "combo" + pixelShitPart2);
		for (i in 0...10) {
			Paths.image("combo/" + pixelShitPart1 + 'num' + i + pixelShitPart2);
			Paths.image("combo/" + pixelShitPart1 + 'FC/' + 'num' + i + pixelShitPart2);
		}
	}

	private function popUpScore(note:Note = null, strumline:StrumLineNote = null):Void
	{
		var noteDiff:Float = Math.abs(note.strumTime - Conductor.songPosition + ClientPrefs.ratingOffset);
		//trace(noteDiff, ' ' + Math.abs(note.strumTime - Conductor.songPosition));

		// boyfriend.playAnim('hey');
		if(vocals != null)
		{
			vocals.volume = 1;
		}
		
		if(vocalsBoyfriend != null)
		{
			for(boyfriend in vocalsBoyfriend)
			{
				boyfriend.volume = 1;
			}
		}

		if(vocalsDad != null)
		{
			for(dad in vocalsDad)
			{
				dad.volume = 1;
			}
		}
		

		var placement:String = Std.string(combo);

		var coolText:FlxText = new FlxText(0, 0, 0, placement, 32);
		coolText.screenCenter();
		coolText.x = FlxG.width * 0.35;
		//

		var rating:FlxSprite = new FlxSprite();
		var score:Int = 350;

		//tryna do MS based judgment due to popular demand
		var daRating:Rating = Conductor.judgeNote(note, noteDiff / playbackRate);

		totalNotesHit += daRating.ratingMod;
		note.ratingMod = daRating.ratingMod;
		if(!note.ratingDisabled) daRating.increase();
		note.rating = daRating.name;
		score = daRating.score;

		if(daRating.noteSplash && !note.noteSplashDisabled)
		{
			spawnNoteSplashOnNote(note, strumline);
		}

		if(!practiceMode) {
			songScore += score;
			if(!note.ratingDisabled)
			{
				songHits++;
				totalPlayed++;
				RecalculateRating(false);
			}
		}

		var pixelShitPart1:String = "";
		var pixelShitPart2:String = '';

		if (PlayState.isPixelStage)
		{
			pixelShitPart1 = 'pixelUI/';
			pixelShitPart2 = '-pixel';
		}

		switch(ratingFC)
		{
			default:
				rating.loadGraphic(Paths.image('judegetment/' + pixelShitPart1 + daRating.image + pixelShitPart2));
			case 'SFC':
				rating.loadGraphic(Paths.image('judegetment/' + pixelShitPart1 + 'sick-fc' + pixelShitPart2));
		}

		rating.cameras = [camHUD];
		rating.screenCenter();
		rating.x = coolText.x - 40;
		rating.y -= 60;
		rating.acceleration.y = 550 * playbackRate * playbackRate;
		rating.velocity.y -= FlxG.random.int(140, 175) * playbackRate;
		rating.velocity.x -= FlxG.random.int(0, 10) * playbackRate;
		rating.visible = (!ClientPrefs.hideHud && showRating);
		rating.x += ClientPrefs.comboOffset[0];
		rating.y -= ClientPrefs.comboOffset[1];

		var comboSpr:FlxSprite = new FlxSprite();
		comboSpr.loadGraphic(Paths.image('combo/' + pixelShitPart1 + 'combo' + pixelShitPart2));
		comboSpr.cameras = [camHUD];
		comboSpr.screenCenter();
		comboSpr.x = coolText.x;
		comboSpr.acceleration.y = FlxG.random.int(200, 300) * playbackRate * playbackRate;
		comboSpr.velocity.y -= FlxG.random.int(140, 160) * playbackRate;
		comboSpr.visible = (!ClientPrefs.hideHud && showCombo);
		comboSpr.x += ClientPrefs.comboOffset[0];
		comboSpr.y -= ClientPrefs.comboOffset[1];
		comboSpr.y += 60;
		comboSpr.velocity.x += FlxG.random.int(1, 10) * playbackRate;

		insert(members.indexOf(strumLineNotes), rating);
		
		if (!ClientPrefs.comboStacking)
		{
			if (lastRating != null) lastRating.kill();
			lastRating = rating;
		}

		if (!PlayState.isPixelStage)
		{
			rating.setGraphicSize(Std.int(rating.width * 0.7));
			rating.antialiasing = ClientPrefs.globalAntialiasing;
			comboSpr.setGraphicSize(Std.int(comboSpr.width * 0.7));
			comboSpr.antialiasing = ClientPrefs.globalAntialiasing;
		}
		else
		{
			rating.setGraphicSize(Std.int(rating.width * daPixelZoom * 0.85));
			comboSpr.setGraphicSize(Std.int(comboSpr.width * daPixelZoom * 0.85));
		}

		comboSpr.updateHitbox();
		rating.updateHitbox();

		var seperatedScore:Array<Int> = [];

		if(combo >= 1000) {
			seperatedScore.push(Math.floor(combo / 1000) % 10);
		}
		seperatedScore.push(Math.floor(combo / 100) % 10);
		seperatedScore.push(Math.floor(combo / 10) % 10);
		seperatedScore.push(combo % 10);

		var daLoop:Int = 0;
		var xThing:Float = 0;
		if (showCombo)
		{
			insert(members.indexOf(strumLineNotes), comboSpr);
		}
		if (!ClientPrefs.comboStacking)
		{
			if (lastCombo != null) lastCombo.kill();
			lastCombo = comboSpr;
		}
		if (lastScore != null)
		{
			while (lastScore.length > 0)
			{
				lastScore[0].kill();
				lastScore.remove(lastScore[0]);
			}
		}
		for (i in seperatedScore)
		{
			var numScore:FlxSprite = new FlxSprite();
			switch(ratingFC)
			{
				default:
					numScore.loadGraphic(Paths.image('combo/' + pixelShitPart1 + 'num' + Std.int(i) + pixelShitPart2));
				case 'SFC':
					numScore.loadGraphic(Paths.image('combo/' + pixelShitPart1 + 'FC/'  + 'num' + Std.int(i) + pixelShitPart2));
			}
			numScore.cameras = [camHUD];
			numScore.screenCenter();
			numScore.x = coolText.x + (43 * daLoop) - 90;
			numScore.y += 80;

			numScore.x += ClientPrefs.comboOffset[2];
			numScore.y -= ClientPrefs.comboOffset[3];
			
			if (!ClientPrefs.comboStacking)
				lastScore.push(numScore);

			if (!PlayState.isPixelStage)
			{
				numScore.antialiasing = ClientPrefs.globalAntialiasing;
				numScore.setGraphicSize(Std.int(numScore.width * 0.5));
			}
			else
			{
				numScore.setGraphicSize(Std.int(numScore.width * daPixelZoom));
			}
			numScore.updateHitbox();

			numScore.acceleration.y = FlxG.random.int(200, 300) * playbackRate * playbackRate;
			numScore.velocity.y -= FlxG.random.int(140, 160) * playbackRate;
			numScore.velocity.x = FlxG.random.float(-5, 5) * playbackRate;
			numScore.visible = !ClientPrefs.hideHud;

			//if (combo >= 10 || combo == 0)
			if(showComboNum)
				insert(members.indexOf(strumLineNotes), numScore);

			FlxTween.tween(numScore, {alpha: 0}, 0.2 / playbackRate, {
				onComplete: function(tween:FlxTween)
				{
					numScore.destroy();
				},
				startDelay: Conductor.crochet * 0.002 / playbackRate
			});

			daLoop++;
			if(numScore.x > xThing) xThing = numScore.x;
		}
		comboSpr.x = xThing + 50;
		/*
			trace(combo);
			trace(seperatedScore);
		 */

		coolText.text = Std.string(seperatedScore);
		// add(coolText);

		FlxTween.tween(rating, {alpha: 0}, 0.2 / playbackRate, {
			startDelay: Conductor.crochet * 0.001 / playbackRate
		});

		FlxTween.tween(comboSpr, {alpha: 0}, 0.2 / playbackRate, {
			onComplete: function(tween:FlxTween)
			{
				coolText.destroy();
				comboSpr.destroy();

				rating.destroy();
			},
			startDelay: Conductor.crochet * 0.002 / playbackRate
		});
	}

	public var strumsBlocked:Array<Bool> = [];
	private function onKeyPress(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(eventKey);
		//trace('Pressed: ' + eventKey);

		if (!playerStrums.autoplay && startedCountdown && !paused && key > -1 && (FlxG.keys.checkStatus(eventKey, JUST_PRESSED) || ClientPrefs.controllerMode))
		{
			for(character in playerStrums.characters)
			{
				if(character != null && !character.stunned && generatedMusic && !endingSong)
				{
						
					var lastTime:Float = Conductor.songPosition;
					Conductor.songPosition = FlxG.sound.music.time;
		
					var canMiss:Bool = !ClientPrefs.ghostTapping;
		
					// heavily based on my own code LOL if it aint broke dont fix it
					var pressNotes:Array<Note> = [];
					var notesStopped:Bool = false;
		
					var sortedNotesList:Array<Note> = [];
					notes.forEachAlive(function(daNote:Note)
					{
						if (strumsBlocked[daNote.noteData] != true && daNote.canBeHit && daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit && !daNote.isSustainNote && !daNote.blockHit)
						{
							if(daNote.noteData == key)
							{
								sortedNotesList.push(daNote);
							}
							canMiss = true;
						}
					});
					sortedNotesList.sort(sortHitNotes);
		
					if (sortedNotesList.length > 0) {
						for (epicNote in sortedNotesList)
						{
							for (doubleNote in pressNotes) {
								if (Math.abs(doubleNote.strumTime - epicNote.strumTime) < 1) {
									doubleNote.kill();
									notes.remove(doubleNote, true);
									doubleNote.destroy();
								} else
									notesStopped = true;
							}
		
								// eee jack detection before was not super good
							if (!notesStopped) {
								goodNoteHit(epicNote, playerStrums.characters, playerStrums);
								pressNotes.push(epicNote);
							}
		
						}
					}
					else{
						callOnLuas('onGhostTap', [key]);
						callOnHaxes('onGhostTap', [key]);
						if (canMiss) {
							noteMissPress(key, playerStrums.characters);
						}
					}
		
					keysPressed[key] = true;
					Conductor.songPosition = lastTime;
				}
			}


			var spr:StrumNote = playerStrums.members[key];
			if(strumsBlocked[key] != true && spr != null && spr.animation.curAnim.name != 'confirm')
			{
				spr.playAnim('pressed');
				spr.resetAnim = 0;
			}
			
		}


		if (!opponentStrums.autoplay && startedCountdown && !paused && key > -1 && (FlxG.keys.checkStatus(eventKey, JUST_PRESSED) || ClientPrefs.controllerMode))
		{
			for(character in opponentStrums.characters)
			{
				if(character != null && !character.stunned && generatedMusic && !endingSong)
				{
						
					var lastTime:Float = Conductor.songPosition;
					Conductor.songPosition = FlxG.sound.music.time;
		
					var canMiss:Bool = !ClientPrefs.ghostTapping;
		
					// heavily based on my own code LOL if it aint broke dont fix it
					var pressNotes:Array<Note> = [];
					var notesStopped:Bool = false;
		
					var sortedNotesList:Array<Note> = [];
					notes.forEachAlive(function(daNote:Note)
					{
						if (strumsBlocked[daNote.noteData] != true && daNote.canBeHit && !daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit && !daNote.isSustainNote && !daNote.blockHit)
						{
							if(daNote.noteData == key)
							{
								sortedNotesList.push(daNote);
							}
							canMiss = true;
						}
					});
					sortedNotesList.sort(sortHitNotes);
		
					if (sortedNotesList.length > 0) {
						for (epicNote in sortedNotesList)
						{
							for (doubleNote in pressNotes) {
								if (Math.abs(doubleNote.strumTime - epicNote.strumTime) < 1) {
									doubleNote.kill();
									notes.remove(doubleNote, true);
									doubleNote.destroy();
								} else
									notesStopped = true;
							}
		
							// eee jack detection before was not super good
							if (!notesStopped) {
								goodNoteHit(epicNote, opponentStrums.characters, opponentStrums);
								pressNotes.push(epicNote);
							}
		
						}
					}
					else{
						callOnLuas('onGhostTap', [key]);
						callOnHaxes('onGhostTap', [key]);
						if (canMiss) {
							noteMissPress(key, opponentStrums.characters);
						}
					}
		
					keysPressed[key] = true;
					Conductor.songPosition = lastTime;
				}
			}

			var spr:StrumNote = opponentStrums.members[key];
			if(strumsBlocked[key] != true && spr != null && spr.animation.curAnim.name != 'confirm')
			{
				spr.playAnim('pressed');
				spr.resetAnim = 0;
			}
		}
		callOnLuas('onKeyPress', [key]);
		callOnHaxes('onKeyPress', [key]);
	}

	function sortHitNotes(a:Note, b:Note):Int
	{
		if (a.lowPriority && !b.lowPriority)
			return 1;
		else if (!a.lowPriority && b.lowPriority)
			return -1;

		return FlxSort.byValues(FlxSort.ASCENDING, a.strumTime, b.strumTime);
	}

	private function onKeyRelease(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(eventKey);
		if(!playerStrums.autoplay && startedCountdown && !paused && key > -1)
		{
			if (playerStrums.members[key] != null)
			{
				playerStrums.members[key].playAnim('static');
				playerStrums.members[key].resetAnim = 0;
			}
			callOnLuas('onKeyRelease', [key]);
			callOnHaxes('onKeyRelease', [key]);
		}

		if(!opponentStrums.autoplay && startedCountdown && !paused && key > -1)
		{
			if (opponentStrums.members[key] != null)
			{
				opponentStrums.members[key].playAnim('static');
				opponentStrums.members[key].resetAnim = 0;
			}
			callOnLuas('onKeyRelease', [key]);
			callOnHaxes('onKeyRelease', [key]);
		}
		//trace('released: ' + controlArray);
	}

	private function getKeyFromEvent(key:FlxKey):Int
	{
		if(key != NONE)
		{
			for (i in 0...keysArray.length)
			{
				for (j in 0...keysArray[i].length)
				{
					if(key == keysArray[i][j])
					{
						return i;
					}
				}
			}
		}
		return -1;
	}

	/* Hold notes*/
	private function keyShit():Void
	{
		// HOLDING
		var parsedHoldArray:Array<Bool> = parseKeys();

		// TO DO: Find a better way to handle controller inputs, this should work for now
		if(ClientPrefs.controllerMode)
		{
			var parsedArray:Array<Bool> = parseKeys('_P');
			if(parsedArray.contains(true))
			{
				for (i in 0...parsedArray.length)
				{
					if(parsedArray[i] && strumsBlocked[i] != true)
						onKeyPress(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, -1, keysArray[i][0]));
				}
			}
		}

		if (startedCountdown && !boyfriend.stunned && generatedMusic)
		{
			// rewritten inputs???
			notes.forEachAlive(function(daNote:Note)
			{
				// hold note functions
				if (strumsBlocked[daNote.noteData] != true && daNote.isSustainNote && parsedHoldArray[daNote.noteData] && daNote.canBeHit
					&& daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit && !daNote.blockHit) {
					goodNoteHit(daNote, playerStrums.characters, playerStrums);
				}

				if (strumsBlocked[daNote.noteData] != true && daNote.isSustainNote && parsedHoldArray[daNote.noteData] && daNote.canBeHit
					&& !daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit && !daNote.blockHit) {
					goodNoteHit(daNote, opponentStrums.characters, opponentStrums);
				}
			});

			if (parsedHoldArray.contains(true) && !endingSong) {
				#if ACHIEVEMENTS_ALLOWED
				var achieve:String = checkForAchievement(['oversinging']);
				if (achieve != null) {
					startAchievement(achieve);
				}
				#end
			}
			else if (dad.animation.curAnim != null && dad.holdTimer > Conductor.stepCrochet * (0.0011 / FlxG.sound.music.pitch) * dad.singDuration && dad.animation.curAnim.name.startsWith('sing') && !dad.animation.curAnim.name.endsWith('miss'))
			{
				dad.dance();
			}
			else if (boyfriend.animation.curAnim != null && boyfriend.holdTimer > Conductor.stepCrochet * (0.0011 / FlxG.sound.music.pitch) * boyfriend.singDuration && boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.animation.curAnim.name.endsWith('miss'))
			{
				boyfriend.dance();
			}
		}

		// TO DO: Find a better way to handle controller inputs, this should work for now
		if(ClientPrefs.controllerMode || strumsBlocked.contains(true))
		{
			var parsedArray:Array<Bool> = parseKeys('_R');
			if(parsedArray.contains(true))
			{
				for (i in 0...parsedArray.length)
				{
					if(parsedArray[i] || strumsBlocked[i] == true)
						onKeyRelease(new KeyboardEvent(KeyboardEvent.KEY_UP, true, true, -1, keysArray[i][0]));
				}
			}
		}
	}

	private function mainFakeControls(daNote:Note, strumline:StrumLineNote):Void
	{
		if (strumline.autoplay)
		{
			if(!daNote.blockHit && daNote.canBeHit) {
				if(daNote.isSustainNote) {
					if(daNote.canBeHit) {
						fakeGoodNoteHit(daNote, strumline.characters, strumline);
					}
				} else if(daNote.strumTime <= Conductor.songPosition || daNote.isSustainNote) {
					fakeGoodNoteHit(daNote, strumline.characters, strumline);
				}
			}
		}
	}

	private function mainControls(daNote:Note, strumline:StrumLineNote):Void
	{
		if (strumline.autoplay)
		{
			if(!daNote.blockHit && daNote.canBeHit) {
				if(daNote.isSustainNote) {
					if(daNote.canBeHit) {
						goodNoteHit(daNote, strumline.characters, strumline);
					}
				} else if(daNote.strumTime <= Conductor.songPosition || daNote.isSustainNote) {
					goodNoteHit(daNote, strumline.characters, strumline);
				}
			}
		}
		else
		{
			keyShit();
		}
	}

	private function parseKeys(?suffix:String = ''):Array<Bool>
	{
		var ret:Array<Bool> = [];
		for (i in 0...controlArray.length)
		{
			ret[i] = Reflect.getProperty(controls, controlArray[i] + suffix);
		}
		return ret;
	}

	function noteMiss(daNote:Note, character:Array<Character>):Void { //You didn't hit the key and let it go offscreen, also used by Hurt Notes
		//Dupe note remove
		daNote.kill();
		notes.remove(daNote, true);
		daNote.destroy();

		for(char in character)
		{
			if(char == boyfriend)
			{
				if (combo > 5 && gf != null && gf.animOffsets.exists('sad'))
				{
					gf.playAnim('sad');
				}
			}

			if(char != null && !daNote.noMissAnimation && char.hasMissAnimations)
			{
				characterPlayAnimation(daNote, char, 'miss');
			}

			// I'm kinda stupid if character was gf sooo
			if(vocalsBoyfriend != null && char == gf && !playerStrums.autoplay)
			{
				vocalsBoyfriend[1].volume = 0;
			}

			if(vocalsDad != null && char == gf && !opponentStrums.autoplay)
			{
				vocalsDad[1].volume = 0;
			}
		}

		combo = 0;

		health -= daNote.missHealth * healthLoss;
		
		
		if(instakillOnMiss)
		{
			if(vocals != null)
			{
				vocals.volume = 0;
			}
			
			if(vocalsBoyfriend != null && !playerStrums.autoplay)
			{
				for(boyfriend in vocalsBoyfriend)
				{
					boyfriend.volume = 0;
				}
			}
			if(vocalsDad != null && !opponentStrums.autoplay)
			{
				for(dad in vocalsDad)
				{
					dad.volume = 0;
				}
			}
			doDeathCheck(true);
		}

		songMisses++;
		if(vocals != null)
		{
			vocals.volume = 0;
		}
		if(vocalsBoyfriend != null && !playerStrums.autoplay)
		{
			for(boyfriend in vocalsBoyfriend)
			{
				boyfriend.volume = 0;
			}
		}
		if(vocalsDad != null && !opponentStrums.autoplay)
		{
			for(dad in vocalsDad)
			{
				dad.volume = 0;
			}
		}		
		if(!practiceMode) songScore -= 10;

		totalPlayed++;
		RecalculateRating(true);



		callOnLuas('noteMiss', [notes.members.indexOf(daNote), daNote.noteData, daNote.noteType, daNote.isSustainNote]);
		callOnHaxes('noteMiss', [daNote, character]);
	}

	function noteMissPress(direction:Int = 1, character:Array<Character>):Void //You pressed a key when there was no notes to press for this key
	{
		if(ClientPrefs.ghostTapping) return; //fuck it
		for(char in character)
		{
			if (!char.stunned)
			{
				health -= 0.05 * healthLoss;
			}

			if(instakillOnMiss)
			{
				if(vocals != null)
				{
					vocals.volume = 0;
				}
				if(vocalsBoyfriend != null && !playerStrums.autoplay)
				{
					for(boyfriend in vocalsBoyfriend)
					{
						boyfriend.volume = 0;
					}
				}
				if(vocalsDad != null && !opponentStrums.autoplay)
				{
					for(dad in vocalsDad)
					{
						dad.volume = 0;
					}
				}
				doDeathCheck(true);
			}

			if(char == boyfriend)
			{
				if (combo > 5 && gf != null && gf.animOffsets.exists('sad'))
				{
					gf.playAnim('sad');
				}
			}

			if(char == gf)
			{
				if(vocalsBoyfriend != null && char == gf && !playerStrums.autoplay)
				{
					vocalsBoyfriend[1].volume = 0;
				}
		
				if(vocalsDad != null && char == gf && !opponentStrums.autoplay)
				{
					vocalsDad[1].volume = 0;
				}
			}

			combo = 0;
			if(!practiceMode) songScore -= 10;
			if(!endingSong) {
				songMisses++;
				
			}
			totalPlayed++;
			RecalculateRating(true);

			FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));

			if(char.hasMissAnimations) {
				char.playAnim(singAnimations[Std.int(Math.abs(direction))] + 'miss', true);
			}
			if(vocals != null)
			{
				vocals.volume = 0;
			}
			if(vocalsBoyfriend != null && !playerStrums.autoplay)
			{
				for(boyfriend in vocalsBoyfriend)
				{
					boyfriend.volume = 0;
				}
			}
			if(vocalsDad != null && !opponentStrums.autoplay)
			{
				for(dad in vocalsDad)
				{
					dad.volume = 0;
				}
			}
		}
		callOnLuas('noteMissPress', [direction]);
		callOnHaxes('noteMissPress', [direction, character]);
	}

	function fakeGoodNoteHit(note:Note, character:Array<Character>, chararterStrums:StrumLineNote)
	{
		if (!note.wasGoodHit)
		{
			if(note.ignoreNote || note.hitCausesMiss) return;

			if (ClientPrefs.hitsoundVolume > 0 && !note.hitsoundDisabled && note.mustPress)
			{
				FlxG.sound.play(Paths.sound('hitsound'), ClientPrefs.hitsoundVolume);
			}

			for(char in character)
			{
				if(!note.noAnimation) {
					characterPlayAnimation(note, char);
				}
			}

			var time:Float = 0.15;
			if(note.animation.curAnim != null && note.isSustainNote && !note.animation.curAnim.name.endsWith('end')) {
				time += 0.15;
			}

			if (chararterStrums.members[Std.int(Math.abs(note.noteData))] != null)
			{
				chararterStrums.members[Std.int(Math.abs(note.noteData))].playAnim('confirm', true);
				chararterStrums.members[Std.int(Math.abs(note.noteData))].resetAnim = time;
			}

			note.wasGoodHit = true;
			if(vocals != null)
			{
				vocals.volume = 1;
			}

			if(vocalsBoyfriend != null)
			{
				for(boyfriend in vocalsBoyfriend)
				{
					boyfriend.volume = 1;
				}
			}
			if(vocalsDad != null)
			{
				for(dad in vocalsDad)
				{
					dad.volume = 1;
				}
			}

			callOnLuas(note.mustPress ? 'fakeGoodNoteHit' : 'fakeOpponentNoteHit', [notes.members.indexOf(note), Math.abs(note.noteData), note.noteType, note.isSustainNote]);
			callOnHaxes(note.mustPress ? 'fakeGoodNoteHit' : 'fakeOpponentNoteHit', [note, character, chararterStrums]);

			if (!note.isSustainNote)
			{
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}
		}
	}

	function goodNoteHit(note:Note, character:Array<Character>, chararterStrums:StrumLineNote)
	{
		if (!note.wasGoodHit)
		{
			if(chararterStrums.autoplay && (note.ignoreNote || note.hitCausesMiss)) return;

			if (ClientPrefs.hitsoundVolume > 0 && !note.hitsoundDisabled && note.mustPress)
			{
				FlxG.sound.play(Paths.sound('hitsound'), ClientPrefs.hitsoundVolume);
			}

			for(char in character)
			{
				if(note.hitCausesMiss) {
					noteMiss(note, character);
					if(!note.noteSplashDisabled && !note.isSustainNote) {
						spawnNoteSplashOnNote(note, chararterStrums);
					}
	
					if(!note.noMissAnimation)
					{
						switch(note.noteType) {
							case 'Hurt Note': //Hurt note
								if(char.animation.getByName('hurt') != null) {
									char.playAnim('hurt', true);
									char.specialAnim = true;
								}
						}
					}
	
					note.wasGoodHit = true;
					if (!note.isSustainNote)
					{
						note.kill();
						notes.remove(note, true);
						note.destroy();
					}
					return;
				}

				if(!note.noAnimation) {
					characterPlayAnimation(note, char);
				}
			}

			if(note.mustPress)
			{
				if (!opponentControlled && !note.isSustainNote)
				{
					combo += 1;
					if(combo > 9999) combo = 9999;
					popUpScore(note, chararterStrums);
				}
				else if(!note.isSustainNote && !note.noteSplashDisabled)
				{
					spawnNoteSplashOnNote(note, chararterStrums);
				}

				if(!opponentControlled)
				{
					health += note.hitHealth * healthGain;
				}
			}
			else
			{
				if (opponentControlled && !note.isSustainNote)
				{
					combo += 1;
					if(combo > 9999) combo = 9999;
					popUpScore(note, chararterStrums);
				}
				else if(!note.isSustainNote && !note.noteSplashDisabled)
				{
					spawnNoteSplashOnNote(note, chararterStrums);
				}

				if(opponentControlled)
				{
					health += note.hitHealth * healthGain;
				}
			}

			if(chararterStrums.autoplay)
			{
				var time:Float = 0.15;
				if(note.animation.curAnim != null && note.isSustainNote && !note.animation.curAnim.name.endsWith('end')) {
					time += 0.15;
				}
	
				if (chararterStrums.members[Std.int(Math.abs(note.noteData))] != null)
				{
					chararterStrums.members[Std.int(Math.abs(note.noteData))].playAnim('confirm', true);
					chararterStrums.members[Std.int(Math.abs(note.noteData))].resetAnim = time;
				}
			}
			else
			{
				if (chararterStrums.members[note.noteData] != null)
				{
					chararterStrums.members[note.noteData].playAnim('confirm', true);
					chararterStrums.members[note.noteData].resetAnim = 0;
				}
			}
			note.wasGoodHit = true;
			if(vocals != null)
			{
				vocals.volume = 1;
			}
			if(vocalsBoyfriend != null && !playerStrums.autoplay)
			{
				for(boyfriend in vocalsBoyfriend)
				{
					boyfriend.volume = 1;
				}
			}
			if(vocalsDad != null && !opponentStrums.autoplay)
			{
				for(dad in vocalsDad)
				{
					dad.volume = 1;
				}
			}

			callOnLuas(note.mustPress ? 'goodNoteHit' : 'opponentNoteHit', [notes.members.indexOf(note), Math.abs(note.noteData), note.noteType, note.isSustainNote]);
			callOnHaxes(note.mustPress ? 'goodNoteHit' : 'opponentNoteHit', [note, character, chararterStrums]);

			if (!note.isSustainNote)
			{
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}
		}
	}


	function characterPlayAnimation(note:Note, character:Character, ?suffix:String = '')
	{
		var altAnim:String = note.animSuffix;

		if (SONG.notes[curSection] != null)
		{
			if (SONG.notes[curSection].altAnim && !SONG.notes[curSection].gfSection) {
				altAnim = '-alt';
			}
		}

		var animToPlay:String = singAnimations[Std.int(Math.abs(note.noteData))] + altAnim + suffix;
		if(note.gfNote) {
			character = gf;
		}
		
		if(character != null)
		{
			//I hate ugh and Stress Song
			if(character.existsOffsets('singLEFT'  + altAnim + suffix) || 
				character.existsOffsets('singUP'  + altAnim + suffix) ||
			    character.existsOffsets('singDOWN'  + altAnim + suffix) ||
				character.existsOffsets('singRIGHT'  + altAnim + suffix))
			{
				character.playAnim(animToPlay, true);
				character.holdTimer = 0;
			}
			else
			{
				//if Character don't have any type suffix animation
				character.playAnim(singAnimations[Std.int(Math.abs(note.noteData))], true);
				character.holdTimer = 0;
			}

		}

		if(note.noteType == 'Hey!') {
			if(character != null &&  character.existsOffsets('hey')) {
				character.playAnim('hey', true);
				character.specialAnim = true;
				character.heyTimer = 0.6;
			}

			if(character != null && character.existsOffsets('cheer')) {
				character.playAnim('cheer', true);
				character.specialAnim = true;
				character.heyTimer = 0.6;
			}
		}

		callOnLuas('characterPlayAnimation', [Math.abs(note.noteData), note.noteType, note.isSustainNote]);
		callOnHaxes('characterPlayAnimation', [note, character, suffix]);		
	}

	public function spawnNoteSplashOnNote(note:Note, ?strumline:StrumLineNote) {
		if(ClientPrefs.noteSplashes && note != null && strumline != null) {
			var strum:StrumNote = strumline.members[note.noteData];
			if(strum != null) {
				spawnNoteSplash(strum.x, strum.y, note.noteData, note);
			}
		}
	}

	public function spawnNoteSplash(x:Float, y:Float, data:Int, ?note:Note = null) {
		var skin:String = 'noteSplashes';
		if(PlayState.SONG.splashSkin != null && PlayState.SONG.splashSkin.length > 0) skin = PlayState.SONG.splashSkin;

		var hue:Float = 0;
		var sat:Float = 0;
		var brt:Float = 0;
		if (data > -1 && data < ClientPrefs.arrowHSV.length)
		{
			hue = ClientPrefs.arrowHSV[data][0] / 360;
			sat = ClientPrefs.arrowHSV[data][1] / 100;
			brt = ClientPrefs.arrowHSV[data][2] / 100;
			if(note != null) {
				skin = note.noteSplashTexture;
				hue = note.noteSplashHue;
				sat = note.noteSplashSat;
				brt = note.noteSplashBrt;
			}
		}

		var splash:NoteSplash = grpNoteSplashes.recycle(NoteSplash);
		splash.setupNoteSplash(x, y, data, skin, hue, sat, brt);
		grpNoteSplashes.add(splash);
	}

	override function destroy() {
		for (lua in luaArray) {
			lua.call('onDestroy', []);
			lua.stop();
		}
		luaArray = [];

		for (lua in haxeArray) {
			lua.call('destroy', []);
			if(lua != null) lua = null;
		}
		haxeArray = [];

		#if hscript
		if(FunkinLua.hscript != null) FunkinLua.hscript = null;
		#end

		if(!ClientPrefs.controllerMode)
		{
			FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
			FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		}
		FlxAnimationController.globalSpeed = 1;
		FlxG.sound.music.pitch = 1;
		super.destroy();
	}

	public static function cancelMusicFadeTween() {
		if(FlxG.sound.music.fadeTween != null) {
			FlxG.sound.music.fadeTween.cancel();
		}
		FlxG.sound.music.fadeTween = null;
	}

	var lastStepHit:Int = -1;
	override function stepHit()
	{
		super.stepHit();
		if(vocals != null)
		{
			if (Math.abs(FlxG.sound.music.time - (Conductor.songPosition - Conductor.offset)) > (20 * playbackRate)
				|| (SONG.needsVoices && Math.abs(vocals.time - (Conductor.songPosition - Conductor.offset)) > (20 * playbackRate)))
			{
				resyncVocals();
			}
		}


		if(vocalsBoyfriend != null)
		{
			for(boyfriend in vocalsBoyfriend)
			{
				if (Math.abs(FlxG.sound.music.time - (Conductor.songPosition - Conductor.offset)) > (20 * playbackRate)
					|| (SONG.needsVoices && Math.abs(boyfriend.time - (Conductor.songPosition - Conductor.offset)) > (20 * playbackRate)))
				{
					resyncVocals();
				}
			}
		}
		if(vocalsDad != null)
		{
			for(dad in vocalsDad)
			{
				if (Math.abs(FlxG.sound.music.time - (Conductor.songPosition - Conductor.offset)) > (20 * playbackRate)
					|| (SONG.needsVoices && Math.abs(dad.time - (Conductor.songPosition - Conductor.offset)) > (20 * playbackRate)))
				{
					resyncVocals();
				}
			}
		}

		if(curStep == lastStepHit) {
			return;
		}

		stage.stepHit();

		lastStepHit = curStep;
		setOnLuas('curStep', curStep);
		callOnLuas('onStepHit', []);

		setOnHaxes('curStep', curStep);
		callOnHaxes('stepHit', []);
	}

	var lightningStrikeBeat:Int = 0;
	var lightningOffset:Int = 8;

	var lastBeatHit:Int = -1;

	override function beatHit()
	{
		super.beatHit();

		if(lastBeatHit >= curBeat) {
			//trace('BEAT HIT: ' + curBeat + ', LAST HIT: ' + lastBeatHit);
			return;
		}

		iconP1.scale.set(1.2, 1.2);
		iconP2.scale.set(1.2, 1.2);

		iconP1.updateHitbox();
		iconP2.updateHitbox();

		if (gf != null && curBeat % Math.round(gfSpeed * gf.danceEveryNumBeats) == 0 && gf.animation.curAnim != null && !gf.animation.curAnim.name.startsWith("sing") && !gf.stunned)
		{
			gf.dance();
		}
		if (curBeat % boyfriend.danceEveryNumBeats == 0 && boyfriend.animation.curAnim != null && !boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.stunned)
		{
			boyfriend.dance();
		}
		if (curBeat % dad.danceEveryNumBeats == 0 && dad.animation.curAnim != null && !dad.animation.curAnim.name.startsWith('sing') && !dad.stunned)
		{
			dad.dance();
		}

		stage.beatHit();
		lastBeatHit = curBeat;

		setOnLuas('curBeat', curBeat); //DAWGG?????
		callOnLuas('onBeatHit', []);

		setOnHaxes('curBeat', curBeat); //DAWGG?????
		callOnHaxes('beatHit', []);
	}

	override function sectionHit()
	{
		super.sectionHit();

		if (SONG.notes[curSection] != null)
		{
			if (generatedMusic && !endingSong && !isCameraOnForcedPos)
			{
				moveCameraSection();
			}

			if (camZooming && FlxG.camera.zoom < 1.35 && ClientPrefs.camZooms)
			{
				FlxG.camera.zoom += 0.015 * camZoomingMult;
				camHUD.zoom += 0.03 * camZoomingMult;
			}

			if (SONG.notes[curSection].changeBPM)
			{
				Conductor.changeBPM(SONG.notes[curSection].bpm);
				setOnLuas('curBpm', Conductor.bpm);
				setOnLuas('crochet', Conductor.crochet);
				setOnLuas('stepCrochet', Conductor.stepCrochet);

				setOnHaxes('curBpm', Conductor.bpm);
				setOnHaxes('crochet', Conductor.crochet);
				setOnHaxes('stepCrochet', Conductor.stepCrochet);
			}
			setOnLuas('mustHitSection', SONG.notes[curSection].mustHitSection);
			setOnLuas('altAnim', SONG.notes[curSection].altAnim);
			setOnLuas('gfSection', SONG.notes[curSection].gfSection);

			setOnHaxes('mustHitSection', SONG.notes[curSection].mustHitSection);
			setOnHaxes('altAnim', SONG.notes[curSection].altAnim);
			setOnHaxes('gfSection', SONG.notes[curSection].gfSection);
		}
		
		setOnLuas('curSection', curSection);
		callOnLuas('onSectionHit', []);

		setOnHaxes('curSection', curSection);
		callOnHaxes('sectionHit', []);
	}

	public function callOnLuas(event:String, args:Array<Dynamic>, ignoreStops = true, exclusions:Array<String> = null, excludeValues:Array<Dynamic> = null):Dynamic {
		var returnVal = FunkinLua.Function_Continue;
		#if LUA_ALLOWED
		if(exclusions == null) exclusions = [];
		if(excludeValues == null) excludeValues = [];

		for (script in luaArray) {
			if(exclusions.contains(script.scriptName))
				continue;

			var myValue = script.call(event, args);
			if(myValue == FunkinLua.Function_StopLua && !ignoreStops)
				break;
			
			if(myValue != null && myValue != FunkinLua.Function_Continue) {
				returnVal = myValue;
			}
		}
		#end
		return returnVal;
	}

	public function setOnLuas(variable:String, arg:Dynamic) {
		#if LUA_ALLOWED
		for (i in 0...luaArray.length) {
			luaArray[i].set(variable, arg);
		}
		#end
	}


	public function callbackOnLuas(variable:String, arg:Dynamic) {
		#if LUA_ALLOWED
		for (i in 0...luaArray.length) {
			luaArray[i].callback(variable, arg);
		}
		#end
	}

	public function callOnHaxes(key:String, args:Array<Dynamic>)
	{
		for (script in haxeArray) {
			script.call(key, args);
		}
	}



	public function setOnHaxes(variable:String, arg:Dynamic) {
		for (i in 0...haxeArray.length) {
			haxeArray[i].set(variable, arg);
		}
	}

	function callLocalVariables()
	{
		setOnHaxes('openSubState', PlayState.instance.openSubState);
		setOnHaxes('logTrace', function(text:String)
		{
			addTextToDebug(text, FlxColor.WHITE);
		});
		setOnHaxes('songName', Paths.formatToSongPath(SONG.song));

		if (boyfriend != null)
		{
			setOnHaxes('bf', boyfriend);
			setOnHaxes('boyfriend', boyfriend);
		}

		if (dad != null)
		{
			setOnHaxes('dad', dad);
			setOnHaxes('dadOpponent', dad);
			setOnHaxes('opponent', dad);

			setOnHaxes('dadOpponentName', dad.curCharacter);
			setOnHaxes('opponentName', dad.curCharacter);
		}

		if (gf != null)
		{
			setOnHaxes('gf', gf);
			setOnHaxes('girlfriend', gf);
			setOnHaxes('spectator', gf);

			setOnHaxes('girlfriendName', gf.curCharacter);
			setOnHaxes('spectatorName', gf.curCharacter);
		}

		if (playerStrums != null)
		{
			setOnHaxes('bfStrums', playerStrums);
			setOnHaxes('playerStrums', playerStrums);
		}

		if (opponentStrums != null)
		{
			setOnHaxes('dadStrums', opponentStrums);
			setOnHaxes('opponentStrums', opponentStrums);
		}

		if (strumLineNotes != null)
		{
			setOnHaxes('strumLines', strumLineNotes);
			setOnHaxes('strumLineNotes', strumLineNotes);
		}
			

		if (camGame != null)
			setOnHaxes('camGame', camGame);
		if (camHUD != null)
			setOnHaxes('camHUD', camHUD);
		if (camOther != null)
			setOnHaxes('camOther', camOther);

		setOnHaxes('set', function(key:String, value:Dynamic)
		{
			var dotList:Array<String> = key.split('.');

			if (dotList.length > 1)
			{
				var reflector:Dynamic = Reflect.getProperty(this, dotList[0]);

				for (i in 1...dotList.length - 1)
					reflector = Reflect.getProperty(reflector, dotList[i]);

				Reflect.setProperty(reflector, dotList[dotList.length - 1], value);
				return true;
			}

			Reflect.setProperty(instance, key, value);
			return true;
		});

		setOnHaxes('get', function(variable:String)
		{
			var dotList:Array<String> = variable.split('.');

			if (dotList.length > 1)
			{
				var reflector:Dynamic = Reflect.getProperty(instance, dotList[0]);

				for (i in 1...dotList.length - 1)
					reflector = Reflect.getProperty(reflector, dotList[i]);

				return Reflect.getProperty(reflector, dotList[dotList.length - 1]);
			}

			return Reflect.getProperty(instance, variable);
		});

		setOnHaxes('exists', function(variable:String)
		{
			var dotList:Array<String> = variable.split('.');

			if (dotList.length > 1)
			{
				var reflector:Dynamic = Reflect.getProperty(instance, dotList[0]);

				for (i in 1...dotList.length - 1)
					reflector = Reflect.getProperty(reflector, dotList[i]);

				return Reflect.hasField(reflector, dotList[dotList.length - 1]);
			}

			return Reflect.hasField(instance, variable);
		});

		setOnHaxes('copy', function(variable:String)
		{
			var dotList:Array<String> = variable.split('.');

			var reflector:Dynamic = null;

			if (dotList.length > 1)
			{
				reflector = Reflect.getProperty(instance, dotList[0]);

				for (i in 1...dotList.length - 1)
					reflector = Reflect.getProperty(reflector, dotList[i]);

				return Reflect.getProperty(reflector, dotList[dotList.length - 1]);
			}

			return Reflect.copy(reflector);
		});
	}

	public var ratingName:String = '?';
	public var ratingPercent:Float;
	public var ratingFC:String;
	public function RecalculateRating(badHit:Bool = false) {
		setOnLuas('score', songScore);
		setOnLuas('misses', songMisses);
		setOnLuas('hits', songHits);
		setOnHaxes('score', songScore);
		setOnHaxes('misses', songMisses);
		setOnHaxes('hits', songHits);

		var ret:Dynamic = callOnLuas('onRecalculateRating', [], false);
		callOnHaxes('RecalculateRating', []);
		if(ret != FunkinLua.Function_Stop)
		{
			if(totalPlayed < 1) //Prevent divide by 0
				ratingName = '?';
			else
			{
				// Rating Percent
				ratingPercent = Math.min(1, Math.max(0, totalNotesHit / totalPlayed));
				//trace((totalNotesHit / totalPlayed) + ', Total: ' + totalPlayed + ', notes hit: ' + totalNotesHit);

				// Rating Name
				if(ratingPercent >= 1)
				{
					ratingName = ratingStuff[ratingStuff.length-1][0]; //Uses last string
				}
				else
				{
					for (i in 0...ratingStuff.length-1)
					{
						if(ratingPercent < ratingStuff[i][1])
						{
							ratingName = ratingStuff[i][0];
							break;
						}
					}
				}
			}

			// Rating FC
			ratingFC = "";
			if (sicks > 0) ratingFC = "SFC";
			if (goods > 0) ratingFC = "GFC";
			if (bads > 0 || shits > 0) ratingFC = "FC";
			if (songMisses > 0 && songMisses < 10) ratingFC = "SDCB";
			else if (songMisses >= 10) ratingFC = "Clear";
		}
		updateScore(badHit); // score will only update after rating is calculated, if it's a badHit, it shouldn't bounce -Ghost
		setOnLuas('rating', ratingPercent);
		setOnLuas('ratingName', ratingName);
		setOnLuas('ratingFC', ratingFC);

		setOnHaxes('rating', ratingPercent);
		setOnHaxes('ratingName', ratingName);
		setOnHaxes('ratingFC', ratingFC);
	}

	#if ACHIEVEMENTS_ALLOWED
	private function checkForAchievement(achievesToCheck:Array<String> = null):String
	{
		if(chartingMode) return null;

		var usedPractice:Bool = (ClientPrefs.getGameplaySetting('practice', false) || ClientPrefs.getGameplaySetting('botplay', false));
		for (i in 0...achievesToCheck.length) {
			var achievementName:String = achievesToCheck[i];
			if(!Achievements.isAchievementUnlocked(achievementName) && !cpuControlled) {
				var unlock:Bool = false;
				
				if (achievementName.contains(WeekData.getWeekFileName()) && achievementName.endsWith('nomiss')) // any FC achievements, name should be "weekFileName_nomiss", e.g: "weekd_nomiss";
				{
					if(isStoryMode && campaignMisses + songMisses < 1 && CoolUtil.difficultyString() == 'HARD'
						&& storyPlaylist.length <= 1 && !changedDifficulty && !usedPractice)
						unlock = true;
				}
				switch(achievementName)
				{
					case 'ur_bad':
						if(ratingPercent < 0.2 && !practiceMode) {
							unlock = true;
						}
					case 'ur_good':
						if(ratingPercent >= 1 && !usedPractice) {
							unlock = true;
						}
					case 'roadkill_enthusiast':
						if(Achievements.henchmenDeath >= 100) {
							unlock = true;
						}
					case 'oversinging':
						for(charPlayer in playerStrums.characters)
						{
							if(charPlayer != null && charPlayer.holdTimer >= 10)
								unlock = true;
						}
						for(dadPlayer in opponentStrums.characters)
						{
							if(dadPlayer != null && dadPlayer.holdTimer >= 10)
								unlock = true;
						}
					case 'hype':
						if(!boyfriendIdled && !usedPractice) {
							unlock = true;
						}
					case 'two_keys':
						if(!usedPractice) {
							var howManyPresses:Int = 0;
							for (j in 0...keysPressed.length) {
								if(keysPressed[j]) howManyPresses++;
							}

							if(howManyPresses <= 2) {
								unlock = true;
							}
						}
					case 'toastie':
						if(/*ClientPrefs.framerate <= 60 &&*/ !ClientPrefs.shaders && ClientPrefs.lowQuality && !ClientPrefs.globalAntialiasing) {
							unlock = true;
						}
					case 'debugger':
						if(Paths.formatToSongPath(SONG.song) == 'test' && !usedPractice) {
							unlock = true;
						}
				}

				if(unlock) {
					Achievements.unlockAchievement(achievementName);
					return achievementName;
				}
			}
		}
		return null;
	}
	#end

	var curLight:Int = -1;
	var curLightEvent:Int = -1;
}