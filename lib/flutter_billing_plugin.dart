import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

typedef PurchaseUpdateHandler = void Function(String, dynamic);
typedef PriceUpdateHandler = void Function(String);

class FlutterBillingPlugin {
  static const MethodChannel _channel = MethodChannel('flutter_billing');

  PurchaseUpdateHandler? purchaseUpdateHandler;
  PriceUpdateHandler? priceUpdateHandler;

  FlutterBillingPlugin() {
    _channel.setMethodCallHandler(platformCallHandler);
  }

  void setPurchaseUpdateHandler(PurchaseUpdateHandler handler) {
    purchaseUpdateHandler = handler;
  }

  void setPriceUpdateHandler(PriceUpdateHandler handler) {
    priceUpdateHandler = handler;
  }

  Future<dynamic> init(List<String>? productIds, String? secretKey, bool isSendbox) => _channel.invokeMethod('init', {"product_ids": productIds ?? [], "secret_key": secretKey, "is_sendbox": isSendbox});

  Future<dynamic> buyProduct(String? productId) => _channel.invokeMethod('buy_product', {"product_id": productId});

  Future<dynamic> getPrice(String? productId) => _channel.invokeMethod('get_price', {"product_id": productId});

  Future<dynamic> checkRestore() => _channel.invokeMethod('check_restore');

  Future platformCallHandler(MethodCall call) async {
    switch (call.method) {
      case "isProductPurchased":
        bool status = await call.arguments;
        if (purchaseUpdateHandler != null) {
          purchaseUpdateHandler!("isProductPurchased", status);
        }
        break;
      case "success":
        String status = await call.arguments;
        if (purchaseUpdateHandler != null) {
          purchaseUpdateHandler!("success", status);
        }
        break;
      case "cancelled":
        String status = await call.arguments;
        if (purchaseUpdateHandler != null) {
          purchaseUpdateHandler!("cancelled", status);
        }
        break;
      case "error":
        String status = await call.arguments;
        if (purchaseUpdateHandler != null) {
          purchaseUpdateHandler!("error", status);
        }
        break;
      case "restore":
        bool status = await call.arguments;
        if (purchaseUpdateHandler != null) {
          purchaseUpdateHandler!("restore", status);
        }
        break;
      case "price":
        String price = await call.arguments;
        if (priceUpdateHandler != null) {
          priceUpdateHandler!(price);
        }
        break;
      default:
        if (kDebugMode) {
          print('Unknown method ${call.method} ');
        }
    }
  }
}
