package objects;

import util.Conductor;
import flixel.tweens.FlxTween;
import MusicBeat;
import objects.BGSprite;
import flixel.system.FlxSound;
import flixel.util.FlxColor;
import objects.BackgroundGirls;
import objects.BackgroundDancer;
import objects.TankmenBG;
import meta.substate.GameOverSubstate;
import meta.state.PlayState;
import flixel.math.FlxMath;
import util.script.*;
import util.script.Globals.*;
import flixel.FlxBasic;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxObject;
import flixel.util.FlxTimer;
import util.CoolUtil;
import util.DialogueBox;
import objects.Note;
import util.CutsceneHandler;
import flixel.math.FlxPoint;
import animateatlas.AtlasFrameMaker;
import flixel.util.FlxDestroyUtil;
#if HSCRIPT_ALLOWED
import tea.SScript;
#end

#if sys
import sys.io.File;
import sys.FileSystem;
#end

class Stage extends FlxTypedGroup<FlxBasic>
{
	private var game(default, set):Dynamic = PlayState.instance;
	public var onPlayState:Bool = false;

	// some variables for convenience
	public var paused(get, never):Bool;
	public var songName:String = Paths.formatToSongPath(PlayState.SONG.song);
	public var isStoryMode(get, never):Bool;
	public var seenCutscene(get, never):Bool;
	public var inCutscene(get, set):Bool;
	public var canPause(get, set):Bool;

	public var boyfriend(get, never):Character;
	public var dad(get, never):Character;
	public var gf(get, never):Character;
	public var boyfriendGroup(get, never):FlxSpriteGroup;
	public var dadGroup(get, never):FlxSpriteGroup;
	public var gfGroup(get, never):FlxSpriteGroup;
	
	public var camGame(get, never):FlxCamera;
	public var camHUD(get, never):FlxCamera;
	public var camOther(get, never):FlxCamera;

	public var defaultCamZoom(get, set):Float;
	public var camFollow(get, never):FlxObject;

    public var curStage:String;
    public static var instance:Stage;
	public var luaArray:Array<FunkinLua> = [];
	public var haxeArray:Array<FunkinHaxe> = [];
	
	public var sendMessage:Bool = false;
	public var messageText:String = '';

    public var layers:Map<String, FlxTypedGroup<FlxBasic>> = [
        "boyfriend"=>new FlxTypedGroup<FlxBasic>(), // stuff that should be layered infront of all characters, but below the foreground
        "dad"=>new FlxTypedGroup<FlxBasic>(), // stuff that should be layered infront of the dad and gf but below boyfriend and foreground
        "gf"=>new FlxTypedGroup<FlxBasic>(), // stuff that should be layered infront of the gf but below the other characters and foreground
		"foreground"=>new FlxTypedGroup<FlxBasic>(), // stuff that should be layered infront of the characters 
    ];

    public function new(curStage:String = 'stage')
    {
        super();
		this.curStage = curStage;
        instance = this;
		setStage(curStage);
    }

	public function setStage(curStage:String)
	{
		destoryStageScript();
		reloadGroups();

		try
		{
			callStageScript(curStage);
		}
		catch(e:Dynamic)
		{
			if(PlayState.instance != null)
			{
				PlayState.instance.addTextToDebug('Stage ERROR - ' + e.toString(), FlxColor.RED);
			}
			trace('Stage ERROR - ' + e.toString());
		}
	}

	public function reloadGroups()
	{
				
		var i:Int = members.length-1;
		while(i >= 0) {
			var memb:FlxBasic = members[i];
			if(memb != null) {
				memb.kill();
				remove(memb);
				memb.destroy();
			}
			--i;
		}

		if(layers.get('boyfriend') != null)
		{
			var i:Int = layers.get('boyfriend').members.length-1;
			while(i >= 0) {
				var memb:FlxBasic = layers.get('boyfriend').members[i];
				if(memb != null) {
					memb.kill();
					layers.get('boyfriend').remove(memb);
					memb.destroy();
				}
				--i;
			}
		}

		if(layers.get('dad') != null)
		{
			var i:Int = layers.get('dad').members.length-1;
			while(i >= 0) {
				var memb:FlxBasic = layers.get('dad').members[i];
				if(memb != null) {
					memb.kill();
					layers.get('dad').remove(memb);
					memb.destroy();
				}
				--i;
			}
		}

		if(layers.get('gf') != null)
		{
			var i:Int = layers.get('gf').members.length-1;
			while(i >= 0) {
				var memb:FlxBasic = layers.get('gf').members[i];
				if(memb != null) {
					memb.kill();
					layers.get('gf').remove(memb);
					memb.destroy();
				}
				--i;
			}
		}

		if(layers.get('foreground') != null)
		{
			var i:Int = layers.get('foreground').members.length-1;
			while(i >= 0) {
				var memb:FlxBasic = layers.get('foreground').members[i];
				if(memb != null) {
					memb.kill();
					layers.get('foreground').remove(memb);
					memb.destroy();
				}
				--i;
			}
		}
	}

	function destoryStageScript()
	{
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
	}

	function callStageScript(curStage:String)
	{
		startStageScripts(curStage);

		setOnScripts('paused', Stage.instance.paused);
		setOnScripts('songName', Stage.instance.songName);
		setOnScripts('isStoryMode', Stage.instance.isStoryMode);
		setOnScripts('seenCutscene', Stage.instance.seenCutscene);
		setOnScripts('inCutscene', Stage.instance.inCutscene);
		setOnScripts('canPause', Stage.instance.canPause);

		if (PlayState.isStoryMode && !PlayState.seenCutscene)
		{
			switch(songName)
			{
				case 'monster':
					setStartCallback(monsterCutscene);
				case 'eggnog':
					setEndCallback(eggnogEndCutscene);
				case 'winter-horrorland':
					setStartCallback(winterHorrorlandCutscene);
				case 'senpai'|'roses'|'thorns':
					FlxG.sound.playMusic(Paths.music('stages/school/Lunchbox'), 0);
					FlxG.sound.music.fadeIn(1, 0, 0.8);

					if(songName == 'roses') FlxG.sound.play(Paths.sound('stages/school/ANGRY'));
					initDoof();
					if(songName == 'thorns')
						setStartCallback(thornIntro);
					else
						setStartCallback(schoolIntro);
				case 'ugh'|'guns'|'stress':
					setStartCallback(tankmanCutscene);
			}
		}
	}

	public function createPost()
	{
		callOnScripts('createPost');
		callOnScripts('onCreatePost');
	}

	public function triggerEventStage(name:String, value:Array<String>, strumTime:Float)
	{
		callOnScripts('event', [name, value[0], value[1], strumTime]);
		callOnScripts('onEvent', [name, value[0], value[1], strumTime]);
	}

	public function eventPushed(subEvent:EventNote)
	{
		callOnScripts('onEventPushed', [subEvent.event, subEvent.value1 != null ? subEvent.value1 : '', subEvent.value2 != null ? subEvent.value2 : '', subEvent.strumTime]);
		callOnScripts('eventPushed', [subEvent.event, subEvent.value1 != null ? subEvent.value1 : '', subEvent.value2 != null ? subEvent.value2 : '', subEvent.strumTime]);
	}

	public function countdownTick(swagCounter:Int) {
		callOnScripts('countdownTick', [swagCounter]);
		callOnScripts('onCountdownTick', [swagCounter]);
	}

	
    override public function update(elapsed:Float)
    {
		super.update(elapsed);
		
		callOnScripts('update', [elapsed]);
		callOnScripts('onUpdate', [elapsed]);

		callOnScripts('updatePost', [elapsed]);
		callOnScripts('onUpdatePost', [elapsed]);
    }

	var lastStepHit:Int = -1;
	public function stepHit(curStep:Int)
	{
		if(curStep == lastStepHit) {
			return;
		}

		lastStepHit = curStep;
		setOnScripts('curStep', curStep);
		callOnScripts('onStepHit', []);
		callOnScripts('stepHit', []);
	}

	var lastBeatHit:Int = -1;
    public function beatHit(curBeat:Int)
    {

        if(lastBeatHit >= curBeat) {
			return;
		}

		setOnScripts('curBeat', curBeat);

		callOnScripts('onBeatHit');
		callOnScripts('beatHit');
    }

	public function sectionHit(curSection:Int) {
		setOnScripts('curSection', curSection);
		callOnScripts('onSectionHit', []);

		setOnScripts('curSection', curSection);
		callOnScripts('sectionHit', []);
	}

	public function closeSubState() {
		callOnScripts('onResume');
		callOnScripts('resume');
		callOnScripts('closeSubState');
	}

	public function openSubState() {

		callOnScripts('openSubState');
	}

	public function addBehindGF(obj:FlxSprite) insert(members.indexOf(game.gfGroup), obj);
	public function addBehindBF(obj:FlxSprite) insert(members.indexOf(game.boyfriendGroup), obj);
	public function addBehindDad(obj:FlxSprite) insert(members.indexOf(game.dadGroup), obj);

	public function setDefaultGF(name:String) //Fix for the Chart Editor on Base Game stages
	{
		var gfVersion:String = PlayState.SONG.gfVersion;
		if(gfVersion == null || gfVersion.length < 1)
		{
			gfVersion = name;
			PlayState.SONG.gfVersion = gfVersion;
		}
	}

	public function setStartCallback(myfn:Void->Void)
	{
		PlayState.instance.startCallback = myfn;
	}

	public function setEndCallback(myfn:Void->Void)
	{
		PlayState.instance.endCallback = myfn;
	}

	public function precacheImage(key:String) precache(key, 'image');
	public function precacheSound(key:String) precache(key, 'sound');
	public function precacheMusic(key:String) precache(key, 'music');

	public function precache(key:String, type:String)
	{
		if(onPlayState)
			game.precacheList.set(key, type);

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

	function startCountdown() if(onPlayState) return game.startCountdown(); else return false;
	function endSong() if(onPlayState) return game.endSong(); else return false;
	function moveCameraSection() if(onPlayState) game.moveCameraSection();
	function moveCamera(isDad:Bool) if(onPlayState) game.moveCamera(isDad);

	override function destroy()
	{
		super.destroy();
		#if LUA_ALLOWED
		for (i in 0...luaArray.length) {
			var lua:FunkinLua = luaArray[0];
			lua.call('onDestroy', []);
			lua.stop();
		}
		luaArray = [];
		#end

		#if HSCRIPT_ALLOWED
		for (script in haxeArray)
			if(script != null)
			{
				script.call('onDestroy');
				script.active = false;
			}

		haxeArray = [];
		#end
	}

	public function startStageScripts(name:String)
	{
		#if LUA_ALLOWED
		var doPush:Bool = false;
		var luaFile:String = 'stages/' + name + '.lua';
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
			var scriptFile:String = 'stages/' + name + '.$ext';
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
						FunkinLua.luaTrace('STAGE ERROR (${script.origin}: ${callValue.calledFunction}) - ' + e.message.substr(0, e.message.indexOf('\n')), true, false, FlxColor.RED);
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
	function loadHaxe(file:String)
	{
		try
		{
			var newScript:FunkinHaxe = new FunkinHaxe(null, file, true);

			setScriptHaxe(newScript, 'stage', Stage.instance);
			setScriptHaxe(newScript, 'boyfriend', Stage.instance.boyfriend);
			setScriptHaxe(newScript, 'dad', Stage.instance.dad);

			setScriptHaxe(newScript, 'boyfriendGroup', Stage.instance.boyfriendGroup);
			setScriptHaxe(newScript, 'dadGroup', Stage.instance.dadGroup);
			setScriptHaxe(newScript, 'gfGroup', Stage.instance.gfGroup);

			setScriptHaxe(newScript, 'camGame', Stage.instance.camGame);
			setScriptHaxe(newScript, 'camHUD', Stage.instance.camHUD);
			setScriptHaxe(newScript, 'camOther', Stage.instance.camOther);

			setScriptHaxe(newScript, 'defaultCamZoom', Stage.instance.defaultCamZoom);
			setScriptHaxe(newScript, 'camFollow', Stage.instance.camFollow);

			@:privateAccess
			if(newScript.parsingExceptions != null && newScript.parsingExceptions.length > 0)
			{
				@:privateAccess
				for (e in newScript.parsingExceptions)
					if(e != null)
					{
						if(PlayState.instance != null)
						{
							PlayState.instance.addTextToDebug('STAGE ERROR ON LOADING ($file): ${e.message.substr(0, e.message.indexOf('\n'))}', FlxColor.RED);
						}
					}
						
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
						{
							if(PlayState.instance != null)
							{
								PlayState.instance.addTextToDebug('STAGE ERROR ($file: onCreate) - ${e.message.substr(0, e.message.indexOf('\n'))}', FlxColor.RED);
							}
						}
							
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
						{
							if(PlayState.instance != null)
							{
								if(PlayState.instance != null)
								{
									PlayState.instance.addTextToDebug('STAGE ERROR ($file: create) - ${e.message.substr(0, e.message.indexOf('\n'))}', FlxColor.RED);
								}
							}
						}
							
					newScript.active = false;
					haxeArray.remove(newScript);
					trace('failed to initialize sscript interp!!! ($file)');
				}
				else trace('initialized sscript interp successfully: $file');
			}
		}
		catch(e:Dynamic)
		{
			var newScript:FunkinHaxe = cast (SScript.global.get(file), FunkinHaxe);
			if(PlayState.instance != null)
			{
				PlayState.instance.addTextToDebug('STAGE ERROR ($file) - ' + e.message.substr(0, e.message.indexOf('\n')), FlxColor.RED);
			}
			trace('STAGE ERROR ($file) - ' + e.message.substr(0, e.message.indexOf('\n')));
			if(newScript != null)
			{
				newScript.active = false;
				haxeArray.remove(newScript);
			}
		}
	}
	
	function setScriptHaxe(newScript:FunkinHaxe, name:String, data:Dynamic)
	{
		newScript.set(name, data);
	}


	inline private function get_paused() return game.paused;
	inline private function get_isStoryMode() return PlayState.isStoryMode;
	inline private function get_seenCutscene() return PlayState.seenCutscene;
	inline private function get_inCutscene() return game.inCutscene;
	inline private function set_inCutscene(value:Bool)
	{
		game.inCutscene = value;
		return value;
	}
	inline private function get_canPause() return game.canPause;
	inline private function set_canPause(value:Bool)
	{
		game.canPause = value;
		return value;
	}
	inline private function set_game(value:MusicBeatState)
	{
		onPlayState = (Std.isOfType(value, meta.state.PlayState));
		game = value;
		return value;
	}

	inline private function get_boyfriend():Character return game.boyfriend;
	inline private function get_dad():Character return game.dad;
	inline private function get_gf():Character return game.gf;

	inline private function get_boyfriendGroup():FlxSpriteGroup return game.boyfriendGroup;
	inline private function get_dadGroup():FlxSpriteGroup return game.dadGroup;
	inline private function get_gfGroup():FlxSpriteGroup return game.gfGroup;
	
	inline private function get_camGame():FlxCamera return game.camGame;
	inline private function get_camHUD():FlxCamera return game.camHUD;
	inline private function get_camOther():FlxCamera return game.camOther;

	inline private function get_defaultCamZoom():Float return game.defaultCamZoom;
	inline private function set_defaultCamZoom(value:Float):Float
	{
		game.defaultCamZoom = value;
		return game.defaultCamZoom;
	}
	inline private function get_camFollow():FlxObject return game.camFollow;




	//BASE GAME CUTSCENE
	function monsterCutscene()
	{
		inCutscene = true;
		camHUD.visible = false;

		FlxG.camera.focusOn(new FlxPoint(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100));

		// character anims
		FlxG.sound.play(Paths.soundRandom('stages/spooky/thunder_', 1, 2));
		if(gf != null) gf.playAnim('scared', true);
		boyfriend.playAnim('scared', true);

		// white flash
		var whiteScreen:FlxSprite = new FlxSprite().makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.WHITE);
		whiteScreen.scrollFactor.set();
		whiteScreen.blend = ADD;
		add(whiteScreen);
		FlxTween.tween(whiteScreen, {alpha: 0}, 1, {
			startDelay: 0.1,
			ease: FlxEase.linear,
			onComplete: function(twn:FlxTween)
			{
				remove(whiteScreen);
				whiteScreen.destroy();

				camHUD.visible = true;
				startCountdown();
			}
		});
	}

	function eggnogEndCutscene()
	{
		if(PlayState.storyPlaylist[1] == null)
		{
			endSong();
			return;
		}

		var nextSong:String = Paths.formatToSongPath(PlayState.storyPlaylist[1]);
		if(nextSong == 'winter-horrorland')
		{
			FlxG.sound.play(Paths.sound('stages/mall/Lights_Shut_off'));

			var blackShit:FlxSprite = new FlxSprite(-FlxG.width * FlxG.camera.zoom,
				-FlxG.height * FlxG.camera.zoom).makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.BLACK);
			blackShit.scrollFactor.set();
			add(blackShit);
			camHUD.visible = false;

			inCutscene = true;
			canPause = false;

			new FlxTimer().start(1.5, function(tmr:FlxTimer) {
				endSong();
			});
		}
		else endSong();
	}

	function winterHorrorlandCutscene()
	{
		
	}

	var doof:DialogueBox = null;
	function initDoof()
	{
		var file:String = Paths.txt(songName + '/' + songName + 'Dialogue'); //Checks for vanilla/Senpai dialogue
		#if MODS_ALLOWED
		if (!FileSystem.exists(file))
		#else
		if (!OpenFlAssets.exists(file))
		#end
		{
			startCountdown();
			return;
		}

		doof = new DialogueBox(false, CoolUtil.coolTextFile(file));
		doof.cameras = [camHUD];
		doof.scrollFactor.set();
		doof.finishThing = startCountdown;
		doof.nextDialogueThing = PlayState.instance.startNextDialogue;
		doof.skipDialogueThing = PlayState.instance.skipDialogue;
	}
	
	function schoolIntro():Void
	{
		inCutscene = true;
		var black:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
		black.scrollFactor.set();
		if(songName == 'senpai') add(black);

		new FlxTimer().start(0.3, function(tmr:FlxTimer)
		{
			black.alpha -= 0.15;

			if (black.alpha > 0)
				tmr.reset(0.3);
			else
			{
				if (doof != null)
					add(doof);
				else
					startCountdown();

				remove(black);
				black.destroy();
			}
		});
	}

	function thornIntro():Void
	{
		inCutscene = true;
		var red:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, 0xFFff1b31);
		red.scrollFactor.set();
		add(red);

		var senpaiEvil:FlxSprite = new FlxSprite();
		senpaiEvil.frames = Paths.getSparrowAtlas('stages/school/senpaiCrazy');
		senpaiEvil.animation.addByPrefix('idle', 'Senpai Pre Explosion', 24, false);
		senpaiEvil.setGraphicSize(Std.int(senpaiEvil.width * 6));
		senpaiEvil.scrollFactor.set();
		senpaiEvil.updateHitbox();
		senpaiEvil.screenCenter();
		senpaiEvil.x += 300;
		camHUD.visible = false;

		new FlxTimer().start(2.1, function(tmr:FlxTimer)
		{
			if (doof != null)
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
							senpaiEvil.destroy();
							remove(red);
							red.destroy();
							FlxG.camera.fade(FlxColor.WHITE, 0.01, true, function()
							{
								add(doof);
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
		});
	}


	var cutsceneHandler:CutsceneHandler;
	var tankman:FlxSprite;
	var tankman2:FlxSprite;
	var gfDance:FlxSprite;
	var gfCutscene:FlxSprite;
	var picoCutscene:FlxSprite;
	var boyfriendCutscene:FlxSprite;
	function tankmanCutscene()
	{
		cutsceneHandler = new CutsceneHandler();

		dadGroup.alpha = 0.00001;
		camHUD.visible = false;
		//inCutscene = true; //this would stop the camera movement, oops

		tankman = new FlxSprite(-20, 320);
		tankman.frames = Paths.getSparrowAtlas('tank/cutscenes/' + songName);
		tankman.antialiasing = ClientPrefs.globalAntialiasing;
		addBehindDad(tankman);

		tankman2 = new FlxSprite(16, 312);
		tankman2.antialiasing = ClientPrefs.globalAntialiasing;
		tankman2.alpha = 0.000001;

		gfDance = new FlxSprite(gf.x - 107, gf.y + 140);
		gfDance.antialiasing = ClientPrefs.globalAntialiasing;

		gfCutscene = new FlxSprite(gf.x - 104, gf.y + 122);
		gfCutscene.antialiasing = ClientPrefs.globalAntialiasing;

		picoCutscene = new FlxSprite(gf.x - 849, gf.y - 264);
		picoCutscene.antialiasing = ClientPrefs.globalAntialiasing;

		boyfriendCutscene = new FlxSprite(boyfriend.x + 5, boyfriend.y + 20);
		boyfriendCutscene.antialiasing = ClientPrefs.globalAntialiasing;

		cutsceneHandler.push(tankman);
		cutsceneHandler.push(tankman2);
		cutsceneHandler.push(gfDance);
		cutsceneHandler.push(gfCutscene);
		cutsceneHandler.push(picoCutscene);
		cutsceneHandler.push(boyfriendCutscene);

		cutsceneHandler.finishCallback = function()
		{
			var timeForStuff:Float = Conductor.crochet / 1000 * 4.5;
			FlxG.sound.music.fadeOut(timeForStuff);
			FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, timeForStuff, {ease: FlxEase.quadInOut});
			startCountdown();

			dadGroup.alpha = 1;
			camHUD.visible = true;
			boyfriend.animation.finishCallback = null;
			gf.animation.finishCallback = null;
			gf.dance();
		};
		camFollow.setPosition(dad.x + 280, dad.y + 170);

		switch(songName)
		{
			case 'ugh':
				ughIntro();
			case 'guns':
				gunsIntro();
			case 'stress':
				stressIntro();
		}
	}

	function ughIntro()
	{
		cutsceneHandler.endTime = 12;
		cutsceneHandler.music = 'stage/tank/DISTORTO';
		precacheSound('stage/tank/wellWellWell');
		precacheSound('stage/tank/killYou');
		precacheSound('stage/tank/bfBeep');


		var wellWellWell:FlxSound = new FlxSound().loadEmbedded(Paths.sound('stage/tank/wellWellWell'));
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
			FlxG.sound.play(Paths.sound('stage/tank/bfBeep'));
		});

		// Move camera to Tankman
		cutsceneHandler.timer(6, function()
		{
			camFollow.x -= 750;
			camFollow.y -= 100;

			// We should just kill you but... what the hell, it's been a boring day... let's see what you've got!
			tankman.animation.play('killYou', true);
			FlxG.sound.play(Paths.sound('stage/tank/killYou'));
		});
	}

	function gunsIntro()
	{
		cutsceneHandler.endTime = 11.5;
		cutsceneHandler.music = 'stage/tank/DISTORTO';
		tankman.x += 40;
		tankman.y += 10;
		precacheSound('stage/tank/tankSong2');

		var tightBars:FlxSound = new FlxSound().loadEmbedded(Paths.sound('stage/tank/tankSong2'));
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
	}

	function stressIntro()
	{
		cutsceneHandler.endTime = 35.5;
		tankman.x -= 54;
		tankman.y -= 14;
		gfGroup.alpha = 0.00001;
		boyfriendGroup.alpha = 0.00001;
		camFollow.setPosition(dad.x + 400, dad.y + 170);
		FlxTween.tween(FlxG.camera, {zoom: 0.9 * 1.2}, 1, {ease: FlxEase.quadInOut});
		if(game.getLuaGroup('foregroundSprites') != null) 
		{
			game.getLuaGroup('foregroundSprites').forEach(function(spr:FlxSprite)
			{
				if(spr != null)
					spr.y += 100;
			});
		}

		precacheSound('stage/tank/stressCutscene');

		tankman2.frames = Paths.getSparrowAtlas('stage/tank/cutscenes/stress2');
		addBehindDad(tankman2);

		if (!ClientPrefs.lowQuality)
		{
			gfDance.frames = Paths.getSparrowAtlas('characters/gfTankmen');
			gfDance.animation.addByPrefix('dance', 'GF Dancing at Gunpoint', 24, true);
			gfDance.animation.play('dance', true);
			addBehindGF(gfDance);
		}

		gfCutscene.frames = Paths.getSparrowAtlas('stage/tank/cutscenes/stressGF');
		gfCutscene.animation.addByPrefix('dieBitch', 'GF STARTS TO TURN PART 1', 24, false);
		gfCutscene.animation.addByPrefix('getRektLmao', 'GF STARTS TO TURN PART 2', 24, false);
		gfCutscene.animation.play('dieBitch', true);
		gfCutscene.animation.pause();
		addBehindGF(gfCutscene);
		if (!ClientPrefs.lowQuality) gfCutscene.alpha = 0.00001;

		picoCutscene.frames = AtlasFrameMaker.construct('stage/tank/cutscenes/stressPico');
		picoCutscene.animation.addByPrefix('anim', 'Pico Badass', 24, false);
		addBehindGF(picoCutscene);
		picoCutscene.alpha = 0.00001;

		boyfriendCutscene.frames = Paths.getSparrowAtlas('characters/BOYFRIEND');
		boyfriendCutscene.animation.addByPrefix('idle', 'BF idle dance', 24, false);
		boyfriendCutscene.animation.play('idle', true);
		boyfriendCutscene.animation.curAnim.finish();
		addBehindBF(boyfriendCutscene);

		var cutsceneSnd:FlxSound = new FlxSound().loadEmbedded(Paths.sound('stage/tank/stressCutscene'));
		FlxG.sound.list.add(cutsceneSnd);

		tankman.animation.addByPrefix('godEffingDamnIt', 'TANK TALK 3', 24, false);
		tankman.animation.play('godEffingDamnIt', true);

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
			camFollow.setPosition(dad.x + 500, dad.y + 170);
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

			camFollow.setPosition(boyfriend.x + 280, boyfriend.y + 200);
			FlxG.camera.snapToTarget();
			game.cameraSpeed = 12;
			FlxTween.tween(FlxG.camera, {zoom: 0.9 * 1.2 * 1.2}, 0.25, {ease: FlxEase.elasticOut});
		});

		cutsceneHandler.timer(32.2, function()
		{
			zoomBack();
		});
	}

	function zoomBack()
	{
		var calledTimes:Int = 0;
		camFollow.setPosition(630, 425);
		FlxG.camera.snapToTarget();
		FlxG.camera.zoom = 0.8;
		game.cameraSpeed = 1;

		calledTimes++;
		if (calledTimes > 1)
		{
			if(game.getLuaGroup('foregroundSprites') != null) 
			{
				game.getLuaGroup('foregroundSprites').forEach(function(spr:FlxSprite)
				{
					if(spr != null)
						spr.y -= 100;
				});
			}
		}
	}
}