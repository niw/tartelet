import Foundation
import LoggingDomain
import Security

public final class Keychain {
    private let logger: Logger
    private static let keyService = "dk.shape.Tartelet.privateKeys"

    public init(logger: Logger) {
        self.logger = logger
    }
}

// MARK: - Passwords
public extension Keychain {
    func setPassword(_ password: Data, forAccount account: String, belongingToService service: String) -> Bool {
        let findQuery = FindPasswordQuery(service: service, account: account)
        if SecItemCopyMatching(findQuery.rawQuery, nil) == errSecSuccess {
            let updateQuery = UpdatePasswordQuery(password: password)
            let updateStatus = SecItemUpdate(findQuery.rawQuery, updateQuery.rawQuery)
            guard updateStatus == errSecSuccess else {
                logger.error(
                    "Failed updating password for account \(account) belong to service \(service)."
                    + " Received status: \(updateStatus)"
                )
                return false
            }
        } else {
            let addQuery = AddPasswordQuery(
                service: service,
                account: account,
                password: password
            )
            let addStatus = SecItemAdd(addQuery.rawQuery, nil)
            guard addStatus == errSecSuccess else {
                logger.error(
                    "Failed setting password for account \(account) belong to service \(service)."
                    + " Received status: \(addStatus)"
                )
                return false
            }
        }
        return true
    }

    func setPassword(_ password: String, forAccount account: String, belongingToService service: String) -> Bool {
        guard let data = password.data(using: .utf8) else {
            // swiftlint:disable:next line_length
            logger.error("Failed setting password for account \(account) belong to service \(service) because the password could not be converted to UTF-8 data")
            return false
        }
        return setPassword(data, forAccount: account, belongingToService: service)
    }

    func password(forAccount account: String, belongingToService service: String) -> Data? {
        let query = ReadPasswordQuery(service: service, account: account)
        return read(Data.self, usingQuery: query.rawQuery)
    }

    func password(forAccount account: String, belongingToService service: String) -> String? {
        let query = ReadPasswordQuery(service: service, account: account)
        guard let data = read(Data.self, usingQuery: query.rawQuery) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    func removePassword(forAccount account: String, belongingToService service: String) {
        let query = FindPasswordQuery(service: service, account: account)
        SecItemDelete(query.rawQuery)
    }
}

// MARK: - Keys
public extension Keychain {
    // Store exported key data as a generic password in the file-based keychain.
    // Saving a modern SecKey reference would instead select the data protection keychain.
    func setKey(_ key: RSAPrivateKey, withTag tag: String) -> Bool {
        guard let data = key.data else {
            logger.error("Failed exporting RSA private key with tag \(tag).")
            return false
        }
        return setPassword(data, forAccount: tag, belongingToService: Self.keyService)
    }

    func key(withTag tag: String) -> RSAPrivateKey? {
        guard let data: Data = password(forAccount: tag, belongingToService: Self.keyService) else {
            return nil
        }
        return RSAPrivateKey(derRepresentation: data)
    }

    func removeKey(withTag tag: String) {
        removePassword(forAccount: tag, belongingToService: Self.keyService)
    }
}

// MARK: - Helpers
private extension Keychain {
    private func read<T>(_ valueType: T.Type, usingQuery query: CFDictionary) -> T? {
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query, &item)
        guard let value = item as? T, status == errSecSuccess else {
            return nil
        }
        return value
    }
}
