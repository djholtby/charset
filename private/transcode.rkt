#lang racket/base

(require "charset.rkt")

(provide bytes->string/name string->bytes/name bytes->string/mib string->bytes/mib
         transcode-close)

(define converter-table (make-hasheq))

(define (transcode-close)
  (hash-for-each converter-table (lambda (s convs)
                                   (bytes-close-converter (car convs))
                                   (bytes-close-converter (cdr convs))))
  (hash-clear! converter-table))

(define (get-converter who from? enc)
  (unless (hash-has-key? converter-table enc)
    (define enc/str (symbol->string enc))
    (define convs (cons (bytes-open-converter enc/str "UTF-8//TRANSLIT//IGNORE")
                        (bytes-open-converter "UTF-8" (string-append enc/str "//TRANSLIT//IGNORE"))))
    (unless (and (bytes-converter? (car convs))
                 (bytes-converter? (cdr convs)))
      (raise-arguments-error who "given encoding not supported on this platform" "encoding" enc))
    (hash-set! converter-table enc convs))
  ((if from? car cdr) (hash-ref converter-table enc)))

(define (bytes-convert/complete bytes converter)
  (let loop ([index 0]
             [acc (open-output-bytes)])
      (define-values (new-bytes read state) (bytes-convert converter bytes index))
      (case state
        [(complete)
         (write-bytes new-bytes acc)
         (get-output-bytes acc #t)]
        [(continues aborts)
         (write-bytes new-bytes acc)
         (write-bytes (bytes-convert-end converter) acc)
         (get-output-bytes acc #t)]
        [(error)
         (write-bytes #"?" acc)
         (loop (+ index read 1) acc)])))

(define (string-convert/complete string converter)
  (bytes-convert/complete (string->bytes/utf-8 string) converter))

(define (bytes->string/name bytes enc)
  (case enc
    [(UTF-8 ASCII) (bytes->string/utf-8 bytes)] ; ASCII bytes are also UTF-8 bytes 
    [else 
     (define converter (get-converter 'bytes->string/name #t enc))
     (bytes->string/utf-8 (bytes-convert/complete bytes converter))]))

(define (bytes->string/mib bytes mib)
  (bytes->string/name bytes (mib->charset-name mib)))

(define (string->bytes/name str enc)
  (case enc
    [(UTF-8) (string->bytes/utf-8 str)] ; But UTF-8 bytes are not always ASCII bytes
    [else 
     (define converter (get-converter 'string->bytes/name #f enc))
     (string-convert/complete str converter)]))

(define (string->bytes/mib str mib)
  (string->bytes/name str (mib->charset-name mib)))