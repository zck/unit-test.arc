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
    math.this-will-fail failed: (+ 2 2) should be 3 but instead was 4
    math.this-will-pass passed!
    In suite math, 1 of 2 tests passed.

    Oh dear, 1 of 2 failed.
    (1 2)

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
    In suite math, 1 of 2 tests passed.

    Running suite math.adding
    math.adding.bad failed: (+ 2 2) should be 3 but instead was 4
    math.adding.good passed!
    In suite math.adding, 1 of 2 tests passed.

    Running suite math.subtracting
    math.subtracting.bad failed: (- 2 42) should be 0 but instead was -40
    math.subtracting.good passed!
    In suite math.subtracting, 1 of 2 tests passed.

    Oh dear, 3 of 6 failed.
    (3 6)

If you want to run only one suite that's nested inside another one, that's possible. Just call `run-suite` with the full name of the suite you want to run. The full name is simply the names of all the parents of the suite concatenated together, with a period between them, then the suite's name:

    arc> (run-suite math.adding)

    Running suite math.adding
    math.adding.bad failed: (+ 2 2) should be 3 but instead was 4
    math.adding.good passed!
    In suite math.adding, 1 of 2 tests passed.

    Oh dear, 1 of 2 failed.
    (1 2)


## Setup

If you need to set up some values to share across tests, use `suite-w/setup`. The method signature is `(suite-w/setup suite-name setup . children)`. Just like a `with` block, insert a list containing `var val` pairs. For example:

    (suite-w/setup math (x 6 y 2)
                   adding-works (assert-same 8
                                             (+ x y))
                   multiplying-works (assert-same 12
                                                  (* x y)))

    arc> (run-suite math)

    Running suite math
    In suite math, all 2 tests passed!
    Yay! All 2 tests passed!
    (2 2)


Under the hood, `suite-w/setup` uses `withs`, so variables can depend on earlier variables.

    (suite-w/setup math (x 3
                         y (+ x 2))
                   lets-multiply (assert-same 15
                                              (* x y)))

    arc> (run-suite math)

    Running suite math
    In suite math, all 1 tests passed!
    Yay! The single test passed!
    (1 1)


## Testing macros

Macros can be tested just like functions. The macro won't be expanded until the test is run, so the you can change it, re-run the test, and the test will use the up-to-date definition.

## Rerunning the last set of suites ran

You can rerun the last set of suites you ran with `(rerun-last-suites-run)`:

    arc> (rerun-last-suites-run)

    Running suite math
    In suite math, all 1 tests passed!
    Yay! The single test passed!
    (1 1)
