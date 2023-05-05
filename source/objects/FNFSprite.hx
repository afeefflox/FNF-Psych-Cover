package objects;

import flixel.FlxG;
import flixel.math.FlxMatrix;
import flixel.math.FlxRect;
import flixel.math.FlxPoint;
import flixel.FlxCamera;
import flixel.math.FlxMath;
import flixel.FlxSprite;
import flixel.util.FlxDestroyUtil;
import util.CoolUtil;
//**Based on Codename engine but slighty diffrent uhh ;-;**/
class FNFSprite extends FlxSprite
{
    public var animateAtlas:FlxAnimate;

    function getPaths(key:String, ?library:String) {
		#if MODS_ALLOWED
		if (sys.FileSystem.exists(Paths.getModsPath(key, library)))
			return Paths.getModsPath(key, library);
		#end
        return Paths.getPath(key, TEXT, library);
    }

    public function loadFrames(key:String, ?library:String = null) {
        if (Paths.fileExists('images/$key/Animation.json', TEXT, false, library) 
            && Paths.fileExists('images/$key/spritemap1.json', TEXT, false, library) 
            && Paths.fileExists('images/$key/spritemap1.png', IMAGE, false, library) ) {
                animateAtlas = new FlxAnimate(x, y, key, library);
            }
        else {
            frames = CoolUtil.loadFrames(key, library);
        }
    }

    public override function update(elapsed:Float) {
        super.update(elapsed);
        if (animateAtlas != null)
            animateAtlas.update(elapsed);
    }
    
    public override function draw() {
        if (animateAtlas != null) {
            animateAtlas.draw();
        } else {
            super.draw();
        }
    }

    public override function destroy() {
        super.destroy();
        if (animateAtlas != null) {
            animateAtlas.destroy();
        }
    }
    

    public function playAnim(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0):Void
    {
        if (AnimName == null) return;

        if (animateAtlas != null)  {
            animateAtlas.animation.play(AnimName, Force, Reversed, Frame);
        }
        else
        {
            animation.play(AnimName, Force, Reversed, Frame);
        }
    }

    public inline function existsAnimation(AnimName:String):Bool
    {
        @:privateAccess
        return animateAtlas != null ? animateAtlas.animation.getByName(AnimName) != null : animation.getByName(AnimName) != null;
    }

    public function getAnimName():String
    {
        var name = null;
        if (animateAtlas != null) {
            if (animateAtlas.animation.curAnim != null)
            {
                name = animateAtlas.animation.curAnim.name;
            }
            
        } else {
            if (animation.curAnim != null)
                name = animation.curAnim.name;
        }
        return name;
    }

    public inline function isAnimFinished() {
        return animateAtlas != null ? (animateAtlas.animation.curAnim != null ? animateAtlas.animation.curAnim.finished : true) : (animation.curAnim != null ? animation.curAnim.finished : true);
    }
}