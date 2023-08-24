
//Discord API
#if desktop
import Discord;
#end

//Psych
#if MODS_ALLOWED import util.Mods; #end

#if LUA_ALLOWED
import llua.*;
import llua.Lua;
#end

import MusicBeat;
import Paths;
import util.Controls;
import util.CoolUtil;
import MusicBeat;
import util.CustomFadeTransition;
import util.Conductor;
import util.Difficulty;

import objects.Alphabet;
import objects.BGSprite;

import meta.state.PlayState;
import meta.state.LoadingState;
import util.Highscore;

//Flixel
#if (flixel >= "5.3.0")
import flixel.sound.FlxSound;
#else
import flixel.system.FlxSound;
#end
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.group.FlxSpriteGroup;
import flixel.group.FlxGroup.FlxTypedGroup;

using StringTools;