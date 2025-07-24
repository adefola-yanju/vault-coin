;; VaultCoin Protocol: Advanced Bitcoin-Collateralized Stablecoin Infrastructure
;; 
;; Revolutionary DeFi protocol that transforms Bitcoin holdings into productive liquidity through
;; sophisticated collateralized debt positions. Users can leverage their BTC to mint USD-pegged
;; stablecoins while maintaining exposure to Bitcoin's long-term value appreciation.
;;
;; This protocol bridges traditional Bitcoin holding strategies with modern DeFi yield generation,
;; enabling capital efficiency without sacrificing the security of Bitcoin-denominated assets.
;; Built on Stacks for native Bitcoin integration and enhanced smart contract capabilities.

;; ERROR CODES & CONSTANTS

;; System Error Definitions
(define-constant ERR-NOT-AUTHORIZED (err u1000))
(define-constant ERR-INSUFFICIENT-COLLATERAL (err u1001))
(define-constant ERR-POSITION-NOT-FOUND (err u1002))
(define-constant ERR-UNDERCOLLATERALIZED (err u1003))
(define-constant ERR-MINIMUM-LOAN-REQUIRED (err u1004))
(define-constant ERR-INSUFFICIENT-DEBT (err u1005))
(define-constant ERR-PRICE-EXPIRED (err u1006))
(define-constant ERR-PROTOCOL-PAUSED (err u1007))
(define-constant ERR-INVALID-AMOUNT (err u1008))
(define-constant ERR-NO-PRICE-DATA (err u1009))

;; Protocol Configuration Parameters
(define-constant COLLATERAL-RATIO u150)           ;; 150% minimum collateralization (1.5x leverage)
(define-constant LIQUIDATION-THRESHOLD u120)      ;; 120% liquidation trigger point
(define-constant LIQUIDATION-PENALTY u10)         ;; 10% liquidation penalty for protocol fees
(define-constant MINIMUM_LOAN_AMOUNT u100000000)  ;; 100 VaultCoin minimum (8 decimal precision)
(define-constant PRICE_EXPIRY u86400)             ;; 24-hour price feed validity window
(define-constant INTEREST_RATE_PER_BLOCK u5)      ;; 0.0005% per block (~10% APR)
(define-constant INTEREST_RATE_DENOMINATOR u1000000) ;; Interest calculation precision factor

;; STATE VARIABLES & DATA STRUCTURES

;; Protocol Administration
(define-data-var protocol-owner principal tx-sender)
(define-data-var protocol-paused bool false)

;; Global Protocol Metrics
(define-data-var total-debt uint u0)              ;; Aggregate system debt in VaultCoins
(define-data-var total-collateral uint u0)        ;; Total BTC collateral locked (satoshis)
(define-data-var stability-fee uint u0)           ;; Accumulated protocol fees
(define-data-var last-accrual-block uint stacks-block-height) ;; Last interest calculation block

;; Oracle Price Feed
(define-data-var btc-price-in-usd (optional {price: uint, timestamp: uint}) none)
(define-data-var current-time uint u0)            ;; Mock timestamp for testing environments

;; User Position Tracking
(define-map positions principal {
  collateral: uint,        ;; BTC collateral amount (satoshis)
  debt: uint,             ;; Outstanding VaultCoin debt
  last-update-block: uint ;; Position's last interest accrual block
})

;; VaultCoin Stablecoin Token
(define-fungible-token vault-coin)

;; ADMINISTRATIVE FUNCTIONS

;; Transfer protocol ownership to new principal
(define-public (set-protocol-owner (new-owner principal))
  (begin
    (asserts! (is-eq tx-sender (var-get protocol-owner)) ERR-NOT-AUTHORIZED)
    (ok (var-set protocol-owner new-owner))
  )
)

;; Emergency protocol pause/unpause mechanism
(define-public (pause-protocol (paused bool))
  (begin
    (asserts! (is-eq tx-sender (var-get protocol-owner)) ERR-NOT-AUTHORIZED)
    (ok (var-set protocol-paused paused))
  )
)

;; Update BTC/USD price feed from trusted oracle
(define-public (update-btc-price (price uint) (timestamp uint))
  (begin
    (asserts! (is-eq tx-sender (var-get protocol-owner)) ERR-NOT-AUTHORIZED)
    (asserts! (> price u0) ERR-INVALID-AMOUNT)
    (var-set btc-price-in-usd (some {price: price, timestamp: timestamp}))
    (ok true)
  )
)

;; Set current timestamp for testing environments
(define-public (set-current-time (time uint))
  (begin
    (asserts! (is-eq tx-sender (var-get protocol-owner)) ERR-NOT-AUTHORIZED)
    (ok (var-set current-time time))
  )
)

;; UTILITY & CALCULATION FUNCTIONS

;; Calculate USD value of BTC collateral
(define-private (collateral-value (collateral-amount uint) (price uint))
  (* collateral-amount price)
)