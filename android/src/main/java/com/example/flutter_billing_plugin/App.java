package com.example.flutter_billing_plugin;

import android.app.Application;
import android.os.AsyncTask;
import android.util.Log;

import com.google.android.gms.ads.identifier.AdvertisingIdClient;
import com.google.android.gms.common.GooglePlayServicesNotAvailableException;
import com.google.android.gms.common.GooglePlayServicesRepairableException;

import java.io.IOException;

public class App extends Application {
    public static String AAID = "";
    private static final String TAG = "App";

    @Override
    public void onCreate() {
        super.onCreate();
        AsyncTask.execute(new Runnable() {
            @Override
            public void run() {
                try {
                    AdvertisingIdClient.Info adInfo = AdvertisingIdClient.getAdvertisingIdInfo(App.this);
                    String adId = adInfo != null ? adInfo.getId() : null;
                    AAID = adId;
                    Log.e(TAG, "run: " + adId);
                    // Use the advertising id
                } catch (IOException | GooglePlayServicesRepairableException | GooglePlayServicesNotAvailableException exception) {
                    // Error handling if needed
                }
            }
        });
    }
}

