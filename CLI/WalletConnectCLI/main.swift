// 

import Foundation
import WalletConnect

let consoleIO = ConsoleIO()
consoleIO.printUsage()
var shouldQuit = false
var walletConnect = Client()


while !shouldQuit {
    print(">", terminator: " ")
    let args = consoleIO.getInput()
    guard args.count > 0 else {continue}
    guard let commandType = CommandType(rawValue: args[0]) else {
        consoleIO.writeMessage("unsupported argument")
        continue
    }
    switch commandType {
    case .pair:
        try walletConnect.pair(with: args[1])
    case .quit:
        shouldQuit.toggle()
    case .disconnect:
        break
    case .test :
        break
    }
}
