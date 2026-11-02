package com.mrzscanner.flutter;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.os.Handler;
import android.os.Looper;

import androidx.annotation.NonNull;

import com.barkoder.mrzscanner.ar.MrzScan;

import java.util.List;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.PluginRegistry;

/**
 * The MRZ scanner for Flutter: each method passes its string arguments to the SDK's MrzScan and
 * returns its JSON (platforms/API.md); lib/mrzscanner.dart parses it.
 */
public class MrzscannerPlugin implements FlutterPlugin, MethodChannel.MethodCallHandler, ActivityAware,
        PluginRegistry.ActivityResultListener {
    private static final int SCAN = 0x4d525a;   // "MRZ"
    private final ExecutorService photos = Executors.newSingleThreadExecutor();
    private final Handler main = new Handler(Looper.getMainLooper());
    private MethodChannel channel;
    private Context context;
    private ActivityPluginBinding activity;
    private MethodChannel.Result scanning;

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
        context = binding.getApplicationContext();
        channel = new MethodChannel(binding.getBinaryMessenger(), "mrzscanner");
        channel.setMethodCallHandler(this);
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
        photos.shutdown();
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        List<String> args = call.arguments();
        switch (call.method) {
            case "registerLicense":
                result.success(MrzScan.registerLicense(context, args.get(0)));
                break;
            case "version":
                result.success(MrzScan.version());
                break;
            case "scanImage":
                photos.execute(() -> {
                    try {
                        String json = MrzScan.scanImage(context, args.get(0), args.get(1));
                        main.post(() -> result.success(json));
                    } catch (Exception e) {
                        main.post(() -> result.error("image", "Could not read the image: " + e.getMessage(), null));
                    }
                });
                break;
            case "scan":
                Activity a = activity == null ? null : activity.getActivity();
                if (a == null) {
                    result.error("activity", "No activity to show the camera over", null);
                    break;
                }
                scanning = result;
                a.startActivityForResult(new MrzScan.Contract().createIntent(a, args.get(0)), SCAN);
                break;
            default:
                result.notImplemented();
        }
    }

    @Override
    public boolean onActivityResult(int requestCode, int resultCode, Intent data) {
        if (requestCode != SCAN || scanning == null) return false;
        scanning.success(new MrzScan.Contract().parseResult(resultCode, data));
        scanning = null;
        return true;
    }

    @Override
    public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
        activity = binding;
        binding.addActivityResultListener(this);
    }

    @Override
    public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
        onAttachedToActivity(binding);
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {
        onDetachedFromActivity();
    }

    @Override
    public void onDetachedFromActivity() {
        if (activity != null) activity.removeActivityResultListener(this);
        activity = null;
    }
}
