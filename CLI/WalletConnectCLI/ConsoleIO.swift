// 

import Foundation

enum OutputType {
    case error
    case standard
}

class ConsoleIO {
    func writeMessage(_ message: String, to: OutputType = .standard) {
        switch to {
        case .standard:
            print("\(message)")
        case .error:
            fputs("Error: \(message)\n", stderr)
        }
    }
    
    func getInput() -> [String] {
        let keyboard = FileHandle.standardInput
        let inputData = keyboard.availableData
        let strData = String(data: inputData, encoding: String.Encoding.utf8)!
        return strData.trimmingCharacters(in: CharacterSet.newlines).split(separator: " ").map{String($0)}
    }
    
    func printUsage() {
        let usage = """
        pair <wc_pairing_signal>     // approve pairing
        q                               // terminates CLI
        """
        print(usage)
    }
}
