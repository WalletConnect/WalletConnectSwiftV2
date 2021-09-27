struct ActiveSessionItem {
    let dappName: String
    let dappURL: String
    let iconURL: String
}

extension ActiveSessionItem {
    
    static func mockList() -> [ActiveSessionItem] {
        [mockPancakeSwap(), mockUniswap(), mockSushiSwap()]
    }
    
    static func mockPancakeSwap() -> ActiveSessionItem {
        ActiveSessionItem(
            dappName: "PancakeSwap",
            dappURL: "pancakeswap.finance",
            iconURL: "https://pancakeswap.finance/logo.png"
        )
    }
    
    static func mockUniswap() -> ActiveSessionItem {
        ActiveSessionItem(
            dappName: "Uniswap",
            dappURL: "app.uniswap.org",
            iconURL: "https://s2.coinmarketcap.com/static/img/coins/64x64/7083.png"
        )
    }
    
    static func mockSushiSwap() -> ActiveSessionItem {
        ActiveSessionItem(
            dappName: "Sushi Swap",
            dappURL: "app.sushi.com",
            iconURL: "https://s2.coinmarketcap.com/static/img/coins/64x64/6758.png"
        )
    }
}
