var phillyLightsColors = [0xFF31A2FD, 0xFF31FD8C, 0xFFFB33F5, 0xFFFD4531, 0xFFFBA633];

var phillyTrain:FlxSprite;
var trainSound:FlxSound;
var phillyStreet:FlxSprite;
var phillyWindow:FlxSprite;
function create() {
    if(!ClientPrefs.lowQuality) {
        var bg:FlxSprite = new FlxSprite(-100, 0);
        makeBGSprite(bg, ['stages/philly/sky'], [0.1, 0.1]);
        bg.antialiasing = ClientPrefs.globalAntialiasing;
        add(bg);
    }

    var city:FlxSprite = new FlxSprite(-10, 0);
    makeBGSprite(city, ['stages/philly/city'], [0.3, 0.3], [1, 1]);
    city.antialiasing = ClientPrefs.globalAntialiasing;
    city.setGraphicSize(Std.int(city.width * 0.85));
    city.updateHitbox();
    add(city);

    phillyWindow = new FlxSprite(-10, 0);
    makeBGSprite(phillyWindow, ['stages/philly/window'], [0.3, 0.3], [1, 1]);
    phillyWindow.antialiasing = ClientPrefs.globalAntialiasing;
    phillyWindow.setGraphicSize(Std.int(phillyWindow.width * 0.85));
    phillyWindow.updateHitbox();
    add(phillyWindow);
    phillyWindow.alpha = 0;

    if(!ClientPrefs.lowQuality) {
        var streetBehind:FlxSprite = new FlxSprite(-40, 50);
        makeBGSprite(streetBehind, ['stages/philly/behindTrain'], [1, 1]);
        streetBehind.antialiasing = ClientPrefs.globalAntialiasing;
        add(streetBehind);
    }

    phillyTrain = new FlxSprite(2000, 360);
    makeBGSprite(phillyTrain, ['stages/philly/train'], [1, 1]);
    phillyTrain.antialiasing = ClientPrefs.globalAntialiasing;
    add(phillyTrain);

    trainSound = new FlxSound().loadEmbedded(Paths.sound('stages/philly/train_passes'));
    FlxG.sound.list.add(trainSound);

    phillyStreet = new FlxSprite(-40, 50);
    makeBGSprite(phillyStreet, ['stages/philly/street'], [1, 1]);
    phillyStreet.antialiasing = ClientPrefs.globalAntialiasing;
    add(phillyStreet);
}

var trainMoving:Bool = false;
var trainFrameTiming:Float = 0;

var trainCars:Int = 8;
var trainFinishing:Bool = false;
var trainCooldown:Int = 0;
var startedMoving:Bool = false;
function update(elapsed)
{
    if (trainMoving)
    {
        trainFrameTiming += elapsed;

        if (trainFrameTiming >= 1 / 24)
        {
            updateTrainPos();
            trainFrameTiming = 0;
        }
    }

    phillyWindow.alpha -= (Conductor.crochet / 1000) * FlxG.elapsed * 1.5;
    
}

var curLight:Int = -1;
function beatHit()
{
    if (!trainMoving)
        trainCooldown += 1;

    if (curBeat % 4 == 0)
    {
        curLight = FlxG.random.int(0, phillyLightsColors.length - 1, [curLight]);
        phillyWindow.color = phillyLightsColors[curLight];
        phillyWindow.alpha = 1;
    }

    if (curBeat % 8 == 4 && FlxG.random.bool(30) && !trainMoving && trainCooldown > 8)
    {
        trainCooldown = FlxG.random.int(-4, 0);
        trainStart();
    }
}


function updateTrainPos():Void
{
	if (trainSound.time >= 4700)
	{
		startedMoving = true;
		if (game.gf != null)
		{
			game.gf.playAnim('hairBlow');
			game.gf.specialAnim = true;
		}
	}

	if (startedMoving)
	{
		phillyTrain.x -= 400;

		if (phillyTrain.x < -2000 && !trainFinishing)
		{
			phillyTrain.x = -1150;
			trainCars -= 1;

			if (trainCars <= 0)
				trainFinishing = true;
		}

		if (phillyTrain.x < -4000 && trainFinishing)
			trainReset();
	}
}

function trainReset():Void
{
	if(game.gf != null)
	{
		game.gf.danced = false; //Sets head to the correct position once the animation ends
		game.gf.playAnim('hairFall');
		game.gf.specialAnim = true;
	}
	phillyTrain.x = FlxG.width + 200;
	trainMoving = false;
	trainCars = 8;
	trainFinishing = false;
	startedMoving = false;
}

function trainStart():Void
{
	trainMoving = true;
	if (!trainSound.playing)
		trainSound.play(true);
}

function makeBGSprite(target:FlxSprite, image:Array<String>, scrollFactor:Array<Float>)
{
    target.loadGraphic(Paths.image(image[0], image[1]));
	target.scrollFactor.set(scrollFactor[0], scrollFactor[1]);
    target.active = false;
}
