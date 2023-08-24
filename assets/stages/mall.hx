

var upperBoppers:FlxSprite;
var bottomBoppers:FlxSprite;
var santa:FlxSprite;
var heyTimer:Float = 0;
function create() {
    makeLuaGroup('grpLimoParticles');
    var bg:FlxSprite = new FlxSprite(-1000, -500).loadGraphic(Paths.image('stages/mall/bgWalls'));
	bg.antialiasing = ClientPrefs.globalAntialiasing;
	bg.scrollFactor.set(0.2, 0.2);
	bg.active = false;
	bg.setGraphicSize(Std.int(bg.width * 0.8));
	bg.updateHitbox();
	add(bg);
    
    if(!ClientPrefs.lowQuality) {
        upperBoppers = new FlxSprite(-240, -90);
        upperBoppers.frames = Paths.getSparrowAtlas('stages/mall/upperBop');
        upperBoppers.animation.addByPrefix('idle', "Upper Crowd Bob", 24, false);
        upperBoppers.antialiasing = ClientPrefs.globalAntialiasing;
        upperBoppers.scrollFactor.set(0.33, 0.33);
        upperBoppers.setGraphicSize(Std.int(upperBoppers.width * 0.85));
        upperBoppers.updateHitbox();
        add(upperBoppers);

        var bgEscalator:FlxSprite = new FlxSprite(-1100, -600).loadGraphic(Paths.image('stages/mall/bgEscalator'));
        bgEscalator.antialiasing = ClientPrefs.globalAntialiasing;
        bgEscalator.scrollFactor.set(0.3, 0.3);
        bgEscalator.active = false;
        bgEscalator.setGraphicSize(Std.int(bgEscalator.width * 0.9));
        bgEscalator.updateHitbox();
        add(bgEscalator);
    }

    var tree:FlxSprite = new FlxSprite(370, -250).loadGraphic(Paths.image('stages/mall/christmasTree'));
	tree.antialiasing = ClientPrefs.globalAntialiasing;
	tree.scrollFactor.set(0.40, 0.40);
	add(tree);

	bottomBoppers = new FlxSprite(-300, 140);
	bottomBoppers.frames = Paths.getSparrowAtlas('stages/mall/bottomBop');
	bottomBoppers.animation.addByPrefix('idle', 'Bottom Level Boppers Idle', 24, false);
    bottomBoppers.animation.addByPrefix('hey', 'Bottom Level Boppers HEY!!', 24, false);
	bottomBoppers.antialiasing = ClientPrefs.globalAntialiasing;
	bottomBoppers.scrollFactor.set(0.9, 0.9);
	bottomBoppers.setGraphicSize(Std.int(bottomBoppers.width * 1));
	bottomBoppers.updateHitbox();
	add(bottomBoppers);

	var fgSnow:FlxSprite = new FlxSprite(-600, 700).loadGraphic(Paths.image('stages/mall/fgSnow'));
	fgSnow.active = false;
	fgSnow.antialiasing = ClientPrefs.globalAntialiasing;
	add(fgSnow);

	santa = new FlxSprite(-840, 150);
	santa.frames = Paths.getSparrowAtlas('stages/mall/santa');
	santa.animation.addByPrefix('idle', 'santa idle in fear', 24, false);
	santa.antialiasing = ClientPrefs.globalAntialiasing;
	add(santa);

	stage.precacheSound('stages/mall/Lights_Shut_off');
	stage.setDefaultGF('gf-christmas');

	if(isStoryMode && !seenCutscene)
		stage.setEndCallback(eggnogEndCutscene);
}

function event(eventName:String, value1:String, value2:String)
{
    switch(eventName)
    {
        case 'Hey!':
            var time:Float = Std.parseFloat(value2);
            if(Math.isNaN(time) || time <= 0) time = 0.6;
            heyTimer = time;

            bottomBoppers.animation.play('hey', true);
    }
}

function update(elapsed:Float)
{
	if(heyTimer > 0) {
		heyTimer -= elapsed;
		if(heyTimer <= 0 && bottomBoppers != null)  {
            bottomBoppers.animation.play('idle', true);
			heyTimer = 0;
		}
	}
}

function beatHit() 
{
    dance();
}

function dance()
{
	if (upperBoppers != null)
		upperBoppers.animation.play('idle', true);

    if(heyTimer <= 0 && bottomBoppers != null) 
        bottomBoppers.animation.play('idle', true);

	if (santa != null)
		santa.animation.play('idle', true);
}

function eggnogEndCutscene()
{
	if(PlayState.storyPlaylist[1] == null)
	{
		stage.endSong();
		return;
	}

	var nextSong:String = Paths.formatToSongPath(PlayState.storyPlaylist[1]);
	if(nextSong == 'winter-horrorland')
	{
		FlxG.sound.play(Paths.sound('stages/mall/Lights_Shut_off'));

		var blackShit:FlxSprite = new FlxSprite(-FlxG.width * FlxG.camera.zoom,
			-FlxG.height * FlxG.camera.zoom).makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.BLACK);
		blackShit.scrollFactor.set();
		add(blackShit);
		camHUD.visible = false;

		inCutscene = true;
		canPause = false;

		new FlxTimer().start(1.5, function(tmr:FlxTimer) {
			stage.endSong();
		});
	}
	else stage.endSong();
}