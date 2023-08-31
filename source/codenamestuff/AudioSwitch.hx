package codenamestuff;

import lime.media.AudioManager;
import flixel.sound.FlxSound;
import flixel.FlxState;

/**
 * Code are from codename engine :sob:
 */
typedef PlayingSound = {
	var sound:FlxSound;
	var time:Float;
}

 class AudioSwitch {
	@:noCompletion
	private static function onStateSwitch(state:FlxState):Void {
        #if windows
        if (Main.audioDisconnected) {
            var playingList:Array<PlayingSound> = [];
            for(e in FlxG.sound.list) {
                if (e.playing) {
                    playingList.push({
                        sound: e,
                        time: e.time
                    });
                    e.stop();
                }
            }
            if (FlxG.sound.music != null)
                FlxG.sound.music.stop();

            AudioManager.shutdown();
            AudioManager.init();

            Main.changeID++;

            for(e in playingList) {
                e.sound.play(e.time);
            }

            Main.audioDisconnected = false;
        }
        #end
    }

    public static function init() {
		#if windows
		Main.audioDisconnected = false;
		FlxG.signals.preStateCreate.add(onStateSwitch);
		#end
	}
 }