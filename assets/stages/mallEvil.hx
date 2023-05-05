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
}