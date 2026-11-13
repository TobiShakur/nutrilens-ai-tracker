import 'dart:js_interop';

@JS('window')
external _BrowserWindow get _window;

extension type _BrowserWindow(JSObject _) implements JSObject {
  external JSAny? open(String url, String target, [String features]);
  external _BrowserLocation get location;
}

extension type _BrowserLocation(JSObject _) implements JSObject {
  external void assign(String url);
}

/// Opens [url] in a new secure browser tab, or invokes mailto via location.
Future<void> openExternalLink(String url) async {
  if (url.startsWith('mailto:')) {
    _window.location.assign(url);
    return;
  }
  _window.open(url, '_blank', 'noopener,noreferrer');
}
