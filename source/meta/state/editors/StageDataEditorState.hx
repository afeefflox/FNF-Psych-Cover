package meta.state.editors;
import objects.Character;

import MusicBeat;
import util.StageData;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import objects.Stage;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.ui.FlxInputText;
import flixel.addons.ui.FlxUI9SliceSprite;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUINumericStepper;
import flixel.addons.ui.FlxUISlider;
import flixel.addons.ui.FlxUITabMenu;
import flixel.addons.ui.FlxUITooltip.FlxUITooltipStyle;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxButton;
import flixel.ui.FlxSpriteButton;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import lime.media.AudioBuffer;
import lime.utils.Assets;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.media.Sound;
import openfl.net.FileReference;
import openfl.utils.Assets as OpenFlAssets;
import openfl.utils.ByteArray;
import util.FlxUIDropDownMenuCustom;
import util.CoolUtil;
import meta.state.PlayState;
import objects.HealthIcon;
import objects.AttachedSprite;
import flixel.util.FlxStringUtil;
import flixel.system.debug.interaction.tools.Pointer.GraphicCursorCross;
import flixel.graphics.FlxGraphic;
import flixel.FlxCamera;
import flixel.FlxBasic;
import Discord;
#if sys
import sys.FileSystem;

#end

using StringTools;

class StageDataEditorState extends MusicBeatState {
    public var camera_position:Map<String,FlxPoint> = [
		"boyfriend"=> FlxPoint.get(0, 0),
		"dad"=> FlxPoint.get(0, 0),
		"gf"=> FlxPoint.get(0, 0),
	];

	public static var instance:StageDataEditorState;
    public var stageGroup:FlxTypedGroup<FlxBasic>;
	public var boyfriendGroup:FlxSpriteGroup;
	public var dadGroup:FlxSpriteGroup;
	public var gfGroup:FlxSpriteGroup;

    public var boyfriendLayer:FlxTypedGroup<FlxBasic>;
	public var dadLayer:FlxTypedGroup<FlxBasic>;
	public var gfLayer:FlxTypedGroup<FlxBasic>;

    var dad:FakeCharacter;
    var boyfriend:FakeCharacter;
    var gf:FakeCharacter;
	var stage:Stage;

    var daStage:String = '';
    var daCharacter:String = 'bf';
    var goToPlayState:Bool = true;
    var camFollow:FlxObject;
    var cameraFollowPointer:FlxSprite;
    var dumbTexts:FlxTypedGroup<FlxText>;

    var UI_box:FlxUITabMenu;
	var UI_stagebox:FlxUITabMenu;

    private var camEditor:FlxCamera;
	private var camHUD:FlxCamera;
	private var camMenu:FlxCamera;


    var characterList:Array<String> = [];
    var stageList:Array<String> = [];

    //StageData
    var stageData:StageFile;
    public var defaultCamZoom:Float = 1.05;
    public var boyfriendCameraOffset:Array<Float> = null;
	public var opponentCameraOffset:Array<Float> = null;
	public var girlfriendCameraOffset:Array<Float> = null;
	public var cameraSpeed:Float = 1;
    public var BF_X:Float = 770;
	public var BF_Y:Float = 100;
	public var DAD_X:Float = 100;
	public var DAD_Y:Float = 100;
	public var GF_X:Float = 400;
	public var GF_Y:Float = 130;


    //Block Input
    private var blockPressWhileTypingOn:Array<FlxUIInputText> = [];
	private var blockPressWhileTypingOnStepper:Array<FlxUINumericStepper> = [];
	private var blockPressWhileScrolling:Array<FlxUIDropDownMenuCustom> = [];

    //Current Stuff
    var curCharIndex:Int = 0;
    var curChars:Array<FakeCharacter>;
    var curGroups:Array<FlxSpriteGroup>;
    var curCameras:Array<FlxPoint>;

    var curChar:FakeCharacter;
    var curCamera:FlxPoint;
    var curGroup:FlxSpriteGroup;


	public function new(?daStage:String = 'stage', ?goToPlayState:Bool = true)
	{
		super();
		this.daStage = daStage;
		this.goToPlayState = goToPlayState;
	}

    override function create()
    {
		instance = this;
        loadStageData();

        camEditor = new FlxCamera();
		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		camMenu = new FlxCamera();
		camMenu.bgColor.alpha = 0;

		FlxG.cameras.reset(camEditor);
		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.add(camMenu, false);
		FlxG.cameras.setDefaultDrawTarget(camEditor, true);

        stageGroup = new FlxTypedGroup<FlxBasic>();
		boyfriendGroup = new FlxSpriteGroup(BF_X, BF_Y);
		dadGroup = new FlxSpriteGroup(DAD_X, DAD_Y);
		gfGroup = new FlxSpriteGroup(GF_X, GF_Y);

		//Layers
		boyfriendLayer = new FlxTypedGroup<FlxBasic>();
		dadLayer = new FlxTypedGroup<FlxBasic>();
		gfLayer = new FlxTypedGroup<FlxBasic>();

        add(stageGroup);

		add(gfGroup);
		add(gfLayer);

		add(dadGroup);
		add(dadLayer);

		
		add(boyfriendGroup);
		add(boyfriendLayer);

		reloadStage();

		gf = new FakeCharacter().setCharacter('gf');
		startCharacterPos(gf);
		gf.scrollFactor.set(0.95, 0.95);
		gfGroup.add(gf);

        dad = new FakeCharacter().setCharacter('dad');
		startCharacterPos(dad, true);
		dadGroup.add(dad);


		boyfriend = new FakeCharacter().setCharacter('boyfriend', true);
		startCharacterPos(boyfriend);
		boyfriendGroup.add(boyfriend);

        curChars = [dad, boyfriend, gf];
		curChar = curChars[curCharIndex];

        curGroups = [dadGroup, boyfriendGroup, gfGroup];
        curGroup = curGroups[curCharIndex];

        curCameras = [camera_position.get('dad'), camera_position.get('boyfriend'), camera_position.get('gf')];
        curCamera = curCameras[curCharIndex];

        var pointer:FlxGraphic = FlxGraphic.fromClass(GraphicCursorCross);
		cameraFollowPointer = new FlxSprite().loadGraphic(pointer);
		cameraFollowPointer.setGraphicSize(40, 40);
		cameraFollowPointer.updateHitbox();
		cameraFollowPointer.color = FlxColor.WHITE;
		add(cameraFollowPointer);

        dumbTexts = new FlxTypedGroup<FlxText>();
		add(dumbTexts);
		dumbTexts.cameras = [camHUD];
        genBoyOffsets();

        camFollow = new FlxObject(0, 0, 2, 2);
		camFollow.screenCenter();
		add(camFollow);

        var tipTextArray:Array<String> = "
        E/Q - Camera Zoom In/Out
		\nR - Reset Camera Zoom
		\nJKLI - Move Camera
		\nW/S - Previous/Next Character
		\nArrow Keys - Move Character Postions
		\nT - Reset Current Character Postions
		\nHold Shift to Move 10x faster
        \nHold Control to Move 100x faster...
        \n".split('\n');

        for (i in 0...tipTextArray.length-1)
		{
			var tipText:FlxText = new FlxText(FlxG.width - 320, FlxG.height - 15 - 16 * (tipTextArray.length - i), 300, tipTextArray[i], 12);
			tipText.cameras = [camHUD];
			tipText.setFormat(null, 12, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE_FAST, FlxColor.BLACK);
			tipText.scrollFactor.set();
			tipText.borderSize = 1;
			add(tipText);
		}

        FlxG.camera.follow(camFollow);

        var tabs = [
			{name: 'Settings', label: 'Settings'},
		];

		UI_box = new FlxUITabMenu(null, tabs, true);
		UI_box.cameras = [camMenu];
		UI_box.resize(250, 150);
		UI_box.x = FlxG.width - 275;
		UI_box.y = -25;
		UI_box.scrollFactor.set();

        
		var tabs = [
			{name: 'Stage', label: 'Stage'},
			{name: 'Character', label: 'Character'}
		];

        UI_stagebox = new FlxUITabMenu(null, tabs, true);
		UI_stagebox.cameras = [camMenu];
		UI_stagebox.resize(350, 350);
		UI_stagebox.x = UI_box.x - 100;
		UI_stagebox.y = UI_box.y + UI_box.height;
		UI_stagebox.scrollFactor.set();
		add(UI_stagebox);
		add(UI_box);

        addSettingsUI();
        addStageUI();
        addCharacterUI();

        UI_stagebox.selected_tab_id = 'Stage';
        FlxG.mouse.visible = true;
        reloadStageOptions();

        super.create();
    }

    var stageDropDown:FlxUIDropDownMenuCustom;
    function addSettingsUI() {
        var tab_group = new FlxUI(null, UI_box);
		tab_group.name = "Settings";
        stageDropDown = new FlxUIDropDownMenuCustom(10, 30, FlxUIDropDownMenuCustom.makeStrIdLabelArray([''], true), function(stage:String)
		{
			daStage = stageList[Std.parseInt(stage)];
			reloadStage();
            loadStageData();
			reloadStageOptions();
			updatePresence();
			reloadStageDropDown();
		});
		stageDropDown.selectedLabel = daStage;
		reloadStageDropDown();
		blockPressWhileScrolling.push(stageDropDown);

        var reloadStage:FlxButton = new FlxButton(140, 20, "Reload Stage", function()
		{
            reloadStage();
            loadStageData();
			reloadStageOptions();
			reloadStageDropDown();
		});

        tab_group.add(new FlxText(stageDropDown.x, stageDropDown.y - 18, 0, 'Stage:'));
        tab_group.add(reloadStage);
		tab_group.add(stageDropDown);
        UI_box.addGroup(tab_group);
    } 

    var gfHideCheckBox:FlxUICheckBox;
	var isPixelStageCheckBox:FlxUICheckBox;

	var defaultZoomStepper:FlxUINumericStepper;
	var cameraSpeedStepper:FlxUINumericStepper;
    function addStageUI()
    {
        var tab_group = new FlxUI(null, UI_box);
		tab_group.name = "Stage";

        gfHideCheckBox = new FlxUICheckBox(15, 30, null, null, "GF Hide", 50);
		gfHideCheckBox.checked = !gf.visible;
        if(stageData.hide_girlfriend) gfHideCheckBox.checked = !gfHideCheckBox.checked;
		gfHideCheckBox.callback = function()
		{
			stageData.hide_girlfriend = !stageData.hide_girlfriend;
			gf.visible = !gf.visible;
		};

		isPixelStageCheckBox = new FlxUICheckBox(15, gfHideCheckBox.y + 35, null, null, "is Pixel Stage", 50);
		isPixelStageCheckBox.callback = function() {
            stageData.isPixelStage = !stageData.isPixelStage;
		};

        defaultZoomStepper = new FlxUINumericStepper(15, isPixelStageCheckBox.y + 45, 0.1, 0.9, 0, 999, 1);
		blockPressWhileTypingOnStepper.push(defaultZoomStepper);

        //I mean zero don't even move lol
        cameraSpeedStepper = new FlxUINumericStepper(15, defaultZoomStepper.y + 55, 1, 1, 0, 100, 1);
		blockPressWhileTypingOnStepper.push(cameraSpeedStepper);

		var saveCharacterButton:FlxButton = new FlxButton(cameraSpeedStepper.x + 210, cameraSpeedStepper.y - 3, "Save Stage", function() {
			saveStage();
		});


        tab_group.add(new FlxText(cameraSpeedStepper.x, cameraSpeedStepper.y - 18, 0, 'Camera Speed:'));
        tab_group.add(new FlxText(defaultZoomStepper.x, defaultZoomStepper.y - 18, 0, 'Camera Zoom:'));
        tab_group.add(gfHideCheckBox);
        tab_group.add(defaultZoomStepper);
		tab_group.add(cameraSpeedStepper);
		tab_group.add(isPixelStageCheckBox);
        UI_stagebox.addGroup(tab_group);
    }

    var positionCameraXStepper:FlxUINumericStepper;
	var positionCameraYStepper:FlxUINumericStepper;
	var positionXStepper:FlxUINumericStepper;
	var positionYStepper:FlxUINumericStepper;
    var characterDropDown:FlxUIDropDownMenuCustom;
    function addCharacterUI()
    {
        var tab_group = new FlxUI(null, UI_box);
		tab_group.name = "Character";
        characterDropDown = new FlxUIDropDownMenuCustom(10, 30, FlxUIDropDownMenuCustom.makeStrIdLabelArray([''], true), function(character:String)
		{
            if(curChar != null && curGroup != null)
            {
                curChar.setCharacter(characterList[Std.parseInt(character)]);
                if(curChar.isPlayer)
                    curChar.setPosition(curChar.playerPositionArray[0] + curGroup.x, curChar.playerPositionArray[1] + curGroup.y);
                else
                    curChar.setPosition(curChar.positionArray[0] + curGroup.x, curChar.positionArray[1] + curGroup.y);

            }
			reloadCharacterDropDown();
		});
		characterDropDown.selectedLabel = daCharacter;
		reloadCharacterDropDown();
		blockPressWhileScrolling.push(characterDropDown);

		positionXStepper = new FlxUINumericStepper(95, characterDropDown.y + 35, 10, curGroup.x, -9000, 9000, 0);
		positionYStepper = new FlxUINumericStepper(positionXStepper.x + 60, positionXStepper.y, 10, curGroup.y, -9000, 9000, 0);
		blockPressWhileTypingOnStepper.push(positionXStepper);
		blockPressWhileTypingOnStepper.push(positionYStepper);

        positionCameraXStepper = new FlxUINumericStepper(positionXStepper.x, positionXStepper.y + 40, 10, curCamera.x, -9000, 9000, 0);
		positionCameraYStepper = new FlxUINumericStepper(positionYStepper.x, positionYStepper.y + 40, 10, curCamera.y, -9000, 9000, 0);
		blockPressWhileTypingOnStepper.push(positionCameraXStepper);
		blockPressWhileTypingOnStepper.push(positionCameraYStepper);

        tab_group.add(new FlxText(characterDropDown.x, characterDropDown.y - 18, 0, 'Character:'));
		tab_group.add(new FlxText(positionXStepper.x, positionXStepper.y - 18, 0, 'Character X/Y:'));
		tab_group.add(new FlxText(positionCameraXStepper.x, positionCameraXStepper.y - 18, 0, 'Character Camera X/Y:'));
        tab_group.add(characterDropDown);
        tab_group.add(positionXStepper);
        tab_group.add(positionYStepper);
        tab_group.add(positionCameraXStepper);
        tab_group.add(positionCameraYStepper);
        UI_stagebox.addGroup(tab_group);
    }
    function startCharacterPos(char:FakeCharacter, ?gfCheck:Bool = false)
    {
		if(gfCheck && char.curCharacter.startsWith('gf')) { //IF DAD IS GIRLFRIEND, HE GOES TO HER POSITION
			char.setPosition(GF_X, GF_Y);
			char.scrollFactor.set(0.95, 0.95);
		}
		if(char.isPlayer)
		{
			char.x += char.playerPositionArray[0];
			char.y += char.playerPositionArray[1];
		}
		else
		{
			char.x += char.positionArray[0];
			char.y += char.positionArray[1];
		}
    }

    function reloadStage()
    {
		if(boyfriendLayer != null)
		{
			var i:Int = boyfriendLayer.members.length-1;
			while(i >= 0) {
				var memb:FlxBasic = boyfriendLayer.members[i];
				if(memb != null) {
					memb.kill();
					boyfriendLayer.remove(memb);
					memb.destroy();
				}
				--i;
			}
		}
        boyfriendLayer.clear();

		if(dadLayer != null)
		{
			var i:Int = dadLayer.members.length-1;
			while(i >= 0) {
				var memb:FlxBasic = dadLayer.members[i];
				if(memb != null) {
					memb.kill();
					dadLayer.remove(memb);
					memb.destroy();
				}
				--i;
			}
		}
        dadLayer.clear();

		if(gfLayer != null)
		{
			var i:Int = gfLayer.members.length-1;
			while(i >= 0) {
				var memb:FlxBasic = gfLayer.members[i];
				if(memb != null) {
					memb.kill();
					gfLayer.remove(memb);
					memb.destroy();
				}
				--i;
			}
		}
        gfLayer.clear();

		if(stageGroup != null)
		{
			var i:Int = stageGroup.members.length-1;
			while(i >= 0) {
				var memb:FlxBasic = stageGroup.members[i];
				if(memb != null) {
					memb.kill();
					stageGroup.remove(memb);
					memb.destroy();
				}
				--i;
			}
		}
        stageGroup.clear();

        stage = new Stage(daStage);
		stageGroup.add(stage);
		gfLayer.add(stage.layers.get('gf'));
		dadLayer.add(stage.layers.get('dad'));
		boyfriendLayer.add(stage.layers.get('boyfriend'));
    }

    function loadStageData()
	{
		stageData = StageData.getStageFile(daStage);
		if(stageData == null) { //Stage couldn't be found, create a dummy stage for preventing a crash
			stageData = {
				directory: "",
				defaultZoom: 0.9,
				isPixelStage: false,

				boyfriend: [770, 100],
				girlfriend: [400, 130],
				opponent: [100, 100],
				hide_girlfriend: false,

				camera_boyfriend: [0, 0],
				camera_opponent: [0, 0],
				camera_girlfriend: [0, 0],
				camera_speed: 1
			};
		}

		defaultCamZoom = stageData.defaultZoom;
		BF_X = stageData.boyfriend[0];
		BF_Y = stageData.boyfriend[1];
		GF_X = stageData.girlfriend[0];
		GF_Y = stageData.girlfriend[1];
		DAD_X = stageData.opponent[0];
		DAD_Y = stageData.opponent[1];

		if(stageData.camera_speed != null)
			cameraSpeed = stageData.camera_speed;

		boyfriendCameraOffset = stageData.camera_boyfriend;
		if(boyfriendCameraOffset == null) //Fucks sake should have done it since the start :rolling_eyes:
			boyfriendCameraOffset = [0, 0];

		opponentCameraOffset = stageData.camera_opponent;
		if(opponentCameraOffset == null)
			opponentCameraOffset = [0, 0];

		girlfriendCameraOffset = stageData.camera_girlfriend;
		if(girlfriendCameraOffset == null)
			girlfriendCameraOffset = [0, 0];
	}

    function reloadStageOptions()
    {
        if(UI_stagebox != null) {
            gfHideCheckBox.checked = stageData.hide_girlfriend;
            isPixelStageCheckBox.checked = stageData.isPixelStage;
            defaultZoomStepper.value = defaultCamZoom;
			boyfriendGroup.setPosition(BF_X, BF_Y);
			gfGroup.setPosition(GF_X, GF_Y);
			dadGroup.setPosition(DAD_X, DAD_Y);
			camera_position.get('boyfriend').x = boyfriendCameraOffset[0];
			camera_position.get('boyfriend').y = boyfriendCameraOffset[1];
			camera_position.get('dad').x = opponentCameraOffset[0];
			camera_position.get('dad').y = opponentCameraOffset[1];
			camera_position.get('gf').x = girlfriendCameraOffset[0];
			camera_position.get('gf').y = girlfriendCameraOffset[1];
			genBoyOffsets();
			updatePresence();
            updatePointerPos();
        }
    }

	override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>) {
		if(id == FlxUINumericStepper.CHANGE_EVENT && (sender is FlxUINumericStepper)) {
			if(sender == defaultZoomStepper)
			{
				sender.value = FlxG.camera.zoom;
			}
			else if(sender == cameraSpeedStepper)
			{
				sender.value = cameraSpeed;
			}
			else if(sender == positionXStepper)
			{
				curGroup.x = sender.value;
				updatePointerPos();
				genBoyOffsets();
			}
			else if(sender == positionYStepper)
			{
				curGroup.y = sender.value;
				updatePointerPos();
				genBoyOffsets();
			}
			else if(sender == positionCameraXStepper)
			{
				curCamera.x = sender.value;
				updatePointerPos();
				genBoyOffsets();
			}
			else if(sender == positionCameraXStepper)
			{
				curCamera.y = sender.value;
				updatePointerPos();
				genBoyOffsets();
			}
		}
	}

	function genBoyOffsets()
	{
		var i:Int = dumbTexts.members.length-1;
        while(i >= 0) {
            var memb:FlxText = dumbTexts.members[i];
            if(memb != null) {
                memb.kill();
                dumbTexts.remove(memb);
                memb.destroy();
            }
            --i;
        }
        dumbTexts.clear();

        for (i in 0...12)
        {
            var text:FlxText = new FlxText(10, 48 + (i * 30), 0, '', 24);
            text.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
            text.scrollFactor.set();
            text.borderSize = 2;
            dumbTexts.add(text);
            text.cameras = [camHUD];

            if(i > 1)
            {
                text.y += 24;
            }
        }

        for (i in 0...dumbTexts.length)
		{
			switch(i)
            {
                case 0: dumbTexts.members[i].text = 'Boyfriend Positions:';
                case 1: dumbTexts.members[i].text = '[' + boyfriendGroup.x + ', ' + boyfriendGroup.y + ']';
                case 2: dumbTexts.members[i].text = 'GirlFriend Positions:';
                case 3: dumbTexts.members[i].text = '[' + gfGroup.x + ', ' + gfGroup.y + ']';
                case 4: dumbTexts.members[i].text = 'Opponent Positions:';
                case 5: dumbTexts.members[i].text = '[' + dadGroup.x + ', ' + dadGroup.y + ']';
                case 6: dumbTexts.members[i].text = 'Boyfriend Camera Positions:';
                case 7: dumbTexts.members[i].text = '[' + camera_position.get("boyfriend").x  + ', ' +  camera_position.get("boyfriend").y  + ']';
                case 8: dumbTexts.members[i].text = 'Girlfriend Camera Positions:';
                case 9: dumbTexts.members[i].text = '[' + camera_position.get("gf").x  + ', ' +  camera_position.get("gf").y  + ']';
                case 10: dumbTexts.members[i].text = 'Opponent Camera Positions:';
                case 11: dumbTexts.members[i].text = '[' + camera_position.get("dad").x + ', ' +  camera_position.get("dad").y + ']';
            }
		}
	}

    function updatePointerPos() 
    {
		if(curChar == gf)
		{
			cameraFollowPointer.setPosition(curChar.getMidpoint().x, curChar.getMidpoint().y);
			cameraFollowPointer.x += curChar.cameraPosition[0] + curCamera.x;
			cameraFollowPointer.y += curChar.cameraPosition[1] + curCamera.y;
		}
		else if(curChar == boyfriend)
		{
			cameraFollowPointer.setPosition(curChar.getMidpoint().x - 100, curChar.getMidpoint().y - 100);
			cameraFollowPointer.x -= curChar.playerCameraPosition[0] - curCamera.x;
			cameraFollowPointer.y += curChar.playerCameraPosition[1] + curCamera.y;
		}
		else
		{
			cameraFollowPointer.setPosition(curChar.getMidpoint().x + 150, curChar.getMidpoint().y - 100);
			cameraFollowPointer.x += curChar.cameraPosition[0] + curCamera.x;
			cameraFollowPointer.y += curChar.cameraPosition[1] + curCamera.y;		
		}
    }
    

    function reloadCharacterDropDown() {
		var charsLoaded:Map<String, Bool> = new Map();

		#if MODS_ALLOWED
		characterList = [];
		var directories:Array<String> = [Paths.mods('characters/'), Paths.mods(Paths.currentModDirectory + '/characters/'), Paths.getPreloadPath('characters/')];
		for(mod in Paths.getGlobalMods())
			directories.push(Paths.mods(mod + '/characters/'));
		for (i in 0...directories.length) {
			var directory:String = directories[i];
			if(FileSystem.exists(directory)) {
				for (file in FileSystem.readDirectory(directory)) {
					var path = haxe.io.Path.join([directory, file]);
					if (!sys.FileSystem.isDirectory(path) && file.endsWith('.json')) {
						var charToCheck:String = file.substr(0, file.length - 5);
						if(!charsLoaded.exists(charToCheck)) {
							characterList.push(charToCheck);
							charsLoaded.set(charToCheck, true);
						}
					}
				}
			}
		}
		#else
		characterList = CoolUtil.coolTextFile(Paths.txt('characterList'));
		#end
	}

    function reloadStageDropDown() {
		var stageLoaded:Map<String, Bool> = new Map();

		#if MODS_ALLOWED
		stageList = [];
		var directories:Array<String> = [Paths.mods('stages/'), Paths.mods(Paths.currentModDirectory + '/stages/'), Paths.getPreloadPath('stages/')];
		for(mod in Paths.getGlobalMods())
			directories.push(Paths.mods(mod + '/stages/'));
		for (i in 0...directories.length) {
			var directory:String = directories[i];
			if(FileSystem.exists(directory)) {
				for (file in FileSystem.readDirectory(directory)) {
					var path = haxe.io.Path.join([directory, file]);
					if (!sys.FileSystem.isDirectory(path) && file.endsWith('.json')) {
						var charToCheck:String = file.substr(0, file.length - 5);
						if(!stageLoaded.exists(charToCheck)) {
							stageList.push(charToCheck);
							stageLoaded.set(charToCheck, true);
						}
					}
				}
			}
		}
		#else
		stageList = CoolUtil.coolTextFile(Paths.txt('stageList'));
		#end

		stageDropDown.setData(FlxUIDropDownMenuCustom.makeStrIdLabelArray(stageList, true));
		stageDropDown.selectedLabel = daStage;
	}

    function updatePresence() {
		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("Stage Data Editor", "Stage: " + daStage, null);
		#end
	}

    override function update(elapsed:Float)
    {
        var blockInput:Bool = false;
		for (inputText in blockPressWhileTypingOn) {
			if(inputText.hasFocus) {
				FlxG.sound.muteKeys = [];
				FlxG.sound.volumeDownKeys = [];
				FlxG.sound.volumeUpKeys = [];
				blockInput = true;
				break;
			}
		}

		if(!blockInput) {
			for (stepper in blockPressWhileTypingOnStepper) {
				@:privateAccess
				var leText:Dynamic = stepper.text_field;
				var leText:FlxUIInputText = leText;
				if(leText.hasFocus) {
					FlxG.sound.muteKeys = [];
					FlxG.sound.volumeDownKeys = [];
					FlxG.sound.volumeUpKeys = [];
					blockInput = true;
					break;
				}
			}
		}

		if(!blockInput) {

			for (dropDownMenu in blockPressWhileScrolling) {
				if(dropDownMenu.dropPanel.visible) {
					blockInput = true;
					break;
				}
			}
		}

		var colorSine:Float = 0;
		colorSine += elapsed;
		var colorVal:Float = 0.7 + Math.sin(Math.PI * colorSine) * 0.3;
		if(curChar == boyfriend) {
			curChar.color = FlxColor.fromRGBFloat(colorVal, colorVal, colorVal, 0.999);
		}
		else
		{
			boyfriend.color = FlxColor.WHITE;
		}

		if(curChar == gf) {
			curChar.color = FlxColor.fromRGBFloat(colorVal, colorVal, colorVal, 0.999);
		}
		else
		{
			gf.color = FlxColor.WHITE;
		}

		if(curChar == dad) {
			curChar.color = FlxColor.fromRGBFloat(colorVal, colorVal, colorVal, 0.999);
		}
		else
		{
			dad.color = FlxColor.WHITE;
		}
		

		if (curCharIndex < 0)
			curCharIndex = curChars.length - 1;

		if (curCharIndex >= curChars.length)
			curCharIndex = 0;

		curGroup = curGroups[curCharIndex];
		curCamera = curCameras[curCharIndex];
		curChar = curChars[curCharIndex];

        if(!blockInput) {
            FlxG.sound.muteKeys = TitleState.muteKeys;
			FlxG.sound.volumeDownKeys = TitleState.volumeDownKeys;
			FlxG.sound.volumeUpKeys = TitleState.volumeUpKeys;
            var lerpVal:Float = CoolUtil.boundTo(elapsed * 2.4 * cameraSpeed, 0, 1);

			if (FlxG.keys.justPressed.ESCAPE) {
				if(goToPlayState) {
					MusicBeatState.switchState(new PlayState());
				} else {
					MusicBeatState.switchState(new meta.state.editors.MasterEditorMenu());
					FlxG.sound.playMusic(Paths.music('freakyMenu'));
				}
				FlxG.mouse.visible = false;
				return;
			}

			if (FlxG.keys.justPressed.R) {
				FlxG.camera.zoom = 1;
			}

			if (FlxG.keys.pressed.E && FlxG.camera.zoom < 3) {
				FlxG.camera.zoom += elapsed * FlxG.camera.zoom;
				if(FlxG.camera.zoom > 3) FlxG.camera.zoom = 3;
			}
			if (FlxG.keys.pressed.Q && FlxG.camera.zoom > 0.1) {
				FlxG.camera.zoom -= elapsed * FlxG.camera.zoom;
				if(FlxG.camera.zoom < 0.1) FlxG.camera.zoom = 0.1;
			}

			if (FlxG.keys.pressed.I || FlxG.keys.pressed.J || FlxG.keys.pressed.K || FlxG.keys.pressed.L)
			{
				var addToCam:Float = 500 * elapsed;
				if (FlxG.keys.pressed.SHIFT)
					addToCam *= 4;

				if (FlxG.keys.pressed.I)
					camFollow.y -= addToCam;
				else if (FlxG.keys.pressed.K)
					camFollow.y += addToCam;

				if (FlxG.keys.pressed.J)
					camFollow.x -= addToCam;
				else if (FlxG.keys.pressed.L)
					camFollow.x += addToCam;
			}

			


            if (FlxG.keys.justPressed.W)
				curCharIndex -= 1;
				

			if (FlxG.keys.justPressed.S)
				curCharIndex += 1;

            if (FlxG.keys.justPressed.T)
            {
				if(curGroup == boyfriendGroup)
				{
					curGroup.x = BF_X;
					curGroup.y = BF_Y;
				}
				else if(curGroup == gfGroup)
				{
					curGroup.x = GF_X;
					curGroup.y = GF_Y;
				}
				else
				{
					curGroup.x = DAD_X;
					curGroup.y = DAD_Y;
				}
            }

            var controlArray:Array<Bool> = [FlxG.keys.justPressed.LEFT, FlxG.keys.justPressed.RIGHT, FlxG.keys.justPressed.UP, FlxG.keys.justPressed.DOWN];
            for (i in 0...controlArray.length) {
                if(controlArray[i]) {
                    var holdShift = FlxG.keys.pressed.SHIFT;
                    var holdControl = FlxG.keys.pressed.CONTROL;
                    var multiplier = 1;
                    if (holdShift)
                        multiplier = 10;
                    if(holdControl)
                        multiplier = 100;

                    var arrayVal = 0;
                    if(i > 1) arrayVal = 1;

                    var negaMult:Int = 1;
                    if(i % 2 == 1) negaMult = -1;


                    var postions:Array<Float> = [curGroup.x, curGroup.y];

                    postions[arrayVal] += negaMult * multiplier;
                    curGroup.x = postions[0];
                    curGroup.y = postions[1];
					updatePointerPos();
					genBoyOffsets();
                    
                }
            }
            
        }
        super.update(elapsed);
    }

	var _file:FileReference;
	function onSaveComplete(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.notice("Successfully saved file.");
	}

	/**
		* Called when the save file dialog is cancelled.
		*/
	function onSaveCancel(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
	}

	/**
		* Called if there is an error while saving the gameplay recording.
		*/
	function onSaveError(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.error("Problem saving file");
	}

	function saveStage() 
	{
		var json = {
			"directory": "",
			"defaultZoom": defaultCamZoom,
			"isPixelStage": stageData.isPixelStage,
		
			"boyfriend": [boyfriendGroup.x, boyfriendGroup.y],
			"girlfriend": [gfGroup.x, gfGroup.y],
			"opponent": [dadGroup.x, dadGroup.y],
			"hide_girlfriend": stageData.hide_girlfriend,
		
			"camera_boyfriend": [camera_position.get("boyfriend").x, camera_position.get("boyfriend").y],
			"camera_opponent": [camera_position.get("dad").x, camera_position.get("dad").y],
			"camera_girlfriend": [camera_position.get("gf").x, camera_position.get("gf").y],
			"camera_speed": cameraSpeed,
		};

		var data:String = haxe.Json.stringify(json, "\t");

		if (data.length > 0)
		{
			_file = new FileReference();
			_file.addEventListener(Event.COMPLETE, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data, daStage + ".json");
		}
	}
}