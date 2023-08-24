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
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
#if (flixel >= "5.3.0")
import flixel.sound.FlxSound;
#else
import flixel.system.FlxSound;
#end
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
import util.Difficulty;
import util.Controls;
import util.script.FunkinHaxe;
import util.script.FunkinLua;
import util.script.Globals.*;
import util.script.Globals;
import util.Mods;
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
#if (HSCRIPT_ALLOWED && SScript >= "3.0.0")
import tea.SScript;
#end

#if VIDEOS_ALLOWED 
#if (hxCodec >= "3.0.0") import hxcodec.flixel.FlxVideo as VideoHandler;
#elseif (hxCodec >= "2.6.1") import hxcodec.VideoHandler as VideoHandler;
#elseif (hxCodec == "2.6.0") import VideoHandler;
#else import vlc.MP4Handler as VideoHandler; #end
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

	public var stageMap:Map<String, Stage> = new Map<String, Stage>();
	public var boyfriendMap:Map<String, Character> = new Map<String, Character>();
	public var dadMap:Map<String, Character> = new Map<String, Character>();
	public var gfMap:Map<String, Character> = new Map<String, Character>();

	//Percache Arrow and Note huh it werid...
	public var boyfriendStrumsMap:Map<String, StrumLineNote> = new Map<String, StrumLineNote>();
	public var dadStrumsMap:Map<String, StrumLineNote> = new Map<String, StrumLineNote>();

	public var boyfriendNoteMap:Map<String, FlxTypedGroup<Note>> = new Map<String, FlxTypedGroup<Note>>();
	public var dadNoteMap:Map<String, FlxTypedGroup<Note>> = new Map<String, FlxTypedGroup<Note>>();

	public var gfStrumsMap:Map<String, StrumLineNote> = new Map<String, StrumLineNote>();
	public var momStrumsMap:Map<String, StrumLineNote> = new Map<String, StrumLineNote>();

	public var gfNoteMap:Map<String, FlxTypedGroup<Note>> = new Map<String, FlxTypedGroup<Note>>();
	public var momNoteMap:Map<String, FlxTypedGroup<Note>> = new Map<String, FlxTypedGroup<Note>>();

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
	public var modchartTexts:Map<String, FlxText> = new Map<String, FlxText>();
	public var modchartSaves:Map<String, FlxSave> = new Map<String, FlxSave>();

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
	public static var stageUI:String = "default";//called them as normal is suck
	public static var isPixelStage(get, never):Bool;

	@:noCompletion
	static function get_isPixelStage():Bool
		return stageUI == "pixel";

	public static var SONG:SwagSong = null;
	public static var isStoryMode:Bool = false;
	public static var isBETADCIU:Bool = false;
	public static var isCover:Bool = false;
	public static var storyWeek:Int = 0;
	public static var storyPlaylist:Array<String> = [];
	public static var storyDifficulty:Int = 1;

	public var spawnTime:Float = 2000;

	public var vocals:FlxSound;
	public var inst:FlxSound;

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
	public var boyfriendSplashSkin:String = null;

	public var dadArrowSkin:String = null;
	public var dadArrowStyle:String = null;
	public var dadSplashSkin:String = null;

	public var gfArrowSkin:String = null;
	public var gfArrowStyle:String = null;
	public var gfSplashSkin:String = null;

	public var momArrowSkin:String = null;
	public var momArrowStyle:String = null;
	public var momSplashSkin:String = null;

	public var boyfriendDisabledRGB:Bool = false;
	public var gfDisabledRGB:Bool = false;
	public var dadDisabledRGB:Bool = false;
	public var momDisabledRGB:Bool = false;

	private var strumLine:FlxSprite;

	//Handles the new epic mega sexy cam code that i've done
	public var camFollow:FlxObject;
	private static var prevCamFollow:FlxObject;

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
	public var fullComboFunction:Void->Void = null;

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
	var keysPressed:Array<Int> = [];
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
	private var keysArray:Array<String>;
	public var precacheList:Map<String, String> = new Map<String, String>();

	// Callbacks for stages
	public var startCallback:Void->Void = null;
	public var endCallback:Void->Void = null;

	override public function create()
	{
		//trace('Playback Rate: ' + playbackRate);
		Paths.clearStoredMemory();

		startCallback = startCountdown;
		endCallback = endSong;

		// for lua
		instance = this;

		debugKeysChart = ClientPrefs.keyBinds.get('debug_1').copy();
		debugKeysCharacter = ClientPrefs.keyBinds.get('debug_2').copy();
		botplayKeys = ClientPrefs.keyBinds.get('botplay').copy();
		PauseSubState.songName = null; //Reset to default
		playbackRate = ClientPrefs.getGameplaySetting('songspeed');
		fullComboFunction = fullComboUpdate;

		keysArray = [
			'note_left',
			'note_down',
			'note_up',
			'note_right'
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
			keysPressed.push(i);//?
		}

		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		// Gameplay settings
		healthGain = ClientPrefs.getGameplaySetting('healthgain');
		healthLoss = ClientPrefs.getGameplaySetting('healthloss');
		instakillOnMiss = ClientPrefs.getGameplaySetting('instakill');
		practiceMode = ClientPrefs.getGameplaySetting('practice');
		cpuControlled = ClientPrefs.getGameplaySetting('botplay');
		opponentControlled = ClientPrefs.getGameplaySetting('opponentplay');
		showcaseMode = ClientPrefs.getGameplaySetting('showcase');

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
		Conductor.bpm = SONG.bpm;

		#if desktop
		storyDifficultyText = Difficulty.getString();

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

		
		luaDebugGroup = new FlxTypedGroup<DebugLuaText>();
		luaDebugGroup.cameras = [camOther];
		add(luaDebugGroup);

		var scriptExts:Array<String> = ['hx', 'hxs', 'hscript', 'hxc'];

		// "GLOBAL" SCRIPTS
		var foldersToCheck:Array<String> = Mods.getFoldersList(Paths.getPreloadPath(), 'scripts/');
		for (folder in foldersToCheck)
		{
			for (file in FileSystem.readDirectory(folder))
			{
				#if LUA_ALLOWED
				if(file.toLowerCase().endsWith('.lua'))
				{
					luaArray.push(new FunkinLua(folder + file));
					for (script in luaArray) {
						script.call('onCreate', []);
						script.call('create', []);
					}
				}
				#end
				#if HSCRIPT_ALLOWED
				for (ext in scriptExts)
				{
					if(file.toLowerCase().endsWith('.$ext'))
					{
						loadHaxe(folder + file);
					}
				}
				#end
			}
		}

		stage = new Stage(curStage);
		stageGroup.add(stage);
		gfLayer.add(stage.layers.get('gf'));
		dadLayer.add(stage.layers.get('dad'));
		boyfriendLayer.add(stage.layers.get('boyfriend'));

		if (!stageData.hide_girlfriend)
		{
			if(SONG.gfVersion == null || SONG.gfVersion.length < 1) SONG.gfVersion = 'gf'; //Fix for the Chart Editor
			gf = new Character(0, 0, SONG.gfVersion);
			startCharacterPos(gf);
			gf.scrollFactor.set(0.95, 0.95);
			gfGroup.add(gf);
			startCharacterScripts(gf.curCharacter);
			startCharacterBETADCIUScripts(gf.curCharacter);
		}

		dad = new Character(0, 0, SONG.player2);
		startCharacterPos(dad, true);
		dadGroup.add(dad);
		startCharacterScripts(dad.curCharacter);
		startCharacterBETADCIUScripts(dad.curCharacter);

		boyfriend = new Character(0, 0, SONG.player1, true);
		startCharacterPos(boyfriend);
		boyfriendGroup.add(boyfriend);
		startCharacterScripts(boyfriend.curCharacter);
		startCharacterBETADCIUScripts(boyfriend.curCharacter);

		var camPos:FlxPoint = FlxPoint.get(girlfriendCameraOffset[0], girlfriendCameraOffset[1]);
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

		stage.createPost();

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

		var splash:NoteSplash = new NoteSplash(100, 100);
		grpNoteSplashes.add(splash);
		splash.alpha = 0.000001;

		generateSong(SONG.song);


		opponentStrums = new StrumLineNote([dad], true);
		opponentStrums.autoplay = !opponentControlled;

		playerStrums = new StrumLineNote([boyfriend], false);
		playerStrums.autoplay = (cpuControlled || opponentControlled);

		opponentFakeStrums = new StrumLineNote([gf], true);
		playerFakeStrums = new StrumLineNote([getLuaCharacter('mom')], true);

		generateStaticArrows(0, dadArrowSkin, dadArrowStyle, dadDisabledRGB);
		generateStaticArrows(1, boyfriendArrowSkin, boyfriendArrowStyle, boyfriendDisabledRGB);
		generateStaticFakeArrows(0, gfArrowSkin, gfArrowStyle, gfDisabledRGB);
		generateStaticFakeArrows(1, momArrowSkin, momArrowStyle, momDisabledRGB);

		// After all characters being loaded, it makes then invisible 0.01s later so that the player won't freeze when you change characters
		// add(strumLine);

		camFollow = new FlxObject(0, 0, 1, 1);
		camFollow.setPosition(camPos.x, camPos.y);
		camPos.put();
		if (prevCamFollow != null)
		{
			camFollow = prevCamFollow;
			prevCamFollow = null;
		}
		add(camFollow);

		FlxG.camera.follow(camFollow, LOCKON, 0);
		// FlxG.camera.setScrollBounds(0, FlxG.width, 0, FlxG.height);
		FlxG.camera.zoom = defaultCamZoom;
		FlxG.camera.snapToTarget();

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
			startScripts('custom_notetypes/' + notetype);
		for (event in eventPushedMap.keys())
			startScripts('custom_events/' + event);


		noteTypeMap.clear();
		noteTypeMap = null;
		eventPushedMap.clear();
		eventPushedMap = null;

		if(eventNotes.length > 1)
		{
			for (event in eventNotes) event.strumTime -= eventNoteEarlyTrigger(event);
			eventNotes.sort(sortByTime);
		}


		var foldersToCheck:Array<String> = Mods.getFoldersList(Paths.getPreloadPath(), 'data/' + songName + '/');
		for (folder in foldersToCheck)
			for (file in FileSystem.readDirectory(folder))
			{
				#if LUA_ALLOWED
				if(file.toLowerCase().endsWith('.lua'))
				{
					luaArray.push(new FunkinLua(folder + file));
					for (script in luaArray) {
						script.call('onCreate', []);
						script.call('create', []);
					}
				}

				#end
				#if HSCRIPT_ALLOWED
				for (ext in scriptExts)
				{
					if(file.toLowerCase().endsWith('.$ext'))
					{
						loadHaxe(folder + file);
					}
				}
				#end
			}

		startCallback();
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

		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
		FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		callOnScripts('onCreatePost');
		callOnScripts('createPost');

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

		if(SONG.splashSkin.length > 1)
		{
			boyfriendSplashSkin = SONG.splashSkin;
			dadSplashSkin = SONG.splashSkin;
			gfSplashSkin = SONG.splashSkin;
			momSplashSkin = SONG.splashSkin;
		}
		else
		{
			boyfriendSplashSkin = boyfriend.splashSkin;
			dadSplashSkin = dad.splashSkin;
			if(gf != null)
				gfSplashSkin = gf.splashSkin;
			else
				gfSplashSkin = dad.splashSkin;
			if(getLuaCharacter('mom') != null)
			{
				momSplashSkin = getLuaCharacter('mom').splashSkin;
			}
			else
			{
				momSplashSkin = boyfriend.splashSkin;
			}
		}

		//0.7 code
		if(SONG.disableNoteRGB)
		{
			boyfriendDisabledRGB = !SONG.disableNoteRGB;
			dadDisabledRGB = !SONG.disableNoteRGB;
			gfDisabledRGB = !SONG.disableNoteRGB;
			momDisabledRGB = !SONG.disableNoteRGB;
		}
		else
		{
			boyfriendDisabledRGB = !boyfriend.disabledRGB;
			dadDisabledRGB = !dad.disabledRGB;
			if(gf != null)
				gfDisabledRGB = !gf.disabledRGB;
			else
				gfDisabledRGB = !dad.disabledRGB;
			if(getLuaCharacter('mom') != null)
			{
				momDisabledRGB = getLuaCharacter('mom').disabledRGB;
			}
			else
			{
				momDisabledRGB = !boyfriend.disabledRGB;
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
		stage.createPost();
	}
	

	function loadStageData(stage:String, ?sawp:Bool = false)
	{
		stageData = StageData.getStageFile(stage);
		if(stageData == null) { //Stage couldn't be found, create a dummy stage for preventing a crash
			stageData = {
				directory: "",
				defaultZoom: 0.9,
				isPixelStage: false,
				stageUI: "default",

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
		if (stageData.stageUI != null && stageData.stageUI.trim().length > 0)
			stageUI = stageData.stageUI;
		else {
			if (stageData.isPixelStage)
				stageUI = "pixel";
			else
				stageUI = "default";
		}
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
		if(Mods.currentModDirectory != null && Mods.currentModDirectory.length > 0)
			foldersToCheck.insert(0, Paths.mods(Mods.currentModDirectory + '/shaders/'));

		for(mod in Mods.getGlobalMods())
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
			if(ratio != 1)
			{
				for (note in notes) note.resizeByRatio(ratio);
				for (note in fakeNotes) note.resizeByRatio(ratio);
				for (note in unspawnNotes) note.resizeByRatio(ratio);
				for (note in unspawnFakeNotes) note.resizeByRatio(ratio);
			}

		}
		songSpeed = value;
		noteKillOffset = Math.max(Conductor.stepCrochet, 350 / songSpeed * playbackRate);
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

			var ratio:Float = value / songSpeed; //funny word huh
			if(ratio != 1)
			{
				for (note in notes) note.resizeByRatio(ratio);
				for (note in fakeNotes) note.resizeByRatio(ratio);
				for (note in unspawnNotes) note.resizeByRatio(ratio);
				for (note in unspawnFakeNotes) note.resizeByRatio(ratio);
			}
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
		var newText:DebugLuaText = luaDebugGroup.recycle(DebugLuaText);
		newText.text = text;
		newText.color = color;
		newText.disableTime = 6;
		newText.alpha = 1;
		newText.setPosition(10, 8 - newText.height);

		luaDebugGroup.forEachAlive(function(spr:DebugLuaText) {
			spr.y += newText.height + 2;
		});
		luaDebugGroup.add(newText);

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

	function addStageToList(value:String)
	{
		if(!stageMap.exists(value)) {
			var newStage:Stage = new Stage(value);
			newStage.createPost();

			stageMap.set(value, newStage);
			stageGroup.add(newStage);
	
			gfLayer.add(newStage.layers.get('gf'));
			dadLayer.add(newStage.layers.get('dad'));
			boyfriendLayer.add(newStage.layers.get('boyfriend'));

			if(newStage.members != null)
			{
				var i:Int = newStage.members.length-1;
				while(i >= 0) {
					var memb:FlxSprite = cast (newStage.members[i], FlxSprite);
					if(memb != null) {
						memb.alpha = 0.00001;
					}
					--i;
				}
			}


			if(newStage.layers.get('boyfriend') != null)
			{
				var i:Int = newStage.layers.get('boyfriend').members.length-1;
				while(i >= 0) {
					var memb:FlxSprite = cast (newStage.layers.get('boyfriend').members[i], FlxSprite);
					if(memb != null) {
						memb.alpha = 0.00001;
					}
					--i;
				}
			}

			if(newStage.layers.get('dad') != null)
			{
				var i:Int = newStage.layers.get('dad').members.length-1;
				while(i >= 0) {
					var memb:FlxSprite = cast (newStage.layers.get('dad').members[i], FlxSprite);
					if(memb != null) {
						memb.alpha = 0.00001;
					}
					--i;
				}
			}

			if(newStage.layers.get('gf') != null)
			{
				var i:Int = newStage.layers.get('gf').members.length-1;
				while(i >= 0) {
					var memb:FlxSprite = cast (newStage.layers.get('gf').members[i], FlxSprite);
					if(memb != null) {
						memb.alpha = 0.00001;
					}
					--i;
				}
			}
		}
	}

	public function addCharacterToList(newCharacter:String, type:Int, ?isPlayer:Bool = false) {
		switch(type) {
			case 0:
				if(!boyfriendMap.exists(newCharacter)) {
					var newBoyfriend:Character = new Character(0, 0, newCharacter, !isPlayer);
					//changeSkin('playerStrums', newBoyfriend);
					boyfriendMap.set(newCharacter, newBoyfriend);
					boyfriendGroup.add(newBoyfriend);
					startCharacterPos(newBoyfriend);
					newBoyfriend.alpha = 0.00001;
					startCharacterScripts(newBoyfriend.curCharacter);
					startCharacterBETADCIUScripts(newBoyfriend.curCharacter);
				}

			case 1:
				if(!dadMap.exists(newCharacter)) {
					var newDad:Character = new Character(0, 0, newCharacter, isPlayer);
					//changeSkin('opponentStrums', newDad);
					dadMap.set(newCharacter, newDad);
					dadGroup.add(newDad);
					startCharacterPos(newDad, true);
					newDad.alpha = 0.00001;
					startCharacterScripts(newDad.curCharacter);
					startCharacterBETADCIUScripts(newDad.curCharacter);
				}

			case 2:
				if(gf != null && !gfMap.exists(newCharacter)) {
					var newGf:Character = new Character(0, 0, newCharacter, isPlayer);
					//changeSkin('opponentFakeStrums', newGf);
					newGf.scrollFactor.set(0.95, 0.95);
					gfMap.set(newCharacter, newGf);
					gfGroup.add(newGf);
					startCharacterPos(newGf);
					newGf.alpha = 0.00001;
					startCharacterScripts(newGf.curCharacter);
					startCharacterBETADCIUScripts(newGf.curCharacter);
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
				startCharacterScripts(newChar.curCharacter);
				startCharacterBETADCIUScripts(newChar.curCharacter);
			}
		}
	}

	public function startScripts(name:String)
	{
		#if LUA_ALLOWED
		var doPush:Bool = false;
		var luaFile:String = name + '.lua';
		#if MODS_ALLOWED
		var replacePath:String = Paths.modFolders(luaFile);
		if(FileSystem.exists(replacePath))
		{
			luaFile = replacePath;
			doPush = true;
		}
		else
		{
			luaFile = Paths.getPreloadPath(luaFile);
			if(FileSystem.exists(luaFile))
				doPush = true;
		}
		#else
		luaFile = Paths.getPreloadPath(luaFile);
		if(Assets.exists(luaFile)) doPush = true;
		#end

		if(doPush)
		{
			for (script in luaArray)
			{
				if(script.scriptName == luaFile)
				{
					doPush = false;
					break;
				}
			}
			if(doPush)
			{
				luaArray.push(new FunkinLua(luaFile));
				for (script in luaArray) {
					script.call('onCreate', []);
					script.call('create', []);
				}
			} 
				
		}
		#end

		var scriptExts:Array<String> = ['hx', 'hxs', 'hscript', 'hxc'];
		#if HSCRIPT_ALLOWED
		for (ext in scriptExts)
		{
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
			
			if(doPush)
			{
				if(SScript.global.exists(scriptFile))
					doPush = false;
	
				if(doPush) loadHaxe(scriptFile);
			}
		}
		#end
	}

	public function startCharacterBETADCIUScripts(name:String)
	{
		#if LUA_ALLOWED
		var doPush:Bool = false;
		var luaFile:String = 'charactersBETADCIU/' + name + '.lua';
		#if MODS_ALLOWED
		var replacePath:String = Paths.modFolders(luaFile);
		if(FileSystem.exists(replacePath))
		{
			luaFile = replacePath;
			doPush = true;
		}
		else
		{
			luaFile = Paths.getPreloadPath(luaFile);
			if(FileSystem.exists(luaFile))
				doPush = true;
		}
		#else
		luaFile = Paths.getPreloadPath(luaFile);
		if(Assets.exists(luaFile)) doPush = true;
		#end

		if(doPush)
		{
			for (script in luaArray)
			{
				if(script.scriptName == luaFile)
				{
					doPush = false;
					break;
				}
			}
			if(doPush)
			{
				luaArray.push(new FunkinLua(luaFile));
				for (script in luaArray) {
					script.call('onCreate', []);
					script.call('create', []);
				}
			} 
				
		}
		#end

		var scriptExts:Array<String> = ['hx', 'hxs', 'hscript', 'hxc'];
		#if HSCRIPT_ALLOWED
		for (ext in scriptExts)
		{
			var doPush:Bool = false;
			var scriptFile:String = 'charactersBETADCIU/' + name + '.$ext';
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
			
			if(doPush)
			{
				if(SScript.global.exists(scriptFile))
					doPush = false;
	
				if(doPush) loadHaxe(scriptFile);
			}
		}
		#end
	}

	public function startCharacterScripts(name:String)
	{
		#if LUA_ALLOWED
		var doPush:Bool = false;
		var luaFile:String = 'characters/' + name + '.lua';
		#if MODS_ALLOWED
		var replacePath:String = Paths.modFolders(luaFile);
		if(FileSystem.exists(replacePath))
		{
			luaFile = replacePath;
			doPush = true;
		}
		else
		{
			luaFile = Paths.getPreloadPath(luaFile);
			if(FileSystem.exists(luaFile))
				doPush = true;
		}
		#else
		luaFile = Paths.getPreloadPath(luaFile);
		if(Assets.exists(luaFile)) doPush = true;
		#end

		if(doPush)
		{
			for (script in luaArray)
			{
				if(script.scriptName == luaFile)
				{
					doPush = false;
					break;
				}
			}
			if(doPush)
			{
				luaArray.push(new FunkinLua(luaFile));
				for (script in luaArray) {
					script.call('onCreate', []);
					script.call('create', []);
				}
			} 
				
		}
		#end

		var scriptExts:Array<String> = ['hx', 'hxs', 'hscript', 'hxc'];
		#if HSCRIPT_ALLOWED
		for (ext in scriptExts)
		{
			var doPush:Bool = false;
			var scriptFile:String = 'characters/' + name + '.$ext';
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
			
			if(doPush)
			{
				if(SScript.global.exists(scriptFile))
					doPush = false;
	
				if(doPush) loadHaxe(scriptFile);
			}
		}
		#end
	}

	public var skipArrowStartTween:Bool = false; //for lua
	public var keyAmonut:Int = 4;
	private function generateStaticArrows(player:Int, arrowSkin:String, arrowStyle:String, arrowRGBDisabled:Bool):Void
	{
		var strumLineX:Float = ClientPrefs.middleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X;
		var strumLineY:Float = ClientPrefs.downScroll ? (FlxG.height - 150) : 50;

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
			
			var babyArrow:StrumNote = new StrumNote(strumLineX, strumLineY, i, playerSwap);
			babyArrow.texture = arrowSkin;
			babyArrow.style = arrowStyle;
			babyArrow.useRGBShader = arrowRGBDisabled;
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

	private function generateStaticFakeArrows(player:Int, arrowSkin:String, arrowStyle:String, arrowRGBDisabled:Bool):Void
	{
		var strumLineX:Float = ClientPrefs.middleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X;
		var strumLineY:Float = ClientPrefs.downScroll ? (FlxG.height - 150) : 50;

		for (i in 0...keyAmonut)
		{
			var targetAlpha:Float = 0;
			var babyArrow:StrumNote = new StrumNote(strumLineX, strumLineY, i, player);
			babyArrow.texture = arrowSkin;
			babyArrow.style = arrowStyle;
			if(arrowRGBDisabled == true)
				babyArrow.useRGBShader = false;
			else if(arrowRGBDisabled == false)
				babyArrow.useRGBShader = true;
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


	public function getLuaObject(tag:String, text:Bool=true):FlxSprite {
		//if(modchartGroupTypes.exists(tag)) return modchartGroupTypes.get(tag);
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

		var video:VideoHandler = new VideoHandler();
		#if (hxCodec >= "3.0.0")
		// Recent versions
		video.play(filepath);
		video.onEndReached.add(function()
		{
			startAndEnd();
			return;
		}, true);
		#else
		// Older versions
		video.playVideo(filepath);
		video.finishCallback = function()
		{
			startAndEnd();
			return;
		}
		#end

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
		var introImagesArray:Array<String> = switch(stageUI) {
			case "pixel": ['${stageUI}UI/ready-pixel', '${stageUI}UI/set-pixel', '${stageUI}UI/date-pixel'];
			case "default"|"normal": ["ready", "set" ,"go"];
			default: ['${stageUI}UI/ready', '${stageUI}UI/set', '${stageUI}UI/go'];
		}
		introAssets.set(stageUI, introImagesArray);

		var introAlts:Array<String> = introAssets.get(stageUI);
		for (asset in introAlts) Paths.image(asset);
		
		Paths.sound('intro3' + introSoundsSuffix);
		Paths.sound('intro2' + introSoundsSuffix);
		Paths.sound('intro1' + introSoundsSuffix);
		Paths.sound('introGo' + introSoundsSuffix);
	}

	public function startCountdown()
	{
		if(startedCountdown) {
			callOnScripts('onStartCountdown');
			return false;
		}
		
		seenCutscene = true;
		inCutscene = false;
		var ret:Dynamic = callOnScripts('onStartCountdown', null, true);
		if(ret != FunkinLua.Function_Stop) {
			if (skipCountdown || startOnTime > 0) skipArrowStartTween = true;

			for (i in 0...playerStrums.length) {
				setOnScripts('defaultPlayerStrumX' + i, playerStrums.members[i].x);
				setOnScripts('defaultPlayerStrumY' + i, playerStrums.members[i].y);
			}
			for (i in 0...opponentStrums.length) {
				setOnScripts('defaultOpponentStrumX' + i, opponentStrums.members[i].x);
				setOnScripts('defaultOpponentStrumY' + i, opponentStrums.members[i].y);
			}

			startedCountdown = true;
			Conductor.songPosition = -Conductor.crochet * 5;
			setOnScripts('startedCountdown', true);
			callOnScripts('onCountdownStarted', null);
			callOnScripts('countdownStarted', null);
			
			var swagCounter:Int = 0;

			if(startOnTime < 0) startOnTime = 0;

			if (startOnTime > 0) {
				clearNotesBefore(startOnTime);
				setSongTime(startOnTime - 350);
				return true;
			}
			else if (skipCountdown)
			{
				setSongTime(0);
				return true;
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
				var introImagesArray:Array<String> = switch(stageUI) {
					case "pixel": ['${stageUI}UI/ready-pixel', '${stageUI}UI/set-pixel', '${stageUI}UI/date-pixel'];
					case "normal"|"default": ["ready", "set" ,"go"];
					default: ['${stageUI}UI/ready', '${stageUI}UI/set', '${stageUI}UI/go'];
				}
				introAssets.set(stageUI, introImagesArray);

				var introAlts:Array<String> = introAssets.get(stageUI);
				var antialias:Bool = (ClientPrefs.globalAntialiasing && !isPixelStage);
				
				stage.countdownTick(swagCounter);

				switch (swagCounter)
				{
					case 0:
						FlxG.sound.play(Paths.sound(introSoundsSuffix + 'intro3'), 0.6);
					case 1:
						makeCountdownSprite(countdownReady, 'ready', antialias, introAlts[0]);
					case 2:
						makeCountdownSprite(countdownSet, 'set', antialias, introAlts[2]);
					case 3:
						makeCountdownSprite(countdownGo, 'go', antialias, introAlts[1]);
					case 4:
				}
				callOnScripts('onCountdownTick', [swagCounter]);
				callOnScripts('countdownTick', [swagCounter]);
				swagCounter += 1;
			}, 5);
		}
		return true;
	}

	public function makeCountdownSprite(countdown:FlxSprite, name:String, ?antialiasing:Bool = false, ?image:String = 'ready')
	{
		var idkFlieName:String = '2';
		var currentImage:Int = 2;
		switch(name)
		{
			case 'ready':
				idkFlieName = '2';
				currentImage = 0;
			case 'set':
				idkFlieName = '1';
				currentImage = 1;
			case 'go':
				idkFlieName = 'Go';
				currentImage = 2;	

		}
		var soundName:String = 'intro' + idkFlieName;
		countdown = new FlxSprite().loadGraphic(Paths.image(image));
		countdown.cameras = [camHUD];
		countdown.scrollFactor.set();

		if (PlayState.isPixelStage)
			countdown.setGraphicSize(Std.int(countdown.width * daPixelZoom));

		countdown.updateHitbox();

		countdown.screenCenter();
		countdown.antialiasing = antialiasing;
		insert(members.indexOf(notes), countdown);
		FlxTween.tween(countdown, {alpha: 0}, Conductor.crochet / 1000, {
			ease: FlxEase.cubeInOut,
			onComplete: function(twn:FlxTween)
			{
				remove(countdown);
				countdown.destroy();
			}
		});
		FlxG.sound.play(Paths.sound(introSoundsSuffix + soundName), 0.6);
	}

	public function addBehindGF(obj:FlxBasic)
	{
		insert(members.indexOf(gfGroup), obj);
	}
	public function addBehindBF(obj:FlxBasic)
	{
		insert(members.indexOf(boyfriendGroup), obj);
	}
	public function addBehindDad (obj:FlxBasic)
	{
		insert(members.indexOf(dadGroup), obj);
	}

	public function addBehind (objThing:FlxBasic, obj:FlxBasic)
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
		var str:String = ratingName;
		if(totalPlayed != 0)
		{
			var percent:Float = Highscore.floorDecimal(ratingPercent * 100, 2);
			str += ' ($percent%) - $ratingFC';
		}

		scoreTxt.text = 'Score: ' + songScore
		+ ' | Misses: ' + songMisses
		+ ' | Rating: ' + str;

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
		callOnScripts('onUpdateScore', [miss]);
		callOnScripts('updateScore', [miss]);
	}

	public function setSongTime(time:Float)
	{
		if(time < 0) time = 0;

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

		FlxG.sound.music.time = time;
		FlxG.sound.music.pitch = playbackRate;
		FlxG.sound.music.play();


		if(vocals != null)
		{
			if (Conductor.songPosition <= vocals.length)
			{
				vocals.time = time;
				vocals.pitch = playbackRate;
			}

			vocals.play();
		}
		

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
	}

	public function startNextDialogue() {
		dialogueCount++;
		callOnScripts('onNextDialogue', [dialogueCount]);
	}

	public function skipDialogue() {
		callOnScripts('onSkipDialogue', [dialogueCount]);
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

		@:privateAccess
		FlxG.sound.playMusic(inst._sound, 1, false);
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
		setOnScripts('songLength', songLength);
		callOnScripts('onSongStart');
		callOnScripts('songStart');
	}

	var debugNum:Int = 0;
	private var noteTypeMap:Map<String, Bool> = new Map<String, Bool>();
	private var eventPushedMap:Map<String, Bool> = new Map<String, Bool>();
	private function generateSong(dataPath:String):Void
	{
		// FlxG.log.add(ChartParser.parse());
		songSpeedType = ClientPrefs.getGameplaySetting('scrolltype');

		switch(songSpeedType)
		{
			case "multiplicative":
				songSpeed = SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed');
			case "constant":
				songSpeed = ClientPrefs.getGameplaySetting('scrollspeed');
		}
		//noteKillOffset = Math.max(Conductor.stepCrochet, 350 / songSpeed);

		var songData = SONG;
		Conductor.bpm = songData.bpm;

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
			
			//EXTRA
			var songKeyExtraDad:String = '${Paths.formatToSongPath(curSong)}/' + Difficulty.getString() + '/Voices' + songData.player2.toUpperCase();
			var songKeyExtraBF:String = '${Paths.formatToSongPath(curSong)}/' + Difficulty.getString() + '/Voices' + songData.player1.toUpperCase();
			var songKeyExtraGF:String = '${Paths.formatToSongPath(curSong)}/' + Difficulty.getString() + '/Voices' + songData.gfVersion.toUpperCase();

			var songKeyExtraDadNormal:String = '${Paths.formatToSongPath(curSong)}/' + Difficulty.getString() + '/VoicesDAD';
			var songKeyExtraBFNormal:String = '${Paths.formatToSongPath(curSong)}/' + Difficulty.getString() + '/VoicesBF';
			var songKeyExtraGFNormal:String = '${Paths.formatToSongPath(curSong)}/' + Difficulty.getString() + '/VoicesGF';
			var songKeyExtraMOMNormal:String = '${Paths.formatToSongPath(curSong)}/' + Difficulty.getString() + '/VoicesMOM';
			var songKeyExtraNormal:String = '${Paths.formatToSongPath(curSong)}/Voices' + Difficulty.getString();


			if(Paths.fileExists(songKeyExtraDad + '.' + Paths.SOUND_EXT, SOUND, false, 'songs') && Paths.fileExists(songKeyExtraBF + '.' + Paths.SOUND_EXT, SOUND, false, 'songs'))
			{
				var customGF:FlxSound = null;
				if(Paths.fileExists(songKeyExtraGF + '.' + Paths.SOUND_EXT, SOUND, false, 'songs'))
					customGF = new FlxSound().loadEmbedded(Paths.returnSound('songs', songKeyExtraGF)); 
				else
					customGF = new FlxSound();

				var customMOM:FlxSound = null;
				if(Paths.fileExists(songKeyExtraMOMNormal + '.' + Paths.SOUND_EXT, SOUND, false, 'songs'))
					customMOM = new FlxSound().loadEmbedded(Paths.returnSound('songs', songKeyExtraMOMNormal)); 
				else
					customMOM = new FlxSound();

				vocalsDad.push(new FlxSound().loadEmbedded(Paths.returnSound('songs', songKeyExtraDad)));
				vocalsBoyfriend.push(new FlxSound().loadEmbedded(Paths.returnSound('songs', songKeyExtraBF)));
	
				vocalsDad.push(customGF);
				vocalsBoyfriend.push(customGF);

				vocalsDad.push(customMOM);
				vocalsBoyfriend.push(customMOM);
			}
			else if(Paths.fileExists(songKeyDad + '.' + Paths.SOUND_EXT, SOUND, false, 'songs') && Paths.fileExists(songKeyBF + '.' + Paths.SOUND_EXT, SOUND, false, 'songs'))
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
			else if(Paths.fileExists(songKeyExtraDadNormal + '.' + Paths.SOUND_EXT, SOUND, false, 'songs') && Paths.fileExists(songKeyExtraBFNormal + '.' + Paths.SOUND_EXT, SOUND, false, 'songs'))
			{
				var customGF:FlxSound = null;
				if(Paths.fileExists(songKeyExtraGFNormal + '.' + Paths.SOUND_EXT, SOUND, false, 'songs'))
					customGF = new FlxSound().loadEmbedded(Paths.returnSound('songs', songKeyExtraGFNormal)); 
				else
					customGF = new FlxSound();

				var customMOM:FlxSound = null;
				if(Paths.fileExists(songKeyExtraMOMNormal + '.' + Paths.SOUND_EXT, SOUND, false, 'songs'))
					customMOM = new FlxSound().loadEmbedded(Paths.returnSound('songs', songKeyExtraMOMNormal)); 
				else
					customMOM = new FlxSound();

				vocalsDad.push(new FlxSound().loadEmbedded(Paths.returnSound('songs', songKeyExtraDadNormal)));
				vocalsBoyfriend.push(new FlxSound().loadEmbedded(Paths.returnSound('songs', songKeyExtraBFNormal)));
	
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
			else if(Paths.fileExists(songKeyExtraNormal + '.' + Paths.SOUND_EXT, SOUND, false, 'songs'))
			{
				vocals = new FlxSound().loadEmbedded(Paths.returnSound('songs', songKeyExtraNormal));
			}
			else
			{
				vocals = new FlxSound().loadEmbedded(Paths.voices(songData.song));
			}
		}
		else
		{
			vocals = new FlxSound();
		}

		//The String Sort of broken tho
		if(Paths.fileExists('${Paths.formatToSongPath(curSong)}/Inst' + Difficulty.getString() + '.' + Paths.SOUND_EXT, SOUND, false, 'songs')) //WOW Inst Difficulty
			inst = new FlxSound().loadEmbedded(Paths.returnSound('songs', '${Paths.formatToSongPath(curSong)}/Inst' + Difficulty.getString()));
		else
			inst = new FlxSound().loadEmbedded(Paths.inst(songData.song));
		

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

		FlxG.sound.list.add(inst);
		

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
				for (i in 0...event[1].length)
					makeEvent(event, i);
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
						if(swagNote.rgbShader != null)
						{
							swagNote.rgbShader.enabled = momDisabledRGB;
						}
						
					}
					else
					{
						swagNote.texture = gfArrowSkin;
						swagNote.style = gfArrowSkin;
						if(swagNote.rgbShader != null)
						{
							swagNote.rgbShader.enabled = gfDisabledRGB;
						}
						
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
	
							var sustainNote:Note = new Note(daStrumTime + (Conductor.stepCrochet * susNote), daNoteData, oldNote, true);
							if(gottaHitNote)
							{
								sustainNote.texture = momArrowSkin;
								sustainNote.style = momArrowStyle;
								if(swagNote.rgbShader != null)
								{
									sustainNote.rgbShader.enabled = momDisabledRGB;
								}
								
							}
							else
							{
								sustainNote.texture = gfArrowSkin;
								sustainNote.style = gfArrowSkin;
								if(swagNote.rgbShader != null)
								{
									sustainNote.rgbShader.enabled = gfDisabledRGB;
								}
								
							}
							sustainNote.alpha = 0.45;
							sustainNote.mustPress = gottaHitNote;
							sustainNote.gfNote = (section.gfSection && (songNotes[1]<4));
							sustainNote.noteType = swagNote.noteType;
							sustainNote.scrollFactor.set();
							swagNote.tail.push(sustainNote);
							sustainNote.parent = swagNote;
							unspawnFakeNotes.push(sustainNote);
							sustainNote.correctionOffset = swagNote.height / 2;
							switch(sustainNote.style)
							{
								default:
									sustainNote.correctionOffset = swagNote.height / 2;
									if(oldNote.isSustainNote)
									{
										sustainNote.scale.y *= Note.SUSTAIN_SIZE / oldNote.frameHeight ;
										
									}
				
									if(ClientPrefs.downScroll)
										sustainNote.correctionOffset = 0;
								case 'pixel':
									sustainNote.scale.y *=  1.19 * 6;

							}
							sustainNote.scale.y /= playbackRate;
							sustainNote.updateHitbox();
							

							if(ClientPrefs.downScroll)
								sustainNote.correctionOffset = 0;
							
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
					for (i in 0...event[1].length)
						makeEvent(event, i);
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
					if(swagNote.rgbShader != null)
					{
						swagNote.rgbShader.enabled = boyfriendDisabledRGB;
					}
					
				}
				else
				{
					swagNote.texture = dadArrowSkin;
					swagNote.style = dadArrowStyle;
					if(swagNote.rgbShader != null)
					{
						swagNote.rgbShader.enabled = dadDisabledRGB;
					}
					
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

						var sustainNote:Note = new Note(daStrumTime + (Conductor.stepCrochet * susNote), daNoteData, oldNote, true);
						sustainNote.mustPress = gottaHitNote;
						if(gottaHitNote)
						{
							sustainNote.texture = boyfriendArrowSkin;
							sustainNote.style = boyfriendArrowStyle;
							if(sustainNote.rgbShader != null)
							{
								sustainNote.rgbShader.enabled = boyfriendDisabledRGB;
							}
							
						}
						else
						{
							sustainNote.texture = dadArrowSkin;
							sustainNote.style = dadArrowStyle;
							if(sustainNote.rgbShader != null)
							{
								sustainNote.rgbShader.enabled = dadDisabledRGB;
							}
							
						}
						sustainNote.gfNote = (section.gfSection && (songNotes[1]<4));
						sustainNote.noteType = swagNote.noteType;
						sustainNote.scrollFactor.set();
						swagNote.tail.push(sustainNote);
						sustainNote.parent = swagNote;
						unspawnNotes.push(sustainNote);
						switch(sustainNote.style)
						{
							default:
								sustainNote.correctionOffset = swagNote.height / 2;
								if(oldNote.isSustainNote)
								{
									sustainNote.scale.y *= Note.SUSTAIN_SIZE / oldNote.frameHeight ;
								}
			
								if(ClientPrefs.downScroll)
									sustainNote.correctionOffset = 0;
						    case 'pixel':
								sustainNote.scale.y *=  1.19 * 6;
						}
						sustainNote.scale.y /= playbackRate;
						sustainNote.updateHitbox();
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
			for (i in 0...event[1].length)
				makeEvent(event, i);
		// trace(unspawnNotes.length);
		// playerCounter += 1;

		unspawnNotes.sort(sortByTime);
		generatedMusic = true;
		
	}


	function makeEvent(event:Array<Dynamic>, i:Int)
	{
		var subEvent:EventNote = {
			strumTime: event[0] + ClientPrefs.noteOffset,
			event: event[1][i][0],
			value1: event[1][i][1],
			value2: event[1][i][2]
		};
		eventNotes.push(subEvent);
		eventPushed(subEvent);
		stage.eventPushed(subEvent);
		callOnScripts('onEventPushed', [subEvent.event, subEvent.value1 != null ? subEvent.value1 : '', subEvent.value2 != null ? subEvent.value2 : '', subEvent.strumTime]);
		callOnScripts('eventPushed', [subEvent.event, subEvent.value1 != null ? subEvent.value1 : '', subEvent.value2 != null ? subEvent.value2 : '', subEvent.strumTime]);
	}

	//Don't use these thing it won't work because FlxBasic is hard


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
						addCharacterLuaToList(event.value2, event.value1, event.value1.endsWith('flip'));
					default:
						addCharacterToList(newCharacter, charType, event.value1.endsWith('flip'));
				}
			case 'Change Stage':
				//addStageToList(event.value1);

			case 'Play Sound':
				precacheList.set(event.value1, 'sound');
				Paths.sound(event.value1);
	
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
		
	}

	function eventNoteEarlyTrigger(event:EventNote):Float {
		var returnedValue:Null<Float> = callOnScripts('eventEarlyTrigger', [event.event, event.value1, event.value2, event.strumTime], true, [], [0]);
		if(returnedValue != null && returnedValue != 0 && returnedValue != FunkinLua.Function_Continue) {
			return returnedValue;
		}

		switch(event.event) {
			case 'Kill Henchmen': //Better timing so that the kill sound matches the beat intended
				return 280; //Plays 280ms before the actual position
		}
		return 0;
	}

	public static function sortByTime(Obj1:Dynamic, Obj2:Dynamic):Int
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
			stage.openSubState();
			callOnScripts('openSubState');
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

			stage.closeSubState();
			paused = false;
			callOnScripts('onResume');
			callOnScripts('resume');
			callOnScripts('closeSubState');

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
		setOnScripts('onUpdate', [elapsed]);
		setOnScripts('update', [elapsed]);
		stage.update(elapsed);

		FlxG.camera.followLerp = 0;

		if(!inCutscene && !paused) {
			FlxG.camera.followLerp = CoolUtil.boundTo(elapsed * 2.4 * cameraSpeed * playbackRate, 0, 1);
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

		setOnScripts('curDecStep', curDecStep);
		setOnScripts('curDecBeat', curDecBeat);

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
			var ret:Dynamic = callOnScripts('onPause', null, true);
			if(ret != FunkinLua.Function_Stop) {
				openPauseMenu();
			}

		}

		if (controls.justPressed('debug_1') && !endingSong && !inCutscene)
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

		if (controls.justPressed('debug_2') && !endingSong && !inCutscene) {
			persistentUpdate = false;
			paused = true;
			cancelMusicFadeTween();
			MusicBeatState.switchState(new CharacterEditorState(SONG.player2));
		}
		
		if (startedCountdown && !paused)
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
		else if (!paused && updateTime)
		{
			var curTime:Float = Math.max(0, Conductor.songPosition - ClientPrefs.noteOffset);
			songPercent = (curTime / songLength);

			var songCalc:Float = (songLength - curTime);
			if(ClientPrefs.timeBarType == 'Time Elapsed') songCalc = curTime;

			var secondsTotal:Int = Math.floor(songCalc / 1000);
			if(secondsTotal < 0) secondsTotal = 0;

			if(ClientPrefs.timeBarType != 'Song Name')
				timeTxt.text = FlxStringUtil.formatTime(secondsTotal, false);
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
			var time:Float = spawnTime * playbackRate;
			if(songSpeed < 1) time /= songSpeed;
			if(unspawnNotes[0].multSpeed < 1) time /= unspawnNotes[0].multSpeed;

			while (unspawnNotes.length > 0 && unspawnNotes[0].strumTime - Conductor.songPosition < time)
			{
				var dunceNote:Note = unspawnNotes[0];
				notes.insert(0, dunceNote);
				dunceNote.spawned=true;
				callOnLuas('onSpawnNote', [notes.members.indexOf(dunceNote), dunceNote.noteData, dunceNote.noteType, dunceNote.isSustainNote, dunceNote.strumTime]);
				callOnHaxes('spawnNote', [dunceNote]);
				var index:Int = unspawnNotes.indexOf(dunceNote);
				unspawnNotes.splice(index, 1);
			}
		}

		if (unspawnFakeNotes[0] != null)
		{
			var time:Float = spawnTime * playbackRate;
			if(songSpeed < 1) time /= songSpeed;
			if(unspawnFakeNotes[0].multSpeed < 1) time /= unspawnFakeNotes[0].multSpeed;

			while (unspawnFakeNotes.length > 0 && unspawnFakeNotes[0].strumTime - Conductor.songPosition < time)
			{
				var dunceNote:Note = unspawnFakeNotes[0];
				fakeNotes.insert(0, dunceNote);
				dunceNote.spawned=true;
				callOnLuas('onSpawnFakeNote', [fakeNotes.members.indexOf(dunceNote), dunceNote.noteData, dunceNote.noteType, dunceNote.isSustainNote, dunceNote.strumTime]);
				callOnHaxes('spawnFakeNote', [dunceNote]);
				var index:Int = unspawnFakeNotes.indexOf(dunceNote);
				unspawnFakeNotes.splice(index, 1);
			}
		}

		if (generatedMusic)
		{
			if(!inCutscene)
			{
				if(!playerStrums.autoplay) {
					keysCheck();
				}
				else if(boyfriend.animation.curAnim != null && boyfriend.holdTimer > Conductor.stepCrochet * (0.0011 / FlxG.sound.music.pitch) * boyfriend.singDuration && boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.animation.curAnim.name.endsWith('miss')) {
					boyfriend.dance();
				}
	
				if(!opponentStrums.autoplay) {
					keysCheck();
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

		setOnScripts('cameraX', camFollow.x);
		setOnScripts('cameraY', camFollow.y);
		setOnScripts('botPlay', [opponentControlled ? opponentStrums.autoplay : playerStrums.autoplay]);
		callOnScripts('onUpdatePost', [elapsed]);
		callOnScripts('updatePost', [elapsed]);
	}

	function notefakeCall()
	{
		if(fakeNotes.length > 0)
		{
			if(startedCountdown)
			{
				var fakeCrochet:Float = (60 / SONG.bpm) * 1000;
				fakeNotes.forEachAlive(function(daNote:Note)
				{
					var strumGroup:StrumLineNote = playerFakeStrums;
					if(!daNote.mustPress) strumGroup = opponentFakeStrums;

					var strum:StrumNote = strumGroup.members[daNote.noteData];
					daNote.followStrumNote(strum, fakeCrochet, songSpeed / playbackRate);

					mainControls(daNote, strumGroup);

					if(daNote.isSustainNote && strum.sustainReduce) daNote.clipToStrumNote(strum);

					if (Conductor.songPosition - daNote.strumTime > noteKillOffset)
					{
						daNote.active = false;
						daNote.visible = false;
		
						daNote.kill();
						notes.remove(daNote, true);
						daNote.destroy();
					}
				});
			}
		}
		
	}

	function noteCall()
	{
		if(notes.length > 0)
		{
			if(startedCountdown)
			{
				var fakeCrochet:Float = (60 / SONG.bpm) * 1000;
				notes.forEachAlive(function(daNote:Note)
				{
					var strumGroup:StrumLineNote = playerStrums;
					if(!daNote.mustPress) strumGroup = opponentStrums;

					var strum:StrumNote = strumGroup.members[daNote.noteData];
					daNote.followStrumNote(strum, fakeCrochet, songSpeed / playbackRate);

					mainControls(daNote, strumGroup);

					if(daNote.isSustainNote && strum.sustainReduce) daNote.clipToStrumNote(strum);

					if (Conductor.songPosition - daNote.strumTime > noteKillOffset)
					{
						if (strumGroup.autoplay &&!daNote.ignoreNote && !endingSong && (daNote.tooLate || !daNote.wasGoodHit)) {
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
		}
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
		DiscordClient.resetClientID();
		#end
	}

	public var isDead:Bool = false; //Don't mess with this on Lua!!!
	function doDeathCheck(?skipHealthCheck:Bool = false) {
		if (((skipHealthCheck && instakillOnMiss) || health <= 0) && !practiceMode && !isDead && !opponentControlled)
		{
			var ret:Dynamic = callOnScripts('onGameOver', null, true);
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
				openSubState(new GameOverSubstate(boyfriend.getScreenPosition().x - boyfriend.playerPositionArray[0], boyfriend.getScreenPosition().y - boyfriend.playerPositionArray[1], boyfriend.isPlayer, camFollow.x, camFollow.y));
					
				
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
			var ret:Dynamic = callOnScripts('onGameOver', null, true);
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
				openSubState(new GameOverSubstate(dad.getScreenPosition().x - dad.positionArray[0], dad.getScreenPosition().y - dad.positionArray[1], dad.isPlayer, camFollow.x, camFollow.y));
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

			triggerEventNote(eventNotes[0].event, value1, value2, leStrumTime);
			eventNotes.shift();
		}
	}

	public function triggerEventNote(eventName:String, value1:String, value2:String, strumTime:Float) {
		var flValue1:Null<Float> = Std.parseFloat(value1);
		var flValue2:Null<Float> = Std.parseFloat(value2);
		if(Math.isNaN(flValue1)) flValue1 = null;
		if(Math.isNaN(flValue2)) flValue2 = null;
		
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
						isCameraOnForcedPos = false;
						if(flValue1 != null || flValue2 != null)
						{
							isCameraOnForcedPos = true;
							if(flValue1 == null) flValue1 = 0;
							if(flValue2 == null) flValue2 = 0;
							camFollow.x = flValue1;
							camFollow.y = flValue2;
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

						charType = Std.parseInt(value1);
						if(Math.isNaN(charType)) charType = 0;
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
						if(mom != null && mom.curCharacter != value2) {
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
						if(luaCharacter != null && luaCharacter.curCharacter != value2) {
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

				var newValue:Float = SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed') * val1;

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
			    try
				{
					var split:Array<String> = value1.split('.');
					if(split.length > 1) {
						setVarInArray(getPropertyLoop(split), split[split.length-1], value2);
					} else {
						setVarInArray(this, value1, value2);
					}
				}
				catch(e:Dynamic)
				{
					addTextToDebug('ERROR ("Set Property" Event) - ' + e.message.substr(0, e.message.indexOf('\n')), FlxColor.RED);
				}
			case 'Change Stage':
				//ok so why this thing is scrapped well it cause lot of crash to convert FlxBasic to FlxSprite and it pain tho..
				/*
				if(stage.curStage != value1)
				{
					if(!stageMap.exists(value1))
						addStageToList(value1);

					if(stage.members != null)
					{
						var i:Int = stage.members.length-1;
						while(i >= 0) {
							var memb:FlxSprite = cast (stage.members[i], FlxSprite);
							if(memb != null) {
	
								var lastAlpha:Float = memb.alpha;
								memb.alpha = 0.00001;
								
								memb = cast (stageMap.get(value1).members[i], FlxSprite);
								memb.alpha = lastAlpha;
							}
							--i;
						}
					}


					if(stage.layers.get('boyfriend') != null)
					{
						var i:Int = stage.layers.get('boyfriend').members.length-1;
						while(i >= 0) {
							var memb:FlxSprite = cast (stage.layers.get('boyfriend').members[i], FlxSprite);
							if(memb != null) {
								var lastAlpha:Float = memb.alpha;
								memb.alpha = 0.00001;
								memb = cast (stageMap.get(value1).layers.get('boyfriend').members[i], FlxSprite);
								memb.alpha = lastAlpha;
							}
							--i;
						}
					}

					if(stage.layers.get('dad') != null)
					{
						var i:Int = stage.layers.get('dad').members.length-1;
						while(i >= 0) {
							var memb:FlxSprite = cast (stage.layers.get('dad').members[i], FlxSprite);
							if(memb != null) {
								var lastAlpha:Float = memb.alpha;
								memb.alpha = 0.00001;
								memb = cast (stageMap.get(value1).layers.get('dad').members[i], FlxSprite);
								memb.alpha = lastAlpha;
							}
							--i;
						}
					}

					if(stage.layers.get('gf') != null)
					{
						var i:Int = stage.layers.get('gf').members.length-1;
						while(i >= 0) {
							var memb:FlxSprite = cast (stage.layers.get('gf').members[i], FlxSprite);
							if(memb != null) {
								var lastAlpha:Float = memb.alpha;
								memb.alpha = 0.00001;
								memb = cast (stageMap.get(value1).layers.get('gf').members[i], FlxSprite);
								memb.alpha = lastAlpha;
							}
							--i;
						}
					}

					var swapp:Bool = false;
					switch(value2)
					{
						case 'true':
							swapp = true;
						default:
							swapp = false;
					}
					loadStageData(value1, swapp);
				}
				*/

				if(stage.curStage != value1) {
					
					var swapp:Bool = false;
					switch(value2)
					{
						case 'true':
							swapp = true;
						default:
							swapp = false;
					}
					createStage(value1, swapp);
				}
			
				
			case 'Play Sound':
				if(flValue2 == null) flValue2 = 1;
				FlxG.sound.play(Paths.sound(value1), flValue2);

		}
		stage.triggerEventStage(eventName, [value1, value2], strumTime);
		callOnScripts('onEvent', [eventName, value1, value2, strumTime]);
		callOnScripts('event', [eventName, value1, value2, strumTime]);
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
						if(daNote.rgbShader != null) daNote.rgbShader.enabled = !character.disabledRGB;
					}

					if(daNote.mustPress)
					{
						if(daNote.isSustainNote)
						{
							switch(character.arrowStyle)
							{
								case 'pixel':
									daNote.scale.y = daNote.scale.y * 1.19 * 6;
								default:
									daNote.scale.y = 1;
									if(!daNote.animation.curAnim.name.endsWith('end'))
									{
										daNote.scale.y *= Conductor.stepCrochet / 100 * 1.05;
										daNote.scale.y *= songSpeed;
									}
							}

							daNote.scale.y /= playbackRate;
							daNote.updateHitbox();
						}
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
						if(daNote.rgbShader != null) daNote.rgbShader.enabled = !character.disabledRGB;
					}

					if(daNote.mustPress)
					{
						if(daNote.isSustainNote)
						{
							switch(character.arrowStyle)
							{
								case 'pixel':
									daNote.scale.y = daNote.scale.y * 1.19 * 6;
								default:
									daNote.scale.y = 1;
									if(!daNote.animation.curAnim.name.endsWith('end'))
									{
										daNote.scale.y *= Conductor.stepCrochet / 100 * 1.05;
										daNote.scale.y *= songSpeed;
									}
							}

							daNote.scale.y /= playbackRate;
							daNote.updateHitbox();
						}
					}
				}
				for (i in 0...playerStrums.members.length)
				{
					var strums:StrumNote = playerStrums.members[i];
					if(SONG.arrowStyle.length < 1 && SONG.arrowSkin.length < 1)
					{
						strums.texture = character.arrowSkin;
						strums.style = character.arrowStyle;
						if(strums.rgbShader != null) strums.rgbShader.enabled = !character.disabledRGB;
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
						daNote.noteSplashTexture = character.splashSkin;
						if(daNote.rgbShader != null) daNote.rgbShader.enabled = !character.disabledRGB;
					}

					if(!daNote.mustPress)
					{
						if(daNote.isSustainNote)
						{
							switch(character.arrowStyle)
							{
								case 'pixel':
									daNote.scale.y = daNote.scale.y * 1.19 * 6;
								default:
									daNote.scale.y = 1;
									if(!daNote.animation.curAnim.name.endsWith('end'))
									{
										daNote.scale.y *= Conductor.stepCrochet / 100 * 1.05;
										daNote.scale.y *= songSpeed;
									}
							}

							daNote.scale.y /= playbackRate;
							daNote.updateHitbox();
						}
					}
				}
				for (i in 0...notes.members.length)
				{
					var daNote:Note = notes.members[i];
					if(!daNote.mustPress && (daNote.noteType == '' || daNote.noteType == 'Alt Animation' || daNote.noteType == 'No Animation' || daNote.noteType == 'GF Sing') && SONG.arrowStyle.length < 1 && SONG.arrowSkin.length < 1) //Prevent avoid the notetype stuff
					{
						daNote.texture = character.arrowSkin;
						daNote.style = character.arrowStyle;
						daNote.noteSplashTexture = character.splashSkin;
						if(daNote.rgbShader != null) daNote.rgbShader.enabled = !character.disabledRGB;
					}

					if(!daNote.mustPress)
					{
						if(daNote.isSustainNote)
						{
							switch(character.arrowStyle)
							{
								case 'pixel':
									daNote.scale.y = daNote.scale.y * 1.19 * 6;
								default:
									daNote.scale.y = 1;
									if(!daNote.animation.curAnim.name.endsWith('end'))
									{
										daNote.scale.y *= Conductor.stepCrochet / 100 * 1.05;
										daNote.scale.y *= songSpeed;
									}
							}

							daNote.scale.y /= playbackRate;
							daNote.updateHitbox();
						}
					}
				}
				for (i in 0...opponentStrums.members.length)
				{
					var strums:StrumNote = opponentStrums.members[i];
					if(SONG.arrowStyle.length < 1 && SONG.arrowSkin.length < 1)
					{
						strums.texture = character.arrowSkin;
						strums.style = character.arrowStyle;
						if(strums.rgbShader != null) strums.rgbShader.enabled = !character.disabledRGB;
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
						daNote.noteSplashTexture = character.splashSkin;
						if(daNote.rgbShader != null) daNote.rgbShader.enabled = !character.disabledRGB;
					}

					
					if(!daNote.mustPress)
					{
						if(daNote.isSustainNote)
						{
							switch(character.arrowStyle)
							{
								case 'pixel':
									daNote.scale.y = daNote.scale.y * 1.19 * 6;
								default:
									daNote.scale.y = 1;
									if(!daNote.animation.curAnim.name.endsWith('end'))
									{
										daNote.scale.y *= Conductor.stepCrochet / 100 * 1.05;
										daNote.scale.y *= songSpeed;
									}
							}

							daNote.scale.y /= playbackRate;
							daNote.updateHitbox();
						}
					}
				}
				for (i in 0...fakeNotes.members.length)
				{
					var daNote:Note = fakeNotes.members[i];
					if(!daNote.mustPress && (daNote.noteType == '' || daNote.noteType == 'Alt Animation' || daNote.noteType == 'No Animation' || daNote.noteType == 'GF Sing') && SONG.arrowStyle.length < 1 && SONG.arrowSkin.length < 1) //Prevent avoid the notetype stuff
					{
						daNote.texture = character.arrowSkin;
						daNote.style = character.arrowStyle;
						daNote.noteSplashTexture = character.splashSkin;
						if(daNote.rgbShader != null) daNote.rgbShader.enabled = !character.disabledRGB;
					}

					
					if(!daNote.mustPress)
					{
						if(daNote.isSustainNote)
						{
							switch(character.arrowStyle)
							{
								case 'pixel':
									daNote.scale.y = daNote.scale.y * 1.19 * 6;
								default:
									daNote.scale.y = 1;
									if(!daNote.animation.curAnim.name.endsWith('end'))
									{
										daNote.scale.y *= Conductor.stepCrochet / 100 * 1.05;
										daNote.scale.y *= songSpeed;
									}
							}

							daNote.scale.y /= playbackRate;
							daNote.updateHitbox();
						}
					}
				}
				for (i in 0...opponentFakeStrums.members.length)
				{
					var strums:StrumNote = opponentFakeStrums.members[i];
					strums.texture = character.arrowSkin;
					strums.style = character.arrowStyle;
					if(strums.rgbShader != null) strums.rgbShader.enabled = !character.disabledRGB;
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
						daNote.noteSplashTexture = character.splashSkin;
						if(daNote.rgbShader != null) daNote.rgbShader.enabled = !character.disabledRGB;
					}

					if(daNote.mustPress)
					{
						if(daNote.isSustainNote)
						{
							switch(character.arrowStyle)
							{
								case 'pixel':
									daNote.scale.y = daNote.scale.y * 1.19 * 6;
								default:
									daNote.scale.y = 1;
									if(!daNote.animation.curAnim.name.endsWith('end'))
									{
										daNote.scale.y *= Conductor.stepCrochet / 100 * 1.05;
										daNote.scale.y *= songSpeed;
									}
							}

							daNote.scale.y /= playbackRate;
							daNote.updateHitbox();
						}
					}
				}
				for (i in 0...fakeNotes.members.length)
				{
					var daNote:Note = fakeNotes.members[i];
					if(!daNote.mustPress && (daNote.noteType == '' || daNote.noteType == 'Alt Animation' || daNote.noteType == 'No Animation' || daNote.noteType == 'GF Sing') && SONG.arrowStyle.length < 1 && SONG.arrowSkin.length < 1) //Prevent avoid the notetype stuff
					{
						daNote.texture = character.arrowSkin;
						daNote.style = character.arrowStyle;
						daNote.noteSplashTexture = character.splashSkin;
						if(daNote.rgbShader != null) daNote.rgbShader.enabled = !character.disabledRGB;
					}

					if(daNote.mustPress)
					{
						if(daNote.isSustainNote)
						{
							switch(character.arrowStyle)
							{
								case 'pixel':
									daNote.scale.y = daNote.scale.y * 1.19 * 6;
								default:
									daNote.scale.y = 1;
									if(!daNote.animation.curAnim.name.endsWith('end'))
									{
										daNote.scale.y *= Conductor.stepCrochet / 100 * 1.05;
										daNote.scale.y *= songSpeed;
									}
							}

							daNote.scale.y /= playbackRate;
							daNote.updateHitbox();
						}
					}
				}
				for (i in 0...playerFakeStrums.members.length)
				{
					var strums:StrumNote = playerFakeStrums.members[i];
					if(SONG.arrowStyle.length < 1 && SONG.arrowSkin.length < 1)
					{
						strums.texture = character.arrowSkin;
						strums.style = character.arrowStyle;
						if(strums.rgbShader != null) strums.rgbShader.enabled = !character.disabledRGB;
					}
				}
		}
	}

	function moveCameraSection(?sec:Null<Int>):Void {
		if(sec == null) sec = curSection;
		if(sec < 0) sec = 0;

		if(SONG.notes[sec] == null) return;
		
		if (gf != null && SONG.notes[curSection].gfSection)
		{
			camFollow.setPosition(gf.getMidpoint().x, gf.getMidpoint().y);
			camFollow.x += gf.cameraPosition[0] + girlfriendCameraOffset[0];
			camFollow.y += gf.cameraPosition[1] + girlfriendCameraOffset[1];
			tweenCamIn();
			callOnScripts('onMoveCamera', ['gf']);
			callOnScripts('moveCamera', ['gf']);
			return;
		}

		var isDad:Bool = (SONG.notes[sec].mustHitSection != true);
		moveCamera(isDad);
		callOnScripts('onMoveCamera', [isDad ? 'dad' : 'boyfriend']);
		callOnScripts('moveCamera', [isDad ? 'dad' : 'boyfriend']);
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
						camFollow.setPosition(character.getMidpoint().x + 150, character.getMidpoint().y - 100);
						camFollow.x += character.playerCameraPosition[0] + opponentCameraOffset[0];
						camFollow.y += character.playerCameraPosition[1] + opponentCameraOffset[1];
					}
					else
					{
						camFollow.setPosition(character.getMidpoint().x + 150, character.getMidpoint().y - 100);
						camFollow.x += character.cameraPosition[0] + opponentCameraOffset[0];
						camFollow.y += character.cameraPosition[1] + opponentCameraOffset[1];
					}
				}

			}
			else
			{
				if(dad.isPlayer)
				{
					camFollow.setPosition(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);
					camFollow.x += dad.playerCameraPosition[0] + opponentCameraOffset[0];
					camFollow.y += dad.playerCameraPosition[1] + opponentCameraOffset[1];
				}
				else
				{
					camFollow.setPosition(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);
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
						camFollow.setPosition(character.getMidpoint().x - 100, character.getMidpoint().y - 100);
						camFollow.x -= character.playerCameraPosition[0] - boyfriendCameraOffset[0];
						camFollow.y += character.playerCameraPosition[1] + boyfriendCameraOffset[1];
					}
					else
					{
						camFollow.setPosition(character.getMidpoint().x - 100, character.getMidpoint().y - 100);
						camFollow.x -= character.cameraPosition[0] - boyfriendCameraOffset[0];
						camFollow.y += character.cameraPosition[1] + boyfriendCameraOffset[1];
					}
				}

			}
			else
			{
				if(boyfriend.isPlayer)
				{
					camFollow.setPosition(boyfriend.getMidpoint().x - 100, boyfriend.getMidpoint().y - 100);
					camFollow.x -= boyfriend.playerCameraPosition[0] - boyfriendCameraOffset[0];
					camFollow.y += boyfriend.playerCameraPosition[1] + boyfriendCameraOffset[1];
				}
				else
				{
					camFollow.setPosition(boyfriend.getMidpoint().x - 100, boyfriend.getMidpoint().y - 100);
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

	public function finishSong(?ignoreNoteOffset:Bool = false):Void
	{
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
			endCallback();
		} else {
			finishTimer = new FlxTimer().start(ClientPrefs.noteOffset / 1000, function(tmr:FlxTimer) {
				endCallback();
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

		var ret:Dynamic = callOnScripts('onEndSong', null, true);
		if(ret != FunkinLua.Function_Stop && !transitioning) {
			#if !switch
			var percent:Float = ratingPercent;
			if(Math.isNaN(percent)) percent = 0;
			Highscore.saveScore(SONG.song, songScore, storyDifficulty, percent);
			#end

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
					Mods.loadTheFirstEnabledMod();
					FlxG.sound.playMusic(Paths.music('freakyMenu'));
					#if desktop DiscordClient.resetClientID(); #end
					
					cancelMusicFadeTween();
					if(FlxTransitionableState.skipNextTransIn) {
						CustomFadeTransition.nextCamera = null;
					}
					MusicBeatState.switchState(new StoryMenuState());

					// if ()
					if(!ClientPrefs.getGameplaySetting('practice') && !ClientPrefs.getGameplaySetting('botplay')) { 
						StoryMenuState.weekCompleted.set(WeekData.weeksList[storyWeek], true);

						Highscore.saveWeekScore(WeekData.getWeekFileName(), campaignScore, storyDifficulty);

						FlxG.save.data.weekCompleted = StoryMenuState.weekCompleted;
						FlxG.save.flush();
					}
					changedDifficulty = false;
				}
				else
				{
					var difficulty:String = Difficulty.getFilePath();

					trace('LOADING NEXT SONG');
					trace(Paths.formatToSongPath(PlayState.storyPlaylist[0]) + difficulty);

					FlxTransitionableState.skipNextTransIn = true;
					FlxTransitionableState.skipNextTransOut = true;

					prevCamFollow = camFollow;
					PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0] + difficulty, PlayState.storyPlaylist[0]);
					FlxG.sound.music.stop();

					cancelMusicFadeTween();
					LoadingState.loadAndSwitchState(new PlayState());
				}
			}
			else if(isBETADCIU)
			{
				trace('WENT BACK TO BETADCIU??');
				Mods.loadTheFirstEnabledMod();
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
				Mods.loadTheFirstEnabledMod();
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
				Mods.loadTheFirstEnabledMod();
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

	// stores the last judgement object
	var lastRating:FlxSprite;
	// stores the last combo sprite object
	var lastCombo:FlxSprite;
	// stores the last combo score objects in an array
	var lastScore:Array<FlxSprite> = [];

	private function cachePopUpScore()
	{
		var uiPrefix:String = '';
		var uiSuffix:String = '';

		switch(stageUI)
		{
			case 'normal'|'default':
				uiPrefix = '';
				uiSuffix = '';
			default:
				uiPrefix = '${stageUI}UI/';
				if (isPixelStage) uiSuffix = '-pixel';
		}

		Paths.image("judegetment/" + uiPrefix + "sick-fc" + uiSuffix);
		for (rating in ratingsData)
			Paths.image("judegetment/" + uiPrefix + rating.image + uiSuffix);
		Paths.image("combo/" + uiPrefix + "combo" + uiSuffix);
		for (i in 0...10) {
			Paths.image("combo/" + uiPrefix + 'num' + i + uiSuffix);
			Paths.image("combo/" + uiPrefix + 'FC/' + 'num' + i + uiSuffix);
		}
	}

	private function popUpScore(note:Note = null, strumline:StrumLineNote = null):Void
	{
		var noteDiff:Float = Math.abs(note.strumTime - Conductor.songPosition + ClientPrefs.ratingOffset);
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
		

		var placement:Float = FlxG.width * 0.35;
		
		var rating:FlxSprite = new FlxSprite();
		var score:Int = 350;

		//tryna do MS based judgment due to popular demand
		var daRating:Rating = Conductor.judgeNote(ratingsData, noteDiff / playbackRate);

		totalNotesHit += daRating.ratingMod;
		note.ratingMod = daRating.ratingMod;
		if(!note.ratingDisabled) daRating.hits++;
		note.rating = daRating.name;
		score = daRating.score;

		if(daRating.noteSplash && !note.noteSplashDisabled)
			spawnNoteSplashOnNote(note, strumline);

		if(!practiceMode) {
			songScore += score;
			if(!note.ratingDisabled)
			{
				songHits++;
				totalPlayed++;
				RecalculateRating(false);
			}
		}

		var uiPrefix:String = "";
		var uiSuffix:String = '';

		switch(stageUI)
		{
			case 'normal'|'default':
				uiPrefix = '';
				uiSuffix = '';
			default:
				uiPrefix = '${stageUI}UI/';
				if (isPixelStage) uiSuffix = '-pixel';
		}

		switch(ratingFC)
		{
			default:
				rating.loadGraphic(Paths.image('judegetment/' + uiPrefix + daRating.image + uiSuffix));
			case 'SFC':
				rating.loadGraphic(Paths.image('judegetment/' + uiPrefix + 'sick-fc' + uiSuffix));
		}

		rating.cameras = [camHUD];
		rating.screenCenter();
		rating.x = placement - 40;
		rating.y -= 60;
		rating.acceleration.y = 550 * playbackRate * playbackRate;
		rating.velocity.y -= FlxG.random.int(140, 175) * playbackRate;
		rating.velocity.x -= FlxG.random.int(0, 10) * playbackRate;
		rating.visible = (!ClientPrefs.hideHud && showRating);
		rating.x += ClientPrefs.comboOffset[0];
		rating.y -= ClientPrefs.comboOffset[1];

		var comboSpr:FlxSprite = new FlxSprite();
		comboSpr.loadGraphic(Paths.image('combo/' + uiPrefix + 'combo' + uiSuffix));
		comboSpr.cameras = [camHUD];
		comboSpr.screenCenter();
		comboSpr.x = placement;
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
					numScore.loadGraphic(Paths.image('combo/' + uiPrefix + 'num' + Std.int(i) + uiSuffix));
				case 'SFC':
					numScore.loadGraphic(Paths.image('combo/' + uiPrefix + 'FC/'  + 'num' + Std.int(i) + uiSuffix));
			}
			numScore.cameras = [camHUD];
			numScore.screenCenter();
			numScore.x = placement + (43 * daLoop) - 90;
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
		FlxTween.tween(rating, {alpha: 0}, 0.2 / playbackRate, {
			startDelay: Conductor.crochet * 0.001 / playbackRate
		});

		FlxTween.tween(comboSpr, {alpha: 0}, 0.2 / playbackRate, {
			onComplete: function(tween:FlxTween)
			{
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
		var key:Int = getKeyFromEvent(keysArray, eventKey);
		//trace('Pressed: ' + eventKey);

		if (!controls.controllerMode && FlxG.keys.checkStatus(eventKey, JUST_PRESSED)) keyPressed(key);
		callOnScripts('onKeyPress', [key]);
	}

	private function keyPressed(key:Int)
	{
		var lastTime:Float = Conductor.songPosition;
		if (startedCountdown && !paused && key > -1)
		{
			if (!playerStrums.autoplay)
			{
				for(character in playerStrums.characters)
				{
					if(notes.length > 0 && !character.stunned && generatedMusic && !endingSong)
					{
						
						Conductor.songPosition = FlxG.sound.music.time;
		
						var canMiss:Bool = !ClientPrefs.ghostTapping;

						var pressNotes:Array<Note> = [];
						var notesStopped:Bool = false;
				        var sortedNotesList:Array<Note> = [];

						notes.forEachAlive(function(daNote:Note)
						{
							if (strumsBlocked[daNote.noteData] != true && daNote.canBeHit && daNote.mustPress &&
								!daNote.tooLate && !daNote.wasGoodHit && !daNote.isSustainNote && !daNote.blockHit)
							{
								if(daNote.noteData == key) sortedNotesList.push(daNote);
								canMiss = true;
							}
						});
						sortedNotesList.sort(sortHitNotes);

						if (sortedNotesList.length > 0) 
						{
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

								if (!notesStopped) {
									goodNoteHit(epicNote, playerStrums.characters, playerStrums);
									pressNotes.push(epicNote);
								}
							}
						}
						else
						{
							callOnLuas('onGhostTap', [key]);
							callOnHaxes('onGhostTap', [key]);
							if (canMiss && !character.stunned) noteMissPress(key, playerStrums.characters);
						}
					}


				}

				var spr:StrumNote = playerStrums.members[key];
				if(strumsBlocked[key] != true && spr != null && spr.animation.curAnim.name != 'confirm')
				{
					spr.playAnim('pressed');
					spr.resetAnim = 0;
				}
			}

			if (!opponentStrums.autoplay)
			{
				for(character in opponentStrums.characters)
				{
					if(notes.length > 0 && !character.stunned && generatedMusic && !endingSong)
					{
						var lastTime:Float = Conductor.songPosition;
						Conductor.songPosition = FlxG.sound.music.time;
		
						var canMiss:Bool = !ClientPrefs.ghostTapping;

						var pressNotes:Array<Note> = [];
						var notesStopped:Bool = false;
				        var sortedNotesList:Array<Note> = [];

						notes.forEachAlive(function(daNote:Note)
						{
							if (strumsBlocked[daNote.noteData] != true && daNote.canBeHit && !daNote.mustPress &&
								!daNote.tooLate && !daNote.wasGoodHit && !daNote.isSustainNote && !daNote.blockHit)
							{
								if(daNote.noteData == key) sortedNotesList.push(daNote);
								canMiss = true;
							}
						});
						sortedNotesList.sort(sortHitNotes);

						if (sortedNotesList.length > 0) 
						{
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

								if (!notesStopped) {
									goodNoteHit(epicNote, opponentStrums.characters, opponentStrums);
									pressNotes.push(epicNote);
								}
							}
						}
						else
						{
							callOnLuas('onGhostTap', [key]);
							callOnHaxes('onGhostTap', [key]);
							if (canMiss && !character.stunned) noteMissPress(key, opponentStrums.characters);
						}
					}
				}
				
				
				var spr:StrumNote = opponentStrums.members[key];
				if(strumsBlocked[key] != true && spr != null && spr.animation.curAnim.name != 'confirm')
				{
					spr.playAnim('pressed');
					spr.resetAnim = 0;
				}				
			}

			Conductor.songPosition = lastTime;
			if(!keysPressed.contains(key)) keysPressed.push(key);
		}
	}

	public static function sortHitNotes(a:Note, b:Note):Int
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
		var key:Int = getKeyFromEvent(keysArray, eventKey);
		//trace('Pressed: ' + eventKey);

		if(!controls.controllerMode && key > -1) keyReleased(key);
		callOnScripts('onKeyRelease', [key]);
	}

	private function keyReleased(key:Int)
	{
		if(startedCountdown && !paused)
		{
			if(!playerStrums.autoplay)
			{
				var spr:StrumNote = playerStrums.members[key];
				if(spr != null)
				{
					spr.playAnim('static');
					spr.resetAnim = 0;
				}
			}

			if(!opponentStrums.autoplay)
			{
				var spr:StrumNote = opponentStrums.members[key];
				if(spr != null)
				{
					spr.playAnim('static');
					spr.resetAnim = 0;
				}
			}
		}
	}

	public static function getKeyFromEvent(arr:Array<String>, key:FlxKey):Int
	{
		if(key != NONE)
		{
			for (i in 0...arr.length)
			{
				var note:Array<FlxKey> = Controls.instance.keyboardBinds[arr[i]];
				for (noteKey in note)
					if(key == noteKey)
						return i;
			}
		}
		return -1;
	}

	/* Hold notes*/
	private function keysCheck():Void
	{
		// HOLDING
		var holdArray:Array<Bool> = [];
		var pressArray:Array<Bool> = [];
		var releaseArray:Array<Bool> = [];
		for (key in keysArray)
		{
			holdArray.push(controls.pressed(key));
			pressArray.push(controls.justPressed(key));
			releaseArray.push(controls.justReleased(key));
		}

		// TO DO: Find a better way to handle controller inputs, this should work for now
		if(controls.controllerMode && pressArray.contains(true))
			for (i in 0...pressArray.length)
				if(pressArray[i] && strumsBlocked[i] != true)
					keyPressed(i);

		if (startedCountdown && generatedMusic)
		{
			// rewritten inputs???
			if(notes.length > 0)
			{
				notes.forEachAlive(function(daNote:Note)
				{
					// hold note functions
					if (strumsBlocked[daNote.noteData] != true && daNote.isSustainNote && holdArray[daNote.noteData] 
						&& daNote.canBeHit && daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit && !daNote.blockHit) {
						goodNoteHit(daNote, playerStrums.characters, playerStrums);
					}

					if (strumsBlocked[daNote.noteData] != true && daNote.isSustainNote && holdArray[daNote.noteData] 
						&& daNote.canBeHit && !daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit && !daNote.blockHit) {
						goodNoteHit(daNote, opponentStrums.characters, opponentStrums);
					}
				});
			}
			for(character in playerStrums.characters)
			{
				if (holdArray.contains(true) && !endingSong) {
					#if ACHIEVEMENTS_ALLOWED
					var achieve:String = checkForAchievement(['oversinging']);
					if (achieve != null) {
						startAchievement(achieve);
					}
					#end
				}
				else if (character.animation.curAnim != null && character.holdTimer > Conductor.stepCrochet * (0.0011 / FlxG.sound.music.pitch) * character.singDuration && character.animation.curAnim.name.startsWith('sing') && !character.animation.curAnim.name.endsWith('miss'))
				{
					character.dance();
				}
			}

			for(character in opponentStrums.characters)
			{
				if (holdArray.contains(true) && !endingSong) {
					#if ACHIEVEMENTS_ALLOWED
					var achieve:String = checkForAchievement(['oversinging']);
					if (achieve != null) {
						startAchievement(achieve);
					}
					#end
				}
				else if (character.animation.curAnim != null && character.holdTimer > Conductor.stepCrochet * (0.0011 / FlxG.sound.music.pitch) * character.singDuration && character.animation.curAnim.name.startsWith('sing') && !character.animation.curAnim.name.endsWith('miss'))
				{
					character.dance();
				}
			}

		}

		// TO DO: Find a better way to handle controller inputs, this should work for now
		if((controls.controllerMode || strumsBlocked.contains(true)) && releaseArray.contains(true))
			for (i in 0...releaseArray.length)
				if(releaseArray[i] || strumsBlocked[i] == true)
					keyReleased(i);
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
			keysCheck();
		}
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
			if(vocalsBoyfriend != null && char == gf)
			{
				vocalsBoyfriend[1].volume = 0;
			}

			if(vocalsDad != null && char == gf)
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
			
			if(vocalsBoyfriend != null)
			{
				for(boyfriend in vocalsBoyfriend)
				{
					boyfriend.volume = 0;
				}
			}
			if(vocalsDad != null)
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
		if(vocalsBoyfriend != null)
		{
			for(boyfriend in vocalsBoyfriend)
			{
				boyfriend.volume = 0;
			}
		}
		if(vocalsDad != null)
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
				if(vocalsBoyfriend != null)
				{
					for(boyfriend in vocalsBoyfriend)
					{
						boyfriend.volume = 0;
					}
				}
				if(vocalsDad != null)
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
				if(vocalsBoyfriend != null && char == gf)
				{
					vocalsBoyfriend[1].volume = 0;
				}
		
				if(vocalsDad != null && char == gf)
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
			if(vocalsBoyfriend != null)
			{
				for(boyfriend in vocalsBoyfriend)
				{
					boyfriend.volume = 0;
				}
			}
			if(vocalsDad != null)
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

			if (chararterStrums.members[Std.int(Math.abs(note.noteData))] != null)
			{
				chararterStrums.members[Std.int(Math.abs(note.noteData))].playAnim('confirm', true);
				chararterStrums.members[Std.int(Math.abs(note.noteData))].resetAnim = (Conductor.stepCrochet * 1.25 / 1000 / playbackRate);
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

			//where All player and opponent hit a note but simple 
			callOnHaxes('noteHit', [note, character, chararterStrums]);
			callOnHaxes('noteHit', [notes.members.indexOf(note), Math.abs(note.noteData), note.noteType, note.isSustainNote]);

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
					popUpScore(note, playerStrums);
				}
				else if(!note.isSustainNote && !note.noteSplashDisabled)
				{
					spawnNoteSplashOnNote(note, playerStrums);
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
					popUpScore(note, opponentStrums);
				}
				else if(!note.isSustainNote && !note.noteSplashDisabled)
				{
					spawnNoteSplashOnNote(note, opponentStrums);
				}

				if(opponentControlled)
				{
					health += note.hitHealth * healthGain;
				}
			}

			if(chararterStrums.autoplay)
			{
				if (chararterStrums.members[Std.int(Math.abs(note.noteData))] != null)
				{
					chararterStrums.members[Std.int(Math.abs(note.noteData))].playAnim('confirm', true);
					chararterStrums.members[Std.int(Math.abs(note.noteData))].resetAnim = (Conductor.stepCrochet * 1.25 / 1000 / playbackRate);
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
			
			if(note.mustPress)
			{
				callOnHaxes('goodNoteHit', [note, character, chararterStrums]);
				callOnLuas('goodNoteHit', [notes.members.indexOf(note), Math.abs(note.noteData), note.noteType, note.isSustainNote]);
			}
			else
			{
				callOnHaxes('opponentNoteHit', [note, character, chararterStrums]);
				callOnLuas('opponentNoteHit', [notes.members.indexOf(note), Math.abs(note.noteData), note.noteType, note.isSustainNote]);
			}

			//where All player and opponent hit a note but simple 
			callOnHaxes('noteHit', [note, character, chararterStrums]);
			callOnLuas('noteHit', [notes.members.indexOf(note), Math.abs(note.noteData), note.noteType, note.isSustainNote]);

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
		if(note != null && strumline != null) {
			var strum:StrumNote = strumline.members[note.noteData];
			if(strum != null)
				spawnNoteSplash(strum.x, strum.y, note.noteData, note);
		}
	}

	public function spawnNoteSplash(x:Float, y:Float, data:Int, ?note:Note = null) {
		var splash:NoteSplash = grpNoteSplashes.recycle(NoteSplash);
		splash.setupNoteSplash(x, y, data, note);
		grpNoteSplashes.add(splash);

		setOnHaxes('splash', splash);
		setOnHaxes('grpNoteSplashes', grpNoteSplashes);
		callOnLuas('spawnNoteSplash', [x,y, Math.abs(note.noteData)]);
		callOnHaxes('spawnNoteSplash', [x, y, data, note]);		
	}

	override function destroy() {
		#if LUA_ALLOWED
		for (i in 0...luaArray.length) {
			var lua:FunkinLua = luaArray[0];
			lua.call('onDestroy', []);
			lua.stop();
		}
		luaArray = [];
		FunkinLua.customFunctions.clear();
		#end

		#if HSCRIPT_ALLOWED
		for (script in haxeArray)
			if(script != null)
			{
				script.call('onDestroy');
				script.active = false;
				#if (SScript >= "3.0.3")
				script.destroy();
				#end
			}

		haxeArray = [];
		#end

		
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyRelease);

		FlxAnimationController.globalSpeed = 1;
		FlxG.sound.music.pitch = 1;
		Note.globalRgbShaders = [];
		objects.NoteTypesConfig.clearNoteTypesData();
		FunkinLua.customFunctions.clear();
		instance = null;
		#if desktop
		DiscordClient.resetID();
		#end
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

		stage.stepHit(curStep);

		lastStepHit = curStep;
		setOnScripts('curStep', curStep);
		callOnScripts('onStepHit', []);
		callOnScripts('stepHit', []);
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

		stage.beatHit(curBeat);
		lastBeatHit = curBeat;

		setOnScripts('curBeat', curBeat); //DAWGG?????
		callOnScripts('onBeatHit', []);
		callOnScripts('beatHit', []);
	}

	override function sectionHit()
	{
		super.sectionHit();

		stage.sectionHit(curSection);

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
				Conductor.bpm = SONG.notes[curSection].bpm;
				setOnScripts('curBpm', Conductor.bpm);
				setOnScripts('crochet', Conductor.crochet);
				setOnScripts('stepCrochet', Conductor.stepCrochet);
			}
			setOnScripts('mustHitSection', SONG.notes[curSection].mustHitSection);
			setOnScripts('altAnim', SONG.notes[curSection].altAnim);
			setOnScripts('gfSection', SONG.notes[curSection].gfSection);
		}
		
		setOnScripts('curSection', curSection);
		callOnScripts('onSectionHit', []);

		setOnScripts('curSection', curSection);
		callOnScripts('sectionHit', []);
	}

	public function callOnScripts(funcToCall:String, args:Array<Dynamic> = null, ignoreStops = false, exclusions:Array<String> = null, excludeValues:Array<Dynamic> = null):Dynamic {
		var returnVal:Dynamic = FunkinLua.Function_Continue;
		if(args == null) args = [];
		if(exclusions == null) exclusions = [];
		if(excludeValues == null) excludeValues = [FunkinLua.Function_Continue];

		var result:Dynamic = callOnLuas(funcToCall, args, ignoreStops, exclusions, excludeValues);
		if(result == null || excludeValues.contains(result)) result = callOnHaxes(funcToCall, args, ignoreStops, exclusions, excludeValues);
		return result;
	}


	public function callOnLuas(funcToCall:String, args:Array<Dynamic> = null, ignoreStops = false, exclusions:Array<String> = null, excludeValues:Array<Dynamic> = null):Dynamic {
		var returnVal:Dynamic = FunkinLua.Function_Continue;
		#if LUA_ALLOWED
		if(args == null) args = [];
		if(exclusions == null) exclusions = [];
		if(excludeValues == null) excludeValues = [FunkinLua.Function_Continue];

		var len:Int = luaArray.length;
		var i:Int = 0;
		while(i < len)
		{
			var script:FunkinLua = luaArray[i];
			if(exclusions.contains(script.scriptName))
			{
				i++;
				continue;
			}

			var myValue:Dynamic = script.call(funcToCall, args);
			if((myValue == FunkinLua.Function_StopLua || myValue == FunkinLua.Function_StopAll) && !excludeValues.contains(myValue) && !ignoreStops)
			{
				returnVal = myValue;
				break;
			}
			
			if(myValue != null && !excludeValues.contains(myValue))
				returnVal = myValue;

			if(!script.closed) i++;
			else len--;
		}
		#end
		return returnVal;
	}

	public function callOnHaxes(funcToCall:String, args:Array<Dynamic> = null, ?ignoreStops:Bool = false, exclusions:Array<String> = null, excludeValues:Array<Dynamic> = null):Dynamic {
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

	public function setOnScripts(variable:String, arg:Dynamic, exclusions:Array<String> = null) {
		if(exclusions == null) exclusions = [];
		setOnLuas(variable, arg, exclusions);
		setOnHaxes(variable, arg, exclusions);
	}

	public function setOnLuas(variable:String, arg:Dynamic, exclusions:Array<String> = null) {
		#if LUA_ALLOWED
		if(exclusions == null) exclusions = [];
		for (script in luaArray) {
			if(exclusions.contains(script.scriptName))
				continue;

			script.set(variable, arg);
		}
		#end
	}

	public function setOnHaxes(variable:String, arg:Dynamic, exclusions:Array<String> = null) {
		#if HSCRIPT_ALLOWED
		if(exclusions == null) exclusions = [];
		for (script in haxeArray) {
			if(exclusions.contains(script.origin))
				continue;

			script.set(variable, arg);
		}
		#end
	}

	public function loadHaxe(file:String)
	{
		var newScript:FunkinHaxe = null;
		try
		{
			newScript = new FunkinHaxe(null, file);
			@:privateAccess
			if(newScript.parsingExceptions != null && newScript.parsingExceptions.length > 0)
			{
				@:privateAccess
				for (e in newScript.parsingExceptions)
					if(e != null)
						addTextToDebug('ERROR ON LOADING ($file): ${e.message.substr(0, e.message.indexOf('\n'))}', FlxColor.RED);
				return;
			}

			haxeArray.push(newScript);
			if(newScript.exists('onCreate'))
			{
				var callValue = newScript.call('onCreate');
				if(!callValue.succeeded)
				{
					for (e in callValue.exceptions)
						if (e != null)
							addTextToDebug('ERROR ($file: onCreate) - ${e.message.substr(0, e.message.indexOf('\n'))}', FlxColor.RED);
					newScript.active = false;
					haxeArray.remove(newScript);
					trace('failed to initialize sscript interp!!! ($file)');
				}
				else trace('initialized sscript interp successfully: $file');
			}

			if(newScript.exists('create'))
			{
				var callValue = newScript.call('create');
				if(!callValue.succeeded)
				{
					for (e in callValue.exceptions)
						if (e != null)
							addTextToDebug('ERROR ($file: create) - ${e.message.substr(0, e.message.indexOf('\n'))}', FlxColor.RED);
					newScript.active = false;
					haxeArray.remove(newScript);
					trace('failed to initialize sscript interp!!! ($file)');
				}
				else trace('initialized sscript interp successfully: $file');
			}

			trace('initialized sscript interp successfully: $file');
		}
		catch(e:Dynamic)
		{
			var newScript:FunkinHaxe = cast (SScript.global.get(file), FunkinHaxe);
			addTextToDebug('ERROR ($file) - ' + e.message.substr(0, e.message.indexOf('\n')), FlxColor.RED);
			if(newScript != null)
			{
				newScript.active = false;
				haxeArray.remove(newScript);
			}
		}
	}

	public var ratingName:String = '?';
	public var ratingPercent:Float;
	public var ratingFC:String;
	public function RecalculateRating(badHit:Bool = false) {
		setOnScripts('score', songScore);
		setOnScripts('misses', songMisses);
		setOnScripts('hits', songHits);

		var ret:Dynamic = callOnScripts('onRecalculateRating', null, true);
		if(ret != FunkinLua.Function_Stop)
		{
			ratingName = '?';
			if(totalPlayed != 0) //Prevent divide by 0
			{
				// Rating Percent
				ratingPercent = Math.min(1, Math.max(0, totalNotesHit / totalPlayed));
				//trace((totalNotesHit / totalPlayed) + ', Total: ' + totalPlayed + ', notes hit: ' + totalNotesHit);

				// Rating Name
				ratingName = ratingStuff[ratingStuff.length-1][0]; //Uses last string
				if(ratingPercent < 1)
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

			fullComboFunction();
		}
		updateScore(badHit); // score will only update after rating is calculated, if it's a badHit, it shouldn't bounce -Ghost
		setOnScripts('rating', ratingPercent);
		setOnScripts('ratingName', ratingName);
		setOnScripts('ratingFC', ratingFC);
	}

	function fullComboUpdate()
	{
		var sicks:Int = ratingsData[0].hits;
		var goods:Int = ratingsData[1].hits;
		var bads:Int = ratingsData[2].hits;
		var shits:Int = ratingsData[3].hits;

		ratingFC = 'Clear';
		if(songMisses < 1)
		{
			if (bads > 0 || shits > 0) ratingFC = 'FC';
			else if (goods > 0) ratingFC = 'GFC';
			else if (sicks > 0) ratingFC = 'SFC';
		}
		else if (songMisses < 10)
			ratingFC = 'SDCB';
	}

	#if ACHIEVEMENTS_ALLOWED
	private function checkForAchievement(achievesToCheck:Array<String> = null):String
	{
		if(chartingMode) return null;

		var usedPractice:Bool = (ClientPrefs.getGameplaySetting('practice') || ClientPrefs.getGameplaySetting('botplay'));
		for (i in 0...achievesToCheck.length) {
			var achievementName:String = achievesToCheck[i];
			if(!Achievements.isAchievementUnlocked(achievementName) && !cpuControlled && Achievements.getAchievementIndex(achievementName) > -1)  {
				var unlock:Bool = false;
				
				if (achievementName.contains(WeekData.getWeekFileName()) && achievementName.endsWith('_nomiss')) // any FC achievements, name should be "weekFileName_nomiss", e.g: "weekd_nomiss";
				{
					if(isStoryMode && campaignMisses + songMisses < 1 && Difficulty.getString().toUpperCase() == 'HARD'
						&& storyPlaylist.length <= 1 && !changedDifficulty && !usedPractice)
						unlock = true;
				}
				else
				{
					switch(achievementName)
					{
						case 'ur_bad':
							unlock = (ratingPercent < 0.2 && !practiceMode);
						case 'ur_good':
							unlock = (ratingPercent >= 1 && !usedPractice);
						case 'roadkill_enthusiast':
							unlock = (Achievements.henchmenDeath >= 50);
						case 'oversinging':
							for(charPlayer in playerStrums.characters)
							{
								if(charPlayer != null)
									unlock = (charPlayer.holdTimer >= 10 && !usedPractice);
							}
							for(dadPlayer in opponentStrums.characters)
							{
								if(dadPlayer != null)
									unlock = (dadPlayer.holdTimer >= 10 && !usedPractice);
							}
						case 'hype':
							unlock = (!boyfriendIdled && !usedPractice);
						case 'two_keys':
							unlock = (!usedPractice && keysPressed.length <= 2);
						case 'toastie':
							unlock = (!ClientPrefs.shaders && ClientPrefs.lowQuality && !ClientPrefs.globalAntialiasing);
						case 'debugger':
							unlock = (Paths.formatToSongPath(SONG.song) == 'test' && !usedPractice);
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