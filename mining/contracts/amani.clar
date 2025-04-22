;; Consensus Mining Network - Stage 1
;; Basic framework for blockchain consensus mining operations

;; Constants
(define-constant ERR-NOT-COORDINATOR (err u1))
(define-constant ERR-NETWORK-PAUSED (err u2))
(define-constant ERR-INVALID-BLOCK (err u3))
(define-constant ERR-BLOCK-ALREADY-MINED (err u4))
(define-constant ERR-INVALID-NONCE (err u5))

;; Data Variables
(define-data-var network-coordinator principal tx-sender)
(define-data-var network-active bool false)
(define-data-var current-difficulty uint u0)
(define-data-var total-reward-pool uint u0)

;; Block Structure
(define-map block-registry
    uint
    {
        target-hash: (string-utf8 256),
        solution-nonce: (buff 32),
        block-reward: uint,
        mined: bool
    }
)

;; Miner Profiles
(define-map miner-profiles
    principal
    {
        mined-blocks: (list 10 uint),
        total-mined: uint
    }
)

;; Authorization
(define-private (is-coordinator)
    (is-eq tx-sender (var-get network-coordinator)))

;; Network Management Functions
(define-public (activate-network)
    (begin
        (asserts! (is-coordinator) ERR-NOT-COORDINATOR)
        (var-set network-active true)
        (var-set current-difficulty u0)
        (var-set total-reward-pool u0)
        (ok true)))

(define-public (deactivate-network)
    (begin
        (asserts! (is-coordinator) ERR-NOT-COORDINATOR)
        (var-set network-active false)
        (ok true)))

(define-public (register-block
    (block-id uint)
    (target-hash (string-utf8 256))
    (solution-nonce (buff 32))
    (block-reward uint))
    (begin
        (asserts! (is-coordinator) ERR-NOT-COORDINATOR)
        (asserts! (var-get network-active) ERR-NETWORK-PAUSED)
        
        ;; Validate target hash is not empty
        (asserts! (> (len target-hash) u0) ERR-INVALID-BLOCK)
        
        ;; Validate solution nonce is not empty
        (asserts! (> (len solution-nonce) u0) ERR-INVALID-BLOCK)
        
        ;; Set the block data
        (map-set block-registry block-id
            {
                target-hash: target-hash,
                solution-nonce: solution-nonce,
                block-reward: block-reward,
                mined: false
            })
            
        ;; Update the total reward pool
        (var-set total-reward-pool (+ (var-get total-reward-pool) block-reward))
        (ok true)))

;; Miner Registration
(define-public (register-as-miner)
    (begin
        (asserts! (var-get network-active) ERR-NETWORK-PAUSED)
        
        (map-set miner-profiles tx-sender
            {
                mined-blocks: (list),
                total-mined: u0
            })
        (ok true)))

;; Block Mining Functions
(define-public (submit-solution
    (block-id uint)
    (nonce-solution (buff 32)))
    (let (
        (block (unwrap! (map-get? block-registry block-id) ERR-INVALID-BLOCK))
        (miner (unwrap! (map-get? miner-profiles tx-sender) ERR-INVALID-BLOCK))
        )
        ;; Check block availability
        (asserts! (var-get network-active) ERR-NETWORK-PAUSED)
        (asserts! (not (get mined block)) ERR-BLOCK-ALREADY-MINED)
        
        ;; Verify solution nonce
        (if (is-eq nonce-solution (get solution-nonce block))
            (begin
                ;; Update block status
                (map-set block-registry block-id
                    (merge block {mined: true}))
                
                ;; Update miner profile
                (map-set miner-profiles tx-sender
                    (merge miner {
                        mined-blocks: (unwrap! (as-max-len? 
                            (append (get mined-blocks miner) block-id) u10)
                            ERR-INVALID-BLOCK),
                        total-mined: (+ (get total-mined miner) u1)
                    }))
                
                ;; Distribute block reward
                (try! (stx-transfer? (get block-reward block) (var-get network-coordinator) tx-sender))
                
                (ok true))
            ERR-INVALID-NONCE)))

;; Read-only functions
(define-read-only (get-block-target (block-id uint))
    (match (map-get? block-registry block-id)
        block (ok (get target-hash block))
        ERR-INVALID-BLOCK))

(define-read-only (get-miner-status (miner principal))
    (map-get? miner-profiles miner))

(define-read-only (get-network-stats)
    {
        active: (var-get network-active),
        current-difficulty: (var-get current-difficulty),
        total-reward-pool: (var-get total-reward-pool)
    })