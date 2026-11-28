import 'dart:js_interop';
import 'dart:js_interop_unsafe';

@JS('document')
external JSObject get _jsDocument;

@JS('window')
external JSObject get _jsWindow;

@JS('navigator')
external JSObject get _jsNavigator;

void setWebDocumentTitle(String title) {
  _jsDocument.setProperty('title'.toJS, title.toJS);
}

Future<bool> tryNativeWebShare({
  required String title,
  required String text,
  required String url,
}) async {
  try {
    if (!_jsNavigator.has('share')) return false;
    final payload = JSObject();
    payload.setProperty('title'.toJS, title.toJS);
    payload.setProperty('text'.toJS, text.toJS);
    payload.setProperty('url'.toJS, url.toJS);
    final promise = _jsNavigator.callMethod<JSPromise<JSAny?>>('share'.toJS, payload);
    await promise.toDart;
    return true;
  } catch (_) {
    return false;
  }
}

void openExternalShareUrl(String url) {
  _jsWindow.callMethod<JSAny?>('open'.toJS, url.toJS, '_blank'.toJS);
}
