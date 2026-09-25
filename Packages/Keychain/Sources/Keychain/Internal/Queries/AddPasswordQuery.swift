import Foundation

struct AddPasswordQuery: KeychainQuery {
    let service: String
    let account: String
    let password: Data

    var rawQuery: CFDictionary {
        var query: [String: Any] = [:]
        query[kSecClass as String] = kSecClassGenericPassword
        query[kSecUseDataProtectionKeychain as String] = false
        query[kSecAttrService as String] = service
        query[kSecAttrAccount as String] = account
        query[kSecValueData as String] = password
        return query as CFDictionary
    }
}
