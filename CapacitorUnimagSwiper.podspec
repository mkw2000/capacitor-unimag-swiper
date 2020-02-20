
  Pod::Spec.new do |s|
    s.name = 'CapacitorUnimagSwiper'
    s.version = '0.3.3'
    s.summary = 'Capacitor plugin for IDTech mobile credit card swipers'
    s.license = 'MIT'
    s.homepage = 'https://github.com/mkw2000/capacitor-unimag-swiper'
    s.author = 'Michael Weiner'
    s.source = { :git => 'https://github.com/mkw2000/capacitor-unimag-swiper', :tag => s.version.to_s }
    s.source_files = 'ios/Plugin/**/*.{swift,h,m,c,cc,mm,cpp,a}'
    s.ios.deployment_target  = '11.0'
    s.public_header_files = 'Plugin/uniMag.h'
    s.ios.vendored_library = 'Plugin/libIDTECH_UniMag.a'
    s.preserve_paths = 'Plugin/libIDTECH_UniMag.a'
    s.dependency 'Capacitor'
    s.static_framework = true
    s.dependency 'IDTech'

  end   