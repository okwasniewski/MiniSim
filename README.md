# MiniSim

![App logo](/MiniSim/Assets.xcassets/AppIcon.appiconset/256.png)

## About

MiniSim is a small utility menu bar app for launching Android 🤖 and iOS  emulators (and more!).

Written in Swift and AppKit. 

## Install

Download the app from [releases](https://github.com/okwasniewski/MiniSim/releases) page or use [Homebrew](https://brew.sh):

```shell
brew install --cask minisim
```

## Features
- Lightweight
- Fast, 100% native
- Open Source
- Open with shortcut: <kbd>⌥ + ⇧ + e</kbd>
- Launch iOS emulators
    - Copy device UDID
    - Copy device name
    - Delete simulators
- Launch Android emulators
    - Cold boot android emulators 
    - Run android emulators without audio (Your bluetooth headphones will thank you 🎧)
    - Toggle a11y on selected emulator
    - Copy device name
    - Copy device ADB id
- Focus devices using accessibility API
- Set default launch flags 
- Indicate running devices


## Screenshots 

<img width="512" src="https://user-images.githubusercontent.com/52801365/223483262-aa3bad72-2948-4893-87a0-578e5d3d8e89.png">

https://user-images.githubusercontent.com/52801365/224473566-a6248f20-8fc9-4b8e-ab95-64e85bc6d5c6.mp4

## Usage 

> **important**
This utility uses `xcrun` and `sdk/emulator` to fetch available devices on your machine. 
It might not work if you don't have a proper XCode and Android Studio setup.

There is a global shortcut for invoking the menu: <kbd>⌥ + ⇧ + e</kbd>.

