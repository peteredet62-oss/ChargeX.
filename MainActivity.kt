package com.example.charge_monitor

import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import android.os.Build
import android.os.Bundle
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import kotlin.math.abs

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.user.charge_monitor/battery"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        MethodChannel(flutterEngine?.dartExecutor?.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getBatteryInfo" -> {
                    val info = getBatteryInfo()
                    result.success(info)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun getBatteryInfo(): Map<String, Any> {
        val ifilter = IntentFilter(Intent.ACTION_BATTERY_CHANGED)
        val batteryStatus: Intent? = registerReceiver(null, ifilter)

        val level = batteryStatus?.getIntExtra(BatteryManager.EXTRA_LEVEL, -1) ?: -1
        val scale = batteryStatus?.getIntExtra(BatteryManager.EXTRA_SCALE, -1) ?: -1
        val batteryPct = if (level >=0 && scale > 0) (level * 100 / scale) else -1

        val voltage = batteryStatus?.getIntExtra(BatteryManager.EXTRA_VOLTAGE, 0) ?: 0 // mV
        val status = batteryStatus?.getIntExtra(BatteryManager.EXTRA_STATUS, -1) ?: -1
        val isCharging = status == BatteryManager.BATTERY_STATUS_CHARGING || status == BatteryManager.BATTERY_STATUS_FULL

        var currentNow = 0
        try {
            val bm = getSystemService(Context.BATTERY_SERVICE) as BatteryManager
            // BATTERY_PROPERTY_CURRENT_NOW returns microamperes on some devices -> convert to mA
            val cap = bm.getIntProperty(BatteryManager.BATTERY_PROPERTY_CURRENT_NOW)
            if (cap != Int.MIN_VALUE) {
                // convert microamps to mA if value seems large; some vendors already return mA negative for discharge
                currentNow = if (abs(cap) > 100000) (cap / 1000) else cap
            }
        } catch (e: Exception) {
            currentNow = 0
        }

        // Some devices return negative for charging/discharging; normalize so charging current positive
        val normalizedCurrent = if (currentNow < 0) abs(currentNow) else currentNow

        val map: MutableMap<String, Any> = HashMap()
        map["level"] = batteryPct
        map["voltage"] = voltage // mV
        map["current"] = normalizedCurrent // mA (approx)
        map["isCharging"] = isCharging
        return map
    }
}
