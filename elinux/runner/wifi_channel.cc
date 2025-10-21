// Simple Wi-Fi control channel using nmcli for Flutter eLinux
// Note: This implementation shells out to nmcli; ensure the process has
// permission to control NetworkManager (usually requires running with proper
// privileges or policykit rules).

#include "wifi_channel.h"

#include <flutter/encodable_value.h>
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>

#include <cstdio>
#include <cstdlib>
#include <memory>
#include <sstream>
#include <string>
#include <vector>

using flutter::EncodableList;
using flutter::EncodableMap;
using flutter::EncodableValue;

static std::string RunCmd(const std::string& cmd) {
  std::string result;
  FILE* pipe = popen(cmd.c_str(), "r");
  if (!pipe) {
    return "";
  }
  char buffer[512];
  while (fgets(buffer, sizeof(buffer), pipe) != nullptr) {
    result += buffer;
  }
  pclose(pipe);
  return result;
}

static bool WifiEnable(bool enable) {
  // nmcli radio wifi on|off
  std::string cmd = std::string("nmcli radio wifi ") + (enable ? "on" : "off");
  auto out = RunCmd(cmd);
  // nmcli returns empty on success in some versions; we just check again.
  auto status = RunCmd("nmcli -t -f WIFI general");
  return (enable && status.find("enabled") != std::string::npos) ||
         (!enable && status.find("disabled") != std::string::npos);
}

static EncodableList WifiScan() {
  // Trigger rescan
  RunCmd("nmcli device wifi rescan");
  // List access points in terse format: SSID:SECURITY:SIGNAL
  auto out = RunCmd("nmcli -t -f SSID,SECURITY,SIGNAL device wifi list");
  EncodableList networks;
  std::istringstream ss(out);
  std::string line;
  while (std::getline(ss, line)) {
    if (line.empty()) continue;
    // Split by ':' but SSID itself may contain ':'; nmcli uses '\n' separated rows
    // We'll parse first field as SSID, then SECURITY, SIGNAL by counting fields.
    size_t p1 = line.find(':');
    size_t p2 = line.find(':', p1 == std::string::npos ? 0 : p1 + 1);
    std::string ssid = p1 == std::string::npos ? line : line.substr(0, p1);
    std::string security = (p1 != std::string::npos && p2 != std::string::npos)
                               ? line.substr(p1 + 1, p2 - p1 - 1)
                               : "";
    std::string signal = (p2 != std::string::npos) ? line.substr(p2 + 1) : "";

    EncodableMap item;
    item[EncodableValue("ssid")] = EncodableValue(ssid);
    item[EncodableValue("security")] = EncodableValue(security);
    item[EncodableValue("signal")] = EncodableValue(signal);
    networks.emplace_back(item);
  }
  return networks;
}

static EncodableMap WifiStatus() {
  EncodableMap status;
  auto radio = RunCmd("nmcli -t -f WIFI general");
  status[EncodableValue("enabled")] = EncodableValue(radio.find("enabled") != std::string::npos);
  // Active connection SSID
  auto active = RunCmd("nmcli -t -f NAME,DEVICE connection show --active");
  std::istringstream ss(active);
  std::string line;
  std::string ssid;
  while (std::getline(ss, line)) {
    if (line.empty()) continue;
    size_t p = line.find(':');
    ssid = p == std::string::npos ? line : line.substr(0, p);
    break;
  }
  status[EncodableValue("ssid")] = EncodableValue(ssid);
  return status;
}

static bool WifiConnect(const std::string& ssid, const std::string& password) {
  if (ssid.empty()) return false;
  std::string cmd = std::string("nmcli device wifi connect \"") + ssid + "\"";
  if (!password.empty()) {
    cmd += std::string(" password \"") + password + "\"";
  }
  // capture stderr
  auto out = RunCmd(cmd + " 2>&1");
  // Verify active connections contain the SSID
  auto active = RunCmd("nmcli -t -f NAME,DEVICE connection show --active");
  return active.find(ssid) != std::string::npos;
}

void RegisterWifiChannel(flutter::FlutterViewController* controller) {
  if (!controller || !controller->engine()) return;
  auto messenger = controller->engine()->messenger();
  static const auto& codec = flutter::StandardMethodCodec::GetInstance();
  auto channel = std::make_unique<flutter::MethodChannel<EncodableValue>>(messenger, "wifi_control", &codec);

  channel->SetMethodCallHandler(
      [channel_ptr = channel.get()](const auto& call, std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
        const std::string& method = call.method_name();
        const auto* args = std::get_if<EncodableMap>(call.arguments());
        if (method == "enable") {
          bool enable = false;
          if (args) {
            auto it = args->find(EncodableValue("enable"));
            if (it != args->end()) {
              if (const bool* b = std::get_if<bool>(&it->second)) enable = *b;
            }
          }
          bool ok = WifiEnable(enable);
          result->Success(EncodableValue(ok));
          return;
        } else if (method == "scan") {
          auto list = WifiScan();
          result->Success(EncodableValue(list));
          return;
        } else if (method == "status") {
          auto st = WifiStatus();
          result->Success(EncodableValue(st));
          return;
        } else if (method == "connect") {
          std::string ssid;
          std::string password;
          if (args) {
            auto itSsid = args->find(EncodableValue("ssid"));
            if (itSsid != args->end()) {
              if (const std::string* s = std::get_if<std::string>(&itSsid->second)) ssid = *s;
            }
            auto itPwd = args->find(EncodableValue("password"));
            if (itPwd != args->end()) {
              if (const std::string* p = std::get_if<std::string>(&itPwd->second)) password = *p;
            }
          }
          bool ok = WifiConnect(ssid, password);
          EncodableMap res;
          res[EncodableValue("ok")] = EncodableValue(ok);
          res[EncodableValue("ssid")] = EncodableValue(ssid);
          result->Success(EncodableValue(res));
          return;
        }
        result->NotImplemented();
      });

  // Keep channel alive for app lifetime. Store as static unique_ptr.
  static std::unique_ptr<flutter::MethodChannel<EncodableValue>> s_channel;
  s_channel = std::move(channel);
}