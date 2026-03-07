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

      // Get all activity components (including aliases and disabled ones)
      val packageInfo = packageManager.getPackageInfo(
          packageName,
          PackageManager.GET_ACTIVITIES or PackageManager.GET_DISABLED_COMPONENTS
      )
      
      val mainActivityName = "$packageName.MainActivity"
      val mainActivityComponent = ComponentName(packageName, mainActivityName)
      
      // Restrict to activity-alias entries that explicitly target MainActivity.
      // packageInfo.activities may include regular activities from dependencies
      // (e.g. Google Sign-In), and disabling them can break sign-in flows.
      val aliases = packageInfo.activities
          ?.filter { it.targetActivity == mainActivityName }
          ?.filter { it.name != mainActivityName }
          ?.map { it.name }
          ?: emptyList()

      if (aliases.isEmpty()) {
        result.error("FAILED", "No app logo activity aliases found", null)
        return
      }

      aliasName?.let {
        if (!aliases.contains(it)) {
          result.error("FAILED", "Invalid app logo alias: $it", null)
          return
        }
      }

      // Disable all aliases
      aliases.forEach { alias ->
        packageManager.setComponentEnabledSetting(
            ComponentName(packageName, alias),
            PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
            PackageManager.DONT_KILL_APP
        )
      }

      if (aliasName == null) {
        // Fall back to the default launcher declared on MainActivity.
        packageManager.setComponentEnabledSetting(
            mainActivityComponent,
            PackageManager.COMPONENT_ENABLED_STATE_ENABLED,
            PackageManager.DONT_KILL_APP
        )
      } else {
        // Use alias launcher icon and hide the default launcher entry.
        packageManager.setComponentEnabledSetting(
            mainActivityComponent,
            PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
            PackageManager.DONT_KILL_APP
        )
        packageManager.setComponentEnabledSetting(
            ComponentName(packageName, aliasName),
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
