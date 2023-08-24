var fastCar:FlxSprite;
var fastCarCanDrive:Bool = true;
var dancer:FlxSprite;
var limoKillingState:String = 'WAIT';
var limoMetalPole:FlxSprite;
var limoLight:FlxSprite;
var limoCorpse:FlxSprite;
var limoCorpseTwo:FlxSprite;
var bgLimo:FlxSprite;
var dancersDiff:Float = 320;

function create()
{
	addHaxeLibrary('Achievements', 'util');
	addHaxeLibrary('BackgroundDancer', 'objects');
	makeLuaGroup('grpLimoParticles');
	makeLuaGroup('grpLimoDancers');

	var skyBG:FlxSprite = new FlxSprite(-120, -50).loadGraphic(Paths.image('stages/limo/limoSunset'));
	skyBG.scrollFactor.set(0.1, 0.1);
	skyBG.antialiasing = ClientPrefs.globalAntialiasing;
	add(skyBG);

	if(!ClientPrefs.lowQuality) {
		limoMetalPole = new FlxSprite(-500, 220).loadGraphic(Paths.image('stages/limo/gore/metalPole'));
		limoMetalPole.scrollFactor.set(0.4, 0.4);
		limoMetalPole.antialiasing = ClientPrefs.globalAntialiasing;
		add(limoMetalPole);

		bgLimo = new FlxSprite(-150, 480);
		bgLimo.frames = Paths.getSparrowAtlas('stages/limo/bgLimo');
		bgLimo.animation.addByPrefix('drive', "background limo pink", 24, true);
		bgLimo.animation.play('drive', true);
		bgLimo.scrollFactor.set(0.4, 0.4);
		bgLimo.antialiasing = ClientPrefs.globalAntialiasing;
		add(bgLimo);

		limoCorpse = new FlxSprite(-500, limoMetalPole.y - 130);
		limoCorpse.frames = Paths.getSparrowAtlas("stages/limo/gore/noooooo");
		limoCorpse.animation.addByPrefix('dead', "Henchmen on rail", 24, true);
		limoCorpse.animation.play('dead', true);
		limoCorpse.scrollFactor.set(0.4, 0.4);
		limoCorpse.antialiasing = ClientPrefs.globalAntialiasing;
		add(limoCorpse);

		limoCorpseTwo = new FlxSprite(-500, limoMetalPole.y);
		limoCorpseTwo.frames = Paths.getSparrowAtlas("stages/limo/gore/noooooo");
		limoCorpseTwo.animation.addByPrefix('dead', "henchmen death", 24, true);
		limoCorpseTwo.animation.play('dead', true);
		limoCorpseTwo.scrollFactor.set(0.4, 0.4);
		limoCorpseTwo.antialiasing = ClientPrefs.globalAntialiasing;
		add(limoCorpseTwo);

		
		addLuaGroup('grpLimoDancers');

		for (i in 0...5)
		{
			var dancer:BackgroundDancer = new BackgroundDancer((370 * i) + 170, bgLimo.y - 400);
			dancer.scrollFactor.set(0.4, 0.4);
			addGroup('grpLimoDancers', dancer);
		}

		limoLight = new FlxSprite(limoMetalPole.x - 180, limoMetalPole.y - 80).loadGraphic(Paths.image('stages/limo/gore/coldHeartKiller'));
		limoLight.antialiasing = ClientPrefs.globalAntialiasing;
		limoLight.scrollFactor.set(0.4, 0.4);
		add(limoLight);

		addLuaGroup('grpLimoParticles');

		//PRECACHE BLOOD
		var particle:FlxSprite = new FlxSprite(-400, -400);
		particle.frames = Paths.getSparrowAtlas("stages/limo/gore/stupidBlood");
		particle.animation.addByPrefix('bloody', "blood", 24, false);
		particle.animation.play('bloody', true);
		particle.scrollFactor.set(0.4, 0.4);
		particle.alpha = 0.01;
		particle.antialiasing = ClientPrefs.globalAntialiasing;
		addGroup('grpLimoParticles', particle);

		resetLimoKill();
	}

	fastCar = new FlxSprite(-300, 160).loadGraphic(Paths.image('stages/limo/fastCarLol'));
	fastCar.antialiasing = ClientPrefs.globalAntialiasing;
	//fastCar.active = true; well it solve a lot for change stage
	resetFastCar();
	add(fastCar, true);

	var limo:FlxSprite = new FlxSprite(-120, 550);
	limo.frames = Paths.getSparrowAtlas('stages/limo/limoDrive');
	limo.antialiasing = ClientPrefs.globalAntialiasing;
	limo.animation.addByPrefix('drive', "Limo stage", 24, true);
	limo.animation.play('drive', true);
	add(limo, true, 'gf');

	stage.setDefaultGF('gf-car');
}


var limoSpeed:Float = 0;
function update(elapsed:Float)
{
	if(!ClientPrefs.lowQuality) {

		game.getLuaGroup('grpLimoParticles').forEach(function(spr:FlxSprite)
		{
			if(spr.animation.curAnim.finished) {
				spr.kill();
				game.getLuaGroup('grpLimoParticles').remove(spr, true);
				spr.destroy();
			}
		});
		
		switch(limoKillingState) 
		{
			case 'KILLING':
				limoMetalPole.x += 5000 * elapsed;
				limoLight.x = limoMetalPole.x - 180;
				limoCorpse.x = limoLight.x - 50;
				limoCorpseTwo.x = limoLight.x + 35;
				
				var dancers:Array<FlxSprite> = game.getLuaGroup('grpLimoDancers').members;

				for (i in 0...dancers.length) {
					if(dancers[i].x < FlxG.width * 1.5 && limoLight.x > (370 * i) + 170) {
						switch(i) {
							case 0 | 3:
								if(i == 0) FlxG.sound.play(Paths.sound('dancerdeath'), 0.5);

								var diffStr:String = i == 3 ? ' 2 ' : ' ';

								var particle:FlxSprite = new FlxSprite(dancers[i].x + 200, dancers[i].y);
								particle.frames = Paths.getSparrowAtlas("stages/limo/gore/noooooo");
								particle.animation.addByPrefix('legSpin', 'hench leg spin' + diffStr + 'PINK', 24, false);
								particle.animation.play('legSpin', true);
								particle.scrollFactor.set(0.4, 0.4);
								particle.antialiasing = ClientPrefs.globalAntialiasing;
								addGroup('grpLimoParticles', particle);

								var particle:FlxSprite = new FlxSprite(dancers[i].x + 160, dancers[i].y + 200);
								particle.frames = Paths.getSparrowAtlas("stages/limo/gore/noooooo");
								particle.animation.addByPrefix('armSpin', 'hench arm spin' + diffStr + 'PINK', 24, false);
								particle.animation.play('armSpin', true);
								particle.scrollFactor.set(0.4, 0.4);
								particle.antialiasing = ClientPrefs.globalAntialiasing;
								addGroup('grpLimoParticles', particle);

								var particle:FlxSprite = new FlxSprite(dancers[i].x + 50, dancers[i].y);
								particle.frames = Paths.getSparrowAtlas("stages/limo/gore/noooooo");
								particle.animation.addByPrefix('headSpin', 'hench head spin' + diffStr + 'PINK', 24, false);
								particle.animation.play('headSpin', true);
								particle.scrollFactor.set(0.4, 0.4);
								particle.antialiasing = ClientPrefs.globalAntialiasing;
								addGroup('grpLimoParticles', particle);

								var particle:FlxSprite = new FlxSprite(dancers[i].x - 110, dancers[i].y + 20);
								particle.frames = Paths.getSparrowAtlas("stages/limo/gore/stupidBlood");
								particle.animation.addByPrefix('bloody', 'blood', 24, false);
								particle.animation.play('bloody', true);
								particle.scrollFactor.set(0.4, 0.4);
								particle.flipX = true;
								particle.angle = -57.5;
								addGroup('grpLimoParticles', particle);
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
					limoKillingState = 'SPEEDING OFFSCREEN';
				}
			case 'SPEEDING OFFSCREEN':
				limoSpeed -= 4000 * elapsed;
				bgLimo.x -= limoSpeed * elapsed;
				if(bgLimo.x > FlxG.width * 1.5) {
					limoSpeed = 3000;
					limoKillingState = 'SPEEDING';
				}
			case 'SPEEDING':
				limoSpeed -= 2000 * elapsed;
				if(limoSpeed < 1000) limoSpeed = 1000;

				bgLimo.x -= limoSpeed * elapsed;
				if(bgLimo.x < -275) {
					limoKillingState = 'STOPPING';
					limoSpeed = 800;
				}

				var dancers:Array<FlxSprite> = game.getLuaGroup('grpLimoDancers').members;
				for (i in 0...dancers.length) {
					dancers[i].x = (370 * i) + dancersDiff + bgLimo.x;
				}
			case 'STOPPING':
				bgLimo.x = FlxMath.lerp(bgLimo.x, -150, CoolUtil.boundTo(elapsed * 9, 0, 1));
				if(Math.round(bgLimo.x) == -150) {
					bgLimo.x = -150;
					limoKillingState = 'WAIT';
				}

				var dancers:Array<FlxSprite> = game.getLuaGroup('grpLimoDancers').members;
				for (i in 0...dancers.length) {
					dancers[i].x = (370 * i) + dancersDiff + bgLimo.x;
				}
			default:
				//nothing
		}
	}
}


var danceDir:Bool = false;
function beatHit() {
	if(!ClientPrefs.lowQuality) {
		game.getLuaGroup('grpLimoDancers').forEach(function(dancer:BackgroundDancer)
		{
			dancer.dance();
		});

		if (FlxG.random.bool(1)) //real
			killHenchmen();
	}



	if (FlxG.random.bool(10) && fastCarCanDrive)
		fastCarDrive();
}

function event(eventName:String, value1:String, value2:String)
{
	switch(eventName)
	{
		case "Kill Henchmen":
			killHenchmen();
	}
}

function resetLimoKill():Void
{
	limoMetalPole.x = -500;
	limoMetalPole.visible = false;
	limoLight.x = -500;
	limoLight.visible = false;
	limoCorpse.x = -500;
	limoCorpse.visible = false;
	limoCorpseTwo.x = -500;
	limoCorpseTwo.visible = false;
}


var carTimer:FlxTimer;
function fastCarDrive()
{
	//trace('Car drive');
	if(fastCar != null)
	{
		FlxG.sound.play(Paths.soundRandom('carPass', 0, 1), 0.7);

		fastCar.velocity.x = (FlxG.random.int(170, 220) / FlxG.elapsed) * 3;
		fastCarCanDrive = false;
		carTimer = new FlxTimer().start(2, function(tmr:FlxTimer)
		{
			resetFastCar();
			carTimer = null;
		});
	}
}

function resetFastCar():Void
{
	if(fastCar != null)
	{
		fastCar.x = -12600;
		fastCar.y = FlxG.random.int(140, 250);
		fastCar.velocity.x = 0;
		fastCarCanDrive = true;
	}
}


function killHenchmen():Void
{
	if(!ClientPrefs.lowQuality) {
		switch(limoKillingState)
		{
			default:
				//Nothing
			case 'WAIT':
				limoMetalPole.x = -400;
				limoMetalPole.visible = true;
				limoLight.visible = true;
				limoCorpse.visible = false;
				limoCorpseTwo.visible = false;
				limoKillingState = 'KILLING';

				Achievements.henchmenDeath++;
				FlxG.save.data.henchmenDeath = Achievements.henchmenDeath;
				var achieve:String = game.checkForAchievement(['roadkill_enthusiast']);
				if (achieve != null) {
					game.startAchievement(achieve);
				} else {
					FlxG.save.flush();
				}
				FlxG.log.add('Deaths: ' + Achievements.henchmenDeath);
		}
	}
}