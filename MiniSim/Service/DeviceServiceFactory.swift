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
    }
  }

  static func getDeviceDiscoveryService(platform: Platform) -> DeviceDiscoveryService {
    switch platform {
    case .ios:
      return IOSDeviceDiscovery()
    case .android:
      return AndroidDeviceDiscovery()
    }
  }

  static func getAllDevices(
    android: Bool,
    iOS: Bool,
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
