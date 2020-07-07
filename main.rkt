#lang racket/base

(module+ test
  (require rackunit))

(require "private/charset.rkt" "private/transcode.rkt" racket/contract)

(provide/contract
 [mib->charset-name (-> mib-number? (or/c #f charset-name?))]
 [charset-name->mib (-> charset-name? (or/c #f mib-number?))]
 [string->mib (-> string?(or/c #f mib-number?))]
 [string->charset-name (-> string? (or/c #f charset-name?))]
 [mib-number? (-> any/c boolean?)]
 [charset-name? (-> any/c boolean?)]

 [transcode-close (-> void?)]
 [string->bytes/name (-> string? charset-name? bytes?)]
 [bytes->string/name (-> bytes? charset-name? string?)]
 
 [string->bytes/mib (-> string? mib-number? bytes?)]
 [bytes->string/mib (-> bytes? mib-number? string?)]
 )