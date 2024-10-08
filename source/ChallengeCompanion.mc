import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.Math;
import Toybox.Application.Properties;
import Toybox.Application.Storage;
using Toybox.Communications as Comms;
using Toybox.System;
using Toybox.Timer;
import Toybox.Time.Gregorian;

(:background :glance)
class ChallengeCompanion {

    const MAX_TRIES = 2;
    var tries = 0;
    var fg_color = Graphics.COLOR_WHITE;
    var bg_color = Graphics.COLOR_BLACK;
    var hl_color = Graphics.COLOR_DK_GRAY;
    var dl_color = Graphics.COLOR_LT_GRAY;
    var data = {};
    var logo = null;
    var width = null;
    var height = null;
    var is_instinct = false;
    var is_crossover = false;
    const STATUS = "status";


    function initialize() {
        self.makeRequest();
        if (!Application.getApp().inBackground) {
            // start the timer
            var myTimer = new Timer.Timer();
            myTimer.start(method(:makeRequest), 60000, true);
            self.is_instinct = (WatchUi has :getSubscreen);
            self.is_crossover = (WatchUi.View has :setClockHandPosition);
        }
    }


    function getImageRequest() as Void {
        var options = {
            :maxWidth => (self.width/4).toNumber(),
            :maxHeight => (self.width/4).toNumber()
        };
        var params = {                                              // set the parameters
            "k" => Properties.getValue("k"),
            "c" => Properties.getValue("c"),
        };
        var url = Properties.getValue("e")+"/logo";
        Communications.makeImageRequest(url, params, options, method(:onLogoReceive));
    }


    function setRes(width, height) {
        self.width = width;
        self.height = height;
        self.getImageRequest();
    }


    function makeRequest() as Void {
        var mySettings = System.getDeviceSettings();
        var info = ActivityMonitor.getInfo();
        var id = mySettings.uniqueIdentifier;

        var today = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);		
        var profile = UserProfile.getProfile();
        var age_factor = - 197.6;
        if (profile.gender == UserProfile.GENDER_MALE) {
            age_factor = 5.2;
        }
        // https://forums.garmin.com/developer/connect-iq/f/discussion/208338/active-calories#pifragment-1298=2
        // restCalories = -197.6 - 6.116*age + 7.628*profile.height + 12.2*weight;
        var rest_calories = age_factor - 6.116*(today.year - profile.birthYear) + 7.628*profile.height + 12.2*(profile.weight / 1000.0);
        var rest_calories_today = Math.round((today.hour*60+today.min) * rest_calories / 1440 ).toNumber();

        var hist = ActivityMonitor.getHistory();
        // history only contains the data for days that are already "over"
        var floorsClimbed = 0;
        if (info has :floorsClimbed) {
            floorsClimbed = info.floorsClimbed;
        }
        var data = [0, info.steps, info.calories, info.calories - rest_calories_today, info.distance, info.activeMinutesDay.total, floorsClimbed];
        if (hist != null) {
            for (var i=0; i < hist.size(); ++i) {
                data.add(hist[i].startOfDay.value());
                data.add(hist[i].steps);
                data.add(hist[i].calories);
                data.add(hist[i].calories - rest_calories);
                data.add(hist[i].distance);
                data.add(hist[i].activeMinutes.total);
                if (hist[i] has :floorsClimbed) {
                    data.add(hist[i].floorsClimbed);
                } else {
                    data.add(0);
                }
            }
        }

        var params = {                                              // set the parameters
            "u" => Properties.getValue("u"), // username
            "t" => Properties.getValue("t"), // team-name
            "c" => Properties.getValue("c"), // challenge-name
            "d" => data.toString(), // list with data containing timestamps, steps, calories, active calories
            "o" => (System.getClockTime().timeZoneOffset/60).toNumber(), // timezone-offset
            "i" => id, // unique app&user&device-id
            "v" => System.getDeviceSettings().monkeyVersion.toString(),
        };
        var headers = {                                           // set headers
                "Accept-Encoding" => "deflate",
                "Content-Type" => Communications.REQUEST_CONTENT_TYPE_JSON
        };
        var options = {                                             // set the options
            :method => Communications.HTTP_REQUEST_METHOD_POST,      // set HTTP method
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON, // set response type
            :headers => headers,
        };
        if (!Application.getApp().inBackground) {
            Communications.makeWebRequest(Properties.getValue("e") + "/data", params, options, method(:onReceive));
        } else {
            Communications.makeWebRequest(Properties.getValue("e") + "/data", params, options, method(:onDummyReceive));
        }
    }

    // set up the response callback function
    function onDummyReceive(responseCode as Number, data as Dictionary?) as Void {
        Background.exit(responseCode);
    }


    // set up the response callback function
    function onReceive(responseCode as Number, data as Dictionary?) as Void {
        if (responseCode != 200) {
            self.data = {"status" => "oopsi woopsi!\nE"+responseCode.toString()};
        } else {
            if (data instanceof Dictionary && data.hasKey("k")) {
                // updating the image-key
                Properties.setValue("k", data);
            }
            self.data = data;
        }
        WatchUi.requestUpdate();
    }


    function onLogoReceive(responseCode as Number, data as Dictionary?) as Void {
        if (responseCode != 200) {
            //self.data = {"status" => "E"+responseCode.toString()};
            self.logo = false;
        } else {
            self.logo = data;
        }
        WatchUi.requestUpdate();
    }


    function draw_main(dc) {
        // Call the parent onUpdate function to redraw the layout
        var display_headline = "loading...";
        var display_text = "";

        if (self.data.hasKey(self.STATUS)) {
            display_text = self.data[self.STATUS].toString();
        }

        if (self.data.hasKey("c")) {
            display_headline = self.data["c"].toString();
        }

        if (!System.getDeviceSettings().phoneConnected) {
            display_text += "\nnot connected\nto phone";
        }

        var watch_width = dc.getWidth() / 2;
        if (self.is_instinct) {
            watch_width = dc.getWidth() / 3;
        }
        dc.setColor(self.fg_color, self.bg_color);
        dc.clear();
        dc.setColor(self.fg_color, Graphics.COLOR_TRANSPARENT);
        if (self.logo != null and !(self.logo instanceof Toybox.Lang.Boolean)) {
            dc.drawBitmap(dc.getWidth()/2-(self.width/8), 0, self.logo);
        }
        dc.drawText(watch_width, (self.width/4).toNumber()+self.width*0.05, Graphics.FONT_SMALL, display_headline, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(watch_width, dc.getHeight()/2, Graphics.FONT_XTINY, display_text, Graphics.TEXT_JUSTIFY_CENTER);
    }


    function draw_glance(dc) {
        // Call the parent onUpdate function to redraw the layout
        var fg = Graphics.COLOR_WHITE;
        var bg = Graphics.COLOR_BLACK;
        if (System.getDeviceSettings() has :isNightModeEnabled && !System.getDeviceSettings().isNightModeEnabled) {
            fg = Graphics.COLOR_BLACK;
            bg = Graphics.COLOR_WHITE;
        }
        var display_text = "loading...";
        
        var value_color = Graphics.COLOR_BLACK;
        if (value_color == bg) {
            value_color = Graphics.COLOR_WHITE;
        }

        if (self.data.hasKey(self.STATUS)) {
            display_text = self.data[self.STATUS].toString();
        }

        var textLeft = Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER;

        dc.setColor(fg, bg);
        dc.clear();     
        dc.setColor(fg, Graphics.COLOR_TRANSPARENT);
        dc.drawText(0, dc.getHeight()/2, Graphics.FONT_GLANCE, display_text, textLeft);
    }
}