---
layout: default
parent: Contribution
title: Runner.entitlements
---

# Runner.entitlements

## How to generate Runner.entitlements in Flutter?

To generate this file,

1. Simply click on Runner.xcworkspace which will open Xcode.
2. Then go to Target > Runner > Signing & Capabilities
3. Click on "+ Capability"
4. Then add a capability that you need.
5. Done ✅

## FlutterSecureStorage

FlutterSecureStorage required to add Keychain Sharing Capability. After going through step by step above, it will generate following content:

```
<dict>
  <key>keychain-access-groups</key>
  <array />
</dict>
```
