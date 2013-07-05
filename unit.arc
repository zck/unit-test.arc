(mac run-suites suite-names
     `(each name ',suite-names
           (run-suite name)))

(def run-suite (suite-name)
     (ensure-suite-obj)
     (aif *unit-tests*.suite-name
          (each (name test) it
                (prn "running test " name)
                (test))
          (err "no suite found" suite-name " isn't a test suite!")))



(mac test (suite-name test-name . body)
     `(fn ()
          (on-err (fn (ex) (obj suite-name ',suite-name test-name ',test-name status 'fail details (details ex)))
                  (fn ()
                      (obj suite-name ',suite-name test-name ',test-name status 'pass return (do ,@body))))))

(test math
      square
      (assert-is 4 (* 2 2)))


(def ensure-suite-obj ()
     (unless (bound '*unit-tests*)
       (= *unit-tests* (obj))))


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
                                   ',expected
                                   " but instead was "
                                   ,act
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

(mac make-tests (suite-name . tests)
     (when tests
       `(cons (test suite-name
                    ,(car tests)
                    ,(cadr tests))
              (make-tests suite-name
                          ,@(cddr tests))))) ;;works!

(mac suite (suite-name . tests)
     (ensure-suite-obj)
     `(= (*unit-tests* ',suite-name)
         (obj suite ',suite-name
           tests (make-tests ,suite-name
                             ,@tests)))) ;;works to put suite in *unit-tests*
