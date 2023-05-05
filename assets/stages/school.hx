var bgGirls:FlxSprite;
var bgTrees:FlxSprite;
var treeLeaves:FlxSprite;
function create()
{
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

        bgGirls = new FlxSprite(-100, 190);
	    bgGirls.frames = Paths.getSparrowAtlas('stages/school/bgFreaks');
        swapDanceType();
        bgGirls.animation.play('danceLeft');
        bgGirls.scrollFactor.set(0.9, 0.9);
        bgGirls.setGraphicSize(Std.int(bgGirls.width * 6));
        bgGirls.updateHitbox();
        bgGirls.antialiasing = false;
        add(bgGirls);
    }

    bgSky.setGraphicSize(widShit);
    bgSchool.setGraphicSize(widShit);
    bgStreet.setGraphicSize(widShit);
    bgTrees.setGraphicSize(Std.int(widShit * 1.4));

    bgSky.updateHitbox();
    bgSchool.updateHitbox();
    bgStreet.updateHitbox();
    bgTrees.updateHitbox();
}

function event(eventName:String, value1:String, value2:String)
{
    switch(eventName)
    {
        case 'BG Freaks Expression':
            if(bgGirls != null) 
                swapDanceType();
    }
}

function beatHit() 
{
    dance();
}

function setGraphicSize()
{

}

var danceDir:Bool = false;
function dance()
{
	danceDir = !danceDir;

	if (bgGirls != null)
	{
		if (danceDir)
			bgGirls.animation.play('danceRight', true);
		else
			bgGirls.animation.play('danceLeft', true);
	}
}

var isPissed:Bool = true;
function swapDanceType()
{
    isPissed = !isPissed;
    if(!isPissed) { //Gets unpissed
        bgGirls.animation.addByIndices('danceLeft', 'BG girls group', CoolUtil.numberArray(14), "", 24, false);
        bgGirls.animation.addByIndices('danceRight', 'BG girls group', CoolUtil.numberArray(30, 15), "", 24, false);
    } else { //Pisses
        bgGirls.animation.addByIndices('danceLeft', 'BG fangirls dissuaded', CoolUtil.numberArray(14), "", 24, false);
        bgGirls.animation.addByIndices('danceRight', 'BG fangirls dissuaded', CoolUtil.numberArray(30, 15), "", 24, false);
    }
    dance();
}
