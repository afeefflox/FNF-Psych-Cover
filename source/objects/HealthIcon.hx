package objects;

import flixel.graphics.FlxGraphic;
import flixel.FlxSprite;
import openfl.utils.Assets as OpenFlAssets;

using StringTools;

class HealthIcon extends FlxSprite
{
	public var sprTracker:FlxSprite;
	private var isOldIcon:Bool = false;

	private var isWinner:Bool = false;
	private var isEmotionStuff:Bool = false;
	private var isNormal:Bool = true;

	public var initialWidth:Float = 0;
	public var initialHeight:Float = 0;

	public var offsetX = 0;
	public var offsetY = 0;

	private var char:String = '';
	var isPlayer:Bool = false;


	public function new(char:String = 'bf', isPlayer:Bool = false)
	{
		super();
		isOldIcon = (char == char +'-old');
		this.isPlayer = isPlayer;
		changeIcon(char);
		scrollFactor.set();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (sprTracker != null)
			setPosition(sprTracker.x + sprTracker.width + 12, sprTracker.y - 30);
	}

	public function swapOldIcon(char:String) {
		if(isOldIcon = !isOldIcon) 
			changeIcon(char + '-old');
		else 
			changeIcon(char);
	}

	private var iconOffsets:Array<Float> = [0, 0];
	public function changeIcon(char:String, ?newPlayer:Bool = null) {
		if (this.char != char || (newPlayer != null && newPlayer != isPlayer))
		{
			if (newPlayer != null)
				isPlayer = newPlayer;
			
			offsetX = 0;
			offsetY = 0;

			var iconPath = char;
			if (!Paths.fileExists('images/icons/icon-' + iconPath + '.png', IMAGE))
			{
				if (iconPath != char)
					iconPath = char;
				else
					iconPath = 'face';
				trace('$char icon trying $iconPath instead you fuck');
			}
			var iconGraphic:FlxGraphic = Paths.image('icons/icon-' + iconPath);
			if(iconGraphic.width == 450)
			{
				loadGraphic(iconGraphic, true, Std.int(iconGraphic.width / 3), iconGraphic.height);
				iconOffsets[0] = (width - 150) / 2;
				iconOffsets[1] = (width - 150) / 2;
				iconOffsets[2] = (width - 150) / 2;
				updateHitbox();
		
				animation.add('icon', [0, 1, 2], 0, false, isPlayer);
				animation.play('icon');
				isWinner = true;
				isEmotionStuff = false;
				isNormal = false;
			}
			else if (iconGraphic.width == 750)
			{
				loadGraphic(iconGraphic, true, Std.int(iconGraphic.width / 5), iconGraphic.height);
				iconOffsets[0] = (width - 150) / 2;
				iconOffsets[1] = (width - 150) / 2;
				iconOffsets[2] = (width - 150) / 2;
				iconOffsets[3] = (width - 150) / 2;
				iconOffsets[4] = (width - 150) / 2;
				updateHitbox();
				animation.add('icon', [0, 1, 2, 3, 4], 0, false, isPlayer);
				animation.play('icon');
				isWinner = false;
				isEmotionStuff = true;
				isNormal = false;
			}
			else if (iconGraphic.width == 300)
			{
				loadGraphic(iconGraphic, true, Std.int(iconGraphic.width / 2), iconGraphic.height);
				iconOffsets[0] = (width - 150) / 2;
				iconOffsets[1] = (width - 150) / 2;
				updateHitbox();
		
				animation.add('icon', [0, 1], 0, false, isPlayer);
				animation.play('icon');
				isWinner = false;
				isEmotionStuff = false;
				isNormal = true;
			}
			animation.play('icon');
			this.char = char;

			initialWidth = width;
			initialHeight = height;

			antialiasing = ClientPrefs.globalAntialiasing;
			if(char.endsWith('-pixel')) {
				antialiasing = false;
			}
		}
	}

	override function updateHitbox()
	{
		super.updateHitbox();
		offset.x = iconOffsets[0];
		offset.y = iconOffsets[1];
	}

	public function updateAnims(health:Float)
	{
		if(isWinner)
		{
			if (health < 20)
				animation.curAnim.curFrame = 1;
			else if (health > 80)
				animation.curAnim.curFrame = 2;
			else
				animation.curAnim.curFrame = 0;
		}
		else if(isEmotionStuff)
		{
			if (health < 20)
				animation.curAnim.curFrame = 1;
			else if (health > 20 && health < 30)
				animation.curAnim.curFrame = 2;
			else if (health > 70 && health < 80)
				animation.curAnim.curFrame = 3;
			else if (health > 80)
				animation.curAnim.curFrame = 4;
			else
				animation.curAnim.curFrame = 0;
		}
		else if(isNormal)
		{
			if (health < 20)
				animation.curAnim.curFrame = 1;
			else
				animation.curAnim.curFrame = 0;
		}
	}

	public function getCharacter():String {
		return char;
	}
}
