#lang racket/base

(require
 (for-syntax
  chk
  racket/base
  cur/curnel/racket-impl/eval
  cur/curnel/racket-impl/equiv
  cur/curnel/racket-impl/stxutils)
 cur/curnel/racket-impl/runtime
 "runtime.rkt")
(begin-for-syntax

  (chk
   ; cur-eval tests
   #:eq cur-α-equal?
   (cur-eval (local-expand-expr #'(cur-Type 0)))
   (local-expand-expr #'(cur-Type '0))
   #:eq cur-α-equal?
   (cur-eval (local-expand-expr #'two))
   (local-expand-expr #'(cur-apply s (cur-apply s z)))
   #:eq cur-α-equal?
   (cur-eval (local-expand-expr #'(cur-apply (cur-λ (cur-Type 0) (lambda (x) x)) z)))
   #'z
   #:eq cur-α-equal?
   (cur-eval (local-expand-expr #'(cur-apply (cur-apply plus z) (cur-apply s z))))
   (local-expand-expr #'(cur-apply s z))))