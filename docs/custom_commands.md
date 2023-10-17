## What are custom commands?

Custom commands allows you to add additional menu items that speed up your workflow. If you have a command that you execute regularly through terminal you can convert it to custom command and make your life easier.

Some examples of custom commands:

- Execute a sequence of clicks to log into your app
- Reverse Android emulator port (for React Native)
- Open iOS deep link
- Open Logcat

## Creating your first command

1. Go to Preferences > Commands > Add new
2. Assign a name
3. Write custom command

For Android you will most likely use ADB:

```sh
$adb_path -s $adb_id reverse tcp:8081 tcp:8081
```

You can find available variables that you can use based on selected toggles if command needs booted device or not.

Let's break down the command:

- `$adb_path` - absolute path of the ADB utility
- `-s $adb_id` - executes command on emulator with a given ID (useful when you have multiple emulators running)
- `reverse tcp:8081 tcp:8081` rest of the ADB command. Run `adb --help` to check out what can be done.

For iOS you will most likely use `xcrun simctl` utility:

```sh
$xcrun_path simctl openurl booted "app://test.com"
```

You can identify simulators by the `$uuid` variable.

4. Choose icon
5. Click Add

Done! ✅

## Ready to use recipes

Here you can find a list of ready to use commands.

### Reverse React Native Metro port

```sh
$adb_path -s $adb_id reverse tcp:8081 tcp:8081
```

### Launch Logcat

```sh
osascript -e 'tell app "Terminal"
    do script "adb logcat -v color"
end tell'
```

### Login in to your app

```sh
$adb_path -s $adb_id
	shell input text "login@gmail.com"
	&& $adb_path -s $adb_id shell input tap 500 600
	&& $adb_path -s $adb_id shell input text "password"
```

_This might need some tweaking to fit your app_

### Wipe emulator data

```sh
$android_home_path/emulator/emulator @$device_name -wipe-data
```
