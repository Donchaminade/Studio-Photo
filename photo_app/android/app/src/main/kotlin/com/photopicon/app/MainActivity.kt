package com.photopicon.app

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.telecom.PhoneAccountHandle
import android.telecom.TelecomManager
import android.telephony.SubscriptionManager
import android.telephony.TelephonyManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsControllerCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        private const val CHANNEL = "com.picon/ussd"
    }

    private val mainHandler = Handler(Looper.getMainLooper())

    override fun onCreate(savedInstanceState: Bundle?) {
        // FlutterActivity n'étend pas ComponentActivity : pas de enableEdgeToEdge().
        // WindowCompat = même contrat Android 15 (insets), sans setStatusBarColor.
        WindowCompat.setDecorFitsSystemWindows(window, false)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            window.isStatusBarContrastEnforced = false
            window.isNavigationBarContrastEnforced = false
        }
        super.onCreate(savedInstanceState)
        WindowCompat.setDecorFitsSystemWindows(window, false)
        WindowInsetsControllerCompat(window, window.decorView).apply {
            isAppearanceLightStatusBars = false
            isAppearanceLightNavigationBars = true
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getSimCards" -> {
                        try {
                            result.success(getSimCards())
                        } catch (e: Exception) {
                            result.error("SIM_ERROR", e.message, null)
                        }
                    }

                    "launchUssd" -> {
                        val code = call.argument<String>("code")
                        if (code.isNullOrBlank()) {
                            result.error("INVALID", "Code USSD requis", null)
                            return@setMethodCallHandler
                        }
                        if (ContextCompat.checkSelfPermission(
                                this,
                                Manifest.permission.CALL_PHONE
                            ) != PackageManager.PERMISSION_GRANTED
                        ) {
                            result.error(
                                "PERMISSION",
                                "Permission CALL_PHONE refusée",
                                null
                            )
                            return@setMethodCallHandler
                        }
                        try {
                            val paymentPhone = call.argument<String>("paymentPhone")
                            val operatorHint = call.argument<String>("operatorHint")
                            val launchResult =
                                launchUssdOnMatchingSim(code, paymentPhone, operatorHint)
                            result.success(launchResult)
                        } catch (e: Exception) {
                            result.error("USSD_ERROR", e.message, null)
                        }
                    }

                    else -> result.notImplemented()
                }
            }
    }

    private fun getSimCards(): List<Map<String, Any?>> {
        val list = mutableListOf<Map<String, Any?>>()
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.LOLLIPOP_MR1) return list
        val sm = getSystemService(Context.TELEPHONY_SUBSCRIPTION_SERVICE) as SubscriptionManager
        if (ActivityCompat.checkSelfPermission(
                this,
                Manifest.permission.READ_PHONE_STATE
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            return list
        }
        val subs = sm.activeSubscriptionInfoList ?: return list
        val baseTm = getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager

        for (info in subs) {
            var number = info.number ?: ""
            if (number.isBlank() && Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                try {
                    val subTm = baseTm.createForSubscriptionId(info.subscriptionId)
                    if (hasPhoneNumberPermission()) {
                        number = subTm.line1Number ?: ""
                    }
                } catch (_: Exception) {
                }
            }
            list.add(
                mapOf(
                    "subscriptionId" to info.subscriptionId,
                    "slotIndex" to info.simSlotIndex,
                    "carrierName" to (info.carrierName?.toString() ?: ""),
                    "displayName" to (info.displayName?.toString() ?: ""),
                    "number" to number
                )
            )
        }
        return list
    }

    private fun hasPhoneNumberPermission(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            return ActivityCompat.checkSelfPermission(
                this,
                Manifest.permission.READ_PHONE_NUMBERS
            ) == PackageManager.PERMISSION_GRANTED
        }
        return ActivityCompat.checkSelfPermission(
            this,
            Manifest.permission.READ_PHONE_STATE
        ) == PackageManager.PERMISSION_GRANTED
    }

    private fun launchUssdOnMatchingSim(
        ussdCode: String,
        paymentPhone: String?,
        operatorHint: String?
    ): Map<String, Any?> {
        val subscriptionId = resolveSubscriptionId(paymentPhone, operatorHint)
        val telecomManager = getSystemService(Context.TELECOM_SERVICE) as TelecomManager

        if (launchUssdViaPlaceCall(ussdCode, subscriptionId, telecomManager)) {
            return mapOf("success" to true, "method" to "place_call")
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && subscriptionId != null) {
            if (launchUssdViaTelephony(ussdCode, subscriptionId)) {
                return mapOf("success" to true, "method" to "ussd_dialog")
            }
        }

        if (launchUssdViaDefaultDialer(ussdCode)) {
            return mapOf("success" to true, "method" to "dialer_explicit")
        }

        return mapOf("success" to false, "method" to "failed")
    }

    private fun ussdTelUri(ussdCode: String): Uri {
        val encoded = ussdCode.replace("#", "%23")
        return Uri.parse("tel:$encoded")
    }

    private fun launchUssdViaPlaceCall(
        ussdCode: String,
        subscriptionId: Int?,
        telecomManager: TelecomManager
    ): Boolean {
        return try {
            val uri = ussdTelUri(ussdCode)
            val extras = Bundle()
            val handle = findPhoneAccountHandle(telecomManager, subscriptionId)
            if (handle != null) {
                extras.putParcelable(TelecomManager.EXTRA_PHONE_ACCOUNT_HANDLE, handle)
            }
            telecomManager.placeCall(uri, extras)
            true
        } catch (_: Exception) {
            false
        }
    }

    private fun launchUssdViaTelephony(ussdCode: String, subscriptionId: Int): Boolean {
        return try {
            val baseTm = getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager
            val tm = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                baseTm.createForSubscriptionId(subscriptionId)
            } else {
                baseTm
            }

            tm.sendUssdRequest(
                ussdCode,
                object : TelephonyManager.UssdResponseCallback() {
                    override fun onReceiveUssdResponse(
                        telephonyManager: TelephonyManager,
                        request: String,
                        response: CharSequence
                    ) {
                    }

                    override fun onReceiveUssdResponseFailed(
                        telephonyManager: TelephonyManager,
                        request: String,
                        failureCode: Int
                    ) {
                    }
                },
                mainHandler
            )
            true
        } catch (_: Exception) {
            false
        }
    }

    private fun launchUssdViaDefaultDialer(ussdCode: String): Boolean {
        val uri = ussdTelUri(ussdCode)
        val telecomManager = getSystemService(Context.TELECOM_SERVICE) as TelecomManager

        val candidates = mutableListOf<String>()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            telecomManager.defaultDialerPackage?.let { candidates.add(it) }
        }
        candidates.addAll(
            listOf(
                "com.google.android.dialer",
                "com.android.dialer",
                "com.samsung.android.dialer",
                "com.sh.smart.caller",
                "com.huawei.contacts"
            )
        )

        for (pkg in candidates.distinct()) {
            try {
                val intent = Intent(Intent.ACTION_CALL, uri).apply {
                    setPackage(pkg)
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                if (intent.resolveActivity(packageManager) != null) {
                    startActivity(intent)
                    return true
                }
            } catch (_: Exception) {
            }
        }
        return false
    }

    private fun resolveSubscriptionId(paymentPhone: String?, operatorHint: String?): Int? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.LOLLIPOP_MR1) return null
        val sm = getSystemService(Context.TELEPHONY_SUBSCRIPTION_SERVICE) as SubscriptionManager
        if (ActivityCompat.checkSelfPermission(
                this,
                Manifest.permission.READ_PHONE_STATE
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            return null
        }
        val subs = sm.activeSubscriptionInfoList ?: return null
        if (subs.isEmpty()) return null

        val paymentLocal = normalizeLocalDigits(paymentPhone)
        if (paymentLocal.length >= 8) {
            val tail = paymentLocal.takeLast(8)
            for (info in subs) {
                val simLocal = normalizeLocalDigits(readNumberForSubscription(info))
                if (simLocal.isNotEmpty() &&
                    (simLocal == tail || simLocal.endsWith(tail) || tail.endsWith(simLocal))
                ) {
                    return info.subscriptionId
                }
            }
        }

        val hint = operatorHint?.uppercase() ?: ""
        if (hint.isNotEmpty()) {
            for (info in subs) {
                val label = "${info.carrierName} ${info.displayName}".lowercase()
                when {
                    hint.contains("YAS") || hint.contains("MIXX") || hint.contains("TOGOCEL") -> {
                        if (
                            label.contains("yas") ||
                            label.contains("togocel") ||
                            label.contains("togocom") ||
                            label.contains("mix")
                        ) {
                            return info.subscriptionId
                        }
                    }

                    hint.contains("MOOV") || hint.contains("FLOOZ") -> {
                        if (label.contains("moov") || label.contains("flooz")) {
                            return info.subscriptionId
                        }
                    }
                }
            }
        }

        return subs.first().subscriptionId
    }

    private fun readNumberForSubscription(
        info: android.telephony.SubscriptionInfo
    ): String {
        var number = info.number ?: ""
        if (number.isNotBlank()) return number
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N && hasPhoneNumberPermission()) {
            try {
                val tm = (getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager)
                    .createForSubscriptionId(info.subscriptionId)
                number = tm.line1Number ?: ""
            } catch (_: Exception) {
            }
        }
        return number
    }

    private fun findPhoneAccountHandle(
        telecomManager: TelecomManager,
        subscriptionId: Int?
    ): PhoneAccountHandle? {
        val accounts = telecomManager.callCapablePhoneAccounts ?: return null
        if (accounts.isEmpty()) return null
        if (subscriptionId == null) return accounts[0]

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP_MR1) {
            val sm = getSystemService(Context.TELEPHONY_SUBSCRIPTION_SERVICE) as SubscriptionManager
            val info = sm.activeSubscriptionInfoList?.find { it.subscriptionId == subscriptionId }
            val slot = info?.simSlotIndex
            if (slot != null && slot >= 0 && slot < accounts.size) {
                return accounts[slot]
            }
        }
        return accounts[0]
    }

    private fun normalizeLocalDigits(phone: String?): String {
        if (phone.isNullOrBlank()) return ""
        var digits = phone.replace(Regex("[^0-9]"), "")
        if (digits.startsWith("00228")) {
            digits = digits.substring(5)
        } else if (digits.startsWith("228") && digits.length >= 11) {
            digits = digits.substring(3)
        }
        if (digits.startsWith("0") && digits.length == 9) {
            digits = digits.substring(1)
        }
        if (digits.length > 8) {
            digits = digits.substring(digits.length - 8)
        }
        return digits
    }
}
