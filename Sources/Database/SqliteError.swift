import Foundation

public enum SQLiteError: Error {
    case openDatabase(path: String)
    case openDatabaseMemory
    case queryPrepare(statement: String)
    case exec(error: String?)
    case decodeString(index: Int32)
    case stringIsNotBase64
    case stringIsNotTimestamp
}
