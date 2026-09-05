import Foundation
import Security

public final class KeychainHelper {
    public static let shared = KeychainHelper()
    
    private let defaultService = "com.haki.app"
    public static let legacyService = "com.arabicdictation.app"
    public static let currentService = "com.haki.app"
    private let defaultAccount = "OpenAI_API_Key"
    
    public init() {}
    
    public func save(
        apiKey: String,
        service: String? = nil,
        account: String? = nil
    ) -> Bool {
        let service = service ?? defaultService
        let account = account ?? defaultAccount
        guard let data = apiKey.data(using: .utf8) else { return false }
        
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account
        ]
        
        // Delete any existing item first
        SecItemDelete(query as CFDictionary)
        
        var attributes = query
        attributes[kSecValueData] = data
        attributes[kSecAttrAccessible] = kSecAttrAccessibleAfterFirstUnlock
        
        let status = SecItemAdd(attributes as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    public func read(
        service: String? = nil,
        account: String? = nil
    ) -> String? {
        let account = account ?? defaultAccount
        
        // If a specific service was explicitly requested, read from it directly
        if let specificService = service {
            return readRaw(service: specificService, account: account)
        }
        
        // 1. Try reading from Haki service
        if let key = readRaw(service: defaultService, account: account) {
            return key
        }
        
        // 2. Backward-compatible migration: Check legacy ArabicDictation Keychain entry
        if let legacyKey = readRaw(service: KeychainHelper.legacyService, account: account) {
            // Migrate to Haki service securely
            _ = save(apiKey: legacyKey, service: defaultService, account: account)
            return legacyKey
        }
        
        return nil
    }
    
    private func readRaw(service: String, account: String) -> String? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecReturnData: kCFBooleanTrue as Any,
            kSecMatchLimit: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }
    
    public func delete(
        service: String? = nil,
        account: String? = nil
    ) -> Bool {
        let account = account ?? defaultAccount
        
        if let specificService = service {
            return deleteRaw(service: specificService, account: account)
        }
        
        // Delete from both current Haki service and legacy service
        let currentStatus = deleteRaw(service: defaultService, account: account)
        let legacyStatus = deleteRaw(service: KeychainHelper.legacyService, account: account)
        return currentStatus || legacyStatus
    }
    
    private func deleteRaw(service: String, account: String) -> Bool {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
}
