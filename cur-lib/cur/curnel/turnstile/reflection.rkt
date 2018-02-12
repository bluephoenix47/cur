#lang racket/base
(require
 racket/syntax
 syntax/parse
 racket/function
 syntax/to-string
 ;"type-reconstruct.rkt"
 "eval.rkt"
; "runtime-utils.rkt"
 (rename-in "equiv.rkt" [cur-equal? _cur-equal?])
 "stxutils.rkt"
; (for-template "type-check.rkt")
 ;(for-template "runtime.rkt")
 (for-template (only-in turnstile/lang infer typecheck? current-type-eval))
 (for-template  turnstile/examples/dep-ind-cur )
 (for-template "cur-to-turnstile.rkt")
 (for-template (only-in racket/base quote ))
 )

(provide
;; with-env
;; call-with-env
 cur->datum
 ;;deprecated-cur-expand
 ;;cur-expand
 cur-type-infer
 cur-type-check?
 ;;cur-constructors-for
 ;;cur-data-parameters
 ;;cur-method-type
 ;;cur-constructor-recursive-index-ls
 ;;cur-constructor-telescope-length
 cur-normalize 
 ;;cur-rename
 ;;cur-reflect-id
 ;;cur-step
; cur-equal?
 )



(define (cur-type-infer syn)
  (let ([t   (car (cadddr (infer (list syn) #:ctx '())))])
   (cur-reflect t)))

(define (cur-type-check? term expected-type) 
  (let ([inferred-type (cur-type-infer term)])
   ; (displayln (format "(inferred: ~a \n expected: ~a" inferred-type expected-type))
    (typecheck? inferred-type expected-type)))

(define (cur->datum syn) ;write special case for each core turn- form instead? 
  (let ([expanded (cur-expand syn)])
    ;(displayln (format "expanded: ~a" expanded))
    (let ([reflected (cur-reflect expanded)])
     ; (displayln (format "reflected: ~a" reflected))
      (syntax->datum reflected))))

(define (cur-normalize syn)
  (let ([evaled ((current-type-eval) syn)])
    (cur-reflect evaled)))

(define (cur-reflect syn) 
  (syntax-parse syn #:literals ( quote λ Type)
    [x:id
     #'x]
    [(Type i:exact-nonnegative-integer)
     syn]
    [(_ _ (_ () _ (_ _ (quote i:exact-nonnegative-integer))))
     #'(Type i)]
    [(λ (x : type) body)  ;dep-ind-cur throws away the arg type, never reaches this case in cur-normalize or cur->datum
     #`(λ (#,(cur-reflect #'x) : #,(cur-reflect #'type)) #,(cur-reflect #'body))]
    [(_  _ (_ (x)
             _ (_  _  (_ _
                (_ ()
                  _
                  (_ _  arg-type body-type))))))
     #`(Π (x : #,(cur-reflect #'arg-type)) #,(cur-reflect #'body-type))]
    ))

(define (cur-expand syn) 
  (local-expand syn 'expression null))