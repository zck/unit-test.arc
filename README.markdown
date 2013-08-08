# unit-test.arc

A unit test library for the [Arc](http://www.arclanguage.org/) programming language. It lets test suites be written and run simply.

## Quickstart

Yeah, everyone wants examples first, so here they are:

### Defining a suite

To declare a suite, give it a name, then a declare a bunch of tests. To declare a test, give it a name, then the code to run it. Use asserts (see below) when you want to throw if the two things aren't equal to each other.

    (suite math
           this-will-pass (assert-is 4 (+ 2 2))
           this-will-fail (assert-is 3 (+ 2 2)))


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

You can use either `assert-is` or `assert-iso` for right now. They work the same, except on lists: `assert-is` will throw unless the two lists are the exact same, not just with the same elements. If you're comparing lists, always use `assert-iso`. Note: we can't compare hashtables with either of those. It's a known bug; check its [bug report](https://bitbucket.org/zck/unit-test.arc/issue/18/make-assert-iso-work-on-hashtables) for updates.

All asserts require the expected value *before* the test-value. This is needed for pretty, pretty messages when the assert fails:

    arc> (assert-is 4 (- 2 2))
    Error: "(- 2 2) should be 4 but instead was 0"

### Custom error messages

You can also add custom error messages to your asserts. They get appended to the end of the aforementioned pretty, pretty error message.

    arc> (assert-is 42 27 "Those aren't equal?!")
    Error: "27 should be 42 but instead was 27. Those aren't equal?!"

## Nested suites

Suites can be nested, for the sake of organization, and to make them easier to run.

### Defining nested suites

Put a nested suite anywhere inside its parent suite. You can intermingle tests and suites, and it'll deal with it just fine:

    (suite math
           numbers-are-equal (assert-is 2 2)
           (suite adding
                  good (assert-is 4 (+ 2 2))
                  bad (assert-is 3 (+ 2 2)))
           numbers-are-equal-but-this-test-will-fail (assert-is 3 4)
           (suite subtracting
                  good (assert-is 0 (- 2 2))
                  bad (assert-is 0 (- 2 42))))

If you run a suite, it also runs all nested suites inside it.

    arc> (run-suites math)

    Running suite math
    math.numbers-are-equal passed!
    adding.numbers-are-equal-but-this-test-will-fail failed: 4 should be 3 but instead was 4
    In math, 1 of 2 passed.

    Running suite math.adding
    adding.good passed!
    adding.bad failed: (+ 2 2) should be 3 but instead was 4
    In math.adding, 1 of 2 passed.

    Running suite adding.subtracting
    subtracting.good passed!
    subtracting.bad failed: (- 2 42) should be 0 but instead was -40
    In adding.subtracting, 1 of 2 passed.

    Oh dear, 3 of 6 failed.
    nil