// $Id$

package com.threerings.graffiti.tools {

import fl.controls.ComboBox;
import fl.controls.Slider;

import fl.events.SliderEvent;

import fl.data.DataProvider;

import flash.display.Loader;
import flash.display.DisplayObject;
import flash.display.MovieClip;
import flash.display.SimpleButton;
import flash.display.Sprite;

import flash.events.Event;
import flash.events.MouseEvent;

import flash.system.ApplicationDomain;

import com.threerings.flash.DisplayUtil;

import com.threerings.util.Log;
import com.threerings.util.MultiLoader;

import com.whirled.contrib.DelayUtil;

import com.threerings.graffiti.Canvas;

[Event(name="colorPicked", type="ToolEvent")];
[Event(name="brushPicked", type="ToolEvent")];
[Event(name="backgroundColor", type="ToolEvent")];
[Event(name="clearCanvas", type="ToolEvent")];

public class ToolBox extends Sprite 
{
    public static const POPUP_WIDTH :int = 485;
    public static const POPUP_HEIGHT :int = 465;

    public function ToolBox (canvas :Canvas) 
    {
        addChild(_canvas = canvas);
        MultiLoader.getLoaders(TOOLBOX_UI, handleUILoaded, false, ApplicationDomain.currentDomain); 
    }

    public function pickColor (color :uint) :void
    {
        // TODO: pick color for currently selected color picker
        // commented out to prevent NPE
//        var w :int = _brushSwatch.width;
//        var h :int = _brushSwatch.height;
//        _brushSwatch.graphics.clear();
//        _brushSwatch.graphics.beginFill(color);
//        _brushSwatch.graphics.drawRect(0, 0, w, h);
//        _brushSwatch.graphics.endFill();
//        _brush.color = color;
        dispatchEvent(new ToolEvent(ToolEvent.BRUSH_PICKED, _brush.clone()));
    }
    
    public function hoverColor (color :uint) :void
    {
        // TODO
    }

    public function setBackgroundColor (color :uint) :void
    {
        dispatchEvent(new ToolEvent(ToolEvent.BACKGROUND_COLOR, color));
    }

    public function clearCanvas () :void
    {
        dispatchEvent(new ToolEvent(ToolEvent.CLEAR_CANVAS));
    }

    public function displayFillPercent (percent :Number) :void
    {
    }
    
    protected function handleUILoaded (loader :Loader) :void
    {
        var ui :MovieClip = loader.content as MovieClip;
        addChild(ui);

        DelayUtil.init(this);
        DelayUtil.delay(DelayUtil.FRAMES, 10, function () :void {
            _brushSwatch = 
                DisplayUtil.findInHierarchy(ui.bg_color, "bfcolor_swatch", false, 5) as Sprite;
            log.debug("find [" + _brushSwatch + "]");
            log.debug("upState [" + DisplayUtil.dumpHierarchy(ui.bg_color.upState) + "]");
            log.debug("overState [" + DisplayUtil.dumpHierarchy(ui.bg_color.overState) + "]");
            log.debug("downState [" + DisplayUtil.dumpHierarchy(ui.bg_color.downState) + "]");
        });

        var palette :Palette = new Palette(this, 0xFF0000);
        palette.x = 445;
        palette.y = 65;
        addChild(palette);

        var thicknessSlider :Slider = ui.size_slider;
        thicknessSlider.liveDragging = true;
        thicknessSlider.minimum = MIN_BRUSH_SIZE;
        thicknessSlider.maximum = MAX_BRUSH_SIZE;
        thicknessSlider.value = _brush.thickness;
        thicknessSlider.snapInterval = 1;
        thicknessSlider.addEventListener(SliderEvent.CHANGE, function (event :SliderEvent) :void {
            _brush.thickness = thicknessSlider.value;
            dispatchEvent(new ToolEvent(ToolEvent.BRUSH_PICKED, _brush.clone()));
        });

        var alphaSlider :Slider = ui.alpha_slider;
        alphaSlider.liveDragging = true;
        alphaSlider.maximum = 1;
        alphaSlider.minimum = 0;
        alphaSlider.value = _brush.alpha;
        alphaSlider.snapInterval = 0.05;
        alphaSlider.addEventListener(SliderEvent.CHANGE, function (event :SliderEvent) :void {
            _brush.alpha = alphaSlider.value;
            dispatchEvent(new ToolEvent(ToolEvent.BRUSH_PICKED, _brush.clone()));
        });

        var fontSizeCombo :ComboBox = ui.font_size;
        fontSizeCombo.dataProvider = new DataProvider(["TODO"]);

        var doneButton :SimpleButton = ui.done_button;
        doneButton.addEventListener(MouseEvent.CLICK, function (event :MouseEvent) :void {
            dispatchEvent(new ToolEvent(ToolEvent.DONE_EDITING));
        });
    }

    [Embed(source="../../../../../rsrc/graffiti_UI.swf", mimeType="application/octet-stream")]
    protected static const TOOLBOX_UI :Class;

    protected var MIN_BRUSH_SIZE :int = 2;
    protected var MAX_BRUSH_SIZE :int = 60;

    private static const log :Log = Log.getLog(ToolBox);

    protected var _canvas :Canvas;
    protected var _brush :Brush = new Brush();

    protected var _brushSwatch :Sprite;
}
}
