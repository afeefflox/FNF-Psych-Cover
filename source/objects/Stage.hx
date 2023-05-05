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
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxTimer;
import util.CoolUtil;
#if MODS_ALLOWED
import sys.FileSystem;
#end
class Stage extends MusicBeatObject
{
    public var curStage:String;
    public static var instance:Stage;
	public var luaArray:Array<FunkinLua> = [];
	public var haxeArray:Array<FunkinHaxe> = [];

	
	public var sendMessage:Bool = false;
	public var messageText:String = '';

    public var layers:Map<String,FlxTypedGroup<FlxBasic>> = [
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
		reloadGroups();

		try
		{
			callStageScript(curStage);
		}
		catch (e)
		{
			sendMessage = true;
			messageText = '$curStage: Uncaught Error: $e';
		}
	}

	public function reloadGroups()
	{
		layers.get('boyfriend').forEach(function(a:Dynamic)
		{
			if (a != null && !Std.isOfType(a, flixel.system.FlxSound))
				remove(a);
		});
		layers.get('dad').forEach(function(a:Dynamic)
		{
			if (a != null && !Std.isOfType(a, flixel.system.FlxSound))
				remove(a);
		});
		layers.get('gf').forEach(function(a:Dynamic)
		{
			if (a != null && !Std.isOfType(a, flixel.system.FlxSound))
				remove(a);
		});
		layers.get('foreground').forEach(function(a:Dynamic)
		{
			if (a != null && !Std.isOfType(a, flixel.system.FlxSound))
				remove(a);
		});
	}


	function callStageScript(curStage:String)
	{
		startStageLua(curStage);
		startStageHaxe(curStage);
		
		if (PlayState.SONG != null)
			setOnHaxes('songName', Paths.formatToSongPath(PlayState.SONG.song));

		if (PlayState.instance.boyfriend != null)
		{
			setOnHaxes('bf', PlayState.instance.boyfriend);
			setOnHaxes('boyfriend', PlayState.instance.boyfriend);
			setOnHaxes('player', PlayState.instance.boyfriend);

			setOnHaxes('bfName', PlayState.instance.boyfriend.curCharacter);
			setOnHaxes('boyfriendName', PlayState.instance.boyfriend.curCharacter);
			setOnHaxes('playerName', PlayState.instance.boyfriend.curCharacter);
		}

		if (PlayState.instance.dad != null)
		{
			setOnHaxes('dad', PlayState.instance.dad);
			setOnHaxes('dadOpponent', PlayState.instance.dad);
			setOnHaxes('opponent', PlayState.instance.dad);

			setOnHaxes('dadName', PlayState.instance.dad.curCharacter);
			setOnHaxes('dadOpponentName', PlayState.instance.dad.curCharacter);
			setOnHaxes('opponentName', PlayState.instance.dad.curCharacter);
		}

		if (PlayState.instance.gf != null)
		{
			setOnHaxes('gf', PlayState.instance.gf);
			setOnHaxes('girlfriend', PlayState.instance.gf);
			setOnHaxes('spectator', PlayState.instance.gf);

			setOnHaxes('gfName', PlayState.instance.gf.curCharacter);
			setOnHaxes('girlfriendName', PlayState.instance.gf.curCharacter);
			setOnHaxes('spectatorName', PlayState.instance.gf.curCharacter);
		}

		callOnHaxes('create', []);
		callOnLuas('onCreate', []);
	}

	public function createPost()
	{
		callOnHaxes('createPost', []);
		callOnLuas('onCreatePost', []);
	}

	public function triggerEventStage(name:String, value:Array<String>)
	{
		callOnHaxes('event', [name, value[0], value[1]]);
		callOnLuas('onEvent', [name, value[0], value[1]]);
	}

	
    override public function update(elapsed:Float)
    {
		super.update(elapsed);
		
		callOnHaxes('update', [elapsed]);
		callOnLuas('onUpdate', [elapsed]);

		callOnHaxes('updatePost', [elapsed]);
		callOnLuas('onUpdatePost', [elapsed]);
    }

	public function startStageLua(name:String)
	{
		#if LUA_ALLOWED
		var doPush:Bool = false;
		var luaFile:String = 'stages/' + name + '.lua';
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
			luaArray.push(new FunkinLua(luaFile, true));
		}
		#end		
	}

	
	public function startStageHaxe(name:String)
	{
		var doPush:Bool = false;
		var luaFile:String = 'stages/' + name + '.hx';
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
			haxeArray.push(new FunkinHaxe(luaFile, true));
		}
	}

	var lastStepHit:Int = -1;
	override function stepHit()
	{
		super.stepHit();
		if(curStep == lastStepHit) {
			return;
		}

		lastStepHit = curStep;
		setOnLuas('curStep', curStep);
		setOnHaxes('curStep', curStep);

		callOnLuas('onStepHit', []);
		callOnHaxes('stepHit', []);
	}

	var lastBeatHit:Int = -1;
	
	var lightningStrikeBeat:Int = 0;
	var lightningOffset:Int = 8;
    override function beatHit()
    {
        super.beatHit();

        if(lastBeatHit >= curBeat) {
			return;
		}

		setOnLuas('curBeat', curBeat);
		setOnHaxes('curBeat', curBeat);

		callOnLuas('onBeatHit', []);
		callOnHaxes('beatHit', []);
    }

	override function destroy()
	{
		super.destroy();
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

	
	public function callOnLuas(event:String, args:Array<Dynamic>, ignoreStops = true, exclusions:Array<String> = null):Dynamic {
		var returnVal:Dynamic = FunkinLua.Function_Continue;
		#if LUA_ALLOWED
		if(exclusions == null) exclusions = [];
		for (script in luaArray) {
			if(exclusions.contains(script.scriptName))
				continue;

			var ret:Dynamic = script.call(event, args);
			if(ret == FunkinLua.Function_StopLua && !ignoreStops)
				break;
			
			// had to do this because there is a bug in haxe where Stop != Continue doesnt work
			var bool:Bool = ret == FunkinLua.Function_Continue;
			if(!bool && ret != 0) {
				returnVal = cast ret;
			}
		}
		#end
		//trace(event, returnVal);
		return returnVal;
	}

	public function callOnHaxes(event:String, args:Array<Dynamic>) {
		for (script in haxeArray) {
			script.call(event, args);
		}
	}

	public function setOnLuas(variable:String, arg:Dynamic) {
		#if LUA_ALLOWED
		for (i in 0...luaArray.length) {
			luaArray[i].set(variable, arg);
		}
		#end
	}

	public function setOnHaxes(variable:String, arg:Dynamic) {
		for (i in 0...haxeArray.length) {
			haxeArray[i].set(variable, arg);
		}
	}
}