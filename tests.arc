(suite assert t-doesnt-error (assert t "shouldn't throw")
       nil-errors (assert-error (assert nil "should throw")))

(suite same
       numbers-same (assert-t (same 1 1))
       numbers-diff (assert-nil (same 1 2))
       strings-same (assert-t (same "Now Mary" "Now Mary"))
       strings-diff (assert-nil (same "Now Mary" "Mow Nary"))
       lists-same (assert-t (same '(1 2 3)
                                  '(1 2 3)))
       lists-diff (assert-nil (same '(1 2 3)
                                    '(1 3 3)))
       lists-sub-lists-of-the-second (assert-nil (same '(1 2 3)
                                                       '(1 2 3 4)))
       tables-same (assert-t (same (obj 1 2)
                                   (obj 1 2)))
       tables-different-vals (assert-nil (same (obj 1 2)
                                               (obj 1 1)))
       tables-different-keys (assert-nil (same (obj 1 1)
                                               (obj 2 1)))
       tables-extra-keys (assert-nil (same (obj 1 2)
                                           (obj 1 2 3 4)))
       cross-number-and-obj (assert-nil (same 1
                                              (obj 1 2)))
       cross-obj-and-number (assert-nil (same (obj 1 2)
                                              1))
       cross-number-and-string (assert-nil (same 1
                                                 "1")))


(suite assert-same
       equal-vals (assert-same 1 1 "equal values are good")
       lists-are-iso (assert-same (list 1) (list 1) "equal lists are good")
       different-vals (assert-error (assert-same 1 2)))

(suite assert-t
       t-is-good (assert-t t)
       nil-throws (assert-error (assert-t nil))
       3-is-treated-as-good (assert-t 3))

(suite assert-nil
       t-is-good (assert-error (assert-nil t))
       nil-is-good (assert-nil nil)
       3-is-treated-as-bad (assert-error (assert-nil 3)))

(with (sample-test (test sample-suite sample-test nil 3)
       simple-setup (test sample-suite simple-setup (x 3) x)
       multiple-variable-setup (test sample-suite multiple-variable-setup (x 3 y 4) (+ x y))
       reliant-variable-setup (test sample-suite reliant-variable-setup (x 3 y x) (+ x y)))
     (suite test
            test-name (assert-same 'sample-test sample-test!test-name)
            suite-name (assert-same 'sample-suite sample-test!suite-name)
            test-fn (assert-same 3
                                 ((sample-test!test-fn)
                                  'return-value))
            simple-setup (assert-same 3
                                      ((simple-setup!test-fn)
                                       'return-value))
            multiple-variable-setup (assert-same 7
                                      ((multiple-variable-setup!test-fn)
                                       'return-value))
            reliant-variable-setup (assert-same 6
                                      ((reliant-variable-setup!test-fn)
                                       'return-value))))



(with (pass-test-val ((make-test-fn sample-suite pass-test nil 3))
       fail-test-val ((make-test-fn sample-suite fail-test nil (err "failing...")))
       simple-setup ((make-test-fn sample-suite w/setup (x 3) x))
       multiple-variable-setup ((make-test-fn sample-suite multiple-variable-setup (x 3 y 4) (+ x y)))
       reliant-variable-setup ((make-test-fn sample-suite reliant-variable-setup (x 3 y x) (+ x y))))
      (suite make-test-fn
             pass-has-right-return-value (assert-same 3 pass-test-val!return-value)
             pass-has-test-name (assert-same 'pass-test pass-test-val!test-name)
             fail-has-test-name (assert-same 'fail-test fail-test-val!test-name)
             pass-has-suite-name (assert-same 'sample-suite pass-test-val!suite-name)
             fail-has-suite-name (assert-same 'sample-suite fail-test-val!suite-name)
             pass-has-pass-status (assert-same 'pass pass-test-val!status)
             fail-has-fail-status (assert-same 'fail fail-test-val!status)
             fail-has-proper-details (assert-same "failing..." fail-test-val!details)
             setup-has-right-value (assert-same 3 simple-setup!return-value)
             multiple-variables-are-setup-properly (assert-same 7 multiple-variable-setup!return-value)
             reliant-variables-are-setup-properly (assert-same 6 reliant-variable-setup!return-value)))

(with (single-test (suite-partition test-suite-1 nil a 3)
       single-suite (suite-partition test-suite-2 nil (suite a b 3))
       two-of-each (suite-partition test-suite-3 nil a 3 (suite b c 4) d 5 (suite e f 6 g 7))
       none-of-either (suite-partition test-suite-4 nil)
       test-after-nested-suite (suite-partition test-suite-4 nil (suite a b 1) c 2)
       test-with-setup (suite-partition test-suite-5 (x 3) a x))
      (suite suite-partition
             nothing (do (assert-t (empty none-of-either!tests))
                         (assert-t (empty none-of-either!suites)))
             single-test-has-no-suite (assert-t (empty single-test!suites))
             single-test-has-one-test (assert-same 1
                                                   (len single-test!tests))
             single-test-has-right-test (assert-same 'a
                                                     single-test!tests!a!test-name)
             single-test-has-right-suite (assert-same 'test-suite-1
                                                      single-test!tests!a!suite-name)
             single-suite-has-no-tests (assert-t (empty single-suite!tests))
             single-suite-has-one-suite (assert-same 1
                                                     (len single-suite!suites))
             single-suite-contains-one-test (assert-same 1
                                                         (len single-suite!suites!a!tests))
             single-suite-contains-right-test (assert-same 'b
                                                           single-suite!suites!a!tests!b!test-name)
             two-of-each-has-two-tests (assert-same 2
                                                    (len two-of-each!tests))
             two-of-each-has-two-suites (assert-same 2
                                                     (len two-of-each!suites))
             nested-suite-has-right-name (assert-same 'a
                                                      single-suite!suites!a!suite-name)
             nested-suite-has-right-full-name (assert-same 'test-suite-2.a
                                                           single-suite!suites!a!full-suite-name)
             test-after-nested-suite-has-correct-parent-name (assert-same 'test-suite-4
                                                                          test-after-nested-suite!tests!c!suite-name)
             test-fn-returns-right-value (assert-same 3
                                                      ((single-test!tests!a!test-fn) 'return-value))
             nested-test-fn-returns-right-value (assert-same 3
                                                             ((single-suite!suites!a!tests!b!test-fn) 'return-value))
             test-with-setup-returns-right-value (assert-same 3
                                                              ((test-with-setup!tests!a!test-fn)
                                                               'return-value))))


(with (single-test (make-suite test-suite-1 nil nil a 3)
       single-suite (make-suite test-suite-2 nil nil (suite a b 3))
       two-of-each (make-suite test-suite-3 nil nil a 3 (suite b c 4) d 5 (suite e f 6 g 7))
       test-w/setup (make-suite test-suite-4 nil (x 3) a x))
      (suite make-suite
             single-test-has-no-suite (assert-t (empty single-test!suites))
             single-test-has-one-test (assert-same 1
                                                   (len single-test!tests))
             single-test-has-right-test (assert-same 'a
                                                     single-test!tests!a!test-name)
             single-test-has-right-suite (assert-same 'test-suite-1
                                                      single-test!tests!a!suite-name)
             single-suite-has-no-tests (assert-t (empty single-suite!tests))
             single-suite-has-one-suite (assert-same 1
                                                     (len single-suite!nested-suites))
             single-suites-nested-suite-has-right-suite-name (assert-same 'a
                                                                          single-suite!nested-suites!a!suite-name)
             single-suites-nested-suite-has-right-full-suite-name (assert-same 'test-suite-2.a
                                                                               single-suite!nested-suites!a!full-suite-name)
             single-suite-has-right-name (assert-same 'test-suite-2
                                                      single-suite!suite-name)
             single-suite-has-right-full-suite-name (assert-same 'test-suite-2
                                                                 single-suite!full-suite-name)
             single-suite-contains-one-test (assert-same 1
                                                         (len single-suite!nested-suites!a!tests))
             single-suite-contains-right-test (assert-same 'b
                                                           single-suite!nested-suites!a!tests!b!test-name)
             single-suite-test-in-nested-suite-has-right-suite-name (assert-same 'test-suite-2.a
                                                                                 single-suite!nested-suites!a!tests!b!suite-name)
             two-of-each-has-two-tests (assert-same 2
                                                    (len two-of-each!tests))
             two-of-each-has-two-suites (assert-same 2
                                                     (len two-of-each!nested-suites))
             setup-is-done-properly (assert-same 3
                                                 ((test-w/setup!tests!a!test-fn)
                                                  'return-value))))


(suite count-passes
       0-empty (assert-same 0
                            (count-passes (inst 'suite-results
                                                'test-results (obj))))
       0-stuff (assert-same 0
                            (count-passes (inst 'suite-results
                                                'test-results (obj fail (inst 'test-results 'status 'fail)))))
       1 (assert-same 1
                      (count-passes (inst 'suite-results
                                          'test-results (obj numbers
                                                             (inst 'test-results 'status 'pass)))))
       2-flat (assert-same 2
                           (count-passes (inst 'suite-results
                                               'test-results (obj sample1 (inst 'test-results 'status 'pass)
                                                                  sample2 (inst 'test-results 'status 'fail)
                                                                  sample3 (inst 'test-results 'status 'pass)))))
       3-nested (assert-same 3
                             (count-passes (inst 'suite-results
                                                 'test-results (obj sample1 (inst 'test-results 'status 'pass)
                                                                    sample2 (inst 'test-results 'status 'pass)
                                                                    sample3 (inst 'test-results 'status 'fail))
                                                 'nested-suite-results (obj nested (inst 'suite-results
                                                                                         'test-results (obj sample1 (inst 'test-results 'status 'pass)
                                                                                                            sample2 (inst 'test-results 'status 'fail)))))))
       1-empty-main-suite (assert-same 1
                                       (count-passes (inst 'suite-results
                                                           'nested-suite-results (obj nested (inst 'suite-results
                                                                                                   'test-results (obj sample1 (inst 'test-results 'status 'pass)
                                                                                                                      sample2 (inst 'test-results 'status 'fail)))))))
       3-doubly-nested (assert-same 3
                                    (count-passes (inst 'suite-results
                                                        'test-results (obj sample1 (inst 'test-results 'status 'fail))
                                                        'nested-suite-results (obj nested1 (inst 'suite-results
                                                                                                 'test-results (obj sample2 (inst 'test-results 'status 'pass)
                                                                                                                    sample3 (inst 'test-results 'status 'fail))
                                                                                                 'nested-suite-results (obj nested2 (inst 'suite-results
                                                                                                                                          'test-results (obj sample4 (inst 'test-results 'status 'pass)
                                                                                                                                                             sample5 (inst 'test-results 'status 'pass)
                                                                                                                                                             sample6 (inst 'test-results 'status 'fail)
                                                                                                                                                             sample7 (inst 'test-results 'status 'fail)))))))))
       6-multiple-nested (assert-same 6
                                      (count-passes (inst 'suite-results
                                                          'test-results (obj sample1 (inst 'test-results 'status 'pass))
                                                          'nested-suite-results (obj nested1 (inst 'suite-results
                                                                                                   'test-results (obj sample2 (inst 'test-results 'status 'pass)
                                                                                                                      sample3 (inst 'test-results 'status 'pass)
                                                                                                                      sample4 (inst 'test-results 'status 'fail)))
                                                                                     nested2 (inst 'suite-results
                                                                                                   'test-results
                                                                                                   (obj sample4 (inst 'test-results 'status 'pass)
                                                                                                        sample5 (inst 'test-results 'status 'pass)
                                                                                                        sample6 (inst 'test-results 'status 'pass)
                                                                                                        sample7 (inst 'test-results 'status 'fail))))))))



(suite result-is-pass
       pass (assert-t (result-is-pass (inst 'test-results
                                             'status 'pass)))
       fail (assert-nil (result-is-pass (inst 'test-results
                                             'status 'fail))))

(suite make-full-suite-name
       regular (assert-same 'pants
                            (make-full-suite-name nil
                                                  'pants))
       nested (assert-same 'parent.child
                           (make-full-suite-name 'parent
                                                 'child)))

(suite hash-equal
       empty (assert-t (hash-equal (obj)
                                   (obj)))
       single-elt-same (assert-t (hash-equal (obj 1 t)
                                             (obj 1 t)))
       single-elt-different-val (assert-nil (hash-equal (obj 1 t)
                                                        (obj 1 'pants)))
       single-elt-different-key (assert-nil (hash-equal (obj 1 t)
                                                        (obj 2 t)))
       multiple-elts-same (assert-t (hash-equal (obj 1 t 2 'a (1) 2)
                                                (obj 1 t 2 'a (1) 2)))
       multiple-elts-different-key (assert-nil (hash-equal (obj 1 t 2 t 3 t)
                                                           (obj 1 t 2 t 4 t)))
       multiple-elts-different-val (assert-nil (hash-equal (obj 1 t 2 t 3 t)
                                                           (obj 1 t 2 t 3 4)))
       extra-elt-on-left (assert-nil (hash-equal (obj 1 t 2 t)
                                                 (obj 1 t 2 t 3 t)))
       extra-elt-on-right (assert-nil (hash-equal (obj 1 t 2 t 3 t)
                                                  (obj 1 t 2 t)))
       does-order-matter? (assert-t (hash-equal (obj 1 t 2 t)
                                                (obj 2 t 1 t))))

(suite assert-error
       err-is-ok (assert-error (err "oh dear!"))
       no-err-fails (assert-nil (errsafe (do (assert-error "no error")
                                             t)))
       checks-error-message (assert-nil (errsafe (do (assert-error (err "this is bad")
                                                                 "this is the wrong message")
                                                   t)))
       valid-error-message-passes (assert-error (err "oh no...")
                                                "oh no...")
       no-error-fails-when-error-message-given (assert-nil (errsafe (do (assert-error "no error" "error message")
                                                                        t))
                                                           "Even when an error message is given, not having an error should fail assert-error."))

(suite to-readable-string
       strings-are-quoted (assert-same "'string!'"
                                       (to-readable-string "string!"))
       numbers-are-ok (assert-same "42"
                                   (to-readable-string 42))
       lists-are-ok (assert-same "(1 (2 3) . 4)"
                                 (to-readable-string '(1 (2 3) . 4)))
       lists-containing-string (assert-same "(1 '2' 3)"
                                            (to-readable-string '(1 "2" 3)))
       tables-containing-string (assert-same "#hash((1 . '2')('3' . 4))"
                                             (to-readable-string (obj 1 "2" "3" 4))))
