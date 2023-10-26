import Foundation

public protocol SqliteRow {

    /// SqliteRow initialization
	/// - Parameter decoder: SqliteRowDecoder instance
	init(decoder: SqliteRowDecoder) throws

    /// SqliteRow encoding
    /// - Returns: SqliteRowEncoder instance
    func encode() -> SqliteRowEncoder
}
