# Capacitor Unimag Swiper

The purpose of this plugin is to allow for swiping credit cards using the IDTech UniMag II, UniMag Pro, or Shuttle mobile readers in hybrid applications.

### Supported Platforms

- **iOS**

### Installation

```
npm install capacitor-unimag-swiper
```

```
npx cap sync ios 
```


## Usage

The IDTech reader can be used by calling the **activate** method on your plugin object. Here, "activated" means that the plugin will be able to listen to IDTech SDK events. The IDTech SDK (hereby referred to simply as SDK) sends a wide variety of events related to reader tasks such as connection and swipe. In response to some of these events, the plugin will fire its own events that you can capture in your application.

A reader may be either **attached** or **detached**. It is attached when it is plugged into the mobile device running your application. While the reader is activated, once a reader is attached, (or if it is already attached upon application startup) the SDK will begin a connection task with the reader. When this task begins, a **"connecting"** event will be fired from the plugin. After the task has finished successfully, a **"connected"** event will fire. If a connection could not be established, a **"timeout"** event will be fired instead. Once you have captured the **"connected"** event you can begin initiating the swipe process.

To initiate the swipe process, call the **swipe** method on your plugin object. After this method has been called you can physically swipe the card. The data will be parsed and returned if valid. This will result in a **"swipe_success"** event containing the data (it will be stringified, you will need to parse it). If the card data was invalid, or the swipe was otherwise unsuccessful (e.g., if it was crooked) you a **"swipe_error"** event will be fired instead.

You can deactivate the reader by calling the **deactivate** method on your plugin object. Once the reader has been deactivated, it will not listen to attachment/detachment and will never attempt a connection. The reader need not be attached for it to be activated successfully - if it is activated, it will automatically detect attachment/detachment and handle connection as such.

NOTE: To use this plugin you'll need to disable bitcode. You can do this by clicking on your project in Xcode and going to Build Settings. Search for 'bitcode', and you'l see an 'Enable Bitcode' setting. Change this to 'No'. There is currently no way for me to configure this through the plugin, as far as I'm aware.

## Events

See Sample section for how exactly to capture the events listed below.

| name                 | platform     | meaning                                                                                                                                            | details                                                                                                                                                                   |
| -------------------- | ------------ | -------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| connecting           | iOS, Android | connection task has begun                                                                                                                          | none                                                                                                                                                                      |
| connected            | iOS, Android | connection task was successful                                                                                                                     | none                                                                                                                                                                      |
| disconnected         | iOS, Android | reader was disconnected                                                                                                                            | none                                                                                                                                                                      |
| timeout              | iOS, Android | connection or swipe task has timed out                                                                                                             | string: message from SDK regarding timeout type                                                                                                                           |
| swipe_processing     | iOS, Android | swipe has been received and is processing                                                                                                          | none                                                                                                                                                                      |
| swipe_success        | iOS, Android | card data has been parsed successfully                                                                                                             | string: use JSON.parse to get object of card data w/ properties card_number, expiry_month, expiry_year, first_name, last_name, & trimmedUnimagData (raw data from reader) |
| swipe_error          | iOS, Android | card data was invalid and could not be parsed                                                                                                      | none                                                                                                                                                                      |
| connection_error     | iOS          | connection task was unsuccessful                                                                                                                   | string: message from plugin with reason reader could not connect                                                                                                          |
| xml_error            | Android      | xml config file listing settings for devices could not be loaded, can also be called during auto config if the device's volume could not be raised | string: message from SDK regarding particular issue with XML config file                                                                                                  |
| autoconfig_completed | Android      | auto config process completed and connection should now begin                                                                                      | none                                                                                                                                                                      |
| autoconfig_error     | Android      | auto config process failed or timed out                                                                                                            | string: message from SDK in case of timeout                                                                                                                               |

## Sample

The sample demonstrates how to activate the reader, capture events, and swipe a card.

```javascript
document.addEventListener(
  "deviceready",
  function() {
    cordova.plugins.unimag.swiper.activate();
    cordova.plugins.unimag.swiper.enableLogs(true);
    cordova.plugins.unimag.swiper.setReaderType("unimag_ii");

    var connected = false;

    var swipe = function() {
      if (connected) {
        cordova.plugins.unimag.swiper.swipe(
          function successCallback() {
            console.log("SUCCESS: Swipe started.");
          },
          function errorCallback() {
            console.log("ERROR: Could not start swipe.");
          }
        );
      } else console.log("ERROR: Reader is not connected.");
    };

    cordova.plugins.unimag.swiper.on("connected", function() {
      connected = true;
    });

    cordova.plugins.unimag.swiper.on("disconnected", function() {
      connected = false;
    });

    cordova.plugins.unimag.swiper.on("swipe_success", function(e) {
      var data = JSON.parse(e.detail);
      console.log("cardholder name: " + data.first_name + " " + data.last_name);
      console.log("card number:" + data.card_number);
      console.log("expiration:" + data.expiry_month + "/" + data.expiry_year);
    });

    cordova.plugins.unimag.swiper.on("swipe_error", function() {
      console.log("ERROR: Could not parse card data.");
    });

    cordova.plugins.unimag.swiper.on("timeout", function(e) {
      if (connected) {
        console.log("ERROR: Swipe timed out - " + e.detail);
      } else {
        console.log("ERROR: Connection timed out - " + e.detail);
      }
    });
  },
  false
); 


    async activate() {
        const result = await CapacitorUnimagSwiper.activateReader();
        if (result === "active") {
            this.activated = true;
        } else {

        }
    }

    async ngOnInit() {
    
    
    
    }

```

## Contributing (please do!)

1. Fork this repo.
2. Create your own branch. (`git checkout -b my-feature`)
3. Commit your changes. (`git commit -am 'Add my awesome feature'`)
4. Push to your branch. (`git push origin my-feature`)
5. Create new pull request.

## License

This software is released under the <a href="http://www.wtfpl.net/">WTFPL License</a>.
