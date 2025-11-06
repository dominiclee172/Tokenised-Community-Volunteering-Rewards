(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_NON_TRANSFERABLE (err u200))

(define-data-var last-token-id uint u0)

(define-non-fungible-token volunteer-badge uint)

(define-map token-uris 
  { token-id: uint } 
  { uri: (optional (string-ascii 200)) }
)

(define-read-only (get-last-token-id)
  (ok (var-get last-token-id))
)

(define-read-only (get-owner (token-id uint))
  (ok (nft-get-owner? volunteer-badge token-id))
)

(define-read-only (get-token-uri (token-id uint))
  (map-get? token-uris { token-id: token-id })
)

(define-public (mint-badge (recipient principal) (uri (optional (string-ascii 200))))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    (let ((new-id (+ (var-get last-token-id) u1)))
      (try! (nft-mint? volunteer-badge new-id recipient))
      (map-set token-uris { token-id: new-id } { uri: uri })
      (var-set last-token-id new-id)
      (ok new-id)
    )
  )
)

(define-public (transfer (token-id uint) (sender principal) (recipient principal))
  ERR_NON_TRANSFERABLE
)
