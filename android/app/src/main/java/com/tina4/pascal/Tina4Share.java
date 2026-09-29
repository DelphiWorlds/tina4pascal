package com.tina4.pascal;

import android.app.Activity;
import android.content.ClipData;
import android.content.Intent;
import android.net.Uri;
import android.webkit.MimeTypeMap;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.Set;

/** Native Android adapter for Tina4ShareItems.  Files are exposed through the
 * narrow Tina4ShareProvider; file:// URIs and broad storage permissions are
 * deliberately avoided. */
public final class Tina4Share {
    public static final int REQUEST_CODE = 4981;
    private static Activity activity;
    private static Tina4View view;

    private Tina4Share() {}

    static void init(Activity a) { activity = a; }
    static void setView(Tina4View v) { view = v; }

    public static void share(String[] kinds, String[] values, String[] mimes) {
        if (activity == null || kinds == null || values == null) return;
        try {
            Intent intent = new Intent();
            ArrayList<Uri> uris = new ArrayList<>();
            Set<String> types = new HashSet<>();
            StringBuilder text = new StringBuilder();
            for (int i = 0; i < kinds.length && i < values.length; i++) {
                String kind = kinds[i];
                String value = values[i];
                if ("text".equals(kind)) {
                    if (text.length() > 0) text.append('\n');
                    text.append(value);
                    types.add("text/plain");
                } else {
                    Uri uri = copyToShareCache(value);
                    uris.add(uri);
                    String mime = (mimes != null && i < mimes.length) ? mimes[i] : "*/*";
                    if ("*/*".equals(mime)) {
                        String ext = MimeTypeMap.getFileExtensionFromUrl(value);
                        String detected = MimeTypeMap.getSingleton().getMimeTypeFromExtension(ext);
                        if (detected != null) mime = detected;
                    }
                    types.add(mime);
                }
            }
            String type = "*/*";
            if (!types.isEmpty() && !types.contains("*/*")) {
                type = types.iterator().next();
                for (String t : types) if (!t.equals(type)) { type = "*/*"; break; }
            }
            if (uris.size() > 1) {
                intent.setAction(Intent.ACTION_SEND_MULTIPLE);
                intent.putParcelableArrayListExtra(Intent.EXTRA_STREAM, uris);
            } else {
                intent.setAction(Intent.ACTION_SEND);
                if (!uris.isEmpty()) intent.putExtra(Intent.EXTRA_STREAM, uris.get(0));
            }
            if (text.length() > 0) intent.putExtra(Intent.EXTRA_TEXT, text.toString());
            intent.setType(type);
            if (!uris.isEmpty()) {
                ClipData clip = ClipData.newRawUri("Tina4 share", uris.get(0));
                for (int i = 1; i < uris.size(); i++) clip.addItem(new ClipData.Item(uris.get(i)));
                intent.setClipData(clip);
                intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);
            }
            activity.startActivityForResult(Intent.createChooser(intent, "Share using"), REQUEST_CODE);
        } catch (Exception e) {
            if (view != null)
                activity.runOnUiThread(() -> view.onShareResult(7, "", e.getMessage()));
        }
    }

    private static Uri copyToShareCache(String source) throws Exception {
        File dir = new File(activity.getCacheDir(), "tina4-share");
        if (!dir.exists() && !dir.mkdirs()) throw new Exception("share cache unavailable");
        File in = new File(source);
        File out = new File(dir, System.currentTimeMillis() + "-" + in.getName());
        try (FileInputStream src = new FileInputStream(in);
             FileOutputStream dst = new FileOutputStream(out)) {
            byte[] buf = new byte[8192]; int n;
            while ((n = src.read(buf)) > 0) dst.write(buf, 0, n);
        }
        return Uri.parse("content://com.tina4.pascal.tina4share/" + Uri.encode(out.getName()));
    }
}
