package com.tina4.pascal;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.Service;
import android.content.Context;
import android.content.Intent;
import android.content.pm.ServiceInfo;
import android.os.Build;
import android.os.IBinder;

/** E4: a microphone foreground service that keeps the app alive (and background-mic
 *  allowed) while the screen is off / the app is backgrounded during a &lt;recorder&gt;
 *  capture. Android 9+ throttles background mic access; a foregroundServiceType
 *  "microphone" service with an ongoing notification is the OS-blessed way to keep
 *  capturing. MediaRecorder itself stays in MainActivity — this just holds the
 *  foreground slot. Started on record-start, stopped on record-stop. */
public class Tina4CaptureService extends Service {
    private static final String CH = "tina4.capture";
    private static final int NOTIF_ID = 0x7CA9;

    @Override public int onStartCommand(Intent intent, int flags, int startId) {
        if (Build.VERSION.SDK_INT >= 26) {
            NotificationManager nm = (NotificationManager) getSystemService(Context.NOTIFICATION_SERVICE);
            NotificationChannel ch = new NotificationChannel(
                CH, "Recording", NotificationManager.IMPORTANCE_LOW);
            nm.createNotificationChannel(ch);
        }
        Notification.Builder b = (Build.VERSION.SDK_INT >= 26)
            ? new Notification.Builder(this, CH) : new Notification.Builder(this);
        Notification n = b.setContentTitle("Recording")
            .setContentText("Microphone capture is active")
            .setSmallIcon(getApplicationInfo().icon)
            .setOngoing(true)
            .build();
        if (Build.VERSION.SDK_INT >= 29)
            startForeground(NOTIF_ID, n, ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE);
        else
            startForeground(NOTIF_ID, n);
        return START_NOT_STICKY;   // don't resurrect after an explicit stop/kill
    }

    @Override public IBinder onBind(Intent intent) { return null; }

    /** Start/stop helpers for MainActivity's record lifecycle. */
    static void start(Context ctx) {
        Intent i = new Intent(ctx, Tina4CaptureService.class);
        if (Build.VERSION.SDK_INT >= 26) ctx.startForegroundService(i); else ctx.startService(i);
    }
    static void stop(Context ctx) {
        ctx.stopService(new Intent(ctx, Tina4CaptureService.class));
    }
}
