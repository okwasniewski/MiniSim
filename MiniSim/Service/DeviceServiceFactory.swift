import Foundation

class DeviceServiceFactory {
  private static let queue = DispatchQueue(
    label: "com.MiniSim.DeviceService",
    qos: .userInteractive,
    attributes: .concurrent
  )

  static func getDeviceService(device: Device) -> DeviceServiceCommon {
    switch device.platform {
    case .ios:
      return IOSDeviceService(device: device)
    case .android:
      return AndroidDeviceService(device: device)
    case .harmony:
      return HarmonyDeviceService(device: device)
    }
  }

  static func getDeviceDiscoveryService(platform: Platform) -> DeviceDiscoveryService {
    switch platform {
    case .ios:
      return IOSDeviceDiscovery()
    case .android:
      return AndroidDeviceDiscovery()
    case .harmony:
      return HarmonyDeviceDiscovery()
    }
  }

  static func getAllDevices(
    android: Bool,
    iOS: Bool,
    harmony: Bool = false,
    completionQueue: DispatchQueue = .main,
    completion: @escaping ([Device], Error?) -> Void
  ) {
    queue.async {
      do {
        var devicesArray: [Device] = []

        if android {
          try devicesArray.append(contentsOf: AndroidDeviceDiscovery().getDevices())
        }

        if iOS {
          try devicesArray.append(contentsOf: IOSDeviceDiscovery().getDevices())
        }

        if harmony {
          // HarmonyOS support is optional; an unavailable DevEco installation
          // should not hide otherwise usable iOS or Android devices.
          try? devicesArray.append(contentsOf: HarmonyDeviceDiscovery().getDevices())
        }

        completionQueue.async {
          completion(devicesArray, nil)
        }
      } catch {
        completionQueue.async {
          completion([], error)
        }
      }
    }
  }
}
