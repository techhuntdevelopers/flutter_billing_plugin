import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_billing_plugin/flutter_billing_plugin.dart';
import 'package:flutter_billing_plugin_example/utils.dart';

void main() {
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    systemNavigationBarColor: Utils.getBGColor(),
    systemNavigationBarIconBrightness: Brightness.dark,
    systemNavigationBarDividerColor: Utils.getBGColor(),
    statusBarColor: Utils.getBGColor(),
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.dark,
  ));

  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: PaymentScreen(),
    ),
  );
}

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _PaymentScreenState();
  }
}

class _PaymentScreenState extends State<PaymentScreen> {
  var price = "\$0.05";

  List<String> productIds = [Platform.isAndroid ? 'android.test.purchased' : 'weekly'];
  FlutterBillingPlugin? billingHelper;

  @override
  void initState() {
    super.initState();
    initBilling();
    initListeners();
    initPrice();
  }

  Future<void> initBilling() async {
    billingHelper = FlutterBillingPlugin();
    //pass secret key for iOS development auto renewal
    await billingHelper?.init(productIds, "a59d0387edeb46e594fc00be5463ab7f", false);
  }

  Future<void> initPrice() async {
    await billingHelper?.getPrice(Platform.isAndroid ? 'android.test.purchased' : 'weekly');
  }

  void initListeners() {
    billingHelper?.setPurchaseUpdateHandler((status, value) async {
      switch (status) {
        case 'isProductPurchased':
          if (kDebugMode) {
            print('$status : $value');
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                duration: const Duration(seconds: 1),
                backgroundColor: Utils.getPrimaryColor(),
                content: Text(
                  'isProductPurchased: $value',
                  style: TextStyle(fontSize: 18.0, fontFamily: 'Sans', fontStyle: FontStyle.normal, fontWeight: FontWeight.w500, color: Utils.getWhiteColor()),
                )));
          }
          break;
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

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Utils.getAccentColor(),
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(image: AssetImage('assets/ic_subscription_screen_bg.png'), fit: BoxFit.fill),
          ),
          child: SafeArea(
            child: Stack(children: [
              Align(
                alignment: Alignment.topCenter,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          IconButton(
                            icon: Image.asset(
                              'assets/ic_subscription_screen_close.png',
                              height: 22.0,
                              width: 22.0,
                              color: Utils.getWhiteTextColor().withOpacity(0.8),
                            ),
                            onPressed: () {},
                          ),
                          const Spacer(),
                          InkWell(
                            borderRadius: const BorderRadius.all(Radius.circular(2.0)),
                            onTap: () {
                              billingHelper!.checkRestore();
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "RESTORE",
                                  style: TextStyle(fontSize: 16.0, fontFamily: 'Sans', fontStyle: FontStyle.normal, fontWeight: FontWeight.w500, color: Utils.getWhiteTextColor().withOpacity(0.9)),
                                ),
                                const SizedBox(
                                  width: 4.0,
                                ),
                                Image.asset(
                                  'assets/ic_subscription_screen_restore.png',
                                  height: 16.0,
                                  width: 16.0,
                                  color: Utils.getWhiteTextColor().withOpacity(0.9),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 36.0),
                      child: Text(
                        "Become\nPro User",
                        style: TextStyle(fontSize: 43.0, fontFamily: 'Sans', fontStyle: FontStyle.normal, fontWeight: FontWeight.w700, color: Utils.getWhiteTextColor()),
                      ),
                    ),
                    const SizedBox(
                      height: 12.0,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 36.0),
                      child: Text(
                        "Unlock all functions".toUpperCase(),
                        style: TextStyle(fontSize: 16.0, fontFamily: 'Sans', fontStyle: FontStyle.normal, fontWeight: FontWeight.w700, letterSpacing: 4, color: Utils.getWhiteTextColor()),
                      ),
                    ),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Wrap(
                  children: [
                    Column(children: [
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '\u2022',
                                  style: TextStyle(fontSize: 36, fontFamily: 'Sans', fontStyle: FontStyle.normal, fontWeight: FontWeight.w700, color: Utils.getYellowColor()),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  "+200 Questions",
                                  style: TextStyle(fontSize: 18.0, fontFamily: 'Sans', fontStyle: FontStyle.normal, fontWeight: FontWeight.w500, color: Utils.getWhiteTextColor()),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Text(
                                  '\u2022',
                                  style: TextStyle(fontSize: 36, fontFamily: 'Sans', fontStyle: FontStyle.normal, fontWeight: FontWeight.w700, color: Utils.getYellowColor()),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  "All Mock Tests",
                                  style: TextStyle(fontSize: 18.0, fontFamily: 'Sans', fontStyle: FontStyle.normal, fontWeight: FontWeight.w500, color: Utils.getWhiteTextColor()),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Text(
                                  '\u2022',
                                  style: TextStyle(fontSize: 36, fontFamily: 'Sans', fontStyle: FontStyle.normal, fontWeight: FontWeight.w700, color: Utils.getYellowColor()),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  "All Statistics",
                                  style: TextStyle(fontSize: 18.0, fontFamily: 'Sans', fontStyle: FontStyle.normal, fontWeight: FontWeight.w500, color: Utils.getWhiteTextColor()),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Text(
                                  '\u2022',
                                  style: TextStyle(fontSize: 36, fontFamily: 'Sans', fontStyle: FontStyle.normal, fontWeight: FontWeight.w700, color: Utils.getYellowColor()),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  "Check progress",
                                  style: TextStyle(fontSize: 18.0, fontFamily: 'Sans', fontStyle: FontStyle.normal, fontWeight: FontWeight.w500, color: Utils.getWhiteTextColor()),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 12.0,
                      ),
                      Text(
                        "3 days free trial, then ${price}/week.\ncancel at any time",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14.0, fontFamily: 'Sans', fontStyle: FontStyle.normal, fontWeight: FontWeight.w300, color: Utils.getWhiteTextColor().withOpacity(.5)),
                      ),
                      const SizedBox(
                        height: 12.0,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 36.0),
                        child: MaterialButton(
                          elevation: 0.0,
                          minWidth: double.infinity,
                          color: Utils.getYellowColor(),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
                          onPressed: () {
                            billingHelper!.buyProduct(Platform.isAndroid ? 'android.test.purchased' : 'weekly');
                          },
                          child: Text(
                            "Unlock now".toUpperCase(),
                            style: TextStyle(fontSize: 16.0, fontFamily: 'Sans', fontStyle: FontStyle.normal, fontWeight: FontWeight.w700, color: Utils.getButtonTextColor()),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 8.0,
                      ),
                      SizedBox(
                        height: 44.0,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 36.0),
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            scrollDirection: Axis.vertical,
                            child: Text(
                              "After you start the subscription, you will be able to use all the advanced features. Premium subscriptions are charged weekly/monthly/yearly at the rate corresponding to the selected plan. When confirming the purchase, the fee will be charged through the payment method you selected. The account will be charged for renewal within 24 hours before the end of the current period. You can cancel your subscription within 24 hours before the end of the current period, otherwise the subscription will automatically renew.",
                              textAlign: TextAlign.center,
                              // maxLines: 3,
                              style: TextStyle(fontSize: 12.0, fontFamily: 'Sans', fontStyle: FontStyle.normal, fontWeight: FontWeight.w300, color: Utils.getWhiteTextColor().withOpacity(.5)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12.0),
                    ])
                  ],
                ),
              )
            ]),
          ),
        ),
      ),
    );
  }
}
