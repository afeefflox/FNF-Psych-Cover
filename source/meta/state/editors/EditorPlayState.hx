package meta.state.editors;

import MusicBeat.MusicBeatSubstate;
import util.Song;
import util.Section;
import util.Conductor.Rating;
import util.Conductor;

import objects.Note;
import objects.NoteSplash;
import StrumNote;

import flixel.util.FlxSort;
import flixel.util.FlxStringUtil;
import flixel.animation.FlxAnimationController;
import flixel.input.keyboard.FlxKey;
import openfl.events.KeyboardEvent;
import meta.state.PlayState;
import flixel.util.FlxTimer;

#if sys
import sys.FileSystem;
#end

class EditorPlayState extends MusicBeatSubstate
{
	// Borrowed from original PlayState
	var finishTimer:FlxTimer = null;
	var noteKillOffset:Float = 350;
	var spawnTime:Float = 2000;
	var startingSong:Bool = true;

	var playbackRate:Float = 1;
	var vocals:FlxSound;
	var inst:FlxSound;

	var vocalsDad:Array<FlxSound> = [];
	var vocalsBoyfriend:Array<FlxSound> = [];
	
	var notes:FlxTypedGroup<Note>;
	var fakeNotes:FlxTypedGroup<Note>;

	var unspawnNotes:Array<Note> = [];
	var unspawnFakeNotes:Array<Note> = [];

	var ratingsData:Array<Rating> = [];
	
	var strumLineNotes:FlxTypedGroup<StrumNote>;
	var fakeStrumLineNotes:FlxTypedGroup<StrumNote>;

	var opponentStrums:StrumLineEditorNote;
	var playerStrums:StrumLineEditorNote;
	var opponentFakeStrums:StrumLineEditorNote;
	var playerFakeStrums:StrumLineEditorNote;

	var grpNoteSplashes:FlxTypedGroup<NoteSplash>;
	
	var combo:Int = 0;
	var lastRating:FlxSprite;
	var lastCombo:FlxSprite;
	var lastScore:Array<FlxSprite> = [];
	var keysArray:Array<String> = [
		'note_left',
		'note_down',
		'note_up',
		'note_right'
	];
	
	var songHits:Int = 0;
	var songMisses:Int = 0;
	var songLength:Float = 0;
	var songSpeed:Float = 1;
	
	var totalPlayed:Int = 0;
	var totalNotesHit:Float = 0.0;
	var ratingPercent:Float;
	var ratingFC:String;
	
	var showCombo:Bool = false;
	var showComboNum:Bool = true;
	var showRating:Bool = true;

	// Originals
	var startOffset:Float = 0;
	var startPos:Float = 0;
	var timerToStart:Float = 0;

	var scoreTxt:FlxText;
	var dataTxt:FlxText;
	public function new(playbackRate:Float)
	{
		super();

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
		
		/* setting up some important data */
		this.playbackRate = playbackRate;
		this.startPos = Conductor.songPosition;

		Conductor.safeZoneOffset = (ClientPrefs.safeFrames / 60) * 1000 * playbackRate;
		Conductor.songPosition -= startOffset;
		startOffset = Conductor.crochet;
		timerToStart = startOffset;
		
		/* borrowed from PlayState */
		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		cachePopUpScore();
		if(ClientPrefs.hitsoundVolume > 0) Paths.sound('hitsound');

		/* setting up Editor PlayState stuff */
		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.scrollFactor.set();
		bg.color = 0xFF101010;
		bg.alpha = 0.9;
		add(bg);
		
		/**** NOTES ****/
		fakeStrumLineNotes = new FlxTypedGroup<StrumNote>();
		add(fakeStrumLineNotes);

		strumLineNotes = new FlxTypedGroup<StrumNote>();
		add(strumLineNotes);

		grpNoteSplashes = new FlxTypedGroup<NoteSplash>();
		add(grpNoteSplashes);
		
		var splash:NoteSplash = new NoteSplash(100, 100);
		grpNoteSplashes.add(splash);
		splash.alpha = 0.000001; //cant make it invisible or it won't allow precaching

		opponentStrums = new StrumLineEditorNote(true);
		playerStrums = new StrumLineEditorNote();

		opponentFakeStrums = new StrumLineEditorNote(true);
		playerFakeStrums = new StrumLineEditorNote(true);
		generateStaticFakeArrows(0);
		generateStaticFakeArrows(1);

		generateStaticArrows(0);
		generateStaticArrows(1);
		/***************/
		
		scoreTxt = new FlxText(10, FlxG.height - 50, FlxG.width - 20, "", 20);
		scoreTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scoreTxt.scrollFactor.set();
		scoreTxt.borderSize = 1.25;
		scoreTxt.visible = !ClientPrefs.hideHud;
		add(scoreTxt);
		
		dataTxt = new FlxText(10, 580, FlxG.width - 20, "Section: 0", 20);
		dataTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		dataTxt.scrollFactor.set();
		dataTxt.borderSize = 1.25;
		add(dataTxt);

		var tipText:FlxText = new FlxText(10, FlxG.height - 24, 0, 'Press ESC to Go Back to Chart Editor', 16);
		tipText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		tipText.borderSize = 2;
		tipText.scrollFactor.set();
		add(tipText);
		FlxG.mouse.visible = false;
		
		generateSong(PlayState.SONG.song);

		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
		FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		
		#if desktop
		// Updating Discord Rich Presence (with Time Left)
		DiscordClient.changePresence('Playtesting on Chart Editor', PlayState.SONG.song, null, true, songLength);
		#end
		RecalculateRating();
	}

	override function update(elapsed:Float)
	{
		if(controls.BACK || FlxG.keys.justPressed.ESCAPE)
		{
			endSong();
			super.update(elapsed);
			return;
		}
		
		if (startingSong)
		{
			timerToStart -= elapsed * 1000;
			Conductor.songPosition = startPos - timerToStart;
			if(timerToStart < 0) startSong();
		}
		else Conductor.songPosition += elapsed * 1000;

		if (unspawnNotes[0] != null)
		{
			var time:Float = spawnTime * playbackRate;
			if(songSpeed < 1) time /= songSpeed;
			if(unspawnNotes[0].multSpeed < 1) time /= unspawnNotes[0].multSpeed;

			while (unspawnNotes.length > 0 && unspawnNotes[0].strumTime - Conductor.songPosition < time)
			{
				var dunceNote:Note = unspawnNotes[0];
				notes.insert(0, dunceNote);
				dunceNote.spawned = true;

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
				notes.insert(0, dunceNote);
				dunceNote.spawned = true;

				var index:Int = unspawnFakeNotes.indexOf(dunceNote);
				unspawnFakeNotes.splice(index, 1);
			}
		}

		if(notes.length > 0)
		{
			var fakeCrochet:Float = (60 / PlayState.SONG.bpm) * 1000;
			notes.forEachAlive(function(daNote:Note)
			{
				var strumGroup:StrumLineEditorNote = playerStrums;
				if(!daNote.mustPress) strumGroup = opponentStrums;

				var strum:StrumNote = strumGroup.members[daNote.noteData];
				daNote.followStrumNote(strum, fakeCrochet, songSpeed / playbackRate);

			    if(daNote.isSustainNote && strum.sustainReduce) daNote.clipToStrumNote(strum);

				mainControls(daNote, strumGroup);

				if (Conductor.songPosition - daNote.strumTime > noteKillOffset)
				{
					if (!strumGroup.autoplay && !daNote.ignoreNote && (daNote.tooLate || !daNote.wasGoodHit)) {
						noteMiss(daNote);
					}
	
					daNote.active = false;
					daNote.visible = false;
	
					daNote.kill();
					notes.remove(daNote, true);
					daNote.destroy();
				}
			});
		}

		if(fakeNotes.length > 0)
		{
			var fakeCrochet:Float = (60 / PlayState.SONG.bpm) * 1000;
			fakeNotes.forEachAlive(function(daNote:Note)
			{
				var strumGroup:StrumLineEditorNote = playerFakeStrums;
				if(!daNote.mustPress) strumGroup = opponentFakeStrums;

				var strum:StrumNote = strumGroup.members[daNote.noteData];
				daNote.followStrumNote(strum, fakeCrochet, songSpeed / playbackRate);

				mainFakeControls(daNote, strumGroup);

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
		
		var time:Float = Highscore.floorDecimal((Conductor.songPosition - ClientPrefs.noteOffset) / 1000, 1);
		dataTxt.text = 'Time: $time / ${songLength/1000}\nSection: $curSection\nBeat: $curBeat\nStep: $curStep';
		super.update(elapsed);
	}

	private function mainFakeControls(daNote:Note, strumline:StrumLineEditorNote):Void
	{
		if (strumline.autoplay)
		{
			if(!daNote.blockHit && daNote.canBeHit) {
				if(daNote.isSustainNote) {
					if(daNote.canBeHit) {
						fakeGoodNoteHit(daNote, strumline);
					}
				} else if(daNote.strumTime <= Conductor.songPosition || daNote.isSustainNote) {
					fakeGoodNoteHit(daNote, strumline);
				}
			}
		}
	}

	private function mainControls(daNote:Note, strumline:StrumLineEditorNote):Void
	{
		if (strumline.autoplay)
		{
			if(!daNote.blockHit && daNote.canBeHit) {
				if(daNote.isSustainNote) {
					if(daNote.canBeHit) {
						goodNoteHit(daNote, strumline);
					}
				} else if(daNote.strumTime <= Conductor.songPosition || daNote.isSustainNote) {
					goodNoteHit(daNote, strumline);
				}
			}
		}
		else
		{
			keysCheck();
		}
	}
	
	var lastStepHit:Int = -1;
	override function stepHit()
	{
		if(vocals != null)
		{
			if (Math.abs(FlxG.sound.music.time - (Conductor.songPosition - Conductor.offset)) > (20 * playbackRate)
				|| (PlayState.SONG.needsVoices && Math.abs(vocals.time - (Conductor.songPosition - Conductor.offset)) > (20 * playbackRate)))
			{
				resyncVocals();
			}
		}


		if(vocalsBoyfriend != null)
		{
			for(boyfriend in vocalsBoyfriend)
			{
				if (Math.abs(FlxG.sound.music.time - (Conductor.songPosition - Conductor.offset)) > (20 * playbackRate)
					|| (PlayState.SONG.needsVoices && Math.abs(boyfriend.time - (Conductor.songPosition - Conductor.offset)) > (20 * playbackRate)))
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
					|| (PlayState.SONG.needsVoices && Math.abs(dad.time - (Conductor.songPosition - Conductor.offset)) > (20 * playbackRate)))
				{
					resyncVocals();
				}
			}
		}

		super.stepHit();

		if(curStep == lastStepHit) {
			return;
		}
		lastStepHit = curStep;
	}

	var lastBeatHit:Int = -1;
	override function beatHit()
	{
		if(lastBeatHit >= curBeat) {
			//trace('BEAT HIT: ' + curBeat + ', LAST HIT: ' + lastBeatHit);
			return;
		}
		notes.sort(FlxSort.byY, ClientPrefs.downScroll ? FlxSort.ASCENDING : FlxSort.DESCENDING);

		super.beatHit();
		lastBeatHit = curBeat;
	}
	
	override function sectionHit()
	{
		if (PlayState.SONG.notes[curSection] != null)
		{
			if (PlayState.SONG.notes[curSection].changeBPM)
				Conductor.bpm = PlayState.SONG.notes[curSection].bpm;
		}
		super.sectionHit();
	}

	override function destroy()
	{
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		FlxG.mouse.visible = true;
		super.destroy();
	}
	
	function startSong():Void
	{
		startingSong = false;
		@:privateAccess
		FlxG.sound.playMusic(inst._sound, 1, false);
		FlxG.sound.music.time = startPos;
		FlxG.sound.music.pitch = playbackRate;
		FlxG.sound.music.onComplete = finishSong;
		if(vocals != null)
		{
			vocals.volume = 1;
			vocals.time = startPos;
			vocals.play();
		}
		

		if(vocalsBoyfriend != null)
		{
			for(boyfriend in vocalsBoyfriend)
			{
				boyfriend.volume = 1;
				boyfriend.time = startPos;
				boyfriend.play();
			}
		}

		if(vocalsDad != null)
		{
			for(dad in vocalsDad)
			{
				dad.volume = 1;
				dad.time = startPos;
				dad.play();
			}
		}

		// Song duration in a float, useful for the time left feature
		songLength = FlxG.sound.music.length;
	}

	// Borrowed from PlayState
	function generateSong(dataPath:String)
	{
		// FlxG.log.add(ChartParser.parse());
		songSpeed = PlayState.SONG.speed;
		var songSpeedType:String = ClientPrefs.getGameplaySetting('scrolltype');
		switch(songSpeedType)
		{
			case "multiplicative":
				songSpeed = PlayState.SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed');
			case "constant":
				songSpeed = ClientPrefs.getGameplaySetting('scrollspeed');
		}
		noteKillOffset = Math.max(Conductor.stepCrochet, 350 / songSpeed * playbackRate);

		var songData = PlayState.SONG;
		Conductor.bpm = songData.bpm;

		var songINSTKeyNormal:String = '${Paths.formatToSongPath(songData.song)}/Inst';
		var songINSTExtraKeyNormal:String = '${Paths.formatToSongPath(songData.song)}/Inst' + Difficulty.getString();

		if (songData.needsVoices)
		{
			//Wow Funkelion Moment I think Monika outdated exe already made lol
			var songKeyDad:String = '${Paths.formatToSongPath(songData.song)}/Voices' + songData.player2.toUpperCase();
			var songKeyBF:String = '${Paths.formatToSongPath(songData.song)}/Voices' + songData.player1.toUpperCase();
			var songKeyGF:String = '${Paths.formatToSongPath(songData.song)}/Voices' + songData.gfVersion.toUpperCase();

			var songKeyDadNormal:String = '${Paths.formatToSongPath(songData.song)}/VoicesDAD';
			var songKeyBFNormal:String = '${Paths.formatToSongPath(songData.song)}/VoicesBF';
			var songKeyGFNormal:String = '${Paths.formatToSongPath(songData.song)}/VoicesGF';
			var songKeyMOMNormal:String = '${Paths.formatToSongPath(songData.song)}/VoicesMOM';
			var songKeyNormal:String = '${Paths.formatToSongPath(songData.song)}/Voices';
			var songKeyExtraNormal:String = '${Paths.formatToSongPath(songData.song)}/Voices' + Difficulty.getString();

	
			//EXTRA
			var songKeyExtraDad:String = '${Paths.formatToSongPath(songData.song)}/' + Difficulty.getString() + '/Voices' + songData.player2.toUpperCase();
			var songKeyExtraBF:String = '${Paths.formatToSongPath(songData.song)}/' + Difficulty.getString() + '/Voices' + songData.player1.toUpperCase();
			var songKeyExtraGF:String = '${Paths.formatToSongPath(songData.song)}/' + Difficulty.getString() + '/Voices' + songData.gfVersion.toUpperCase();

			var songKeyExtraDadNormal:String = '${Paths.formatToSongPath(songData.song)}/' + Difficulty.getString() + '/VoicesDAD';
			var songKeyExtraBFNormal:String = '${Paths.formatToSongPath(songData.song)}/' + Difficulty.getString() + '/VoicesBF';
			var songKeyExtraGFNormal:String = '${Paths.formatToSongPath(songData.song)}/' + Difficulty.getString() + '/VoicesGF';
			var songKeyExtraMOMNormal:String = '${Paths.formatToSongPath(songData.song)}/' + Difficulty.getString() + '/VoicesMOM';


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
			else if(Paths.fileExists(songKeyNormal + '.' + Paths.SOUND_EXT, SOUND, false, 'songs'))
			{
				vocals = new FlxSound().loadEmbedded(Paths.voices(songData.song));
			}
			else
			{
				vocals = new FlxSound();
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


		if(Paths.fileExists(songINSTExtraKeyNormal + '.' + Paths.SOUND_EXT, SOUND, false, 'songs')) //WOW Inst Difficulty
			inst = new FlxSound().loadEmbedded(Paths.returnSound('songs', songINSTExtraKeyNormal));
		else if(Paths.fileExists(songINSTKeyNormal + '.' + Paths.SOUND_EXT, SOUND, false, 'songs'))
			inst = new FlxSound().loadEmbedded(Paths.inst(songData.song));
		else
			inst = new FlxSound(); //empty...


		FlxG.sound.list.add(inst);
		FlxG.sound.music.volume = 0;

		fakeNotes = new FlxTypedGroup<Note>();
		add(fakeNotes);

		notes = new FlxTypedGroup<Note>();
		add(notes);

		var noteData:Array<SwagSection>;
		var rmtjData:Array<SwagSection> = null;

		var songName:String = Paths.formatToSongPath(songData.song);
		var songOther:String = Paths.json(songName + '/$songName-other');
		#if MODS_ALLOWED
		if (FileSystem.exists(Paths.modsJson(songName + '/$songName-other')) || FileSystem.exists(songOther)) {
		#else
		if (OpenFlAssets.exists(songOther)) {
		#end
		    rmtjData = Song.loadFromJson(songName + '-other', songName).notes;
		}

		if(rmtjData != null)
		{
			for (section in rmtjData)
			{
				for (songNotes in section.sectionNotes)
				{
					var daStrumTime:Float = songNotes[0];
					if(daStrumTime < startPos) continue;
	
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
					swagNote.mustPress = gottaHitNote;
					swagNote.sustainLength = songNotes[2];
					swagNote.gfNote = (section.gfSection && (songNotes[1]<4));
					swagNote.noteType = songNotes[3];
					if(!Std.isOfType(songNotes[3], String)) swagNote.noteType = ChartingState.noteTypeList[songNotes[3]]; //Backward compatibility + compatibility with Week 7 charts
	
					swagNote.scrollFactor.set();
	
					var susLength:Float = swagNote.sustainLength;
	
					susLength = susLength / Conductor.stepCrochet;
					unspawnFakeNotes.push(swagNote);
	
					var floorSus:Int = Math.floor(susLength);
					if(floorSus > 0) {
						for (susNote in 0...floorSus+1)
						{
							oldNote = unspawnFakeNotes[Std.int(unspawnFakeNotes.length - 1)];
	
							var sustainNote:Note = new Note(daStrumTime + (Conductor.stepCrochet * susNote), daNoteData, oldNote, true);
							sustainNote.mustPress = gottaHitNote;
							sustainNote.gfNote = (section.gfSection && (songNotes[1]<4));
							sustainNote.noteType = swagNote.noteType;
							sustainNote.scrollFactor.set();
							swagNote.tail.push(sustainNote);
							sustainNote.parent = swagNote;
							unspawnFakeNotes.push(sustainNote);

							sustainNote.correctionOffset = swagNote.height / 2;
							if(sustainNote.style != 'pixel')
							{
								if(oldNote.isSustainNote)
								{
									oldNote.scale.y *= Note.SUSTAIN_SIZE / oldNote.frameHeight;
									oldNote.updateHitbox();
								}
				
								if(ClientPrefs.downScroll)
									sustainNote.correctionOffset = 0;
							}
		
							if(oldNote.isSustainNote)
							{
								oldNote.scale.y /= playbackRate;
								oldNote.updateHitbox();
							}
						
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
				}
			}
		}





		// NEW SHIT
		noteData = songData.notes;
		for (section in noteData)
		{
			for (songNotes in section.sectionNotes)
			{
				var daStrumTime:Float = songNotes[0];
				if(daStrumTime < startPos) continue;

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
				swagNote.mustPress = gottaHitNote;
				swagNote.sustainLength = songNotes[2];
				swagNote.gfNote = (section.gfSection && (songNotes[1]<4));
				swagNote.noteType = songNotes[3];
				if(!Std.isOfType(songNotes[3], String)) swagNote.noteType = ChartingState.noteTypeList[songNotes[3]]; //Backward compatibility + compatibility with Week 7 charts

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
						sustainNote.gfNote = (section.gfSection && (songNotes[1]<4));
						sustainNote.noteType = swagNote.noteType;
						sustainNote.scrollFactor.set();
						swagNote.tail.push(sustainNote);
						sustainNote.parent = swagNote;
						unspawnNotes.push(sustainNote);

						sustainNote.correctionOffset = swagNote.height / 2;
						if(sustainNote.style != 'pixel')
						{
							if(oldNote.isSustainNote)
							{
								oldNote.scale.y *= Note.SUSTAIN_SIZE / oldNote.frameHeight;
								oldNote.updateHitbox();
							}
				
							if(ClientPrefs.downScroll)
								sustainNote.correctionOffset = 0;
						}
		
						if(oldNote.isSustainNote)
						{
							oldNote.scale.y /= playbackRate;
							oldNote.updateHitbox();
						}

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
			}
		}

		unspawnNotes.sort(PlayState.sortByTime);
	}
	
	private function generateStaticArrows(player:Int):Void
	{
		var strumLineX:Float = ClientPrefs.middleScroll ? PlayState.STRUM_X_MIDDLESCROLL : PlayState.STRUM_X;
		var strumLineY:Float = ClientPrefs.downScroll ? (FlxG.height - 150) : 50;

		for (i in 0...4)
		{
			var targetAlpha:Float = 1;
			var babyArrow:StrumNote = new StrumNote(strumLineX, strumLineY, i, player);
			babyArrow.downScroll = ClientPrefs.downScroll;
			babyArrow.alpha = targetAlpha;

			switch(player)
			{
				default:
					if(ClientPrefs.middleScroll)
					{
						babyArrow.x += 310;
						if(i > 1) { //Up and Right
							babyArrow.x += FlxG.width / 2 + 25;
						}
					}
					opponentStrums.add(babyArrow);
				case 1:
					playerStrums.add(babyArrow);
			}

			strumLineNotes.add(babyArrow);
			babyArrow.postAddedToGroup();			
		}
	}



	private function generateStaticFakeArrows(player:Int):Void
	{
		var strumLineX:Float = ClientPrefs.middleScroll ? PlayState.STRUM_X_MIDDLESCROLL : PlayState.STRUM_X;
		var strumLineY:Float = ClientPrefs.downScroll ? (FlxG.height - 150) : 50;

		for (i in 0...4)
		{
			var targetAlpha:Float = 0;
			var babyArrow:StrumNote = new StrumNote(strumLineX, strumLineY, i, player);
			babyArrow.downScroll = ClientPrefs.downScroll;
			babyArrow.alpha = targetAlpha;

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

	public function finishSong():Void
	{
		if(ClientPrefs.noteOffset <= 0) {
			endSong();
		} else {
			finishTimer = new FlxTimer().start(ClientPrefs.noteOffset / 1000, function(tmr:FlxTimer) {
				endSong();
			});
		}
	}

	public function endSong()
	{
		if(vocals != null)
		{
			vocals.pause();
			vocals.destroy();
			vocals = null;
		}

		
		if(vocalsBoyfriend != null)
		{
			for(boyfriend in vocalsBoyfriend)
			{
				boyfriend.pause();
				boyfriend.destroy();
				boyfriend = null;
			}
		}

		if(vocalsDad != null)
		{
			for(dad in vocalsDad)
			{
				dad.pause();
				dad.destroy();
				dad = null;
			}
		}
		if(finishTimer != null)
		{
			finishTimer.cancel();
			finishTimer.destroy();
		}
		close();
	}

	private function cachePopUpScore()
	{
		for (rating in ratingsData)
			Paths.image(rating.image);
		
		for (i in 0...10)
			Paths.image('num' + i);
	}

	private function popUpScore(note:Note = null, strumLine:StrumLineEditorNote):Void
	{
		var noteDiff:Float = Math.abs(note.strumTime - Conductor.songPosition + ClientPrefs.ratingOffset);
		//trace(noteDiff, ' ' + Math.abs(note.strumTime - Conductor.songPosition));

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
		var placement:String = Std.string(combo);

		var coolText:FlxText = new FlxText(0, 0, 0, placement, 32);
		coolText.screenCenter();
		coolText.x = FlxG.width * 0.35;

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
			spawnNoteSplashOnNote(note, strumLine);

		if(!note.ratingDisabled)
		{
			songHits++;
			totalPlayed++;
			RecalculateRating(false);
		}

		var pixelShitPart1:String = "";
		var pixelShitPart2:String = '';

		rating.loadGraphic(Paths.image(pixelShitPart1 + daRating.image + pixelShitPart2));
		rating.screenCenter();
		rating.x = coolText.x - 40;
		rating.y -= 60;
		rating.acceleration.y = 550 * playbackRate * playbackRate;
		rating.velocity.y -= FlxG.random.int(140, 175) * playbackRate;
		rating.velocity.x -= FlxG.random.int(0, 10) * playbackRate;
		rating.visible = (!ClientPrefs.hideHud && showRating);
		rating.x += ClientPrefs.comboOffset[0];
		rating.y -= ClientPrefs.comboOffset[1];

		var comboSpr:FlxSprite = new FlxSprite().loadGraphic(Paths.image(pixelShitPart1 + 'combo' + pixelShitPart2));
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

		rating.setGraphicSize(Std.int(rating.width * 0.7));
		rating.updateHitbox();
		comboSpr.setGraphicSize(Std.int(comboSpr.width * 0.7));
		comboSpr.updateHitbox();

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
			var numScore:FlxSprite = new FlxSprite().loadGraphic(Paths.image(pixelShitPart1 + 'num' + Std.int(i) + pixelShitPart2));
			numScore.screenCenter();
			numScore.x = coolText.x + (43 * daLoop) - 90 + ClientPrefs.comboOffset[2];
			numScore.y += 80 - ClientPrefs.comboOffset[3];
			
			if (!ClientPrefs.comboStacking)
				lastScore.push(numScore);

			numScore.setGraphicSize(Std.int(numScore.width * 0.5));
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

	private function keyPressed(key:Int)
	{
		var lastTime:Float = Conductor.songPosition;
		if (key > -1)
		{
			if (!playerStrums.autoplay)
			{
				if(notes.length > 0)
				{
						
					Conductor.songPosition = FlxG.sound.music.time;
		
					var canMiss:Bool = !ClientPrefs.ghostTapping;

					var pressNotes:Array<Note> = [];
					var notesStopped:Bool = false;
				    var sortedNotesList:Array<Note> = [];

					notes.forEachAlive(function(daNote:Note)
					{
						if (daNote.canBeHit && daNote.mustPress &&
							!daNote.tooLate && !daNote.wasGoodHit && !daNote.isSustainNote && !daNote.blockHit)
						{
							if(daNote.noteData == key) sortedNotesList.push(daNote);
							canMiss = true;
						}
					});
					sortedNotesList.sort(PlayState.sortHitNotes);

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
								goodNoteHit(epicNote, playerStrums);
								pressNotes.push(epicNote);
							}
						}
					}
				}
				var spr:StrumNote = playerStrums.members[key];
				if(spr != null && spr.animation.curAnim.name != 'confirm')
				{
					spr.playAnim('pressed');
					spr.resetAnim = 0;
				}
			}

			if (!opponentStrums.autoplay)
			{
				if(notes.length > 0)
				{
					var lastTime:Float = Conductor.songPosition;
					Conductor.songPosition = FlxG.sound.music.time;
		
					var canMiss:Bool = !ClientPrefs.ghostTapping;

					var pressNotes:Array<Note> = [];
					var notesStopped:Bool = false;
				     var sortedNotesList:Array<Note> = [];

					notes.forEachAlive(function(daNote:Note)
					{
						if (daNote.canBeHit && !daNote.mustPress &&
							!daNote.tooLate && !daNote.wasGoodHit && !daNote.isSustainNote && !daNote.blockHit)
						{
							if(daNote.noteData == key) sortedNotesList.push(daNote);
							canMiss = true;
						}
					});
					sortedNotesList.sort(PlayState.sortHitNotes);

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
								goodNoteHit(epicNote, opponentStrums);
								pressNotes.push(epicNote);
							}
						}
					}
				}
				
				
				var spr:StrumNote = opponentStrums.members[key];
				if(spr != null && spr.animation.curAnim.name != 'confirm')
				{
					spr.playAnim('pressed');
					spr.resetAnim = 0;
				}				
			}

			Conductor.songPosition = lastTime;
		}
	}

	private function onKeyPress(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = PlayState.getKeyFromEvent(keysArray, eventKey);
		//trace('Pressed: ' + eventKey);

		if (!controls.controllerMode && FlxG.keys.checkStatus(eventKey, JUST_PRESSED)) keyPressed(key);
	}

	private function onKeyRelease(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = PlayState.getKeyFromEvent(keysArray, eventKey);
		//trace('Pressed: ' + eventKey);

		if(!controls.controllerMode && key > -1) keyReleased(key);
	}

	private function keyReleased(key:Int)
	{
		if(!playerStrums.autoplay && key > -1)
		{
			if (playerStrums.members[key] != null)
			{
				playerStrums.members[key].playAnim('static');
				playerStrums.members[key].resetAnim = 0;
			}
		}

		if(!opponentStrums.autoplay && key > -1)
		{
			if (opponentStrums.members[key] != null)
			{
				opponentStrums.members[key].playAnim('static');
				opponentStrums.members[key].resetAnim = 0;
			}
		}
	}
	
	// Hold notes
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
				if(pressArray[i])
					keyPressed(i);

		// rewritten inputs???
		notes.forEachAlive(function(daNote:Note)
		{
			// hold note functions
			if (daNote.isSustainNote && holdArray[daNote.noteData] && daNote.canBeHit
				&& daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit && !daNote.blockHit)
				goodNoteHit(daNote, playerStrums);

			if (daNote.isSustainNote && holdArray[daNote.noteData] && daNote.canBeHit
				&& !daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit && !daNote.blockHit)
				goodNoteHit(daNote, opponentStrums);
		});

		// TO DO: Find a better way to handle controller inputs, this should work for now
		if(controls.controllerMode && releaseArray.contains(true))
			for (i in 0...releaseArray.length)
				if(releaseArray[i])
					keyReleased(i);
	}

	function fakeGoodNoteHit(note:Note, chararterStrums:StrumLineEditorNote)
	{
		if (!note.wasGoodHit)
		{
			if(note.ignoreNote || note.hitCausesMiss) return;

			if (ClientPrefs.hitsoundVolume > 0 && !note.hitsoundDisabled && note.mustPress)
			{
				FlxG.sound.play(Paths.sound('hitsound'), ClientPrefs.hitsoundVolume);
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

			if (!note.isSustainNote)
			{
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}
		}
	}

	function goodNoteHit(note:Note, strumLine:StrumLineEditorNote):Void
	{
		if (!note.wasGoodHit)
		{
			note.wasGoodHit = true;
			if (ClientPrefs.hitsoundVolume > 0 && !note.hitsoundDisabled)
				FlxG.sound.play(Paths.sound('hitsound'), ClientPrefs.hitsoundVolume);

			if(note.hitCausesMiss) {
				noteMiss(note);
				if(!note.noteSplashDisabled && !note.isSustainNote)
					spawnNoteSplashOnNote(note, strumLine);

				if (!note.isSustainNote)
				{
					note.kill();
					notes.remove(note, true);
					note.destroy();
				}
				return;
			}

			if(note.mustPress)
			{
				if (!playerStrums.autoplay && !note.isSustainNote)
				{
					combo += 1;
					if(combo > 9999) combo = 9999;
					popUpScore(note, strumLine);
				}
				else if(!note.isSustainNote && !note.noteSplashDisabled)
				{
					spawnNoteSplashOnNote(note, strumLine);
				}
			}
			else
			{
				if (!opponentStrums.autoplay && !note.isSustainNote)
				{
					combo += 1;
					if(combo > 9999) combo = 9999;
					popUpScore(note, strumLine);
				}
				else if(!note.isSustainNote && !note.noteSplashDisabled)
				{
					spawnNoteSplashOnNote(note, strumLine);
				}
				note.hitByOpponent = true;
			}

			if(strumLine.autoplay)
			{
				if (strumLine.members[Std.int(Math.abs(note.noteData))] != null)
				{
					strumLine.members[Std.int(Math.abs(note.noteData))].playAnim('confirm', true);
					strumLine.members[Std.int(Math.abs(note.noteData))].resetAnim = (Conductor.stepCrochet * 1.25 / 1000 / playbackRate);
				}
			}
			else
			{
				if (strumLine.members[note.noteData] != null)
				{
					strumLine.members[note.noteData].playAnim('confirm', true);
					strumLine.members[note.noteData].resetAnim = 0;
				}
			}

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

			if (!note.isSustainNote)
			{
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}
		}
	}
	
	function noteMiss(daNote:Note):Void { //You didn't hit the key and let it go offscreen, also used by Hurt Notes
		//Dupe note remove
		notes.forEachAlive(function(note:Note) {
			if (daNote != note && daNote.noteData == note.noteData && daNote.isSustainNote == note.isSustainNote && Math.abs(daNote.strumTime - note.strumTime) < 1) {
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}
		});

		// score and data
		songMisses++;
		totalPlayed++;
		RecalculateRating(true);
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
		combo = 0;
	}

	function spawnNoteSplashOnNote(note:Note, strumLine:StrumLineEditorNote) {
		if(note != null) {
			var strum:StrumNote = strumLine.members[note.noteData];
			if(strum != null)
				spawnNoteSplash(strum.x, strum.y, note.noteData, note);
		}
	}

	function spawnNoteSplash(x:Float, y:Float, data:Int, ?note:Note = null) {
		var splash:NoteSplash = grpNoteSplashes.recycle(NoteSplash);
		splash.setupNoteSplash(x, y, data, note);
		grpNoteSplashes.add(splash);
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

	function RecalculateRating(badHit:Bool = false) {
		if(totalPlayed != 0) //Prevent divide by 0
			ratingPercent = Math.min(1, Math.max(0, totalNotesHit / totalPlayed));

		fullComboUpdate();
		updateScore(badHit); // score will only update after rating is calculated, if it's a badHit, it shouldn't bounce -Ghost
	}

	function updateScore(miss:Bool = false)
	{
		var str:String = '?';
		if(totalPlayed != 0)
		{
			var percent:Float = Highscore.floorDecimal(ratingPercent * 100, 2);
			str = '$percent% - $ratingFC';
		}
		scoreTxt.text = 'Hits: $songHits | Misses: $songMisses | Rating: $str';
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
}