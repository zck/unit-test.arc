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
  tests nil ;;zck should this start out as an obj?
  nested-suites nil ;; zck should this start out as an obj?
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

(mac ensure-bound (place default)
     `(unless (bound ',place)
       (= ,place ,default)))

(ensure-bound *unit-tests* (obj))

;;full suite name -> suite results template
(ensure-bound *suite-results* (obj))

;;full test name -> test results template
(ensure-bound *test-results* (obj))

;;zck make things use this
(def store-test-result (result)
     (= (*test-results*
         (make-full-name result!suite-name
                         result!test-name))
        result))

;;zck make things use this
(def get-test-result (name)
     *test-results*.name)

;;zck make things use this
(def store-suite-result (result)
     (= (*suite-results* result!suite-name)
        result))

;;zck make things use this
(def get-suite-result (name)
     *suite-results*.name)

(def make-full-name args
     (sym (string (intersperse #\.
                               (keep idfn ;;for when called with nil, as in make-and-save-suite of top-level suites
                                     args)))))

(mac make-and-save-suite (suite-name parent-suite-name setup . children)
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
                              (make-test ,parent-suite-name
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

(mac make-test (suite-name test-name setup . body)
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

(mac test names-list
     `(do-test ',names-list))

(def do-test (names)
     (if (no names)
         (do (run-all-tests)
             (summarize-run-of-all-tests));;what does this do when there are tests?
       (do (run-specific-things names) ;;if some tests aren't found, should we complain about that?
           (summarize-run names))))

;;how do I summarize run?
;;  -> differently for running all tests vs running specified tests?
;;where should "no things found" be printed out?
;;does run-these-things set *last-things-run* ?

(def retest ()
     nil);;zck fill me out

;;zck probably obsolete?
;;this should be either 'test or 'suite
(ensure-bound *last-thing-run* nil)

;; This should be either a list of names, or nil.
;; nil means the last thing run was all tests.
(ensure-bound *last-things-run* nil)

;;in make-test-fn, we inst 'testresults _and_ 'test-results. This is worrisome, but might be fixed in a later version.

;;; functions dealing with symbol manipulation

(def verify-suite-name (full-suite-name)
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
                             (if (get-suite next-name)
                                 (self next-name (cdr nested-names))
                               (list existing-suite-name (sym (car nested-names)))))))
          (helper nil (tokens (string full-suite-name) #\.))))

(def get-suite-and-test-name (test-full-name)
     "Return (suite-name test-name), as a list."
     (withs (string-name (string test-full-name)
             pivot (last (positions #\. string-name)))
            (list (sym (cut string-name 0 pivot))
                  (when pivot (sym (cut string-name (+ 1 pivot)))))))

(def get-suite-name (test-full-name)
     "This takes a test full name, and returns the suite that would hold the test.
      Note that you can pass in a suite name, and get that suite's parent suite."
     (car (get-suite-and-test-name test-full-name)))

(def get-test-name (test-full-name)
     (cadr (get-suite-and-test-name test-full-name)))


;;zck Eventually, we'll have to make this look up the suite recursively, and not assume all suites are stored at the top-level of *unit-tests*.
(def get-suite (name)
     "Get the suite obj referred to by NAME, or nil if it isn't found."
     *unit-tests*.name)

(def get-test (name)
     "Get the test obj referred to by NAME, or nil if it isn't found."
     (let (suite-name test-name (break-apart-name name))
       (aand (get-suite suite-name)
             it!tests.name)))

;;runs all tests. Returns t if any were found, nil if none were.
(def run-all-tests ()
     (when (run-specific-things (get-all-top-level-suite-names))
       (= *last-things-run* nil)
       t))

(def get-all-top-level-suite-names ()
     (keep is-valid-name
           (keys *unit-tests*)))

(def run-specific-things (names)
     "Run the things in names, then if there were any, store that in *last-things-run*.
      Return t if at least one of the names is found, nil otherwise."
     (when (run-these-things names)
       (= *last-things-run* names)
       t))

(def run-these-things-functionally (names (o store-result nil))
     "Each name in NAMES can either be a suite or a test.
      If STORE-RESULT is t, store the result of each function in *test-results* or *suite-results*
      Return t if at least one of the names is found, nil otherwise."

     (let at-least-one-found nil
          (each name names
                (when (run-this-thing name store-result)
                  (= at-least-one-found t)))
          at-least-one-found


          ))

(def run-this-thing (name (o store-result nil))
     "If NAME is a test or a suite, run it and return the template result.
      If NAME is not either, return nil."
     (aif (get-suite name)
          (run-suite-and-children it store-result)
          (get-test name)
          (run-test it store-result)
          nil))

(def run-these-things (names)
     "Each name in names can either be a suite or a test.
      Return t if at least one of the names is found, nil otherwise."
     (let at-least-one-found nil
          (each name names
                (aif (get-suite name)
                     (do (run-one-suite it)
                         (= at-least-one-found t))
                     (let (suite-name test-name) (get-suite-and-test-name name)
                          (aif (aand (get-suite suite-name)
                                     it!tests.test-name)
                               (do (= at-least-one-found t)
                                   (run-one-test it))))))
          at-least-one-found))

;;zck does this work for functions? if names includes a function name, is that result in *suite-results*?

;; Summarize a given test run. That is, print out information about the overall
;; status of a set of suites.
(def summarize-run (names)
     (with (tests 0
            passes 0
            names-not-found nil)
           (each name names
                 (print-suite-run-summary name)
                 (aif (get-suite-result name)
                      (prn "it's a suite!")
                      (get-test-result name)
                      (prn "it's a test!")
                      (prn "it's nonexistant!")
                      )
                 (let results (get-suite-result name)
                      (if results
                          (do (++ tests (total-tests results))
                              (++ passes (count-passes results)))
                        (push name names-not-found))))
           (when names-not-found
             (prn "\nThe following suites were not found:")
             (each name names-not-found
                   (prn name))
             (prn))
           (if (is tests 0)
               (prn "We didn't find any tests. Odd...")
             (is passes tests)
             (if (is tests 1)
                 (prn "Yay! The single test passed!")
               (prn "Yay! All " tests " tests passed!"))
             (prn "Oh dear, " (- tests passes) " of " tests " failed."))
           (list passes tests)))

(def summarize-run-of-all-tests ()
     (summarize-run (get-all-top-level-suite-names)))


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

;;zck after loading the math suite from README, and running (test), do I get math.subtracting, math.adding, and math in *suite-results*? Shouldn't it just be math?
(def run-one-suite (cur-suite)
     (= (*suite-results* cur-suite!full-suite-name)
        (inst 'suite-results 'suite-name cur-suite!full-suite-name))

     ;;should run-tests return the template? Probably. And then it should recurse.
     (run-tests cur-suite)
     ;; (prn "\nRunning suite " cur-suite!full-suite-name)
     ;; (print-suite-run-summary cur-suite!full-suite-name)
     (run-child-suites cur-suite)
     (get-suite-result cur-suite!full-suite-name))


;;zck this should obsolete run-one-suite
(def run-suite-and-children (cur-suite (o store-result nil))
     (let results (inst 'suite-results 'suite-name cur-suite!full-suite-name)
          ;;run these tests, store
          (= results!test-results (run-this-suite cur-suite))

          ;;run children
          (each (nested-name nested-suite) cur-suite!nested-suites
                (= results!nested-suite-results.nested-name
                   (run-suite-and-children nested-suite)))

          results))

;;zck this should obsolete run-tests
(def run-this-suite (cur-suite)
     (let test-results (obj)
          (each (test-name test-template) cur-suite!tests
                (= test-results.test-name
                   (test-template!test-fn)))))



;;zck fill me out
(def run-one-test (cur-test)
     (prn "\nRunning test " cur-test!suite-name "." cur-test!test-name)
     ;;run test
     ;;store in *suite-results* as name
     (= (*test-results* (make-full-name cur-test!suite-name cur-test!test-name))
        (cur-test!test-fn)))


;;zck obsoletes run-one-test?
(def run-test (cur-test (o store-result nil))
     (let result (cur-test!test-fn)
          (when store-result
            (store-test-result result))
          result))

(def run-suite-or-test (name)
     (aif (get-suite name)
          (run-suite-and-children it)
          (let (suite-name test-name (get-suite-and-test-name name)))))

;; Runs all the tests inside cur-suite. Does not recurse.
(def run-tests (cur-suite)
     (let cur-results ((get-suite-result cur-suite!full-suite-name) 'test-results) ;; zck does this modify the existing thing inside *suite-results*? Where does it get reset?
          (each (name cur-test) cur-suite!tests
                (= cur-results.name
                   (cur-test!test-fn)))))

(def run-child-suites (cur-suite)
     ;;should this put it into *suite-results*?
     (prn "getting results for " cur-suite!full-suite-name)
     (let cur-results ((get-suite-result cur-suite!full-suite-name)
                       'nested-suite-results)
          (each (child-suite-name child-suite) cur-suite!nested-suites
                (= cur-results.child-suite-name
                   (run-one-suite child-suite)))))

;;why is this just for suites? It doesn't work for tests.
(def print-suite-run-summary-no-recurse (suite-name)
     "Prints out summary information for the suite, but not any child suites."
     (prn "\nRunning suite " suite-name)
     (with (tests 0
            passed 0)
           (each (test-name test-result) (get-suite-result suite-name!test-results)
                 (++ tests)
                 (when (is test-result!status 'pass)
                   (++ passed)))
           (if (is tests 0)
               (prn "There are no tests directly in suite " suite-name ".")
             (is tests passed)
             (prn "In suite " suite-name ", all " tests " tests passed!")
             (do (each (test-name test-result) (get-suite-result suite-name!test-results)  ;;zck this assumes it's a suite, not a test
                       (pretty-results test-result))
                 (prn "In suite " suite-name ", " passed " of " tests " tests passed.")))))

;; (def print-suite-run-summary (suite-name)
;;      (prn "Summarizing suite " suite-name)
;;      (each (nested-name nested-results) *suite-results*.suite-name!nested-suite-results
;;            (prn "A nested suite! " nested-name)
;;            (print-suite-run-summary nested-name))
;;      nil)

(def print-suite-run-summary (suite-name)
     (print-suite-run-summary-helper (get-suite-result suite-name))
     nil) ;;zck what should return value be?

(def print-suite-run-summary-helper (suite-results-template)
     (when suite-results-template
       (with (tests 0
              passed 0)
               (each (test-name test-result) suite-results-template!test-results
                     (++ tests)
                     (when (is test-result!status 'pass)
                       (++ passed)))
               (prn)
               (if (is tests 0)
                   (prn "There are no tests directly in suite " suite-results-template!suite-name ".")
                 (is tests passed)
                 (prn "In suite " suite-results-template!suite-name ", all " tests " tests passed!") ;;zck pluralize properly
                 (do (prn "Suite " suite-results-template!suite-name ":")
                     (each (test-name test-result) suite-results-template!test-results
                           (pretty-results test-result))
                   (prn "In suite " suite-results-template!suite-name ", " passed " of " tests " tests passed."))))
       (each (nested-name nested-results) suite-results-template!nested-suite-results
             (print-suite-run-summary-helper nested-results))))

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
