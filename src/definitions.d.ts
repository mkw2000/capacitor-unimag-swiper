declare module '@capacitor/core' {
  interface PluginRegistry {
    CapacitorUnimagSwiper: CapacitorUnimagSwiperPlugin;
  }
}

export interface CapacitorUnimagSwiperPlugin {
  
  /**
   * Initializes uniMag objext to start listening to SDK events
   * for connection, disconnection, swiping, etc.
   */
  activateReader(): Promise<{value: string}>;

  /**
   * Releases uniMag object. Because this stops listening to SDK
   * events, swiper will no longer function until activateReader
   * is called again by the containing app, unless this is called
   * by onPause.
   */
  deactivateReader(): Promise<void>;

  /**
   * Tells the SDK to begin expecting a swipe. From the moment this is
   * called, the user will have 30 seconds to swipe a card before a
   * timeout error occurs.
   */
  swipe(): Promise<{value: string}>;

}
