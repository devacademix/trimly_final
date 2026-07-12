Drop real branding here before store submission:

  icon.png            - 1024x1024 PNG, square, full-bleed logo (used for iOS
                         icon, splash screen, and the Android adaptive icon's
                         background layer image if you don't split fg/bg).
  icon_foreground.png - 1024x1024 PNG, transparent background, logo centered
                         with safe padding (used as the Android adaptive
                         icon foreground layer).

Then run, from apps/customer-app:
  dart run flutter_launcher_icons
  dart run flutter_native_splash:create

Both commands read their config from pubspec.yaml (flutter_launcher_icons: /
flutter_native_splash: sections) and regenerate every platform's icon/splash
assets in place. Re-run whenever the logo changes.
