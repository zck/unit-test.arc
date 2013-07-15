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
