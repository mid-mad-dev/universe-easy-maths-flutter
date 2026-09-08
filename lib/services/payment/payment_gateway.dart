export 'payment_gateway_result.dart';

export 'payment_gateway_stub.dart'
    if (dart.library.html) 'payment_gateway_stub.dart'
    if (dart.library.js_interop) 'payment_gateway_stub.dart'
    if (dart.library.io) 'payment_gateway_mobile.dart';
