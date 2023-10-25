import Foundation

public protocol SqliteRow {
	/// SqliteRow initialization
	/// - Parameter decoder: SqliteRowDecoder instance
	init(decoder: SqliteRowDecoder) throws
}
