package com.tina4.pascal;

import android.Manifest;
import android.app.Activity;
import android.content.Context;
import android.content.pm.PackageManager;
import android.content.Intent;
import android.location.Location;
import android.location.LocationListener;
import android.location.LocationManager;
import android.os.Bundle;
import android.os.Looper;

/** Platform Android location adapter. Uses framework LocationManager only; no
 * Google Play Services dependency is required. */
public final class Tina4Location {
    public static final int REQUEST_CODE = 4761;
    private static Activity activity;
    private static LocationManager manager;
    private static LocationListener listener;
    private static Tina4View view;
    private static boolean requesting;
    private static boolean backgroundPending;

    private Tina4Location() {}

    static native void nativeLocationResult(int status, double latitude,
        double longitude, double accuracy, double altitude, double speed,
        double timestamp, String error);

    private static void deliver(int status, double latitude, double longitude,
        double accuracy, double altitude, double speed, double timestamp,
        String error) {
        nativeLocationResult(status, latitude, longitude, accuracy, altitude,
            speed, timestamp, error);
        if (view != null) view.invalidate();
    }

    public static void init(Activity a) {
        activity = a;
        manager = (LocationManager) a.getSystemService(Context.LOCATION_SERVICE);
        ensureListener();
    }

    static void initForService(Context c) {
        manager = (LocationManager) c.getSystemService(Context.LOCATION_SERVICE);
        ensureListener();
    }

    private static void ensureListener() {
        if (listener != null) return;
        listener = new LocationListener() {
            @Override public void onLocationChanged(Location l) {
                deliver(0, l.getLatitude(), l.getLongitude(),
                    l.hasAccuracy() ? l.getAccuracy() : 0,
                    l.hasAltitude() ? l.getAltitude() : 0,
                    l.hasSpeed() ? l.getSpeed() : 0,
                    l.getTime() / 1000.0, null);
            }
            @Override public void onProviderDisabled(String provider) {
                if (requesting && !hasProvider())
                    deliver(5, 0, 0, 0, 0, 0, 0,
                        "no location provider is enabled");
            }
            @Override public void onProviderEnabled(String provider) {}
            @Override public void onStatusChanged(String p, int s, Bundle e) {}
        };
    }

    static void setView(Tina4View v) { view = v; }

    private static boolean granted() {
        return activity != null &&
            (activity.checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION)
                == PackageManager.PERMISSION_GRANTED ||
             activity.checkSelfPermission(Manifest.permission.ACCESS_COARSE_LOCATION)
                == PackageManager.PERMISSION_GRANTED);
    }

    private static boolean hasProvider() {
        return manager != null &&
            (manager.isProviderEnabled(LocationManager.GPS_PROVIDER) ||
             manager.isProviderEnabled(LocationManager.NETWORK_PROVIDER));
    }

    private static void ask() {
        if (activity == null) return;
        activity.requestPermissions(new String[] {
            Manifest.permission.ACCESS_FINE_LOCATION,
            Manifest.permission.ACCESS_COARSE_LOCATION
        }, REQUEST_CODE);
    }

    public static void request() { if (!granted()) ask(); }

    public static void permissionResult(boolean allowed) {
        if (!allowed) {
            deliver(4, 0, 0, 0, 0, 0, 0,
                "location permission denied");
        } else if (backgroundPending) {
            backgroundPending = false;
            startBackgroundService();
        } else if (requesting) {
            startUpdates();
        }
    }

    public static void start() {
        requesting = true;
        if (!granted()) { ask(); return; }
        startUpdates();
    }

    public static void startBackground() {
        requesting = true;
        if (!granted()) { backgroundPending = true; ask(); return; }
        startBackgroundService();
    }

    private static void startBackgroundService() {
        if (activity == null) return;
        Intent intent = new Intent(activity, Tina4LocationService.class);
        if (android.os.Build.VERSION.SDK_INT >= 26)
            activity.startForegroundService(intent);
        else
            activity.startService(intent);
    }

    static void startFromService() { startUpdates(); }

    static void stopFromService() {
        if (manager != null && listener != null) manager.removeUpdates(listener);
    }

    private static void startUpdates() {
        if (manager == null || listener == null) return;
        if (!hasProvider()) {
            deliver(5, 0, 0, 0, 0, 0, 0,
                "no location provider is enabled");
            return;
        }
        try {
            Looper looper = Looper.getMainLooper();
            if (manager.isProviderEnabled(LocationManager.GPS_PROVIDER))
                manager.requestLocationUpdates(LocationManager.GPS_PROVIDER,
                    0, 0, listener, looper);
            if (manager.isProviderEnabled(LocationManager.NETWORK_PROVIDER))
                manager.requestLocationUpdates(LocationManager.NETWORK_PROVIDER,
                    0, 0, listener, looper);
        } catch (SecurityException e) {
            deliver(4, 0, 0, 0, 0, 0, 0,
                "location permission denied");
        } catch (IllegalArgumentException e) {
            deliver(5, 0, 0, 0, 0, 0, 0,
                e.getMessage() != null ? e.getMessage() : "location unavailable");
        }
    }

    public static void stop() {
        requesting = false;
        backgroundPending = false;
        if (manager != null && listener != null) manager.removeUpdates(listener);
        if (activity != null)
            activity.stopService(new Intent(activity, Tina4LocationService.class));
    }
}
