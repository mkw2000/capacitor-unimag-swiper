import Capacitor
import Foundation
import UIKit

@objc(CapacitorUnimagSwiper)
public class CapacitorUnimagSwiper: CAPPlugin {

    /**
     * This plugin allows for swiping a credit or debit card and returning
     * its parsed data for use in financial transactions.
     */

    // Indicates whether app has launched and observers have been set
    var pluginInited = false
    // Reader from SDK to handle all swipe functionality
    var reader: uniMag?
    // Indicates if the containing app has not manually deactivated reader
    var readerActivated = false
    // Stores user preference, default false
    var enableLogs = true
    // Type of uniMag reader
    var readerType: UmReader?

    /***************************************************
     * LIFECYCLE
     ***************************************************/

    /**
     * Rather than register an observer for UIApplicationDidFinishLaunchingNotification,
     * this method is used directly to register observers for subsequent lifecycle
     * notifications.
     */

    @objc func initPlugin() {
        if !pluginInited {
            uniMag.enableLogging(true)

            let center = NotificationCenter.default

            center.addObserver(self, selector: #selector(onPause), name:
                UIApplication.willResignActiveNotification, object: nil)

            center.addObserver(self, selector: #selector(onResume), name:
                UIApplication.didBecomeActiveNotification, object: nil)

            pluginInited = true
        }
    }

    /**
     * Called when the application enters the background.
     * The reader is killed to maintain consistency with Android behavior.
     */

    @objc func onPause(_ notification: Notification?) {
        if readerActivated {
            deactivateReader(nil)
        }
    }


    /**
     * Called when the application returns to the foreground.
     * The reader is reinitialized as if the app was just opened.
     */

    @objc func onResume(_ notification: Notification?) {
        if readerActivated {
            activateReader(nil)
        }
    }


    /***************************************************
     * JAVASCRIPT INTERFACE IMPLEMENTATION
     ***************************************************/

    /**
     * Initializes uniMag object to start listening to SDK events
     * for connection, disconnection, swiping, etc.
     *
     * @param {CDVInvokedUrlCommand*}
     *        The command sent from JavaScript
     */

    @objc func activateReader(_ call: CAPPluginCall?) {

        DispatchQueue.global(qos: .background).async {

            // Register observers if this is the first time reader
            // is activated
            self.initPlugin()

            if self.reader == nil {
                // Because logging is a class method, we can call
                // it before initialization
                uniMag.enableLogging(self.enableLogs)

                // Begin listening to SDK events, including
                // initialization
                self.setReaderListener(true)

                self.reader = uniMag.init()
                self.reader?.setAutoConnect(true)
                self.reader?.setSwipeTimeoutDuration(30)
                self.reader?.setAutoAdjustVolume(true)

                // Set type if possible
                if self.readerType != nil {
                    self.reader?.readerType = self.readerType!
                }

                // Store status of connection task
                let activated = self.reader!.start(true)

                if call != nil {
                    self.readerActivated = true;

                    if activated == UMRET_SUCCESS {
                        call?.resolve([
                            "value": "activate reader",
                        ])

                    } else if activated == UMRET_NO_READER {
                        call?.resolve([
                            "value": "no reader",
                        ])
                    } else {
                        call?.reject("rejected in active reeader")
                    }
                } else {
                    call?.reject("call is nil")
                }
            }

        }

    }

    @objc func deactivateReader(_ call: CAPPluginCall?) {

        if self.reader != nil {
            self.reader?.cancelTask()

            // Stop listening to SDK events
            self.setReaderListener(false)
            self.reader = nil

            fireEvent("disconnected")
        } else {
            call?.resolve([
                "value": "reader already deactivated",
            ])        }

        if call != nil {
            self.readerActivated = false
            call?.resolve([
                "value": "deactivate reader",
            ])

        }

    }

    /**
     * Tells the SDK to begin expecting a swipe. From the moment this is
     * called, the user will have 30 seconds to swipe a card before a
     * timeout error occurs.
     *
     * @param {CDVInvokedUrlCommand*} command
     *        The command sent from JavaScript
     */

    @objc func swipe(_ call: CAPPluginCall?) {

        DispatchQueue.global(qos: .background).async {
            print("This is run on the background queue")
            //            var result: CDVPluginResult?

            if self.reader != nil {
                guard let reader = self.reader else {
                    return
                };
                if reader.getConnectionStatus() == true {
                    reader.cancelTask()

                    // Store status of swipe task
                    let swipeStarted = reader.requestSwipe()
                    print(swipeStarted)
                    if swipeStarted == UMRET_SUCCESS {
                        call?.resolve([
                            "value": "swipe started",
                        ])
                    } else {
                        call?.reject("swipe fail")

                    }
                } else {
                    call?.resolve([
                        "value": "reader activated but not connected",
                    ])
                }
            } else {
                call?.resolve([
                    "value": "Reader must be activated before starting swipe.",
                ])
            }

        }

    }


    /***************************************************
     * SDK CALLBACKS
     ***************************************************/

    /**
     * Receive notification from the SDK when the device is powering up.
     * Can result in a timeout rather than an actual connection.
     */

    @objc func umConnecting(_ notification: Notification?) {
        fireEvent("uniMagPoweringNotification")
    }

    /**
     * Receive notification from the SDK when the swiper is connected to
     * the device. Swipe cannot be performed until this has been called.
     */
    @objc func umConnected(_ notification: Notification?) {
        fireEvent("uniMagDidConnectNotification")
    }

    /**
     * Receive notification from the SDK when the swiper becomes disconnected
     * from the device.
     */
    @objc func umDisconnected(_ notification: Notification?) {
        fireEvent("uniMagDidDisconnectNotification")
    }

    /**
     * Receive notification from the SDK when connection task has timed out.
     */
    @objc func umConnectionTimeout(_ notification: Notification?) {
        fireEvent("uniMagTimeoutSwipeNotification", withData: "Connection timed out.")
    }

    /**
     * Receive notification from SDK when system volume is too low to connect.
     */
    @objc func umConnection_InsufficientPower(_ notification: Notification?) {
        fireEvent("uniMagTimeoutSwipeNotification", withData: "Volume too low. Please maximize volume before reattaching swiper.")
    }

    /**
     * Receive notification from SDK when mono audio is enabled by system,
     * blocking a connection.
     */
    @objc func umConnectionMonoAudio(_ notification: Notification?) {
        fireEvent("uniMagTimeoutSwipeNotification", withData: "Mono audio is enabled. Please disable it in your iOS settings.")
    }

    /**
     * Receive notification from the SDK when swipe task has timed out.
     */
    @objc func umSwipeTimeout(_ notification: Notification?) {
        fireEvent("uniMagTimeoutSwipeNotification", withData: "Swipe timed out.")
    }

    /**
     * Receive notification from the SDK as soon as it detects data coming from
     * the swiper after requestSwipe API method is called.
     */
    @objc func umSwipeProcessing(_ notification: Notification?) {
        fireEvent("uniMagDataProcessingNotification")
    }

    /**
     * Receive notification from the SDK when it cannot read a swipe (i.e., a
     * crooked swipe) rather than behave as if no swipe was made.
     */
    @objc func umSwipeError(_ notification: Notification?) {
        fireEvent("uniMagInvalidSwipeNotification")
    }

    /**
     * Receive notification from the SDK when a successful swipe was read. Parses
     * the raw card data and sends resulting JSON with event.
     */
    @objc func umSwipeReceived(_ notification: Notification?) {

                let data = notification?.object as? Data

                var cardData: String? = nil
                if let data = data {
                    cardData = String(data: data, encoding: .ascii)
                }

                let parsedCardData = parseCardData(cardData)

                if parsedCardData != "" {
                    print(parsedCardData)
                    fireEvent("uniMagDidReceiveDataNotification", withData: parsedCardData)
                } else {
                    fireEvent("uniMagInvalidSwipeNotification")
                }
    }

    /***************************************************
     * UTILS
     ***************************************************/

    /**
     * Adds or removes observers for SDK notifications.
     *
     * @param {BOOL} listen
     *        Whether to register
     */

    @objc func setReaderListener(_ listen: Bool) {


        let center = NotificationCenter.default

        if listen {
            center.addObserver(self, selector: #selector(umConnected(_:)), name: NSNotification.Name("uniMagDidConnectNotification"), object: nil)
            center.addObserver(self, selector: #selector(umDisconnected(_:)), name: NSNotification.Name("uniMagDidDisconnectNotification"), object: nil)
            center.addObserver(self, selector: #selector(umConnectionTimeout(_:)), name: NSNotification.Name("uniMagTimeoutNotification"), object: nil)
            center.addObserver(self, selector: #selector(umConnection_InsufficientPower(_:)), name: NSNotification.Name("uniMagInsufficientPowerNotification"), object: nil)
            center.addObserver(self, selector: #selector(umConnectionMonoAudio(_:)), name: NSNotification.Name("uniMagMonoAudioErrorNotification"), object: nil)
            center.addObserver(self, selector: #selector(umSwipeProcessing(_:)), name: NSNotification.Name("uniMagDataProcessingNotification"), object: nil)
            center.addObserver(self, selector: #selector(umSwipeReceived(_:)), name: NSNotification.Name("uniMagDidReceiveDataNotification"), object: nil)
            center.addObserver(self, selector: #selector(umSwipeTimeout(_:)), name: NSNotification.Name("uniMagTimeoutSwipeNotification"), object: nil)
            center.addObserver(self, selector: #selector(umSwipeError(_:)), name: NSNotification.Name("uniMagInvalidSwipeNotification"), object: nil)
            center.addObserver(self, selector: #selector(umConnecting(_:)), name: NSNotification.Name("uniMagPoweringNotification"), object: nil)

        } else {
            center.removeObserver(self, name: NSNotification.Name("uniMagDidConnectNotification"), object: nil)
            center.removeObserver(self, name: NSNotification.Name("uniMagDidDisconnectNotification"), object: nil)
            center.removeObserver(self, name: NSNotification.Name("uniMagDidConnectNotification"), object: nil)
            center.removeObserver(self, name: NSNotification.Name("uniMagTimeoutNotification"), object: nil)
            center.removeObserver(self, name: NSNotification.Name("uniMagInsufficientPowerNotification"), object: nil)
            center.removeObserver(self, name: NSNotification.Name("uniMagMonoAudioErrorNotification"), object: nil)
            center.removeObserver(self, name: NSNotification.Name("uniMagDataProcessingNotification"), object: nil)
            center.removeObserver(self, name: NSNotification.Name("uniMagDidReceiveDataNotification"), object: nil)
            center.removeObserver(self, name: NSNotification.Name("uniMagInvalidSwipeNotification"), object: nil)
            center.removeObserver(self, name: NSNotification.Name("uniMagPoweringNotification"), object: nil)

        }

    }

    /**
     * Uses a regex to parse raw card data.
     * @param  {NSString*} data
     *         Raw card data
     * @return {NSString*}
     *         Stringified JSON representation of parsed card data
     */

        @objc func parseCardData(_ data: String?) -> String? {
            var num: String?
            var name: [AnyHashable]?
            var exp: String?

            var error: Error? = nil
            var cardParser: NSRegularExpression? = nil
            do {
                cardParser = try NSRegularExpression(pattern: "%B(\\d+)\\^([^\\^]+)\\^(\\d{4})", options: [])
            } catch {
            }

            let matches = cardParser?.matches(in: data ?? "", options: [], range: NSRange(location: 0, length: data?.count ?? 0))

            if matches?.count != nil {
                if let range = matches?[0].range(at: 1) {
                    num = (data as NSString?)?.substring(with: range)
                }

                if let range = matches?[0].range(at: 2) {
                    name = ((data as NSString?)!.substring(with: range)).components(separatedBy: "/")
                }

                if let range = matches?[0].range(at: 3) {
                    exp = (data as NSString?)?.substring(with: range)
                }

                if num != nil && (name?.count ?? 0) >= 2 && name?[0] != nil && name?[1] != nil && exp != nil {

                    let firstName = name?[0] as! String;
                    let lastName = name?[1] as! String;
                    let cardData: [String : Any] = [
                        "card_number" : num ?? "",
                        "expiry_month" : (exp as NSString?)?.substring(from: 2),
                        "expiry_year" : (exp as NSString?)?.substring(to: 2),
                        "first_name" : firstName,
                        "last_name" : lastName,
                        "trimmedUnimagData" : data?.components(separatedBy: CharacterSet.whitespacesAndNewlines).joined(separator: "")
                    ]

                    return String(data: try! JSONSerialization.data(withJSONObject: cardData, options: []), encoding: .utf8)
                }
            }
            return nil
        }


    /**
     * Retrieve error message corresponding to a particular UmRet value.
     *
     * @param  {UmRet}      ret
     *         Status of an SDK task
     * @return {NSString*}
     *         Corresponding error message
     */

    @objc func getUmRetErrorMessage(_ ret: UmRet) -> String? {
        switch ret {
        case UMRET_NO_READER:
            return "No reader is attached."
        case UMRET_NOT_CONNECTED:
            return "Connection task must be run first."
        case UMRET_ALREADY_CONNECTED:
            return "Reader is already connected."
        case UMRET_MONO_AUDIO:
            return "Mono audio is enabled."
        case UMRET_LOW_VOLUME:
            return "iOS device playback volume is too low."
        case UMRET_SDK_BUSY:
            return "SDK is busy running another task."
        default:
            return nil
        }
    }

    /**
     * Pass event to method overload.
     *
     * @param {NSString*} event
     *        The event name
     */

    @objc func fireEvent(_ event: String?) {
        fireEvent(event, withData: nil)
    }

    /**
     * Format and send event to JavaScript side.
     *
     * @param {NSString*} event
     *        The event name
     * @param {NSString*} data
     *        Details about the event
     */

    @objc func fireEvent(_ event: String?, withData data: String?) {
        let dataArg = data != nil ? "','\(data ?? "")" : ""
        self.notifyListeners(event, data: ["data" : dataArg])
    }

}
