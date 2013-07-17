(deftem suite
  suite-name ""
  tests nil
  nested-suites nil)

(mac suite (suite-name . children)
     (ensure-globals)
     `(= (*unit-tests* ',suite-name)
         (make-suite ,suite-name ,@children)))

(mac make-suite (suite-name . children)
     `(let processed-children (suite-partition ,suite-name
                                               ,@children)
           (inst 'suite 'suite-name ',suite-name
                 'nested-suites processed-children!suites
                 'tests processed-children!tests)))

;;going to need to deal with test names: right now, the test takes a suite name. Maybe just make this already a string that's pre-concatenated.
(mac suite-partition (parent-suite-name . children)
     (if children
         (if (caris (car children)
                     'suite)
              `(let the-rest (suite-partition ,(cadr (car children))
                                              ,@(cdr children))
                    (= (the-rest!suites ',(cadr (car children)))
                       (make-suite ,@(cdr (car children))))
                    the-rest)
            `(let the-rest (suite-partition ,parent-suite-name
                                            ,@(cddr children))
                  (= (the-rest!tests ',(car children))
                     (test ,parent-suite-name
                           ,(car children)
                           ,(cadr children)))
                  the-rest))
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
     `(each name ',suite-names
            (aif *unit-tests*.name
                 (run-suite it)
                 (err "no suite found: " name " isn't a test suite."))))

(def run-suite (cur-suite)
     (ensure-globals)
     (prn "\nRunning suite " cur-suite!suite-name)
     (= (*unit-test-results* cur-suite!suite-name) (obj))
     (each (name cur-test) cur-suite!tests
           (pretty-results (= ((*unit-test-results* cur-suite!suite-name) name)
                              (cur-test!test-fn))))
     (summarize-suite cur-suite!suite-name)
     (each (child-suite-name child-suite) cur-suite!nested-suites
           (run-suite child-suite)))


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

(mac assert-is (expected actual (o fail-message))
     (w/uniq (exp act)
             `(with (,exp ,expected
                     ,act ,actual)
                    (assert (is ,exp ,act)
                            (string (list->str ',actual)
                                   " should be "
                                   (list->str ,expected)
                                   " but instead was "
                                   (list->str ,act)
                                   (awhen ,fail-message
                                          (string ". " it)))))))

(mac assert-iso (expected actual (o fail-message))
     (w/uniq (exp act)
             `(with (,exp ,expected
                     ,act ,actual)
                    (assert (iso ,exp ,act)
                            (string (list->str ',actual)
                                   " should be "
                                   (list->str ,expected)
                                   " but instead was "
                                   (list->str ,act)
                                   (awhen ,fail-message
                                          (string ". " it)))))))

(def list->str (l) ;;iterative
     (if (atom l)
         (string l)
       (let ret nil
            (each ele l
                  (push (list->str ele)
                        ret))
            (string "("
                    (string (intersperse #\space (rev ret)))
                    ")"))))

(def list->str (l) ;;recursive
     (if (atom l)
         (string l)
       (string "("
               (list->str (car l))
               (when (cdr l) " ")
               ((afn (ele)
                     (if (atom ele)
                         (string ele)
                       (string (list->str (car ele))
                               (when (cdr ele) " ")
                               (self (cdr ele)))))
                (cdr l))
               ")")))

(mac make-tests (suite-name suite-obj . tests)
     (if tests
         `(let cur-suite ,suite-obj ;;make gensyms
            (= (cur-suite ',(car tests))
               (test ,suite-name
                     ,(car tests)
                     ,(cadr tests)))
              (make-tests ,suite-name
                          cur-suite
                          ,@(cddr tests)))
       suite-obj))
