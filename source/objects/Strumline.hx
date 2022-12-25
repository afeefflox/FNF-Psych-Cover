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

		alpha = daAlpha * alphaM * alphaModchart;
		super.update(elapsed);
	}

    public function playAnim(anim:String, ?force:Bool = false) {
		animation.play(anim, force);
		centerOffsets();
		centerOrigin();
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

class Strumline extends FlxTypedGroup<FlxBasic>
{
    public var receptors:FlxTypedGroup<StaticNote>;
	public var notesGroup:FlxTypedGroup<Note>;
	public var holdsGroup:FlxTypedGroup<Note>;
	public var allNotes:FlxTypedGroup<Note>;

    public var autoplay:Bool = true;
	public var character:Character;
	public var playState:PlayState;

    public function new(x:Float = 0, playState:PlayState, ?character:Character, arrowSkin:String, arrowStyle:String, ?autoplay:Bool = true, ?keyAmount:Int = 4, ?parent:Strumline)
    {
        super();

		receptors = new FlxTypedGroup<StaticNote>();
		notesGroup = new FlxTypedGroup<Note>();
		holdsGroup = new FlxTypedGroup<Note>();
		allNotes = new FlxTypedGroup<Note>();

        this.autoplay = autoplay;
		this.character = character;
		this.playState = playState;

        for (i in 0...keyAmount)
        {
            var babyArrow:StaticNote = new StaticNote(-25 + x, 25 + (ClientPrefs.downScroll ? FlxG.height - 200 : 0), i, arrowSkin, arrowStyle);
			babyArrow.downScroll = ClientPrefs.downScroll;
            babyArrow.x += Note.swagWidth * i;
            babyArrow.x += 50;
            babyArrow.x -= ((keyAmount / 2) * Note.swagWidth);
            babyArrow.ID = i;
            receptors.add(babyArrow);
            babyArrow.playAnim('static');
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