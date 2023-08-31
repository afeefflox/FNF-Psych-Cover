package;

import flixel.graphics.FlxGraphic;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxState;
import openfl.Assets;
import openfl.Lib;
import openfl.display.FPS;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.display.StageScaleMode;
import lime.app.Application;
import meta.state.TitleState;
import util.script.Globals;
import codenamestuff.AudioSwitch;
#if desktop
import Discord.DiscordClient;
#end

//crash handler stuff
#if CRASH_HANDLER
import openfl.events.UncaughtErrorEvent;
import haxe.CallStack;
import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;
import sys.io.Process;
#end


using StringTools;

#if windows
@:buildXml('
<target id="haxe">
	<lib name="dwmapi.lib" if="windows" />
	<lib name="shell32.lib" if="windows" />
	<lib name="gdi32.lib" if="windows" />
	<lib name="ole32.lib" if="windows" />
	<lib name="uxtheme.lib" if="windows" />
</target>
')

// majority is taken from microsofts doc 
@:cppFileCode('
#include "mmdeviceapi.h"
#include "combaseapi.h"
#include <iostream>
#include <Windows.h>
#include <cstdio>
#include <tchar.h>
#include <dwmapi.h>
#include <winuser.h>
#include <Shlobj.h>
#include <wingdi.h>
#include <shellapi.h>
#include <uxtheme.h>

#define SAFE_RELEASE(punk)  \\
			  if ((punk) != NULL)  \\
				{ (punk)->Release(); (punk) = NULL; }

static long lastDefId = 0;

class AudioFixClient : public IMMNotificationClient {
	LONG _cRef;
	IMMDeviceEnumerator *_pEnumerator;
	
	public:
	AudioFixClient() :
		_cRef(1),
		_pEnumerator(NULL)
	{
		HRESULT result = CoCreateInstance(__uuidof(MMDeviceEnumerator),
							  NULL, CLSCTX_INPROC_SERVER,
							  __uuidof(IMMDeviceEnumerator),
							  (void**)&_pEnumerator);
		if (result == S_OK) {
			_pEnumerator->RegisterEndpointNotificationCallback(this);
		}
	}

	~AudioFixClient()
	{
		SAFE_RELEASE(_pEnumerator);
	}

	ULONG STDMETHODCALLTYPE AddRef()
	{
		return InterlockedIncrement(&_cRef);
	}

	ULONG STDMETHODCALLTYPE Release()
	{
		ULONG ulRef = InterlockedDecrement(&_cRef);
		if (0 == ulRef)
		{
			delete this;
		}
		return ulRef;
	}

	HRESULT STDMETHODCALLTYPE QueryInterface(
								REFIID riid, VOID **ppvInterface)
	{
		return S_OK;
	}

	HRESULT STDMETHODCALLTYPE OnDeviceAdded(LPCWSTR pwstrDeviceId)
	{
		return S_OK;
	};

	HRESULT STDMETHODCALLTYPE OnDeviceRemoved(LPCWSTR pwstrDeviceId)
	{
		return S_OK;
	}

	HRESULT STDMETHODCALLTYPE OnDeviceStateChanged(
								LPCWSTR pwstrDeviceId,
								DWORD dwNewState)
	{
		return S_OK;
	}

	HRESULT STDMETHODCALLTYPE OnPropertyValueChanged(
								LPCWSTR pwstrDeviceId,
								const PROPERTYKEY key)
	{
		return S_OK;
	}

	HRESULT STDMETHODCALLTYPE OnDefaultDeviceChanged(
		EDataFlow flow, ERole role,
		LPCWSTR pwstrDeviceId)
	{
		Main_obj::audioDisconnected = true;
		return S_OK;
	};
};

AudioFixClient *curAudioFix;
')
#end

class Main extends Sprite
{
	var game = {
		width: 1280, // WINDOW width
		height: 720, // WINDOW height
		initialState: TitleState, // initial game state
		zoom: -1.0, // game state bounds
		framerate: 60, // default framerate
		skipSplash: true, // if the default flixel splash screen should be skipped
		startFullscreen: false // if the game should start at fullscreen mode
	};

	public static var fpsVar:FPS;
	public static var changeID:Int = 0;
	public static var audioDisconnected:Bool = false;

	// You can pretty much ignore everything from here on - your code should go in your states.

	public static function main():Void
	{
		Lib.current.addChild(new Main());
	}

	public function new()
	{
		super();

		if (stage != null)
		{
			init();
		}
		else
		{
			addEventListener(Event.ADDED_TO_STAGE, init);
		}
	}

	private function init(?E:Event):Void
	{
		if (hasEventListener(Event.ADDED_TO_STAGE))
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
		}

		setupGame();
	}

	@:functionCode('
	if (!curAudioFix) curAudioFix = new AudioFixClient();
	')

	private function setupGame():Void
	{
		#if CRASH_HANDLER
		Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onCrash);
		#end

		var stageWidth:Int = Lib.current.stage.stageWidth;
		var stageHeight:Int = Lib.current.stage.stageHeight;

		if (game.zoom == -1.0)
		{
			var ratioX:Float = stageWidth / game.width;
			var ratioY:Float = stageHeight / game.height;
			game.zoom = Math.min(ratioX, ratioY);
			game.width = Math.ceil(stageWidth / game.zoom);
			game.height = Math.ceil(stageHeight / game.zoom);
		}

		#if LUA_ALLOWED Lua.set_callbacks_function(cpp.Callable.fromStaticFunction(CallbackHandler.call)); #end
		//Cache.init(); it kinda brokey
		Controls.instance = new Controls();
		ClientPrefs.loadDefaultKeys();
		addChild(new FlxGame(game.width, game.height, game.initialState, #if (flixel < "5.0.0") game.zoom, #end game.framerate, game.framerate, game.skipSplash, game.startFullscreen));
		
		#if !mobile
		fpsVar = new FPS(10, 3, 0xFFFFFF);
		addChild(fpsVar);
		Lib.current.stage.align = "tl";
		Lib.current.stage.scaleMode = StageScaleMode.NO_SCALE;
		if(fpsVar != null) {
			fpsVar.visible = ClientPrefs.showFPS;
		}
		#end

		AudioSwitch.init();

		#if html5
		FlxG.autoPause = false;
		FlxG.mouse.visible = false;
		#end
		
		#if desktop
		if (!DiscordClient.isInitialized) {
			DiscordClient.initialize();
			Application.current.window.onClose.add(function() {
				DiscordClient.shutdown();
			});
		}
		#end

		FlxG.signals.gameResized.add(function (w, h) {
			if (FlxG.cameras != null) {
			  for (cam in FlxG.cameras.list) {
			   @:privateAccess
			   if (cam != null && cam._filters != null)
				   resetSpriteCache(cam.flashSprite);
			  }
			}

			if (FlxG.game != null)
			resetSpriteCache(FlxG.game);
	   });
	}

	static function resetSpriteCache(sprite:Sprite):Void {
		@:privateAccess {
		        sprite.__cacheBitmap = null;
			sprite.__cacheBitmapData = null;
		}
	}

	// Code was entirely made by sqirra-rng for their fnf engine named "Izzy Engine", big props to them!!!
	// very cool person for real they don't get enough credit for their work
	#if CRASH_HANDLER
	function onCrash(e:UncaughtErrorEvent):Void
	{
		var errMsg:String = "";
		var path:String;
		var callStack:Array<StackItem> = CallStack.exceptionStack(true);
		var dateNow:String = Date.now().toString();

		dateNow = dateNow.replace(" ", "_");
		dateNow = dateNow.replace(":", "'");

		path = "./crash/" + "PsychEngine_" + dateNow + ".txt";

		for (stackItem in callStack)
		{
			switch (stackItem)
			{
				case FilePos(s, file, line, column):
					errMsg += file + " (line " + line + ")\n";
				default:
					Sys.println(stackItem);
			}
		}

		errMsg += "\nUncaught Error: " + e.error + "\nPlease report this error to the GitHub page: https://github.com/ShadowMario/FNF-PsychEngine\n\n> Crash Handler written by: sqirra-rng";

		if (!FileSystem.exists("./crash/"))
			FileSystem.createDirectory("./crash/");

		File.saveContent(path, errMsg + "\n");

		Sys.println(errMsg);
		Sys.println("Crash dump saved in " + Path.normalize(path));

		Application.current.window.alert(errMsg, "Error!");
		DiscordClient.shutdown();
		Sys.exit(1);
	}
	#end
}
