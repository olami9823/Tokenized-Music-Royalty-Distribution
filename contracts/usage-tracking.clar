;; Usage Tracking Contract
;; Monitors plays across streaming platforms

(define-data-var admin principal tx-sender)

;; Structure for tracking plays
(define-map composition-plays
  { composition-id: uint }
  { total-plays: uint }
)

;; Structure for tracking plays by platform
(define-map platform-plays
  { composition-id: uint, platform-id: uint }
  { plays: uint }
)

;; Authorized platforms that can report plays
(define-map authorized-platforms
  uint
  { name: (string-ascii 50), active: bool }
)

;; Error codes
(define-constant err-not-admin (err u100))
(define-constant err-platform-not-authorized (err u101))
(define-constant err-invalid-play-count (err u102))

;; Check if caller is admin
(define-private (is-admin)
  (is-eq tx-sender (var-get admin)))

;; Authorize a platform to report plays
(define-public (authorize-platform (platform-id uint) (name (string-ascii 50)))
  (begin
    (asserts! (is-admin) err-not-admin)
    (ok (map-set authorized-platforms platform-id { name: name, active: true }))
  )
)

;; Deauthorize a platform
(define-public (deauthorize-platform (platform-id uint))
  (begin
    (asserts! (is-admin) err-not-admin)
    (match (map-get? authorized-platforms platform-id)
      platform (ok (map-set authorized-platforms platform-id
                    (merge platform { active: false })))
      (err err-platform-not-authorized)
    )
  )
)

;; Record plays for a composition
(define-public (record-plays
  (composition-id uint)
  (platform-id uint)
  (play-count uint))

  (let
    (
      (current-total (default-to { total-plays: u0 }
                      (map-get? composition-plays { composition-id: composition-id })))
      (current-platform (default-to { plays: u0 }
                        (map-get? platform-plays
                          { composition-id: composition-id, platform-id: platform-id })))
    )

    ;; Check if platform is authorized
    (asserts! (is-platform-authorized platform-id) err-platform-not-authorized)

    ;; Validate play count
    (asserts! (> play-count u0) err-invalid-play-count)

    ;; Update total plays
    (map-set composition-plays
      { composition-id: composition-id }
      { total-plays: (+ (get total-plays current-total) play-count) }
    )

    ;; Update platform plays
    (map-set platform-plays
      { composition-id: composition-id, platform-id: platform-id }
      { plays: (+ (get plays current-platform) play-count) }
    )

    (ok true)
  )
)

;; Check if a platform is authorized
(define-read-only (is-platform-authorized (platform-id uint))
  (match (map-get? authorized-platforms platform-id)
    platform (get active platform)
    false
  )
)

;; Get total plays for a composition
(define-read-only (get-total-plays (composition-id uint))
  (match (map-get? composition-plays { composition-id: composition-id })
    plays (get total-plays plays)
    u0
  )
)

;; Get plays for a composition on a specific platform
(define-read-only (get-platform-plays (composition-id uint) (platform-id uint))
  (match (map-get? platform-plays { composition-id: composition-id, platform-id: platform-id })
    plays (get plays plays)
    u0
  )
)
