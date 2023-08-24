package meta.state.freeplay;

import MusicBeat;
#if desktop
import Discord.DiscordClient;
#end
import meta.state.editors.ChartingState;
import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import lime.utils.Assets;
#if (flixel >= "5.3.0")
import flixel.sound.FlxSound;
#else
import flixel.system.FlxSound;
#end
import openfl.utils.Assets as OpenFlAssets;
import util.WeekDataAlt as WeekData;
import util.CoolUtil;
import meta.substate.GameplayChangersSubstate;
import objects.Alphabet;
import objects.HealthIcon;
import util.Highscore;
import util.Song;
import util.Difficulty;
import util.Mods;
import meta.substate.ResetScoreSubState;
import flixel.input.keyboard.FlxKey;
import meta.state.freeplay.FreeplayState;
#if MODS_ALLOWED
import sys.FileSystem;
#end

using StringTools;

class BETADCIUState extends MusicBeatState
{
	var songs:Array<SongMetadata> = [];

	var selector:FlxText;
	private static var curSelected:Int = 0;
	var curDifficulty:Int = -1;
	private static var lastDifficultyName:String = '';

	var scoreBG:FlxSprite;
	var scoreText:FlxText;
	var diffText:FlxText;
	var lerpSelected:Float = 0;
	var lerpScore:Int = 0;
	var lerpRating:Float = 0;
	var intendedScore:Int = 0;
	var intendedRating:Float = 0;

	var missingTextBG:FlxSprite;
	var missingText:FlxText;

	private var grpSongs:FlxTypedGroup<Alphabet>;
	private var curPlaying:Bool = false;

	private var iconArray:Array<HealthIcon> = [];

	var bg:FlxSprite;
	var intendedColor:Int;
	var colorTween:FlxTween;
	override function create()
	{
		persistentUpdate = true;
		PlayState.isStoryMode = false;
        PlayState.isBETADCIU = true;
        PlayState.isCover = false;
		WeekData.reloadWeekFiles(false);

		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end

		for (i in 0...WeekData.weeksList.length) {
			if(weekIsLocked(WeekData.weeksList[i])) continue;

			var leWeek:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[i]);
			var leSongs:Array<String> = [];
			var leChars:Array<String> = [];

			for (j in 0...leWeek.songs.length)
			{
				leSongs.push(leWeek.songs[j][0]);
				leChars.push(leWeek.songs[j][1]);
			}

			WeekData.setDirectoryFromWeek(leWeek);
			for (song in leWeek.songs)
			{
				var colors:Array<Int> = song[2];
				if(colors == null || colors.length < 3)
				{
					colors = [146, 113, 253];
				}
				addSong(song[0], i, song[1], FlxColor.fromRGB(colors[0], colors[1], colors[2]));
			}
		}
		Mods.loadTheFirstEnabledMod();

		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.antialiasing = ClientPrefs.globalAntialiasing;
		add(bg);
		bg.screenCenter();

		grpSongs = new FlxTypedGroup<Alphabet>();
		add(grpSongs);

		for (i in 0...songs.length)
		{
			var songText:Alphabet = new Alphabet(90, 320, songs[i].songName, true);
			songText.targetY = i;
			grpSongs.add(songText);

			songText.scaleX = Math.min(1, 980 / songText.width);
			songText.snapToPosition();

			Mods.currentModDirectory = songs[i].folder;
			var icon:HealthIcon = new HealthIcon(songs[i].songCharacter);
			icon.sprTracker = songText;

			
			// too laggy with a lot of songs, so i had to recode the logic for it
			songText.visible = songText.active = songText.isMenuItem = false;
			icon.visible = icon.active = false;

			// using a FlxGroup is too much fuss!
			iconArray.push(icon);
			add(icon);
		}
		WeekData.setDirectoryFromWeek();

		scoreText = new FlxText(FlxG.width * 0.7, 5, 0, "", 32);
		scoreText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, RIGHT);

		scoreBG = new FlxSprite(scoreText.x - 6, 0).makeGraphic(1, 66, 0xFF000000);
		scoreBG.alpha = 0.6;
		add(scoreBG);

		diffText = new FlxText(scoreText.x, scoreText.y + 36, 0, "", 24);
		diffText.font = scoreText.font;
		add(diffText);

		add(scoreText);

		missingTextBG = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		missingTextBG.alpha = 0.6;
		missingTextBG.visible = false;
		add(missingTextBG);
		
		missingText = new FlxText(50, 0, FlxG.width - 100, '', 24);
		missingText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		missingText.scrollFactor.set();
		missingText.visible = false;
		add(missingText);

		if(curSelected >= songs.length) curSelected = 0;
		bg.color = songs[curSelected].color;
		intendedColor = bg.color;
		lerpSelected = curSelected;

		curDifficulty = Math.round(Math.max(0, Difficulty.defaultList.indexOf(lastDifficultyName)));
		
		changeSelection();
		changeDiff();

		var swag:Alphabet = new Alphabet(1, 0, "swag");

		var textBG:FlxSprite = new FlxSprite(0, FlxG.height - 26).makeGraphic(FlxG.width, 26, 0xFF000000);
		textBG.alpha = 0.6;
		add(textBG);

		#if PRELOAD_ALL
		var leText:String = "Press SPACE to listen to the Song / Press CTRL to open the Gameplay Changers Menu / Press RESET to Reset your Score and Accuracy.";
		var size:Int = 16;
		#else
		var leText:String = "Press CTRL to open the Gameplay Changers Menu / Press RESET to Reset your Score and Accuracy.";
		var size:Int = 18;
		#end
		var text:FlxText = new FlxText(textBG.x, textBG.y + 4, FlxG.width, leText, size);
		text.setFormat(Paths.font("vcr.ttf"), size, FlxColor.WHITE, RIGHT);
		text.scrollFactor.set();
		add(text);
		
		updateTexts();
		super.create();
	}

	override function closeSubState() {
		changeSelection(0, false);
		persistentUpdate = true;
		super.closeSubState();
	}

	public function addSong(songName:String, weekNum:Int, songCharacter:String, color:Int)
	{
		songs.push(new SongMetadata(songName, weekNum, songCharacter, color));
	}

	function weekIsLocked(name:String):Bool {
		var leWeek:WeekData = WeekData.weeksLoaded.get(name);
		return (!leWeek.startUnlocked && leWeek.weekBefore.length > 0 && (!StoryMenuState.weekCompleted.exists(leWeek.weekBefore) || !StoryMenuState.weekCompleted.get(leWeek.weekBefore)));
	}

	var instPlaying:Int = -1;
	public static var vocals:FlxSound = null;
	public static var vocalsDad:Array<FlxSound> = null;
	public static var vocalsBoyfriend:Array<FlxSound> = null;
	var holdTime:Float = 0;
	override function update(elapsed:Float)
	{
		if (FlxG.sound.music.volume < 0.7)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}

		lerpScore = Math.floor(FlxMath.lerp(lerpScore, intendedScore, CoolUtil.boundTo(elapsed * 24, 0, 1)));
		lerpRating = FlxMath.lerp(lerpRating, intendedRating, CoolUtil.boundTo(elapsed * 12, 0, 1));

		if (Math.abs(lerpScore - intendedScore) <= 10)
			lerpScore = intendedScore;
		if (Math.abs(lerpRating - intendedRating) <= 0.01)
			lerpRating = intendedRating;

		var ratingSplit:Array<String> = Std.string(Highscore.floorDecimal(lerpRating * 100, 2)).split('.');
		if(ratingSplit.length < 2) { //No decimals, add an empty space
			ratingSplit.push('');
		}
		
		while(ratingSplit[1].length < 2) { //Less than 2 decimals in it, add decimals then
			ratingSplit[1] += '0';
		}

		scoreText.text = 'PERSONAL BEST: ' + lerpScore + ' (' + ratingSplit.join('.') + '%)';
		positionHighscore();

		var upP = controls.UI_UP_P;
		var downP = controls.UI_DOWN_P;
		var accepted = controls.ACCEPT;
		var space = FlxG.keys.justPressed.SPACE;
		var ctrl = FlxG.keys.justPressed.CONTROL;

		var shiftMult:Int = 1;
		if(FlxG.keys.pressed.SHIFT) shiftMult = 3;

		if(songs.length > 1)
		{
			if (upP)
			{
				changeSelection(-shiftMult);
				holdTime = 0;
			}
			if (downP)
			{
				changeSelection(shiftMult);
				holdTime = 0;
			}

			if(controls.UI_DOWN || controls.UI_UP)
			{
				var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
				holdTime += elapsed;
				var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);

				if(holdTime > 0.5 && checkNewHold - checkLastHold > 0)
				{
					changeSelection((checkNewHold - checkLastHold) * (controls.UI_UP ? -shiftMult : shiftMult));
					changeDiff();
				}
			}

			if(FlxG.mouse.wheel != 0)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.2);
				changeSelection(-shiftMult * FlxG.mouse.wheel, false);
				changeDiff();
			}
		}

		if (controls.UI_LEFT_P)
			changeDiff(-1);
		else if (controls.UI_RIGHT_P)
			changeDiff(1);
		else if (upP || downP) changeDiff();

		if (controls.BACK)
		{
			persistentUpdate = false;
			if(colorTween != null) {
				colorTween.cancel();
			}
			FlxG.sound.play(Paths.sound('cancelMenu'));
			MusicBeatState.switchState(new FreeplayMenu());
		}

		if(ctrl)
		{
			persistentUpdate = false;
			openSubState(new GameplayChangersSubstate());
		}
		else if(space)
		{
			if(instPlaying != curSelected)
			{
				#if PRELOAD_ALL
				destroyFreeplayVocals();
				vocalsDad = [];
				vocalsBoyfriend = [];
				CoverState.destroyFreeplayVocals();
				BETADCIUState.destroyFreeplayVocals();
				FlxG.sound.music.volume = 0;
				Mods.currentModDirectory = songs[curSelected].folder;
				var poop:String = Highscore.formatSong(songs[curSelected].songName.toLowerCase(), curDifficulty);
				try
				{
					PlayState.SONG = Song.loadFromJson(poop, songs[curSelected].songName.toLowerCase());
				}
				catch(e:Dynamic)
				{
					trace('ERROR! $e');
		
					var errorStr:String = e.toString();
					if(errorStr.startsWith('[file_contents,assets/data/')) errorStr = 'Missing file: ' + errorStr.substring(27, errorStr.length-1); //Missing chart
					missingText.text = 'ERROR WHILE LOADING CHART:\n$errorStr';
					missingText.screenCenter(Y);
					missingText.visible = true;
					missingTextBG.visible = true;
					FlxG.sound.play(Paths.sound('cancelMenu'));
		
					updateTexts(elapsed);
					super.update(elapsed);
					return;
				}

				if (PlayState.SONG.needsVoices)
				{
					var songKeyDad:String = '${Paths.formatToSongPath(PlayState.SONG.song)}/Voices' + PlayState.SONG.player2.toUpperCase();
					var songKeyBF:String = '${Paths.formatToSongPath(PlayState.SONG.song)}/Voices' + PlayState.SONG.player1.toUpperCase();
					var songKeyGF:String = '${Paths.formatToSongPath(PlayState.SONG.song)}/Voices' + PlayState.SONG.gfVersion.toUpperCase();
		
					var songKeyDadNormal:String = '${Paths.formatToSongPath(PlayState.SONG.song)}/VoicesDAD';
					var songKeyBFNormal:String = '${Paths.formatToSongPath(PlayState.SONG.song)}/VoicesBF';
					var songKeyGFNormal:String = '${Paths.formatToSongPath(PlayState.SONG.song)}/VoicesGF';
					var songKeyMOMNormal:String = '${Paths.formatToSongPath(PlayState.SONG.song)}/VoicesMOM';

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
						vocalsDad.push(new FlxSound());
						vocalsBoyfriend.push(new FlxSound());
						vocals = new FlxSound().loadEmbedded(Paths.voices(PlayState.SONG.song));
					}
				}
				else
				{
					vocalsDad.push(new FlxSound());
					vocalsBoyfriend.push(new FlxSound());
					vocals = new FlxSound();
				}

				if(vocalsBoyfriend != null)
				{
					for(boyfriend in vocalsBoyfriend)
					{
						FlxG.sound.list.add(boyfriend);
						boyfriend.play();
						boyfriend.persist = true;
						boyfriend.looped = true;
						boyfriend.volume = 0.7;
					}
				}
			
				if(vocalsDad != null)
				{
					for(dad in vocalsDad)
					{
						FlxG.sound.list.add(dad);
						dad.play();
						dad.persist = true;
						dad.looped = true;
						dad.volume = 0.7;
					}
				}
						
				if(vocals != null)
				{
					FlxG.sound.list.add(vocals);
					vocals.play();
					vocals.persist = true;
					vocals.looped = true;
					vocals.volume = 0.7;
				}
				FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song), 0.7);

				instPlaying = curSelected;
				#end
			}
		}
        else if(controls.justPressed('debug_1') || FlxG.keys.justPressed.SHIFT)
        {
            var songLowercase:String = Paths.formatToSongPath(songs[curSelected].songName);
			var poop:String = Highscore.formatSong(songLowercase, curDifficulty);
			trace(poop);

			try
			{
				PlayState.SONG = Song.loadFromJson(poop, songLowercase);
				PlayState.isStoryMode = false;
				PlayState.storyDifficulty = curDifficulty;
				if(colorTween != null) {
					colorTween.cancel();
				}
			}
			catch(e:Dynamic)
			{
				trace('ERROR! $e');

				var errorStr:String = e.toString();
				if(errorStr.startsWith('[file_contents,assets/data/')) errorStr = 'Missing file: ' + errorStr.substring(27, errorStr.length-1); //Missing chart
				missingText.text = 'ERROR WHILE LOADING CHART:\n$errorStr';
				missingText.screenCenter(Y);
				missingText.visible = true;
				missingTextBG.visible = true;
				FlxG.sound.play(Paths.sound('cancelMenu'));

				updateTexts(elapsed);
				super.update(elapsed);
				return;
			}

			trace('CURRENT WEEK: ' + WeekData.getWeekFileName());
			if(colorTween != null) {
				colorTween.cancel();
            }

            LoadingState.loadAndSwitchState(new ChartingState());

            FlxG.sound.music.volume = 0;
					
			destroyFreeplayVocals();
			FreeplayState.destroyFreeplayVocals();
			CoverState.destroyFreeplayVocals();

			#if MODS_ALLOWED
			DiscordClient.loadModRPC();
			#end
        }
		else if (accepted)
		{
			persistentUpdate = false;
			var songLowercase:String = Paths.formatToSongPath(songs[curSelected].songName);
			var poop:String = Highscore.formatSong(songLowercase, curDifficulty);
			trace(poop);

			try
			{
				PlayState.SONG = Song.loadFromJson(poop, songLowercase);
				PlayState.isStoryMode = false;
				PlayState.storyDifficulty = curDifficulty;
				if(colorTween != null) {
					colorTween.cancel();
				}
			}
			catch(e:Dynamic)
			{
				trace('ERROR! $e');

				var errorStr:String = e.toString();
				if(errorStr.startsWith('[file_contents,assets/data/')) errorStr = 'Missing file: ' + errorStr.substring(27, errorStr.length-1); //Missing chart
				missingText.text = 'ERROR WHILE LOADING CHART:\n$errorStr';
				missingText.screenCenter(Y);
				missingText.visible = true;
				missingTextBG.visible = true;
				FlxG.sound.play(Paths.sound('cancelMenu'));

				updateTexts(elapsed);
				super.update(elapsed);
				return;
			}

			LoadingState.loadAndSwitchState(new PlayState());
			trace('CURRENT WEEK: ' + WeekData.getWeekFileName());
			if(colorTween != null) {
				colorTween.cancel();
			}

			FlxG.sound.music.volume = 0;
					
			destroyFreeplayVocals();
			FreeplayState.destroyFreeplayVocals();
			CoverState.destroyFreeplayVocals();

			#if MODS_ALLOWED
			DiscordClient.loadModRPC();
			#end
		}
		else if(controls.RESET)
		{
			persistentUpdate = false;
			openSubState(new ResetScoreSubState(songs[curSelected].songName, curDifficulty, songs[curSelected].songCharacter));
			FlxG.sound.play(Paths.sound('scrollMenu'));
		}
		updateTexts(elapsed);
		super.update(elapsed);
	}

	public static function destroyFreeplayVocals() {
		if(vocals != null) {
			vocals.stop();
			vocals.destroy();
		}
		vocals = null;

		if(vocalsBoyfriend != null)
		{
			for(boyfriend in vocalsBoyfriend)
			{
				if(boyfriend != null) {
					boyfriend.stop();
					boyfriend.destroy();
				}
				boyfriend = null;
			}
		}
		
		if(vocalsDad != null)
		{
			for(dad in vocalsDad)
			{
				if(dad != null) {
					dad.stop();
					dad.destroy();
				}
				dad = null;
			}
		}
	}

	function changeDiff(change:Int = 0)
	{
		curDifficulty += change;

		if (curDifficulty < 0)
			curDifficulty = Difficulty.list.length-1;
		if (curDifficulty >= Difficulty.list.length)
			curDifficulty = 0;

		lastDifficultyName = Difficulty.getString(curDifficulty);
		updateSongLastDifficulty();

		#if !switch
		intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty);
		intendedRating = Highscore.getRating(songs[curSelected].songName, curDifficulty);
		#end

		PlayState.storyDifficulty = curDifficulty;
		lastDifficultyName = Difficulty.getString(curDifficulty);
		if (Difficulty.list.length > 1)
			diffText.text = '< ' + lastDifficultyName.toUpperCase() + ' >';
		else
			diffText.text = lastDifficultyName.toUpperCase();
		positionHighscore();
	}

	function changeSelection(change:Int = 0, playSound:Bool = true)
	{
		updateSongLastDifficulty();
		if(playSound) FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		curSelected += change;
		var lastList:Array<String> = Difficulty.list;
		
		if (curSelected < 0)
			curSelected = songs.length - 1;
		if (curSelected >= songs.length)
			curSelected = 0;
			
		var newColor:Int = songs[curSelected].color;
		if(newColor != intendedColor) {
			if(colorTween != null) {
				colorTween.cancel();
			}
			intendedColor = newColor;
			colorTween = FlxTween.color(bg, 1, bg.color, intendedColor, {
				onComplete: function(twn:FlxTween) {
					colorTween = null;
				}
			});
		}

		// selector.y = (70 * curSelected) + 30;

		#if !switch
		intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty);
		intendedRating = Highscore.getRating(songs[curSelected].songName, curDifficulty);
		#end

		var bullShit:Int = 0;

		for (i in 0...iconArray.length)
		{
			iconArray[i].alpha = 0.6;
		}

		iconArray[curSelected].alpha = 1;

		for (item in grpSongs.members)
		{
			bullShit++;
			item.alpha = 0.6;
			if (item.targetY == curSelected)
				item.alpha = 1;
		}
		
		Mods.currentModDirectory = songs[curSelected].folder;
		PlayState.storyWeek = songs[curSelected].week;

		Difficulty.loadFromWeekAlt();
		
		var savedDiff:String = songs[curSelected].lastDifficulty;
		var lastDiff:Int = Difficulty.list.indexOf(lastDifficultyName);
		if(savedDiff != null && !lastList.contains(savedDiff) && Difficulty.list.contains(savedDiff))
			curDifficulty = Math.round(Math.max(0, Difficulty.list.indexOf(savedDiff)));
		else if(lastDiff > -1)
			curDifficulty = lastDiff;
		else if(Difficulty.list.contains(Difficulty.getDefault()))
			curDifficulty = Math.round(Math.max(0, Difficulty.defaultList.indexOf(Difficulty.getDefault())));
		else
		{
			curDifficulty = 0;
		}

		changeDiff();
		updateSongLastDifficulty();
	}

	inline private function updateSongLastDifficulty()
	{
		songs[curSelected].lastDifficulty = Difficulty.getString(curDifficulty);
	}

	private function positionHighscore() {
		scoreText.x = FlxG.width - scoreText.width - 6;

		scoreBG.scale.x = FlxG.width - scoreText.x + 6;
		scoreBG.x = FlxG.width - (scoreBG.scale.x / 2);
		diffText.x = Std.int(scoreBG.x + (scoreBG.width / 2));
		diffText.x -= diffText.width / 2;
	}

	var _drawDistance:Int = 4;
	var _lastVisibles:Array<Int> = [];
	public function updateTexts(elapsed:Float = 0.0)
	{
		lerpSelected = FlxMath.lerp(lerpSelected, curSelected, FlxMath.bound(elapsed * 9.6, 0, 1));
		for (i in _lastVisibles)
		{
			grpSongs.members[i].visible = grpSongs.members[i].active = false;
			iconArray[i].visible = iconArray[i].active = false;
		}
		_lastVisibles = [];

		var min:Int = Math.round(Math.max(0, Math.min(songs.length, lerpSelected - _drawDistance)));
		var max:Int = Math.round(Math.max(0, Math.min(songs.length, lerpSelected + _drawDistance)));
		for (i in min...max)
		{
			var item:Alphabet = grpSongs.members[i];
			item.visible = item.active = true;
			item.x = ((item.targetY - lerpSelected) * item.distancePerItem.x) + item.startPosition.x;
			item.y = ((item.targetY - lerpSelected) * 1.3 * item.distancePerItem.y) + item.startPosition.y;

			var icon:HealthIcon = iconArray[i];
			icon.visible = icon.active = true;
			_lastVisibles.push(i);
		}
	}
}