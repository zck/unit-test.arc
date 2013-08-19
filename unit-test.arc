(deftem suite
  suite-name ""
  tests nil
  nested-suites nil
  full-suite-name "")

(mac suite (suite-name . children)
     (ensure-globals)
     `(= (*unit-tests* ',suite-name)
         (make-suite ,suite-name nil ,@children)))

(mac make-suite (suite-name parent-suite-name . children)
     (w/uniq processed-children
             `(let ,processed-children (suite-partition ,(make-full-suite-name parent-suite-name
                                                                               suite-name)
                                                        ,@children)
                   (inst 'suite 'suite-name ',suite-name
                         'nested-suites (,processed-children 'suites)
                         'tests (,processed-children 'tests)
                         'full-suite-name (make-full-suite-name ',parent-suite-name
                                                                ',suite-name)))))

;;going to need to deal with test names: right now, the test takes a suite name. Maybe just make this already a string that's pre-concatenated.
(mac suite-partition (parent-suite-name . children)
     (if children
         (w/uniq the-rest
                 (if (isa (car children)
                          'cons)
                     `(let ,the-rest (suite-partition ,parent-suite-name
                                                      ,@(cdr children))
                           (= ((,the-rest 'suites) ',(cadr (car children)))
                              (make-suite ,(cadr (car children))
                                          ,parent-suite-name
                                          ,@(cddr (car children))))
                           ,the-rest)
                   `(let ,the-rest (suite-partition ,parent-suite-name
                                                   ,@(cddr children))
                         (= ((,the-rest 'tests) ',(car children))
                            (test ,parent-suite-name
                                  ,(car children)
                                  ,(cadr children)))
                         ,the-rest)))
       `(obj tests (obj) suites (obj))))

(deftem test
  test-name "no-testname mcgee"
  suite-name "no-suitename mcgee"
  test-fn (fn args (assert nil "You didn't give this test a body. So I'm making it fail.")))

(mac test (suite-name test-name . body)
     `(inst 'test
            'suite-name ',suite-name
            'test-name ',test-name
            'test-fn (make-test-fn ,suite-name ,test-name ,@body)))

(mac make-test-fn (suite-name test-name . body)
     `(fn ()
          (on-err (fn (ex) (inst 'testresults 'suite-name ',suite-name 'test-name ',test-name 'status 'fail 'details (details ex)))
                  (fn ()
                      (inst 'test-results 'suite-name ',suite-name 'test-name ',test-name 'status 'pass 'return-value (do ,@body))))))

(deftem test-results
  test-name ""
  suite-name ""
  status 'fail
  details ""
  return-value nil)

(def pretty-results (test-result)
     (pr test-result!suite-name "." test-result!test-name " ")
     (if (is test-result!status 'pass)
         (prn  "passed!")
       (prn "failed: " test-result!details)))

(mac run-suites suite-names
     `(do
       (run-these-suites ,@suite-names)
       (summarize-run ,@suite-names)
       nil))

(mac run-suite suite-names
     `(run-suites ,@suite-names))

(mac run-these-suites suite-names
     (w/uniq name
             `(each ,name ',suite-names
                    (aif (*unit-tests* ,name)
                         (run-one-suite it)
                         (prn "\nno suite found: " ,name " isn't a test suite.")))))

;; Summarize a given test run. That is, print out information about the overall
;; status of a set of suites.
(mac summarize-run suite-names
     (w/uniq name
             `(with (tests 0
                     passes 0)
                    (each ,name ',suite-names
                          (let results (*unit-test-results* ,name)
                               (++ tests (total-tests results))
                               (++ passes (count-passes results))))
                    (if (is passes tests)
                        (prn "\nYay! All " tests " tests pass! Get yourself a cookie.")
                      (prn "\nOh dear, " (- tests passes) " of " tests " failed.")))))

(def total-tests (suite-results)
     (apply +
            (len suite-results!test-results)
            (map total-tests
                 (vals suite-results!nested-suite-results))))

(def count-passes (suite-results)
     (apply +
            (count result-is-pass
                   (vals suite-results!test-results))
            (map count-passes
                 (vals suite-results!nested-suite-results))))

(def result-is-pass (test-result)
     (is test-result!status
         'pass))

(deftem suite-results
  suite-name ""
  test-results (obj) ;;hash of test-name -> test-result
  nested-suite-results (obj)) ;;nested-suite-fullname -> suite-result

(def run-one-suite (cur-suite)
     (ensure-globals)
     (prn "\nRunning suite " cur-suite!full-suite-name)
     (= (*unit-test-results* cur-suite!full-suite-name)
        (inst 'suite-results 'suite-name cur-suite!full-suite-name))
     (run-tests cur-suite)
     (summarize-suite cur-suite!full-suite-name)
     (run-child-suites cur-suite)
     (*unit-test-results* cur-suite!full-suite-name))

;; Runs all the tests inside cur-suite. Does not recurse.
(def run-tests (cur-suite)
     (let cur-results ((*unit-test-results* cur-suite!full-suite-name) 'test-results)
          (each (name cur-test) cur-suite!tests
                (pretty-results (= cur-results.name
                                   (cur-test!test-fn))))))

(def run-child-suites (cur-suite)
     (let cur-results ((*unit-test-results* cur-suite!full-suite-name)
                       'nested-suite-results)
          (each (child-suite-name child-suite) cur-suite!nested-suites
                (= cur-results.child-suite-name
                   (run-one-suite child-suite)))))

(def summarize-suite (suite-name)
     (with (tests 0
            passed 0)
           (each (test-name test-result) *unit-test-results*.suite-name!test-results
                 (++ tests)
                 (when (is test-result!status 'pass)
                   (++ passed)))
           (prn "In " suite-name ", " passed " of " tests " passed.")))

(def ensure-globals ()
     (unless (bound '*unit-tests*)
       (= *unit-tests* (obj)))
     (unless (bound '*unit-test-results*)
       (= *unit-test-results* (obj))))

(mac assert (test fail-message)
     `(unless ,test
        (err ,fail-message)))

(mac assert-two-vals (test expected actual (o fail-message))
     (w/uniq (exp act)
             `(with (,exp ,expected
                          ,act ,actual)
                    (assert (,test ,exp ,act)
                            (string (tostring (disp ',actual))
                                    " should be "
                                    (tostring (disp ,expected))
                                    " but instead was "
                                    (tostring (disp ,act))
                                    (awhen ,fail-message
                                           (string ". " it)))))))

(mac assert-same (expected actual (o fail-message))
     `(assert-two-vals iso ,expected ,actual ,fail-message))

(mac assert-t (actual (o fail-message))
     `(assert-two-vals isnt nil ,actual ,fail-message))
;; have to do "isnt nil" because we want to accept _any_ non-nil value, not just 't

(mac assert-nil (actual (o fail-message))
     `(assert-two-vals is nil ,actual ,fail-message))

(mac make-tests (suite-name suite-obj . tests)
     (if tests
         (w/uniq cur-suite
                 `(let ,cur-suite ,suite-obj
                       (= (,cur-suite ',(car tests))
                          (test ,suite-name
                                ,(car tests)
                                ,(cadr tests)))
                       (make-tests ,suite-name
                                   ,cur-suite
                                   ,@(cddr tests))))
       suite-obj))

(def make-full-suite-name (parent-suite-name child-suite-name)
     (sym (string (when parent-suite-name
                    (string parent-suite-name "."))
                  child-suite-name)))

(def same (thing1 thing2)
     (if (and (isa thing1
                   'table)
              (isa thing2
                   'table))
         (hash-equal thing1 thing2)
       (iso thing1 thing2)))

(def hash-equal (hash1 hash2)
     (and (is (len (keys hash1))
              (len (keys hash2))) ;;only need to check the length here; if the keys differ, we'll find it below
          (all idfn
               (map [is hash1._
                        hash2._]
                    (keys hash1)))))
