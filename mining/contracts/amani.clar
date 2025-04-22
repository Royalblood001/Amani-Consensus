;; Consensus Mining Network 

;; Constants
(define-constant ERR-NOT-COORDINATOR (err u1))
(define-constant ERR-NETWORK-PAUSED (err u2))
(define-constant ERR-INVALID-BLOCK (err u3))
(define-constant ERR-BLOCK-ALREADY-MINED (err u4))
(define-constant ERR-INVALID-NONCE (err u5))
(define-constant ERR-TIMEOUT-ACTIVE (err u6))
(define-constant ERR-INVALID-PARAMETER (err u7))
(define-constant ERR-BLOCK-EXISTS (err u8))
(define-constant MAX-BLOCK-ID u100) ;; Maximum allowed block ID

;; Data Variables
(define-data-var network-coordinator principal tx-sender)
(define-data-var network-active bool false)
(define-data-var current-difficulty uint u0)
(define-data-var total-reward-pool uint u0)
(define-data-var chain-height uint u0) ;; Block height tracking for timeouts

;; Block Structure
(define-map block-registry
    uint
    {
        target-hash: (string-utf8 256),
        solution-nonce: (buff 32),
        timeout: uint,                 ;; Timeout period end block height
        block-reward: uint,
        mined: bool
    }
)

;; Miner Performance Tracking
(define-map miner-profiles
    principal
    {
        assigned-block: uint,
        mined-blocks: (list 15 uint),
        last-activity: uint,
        total-mined: uint
    }
)

;; Mining History
(define-map block-mining-records
    {block-id: uint, miner: principal}
    {
        attempts: uint,
        mined-at: (optional uint)
    }
)

;; Authorization
(define-private (is-coordinator)
    (is-eq tx-sender (var-get network-coordinator)))

;; Chain Height Management
(define-public (update-chain-height (new-height uint))
    (begin
        (asserts! (is-coordinator) ERR-NOT-COORDINATOR)
        ;; Validate height is not less than current
        (asserts! (>= new-height (var-get chain-height)) ERR-INVALID-PARAMETER)
        (var-set chain-height new-height)
        (ok true)))

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
    (timeout uint)
    (block-reward uint))
    (begin
        (asserts! (is-coordinator) ERR-NOT-COORDINATOR)
        (asserts! (var-get network-active) ERR-NETWORK-PAUSED)
        
        ;; Validate block-id is within acceptable range
        (asserts! (<= block-id MAX-BLOCK-ID) ERR-INVALID-PARAMETER)
        
        ;; Check if block already exists to prevent overwriting
        (asserts! (is-none (map-get? block-registry block-id)) ERR-BLOCK-EXISTS)
        
        ;; Validate timeout is in the future
        (asserts! (>= timeout (var-get chain-height)) ERR-INVALID-PARAMETER)
        
        ;; Validate solution nonce is not empty
        (asserts! (> (len solution-nonce) u0) ERR-INVALID-PARAMETER)
        
        ;; Validate target hash is not empty
        (asserts! (> (len target-hash) u0) ERR-INVALID-PARAMETER)
        
        ;; Validate block reward is a positive amount
        (asserts! (> block-reward u0) ERR-INVALID-PARAMETER)
        
        ;; Set the block data
        (map-set block-registry block-id
            {
                target-hash: target-hash,
                solution-nonce: solution-nonce,
                timeout: timeout,
                block-reward: block-reward,
                mined: false
            })
            
        ;; Calculate new reward pool safely
        (let ((new-pool (+ (var-get total-reward-pool) block-reward)))
            (asserts! (>= new-pool (var-get total-reward-pool)) ERR-INVALID-PARAMETER)
            (var-set total-reward-pool new-pool))
        (ok true)))

;; Miner Onboarding
(define-public (register-as-miner)
    (begin
        (asserts! (var-get network-active) ERR-NETWORK-PAUSED)
        
        (map-set miner-profiles tx-sender
            {
                assigned-block: u0,
                mined-blocks: (list),
                last-activity: (var-get chain-height),
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
        (current-height (var-get chain-height))
        )
        ;; Check block availability
        (asserts! (var-get network-active) ERR-NETWORK-PAUSED)
        (asserts! (>= current-height (get timeout block)) ERR-TIMEOUT-ACTIVE)
        (asserts! (not (get mined block)) ERR-BLOCK-ALREADY-MINED)
        
        ;; Update mining attempt record
        (match (map-get? block-mining-records {block-id: block-id, miner: tx-sender})
            record (map-set block-mining-records
                {block-id: block-id, miner: tx-sender}
                {
                    attempts: (+ (get attempts record) u1),
                    mined-at: none
                })
            (map-set block-mining-records
                {block-id: block-id, miner: tx-sender}
                {
                    attempts: u1,
                    mined-at: none
                }))
        
        ;; Verify solution nonce
        (if (is-eq nonce-solution (get solution-nonce block))
            (begin
                ;; Update block status
                (map-set block-registry block-id
                    (merge block {mined: true}))
                
                ;; Update miner profile
                (map-set miner-profiles tx-sender
                    (merge miner {
                        assigned-block: (+ block-id u1),
                        mined-blocks: (unwrap! (as-max-len? 
                            (append (get mined-blocks miner) block-id) u15)
                            ERR-INVALID-BLOCK),
                        last-activity: current-height,
                        total-mined: (+ (get total-mined miner) u1)
                    }))
                
                ;; Update mining record
                (map-set block-mining-records
                    {block-id: block-id, miner: tx-sender}
                    {
                        attempts: (get attempts (default-to 
                            {attempts: u1, mined-at: none}
                            (map-get? block-mining-records {block-id: block-id, miner: tx-sender}))),
                        mined-at: (some current-height)
                    })
                
                ;; Distribute block reward
                (try! (stx-transfer? (get block-reward block) (var-get network-coordinator) tx-sender))
                
                (ok true))
            ERR-INVALID-NONCE)))

;; Read-only functions
(define-read-only (get-block-target (block-id uint))
    (match (map-get? block-registry block-id)
        block (if (>= (var-get chain-height) (get timeout block))
            (ok (get target-hash block))
            ERR-TIMEOUT-ACTIVE)
        ERR-INVALID-BLOCK))

(define-read-only (get-miner-status (miner principal))
    (map-get? miner-profiles miner))

(define-read-only (get-miner-history (miner principal) (block-id uint))
    (map-get? block-mining-records {block-id: block-id, miner: miner}))

(define-read-only (get-current-height)
    (var-get chain-height))

(define-read-only (get-network-stats)
    {
        active: (var-get network-active),
        current-difficulty: (var-get current-difficulty),
        total-reward-pool: (var-get total-reward-pool),
        chain-height: (var-get chain-height)
    })