import Foundation
import Security

public final class KeychainHelper {
    public static let shared = KeychainHelper()
    
    private let defaultService = "com.arabicdictation.app"
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
        let service = service ?? defaultService
        let account = account ?? defaultAccount
        
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
        let service = service ?? defaultService
        let account = account ?? defaultAccount
        
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
}
