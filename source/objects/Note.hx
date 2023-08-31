package objects;

import meta.state.PlayState;
import util.RGBPalette;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import flash.display.BitmapData;
import meta.state.editors.ChartingState;
import util.Conductor;
import util.CoolUtil;
import objects.NoteTypesConfig;
import flixel.math.FlxRect;

using StringTools;

typedef EventNote = {
	strumTime:Float,
	event:String,
	value1:String,
	value2:String
}

typedef NoteSplashData = {
	useGlobalShader:Bool, //breaks r/g/b/a but makes it copy default colors for your custom note
	antialiasing:Bool,
	useRGBShader:Bool,
	r:FlxColor,
	g:FlxColor,
	b:FlxColor,
	a:Float
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

	public var inEditor:Bool = false;

	public var animSuffix:String = '';
	public var gfNote:Bool = false;
	public var earlyHitMult:Float = 1;
	public var lateHitMult:Float = 1;
	public var lowPriority:Bool = false;
	public var row:Int = 0;

	public static var SUSTAIN_SIZE:Int = 44;
	public static var swagWidth:Float = 160 * 0.7;
	
	public static var colArray:Array<String> = ['purple', 'blue', 'green', 'red'];
	private var pixelInt:Array<Int> = [0, 1, 2, 3];

	public var rgbShader:RGBShaderReference;
	public static var globalRgbShaders:Array<RGBPalette> = [];

	// Lua shit
	public var noteSplashDisabled:Bool = false;
	public var noteSplashTexture:String = null;
	public var noteSplashData:NoteSplashData = {
		antialiasing: true,
		useGlobalShader: false,
		useRGBShader: (PlayState.SONG != null) ? !(PlayState.SONG.disableNoteRGB == true) : true,
		r: -1,
		g: -1,
		b: -1,
		a: ClientPrefs.splashAlpha
	};
	
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
	public var hitsound:String = 'hitsound';
	public var hitsoundChartEditor:Bool = true;

	public var createdFrom:Dynamic = null;


	private function set_multSpeed(value:Float):Float {
		resizeByRatio(value / multSpeed);
		multSpeed = value;
		//trace('fuck cock');
		return value;
	}

	public function resizeByRatio(ratio:Float) //haha funny twitter shit
	{
		if(isSustainNote && animation.curAnim != null && !animation.curAnim.name.endsWith('end'))
		{
			scale.y *=  ratio;
			updateHitbox();				
		}
	}

	private function set_texture(value:String):String {
		if(texture != value) {
			reloadNote(value);
		}
		texture = value;
		return value;
	}

	private function set_style(value:String):String {
		if(style != value) {
			style = value;
			reloadNote(texture);
		}
		return value;
	}

	public function defaultRGB()
	{
		var arr:Array<FlxColor> = ClientPrefs.arrowRGB[noteData];
		if(style == 'pixel') arr = ClientPrefs.arrowRGBPixel[noteData];

		if (rgbShader != null && noteData > -1 && noteData < 4)
		{
			rgbShader.r = arr[0];
			rgbShader.g = arr[1];
			rgbShader.b = arr[2];
		}
	}

	private function set_noteType(value:String):String {
		noteSplashTexture = PlayState.SONG != null ? PlayState.SONG.splashSkin : 'noteSplashes';
		defaultRGB();

		if(noteData > -1 && noteType != value) {
			switch(value) {
				case 'Hurt Note':
					ignoreNote = mustPress;
					if(noteData > -1  && noteData < 4) {
						rgbShader.r = 0xFF101010;
						rgbShader.g = 0xFFFF0000;
						rgbShader.b = 0xFF990022;
					}


					noteSplashData.r = 0xFFFF0000;
					noteSplashData.g = 0xFF101010;

					noteSplashTexture = 'noteSplashes/noteSplashes-electric';

					lowPriority = true;

					if(isSustainNote) {
						missHealth = 0.1;
					} else {
						missHealth = 0.3;
					}
					hitCausesMiss = true;
					hitsound = 'cancelMenu';
					hitsoundChartEditor = false;
				case 'Alt Animation':
					animSuffix = '-alt';
				case 'No Animation':
					noAnimation = true;
					noMissAnimation = true;
				case 'GF Sing':
					gfNote = true;
			}
			if (value != null && value.length > 1 && Paths.fileExists('custom_notetypes/$value.txt', TEXT)) NoteTypesConfig.applyNoteTypeData(this, value); //uhh Prevent txt issue
			if (hitsound != 'hitsound' && ClientPrefs.hitsoundVolume > 0) Paths.sound(hitsound); //imagine adding Fart poo poo
			noteType = value;
		}
		return value;
	}

	public function new(strumTime:Float, noteData:Int, ?prevNote:Note, ?sustainNote:Bool = false, ?inEditor:Bool = false, ?createdFrom:Dynamic = null)
	{
		super();

		if(createdFrom == null) 
			createdFrom = PlayState.instance;

		if (prevNote == null)
			prevNote = this;

		this.prevNote = prevNote;
		this.createdFrom = createdFrom; //For Pixel Sustain Note I guess
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
			if(noteData > -1  && noteData < 4) {
				rgbShader = new RGBShaderReference(this, initializeGlobalRGBShader(noteData));
			}

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

			animation.play(colArray[noteData % colArray.length] + 'holdend');

			updateHitbox();

			

			switch(style)
			{
				case 'pixel':
					offsetX -= 30;
				default:
					offsetX -= width / 2;
			}

			if (prevNote.isSustainNote)
			{
				prevNote.animation.play(colArray[prevNote.noteData % colArray.length] + 'hold');

				prevNote.scale.y *= Conductor.stepCrochet / 100 * 1.05;
				if(createdFrom != null && createdFrom.songSpeed != null) prevNote.scale.y *= createdFrom.songSpeed;
				prevNote.updateHitbox();
			}

			if (style == 'pixel') {
				scale.y *= 6;
				updateHitbox();
			}
			earlyHitMult = 0;
		} else if(!isSustainNote) {
			centerOffsets();
			centerOrigin();
		}
		x += offsetX;
	}

	public static function initializeGlobalRGBShader(noteData:Int)
	{
		if(globalRgbShaders[noteData] == null)
		{
			var newRGB:RGBPalette = new RGBPalette();
			globalRgbShaders[noteData] = newRGB;

			var arr:Array<FlxColor> = ClientPrefs.arrowRGB[noteData];
			if(PlayState.isPixelStage) arr = ClientPrefs.arrowRGBPixel[noteData];

			if (noteData > -1 && noteData <= arr.length)
			{
				newRGB.r = arr[0];
				newRGB.g = arr[1];
				newRGB.b = arr[2];
			}
		}
		return globalRgbShaders[noteData];
	}

	var lastNoteOffX:Float = 0;
	static var lastValidChecked:String; //optimization
	public var originalHeight:Float = 6;
	public var correctionOffset:Float = 0; //dont mess with this
	function reloadNote(?texture:String = '', ?suffix:String = '') {
		if(texture == null) texture = '';
		if(suffix == null) suffix = '';

		var skin:String = texture + suffix;
		if(skin == 'NOTE_assets' || skin == 'noteSkins/NOTE_assets')
			skin =  'noteSkins/NOTE_assets' + Note.getNoteSkinPostfix();
		
		if(texture.length < 1) {
			skin = PlayState.SONG != null ? PlayState.SONG.arrowSkin : null;
			if(skin == null || skin.length < 1) {
				skin = 'noteSkins/NOTE_assets' + suffix;
			}
		}

		var animName:String = null;
		if(animation.curAnim != null) {
			animName = animation.curAnim.name;
		}

		var lastScaleY:Float = scale.y;
		var skinPostfix:String = getNoteSkinPostfix();
		var customSkin:String = skin + skinPostfix;
		var path:String = '';
		if(customSkin == lastValidChecked  || (Paths.fileExists('images/$customSkin.png', IMAGE) || style == 'pixel' && Paths.fileExists('images/pixelUI/$customSkin.png', IMAGE)))
		{
			skin = customSkin;
			lastValidChecked = customSkin;
		}
		else 
			skinPostfix = '';

		switch (style)
		{
			case 'pixel':
				if(isSustainNote) {
					if(Paths.fileExists('images/pixelUI/' + skin + 'ENDS.png', IMAGE))
					{
						var graphic = Paths.image('pixelUI/' + skin + 'ENDS');
						loadGraphic(graphic, true, Math.floor(graphic.width / 4), Math.floor(graphic.height / 2));
						originalHeight = graphic.height / 2;
					}
					else if(Paths.fileExists('images/pixelUI/NOTE_assetsENDS'+ getNoteSkinPostfix() +'.png', IMAGE))
					{
						var graphic = Paths.image('pixelUI/NOTE_assetsENDS' + getNoteSkinPostfix());
						loadGraphic(graphic, true, Math.floor(graphic.width / 4), Math.floor(graphic.height / 2));
						originalHeight = graphic.height / 2;
					}
					else
					{
						var graphic = Paths.image('pixelUI/noteSkins/NOTE_assetsENDS');
						loadGraphic(graphic, true, Math.floor(graphic.width / 4), Math.floor(graphic.height / 2));
						originalHeight = graphic.height / 2;
					}
				} else {
					if(Paths.fileExists('images/pixelUI/$skin.png', IMAGE))
					{
						var graphic = Paths.image('pixelUI/' + skin + getNoteSkinPostfix());
						loadGraphic(graphic, true, Math.floor(graphic.width / 4), Math.floor(graphic.height / 5));
					}
					else if(Paths.fileExists('images/pixelUI/NOTE_assets'+ getNoteSkinPostfix() + '.png', IMAGE))
					{
						var graphic = Paths.image('pixelUI/NOTE_assets' + getNoteSkinPostfix());
						loadGraphic(graphic, true, Math.floor(graphic.width / 4), Math.floor(graphic.height / 5));
					}
					else
					{
						var graphic = Paths.image('pixelUI/noteSkins/NOTE_assets');
						loadGraphic(graphic, true, Math.floor(graphic.width / 4), Math.floor(graphic.height / 5));
					}
						
				}
				setGraphicSize(Std.int(width * 6));
				loadPixelNoteAnims();
				antialiasing = false;
	
				if(isSustainNote) {
					offsetX += lastNoteOffX;
					lastNoteOffX = (width - 7) * (6 / 2);
					offsetX -= lastNoteOffX;
				}
			default:
				if(Paths.fileExists('images/$skin.png', IMAGE))
					frames = Paths.getSparrowAtlas(skin);
				else if(Paths.fileExists('images/noteSkins/NOTE_assets' + getNoteSkinPostfix() + '.png', IMAGE))
					frames = Paths.getSparrowAtlas('noteSkins/NOTE_assets' + getNoteSkinPostfix());
				else
					frames = Paths.getSparrowAtlas('noteSkins/NOTE_assets');

				loadNoteAnims();
				if(!isSustainNote)
				{
					centerOffsets();
					centerOrigin();
				}

				antialiasing = ClientPrefs.globalAntialiasing;
		}
		if(isSustainNote) {

			scale.y = lastScaleY;
		}
		updateHitbox();

		if(animName != null)
			animation.play(animName, true);
	}

	public static function getNoteSkinPostfix()
	{
		var skin:String = '';
		if(ClientPrefs.noteSkin != 'Default')
			skin = '-' + ClientPrefs.noteSkin.toLowerCase().replace(' ', '_');
		return skin;
	}

	function loadNoteAnims() {
		if (isSustainNote)
		{
			animation.addByPrefix('purpleholdend', 'pruple end hold', 24, true); // this fixes some retarded typo from the original note .FLA
			animation.addByPrefix(colArray[noteData] + 'holdend', colArray[noteData] + ' hold end', 24, true);
			animation.addByPrefix(colArray[noteData] + 'hold', colArray[noteData] + ' hold piece', 24, true);
		}
		else 
			animation.addByPrefix(colArray[noteData] + 'Scroll', colArray[noteData] + '0');

		setGraphicSize(Std.int(width * 0.7));
		updateHitbox();
	}

	function loadPixelNoteAnims() {
		if(isSustainNote)
		{
			animation.add(colArray[noteData] + 'holdend', [noteData + 4], 24, true);
			animation.add(colArray[noteData] + 'hold', [noteData], 24, true);
		} 
		else 
		    animation.add(colArray[noteData] + 'Scroll', [noteData + 4], 24, true);
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);

		canBeHit = (strumTime > Conductor.songPosition - (Conductor.safeZoneOffset * lateHitMult) && strumTime < Conductor.songPosition + (Conductor.safeZoneOffset * earlyHitMult));

		if (strumTime < Conductor.songPosition - Conductor.safeZoneOffset && !wasGoodHit)
			tooLate = true;

		if (tooLate && !inEditor)
		{
			if (alpha > 0.3)
				alpha = 0.3;
		}
	}

	override public function destroy()
	{
		super.destroy();
		lastValidChecked = '';
	}


	public function followStrumNote(myStrum:StrumNote, fakeCrochet:Float, songSpeed:Float = 1)
	{
		var strumX:Float = myStrum.x;
		var strumY:Float = myStrum.y;
		var strumAngle:Float = myStrum.angle;
		var strumAlpha:Float = myStrum.alpha;
		var strumDirection:Float = myStrum.direction;

		distance = (0.45 * (Conductor.songPosition - strumTime) * songSpeed * multSpeed);
		if (!myStrum.downScroll) distance *= -1;

		var angleDir = strumDirection * Math.PI / 180;
		if (copyAngle)
			angle = strumDirection - 90 + strumAngle + offsetAngle;

		if(copyAlpha)
			alpha = strumAlpha * multAlpha;

		if(copyX)
			x = strumX + offsetX + Math.cos(angleDir) * distance;

		if(copyY)
		{
			y = strumY + offsetY + correctionOffset + Math.sin(angleDir) * distance;
			if(myStrum.downScroll && isSustainNote)
			{

				if(animation.curAnim.name.endsWith('end')) //yk it has to do it
					flipY = true;
				switch(style)
				{
					case 'pixel':
						y -= PlayState.daPixelZoom * 9.5;
					default:
						y -= (frameHeight * scale.y) - (Note.swagWidth / 2);
				}
			}
			else if(isSustainNote) //go back up scroll
			{
				if(animation.curAnim.name.endsWith('end')) //yk it has to do it
					flipY = false;
			}
		}
	}

	public function clipToStrumNote(myStrum:StrumNote)
	{
		var center:Float = myStrum.y + offsetY + Note.swagWidth / 2;
		if(isSustainNote && (mustPress || !ignoreNote) &&
			(!mustPress || (wasGoodHit || (prevNote.wasGoodHit && !canBeHit))))
		{
			var swagRect:FlxRect = clipRect;
			if(swagRect == null) swagRect = new FlxRect(0, 0, frameWidth, frameHeight);

			if (myStrum.downScroll)
			{
				if(y - offset.y * scale.y + height >= center)
				{
					swagRect.width = frameWidth;
					swagRect.height = (center - y) / scale.y;
					swagRect.y = frameHeight - swagRect.height;
				}
			}
			else if (y + offset.y * scale.y <= center)
			{
				swagRect.y = (center - y) / scale.y;
				swagRect.width = width / scale.x;
				swagRect.height = (height / scale.y) - swagRect.y;
			}
			clipRect = swagRect;
		}
	}
}

