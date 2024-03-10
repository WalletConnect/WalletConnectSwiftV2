
import Foundation

public class SiweStatementBuilder {
    public static func buildSiweStatement(statement: String?, mergedRecapUrn: RecapUrn?) throws -> String {
        var finalStatement = statement ?? ""

        if let mergedRecapUrn = mergedRecapUrn {
            // Generate recap statement from the merged RecapUrn
            let recapStatement = try RecapStatementBuilder.buildRecapStatement(recapUrn: mergedRecapUrn)
            // Append recap statement to the original statement, if it exists
            if !finalStatement.isEmpty {
                finalStatement += " \(recapStatement)"
            } else {
                finalStatement = recapStatement
            }
        }

        return finalStatement.isEmpty ? "" : "\(finalStatement)"
    }
}

