;; --------------------------------------------------
;; RENTIFY: Decentralized Rental & Escrow Platform
;; --------------------------------------------------

(define-constant ERR-NOT-OWNER (err u100))
(define-constant ERR-NOT-RENTED (err u101))
(define-constant ERR-NOT-AUTHORIZED (err u102))
(define-constant ERR-INVALID-DURATION (err u103))
(define-constant ERR-ALREADY-RENTED (err u104))
(define-constant ERR-DISPUTE-OPEN (err u105))

(define-data-var item-count uint u0)

(define-map items
  {id: uint}
  {owner: principal,
   name: (string-ascii 60),
   daily-rate: uint,
   available: bool}
)

(define-map rentals
  {item-id: uint}
  {renter: principal,
   start-date: uint,
   end-date: uint,
   total-cost: uint,
   completed: bool,
   in-dispute: bool}
)

(define-map users
  {user: principal}
  {total-rentals: uint,
   reputation: int}
)

(define-map dao-stakes
  {member: principal}
  {amount: uint,
   reputation: uint}
)

(define-map disputes
  {item-id: uint}
  {raised-by: principal,
   votes-for-owner: uint,
   votes-for-renter: uint,
   resolved: bool}
)

(define-public (stake (amount uint))
  (let ((staker (map-get? dao-stakes { member: tx-sender })))
    (if (is-some staker)
        (let ((old (unwrap! staker ERR-NOT-AUTHORIZED)))
          (map-set dao-stakes { member: tx-sender }
            { amount: (+ (get amount old) amount), reputation: (+ (get reputation old) (/ amount u100)) }
          ))
        (map-set dao-stakes { member: tx-sender }
          { amount: amount, reputation: (/ amount u100) }
        )
    )
    (ok "DAO stake recorded")
  )
)

;; --------------------------------------------------
;; ITEM LISTING AND MANAGEMENT
;; --------------------------------------------------

(define-public (list-item (name (string-ascii 60)) (daily-rate uint))
  (begin
    (var-set item-count (+ (var-get item-count) u1))
    (map-set items { id: (var-get item-count) }
      {
        owner: tx-sender,
        name: name,
        daily-rate: daily-rate,
        available: true
      }
    )
    (ok (var-get item-count))
  )
)

(define-public (update-availability (item-id uint) (status bool))
  (let ((item (unwrap! (map-get? items { id: item-id }) ERR-NOT-OWNER)))
    (asserts! (is-eq (get owner item) tx-sender) ERR-NOT-OWNER)
    (map-set items { id: item-id } (merge item { available: status }))
    (ok "Availability updated")
  )
)

;; --------------------------------------------------
;; RENTING & ESCROW
;; --------------------------------------------------

(define-public (rent-item (item-id uint) (days uint))
  (let ((item (unwrap! (map-get? items { id: item-id }) ERR-NOT-OWNER)))
    (asserts! (> days u0) ERR-INVALID-DURATION)
    (asserts! (is-eq (get available item) true) ERR-ALREADY-RENTED)
    (let ((cost (* (get daily-rate item) days)))
      (try! (stx-transfer? cost tx-sender (as-contract tx-sender)))
      (map-set rentals { item-id: item-id }
        {
          renter: tx-sender,
          start-date: stacks-block-height,
          end-date: (+ stacks-block-height days),
          total-cost: cost,
          completed: false,
          in-dispute: false
        }
      )
      (map-set items { id: item-id } (merge item { available: false }))
      (ok "Item rented and funds locked in escrow")
    )
  )
)

;; --------------------------------------------------
;; RETURN & RELEASE
;; --------------------------------------------------

(define-private (update-reputation (user principal) (change int))
  (let ((u (map-get? users { user: user })))
    (if (is-some u)
        (let ((old (unwrap! u ERR-NOT-AUTHORIZED)))
          (map-set users { user: user }
            {
              total-rentals: (+ (get total-rentals old) u1),
              reputation: (+ (get reputation old) change)
            }
          )
          (ok true)
        )
        (begin
          (map-set users { user: user }
            {
              total-rentals: u1,
              reputation: change
            }
          )
          (ok true)
        )
    )
  )
)

(define-public (return-item (item-id uint))
  (let ((rental (unwrap! (map-get? rentals { item-id: item-id }) ERR-NOT-RENTED)))
    (asserts! (is-eq (get renter rental) tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (>= stacks-block-height (get end-date rental)) ERR-NOT-RENTED)
    (let ((item (unwrap! (map-get? items { id: item-id }) ERR-NOT-OWNER)))
      (match (stx-transfer? (get total-cost rental) (as-contract tx-sender) (get owner item))
        success
          (begin
            (map-set rentals { item-id: item-id } (merge rental { completed: true }))
            (map-set items { id: item-id } (merge item { available: true }))
            (try! (update-reputation tx-sender 5))
            (try! (update-reputation (get owner item) 5))
            (ok "Rental completed and funds released")
          )
        error (err error))
    )
  )
)

;; --------------------------------------------------
;; DISPUTE & DAO ARBITRATION
;; --------------------------------------------------

(define-public (raise-dispute (item-id uint))
  (let ((rental (unwrap! (map-get? rentals { item-id: item-id }) ERR-NOT-RENTED)))
    (asserts! (is-eq (get renter rental) tx-sender) ERR-NOT-AUTHORIZED)
    (map-set disputes { item-id: item-id }
      {
        raised-by: tx-sender,
        votes-for-owner: u0,
        votes-for-renter: u0,
        resolved: false
      }
    )
    (map-set rentals { item-id: item-id } (merge rental { in-dispute: true }))
    (ok "Dispute raised")
  )
)

(define-public (vote-dispute (item-id uint) (vote-for-owner bool))
  (let ((staker (unwrap! (map-get? dao-stakes { member: tx-sender }) ERR-NOT-AUTHORIZED))
        (dispute (unwrap! (map-get? disputes { item-id: item-id }) ERR-DISPUTE-OPEN)))
    (asserts! (is-eq (get resolved dispute) false) ERR-DISPUTE-OPEN)
    (if vote-for-owner
        (map-set disputes { item-id: item-id } (merge dispute { votes-for-owner: (+ (get votes-for-owner dispute) (get reputation staker)) }))
        (map-set disputes { item-id: item-id } (merge dispute { votes-for-renter: (+ (get votes-for-renter dispute) (get reputation staker)) }))
    )
    (ok "Vote recorded")
  )
)

(define-public (resolve-dispute (item-id uint))
  (let ((dispute (unwrap! (map-get? disputes { item-id: item-id }) ERR-DISPUTE-OPEN)))
    (let ((rental (unwrap! (map-get? rentals { item-id: item-id }) ERR-NOT-RENTED)))
      (let ((item (unwrap! (map-get? items { id: item-id }) ERR-NOT-OWNER)))
        (if (> (get votes-for-owner dispute) (get votes-for-renter dispute))
          (begin
            (try! (stx-transfer? (get total-cost rental) (as-contract tx-sender) (get owner item)))
            (try! (update-reputation (get owner item) 10))
            (try! (update-reputation (get renter rental) -5))
          )
          (begin
            (try! (stx-transfer? (get total-cost rental) (as-contract tx-sender) (get renter rental)))
            (try! (update-reputation (get renter rental) 10))
            (try! (update-reputation (get owner item) -5))
          )
        )
        (map-set disputes { item-id: item-id } (merge dispute { resolved: true }))
        (ok "Dispute resolved and funds released")
      )
    )
  )
)

;; --------------------------------------------------
;; REPUTATION HANDLER
;; --------------------------------------------------

(define-read-only (get-reputation (user principal))
  (get reputation (default-to { total-rentals: u0, reputation: 0 } (map-get? users { user: user })))
)
