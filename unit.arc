(deftem suite
  suite-name ""
  tests nil
  nested-suites nil)

(mac suite (suite-name . tests)
     (ensure-globals)
     `(= (*unit-tests* ',suite-name)
         (make-suite ,suite-name ,@tests)))

(mac make-suite (suite-name . tests)
     `(inst 'suite 'suite-name ',suite-name
           'tests (make-tests ,suite-name
                             (obj)
                             ,@tests)))

;;returns a cons. The car is a list of tests.
;;The cdr is a list of nested suites.

;;going to need to deal with test names: right now, the test takes a suite name. Maybe just make this already a string that's pre-concatenated.
(mac suite-partition everything
     (if everything
         (if (caris (car everything)
                     'suite)
              `(let the-rest (suite-partition ,@(cdr everything))
                   (cons (car the-rest)
                         (cons (make-suite ,@(cdr (car everything)))
                               (cdr the-rest))))
            `(let the-rest (suite-partition ,@(cddr everything))
                 (cons (cons (test 'temp
                                   ',(car everything)
                                   ,(cadr everything))
                             (car the-rest))
                       (cdr the-rest))))
       `(cons nil nil)))

(deftem test
  test-name "no-testname mcgee"
  suite-name "no-suitename mcgee"
  test-fn (fn args (assert nil "You didn't give this test a body. So I'm making it fail.")))

(mac test (suite-name test-name . body)
     `(inst 'test
            'suite-name ',suite-name
            'test-name ',test-name
            'test-fn (fn ()
          (on-err (fn (ex) (inst 'testresults 'suite-name ',suite-name 'test-name ',test-name 'status 'fail 'details (details ex)))
                  (fn ()
                      (inst 'test-results 'suite-name ',suite-name 'test-name ',test-name 'status 'pass 'return-value (do ,@body)))))))

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
           (run-suite name)))

(def run-suite (suite-name)
     (ensure-globals)
     (prn "\nRunning suite " suite-name)
     (= *unit-test-results*.suite-name (obj))
     (aif *unit-tests*.suite-name
          (do (each (name cur-test) it!tests
                    (pretty-results (= *unit-test-results*.suite-name.name
                                       (cur-test!test-fn))))
              (summarize-suite suite-name))
          (err "no suite found" suite-name " isn't a test suite!")))

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
