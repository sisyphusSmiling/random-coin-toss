import "FungibleToken"
import "FlowToken"

/// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
/// DO NOT MODEL AFTER THIS CONTRACT YOU WILL RUG YOURSELF
/// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
///
/// WARNING: This contract is presented as what NOT to do when using implementing randomness in your contract.
///
/// See FLIP 123 for more details: https://github.com/onflow/flips/blob/main/protocol/20230728-commit-reveal.md
/// And the onflow/random-coin-toss repo for implementation context: https://github.com/onflow/random-coin-toss
///
access(all) contract BadCoinToss {

    /// The Vault used by the contract to store funds.
    access(self) let reserve: @FlowToken.Vault

    access(all) event CoinToss(betAmount: UFix64, winningAmount: UFix64)

    /// !!!!!!!!!!!!!!!!!!!!!!!
    /// THIS IS AN ANTI-PATTERN
    /// !!!!!!!!!!!!!!!!!!!!!!!
    ///
    /// In this method, the caller provides a bet and a coin toss is performed. If the coin toss is a 1, the bet is
    /// deposited and the caller receives nothing. If the coin toss is a 0, the bet is deposited and the caller
    /// receives double their original bet.
    /// HOWEVER, a caller can condition the execution of this method on the returned Vault balance, ensuring that only
    /// coin tosses in which they win are executed.
    /// INSTEAD, this process should be split in a commit-reveal pattern, where the caller commits to a bet, and then
    /// reveals the results in a separate transaction.
    ///
    access(all) fun betOnCoinToss(bet: @FungibleToken.Vault): @FungibleToken.Vault {
        let betAmount: UFix64 = bet.balance
        self.reserve.deposit(from: <-bet)

        let coin: UInt8 = self.randomCoin()

        if coin == 1 {
            emit CoinToss(betAmount: betAmount, winningAmount: 0.0)
            return <- FlowToken.createEmptyVault()
        }

        let reward <- self.reserve.withdraw(amount: betAmount * 2.0)

        emit CoinToss(betAmount: betAmount, winningAmount: reward.balance)

        return <- reward
    }

    /// Helper method to retrieve a random UInt64 which is then reduced by bitwise operation to UInt8 value of 1 or 0
    /// and returned.
    ///
    access(all) fun randomCoin(): UInt8 {
        let rand = revertibleRandom()
        return UInt8(rand & 1)
    }

    init() {
        self.reserve <- (FlowToken.createEmptyVault() as! @FlowToken.Vault)
        let seedVault = self.account.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)!
        self.reserve.deposit(
            from: <-seedVault.withdraw(amount: 1000.0)
        )

        self.ReceiptStoragePath = StoragePath(identifier: "CoinTossReceipt_".concat(self.account.address.toString()))!
    }
}
