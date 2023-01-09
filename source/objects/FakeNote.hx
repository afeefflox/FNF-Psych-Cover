package objects;
import flixel.FlxSprite;
import meta.state.PlayState;
//WHAAAT FAKE NOTE????
//I Found you Faker - Note FNF
class FakeNote extends FlxSprite
{
	public var isSustainNote:Bool = false;
	public var texture(default, set):String = null;
	public var style(default, set):String = null;
	public var colArray:Array<String> = ['purple', 'blue', 'green', 'red'];
	public var pixelInt:Array<Int> = [0, 1, 2, 3];
	public var noteData:Int = 0;
	public static var swagWidth:Float = 160 * 0.7;
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

	public function new(x:Float, y:Float, noteData:Int, ?sustainNote:Bool = false)
	{
		super(x, y);
		this.noteData = noteData;

	}

	var lastNoteOffsetXForPixelAutoAdjusting:Float = 0;
	var lastNoteScaleToo:Float = 1;
	public var originalHeightForCalcs:Float = 6;
	public var offsetX:Float = 0;
	public var offsetY:Float = 0;
	function reloadNote(?prefix:String = '', ?texture:String = '', ?suffix:String = '') {
		if(prefix == null) prefix = '';
		if(texture == null) texture = '';
		if(suffix == null) suffix = '';

		var skin:String = texture;
		if(texture.length < 1) {
			skin = 'NOTE_assets';
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
				setGraphicSize(Std.int(width * 6));
				loadPixelNoteAnims();
				antialiasing = false;
	
				if(isSustainNote) {
					offsetX += lastNoteOffsetXForPixelAutoAdjusting;
					lastNoteOffsetXForPixelAutoAdjusting = (width - 7) * (6 / 2);
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
}
