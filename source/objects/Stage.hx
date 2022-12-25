package objects;

import util.Conductor;
import flixel.tweens.FlxTween;
import MusicBeat;
import objects.BGSprite;
import flixel.system.FlxSound;
import flixel.util.FlxColor;
import objects.BackgroundGirls;
import objects.BackgroundDancer;
import objects.TankmenBG;
import meta.substate.GameOverSubstate;
import meta.state.PlayState;
import flixel.math.FlxMath;
import util.FunkinLua;
import flixel.FlxBasic;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxTimer;
import util.CoolUtil;
#if MODS_ALLOWED
import sys.FileSystem;
#end
class Stage extends MusicBeatObject
{
    public var curStage:String;
    public static var instance:Stage;
	public var luaArray:Array<FunkinLua> = [];
    public var layers:Map<String,FlxTypedGroup<FlxBasic>> = [
        "boyfriend"=>new FlxTypedGroup<FlxBasic>(), // stuff that should be layered infront of all characters, but below the foreground
        "dad"=>new FlxTypedGroup<FlxBasic>(), // stuff that should be layered infront of the dad and gf but below boyfriend and foreground
        "gf"=>new FlxTypedGroup<FlxBasic>(), // stuff that should be layered infront of the gf but below the other characters and foreground
		"foreground"=>new FlxTypedGroup<FlxBasic>(), // stuff that should be layered infront of the characters 
    ];

    //Spooky - Week 2
    var halloweenBG:BGSprite;
	var halloweenWhite:BGSprite;

    //Philly - Week 3
    public var phillyLightsColors:Array<FlxColor>;
	var phillyWindow:BGSprite;
	public var phillyStreet:BGSprite;
	var phillyTrain:BGSprite;
	var trainSound:FlxSound;

    //Limo - Week 4
	var limo:BGSprite;
	var bgLimo:BGSprite;
	var grpLimoParticles:FlxTypedGroup<BGSprite>;
	var grpLimoDancers:FlxTypedGroup<BackgroundDancer>;
	var fastCar:BGSprite;

	//Henchmen Death Events
	var limoSpeed:Float = 0;
	public var limoKillingState:Int = 0;
	public var limoMetalPole:BGSprite;
	public var limoLight:BGSprite;
	public var limoCorpse:BGSprite;
	public var limoCorpseTwo:BGSprite;

    //Mall - Week 5
    public var upperBoppers:BGSprite;
	public var bottomBoppers:BGSprite;
	var santa:BGSprite;
	public var heyTimer:Float;

    //School - Week 6
	public var bgGirls:BackgroundGirls;
	public var bgGhouls:BGSprite;

    //Tank - Week 7
    public var tankWatchtower:BGSprite;
	var tankGround:BGSprite;
	public var tankmanRun:FlxTypedGroup<TankmenBG>;
	public var foregroundSprites:FlxTypedGroup<BGSprite>;
	var curLight:Int = -1;

    public function new(curStage:String = 'stage')
    {
        super();
		this.curStage = curStage;
        instance = this;

        switch (curStage)
        {
			default:
				#if (MODS_ALLOWED && LUA_ALLOWED)
				var doPush:Bool = false;
				var luaFile:String = 'stages/' + curStage + '.lua';
				if(FileSystem.exists(Paths.modFolders(luaFile))) {
					luaFile = Paths.modFolders(luaFile);
					doPush = true;
				} else {
					luaFile = Paths.getPreloadPath(luaFile);
					if(FileSystem.exists(luaFile)) {
						doPush = true;
					}
				}
		
				if(doPush)
					luaArray.push(new FunkinLua(luaFile));
				#end
				callOnLuas('onCreatePost', []);
            case 'stage':
				var bg:BGSprite = new BGSprite('stages/' + curStage + '/stageback', -600, -200, 0.9, 0.9);
				add(bg);

				var stageFront:BGSprite = new BGSprite('stages/' + curStage + '/stagefront', -650, 600, 0.9, 0.9);
				stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
				stageFront.updateHitbox();
				add(stageFront);
				if(!ClientPrefs.lowQuality) {
					var stageLight:BGSprite = new BGSprite('stages/' + curStage + '/stage_light', -125, -100, 0.9, 0.9);
					stageLight.setGraphicSize(Std.int(stageLight.width * 1.1));
					stageLight.updateHitbox();
					add(stageLight);
					var stageLight:BGSprite = new BGSprite('stages/' + curStage + '/stage_light', 1225, -100, 0.9, 0.9);
					stageLight.setGraphicSize(Std.int(stageLight.width * 1.1));
					stageLight.updateHitbox();
					stageLight.flipX = true;
					add(stageLight);

					var stageCurtains:BGSprite = new BGSprite('stages/' + curStage + '/stagecurtains', -500, -300, 1.3, 1.3);
					stageCurtains.setGraphicSize(Std.int(stageCurtains.width * 0.9));
					stageCurtains.updateHitbox();
					add(stageCurtains);
				}
            case 'spooky':
                if(!ClientPrefs.lowQuality) {
					halloweenBG = new BGSprite('stages/' + curStage + '/halloween_bg', -200, -100, ['halloweem bg0', 'halloweem bg lightning strike']);
				} else {
					halloweenBG = new BGSprite('stages/' + curStage + '/halloween_bg_low', -200, -100);
				}
				add(halloweenBG);

				halloweenWhite = new BGSprite(null, -800, -400, 0, 0);
				halloweenWhite.makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.WHITE);
				halloweenWhite.alpha = 0;
				halloweenWhite.blend = ADD;
                layers.get('boyfriend').add(halloweenWhite);
            case 'philly':
                if(!ClientPrefs.lowQuality) {
					var bg:BGSprite = new BGSprite('stages/' + curStage + '/sky', -100, 0, 0.1, 0.1);
					add(bg);
				}

				var city:BGSprite = new BGSprite('stages/' + curStage + '/city', -10, 0, 0.3, 0.3);
				city.setGraphicSize(Std.int(city.width * 0.85));
				city.updateHitbox();
				add(city);

				phillyLightsColors = [0xFF31A2FD, 0xFF31FD8C, 0xFFFB33F5, 0xFFFD4531, 0xFFFBA633];
				phillyWindow = new BGSprite('stages/' + curStage + '/window', city.x, city.y, 0.3, 0.3);
				phillyWindow.setGraphicSize(Std.int(phillyWindow.width * 0.85));
				phillyWindow.updateHitbox();
				add(phillyWindow);
				phillyWindow.alpha = 0;

				if(!ClientPrefs.lowQuality) {
					var streetBehind:BGSprite = new BGSprite('stages/' + curStage + '/behindTrain', -40, 50);
					add(streetBehind);
				}

				phillyTrain = new BGSprite('stages/' + curStage + '/train', 2000, 360);
				add(phillyTrain);

				trainSound = new FlxSound().loadEmbedded(Paths.sound('train_passes'));
				FlxG.sound.list.add(trainSound);

				phillyStreet = new BGSprite('stages/' + curStage + '/street', -40, 50);
				add(phillyStreet);
            case 'limo':
                var skyBG:BGSprite = new BGSprite('stages/' + curStage + '/limoSunset', -120, -50, 0.1, 0.1);
				add(skyBG);

				if(!ClientPrefs.lowQuality) {
					limoMetalPole = new BGSprite('stages/' + curStage + '/gore/metalPole', -500, 220, 0.4, 0.4);
					add(limoMetalPole);

					bgLimo = new BGSprite('stages/' + curStage + '/bgLimo', -150, 480, 0.4, 0.4, ['background limo pink'], true);
					add(bgLimo);

					limoCorpse = new BGSprite('stages/' + curStage + '/gore/noooooo', -500, limoMetalPole.y - 130, 0.4, 0.4, ['Henchmen on rail'], true);
					add(limoCorpse);

					limoCorpseTwo = new BGSprite('stages/' + curStage + '/gore/noooooo', -500, limoMetalPole.y, 0.4, 0.4, ['henchmen death'], true);
					add(limoCorpseTwo);

					grpLimoDancers = new FlxTypedGroup<BackgroundDancer>();
					add(grpLimoDancers);

					for (i in 0...5)
					{
						var dancer:BackgroundDancer = new BackgroundDancer((370 * i) + 170, bgLimo.y - 400);
						dancer.scrollFactor.set(0.4, 0.4);
						grpLimoDancers.add(dancer);
					}

					limoLight = new BGSprite('stages/' + curStage + '/gore/coldHeartKiller', limoMetalPole.x - 180, limoMetalPole.y - 80, 0.4, 0.4);
					add(limoLight);

					grpLimoParticles = new FlxTypedGroup<BGSprite>();
					add(grpLimoParticles);

					//PRECACHE BLOOD
					var particle:BGSprite = new BGSprite('stages/' + curStage + '/gore/stupidBlood', -400, -400, 0.4, 0.4, ['blood'], false);
					particle.alpha = 0.01;
					grpLimoParticles.add(particle);
					resetLimoKill();
				}

				limo = new BGSprite('stages/' + curStage + '/limoDrive', -120, 550, 1, 1, ['Limo stage'], true);
                layers.get('gf').add(limo);
                
				fastCar = new BGSprite('stages/' + curStage + '/fastCarLol', -300, 160);
				fastCar.active = true;
                resetFastCar();
				PlayState.instance.addBehindGF(fastCar);

				limoKillingState = 0;
            case 'mall':
                var bg:BGSprite = new BGSprite('stages/' + curStage + '/bgWalls', -1000, -500, 0.2, 0.2);
				bg.setGraphicSize(Std.int(bg.width * 0.8));
				bg.updateHitbox();
				add(bg);

				if(!ClientPrefs.lowQuality) {
					upperBoppers = new BGSprite('stages/' + curStage + '/upperBop', -240, -90, 0.33, 0.33, ['Upper Crowd Bob']);
					upperBoppers.setGraphicSize(Std.int(upperBoppers.width * 0.85));
					upperBoppers.updateHitbox();
					add(upperBoppers);

					var bgEscalator:BGSprite = new BGSprite('stages/' + curStage + '/bgEscalator', -1100, -600, 0.3, 0.3);
					bgEscalator.setGraphicSize(Std.int(bgEscalator.width * 0.9));
					bgEscalator.updateHitbox();
					add(bgEscalator);
				}

				var tree:BGSprite = new BGSprite('stages/' + curStage + '/christmasTree', 370, -250, 0.40, 0.40);
				add(tree);

				bottomBoppers = new BGSprite('stages/' + curStage + '/bottomBop', -300, 140, 0.9, 0.9, ['Bottom Level Boppers Idle']);
				bottomBoppers.animation.addByPrefix('hey', 'Bottom Level Boppers HEY', 24, false);
				bottomBoppers.setGraphicSize(Std.int(bottomBoppers.width * 1));
				bottomBoppers.updateHitbox();
				add(bottomBoppers);

				var fgSnow:BGSprite = new BGSprite('stages/' + curStage + '/fgSnow', -600, 700);
				add(fgSnow);

				santa = new BGSprite('stages/' + curStage + '/santa', -840, 150, 1, 1, ['santa idle in fear']);
				add(santa);
            case 'mallEvil':
                var bg:BGSprite = new BGSprite('stages/' + curStage + '/evilBG', -400, -500, 0.2, 0.2);
				bg.setGraphicSize(Std.int(bg.width * 0.8));
				bg.updateHitbox();
				add(bg);

				var evilTree:BGSprite = new BGSprite('stages/' + curStage + '/evilTree', 300, -300, 0.2, 0.2);
				add(evilTree);

				var evilSnow:BGSprite = new BGSprite('stages/' + curStage + '/evilSnow', -200, 700);
				add(evilSnow);
            case 'school':
                GameOverSubstate.deathSoundName = 'pixel/fnf_loss_sfx';
				GameOverSubstate.loopSoundName = 'pixel/gameOver';
				GameOverSubstate.endSoundName = 'pixel/gameOverEnd';
				GameOverSubstate.characterName = 'bf-pixel-dead';

                var bgSky:BGSprite = new BGSprite('stages/' + curStage + '/weebSky', 0, 0, 0.1, 0.1);
				add(bgSky);
				bgSky.antialiasing = false;

				var repositionShit = -200;

				var bgSchool:BGSprite = new BGSprite('stages/' + curStage + '/weebSchool', repositionShit, 0, 0.6, 0.90);
				add(bgSchool);
				bgSchool.antialiasing = false;

				var bgStreet:BGSprite = new BGSprite('stages/' + curStage + '/weebStreet', repositionShit, 0, 0.95, 0.95);
				add(bgStreet);
				bgStreet.antialiasing = false;

				var widShit = Std.int(bgSky.width * 6);
				if(!ClientPrefs.lowQuality) {
					var fgTrees:BGSprite = new BGSprite('stages/' + curStage + '/weebTreesBack', repositionShit + 170, 130, 0.9, 0.9);
					fgTrees.setGraphicSize(Std.int(widShit * 0.8));
					fgTrees.updateHitbox();
					add(fgTrees);
					fgTrees.antialiasing = false;
				}

				var bgTrees:FlxSprite = new FlxSprite(repositionShit - 380, -800);
				bgTrees.frames = Paths.getPackerAtlas('stages/' + curStage + '/weebTrees');
				bgTrees.animation.add('treeLoop', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18], 12);
				bgTrees.animation.play('treeLoop');
				bgTrees.scrollFactor.set(0.85, 0.85);
				add(bgTrees);
				bgTrees.antialiasing = false;

				if(!ClientPrefs.lowQuality) {
					var treeLeaves:BGSprite = new BGSprite('stages/' + curStage + '/petals', repositionShit, -40, 0.85, 0.85, ['PETALS ALL'], true);
					treeLeaves.setGraphicSize(widShit);
					treeLeaves.updateHitbox();
					add(treeLeaves);
					treeLeaves.antialiasing = false;
				}

				bgSky.setGraphicSize(widShit);
				bgSchool.setGraphicSize(widShit);
				bgStreet.setGraphicSize(widShit);
				bgTrees.setGraphicSize(Std.int(widShit * 1.4));

				bgSky.updateHitbox();
				bgSchool.updateHitbox();
				bgStreet.updateHitbox();
				bgTrees.updateHitbox();

				if(!ClientPrefs.lowQuality) {
					bgGirls = new BackgroundGirls(-100, 190);
					bgGirls.scrollFactor.set(0.9, 0.9);

					bgGirls.setGraphicSize(Std.int(bgGirls.width * 6));
					bgGirls.updateHitbox();
					add(bgGirls);
				}
            case 'schoolEvil':
                GameOverSubstate.deathSoundName = 'pixel/fnf_loss_sfx';
				GameOverSubstate.loopSoundName = 'pixel/gameOver';
				GameOverSubstate.endSoundName = 'pixel/gameOverEnd';
				GameOverSubstate.characterName = 'bf-pixel-dead';

				if(!ClientPrefs.lowQuality) {
					var bg:BGSprite = new BGSprite('stages/' + curStage + '/animatedEvilSchool', 400, 200, 0.8, 0.9, ['background 2'], true);
					bg.scale.set(6, 6);
					bg.antialiasing = false;
					add(bg);

					bgGhouls = new BGSprite('stages/' + curStage + '/bgGhouls', -100, 190, 0.9, 0.9, ['BG freaks glitch instance'], false);
					bgGhouls.setGraphicSize(Std.int(bgGhouls.width * 6));
					bgGhouls.updateHitbox();
					bgGhouls.visible = false;
					bgGhouls.antialiasing = false;
					add(bgGhouls);
				} else {
					var bg:BGSprite = new BGSprite('stages/' + curStage + '/animatedEvilSchool_low', 400, 200, 0.8, 0.9);
					bg.scale.set(6, 6);
					bg.antialiasing = false;
					add(bg);
				}
            case 'tank':
                var sky:BGSprite = new BGSprite('stages/' + curStage + '/tankSky', -400, -400, 0, 0);
				add(sky);

				if(!ClientPrefs.lowQuality)
				{
					var clouds:BGSprite = new BGSprite('stages/' + curStage + '/tankClouds', FlxG.random.int(-700, -100), FlxG.random.int(-20, 20), 0.1, 0.1);
					clouds.active = true;
					clouds.velocity.x = FlxG.random.float(5, 15);
					add(clouds);

					var mountains:BGSprite = new BGSprite('stages/' + curStage + '/tankMountains', -300, -20, 0.2, 0.2);
					mountains.setGraphicSize(Std.int(1.2 * mountains.width));
					mountains.updateHitbox();
					add(mountains);

					var buildings:BGSprite = new BGSprite('stages/' + curStage + '/tankBuildings', -200, 0, 0.3, 0.3);
					buildings.setGraphicSize(Std.int(1.1 * buildings.width));
					buildings.updateHitbox();
					add(buildings);
				}

				var ruins:BGSprite = new BGSprite('stages/' + curStage + '/tankRuins',-200,0,.35,.35);
				ruins.setGraphicSize(Std.int(1.1 * ruins.width));
				ruins.updateHitbox();
				add(ruins);

				if(!ClientPrefs.lowQuality)
				{
					var smokeLeft:BGSprite = new BGSprite('stages/' + curStage + '/smokeLeft', -200, -100, 0.4, 0.4, ['SmokeBlurLeft'], true);
					add(smokeLeft);
					var smokeRight:BGSprite = new BGSprite('stages/' + curStage + '/smokeRight', 1100, -100, 0.4, 0.4, ['SmokeRight'], true);
					add(smokeRight);

					tankWatchtower = new BGSprite('stages/' + curStage + '/tankWatchtower', 100, 50, 0.5, 0.5, ['watchtower gradient color']);
					add(tankWatchtower);
				}

				tankGround = new BGSprite('stages/' + curStage + '/tankRolling', 300, 300, 0.5, 0.5,['BG tank w lighting'], true);
				add(tankGround);

				tankmanRun = new FlxTypedGroup<TankmenBG>();
				add(tankmanRun);

				var ground:BGSprite = new BGSprite('stages/' + curStage + '/tankGround', -420, -150);
				ground.setGraphicSize(Std.int(1.15 * ground.width));
				ground.updateHitbox();
				add(ground);
				moveTank();

				foregroundSprites = new FlxTypedGroup<BGSprite>();
				foregroundSprites.add(new BGSprite('tank0', -500, 650, 1.7, 1.5, ['fg']));
				if(!ClientPrefs.lowQuality) foregroundSprites.add(new BGSprite('tank1', -300, 750, 2, 0.2, ['fg']));
				foregroundSprites.add(new BGSprite('tank2', 450, 940, 1.5, 1.5, ['foreground']));
				if(!ClientPrefs.lowQuality) foregroundSprites.add(new BGSprite('tank4', 1300, 900, 1.5, 1.5, ['fg']));
				foregroundSprites.add(new BGSprite('tank5', 1620, 700, 1.5, 1.5, ['fg']));
				if(!ClientPrefs.lowQuality) foregroundSprites.add(new BGSprite('tank3', 1300, 1200, 3.5, 2.5, ['fg']));

                layers.get('boyfriend').add(foregroundSprites);
        }
    }

    override public function update(elapsed:Float)
    {
		super.update(elapsed);
		callOnLuas('onUpdate', [elapsed]);
        switch (curStage)
        {
			case 'tank':
				moveTank(elapsed);
			case 'schoolEvil':
				if(!ClientPrefs.lowQuality && bgGhouls.animation.curAnim.finished) {
					bgGhouls.visible = false;
				}
			case 'philly':
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

				if(PlayState.instance.phillyGlowParticles != null)
				{
					var i:Int = PlayState.instance.phillyGlowParticles.members.length-1;
					while (i > 0)
					{
						var particle = PlayState.instance.phillyGlowParticles.members[i];
						if(particle.alpha < 0)
						{
							particle.kill();
							PlayState.instance.phillyGlowParticles.remove(particle, true);
							particle.destroy();
						}
						--i;
					}
				}
			case 'limo':
				if(!ClientPrefs.lowQuality) {
					grpLimoParticles.forEach(function(spr:BGSprite) {
						if(spr.animation.curAnim.finished) {
							spr.kill();
							grpLimoParticles.remove(spr, true);
							spr.destroy();
						}
					});

					switch(limoKillingState) {
						case 1:
							limoMetalPole.x += 5000 * elapsed;
							limoLight.x = limoMetalPole.x - 180;
							limoCorpse.x = limoLight.x - 50;
							limoCorpseTwo.x = limoLight.x + 35;

							var dancers:Array<BackgroundDancer> = grpLimoDancers.members;
							for (i in 0...dancers.length) {
								if(dancers[i].x < FlxG.width * 1.5 && limoLight.x > (370 * i) + 170) {
									switch(i) {
										case 0 | 3:
											if(i == 0) FlxG.sound.play(Paths.sound('stages/' + curStage + '/dancerdeath'), 0.5);

											var diffStr:String = i == 3 ? ' 2 ' : ' ';
											var particle:BGSprite = new BGSprite('stages/' + curStage + '/gore/noooooo', dancers[i].x + 200, dancers[i].y, 0.4, 0.4, ['hench leg spin' + diffStr + 'PINK'], false);
											grpLimoParticles.add(particle);
											var particle:BGSprite = new BGSprite('stages/' + curStage + '/gore/noooooo', dancers[i].x + 160, dancers[i].y + 200, 0.4, 0.4, ['hench arm spin' + diffStr + 'PINK'], false);
											grpLimoParticles.add(particle);
											var particle:BGSprite = new BGSprite('stages/' + curStage + '/gore/noooooo', dancers[i].x, dancers[i].y + 50, 0.4, 0.4, ['hench head spin' + diffStr + 'PINK'], false);
											grpLimoParticles.add(particle);

											var particle:BGSprite = new BGSprite('stages/' + curStage + '/gore/stupidBlood', dancers[i].x - 110, dancers[i].y + 20, 0.4, 0.4, ['blood'], false);
											particle.flipX = true;
											particle.angle = -57.5;
											grpLimoParticles.add(particle);
										case 1:
											limoCorpse.visible = true;
										case 2:
											limoCorpseTwo.visible = true;
									} //Note: Nobody cares about the fifth dancer because he is mostly hidden offscreen :(
									dancers[i].x += FlxG.width * 2;
								}
							}

							if(limoMetalPole.x > FlxG.width * 2) {
								resetLimoKill();
								limoSpeed = 800;
								limoKillingState = 2;
							}

						case 2:
							limoSpeed -= 4000 * elapsed;
							bgLimo.x -= limoSpeed * elapsed;
							if(bgLimo.x > FlxG.width * 1.5) {
								limoSpeed = 3000;
								limoKillingState = 3;
							}

						case 3:
							limoSpeed -= 2000 * elapsed;
							if(limoSpeed < 1000) limoSpeed = 1000;

							bgLimo.x -= limoSpeed * elapsed;
							if(bgLimo.x < -275) {
								limoKillingState = 4;
								limoSpeed = 800;
							}

						case 4:
							bgLimo.x = FlxMath.lerp(bgLimo.x, -150, CoolUtil.boundTo(elapsed * 9, 0, 1));
							if(Math.round(bgLimo.x) == -150) {
								bgLimo.x = -150;
								limoKillingState = 0;
							}
					}

					if(limoKillingState > 2) {
						var dancers:Array<BackgroundDancer> = grpLimoDancers.members;
						for (i in 0...dancers.length) {
							dancers[i].x = (370 * i) + bgLimo.x + 280;
						}
					}
				}
			case 'mall':
				if(heyTimer > 0) {
					heyTimer -= elapsed;
					if(heyTimer <= 0) {
						bottomBoppers.dance(true);
						heyTimer = 0;
					}
				}            
        }
		callOnLuas('onUpdatePost', [elapsed]);
    }

	var lastStepHit:Int = -1;
	override function stepHit()
	{
		super.stepHit();
		if(curStep == lastStepHit) {
			return;
		}

		lastStepHit = curStep;
		setOnLuas('curStep', curStep);
		callOnLuas('onStepHit', []);
	}

	var lastBeatHit:Int = -1;
	
	var lightningStrikeBeat:Int = 0;
	var lightningOffset:Int = 8;
    override function beatHit()
    {
        super.beatHit();

        if(lastBeatHit >= curBeat) {
			return;
		}

        switch(curStage)
        {
            case 'spooky':
                if(FlxG.random.bool(10) && curBeat > lightningStrikeBeat + lightningOffset)
                {
                    lightningStrikeShit();
                }
            case "philly":
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
            case 'limo':
                if(!ClientPrefs.lowQuality) {
					grpLimoDancers.forEach(function(dancer:BackgroundDancer)
					{
						dancer.dance();
					});
				}

				if (FlxG.random.bool(10) && fastCarCanDrive)
					fastCarDrive();
            case 'mall':
                if(!ClientPrefs.lowQuality) {
					upperBoppers.dance(true);
				}

				if(heyTimer <= 0) bottomBoppers.dance(true);
				santa.dance(true);
            case 'school':
                if(!ClientPrefs.lowQuality) {
					bgGirls.dance();
				}
            case 'tank':
                if(!ClientPrefs.lowQuality) tankWatchtower.dance();
                foregroundSprites.forEach(function(spr:BGSprite)
                {
                    spr.dance();
                });
        }

		setOnLuas('curBeat', curBeat);
		callOnLuas('onBeatHit', []);
    }

    function lightningStrikeShit():Void
	{
		FlxG.sound.play(Paths.soundRandom('stages/' + curStage + '/thunder_', 1, 2));
		if(!ClientPrefs.lowQuality) halloweenBG.animation.play('halloweem bg lightning strike');

		lightningStrikeBeat = curBeat;
		lightningOffset = FlxG.random.int(8, 24);

		if(PlayState.instance.boyfriend.existsOffsets('scared')) {
			PlayState.instance.boyfriend.playAnim('scared', true);
		}

		if(PlayState.instance.gf != null && PlayState.instance.gf.existsOffsets('scared')) {
			PlayState.instance.gf.playAnim('scared', true);
		}

		if(ClientPrefs.camZooms) {
			FlxG.camera.zoom += 0.015;
			PlayState.instance.camHUD.zoom += 0.03;

			if(!PlayState.instance.camZooming) { //Just a way for preventing it to be permanently zoomed until Skid & Pump hits a note
				FlxTween.tween(FlxG.camera, {zoom: PlayState.instance.defaultCamZoom}, 0.5);
				FlxTween.tween(PlayState.instance.camHUD, {zoom: 1}, 0.5);
			}
		}

		if(ClientPrefs.flashing) {
			halloweenWhite.alpha = 0.4;
			FlxTween.tween(halloweenWhite, {alpha: 0.5}, 0.075);
			FlxTween.tween(halloweenWhite, {alpha: 0}, 0.25, {startDelay: 0.15});
		}
	}

    var trainMoving:Bool = false;
	var trainFrameTiming:Float = 0;

	var trainCars:Int = 8;
	var trainFinishing:Bool = false;
	var trainCooldown:Int = 0;
    function trainStart():Void
	{
		trainMoving = true;
		if (!trainSound.playing)
			trainSound.play(true);
	}

    var startedMoving:Bool = false;

	function updateTrainPos():Void
	{
		if (trainSound.time >= 4700)
		{
			startedMoving = true;
			if (PlayState.instance.gf != null && PlayState.instance.gf.existsOffsets('hairBlow')) 
			{
				PlayState.instance.gf.playAnim('hairBlow');
				PlayState.instance.gf.specialAnim = true;
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
		if(PlayState.instance.gf != null && PlayState.instance.gf.existsOffsets('hairBlow')) 
		{
			PlayState.instance.gf.danced = false; //Sets head to the correct position once the animation ends
			PlayState.instance.gf.playAnim('hairFall');
			PlayState.instance.gf.specialAnim = true;
		}
		phillyTrain.x = FlxG.width + 200;
		trainMoving = false;
		trainCars = 8;
		trainFinishing = false;
		startedMoving = false;
	}

    var fastCarCanDrive:Bool = true;
    function resetFastCar():Void
	{
		fastCar.x = -12600;
		fastCar.y = FlxG.random.int(140, 250);
		fastCar.velocity.x = 0;
		fastCarCanDrive = true;
	}

    function fastCarDrive()
	{
		FlxG.sound.play(Paths.soundRandom('stages/' + curStage + '/carPass', 0, 1), 0.7);

		fastCar.velocity.x = (FlxG.random.int(170, 220) / FlxG.elapsed) * 3;
		fastCarCanDrive = false;
		PlayState.instance.carTimer = new FlxTimer().start(2, function(tmr:FlxTimer)
		{
			resetFastCar();
			PlayState.instance.carTimer = null;
		});
	}

	function resetLimoKill():Void
	{
		if(curStage == 'limo') {
			limoMetalPole.x = -500;
			limoMetalPole.visible = false;
			limoLight.x = -500;
			limoLight.visible = false;
			limoCorpse.x = -500;
			limoCorpse.visible = false;
			limoCorpseTwo.x = -500;
			limoCorpseTwo.visible = false;
		}
	}

    var tankX:Float = 400;
	var tankSpeed:Float = FlxG.random.float(5, 7);
	var tankAngle:Float = FlxG.random.int(-90, 45);

	function moveTank(?elapsed:Float = 0):Void
	{
		if(!PlayState.instance.inCutscene)
		{
			tankAngle += elapsed * tankSpeed;
			tankGround.angle = tankAngle - 90 + 15;
			tankGround.x = tankX + 1500 * Math.cos(Math.PI / 180 * (1 * tankAngle + 180));
			tankGround.y = 1300 + 1100 * Math.sin(Math.PI / 180 * (1 * tankAngle + 180));
		}
	}
	
	override function destroy()
	{
		super.destroy();
		for (lua in luaArray) {
			lua.call('onDestroy', []);
			lua.stop();
		}
		luaArray = [];

		if(PlayState.instance.boyfriendGroup != null)
		{
			var i:Int = PlayState.instance.boyfriendGroup.members.length-1;
			while(i >= 0) {
				var memb:FlxSprite = PlayState.instance.boyfriendGroup.members[i];
				//Avoid for Character...
				if(memb != null && !Std.isOfType(memb, Character)) {
					memb.kill();
					PlayState.instance.boyfriendGroup.remove(memb);
					memb.destroy();
				}
				--i;
			}
		}

		if(PlayState.instance.gfGroup != null)
		{
			var i:Int = PlayState.instance.gfGroup.members.length-1;
			while(i >= 0) {
				var memb:FlxSprite = PlayState.instance.gfGroup.members[i];
				//Avoid for Character...
				if(memb != null && !Std.isOfType(memb, Character)) {
					memb.kill();
					PlayState.instance.gfGroup.remove(memb);
					memb.destroy();
				}
				--i;
			}
		}

		if(PlayState.instance.dadGroup != null)
		{
			var i:Int = PlayState.instance.dadGroup.members.length-1;
			while(i >= 0) {
				var memb:FlxSprite = PlayState.instance.dadGroup.members[i];
				//Avoid for Character...
				if(memb != null && !Std.isOfType(memb, Character)) {
					memb.kill();
					PlayState.instance.dadGroup.remove(memb);
					memb.destroy();
				}
				--i;
			}
		}
	}

	public function callOnLuas(event:String, args:Array<Dynamic>, ignoreStops = true, exclusions:Array<String> = null):Dynamic {
		var returnVal:Dynamic = FunkinLua.Function_Continue;
		#if LUA_ALLOWED
		if(exclusions == null) exclusions = [];
		for (script in luaArray) {
			if(exclusions.contains(script.scriptName))
				continue;

			var ret:Dynamic = script.call(event, args);
			if(ret == FunkinLua.Function_StopLua && !ignoreStops)
				break;
			
			// had to do this because there is a bug in haxe where Stop != Continue doesnt work
			var bool:Bool = ret == FunkinLua.Function_Continue;
			if(!bool && ret != 0) {
				returnVal = cast ret;
			}
		}
		#end
		//trace(event, returnVal);
		return returnVal;
	}

	public function setOnLuas(variable:String, arg:Dynamic) {
		#if LUA_ALLOWED
		for (i in 0...luaArray.length) {
			luaArray[i].set(variable, arg);
		}
		#end
	}
}