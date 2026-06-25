# OrientDemo

A small [Mob](https://github.com/GenericJam/mob) app that demonstrates the device
screen-orientation API: reading the current orientation, subscribing to rotation
changes, and locking or unlocking the app to a specific orientation. The same
Elixir UI runs on both iOS and Android, with the BEAM on the device.

Generated with `mix mob.new` (mob_new 0.4.14) and built against `mob ~> 0.7.7`.

## What it shows

[`lib/orient_demo/orientation_screen.ex`](lib/orient_demo/orientation_screen.ex)
exercises `Mob.Device`:

```elixir
Mob.Device.orientation()
# :portrait | :portrait_upside_down | :landscape_left | :landscape_right | :unknown

Mob.Device.subscribe(:display)
# screen process then receives {:mob_device, :orientation_changed, orientation}

Mob.Device.lock_orientation(:landscape)
# force landscape (either side); also :portrait, :landscape_left, :landscape_right,
# :portrait_upside_down. Returns {:error, :invalid} for anything else.

Mob.Device.unlock_orientation()
# follow the sensor again
```

The screen shows the live orientation (kept current via the `:display`
subscription) plus a button per lock value and an unlock button. Locking rotates
the device and holds it there regardless of the OS auto-rotate setting.

## Running it

Prerequisites: the Mob toolchain (Elixir/OTP from the pinned `.tool-versions`,
Android SDK + JDK 17 for Android, Xcode for iOS). See the
[Mob getting-started guide](https://hexdocs.pm/mob/getting_started.html).

```bash
mix deps.get
mix mob.install            # first-run setup: OTP runtimes, icons, local.properties

# Android device or emulator (serial from `adb devices`):
mix mob.deploy --native --device <serial>

# iOS simulator (UDID from `mix mob.devices`):
mix mob.deploy --native --device <sim-udid>

# iOS physical device: one-time provisioning, then deploy:
mix mob.provision
mix mob.deploy --native --device <iphone-udid>
```

Open the app and tap **Orientation**.

## How orientation lock works

`lock_orientation/1` lives in `Mob.Device` (core Mob), but actually *holding* a
rotation needs a little native glue in the app shell. `mix mob.new` (0.4.14+)
scaffolds it automatically:

- **iOS** (`ios/AppDelegate.m`, `ios/Info.plist`): the app delegate returns
  `mob_locked_orientation_mask()` from
  `application:supportedInterfaceOrientationsForWindow:` (the window-level
  override that holds the lock over the root view controller), and the plist
  declares the landscape orientations so iOS will rotate to them.
- **Android** (`MobBridge.kt`, `MainActivity.kt`, `beam_jni.c`):
  `MobBridge.orientationLock/1` calls `Activity.setRequestedOrientation`, and
  `onConfigurationChanged` forwards each rotation back to the BEAM
  (`mob_send_orientation_changed`) so `orientation/0` and the `:display`
  subscription stay accurate.

## Notes

This is a reference / demo app. `mob.exs` and `android/local.properties` are
machine-local and gitignored; `mix mob.install` regenerates them. iOS signing
config (team, profile) comes from `mix mob.provision`.
