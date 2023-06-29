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
import flixel.system.FlxSound;
import openfl.utils.Assets as OpenFlAssets;
import util.WeekDataAlt as WeekData;
import util.CoolUtil;
import meta.substate.GameplayChangersSubstate;
import objects.Alphabet;
import objects.HealthIcon;
import util.Highscore;
import util.Song;
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
	var lerpScore:Int = 0;
	var lerpRating:Float = 0;
	var intendedScore:Int = 0;
	var intendedRating:Float = 0;

	private var grpSongs:FlxTypedGroup<Alphabet>;
	private var curPlaying:Bool = false;

	private var iconArray:Array<HealthIcon> = [];

	var bg:FlxSprite;
	var intendedColor:Int;
	var colorTween:FlxTween;
	private var debugKeysChart:Array<FlxKey>;
	override function create()
	{
		debugKeysChart = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_1'));
		persistentUpdate = true;
		PlayState.isStoryMode = false;
        PlayState.isBETADCIU = false;
        PlayState.isCover = true;
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
		WeekData.loadTheFirstEnabledMod();

		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.antialiasing = ClientPrefs.globalAntialiasing;
		add(bg);
		bg.screenCenter();

		grpSongs = new FlxTypedGroup<Alphabet>();
		add(grpSongs);

		for (i in 0...songs.length)
		{
			var songText:Alphabet = new Alphabet(90, 320, songs[i].songName, true);
			songText.isMenuItem = true;
			songText.targetY = i - curSelected;
			grpSongs.add(songText);

			var maxWidth = 980;
			if (songText.width > maxWidth)
			{
				songText.scaleX = maxWidth / songText.width;
			}
			songText.snapToPosition();

			Paths.currentModDirectory = songs[i].folder;
			var icon:HealthIcon = new HealthIcon(songs[i].songCharacter);
			icon.sprTracker = songText;

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

		if(curSelected >= songs.length) curSelected = 0;
		bg.color = songs[curSelected].color;
		intendedColor = bg.color;

		if(lastDifficultyName == '')
		{
			lastDifficultyName = CoolUtil.defaultDifficulty;
		}
		curDifficulty = Math.round(Math.max(0, CoolUtil.defaultDifficulties.indexOf(lastDifficultyName)));
		
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
				Paths.currentModDirectory = songs[curSelected].folder;
				var poop:String = Highscore.formatSong(songs[curSelected].songName.toLowerCase(), curDifficulty);
				PlayState.SONG = Song.loadFromJson(poop, songs[curSelected].songName.toLowerCase());
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
        else if(FlxG.keys.anyJustPressed(debugKeysChart) || FlxG.keys.justPressed.SHIFT)
        {
            var songLowercase:String = Paths.formatToSongPath(songs[curSelected].songName);
			var poop:String = Highscore.formatSong(songLowercase, curDifficulty);
			trace(poop);

			PlayState.SONG = Song.loadFromJson(poop, songLowercase);
			PlayState.isStoryMode = false;
			PlayState.storyDifficulty = curDifficulty;

			trace('CURRENT WEEK: ' + WeekData.getWeekFileName());
			if(colorTween != null) {
				colorTween.cancel();
            }

            LoadingState.loadAndSwitchState(new ChartingState());

            FlxG.sound.music.volume = 0;
					
			destroyFreeplayVocals();
			FreeplayState.destroyFreeplayVocals();
			CoverState.destroyFreeplayVocals();
        }
		else if (accepted)
		{
			persistentUpdate = false;
			var songLowercase:String = Paths.formatToSongPath(songs[curSelected].songName);
			var poop:String = Highscore.formatSong(songLowercase, curDifficulty);
			trace(poop);

			PlayState.SONG = Song.loadFromJson(poop, songLowercase);
			PlayState.isStoryMode = false;
			PlayState.storyDifficulty = curDifficulty;
			LoadingState.loadAndSwitchState(new PlayState());
			trace('CURRENT WEEK: ' + WeekData.getWeekFileName());
			if(colorTween != null) {
				colorTween.cancel();
			}

			FlxG.sound.music.volume = 0;
					
			destroyFreeplayVocals();
			FreeplayState.destroyFreeplayVocals();
			CoverState.destroyFreeplayVocals();
		}
		else if(controls.RESET)
		{
			persistentUpdate = false;
			openSubState(new ResetScoreSubState(songs[curSelected].songName, curDifficulty, songs[curSelected].songCharacter));
			FlxG.sound.play(Paths.sound('scrollMenu'));
		}
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
			curDifficulty = CoolUtil.difficulties.length-1;
		if (curDifficulty >= CoolUtil.difficulties.length)
			curDifficulty = 0;

		lastDifficultyName = CoolUtil.difficulties[curDifficulty];

		#if !switch
		intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty);
		intendedRating = Highscore.getRating(songs[curSelected].songName, curDifficulty);
		#end

		PlayState.storyDifficulty = curDifficulty;
		diffText.text = '< ' + CoolUtil.difficultyString() + ' >';
		positionHighscore();
	}

	function changeSelection(change:Int = 0, playSound:Bool = true)
	{
		if(playSound) FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		curSelected += change;

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
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;
			// item.setGraphicSize(Std.int(item.width * 0.8));

			if (item.targetY == 0)
			{
				item.alpha = 1;
				// item.setGraphicSize(Std.int(item.width));
			}
		}
		
		Paths.currentModDirectory = songs[curSelected].folder;
		PlayState.storyWeek = songs[curSelected].week;

		CoolUtil.difficulties = CoolUtil.defaultDifficulties.copy();
		var diffStr:String = WeekData.getCurrentWeek().difficulties;
		if(diffStr != null) diffStr = diffStr.trim(); //Fuck you HTML5

		if(diffStr != null && diffStr.length > 0)
		{
			var diffs:Array<String> = diffStr.split(',');
			var i:Int = diffs.length - 1;
			while (i > 0)
			{
				if(diffs[i] != null)
				{
					diffs[i] = diffs[i].trim();
					if(diffs[i].length < 1) diffs.remove(diffs[i]);
				}
				--i;
			}

			if(diffs.length > 0 && diffs[0].length > 0)
			{
				CoolUtil.difficulties = diffs;
			}
		}
		
		if(CoolUtil.difficulties.contains(CoolUtil.defaultDifficulty))
		{
			curDifficulty = Math.round(Math.max(0, CoolUtil.defaultDifficulties.indexOf(CoolUtil.defaultDifficulty)));
		}
		else
		{
			curDifficulty = 0;
		}

		var newPos:Int = CoolUtil.difficulties.indexOf(lastDifficultyName);
		//trace('Pos of ' + lastDifficultyName + ' is ' + newPos);
		if(newPos > -1)
		{
			curDifficulty = newPos;
		}
	}

	private function positionHighscore() {
		scoreText.x = FlxG.width - scoreText.width - 6;

		scoreBG.scale.x = FlxG.width - scoreText.x + 6;
		scoreBG.x = FlxG.width - (scoreBG.scale.x / 2);
		diffText.x = Std.int(scoreBG.x + (scoreBG.width / 2));
		diffText.x -= diffText.width / 2;
	}
}