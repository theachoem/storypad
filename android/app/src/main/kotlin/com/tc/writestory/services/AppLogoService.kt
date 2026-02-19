package com.tc.writestory.services

import android.content.ComponentName
import android.content.Context
import android.content.pm.PackageManager
import io.flutter.plugin.common.MethodChannel

object AppLogoService {
  fun set(context: Context, aliasName: String?, result: MethodChannel.Result) {
    try {
      val packageManager = context.packageManager
      val packageName = context.packageName

      // Get all activity aliases from manifest
      val packageInfo = packageManager.getPackageInfo(
          packageName,
          PackageManager.GET_ACTIVITIES or PackageManager.GET_DISABLED_COMPONENTS
      )
      
      val mainActivity = "com.tc.writestory.MainActivity"
      val aliases = packageInfo.activities
          ?.filter { it.targetActivity == mainActivity && it.name != mainActivity }
          ?.map { it.name }
          ?: emptyList()

      // Disable all aliases
      aliases.forEach { alias ->
        packageManager.setComponentEnabledSetting(
            ComponentName(packageName, alias),
            PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
            PackageManager.DONT_KILL_APP
        )
      }

      // Enable specific alias if provided
      aliasName?.let {
        packageManager.setComponentEnabledSetting(
            ComponentName(packageName, it),
            PackageManager.COMPONENT_ENABLED_STATE_ENABLED,
            PackageManager.DONT_KILL_APP
        )
      }

      result.success(null)
    } catch (e: Exception) {
      result.error("FAILED", "Failed to set alternate icon: ${e.message}", null)
    }
  }
}
