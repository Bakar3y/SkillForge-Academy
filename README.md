# SkillForge Academy

A decentralized skill certification platform built on Stacks blockchain that enables instructors to create courses, students to enroll with STX payments, and mentors to validate and certify achievements.

## Features

- Course creation with customizable curriculum and pricing
- Secure STX-based enrollment system
- Mentor-validated certification process
- Transparent enrollment tracking
- Decentralized skill verification

## Smart Contract Functions

### Public Functions
- `create-course`: Create new skill courses
- `enroll-course`: Enroll in courses with STX payment
- `certify-course`: Validate courses (mentor only)

### Read-Only Functions
- `get-course`: Retrieve course details
- `get-enrollment-record`: Get enrollment history
- `get-enrollment-count`: View total enrollments

## Getting Started

1. Deploy the contract to Stacks blockchain
2. Set lead mentor address
3. Create courses with curriculum and pricing
4. Students can enroll and pay with STX
5. Mentors certify completed courses

## License

MIT License
```

**PR Title:** feat: implement SkillForge Academy decentralized certification platform

**PR Description:**
Introduces a comprehensive skill certification platform with course creation, STX-based enrollment, and mentor validation system. Features secure payment processing, transparent tracking, and decentralized certification management for educational content delivery.

**README Commit:** docs: add comprehensive documentation for SkillForge Academy platform

**Code Commit:** feat: implement core certification platform with enrollment and validation

**Branch Name:** feature/skillforge-academy-platform

---

## PROJECT 2: ARTISAN MARKETPLACE

<CodeProject id="skillforge-academy">

```clarity file="contracts/artisan-marketplace.clar"
;; Artisan Marketplace: Decentralized craft marketplace with quality assurance
;; Enables artisans to list products, buyers to purchase, and curators to verify authenticity

(define-data-var chief-curator principal tx-sender)

(define-map product-catalog
  { product-id: uint }
  {
    artisan: principal,
    listing-price: uint,
    product-name: (string-ascii 50),
    description: (string-ascii 500),
    craft-time-hours: uint,
    authenticated: bool
  }
)

(define-map transaction-history
  { product-id: uint, transaction-id: uint }
  {
    buyer: principal,
    purchase-date: uint,
    order-status: (string-ascii 20)
  }
)

(define-data-var next-product-id uint u1)

(define-map transaction-counter
  { product-id: uint }
  { transactions: uint }
)

;; List a new artisan product
(define-public (list-product (name-input (string-ascii 50)) (description-input (string-ascii 500)) (hours-input uint) (price-input uint))
  (let
    (
      (product-id (var-get next-product-id))
      (transaction-id u0)
      (name name-input)
      (description description-input)
      (hours hours-input)
      (price price-input)
    )
    ;; Input validation
    (asserts! (> price u0) (err u1))
    (asserts! (> (len name) u0) (err u5))
    (asserts! (> (len description) u0) (err u6))
    (asserts! (> hours u0) (err u7))
    
    (map-set product-catalog
      { product-id: product-id }
      {
        artisan: tx-sender,
        listing-price: price,
        product-name: name,
        description: description,
        craft-time-hours: hours,
        authenticated: false
      }
    )
    (map-set transaction-history
      { product-id: product-id, transaction-id: transaction-id }
      {
        buyer: tx-sender,
        purchase-date: product-id,
        order-status: "listed"
      }
    )
    (map-set transaction-counter
      { product-id: product-id }
      { transactions: u1 }
    )
    (var-set next-product-id (+ product-id u1))
    (ok product-id)
  )
)

;; Purchase an artisan product
(define-public (purchase-product (product-id-input uint))
  (let
    (
      (product-id product-id-input)
      (product-info (unwrap! (map-get? product-catalog { product-id: product-id }) (err u2)))
      (price (get listing-price product-info))
      (artisan (get artisan product-info))
      (transaction-data (default-to { transactions: u0 } (map-get? transaction-counter { product-id: product-id })))
      (transaction-id (get transactions transaction-data))
      (new-transaction-id (+ transaction-id u1))
    )
    ;; Input validation
    (asserts! (> product-id u0) (err u8))
    (asserts! (not (is-eq tx-sender artisan)) (err u3))
    
    (try! (stx-transfer? price tx-sender artisan))
    (map-set transaction-history
      { product-id: product-id, transaction-id: transaction-id }
      {
        buyer: tx-sender,
        purchase-date: (var-get next-product-id),
        order-status: "purchased"
      }
    )
    (map-set transaction-counter
      { product-id: product-id }
      { transactions: new-transaction-id }
    )
    (ok true)
  )
)

;; Authenticate a product (chief curator only)
(define-public (authenticate-product (product-id-input uint))
  (let
    (
      (product-id product-id-input)
      (product-info (unwrap! (map-get? product-catalog { product-id: product-id }) (err u2)))
      (transaction-data (default-to { transactions: u0 } (map-get? transaction-counter { product-id: product-id })))
      (transaction-id (get transactions transaction-data))
      (new-transaction-id (+ transaction-id u1))
    )
    ;; Input validation
    (asserts! (> product-id u0) (err u8))
    (asserts! (is-eq tx-sender (var-get chief-curator)) (err u4))
    
    (map-set product-catalog
      { product-id: product-id }
      (merge product-info { authenticated: true })
    )
    (map-set transaction-history
      { product-id: product-id, transaction-id: transaction-id }
      {
        buyer: (get artisan product-info),
        purchase-date: (var-get next-product-id),
        order-status: "authenticated"
      }
    )
    (map-set transaction-counter
      { product-id: product-id }
      { transactions: new-transaction-id }
    )
    (ok true)
  )
)

;; Get product details
(define-read-only (get-product (product-id uint))
  (map-get? product-catalog { product-id: product-id })
)

;; Get transaction history entry
(define-read-only (get-transaction-history (product-id uint) (transaction-id uint))
  (map-get? transaction-history { product-id: product-id, transaction-id: transaction-id })
)

;; Get total transactions for a product
(define-read-only (get-transaction-count (product-id uint))
  (let
    (
      (transaction-data (default-to { transactions: u0 } (map-get? transaction-counter { product-id: product-id })))
    )
    (get transactions transaction-data)
  )
)