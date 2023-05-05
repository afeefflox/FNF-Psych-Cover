package objects;

import util.ColorSwap;
import flixel.FlxBasic;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.math.FlxRect;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxSort;
import meta.state.PlayState;
import objects.Character;

class FakerNote extends FlxSprite {
	private var noteData:Int = 0;

	public var texture(default, set):String = null;
	public var style(default, set):String = null;
	public var isSustainNote:Bool = false;

	public static var PURP_NOTE:Int = 0;
	public static var GREEN_NOTE:Int = 2;
	public static var BLUE_NOTE:Int = 1;
	public static var RED_NOTE:Int = 3;
	
	private function set_texture(value:String):String {
		if(texture != value) {
			texture = value;
			reloadNote();
		}
		return value;
	}

	private function set_style(value:String):String {
		if(style != value) {
			style = value;
			reloadNote();
		}
		return value;
	}

	public function new(x:Float, y:Float, leData:Int, ?arrowSkin:String, ?arrowStyle:String, ?sustainNote:Bool = false) {
		noteData = leData;
		this.noteData = leData;
		isSustainNote = sustainNote;
		this.isSustainNote = sustainNote;

		super(x, y);

		var skin:String = 'NOTE_assets';
		if(arrowSkin != null && arrowSkin.length > 1) skin = arrowSkin;
		if(arrowSkin == null) arrowSkin = 'NOTE_assets';

		var styleStuff:String = 'normal';
		if(arrowStyle != null && arrowStyle.length > 1) styleStuff = arrowStyle;
		if(arrowStyle == null) arrowStyle = 'normal';
		texture = skin; //Load texture and anims
		style = styleStuff;

		scrollFactor.set();
	}

	public function reloadNote()
	{
		var lastAnim:String = null;
		if(animation.curAnim != null) lastAnim = animation.curAnim.name;

		switch(style)
		{
			case 'pixel':
				if(isSustainNote) {
					loadGraphic(Paths.image('pixelUI/' + texture + 'ENDS'));
					width = width / 4;
					height = height / 2;
					loadGraphic(Paths.image('pixelUI/' + texture + 'ENDS'), true, Math.floor(width), Math.floor(height));
				} else {
					loadGraphic(Paths.image('pixelUI/' + texture));
					width = width / 4;
					height = height / 5;
					loadGraphic(Paths.image('pixelUI/' + texture), true, Math.floor(width), Math.floor(height));
				}

				loadGraphic(Paths.image('pixelUI/' + texture));
				width = width / 4;
				height = height / 5;
				loadGraphic(Paths.image('pixelUI/' + texture), true, Math.floor(width), Math.floor(height));
	
				antialiasing = false;
				setGraphicSize(Std.int(width * 6));
	
				animation.add('green', [GREEN_NOTE + 4]);
				animation.add('red', [RED_NOTE + 4]);
				animation.add('blue', [BLUE_NOTE + 4]);
				animation.add('purple', [PURP_NOTE + 4]);
				switch (Math.abs(noteData) % 4)
				{
					case 0:
						animation.add('static', [PURP_NOTE + 4]);
						animation.add('sustain', [PURP_NOTE]);
						animation.add('sustainEND', [PURP_NOTE + 4]);
					case 1:
						animation.add('static', [BLUE_NOTE + 4]);
						animation.add('sustain', [BLUE_NOTE]);
						animation.add('sustainEND', [BLUE_NOTE + 4]);
					case 2:
						animation.add('static', [GREEN_NOTE + 4]);
						animation.add('sustain', [GREEN_NOTE]);
						animation.add('sustainEND', [GREEN_NOTE + 4]);
					case 3:
						animation.add('static', [RED_NOTE + 4]);
						animation.add('sustain', [RED_NOTE]);
						animation.add('sustainEND', [RED_NOTE + 4]);
				}
			default:
				frames = Paths.getSparrowAtlas(texture);
				animation.addByPrefix('green', 'green');
				animation.addByPrefix('blue', 'blue');
				animation.addByPrefix('purple', 'purple');
				animation.addByPrefix('red', 'red');
	
				antialiasing = ClientPrefs.globalAntialiasing;
				setGraphicSize(Std.int(width * 0.7));
	
				switch (Math.abs(noteData) % 4)
				{
					case 0:
						animation.addByPrefix('static', 'purple0');
						animation.addByPrefix('sustain', 'purple hold piece', 24, false);
						animation.addByPrefix('sustainEND', 'pruple end hold', 24, false);
					case 1:
						animation.addByPrefix('static', 'blue0');
						animation.addByPrefix('sustain', 'blue hold piece', 24, false);
						animation.addByPrefix('sustainEND', 'blue hold end', 24, false);
					case 2:
						animation.addByPrefix('static', 'green0');
						animation.addByPrefix('sustain', 'green hold piece', 24, false);
						animation.addByPrefix('sustainEND', 'green hold end', 24, false);
					case 3:
						animation.addByPrefix('static', 'red0');
						animation.addByPrefix('sustain', 'red hold piece', 24, false);
						animation.addByPrefix('sustainEND', 'red hold end', 24, false);
				}
		}

		updateHitbox();

		if(lastAnim != null)
		{
			playAnim(lastAnim, true);
		}
	}

	public function playAnim(anim:String, ?force:Bool = false) {
		animation.play(anim, force);
		centerOffsets();
		centerOrigin();
	}
}

class StaticNote extends FlxSprite {
    private var colorSwap:ColorSwap;
	public var resetAnim:Float = 0;
	private var noteData:Int = 0;
	public var alphaM:Float = 1; // modifier
	public var alphaModchart:Float = 1; // for modcharts if we do them (idk if we will but just incase -neb)
	public var daAlpha:Float = 1; // the receptors actual alpha
	public var direction:Float = 90;//plan on doing scroll directions soon -bb
	public var downScroll:Bool = false;//plan on doing scroll directions soon -bb
	public var sustainReduce:Bool = true;
	public var debugMode:Bool = false;

    public var texture(default, set):String = null;
	public var style(default, set):String = null;
	private function set_texture(value:String):String {
		if(texture != value) {
			texture = value;
			reloadNote();
		}
		return value;
	}

	private function set_style(value:String):String {
		if(style != value) {
			style = value;
			reloadNote();
		}
		return value;
	}

    public function new(x:Float, y:Float, leData:Int, ?arrowSkin:String, ?arrowStyle:String) {
		colorSwap = new ColorSwap();
		shader = colorSwap.shader;
		noteData = leData;
		this.noteData = leData;
		super(x, y);

		var skin:String = 'NOTE_assets';
		if(arrowSkin != null && arrowSkin.length > 1) skin = arrowSkin;
		if(arrowSkin == null) arrowSkin = 'NOTE_assets';

		var styleStuff:String = 'normal';
		if(arrowStyle != null && arrowStyle.length > 1) styleStuff = arrowStyle;
		if(arrowStyle == null) arrowStyle = 'normal';
		texture = skin; //Load texture and anims
		style = styleStuff;

		scrollFactor.set();
	}

    public function reloadNote()
	{
		var lastAnim:String = null;
		if(animation.curAnim != null) lastAnim = animation.curAnim.name;

		switch(style)
		{
			case 'pixel':
				loadGraphic(Paths.image('pixelUI/' + texture));
				width = width / 4;
				height = height / 5;
				loadGraphic(Paths.image('pixelUI/' + texture), true, Math.floor(width), Math.floor(height));
	
				antialiasing = false;
				setGraphicSize(Std.int(width * 6));
	
				animation.add('green', [6]);
				animation.add('red', [7]);
				animation.add('blue', [5]);
				animation.add('purple', [4]);
				switch (Math.abs(noteData) % 4)
				{
					case 0:
						animation.add('static', [0]);
						animation.add('pressed', [4, 8], 12, false);
						animation.add('confirm', [12, 16], 24, false);
					case 1:
						animation.add('static', [1]);
						animation.add('pressed', [5, 9], 12, false);
						animation.add('confirm', [13, 17], 24, false);
					case 2:
						animation.add('static', [2]);
						animation.add('pressed', [6, 10], 12, false);
						animation.add('confirm', [14, 18], 12, false);
					case 3:
						animation.add('static', [3]);
						animation.add('pressed', [7, 11], 12, false);
						animation.add('confirm', [15, 19], 24, false);
				}
			default:
				frames = Paths.getSparrowAtlas(texture);
				animation.addByPrefix('green', 'arrowUP');
				animation.addByPrefix('blue', 'arrowDOWN');
				animation.addByPrefix('purple', 'arrowLEFT');
				animation.addByPrefix('red', 'arrowRIGHT');
	
				antialiasing = ClientPrefs.globalAntialiasing;
				setGraphicSize(Std.int(width * 0.7));
	
				switch (Math.abs(noteData) % 4)
				{
					case 0:
						animation.addByPrefix('static', 'arrowLEFT');
						animation.addByPrefix('pressed', 'left press', 24, false);
						animation.addByPrefix('confirm', 'left confirm', 24, false);
					case 1:
						animation.addByPrefix('static', 'arrowDOWN');
						animation.addByPrefix('pressed', 'down press', 24, false);
						animation.addByPrefix('confirm', 'down confirm', 24, false);
					case 2:
						animation.addByPrefix('static', 'arrowUP');
						animation.addByPrefix('pressed', 'up press', 24, false);
						animation.addByPrefix('confirm', 'up confirm', 24, false);
					case 3:
						animation.addByPrefix('static', 'arrowRIGHT');
						animation.addByPrefix('pressed', 'right press', 24, false);
						animation.addByPrefix('confirm', 'right confirm', 24, false);
				}
		}

		updateHitbox();

		if(lastAnim != null)
		{
			playAnim(lastAnim, true);
		}
	}

    override function update(elapsed:Float) {
		if(!debugMode)
		{
			if(resetAnim > 0) {
				resetAnim -= elapsed;
				if(resetAnim <= 0) {
					playAnim('static');
					resetAnim = 0;
				}
			}
			
			if(animation.curAnim.name == 'confirm' && style != 'pixel') {
				centerOrigin();
			}
		}
		alpha = daAlpha * alphaM * alphaModchart;
		super.update(elapsed);
	}

    public function playAnim(anim:String, ?force:Bool = false) {
		animation.play(anim, force);
		centerOffsets();
		centerOrigin();
		if(!debugMode)
		{
			if(animation.curAnim == null || animation.curAnim.name == 'static') {
				colorSwap.hue = 0;
				colorSwap.saturation = 0;
				colorSwap.brightness = 0;
			} else {
				colorSwap.hue = ClientPrefs.arrowHSV[noteData % 4][0] / 360;
				colorSwap.saturation = ClientPrefs.arrowHSV[noteData % 4][1] / 100;
				colorSwap.brightness = ClientPrefs.arrowHSV[noteData % 4][2] / 100;
	
				if(animation.curAnim.name == 'confirm' && style != 'pixel') {
					centerOrigin();
				}
			}
		}
	}
}



class FakeStrumline extends FlxTypedGroup<FlxBasic>
{
	public var receptors:FlxTypedGroup<StaticNote>;
	public function new(x:Float = 0, ?character:Character, arrowSkin:String, arrowStyle:String, ?keyAmount:Int = 4, ?parent:Strumline)
	{
		super();
		receptors = new FlxTypedGroup<StaticNote>();
		for (i in 0...keyAmount)
        {
            var babyArrow:StaticNote = new StaticNote(-25 + x, 25, i, arrowSkin, arrowStyle);
			babyArrow.downScroll = false;
            babyArrow.x += Note.swagWidth * i;
            babyArrow.x += 50;
			babyArrow.debugMode = true;
            babyArrow.x -= ((keyAmount / 2) * Note.swagWidth);
            babyArrow.ID = i;
            receptors.add(babyArrow);
            babyArrow.playAnim('static');
        }
		add(receptors);
	}
}

class FakeNotes extends FlxTypedGroup<FlxBasic>
{
	public var receptors:FlxTypedGroup<FakerNote>;
	public function new(x:Float = 0, y:Float, ?character:Character, arrowSkin:String, arrowStyle:String, ?keyAmount:Int = 4, ?parent:Strumline)
	{
		super();
		receptors = new FlxTypedGroup<FakerNote>();
		for (i in 0...keyAmount)
        {
            var babyArrow:FakerNote = new FakerNote(-25 + x, 25 + y, i, arrowSkin, arrowStyle);
            babyArrow.x += Note.swagWidth * i;
            babyArrow.x += 50;
            babyArrow.x -= ((keyAmount / 2) * Note.swagWidth);
            babyArrow.ID = i;
            receptors.add(babyArrow);
            babyArrow.playAnim('static');
        }
		add(receptors);
	}
}

class Strumline extends FlxTypedGroup<FlxBasic>
{
    public var receptors:FlxTypedGroup<StaticNote>;
	public var notesGroup:FlxTypedGroup<Note>;
	public var holdsGroup:FlxTypedGroup<Note>;
	public var allNotes:FlxTypedGroup<Note>;

    public var autoplay:Bool = true;
	public var debugMode:Bool = false;
	public var character:Character;
	public var keyAmount:Int = 0;
	public var alpha:Float = 1;
	var babyArrow:StaticNote = null;

    public function new(x:Float = 0, y:Float = 0, ?player:Int = 0, ?character:Character, arrowSkin:String, arrowStyle:String, ?autoplay:Bool = true, ?keyAmount:Int = 4, ?visibleArrow:Bool = false, ?alpha:Float = 1)
    {
        super();

		receptors = new FlxTypedGroup<StaticNote>();
		notesGroup = new FlxTypedGroup<Note>();
		holdsGroup = new FlxTypedGroup<Note>();
		allNotes = new FlxTypedGroup<Note>();

        this.autoplay = autoplay;
		this.character = character;
		this.keyAmount = keyAmount;
		this.alpha = alpha;
        for (i in 0...keyAmount)
        {
            babyArrow = new StaticNote(x, y, i, arrowSkin, arrowStyle);
			babyArrow.downScroll = ClientPrefs.downScroll;
			babyArrow.debugMode = debugMode;
            receptors.add(babyArrow);
            babyArrow.playAnim('static');
			babyArrow.x += Note.swagWidth * i;
			babyArrow.x += 50;
			babyArrow.x += ((FlxG.width / 2) * player);
			babyArrow.visible = visibleArrow;
			babyArrow.alpha = alpha;
			ID = i;
        }


        add(receptors);
        add(holdsGroup);
		add(notesGroup);
    }

    public function push(newNote:Note)
	{
		var chosenGroup = (newNote.isSustainNote ? holdsGroup : notesGroup);
		chosenGroup.add(newNote);
		allNotes.add(newNote);
		chosenGroup.sort(FlxSort.byY, (!ClientPrefs.downScroll) ? FlxSort.DESCENDING : FlxSort.ASCENDING);
	}
}