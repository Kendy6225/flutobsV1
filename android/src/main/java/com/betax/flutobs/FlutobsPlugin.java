package com.betax.flutobs;

import android.os.Handler;
import android.os.Looper;
import android.os.Message;
import android.util.Log;

import androidx.annotation.NonNull;

import com.obs.services.ObsClient;
import com.obs.services.ObsConfiguration;
import com.obs.services.model.ObjectMetadata;
import com.obs.services.model.ProgressListener;
import com.obs.services.model.ProgressStatus;
import com.obs.services.model.PutObjectRequest;

import java.io.File;
import java.util.Map;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;

/**
 * FlutobsPlugin
 */
public class FlutobsPlugin implements FlutterPlugin, MethodCallHandler {
    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private MethodChannel channel;

    private ObsClient obsClient;

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
        channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "flutobs");
        channel.setMethodCallHandler(this);
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
        if (call.method.equals("getPlatformVersion")) {
            result.success("Android " + android.os.Build.VERSION.RELEASE);
        } else if (call.method.equals("initSDK")) {
            Map<String, String> map = (Map) call.arguments;
            String appKey = map.get("appKey");
            String appSecret = map.get("appSecret");
            String endPoint = map.get("endPoint");
            ObsConfiguration config = new ObsConfiguration();
            config.setEndPoint(endPoint);
            config.setSocketTimeout(30000);
            config.setMaxErrorRetry(3);
            obsClient = new ObsClient(appKey, appSecret, config);
            result.success(true);
        } else if (call.method.equals("upload")) {
            final Map<String, String> map = (Map) call.arguments;
            final Handler handler = new Handler(Looper.getMainLooper()) {
                @Override
                public void handleMessage(Message msg) {
                    super.handleMessage(msg);
                    switch (msg.what) {
                        case 0x01:
                            channel.invokeMethod("progress", msg.obj);
                            break;
                    }
                }
            };
            new Thread(
                    new Runnable() {
                        @Override
                        public void run() {
                            String filePath = map.get("filePath");
                            String bucketName = map.get("bucketname");
                            String fileName = map.get("objectname");
                            ObjectMetadata metadata = new ObjectMetadata();
                            metadata.setContentType("image/*");
                            File file = new File(filePath);
                            PutObjectRequest request = new PutObjectRequest(bucketName, file.getName());
                            request.setFile(file);
                            request.setMetadata(metadata);
                            request.setProgressListener(new ProgressListener() {
                                @Override
                                public void progressChanged(ProgressStatus status) {
                                    // 获取上传平均速率
                                    Log.d("OBS", "ObsManger Start ======> AverageSpeed:" + status.getAverageSpeed());
                                    // 获取上传进度百分比
                                    Log.d("OBS", "ObsManger Start ======> TransferPercentage:" + status.getTransferPercentage());
                                    handler.obtainMessage(0x01, status.getTransferPercentage()).sendToTarget();
                                }
                            });
                            request.setProgressInterval(10L);
                            obsClient.putObject(request);
                        }
                    }
            ).start();
        } else {
            result.notImplemented();
        }
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
    }
}
