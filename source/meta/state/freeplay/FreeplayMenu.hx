package meta.state.freeplay;

import MusicBeat.MusicBeatState;
#if desktop
import Discord.DiscordClient;
#end
import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import lime.utils.Assets;
import flixel.FlxSubState;
import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxSave;
import haxe.Json;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import flixel.input.keyboard.FlxKey;
import flixel.graphics.FlxGraphic;
import objects.Alphabet;
using StringTools;
class FreeplayMenu extends MusicBeatState
{
    var freeplays:Array<String> = ['BETADCIU', 'Cover Songs', 'Freeplay'];
	private var grpFreeplays:FlxTypedGroup<Alphabet>;
	private static var curSelected:Int = 0;
	public static var menuBG:FlxSprite;

    function openSelectedSubstate(label:String) {
		switch(label) {
			case 'BETADCIU':
				MusicBeatState.switchState(new BETADCIUState());
			case 'Cover Songs':
				MusicBeatState.switchState(new CoverState());
			case 'Freeplay':
                MusicBeatState.switchState(new FreeplayState());
		}
	}

    var selectorLeft:Alphabet;
	var selectorRight:Alphabet;

    override function create()
    {
        #if desktop
		DiscordClient.changePresence("In Freeplay Menu", null);
		#end

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.color = 0xFF3d85c6;
		bg.updateHitbox();

		bg.screenCenter();
		bg.antialiasing = ClientPrefs.globalAntialiasing;
		add(bg);

		grpFreeplays = new FlxTypedGroup<Alphabet>();
		add(grpFreeplays);

        for (i in 0...freeplays.length)
		{
			var optionText:Alphabet = new Alphabet(0, 0, freeplays[i], true);
			optionText.screenCenter();
			optionText.y += (100 * (i - (freeplays.length / 2))) + 50;
			grpFreeplays.add(optionText);
		}

        selectorLeft = new Alphabet(0, 0, '>', true);
		add(selectorLeft);
		selectorRight = new Alphabet(0, 0, '<', true);
		add(selectorRight);

		changeSelection();

        super.create();
    }

    override function update(elapsed:Float) {
		super.update(elapsed);

		if (controls.UI_UP_P) {
			changeSelection(-1);
		}
		if (controls.UI_DOWN_P) {
			changeSelection(1);
		}

		if (controls.BACK) {
            MusicBeatState.switchState(new MainMenuState());
			FlxG.sound.play(Paths.sound('cancelMenu'));
		}

		if (controls.ACCEPT) {
			openSelectedSubstate(freeplays[curSelected]);
		}
	}

    function changeSelection(change:Int = 0) {
		curSelected += change;
		if (curSelected < 0)
			curSelected = freeplays.length - 1;
		if (curSelected >= freeplays.length)
			curSelected = 0;

		var bullShit:Int = 0;

		for (item in grpFreeplays.members) {
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;
			if (item.targetY == 0) {
				item.alpha = 1;
				selectorLeft.x = item.x - 63;
				selectorLeft.y = item.y;
				selectorRight.x = item.x + item.width + 15;
				selectorRight.y = item.y;
			}
		}
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}
}