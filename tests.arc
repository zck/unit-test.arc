(suite assert t-doesnt-error (assert t "shouldn't throw")
       nil-errors (when (errsafe (do (assert nil "should throw") t)) (err
                                                                      "asserting nil should throw")))

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
       different-vals (when (errsafe (do (assert-same 1 2)
                                         t))
                        (err "assert-same on different values should throw")))

(suite assert-t
       t-is-good (assert-t t)
       nil-throws (when (errsafe (do (assert-t nil)
                                         t))
                        (err "assert-t called with nil should throw"))
       3-is-treated-as-good (assert-t 3))

(suite assert-nil
       t-is-good (when (errsafe (do (assert-nil t)
                                    t))
                   (err "assert-t called with nil should throw"))
       nil-is-good (assert-nil nil)
       3-is-treated-as-bad (when (errsafe (do (assert-nil 3)
                                              t))
                             (err "assert-nil called with 3 should throw")))

(let sample-test (test sample-suite sample-test 3)
     (suite test
            test-name (assert-is 'sample-test sample-test!test-name)
            suite-name (assert-is 'sample-suite sample-test!suite-name)
            test-fn (assert-is 3
                               ((sample-test!test-fn)
                                'return-value))))


(with (pass-test-val ((make-test-fn sample-suite pass-test 3))
       fail-test-val ((make-test-fn sample-suite fail-test (err "failing..."))))
      (suite make-test-fn
             pass-has-right-return-value (assert-is 3 pass-test-val!return-value)
             pass-has-test-name (assert-is 'pass-test pass-test-val!test-name)
             fail-has-test-name (assert-is 'fail-test fail-test-val!test-name)
             pass-has-suite-name (assert-is 'sample-suite pass-test-val!suite-name)
             fail-has-suite-name (assert-is 'sample-suite fail-test-val!suite-name)
             pass-has-pass-status (assert-is 'pass pass-test-val!status)
             fail-has-fail-status (assert-is 'fail fail-test-val!status)
             fail-has-proper-details (assert-is "failing..." fail-test-val!details)))

(with (single-test (suite-partition test-suite-1 a 3)
       single-suite (suite-partition test-suite-2 (suite a b 3))
       two-of-each (suite-partition test-suite-3 a 3 (suite b c 4) d 5 (suite e 6 f 7))
       none-of-either (suite-partition test-suite-4)
       test-after-nested-suite (suite-partition test-suite-4 (suite a 1) b 2))
      (suite suite-partition
             nothing (do (assert-is t (empty none-of-either!tests))
                         (assert-is t (empty none-of-either!suites)))
             single-test-has-no-suite (assert-is t
                                              (empty single-test!suites))
             single-test-has-one-test (assert-is 1
                                              (len single-test!tests))
             single-test-has-right-test (assert-is 'a
                                                single-test!tests!a!test-name)
             single-test-has-right-suite (assert-is 'test-suite-1
                                                 single-test!tests!a!suite-name)
             single-suite-has-no-tests (assert-is t
                                                  (empty single-suite!tests))
             single-suite-has-one-suite (assert-is 1
                                                   (len single-suite!suites))
             single-suite-contains-one-test (assert-is 1
                                                       (len single-suite!suites!a!tests))
             single-suite-contains-right-test (assert-is 'b
                                                         single-suite!suites!a!tests!b!test-name)
             two-of-each-has-two-tests (assert-is 2
                                                  (len two-of-each!tests))
             two-of-each-has-two-suites (assert-is 2
                                                  (len two-of-each!suites))
             nested-suite-has-right-name (assert-is 'a
                                                    single-suite!suites!a!suite-name)
             nested-suite-has-right-full-name (assert-is 'test-suite-2.a
                                                    single-suite!suites!a!full-suite-name)
             test-after-nested-suite-has-correct-parent-name (assert-is 'test-suite-4
                                                                        test-after-nested-suite!tests!b!suite-name)))


(with (single-test (make-suite test-suite-1 nil a 3)
       single-suite (make-suite test-suite-2 nil (suite a b 3))
       two-of-each (make-suite test-suite-3 a 3 nil (suite b c 4) d 5 (suite e 6 f 7)))
      (suite make-suite
             single-test-has-no-suite (assert-is t
                                              (empty single-test!suites))
             single-test-has-one-test (assert-is 1
                                              (len single-test!tests))
             single-test-has-right-test (assert-is 'a
                                                single-test!tests!a!test-name)
             single-test-has-right-suite (assert-is 'test-suite-1
                                                 single-test!tests!a!suite-name)
             single-suite-has-no-tests (assert-is t
                                                  (empty single-suite!tests))
             single-suite-has-one-suite (assert-is 1
                                                   (len single-suite!nested-suites))
             single-suites-nested-suite-has-right-suite-name (assert-is 'a
                                                                        single-suite!nested-suites!a!suite-name)
             single-suites-nested-suite-has-right-full-suite-name (assert-is 'test-suite-2.a
                                                                             single-suite!nested-suites!a!full-suite-name)
             single-suite-has-right-name (assert-is 'test-suite-2
                                                    single-suite!suite-name)
             single-suite-has-right-full-suite-name (assert-is 'test-suite-2
                                                               single-suite!full-suite-name)
             single-suite-contains-one-test (assert-is 1
                                                       (len single-suite!nested-suites!a!tests))
             single-suite-contains-right-test (assert-is 'b
                                                         single-suite!nested-suites!a!tests!b!test-name)
             single-suite-test-in-nested-suite-has-right-suite-name (assert-is 'test-suite-2.a
                                                                               single-suite!nested-suites!a!tests!b!suite-name)
             two-of-each-has-two-tests (assert-is 2
                                                  (len two-of-each!tests))
             two-of-each-has-two-suites (assert-is 2
                                                  (len two-of-each!nested-suites))))


(suite total-tests
       0 (assert-is 0
                    (total-tests (inst 'suite-results
                                       'test-results (obj))))
       1 (assert-is 1
                    (total-tests (inst 'suite-results
                                       'test-results (obj numbers
                                                          (inst 'test-results)))))
       3-flat (assert-is 3
                         (total-tests (inst 'suite-results
                                            'test-results (obj sample1 (inst 'test-results)
                                                               sample2 (inst 'test-results)
                                                               sample3 (inst 'test-results)))))
       3-nested (assert-is 3
                           (total-tests (inst 'suite-results
                                              'test-results (obj sample (inst 'test-results))
                                              'nested-suite-results (obj nested (inst 'suite-results
                                                                          'test-results (obj sample1 (inst 'test-results)
                                                                                             sample2 (inst 'test-results)))))))
       2-empty-main-suite (assert-is 2
                                     (total-tests (inst 'suite-results
                                                        'nested-suite-results (obj nested (inst 'suite-results
                                                                                                'test-results (obj sample1 (inst 'test-results)
                                                                                                                   sample2 (inst 'test-results)))))))
       7-doubly-nested (assert-is 7
                                  (total-tests (inst 'suite-results
                                                     'test-results (obj sample1 (inst 'test-results))
                                                     'nested-suite-results (obj nested1 (inst 'suite-results
                                                                                              'test-results (obj sample2 (inst 'test-results)
                                                                                                                 sample3 (inst 'test-results))
                                                                                              'nested-suite-results (obj nested2 (inst 'suite-results
                                                                                                                                       'test-results (obj sample4 (inst 'test-results)
                                                                                                                                                          sample5 (inst 'test-results)
                                                                                                                                                          sample6 (inst 'test-results)
                                                                                                                                                          sample7 (inst 'test-results)))))))))
       7-multiple-nested (assert-is 7
                                    (total-tests (inst 'suite-results
                                                       'test-results (obj sample1 (inst 'test-results))
                                                       'nested-suite-results (obj nested1 (inst 'suite-results
                                                                                                'test-results (obj sample2 (inst 'test-results)
                                                                                                                   sample3 (inst 'test-results)))
                                                                                  nested2 (inst 'suite-results
                                                                                                'test-results
                                                                                                (obj sample4 (inst 'test-results)
                                                                                                     sample5 (inst 'test-results)
                                                                                                     sample6 (inst 'test-results)
                                                                                                     sample7 (inst 'test-results))))))))


(suite count-passes
       0-empty (assert-is 0
                          (count-passes (inst 'suite-results
                                              'test-results (obj))))
       0-stuff (assert-is 0
                          (count-passes (inst 'suite-results
                                              'test-results (obj fail (inst 'test-results 'status 'fail)))))
       1 (assert-is 1
                    (count-passes (inst 'suite-results
                                        'test-results (obj numbers
                                                           (inst 'test-results 'status 'pass)))))
       2-flat (assert-is 2
                         (count-passes (inst 'suite-results
                                             'test-results (obj sample1 (inst 'test-results 'status 'pass)
                                                                sample2 (inst 'test-results 'status 'fail)
                                                                sample3 (inst 'test-results 'status 'pass)))))
       3-nested (assert-is 3
                           (count-passes (inst 'suite-results
                                               'test-results (obj sample1 (inst 'test-results 'status 'pass)
                                                                  sample2 (inst 'test-results 'status 'pass)
                                                                  sample3 (inst 'test-results 'status 'fail))
                                               'nested-suite-results (obj nested (inst 'suite-results
                                                                                       'test-results (obj sample1 (inst 'test-results 'status 'pass)
                                                                                                          sample2 (inst 'test-results 'status 'fail)))))))
       1-empty-main-suite (assert-is 1
                                     (count-passes (inst 'suite-results
                                                         'nested-suite-results (obj nested (inst 'suite-results
                                                                                                 'test-results (obj sample1 (inst 'test-results 'status 'pass)
                                                                                                                    sample2 (inst 'test-results 'status 'fail)))))))
       3-doubly-nested (assert-is 3
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
       6-multiple-nested (assert-is 6
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
       pass (assert-is t
                       (result-is-pass (inst 'test-results
                                             'status 'pass)))
       fail (assert-is nil
                       (result-is-pass (inst 'test-results
                                             'status 'fail))))

(suite make-full-suite-name
       regular (assert-is 'pants
                          (make-full-suite-name nil
                                                'pants))
       nested (assert-is 'parent.child
                         (make-full-suite-name 'parent
                                               'child)))

(suite hash-equal
       empty (assert-is t
                        (hash-equal (obj)
                                    (obj)))
       single-elt-same (assert-is t
                                  (hash-equal (obj 1 t)
                                              (obj 1 t)))
       single-elt-different-val (assert-is nil
                                           (hash-equal (obj 1 t)
                                                       (obj 1 'pants)))
       single-elt-different-key (assert-is nil
                                           (hash-equal (obj 1 t)
                                                       (obj 2 t)))
       multiple-elts-same (assert-is t
                                     (hash-equal (obj 1 t 2 'a (1) 2)
                                                 (obj 1 t 2 'a (1) 2)))
       multiple-elts-different-key (assert-is nil
                                              (hash-equal (obj 1 t 2 t 3 t)
                                                          (obj 1 t 2 t 4 t)))
       multiple-elts-different-val (assert-is nil
                                              (hash-equal (obj 1 t 2 t 3 t)
                                                          (obj 1 t 2 t 3 4)))
       extra-elt-on-left (assert-is nil
                                    (hash-equal (obj 1 t 2 t)
                                                (obj 1 t 2 t 3 t)))
       extra-elt-on-right (assert-is nil
                                     (hash-equal (obj 1 t 2 t 3 t)
                                                 (obj 1 t 2 t)))
       does-order-matter? (assert-is t
                                     (hash-equal (obj 1 t 2 t)
                                                 (obj 2 t 1 t))))
