import Foundation
import Security

public struct Stash {

  enum Action {
    case Insert, Fetch, Delete
  }

  // MARK: - Public methods

  public static func password(service: String, account: String) -> String {
    guard !service.isEmpty && !account.isEmpty else { return "" }

    let query = [
      kSecAttrAccount as String : account,
      kSecAttrService as String : service,
      kSecClass as String : kSecClassGenericPassword]

    return Stash.query(.Fetch, query).1
  }

  public static func setPassword(password: String, service: String, account: String) -> Bool {
    guard !service.isEmpty && !account.isEmpty else { return false }

    let query = [
      kSecAttrAccount as String : account,
      kSecAttrService as String : service,
      kSecClass as String : kSecClassGenericPassword,
      kSecAttrAccessible as String : kSecAttrAccessibleWhenUnlocked]

    return Stash.query(.Insert, query, password).0 == errSecSuccess
  }

  public static func delete(service: String, account: String) -> Bool {
    guard !service.isEmpty && !account.isEmpty else { return false }

    let query = [
      kSecAttrAccount as String: account,
      kSecAttrService as String : service,
      kSecClass as String : kSecClassGenericPassword
    ]

    return Stash.query(.Delete, query).0 == errSecSuccess
  }

  // MARK: - Private methods

  private static func query(action: Action, _ query: [String : AnyObject], _ password: String = "") -> (OSStatus, String) {
    let passwordData = password.dataUsingEncoding(NSUTF8StringEncoding)
    var returnPassword = ""
    var status = SecItemCopyMatching(query, nil)
    var attributes = [String : AnyObject]()

    switch action {
    case .Insert:
      switch status {
      case errSecSuccess:
        attributes[kSecValueData as String] = passwordData
        status = SecItemUpdate(query as CFDictionaryRef, attributes)
      case errSecItemNotFound:
        var query = query
        query[kSecValueData as String] = passwordData
        status = SecItemAdd(query as CFDictionaryRef, nil)
      default: break
      }
    case .Fetch:
      var query = query
      query[kSecReturnData as String] = true
      query[kSecMatchLimit as String] = kSecMatchLimitOne

      var result: CFTypeRef?
      status = SecItemCopyMatching(query, &result)

      if let result = result as? NSData,
        password = String(data: result, encoding: NSUTF8StringEncoding) {
          returnPassword = password
      }
    case .Delete:
      status = SecItemDelete(query)
    }

    return (status, returnPassword)
  }
}