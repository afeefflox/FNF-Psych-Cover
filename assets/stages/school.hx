
var bgTrees:FlxSprite;
var treeLeaves:FlxSprite;
function create()
{

    addHaxeLibrary('BackgroundGirls', 'objects');
	var bgSky:FlxSprite = new FlxSprite().loadGraphic(Paths.image('stages/school/weebSky'));
	bgSky.scrollFactor.set(0.1, 0.1);
	bgSky.antialiasing = false;
	add(bgSky);

	var bgSchool:FlxSprite = new FlxSprite(-200, 0).loadGraphic(Paths.image('stages/school/weebSchool'));
	bgSchool.scrollFactor.set(0.6, 0.90);
	bgSchool.antialiasing = false;
	add(bgSchool);

	var bgStreet:FlxSprite = new FlxSprite(-200).loadGraphic(Paths.image('stages/school/weebStreet'));
	bgStreet.scrollFactor.set(0.95, 0.95);
	bgStreet.antialiasing = false;
	add(bgStreet);

    var widShit = Std.int(bgSky.width * 6);
    if(!ClientPrefs.lowQuality) {
        var fgTrees:FlxSprite = new FlxSprite(-200 + 170, 130).loadGraphic(Paths.image('stages/school/weebTreesBack'));
        fgTrees.scrollFactor.set(0.9, 0.9);
        fgTrees.antialiasing = false;
        fgTrees.setGraphicSize(Std.int(widShit * 0.8));
        fgTrees.updateHitbox();
        add(fgTrees);
    }

    bgTrees = new FlxSprite(-200 - 380, -800);
	bgTrees.frames = Paths.getPackerAtlas('stages/school/weebTrees');
	bgTrees.animation.add('treeLoop', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18], 12);
	bgTrees.animation.play('treeLoop');
	bgTrees.scrollFactor.set(0.85, 0.85);
	bgTrees.antialiasing = false;
	add(bgTrees);

    if(!ClientPrefs.lowQuality) {
        treeLeaves = new FlxSprite(-200, -40);
        treeLeaves.frames = Paths.getSparrowAtlas('stages/school/petals');
        treeLeaves.animation.addByPrefix('leaves', 'PETALS ALL', 24, true);
        treeLeaves.animation.play('leaves');
        treeLeaves.scrollFactor.set(0.85, 0.85);
        treeLeaves.antialiasing = false;
        treeLeaves.setGraphicSize(widShit);
        treeLeaves.updateHitbox();
        add(treeLeaves);

        var bgGirls:BackgroundGirls = new BackgroundGirls(-100, 190);
        bgGirls.scrollFactor.set(0.9, 0.9);
        add(bgGirls);
        setVar('bgGirls', bgGirls);
    }

    

    bgSky.setGraphicSize(widShit);
    bgSchool.setGraphicSize(widShit);
    bgStreet.setGraphicSize(widShit);
    bgTrees.setGraphicSize(Std.int(widShit * 1.4));

    bgSky.updateHitbox();
    bgSchool.updateHitbox();
    bgStreet.updateHitbox();
    bgTrees.updateHitbox();


    stage.setDefaultGF('gf-pixel');

    if(isStoryMode && !seenCutscene)
    {
        if(songName == 'roses') FlxG.sound.play(Paths.sound('ANGRY'));
        initDoof();
        stage.setStartCallback(schoolIntro);
    }
}

var doof:DialogueBox = null;
function initDoof()
{
    var file:String = Paths.txt(songName + '/' + songName + 'Dialogue'); //Checks for vanilla/Senpai dialogue
    #if MODS_ALLOWED
    if (!FileSystem.exists(file))
    #else
    if (!OpenFlAssets.exists(file))
    #end
    {
        stage.startCountdown();
        return;
    }

    doof = new DialogueBox(false, CoolUtil.coolTextFile(file));
    doof.cameras = [camHUD];
    doof.scrollFactor.set();
    doof.finishThing = stage.startCountdown;
    doof.nextDialogueThing = game.startNextDialogue;
    doof.skipDialogueThing = game.skipDialogue;
}

function schoolIntro():Void
{
	inCutscene = true;
	var black:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
	black.scrollFactor.set();
	if(songName == 'senpai') add(black);

	new FlxTimer().start(0.3, function(tmr:FlxTimer)
	{
		black.alpha -= 0.15;

		if (black.alpha > 0)
			tmr.reset(0.3);
		else
		{
			if (doof != null)
				add(doof);
			else
				stage.startCountdown();

			remove(black);
			black.destroy();
		}
	});
}

function event(eventName:String, value1:String, value2:String)
{
    switch(eventName)
    {
        case 'BG Freaks Expression':
            if(getVar('bgGirls') != null) getVar('bgGirls').swapDanceType();
    }
}

function beatHit() 
{
    getVar('bgGirls').dance();
}