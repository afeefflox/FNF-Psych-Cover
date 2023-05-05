var tankWatchtower:FlxSprite;
var tankGround:FlxSprite;
function create()
{
    addHaxeLibrary('TankmenBG', 'objects');

    makeLuaGroup('tankmanRun');
    makeLuaGroup('foregroundSprites');

    var sky:FlxSprite = new FlxSprite(-400, -500).loadGraphic(Paths.image('stages/tank/tankSky'));
    sky.antialiasing = ClientPrefs.globalAntialiasing;
	sky.scrollFactor.set();
	add(sky);

    if(!ClientPrefs.lowQuality)
    {
        var clouds:FlxSprite = new FlxSprite(FlxG.random.int(-700, -100), FlxG.random.int(-20, 20)).loadGraphic(Paths.image('stages/tank/tankClouds'));
        clouds.scrollFactor.set(0.1, 0.1);
        clouds.velocity.x = FlxG.random.float(5, 15);
        clouds.antialiasing = ClientPrefs.globalAntialiasing;
        add(clouds);

        var mountains:FlxSprite = new FlxSprite(-300, -20).loadGraphic(Paths.image('stages/tank/tankMountains'));
        mountains.scrollFactor.set(0.2, 0.2);
        mountains.antialiasing = ClientPrefs.globalAntialiasing;
        add(mountains);

        var buildings:FlxSprite = new FlxSprite(-200, 0).loadGraphic(Paths.image('stages/tank/tankBuildings'));
        buildings.scrollFactor.set(0.3, 0.3);
        buildings.antialiasing = ClientPrefs.globalAntialiasing;
        buildings.setGraphicSize(Std.int(1.1 * buildings.width));
        buildings.updateHitbox();
        add(buildings);
    }
    
    var ruins:FlxSprite = new FlxSprite(-200, 0).loadGraphic(Paths.image('stages/tank/tankRuins'));
    ruins.antialiasing = ClientPrefs.globalAntialiasing;
	ruins.scrollFactor.set(0.35, 0.35);
    ruins.setGraphicSize(Std.int(1.1 * ruins.width));
    ruins.updateHitbox();
	add(ruins);

    if(!ClientPrefs.lowQuality)
    {
        var smokeLeft:FlxSprite = new FlxSprite(-200, -100);
        smokeLeft.frames = Paths.getSparrowAtlas('stages/tank/smokeLeft');
        smokeLeft.animation.addByPrefix('smoke', 'SmokeBlurLeft', 24, true);
        smokeLeft.animation.play('smoke', true);
        smokeLeft.antialiasing = ClientPrefs.globalAntialiasing;
        smokeLeft.scrollFactor.set(0.4, 0.4);
        add(smokeLeft);

        var smokeRight:FlxSprite = new FlxSprite(1100, -100);
        smokeRight.frames = Paths.getSparrowAtlas('stages/tank/smokeRight');
        smokeRight.animation.addByPrefix('smoke', 'SmokeRight', 24, true);
        smokeRight.animation.play('smoke', true);
        smokeRight.antialiasing = ClientPrefs.globalAntialiasing;
        smokeRight.scrollFactor.set(0.4, 0.4);
        add(smokeRight);

        tankWatchtower = new FlxSprite(100, 50);
        tankWatchtower.frames = Paths.getSparrowAtlas('stages/tank/tankWatchtower');
        tankWatchtower.animation.addByPrefix('idle', 'watchtower gradient color', 24, false);
        tankWatchtower.antialiasing = ClientPrefs.globalAntialiasing;
        tankWatchtower.scrollFactor.set(0.5, 0.5);
        add(tankWatchtower);
    }

    tankGround = new FlxSprite(300, 300);
    tankGround.frames = Paths.getSparrowAtlas('stages/tank/tankRolling');
    tankGround.animation.addByPrefix('idle', 'BG tank w lighting', 24, true);
    tankGround.animation.play('idle', true);
    tankGround.antialiasing = ClientPrefs.globalAntialiasing;
    tankGround.scrollFactor.set(0.5, 0.5);
    add(tankGround);
    

    addLuaGroup('tankmanRun');

    var ground:FlxSprite = new FlxSprite(-420, -150).loadGraphic(Paths.image('stages/tank/tankGround'));
    ground.antialiasing = ClientPrefs.globalAntialiasing;
    ground.setGraphicSize(Std.int(1.15 * ground.width));
    ground.updateHitbox();
	add(ground);

    moveTank();

    addLuaGroup('foregroundSprites', true);

    var tank:FlxSprite = new FlxSprite(-500, 650);
    tank.frames = Paths.getSparrowAtlas('stages/tank/tank0');
    tank.animation.addByPrefix('idle', 'fg', 24, false);
    tank.scrollFactor.set(1.7, 1.5);
    tank.animation.play('idle', true);
    addGroup('foregroundSprites', tank);

    if(!ClientPrefs.lowQuality)
    {
        var tank:FlxSprite = new FlxSprite(-300, 750);
        tank.frames = Paths.getSparrowAtlas('stages/tank/tank1');
        tank.animation.addByPrefix('idle', 'fg', 24, false);
        tank.scrollFactor.set(2, 0.2);
        tank.animation.play('idle', true);
        addGroup('foregroundSprites', tank);
    }

    var tank:FlxSprite = new FlxSprite(450, 940);
    tank.frames = Paths.getSparrowAtlas('stages/tank/tank2');
    tank.animation.addByPrefix('idle', 'foreground', 24, false);
    tank.scrollFactor.set(1.5, 1.5);
    tank.animation.play('idle', true);
    addGroup('foregroundSprites', tank);

    if(!ClientPrefs.lowQuality)
    {
        var tank:FlxSprite = new FlxSprite(1300, 900);
        tank.frames = Paths.getSparrowAtlas('stages/tank/tank4');
        tank.animation.addByPrefix('idle', 'fg', 24, false);
        tank.scrollFactor.set(1.5, 1.5);
        tank.animation.play('idle', true);
        addGroup('foregroundSprites', tank);
    }

    var tank:FlxSprite = new FlxSprite(1620, 700);
    tank.frames = Paths.getSparrowAtlas('stages/tank/tank5');
    tank.animation.addByPrefix('idle', 'fg', 24, false);
    tank.scrollFactor.set(1.5, 1.5);
    tank.animation.play('idle', true);
    addGroup('foregroundSprites', tank);

    if(!ClientPrefs.lowQuality)
    {
        var tank:FlxSprite = new FlxSprite(1300, 1200);
        tank.frames = Paths.getSparrowAtlas('stages/tank/tank3');
        tank.animation.addByPrefix('idle', 'fg', 24, false);
        tank.scrollFactor.set(3.5, 2.5);
        tank.animation.play('idle', true);
        addGroup('foregroundSprites', tank);
    }


}

function createPost()
{
    if(!ClientPrefs.lowQuality && game.gf.curCharacter == 'pico-speaker')
    {
        var firstTank:TankmenBG = new TankmenBG(20, 500, true);
        firstTank.resetShit(20, 600, true);
		firstTank.strumTime = 10;
        addGroup('tankmanRun', firstTank);

        for (i in 0...TankmenBG.animationNotes.length)
        {
            if(FlxG.random.bool(16)) {
                var tankBih = game.getLuaGroup('tankmanRun').recycle(TankmenBG);
                tankBih.strumTime = TankmenBG.animationNotes[i][0];
                tankBih.resetShit(500, 200 + FlxG.random.int(50, 100), TankmenBG.animationNotes[i][1] < 2);
                addGroup('tankmanRun', tankBih);
            }
        }
        
    }
}

function update(elapsed:Float)
{
    moveTank(elapsed);
}

function beatHit()
{
    dance();
}

function dance()
{
    if(!ClientPrefs.lowQuality && tankWatchtower != null) 
        tankWatchtower.animation.play('idle', true);

    if(game.getLuaGroup('foregroundSprites') != null) 
    {
        game.getLuaGroup('foregroundSprites').forEach(function(spr:FlxSprite)
        {
            if(spr != null)
                spr.animation.play('idle', true);
        });
    }
}

var tankX:Float = 400;
var tankSpeed:Float = FlxG.random.float(5, 7);
var tankAngle:Float = FlxG.random.int(-90, 45);

function moveTank(?elapsed:Float = 0)
{
    if(!game.inCutscene)
    {
        tankAngle += elapsed * tankSpeed;
        tankGround.angle = tankAngle - 90 + 15;
        tankGround.x = tankX + 1500 * Math.cos(Math.PI / 180 * (1 * tankAngle + 180));
        tankGround.y = 1300 + 1100 * Math.sin(Math.PI / 180 * (1 * tankAngle + 180));
    }
}