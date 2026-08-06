//
//  SubMenuItem.swift
//  MiniSim
//
//  Created by Anton Kolchunov on 11.10.23.
//

import Cocoa
import Foundation

protocol SubMenuItem { }

protocol SubMenuActionItem: SubMenuItem {
    var title: String { get }
    var tag: Int { get }
    var needBootedDevice: Bool { get }
    var bootsDevice: Bool { get }
    var image: NSImage? { get }
    var toolTip: String? { get }
}

extension SubMenuActionItem {
    var toolTip: String? {
        nil
    }
}

protocol SubMenuSectionItem: SubMenuItem {
    var title: String { get }
    var needBootedDevice: Bool { get }
}

enum SubMenuItems {
    enum Tags: Int, CaseIterable {
        case copyName = 100
        case copyID
        case coldBoot
        case noAudio
        case toggleA11y
        case paste
        case delete
        case logcat
        case upload
        case localFiles
        case customCommand = 200
    }

    struct Separator: SubMenuItem { }

    struct SectionTitle: SubMenuSectionItem {
        let title: String
        let needBootedDevice: Bool
    }

    struct CopyName: SubMenuActionItem {
        let title = NSLocalizedString("Copy name", comment: "")
        let tag = Tags.copyName.rawValue
        let bootsDevice = false
        let needBootedDevice = false
        let image = NSImage(
            systemSymbolName: "square.and.arrow.up",
            accessibilityDescription: "Copy name"
        )
    }

    struct CopyID: SubMenuActionItem {
        let title = NSLocalizedString("Copy ID", comment: "")
        let tag = Tags.copyID.rawValue
        let bootsDevice = false
        let needBootedDevice = true
        let image = NSImage(
            systemSymbolName: "doc.on.doc",
            accessibilityDescription: "Copy ID"
        )
    }

    struct CopyUDID: SubMenuActionItem {
        let title = NSLocalizedString("Copy UDID", comment: "")
        let tag = Tags.copyID.rawValue
        let bootsDevice = false
        let needBootedDevice = false
        let image = NSImage(
            systemSymbolName: "doc.on.doc",
            accessibilityDescription: "Copy UDID"
        )
    }

    struct ColdBoot: SubMenuActionItem {
        let title = NSLocalizedString("Cold boot", comment: "")
        let tag = Tags.coldBoot.rawValue
        let bootsDevice = true
        let needBootedDevice = false
        let image = NSImage(
            systemSymbolName: "sunrise.fill",
            accessibilityDescription: "Cold boot"
        )
    }

    struct NoAudio: SubMenuActionItem {
        let title = NSLocalizedString("Run without audio", comment: "")
        let tag = Tags.noAudio.rawValue
        let bootsDevice = true
        let needBootedDevice = false
        let image = NSImage(
            systemSymbolName: "speaker.slash.fill",
            accessibilityDescription: "Run without audio"
        )
    }

    struct ToggleA11y: SubMenuActionItem {
        let title = NSLocalizedString("Toggle accessibility", comment: "")
        let tag = Tags.toggleA11y.rawValue
        let bootsDevice = false
        let needBootedDevice = true
        let image = NSImage(
            systemSymbolName: "figure.walk.circle.fill",
            accessibilityDescription: "Toggle accessibility"
        )
    }

    struct Paste: SubMenuActionItem {
        let title = NSLocalizedString("Paste clipboard to device", comment: "")
        let tag = Tags.paste.rawValue
        let bootsDevice = false
        let needBootedDevice = true
        let image = NSImage(
            systemSymbolName: "keyboard",
            accessibilityDescription: "Keyboard"
        )
    }

    struct Upload: SubMenuActionItem {
        let title = NSLocalizedString("Upload...", comment: "")
        let tag = Tags.upload.rawValue
        let bootsDevice = false
        let needBootedDevice = true
        let image = NSImage(
            systemSymbolName: "tray.and.arrow.up",
            accessibilityDescription: "Upload"
        )
        let toolTip: String? = NSLocalizedString(
            "Upload file/folder to internal storage Downloads folder",
            comment: ""
        )
    }

    struct UploadToFiles: SubMenuActionItem {
        let title = NSLocalizedString("Upload...", comment: "")
        let tag = Tags.upload.rawValue
        let bootsDevice = false
        let needBootedDevice = true
        let image = NSImage(
            systemSymbolName: "tray.and.arrow.up",
            accessibilityDescription: "Upload"
        )
    }

    struct LocalFiles: SubMenuActionItem {
        let title = NSLocalizedString("Open in Finder", comment: "")
        let tag = Tags.localFiles.rawValue
        let bootsDevice = false
        let needBootedDevice = true
        let image = NSImage(
            systemSymbolName: "folder",
            accessibilityDescription: "Local Files"
        )
    }

    struct Delete: SubMenuActionItem {
        let title = NSLocalizedString("Delete simulator", comment: "")
        let tag = Tags.delete.rawValue
        let bootsDevice = false
        let needBootedDevice = false
        let image = NSImage(
            systemSymbolName: "trash",
            accessibilityDescription: "Delete simulator"
        )
    }

    struct DeleteEmulator: SubMenuActionItem {
        let title = NSLocalizedString("Delete emulator", comment: "")
        let tag = Tags.delete.rawValue
        let bootsDevice = false
        let needBootedDevice = false
        let image = NSImage(
            systemSymbolName: "trash",
            accessibilityDescription: "Delete emulator"
        )
    }

    struct LaunchLogCat: SubMenuActionItem {
        let title = NSLocalizedString("Launch logcat", comment: "")
        let tag = Tags.logcat.rawValue
        let bootsDevice = false
        let needBootedDevice = true
        let image = NSImage(
            systemSymbolName: "terminal",
            accessibilityDescription: "Launch Logcat"
        )
    }
}

extension SubMenuItems {
  static func items(platform: Platform, deviceType: DeviceType) -> [SubMenuItem] {
    switch (platform, deviceType) {
    case (.ios, .physical):
      return [
        CopyName(),
        CopyUDID()
      ]
    case (.ios, .virtual):
      return [
        CopyName(),
        CopyUDID(),

        Separator(),

        SectionTitle(
            title: NSLocalizedString("Local Files", comment: ""),
            needBootedDevice: true
        ),
        UploadToFiles(),
        LocalFiles(),

        Separator(),

        Delete()
      ]
    case (.android, .physical):
      return [
        CopyName(),
        CopyID(),

        Separator(),

        ToggleA11y(),
        Paste(),
        LaunchLogCat(),

        Separator(),

        SectionTitle(
            title: NSLocalizedString("Local Files", comment: ""),
            needBootedDevice: true
        ),
        Upload()
      ]

    case (.android, .virtual):
      return [
        CopyName(),
        CopyID(),

        Separator(),

        ColdBoot(),
        NoAudio(),
        ToggleA11y(),
        Paste(),
        LaunchLogCat(),

        Separator(),

        SectionTitle(
            title: NSLocalizedString("Local Files", comment: ""),
            needBootedDevice: true
        ),
        Upload(),

        Separator(),

        DeleteEmulator()
      ]
    case (.harmony, .virtual):
      return [
        CopyName(),
        CopyID(),

        Separator(),

        DeleteEmulator()
      ]
    case (.harmony, .physical):
      return [
        CopyName(),
        CopyID()
      ]
    }
  }
}
