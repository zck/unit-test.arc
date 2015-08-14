;; Copyright 2013-2015 Zachary Kanfer

;; This file is part of unit-test.arc .

;; unit-test.arc is free software: you can redistribute it and/or modify
;; it under the terms of the GNU Lesser General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; unit-test.arc is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU Lesser General Public License for more details.

;; You should have received a copy of the GNU Lesser General Public License
;; along with unit-test.arc.  If not, see <http://www.gnu.org/licenses/>.



(suite unit-test-tests
       (suite comparisons
              (suite same
                     (test numbers-same (assert-t (same 1 1)))
                     (test numbers-diff (assert-nil (same 1 2)))
                     (test strings-same (assert-t (same "Now Mary" "Now Mary")))
                     (test strings-diff (assert-nil (same "Now Mary" "Mow Nary")))
                     (test lists-same (assert-t (same '(1 2 3)
                                                      '(1 2 3))))
                     (test lists-diff (assert-nil (same '(1 2 3)
                                                        '(1 3 3))))
                     (test lists-sub-lists-of-the-second (assert-nil (same '(1 2 3)
                                                                           '(1 2 3 4))))
                     (test tables-same (assert-t (same (obj 1 2)
                                                       (obj 1 2))))
                     (test tables-different-vals (assert-nil (same (obj 1 2)
                                                                   (obj 1 1))))
                     (test tables-different-keys (assert-nil (same (obj 1 1)
                                                                   (obj 2 1))))
                     (test tables-extra-keys (assert-nil (same (obj 1 2)
                                                               (obj 1 2 3 4))))
                     (test cross-number-and-obj (assert-nil (same 1
                                                                  (obj 1 2))))
                     (test cross-obj-and-number (assert-nil (same (obj 1 2)
                                                                  1)))
                     (test cross-number-and-string (assert-nil (same 1
                                                                     "1")))
                     (test obj-as-key-of-obj-are-same (assert-t (same (w/table tbl (= (tbl (obj 1 2)) 'val))
                                                                      (w/table tbl (= (tbl (obj 1 2)) 'val)))))
                     (test obj-as-val-of-obj-are-same (assert-t (same (obj 1 (obj))
                                                                      (obj 1 (obj))))))

              (suite hash-same
                     (test empty (assert-t (hash-same (obj)
                                                      (obj))))
                     (test single-elt-same (assert-t (hash-same (obj 1 t)
                                                                (obj 1 t))))
                     (test single-elt-different-val (assert-nil (hash-same (obj 1 t)
                                                                           (obj 1 'pants))))
                     (test single-elt-different-key (assert-nil (hash-same (obj 1 t)
                                                                           (obj 2 t))))
                     (test multiple-elts-same (assert-t (hash-same (obj 1 t 2 'a (1) 2)
                                                                   (obj 1 t 2 'a (1) 2))))
                     (test multiple-elts-different-key (assert-nil (hash-same (obj 1 t 2 t 3 t)
                                                                              (obj 1 t 2 t 4 t))))
                     (test multiple-elts-different-val (assert-nil (hash-same (obj 1 t 2 t 3 t)
                                                                              (obj 1 t 2 t 3 4))))
                     (test extra-elt-on-left (assert-nil (hash-same (obj 1 t 2 t)
                                                                    (obj 1 t 2 t 3 t))))
                     (test extra-elt-on-right (assert-nil (hash-same (obj 1 t 2 t 3 t)
                                                                     (obj 1 t 2 t))))
                     (test does-order-matter? (assert-t (hash-same (obj 1 t 2 t)
                                                                   (obj 2 t 1 t))))))

       (suite asserts
              (suite assert
                     (test t-doesnt-error (assert t "shouldn't throw"))
                     (test nil-errors (assert-error (assert nil "should throw"))))


              (suite assert-same
                     (test equal-vals (assert-same 1 1 "equal values are good"))
                     (test lists-are-same (assert-same (list 1) (list 1) "equal lists are good"))
                     (test different-vals (assert-error (assert-same 1 2)))
                     (test hashtables-are-same (assert-same (obj 1 2) (obj 1 2) "equal hashtables are good")))

              (suite assert-t
                     (test t-is-good (assert-t t))
                     (test nil-throws (assert-error (assert-t nil)))
                     (test 3-is-treated-as-good (assert-t 3)))

              (suite assert-nil
                     (test t-is-good (assert-error (assert-nil t)))
                     (test nil-is-good (assert-nil nil))
                     (test 3-is-treated-as-bad (assert-error (assert-nil 3))))

              (suite assert-error
                     (test err-is-ok (assert-error (err "oh dear!")))
                     (test no-err-fails (assert-nil (errsafe (do (assert-error "no error")
                                                                 t))))
                     (test checks-error-message (assert-nil (errsafe (do (assert-error (err "this is bad")
                                                                                       "this is the wrong message")
                                                                         t))))
                     (test valid-error-message-passes (assert-error (err "oh no...")
                                                                    "oh no..."))
                     (test no-error-fails-when-error-message-given (assert-nil (errsafe (do (assert-error "no error" "error message")
                                                                                            t))
                                                                               "Even when an error message is given, not having an error should fail assert-error.")))

              (suite assert-no-error
                     (test no-error-is-ok (assert-no-error 3))

                     ;;errsafe returns nil if error happens, so if assert-no-error properly errors
                     ;;(because there was an error in its body), errsafe will return nil.
                     ;;If there's no error, it'll return t and not error
                     (test error-fails (assert-nil (errsafe (do (assert-no-error (err "error!"))
                                                                t))))))

       (suite-w/setup make-test
                      (sample-test (make-test sample-suite sample-test nil 3)
                       simple-setup (make-test sample-suite simple-setup (x 3) x)
                       multiple-variable-setup (make-test sample-suite multiple-variable-setup (x 3 y 4) (+ x y))
                       reliant-variable-setup (make-test sample-suite reliant-variable-setup (x 3 y x) (+ x y)))
                      (test test-name (assert-same 'sample-test sample-test!test-name))
                      (test suite-name (assert-same 'sample-suite sample-test!suite-name))
                      (test test-fn (assert-same 3
                                                 ((sample-test!test-fn)
                                                  'return-value)))
                      (test simple-setup (assert-same 3
                                                      ((simple-setup!test-fn)
                                                       'return-value)))
                      (test multiple-variable-setup (assert-same 7
                                                                 ((multiple-variable-setup!test-fn)
                                                                  'return-value)))
                      (test reliant-variable-setup (assert-same 6
                                                                ((reliant-variable-setup!test-fn)
                                                                 'return-value)))
                                     (test suite-names-cant-have-periods (assert-error (make-test sample test.name nil))))



       (suite-w/setup make-test-fn
                      (pass-test-val ((make-test-fn sample-suite pass-test nil 3))
                       fail-test-val ((make-test-fn sample-suite fail-test nil (err "failing...")))
                       simple-setup ((make-test-fn sample-suite w/setup (x 3) x))
                       multiple-variable-setup ((make-test-fn sample-suite multiple-variable-setup (x 3 y 4) (+ x y)))
                       reliant-variable-setup ((make-test-fn sample-suite reliant-variable-setup (x 3 y x) (+ x y)))
                       multiple-asserts-all-pass-val ((make-test-fn sample-suite multiple-asserts-all-pass-val nil (assert-same 2 2) (assert-same 1 1)))
                       multiple-asserts-first-fails-val ((make-test-fn sample-suite multiple-asserts-first-fails-val nil (assert-same 2 1) (assert-same 1 1)))
                       multiple-asserts-second-fails-val ((make-test-fn sample-suite multiple-asserts-second-fails-val nil (assert-same 2 2) (assert-same 1 42))))
                      (test pass-has-right-return-value (assert-same 3 pass-test-val!return-value))
                      (test pass-has-test-name (assert-same 'pass-test pass-test-val!test-name))
                      (test fail-has-test-name (assert-same 'fail-test fail-test-val!test-name))
                      (test pass-has-suite-name (assert-same 'sample-suite pass-test-val!suite-name))
                      (test fail-has-suite-name (assert-same 'sample-suite fail-test-val!suite-name))
                      (test pass-has-pass-status (assert-same 'pass pass-test-val!status))
                      (test fail-has-fail-status (assert-same 'fail fail-test-val!status))
                      (test fail-has-proper-details (assert-same "failing..." fail-test-val!details))
                      (test setup-has-right-value (assert-same 3 simple-setup!return-value))
                      (test multiple-variables-are-setup-properly (assert-same 7 multiple-variable-setup!return-value))
                      (test reliant-variables-are-setup-properly (assert-same 6 reliant-variable-setup!return-value))
                      (test multiple-asserts-work (assert-t (result-is-pass multiple-asserts-all-pass-val)))
                      (test multiple-asserts-first-fails (assert-nil (result-is-pass multiple-asserts-first-fails-val)))
                      (test multiple-asserts-second-fails (assert-nil (result-is-pass multiple-asserts-second-fails-val))))

       (suite suite-creation
              (suite-w/setup suite-partition
                             (single-test (suite-partition test-suite-1 nil (test a 3))
                                          single-suite (suite-partition test-suite-2 nil (suite a (test b 3)))
                                          two-of-each (suite-partition test-suite-3 nil (test a 3) (suite b (test c 4)) (test d 5) (suite e (test f 6) (test g 7)))
                                          none-of-either (suite-partition test-suite-4 nil)
                                          test-after-nested-suite (suite-partition test-suite-4 nil (suite a (test b 1)) (test c 2))
                                          test-with-setup (suite-partition test-suite-5 (x 3) (test a x))
                                          nested-test-with-setup (suite-partition test-suite-6 nil (suite-w/setup a (x 3) (test b x))))
                             (test nothing (assert-t (empty none-of-either!tests))
                                   (assert-t (empty none-of-either!suites)))
                             (test single-test-has-no-suite (assert-t (empty single-test!suites)))
                             (test single-test-has-one-test (assert-same 1
                                                                         (len single-test!tests)))
                             (test single-test-has-right-test (assert-same 'a
                                                                           single-test!tests!a!test-name))
                             (test single-test-has-right-suite (assert-same 'test-suite-1
                                                                            single-test!tests!a!suite-name))
                             (test single-suite-has-no-tests (assert-t (empty single-suite!tests)))
                             (test single-suite-has-one-suite (assert-same 1
                                                                           (len single-suite!suites)))
                             (test single-suite-contains-one-test (assert-same 1
                                                                               (len single-suite!suites!a!tests)))
                             (test single-suite-contains-right-test (assert-same 'b
                                                                                 single-suite!suites!a!tests!b!test-name))
                             (test two-of-each-has-two-tests (assert-same 2
                                                                          (len two-of-each!tests)))
                             (test two-of-each-has-two-suites (assert-same 2
                                                                           (len two-of-each!suites)))
                             (test nested-suite-has-right-name (assert-same 'a
                                                                            single-suite!suites!a!suite-name))
                             (test nested-suite-has-right-full-name (assert-same 'test-suite-2.a
                                                                                 single-suite!suites!a!full-suite-name))
                             (test test-after-nested-suite-has-correct-parent-name (assert-same 'test-suite-4
                                                                                                test-after-nested-suite!tests!c!suite-name))
                             (test test-fn-returns-right-value (assert-same 3
                                                                            ((single-test!tests!a!test-fn) 'return-value)))
                             (test nested-test-fn-returns-right-value (assert-same 3
                                                                                   ((single-suite!suites!a!tests!b!test-fn) 'return-value)))
                             (test test-with-setup-returns-right-value (assert-same 3
                                                                                    ((test-with-setup!tests!a!test-fn)
                                                                                     'return-value)))
                             (test nested-test-with-setup-returns-right-value (assert-same 3
                                                                                           ((nested-test-with-setup!suites!a!tests!b!test-fn)
                                                                                            'return-value))))

              (suite-w/setup make-suite
                             (single-test (make-suite test-suite-1 nil nil (test a 3))
                                           single-suite (make-suite test-suite-2 nil nil (suite a (test b 3)))
                                           two-of-each (make-suite test-suite-3 nil nil (test a 3) (suite b (test c 4)) (test d 5) (suite e (test f 6) (test g 7)))
                                           test-w/setup (make-suite test-suite-4 nil (x 3) (test a x)))
                             (test single-test-has-no-suite (assert-t (empty single-test!suites)))
                             (test single-test-has-one-test (assert-same 1
                                                                         (len single-test!tests)))
                             (test single-test-has-right-test (assert-same 'a
                                                                           single-test!tests!a!test-name))
                             (test single-test-has-right-suite (assert-same 'test-suite-1
                                                                            single-test!tests!a!suite-name))
                             (test single-suite-has-no-tests (assert-t (empty single-suite!tests)))
                             (test single-suite-has-one-suite (assert-same 1
                                                                           (len single-suite!nested-suites)))
                             (test single-suites-nested-suite-has-right-suite-name (assert-same 'a
                                                                                                single-suite!nested-suites!a!suite-name))
                             (test single-suites-nested-suite-has-right-full-suite-name (assert-same 'test-suite-2.a
                                                                                                     single-suite!nested-suites!a!full-suite-name))
                             (test single-suite-has-right-name (assert-same 'test-suite-2
                                                                            single-suite!suite-name))
                             (test single-suite-has-right-full-suite-name (assert-same 'test-suite-2
                                                                                       single-suite!full-suite-name))
                             (test single-suite-contains-one-test (assert-same 1
                                                                               (len single-suite!nested-suites!a!tests)))
                             (test single-suite-contains-right-test (assert-same 'b
                                                                                 single-suite!nested-suites!a!tests!b!test-name))
                             (test single-suite-test-in-nested-suite-has-right-suite-name (assert-same 'test-suite-2.a
                                                                                                       single-suite!nested-suites!a!tests!b!suite-name))
                             (test two-of-each-has-two-tests (assert-same 2
                                                                          (len two-of-each!tests)))
                             (test two-of-each-has-two-suites (assert-same 2
                                                                           (len two-of-each!nested-suites)))
                             (test setup-is-done-properly (assert-same 3
                                                                       ((test-w/setup!tests!a!test-fn)
                                                                        'return-value)))
                             (test periods-in-suite-names-error (assert-error (make-suite suite.name nil nil))))

              (suite-w/setup check-for-shadowing
                             (empty-suite (inst 'suite 'suite-name 'empty-suite)
                              suite-with-tests (inst 'suite
                                                     'suite-name 'suite-with-tests
                                                     'tests (obj test1 t test2 t))
                              suite-with-nested-suites (inst 'suite
                                                             'suite-name 'suite-with-nested-suites
                                                             'nested-suites (obj empty-suite empty-suite))
                              suite-with-no-shadows (inst 'suite
                                                          'suite-name 'no-shadows
                                                          'tests (obj test-name t)
                                                          'nested-suites (obj empty-suite empty-suite))
                              suite-with-shadows (inst 'suite
                                                       'suite-name 'suite-with-shadows
                                                       'tests (obj shadow t)
                                                       'nested-suites (obj shadow (inst 'suite 'suite-name 'shadow)))
                              nested-suite-with-no-shadows (inst 'suite
                                                                 'suite-name 'parent
                                                                 'nested-suites (obj suite-with-no-shadows suite-with-no-shadows)
                                                                 'tests (obj test-name t))
                              nested-suite-with-shadows (inst 'suite
                                                              'suite-name 'parent
                                                              'nested-suites (obj suite-with-shadows suite-with-no-shadows)
                                                              'tests (obj suite-with-shadows t)))
                             (test empty-suite-is-ok (assert-no-error (check-for-shadowing empty-suite)))
                             (test suite-with-nested-suite-is-ok (assert-no-error (check-for-shadowing suite-with-nested-suites)))
                             (test suite-with-no-shadows-is-ok (assert-no-error (check-for-shadowing suite-with-no-shadows)))
                             (test suite-with-shadows-errors (assert-error (check-for-shadowing suite-with-shadows)))
                             (test nested-suite-with-shadows-errors (assert-error (check-for-shadowing nested-suite-with-shadows)))
                             (test nested-suite-with-no-shadows-is-ok (assert-no-error (check-for-shadowing nested-suite-with-no-shadows)))))


       (suite new-suite-creation
              (suite-w/setup new-suite-partition
                             (single-test (new-suite-partition test-suite-1 nil (test a 3))
                              ;; single-suite (new-suite-partition test-suite-2 nil (suite a (test b 3)))
                              ;; two-of-each (new-suite-partition test-suite-3 nil (test a 3) (suite b (test c 4)) (test d 5) (suite e (test f 6) (test g 7)))
                              none-of-either (new-suite-partition test-suite-4 nil)
                              ;; test-after-nested-suite (new-suite-partition test-suite-4 nil (suite a (test b 1)) (test c 2))
                              ;; test-with-setup (new-suite-partition test-suite-5 (x 3) (test a x))
                              ;; nested-test-with-setup (new-suite-partition test-suite-6 nil (suite-w/setup a (x 3) (test b x)))
                              )
                             (test nothing (assert-t (empty none-of-either!tests))
                                   (assert-t (empty none-of-either!suites)))
                             (test single-test-has-no-suite (assert-t (empty single-test!suites)))
                             (test single-test-has-one-test (assert-same 1
                                                                         (len single-test!tests)))
                             (test single-test-has-right-test (assert-same 'a
                                                                           single-test!tests!a!test-name))
                             (test single-test-has-right-suite (assert-same 'test-suite-1
                                                                            single-test!tests!a!suite-name))
                             (test single-suite-has-no-tests (assert-t (empty single-suite!tests)))
                             (test single-suite-has-one-suite (assert-same 1
                                                                           (len single-suite!suites)))
                             (test single-suite-contains-one-test (assert-same 1
                                                                               (len single-suite!suites!a!tests)))
                             (test single-suite-contains-right-test (assert-same 'b
                                                                                 single-suite!suites!a!tests!b!test-name))
                             (test two-of-each-has-two-tests (assert-same 2
                                                                          (len two-of-each!tests)))
                             (test two-of-each-has-two-suites (assert-same 2
                                                                           (len two-of-each!suites)))
                             (test nested-suite-has-right-name (assert-same 'a
                                                                            single-suite!suites!a!suite-name))
                             (test nested-suite-has-right-full-name (assert-same 'test-suite-2.a
                                                                                 single-suite!suites!a!full-suite-name))
                             (test test-after-nested-suite-has-correct-parent-name (assert-same 'test-suite-4
                                                                                                test-after-nested-suite!tests!c!suite-name))
                             (test test-fn-returns-right-value (assert-same 3
                                                                            ((single-test!tests!a!test-fn) 'return-value)))
                             (test nested-test-fn-returns-right-value (assert-same 3
                                                                                   ((single-suite!suites!a!tests!b!test-fn) 'return-value)))
                             (test test-with-setup-returns-right-value (assert-same 3
                                                                                    ((test-with-setup!tests!a!test-fn)
                                                                                     'return-value)))
                             (test nested-test-with-setup-returns-right-value (assert-same 3
                                                                                           ((nested-test-with-setup!suites!a!tests!b!test-fn)
                                                                                            'return-value))))

              (suite-w/setup new-make-suite
                             (single-test (new-make-suite test-suite-1 (test a 3))
                              single-suite (new-make-suite test-suite-2 (suite a (test b 3)))
                              two-of-each (new-make-suite test-suite-3 ((test a 3) (suite b (test c 4)) (test d 5) (suite e (test f 6) (test g 7))))
                              test-w/setup (new-make-suite test-suite-4  ;; (x 3)
                                                           (test a x)))
                             (test single-test-has-no-suite (assert-t (empty single-test!suites)))
                             (test single-test-has-one-test (assert-same 1
                                                                         (len single-test!tests)))
                             (test single-test-has-right-test (assert-same 'a
                                                                           single-test!tests!a!test-name))
                             (test single-test-has-right-suite (assert-same 'test-suite-1
                                                                            single-test!tests!a!suite-name))
                             (test single-suite-has-no-tests (assert-t (empty single-suite!tests)))
                             (test single-suite-has-one-suite (assert-same 1
                                                                           (len single-suite!nested-suites)))
                             (test single-suites-nested-suite-has-right-suite-name (assert-same 'a
                                                                                                single-suite!nested-suites!a!suite-name))
                             (test single-suites-nested-suite-has-right-full-suite-name (assert-same 'test-suite-2.a
                                                                                                     single-suite!nested-suites!a!full-suite-name))
                             (test single-suite-has-right-name (assert-same 'test-suite-2
                                                                            single-suite!suite-name))
                             (test single-suite-has-right-full-suite-name (assert-same 'test-suite-2
                                                                                       single-suite!full-suite-name))
                             (test single-suite-contains-one-test (assert-same 1
                                                                               (len single-suite!nested-suites!a!tests)))
                             (test single-suite-contains-right-test (assert-same 'b
                                                                                 single-suite!nested-suites!a!tests!b!test-name))
                             (test single-suite-test-in-nested-suite-has-right-suite-name (assert-same 'test-suite-2.a
                                                                                                       single-suite!nested-suites!a!tests!b!suite-name))
                             (test two-of-each-has-two-tests (assert-same 2
                                                                          (len two-of-each!tests)))
                             (test two-of-each-has-two-suites (assert-same 2
                                                                           (len two-of-each!nested-suites)))
                             (test setup-is-done-properly (assert-same 3
                                                                       ((test-w/setup!tests!a!test-fn)
                                                                        'return-value)))
                             (test periods-in-suite-names-error (assert-error (new-make-suite suite.name nil)))))


       (suite count-passes
              (test 0-empty (assert-same 0
                                         (count-passes (inst 'suite-results
                                                             'test-results (obj)))))
              (test 0-stuff (assert-same 0
                                         (count-passes (inst 'suite-results
                                                             'test-results (obj fail (inst 'test-results 'status 'fail))))))
              (test 1 (assert-same 1
                                   (count-passes (inst 'suite-results
                                                       'test-results (obj numbers
                                                                          (inst 'test-results 'status 'pass))))))
              (test 2-flat (assert-same 2
                                        (count-passes (inst 'suite-results
                                                            'test-results (obj sample1 (inst 'test-results 'status 'pass)
                                                                               sample2 (inst 'test-results 'status 'fail)
                                                                               sample3 (inst 'test-results 'status 'pass))))))
              (test 3-nested (assert-same 3
                                          (count-passes (inst 'suite-results
                                                              'test-results (obj sample1 (inst 'test-results 'status 'pass)
                                                                                 sample2 (inst 'test-results 'status 'pass)
                                                                                 sample3 (inst 'test-results 'status 'fail))
                                                              'nested-suite-results (obj nested (inst 'suite-results
                                                                                                      'test-results (obj sample1 (inst 'test-results 'status 'pass)
                                                                                                                         sample2 (inst 'test-results 'status 'fail))))))))
              (test 1-empty-main-suite (assert-same 1
                                                    (count-passes (inst 'suite-results
                                                                        'nested-suite-results (obj nested (inst 'suite-results
                                                                                                                'test-results (obj sample1 (inst 'test-results 'status 'pass)
                                                                                                                                   sample2 (inst 'test-results 'status 'fail))))))))
              (test 3-doubly-nested (assert-same 3
                                                 (count-passes (inst 'suite-results
                                                                     'test-results (obj sample1 (inst 'test-results 'status 'fail))
                                                                     'nested-suite-results (obj nested1 (inst 'suite-results
                                                                                                              'test-results (obj sample2 (inst 'test-results 'status 'pass)
                                                                                                                                 sample3 (inst 'test-results 'status 'fail))
                                                                                                              'nested-suite-results (obj nested2 (inst 'suite-results
                                                                                                                                                       'test-results (obj sample4 (inst 'test-results 'status 'pass)
                                                                                                                                                                          sample5 (inst 'test-results 'status 'pass)
                                                                                                                                                                          sample6 (inst 'test-results 'status 'fail)
                                                                                                                                                                          sample7 (inst 'test-results 'status 'fail))))))))))
              (test 6-multiple-nested (assert-same 6
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
                                                                                                                     sample7 (inst 'test-results 'status 'fail)))))))))



       (suite result-is-pass
              (test pass (assert-t (result-is-pass (inst 'test-results
                                                         'status 'pass))))
              (test fail (assert-nil (result-is-pass (inst 'test-results
                                                           'status 'fail)))))

       (suite to-readable-string
              (test strings-are-quoted (assert-same "'string!'"
                                                    (to-readable-string "string!")))
              (test numbers-are-ok (assert-same "42"
                                                (to-readable-string 42)))
              (test lists-are-ok (assert-same "(1 (2 3) . 4)"
                                              (to-readable-string '(1 (2 3) . 4))))
              (test lists-containing-string (assert-same "(1 '2' 3)"
                                                         (to-readable-string '(1 "2" 3))))
              (test tables-containing-string (assert-same "#hash((1 . '2')('3' . 4))"
                                                          (to-readable-string (obj 1 "2" "3" 4)))))

       (suite names
              (suite make-full-name
                     (test regular (assert-same 'pants
                                                (make-full-name nil
                                                                'pants)))
                     (test nested (assert-same 'parent.child
                                               (make-full-name 'parent
                                                               'child)))
                     (test multi-nested (assert-same 'parent.child.grandchild
                                                     (make-full-name 'parent 'child 'grandchild))))

              (suite is-valid-name
                     (test periods-not-ok (assert-nil (is-valid-name "hi.there")))
                     (test no-period-is-ok (assert-t (is-valid-name "hi;there!mom:)"))))

              (suite get-suite-name
                     (test only-suite-name (assert-same 'base
                                                        (get-suite-name 'base)))
                     (test with-test-name (assert-same 'base
                                                       (get-suite-name 'base.test)))
                     (test nested-suites (assert-same 'base.nested
                                                      (get-suite-name 'base.nested.test))))

              (suite get-test-name
                     (test simple-test-name (assert-same 'test-name
                                                         (get-test-name 'base.test-name)))
                     (test nested-suites (assert-same 'test-name
                                                      (get-test-name 'base.nested.test-name))))

              (suite get-suite-and-test-name
                     (test no-test-name (assert-same '(suite nil)
                                                     (get-suite-and-test-name 'suite)))
                     (test simple-test-name (assert-same '(suite test)
                                                         (get-suite-and-test-name 'suite.test)))
                     (test nested-suites (assert-same '(suite.nested test)
                                                      (get-suite-and-test-name 'suite.nested.test)))
                     (test deeply-nested-suites (assert-same '(suite.nested1.nested2.nested3 test)
                                                             (get-suite-and-test-name 'suite.nested1.nested2.nested3.test))))

              (suite get-name-fragments
                     (test simple (assert-same '(top-level)
                                               (get-name-fragments 'top-level)))
                     (test one-nested (assert-same '(top-level single)
                                                   (get-name-fragments 'top-level.single)))
                     (test two-nested (assert-same '(top-level nested-1 nested-2)
                                                   (get-name-fragments 'top-level.nested-1.nested-2))))

              (suite filter-unique-names
                     (test empty (assert-nil (filter-unique-names '())))
                     (test one-thing (assert-same '(my-name) (filter-unique-names '(my-name))))
                     (test different-things (assert-same '(one two) (filter-unique-names '(one two))))
                     (test removes-duplicates (assert-same '(one) (filter-unique-names '(one one one one))))
                     (test removes-nested-duplicates (assert-same '(one) (filter-unique-names '(one one.two.three.four))))
                     (test removes-nonconsecutive-duplicates (assert-same '(one two) (filter-unique-names '(one two one two))))
                     (test leading-differs (assert-same '(hell hello) (filter-unique-names '(hell hello))))
                     (test keeps-more-general (assert-same '(top-scope) (filter-unique-names '(top-scope top-scope.nested))))
                     (test keeps-nested-names (assert-same '(a.b.c.d) (filter-unique-names '(a.b.c.d))))
                     (test many-items (assert-same '(math top.one top.three.nested top.two a)
                                                   (filter-unique-names '(math top.one a.b top.three.nested top.two a math.adding))))
                     (test multiple-removals (assert-same '(math xyzzy) (filter-unique-names '(math xyzzy math.adding xyzzy math))))
                     (test order-is-kept (assert-same '(z a y b) (filter-unique-names '(z a y b))))
                     (test first-duplicate-is-kept (assert-same '(z a) (filter-unique-names '(z a z)))))))
