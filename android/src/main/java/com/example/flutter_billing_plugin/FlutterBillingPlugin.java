package com.example.flutter_billing_plugin;

import android.app.Activity;
import android.os.Handler;
import android.os.Looper;
import android.widget.Toast;

import androidx.annotation.NonNull;

import com.android.billingclient.api.BillingClient;

import java.util.List;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

/**
 * FlutterBillingPlugin
 */
public class FlutterBillingPlugin implements FlutterPlugin, MethodCallHandler, ActivityAware {
    private MethodChannel channel;
    private Activity activity;
    private BillingManager billingManager;

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
        channel = new MethodChannel(binding.getBinaryMessenger(), "flutter_billing");
        channel.setMethodCallHandler(this);
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
        if (call.method.equals("init")) {
            List<String> productIds = call.argument("product_ids");
            billingManager = new BillingManager(activity, productIds, (billingResult, list) -> {
                if (billingResult.getResponseCode() == BillingClient.BillingResponseCode.OK) {
                    channel.invokeMethod("success", "success");
                    billingManager.acknowledgement(billingResult, list);
                } else if (billingResult.getResponseCode() == BillingClient.BillingResponseCode.USER_CANCELED) {
                    channel.invokeMethod("cancelled", "cancelled");
                } else {
                    channel.invokeMethod("error", "error");
                }
            });
        } else if (call.method.equals("get_price")) {
            String productId = call.argument("product_id");
            billingManager.setPrice(productId, value -> new Handler(Looper.getMainLooper()).postDelayed(() -> channel.invokeMethod("price", value),100));
        } else if (call.method.equals("buy_product")) {
            String productId = call.argument("product_id");
            billingManager.startPurchaseFlow(productId);
        } else if (call.method.equals("check_restore")) {
            billingManager.checkRestore(b -> new Handler(Looper.getMainLooper()).postDelayed(() -> channel.invokeMethod("restore", b),100));
        } else {
            result.notImplemented();
        }
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
    }

    @Override
    public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
        this.activity = binding.getActivity();
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {

    }

    @Override
    public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {

    }

    @Override
    public void onDetachedFromActivity() {

    }
}
