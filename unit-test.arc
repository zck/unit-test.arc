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



(deftem suite
  suite-name 'suite-with-no-name
  tests (obj)
  nested-suites (obj)
  full-suite-name 'suite-with-no-full-name)

(mac suite args
     `(summarize-suite-creation (make-and-save-suite (suite ,@args))))

(mac suite-w/setup args
     `(summarize-suite-creation (make-and-save-suite (suite-w/setup ,@args))))

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

(def store-test-result (result)
     (= (*test-results*
         (make-full-name result!suite-name
                         result!test-name))
        result))

(def get-test-result (name)
     *test-results*.name)

(def store-suite-result (result)
     (= (*suite-results* result!suite-name)
        result))

(def get-suite-result (name)
     *suite-results*.name)

(def make-full-name args
     (sym (string (intersperse #\.
                               (keep idfn ;;for when called with nil, as in make-and-save-suite of top-level suites
                                     args)))))

(mac make-and-save-suite (suite-body)
     `(let this-suite (make-suite nil ,suite-body)
           (= (*unit-tests* this-suite!full-suite-name)
              this-suite)))

(mac make-suite (parent-suite-name full-suite)
     "Makes a suite.

      PARENT-SUITE-NAME is the full name of the parent suite, or nil.
      FULL-SUITE is the full s-exp for the suite; something like (suite my-name (test...) ...). "
     (w/uniq (processed-children cur-suite)
             `(withs (,processed-children (suite-partition ,parent-suite-name
                                                           nil
                                                           ,full-suite)
                      ,cur-suite (car (vals (,processed-children 'suites))))
                    (check-for-shadowing ,cur-suite)
                    ,cur-suite)))


(def check-for-shadowing (cur-suite)
     (let suite-names (memtable (keys cur-suite!nested-suites))
          (each test-name (keys cur-suite!tests)
                (when suite-names.test-name
                  (err (string "In the suite "
                               cur-suite!full-suite-name
                               ", both a nested suite and a test are named "
                               test-name
                               "."))))
          (each (suite-name suite-template) cur-suite!nested-suites
                (check-for-shadowing suite-template))))

(mac handle-suite-body (parent-suite-name suite-name setup body)
     "Take PARENT-SUITE-NAME SUITE-NAME, and SETUP, and parse BODY into a suite.
      BODY should be everything in the suite body that isn't the initial 'suite' or 'suite-w/setup',
      the name of the suite, or its setup. It could be something like ((test basic (assert-same 2 2)))."
         (let full-suite-name (make-full-name parent-suite-name suite-name)
              (if body
                  `(with (first-thing (suite-partition ,full-suite-name
                                                           ,setup
                                                           ,(car body))
                                      the-rest-of-body (handle-suite-body ,parent-suite-name
                                                                          ,suite-name
                                                                          ,setup
                                                                          ,(cdr body)))
                         (each (nested-suite-name nested-suite) first-thing!suites
                               (= the-rest-of-body!nested-suites.nested-suite-name
                                  nested-suite))
                         (each (test-name the-test) first-thing!tests
                               (= the-rest-of-body!tests.test-name
                                  the-test))
                         the-rest-of-body)
                `(if (no (is-valid-name ',suite-name))
                     ;;this test is inside the macroexpansion so we can test it.
                     ;;We know we'll always get to this case, because handle-suite-body recurses.
                     (err (string "Suite names can't have periods in them. "
                                  ',suite-name
                                  " does."))
                   (inst 'suite
                         'suite-name ',suite-name
                         'tests (obj)
                         'nested-suites (obj)
                         'full-suite-name ',full-suite-name)))))

(mac suite-partition (parent-suite-name setup . children)
     "Return an obj with two values: 'tests and 'suites.
      Each of these is an obj of names to templates.
      CHILDREN is a list of things that can be in the body of a suite: other suites or tests.
      An example call is: (suite-partition parent-name nil (suite a (test b t)))."
     (if children
         (w/uniq the-rest
                 (let this-form (car children)
                      (if (caris this-form
                                 'test)
                          ;;children is:
                          ;;((test test-name . test-body) . suite-rest)
                          (if (len< this-form 3)
                              (err (string "Tests must have a name and a body. This doesn't: "
                                           (to-readable-string this-form)))
                            (let test-name (this-form 1)
                                 `(let ,the-rest (suite-partition ,(make-full-name ',parent-suite-name 'what)
                                                                      ,setup
                                                                      ,@(cdr children))
                                       (= ((,the-rest 'tests) ',test-name)
                                          (make-test ,parent-suite-name
                                                     ,test-name
                                                     ,setup
                                                     ,@(cddr this-form)))
                                       ,the-rest)))

                        (caris this-form
                               'suite)
                        ;;this-form is:
                        ;; (suite suite-name . body)
                        ;;children is:
                        ;;((suite suite-name . suite-body) . suite-rest)
                        (if (len< this-form 3)
                            (err (string "Suites must have a name and a body. This doesn't: "
                                         (to-readable-string this-form)))
                          (let suite-name (this-form 1)
                               `(let ,the-rest (suite-partition ,parent-suite-name
                                                                    ,setup
                                                                    ,@(cdr children))
                                     (= ((,the-rest 'suites) ',suite-name)
                                        (handle-suite-body ,parent-suite-name
                                                           ,suite-name
                                                           nil
                                                           ,(cddr this-form)))
                                     ,the-rest)))
                        (caris this-form
                               'suite-w/setup)
                        ;;children is:
                        ;;((suite suite-name setup . suite-body) . suite-rest)
                        (if (len< this-form 4)
                            (err (string "Suites with setup must have a name, a setup, and a body. This doesn't: "
                                         (to-readable-string this-form)))
                          (let suite-name (this-form 1)
                               `(let ,the-rest (suite-partition ,parent-suite-name
                                                                   ,setup
                                                                   ,@(cdr children))
                                     (= ((,the-rest 'suites) ',suite-name)
                                        (handle-suite-body ,parent-suite-name
                                                           ,suite-name
                                                           ,(this-form 2)
                                                           ,(nthcdr 3 this-form)))
                                     ,the-rest)))
                        (err (string "We can't parse this as a suite body: " (to-readable-string this-form))))))
       `(obj tests (obj) suites (obj))))


(deftem test
  test-name 'test-with-no-name
  suite-name 'test-with-no-suite-name
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
          (on-err (fn (ex) (inst 'test-results 'suite-name ',suite-name 'test-name ',test-name 'status 'fail 'details (details ex)))
                  (fn ()
                      (eval '(withs ,setup
                                   (inst 'test-results 'suite-name ',suite-name 'test-name ',test-name 'status 'pass 'return-value (w/stdout (outstring) ,@body))))))))

(deftem test-results
  test-name 'test-results-with-no-test-name
  suite-name 'test-results-with-no-suite-name
  status 'fail
  details "test results with no details"
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
             (summarize-run-of-all-tests))
       (let unique-names (filter-unique-names names)
            (do (run-specific-things unique-names t)
                (summarize-run unique-names)))))

(mac test-and-error-on-failure names
     `(do-test-and-error-on-failure ',names))

(def do-test-and-error-on-failure (names)
     "Run the tests in NAMES, as in do-test.

However, if there are any test failures, throw an error.
This is intended for use in scripts, where the exit code
from racket is needed to tell if all tests passed or not"
     (let (passes total) (do-test names)
          (unless (is passes total)
            (err "Not all tests passed."))))

(def retest ()
     (do-test *last-things-run*))

(def filter-unique-names (names)
     (withs (names-fragments (map get-name-fragments
                                  (sort < (dedup names)))
             helper (afn (names) (if (len< names 2)
                                     names
                                   (with (first-name (names 0)
                                                     second-name (names 1)
                                                     other-names (nthcdr 2 names))
                                         (if (begins first-name second-name)
                                             (self (cons second-name other-names))
                                           (begins second-name first-name)
                                           (self (cons first-name other-names))
                                           (cons first-name
                                                 (self (cdr names)))))))
             unique-names (memtable (map [apply make-full-name _]
                                         (helper names-fragments))))
            (keep idfn
                  (map [when unique-names._
                             (wipe unique-names._)
                             _]
                       names))))


;; This should be either a list of names, or nil.
;; nil means the last thing run was all tests.
(ensure-bound *last-things-run* nil)


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

(def get-name-fragments (name)
     "Take a full suite name NAME, and return the fragments of it as a list of symbols.
      For example, (get-name-fragments 'math.integers.subtracting)
      returns '(math integers subtracting).
      This function will also work for test names"
     (map sym
          (tokens (string name)
                  #\.)))

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
     "This takes a test full name, and returns the test's name."
     (cadr (get-suite-and-test-name test-full-name)))


(def get-suite (name)
     "Get the suite with full name NAME out of *unit-tests*
      This method looks at nested suites; that is, for a NAME of math.adding,
      it gets the 'math suite out of *unit-tests*, then looks for a nested
      suite 'adding inside it, rather than looking for a suite named math.adding
      at the top level of *unit-tests*."
     (withs (fragments (get-name-fragments name)
             helper (afn (cur-suite leftover-fragments)
                         (aif (no leftover-fragments)
                              cur-suite
                              (cur-suite!nested-suites (car leftover-fragments))
                              (self it (cdr leftover-fragments)))))
            (aand fragments
                  (*unit-tests* (car fragments))
                  (helper it (cdr fragments)))))

(def get-test (name)
     "Get the test obj referred to by NAME, or nil if it isn't found."
     (let (suite-name test-name) (get-suite-and-test-name name)
       (aand (get-suite suite-name)
             it!tests.test-name)))

(def run-all-tests ()
     "Run all tests. Return t if any were found, nil if none were."
     (when (run-specific-things (get-all-top-level-suite-names) t)
       (= *last-things-run* nil)
       t))

(def get-all-top-level-suite-names ()
     (keep is-valid-name
           (keys *unit-tests*)))

(def run-specific-things (names (o store-result nil))
     "Run the things in names, then if there were any, store that in *last-things-run*.
      Return t if at least one of the names is found, nil otherwise."
     (when (run-these-things names store-result)
       (= *last-things-run* names)
       t))

(def run-these-things (names (o store-result nil))
     "Each name in NAMES can either be a suite or a test.
      If STORE-RESULT is t, store the result of each function in *test-results* or *suite-results*
      Return t if at least one of the names is found, nil otherwise."

     (let at-least-one-found nil
          (each name names
                (when (run-this-thing name store-result)
                  (= at-least-one-found t)))
          at-least-one-found))

(def run-this-thing (name (o store-result nil))
     "If NAME is a test or a suite, run it and return the template result.
      If NAME is not either, return nil."
     (aif (get-suite name)
          (run-suite-and-children it store-result)
          (get-test name)
          (run-test it store-result)
          nil))

(def summarize-run (names)
     "Summarize a given test run.
      That is, print out information about the overall status
      of a set of suites."
     (with (tests 0
            passes 0
            names-not-found nil)
           (each name names
                 (print-run-summary name)
                 (aif (get-suite-result name)
                      (do (++ tests (total-tests it))
                          (++ passes (count-passes it)))
                      (get-test-result name)
                      (do (++ tests)
                          (when (result-is-pass it)
                            (++ passes)))
                      (push name names-not-found)))
           (prn)
           (when names-not-found
             (prn "The following names were not found:")
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
  suite-name 'suite-results-with-no-suite-name
  test-results (obj) ;;hash of test-name -> test-result
  nested-suite-results (obj)) ;;nested-suite-fullname -> suite-result


(def run-suite-and-children (cur-suite (o store-result nil))
     (let results (inst 'suite-results
                        'suite-name cur-suite!full-suite-name
                        'test-results (run-this-suite cur-suite))

          (each (nested-name nested-suite) cur-suite!nested-suites
                (= results!nested-suite-results.nested-name
                   (run-suite-and-children nested-suite)))

          (when store-result
            (store-suite-result results))

          results))

(def run-this-suite (cur-suite)
     (let test-results (obj)
          (each (test-name test-template) cur-suite!tests
                (= test-results.test-name
                   (test-template!test-fn)))
          test-results))


(def run-test (cur-test (o store-result nil))
     (let result (cur-test!test-fn)
          (when store-result
            (store-test-result result))
          result))

(def print-run-summary (name)
     "This should work on both suite and test names"
     (aif (get-suite-result name)
          (print-suite-run-summary it)
          (get-test-result name)
          (print-test-run-summary it)))

(def print-test-run-summary (test-result)
     (prn)
     (prn "Running test " (make-full-name test-result!suite-name test-result!test-name))
     (if (result-is-pass test-result)
         (prn "It passed!")
       (prn "It failed.")))

(def print-suite-run-summary (suite-results-template)
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
                 (is tests passed 1)
                 (prn "Suite " suite-results-template!suite-name ": the single test passed!")
                 (is tests passed)
                 (prn "Suite " suite-results-template!suite-name ": all " tests " tests passed!")
                 (do (prn "Suite " suite-results-template!suite-name ":")
                     (each (test-name test-result) suite-results-template!test-results
                           (pretty-results test-result))
                   (prn "In suite " suite-results-template!suite-name ", " passed " of " tests " tests passed."))))
       (each (nested-name nested-results) suite-results-template!nested-suite-results
             (print-suite-run-summary nested-results))))

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
     "Return a readable version of VAL."
     ;; It is intended to be readable when printed.
     ;; This matters, for example, when dealing with strings.
     ;; The return value from this function isn't as readable as it is printed:

     ;; arc> (to-readable-string "hi")
     ;; "\"hi\""
     ;; arc> (prn (to-readable-string "hi"))
     ;; "hi"
     ;; "\"hi\""
     (if (isa val
              'string)
         (string #\" val #\")
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
     (let sorted-table (sort < (map to-readable-string (tablist tbl)))
          (tostring (pr "(obj ")
                    (each ele sorted-table
                          (pr ele))
                    (pr ")"))))



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

(mac assert-no-error (actual)
     `(on-err (fn (exception)
                  (err (string "We got an error with details: "
                                 (details exception))
                         ))
              (fn () ,actual)))

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
