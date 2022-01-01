# flutter_billing_plugin

This plugin supports in-app purchases for App Store (on iOS) or Google Play (on Android).

Simple steps to add in-app purchases in you flutter app.

# Getting Started

Add below line to your pubspec.yaml file
```dart
dependencies:
  flutter_billing_plugin: ^0.0.8
```

Initialize Plugin
```dart
@override
  void initState() {
    super.initState();
    initBilling();
    initListeners();
    initPrice();
  }

  Future<void> initBilling() async {
    billingHelper = FlutterBillingPlugin();
    await billingHelper?.init(productIds);
  }

  Future<void> initPrice() async {
    await billingHelper?.getPrice(Platform.isAndroid ? 'android.test.purchased' : 'weekly');
  }

  void initListeners() {
    billingHelper?.setPurchaseUpdateHandler((status, value) async {
      switch (status) {
        case 'success':
          if (kDebugMode) {
            print('$status : $value');
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                duration: const Duration(seconds: 1),
                backgroundColor: Utils.getPrimaryColor(),
                content: Text(
                  'Purchase Sucessfully',
                  style: TextStyle(fontSize: 18.0, fontFamily: 'Sans', fontStyle: FontStyle.normal, fontWeight: FontWeight.w500, color: Utils.getWhiteColor()),
                )));
          }
          break;
        case 'cancelled':
          if (kDebugMode) {
            print('$status : $value');
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                duration: const Duration(seconds: 1),
                backgroundColor: Utils.getPrimaryColor(),
                content: Text(
                  'Purchase cancelled by you',
                  style: TextStyle(fontSize: 18.0, fontFamily: 'Sans', fontStyle: FontStyle.normal, fontWeight: FontWeight.w500, color: Utils.getWhiteColor()),
                )));
          }
          break;
        case 'error':
          if (kDebugMode) {
            print('$status : $value');
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                duration: const Duration(seconds: 1),
                backgroundColor: Utils.getPrimaryColor(),
                content: Text(
                  'Something went wrong, Please try again after sometime',
                  style: TextStyle(fontSize: 18.0, fontFamily: 'Sans', fontStyle: FontStyle.normal, fontWeight: FontWeight.w500, color: Utils.getWhiteColor()),
                )));
          }
          break;
        case 'restore':
          if (kDebugMode) {
            print('$status : $value');
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                duration: const Duration(seconds: 1),
                backgroundColor: Utils.getPrimaryColor(),
                content: Text(
                  value ? 'Restore Successfully' : 'You don\'t have purchase to restore',
                  style: TextStyle(fontSize: 18.0, fontFamily: 'Sans', fontStyle: FontStyle.normal, fontWeight: FontWeight.w500, color: Utils.getWhiteColor()),
                )));
          }
          break;
        default:
          if (kDebugMode) {
            print('$status : $value');
          }
      }
    });

    billingHelper!.setPriceUpdateHandler((price) {
      if (kDebugMode) {
        print("Price: $price");
        setState(() {
          this.price = price;
        });
      }
    });
  }
```

Purchase product by passing product id as String and get response as 'success', 'cancelled', 'error'.
```dart
billingHelper!.buyProduct(Platform.isAndroid ? 'android.test.purchased' : 'weekly');
```

Recover old purchaseed product using below line call and return callback to restore with bool value
```dart
billingHelper!.checkRestore();
```

## Support

For support, email techhuntdevelopers@gmail.com