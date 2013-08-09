(suite assert t-doesnt-error (assert t "shouldn't throw")
       nil-errors (when (errsafe (do (assert nil "should throw") t)) (err
                                                                      "asserting nil should throw")))

(suite assert-is
       equal-vals (assert-is 1 1 "equal values are good")
       lists-arent-is (when (errsafe (do (assert-is (list 1) (list 1) "lists can't be compared with is")
                                         t))
                        (err "assert-is on two lists should throw"))
       different-vals (when (errsafe (do (assert-is 1 2)
                                         t))
                        (err "assert-is on different values should throw")))

(suite assert-iso
       equal-vals (assert-iso 1 1 "equal values are good")
       lists-are-iso (assert-iso (list 1) (list 1) "equal lists are good")
       different-vals (when (errsafe (do (assert-iso 1 2)
                                         t))
                        (err "assert-iso on different values should throw")))

(let sample-test (test sample-suite sample-test 3)
     (suite test
            test-name (assert-is 'sample-test sample-test!test-name)
            suite-name (assert-is 'sample-suite sample-test!suite-name)
            test-fn (assert (isa (sample-test!test-fn)
                                 'table)"The test function should run and return the value we set up.")))

(with (pass-test-val ((make-test-fn sample-suite pass-test 3))
       fail-test-val ((make-test-fn sample-suite
       fail-test (err "failing..."))))
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
             single-suite-has-right-suite-name (assert-is 'a
                                                          single-suite!suites!a!suite-name)
             single-suite-contains-one-test (assert-is 1
                                                       (len single-suite!suites!a!tests))
             single-suite-contains-right-test (assert-is 'b
                                                         single-suite!suites!a!tests!b!test-name)
             two-of-each-has-two-tests (assert-is 2
                                                  (len two-of-each!tests))
             two-of-each-has-two-suites (assert-is 2
                                                  (len two-of-each!suites))
             nested-suit-has-right-name (assert-is 'a
                                                   single-suite!suites!a!suite-name)
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
             single-suite-has-right-name (assert-is 'test-suite-2
                                                    single-suite!suite-name)
             single-suite-has-right-full-suite-name (assert-is 'test-suite-2
                                                               single-suite!full-suite-name)
             single-suite-contains-one-test (assert-is 1
                                                       (len single-suite!nested-suites!a!tests))
             single-suite-contains-right-test (assert-is 'b
                                                         single-suite!nested-suites!a!tests!b!test-name)
             single-suites-nested-suite-has-right-full-suite-name (assert-is 'test-suite-2.a
                                                                        single-suite!nested-suites!a!full-suite-name)
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
