package com.tina4.pascal;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.Service;
import android.content.Context;
import android.content.Intent;
import android.os.Build;
import android.os.IBinder;

/** Android foreground service which keeps LocationManager updates active while
 * the Tina4 activity is backgrounded. It is deliberately small: the shared
 * location listener remains in Tina4Location and results use the same callback. */
public final class Tina4LocationService extends Service {
    private static final String CHANNEL = "tina4.location";
    private static final int NOTIFICATION_ID = 4763;

    @Override public int onStartCommand(Intent intent, int flags, int startId) {
        createChannel();
        startForeground(NOTIFICATION_ID, notification());
        Tina4Location.initForService(this);
        Tina4Location.startFromService();
        return START_STICKY;
    }

    private void createChannel() {
        if (Build.VERSION.SDK_INT >= 26) {
            NotificationManager nm = (NotificationManager)
                getSystemService(Context.NOTIFICATION_SERVICE);
            nm.createNotificationChannel(new NotificationChannel(
                CHANNEL, "Tina4 location", NotificationManager.IMPORTANCE_LOW));
        }
    }

    private Notification notification() {
        Notification.Builder b = Build.VERSION.SDK_INT >= 26
            ? new Notification.Builder(this, CHANNEL)
            : new Notification.Builder(this);
        return b.setSmallIcon(getApplicationInfo().icon)
            .setContentTitle("Tina4 location")
            .setContentText("Location updates are active")
            .setOngoing(true)
            .build();
    }

    @Override public void onDestroy() {
        Tina4Location.stopFromService();
        super.onDestroy();
    }

    @Override public IBinder onBind(Intent intent) { return null; }
}
