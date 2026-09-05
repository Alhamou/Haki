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
}
