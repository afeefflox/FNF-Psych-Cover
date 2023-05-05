
function create()
{
    makeLuaGroup('grpBgGhouls');

    
    var bg:FlxSprite = new FlxSprite(400, 200);
    if(!ClientPrefs.lowQuality) {
        bg.frames = Paths.getSparrowAtlas('stages/school/animatedEvilSchool');
        bg.animation.addByPrefix('idle', 'background 2', 24, true);
        bg.animation.play('idle');
        bg.scrollFactor.set(0.8, 0.9);
        bg.antialiasing = false;
        bg.scale.set(6, 6);
        add(bg);
        
        addLuaGroup('grpBgGhouls');
        
        var bgGhouls = new FlxSprite(-100, 190);
        bgGhouls.frames = Paths.getSparrowAtlas('stages/school/bgGhouls');
        bgGhouls.animation.addByPrefix('idle', 'BG freaks glitch instance', 24, false);
        bgGhouls.scrollFactor.set(0.8, 0.9);
        bgGhouls.setGraphicSize(Std.int(bgGhouls.width * 6));
        bgGhouls.updateHitbox();
        bgGhouls.alpha = 0;
        bgGhouls.antialiasing = false;
        addGroup('grpBgGhouls', bgGhouls);
    } else {
        bg.loadGraphic(Paths.image('stages/school/animatedEvilSchool_low'));
        bg.scrollFactor.set(0.8, 0.9);
        bg.antialiasing = false;
        bg.scale.set(6, 6);
        add(bg);
    }
}

function event(eventName:String, value1:String, value2:String)
{
    switch(eventName)
    {
        case 'Trigger BG Ghouls':
            game.getLuaGroup('grpBgGhouls').forEach(function(spr:FlxSprite)
            {
                spr.animation.play('idle', true);
                spr.alpha = 1;
                if(spr.animation.curAnim.finished) {
                    spr.alpha = 0;
                }
            });
    }
}