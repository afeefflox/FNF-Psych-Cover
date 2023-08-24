package meta.state.editors;

import MusicBeat;
#if desktop
import Discord.DiscordClient;
#end
import animateatlas.AtlasFrameMaker;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxCamera;
import flixel.input.keyboard.FlxKey;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.graphics.FlxGraphic;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.addons.ui.FlxInputText;
import flixel.addons.ui.FlxUI9SliceSprite;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUINumericStepper;
import flixel.addons.ui.FlxUITabMenu;
import flixel.addons.ui.FlxUITooltip.FlxUITooltipStyle;
import flixel.ui.FlxButton;
import flixel.ui.FlxSpriteButton;
import openfl.net.FileReference;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import haxe.Json;
import objects.Character;
import flixel.system.debug.interaction.tools.Pointer.GraphicCursorCross;
import lime.system.Clipboard;
import flixel.animation.FlxAnimation;
import objects.HealthIcon;
import util.FlxUIDropDownMenuCustom;
import util.CoolUtil;
import objects.BGSprite;
import objects.Strumline;
import objects.FakeNote;
import util.Mods;
#if MODS_ALLOWED
import sys.FileSystem;
#end

using StringTools;

/**
	*DEBUG MODE
 */
class CharacterEditorState extends MusicBeatState
{
	var char:Character;
	var ghostChar:Character;
	var textAnim:FlxText;
	var bgLayer:FlxTypedGroup<FlxSprite>;
	var charLayer:FlxTypedGroup<Character>;
	var ghostLayer:FlxTypedGroup<Character>;
	var noteLayer:FlxTypedGroup<FakeNote>;
	var strumLineNotes:FakeStrumline;
	var fakeNotes:FakeNotes;
	var dumbTexts:FlxTypedGroup<FlxText>;
	//var animList:Array<String> = [];
	var curAnim:Int = 0;
	var daAnim:String = 'spooky';
	var daGhost:String = 'spooky';
	var goToPlayState:Bool = true;
	var enabledOffset:Bool = true;
	var camFollow:FlxObject;

	public function new(daAnim:String = 'spooky', goToPlayState:Bool = true)
	{
		super();
		this.daAnim = daAnim;
		this.daGhost = daAnim;
		this.goToPlayState = goToPlayState;
	}

	var UI_box:FlxUITabMenu;
	var UI_characterbox:FlxUITabMenu;

	private var camEditor:FlxCamera;
	private var camHUD:FlxCamera;
	private var camMenu:FlxCamera;

	var changeBGbutton:FlxButton;
	var leHealthIcon:HealthIcon;
	var characterList:Array<String> = [];
	var arrowList:Array<String> = ['base', 'pixel'];
	var cameraFollowPointer:FlxSprite;
	var healthBarBG:FlxSprite;

	private var blockPressWhileTypingOn:Array<FlxUIInputText> = [];
	private var blockPressWhileTypingOnStepper:Array<FlxUINumericStepper> = [];
	private var blockPressWhileScrolling:Array<FlxUIDropDownMenuCustom> = [];
	var boyfriend:Character; 
	var placement = (FlxG.width / 2);
	override function create()
	{
		camEditor = new FlxCamera();
		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		camMenu = new FlxCamera();
		camMenu.bgColor.alpha = 0;

		FlxG.cameras.reset(camEditor);
		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.add(camMenu, false);
		FlxG.cameras.setDefaultDrawTarget(camEditor, true);
		

		bgLayer = new FlxTypedGroup<FlxSprite>();
		add(bgLayer);
		ghostLayer = new FlxTypedGroup<Character>();
		add(ghostLayer);

		charLayer = new FlxTypedGroup<Character>();
		add(charLayer);

		

		var pointer:FlxGraphic = FlxGraphic.fromClass(GraphicCursorCross);
		cameraFollowPointer = new FlxSprite().loadGraphic(pointer);
		cameraFollowPointer.setGraphicSize(40, 40);
		cameraFollowPointer.updateHitbox();
		cameraFollowPointer.color = FlxColor.WHITE;
		add(cameraFollowPointer);

		changeBGbutton = new FlxButton(FlxG.width - 360, 25, "", function()
		{
			onPixelBG = !onPixelBG;
			reloadBGs();
		});
		changeBGbutton.cameras = [camMenu];
		loadChar(!daAnim.startsWith('bf'), false);
		
		strumLineNotes = new FakeStrumline(placement - (FlxG.width / 10), char, char.arrowSkin, char.arrowStyle, 4);
		strumLineNotes.cameras = [camHUD];
		add(strumLineNotes);

		fakeNotes = new FakeNotes(placement - (FlxG.width / 10), 150, char, char.arrowSkin, char.arrowStyle, 4);
		fakeNotes.cameras = [camHUD];
		add(fakeNotes);

		/*
		noteLayer = new FlxTypedGroup<FakeNote>();
		noteLayer.cameras = [camHUD];
		add(noteLayer);
		addFakeNote();
		*/

		healthBarBG = new FlxSprite(30, FlxG.height - 75).loadGraphic(Paths.image('healthBar'));
		healthBarBG.scrollFactor.set();
		add(healthBarBG);
		healthBarBG.cameras = [camHUD];

		leHealthIcon = new HealthIcon(char.healthIcon, false, false);
		leHealthIcon.y = FlxG.height - 150;
		add(leHealthIcon);
		leHealthIcon.cameras = [camHUD];

		dumbTexts = new FlxTypedGroup<FlxText>();
		add(dumbTexts);
		dumbTexts.cameras = [camHUD];

		textAnim = new FlxText(300, 16);
		textAnim.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		textAnim.borderSize = 1;
		textAnim.size = 32;
		textAnim.scrollFactor.set();
		textAnim.cameras = [camHUD];
		add(textAnim);

		genBoyOffsets();

		camFollow = new FlxObject(0, 0, 2, 2);
		camFollow.screenCenter();
		add(camFollow);

		var tipTextArray:Array<String> = "E/Q - Camera Zoom In/Out
		\nR - Reset Camera Zoom
		\nJKLI - Move Camera
		\nW/S - Previous/Next Animation
		\nSpace - Play Animation
		\nArrow Keys - Move Character Offset
		\nT - Reset Current Offset
		\nHold Shift to Move 10x faster\n".split('\n');

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
			{name: 'Ghost Character', label: 'Ghost Character'},
		];

		UI_box = new FlxUITabMenu(null, tabs, true);
		UI_box.cameras = [camMenu];

		UI_box.resize(250, 150);
		UI_box.x = FlxG.width - 275;
		UI_box.y = -5;
		UI_box.scrollFactor.set();

		var tabs = [
			{name: 'Character', label: 'Character'},
			{name: 'Animations', label: 'Animations'},
			{name: 'Arrows', label: 'Arrows'}
		];
		UI_characterbox = new FlxUITabMenu(null, tabs, true);
		UI_characterbox.cameras = [camMenu];

		UI_characterbox.resize(350, 250);
		UI_characterbox.x = UI_box.x - 100;
		UI_characterbox.y = UI_box.y + UI_box.height;
		UI_characterbox.scrollFactor.set();
		add(UI_characterbox);
		add(UI_box);
		add(changeBGbutton);

		//addOffsetsUI();
		addGhostUI();
		addSettingsUI();
		

		addCharacterUI();
		addAnimationsUI();
		addArrowsUI();
		UI_characterbox.selected_tab_id = 'Character';
		UI_box.selected_tab_id = 'Settings';

		FlxG.mouse.visible = true;
		reloadCharacterOptions();

		super.create();
	}

	var onPixelBG:Bool = false;
	var OFFSET_X:Float = 300;
	
	function reloadBGs() {
		var i:Int = bgLayer.members.length-1;
		while(i >= 0) {
			var memb:FlxSprite = bgLayer.members[i];
			if(memb != null) {
				memb.kill();
				bgLayer.remove(memb);
				memb.destroy();
			}
			--i;
		}
		bgLayer.clear();
		var playerXDifference = 0;
		if(char.isPlayer) playerXDifference = 670;

		if(onPixelBG) {
			var playerYDifference:Float = 0;
			if(char.isPlayer) {
				playerXDifference += 200;
				playerYDifference = 220;
			}

			var bgSky:BGSprite = new BGSprite('stages/school/weebSky', OFFSET_X - (playerXDifference / 2) - 300, 0 - playerYDifference, 0.1, 0.1);
			bgLayer.add(bgSky);
			bgSky.antialiasing = false;

			var repositionShit = -200 + OFFSET_X - playerXDifference;

			var bgSchool:BGSprite = new BGSprite('stages/school/weebSchool', repositionShit, -playerYDifference + 6, 0.6, 0.90);
			bgLayer.add(bgSchool);
			bgSchool.antialiasing = false;

			var bgStreet:BGSprite = new BGSprite('stages/school/weebStreet', repositionShit, -playerYDifference, 0.95, 0.95);
			bgLayer.add(bgStreet);
			bgStreet.antialiasing = false;

			var widShit = Std.int(bgSky.width * 6);
			var bgTrees:FlxSprite = new FlxSprite(repositionShit - 380, -800 - playerYDifference);
			bgTrees.frames = Paths.getPackerAtlas('stages/school/weebTrees');
			bgTrees.animation.add('treeLoop', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18], 12);
			bgTrees.animation.play('treeLoop');
			bgTrees.scrollFactor.set(0.85, 0.85);
			bgLayer.add(bgTrees);
			bgTrees.antialiasing = false;

			bgSky.setGraphicSize(widShit);
			bgSchool.setGraphicSize(widShit);
			bgStreet.setGraphicSize(widShit);
			bgTrees.setGraphicSize(Std.int(widShit * 1.4));

			bgSky.updateHitbox();
			bgSchool.updateHitbox();
			bgStreet.updateHitbox();
			bgTrees.updateHitbox();

			boyfriend = new Character(OFFSET_X + 100, 550,'bf-pixel', char.isPlayer);
			boyfriend.x = OFFSET_X + 100;
			boyfriend.debugMode = true;
			boyfriend.alpha = 0.6;
			boyfriend.color = 0xFF666688;
			bgLayer.add(boyfriend);

			changeBGbutton.text = "Regular BG";

			
		} else {
			var bg:BGSprite = new BGSprite('stages/stage/stageback', -600 + OFFSET_X - playerXDifference, -300, 0.9, 0.9);
			bgLayer.add(bg);

			var stageFront:BGSprite = new BGSprite('stages/stage/stagefront', -650 + OFFSET_X - playerXDifference, 500, 0.9, 0.9);
			stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
			stageFront.updateHitbox();
			bgLayer.add(stageFront);
			boyfriend = new Character(OFFSET_X + 100, 350,'bf', char.isPlayer);
			boyfriend.debugMode = true;
			boyfriend.alpha = 0.6;
			boyfriend.color = 0xFF666688;
			bgLayer.add(boyfriend);

			changeBGbutton.text = "Pixel BG";

		}


	}

	var TemplateCharacter:String = '{
			"animations": [
				{
					"loop": false,
					"offsets": [
						0,
						0
					],
					"offsets_player": [
						0,
						0
					],
					"fps": 24,
					"anim": "idle",
					"indices": [],
					"name": "Dad idle dance"
				},
				{
					"offsets": [
						0,
						0
					],
					"offsets_player": [
						0,
						0
					],
					"indices": [],
					"fps": 24,
					"anim": "singLEFT",
					"loop": false,
					"name": "Dad Sing Note LEFT"
				},
				{
					"offsets": [
						0,
						0
					],
					"offsets_player": [
						0,
						0
					],
					"indices": [],
					"fps": 24,
					"anim": "singDOWN",
					"loop": false,
					"name": "Dad Sing Note DOWN"
				},
				{
					"offsets": [
						0,
						0
					],
					"offsets_player": [
						0,
						0
					],
					"indices": [],
					"fps": 24,
					"anim": "singUP",
					"loop": false,
					"name": "Dad Sing Note UP"
				},
				{
					"offsets": [
						0,
						0
					],
					"offsets_player": [
						0,
						0
					],
					"indices": [],
					"fps": 24,
					"anim": "singRIGHT",
					"loop": false,
					"name": "Dad Sing Note RIGHT"
				}
			],
			"no_antialiasing": false,
			"image": "characters/DADDY_DEAREST",
			"position": [
				0,
				0
			],
			"player_position": [
				0,
				0
			],
			"healthicon": "face",
			"arrowSkin": "noteSkins/NOTE_assets",
			"arrowStyle": "base",
			"splashSkin": "noteSplashes",
			"flip_x": false,
			"healthbar_colors": [
				161,
				161,
				161
			],
			"camera_position": [
				0,
				0
			],
			"playerCamera_position": [
				0,
				0
			],
			"sing_duration": 4,
			"scale": 1,
			"isPlayerChar": false,
			"disabledRGB": false
		}';

	var charDropDown:FlxUIDropDownMenuCustom;
	var characterShowCheckBox:FlxUICheckBox;
	var check_player:FlxUICheckBox;
	function addSettingsUI() {
		var tab_group = new FlxUI(null, UI_box);
		tab_group.name = "Settings";

		check_player = new FlxUICheckBox(10, 60, null, null, "Playable Character", 100);
		check_player.checked = char.wasPlayer;
		check_player.callback = function()
		{
			char.isPlayer = !char.isPlayer;
			char.flipX = !char.flipX;
			ghostChar.flipX = char.flipX;

			if(char.isPlayer)
				char.setPosition(char.playerPositionArray[0] + OFFSET_X + 100, char.playerPositionArray[1]);
			else
				char.setPosition(char.positionArray[0] + OFFSET_X + 100, char.positionArray[1]);

			reloadBGs();
			reloadCharacterOptions();
			updatePointerPos();
			genBoyOffsets();
		};

		charDropDown = new FlxUIDropDownMenuCustom(10, 30, FlxUIDropDownMenuCustom.makeStrIdLabelArray([''], true), function(character:String)
		{
			daAnim = characterList[Std.parseInt(character)];
			check_player.checked = char.wasPlayer;
			loadChar(!check_player.checked);
			updatePresence();
			reloadCharacterDropDown();
		});
		charDropDown.selectedLabel = daAnim;
		reloadCharacterDropDown();
		blockPressWhileScrolling.push(charDropDown);

		var reloadCharacter:FlxButton = new FlxButton(140, 20, "Reload Char", function()
		{
			loadChar(!check_player.checked);
			reloadCharacterDropDown();
		});

		var templateCharacter:FlxButton = new FlxButton(140, 50, "Load Template", function()
		{
			var parsedJson:CharacterFile = cast Json.parse(TemplateCharacter);
			var characters:Array<Character> = [char, ghostChar];
			for (character in characters)
			{
				character.animOffsets.clear();
				character.animOffsetsPlayer.clear();
				character.animationsArray = parsedJson.animations;
				for (anim in character.animationsArray)
				{
					character.addOffset(anim.anim, anim.offsets[0], anim.offsets[1]);
					character.addOffsetPlayer(anim.anim, anim.offsets_player[0], anim.offsets_player[1]);
				}
				if(character.animationsArray[0] != null) {
					character.playAnim(character.animationsArray[0].anim, true);
				}

				character.singDuration = parsedJson.sing_duration;
				character.positionArray = parsedJson.position;
				character.playerPositionArray = parsedJson.player_position;
				character.cameraPosition = parsedJson.camera_position;
				character.playerCameraPosition = parsedJson.playerCamera_position;

				character.imageFile = parsedJson.image;
				character.jsonScale = parsedJson.scale;
				character.noAntialiasing = parsedJson.no_antialiasing;
				character.originalFlipX = parsedJson.flip_x;
				character.healthIcon = parsedJson.healthicon;
				character.healthColorArray = parsedJson.healthbar_colors;
				character.arrowSkin = parsedJson.arrowSkin;
				character.splashSkin = parsedJson.splashSkin;
				character.arrowStyle = parsedJson.arrowStyle;

				if(character.isPlayer)
					character.setPosition(character.playerPositionArray[0] + OFFSET_X + 100, character.playerPositionArray[1]);
				else
					character.setPosition(character.positionArray[0] + OFFSET_X + 100, character.positionArray[1]);
			}

			reloadBGs();
			reloadCharacterImage();
			reloadCharacterDropDown();
			reloadCharacterOptions();
			resetHealthBarColor();
			updatePointerPos();
			genBoyOffsets();
		});
		templateCharacter.color = FlxColor.RED;
		templateCharacter.label.color = FlxColor.WHITE;

		characterShowCheckBox = new FlxUICheckBox(10, 100, null, null, "Show Character Ghost", 100,
		function() {
			FlxG.save.data.showCharacter = characterShowCheckBox.checked;
		});
		if (FlxG.save.data.showCharacter == null) FlxG.save.data.showCharacter = false;
		characterShowCheckBox.checked = FlxG.save.data.showCharacter;

		tab_group.add(new FlxText(charDropDown.x, charDropDown.y - 18, 0, 'Character:'));
		tab_group.add(check_player);
		tab_group.add(reloadCharacter);
		tab_group.add(reloadCharacter);
		tab_group.add(templateCharacter);
		tab_group.add(characterShowCheckBox);
		tab_group.add(charDropDown);
		UI_box.addGroup(tab_group);
	}

	var ghostCharDropDown:FlxUIDropDownMenuCustom;
	var check_offset:FlxUICheckBox;
	function addGhostUI() {
		var tab_group = new FlxUI(null, UI_box);
		tab_group.name = "Ghost Character";

		check_offset = new FlxUICheckBox(10, 60, null, null, "Offset", 100);
		check_offset.checked = enabledOffset;
		check_offset.callback = function() {
			enabledOffset = check_offset.checked;
		};

		ghostCharDropDown = new FlxUIDropDownMenuCustom(10, 30, FlxUIDropDownMenuCustom.makeStrIdLabelArray([''], true), function(character:String)
		{
			daGhost = characterList[Std.parseInt(character)];
			check_player.checked = char.wasPlayer;
			loadGhostChar(!check_player.checked);
			reloadGhostCharacterDropDown();
			if(UI_characterbox != null) {
				reloadAnimationGhostDropDown();
			}
		});
		ghostCharDropDown.selectedLabel = daGhost;
		reloadGhostCharacterDropDown();
		blockPressWhileScrolling.push(ghostCharDropDown);

		var reloadCharacter:FlxButton = new FlxButton(140, 20, "Reload Ghost Char", function()
		{
			loadGhostChar(!check_player.checked);
			reloadGhostCharacterDropDown();
			if(UI_characterbox != null) {
				reloadAnimationGhostDropDown();
			}
		});

		tab_group.add(new FlxText(ghostCharDropDown.x, ghostCharDropDown.y - 18, 0, 'Ghost Character:'));
		tab_group.add(reloadCharacter);
		tab_group.add(check_offset);
		tab_group.add(ghostCharDropDown);
		UI_box.addGroup(tab_group);
	}

	var imageInputText:FlxUIInputText;
	var healthIconInputText:FlxUIInputText;

	var singDurationStepper:FlxUINumericStepper;
	var scaleStepper:FlxUINumericStepper;
	var positionXStepper:FlxUINumericStepper;
	var positionYStepper:FlxUINumericStepper;
	var positionCameraXStepper:FlxUINumericStepper;
	var positionCameraYStepper:FlxUINumericStepper;

	var flipXCheckBox:FlxUICheckBox;
	var psychPlayerCheckBox:FlxUICheckBox;
	var noAntialiasingCheckBox:FlxUICheckBox;

	var healthColorStepperR:FlxUINumericStepper;
	var healthColorStepperG:FlxUINumericStepper;
	var healthColorStepperB:FlxUINumericStepper;

	function addCharacterUI() {
		
		var tab_group = new FlxUI(null, UI_box);
		tab_group.name = "Character";

		imageInputText = new FlxUIInputText(15, 30, 200, 'characters/BOYFRIEND', 8);
		blockPressWhileTypingOn.push(imageInputText);
		var reloadImage:FlxButton = new FlxButton(imageInputText.x + 210, imageInputText.y - 3, "Reload Image", function()
		{
			char.imageFile = imageInputText.text;
			reloadCharacterImage();
			char.playAnim(char.getAnimName(), true);
		});


		var decideIconColor:FlxButton = new FlxButton(reloadImage.x, reloadImage.y + 30, "Get Icon Color", function()
			{
				var coolColor = FlxColor.fromInt(CoolUtil.dominantColor(leHealthIcon));
				healthColorStepperR.value = coolColor.red;
				healthColorStepperG.value = coolColor.green;
				healthColorStepperB.value = coolColor.blue;
				getEvent(FlxUINumericStepper.CHANGE_EVENT, healthColorStepperR, null);
				getEvent(FlxUINumericStepper.CHANGE_EVENT, healthColorStepperG, null);
				getEvent(FlxUINumericStepper.CHANGE_EVENT, healthColorStepperB, null); 
			});

		healthIconInputText = new FlxUIInputText(15, imageInputText.y + 35, 75, leHealthIcon.getCharacter(), 8);
		blockPressWhileTypingOn.push(healthIconInputText);

		psychPlayerCheckBox = new FlxUICheckBox(healthIconInputText.x + 110, healthIconInputText.y, null, null, "Was Playable Character", 80);
		psychPlayerCheckBox.checked = char.wasPlayer;
		psychPlayerCheckBox.callback = function() {
			char.wasPlayer = psychPlayerCheckBox.checked;
		};

		singDurationStepper = new FlxUINumericStepper(15, healthIconInputText.y + 45, 0.1, 4, 0, 999, 1);
		blockPressWhileTypingOnStepper.push(singDurationStepper);

		scaleStepper = new FlxUINumericStepper(15, singDurationStepper.y + 40, 0.1, 1, 0.05, 10, 1);
		blockPressWhileTypingOnStepper.push(scaleStepper);

		flipXCheckBox = new FlxUICheckBox(singDurationStepper.x + 80, singDurationStepper.y, null, null, "Flip X", 50);
		flipXCheckBox.callback = function() {
			char.originalFlipX = !char.originalFlipX;
			char.flipX = char.originalFlipX;
			if(char.isPlayer) char.flipX = !char.flipX;

			ghostChar.flipX = char.flipX;
		};

		noAntialiasingCheckBox = new FlxUICheckBox(flipXCheckBox.x, flipXCheckBox.y + 40, null, null, "No Antialiasing", 80);
		noAntialiasingCheckBox.checked = char.noAntialiasing;
		noAntialiasingCheckBox.callback = function() {
			char.antialiasing = false;
			if(!noAntialiasingCheckBox.checked && ClientPrefs.globalAntialiasing) {
				char.antialiasing = true;
			}
			char.noAntialiasing = noAntialiasingCheckBox.checked;
		};

		var positionArray:Array<Float> = char.positionArray;
		if(char.isPlayer)
			positionArray = char.playerPositionArray;
		else
			positionArray = char.positionArray;

		positionXStepper = new FlxUINumericStepper(flipXCheckBox.x + 110, flipXCheckBox.y, 10, positionArray[0], -9000, 9000, 0);
		positionYStepper = new FlxUINumericStepper(positionXStepper.x + 60, positionXStepper.y, 10, positionArray[1], -9000, 9000, 0);
		blockPressWhileTypingOnStepper.push(positionXStepper);
		blockPressWhileTypingOnStepper.push(positionYStepper);

		var cameraPostion:Array<Float> = char.cameraPosition;
		if(char.isPlayer)
			cameraPostion = char.playerCameraPosition;
		else
			cameraPostion = char.cameraPosition;

		positionCameraXStepper = new FlxUINumericStepper(positionXStepper.x, positionXStepper.y + 40, 10, cameraPostion[0], -9000, 9000, 0);
		positionCameraYStepper = new FlxUINumericStepper(positionYStepper.x, positionYStepper.y + 40, 10, cameraPostion[1], -9000, 9000, 0);
		blockPressWhileTypingOnStepper.push(positionCameraXStepper);
		blockPressWhileTypingOnStepper.push(positionCameraYStepper);

		var saveCharacterButton:FlxButton = new FlxButton(reloadImage.x, noAntialiasingCheckBox.y + 40, "Save Character", function() {
			saveCharacter();
		});

		healthColorStepperR = new FlxUINumericStepper(singDurationStepper.x, saveCharacterButton.y, 20, char.healthColorArray[0], 0, 255, 0);
		healthColorStepperG = new FlxUINumericStepper(singDurationStepper.x + 65, saveCharacterButton.y, 20, char.healthColorArray[1], 0, 255, 0);
		healthColorStepperB = new FlxUINumericStepper(singDurationStepper.x + 130, saveCharacterButton.y, 20, char.healthColorArray[2], 0, 255, 0);
		blockPressWhileTypingOnStepper.push(healthColorStepperR);
		blockPressWhileTypingOnStepper.push(healthColorStepperG);
		blockPressWhileTypingOnStepper.push(healthColorStepperB);
		
		tab_group.add(new FlxText(15, imageInputText.y - 18, 0, 'Image file name:'));
		tab_group.add(new FlxText(15, healthIconInputText.y - 18, 0, 'Health icon name:'));
		tab_group.add(new FlxText(15, singDurationStepper.y - 18, 0, 'Sing Animation length:'));
		tab_group.add(new FlxText(15, scaleStepper.y - 18, 0, 'Scale:'));
		tab_group.add(new FlxText(positionXStepper.x, positionXStepper.y - 18, 0, 'Character X/Y:'));
		tab_group.add(new FlxText(positionCameraXStepper.x, positionCameraXStepper.y - 18, 0, 'Camera X/Y:'));
		tab_group.add(new FlxText(healthColorStepperR.x, healthColorStepperR.y - 18, 0, 'Health bar R/G/B:'));
		tab_group.add(imageInputText);
		tab_group.add(reloadImage);
		tab_group.add(decideIconColor);
		tab_group.add(healthIconInputText);
		tab_group.add(singDurationStepper);
		tab_group.add(scaleStepper);
		tab_group.add(flipXCheckBox);
		tab_group.add(noAntialiasingCheckBox);
		tab_group.add(positionXStepper);
		tab_group.add(positionYStepper);
		tab_group.add(positionCameraXStepper);
		tab_group.add(positionCameraYStepper);
		tab_group.add(psychPlayerCheckBox);
		tab_group.add(healthColorStepperR);
		tab_group.add(healthColorStepperG);
		tab_group.add(healthColorStepperB);
		tab_group.add(saveCharacterButton);
		UI_characterbox.addGroup(tab_group);
	}

	var ghostDropDown:FlxUIDropDownMenuCustom;
	var animationDropDown:FlxUIDropDownMenuCustom;
	var animationInputText:FlxUIInputText;
	var animationNameInputText:FlxUIInputText;
	var animationIndicesInputText:FlxUIInputText;
	var animationNameFramerate:FlxUINumericStepper;
	var animationLoopCheckBox:FlxUICheckBox;
	function addAnimationsUI() {
		var tab_group = new FlxUI(null, UI_box);
		tab_group.name = "Animations";

		animationInputText = new FlxUIInputText(15, 85, 80, '', 8);
		animationNameInputText = new FlxUIInputText(animationInputText.x, animationInputText.y + 35, 150, '', 8);
		animationIndicesInputText = new FlxUIInputText(animationNameInputText.x, animationNameInputText.y + 40, 250, '', 8);

		blockPressWhileTypingOn.push(animationInputText);
		blockPressWhileTypingOn.push(animationNameInputText);
		blockPressWhileTypingOn.push(animationIndicesInputText);
        
		animationNameFramerate = new FlxUINumericStepper(animationInputText.x + 170, animationInputText.y, 1, 24, 0, 240, 0);
		blockPressWhileTypingOnStepper.push(animationNameFramerate);
		animationLoopCheckBox = new FlxUICheckBox(animationNameInputText.x + 170, animationNameInputText.y - 1, null, null, "Should it Loop?", 100);

		animationDropDown = new FlxUIDropDownMenuCustom(15, animationInputText.y - 55, FlxUIDropDownMenuCustom.makeStrIdLabelArray([''], true),
			function(pressed:String)
			{
				var selectedAnimation:Int = Std.parseInt(pressed);
				var anim:AnimArray = char.animationsArray[selectedAnimation];
				animationInputText.text = anim.anim;
				animationNameInputText.text = anim.name;
				animationLoopCheckBox.checked = anim.loop;
				animationNameFramerate.value = anim.fps;

				var indicesStr:String = anim.indices.toString();
				animationIndicesInputText.text = indicesStr.substr(1, indicesStr.length - 2);
			});
		blockPressWhileScrolling.push(animationDropDown);
		ghostDropDown = new FlxUIDropDownMenuCustom(animationDropDown.x + 150, animationDropDown.y, FlxUIDropDownMenuCustom.makeStrIdLabelArray([''], true),
			function(pressed:String)
			{
				var selectedAnimation:Int = Std.parseInt(pressed);
				ghostChar.visible = false;
				char.alpha = 1;
				if (selectedAnimation > 0)
				{
					ghostChar.visible = true;
					ghostChar.playAnim(ghostChar.animationsArray[selectedAnimation - 1].anim, true);
					char.alpha = 0.85;
				}
			});
		blockPressWhileScrolling.push(ghostDropDown);
		var addUpdateButton:FlxButton = new FlxButton(70, animationIndicesInputText.y + 30, "Add/Update", function()
		{
			var indices:Array<Int> = [];
			var indicesStr:Array<String> = animationIndicesInputText.text.trim().split(',');
			if (indicesStr.length > 1)
			{
				for (i in 0...indicesStr.length)
				{
					var index:Int = Std.parseInt(indicesStr[i]);
					if (indicesStr[i] != null && indicesStr[i] != '' && !Math.isNaN(index) && index > -1)
					{
						indices.push(index);
					}
				}
			}

			var lastAnim:String = '';
			if (char.animationsArray[curAnim] != null)
			{
				lastAnim = char.animationsArray[curAnim].anim;
			}

			var lastOffsets:Array<Int> = [0, 0];
			var lastOffsetsPlayer:Array<Int> = [0, 0];
			for (anim in char.animationsArray)
			{
				if (animationInputText.text == anim.anim)
				{
					lastOffsetsPlayer = anim.offsets_player;
					lastOffsets = anim.offsets;
					
                    if (char.existsAnimation(animationInputText.text))
					{
						if(char.animateAtlas != null)
							char.animateAtlas.animation.remove(animationInputText.text);
						else
							char.animation.remove(animationInputText.text);
						
					}
					char.animationsArray.remove(anim);
				}
			}

			var newAnim:AnimArray = {
				anim: animationInputText.text,
				name: animationNameInputText.text,
				fps: Math.round(animationNameFramerate.value),
				loop: animationLoopCheckBox.checked,
				indices: indices,
				offsets: lastOffsets,
				offsets_player: lastOffsetsPlayer
			};

			if(char.animateAtlas != null)
			{
				if (indices != null && indices.length > 0){
					char.animateAtlas.animation.addByIndices(newAnim.anim, newAnim.name, newAnim.indices, "", newAnim.fps, newAnim.loop);
				} else {
					char.animateAtlas.animation.addByPrefix(newAnim.anim, newAnim.name, newAnim.fps, newAnim.loop);
				}
			} else {
				if (indices != null && indices.length > 0){
					char.animation.addByIndices(newAnim.anim, newAnim.name, newAnim.indices, "", newAnim.fps, newAnim.loop);
				}
				else{
					char.animation.addByPrefix(newAnim.anim, newAnim.name, newAnim.fps, newAnim.loop);
				}
			}


			if (!char.animOffsets.exists(newAnim.anim))
			{
				char.addOffset(newAnim.anim, 0, 0);
			}
			if (!char.animOffsetsPlayer.exists(newAnim.anim))
			{
				char.addOffsetPlayer(newAnim.anim, 0, 0);
			}
			char.animationsArray.push(newAnim);

			if (lastAnim == animationInputText.text)
			{
				if(char.animateAtlas != null)
				{
					var leAnim = char.animateAtlas.animation.getByName(lastAnim);
					if (leAnim != null)
					{
						char.playAnim(lastAnim, true);
					}
					else
					{
						for (i in 0...char.animationsArray.length)
						{
							if (char.animationsArray[i] != null)
							{
								leAnim = char.animateAtlas.animation.getByName(char.animationsArray[i].anim);
								if (leAnim != null)
								{
									char.playAnim(char.animationsArray[i].anim, true);
									curAnim = i;
									break;
								}
							}
						}
					}
				}
				else
				{
					var leAnim:FlxAnimation = char.animation.getByName(lastAnim);
					if (leAnim != null && leAnim.frames.length > 0)
					{
						char.playAnim(lastAnim, true);
					}
					else
					{
						for (i in 0...char.animationsArray.length)
						{
							if (char.animationsArray[i] != null)
							{
								leAnim = char.animation.getByName(char.animationsArray[i].anim);
								if (leAnim != null && leAnim.frames.length > 0)
								{
									char.playAnim(char.animationsArray[i].anim, true);
									curAnim = i;
									break;
								}
							}
						}
					}
				}
			}

			reloadAnimationDropDown();
			genBoyOffsets();
			trace('Added/Updated animation: ' + animationInputText.text);
        });
        
		var removeButton:FlxButton = new FlxButton(180, animationIndicesInputText.y + 30, "Remove", function() {
			for (anim in char.animationsArray)
			{
				if (animationInputText.text == anim.anim)
				{
					var resetAnim:Bool = false;
					if (char.animation.curAnim != null && anim.anim == char.animation.curAnim.name)
						resetAnim = true;


					if (char.existsAnimation(anim.anim))
					{
						if(char.animateAtlas != null)
							char.animateAtlas.animation.remove(anim.anim);
						else					
							char.animation.remove(anim.anim);
					}

					if (char.animOffsets.exists(anim.anim))
					{
						char.animOffsets.remove(anim.anim);
					}
					if (char.animOffsetsPlayer.exists(anim.anim))
					{
						char.animOffsetsPlayer.remove(anim.anim);
					}
					char.animationsArray.remove(anim);

					if (resetAnim && char.animationsArray.length > 0)
					{
						char.playAnim(char.animationsArray[0].anim, true);
					}
					reloadAnimationDropDown();
					genBoyOffsets();
					trace('Removed animation: ' + animationInputText.text);
					break;
				}
			}
        });

		tab_group.add(new FlxText(animationDropDown.x, animationDropDown.y - 18, 0, 'Animations:'));
		tab_group.add(new FlxText(ghostDropDown.x, ghostDropDown.y - 18, 0, 'Animation Ghost:'));
		tab_group.add(new FlxText(animationInputText.x, animationInputText.y - 18, 0, 'Animation name:'));
		tab_group.add(new FlxText(animationNameFramerate.x, animationNameFramerate.y - 18, 0, 'Framerate:'));
		tab_group.add(new FlxText(animationNameInputText.x, animationNameInputText.y - 18, 0, 'Animation on .XML/.TXT file:'));
		tab_group.add(new FlxText(animationIndicesInputText.x, animationIndicesInputText.y - 18, 0, 'ADVANCED - Animation Indices:'));

		tab_group.add(animationInputText);
		tab_group.add(animationNameInputText);
		tab_group.add(animationIndicesInputText);
		tab_group.add(animationNameFramerate);
		tab_group.add(animationLoopCheckBox);
		tab_group.add(addUpdateButton);
		tab_group.add(removeButton);
		tab_group.add(ghostDropDown);
		tab_group.add(animationDropDown);
		UI_characterbox.addGroup(tab_group);
	}

	var arrowSkinInputText:FlxUIInputText;
	var splashSkinInputText:FlxUIInputText;
	var arrowStyleDropDown:FlxUIDropDownMenuCustom;
	var arrowShowCheckBox:FlxUICheckBox;

	var rgbDisabledCheckBox:FlxUICheckBox;
	function addArrowsUI()
	{
		var tab_group = new FlxUI(null, UI_box);
		tab_group.name = "Arrows";

		arrowSkinInputText = new FlxUIInputText(15, 30, 200, 'NOTE_assets', 8);
		blockPressWhileTypingOn.push(arrowSkinInputText);
		splashSkinInputText = new FlxUIInputText(15, arrowSkinInputText.y + 40, 200, 'noteSplashes', 8);
		blockPressWhileTypingOn.push(splashSkinInputText);
		arrowStyleDropDown = new FlxUIDropDownMenuCustom(10, splashSkinInputText.y + 50, FlxUIDropDownMenuCustom.makeStrIdLabelArray(arrowList, true), function(arrowStyle:String)
		{
			char.arrowStyle = arrowList[Std.parseInt(arrowStyle)];
			reloadArrowStyleDropDown();
		});
		arrowStyleDropDown.selectedLabel = char.arrowStyle;
		reloadArrowStyleDropDown();
		blockPressWhileScrolling.push(arrowStyleDropDown);

		var reloadNoteSkin:FlxButton = new FlxButton(arrowSkinInputText.x + 210, arrowStyleDropDown.y - 3, "Reload Arrow Skins", function()
		{
			char.arrowSkin = arrowSkinInputText.text;
			char.splashSkin = splashSkinInputText.text;
			for(i in 0...strumLineNotes.receptors.length)
			{
				strumLineNotes.receptors.members[i].texture = char.arrowSkin;
			}
			for(i in 0...fakeNotes.receptors.length)
			{
				fakeNotes.receptors.members[i].texture = char.arrowSkin;
			}
		});

		arrowShowCheckBox = new FlxUICheckBox(arrowStyleDropDown.x + 10, reloadNoteSkin.y + 50, null, null, "Arrow Enabled?", 100,
		function() {
			FlxG.save.data.showArrow = arrowShowCheckBox.checked;
		});
		if (FlxG.save.data.showArrow == null) FlxG.save.data.showArrow = false;
		arrowShowCheckBox.checked = FlxG.save.data.showArrow;

		rgbDisabledCheckBox = new FlxUICheckBox(arrowShowCheckBox.x + 110, arrowShowCheckBox.y, null, null, "Disabled RGB Note?", 100,
		function() {
			char.disabledRGB = rgbDisabledCheckBox.checked;
		});
		rgbDisabledCheckBox.checked = char.disabledRGB;

		tab_group.add(new FlxText(15, arrowSkinInputText.y - 18, 0, 'Image file Arrow Skin:'));
		tab_group.add(new FlxText(15, arrowStyleDropDown.y - 18, 0, 'Arrow Style:'));
		tab_group.add(new FlxText(15, splashSkinInputText.y - 18, 0, 'Image file Splash Skin:'));
		tab_group.add(arrowStyleDropDown);
		tab_group.add(arrowSkinInputText);
		tab_group.add(splashSkinInputText);
		tab_group.add(arrowShowCheckBox);
		tab_group.add(rgbDisabledCheckBox);
		tab_group.add(reloadNoteSkin);
		UI_characterbox.addGroup(tab_group);		
	}


	override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>) {
		if(id == FlxUIInputText.CHANGE_EVENT && (sender is FlxUIInputText)) {
			if(sender == healthIconInputText) {
				leHealthIcon.changeIcon(healthIconInputText.text, false);
				char.healthIcon = healthIconInputText.text;
				updatePresence();
			}
			else if(sender == imageInputText) {
				char.imageFile = imageInputText.text;
			}
			else if(sender == arrowSkinInputText) {
				char.arrowSkin = arrowSkinInputText.text;
			}
			else if(sender == splashSkinInputText) {
				char.splashSkin = splashSkinInputText.text;
			}
		} else if(id == FlxUINumericStepper.CHANGE_EVENT && (sender is FlxUINumericStepper)) {
			if (sender == scaleStepper)
			{
				reloadCharacterImage();
				char.jsonScale = sender.value;
				char.setGraphicSize(Std.int(char.width * char.jsonScale));
				char.updateHitbox();
				
				ghostChar.setGraphicSize(Std.int(ghostChar.width * char.jsonScale));
				ghostChar.updateHitbox();
				
				reloadGhost();
				updatePointerPos();

				char.playAnim(char.getAnimName(), true);
			}
			else if(sender == singDurationStepper)
			{
				char.singDuration = singDurationStepper.value;//ermm you forgot this??
			}
			else if(sender == positionXStepper)
			{
				if(char.isPlayer)
				{
					char.playerPositionArray[0] = positionXStepper.value;
					char.x = char.playerPositionArray[0] + OFFSET_X + 100;
				}
				else
				{
					char.positionArray[0] = positionXStepper.value;
					char.x = char.positionArray[0] + OFFSET_X + 100;
				}
				updatePointerPos();
			}
			else if(sender == positionYStepper)
			{
				if(char.isPlayer)
				{
					char.playerPositionArray[1] = positionYStepper.value;
					char.y = char.playerPositionArray[1];
				}
				else
				{
					char.positionArray[1] = positionYStepper.value;
					char.y = char.positionArray[1];
				}

				updatePointerPos();
			}
			else if(sender == positionCameraXStepper)
			{
				if(char.isPlayer)
					char.playerCameraPosition[0] = positionCameraXStepper.value;
				else
					char.cameraPosition[0] = positionCameraXStepper.value;
					

				updatePointerPos();
			}
			else if(sender == positionCameraYStepper)
			{
				if(char.isPlayer)
					char.playerCameraPosition[1] = positionCameraYStepper.value;
				else
					char.cameraPosition[1] = positionCameraYStepper.value;
				
				updatePointerPos();
				
			}
			else if(sender == healthColorStepperR)
			{
				char.healthColorArray[0] = Math.round(healthColorStepperR.value);
				healthBarBG.color = FlxColor.fromRGB(char.healthColorArray[0], char.healthColorArray[1], char.healthColorArray[2]);
			}
			else if(sender == healthColorStepperG)
			{
				char.healthColorArray[1] = Math.round(healthColorStepperG.value);
				healthBarBG.color = FlxColor.fromRGB(char.healthColorArray[0], char.healthColorArray[1], char.healthColorArray[2]);
			}
			else if(sender == healthColorStepperB)
			{
				char.healthColorArray[2] = Math.round(healthColorStepperB.value);
				healthBarBG.color = FlxColor.fromRGB(char.healthColorArray[0], char.healthColorArray[1], char.healthColorArray[2]);
			}
		}
	}

	function reloadCharacterImage() {
		var lastAnim:String = '';
		lastAnim = char.getAnimName();
		char.loadFrames(char.imageFile);

		if(char.animationsArray != null && char.animationsArray.length > 0) {
			for (anim in char.animationsArray) {
				var animAnim:String = '' + anim.anim;
				var animName:String = '' + anim.name;
				var animFps:Int = anim.fps;
				var animLoop:Bool = !!anim.loop; //Bruh
				var animIndices:Array<Int> = anim.indices;
				if (char.animateAtlas != null) {
					if(animIndices != null && animIndices.length > 0) {
						char.animateAtlas.animation.addByIndices(animAnim, animName, animIndices, "", animFps, animLoop);
					} else {
						char.animateAtlas.animation.addByPrefix(animAnim, animName, animFps, animLoop);
					}
				}
				else {
					if(animIndices != null && animIndices.length > 0) {
						char.animation.addByIndices(animAnim, animName, animIndices, "", animFps, animLoop);
					} else {
						char.animation.addByPrefix(animAnim, animName, animFps, animLoop);
					}
				}

			}
		} else {
			char.quickAnimAdd('idle', 'BF idle dance');
		}

		if(lastAnim != '') {
			char.playAnim(lastAnim, true);
		} else {
			char.dance();
		}
		ghostDropDown.selectedLabel = '';
		reloadGhost();
	}

	function genBoyOffsets():Void
	{
		var daLoop:Int = 0;

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

		if (char.animOffsets != null)
		{
			var text:FlxText = new FlxText(10, 20 + (18 * daLoop), 0, 'Offsets:', 15);
			text.setFormat(null, 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			text.scrollFactor.set();
			text.borderSize = 1;
			dumbTexts.add(text);
			text.cameras = [camHUD];
			daLoop++;
	
			for (anim => offsets in char.animOffsets)
			{
				var text:FlxText = new FlxText(10, 20 + (18 * daLoop), 0, anim + ": " + offsets, 15);
				text.setFormat(null, 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
				text.scrollFactor.set();
				text.borderSize = 1;
				dumbTexts.add(text);
				text.cameras = [camHUD];
	
				daLoop++;
			}
		}

		if (char.animOffsetsPlayer != null)
		{
			daLoop++;

			var text:FlxText = new FlxText(10, 20 + (18 * daLoop), 0, 'Offsets Player:', 15);
			text.setFormat(null, 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			text.scrollFactor.set();
			text.borderSize = 1;
			dumbTexts.add(text);
			text.cameras = [camHUD];
			daLoop++;

			for (anim => playerOffsets in char.animOffsetsPlayer)
			{
				var text:FlxText = new FlxText(10, 20 + (18 * daLoop), 0, anim + ": " + playerOffsets, 15);
				text.setFormat(null, 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
				text.scrollFactor.set();
				text.borderSize = 1;
				dumbTexts.add(text);
				text.cameras = [camHUD];
	
				daLoop++;
			}			
		}

		textAnim.visible = true;
		if(dumbTexts.length < 1) {
			var text:FlxText = new FlxText(10, 38, 0, "ERROR! No animations found.", 15);
			text.scrollFactor.set();
			text.borderSize = 1;
			dumbTexts.add(text);
			textAnim.visible = false;
		}
	}

	function loadGhostChar(isPlayer:Bool = false, blahBlahBlah:Bool = true) {
		var i:Int = ghostLayer.members.length-1;
		while(i >= 0) {
			var memb:Character = ghostLayer.members[i];
			if(memb != null) {
				memb.kill();
				ghostLayer.remove(memb);
				memb.destroy();
			}
			--i;
		}
		ghostLayer.clear();

		ghostChar = new Character(0,0, daGhost, !isPlayer);
		ghostChar.debugMode = true;
		ghostChar.alpha = 0.6;
		ghostLayer.add(ghostChar);
	}

	function loadChar(isPlayer:Bool = false, blahBlahBlah:Bool = true) {
		var i:Int = charLayer.members.length-1;
		while(i >= 0) {
			var memb:Character = charLayer.members[i];
			if(memb != null) {
				memb.kill();
				charLayer.remove(memb);
				memb.destroy();
			}
			--i;
		}
		charLayer.clear();

		var i:Int = ghostLayer.members.length-1;
		while(i >= 0) {
			var memb:Character = ghostLayer.members[i];
			if(memb != null) {
				memb.kill();
				ghostLayer.remove(memb);
				memb.destroy();
			}
			--i;
		}
		ghostLayer.clear();

		ghostChar = new Character(0,0, daAnim, !isPlayer);
		ghostChar.debugMode = true;
		ghostChar.alpha = 0.6;
		ghostLayer.add(ghostChar);

		char = new Character(0,0, daAnim, !isPlayer);
		if(char.animationsArray[0] != null) {
			char.playAnim(char.animationsArray[0].anim, true);
		}
		char.debugMode = true;
		charLayer.add(char);

		if(char.isPlayer)
			char.setPosition(char.playerPositionArray[0] + OFFSET_X + 100, char.playerPositionArray[1]);
		else
			char.setPosition(char.positionArray[0] + OFFSET_X + 100, char.positionArray[1]);

		for (anim => offset in char.animOffsets) {
			var leAnim:AnimArray = findAnimationByName(anim);
			if(leAnim != null && char.isPlayer) {
				leAnim.offsets_player = [offset[0], offset[1]];
			}
		}

		if(blahBlahBlah) {
			genBoyOffsets();
		}
		reloadCharacterOptions();
		reloadBGs();
		updatePointerPos();
	}

	function updatePointerPos() {
		var x:Float = char.getMidpoint().x;
		var y:Float = char.getMidpoint().y;
		if(!char.isPlayer) {
			x += 150 + char.cameraPosition[0];
			y -= 100 - char.cameraPosition[1];
		} else {
			x -= 100 + char.playerCameraPosition[0];
			y -= 100 - char.playerCameraPosition[1];
		}
		

		x -= cameraFollowPointer.width / 2;
		y -= cameraFollowPointer.height / 2;
		cameraFollowPointer.setPosition(x, y);
	}

	function findAnimationByName(name:String):AnimArray {
		for (anim in char.animationsArray) {
			if(anim.anim == name) {
				return anim;
			}
		}
		return null;
	}

	function addFakeNote() {
		for (i in 0...4)
		{
			var babyNote:FakeNote = new FakeNote(placement - (FlxG.width / 4) - 45, 150, i);
			babyNote.x += FakeNote.swagWidth * i - 25;
			babyNote.x += 50;
			var animToPlay:String = '';
			if(babyNote.noteData > -1) {
				babyNote.texture = '';
				if(babyNote.noteData > -1 && babyNote.noteData < 4) { //Doing this 'if' check to fix the warnings on Senpai songs
					
					animToPlay = babyNote.colArray[i % 4];
					babyNote.animation.play(animToPlay + 'Scroll');
				}
			}
			noteLayer.add(babyNote);
		}
	}

	function reloadCharacterOptions() {
		if(UI_characterbox != null) {
			imageInputText.text = char.imageFile;
			arrowSkinInputText.text = char.arrowSkin;
			splashSkinInputText.text = char.splashSkin;

			for(i in 0...strumLineNotes.receptors.length)
			{
				strumLineNotes.receptors.members[i].texture = char.arrowSkin;
			}
			for(i in 0...fakeNotes.receptors.length)
			{
				fakeNotes.receptors.members[i].texture = char.arrowSkin;
			}
			healthIconInputText.text = char.healthIcon;
			singDurationStepper.value = char.singDuration;
			scaleStepper.value = char.jsonScale;
			flipXCheckBox.checked = char.originalFlipX;
			noAntialiasingCheckBox.checked = char.noAntialiasing;
			psychPlayerCheckBox.checked = char.wasPlayer;
			rgbDisabledCheckBox.checked = char.disabledRGB;
			resetHealthBarColor();
			leHealthIcon.changeIcon(healthIconInputText.text, false);
			if(char.isPlayer)
			{
				positionXStepper.value = char.playerPositionArray[0];
				positionYStepper.value = char.playerPositionArray[1];

				positionCameraXStepper.value = char.playerCameraPosition[0];
				positionCameraYStepper.value = char.playerCameraPosition[1];
			}
			else
			{
				positionXStepper.value = char.positionArray[0];
				positionYStepper.value = char.positionArray[1];

				positionCameraXStepper.value = char.cameraPosition[0];
				positionCameraYStepper.value = char.cameraPosition[1];
			}
			reloadAnimationDropDown();
			reloadArrowStyleDropDown();
			updatePresence();
		}
	}

	function reloadArrowStyleDropDown(){
		arrowStyleDropDown.setData(FlxUIDropDownMenuCustom.makeStrIdLabelArray(arrowList, true));
		arrowStyleDropDown.selectedLabel = char.arrowStyle;
		for(i in 0...strumLineNotes.receptors.length)
		{
			strumLineNotes.receptors.members[i].style = char.arrowStyle;
		}
		for(i in 0...fakeNotes.receptors.length)
		{
			fakeNotes.receptors.members[i].style = char.arrowStyle;
		}
	}

	function reloadAnimationGhostDropDown() {
		var ghostAnims:Array<String> = [''];
		for (anim in ghostChar.animationsArray) {
			ghostAnims.push(anim.anim);
		}
		if(ghostAnims.length < 1) ghostAnims.push('NO ANIMATIONS'); //Prevents crash
		ghostDropDown.setData(FlxUIDropDownMenuCustom.makeStrIdLabelArray(ghostAnims, true));
	}

	function reloadAnimationDropDown() {
		var anims:Array<String> = [];
		var ghostAnims:Array<String> = [''];
		for (anim in char.animationsArray) {
			anims.push(anim.anim);
			ghostAnims.push(anim.anim);
		}
		if(anims.length < 1) anims.push('NO ANIMATIONS'); //Prevents crash
		animationDropDown.setData(FlxUIDropDownMenuCustom.makeStrIdLabelArray(anims, true));
		ghostDropDown.setData(FlxUIDropDownMenuCustom.makeStrIdLabelArray(ghostAnims, true));
		reloadGhost();
	}

	function reloadGhost() {
		ghostChar.frames = char.frames;
		for (anim in char.animationsArray) {
			var animAnim:String = '' + anim.anim;
			var animName:String = '' + anim.name;
			var animFps:Int = anim.fps;
			var animLoop:Bool = !!anim.loop; //Bruh
			var animIndices:Array<Int> = anim.indices;
			if (ghostChar.animateAtlas != null) {
				if(animIndices != null && animIndices.length > 0) {
					ghostChar.animateAtlas.animation.addByIndices(animAnim, animName, animIndices, "", animFps, animLoop);
				} else {
					ghostChar.animateAtlas.animation.addByPrefix(animAnim, animName, animFps, animLoop);
				}
			}
			else {
				if(animIndices != null && animIndices.length > 0) {
					ghostChar.animation.addByIndices(animAnim, animName, animIndices, "", animFps, animLoop);
				} else {
					ghostChar.animation.addByPrefix(animAnim, animName, animFps, animLoop);
				}
			}

			if(ghostChar.isPlayer)
			{
				if(anim.offsets_player != null && anim.offsets_player.length > 1) {
					ghostChar.addOffsetPlayer(anim.anim, anim.offsets_player[0], anim.offsets_player[1]);
				}
				else if(anim.offsets != null && anim.offsets.length > 1) {
					ghostChar.addOffsetPlayer(anim.anim, anim.offsets[0], anim.offsets[1]);
				}
			}
			else
			{
				if(anim.offsets != null && anim.offsets.length > 1) {
					ghostChar.addOffset(anim.anim, anim.offsets[0], anim.offsets[1]);
				}
			}
		}

		char.alpha = 0.85;
		ghostChar.visible = true;
		if(ghostDropDown.selectedLabel == '') {
			ghostChar.visible = false;
			char.alpha = 1;
		}
		ghostChar.color = 0xFF666688;
		ghostChar.antialiasing = char.antialiasing;
	}

	function reloadGhostCharacterDropDown() {
		var charsLoaded:Map<String, Bool> = new Map();

		#if MODS_ALLOWED
		characterList = [];
		var directories:Array<String> = [Paths.mods('characters/'), Paths.mods(Mods.currentModDirectory + '/characters/'), Paths.getPreloadPath('characters/')];
		for(mod in Mods.getGlobalMods())
		{
			directories.push(Paths.mods(mod + '/characters/'));
			if(PlayState.isBETADCIU)
				directories.push(Paths.mods(mod + '/charactersBETADCIU/'));
		}

		if(PlayState.isBETADCIU)
		{
			directories.push(Paths.mods('charactersBETADCIU/'));
			directories.push(Paths.mods(Mods.currentModDirectory + '/charactersBETADCIU/'));
			directories.push(Paths.getPreloadPath('charactersBETADCIU/'));
		}
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

		ghostCharDropDown.setData(FlxUIDropDownMenuCustom.makeStrIdLabelArray(characterList, true));
		ghostCharDropDown.selectedLabel = daGhost;
	}

	function reloadCharacterDropDown() {
		var charsLoaded:Map<String, Bool> = new Map();

		#if MODS_ALLOWED
		characterList = [];
		var directories:Array<String> = [Paths.mods('characters/'), Paths.mods(Mods.currentModDirectory + '/characters/'), Paths.getPreloadPath('characters/')];
		for(mod in Mods.getGlobalMods())
		{
			directories.push(Paths.mods(mod + '/characters/'));
			if(PlayState.isBETADCIU)
				directories.push(Paths.mods(mod + '/charactersBETADCIU/'));
		}
		if(PlayState.isBETADCIU)
		{
			directories.push(Paths.mods('charactersBETADCIU/'));
			directories.push(Paths.mods(Mods.currentModDirectory + '/charactersBETADCIU/'));
			directories.push(Paths.getPreloadPath('charactersBETADCIU/'));
		}
		
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

		charDropDown.setData(FlxUIDropDownMenuCustom.makeStrIdLabelArray(characterList, true));
		charDropDown.selectedLabel = daAnim;
	}

	function resetHealthBarColor() {
		healthColorStepperR.value = char.healthColorArray[0];
		healthColorStepperG.value = char.healthColorArray[1];
		healthColorStepperB.value = char.healthColorArray[2];
		healthBarBG.color = FlxColor.fromRGB(char.healthColorArray[0], char.healthColorArray[1], char.healthColorArray[2]);
	}

	function updatePresence() {
		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("Character Editor", "Character: " + daAnim, leHealthIcon.getCharacter());
		#end
	}

	override function update(elapsed:Float)
	{
		MusicBeatState.camBeat = FlxG.camera;
		if(char.animationsArray[curAnim] != null) {
			textAnim.text = char.animationsArray[curAnim].anim;

			if(char.animateAtlas != null)
			{
				var curAnim = char.animateAtlas.animation.getByName(char.animationsArray[curAnim].anim);
				if(curAnim == null || curAnim.frames.length < 1) {
					textAnim.text += ' (ERROR!)';
					textAnim.color += FlxColor.RED;
				}
				else {
					textAnim.color = FlxColor.WHITE;
				}
			}
			else
			{
				var curAnim:FlxAnimation = char.animation.getByName(char.animationsArray[curAnim].anim);
				if(curAnim == null || curAnim.frames.length < 1) {
					textAnim.text += ' (ERROR!)';
					textAnim.color += FlxColor.RED;
				}
				else {
					textAnim.color = FlxColor.WHITE;
				}
			}

		} else {
			textAnim.text = '';
			textAnim.color = FlxColor.WHITE;
		}

		var blockInput:Bool = false;
		for (inputText in blockPressWhileTypingOn) {
			if(inputText.hasFocus) {
				ClientPrefs.toggleVolumeKeys(false);
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
					ClientPrefs.toggleVolumeKeys(false);
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

		for(i in 0...strumLineNotes.receptors.length)
		{
			strumLineNotes.receptors.members[i].visible = arrowShowCheckBox.checked;
		}
		for(i in 0...fakeNotes.receptors.length)
		{
			fakeNotes.receptors.members[i].visible = arrowShowCheckBox.checked;
		}

		boyfriend.visible = characterShowCheckBox.checked;
		if(!blockInput) {
			ClientPrefs.toggleVolumeKeys(true);

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

			if(char.animationsArray.length > 0) {
				if (FlxG.keys.justPressed.W)
				{
					curAnim -= 1;
				}

				if (FlxG.keys.justPressed.S)
				{
					curAnim += 1;
				}

				if (curAnim < 0)
					curAnim = char.animationsArray.length - 1;

				if (curAnim >= char.animationsArray.length)
					curAnim = 0;

				if (FlxG.keys.justPressed.S || FlxG.keys.justPressed.W || FlxG.keys.justPressed.SPACE)
				{
					char.playAnim(char.animationsArray[curAnim].anim, true);
					genBoyOffsets();
				}

				if (FlxG.keys.justPressed.T)
				{
					var offsets:Array<Int> = char.animationsArray[curAnim].offsets;
					var offsetsPlayer:Array<Int> = char.animationsArray[curAnim].offsets_player;

					offsets = [0, 0];
					offsetsPlayer = [0, 0];

					if(char.isPlayer)
						char.addOffsetPlayer(char.animationsArray[curAnim].anim, offsetsPlayer[0], offsetsPlayer[1]);
					else
						char.addOffset(char.animationsArray[curAnim].anim, offsets[0], offsets[1]);

					if(enabledOffset)
					{
						if(char.isPlayer)
							ghostChar.addOffsetPlayer(char.animationsArray[curAnim].anim, offsetsPlayer[0], offsetsPlayer[1]);
						else
							ghostChar.addOffset(char.animationsArray[curAnim].anim, offsets[0], offsets[1]);
					}

					genBoyOffsets();
				}

				var controlArray:Array<Bool> = [FlxG.keys.justPressed.LEFT, FlxG.keys.justPressed.RIGHT, FlxG.keys.justPressed.UP, FlxG.keys.justPressed.DOWN];
				for (i in 0...controlArray.length) {
					if(controlArray[i]) {
						var holdShift = FlxG.keys.pressed.SHIFT;
						var multiplier = 1;
						if (holdShift)
							multiplier = 10;

						var arrayVal = 0;
						if(i > 1) arrayVal = 1;

						var negaMult:Int = 1;
						if(i % 2 == 1) negaMult = -1;


						var offsets:Array<Int> = char.animationsArray[curAnim].offsets;
						if(char.isPlayer) offsets = char.animationsArray[curAnim].offsets_player;
						offsets[arrayVal] += negaMult * multiplier;

						if(char.isPlayer)
							char.addOffsetPlayer(char.animationsArray[curAnim].anim, offsets[0], offsets[1]);
						else
							char.addOffset(char.animationsArray[curAnim].anim, offsets[0], offsets[1]);

						if(enabledOffset)
						{
							if(char.isPlayer)
								ghostChar.addOffsetPlayer(char.animationsArray[curAnim].anim, offsets[0], offsets[1]);
							else
								ghostChar.addOffset(char.animationsArray[curAnim].anim, offsets[0], offsets[1]);
						}
							

						char.playAnim(char.animationsArray[curAnim].anim, false);
						if(char.getAnimName() == ghostChar.getAnimName()) {
							ghostChar.playAnim(char.getAnimName(), false);
						}
						genBoyOffsets();
					}
				}
			}
		}
		//camMenu.zoom = FlxG.camera.zoom;
		if(enabledOffset)
		{
			ghostChar.setPosition(char.x, char.y);
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

	function saveCharacter() {
		var json = {
			"animations": char.animationsArray,
			"image": char.imageFile,
			"scale": char.jsonScale,
			"sing_duration": char.singDuration,
			"healthicon": char.healthIcon,
			"arrowSkin": char.arrowSkin,
			"arrowStyle": char.arrowStyle,
			"splashSkin": char.splashSkin,

			"position":	char.positionArray,
			"camera_position": char.cameraPosition,
			"player_position": char.playerPositionArray,
			"playerCamera_position": char.playerCameraPosition,

			"flip_x": char.originalFlipX,
			"no_antialiasing": char.noAntialiasing,
			"healthbar_colors": char.healthColorArray,
			"isPlayerChar": char.wasPlayer
		};

		var data:String = Json.stringify(json, "\t");

		if (data.length > 0)
		{
			_file = new FileReference();
			_file.addEventListener(Event.COMPLETE, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data, daAnim + ".json");
		}
	}

	function ClipboardAdd(prefix:String = ''):String {
		if(prefix.toLowerCase().endsWith('v')) //probably copy paste attempt
		{
			prefix = prefix.substring(0, prefix.length-1);
		}

		var text:String = prefix + Clipboard.text.replace('\n', '');
		return text;
	}
}
