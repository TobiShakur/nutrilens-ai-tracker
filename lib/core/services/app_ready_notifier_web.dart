import 'package:web/web.dart' as web;

/// Dispatches the `app-ready` DOM event once fonts, images, and first frame
/// have settled so `#initial-loader` transitions out smoothly.
void notifyAppReady() {
  web.window.dispatchEvent(web.Event('app-ready'));
}
