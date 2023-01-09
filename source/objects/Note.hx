package objects;

import meta.state.PlayState;
import util.ColorSwap;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import flash.display.BitmapData;
import meta.state.editors.ChartingState;
import util.Conductor;

using StringTools;

typedef EventNote = {
	strumTime:Float,
	event:String,
	value1:String,
	value2:String
}

class Note extends FlxSprite
{
	public var extraData:Map<String,Dynamic> = [];

	public var strumTime:Float = 0;
	public var mustPress:Bool = false;
	public var noteData:Int = 0;
	public var canBeHit:Bool = false;
	public var tooLate:Bool = false;
	public var wasGoodHit:Bool = false;
	public var ignoreNote:Bool = false;
	public var hitByOpponent:Bool = false;
	public var noteWasHit:Bool = false;
	public var prevNote:Note;
	public var nextNote:Note;

	public var spawned:Bool = false;

	public var tail:Array<Note> = []; // for sustains
	public var parent:Note;
	public var blockHit:Bool = false; // only works for player

	public var sustainLength:Float = 0;
	public var isSustainNote:Bool = false;
	public var noteType(default, set):String = null;

	public var eventName:String = '';
	public var eventLength:Int = 0;
	public var eventVal1:String = '';
	public var eventVal2:String = '';

	public var colorNote:ColorSwap;
	public var inEditor:Bool = false;

	public var animSuffix:String = '';
	public var gfNote:Bool = false;
	public var earlyHitMult:Float = 0.5;
	public var lateHitMult:Float = 1;
	public var lowPriority:Bool = false;
	public var row:Int = 0;

	public static var swagWidth:Float = 160 * 0.7;
	
	private var colArray:Array<String> = ['purple', 'blue', 'green', 'red'];
	private var pixelInt:Array<Int> = [0, 1, 2, 3];

	// Lua shit
	public var noteSplashDisabled:Bool = false;
	public var noteSplashTexture:String = null;
	public var noteSplashHue:Float = 0;
	public var noteSplashSat:Float = 0;
	public var noteSplashBrt:Float = 0;

	public var offsetX:Float = 0;
	public var offsetY:Float = 0;
	public var offsetAngle:Float = 0;
	public var multAlpha:Float = 1;
	public var multSpeed(default, set):Float = 1;

	public var copyX:Bool = true;
	public var copyY:Bool = true;
	public var copyAngle:Bool = true;
	public var copyAlpha:Bool = true;

	public var hitHealth:Float = 0.023;
	public var missHealth:Float = 0.0475;
	public var rating:String = 'unknown';
	public var ratingMod:Float = 0; //9 = unknown, 0.25 = shit, 0.5 = bad, 0.75 = good, 1 = sick
	public var ratingDisabled:Bool = false;

	public var texture(default, set):String = null;
	public var style(default, set):String = null;

	public var noAnimation:Bool = false;
	public var noMissAnimation:Bool = false;
	public var hitCausesMiss:Bool = false;
	public var distance:Float = 2000; //plan on doing scroll directions soon -bb

	public var hitsoundDisabled:Bool = false;

	private function set_multSpeed(value:Float):Float {
		resizeByRatio(value / multSpeed);
		multSpeed = value;
		//trace('fuck cock');
		return value;
	}

	public function resizeByRatio(ratio:Float) //haha funny twitter shit
	{
		if(isSustainNote && !animation.curAnim.name.endsWith('end'))
		{
			scale.y *= ratio;
			updateHitbox();
		}
	}

	private function set_texture(value:String):String {
		if(texture != value) {
			reloadNote('', value);
		}
		texture = value;
		return value;
	}

	private function set_style(value:String):String {
		if(style != value) {
			style = value;
			reloadNote('', texture);
		}
		return value;
	}

	private function set_noteType(value:String):String {
		noteSplashTexture = PlayState.SONG.splashSkin;
		if (noteData > -1 && noteData < ClientPrefs.arrowHSV.length)
		{
			colorNote.hue = ClientPrefs.arrowHSV[noteData][0] / 360;
			colorNote.saturation = ClientPrefs.arrowHSV[noteData][1] / 100;
			colorNote.brightness = ClientPrefs.arrowHSV[noteData][2] / 100;
		}



		if(noteData > -1 && noteType != value) {
			switch(value) {
				case 'Hurt Note':
					ignoreNote = mustPress;
					reloadNote('HURT');
					noteSplashTexture = 'HURTnoteSplashes';
					colorNote.hue = 0;
					colorNote.saturation = 0;
					colorNote.brightness = 0;
					lowPriority = true;

					if(isSustainNote) {
						missHealth = 0.1;
					} else {
						missHealth = 0.3;
					}
					hitCausesMiss = true;
				case 'Alt Animation':
					animSuffix = '-alt';
				case 'No Animation':
					noAnimation = true;
					noMissAnimation = true;
				case 'GF Sing':
					gfNote = true;
			}
			if ((FlxG.state is PlayState))
			{
				PlayState.instance.callOnHaxes('onNoteType', [value]);
				PlayState.instance.callOnHaxes('noteType', [value]);
				PlayState.instance.callOnHaxes('set_noteType', [value]);

				PlayState.instance.setOnHaxes('note', this);
				

				PlayState.instance.setOnHaxes('texture', texture);
				PlayState.instance.setOnHaxes('style', style);

				PlayState.instance.setOnHaxes('canBeHit', canBeHit);
				PlayState.instance.setOnHaxes('tooLate', tooLate);
				PlayState.instance.setOnHaxes('wasGoodHit', wasGoodHit);
				PlayState.instance.setOnHaxes('ignoreNote', ignoreNote);
				PlayState.instance.setOnHaxes('hitByOpponent', hitByOpponent);
				PlayState.instance.setOnHaxes('earlyHitMult', earlyHitMult);
				PlayState.instance.setOnHaxes('gfNote', gfNote);
				PlayState.instance.setOnHaxes('animSuffix', animSuffix);
				PlayState.instance.setOnHaxes('noAnimation', noAnimation);
				PlayState.instance.setOnHaxes('noMissAnimation', noMissAnimation);
				PlayState.instance.setOnHaxes('hitCausesMiss', hitCausesMiss);
				PlayState.instance.setOnHaxes('hitHealth', hitHealth);
				PlayState.instance.setOnHaxes('missHealth', missHealth);
				PlayState.instance.setOnHaxes('colorNote', colorNote);
				

				PlayState.instance.setOnHaxes('offsetX', offsetX);
				PlayState.instance.setOnHaxes('offsetY', offsetY);
				PlayState.instance.setOnHaxes('copyAngle', copyAngle);
				PlayState.instance.setOnHaxes('copyAlpha', copyAlpha);
				PlayState.instance.setOnHaxes('multAlpha', multAlpha);
				PlayState.instance.setOnHaxes('multSpeed', multSpeed);
				PlayState.instance.setOnHaxes('noteSplashDisabled', noteSplashDisabled);
				PlayState.instance.setOnHaxes('noteSplashTexture', noteSplashTexture);
				PlayState.instance.setOnHaxes('noteSplashHue', noteSplashHue);
				PlayState.instance.setOnHaxes('noteSplashSat', noteSplashSat);
				PlayState.instance.setOnHaxes('noteSplashBrt', noteSplashBrt);
			}
			noteType = value;
		}
		noteSplashHue = colorNote.hue;
		noteSplashSat = colorNote.saturation;
		noteSplashBrt = colorNote.brightness;
		return value;
	}

	public function new(strumTime:Float, noteData:Int, ?prevNote:Note, ?sustainNote:Bool = false, ?inEditor:Bool = false)
	{
		super();

		if (prevNote == null)
			prevNote = this;

		this.prevNote = prevNote;
		isSustainNote = sustainNote;
		this.inEditor = inEditor;

		x += (ClientPrefs.middleScroll ? PlayState.STRUM_X_MIDDLESCROLL : PlayState.STRUM_X) + 50;
		// MAKE SURE ITS DEFINITELY OFF SCREEN?
		y -= 2000;
		this.strumTime = strumTime;
		if(!inEditor) this.strumTime += ClientPrefs.noteOffset;

		this.noteData = noteData;

		if(noteData > -1) {
			texture = '';
			colorNote = new ColorSwap();
			shader = colorNote.shader;

			x += swagWidth * (noteData);
			if(!isSustainNote && noteData > -1 && noteData < 4) { //Doing this 'if' check to fix the warnings on Senpai songs
				var animToPlay:String = '';
				animToPlay = colArray[noteData % 4];
				animation.play(animToPlay + 'Scroll');
			}
		}

		// trace(prevNote);

		if(prevNote!=null)
			prevNote.nextNote = this;

		if (isSustainNote && prevNote != null)
		{
			alpha = 0.6;
			multAlpha = 0.6;
			hitsoundDisabled = true;
			if(ClientPrefs.downScroll) flipY = true;

			offsetX += width / 2;
			copyAngle = false;

			animation.play(colArray[noteData % 4] + 'holdend');

			updateHitbox();

			

			if (style != 'pixel')
				offsetX -= width / 2;
			else
				offsetX += 30;

			if (prevNote.isSustainNote)
			{
				prevNote.animation.play(colArray[prevNote.noteData % 4] + 'hold');

				prevNote.scale.y *= Conductor.stepCrochet / 100 * 1.05;
				if(PlayState.instance != null)
				{
					prevNote.scale.y *= PlayState.instance.songSpeed;
				}

				if (style == 'pixel') {
					prevNote.scale.y *= 1.19;
					prevNote.scale.y *= (6 / height); //Auto adjust note size
				}
				prevNote.updateHitbox();
				// prevNote.setGraphicSize();
			}

			if (style == 'pixel') {
				scale.y *= PlayState.daPixelZoom;
				updateHitbox();
			}
		} else if(!isSustainNote) {
			earlyHitMult = 1;
		}
		x += offsetX;
	}

	var lastNoteOffsetXForPixelAutoAdjusting:Float = 0;
	var lastNoteScaleToo:Float = 1;
	public var originalHeightForCalcs:Float = 6;
	function reloadNote(?prefix:String = '', ?texture:String = '', ?suffix:String = '') {
		if(prefix == null) prefix = '';
		if(texture == null) texture = '';
		if(suffix == null) suffix = '';

		var skin:String = texture;
		if(texture.length < 1) {
			skin = PlayState.SONG.arrowSkin;
			if(skin == null || skin.length < 1) {
				skin = 'NOTE_assets';
			}
		}

		var animName:String = null;
		if(animation.curAnim != null) {
			animName = animation.curAnim.name;
		}

		var arraySkin:Array<String> = skin.split('/');
		arraySkin[arraySkin.length-1] = prefix + arraySkin[arraySkin.length-1] + suffix;

		var lastScaleY:Float = scale.y;
		var blahblah:String = arraySkin.join('/');
		switch (style)
		{
			case 'pixel':
				if(isSustainNote) {
					loadGraphic(Paths.image('pixelUI/' + blahblah + 'ENDS'));
					width = width / 4;
					height = height / 2;
					originalHeightForCalcs = height;
					loadGraphic(Paths.image('pixelUI/' + blahblah + 'ENDS'), true, Math.floor(width), Math.floor(height));
				} else {
					loadGraphic(Paths.image('pixelUI/' + blahblah));
					width = width / 4;
					height = height / 5;
					loadGraphic(Paths.image('pixelUI/' + blahblah), true, Math.floor(width), Math.floor(height));
				}
				setGraphicSize(Std.int(width * PlayState.daPixelZoom));
				loadPixelNoteAnims();
				antialiasing = false;
	
				if(isSustainNote) {
					offsetX += lastNoteOffsetXForPixelAutoAdjusting;
					lastNoteOffsetXForPixelAutoAdjusting = (width - 7) * (PlayState.daPixelZoom / 2);
					offsetX -= lastNoteOffsetXForPixelAutoAdjusting;
				}
			default:
				frames = Paths.getSparrowAtlas(blahblah);
				loadNoteAnims();
				antialiasing = ClientPrefs.globalAntialiasing;
		}
		if(isSustainNote) {
			scale.y = lastScaleY;
		}
		updateHitbox();

		if(animName != null)
			animation.play(animName, true);

		if(inEditor) {
			setGraphicSize(ChartingState.GRID_SIZE, ChartingState.GRID_SIZE);
			updateHitbox();
		}
	}

	function loadNoteAnims() {
		animation.addByPrefix(colArray[noteData] + 'Scroll', colArray[noteData] + '0');

		if (isSustainNote)
		{
			animation.addByPrefix('purpleholdend', 'pruple end hold'); // ?????
			animation.addByPrefix(colArray[noteData] + 'holdend', colArray[noteData] + ' hold end');
			animation.addByPrefix(colArray[noteData] + 'hold', colArray[noteData] + ' hold piece');
		}

		setGraphicSize(Std.int(width * 0.7));
		updateHitbox();
	}

	function loadPixelNoteAnims() {
		if(isSustainNote) {
			animation.add(colArray[noteData] + 'holdend', [pixelInt[noteData] + 4]);
			animation.add(colArray[noteData] + 'hold', [pixelInt[noteData]]);
		} else {
			animation.add(colArray[noteData] + 'Scroll', [pixelInt[noteData] + 4]);
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (mustPress)
		{
			// ok river
			if (strumTime > Conductor.songPosition - (Conductor.safeZoneOffset * lateHitMult)
				&& strumTime < Conductor.songPosition + (Conductor.safeZoneOffset * earlyHitMult))
				canBeHit = true;
			else
				canBeHit = false;

			if (strumTime < Conductor.songPosition - Conductor.safeZoneOffset && !wasGoodHit)
				tooLate = true;
		}
		else
		{
			canBeHit = false;

			if (strumTime < Conductor.songPosition + (Conductor.safeZoneOffset * earlyHitMult))
			{
				if((isSustainNote && prevNote.wasGoodHit) || strumTime <= Conductor.songPosition)
					wasGoodHit = true;
			}
		}

		if (tooLate && !inEditor)
		{
			if (alpha > 0.3)
				alpha = 0.3;
		}


		/**
			ReSize NOTE SUSTAIN / LONG NOTES !!
		**/
		if(isSustainNote)
		{
			scale.y = 1;
			if(!animation.curAnim.name.endsWith('end'))
			{
				scale.y = scale.y * Conductor.stepCrochet / 100 * 1.05;
				scale.y = scale.y * PlayState.instance.songSpeed;
			}

			if(style == 'pixel')
			{
				scale.y = scale.y * 1.19;
				scale.y = scale.y * 6;
			}
			updateHitbox();			
		}
	}
}

