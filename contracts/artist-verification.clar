;; Artist Verification Contract
;; This contract validates legitimate music creators

(define-data-var admin principal tx-sender)

;; Map to store verified artists
(define-map verified-artists principal bool)

;; Error codes
(define-constant err-not-admin (err u100))
(define-constant err-already-verified (err u101))
(define-constant err-not-verified (err u102))

;; Check if caller is admin
(define-private (is-admin)
  (is-eq tx-sender (var-get admin)))

;; Verify an artist
(define-public (verify-artist (artist principal))
  (begin
    (asserts! (is-admin) err-not-admin)
    (asserts! (not (default-to false (map-get? verified-artists artist))) err-already-verified)
    (ok (map-set verified-artists artist true))))

;; Revoke artist verification
(define-public (revoke-verification (artist principal))
  (begin
    (asserts! (is-admin) err-not-admin)
    (asserts! (default-to false (map-get? verified-artists artist)) err-not-verified)
    (ok (map-set verified-artists artist false))))

;; Check if an artist is verified
(define-read-only (is-verified (artist principal))
  (default-to false (map-get? verified-artists artist)))

;; Transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-admin) err-not-admin)
    (ok (var-set admin new-admin))))
