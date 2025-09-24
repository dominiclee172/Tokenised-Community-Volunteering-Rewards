(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_INVALID_ACTIVITY (err u101))
(define-constant ERR_ACTIVITY_NOT_FOUND (err u102))
(define-constant ERR_INVALID_VOLUNTEER (err u103))
(define-constant ERR_REWARD_ALREADY_CLAIMED (err u104))
(define-constant ERR_INSUFFICIENT_TOKENS (err u105))
(define-constant ERR_INVALID_AMOUNT (err u106))
(define-constant ERR_ACTIVITY_EXPIRED (err u107))
(define-constant ERR_INVALID_DURATION (err u108))
(define-constant ERR_NOT_VERIFIED (err u109))
(define-constant ERR_INVALID_MULTIPLIER (err u110))

(define-fungible-token community-token)

(define-data-var token-name (string-ascii 32) "Community Volunteer Token")
(define-data-var token-symbol (string-ascii 10) "CVT")
(define-data-var total-supply uint u1000000)
(define-data-var next-activity-id uint u1)
(define-data-var base-reward-rate uint u100)
(define-data-var activity-count uint u0)
(define-data-var total-volunteers uint u0)

(define-map activities 
  { activity-id: uint }
  {
    organizer: principal,
    title: (string-ascii 100),
    description: (string-ascii 500),
    reward-per-hour: uint,
    start-block: uint,
    end-block: uint,
    max-participants: uint,
    current-participants: uint,
    total-hours: uint,
    verified: bool,
    completed: bool
  }
)

(define-map volunteer-records
  { volunteer: principal, activity-id: uint }
  {
    hours-contributed: uint,
    verified: bool,
    reward-claimed: bool,
    reward-amount: uint,
    participation-block: uint
  }
)

(define-map volunteer-stats
  { volunteer: principal }
  {
    total-activities: uint,
    total-hours: uint,
    total-rewards: uint,
    reputation-score: uint,
    verification-count: uint
  }
)

(define-map organizer-permissions
  { organizer: principal }
  {
    verified: bool,
    activities-created: uint,
    reputation: uint
  }
)

(define-map activity-categories
  { category: (string-ascii 50) }
  {
    multiplier: uint,
    active: bool
  }
)

(define-read-only (get-token-name)
  (ok (var-get token-name))
)

(define-read-only (get-token-symbol)
  (ok (var-get token-symbol))
)

(define-read-only (get-decimals)
  (ok u6)
)

(define-read-only (get-balance (who principal))
  (ok (ft-get-balance community-token who))
)

(define-read-only (get-total-supply)
  (ok (ft-get-supply community-token))
)

(define-read-only (get-activity (activity-id uint))
  (map-get? activities { activity-id: activity-id })
)

(define-read-only (get-volunteer-record (volunteer principal) (activity-id uint))
  (map-get? volunteer-records { volunteer: volunteer, activity-id: activity-id })
)

(define-read-only (get-volunteer-stats (volunteer principal))
  (map-get? volunteer-stats { volunteer: volunteer })
)

(define-read-only (get-organizer-permissions (organizer principal))
  (map-get? organizer-permissions { organizer: organizer })
)

(define-read-only (get-activity-category (category (string-ascii 50)))
  (map-get? activity-categories { category: category })
)

(define-read-only (calculate-reward (activity-id uint) (hours uint))
  (match (get-activity activity-id)
    activity-data 
      (let (
        (reward-per-hour (get reward-per-hour activity-data))
        (base-reward (* hours reward-per-hour))
      )
      (ok base-reward)
      )
    ERR_ACTIVITY_NOT_FOUND
  )
)

(define-read-only (is-activity-active (activity-id uint))
  (match (get-activity activity-id)
    activity-data
      (let (
        (current-block stacks-block-height)
        (start-block (get start-block activity-data))
        (end-block (get end-block activity-data))
      )
      (and (>= current-block start-block) (<= current-block end-block))
      )
    false
  )
)

(define-public (transfer (amount uint) (from principal) (to principal) (memo (optional (buff 34))))
  (begin
    (asserts! (or (is-eq from tx-sender) (is-eq from CONTRACT_OWNER)) ERR_NOT_AUTHORIZED)
    (ft-transfer? community-token amount from to)
  )
)

(define-public (mint (amount uint) (to principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)
    (ft-mint? community-token amount to)
  )
)

(define-public (burn (amount uint) (from principal))
  (begin
    (asserts! (or (is-eq tx-sender from) (is-eq tx-sender CONTRACT_OWNER)) ERR_NOT_AUTHORIZED)
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)
    (ft-burn? community-token amount from)
  )
)

(define-public (create-activity 
  (title (string-ascii 100))
  (description (string-ascii 500))
  (reward-per-hour uint)
  (duration-blocks uint)
  (max-participants uint)
)
  (let (
    (activity-id (var-get next-activity-id))
    (current-block stacks-block-height)
    (end-block (+ current-block duration-blocks))
  )
    (asserts! (> reward-per-hour u0) ERR_INVALID_AMOUNT)
    (asserts! (> duration-blocks u0) ERR_INVALID_DURATION)
    (asserts! (> max-participants u0) ERR_INVALID_AMOUNT)
    
    (map-set activities
      { activity-id: activity-id }
      {
        organizer: tx-sender,
        title: title,
        description: description,
        reward-per-hour: reward-per-hour,
        start-block: current-block,
        end-block: end-block,
        max-participants: max-participants,
        current-participants: u0,
        total-hours: u0,
        verified: false,
        completed: false
      }
    )
    
    (var-set next-activity-id (+ activity-id u1))
    (var-set activity-count (+ (var-get activity-count) u1))
    
    (map-set organizer-permissions
      { organizer: tx-sender }
      (merge 
        (default-to 
          { verified: false, activities-created: u0, reputation: u0 }
          (map-get? organizer-permissions { organizer: tx-sender })
        )
        { activities-created: (+ (get activities-created 
          (default-to { verified: false, activities-created: u0, reputation: u0 }
          (map-get? organizer-permissions { organizer: tx-sender }))) u1) }
      )
    )
    
    (ok activity-id)
  )
)

(define-public (join-activity (activity-id uint) (estimated-hours uint))
  (match (get-activity activity-id)
    activity-data
      (let (
        (current-participants (get current-participants activity-data))
        (max-participants (get max-participants activity-data))
      )
        (asserts! (is-activity-active activity-id) ERR_ACTIVITY_EXPIRED)
        (asserts! (< current-participants max-participants) ERR_INVALID_ACTIVITY)
        (asserts! (> estimated-hours u0) ERR_INVALID_AMOUNT)
        (asserts! (is-none (get-volunteer-record tx-sender activity-id)) ERR_INVALID_VOLUNTEER)
        
        (map-set volunteer-records
          { volunteer: tx-sender, activity-id: activity-id }
          {
            hours-contributed: u0,
            verified: false,
            reward-claimed: false,
            reward-amount: u0,
            participation-block: stacks-block-height
          }
        )
        
        (map-set activities
          { activity-id: activity-id }
          (merge activity-data { current-participants: (+ current-participants u1) })
        )
        
        (ok true)
      )
    ERR_ACTIVITY_NOT_FOUND
  )
)

(define-public (log-volunteer-hours (volunteer principal) (activity-id uint) (hours uint))
  (match (get-activity activity-id)
    activity-data
      (let (
        (organizer (get organizer activity-data))
      )
        (asserts! (is-eq tx-sender organizer) ERR_NOT_AUTHORIZED)
        (asserts! (> hours u0) ERR_INVALID_AMOUNT)
        
        (match (get-volunteer-record volunteer activity-id)
          volunteer-record
            (let (
              (new-hours (+ (get hours-contributed volunteer-record) hours))
            )
              (map-set volunteer-records
                { volunteer: volunteer, activity-id: activity-id }
                (merge volunteer-record 
                  { 
                    hours-contributed: new-hours,
                    verified: true
                  }
                )
              )
              
              (map-set activities
                { activity-id: activity-id }
                (merge activity-data 
                  { total-hours: (+ (get total-hours activity-data) hours) }
                )
              )
              
              (ok new-hours)
            )
          ERR_INVALID_VOLUNTEER
        )
      )
    ERR_ACTIVITY_NOT_FOUND
  )
)

(define-public (claim-reward (activity-id uint))
  (match (get-volunteer-record tx-sender activity-id)
    volunteer-record
      (let (
        (hours (get hours-contributed volunteer-record))
        (verified (get verified volunteer-record))
        (already-claimed (get reward-claimed volunteer-record))
      )
        (asserts! verified ERR_NOT_VERIFIED)
        (asserts! (not already-claimed) ERR_REWARD_ALREADY_CLAIMED)
        (asserts! (> hours u0) ERR_INVALID_AMOUNT)
        
        (match (calculate-reward activity-id hours)
          reward-amount
            (begin
              (try! (ft-mint? community-token reward-amount tx-sender))
              
              (map-set volunteer-records
                { volunteer: tx-sender, activity-id: activity-id }
                (merge volunteer-record 
                  {
                    reward-claimed: true,
                    reward-amount: reward-amount
                  }
                )
              )
              
              (let (
                (current-stats (default-to 
                  { total-activities: u0, total-hours: u0, total-rewards: u0, reputation-score: u0, verification-count: u0 }
                  (get-volunteer-stats tx-sender)
                ))
              )
                (map-set volunteer-stats
                  { volunteer: tx-sender }
                  {
                    total-activities: (+ (get total-activities current-stats) u1),
                    total-hours: (+ (get total-hours current-stats) hours),
                    total-rewards: (+ (get total-rewards current-stats) reward-amount),
                    reputation-score: (+ (get reputation-score current-stats) (* hours u10)),
                    verification-count: (+ (get verification-count current-stats) u1)
                  }
                )
              )
              
              (ok reward-amount)
            )
          error-code (err error-code)
        )
      )
    ERR_INVALID_VOLUNTEER
  )
)

(define-public (verify-activity (activity-id uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    
    (match (get-activity activity-id)
      activity-data
        (begin
          (map-set activities
            { activity-id: activity-id }
            (merge activity-data { verified: true })
          )
          (ok true)
        )
      ERR_ACTIVITY_NOT_FOUND
    )
  )
)

(define-public (complete-activity (activity-id uint))
  (match (get-activity activity-id)
    activity-data
      (let (
        (organizer (get organizer activity-data))
      )
        (asserts! (is-eq tx-sender organizer) ERR_NOT_AUTHORIZED)
        
        (map-set activities
          { activity-id: activity-id }
          (merge activity-data { completed: true })
        )
        
        (ok true)
      )
    ERR_ACTIVITY_NOT_FOUND
  )
)

(define-public (set-category-multiplier (category (string-ascii 50)) (multiplier uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    (asserts! (> multiplier u0) ERR_INVALID_MULTIPLIER)
    
    (map-set activity-categories
      { category: category }
      {
        multiplier: multiplier,
        active: true
      }
    )
    
    (ok true)
  )
)

(define-public (set-base-reward-rate (new-rate uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    (asserts! (> new-rate u0) ERR_INVALID_AMOUNT)
    
    (var-set base-reward-rate new-rate)
    (ok true)
  )
)