package util;

import flixel.util.FlxColor;

class FlxColorHelper
{
    public static inline var TRANSPARENT:FlxColor = 0x00000000;
	public static inline var WHITE:FlxColor = 0xFFFFFFFF;
	public static inline var GRAY:FlxColor = 0xFF808080;
	public static inline var BLACK:FlxColor = 0xFF000000;

	public static inline var GREEN:FlxColor = 0xFF008000;
	public static inline var LIME:FlxColor = 0xFF00FF00;
	public static inline var YELLOW:FlxColor = 0xFFFFFF00;
	public static inline var ORANGE:FlxColor = 0xFFFFA500;
	public static inline var RED:FlxColor = 0xFFFF0000;
	public static inline var PURPLE:FlxColor = 0xFF800080;
	public static inline var BLUE:FlxColor = 0xFF0000FF;
	public static inline var BROWN:FlxColor = 0xFF8B4513;
	public static inline var PINK:FlxColor = 0xFFFFC0CB;
	public static inline var MAGENTA:FlxColor = 0xFFFF00FF;
	public static inline var CYAN:FlxColor = 0xFF00FFFF;

    public static inline function fromRGB(Red:Int, Green:Int, Blue:Int, Alpha:Int = 255):FlxColor
    {
        return FlxColor.fromRGB(Red, Green, Blue, Alpha);
    }

    public static inline function fromRGBFloat(Red:Float, Green:Float, Blue:Float, Alpha:Float = 1):FlxColor
	{
        return FlxColor.fromRGBFloat(Red, Green, Blue, Alpha);
	}

    public static inline function fromCMYK(Cyan:Float, Magenta:Float, Yellow:Float, Black:Float, Alpha:Float = 1):FlxColor
	{
		return FlxColor.fromCMYK(Cyan, Magenta, Yellow, Black, Alpha);
	}

    public static function fromHSB(Hue:Float, Saturation:Float, Brightness:Float, Alpha:Float = 1):FlxColor
	{
		return FlxColor.fromHSB(Hue, Saturation, Brightness, Alpha);
	}

    public static inline function fromHSL(Hue:Float, Saturation:Float, Lightness:Float, Alpha:Float = 1):FlxColor
	{
		return FlxColor.fromHSL(Hue, Saturation, Lightness, Alpha);
	}

    public static function fromString(str:String):Null<FlxColor>
	{
		return FlxColor.fromString(str);
	}

    public static function getHSBColorWheel(Alpha:Int = 255):Array<FlxColor>
    {
        return FlxColor.getHSBColorWheel(Alpha);
    }

    public static inline function interpolate(Color1:FlxColor, Color2:FlxColor, Factor:Float = 0.5):FlxColor
	{
		return FlxColor.interpolate(Color1, Color2, Factor);
	}

    public static function gradient(Color1:FlxColor, Color2:FlxColor, Steps:Int, ?Ease:Float->Float):Array<FlxColor>
	{
        return FlxColor.gradient(Color1, Color2, Steps, Ease);
	}

    public static inline function multiply(lhs:FlxColor, rhs:FlxColor):FlxColor
	{
		return FlxColor.multiply(lhs, rhs);
	}

    public static inline function add(lhs:FlxColor, rhs:FlxColor):FlxColor
    {
        return FlxColor.add(lhs, rhs);
    }

    public static inline function subtract(lhs:FlxColor, rhs:FlxColor):FlxColor
    {
        return FlxColor.subtract(lhs, rhs);
    }
}