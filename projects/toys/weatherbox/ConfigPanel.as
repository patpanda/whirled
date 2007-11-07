//
// $Id$

package {

import flash.display.Sprite;

import flash.events.Event;
import flash.events.MouseEvent;

import flash.text.TextField;

import fl.controls.Button;
import fl.controls.ComboBox;

import fl.data.DataProvider;

import com.bogocorp.weather.NOAAWeatherService;

public class ConfigPanel extends Sprite
{
    public function ConfigPanel (box :WeatherBox, svc :NOAAWeatherService, bigMode :Boolean)
    {
        _box = box;
        _svc = svc;

        _stateBox = new ComboBox();
        _stationBox = new ComboBox();
        _statusLabel = new TextField();
        _close = new Button();

        if (bigMode) {
            _height = 150;
            _close.y = 127;
            _statusLabel.y = 130;
            // rowCount defaults are 5

        } else {
            _height = WeatherBox.HEIGHT;
            _close.y = 70;
            _statusLabel.y = 70;
            _stateBox.rowCount = 3;
            _stationBox.rowCount = 2;
        }

        graphics.beginFill(0xFFFFFF);
        graphics.drawRect(0, 0, width, height);

        _statusLabel.selectable =  false;
        _statusLabel.width = 200;
        _statusLabel.text = "Retrieving station directory...";
        addChild(_statusLabel);

        _stateBox.setSize(200, 22);
        _stateBox.prompt = "Choose state...";
        _stateBox.enabled = false;
        _stateBox.addEventListener(Event.CHANGE, handleStatePicked);
        _stateBox.y = 0;
        addChild(_stateBox);
        _stationBox.setSize(200, 22);
        _stationBox.prompt = "Choose station...";
        _stationBox.enabled = false;
        _stationBox.addEventListener(Event.CHANGE, handleStationPicked);
        _stationBox.y = 25;
        addChild(_stationBox);

        _close.label = "Close";
        _close.addEventListener(MouseEvent.CLICK, handleCloseClicked);
        _close.setSize(50, 22);
        _close.x = 199;
        addChild(_close);

        svc.getDirectory(directoryReceived);
    }

    override public function get width () :Number
    {
        return WeatherBox.WIDTH;
    }

    override public function get height () :Number
    {
        return _height;
    }

    protected function directoryReceived () :void
    {
        _statusLabel.text = "Choose your state and station.";
        var states :Array = _svc.getStates();
        _stateBox.dataProvider = new DataProvider(states);
        _stateBox.enabled = true;

        var state :String = _box.getState();
        if (state != null) {
            for each (var o :Object in states) {
                if (o.label == state) {
                    _stateBox.selectedItem = o;
                    handleStatePicked(null);
                    break;
                }
            }
        }
    }

    protected function handleStatePicked (event :Event) :void
    {
        var state :String = String(_stateBox.selectedItem.label);
        var stations :Array = _svc.getStations(state);
        _stationBox.dataProvider = new DataProvider(stations);
        _stationBox.enabled = true;
    
        var station :String = _box.getStation();
        if (station != null) {
            for each (var o :Object in stations) {
                if (o.station == station) {
                    _stationBox.selectedItem = o;
                    break;
                }
            }
        }
    }

    protected function handleStationPicked (event :Event) :void
    {
        _statusLabel.text = "Click Close when done.";
    }

    protected function handleCloseClicked (event :MouseEvent) :void
    {
        var state :String;
        var station :String;

        if (_stationBox.enabled) {
            state = String(_stateBox.selectedItem.label);
            station = String(_stationBox.selectedItem.station);
        }

        _box.closeConfigPanel();

        if (state != null && station != null) {
            _box.configure(state, station);
        }
    }
    
    protected var _box :WeatherBox;
    protected var _svc :NOAAWeatherService;

    protected var _statusLabel :TextField;

    protected var _stateBox :ComboBox;
    protected var _stationBox :ComboBox;

    protected var _close :Button;

    protected var _height :int;
}
}
