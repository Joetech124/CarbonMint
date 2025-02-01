;; CarbonMint: A contract for minting, transferring, and burning carbon credits.

;; Contract owner
(define-constant contract-owner tx-sender)

;; Define traits
(define-trait carbon-trait
  (
    (mint-carbon (principal uint) (response bool uint))
    (burn-carbon (uint) (response bool uint))
    (transfer-carbon (principal uint) (response bool uint))
    (get-carbon-balance (principal) (response uint uint))
  )
)

(define-data-var total-carbon-credits uint u0)

(define-map carbon-balances 
  { owner: principal }
  { balance: uint })

(define-map credit-certifications
  { id: uint }
  { validator: principal, amount: uint })

;; Helper function to get balance safely
(define-private (get-balance-or-default (account principal))
  (match (map-get? carbon-balances {owner: account})
    balance (get balance balance)
    u0))

;; Mint new carbon credits. Only callable by the contract owner.
(define-public (mint-carbon (recipient principal) (amount uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) (err u403))
    (asserts! (> amount u0) (err u1))
    (asserts! (is-ok (principal-destruct? recipient)) (err u3))
    (let ((current-balance (get-balance-or-default recipient)))
      (map-set carbon-balances 
        { owner: recipient } 
        { balance: (+ current-balance amount) })
      (var-set total-carbon-credits (+ (var-get total-carbon-credits) amount))
      (ok true))))

;; Burn carbon credits, removing them from the supply.
(define-public (burn-carbon (amount uint))
  (let ((sender tx-sender)
        (current-balance (get-balance-or-default sender)))
    (asserts! (> amount u0) (err u1))
    (asserts! (>= current-balance amount) (err u2))
    (map-set carbon-balances 
      { owner: sender } 
      { balance: (- current-balance amount) })
    (var-set total-carbon-credits (- (var-get total-carbon-credits) amount))
    (ok true)))

;; Transfer carbon credits between two users.
(define-public (transfer-carbon (recipient principal) (amount uint))
  (let ((sender tx-sender))
    (asserts! (> amount u0) (err u1))
    (asserts! (is-ok (principal-destruct? recipient)) (err u3))
    (let ((sender-balance (get-balance-or-default sender))
          (recipient-balance (get-balance-or-default recipient)))
      (asserts! (>= sender-balance amount) (err u2))
      (map-set carbon-balances 
        { owner: sender } 
        { balance: (- sender-balance amount) })
      (map-set carbon-balances 
        { owner: recipient } 
        { balance: (+ recipient-balance amount) })
      (ok true))))

;; Certify a carbon credit burn by a validator.
(define-public (certify-carbon (id uint) (validator principal) (amount uint))
  (begin
    (asserts! (> amount u0) (err u1))
    (asserts! (> id u0) (err u4))
    (asserts! (is-none (map-get? credit-certifications { id: id })) (err u2))
    (asserts! (is-ok (principal-destruct? validator)) (err u3))
    (map-set credit-certifications { id: id } { validator: validator, amount: amount })
    (ok true)
  )
)

;; Helper function to validate principal
(define-private (validate-principal (user principal))
  (if (is-ok (principal-destruct? user))
      (ok true)
      (err u3)))

;; Read-only function: Get a user's carbon balance.
(define-read-only (get-carbon-balance (user principal))
  (ok (get-balance-or-default user)))

;; Read-only function: Get total carbon credits minted.
(define-read-only (get-total-carbon-credits)
  (ok (var-get total-carbon-credits))
)
