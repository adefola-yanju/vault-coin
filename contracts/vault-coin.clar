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

;; Determine minimum BTC collateral required for debt amount
(define-private (required-collateral (debt-amount uint) (price uint))
  (/ (* debt-amount COLLATERAL-RATIO) (/ price u100))
)

;; Verify if user position meets safety requirements
(define-private (is-position-safe (user principal) (btc-price uint))
  (let (
    (position (unwrap! (map-get? positions user) false))
    (debt (get debt position))
    (collateral (get collateral position))
    (collateral-value-usd (collateral-value collateral btc-price))
    (min-collateral-value-usd (/ (* debt COLLATERAL-RATIO) u100))
  )
  (>= collateral-value-usd min-collateral-value-usd))
)

;; Calculate compound interest for given debt and block duration
(define-private (calculate-interest (debt uint) (blocks-passed uint))
  (/ (* debt (* blocks-passed INTEREST_RATE_PER_BLOCK)) INTEREST_RATE_DENOMINATOR)
)

;; Retrieve current BTC price with staleness validation
(define-read-only (get-current-price)
  (match (var-get btc-price-in-usd)
    price-data (let (
      (price (get price price-data))
      (timestamp (get timestamp price-data))
      (current-timestamp (var-get current-time))
    )
      (if (>= (- current-timestamp timestamp) PRICE_EXPIRY)
        ERR-PRICE-EXPIRED
        (if (<= price u0)
          ERR-PRICE-EXPIRED
          (ok price)
        )
      ))
    ERR-NO-PRICE-DATA)
)

;; INTEREST ACCRUAL SYSTEM

;; Accrue interest on total system debt
(define-private (accrue-global-interest)
  (let (
    (current-block stacks-block-height)
    (last-block (var-get last-accrual-block))
    (blocks-passed (- current-block last-block))
    (total-system-debt (var-get total-debt))
    (interest-accrued (calculate-interest total-system-debt blocks-passed))
  )
    (begin
      (if (> blocks-passed u0)
        (begin
          (var-set stability-fee (+ (var-get stability-fee) interest-accrued))
          (var-set total-debt (+ total-system-debt interest-accrued))
          (var-set last-accrual-block current-block)
        )
        false
      )
      true
    )
  )
)

;; Accrue interest on individual user position
(define-private (accrue-position-interest (user principal))
  (let (
    (position (unwrap! (map-get? positions user) {debt: u0, collateral: u0, last-update-block: stacks-block-height}))
    (debt (get debt position))
    (collateral (get collateral position))
    (last-update (get last-update-block position))
    (blocks-passed (- stacks-block-height last-update))
    (interest-accrued (calculate-interest debt blocks-passed))
    (new-debt (+ debt interest-accrued))
    (updated-position {
      collateral: collateral,
      debt: new-debt,
      last-update-block: stacks-block-height
    })
  )
    (begin
      (if (> blocks-passed u0)
        (map-set positions user updated-position)
        false
      )
      updated-position
    )
  )
)

;; CORE USER FUNCTIONS

;; Create new collateralized debt position or expand existing position
(define-public (create-position (btc-amount uint) (stable-amount uint))
  (begin
    (asserts! (not (var-get protocol-paused)) ERR-PROTOCOL-PAUSED)
    (asserts! (>= btc-amount u0) ERR-INVALID-AMOUNT)
    (asserts! (>= stable-amount MINIMUM_LOAN_AMOUNT) ERR-MINIMUM-LOAN-REQUIRED)
    
    ;; Validate current BTC price availability
    (let (
      (btc-price (try! (get-current-price)))
      (user tx-sender)
      (existing-position (map-get? positions user))
    )
      (begin
        ;; Apply global interest accrual
        (accrue-global-interest)
        
        ;; Handle existing position interest or create new position baseline
        (let (
          (current-position 
            (if (is-some existing-position)
              (accrue-position-interest user)
              {collateral: u0, debt: u0, last-update-block: stacks-block-height}
            )
          )
        )
        
        ;; Calculate expanded position parameters
        (let (
          (old-collateral (get collateral current-position))
          (old-debt (get debt current-position))
          (new-collateral (+ old-collateral btc-amount))
          (new-debt (+ old-debt stable-amount))
          (min-required-collateral (required-collateral new-debt btc-price))
        )
          (begin
            ;; Validate collateralization requirements
            (asserts! (>= (collateral-value new-collateral btc-price) min-required-collateral) ERR-INSUFFICIENT-COLLATERAL)
            
            ;; Update user position
            (map-set positions user {
              collateral: new-collateral,
              debt: new-debt,
              last-update-block: stacks-block-height
            })
            
            ;; Update global protocol metrics
            (var-set total-collateral (+ (var-get total-collateral) btc-amount))
            (var-set total-debt (+ (var-get total-debt) stable-amount))
            
            ;; Mint VaultCoins to user
            (ft-mint? vault-coin stable-amount user)
          )
        ))
      )
    )
  )
)

;; Add additional BTC collateral to existing position
(define-public (add-collateral (btc-amount uint))
  (let (
    (user tx-sender)
    (position (unwrap! (map-get? positions user) ERR-POSITION-NOT-FOUND))
  )
    (begin
      (asserts! (not (var-get protocol-paused)) ERR-PROTOCOL-PAUSED)
      (asserts! (> btc-amount u0) ERR-INVALID-AMOUNT)
      
      ;; Apply global interest accrual
      (accrue-global-interest)
      
      ;; Update position with accumulated interest
      (let (
        (updated-position (accrue-position-interest user))
        (new-debt (get debt updated-position))
        (current-collateral (get collateral updated-position))
        (new-collateral (+ current-collateral btc-amount))
      )
        (begin
          ;; Update position with additional collateral
          (map-set positions user {
            collateral: new-collateral,
            debt: new-debt,
            last-update-block: stacks-block-height
          })
          
          ;; Update global collateral tracking
          (var-set total-collateral (+ (var-get total-collateral) btc-amount))
          
          (ok true)
        )
      )
    )
  )
)

;; Repay VaultCoin debt and reduce position liability
(define-public (repay-debt (amount uint))
  (let (
    (user tx-sender)
    (position (unwrap! (map-get? positions user) ERR-POSITION-NOT-FOUND))
  )
    (begin
      (asserts! (not (var-get protocol-paused)) ERR-PROTOCOL-PAUSED)
      (asserts! (> amount u0) ERR-INVALID-AMOUNT)
      
      ;; Apply global interest accrual
      (accrue-global-interest)
      
      ;; Update position with accumulated interest
      (let (
        (updated-position (accrue-position-interest user))
        (current-debt (get debt updated-position))
        (collateral (get collateral updated-position))
        (repay-amount (if (> amount current-debt) current-debt amount))
        (new-debt (- current-debt repay-amount))
      )
        (begin
          (asserts! (<= repay-amount current-debt) ERR-INSUFFICIENT-DEBT)
          
          ;; Burn VaultCoins from user wallet
          (try! (ft-burn? vault-coin repay-amount user))
          
          ;; Handle position closure or debt reduction
          (if (is-eq new-debt u0)
            ;; Complete debt repayment: return collateral and close position
            (begin
              (map-delete positions user)
              (var-set total-collateral (- (var-get total-collateral) collateral))
            )
            ;; Partial repayment: update position with reduced debt
            (map-set positions user {
              collateral: collateral,
              debt: new-debt,
              last-update-block: stacks-block-height
            })
          )
          
          ;; Update global debt tracking
          (var-set total-debt (- (var-get total-debt) repay-amount))
          
          (ok true)
        )
      )
    )
  )
)

;; Withdraw BTC collateral while maintaining safe collateralization
(define-public (withdraw-collateral (btc-amount uint))
  (begin
    (asserts! (not (var-get protocol-paused)) ERR-PROTOCOL-PAUSED)
    (asserts! (> btc-amount u0) ERR-INVALID-AMOUNT)
    
    ;; Validate current BTC price availability
    (let (
      (btc-price (try! (get-current-price)))
      (user tx-sender)
    )
      (begin
        ;; Apply global interest accrual
        (accrue-global-interest)
        
        ;; Update position with accumulated interest
        (let (
          (updated-position (accrue-position-interest user))
          (current-debt (get debt updated-position))
          (current-collateral (get collateral updated-position))
          (new-collateral (- current-collateral btc-amount))
          (min-required-collateral (required-collateral current-debt btc-price))
        )
          (begin
            (asserts! (<= btc-amount current-collateral) ERR-INSUFFICIENT-COLLATERAL)
            (asserts! (>= (collateral-value new-collateral btc-price) min-required-collateral) ERR-UNDERCOLLATERALIZED)
            
            ;; Update position with reduced collateral
            (map-set positions user {
              collateral: new-collateral,
              debt: current-debt,
              last-update-block: stacks-block-height
            })
            
            ;; Update global collateral tracking
            (var-set total-collateral (- (var-get total-collateral) btc-amount))
            
            (ok true)
          )
        )
      )
    )
  )
)