package com.tina4.pascal;

import android.Manifest;
import android.app.Activity;
import android.content.Context;
import android.content.pm.PackageManager;
import android.graphics.SurfaceTexture;
import android.hardware.camera2.CameraAccessException;
import android.hardware.camera2.CameraCaptureSession;
import android.hardware.camera2.CameraCharacteristics;
import android.hardware.camera2.CameraDevice;
import android.hardware.camera2.CameraManager;
import android.hardware.camera2.CameraMetadata;
import android.hardware.camera2.CaptureRequest;
import android.os.Build;
import android.os.Handler;
import android.os.HandlerThread;
import android.view.Surface;
import android.view.TextureView;

import java.util.ArrayList;
import java.util.List;

/** Live camera preview for &lt;camera-view&gt; (embed kind 4): a Camera2 preview in
 *  a TextureView with NO decoder — the un-decoded sibling of {@link Tina4Scanner},
 *  for a monitor/feed. The view is positioned by Tina4View over the engine's
 *  camera-view box; `facing` selects the front or back lens. Pure platform, no
 *  Gradle. (GrabCameraFrame — an ImageReader JPEG — is a follow-up.) */
public class Tina4Camera implements TextureView.SurfaceTextureListener {
    private final Context ctx;
    public final TextureView view;
    private final boolean front;

    private CameraDevice camera;
    private CameraCaptureSession session;
    private CaptureRequest.Builder req;
    private HandlerThread bg;
    private Handler bgHandler;
    private boolean opening = false;

    private static final int PREV_W = 1280, PREV_H = 720;

    Tina4Camera(Context ctx, String facing) {
        this.ctx = ctx;
        this.front = facing != null && facing.toLowerCase().contains("front");
        this.view = new TextureView(ctx);
        this.view.setSurfaceTextureListener(this);
    }

    /** Camera permission — granted, or ask the host Activity once (returns false). */
    static boolean ensurePermission(Context ctx) {
        if (Build.VERSION.SDK_INT < 23) return true;
        if (ctx.checkSelfPermission(Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED)
            return true;
        if (ctx instanceof Activity)
            ((Activity) ctx).requestPermissions(new String[]{ Manifest.permission.CAMERA }, 4711);
        return false;
    }

    void retryOpen() { open(); }

    @Override public void onSurfaceTextureAvailable(SurfaceTexture st, int w, int h) { open(); }
    @Override public void onSurfaceTextureSizeChanged(SurfaceTexture st, int w, int h) {}
    @Override public boolean onSurfaceTextureDestroyed(SurfaceTexture st) { close(); return true; }
    @Override public void onSurfaceTextureUpdated(SurfaceTexture st) {}

    private void open() {
        if (opening || camera != null) return;
        if (!ensurePermission(ctx)) return;   // retries when the view re-lays out after grant
        if (view.getSurfaceTexture() == null) return;
        opening = true;
        bg = new HandlerThread("tina4-camview"); bg.start(); bgHandler = new Handler(bg.getLooper());
        CameraManager cm = (CameraManager) ctx.getSystemService(Context.CAMERA_SERVICE);
        try {
            String id = pickCamera(cm);
            if (id == null) { opening = false; return; }
            cm.openCamera(id, stateCb, bgHandler);
        } catch (Exception e) { opening = false; }
    }

    /** The first camera matching the requested lens facing, else the first camera. */
    private String pickCamera(CameraManager cm) throws CameraAccessException {
        int want = front ? CameraCharacteristics.LENS_FACING_FRONT
                         : CameraCharacteristics.LENS_FACING_BACK;
        String[] ids = cm.getCameraIdList();
        for (String id : ids) {
            Integer f = cm.getCameraCharacteristics(id).get(CameraCharacteristics.LENS_FACING);
            if (f != null && f == want) return id;
        }
        return ids.length > 0 ? ids[0] : null;
    }

    private final CameraDevice.StateCallback stateCb = new CameraDevice.StateCallback() {
        @Override public void onOpened(CameraDevice cam) {
            camera = cam; opening = false;
            try {
                SurfaceTexture st = view.getSurfaceTexture();
                if (st == null) return;
                st.setDefaultBufferSize(PREV_W, PREV_H);
                Surface preview = new Surface(st);
                req = cam.createCaptureRequest(CameraDevice.TEMPLATE_PREVIEW);
                req.addTarget(preview);
                List<Surface> outs = new ArrayList<>();
                outs.add(preview);
                cam.createCaptureSession(outs, sessionCb, bgHandler);
            } catch (Exception e) { /* ignore */ }
        }
        @Override public void onDisconnected(CameraDevice cam) { cam.close(); camera = null; opening = false; }
        @Override public void onError(CameraDevice cam, int err) { cam.close(); camera = null; opening = false; }
    };

    private final CameraCaptureSession.StateCallback sessionCb = new CameraCaptureSession.StateCallback() {
        @Override public void onConfigured(CameraCaptureSession s) {
            session = s;
            try {
                req.set(CaptureRequest.CONTROL_MODE, CameraMetadata.CONTROL_MODE_AUTO);
                req.set(CaptureRequest.CONTROL_AF_MODE, CaptureRequest.CONTROL_AF_MODE_CONTINUOUS_PICTURE);
                req.set(CaptureRequest.CONTROL_AE_MODE, CaptureRequest.CONTROL_AE_MODE_ON);
                s.setRepeatingRequest(req.build(), null, bgHandler);
            } catch (Exception e) { /* ignore */ }
        }
        @Override public void onConfigureFailed(CameraCaptureSession s) {}
    };

    void close() {
        try { if (session != null) session.close(); } catch (Exception e) {}
        try { if (camera != null) camera.close(); } catch (Exception e) {}
        if (bg != null) { bg.quitSafely(); bg = null; }
        session = null; camera = null; req = null; opening = false;
    }
}
