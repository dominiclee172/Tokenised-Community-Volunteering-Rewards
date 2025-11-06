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
(define-constant ERR_LEADERBOARD_FULL (err u111))
(define-constant ERR_ACHIEVEMENT_EXISTS (err u112))
(define-constant ERR_INVALID_RANK (err u113))

(define-fungible-token community-token)

(define-data-var token-name (string-ascii 32) "Community Volunteer Token")
(define-data-var token-symbol (string-ascii 10) "CVT")
(define-data-var total-supply uint u1000000)
(define-data-var next-activity-id uint u1)
(define-data-var base-reward-rate uint u100)
(define-data-var activity-count uint u0)
(define-data-var total-volunteers uint u0)
(define-data-var leaderboard-size uint u10)
(define-data-var season-number uint u1)
(define-data-var reward-multiplier uint u1)
(define-data-var claim-cooldown-blocks uint u0)

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
    completed: bool,
  }
)

(define-map volunteer-records
  {
    volunteer: principal,
    activity-id: uint,
  }
  {
    hours-contributed: uint,
    verified: bool,
    reward-claimed: bool,
    reward-amount: uint,
    participation-block: uint,
  }
)

(define-map volunteer-stats
  { volunteer: principal }
  {
    total-activities: uint,
    total-hours: uint,
    total-rewards: uint,
    reputation-score: uint,
    verification-count: uint,
  }
)

(define-map organizer-permissions
  { organizer: principal }
  {
    verified: bool,
    activities-created: uint,
    reputation: uint,
  }
)

(define-map activity-categories
  { category: (string-ascii 50) }
  {
    multiplier: uint,
    active: bool,
  }
)

;; NEW LEADERBOARD FEATURE MAPS
(define-map volunteer-leaderboard
  { rank: uint }
  {
    volunteer: principal,
    total-score: uint,
    season: uint,
    last-updated: uint,
  }
)

(define-map volunteer-achievements
  {
    volunteer: principal,
    achievement-type: (string-ascii 50),
  }
  {
    earned-block: uint,
    season: uint,
    milestone-value: uint,
    badge-level: uint,
  }
)

(define-map achievement-definitions
  { achievement-type: (string-ascii 50) }
  {
    name: (string-ascii 100),
    description: (string-ascii 200),
    required-value: uint,
    bonus-points: uint,
    active: bool,
  }
)

(define-map seasonal-stats
  {
    volunteer: principal,
    season: uint,
  }
  {
    activities-completed: uint,
    hours-contributed: uint,
    rewards-earned: uint,
    rank-achieved: uint,
    achievements-unlocked: uint,
  }
)

(define-map claim-cooldowns
  { volunteer: principal }
  { last-claim: uint }
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

(define-read-only (get-volunteer-record
    (volunteer principal)
    (activity-id uint)
  )
  (map-get? volunteer-records {
    volunteer: volunteer,
    activity-id: activity-id,
  })
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

;; NEW LEADERBOARD READ-ONLY FUNCTIONS
(define-read-only (get-leaderboard-entry (rank uint))
  (map-get? volunteer-leaderboard { rank: rank })
)

(define-read-only (get-volunteer-rank (volunteer principal))
  (let ((leaderboard-size-val (var-get leaderboard-size)))
    (fold check-volunteer-rank (list u1 u2 u3 u4 u5 u6 u7 u8 u9 u10) {
      target: volunteer,
      found-rank: none,
      current-rank: u1,
    })
  )
)

(define-read-only (get-volunteer-achievement
    (volunteer principal)
    (achievement-type (string-ascii 50))
  )
  (map-get? volunteer-achievements {
    volunteer: volunteer,
    achievement-type: achievement-type,
  })
)

(define-read-only (get-achievement-definition (achievement-type (string-ascii 50)))
  (map-get? achievement-definitions { achievement-type: achievement-type })
)

(define-read-only (get-seasonal-stats
    (volunteer principal)
    (season uint)
  )
  (map-get? seasonal-stats {
    volunteer: volunteer,
    season: season,
  })
)

(define-read-only (get-top-volunteers (limit uint))
  (let ((actual-limit (if (> limit u10)
      u10
      limit
    )))
    (map get-leaderboard-entry (list u1 u2 u3 u4 u5 u6 u7 u8 u9 u10))
  )
)

(define-private (check-volunteer-rank
    (rank uint)
    (state {
      target: principal,
      found-rank: (optional uint),
      current-rank: uint,
    })
  )
  (if (is-some (get found-rank state))
    state
    (match (get-leaderboard-entry rank)
      entry (if (is-eq (get volunteer entry) (get target state))
        (merge state { found-rank: (some rank) })
        state
      )
      state
    )
  )
)

(define-read-only (calculate-reward
    (activity-id uint)
    (hours uint)
  )
  (match (get-activity activity-id)
    activity-data (let (
        (reward-per-hour (get reward-per-hour activity-data))
        (base-reward (* hours reward-per-hour))
        (multiplier (var-get reward-multiplier))
        (final-reward (* base-reward multiplier))
      )
      (ok final-reward)
    )
    ERR_ACTIVITY_NOT_FOUND
  )
)

(define-read-only (is-activity-active (activity-id uint))
  (match (get-activity activity-id)
    activity-data (let (
        (current-block stacks-block-height)
        (start-block (get start-block activity-data))
        (end-block (get end-block activity-data))
      )
      (and (>= current-block start-block) (<= current-block end-block))
    )
    false
  )
)

(define-public (transfer
    (amount uint)
    (from principal)
    (to principal)
    (memo (optional (buff 34)))
  )
  (begin
    (asserts! (or (is-eq from tx-sender) (is-eq from CONTRACT_OWNER))
      ERR_NOT_AUTHORIZED
    )
    (ft-transfer? community-token amount from to)
  )
)

(define-public (mint
    (amount uint)
    (to principal)
  )
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)
    (ft-mint? community-token amount to)
  )
)

(define-public (burn
    (amount uint)
    (from principal)
  )
  (begin
    (asserts! (or (is-eq tx-sender from) (is-eq tx-sender CONTRACT_OWNER))
      ERR_NOT_AUTHORIZED
    )
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

    (map-set activities { activity-id: activity-id } {
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
      completed: false,
    })

    (var-set next-activity-id (+ activity-id u1))
    (var-set activity-count (+ (var-get activity-count) u1))

    (map-set organizer-permissions { organizer: tx-sender }
      (merge
        (default-to {
          verified: false,
          activities-created: u0,
          reputation: u0,
        }
          (map-get? organizer-permissions { organizer: tx-sender })
        ) { activities-created: (+
        (get activities-created
          (default-to {
            verified: false,
            activities-created: u0,
            reputation: u0,
          }
            (map-get? organizer-permissions { organizer: tx-sender })
          ))
        u1
      ) }
      ))

    (ok activity-id)
  )
)

(define-public (join-activity
    (activity-id uint)
    (estimated-hours uint)
  )
  (match (get-activity activity-id)
    activity-data (let (
        (current-participants (get current-participants activity-data))
        (max-participants (get max-participants activity-data))
      )
      (asserts! (is-activity-active activity-id) ERR_ACTIVITY_EXPIRED)
      (asserts! (< current-participants max-participants) ERR_INVALID_ACTIVITY)
      (asserts! (> estimated-hours u0) ERR_INVALID_AMOUNT)
      (asserts! (is-none (get-volunteer-record tx-sender activity-id))
        ERR_INVALID_VOLUNTEER
      )

      (map-set volunteer-records {
        volunteer: tx-sender,
        activity-id: activity-id,
      } {
        hours-contributed: u0,
        verified: false,
        reward-claimed: false,
        reward-amount: u0,
        participation-block: stacks-block-height,
      })

      (map-set activities { activity-id: activity-id }
        (merge activity-data { current-participants: (+ current-participants u1) })
      )

      (ok true)
    )
    ERR_ACTIVITY_NOT_FOUND
  )
)

(define-public (log-volunteer-hours
    (volunteer principal)
    (activity-id uint)
    (hours uint)
  )
  (match (get-activity activity-id)
    activity-data (let ((organizer (get organizer activity-data)))
      (asserts! (is-eq tx-sender organizer) ERR_NOT_AUTHORIZED)
      (asserts! (> hours u0) ERR_INVALID_AMOUNT)

      (match (get-volunteer-record volunteer activity-id)
        volunteer-record (let ((new-hours (+ (get hours-contributed volunteer-record) hours)))
          (map-set volunteer-records {
            volunteer: volunteer,
            activity-id: activity-id,
          }
            (merge volunteer-record {
              hours-contributed: new-hours,
              verified: true,
            })
          )

          (map-set activities { activity-id: activity-id }
            (merge activity-data { total-hours: (+ (get total-hours activity-data) hours) })
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
    volunteer-record (let (
        (hours (get hours-contributed volunteer-record))
        (verified (get verified volunteer-record))
        (already-claimed (get reward-claimed volunteer-record))
        (current-block stacks-block-height)
        (cooldown (var-get claim-cooldown-blocks))
        (prev (default-to { last-claim: u0 }
          (map-get? claim-cooldowns { volunteer: tx-sender })
        ))
      )
      (asserts! verified ERR_NOT_VERIFIED)
      (asserts! (not already-claimed) ERR_REWARD_ALREADY_CLAIMED)
      (asserts! (> hours u0) ERR_INVALID_AMOUNT)
      (if (> cooldown u0)
        (asserts! (>= current-block (+ (get last-claim prev) cooldown))
          ERR_INVALID_AMOUNT
        )
        true
      )

      (match (calculate-reward activity-id hours)
        reward-amount (begin
          (try! (ft-mint? community-token reward-amount tx-sender))

          (map-set volunteer-records {
            volunteer: tx-sender,
            activity-id: activity-id,
          }
            (merge volunteer-record {
              reward-claimed: true,
              reward-amount: reward-amount,
            })
          )

          (let (
              (current-stats (default-to {
                total-activities: u0,
                total-hours: u0,
                total-rewards: u0,
                reputation-score: u0,
                verification-count: u0,
              }
                (get-volunteer-stats tx-sender)
              ))
              (new-score (+ (get reputation-score current-stats) (* hours u10)))
            )
            (map-set volunteer-stats { volunteer: tx-sender } {
              total-activities: (+ (get total-activities current-stats) u1),
              total-hours: (+ (get total-hours current-stats) hours),
              total-rewards: (+ (get total-rewards current-stats) reward-amount),
              reputation-score: new-score,
              verification-count: (+ (get verification-count current-stats) u1),
            })
            (map-set claim-cooldowns { volunteer: tx-sender } { last-claim: current-block })
            (is-ok (update-leaderboard-position tx-sender new-score))
            (is-ok (check-and-award-achievements tx-sender))
          )

          (ok reward-amount)
        )
        error-code (err error-code)
      )
    )
    ERR_INVALID_VOLUNTEER
  )
)

;; NEW LEADERBOARD FUNCTIONS
(define-private (update-leaderboard-position
    (volunteer principal)
    (score uint)
  )
  (let ((current-season (var-get season-number)))
    (map-set volunteer-leaderboard { rank: u1 } {
      volunteer: volunteer,
      total-score: score,
      season: current-season,
      last-updated: stacks-block-height,
    })
    (ok true)
  )
)

(define-private (insert-into-leaderboard
    (volunteer principal)
    (score uint)
    (season uint)
    (rank uint)
  )
  ;; Simple non-recursive insertion at specified rank
  (if (> rank u10)
    (ok false)
    (begin
      (map-set volunteer-leaderboard { rank: rank } {
        volunteer: volunteer,
        total-score: score,
        season: season,
        last-updated: stacks-block-height,
      })
      (ok true)
    )
  )
)

(define-private (shift-leaderboard-down (from-rank uint))
  (let ((leaderboard-size-val (var-get leaderboard-size)))
    (if (>= from-rank leaderboard-size-val)
      (ok true)
      (match (get-leaderboard-entry from-rank)
        entry (begin
          ;; Only shift if we're not at the bottom
          (if (< (+ from-rank u1) leaderboard-size-val)
            (map-set volunteer-leaderboard { rank: (+ from-rank u1) } entry)
            true
          )
          (ok true)
        )
        (ok true)
      )
    )
  )
)

(define-public (check-and-award-achievements (volunteer principal))
  (let (
      (stats (default-to {
        total-activities: u0,
        total-hours: u0,
        total-rewards: u0,
        reputation-score: u0,
        verification-count: u0,
      }
        (get-volunteer-stats volunteer)
      ))
      (current-season (var-get season-number))
    )
    ;; Check for "First Steps" achievement (1 activity)
    (if (and
        (is-eq (get total-activities stats) u1)
        (is-none (get-volunteer-achievement volunteer "first-steps"))
      )
      (map-set volunteer-achievements {
        volunteer: volunteer,
        achievement-type: "first-steps",
      } {
        earned-block: stacks-block-height,
        season: current-season,
        milestone-value: u1,
        badge-level: u1,
      })
      true
    )

    ;; Check for "Dedicated Helper" achievement (10 activities)
    (if (and
        (>= (get total-activities stats) u10)
        (is-none (get-volunteer-achievement volunteer "dedicated-helper"))
      )
      (map-set volunteer-achievements {
        volunteer: volunteer,
        achievement-type: "dedicated-helper",
      } {
        earned-block: stacks-block-height,
        season: current-season,
        milestone-value: u10,
        badge-level: u2,
      })
      true
    )

    ;; Check for "Time Champion" achievement (100 hours)
    (if (and
        (>= (get total-hours stats) u100)
        (is-none (get-volunteer-achievement volunteer "time-champion"))
      )
      (map-set volunteer-achievements {
        volunteer: volunteer,
        achievement-type: "time-champion",
      } {
        earned-block: stacks-block-height,
        season: current-season,
        milestone-value: u100,
        badge-level: u3,
      })
      true
    )

    (ok true)
  )
)

(define-public (initialize-achievement-definitions)
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)

    (map-set achievement-definitions { achievement-type: "first-steps" } {
      name: "First Steps",
      description: "Complete your first volunteering activity",
      required-value: u1,
      bonus-points: u50,
      active: true,
    })

    (map-set achievement-definitions { achievement-type: "dedicated-helper" } {
      name: "Dedicated Helper",
      description: "Complete 10 volunteering activities",
      required-value: u10,
      bonus-points: u200,
      active: true,
    })

    (map-set achievement-definitions { achievement-type: "time-champion" } {
      name: "Time Champion",
      description: "Contribute 100 hours of volunteer time",
      required-value: u100,
      bonus-points: u500,
      active: true,
    })

    (ok true)
  )
)

(define-public (start-new-season)
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    (var-set season-number (+ (var-get season-number) u1))
    ;; Clear current leaderboard for new season
    (try! (clear-leaderboard u1))
    (ok (var-get season-number))
  )
)

(define-private (clear-leaderboard (rank uint))
  (begin
    ;; Clear positions 1-10 manually to avoid recursion
    (map-delete volunteer-leaderboard { rank: u1 })
    (map-delete volunteer-leaderboard { rank: u2 })
    (map-delete volunteer-leaderboard { rank: u3 })
    (map-delete volunteer-leaderboard { rank: u4 })
    (map-delete volunteer-leaderboard { rank: u5 })
    (map-delete volunteer-leaderboard { rank: u6 })
    (map-delete volunteer-leaderboard { rank: u7 })
    (map-delete volunteer-leaderboard { rank: u8 })
    (map-delete volunteer-leaderboard { rank: u9 })
    (map-delete volunteer-leaderboard { rank: u10 })
    (ok true)
  )
)

(define-public (verify-activity (activity-id uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)

    (match (get-activity activity-id)
      activity-data (begin
        (map-set activities { activity-id: activity-id }
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
    activity-data (let ((organizer (get organizer activity-data)))
      (asserts! (is-eq tx-sender organizer) ERR_NOT_AUTHORIZED)

      (map-set activities { activity-id: activity-id }
        (merge activity-data { completed: true })
      )

      (ok true)
    )
    ERR_ACTIVITY_NOT_FOUND
  )
)

(define-public (set-category-multiplier
    (category (string-ascii 50))
    (multiplier uint)
  )
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    (asserts! (> multiplier u0) ERR_INVALID_MULTIPLIER)

    (map-set activity-categories { category: category } {
      multiplier: multiplier,
      active: true,
    })

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

(define-public (set-reward-multiplier (new-multiplier uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    (asserts! (> new-multiplier u0) ERR_INVALID_AMOUNT)
    (var-set reward-multiplier new-multiplier)
    (ok true)
  )
)

(define-public (set-claim-cooldown (blocks uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    (var-set claim-cooldown-blocks blocks)
    (ok true)
  )
)

(define-read-only (get-reward-multiplier)
  (ok (var-get reward-multiplier))
)

(define-read-only (get-claim-cooldown)
  (ok (var-get claim-cooldown-blocks))
)

(define-read-only (get-last-claim-block (volunteer principal))
  (map-get? claim-cooldowns { volunteer: volunteer })
)
