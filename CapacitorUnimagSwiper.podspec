
  Pod::Spec.new do |s|
    s.name = 'CapacitorUnimagSwiper'
    s.version = '0.0.5'
    s.summary = 'Capacitor plugin for IDTech mobile credit card swipers'
    s.license = 'WTFPL'
    s.homepage = 'https://github.com/mkw2000/capacitor-unimag-swiper'
    s.author = 'Michael Weiner'
    s.source = { :git => 'https://github.com/mkw2000/capacitor-unimag-swiper', :tag => s.version.to_s }
    s.source_files = 'ios/Plugin/**/*.{swift,h,m,c,cc,mm,cpp}'
    s.ios.deployment_target  = '11.0'
    s.ios.vendored_library = 'Plugin/IDTECH_UniMag.a'
    s.dependency 'Capacitor'
  end