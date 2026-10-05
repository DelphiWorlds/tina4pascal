package com.tina4.pascal;

import android.content.ContentProvider;
import android.content.ContentValues;
import android.database.Cursor;
import android.net.Uri;
import android.os.ParcelFileDescriptor;
import java.io.File;

/** Read-only provider for files staged in the app's private share cache. */
public final class Tina4ShareProvider extends ContentProvider {
    @Override public boolean onCreate() { return true; }
    @Override public String getType(Uri uri) { return "application/octet-stream"; }
    @Override public ParcelFileDescriptor openFile(Uri uri, String mode) throws java.io.FileNotFoundException {
        if (!"r".equals(mode)) throw new java.io.FileNotFoundException("read-only");
        File root = new File(getContext().getCacheDir(), "tina4-share");
        File file = new File(root, uri.getLastPathSegment());
        try {
            if (!file.getCanonicalPath().startsWith(root.getCanonicalPath() + File.separator))
                throw new java.io.FileNotFoundException("invalid share path");
        } catch (java.io.IOException e) { throw new java.io.FileNotFoundException("invalid share path"); }
        return ParcelFileDescriptor.open(file, ParcelFileDescriptor.MODE_READ_ONLY);
    }
    @Override public Cursor query(Uri u, String[] p, String s, String[] a, String sort) { return null; }
    @Override public int delete(Uri u, String s, String[] a) { return 0; }
    @Override public int update(Uri u, ContentValues v, String s, String[] a) { return 0; }
    @Override public Uri insert(Uri u, ContentValues v) { return null; }
}
