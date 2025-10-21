// Simple Wi-Fi control channel using nmcli for Flutter eLinux
// Exposes methods: enable(bool), scan(), status()
#ifndef ELINUX_RUNNER_WIFI_CHANNEL_H_
#define ELINUX_RUNNER_WIFI_CHANNEL_H_

#include <flutter/flutter_view_controller.h>

// Registers a MethodChannel named "wifi_control" on the given controller's
// engine messenger, handling nmcli-backed Wi-Fi operations.
void RegisterWifiChannel(flutter::FlutterViewController* controller);

#endif  // ELINUX_RUNNER_WIFI_CHANNEL_H_