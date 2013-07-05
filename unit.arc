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

(mac suite (suite-name . tests)
     (ensure-suite-obj)
     `(when ',tests
        (= (*unit-tests* ',suite-name)
           (suite-helper (obj) ,suite-name ,@tests))))

(mac suite-helper (suite-obj suite-name test-name test-body . other-tests)
     `(let real-suite ,suite-obj
           ;; '(test ,suite-name ,test-name ,test-body)))
           (= (*unit-tests* ',suite-name)
              real-suite)
           (= (real-suite ',test-name)
              (test ,suite-name ,test-name ,test-body))

           (prn (no ',other-tests))
           (prn ',other-tests)
           (prn (type ',other-tests))))
           ;; (when ',other-tests
           ;;   (suite-helper real-suite ,suite-name ,@other-tests))))

(mac tm (cur . others)
     `(do (prn ,cur)
             (when ',others
               (prn "there's more!"))))
               ;; (tm ,@others))))





(mac suite (suite-name . tests)
     (ensure-suite-obj)
     (w/uniq (test-name test-body test-map)
             `(let ,test-map (obj)
                   (each (,test-name ,test-body) (pair ',tests)
                         (prn (type ,test-body))
                         (prn (list->str ,test-body))
                         (= (,test-map ,test-name)
                            ``(test ,,suite-name ,test-name ,,test-body)))
                            ;; (test ,suite-name ,test-name (err "what?"))))
                   ;; (quote ( ,suite-name ,test-name ,@test-body))))
                   ;; (quote (test ',suite-name ',test-name ,@test-body))))
                   (= (*unit-tests* ',suite-name) ,test-map))))

(mac suite (suite-name . tests)
     (ensure-suite-obj)
     `(let test-map (obj)
           (each (test-name test-body) (pair ',tests)
                 ;; (prn (type ,test-body))
                 ;; (prn (list->str ,test-body))
                 (= (test-map test-name)
                    (test ,suite-name test-name test-body))) ;; might not be having test-body run!
           (= (*unit-tests* ',suite-name) test-map)))


(mac run-suites suite-names
     `(each name ',suite-names
           (run-suite name)))
;; * ',suite-name) test-map))))

(def ensure-suite-obj ()
     (unless (bound '*unit-tests*)
       (= *unit-tests* (obj))))





;; (mac suite (suite-name . tests)
;;      `(let suite (obj)
;;            (= (suite (car ',tests))
;;               (fn () (cadr ',tests))) ;;something here gets "inverting what looks like a function call"
;;            (= (*unit-tests* ',suite-name)
;;               suite)))

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

(mac recur stufflst
     (if stufflst
         `(do (prn "the first thing is " ,(car stufflst))
              (recur ,@(cdr stufflst)))))



(mac suite (suite-name . tests)
     (ensure-suite-obj)
     `(let suite (obj)
           (each (test-name test-body)
                 (pair ',tests)
                 (prn test-name #\tab test-body))
           suite))
;; arc> (suite a b c)
;; b	c
;; #hash()

(mac suite (suite-name . tests)
     (ensure-suite-obj)
     `(let suite (obj)
           (each (test-name test-body)
                 (pair ',tests)
                 (= (suite test-name) t)) ;;inverting function call
           suite))


(mac suite (suite-name . tests)
     (ensure-suite-obj)
     `(let suite (obj)
           (each (test-name test-body)
                 (pair ',tests)
                 (prn "what?")) ;;fine, but only prints
           suite))

(mac suite (suite-name . tests)
     (ensure-suite-obj)
     `(let suite (obj)
           (each (test-name test-body)
                 (pair ',tests)
                 (prn test-name #\tab test-body)) ;;fine, only prints *quoted* values
           suite))

(mac suite (suite-name . tests)
     (ensure-suite-obj)
     (each (test-name test-body)
           (pair tests)
           `(prn "print me, please!"))) ;;doesn't execute this line, seemingly.


(mac suite (suite-name . tests)
     (ensure-suite-obj)
     `(let suite (obj)
           (each (test-name test-body) ;;undefined identifier
                 (pair ,tests)
                 (prn test-name #\tab test-body))
           suite))

(mac suite (suite-name . tests)
     (ensure-suite-obj)
     `(let suite (obj)
           (each (test-name test-body)
                 (pair ',tests)
                 suite!a);;loops forever
           suite))

(mac suite (suite-name . tests)
     (ensure-suite-obj)
     `(let suite (obj)
           (each (test-name test-body)
                 (pair ',tests)
                 (let var 'a (suite var)));;loops forever
           suite))


           ;;       (= suite.test-name
           ;;          (test ',suite-name test-name test-body)))
           ;; (= (*unit-tests* ',suite-name)
           ;;    suite)))

(mac suite (suite-name . tests) ;;this doesn't actually run the code in the body
     (each (test-name test-body)
           (pair tests)
           `(prn "executing")
           `(prn ',test-name #\tab ',test-body)))

(mac make-tests (suite-name . tests)
     (when tests
       `(cons ',(car tests)
              (make-tests suite-name
                          ,@(cddr tests))))) ;;works!

(mac make-tests (suite-name . tests)
     (when tests
       `(cons (test suite-name
                    ,(car tests)
                    ,(cadr tests))
              (make-tests suite-name
                          ,@(cddr tests))))) ;;works!

(mac suite (suite-name . tests)
     (ensure-suite-obj)
     `(obj suite ',suite-name
           tests (make-tests ,suite-name
                             ,@tests))) ;;works to return hash of suite

(mac suite (suite-name . tests)
     (ensure-suite-obj)
     `(= (*unit-tests* ',suite-name)
         (obj suite ',suite-name
           tests (make-tests ,suite-name
                             ,@tests)))) ;;works to put suite in *unit-tests*





(mac helper (test-name test-body)
     `(do (prn (type ,test-name))
       (prn ',test-name #\tab ',test-body)))
