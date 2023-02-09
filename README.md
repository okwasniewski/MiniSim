# MiniSim

![App logo](/MiniSim/Assets.xcassets/AppIcon.appiconset/256.png)

## About

MiniSim is a small utility menu bar app for lauching Android 🤖 and iOS  emulators (and more!).

Written in Swift and AppKit. 

## Features
- Lightweight
- Fast, 100% native
- Open Source
- Open with shortcut `⌥ + ⇧ + e` (option + shift + e)
- Launch iOS emulators
    - Copy device UDID
    - Copy device name
- Launch Android emulators
    - Cold boot android emulators 
    - Run android emulators without audio (Your bluetooth headphones will thank you 🎧)
    - Toggle a11y on selected emulator
    - Copy device name
    - Copy device ADB id

## Screenshots 

<img width="512" src="https://user-images.githubusercontent.com/52801365/215720502-bc27dd65-8e5f-47d8-871e-b273f622f909.png">

https://user-images.githubusercontent.com/52801365/215720684-d21deafe-356e-4e5a-9afd-5107bd1c4b2f.mp4

## Usage 

This utility uses `xcrun` and `sdk/emulator` to fetch available devices on your machine. 

It might not work if you don't have a proper XCode and Android Studio setup.

There is a global shortcut for invoking the menu: `⌥ + ⇧ + e` (option + shift + e).

