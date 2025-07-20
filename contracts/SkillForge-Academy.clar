;; SkillForge Academy: Decentralized skill certification platform with mentor validation
;; Enables instructors to create courses, students to enroll, and mentors to certify achievements

(define-data-var lead-mentor principal tx-sender)

(define-map course-registry
  { course-id: uint }
  {
    instructor: principal,
    enrollment-cost: uint,
    course-title: (string-ascii 50),
    curriculum: (string-ascii 500),
    duration-weeks: uint,
    certified: bool
  }
)

(define-map enrollment-records
  { course-id: uint, record-id: uint }
  {
    student: principal,
    enrollment-date: uint,
    status: (string-ascii 20)
  }
)

(define-data-var next-course-id uint u1)

(define-map record-tracker
  { course-id: uint }
  { records: uint }
)

;; Create a new skill course
(define-public (create-course (title-input (string-ascii 50)) (curriculum-input (string-ascii 500)) (weeks-input uint) (cost-input uint))
  (let
    (
      (course-id (var-get next-course-id))
      (record-id u0)
      (title title-input)
      (curriculum curriculum-input)
      (weeks weeks-input)
      (cost cost-input)
    )
    ;; Input validation
    (asserts! (> cost u0) (err u1))
    (asserts! (> (len title) u0) (err u5))
    (asserts! (> (len curriculum) u0) (err u6))
    (asserts! (> weeks u0) (err u7))
    
    (map-set course-registry
      { course-id: course-id }
      {
        instructor: tx-sender,
        enrollment-cost: cost,
        course-title: title,
        curriculum: curriculum,
        duration-weeks: weeks,
        certified: false
      }
    )
    (map-set enrollment-records
      { course-id: course-id, record-id: record-id }
      {
        student: tx-sender,
        enrollment-date: course-id,
        status: "created"
      }
    )
    (map-set record-tracker
      { course-id: course-id }
      { records: u1 }
    )
    (var-set next-course-id (+ course-id u1))
    (ok course-id)
  )
)

;; Enroll in a skill course
(define-public (enroll-course (course-id-input uint))
  (let
    (
      (course-id course-id-input)
      (course-info (unwrap! (map-get? course-registry { course-id: course-id }) (err u2)))
      (cost (get enrollment-cost course-info))
      (instructor (get instructor course-info))
      (record-data (default-to { records: u0 } (map-get? record-tracker { course-id: course-id })))
      (record-id (get records record-data))
      (new-record-id (+ record-id u1))
    )
    ;; Input validation
    (asserts! (> course-id u0) (err u8))
    (asserts! (not (is-eq tx-sender instructor)) (err u3))
    
    (try! (stx-transfer? cost tx-sender instructor))
    (map-set enrollment-records
      { course-id: course-id, record-id: record-id }
      {
        student: tx-sender,
        enrollment-date: (var-get next-course-id),
        status: "enrolled"
      }
    )
    (map-set record-tracker
      { course-id: course-id }
      { records: new-record-id }
    )
    (ok true)
  )
)

;; Certify a course (lead mentor only)
(define-public (certify-course (course-id-input uint))
  (let
    (
      (course-id course-id-input)
      (course-info (unwrap! (map-get? course-registry { course-id: course-id }) (err u2)))
      (record-data (default-to { records: u0 } (map-get? record-tracker { course-id: course-id })))
      (record-id (get records record-data))
      (new-record-id (+ record-id u1))
    )
    ;; Input validation
    (asserts! (> course-id u0) (err u8))
    (asserts! (is-eq tx-sender (var-get lead-mentor)) (err u4))
    
    (map-set course-registry
      { course-id: course-id }
      (merge course-info { certified: true })
    )
    (map-set enrollment-records
      { course-id: course-id, record-id: record-id }
      {
        student: (get instructor course-info),
        enrollment-date: (var-get next-course-id),
        status: "certified"
      }
    )
    (map-set record-tracker
      { course-id: course-id }
      { records: new-record-id }
    )
    (ok true)
  )
)

;; Get course details
(define-read-only (get-course (course-id uint))
  (map-get? course-registry { course-id: course-id })
)

;; Get enrollment record entry
(define-read-only (get-enrollment-record (course-id uint) (record-id uint))
  (map-get? enrollment-records { course-id: course-id, record-id: record-id })
)

;; Get total enrollment records for a course
(define-read-only (get-enrollment-count (course-id uint))
  (let
    (
      (record-data (default-to { records: u0 } (map-get? record-tracker { course-id: course-id })))
    )
    (get records record-data)
  )
)
