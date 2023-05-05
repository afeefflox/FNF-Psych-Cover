var halloweenWhite:FlxSprite;
var halloweenBG:FlxSprite;
function create() {
    halloweenBG = new FlxSprite(-200, -100);
    if(!ClientPrefs.lowQuality) {
		makeBGAnimatedSprite(halloweenBG, ['stages/spooky/halloween_bg'], ['halloweem bg0', 'halloweem bg lightning strike'], false, [1, 1]);
    } else {
		makeBGSprite(halloweenBG, ['stages/spooky/halloween_bg_low'], [1, 1]);
    }
	halloweenBG.antialiasing = ClientPrefs.globalAntialiasing;
    add(halloweenBG);

    halloweenWhite = new FlxSprite(-800, -400);
	halloweenWhite.scrollFactor.set();
    halloweenWhite.makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.WHITE);
    halloweenWhite.alpha = 0;
    setBlendMode(halloweenWhite, 'add');
	add(halloweenWhite, true);
}

function makeBGSprite(target:FlxSprite, image:Array<String>, scrollFactor:Array<Float>)
{
    target.loadGraphic(Paths.image(image[0], image[1]));
	target.scrollFactor.set(scrollFactor[0], scrollFactor[1]);
    target.active = false;
}

function makeBGAnimatedSprite(target:FlxSprite, image:Array<String>, animArray:Array<String> = null, loop:Bool = false, scrollFactor:Array<Float>)
{
	target.frames = CoolUtil.loadFrames(image[0], image[1]);
	for (i in 0...animArray.length) {
		var anim:String = animArray[i];
		target.animation.addByPrefix(anim, anim, 24, loop);
	}
	target.scrollFactor.set(scrollFactor[0], scrollFactor[1]);
}


var lightningStrikeBeat:Int = 0;
var lightningOffset:Int = 8;
function beatHit()
{
    if (FlxG.random.bool(10) && curBeat > lightningStrikeBeat + lightningOffset)
	{
		lightningStrikeShit();
	}
}

function lightningStrikeShit():Void
{
	FlxG.sound.play(Paths.soundRandom('thunder_', 1, 2));
	if(!ClientPrefs.lowQuality) halloweenBG.animation.play('halloweem bg lightning strike');

	lightningStrikeBeat = curBeat;
	lightningOffset = FlxG.random.int(8, 24);

	if(game.boyfriend.animOffsets.exists('scared')) {
		game.boyfriend.playAnim('scared', true);
	}

	if(game.gf != null && game.gf.animOffsets.exists('scared')) {
		game.gf.playAnim('scared', true);
	}

	if(ClientPrefs.camZooms) {
		FlxG.camera.zoom += 0.015;
		game.camHUD.zoom += 0.03;

		if(!game.camZooming) { //Just a way for preventing it to be permanently zoomed until Skid & Pump hits a note
			FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, 0.5);
			FlxTween.tween(game.camHUD, {zoom: 1}, 0.5);
		}
	}

	if(ClientPrefs.flashing) {
		halloweenWhite.alpha = 0.4;
		FlxTween.tween(halloweenWhite, {alpha: 0.5}, 0.075);
		FlxTween.tween(halloweenWhite, {alpha: 0}, 0.25, {startDelay: 0.15});
	}
}
