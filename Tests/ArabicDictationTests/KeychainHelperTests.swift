import XCTest
@testable import ArabicDictation

final class KeychainHelperTests: XCTestCase {
    let testService = "com.arabicdictation.test"
    let testAccount = "TestAccount_\(UUID().uuidString)"
    let testKey = "sk-test-sample-key-12345"
    
    override func tearDown() {
        _ = KeychainHelper.shared.delete(service: testService, account: testAccount)
        super.tearDown()
    }
    
    func testKeychainSaveReadDelete() {
        let helper = KeychainHelper.shared
        
        // 1. Initial read should be nil
        XCTAssertNil(helper.read(service: testService, account: testAccount))
        
        // 2. Save key
        let saveSuccess = helper.save(apiKey: testKey, service: testService, account: testAccount)
        XCTAssertTrue(saveSuccess, "Failed to save key into Keychain")
        
        // 3. Read back
        let retrieved = helper.read(service: testService, account: testAccount)
        XCTAssertEqual(retrieved, testKey, "Retrieved key does not match saved key")
        
        // 4. Overwrite/Update key
        let updatedKey = "sk-updated-test-key-67890"
        let updateSuccess = helper.save(apiKey: updatedKey, service: testService, account: testAccount)
        XCTAssertTrue(updateSuccess, "Failed to update key in Keychain")
        
        let retrievedUpdated = helper.read(service: testService, account: testAccount)
        XCTAssertEqual(retrievedUpdated, updatedKey)
        
        // 5. Delete key
        let deleteSuccess = helper.delete(service: testService, account: testAccount)
        XCTAssertTrue(deleteSuccess)
        
        // 6. Verify deleted
        XCTAssertNil(helper.read(service: testService, account: testAccount))
    }
    
    func testKeychainBackwardCompatibleMigration() {
        let helper = KeychainHelper.shared
        let migrationAccount = "MigrationTest_\(UUID().uuidString)"
        let originalKey = "sk-legacy-key-migration-test"
        
        defer {
            _ = helper.delete(service: KeychainHelper.currentService, account: migrationAccount)
            _ = helper.delete(service: KeychainHelper.legacyService, account: migrationAccount)
        }
        
        // Ensure both are empty initially
        XCTAssertNil(helper.read(service: KeychainHelper.currentService, account: migrationAccount))
        XCTAssertNil(helper.read(service: KeychainHelper.legacyService, account: migrationAccount))
        
        // 1. Save directly to legacy service (simulating existing ArabicDictation user)
        let savedToLegacy = helper.save(apiKey: originalKey, service: KeychainHelper.legacyService, account: migrationAccount)
        XCTAssertTrue(savedToLegacy)
        
        // 2. Call read with default service (simulating Haki app launch)
        let migratedKey = helper.read(account: migrationAccount)
        XCTAssertEqual(migratedKey, originalKey, "Failed to read legacy key during migration")
        
        // 3. Verify key is now persisted under new Haki service
        let hakiStoredKey = helper.read(service: KeychainHelper.currentService, account: migrationAccount)
        XCTAssertEqual(hakiStoredKey, originalKey, "Key was not migrated to Haki service")
    }
}
