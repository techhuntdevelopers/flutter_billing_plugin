package com.example.flutter_billing_plugin;

import android.app.Activity;
import android.content.SharedPreferences;
import android.preference.PreferenceManager;
import android.text.TextUtils;
import android.util.Base64;
import android.util.Log;
import android.widget.Toast;

import androidx.lifecycle.MutableLiveData;

import com.android.billingclient.api.AcknowledgePurchaseParams;
import com.android.billingclient.api.AcknowledgePurchaseResponseListener;
import com.android.billingclient.api.BillingClient;
import com.android.billingclient.api.BillingClient.SkuType;
import com.android.billingclient.api.BillingClientStateListener;
import com.android.billingclient.api.BillingFlowParams;
import com.android.billingclient.api.BillingResult;
import com.android.billingclient.api.Purchase;
import com.android.billingclient.api.PurchaseHistoryRecord;
import com.android.billingclient.api.PurchaseHistoryResponseListener;
import com.android.billingclient.api.PurchasesUpdatedListener;
import com.android.billingclient.api.SkuDetails;
import com.android.billingclient.api.SkuDetailsParams;
import com.android.billingclient.api.SkuDetailsResponseListener;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class BillingManager {
    private static final int STATUS_UNSUBSCRIBED = 0;
    private static final int STATUS_SUBSCRIBED = 1;
    private static final int STATUS_SUBSCRIPTION_RECOVERED = 2;
    private static final int STATUS_ACCOUNT_HOLD = 7;
    private static final String TAG = "InAppManager";
    private final static String[] HEX_CHARACTER_TABLE = {"0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F"};
    private final static int HEX_VALUE_TABLE[] = new int[256];

    static {
        Arrays.fill(HEX_VALUE_TABLE, (byte) 0);
        int length = HEX_CHARACTER_TABLE.length;
        for (int i = 0; i < length; i++) {
            String c = HEX_CHARACTER_TABLE[i];
            HEX_VALUE_TABLE[c.charAt(0)] = (byte) i;
            HEX_VALUE_TABLE[c.toLowerCase().charAt(0)] = (byte) i;
        }
    }

    private final Activity mActivity;
    public MutableLiveData<Map<String, SkuDetails>> skusWithSkuDetails = new MutableLiveData<>();
    OnPriceAvailable onPriceAvailable = null;
    private List<String> mProductIds;
    private BillingClient mBillingClient;

    public BillingManager(Activity activity, List<String> productIds, PurchasesUpdatedListener purchasesUpdatedListener) {
        mActivity = activity;
        mProductIds = productIds;
        mBillingClient = BillingClient.newBuilder(mActivity).enablePendingPurchases().setListener(purchasesUpdatedListener).build();
        startServiceConnectionIfNeeded(null);
    }

    public static byte[] hexString2bytes(String hexString) {
        int length = hexString == null ? 0 : hexString.length();
        if (length == 0) {
            return new byte[0];
        }
        if (length % 2 != 0) {
            hexString += "0";
            length += 1;
        }

        byte[] out = new byte[length / 2];
        for (int n = 0; n < length; n += 2) {
            char h = hexString.charAt(n);
            char l = hexString.charAt(n + 1);
            out[n >> 1] = (byte) (HEX_VALUE_TABLE[h] << 4 | HEX_VALUE_TABLE[l]);
        }
        return out;
    }

    private String generateObfuscatedAccountId() {
        String AAID_ = App.AAID;
        if (!TextUtils.isEmpty(AAID_)) {
            String aaid = AAID_.replace("-", "");
            //Then StringUtil.hexString2bytes() method converts a hexadecimal string into a byte array.
            return "A:" + Base64.encodeToString(hexString2bytes(aaid), Base64.NO_PADDING | Base64.NO_WRAP);
        } else {
            return null;
        }
    }

    private String generateObfuscatedProfileId() {
        SharedPreferences preference = PreferenceManager.getDefaultSharedPreferences(mActivity);
        String channel = preference.getString("adChannel", "NULL");
        return "C:" + Base64.encodeToString(channel.getBytes(), Base64.NO_PADDING | Base64.NO_WRAP);
    }

    /**
     * Trying to restart service connection if it's needed or just execute a request.
     * <p>Note: It's just a primitive example - it's up to you to implement a real retry-policy.</p>
     *
     * @param executeOnSuccess This runnable will be executed once the connection to the Billing
     *                         service is restored.
     */
    private void startServiceConnectionIfNeeded(final Runnable executeOnSuccess) {
        if (mBillingClient.isReady()) {
            if (executeOnSuccess != null) {
                executeOnSuccess.run();
            }
        } else {
            mBillingClient.startConnection(new BillingClientStateListener() {

                @Override
                public void onBillingSetupFinished(BillingResult billingResult) {
                    if (billingResult.getResponseCode() == BillingClient.BillingResponseCode.OK) {
                        Log.i(TAG, "onBillingSetupFinished() response: " + billingResult.getResponseCode());
                        if (executeOnSuccess != null) {
                            executeOnSuccess.run();
                        }
                        querySkuDetails();
                    } else {
                        Log.w(TAG, "onBillingSetupFinished() error code: " + billingResult.getResponseCode());
                    }
                }

                @Override
                public void onBillingServiceDisconnected() {
                    Log.w(TAG, "onBillingServiceDisconnected()");
                }
            });
        }
    }

    public void querySkuDetails() {
        List<String> skus = new ArrayList<>();
        if (mProductIds != null)
            skus.addAll(mProductIds);
        querySkuDetailsAsync(SkuType.SUBS, skus);
    }

    public void querySkuDetailsAsync(@SkuType final String itemType,
                                     final List<String> skuList) {
        // Specify a runnable to start when connection to Billing client is established
        Runnable executeOnConnectedService = new Runnable() {
            @Override
            public void run() {
                SkuDetailsParams skuDetailsParams = SkuDetailsParams.newBuilder()
                        .setSkusList(skuList).setType(itemType).build();
                mBillingClient.querySkuDetailsAsync(skuDetailsParams,
                        new SkuDetailsResponseListener() {
                            @Override
                            public void onSkuDetailsResponse(BillingResult billingResult, List<SkuDetails> skuDetailsList) {
                                switch (billingResult.getResponseCode()) {
                                    case BillingClient.BillingResponseCode.OK:
                                        Log.i(TAG, "onSkuDetailsResponse: " + billingResult.getResponseCode() + " " + billingResult.getDebugMessage());
                                        if (skuDetailsList == null) {
                                            Log.w(TAG, "onSkuDetailsResponse: null SkuDetails list");
                                            skusWithSkuDetails.postValue(Collections.<String, SkuDetails>emptyMap());
                                        } else {
                                            Map<String, SkuDetails> newSkusDetailList = new HashMap<String, SkuDetails>();
                                            for (SkuDetails skuDetails : skuDetailsList) {
                                                newSkusDetailList.put(skuDetails.getSku(), skuDetails);
                                            }
                                            skusWithSkuDetails.postValue(newSkusDetailList);
                                            if (onPriceAvailable != null) {
                                                onPriceAvailable.priceAvailable();
                                            }

                                            Log.i(TAG, "onSkuDetailsResponse: count " + newSkusDetailList.size());
                                        }
                                        break;
                                    case BillingClient.BillingResponseCode.SERVICE_DISCONNECTED:
                                    case BillingClient.BillingResponseCode.SERVICE_UNAVAILABLE:
                                    case BillingClient.BillingResponseCode.BILLING_UNAVAILABLE:
                                    case BillingClient.BillingResponseCode.ITEM_UNAVAILABLE:
                                    case BillingClient.BillingResponseCode.DEVELOPER_ERROR:
                                    case BillingClient.BillingResponseCode.ERROR:
                                        Log.i(TAG, "onSkuDetailsResponse: " + billingResult.getResponseCode() + " " + billingResult.getDebugMessage());
                                        break;
                                    case BillingClient.BillingResponseCode.USER_CANCELED:
                                        Log.i(TAG, "onSkuDetailsResponse: " + billingResult.getResponseCode() + " " + billingResult.getDebugMessage());
                                        break;
                                    // These response codes are not expected.
                                    case BillingClient.BillingResponseCode.FEATURE_NOT_SUPPORTED:
                                    case BillingClient.BillingResponseCode.ITEM_ALREADY_OWNED:
                                    case BillingClient.BillingResponseCode.ITEM_NOT_OWNED:
                                    default:
                                        Log.i(TAG, "onSkuDetailsResponse: " + billingResult.getResponseCode() + " " + billingResult.getDebugMessage());
                                }
                            }
                        });
            }
        };

        // If Billing client was disconnected, we retry 1 time and if success, execute the query
        startServiceConnectionIfNeeded(executeOnConnectedService);
    }

    public void startPurchaseFlow(String skuId) {
        // Specify a runnable to start when connection to Billing client is established
        final String finalSkuId = skuId;
        Runnable executeOnConnectedService = new Runnable() {
            @Override
            public void run() {
                SkuDetails skuDetails = null;
                // Create the parameters for the purchase.
                if (skusWithSkuDetails.getValue() != null) {
                    skuDetails = skusWithSkuDetails.getValue().get(finalSkuId);
                }

                if (skuDetails == null) {
                    Log.e("Billing", "Could not find SkuDetails to make purchase.");
                    querySkuDetails();
                    Toast.makeText(mActivity, "Something went wrong with Billing, Please Try Again.", Toast.LENGTH_SHORT).show();
                    return;
                }

                BillingFlowParams billingFlowParams = BillingFlowParams.newBuilder()
                        .setSkuDetails(skusWithSkuDetails.getValue().get(finalSkuId))
                        .setObfuscatedAccountId(generateObfuscatedAccountId())
                        .setObfuscatedProfileId(generateObfuscatedAccountId() == null ? null : generateObfuscatedProfileId())
                        .build();
                mBillingClient.launchBillingFlow(mActivity, billingFlowParams);
            }
        };

        startServiceConnectionIfNeeded(executeOnConnectedService);
    }

    public void destroy() {
        if (mBillingClient != null && mBillingClient.isReady()) {
            mBillingClient.endConnection();
            mBillingClient = null;
        }

    }

    public void acknowledgement(BillingResult billingResult, List<Purchase> list) {
        handleSubscribed();
        AcknowledgePurchaseParams acknowledgePurchaseParams =
                AcknowledgePurchaseParams.newBuilder()
                        .setPurchaseToken(list.get(0).getPurchaseToken())
                        .build();
        mBillingClient.acknowledgePurchase(acknowledgePurchaseParams, new AcknowledgePurchaseResponseListener() {
            @Override
            public void onAcknowledgePurchaseResponse(BillingResult billingResult) {

            }
        });
    }

    public void acknowledgement(PurchaseHistoryRecord list) {
        AcknowledgePurchaseParams acknowledgePurchaseParams =
                AcknowledgePurchaseParams.newBuilder()
                        .setPurchaseToken(list.getPurchaseToken())
                        .build();
        mBillingClient.acknowledgePurchase(acknowledgePurchaseParams, new AcknowledgePurchaseResponseListener() {
            @Override
            public void onAcknowledgePurchaseResponse(BillingResult billingResult) {

            }
        });
    }

    public void setOnHistoryFetcher(HistoryFetcher inAppHistoryFetcher) {
        getHistory(inAppHistoryFetcher);
    }

    public void getHistory(final HistoryFetcher inAppHistoryFetcher) {
        mBillingClient.queryPurchaseHistoryAsync(SkuType.SUBS, new PurchaseHistoryResponseListener() {
            @Override
            public void onPurchaseHistoryResponse(BillingResult billingResult, List<PurchaseHistoryRecord> list) {
                inAppHistoryFetcher.onGetHistory(billingResult.getResponseCode(), list);
            }

        });
    }

    public void setPrice(String sku,PriceCallback callback) {
        final SkuDetails[] skuDetails = {null};
        // Create the parameters for the purchase.
        if (skusWithSkuDetails.getValue() != null) {
            skuDetails[0] = skusWithSkuDetails.getValue().get(sku);
        }
        if (skuDetails[0] == null) {
            final String finalSku = sku;
            onPriceAvailable = new OnPriceAvailable() {
                @Override
                public void priceAvailable() {
                    if (skusWithSkuDetails.getValue() != null) {
                        skuDetails[0] = skusWithSkuDetails.getValue().get(finalSku);
                    }
                    if (skuDetails[0] == null) {
                        querySkuDetails();
                        return;
                    }

                    callback.OnPrice(skuDetails[0].getPrice());
                    onPriceAvailable = null;
                }
            };
            querySkuDetails();
        } else {
            callback.OnPrice(skuDetails[0].getPrice());
        }
    }
    
    

    public void checkRestore(RestoreCallback callback) {
        setOnHistoryFetcher(new HistoryFetcher() {
            @Override
            public void onGetHistory(int responseCode, List<PurchaseHistoryRecord> purchases) {
                if (purchases != null && purchases.size() > 0) {
                    handleSubscribed();
                    for (PurchaseHistoryRecord purchaseHistoryRecord : purchases) {
                        acknowledgement(purchaseHistoryRecord);
                    }
                } else {
                    handleUnsubscribed();
                    if (callback != null)
                        callback.OnSuccess(false);
                }
                if (isAccountHold()) {
                    if (callback != null)
                        callback.OnSuccess(false);
                } else if (isRecovered()) {
                    if (callback != null)
                        callback.OnSuccess(true);
                }
            }
        });
    }

    private int getLocalSubscriptionStatus() {
        SharedPreferences preference = PreferenceManager.getDefaultSharedPreferences(this.mActivity);
        return preference.getInt("subscription-status", 0);
    }

    private void setLocalSubscriptionStatus(int status) {
        SharedPreferences preference = PreferenceManager.getDefaultSharedPreferences(this.mActivity);
        preference.edit().putInt("subscription-status", status).apply();
    }

    public void handleSubscribed() {
        //If the local status is "Account Hold" and the current status is "Subscribed", the payment problem is fixed
        if (getLocalSubscriptionStatus() == STATUS_ACCOUNT_HOLD) {
            setLocalSubscriptionStatus(STATUS_SUBSCRIPTION_RECOVERED);
        } else {
            setLocalSubscriptionStatus(STATUS_SUBSCRIBED);
        }
    }

    public void handleUnsubscribed() {
        int status = getLocalSubscriptionStatus();
        if (status == STATUS_SUBSCRIBED || status == STATUS_SUBSCRIPTION_RECOVERED) {
            setLocalSubscriptionStatus(STATUS_ACCOUNT_HOLD);
        }
    }

    public boolean isAccountHold() {
        return getLocalSubscriptionStatus() == STATUS_ACCOUNT_HOLD;
    }

    public boolean isRecovered() {
        return getLocalSubscriptionStatus() == STATUS_SUBSCRIPTION_RECOVERED;
    }

    public interface RestoreCallback {
        void OnSuccess(boolean b);
    }

    public interface PriceCallback {
        void OnPrice(String value);
    }

    interface OnPriceAvailable {
        void priceAvailable();

    }
}