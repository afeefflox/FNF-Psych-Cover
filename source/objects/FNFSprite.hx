package objects;

import flixel.FlxG;
import flxanimate.FlxAnimate;
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
    @:noCompletion public var atlasPlayingAnim:String;
    @:noCompletion public var atlasPath:String;

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
                //Do like this?
                animateAtlas = new FlxAnimate(x, y, getPaths('images/$key', library));
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

    //Flx Animate Stuff ;-;
    public override function draw() {
        if (animateAtlas != null) {
            copyAtlasValues();
            animateAtlas.draw();
        } else {
            super.draw();
        }
    }

    public function copyAtlasValues() {
        @:privateAccess {
            animateAtlas.cameras = cameras;
            animateAtlas.scrollFactor = scrollFactor;
            animateAtlas.scale = scale;
            animateAtlas.offset = offset;
            animateAtlas.x = x;
            animateAtlas.y = y;
            animateAtlas.angle = angle;
            animateAtlas.alpha = alpha;
            animateAtlas.visible = visible;
            animateAtlas.flipX = flipX;
            animateAtlas.flipY = flipY;
            animateAtlas.shader = shader;
            animateAtlas.antialiasing = antialiasing;
        }
    }

    public override function destroy() {
        super.destroy();
        if (animateAtlas != null) {
            animateAtlas = FlxDestroyUtil.destroy(animateAtlas);
        }
    }
    

    public function playAnim(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0):Void
    {
        if (AnimName == null) return;

        if (animateAtlas != null)  {
            @:privateAccess
            animateAtlas.anim.play(AnimName, Force, Reversed, Frame);
            atlasPlayingAnim = AnimName;
        }
        else
        {
            animation.play(AnimName, Force, Reversed, Frame);
        }
    }

    public inline function existsAnimation(AnimName:String):Bool
    {
        @:privateAccess
        return animateAtlas != null ? (animateAtlas.anim.animsMap.exists(AnimName) || animateAtlas.anim.symbolDictionary.exists(AnimName)) : animation.getByName(AnimName) != null;
    }

    public function getAnimName():String
    {
        var name = null;
        if (animateAtlas != null) {
            name = atlasPlayingAnim;
        } else {
            if (animation.curAnim != null)
                name = animation.curAnim.name;
        }
        return name;
    }

    public inline function isAnimFinished() {
        return animateAtlas != null ? (animateAtlas.anim.finished) : (animation.curAnim != null ? animation.curAnim.finished : true);
    }
}