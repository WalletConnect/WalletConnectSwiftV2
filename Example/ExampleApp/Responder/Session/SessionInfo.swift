struct SessionInfo {
    let name: String
    let descriptionText: String
    let dappURL: String
    let iconURL: String
}

extension SessionInfo {
    
    static func mock() -> SessionInfo {
        SessionInfo(
            name: "Dapp Name",
            descriptionText: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Mauris at eleifend est, vel porta enim. Praesent non placerat orci. Curabitur orci sem, molestie feugiat enim eu, tincidunt tincidunt est.",
            dappURL: "decentralized.finance",
            iconURL: "https://s2.coinmarketcap.com/static/img/coins/64x64/1.png"
        )
    }
    
    static func mockPancakeSwap() -> SessionInfo {
        SessionInfo(
            name: "🥞 PancakeSwap",
            descriptionText: "Cheaper and faster than Uniswap? Discover PancakeSwap, the leading DEX on Binance Smart Chain (BSC) with the best farms in DeFi and a lottery for CAKE.",
            dappURL: "pancakeswap.finance",
            iconURL: "https://pancakeswap.finance/logo.png"
        )
    }
}
