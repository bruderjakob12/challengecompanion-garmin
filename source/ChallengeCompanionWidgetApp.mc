import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;


var inBackground = false;

(:background :glance)
class ChallengeCompanionWidgetApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }


    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
    }


    // onStop() is called when your application is exiting
    function onStop(state as Dictionary?) as Void {
    }


    // Return the initial view of your application here
    function getInitialView() as Array<Views or InputDelegates>? {
        if(Toybox.System has :ServiceDelegate) {
            // request once every hour
            Background.registerForTemporalEvent(new Time.Duration(60 * 60));
        }
        return [ new ChallengeCompanionWidgetView() ] as Array<Views or InputDelegates>;
    }


    (:glance)    
    function getGlanceView() {
        return [ new ChallengeCompanionGlanceView() ];
    }

    function getServiceDelegate() { 
        inBackground = true;
        return [new ChallengeCompanion()]; 
    }

    function onBackgroundData(data) {
    }
}

function getApp() as ChallengeCompanionWidgetApp {
    return Application.getApp() as ChallengeCompanionWidgetApp;
}