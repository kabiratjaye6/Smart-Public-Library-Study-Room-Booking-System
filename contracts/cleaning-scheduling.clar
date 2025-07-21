;; Cleaning Scheduling Contract
;; Coordinates daily room sanitization and maintenance

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u500))
(define-constant ERR-TASK-NOT-FOUND (err u501))
(define-constant ERR-INVALID-PRIORITY (err u502))
(define-constant ERR-ALREADY-COMPLETED (err u503))
(define-constant ERR-INVALID-ROOM (err u504))
(define-constant ERR-STAFF-NOT-FOUND (err u505))

;; Data Variables
(define-data-var next-task-id uint u1)
(define-data-var daily-schedule-active bool true)

;; Data Maps
(define-map cleaning-staff
  { staff-id: principal }
  {
    name: (string-ascii 50),
    shift-start: uint,
    shift-end: uint,
    specializations: (string-ascii 100),
    is-active: bool
  }
)

(define-map cleaning-tasks
  { task-id: uint }
  {
    room-id: uint,
    task-type: (string-ascii 30),
    priority: uint,
    assigned-staff: (optional principal),
    scheduled-time: uint,
    estimated-duration: uint,
    actual-start: (optional uint),
    completion-time: (optional uint),
    status: (string-ascii 15),
    notes: (optional (string-ascii 200))
  }
)

(define-map room-cleaning-schedule
  { room-id: uint, date: uint }
  {
    morning-clean: bool,
    afternoon-clean: bool,
    deep-clean: bool,
    maintenance-required: bool,
    last-cleaned: uint
  }
)

(define-map emergency-requests
  { request-id: uint }
  {
    room-id: uint,
    requester: principal,
    urgency: uint,
    description: (string-ascii 200),
    requested-at: uint,
    assigned-task-id: (optional uint),
    status: (string-ascii 15)
  }
)

(define-map cleaning-supplies
  { supply-id: uint }
  {
    supply-name: (string-ascii 30),
    current-stock: uint,
    minimum-threshold: uint,
    last-restocked: uint,
    cost-per-unit: uint
  }
)

;; Private Functions
(define-private (is-valid-priority (priority uint))
  (and (>= priority u1) (<= priority u5))
)

(define-private (is-staff-available (staff-id principal) (scheduled-time uint))
  (match (map-get? cleaning-staff { staff-id: staff-id })
    staff-data
    (and (get is-active staff-data)
         (>= scheduled-time (get shift-start staff-data))
         (<= scheduled-time (get shift-end staff-data)))
    false)
)

(define-private (update-room-schedule (room-id uint) (task-type (string-ascii 30)))
  (let ((today (/ block-height u144))) ;; Approximate daily blocks
    (match (map-get? room-cleaning-schedule { room-id: room-id, date: today })
      schedule-data
      (map-set room-cleaning-schedule
               { room-id: room-id, date: today }
               (merge schedule-data {
                 morning-clean: (or (get morning-clean schedule-data) (is-eq task-type "morning-clean")),
                 afternoon-clean: (or (get afternoon-clean schedule-data) (is-eq task-type "afternoon-clean")),
                 deep-clean: (or (get deep-clean schedule-data) (is-eq task-type "deep-clean")),
                 last-cleaned: block-height
               }))
      (map-set room-cleaning-schedule
               { room-id: room-id, date: today }
               {
                 morning-clean: (is-eq task-type "morning-clean"),
                 afternoon-clean: (is-eq task-type "afternoon-clean"),
                 deep-clean: (is-eq task-type "deep-clean"),
                 maintenance-required: false,
                 last-cleaned: block-height
               })))
)

;; Public Functions
(define-public (register-cleaning-staff (staff-id principal) (name (string-ascii 50)) (shift-start uint) (shift-end uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (ok (map-set cleaning-staff
                 { staff-id: staff-id }
                 {
                   name: name,
                   shift-start: shift-start,
                   shift-end: shift-end,
                   specializations: "",
                   is-active: true
                 }))
  )
)

(define-public (schedule-cleaning-task (room-id uint) (task-type (string-ascii 30)) (priority uint) (scheduled-time uint) (duration uint))
  (let ((task-id (var-get next-task-id)))
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (is-valid-priority priority) ERR-INVALID-PRIORITY)

    (map-set cleaning-tasks
             { task-id: task-id }
             {
               room-id: room-id,
               task-type: task-type,
               priority: priority,
               assigned-staff: none,
               scheduled-time: scheduled-time,
               estimated-duration: duration,
               actual-start: none,
               completion-time: none,
               status: "scheduled",
               notes: none
             })

    (var-set next-task-id (+ task-id u1))
    (ok task-id)
  )
)

(define-public (assign-task-to-staff (task-id uint) (staff-id principal))
  (let (
    (task-data (unwrap! (map-get? cleaning-tasks { task-id: task-id }) ERR-TASK-NOT-FOUND))
  )
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (is-some (map-get? cleaning-staff { staff-id: staff-id })) ERR-STAFF-NOT-FOUND)
    (asserts! (is-staff-available staff-id (get scheduled-time task-data)) ERR-NOT-AUTHORIZED)

    (map-set cleaning-tasks
             { task-id: task-id }
             (merge task-data {
               assigned-staff: (some staff-id),
               status: "assigned"
             }))
    (ok true)
  )
)

(define-public (start-cleaning-task (task-id uint))
  (let (
    (task-data (unwrap! (map-get? cleaning-tasks { task-id: task-id }) ERR-TASK-NOT-FOUND))
  )
    (asserts! (is-some (get assigned-staff task-data)) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (unwrap-panic (get assigned-staff task-data)) tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get status task-data) "assigned") ERR-ALREADY-COMPLETED)

    (map-set cleaning-tasks
             { task-id: task-id }
             (merge task-data {
               actual-start: (some block-height),
               status: "in-progress"
             }))
    (ok true)
  )
)

(define-public (complete-cleaning-task (task-id uint) (notes (string-ascii 200)))
  (let (
    (task-data (unwrap! (map-get? cleaning-tasks { task-id: task-id }) ERR-TASK-NOT-FOUND))
  )
    (asserts! (is-some (get assigned-staff task-data)) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (unwrap-panic (get assigned-staff task-data)) tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get status task-data) "in-progress") ERR-ALREADY-COMPLETED)

    (map-set cleaning-tasks
             { task-id: task-id }
             (merge task-data {
               completion-time: (some block-height),
               status: "completed",
               notes: (some notes)
             }))

    (update-room-schedule (get room-id task-data) (get task-type task-data))
    (ok true)
  )
)

(define-public (request-emergency-cleaning (room-id uint) (urgency uint) (description (string-ascii 200)))
  (let ((request-id (var-get next-task-id))) ;; Reusing task ID counter
    (asserts! (is-valid-priority urgency) ERR-INVALID-PRIORITY)

    (map-set emergency-requests
             { request-id: request-id }
             {
               room-id: room-id,
               requester: tx-sender,
               urgency: urgency,
               description: description,
               requested-at: block-height,
               assigned-task-id: none,
               status: "pending"
             })

    (var-set next-task-id (+ request-id u1))
    (ok request-id)
  )
)

(define-public (update-supply-inventory (supply-id uint) (new-stock uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (match (map-get? cleaning-supplies { supply-id: supply-id })
      supply-data
      (begin
        (map-set cleaning-supplies
                 { supply-id: supply-id }
                 (merge supply-data {
                   current-stock: new-stock,
                   last-restocked: block-height
                 }))
        (ok true))
      (ok false))
  )
)

;; Read-only Functions
(define-read-only (get-cleaning-task (task-id uint))
  (map-get? cleaning-tasks { task-id: task-id })
)

(define-read-only (get-staff-info (staff-id principal))
  (map-get? cleaning-staff { staff-id: staff-id })
)

(define-read-only (get-room-schedule (room-id uint) (date uint))
  (map-get? room-cleaning-schedule { room-id: room-id, date: date })
)

(define-read-only (get-emergency-request (request-id uint))
  (map-get? emergency-requests { request-id: request-id })
)

(define-read-only (get-supply-status (supply-id uint))
  (map-get? cleaning-supplies { supply-id: supply-id })
)

(define-read-only (is-room-cleaned-today (room-id uint))
  (let ((today (/ block-height u144)))
    (match (map-get? room-cleaning-schedule { room-id: room-id, date: today })
      schedule-data (or (get morning-clean schedule-data) (get afternoon-clean schedule-data))
      false))
)

(define-read-only (get-pending-tasks-count)
  ;; This would require iteration in a real implementation
  ;; For now, returns a placeholder
  u0
)
