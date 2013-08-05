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
             `(let ,processed-children (suite-partition ,suite-name
                                                        ,@children)
                   (inst 'suite 'suite-name ',suite-name
                         'nested-suites (,processed-children 'suites)
                         'tests (,processed-children 'tests)
                         'full-suite-name (sym (string (when ',parent-suite-name (string ',parent-suite-name ".")) ',suite-name))))))

;;going to need to deal with test names: right now, the test takes a suite name. Maybe just make this already a string that's pre-concatenated.
(mac suite-partition (parent-suite-name . children)
     (if children
         (w/uniq the-rest
                 (if (isa (car children)
                          'cons)
                     `(let ,the-rest (suite-partition ,(cadr (car children))
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
     (w/uniq name
             `(with (total-tests 0
                     passes 0
                     fails 0)
                    (each ,name ',suite-names
                          (aif (*unit-tests* ,name)
                             (do (run-suite it)
                                 (++ total-tests (count-tests it))
                                 (++ passes (count-passes it))
                                 (++ fails (count-fails it)))
                             (prn "\nno suite found: " ,name " isn't a test suite.")))
                    (if (is passes total-tests)
                        (prn "\nYay! All tests pass! Get yourself a cookie.")
                      (prn "\nOh dear, " fails " of " total-tests " failed.")))))

(def total-tests (cur-results)
     (apply +
            (len cur-results!tests)
            (map (fn (nested-suite)
                     (total-tests nested-suite))
                 (vals cur-results!nested-suites))))

(def run-suite (cur-suite)
     (ensure-globals)
     (prn "\nRunning suite " cur-suite!full-suite-name)
     (= (*unit-test-results* cur-suite!full-suite-name) (obj))
     (each (name cur-test) cur-suite!tests
           (pretty-results (= ((*unit-test-results* cur-suite!full-suite-name) name)
                              (cur-test!test-fn))))
     (summarize-suite cur-suite!full-suite-name)
     (each (child-suite-name child-suite) cur-suite!nested-suites ;;put the child suite in the results
           (push (run-suite child-suite)
                 ((*unit-test-results* cur-suite!full-suite-name) 'child-results)))
     (*unit-test-results* cur-suite!full-suite-name))


(def summarize-suite (suite-name)
     (with (tests 0
            passed 0)
           (each (test-name test-result) *unit-test-results*.suite-name
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

(mac assert-is (expected actual (o fail-message))
     `(assert-two-vals is ,expected ,actual ,fail-message))

(mac assert-iso (expected actual (o fail-message))
     `(assert-two-vals iso ,expected ,actual ,fail-message))

(mac make-tests (suite-name suite-obj . tests)
     (if tests
         (w/uniq cur-suite
                 `(let ,cur-suite ,suite-obj ;;make gensyms
                       (= (,cur-suite ',(car tests))
                          (test ,suite-name
                                ,(car tests)
                                ,(cadr tests)))
                       (make-tests ,suite-name
                                   ,cur-suite
                                   ,@(cddr tests))))
       suite-obj))
