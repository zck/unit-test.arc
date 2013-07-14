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
