function create() {
    var bg:FlxSprite = new FlxSprite(-400, -500).loadGraphic(Paths.image('stages/mall/evilBG'));
	bg.antialiasing = ClientPrefs.globalAntialiasing;
	bg.scrollFactor.set(0.2, 0.2);
	bg.active = false;
	bg.setGraphicSize(Std.int(bg.width * 0.8));
	bg.updateHitbox();
	add(bg);

	var evilTree:FlxSprite = new FlxSprite(300, -300).loadGraphic(Paths.image('stages/mall/evilTree'));
	evilTree.antialiasing = ClientPrefs.globalAntialiasing;
	evilTree.scrollFactor.set(0.2, 0.2);
	add(evilTree);

	var evilSnow:FlxSprite = new FlxSprite(-200, 700).loadGraphic(Paths.image("stages/mall/evilSnow"));
	evilSnow.antialiasing = ClientPrefs.globalAntialiasing;
	add(evilSnow);

	stage.setDefaultGF('gf-christmas');
		
	//Winter Horrorland cutscene
	if (isStoryMode && !seenCutscene && songName == 'winter-horrorland')
	{
		stage.setStartCallback(winterHorrorlandCutscene);
	}
}

function winterHorrorlandCutscene()
{
	camHUD.visible = false;
	inCutscene = true;

	FlxG.sound.play(Paths.sound('stages/mall/Lights_Turn_On'));
	FlxG.camera.zoom = 1.5;
	FlxG.camera.focusOn(new FlxPoint(400, -2050));

	// blackout at the start
	var blackScreen:FlxSprite = new FlxSprite().makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
	blackScreen.scrollFactor.set();
	add(blackScreen);

	FlxTween.tween(blackScreen, {alpha: 0}, 0.7, {
		ease: FlxEase.linear,
		onComplete: function(twn:FlxTween) {
			remove(blackScreen);
		}
	});

	// zoom out
	new FlxTimer().start(0.8, function(tmr:FlxTimer)
	{
		camHUD.visible = true;
		FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, 2.5, {
			ease: FlxEase.quadInOut,
			onComplete: function(twn:FlxTween)
			{
				stage.startCountdown();
			}
		});
	});
}