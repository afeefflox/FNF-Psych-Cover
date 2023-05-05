function create() {
    var bg:FlxSprite = new FlxSprite(-600, -200);
    makeBGSprite(bg, ['stages/stage/stageback'], [0.9, 0.9]);
    bg.antialiasing = ClientPrefs.globalAntialiasing;
    add(bg);


    var stageFront:FlxSprite = new FlxSprite(-650, 600);
    makeBGSprite(stageFront, ['stages/stage/stagefront'], [0.9, 0.9]);
    stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
    stageFront.updateHitbox();
    stageFront.antialiasing = ClientPrefs.globalAntialiasing;
    add(stageFront);
    
    if(!ClientPrefs.lowQuality) {

        var stageLight:FlxSprite = new FlxSprite(-125, -100);
        makeBGSprite(stageLight, ['stages/stage/stage_light'], [0.9, 0.9]);
        stageLight.setGraphicSize(Std.int(stageLight.width * 1.1));
        stageLight.updateHitbox();
        stageLight.antialiasing = ClientPrefs.globalAntialiasing;
        add(stageLight);

        var stageLight:FlxSprite = new FlxSprite(1225, -100);
        makeBGSprite(stageLight, ['stages/stage/stage_light'], [0.9, 0.9]);
        stageLight.setGraphicSize(Std.int(stageLight.width * 1.1));
        stageLight.updateHitbox();
        stageLight.flipX = true;
        stageLight.antialiasing = ClientPrefs.globalAntialiasing;
        add(stageLight);
        

        var stageCurtains:FlxSprite = new FlxSprite(-500, -300);
        makeBGSprite(stageCurtains, ['stages/stage/stagecurtains'], [1.3, 1.3]);
        stageCurtains.setGraphicSize(Std.int(stageCurtains.width * 0.9));
        stageCurtains.updateHitbox();
        stageCurtains.antialiasing = ClientPrefs.globalAntialiasing;
        add(stageCurtains);
    }
}


function makeBGSprite(target:FlxSprite, image:Array<String>, scrollFactor:Array<Float>)
{
    target.loadGraphic(Paths.image(image[0], image[1]));
	target.scrollFactor.set(scrollFactor[0], scrollFactor[1]);
    target.active = false;
}
