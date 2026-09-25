import Foundation

struct FindPasswordQuery: KeychainQuery {
    let service: String
    let account: String

    var rawQuery: CFDictionary {
        var query: [String: Any] = [:]
        query[kSecClass as String] = kSecClassGenericPassword
        query[kSecUseDataProtectionKeychain as String] = false
        query[kSecAttrAccount as String] = account
        query[kSecAttrService as String] = service
        return query as CFDictionary
    }
}
