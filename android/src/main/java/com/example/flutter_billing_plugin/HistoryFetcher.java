package com.example.flutter_billing_plugin;

import com.android.billingclient.api.PurchaseHistoryRecord;

import java.util.List;

public interface HistoryFetcher {
    void onGetHistory(int responseCode, List<PurchaseHistoryRecord> list) ;
}
