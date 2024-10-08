import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.Application.Properties;
using Toybox.Communications as Comms;
using Toybox.System;
using Toybox.Timer;


(:glance)
class ChallengeCompanionGlanceView extends WatchUi.GlanceView {

    var ChallengeCompanion;

    function initialize() {
        self.ChallengeCompanion = new ChallengeCompanion();
        GlanceView.initialize();	         
    }
    
    function onLayout(dc) {
    }

    function onUpdate(dc) {
        self.ChallengeCompanion.draw_glance(dc);
    }
}


class ChallengeCompanionWidgetView extends WatchUi.View {

    var ChallengeCompanion;

    function initialize() {
        self.ChallengeCompanion = new ChallengeCompanion();
        View.initialize();
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
        //setLayout(Rez.Layouts.MainLayout(dc));
        self.ChallengeCompanion.setRes(dc.getWidth(), dc.getHeight());
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
        self.ChallengeCompanion.draw_main(dc);
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {
    }
}
