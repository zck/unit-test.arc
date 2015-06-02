;; Copyright 2013-2014 Zachary Kanfer

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



(deftem suite
  suite-name ""
  tests nil
  nested-suites nil
  full-suite-name "")

(mac suite (suite-name . children)
     `(summarize-suite-creation (make-and-save-suite ,suite-name nil nil ,@children)))

(mac suite-w/setup (suite-name setup . children)
     `(summarize-suite-creation (make-and-save-suite ,suite-name nil ,setup ,@children)))

(def summarize-suite-creation (cur-suite)
     (summarize-single-suite cur-suite)
     (each (suite-name nested-suite) cur-suite!nested-suites
           (summarize-suite-creation nested-suite)))

(def summarize-single-suite (cur-suite)
     (prn "Successfully created suite "
          cur-suite!full-suite-name
          " with "
          (plural (len cur-suite!tests) "test")
          " and "
          (plural (len cur-suite!nested-suites) "nested suite")
          "."))

(mac make-and-save-suite (suite-name parent-suite-name setup . children)
     (ensure-globals)
     `(= (*unit-tests* ',(make-full-name parent-suite-name
                                               suite-name))
         (make-suite ,suite-name ,parent-suite-name ,setup ,@children)))

(mac make-suite (suite-name parent-suite-name setup . children)
     (w/uniq processed-children
             `(if (no (is-valid-name ',suite-name))
                  (err (string "Suite names can't have periods in them. "
                               ',suite-name
                               " does."))
                (let ,processed-children (suite-partition ,(make-full-name parent-suite-name
                                                                                 suite-name)
                                                          ,setup
                                                          ,@children)
                     (inst 'suite 'suite-name ',suite-name
                           'nested-suites (,processed-children 'suites)
                           'tests (,processed-children 'tests)
                           'full-suite-name (make-full-name ',parent-suite-name
                                                                  ',suite-name))))))

(mac suite-partition (parent-suite-name setup . children)
     (if children
         (w/uniq the-rest
                 (if (atom (car children))  ;;test names can be anything but lists
                     ;; it must be a test, so children is
                     ;; (testname test-body . everything-else)
                     `(let ,the-rest (suite-partition ,parent-suite-name
                                                      ,setup
                                                      ,@(cddr children))
                           (= ((,the-rest 'tests) ',(car children))
                              (test ,parent-suite-name
                                    ,(car children)
                                    ,setup
                                    ,(cadr children)))
                           ,the-rest)
                   (is (caar children)
                       'suite)
                   ;; children is
                   ;; ((suite . suite-body) . everything-else)
                   `(let ,the-rest (suite-partition ,parent-suite-name
                                                    ,setup
                                                    ,@(cdr children))
                         (= ((,the-rest 'suites) ',(cadr (car children)))
                            (make-and-save-suite ,(cadr (car children))
                                                 ,parent-suite-name
                                                 nil
                                                 ,@(cddr (car children))))
                         ,the-rest)
                   ;; here, children is
                   ;; ((suite-w/setup suite-name (setup...) . body) . rest)
                   `(let ,the-rest (suite-partition ,parent-suite-name
                                                    ,setup
                                                    ,@(cdr children))
                         (= ((,the-rest 'suites) ',(cadr (car children)))
                            (make-and-save-suite ,(cadr (car children))
                                                 ,parent-suite-name
                                                 ,((car children) 2)
                                                 ,@(nthcdr 3 (car children))))
                         ,the-rest)))
       `(obj tests (obj) suites (obj))))

(deftem test
  test-name "no-testname mcgee"
  suite-name "no-suitename mcgee"
  test-fn (fn args (assert nil "You didn't give this test a body. So I'm making it fail.")))

(mac test (suite-name test-name setup . body)
     `(if (no (is-valid-name ',test-name))
          (err (string "Test names can't have periods in them. "
                       ',test-name
                       " does."))
        (inst 'test
              'suite-name ',suite-name
              'test-name ',test-name
              'test-fn (make-test-fn ,suite-name ,test-name ,setup ,@body))))

(mac make-test-fn (suite-name test-name setup . body)
     `(fn ()
          (on-err (fn (ex) (inst 'testresults 'suite-name ',suite-name 'test-name ',test-name 'status 'fail 'details (details ex)))
                  (fn ()
                      (eval '(withs ,setup
                                   (inst 'test-results 'suite-name ',suite-name 'test-name ',test-name 'status 'pass 'return-value (w/stdout (outstring) ,@body))))))))

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
     `(run-suite-list ',suite-names))

(mac run-suite suite-names
     `(run-suites ,@suite-names))

(= *last-test-run* nil)

;;is this consistent with rerun-last-suite?
(def rerun-last-test ()
     (if *last-test-run*
         (run-test *last-test-run*) ;;this macroexpands badly. we probably want to separate the run-test command parsing from the actual body, which doesn't require a function. Something like mac run-test, and def run-test-innards, which does the body of the work.
       (prn "There wasn't a test run previously.")))

(mac run-test args
     (withs (test-full-name (apply make-full-name args)
             test-name (get-test-name test-full-name)
             suite-name (get-suite-name test-full-name))
          (w/uniq (suite test)
                  `(do
                    (ensure-globals)
                    (let ,suite (*unit-tests* ',suite-name)
                         (if ,suite
                             (let ,test ((,suite 'tests) ',test-name)
                                  (if ,test
                                      (let results ((,test 'test-fn))
                                           (= *last-test-run* ',test-full-name)
                                           (pretty-results results))
                                    (prn "we found a suite named " ',suite-name ", but no test named " ',test-name)))
                           (let (existing-suite-name absent-suite-name) (find-nested-suite-that-exists-and-next-one ',suite-name)
                                (if existing-suite-name
                                    (prn "we found a suite named " existing-suite-name ", but it doesn't contain a nested suite named " absent-suite-name)
                                  (prn "we didn't find a suite named " existing-suite-name)))))
                    nil))))


(def find-nested-suite-that-exists-and-next-one (full-suite-name)
     "Take FULL-SUITE-NAME, and parse it into its component suite names, if there are any nested ones.
Then, for each sequence of component suite names, see if there is a suite with that name.
So, for full-suite-name of math.adding.whatever, check if there's a suite named math, then if there's one
named math.adding, then one named math.adding.whatever.

Return a list where the first element is the longest suite name we checked this way that exists,
and the second element is the symbol that isn't a nested suite under the first element. Either element of the list can be nil. A possible return value would be '(math.adding whatever)."
     (let helper (afn (existing-suite-name nested-names)
                      (if (no nested-names)
                          (list existing-suite-name nil)
                        (let next-name (make-full-name existing-suite-name (car nested-names))
                             (if *unit-tests*.next-name
                                 (self next-name (cdr nested-names))
                               (list existing-suite-name (sym (car nested-names)))))))
          (helper nil (tokens (string full-suite-name) #\.))))

;;if user doesn't pass a test name at all, notify about that (possibly with "did you want to run-suite?")
;;rename find-nested-suite-that-exists-and-next-one to something shorter and more obvious
;;in make-test-fn, we inst 'testresults _and_ 'test-results. This is worrisome, but might be fixed in a later version.
;;should we return something other than nil?
;;proper error checking? What does this mean?
;;throw results into results obj
;;store last-run again.
;;rename run-last-thing to support running a single test. Am I up to date?
;;make-full-name

(def make-full-name args
     (sym (string (intersperse #\.
                               (keep idfn ;;for when called with nil, as in make-and-save-suite of top-level suites
                                     args)))))

;;maybe name this "butlast name"
(def get-suite-name (test-full-name)
     (let string-name (string test-full-name)
          (sym (cut string-name 0 (last (positions #\. string-name))))))

(def get-test-name (test-full-name)
     (let string-name (string test-full-name)
          (when (pos #\. string-name)
            (sym (cut string-name (+ 1
                                     (last (positions #\. string-name))))))))

(def run-all-suites ()
     (run-suite-list (keep is-valid-name
                           (keys *unit-tests*))))

(= *last-suites-run* nil)

(def rerun-last-suites-run ()
     (run-suite-list *last-suites-run*))

(def run-these-suites (suite-names)
     (each name suite-names
           (aif (*unit-tests* name)
                (run-one-suite it)
                (prn "\nno suite found: " name " isn't a test suite."))))

;; Summarize a given test run. That is, print out information about the overall
;; status of a set of suites.
(mac summarize-run (suite-names)
     (w/uniq name
             `(with (tests 0
                     passes 0)
                    (each ,name ,suite-names
                          (let results (*unit-test-results* ,name)
                               (when results
                                   (++ tests (total-tests results))
                                   (++ passes (count-passes results)))))
                    (if (is tests 0)
                        (prn "We didn't find any tests. Odd...")
                      (is passes tests)
                      (if (is tests 1)
                          (prn "Yay! The single test passed!")
                        (prn "Yay! All " tests " tests passed!"))
                      (prn "\nOh dear, " (- tests passes) " of " tests " failed."))
                    (list passes tests))))

(def run-suite-list (suite-names)
     (= *last-suites-run* suite-names)
     (run-these-suites suite-names)
     (summarize-run suite-names))

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

(def is-valid-name (name)
     (no (find #\.
               (string name))))

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
                (= cur-results.name
                   (cur-test!test-fn)))))

(def run-child-suites (cur-suite)
     (let cur-results ((*unit-test-results* cur-suite!full-suite-name)
                       'nested-suite-results)
          (each (child-suite-name child-suite) cur-suite!nested-suites
                (= cur-results.child-suite-name
                   (run-one-suite child-suite)))))

;;zck rename to summarize-suite-run
(def summarize-suite (suite-name)
     (with (tests 0
            passed 0)
           (each (test-name test-result) *unit-test-results*.suite-name!test-results
                 (++ tests)
                 (when (is test-result!status 'pass)
                   (++ passed)))
           (if (is tests 0)
               (prn "There are no tests directly in suite " suite-name ".")
               (is tests passed)
               (prn "In suite " suite-name ", all " tests " tests passed!")
             (do (each (test-name test-result) *unit-test-results*.suite-name!test-results
                       (pretty-results test-result))
                 (prn "In suite " suite-name ", " passed " of " tests " tests passed.")))))

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
                            (string (to-readable-string ',actual)
                                    " should be "
                                    (to-readable-string ,exp)
                                    " but instead was "
                                    (to-readable-string ,act)
                                    (awhen ,fail-message
                                           (string ". " it)))))))

(def to-readable-string (val)
     (if (isa val
              'string)
         (string #\' val #\') ;;use single quotes, because (err "a \"string\" here") looks weird
       (acons val)
       (list-to-readable-string val)
       (isa val
            'table)
       (table-to-readable-string val)
       (tostring (disp val))))

(def list-to-readable-string (val)
     (string #\(
             (list-innards-to-readable-string val)
             #\)))

(def list-innards-to-readable-string (val)
     (when val
       (string
        (to-readable-string (car val))
        (when (cdr val)
          (if (isa (cdr val)
                   'cons)
              (string #\space
                      (list-innards-to-readable-string (cdr val)))
            (string " . "
                    (to-readable-string (cdr val))))))))

(def table-to-readable-string (tbl)
     (tostring (pr "#hash(")
               (each (key val) tbl
                     (pr (to-readable-string (cons key val))))
               (pr ")")))



(mac assert-same (expected actual (o fail-message))
     `(assert-two-vals same ,expected ,actual ,fail-message))

(mac assert-t (actual (o fail-message))
     `(assert-two-vals (fn (ex act) act) t ,actual ,fail-message))
;; We can't call (assert-two-vals is t ,actual) because we want to accept _any_ non-nil value, not just 't

(mac assert-nil (actual (o fail-message))
     `(assert-two-vals is nil ,actual ,fail-message))

(def same (thing1 thing2)
     (if (and (isa thing1
                   'table)
              (isa thing2
                   'table))
         (hash-same thing1 thing2)
       (iso thing1 thing2)))

(def hash-same (hash1 hash2)
     (and (is (len hash1)
              (len hash2)) ;;only need to check the length here; if the keys differ, we'll find it below
          (all idfn
               (map [same hash1._
                          hash2._]
                    (keys hash1)))))

(mac assert-error (actual (o expected-error))
     `(unless (on-err (fn (ex) (if ',expected-error
                                   (do (assert-same ,expected-error
                                                    (details ex))
                                       t)
                                 t))
                      (fn () ,actual
                             nil))
        (err "Expected an error to be thrown")))

(def list-suites ()
     "Prints out all suites that can be run."
     (prn "Here are all the suites that can be run.\nEach nested suite is indented under its parent.\n")
     (let helper (afn (cur-suite nesting-level)
                      (prn (newstring nesting-level #\tab)
                           cur-suite!suite-name)
                      (each (child-name child-suite) cur-suite!nested-suites
                            (self child-suite
                                  (+ 1 nesting-level))))
          (each top-level-suite
                (keep [is-valid-name _!full-suite-name]
                      (vals *unit-tests*))
                (helper top-level-suite 0))))
