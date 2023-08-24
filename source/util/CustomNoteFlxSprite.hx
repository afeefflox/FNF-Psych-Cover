package util;
import flixel.FlxSprite;
import util.RGBPalette;
import objects.Note;

class CustomNoteFlxSprite extends FlxSprite {
    public var rgbShader:RGBShaderReference;
    public function new(x:Float, y:Float, noteData:Int)
    {
        rgbShader = new RGBShaderReference(this, Note.initializeGlobalRGBShader(noteData));
        super(x, y);
    }
}
