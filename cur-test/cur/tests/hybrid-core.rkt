#lang racket/base
;; TODO: Copy-paste of redex-core
(require
 redex/reduction-semantics
 cur/curnel/hybrid-core
 rackunit
 racket/function
 (only-in racket/set set=?))
(define-syntax-rule (check-holds (e ...))
  (check-true
   (judgment-holds (e ...))))
(define-syntax-rule (check-not-holds (e ...))
  (check-false
   (judgment-holds (e ...))))
(define-syntax-rule (check-equiv? e1 e2)
  (check (default-equiv) e1 e2))
(define-syntax-rule (check-not-equiv? e1 e2)
  (check (compose not (default-equiv)) e1 e2))

(default-equiv (lambda (x y) (term (α-equivalent? ,x ,y))))

;; Syntax tests
;; ------------------------------------------------------------------------

(define-term Type (Unv 0))
(check-true (x? (term T)))
(check-true (x? (term A)))
(check-true (x? (term truth)))
(check-true (x? (term zero)))
(check-true (x? (term s)))
(check-true (t? (term zero)))
(check-true (t? (term s)))
(check-true (x? (term nat)))
(check-true (t? (term nat)))
(check-true (t? (term A)))
(check-true (t? (term S)))
(check-true (U? (term (Unv 0))))
(check-true (U? (term Type)))
(check-true (e? (term (λ (x_0 : (Unv 0)) x_0))))
(check-true (t? (term (λ (x_0 : (Unv 0)) x_0))))
(check-true (t? (term (λ (x_0 : (Unv 0)) x_0))))

;; TODO: Rename these signatures, and use them in all future tests.
(define Δ (term (Δ-set* ,(make-empty-Δ)
                 (nat (Unv 0) ((zero : nat) (s : (Π (x : nat) nat))))
                 (bool (Unv 0) ((true : bool) (false : bool))))))
(define Δ0 (make-empty-Δ))
(define Δ3 (term (Δ-set ,(make-empty-Δ) and (Π (A : (Unv 0)) (Π (B : (Unv 0)) (Unv 0))) ())))
(define Δ4 (term (Δ-set ,(make-empty-Δ) and (Π (A : (Unv 0)) (Π (B : (Unv 0)) (Unv 0)))
                         ((conj : (Π (A : (Unv 0)) (Π (B : (Unv 0)) (Π (a : A) (Π (b : B) ((and A) B))))))))))
(check-true (Δ? Δ0))
(check-true (Δ? Δ))
(check-true (Δ? Δ4))
(check-true (Δ? Δ3))
(check-true (Δ? Δ4))
(define sigma (term (Δ-set* ,(make-empty-Δ)
                            (true (Unv 0) ((T : true)))
                            (false (Unv 0) ())
                            (equal (Π (A : (Unv 0)) (Π (B : (Unv 0)) (Unv 0)))
                                   ())
                            (nat (Unv 0) ())
                            (heap (Unv 0) ())
                            (pre (Π (temp808 : heap) (Unv 0)) ()))))
(check-true (Δ? (term (Δ-set* ,(make-empty-Δ) (true (Unv 0) ((T : true)))))))
(check-true (Δ? (term (Δ-set* ,(make-empty-Δ) (false (Unv 0) ())))))
(check-true (Δ? (term (Δ-set* ,(make-empty-Δ) (equal (Π (A : (Unv 0)) (Π (B : (Unv 0)) (Unv 0)))
                                ())))))
(check-true (Δ? (term (Δ-set* ,(make-empty-Δ) (nat (Unv 0) ())))))
(check-true (Δ? (term (Δ-set* ,(make-empty-Δ) (pre (Π (temp808 : heap) (Unv 0)) ())))))

(check-true (Δ? (term (Δ-set* ,(make-empty-Δ) (true (Unv 0) ((T : true))) (false (Unv 0) ())))))
(check-true (Δ? (term (Δ-set* ,(make-empty-Δ)
                              (true (Unv 0) ((T : true)))
                              (false (Unv 0) ())
                              (equal (Π (A : (Unv 0)) (Π (B : (Unv 0)) (Unv 0)))
                                     ())))))
(check-true (Δ? sigma))
(check-true (t? (term (Π (a : A) (Π (b : B) ((and A) B))))))


;; α-equiv and subst tests
;; ------------------------------------------------------------------------
(check-true
 (term
  (α-equivalent?
   (Π (a : S) (Π (b : B) ((and S) B)))
   (subst (Π (a : A) (Π (b : B) ((and A) B))) A S))))

;; Various accessor tests
;; ------------------------------------------------------------------------

(check-equal?
 (term (Δ-key-by-constructor ,Δ zero))
 (term nat))
(check-equal?
 (term (Δ-key-by-constructor ,Δ s))
 (term nat))

(check-equal?
 (term (Δ-ref-constructor-map ,Δ nat))
 (term ((zero : nat) (s : (Π (x : nat) nat)))))
(check-equal?
 (term (Δ-ref-constructor-map ,sigma false))
 (term ()))

;; Telescope tests
;; ------------------------------------------------------------------------
;; Are these telescopes the same when filled with alpha-equivalent, and equivalently renamed, termed
(define (telescope-equiv x y)
  (alpha-equivalent? ttL (term (in-hole ,x (Unv 0))) (term (in-hole ,y (Unv 0)))))
(define-syntax-rule (check-telescope-equiv? e1 e2)
  (check telescope-equiv e1 e2))
(define-syntax-rule (check-telescope-not-equiv? e1 e2)
  (check (compose not telescope-equiv) e1 e2))

(check-telescope-equiv?
 (term (Δ-ref-parameter-Ξ ,Δ nat))
 (term hole))
(check-telescope-equiv?
 (term (Δ-ref-parameter-Ξ ,Δ4 and))
 (term (Π (A : Type) (Π (B : Type) hole))))

(check-telescope-equiv?
 (term (Ξ-compose
        (Π (x : t_0) (Π (y : t_1) hole))
        (Π (z : t_2) (Π (a : t_3) hole))))
 (term (Π (x : t_0) (Π (y : t_1) (Π (z : t_2) (Π (a : t_3) hole))))))

(check-telescope-equiv?
 (term (Δ-methods-telescope ,Δ nat (λ (x : nat) nat)))
 (term (Π (m-zero : ((λ (x : nat) nat) zero))
          (Π (m-s : (Π (x : nat) (Π (x-ih : ((λ (x : nat) nat) x)) ((λ (x : nat) nat) (s x))))) hole))))
(check-telescope-equiv?
 (term (Δ-methods-telescope ,Δ nat P))
 (term (Π (m-zero : (P zero))
          (Π (m-s : (Π (x : nat) (Π (ih-x : (P x)) (P (s x)))))
             hole))))
(check-telescope-equiv?
 (term (Δ-methods-telescope ,Δ  nat (λ (x : nat) nat)))
 (term (Π (m-zero :  ((λ (x : nat) nat) zero))
          (Π (m-s : (Π (x : nat) (Π (ih-x : ((λ (x : nat) nat) x)) ((λ (x : nat) nat) (s x)))))
             hole))))
(check-telescope-equiv?
 (term (Δ-methods-telescope ,Δ4 and (λ (A : Type) (λ (B : Type) (λ (x : ((and A) B)) true)))))
 (term (Π (m-conj : (Π (A : Type) (Π (B : Type) (Π (a : A) (Π (b : B)
                                                              ((((λ (A : Type) (λ (B : Type) (λ (x : ((and A) B)) true)))
                                                                 A)
                                                                B)
                                                               ((((conj A) B) a) b)))))))
          hole)))
(check-true (x? (term false)))
(check-true (Ξ? (term hole)))
(check-true (t? (term (λ (y : false) (Π (x : Type) x)))))
(check-true (redex-match? ttL ((x : t) ...) (term ())))
(check-telescope-equiv?
 (term (Δ-methods-telescope ,sigma false (λ (y : false) (Π (x : Type) x))))
 (term hole))

;; Tests for inductive elimination
;; ------------------------------------------------------------------------
;; TODO: Insufficient tests, no tests of inductives with parameters, or complex induction.
(check-true
 (redex-match? tt-ctxtL (in-hole Θ_i (hole (in-hole Θ_r zero))) (term (hole zero))))
(check-telescope-equiv?
 (term (Δ-inductive-elim ,Δ nat Type (λ (x : nat) nat) hole
                         ((hole (s zero)) (λ (x : nat) (λ (ih-x : nat) (s (s x)))))
                         (hole zero)))
 (term (hole (((((elim nat Type) (λ (x : nat) nat))
                (s zero))
               (λ (x : nat) (λ (ih-x : nat) (s (s x)))))
              zero))))
(check-telescope-equiv?
 (term (Δ-inductive-elim ,Δ nat Type (λ (x : nat) nat) hole
                         ((hole (s zero)) (λ (x : nat) (λ (ih-x : nat) (s (s x)))))
                         (hole (s zero))))
 (term (hole (((((elim nat Type) (λ (x : nat) nat))
                (s zero))
               (λ (x : nat) (λ (ih-x : nat) (s (s x)))))
              (s zero)))))

;; Tests for dynamic semantics
;; ------------------------------------------------------------------------

(check-true (v? (term (λ (x_0 : (Unv 0)) x_0))))
(check-true (v? (term (refl Nat))))
(check-true (v? (term ((refl Nat) z))))

;; TODO: Move equivalence up here, and use in these tests.
(check-equiv? (term (reduce ∅ (Unv 0))) (term (Unv 0)))
(check-equiv? (term (reduce ∅ ((λ (x : t) x) (Unv 0)))) (term (Unv 0)))
(check-not-equiv? (term (reduce ∅ ((Π (x : t) x) (Unv 0)))) (term (Unv 0)))
(check-not-equiv? (term (reduce ∅ (Π (x : t) ((Π (x_0 : t) x_0) (Unv 0)))))
                  (term (Π (x : t) (Unv 0))))
(check-not-equiv? (term (reduce ∅ (Π (x : t) ((Π (x_0 : t) (x_0 x)) x))))
                  (term (Π (x : t) (x x))))
(check-equiv? (term (reduce ,Δ (((((elim nat Type) (λ (x : nat) nat))
                                  (s zero))
                                 (λ (x : nat) (λ (ih-x : nat)
                                                (s (s x)))))
                                zero)))
              (term (s zero)))
(check-equiv? (term (reduce ,Δ (((((elim nat Type) (λ (x : nat) nat))
                                  (s zero))
                                 (λ (x : nat) (λ (ih-x : nat)
                                                (s (s x)))))
                                (s zero))))
              (term (s (s zero))))
(check-equiv? (term (reduce ,Δ (((((elim nat Type) (λ (x : nat) nat))
                                  (s zero))
                                 (λ (x : nat) (λ (ih-x : nat) (s (s x)))))
                                (s (s (s zero))))))
              (term (s (s (s (s zero))))))

(check-equiv?
 (term (reduce ,Δ
               (((((elim nat Type) (λ (x : nat) nat))
                  (s (s zero)))
                 (λ (x : nat) (λ (ih-x : nat) (s ih-x))))
                (s (s zero)))))
 (term (s (s (s (s zero))))))
(check-equiv?
 (term (step ,Δ
             (((((elim nat Type) (λ (x : nat) nat))
                (s (s zero)))
               (λ (x : nat) (λ (ih-x : nat) (s ih-x))))
              (s (s zero)))))
 (term
  (((λ (x : nat) (λ (ih-x : nat) (s ih-x)))
    (s zero))
   (((((elim nat Type) (λ (x : nat) nat))
      (s (s zero)))
     (λ (x : nat) (λ (ih-x : nat) (s ih-x))))
    (s zero)))))
(check-equiv?
 (term (step ,Δ (step ,Δ
                      (((λ (x : nat) (λ (ih-x : nat) (s ih-x)))
                        (s zero))
                       (((((elim nat Type) (λ (x : nat) nat))
                          (s (s zero)))
                         (λ (x : nat) (λ (ih-x : nat) (s ih-x))))
                        (s zero))))))
 (term
  ((λ (ih-x1 : nat) (s ih-x1))
   (((λ (x : nat) (λ (ih-x : nat) (s ih-x)))
     zero)
    (((((elim nat Type) (λ (x : nat) nat))
       (s (s zero)))
      (λ (x : nat) (λ (ih-x : nat) (s ih-x))))
     zero)))))

(define-syntax-rule (check-equivalent e1 e2)
  (check-holds (equivalent ∅ e1 e2)))
(check-equivalent
 (λ (x : Type) x) (λ (y : Type) y))
(check-equivalent
 (Π (x : Type) x) (Π (y : Type) y))

;; Test static semantics
;; ------------------------------------------------------------------------

(check-true (term (positive* nat (nat))))
(check-true (term (positive* nat ((Π (x : (Unv 0)) (Π (y : (Unv 0)) nat))))))
(check-true (term (positive* nat ((Π (x : nat) nat)))))
;; (nat -> nat) -> nat
;; Not sure if this is actually supposed to pass
(check-false (term (positive* nat ((Π (x : (Π (y : nat) nat)) nat)))))
;; ((Unv 0) -> nat) -> nat
(check-true (term (positive* nat ((Π (x : (Π (y : (Unv 0)) nat)) nat)))))
;; (((nat -> (Unv 0)) -> nat) -> nat)
(check-true (term (positive* nat ((Π (x : (Π (y : (Π (x : nat) (Unv 0))) nat)) nat)))))
;; Not sure if this is actually supposed to pass
;; ((nat -> nat) -> nat) -> nat
(check-false (term (positive* nat ((Π (x : (Π (y : (Π (x : nat) nat)) nat)) nat)))))

(check-true (judgment-holds (wf ,Δ0 ∅)))
(check-true (redex-match? tt-redL (in-hole Ξ (Unv 0)) (term (Unv 0))))
(check-true (redex-match? tt-redL (in-hole Ξ (in-hole Φ (in-hole Θ nat)))
                          (term (Π (x : nat) nat))))
(define (bindings-equal? l1 l2)
  (map set=? l1 l2))
(check-pred
 (curry bindings-equal?
        (list (list
               (make-bind 'Ξ (term (Π (x : nat) hole)))
               (make-bind 'Φ (term hole))
               (make-bind 'Θ (term hole)))
              (list
               (make-bind 'Ξ (term hole))
               (make-bind 'Φ (term (Π (x : nat) hole)))
               (make-bind 'Θ (term hole)))))
 (map match-bindings (redex-match tt-redL (in-hole Ξ (in-hole Φ (in-hole Θ nat)))
                                  (term (Π (x : nat) nat)))))
(check-pred
 (curry bindings-equal?
        (list
         (list
          (make-bind 'Φ (term (Π (x : nat) hole)))
          (make-bind 'Θ (term hole)))))
 (map match-bindings (redex-match tt-redL (in-hole hole (in-hole Φ (in-hole Θ nat)))
                                  (term (Π (x : nat) nat)))))

(check-true
 (redex-match? tt-redL
               (in-hole hole (in-hole hole (in-hole hole nat)))
               (term nat)))
(check-true
 (redex-match? tt-redL
               (in-hole hole (in-hole (Π (x : nat) hole) (in-hole hole nat)))
               (term (Π (x : nat) nat))))
(check-holds (wf (Δ-set ,(make-empty-Δ) nat (Unv 0) ()) ∅))

(check-holds (wf ,Δ0 ∅))
(check-holds (type-infer ,(make-empty-Δ) ∅ (Unv 0) U))
(check-holds (type-infer ,(make-empty-Δ) (∅ nat : (Unv 0)) nat U))
(check-holds (type-infer ,(make-empty-Δ) (∅ nat : (Unv 0)) (Π (x : nat) nat) U))
(check-true (term (positive* nat (nat (Π (x : nat) nat)))))
(check-holds
 (wf (Δ-set ,(make-empty-Δ) nat (Unv 0) ((zero : nat))) ∅))
(check-holds
 (wf (Δ-set ,(make-empty-Δ) nat (Unv 0) ((s : (Π (x : nat) nat)))) ∅))
(check-holds (wf ,Δ ∅))

;; TODO: Poor abstraction w.r.t. Δ
(check-holds (wf ,Δ3 ∅))
(check-holds (wf ,Δ4 ∅))
(check-holds (wf (Δ-set ,(make-empty-Δ) truth (Unv 0) ()) ∅))
(check-holds (wf ,(make-empty-Δ) (∅ x : (Unv 0))))
(check-holds (wf (Δ-set ,(make-empty-Δ) nat (Unv 0) ()) (∅ x : nat)))
(check-holds (wf (Δ-set ,(make-empty-Δ) nat (Unv 0) ()) (∅ x : (Π (x : nat) nat))))

(check-holds (type-infer ,(make-empty-Δ) ∅ (Unv 0) (Unv 1)))
(check-holds (type-infer ,(make-empty-Δ) (∅ x : (Unv 0)) (Unv 0) (Unv 1)))
(check-holds (type-infer ,(make-empty-Δ) (∅ x : (Unv 0)) x (Unv 0)))
(check-holds (type-infer ,(make-empty-Δ) ((∅ x_0 : (Unv 0)) x_1 : (Unv 0))
                           (Π (x_3 : x_0) x_1) (Unv 0)))
(check-holds (type-infer ,(make-empty-Δ) (∅ x_0 : (Unv 0)) x_0 U_1))
(check-holds (type-infer ,(make-empty-Δ) ((∅ x_0 : (Unv 0)) x_2 : x_0) (Unv 0) U_2))
(check-holds (unv-pred (Unv 0) (Unv 0) (Unv 0)))
(check-holds (type-infer ,(make-empty-Δ) (∅ x_0 : (Unv 0)) (Π (x_2 : x_0) (Unv 0)) t))

(check-holds (type-check ,(make-empty-Δ) ∅ (λ (x : (Unv 0)) x) (Π (x : (Unv 0)) (Unv 0))))
(check-holds (type-check ,(make-empty-Δ) ∅ (λ (y : (Unv 0)) (λ (x : y) x))
                             (Π (y : (Unv 0)) (Π (x : y) y))))

(check-equal? (list (term (Unv 1)))
              (judgment-holds
               (type-infer ,(make-empty-Δ) ((∅ x1 : (Unv 0)) x2 : (Unv 0)) (Π (t6 : x1) (Π (t2 : x2) (Unv 0)))
                             U)
               U))
;; ---- Elim
;; TODO: Clean up/Reorganize these tests
(check-true
 (redex-match? tt-typingL
               (in-hole Θ_m (((elim x_D U) e_D) e_P))
               (term ((((elim truth Type) T) (Π (x : truth) (Unv 1))) (Unv 0)))))
(define Δtruth (term (Δ-set ,(make-empty-Δ) truth (Unv 0) ((T : truth)))))
(check-holds (type-infer ,Δtruth ∅ truth (in-hole Ξ U)))
(check-holds (type-infer ,Δtruth ∅ T (in-hole Θ_ai truth)))
(check-holds (type-infer ,Δtruth ∅ (λ (x : truth) (Unv 1))
                         (in-hole Ξ (Π (x : (in-hole Θ truth)) U))))

(check-telescope-equiv?
 (term (Δ-methods-telescope ,Δtruth truth (λ (x : truth) (Unv 1))))
 (term (Π (m-T : ((λ (x : truth) (Unv 1)) T)) hole)))
(check-holds (type-infer ,Δtruth ∅ (elim truth Type) t))
(check-holds (type-check (Δ-set ,(make-empty-Δ) truth (Unv 0) ((T : truth)))
                         ∅
                         ((((elim truth (Unv 2)) (λ (x : truth) (Unv 1))) (Unv 0))
                          T)
                         (Unv 1)))
(check-not-holds (type-check (Δ-set ,(make-empty-Δ) truth (Unv 0) ((T : truth)))
                             ∅
                             ((((elim truth (Unv 1)) Type) Type) T)
                             (Unv 1)))
(check-holds
 (type-infer ,(make-empty-Δ) ∅ (Π (x2 : (Unv 0)) (Unv 0)) U))
(check-holds
 (type-infer ,(make-empty-Δ) (∅ x1 : (Unv 0)) (λ (x2 : (Unv 0)) (Π (t6 : x1) (Π (t2 : x2) (Unv 0))))
               t))
(check-holds
 (type-infer ,Δ ∅ nat (in-hole Ξ U)))
(check-holds
 (type-infer ,Δ ∅ zero (in-hole Θ_ai nat)))
(check-holds
 (type-infer ,Δ ∅ (λ (x : nat) nat)
             (in-hole Ξ (Π (x : (in-hole Θ nat)) U))))
(define-syntax-rule (nat-test syn ...)
  (check-holds (type-check ,Δ syn ...)))
(nat-test ∅ (Π (x : nat) nat) (Unv 0))
(nat-test ∅ (λ (x : nat) x) (Π (x : nat) nat))
(nat-test ∅ (((((elim nat Type) (λ (x : nat) nat)) zero)
              (λ (x : nat) (λ (ih-x : nat) x))) zero)
            nat)
(nat-test ∅ nat (Unv 0))
(nat-test ∅ zero nat)
(nat-test ∅ s (Π (x : nat) nat))
(nat-test ∅ (s zero) nat)
;; TODO: Meta-function auto-currying and such
(check-holds
 (type-infer ,Δ ∅ ((((elim nat (Unv 0)) (λ (x : nat) nat))
                    zero)
                   (λ (x : nat) (λ (ih-x : nat) x)))
             t))
(nat-test ∅ (((((elim nat (Unv 0)) (λ (x : nat) nat))
               zero)
              (λ (x : nat) (λ (ih-x : nat) x)))
             zero)
            nat)
(nat-test ∅ (((((elim nat (Unv 0)) (λ (x : nat) nat))
               (s zero))
              (λ (x : nat) (λ (ih-x : nat) (s (s x)))))
             zero)
            nat)
(nat-test ∅ (((((elim nat Type) (λ (x : nat) nat))
               (s zero))
              (λ (x : nat) (λ (ih-x : nat) (s (s x))))) zero)
            nat)
(nat-test (∅ n : nat)
          (((((elim nat (Unv 0)) (λ (x : nat) nat)) zero) (λ (x : nat) (λ (ih-x : nat) x))) n)
          nat)
(check-holds
 (type-check (Δ-set ,Δ bool (Unv 0) ((btrue : bool) (bfalse : bool)))
             (∅ n2 : nat)
             (((((elim nat (Unv 0)) (λ (x : nat) bool))
                btrue)
               (λ (x : nat) (λ (ih-x : bool) bfalse)))
              n2)
             bool))
(check-not-holds
 (type-check ,Δ ∅
             ((((elim nat (Unv 0)) nat) (s zero)) zero)
             nat))
(define lam (term (λ (nat : (Unv 0)) nat)))
(check-equivalent
 (Π (nat : (Unv 0)) (Unv 0))
 ,(car (judgment-holds (type-infer ,Δ0 ∅ ,lam t) t)))
(check-equivalent
 (Π (nat : (Unv 0)) (Unv 0))
 ,(car (judgment-holds (type-infer ,Δ ∅ ,lam t) t)))
(check-equivalent
 (Π (x : (Π (y : (Unv 0)) y)) nat)
 ,(car (judgment-holds (type-infer (Δ-set ,(make-empty-Δ) nat (Unv 0) ()) ∅ (λ (x : (Π (y : (Unv 0)) y)) (x nat))
                                   t) t)))
(check-equivalent
 (Π (y : (Unv 0)) (Unv 0))
 ,(car (judgment-holds (type-infer (Δ-set ,(make-empty-Δ) nat (Unv 0) ()) ∅ (λ (y : (Unv 0)) y) t) t)))
(check-equivalent
 (Unv 0)
 ,(car (judgment-holds (type-infer (Δ-set ,(make-empty-Δ) nat (Unv 0) ()) ∅
                                   ((λ (x : (Π (y : (Unv 0)) (Unv 0))) (x nat))
                                    (λ (y : (Unv 0)) y))
                                   t) t)))
(check-equal?
 (list (term (Unv 0)) (term (Unv 1)))
 (judgment-holds
  (type-infer ,Δ4 ∅ (Π (S : (Unv 0)) (Π (B : (Unv 0)) (Π (a : S) (Π (b : B) ((and S) B)))))
              U) U))
(check-holds
 (type-check ,Δ4 (∅ S : (Unv 0)) conj (Π (A : (Unv 0)) (Π (B : (Unv 0)) (Π (a : A) (Π (b : B) ((and A) B)))))))
(check-holds
 (type-check ,Δ4 (∅ S : (Unv 0))
             conj (Π (P : (Unv 0)) (Π (Q : (Unv 0)) (Π (x : P) (Π (y : Q) ((and P) Q)))))))
(check-holds
 (type-check ,Δ4 (∅ S : (Unv 0)) S (Unv 0)))
(check-holds
 (type-check ,Δ4 (∅ S : (Unv 0)) (conj S)
             (Π (B : (Unv 0)) (Π (a : S) (Π (b : B) ((and S) B))))))
(check-holds
 (type-check ,Δ4 (∅ S : (Unv 0)) (conj S)
             (Π (B : (Unv 0)) (Π (a : S) (Π (b : B) ((and S) B))))))
(check-holds
 (type-check ,Δ4 ∅ (λ (S : (Unv 0)) (conj S))
             (Π (S : (Unv 0)) (Π (B : (Unv 0)) (Π (a : S) (Π (b : B) ((and S) B)))))))
(check-holds
 (type-check (Δ-set ,Δ4 true (Unv 0) ((tt : true))) ∅
             ((((conj true) true) tt) tt)
             ((and true) true)))
(check-holds
 (type-infer ,Δ4 ∅ and (in-hole Ξ U_D)))
(check-holds
 (type-infer (Δ-set ,Δ4 true (Unv 0) ((tt : true))) ∅
             ((((conj true) true) tt) tt)
             (in-hole Θ and)))
(check-holds
 (type-infer (Δ-set ,Δ4 true (Unv 0) ((tt : true))) ∅
             (λ (A : Type) (λ (B : Type) (λ (x : ((and A) B)) true)))
             (in-hole Ξ (Π (x : (in-hole Θ_Ξ and)) U_P))))
(check-holds
 (type-check (Δ-set ,Δ4 true (Unv 0) ((tt : true))) ∅
             ((((((elim and (Unv 0))
                  (λ (A : Type) (λ (B : Type) (λ (x : ((and A) B))
                                                true))))
                 (λ (A : (Unv 0))
                   (λ (B : (Unv 0))
                     (λ (a : A)
                       (λ (b : B) tt)))))
                true) true)
              ((((conj true) true) tt) tt))
             true))
(check-true (Γ? (term (((∅ P : (Unv 0)) Q : (Unv 0)) ab : ((and P) Q)))))
(check-holds
 (type-infer ,Δ4 ∅ and (in-hole Ξ U)))
(check-holds
 (type-infer ,Δ4 (((∅ P : Type) Q : Type) ab : ((and P) Q))
             ab (in-hole Θ and)))
(check-true
 (redex-match? tt-redL
               (in-hole Ξ (Π (x : (in-hole Θ and)) U))
               (term (Π (A : (Unv 0)) (Π (B : (Unv 0)) (Π (x : ((and A) B)) (Unv 0)))))))
(check-holds
 (type-infer ,Δ4 (((∅ P : Type) Q : Type) ab : ((and P) Q))
             (λ (A : Type) (λ (B : Type) (λ (x : ((and A) B))
                                           ((and B) A))))
             (in-hole Ξ (Π (x : (in-hole Θ and)) U))))
(check-holds
 (equivalent ,Δ4
             (Π (A : (Unv 0)) (Π (B : (Unv 0)) (Π (x : ((and A) B)) (Unv 0))))
             (Π (P : (Unv 0)) (Π (Q : (Unv 0)) (Π (x : ((and P) Q)) (Unv 0))))))
(check-holds
 (type-infer ,Δ4 ∅
             (λ (A : Type) (λ (B : Type) (λ (x : ((and A) B))
                                           ((and B) A))))
             (in-hole Ξ (Π (x : (in-hole Θ_Ξ and)) U_P))))
(check-holds
 (type-check ,Δ4
             (((∅ P : (Unv 0)) Q : (Unv 0)) ab : ((and P) Q))
             ((((((elim and (Unv 0))
                  (λ (A : Type) (λ (B : Type) (λ (x : ((and A) B))
                                                ((and B) A)))))
                 (λ (A : (Unv 0))
                   (λ (B : (Unv 0))
                     (λ (a : A)
                       (λ (b : B) ((((conj B) A) b) a))))))
                P) Q) ab)
             ((and Q) P)))
(check-holds
 (type-check (Δ-set ,Δ4 true (Unv 0) ((tt : true))) ∅
             (λ (A : Type) (λ (B : Type) (λ (x : ((and A) B)) ((and B) A))))
             (Π (A : (Unv 0)) (Π (B : (Unv 0)) (Π (x : ((and A) B)) (Unv 0))))))
(check-holds
 (type-infer (Δ-set ,Δ4 true (Unv 0) ((tt : true)))
             ((∅ A : Type) B : Type)
             (conj B)
             t))
(check-holds
 (type-check (Δ-set ,Δ4 true (Unv 0) ((tt : true))) ∅
             ((((((elim and (Unv 0))
                  (λ (A : Type) (λ (B : Type) (λ (x : ((and A) B))
                                                ((and B) A)))))
                 (λ (A : (Unv 0))
                   (λ (B : (Unv 0))
                     (λ (a : A)
                       (λ (b : B) ((((conj B) A) b) a))))))
                true) true)
              ((((conj true) true) tt) tt))
             ((and true) true)))
(define gamma (term (∅ temp863 : pre)))
(check-holds (wf ,sigma ∅))
(check-holds (wf ,sigma ,gamma))
(check-holds
 (type-infer ,sigma ,gamma (Unv 0) t))
(check-holds
 (type-infer ,sigma ,gamma pre t))
(check-holds
 (type-check ,sigma (,gamma tmp863 : pre) (Unv 0) (Unv 1)))
(check-holds
 (type-infer ,sigma ,gamma pre t))
(check-holds
 (type-check ,sigma (,gamma tmp863 : pre) (Unv 0) (Unv 1)))
(check-holds
 (type-infer ,sigma (,gamma x : false) false (in-hole Ξ U_D)))
(check-holds
 (type-infer ,sigma (,gamma x : false) x (in-hole Θ false)))
(check-holds
 (type-infer ,sigma (,gamma x : false) (λ (y : false) (Π (x : Type) x))
             (in-hole Ξ (Π (x : (in-hole Θ false)) U))))
(check-true
 (redex-match? tt-typingL
               ((in-hole Θ_m ((elim x_D U) e_P)) e_D)
               (term (((elim false (Unv 1)) (λ (y : false) (Π (x : Type) x)))
                      x))))
(check-holds
 (type-check ,sigma (,gamma x : false)
             (((elim false (Unv 0)) (λ (y : false) (Π (x : Type) x))) x)
             (Π (x : (Unv 0)) x)))

;; nat-equal? tests
(define zero?
  (term ((((elim nat Type) (λ (x : nat) bool))
          true)
         (λ (x : nat) (λ (x_ih : bool) false)))))
(check-holds
 (type-check ,Δ ∅ ,zero? (Π (x : nat) bool)))
(check-equal?
 (term (reduce ,Δ (,zero? zero)))
 (term true))
(check-equal?
 (term (reduce ,Δ (,zero? (s zero))))
 (term false))
(define ih-equal?
  (term ((((elim nat Type) (λ (x : nat) bool))
          false)
         (λ (x : nat) (λ (y : bool) (x_ih x))))))
(check-holds
 (type-check ,Δ (∅ x_ih : (Π (x : nat) bool))
             ,ih-equal?
             (Π (x : nat) bool)))
(check-holds
 (type-infer ,Δ ∅ nat (Unv 0)))
(check-holds
 (type-infer ,Δ ∅ bool (Unv 0)))
(check-holds
 (type-infer ,Δ ∅ (λ (x : nat) (Π (x : nat) bool)) (Π (x : nat) (Unv 0))))
(define nat-equal?
  (term ((((elim nat Type) (λ (x : nat) (Π (x : nat) bool)))
          ,zero?)
         (λ (x : nat) (λ (x_ih : (Π (x : nat) bool))
                        ,ih-equal?)))))
(check-holds
 (type-check ,Δ (∅ nat-equal? : (Π (x-D«4158» : nat) ((λ (x«4159» : nat) (Π (x«4160» : nat) bool)) x-D«4158»)))
             ((nat-equal? zero) zero)
             bool))
(check-holds
 (type-check ,Δ ∅
             ,nat-equal?
             (Π (x : nat) (Π (y : nat) bool))))
(check-equal?
 (term (reduce ,Δ ((,nat-equal? zero) (s zero))))
 (term false))
(check-equal?
 (term (reduce ,Δ ((,nat-equal? (s zero)) zero)))
 (term false))

;; == tests
(define Δ= (term (Δ-set ,Δ == (Π (A : (Unv 0)) (Π (a : A) (Π (b : A) (Unv 0))))
                         ((refl : (Π (A : (Unv 0)) (Π (a : A) (((== A) a) a))))))))
(check-true (Δ? Δ=))

(define refl-elim
  (term (((((((elim == (Unv 0)) (λ (A1 : (Unv 0)) (λ (x1 : A1) (λ (y1 : A1) (λ (p2 : (((==
                                                                                        A1)
                                                                                       x1)
                                                                                      y1))
                                                                              nat)))))
             (λ (A1 : (Unv 0)) (λ (x1 : A1) zero))) bool) true) true) ((refl bool) true))))
(check-holds
 (type-check ,Δ= ∅ ,refl-elim nat))
(check-true
 (redex-match?
  tt-redL
  (Δ (in-hole E (in-hole Θ ((elim x_D U) e_P))))
  (term (,Δ= ,refl-elim))))
(check-true
 (redex-match?
  tt-redL
  (in-hole (Θ_p (in-hole Θ_i x_ci)) Θ_m)
  (term (((((hole
             (λ (A1 : (Unv 0)) (λ (x1 : A1) zero))) bool) true) true) ((refl bool) true)))))
(check-telescope-equiv?
 (term (Δ-ref-parameter-Ξ ,Δ= ==))
 (term (Π (A : Type) (Π (a : A) (Π (b : A) hole)))))
(check-equal?
 (term (reduce ,Δ= ,refl-elim))
 (term zero))