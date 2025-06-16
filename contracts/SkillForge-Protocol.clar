;; SkillForge: Decentralized Skill Learning & Certification Protocol
;; Version: 1.0.0
;; A protocol that enables users to create courses, stake tokens for learning commitments,
;; and earn verifiable on-chain certifications upon completion

;; Error constants
(define-constant ERR-NOT-AUTHORIZED (err u1))
(define-constant ERR-COURSE-NOT-FOUND (err u2))
(define-constant ERR-INVALID-PRICE (err u3))
(define-constant ERR-INVALID-DURATION (err u4))
(define-constant ERR-INVALID-TITLE (err u5))
(define-constant ERR-INVALID-DESCRIPTION (err u6))
(define-constant ERR-COURSE-INACTIVE (err u7))
(define-constant ERR-ALREADY-ENROLLED (err u8))
(define-constant ERR-NOT-ENROLLED (err u9))
(define-constant ERR-INSUFFICIENT-FUNDS (err u10))
(define-constant ERR-COURSE-NOT-COMPLETED (err u11))
(define-constant ERR-ALREADY-CERTIFIED (err u12))
(define-constant ERR-INVALID-CATEGORY (err u13))
(define-constant ERR-INVALID-DIFFICULTY (err u14))
(define-constant ERR-ENROLLMENT-EXPIRED (err u15))
(define-constant ERR-INVALID-PROGRESS (err u16))

;; Constants
(define-constant MIN-PRICE u1000000) ;; 1 STX minimum
(define-constant MAX-PRICE u1000000000000) ;; 1M STX maximum
(define-constant MIN-DURATION u86400) ;; 1 day minimum
(define-constant MAX-DURATION u31536000) ;; 1 year maximum
(define-constant PLATFORM-FEE-PERCENT u5) ;; 5% platform fee
(define-constant COMPLETION-THRESHOLD u80) ;; 80% minimum progress for certification

;; Data variables
(define-data-var next-course-id uint u1)
(define-data-var next-enrollment-id uint u1)
(define-data-var platform-treasury principal tx-sender)
(define-data-var total-platform-fees uint u0)

;; Course data structure
(define-map courses
    uint
    {
        instructor: principal,
        title: (string-utf8 100),
        description: (string-utf8 500),
        category: (string-utf8 20),
        difficulty: (string-utf8 10),
        price: uint,
        stake-amount: uint,
        duration: uint,
        is-active: bool,
        total-enrolled: uint,
        total-certified: uint,
        created-at: uint
    }
)

;; Enrollment data structure
(define-map enrollments
    uint
    {
        student: principal,
        course-id: uint,
        enrolled-at: uint,
        expires-at: uint,
        progress: uint,
        is-completed: bool,
        is-certified: bool,
        stake-locked: uint
    }
)

;; Student enrollments by course
(define-map student-course-enrollments
    { student: principal, course-id: uint }
    uint
)

;; Certification records
(define-map certifications
    { student: principal, course-id: uint }
    {
        certified-at: uint,
        final-score: uint,
        certificate-hash: (string-utf8 64)
    }
)

;; Private validation functions
(define-private (validate-category (category (string-utf8 20)))
    (or 
        (is-eq category u"Programming")
        (is-eq category u"Design")
        (is-eq category u"Marketing")
        (is-eq category u"Finance")
        (is-eq category u"Business")
        (is-eq category u"Data Science")
        (is-eq category u"Blockchain")
        (is-eq category u"AI/ML")
    )
)

(define-private (validate-difficulty (difficulty (string-utf8 10)))
    (or 
        (is-eq difficulty u"Beginner")
        (is-eq difficulty u"Intermediate")
        (is-eq difficulty u"Advanced")
        (is-eq difficulty u"Expert")
    )
)

(define-private (validate-text-length (text (string-utf8 500)) (min-length uint) (max-length uint))
    (let 
        (
            (text-length (len text))
        )
        (and 
            (>= text-length min-length)
            (<= text-length max-length)
        )
    )
)

(define-private (calculate-platform-fee (amount uint))
    (/ (* amount PLATFORM-FEE-PERCENT) u100)
)

(define-private (calculate-instructor-amount (amount uint))
    (- amount (calculate-platform-fee amount))
)

;; Public functions

;; Create a new course
(define-public (create-course 
    (title (string-utf8 100))
    (description (string-utf8 500))
    (category (string-utf8 20))
    (difficulty (string-utf8 10))
    (price uint)
    (stake-amount uint)
    (duration uint)
)
    (let
        (
            (course-id (var-get next-course-id))
            (current-time (unwrap-panic (get-stacks-block-info? time (- stacks-block-height u1))))
        )
        ;; Validate inputs
        (asserts! (validate-text-length title u5 u100) ERR-INVALID-TITLE)
        (asserts! (validate-text-length description u20 u500) ERR-INVALID-DESCRIPTION)
        (asserts! (validate-category category) ERR-INVALID-CATEGORY)
        (asserts! (validate-difficulty difficulty) ERR-INVALID-DIFFICULTY)
        (asserts! (and (>= price MIN-PRICE) (<= price MAX-PRICE)) ERR-INVALID-PRICE)
        (asserts! (and (>= duration MIN-DURATION) (<= duration MAX-DURATION)) ERR-INVALID-DURATION)
        
        ;; Create course
        (map-set courses course-id {
            instructor: tx-sender,
            title: title,
            description: description,
            category: category,
            difficulty: difficulty,
            price: price,
            stake-amount: stake-amount,
            duration: duration,
            is-active: true,
            total-enrolled: u0,
            total-certified: u0,
            created-at: current-time
        })
        
        (var-set next-course-id (+ course-id u1))
        (ok course-id)
    )
)

;; Enroll in a course with stake
(define-public (enroll-in-course (course-id uint))
    (let
        (
            (course (unwrap! (map-get? courses course-id) ERR-COURSE-NOT-FOUND))
            (enrollment-id (var-get next-enrollment-id))
            (current-time (unwrap-panic (get-stacks-block-info? time (- stacks-block-height u1))))
            (expires-at (+ current-time (get duration course)))
            (total-cost (+ (get price course) (get stake-amount course)))
            (platform-fee (calculate-platform-fee (get price course)))
            (instructor-amount (calculate-instructor-amount (get price course)))
        )
        ;; Validate course is active
        (asserts! (get is-active course) ERR-COURSE-INACTIVE)
        
        ;; Check if already enrolled
        (asserts! (is-none (map-get? student-course-enrollments { student: tx-sender, course-id: course-id })) ERR-ALREADY-ENROLLED)
        
        ;; Transfer payment to instructor and platform fee
        (try! (stx-transfer? instructor-amount tx-sender (get instructor course)))
        (try! (stx-transfer? platform-fee tx-sender (var-get platform-treasury)))
        
        ;; Lock stake amount (simulated by requiring balance)
        (asserts! (>= (stx-get-balance tx-sender) (get stake-amount course)) ERR-INSUFFICIENT-FUNDS)
        
        ;; Create enrollment
        (map-set enrollments enrollment-id {
            student: tx-sender,
            course-id: course-id,
            enrolled-at: current-time,
            expires-at: expires-at,
            progress: u0,
            is-completed: false,
            is-certified: false,
            stake-locked: (get stake-amount course)
        })
        
        ;; Map student to enrollment
        (map-set student-course-enrollments { student: tx-sender, course-id: course-id } enrollment-id)
        
        ;; Update course stats
        (map-set courses course-id (merge course { total-enrolled: (+ (get total-enrolled course) u1) }))
        
        ;; Update platform fees
        (var-set total-platform-fees (+ (var-get total-platform-fees) platform-fee))
        (var-set next-enrollment-id (+ enrollment-id u1))
        
        (ok enrollment-id)
    )
)

;; Update learning progress
(define-public (update-progress (course-id uint) (progress uint))
    (let
        (
            (enrollment-id (unwrap! (map-get? student-course-enrollments { student: tx-sender, course-id: course-id }) ERR-NOT-ENROLLED))
            (enrollment (unwrap! (map-get? enrollments enrollment-id) ERR-NOT-ENROLLED))
            (current-time (unwrap-panic (get-stacks-block-info? time (- stacks-block-height u1))))
        )
        ;; Validate enrollment is active
        (asserts! (< current-time (get expires-at enrollment)) ERR-ENROLLMENT-EXPIRED)
        (asserts! (<= progress u100) ERR-INVALID-PROGRESS)
        (asserts! (>= progress (get progress enrollment)) ERR-INVALID-PROGRESS)
        
        ;; Update progress
        (map-set enrollments enrollment-id (merge enrollment { 
            progress: progress,
            is-completed: (>= progress u100)
        }))
        
        (ok true)
    )
)

;; Issue certification
(define-public (issue-certification (course-id uint) (certificate-hash (string-utf8 64)))
    (let
        (
            (enrollment-id (unwrap! (map-get? student-course-enrollments { student: tx-sender, course-id: course-id }) ERR-NOT-ENROLLED))
            (enrollment (unwrap! (map-get? enrollments enrollment-id) ERR-NOT-ENROLLED))
            (course (unwrap! (map-get? courses course-id) ERR-COURSE-NOT-FOUND))
            (current-time (unwrap-panic (get-stacks-block-info? time (- stacks-block-height u1))))
        )
        ;; Validate completion and progress
        (asserts! (get is-completed enrollment) ERR-COURSE-NOT-COMPLETED)
        (asserts! (>= (get progress enrollment) COMPLETION-THRESHOLD) ERR-COURSE-NOT-COMPLETED)
        (asserts! (not (get is-certified enrollment)) ERR-ALREADY-CERTIFIED)
        
        ;; Issue certification
        (map-set certifications { student: tx-sender, course-id: course-id } {
            certified-at: current-time,
            final-score: (get progress enrollment),
            certificate-hash: certificate-hash
        })
        
        ;; Update enrollment
        (map-set enrollments enrollment-id (merge enrollment { is-certified: true }))
        
        ;; Update course stats
        (map-set courses course-id (merge course { total-certified: (+ (get total-certified course) u1) }))
        
        ;; Return stake to student (simulated)
        (ok true)
    )
)

;; Deactivate course (instructor only)
(define-public (deactivate-course (course-id uint))
    (let
        (
            (course (unwrap! (map-get? courses course-id) ERR-COURSE-NOT-FOUND))
        )
        (asserts! (is-eq tx-sender (get instructor course)) ERR-NOT-AUTHORIZED)
        (map-set courses course-id (merge course { is-active: false }))
        (ok true)
    )
)

;; Read-only functions

(define-read-only (get-course (course-id uint))
    (map-get? courses course-id)
)

(define-read-only (get-enrollment (enrollment-id uint))
    (map-get? enrollments enrollment-id)
)

(define-read-only (get-student-enrollment (student principal) (course-id uint))
    (match (map-get? student-course-enrollments { student: student, course-id: course-id })
        enrollment-id (map-get? enrollments enrollment-id)
        none
    )
)

(define-read-only (get-certification (student principal) (course-id uint))
    (map-get? certifications { student: student, course-id: course-id })
)

(define-read-only (is-student-certified (student principal) (course-id uint))
    (is-some (map-get? certifications { student: student, course-id: course-id }))
)

(define-read-only (get-course-stats (course-id uint))
    (match (map-get? courses course-id)
        course {
            total-enrolled: (get total-enrolled course),
            total-certified: (get total-certified course),
            completion-rate: (if (> (get total-enrolled course) u0)
                (/ (* (get total-certified course) u100) (get total-enrolled course))
                u0
            )
        }
        { total-enrolled: u0, total-certified: u0, completion-rate: u0 }
    )
)

(define-read-only (get-platform-stats)
    {
        total-courses: (- (var-get next-course-id) u1),
        total-enrollments: (- (var-get next-enrollment-id) u1),
        total-platform-fees: (var-get total-platform-fees),
        platform-treasury: (var-get platform-treasury)
    }
)

(define-read-only (calculate-course-cost (course-id uint))
    (match (map-get? courses course-id)
        course {
            price: (get price course),
            stake: (get stake-amount course),
            total: (+ (get price course) (get stake-amount course)),
            platform-fee: (calculate-platform-fee (get price course)),
            instructor-amount: (calculate-instructor-amount (get price course))
        }
        { price: u0, stake: u0, total: u0, platform-fee: u0, instructor-amount: u0 }
    )
)