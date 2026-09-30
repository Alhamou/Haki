import Foundation
import CoreAudio
import Combine

public struct AudioInputDevice: Identifiable, Hashable, Equatable {
    public var id: AudioDeviceID
    public let uid: String
    public let name: String
    public var isDefault: Bool
    
    public init(id: AudioDeviceID, uid: String, name: String, isDefault: Bool = false) {
        self.id = id
        self.uid = uid
        self.name = name
        self.isDefault = isDefault
    }
}

public final class AudioDeviceManager: ObservableObject {
    public static let shared = AudioDeviceManager()
    
    @Published public private(set) var availableDevices: [AudioInputDevice] = []
    @Published public private(set) var selectedDevice: AudioInputDevice? {
        didSet {
            if let uid = selectedDevice?.uid {
                UserDefaults.standard.set(uid, forKey: "SelectedAudioInputDeviceUID")
                AppLogger.shared.info("Selected microphone: \(selectedDevice?.name ?? "Unknown") [\(uid)]")
            }
        }
    }
    /// When enabled, the preferred input is picked automatically:
    /// AirPods/Bluetooth first, then USB, falling back to the system default.
    @Published public var autoSelectPreferred: Bool {
        didSet {
            UserDefaults.standard.set(autoSelectPreferred, forKey: "AutoSelectPreferredMicrophone")
        }
    }

    private var isObserving = false

    public init() {
        self.autoSelectPreferred = UserDefaults.standard.object(forKey: "AutoSelectPreferredMicrophone") as? Bool ?? true
        refreshDevices()
        setupListeners()
    }
    
    deinit {
        // Core Audio listeners cleanup if needed
    }
    
    public func refreshDevices() {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        var dataSize: UInt32 = 0
        let sizeStatus = AudioObjectGetPropertyDataSize(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            &dataSize
        )
        guard sizeStatus == noErr else {
            AppLogger.shared.error("Failed to get audio devices size: \(sizeStatus)")
            return
        }
        
        let deviceCount = Int(dataSize) / MemoryLayout<AudioDeviceID>.size
        var deviceIDs = [AudioDeviceID](repeating: 0, count: deviceCount)
        
        let dataStatus = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            &dataSize,
            &deviceIDs
        )
        guard dataStatus == noErr else {
            AppLogger.shared.error("Failed to get audio devices list: \(dataStatus)")
            return
        }
        
        let defaultInputID = getDefaultInputDeviceID()
        var inputs: [AudioInputDevice] = []
        
        for id in deviceIDs {
            if hasInputChannels(deviceID: id) {
                let name = getDeviceName(deviceID: id) ?? "Microphone (\(id))"
                let uid = getDeviceUID(deviceID: id) ?? "\(id)"
                let isDefault = (id == defaultInputID)
                inputs.append(AudioInputDevice(id: id, uid: uid, name: name, isDefault: isDefault))
            }
        }
        
        DispatchQueue.main.async {
            self.availableDevices = inputs

            if self.autoSelectPreferred, let best = inputs.min(by: self.preferenceRank) {
                self.selectedDevice = best
                return
            }

            // Re-resolve selected device
            let savedUID = UserDefaults.standard.string(forKey: "SelectedAudioInputDeviceUID")
            if let savedUID = savedUID, let matching = inputs.first(where: { $0.uid == savedUID }) {
                self.selectedDevice = matching
            } else if let defaultDev = inputs.first(where: { $0.isDefault }) {
                self.selectedDevice = defaultDev
            } else {
                self.selectedDevice = inputs.first
            }
        }
    }

    /// Lower ranks win. AirPods (by name) rank above generic Bluetooth devices,
    /// then USB devices, then everything else.
    private func preferenceRank(_ lhs: AudioInputDevice, _ rhs: AudioInputDevice) -> Bool {
        deviceRank(lhs) < deviceRank(rhs)
    }

    private func deviceRank(_ device: AudioInputDevice) -> Int {
        let name = device.name.lowercased()
        if name.contains("airpods") { return 0 }
        switch transportType(deviceID: device.id) {
        case kAudioDeviceTransportTypeBluetooth, kAudioDeviceTransportTypeBluetoothLE:
            return 1
        case kAudioDeviceTransportTypeUSB:
            return 2
        default:
            return 3
        }
    }

    private func transportType(deviceID: AudioDeviceID) -> UInt32 {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyTransportType,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var transport: UInt32 = 0
        var dataSize = UInt32(MemoryLayout<UInt32>.size)
        let status = AudioObjectGetPropertyData(deviceID, &propertyAddress, 0, nil, &dataSize, &transport)
        return status == noErr ? transport : 0
    }
    
    public func selectDevice(uid: String) {
        if let found = availableDevices.first(where: { $0.uid == uid }) {
            self.selectedDevice = found
        }
    }
    
    public func getDefaultInputDeviceID() -> AudioDeviceID {
        var defaultID: AudioDeviceID = 0
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var dataSize = UInt32(MemoryLayout<AudioDeviceID>.size)
        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            &dataSize,
            &defaultID
        )
        if status != noErr {
            AppLogger.shared.warning("Failed to get default input device ID: \(status)")
        }
        return defaultID
    }
    
    private func hasInputChannels(deviceID: AudioDeviceID) -> Bool {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStreamConfiguration,
            mScope: kAudioObjectPropertyScopeInput,
            mElement: kAudioObjectPropertyElementMain
        )
        var dataSize: UInt32 = 0
        let status = AudioObjectGetPropertyDataSize(deviceID, &propertyAddress, 0, nil, &dataSize)
        guard status == noErr, dataSize > 0 else { return false }
        
        let bufferList = UnsafeMutablePointer<AudioBufferList>.allocate(capacity: Int(dataSize))
        defer { bufferList.deallocate() }
        
        let fetchStatus = AudioObjectGetPropertyData(deviceID, &propertyAddress, 0, nil, &dataSize, bufferList)
        guard fetchStatus == noErr else { return false }
        
        let buffers = UnsafeMutableAudioBufferListPointer(bufferList)
        var totalChannels: UInt32 = 0
        for buffer in buffers {
            totalChannels += buffer.mNumberChannels
        }
        return totalChannels > 0
    }
    
    private func getDeviceName(deviceID: AudioDeviceID) -> String? {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioObjectPropertyName,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var cfName: Unmanaged<CFString>?
        var dataSize = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
        let status = AudioObjectGetPropertyData(
            deviceID,
            &propertyAddress,
            0,
            nil,
            &dataSize,
            &cfName
        )
        return status == noErr ? (cfName?.takeRetainedValue() as String?) : nil
    }
    
    private func getDeviceUID(deviceID: AudioDeviceID) -> String? {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceUID,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var cfUID: Unmanaged<CFString>?
        var dataSize = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
        let status = AudioObjectGetPropertyData(
            deviceID,
            &propertyAddress,
            0,
            nil,
            &dataSize,
            &cfUID
        )
        return status == noErr ? (cfUID?.takeRetainedValue() as String?) : nil
    }
    
    private func setupListeners() {
        guard !isObserving else { return }
        isObserving = true
        
        var devicesAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        AudioObjectAddPropertyListenerBlock(
            AudioObjectID(kAudioObjectSystemObject),
            &devicesAddress,
            DispatchQueue.main
        ) { [weak self] _, _ in
            AppLogger.shared.info("Audio devices changed (connected/disconnected)")
            self?.refreshDevices()
        }
        
        var defaultAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        AudioObjectAddPropertyListenerBlock(
            AudioObjectID(kAudioObjectSystemObject),
            &defaultAddress,
            DispatchQueue.main
        ) { [weak self] _, _ in
            AppLogger.shared.info("System default input device changed")
            self?.refreshDevices()
        }
    }
}
