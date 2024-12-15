;; Contract Name: Decentralized Media Library
;; Description: A smart contract for managing a decentralized media library. Users can add, edit, transfer, delete media entries, and grant access rights with proper validation and permissions.

;; Error Codes
(define-constant ERR_MEDIA_NOT_FOUND (err u301)) ;; Error when a media entry is not found.
(define-constant ERR_DUPLICATE_MEDIA (err u302)) ;; Error when attempting to create duplicate media.
(define-constant ERR_INVALID_NAME (err u303)) ;; Error for invalid media name.
(define-constant ERR_INVALID_SIZE (err u304)) ;; Error for invalid media size.
(define-constant ERR_UNAUTHORIZED (err u305)) ;; Error for unauthorized actions.
(define-constant ERR_INVALID_CATEGORY (err u306)) ;; Error for invalid category name.
(define-constant ERR_RESTRICTED_ACTION (err u307)) ;; Error for restricted actions.
(define-constant ERR_ACCESS_DENIED (err u308)) ;; Error for denied access.
(define-constant ERR_INVALID_ACCESS_GRANT (err u309)) ;; Error for invalid access grant attempts.
(define-constant ERR_INVALID_PRINCIPAL (err u310))

;; Permissions
(define-constant LIBRARY_ADMIN tx-sender) ;; Contract administrator (default is the transaction sender).

;; Global Counters and Mappings
(define-data-var media-count uint u0) ;; Counter to track the total number of media entries.

(define-map media-entries
  { id: uint } ;; Key: Media ID.
  {
    name: (string-ascii 64),         ;; Name of the media.
    owner: principal,               ;; Owner's principal address.
    data-size: uint,                ;; Size of the media file.
    timestamp: uint,                ;; Block height when the media was added.
    category: (string-ascii 32),    ;; Category of the media.
    overview: (string-ascii 128),   ;; Brief overview of the media.
    tags-list: (list 10 (string-ascii 32)) ;; List of tags associated with the media.
  }
)

(define-map access-rights
  { id: uint, user-principal: principal } ;; Key: Media ID and user principal.
  { 
    can-access: bool,              ;; Access rights for users
    granted-by: principal,         ;; Principal who granted the access
    granted-at: uint              ;; Block height when access was granted
  }
)

;; Internal Utility Functions

;; Check if a media entry exists.
(define-private (is-media-present? (id uint))
  (is-some (map-get? media-entries { id: id }))
)

;; Check if the given user is the owner of the media.
(define-private (is-authorized-owner? (id uint) (user principal))
  (match (map-get? media-entries { id: id })
    media-info (is-eq (get owner media-info) user)
    false
  )
)

(define-private (validate-principal (principal principal))
  (not (is-eq principal 'ST000000000000000000002AMW42H))
)

;; Check if a user has read access to a media entry
(define-private (has-read-access? (id uint) (user principal))
  (match (map-get? access-rights { id: id, user-principal: user })
    access-info (get can-access access-info)
    false
  )
)

;; Retrieve the data size of a media entry.
(define-private (get-data-size (id uint))
  (default-to u0 
    (get data-size 
      (map-get? media-entries { id: id })
    )
  )
)

;; Tag Validators

;; Validate a single tag.
(define-private (validate-tag (single-tag (string-ascii 32)))
  (and 
    (> (len single-tag) u0)
    (< (len single-tag) u33)
  )
)

;; Validate a set of tags.
(define-private (validate-tag-set (all-tags (list 10 (string-ascii 32))))
  (and
    (> (len all-tags) u0)
    (<= (len all-tags) u10)
    (is-eq (len (filter validate-tag all-tags)) (len all-tags))
  )
)

;; Public Functions

;; Create a new media entry.
(define-public (create-media (name (string-ascii 64)) (size uint) (category (string-ascii 32)) (overview (string-ascii 128)) (tags (list 10 (string-ascii 32))))
  (let
    (
      (new-id (+ (var-get media-count) u1))
    )
    ;; Validate inputs.
    (asserts! (> (len name) u0) ERR_INVALID_NAME)
    (asserts! (< (len name) u65) ERR_INVALID_NAME)
    (asserts! (> size u0) ERR_INVALID_SIZE)
    (asserts! (< size u1000000000) ERR_INVALID_SIZE)
    (asserts! (> (len category) u0) ERR_INVALID_CATEGORY)
    (asserts! (< (len category) u33) ERR_INVALID_CATEGORY)
    (asserts! (> (len overview) u0) ERR_INVALID_NAME)
    (asserts! (< (len overview) u129) ERR_INVALID_NAME)
    (asserts! (validate-tag-set tags) ERR_INVALID_NAME)

    ;; Insert new media entry.
    (map-insert media-entries
      { id: new-id }
      {
        name: name,
        owner: tx-sender,
        data-size: size,
        timestamp: block-height,
        category: category,
        overview: overview,
        tags-list: tags
      }
    )

    ;; Grant access rights to the creator.
    (map-insert access-rights
      { id: new-id, user-principal: tx-sender }
      { 
        can-access: true,
        granted-by: tx-sender,
        granted-at: block-height
      }
    )
    (var-set media-count new-id) ;; Update media counter.
    (ok new-id)
  )
)

;; Grant read access to a user for a specific media entry
(define-public (grant-read-access (id uint) (user principal))
  (let
    (
      (media-entry (unwrap! (map-get? media-entries { id: id }) ERR_MEDIA_NOT_FOUND))
    )
    ;; Validate media existence and ownership
    (asserts! (is-media-present? id) ERR_MEDIA_NOT_FOUND)
    (asserts! (is-authorized-owner? id tx-sender) ERR_UNAUTHORIZED)
    (asserts! (not (is-eq user tx-sender)) ERR_INVALID_ACCESS_GRANT)
    
    ;; Grant access rights
    (map-set access-rights
      { id: id, user-principal: user }
      { 
        can-access: true,
        granted-by: tx-sender,
        granted-at: block-height
      }
    )
    (ok true)
  )
)

;; Revoke read access from a user for a specific media entry
(define-public (revoke-read-access (id uint) (user principal))
  (let
    (
      (media-entry (unwrap! (map-get? media-entries { id: id }) ERR_MEDIA_NOT_FOUND))
      (access-info (unwrap! (map-get? access-rights { id: id, user-principal: user }) ERR_UNAUTHORIZED))
    )
    ;; Validate media existence and ownership
    (asserts! (is-media-present? id) ERR_MEDIA_NOT_FOUND)
    (asserts! (is-authorized-owner? id tx-sender) ERR_UNAUTHORIZED)
    (asserts! (not (is-eq user tx-sender)) ERR_INVALID_ACCESS_GRANT)
    
    ;; Revoke access rights
    (map-delete access-rights { id: id, user-principal: user })
    (ok true)
  )
)

;; Check if a user has access to a media entry
(define-read-only (check-access (id uint) (user principal))
  (ok (has-read-access? id user))
)

;; Transfer ownership of a media entry.
(define-public (transfer-ownership (id uint) (new-owner principal))
  (let
    (
      (media-details (unwrap! (map-get? media-entries { id: id }) ERR_MEDIA_NOT_FOUND))
    )
    ;; Validate ownership, media existence, and new owner
    (asserts! (is-media-present? id) ERR_MEDIA_NOT_FOUND)
    (asserts! (is-authorized-owner? id tx-sender) ERR_UNAUTHORIZED)
    (asserts! (not (is-eq new-owner tx-sender)) ERR_INVALID_ACCESS_GRANT)
    (asserts! (validate-principal new-owner) ERR_INVALID_PRINCIPAL)

    ;; Update ownership
    (map-set media-entries
      { id: id }
      (merge media-details { owner: new-owner })
    )

    ;; Transfer access rights to new owner
    (map-set access-rights
      { id: id, user-principal: new-owner }
      {
        can-access: true,
        granted-by: tx-sender,
        granted-at: block-height
      }
    )
    (ok true)
  )
)

;; Edit an existing media entry.
(define-public (edit-media (id uint) (updated-name (string-ascii 64)) (updated-size uint) (updated-category (string-ascii 32)) (updated-overview (string-ascii 128)) (updated-tags (list 10 (string-ascii 32))))
  (let
    (
      (media-info (unwrap! (map-get? media-entries { id: id }) ERR_MEDIA_NOT_FOUND))
    )
    ;; Validate ownership and inputs.
    (asserts! (is-media-present? id) ERR_MEDIA_NOT_FOUND)
    (asserts! (is-eq (get owner media-info) tx-sender) ERR_UNAUTHORIZED)
    (asserts! (> (len updated-name) u0) ERR_INVALID_NAME)
    (asserts! (< (len updated-name) u65) ERR_INVALID_NAME)
    (asserts! (> updated-size u0) ERR_INVALID_SIZE)
    (asserts! (< updated-size u1000000000) ERR_INVALID_SIZE)
    (asserts! (> (len updated-category) u0) ERR_INVALID_CATEGORY)
    (asserts! (< (len updated-category) u33) ERR_INVALID_CATEGORY)
    (asserts! (> (len updated-overview) u0) ERR_INVALID_NAME)
    (asserts! (< (len updated-overview) u129) ERR_INVALID_NAME)
    (asserts! (validate-tag-set updated-tags) ERR_INVALID_NAME)

    ;; Update media entry.
    (map-set media-entries
      { id: id }
      (merge media-info { 
        name: updated-name, 
        data-size: updated-size, 
        category: updated-category, 
        overview: updated-overview, 
        tags-list: updated-tags 
      })
    )
    (ok true)
  )
)

;; Delete a media entry.
(define-public (delete-media (id uint))
  (let
    (
      (media-entry (unwrap! (map-get? media-entries { id: id }) ERR_MEDIA_NOT_FOUND))
    )
    ;; Validate ownership and existence.
    (asserts! (is-media-present? id) ERR_MEDIA_NOT_FOUND)
    (asserts! (is-eq (get owner media-entry) tx-sender) ERR_UNAUTHORIZED)
    ;; Remove media entry and all associated access rights
    (map-delete media-entries { id: id })
    (ok true)
  )
)