package com.example.kudipay

import io.flutter.embedding.android.FlutterFragmentActivity

// local_auth's BiometricPrompt integration requires a FragmentActivity —
// plain FlutterActivity throws "local_auth plugin requires the host Activity
// to be a FlutterFragmentActivity" at runtime.
class MainActivity: FlutterFragmentActivity() {
}
