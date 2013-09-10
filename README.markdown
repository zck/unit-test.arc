# unit-test.arc

A unit test library for the [Arc](http://www.arclanguage.org/) programming language. It lets test suites be written and run simply.

## Quickstart

Yeah, everyone wants examples first, so here they are:

### Defining a suite

To declare a suite, give it a name, then a declare a bunch of tests. To declare a test, give it a name, then the code to run it. Use asserts (see below) when you want to throw if the two things aren't equal to each other.

    (suite math
           this-will-pass (assert-same 4 (+ 2 2))
           this-will-fail (assert-same 3 (+ 2 2)))


### Running a suite

    arc> (run-suite math)

    Running suite math
    math.this-will-pass passed!
    math.this-will-fail failed: (+ 2 2) should be 3 but instead was 4
    In math, 1 of 2 passed.

    Oh dear, 1 of 2 failed.
    nil

You can run multiple suites in `run-suite`, or call `run-suites`. They do the same thing.

## Asserts

There are four asserts:

* `assert-t` -- Arguments: `(actual (o fail-message))`. Throws when `actual` is nil. Accepts _any_ other value, whether `t`, or any other data type.

* `assert-nil` -- Arguments: `(actual (o fail-message))`. Throws when `actual` is *not* nil.

* `assert-error` -- Arguments: `(actual (o expected-error))`. Throws when `actual` does *not* error. If `expected-error` is given, also asserts that the error details is the same as `expected-error`.

* `assert-same` -- Arguments: `(expected actual (o fail-message))`. Throws if the `actual` value is not `expected`. `fail-message` is optional, and is used when you want to give more information about a failure.

Note that `assert-same` requires the expected value *before* the test-value. This is needed for pretty, pretty messages when the assert fails:

    arc> (assert-same 4 (- 2 2))
    Error: "(- 2 2) should be 4 but instead was 0"

### Custom error messages

You can also add custom error messages to your asserts. They get appended to the end of the aforementioned pretty, pretty error message.

    arc> (assert-same 42 27 "Those aren't equal?!")
    Error: "27 should be 42 but instead was 27. Those aren't equal?!"

## Nested suites

Suites can be nested, for the sake of organization, and to make them easier to run.

### Defining nested suites

Put a nested suite anywhere inside its parent suite. You can intermingle tests and suites, and it'll deal with it just fine:

    (suite math
           numbers-are-equal (assert-same 2 2)
           (suite adding
                  good (assert-same 4 (+ 2 2))
                  bad (assert-same 3 (+ 2 2)))
           this-test-will-fail (assert-same 3 4)
           (suite subtracting
                  good (assert-same 0 (- 2 2))
                  bad (assert-same 0 (- 2 42))))

### Running nested suites

If you run a suite, it also runs all nested suites inside it.


    arc> (run-suite math)

    Running suite math
    math.numbers-are-equal passed!
    math.this-test-will-fail failed: 4 should be 3 but instead was 4
    In math, 1 of 2 passed.

    Running suite math.adding
    math.adding.good passed!
    math.adding.bad failed: (+ 2 2) should be 3 but instead was 4
    In math.adding, 1 of 2 passed.

    Running suite math.subtracting
    math.subtracting.good passed!
    math.subtracting.bad failed: (- 2 42) should be 0 but instead was -40
    In math.subtracting, 1 of 2 passed.

    Oh dear, 3 of 6 failed.
    nil

If you want to run only one suite that's nested inside another one, that's possible. Just call `run-suite` with the full name of the suite you want to run. The full name is simply the names of all the parents of the suite concatenated together, with a period between them, then the suite's name:

    arc> (run-suite math.adding)

    Running suite math.adding
    math.adding.good passed!
    math.adding.bad failed: (+ 2 2) should be 3 but instead was 4
    In math.adding, 1 of 2 passed.

    Oh dear, 1 of 2 failed.
    nil



## Setup

If you need to set up some values to share across tests, use `suite-w/setup`. The method signature is `(suite-w/setup suite-name setup . children)`. Just like a `with` block, insert a list containing `var val` pairs. For example:

    (suite-w/setup math (x 6 y 2)
                   adding-works (assert-same 8
                                             (+ x y))
                   multiplying-works (assert-same 12
                                                  (* x y)))

    arc> (run-suite math)

    Running suite math
    math.multiplying-works passed!
    math.adding-works passed!
    In math, 2 of 2 passed.

    Yay! All 2 tests pass! Get yourself a cookie.
    nil

Under the hood, `suite-w/setup` uses `withs`, so variables can depend on earlier variables.

    (suite-w/setup math (x 3
                         y (+ x 2))
                   lets-multiply (assert-same 15
                                              (* x y)))

    arc> (run-suite math)

    Running suite math
    math.lets-multiply passed!
    In math, 1 of 1 passed.

    Yay! All 1 tests pass! Get yourself a cookie.
    nil

## Testing macros

Macroexpansion time can mess up unit tests. If a macro is defined and tests created for it, any redefinition of the macro won't effect the already-existing tests:

    arc> (mac should-be-4 () 3) ;; a bad definition!
    #(tagged mac #<procedure: should-be-4>)
    arc> (should-be-4)
    3
    arc> (suite should-be-4 is-it-4? (assert-same 4 (should-be-4)))
    #hash((suite-name . should-be-4) (full-suite-name . should-be-4) (tests . #hash((is-it-4? . #hash((suite-name . should-be-4) (test-fn . #<procedure: gs18727>) (test-name . is-it-4?))))) (nested-suites . #hash()))
    arc> (run-suite should-be-4)

    Running suite should-be-4
    should-be-4.is-it-4? failed: (should-be-4) should be 4 but instead was 3
    In suite should-be-4, 0 of 1 tests passed.

    Oh dear, 1 of 1 failed.
    nil

Now, let's redefine the macro, and re-run the test.

    arc> (mac should-be-4 () 4) ;; fix it.
    *** redefining should-be-4
    #(tagged mac #<procedure: should-be-4>)
    arc> (should-be-4)
    4
    arc> (run-suite should-be-4)

    Running suite should-be-4
    should-be-4.is-it-4? failed: (should-be-4) should be 4 but instead was 3
    In suite should-be-4, 0 of 1 tests passed.

    Oh dear, 1 of 1 failed.
    nil
    arc>

We'd have to redefine the *test* for it to pick up the change to the macro. This is unfortunate, but is the best way to deal with unit testing macros. Depending on the macro, you could test what it macroexpands into:

    arc> (mac should-be-4 () 3) ;; a bad definition!
    *** redefining should-be-4
    #(tagged mac #<procedure: should-be-4>)
    arc> (suite should-be-4 is-it-4? (assert-same 4 (macex '(should-be-4))))
    #hash((suite-name . should-be-4) (full-suite-name . should-be-4) (tests . #hash((is-it-4? . #hash((suite-name . should-be-4) (test-fn . #<procedure: gs18771>) (test-name . is-it-4?))))) (nested-suites . #hash()))
    arc> (run-suite should-be-4)

    Running suite should-be-4
    should-be-4.is-it-4? failed: (macex (quote (should-be-4))) should be 4 but instead was 3
    In suite should-be-4, 0 of 1 tests passed.

    Oh dear, 1 of 1 failed.
    nil
    arc> (mac should-be-4 () 4) ;; fix it.
    *** redefining should-be-4
    #(tagged mac #<procedure: should-be-4>)
    arc> (run-suite should-be-4)

    Running suite should-be-4
    In suite should-be-4, all 1 tests passed!

    Yay! All 1 tests pass! Get yourself a cookie.
    nil

This, however, is pretty ugly, and will be difficult if the macro expands into a large amount of code.