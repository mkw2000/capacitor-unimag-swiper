#import <Foundation/Foundation.h>
#import <Capacitor/Capacitor.h>
#import <UIKit/UIKit.h>

// Define the plugin using the CAP_PLUGIN Macro, and
// each method the plugin supports using the CAP_PLUGIN_METHOD macro.
CAP_PLUGIN(CapacitorUnimagSwiper, "CapacitorUnimagSwiper",
CAP_PLUGIN_METHOD(activateReader, CAPPluginReturnPromise);
CAP_PLUGIN_METHOD(deactivateReader, CAPPluginReturnPromise);
CAP_PLUGIN_METHOD(swipe, CAPPluginReturnPromise);
)
