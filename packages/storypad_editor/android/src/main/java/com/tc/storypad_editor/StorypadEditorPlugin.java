package com.tc.storypad_editor;

import android.app.Activity;
import android.content.ActivityNotFoundException;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.content.pm.ResolveInfo;
import android.os.Build;
import android.util.SparseArray;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.PluginRegistry;

/**
 * The apps that act on selected text ("Process Text": Translate, Ask …) for the editor's selection menus, as a native
 * TextView offers them (AOSP android.widget.Editor.ProcessTextIntentActionsHandler): queried afresh each time,
 * in the system's order, only those this app may start, each labelled as the system labels it.
 *
 * <p>Flutter's own ProcessTextPlugin queries them once per engine and keeps the results, so an app updated since
 * shows its activity's class name (its stale info can no longer load its label), and returns them unordered.
 */
public class StorypadEditorPlugin
    implements FlutterPlugin, ActivityAware, MethodChannel.MethodCallHandler, PluginRegistry.ActivityResultListener {
  private static final String CHANNEL = "storypad_editor/process_text";

  // Request codes of our own for startActivityForResult (within the 16 bits an activity allows).
  private static final int REQUEST_CODE_BASE = 0x5300;
  private static final int REQUEST_CODE_COUNT = 0x100;

  @Nullable private MethodChannel channel;
  @Nullable private Context context;
  @Nullable private ActivityPluginBinding activityBinding;
  private final SparseArray<MethodChannel.Result> pendingResults = new SparseArray<>();
  private int nextRequest = 0;

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
    context = binding.getApplicationContext();
    channel = new MethodChannel(binding.getBinaryMessenger(), CHANNEL);
    channel.setMethodCallHandler(this);
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    if (channel != null) channel.setMethodCallHandler(null);
    channel = null;
    context = null;
  }

  @Override
  public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
    activityBinding = binding;
    binding.addActivityResultListener(this);
  }

  @Override
  public void onDetachedFromActivityForConfigChanges() {
    onDetachedFromActivity();
  }

  @Override
  public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
    onAttachedToActivity(binding);
  }

  @Override
  public void onDetachedFromActivity() {
    if (activityBinding != null) activityBinding.removeActivityResultListener(this);
    activityBinding = null;
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
    switch (call.method) {
      case "queryTextActions":
        result.success(queryTextActions());
        break;
      case "processTextAction":
        processTextAction(call.argument("id"), call.argument("text"), Boolean.TRUE.equals(call.argument("readOnly")), result);
        break;
      default:
        result.notImplemented();
    }
  }

  // ProcessTextIntentActionsHandler.loadSupportedActivities and getLabel: as {id, label}, in the system's order.
  private List<Map<String, String>> queryTextActions() {
    final List<Map<String, String>> actions = new ArrayList<>();
    // As TextView: none without an activity to start one for a result.
    if (context == null || activityBinding == null) return actions;
    final PackageManager packageManager = context.getPackageManager();
    final List<ResolveInfo> infos;
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
      infos = packageManager.queryIntentActivities(processTextIntent(), PackageManager.ResolveInfoFlags.of(0));
    } else {
      infos = packageManager.queryIntentActivities(processTextIntent(), 0);
    }
    for (ResolveInfo info : infos) {
      if (!isSupportedActivity(info)) continue;
      final Map<String, String> action = new HashMap<>();
      action.put("id", new ComponentName(info.activityInfo.packageName, info.activityInfo.name).flattenToString());
      action.put("label", info.loadLabel(packageManager).toString());
      actions.add(action);
    }
    return actions;
  }

  // ProcessTextIntentActionsHandler.isSupportedActivity: ours, or exported and not behind a permission we lack.
  private boolean isSupportedActivity(ResolveInfo info) {
    return context.getPackageName().equals(info.activityInfo.packageName)
        || info.activityInfo.exported
            && (info.activityInfo.permission == null
                || context.checkSelfPermission(info.activityInfo.permission) == PackageManager.PERMISSION_GRANTED);
  }

  // ProcessTextIntentActionsHandler.fireIntent: the app given the text (and whether it may change it); its result
  // the text it returns, if any.
  private void processTextAction(
      @Nullable String id, @Nullable String text, boolean readOnly, @NonNull MethodChannel.Result result) {
    final Activity activity = activityBinding == null ? null : activityBinding.getActivity();
    final ComponentName component = id == null ? null : ComponentName.unflattenFromString(id);
    if (activity == null || component == null) {
      result.error("unavailable", "No activity, or no such text action: " + id, null);
      return;
    }
    final Intent intent =
        processTextIntent()
            .setComponent(component)
            .putExtra(Intent.EXTRA_PROCESS_TEXT, text)
            .putExtra(Intent.EXTRA_PROCESS_TEXT_READONLY, readOnly);
    final int requestCode = REQUEST_CODE_BASE + nextRequest;
    nextRequest = (nextRequest + 1) % REQUEST_CODE_COUNT;
    pendingResults.put(requestCode, result);
    try {
      activity.startActivityForResult(intent, requestCode);
    } catch (ActivityNotFoundException | SecurityException e) {
      pendingResults.remove(requestCode);
      result.error("unavailable", e.getMessage(), null);
    }
  }

  @Override
  public boolean onActivityResult(int requestCode, int resultCode, @Nullable Intent data) {
    final MethodChannel.Result result = pendingResults.get(requestCode);
    if (result == null) return false;
    pendingResults.remove(requestCode);
    final boolean returned = resultCode == Activity.RESULT_OK && data != null;
    result.success(returned ? data.getStringExtra(Intent.EXTRA_PROCESS_TEXT) : null);
    return true;
  }

  private static Intent processTextIntent() {
    return new Intent().setAction(Intent.ACTION_PROCESS_TEXT).setType("text/plain");
  }
}
