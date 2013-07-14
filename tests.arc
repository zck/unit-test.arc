(suite assert t-doesnt-error (assert t "shouldn't throw")
       nil-errors (when (errsafe (do (assert nil "should throw") t)) (err
                                                                      "asserting nil should throw")))
