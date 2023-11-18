import "FungibleToken"
import "FlowToken"

import "BadCoinToss"

/// Bets the given amount of $FLOW on a coin toss, conditioning the transaction on a winning result.
///
transaction(betAmount: UFix64) {

    prepare(signer: AuthAccount) {
        // Withdraw my bet amount from my FlowToken vault
        let flowVault = signer.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)!
        let bet <- flowVault.withdraw(amount: betAmount)
        
        // Perform a degen coin toss
        let winnings <- BadCoinToss.betOnCoinToss(bet: <-bet)

        // Condition transaction on doubling the bet
        assert(
            winnings.balance >= betAmount,
            message: "Lost the coin toss, try again!"
        )

        // Deposit winnings back to my FlowToken vault
        flowVault.deposit(from: <-winnings)
    }
}
