# unit-test.arc

A unit test library for the [Arc](http://www.arclanguage.org/) programming language. It lets test suites be written and run simply.

## Quickstart

Yeah, everyone wants examples first, so here they are:

### Defining a suite

When declaring a test, give it a name, then the code to run it. Use asserts (see below) when you want to throw if the two things aren't equal to each other.

    (suite math
           good (assert-is 4 (+ 2 2))
           bad (assert-is 3 (+ 2 2)))




### Running a suite

    arc> (run-suites math)

    Running suite math
    math.good passed!
    math.bad failed: (+ 2 2) should be 3 but instead was 4
    In math, 1 of 2 passed.
    nil

n.b.: The proper way to call this is with `run-suites`, not `run-suite`. That's a macro used for internal purposes. I'm going to [fix that](https://bitbucket.org/zck/unit-test.arc/issue/17/make-run-suite-work-if-given-a-suite-name). I know I sometimes use `run-suite` by mistake, so it's not your fault for confusing it.

## Asserts

You can use either `assert-is` or `assert-iso` for right now. They work the same, except on lists: `assert-is` will throw unless the two lists are the exact same, not just with the same elements. If you're comparing lists, always use `assert-iso`. Note: we can't compare hashtables with either of those. It's a [known bug](https://bitbucket.org/zck/unit-test.arc/issue/18/make-assert-iso-work-on-hashtables); check its [bug report](https://bitbucket.org/zck/unit-test.arc/issue/18/make-assert-iso-work-on-hashtables) for updates.

All asserts require the expected value *before* the test-value. This is needed for pretty, pretty messages when the assert fails:

    arc> (assert-is 4 (- 2 2))
    Error: "(- 2 2) should be 4 but instead was 0"

### Custom error messages

You can also add custom error messages to your asserts. They get appended to the end of the error message.

    arc> (assert-is 42 27 "Those aren't equal?!")
    Error: "27 should be 42 but instead was 27. Those aren't equal?!"

## Nested suites

Suites can be nested.

### Defining nested suites

Put a suite anywhere inside a suite. You can intermingle tests and suites, and it'll deal with it just fine:

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
    adding.numbers-are-equal-but-this-test-will-fail failed: 4 should be 3 but instead was 4
    math.numbers-are-equal passed!
    In math, 1 of 2 passed.

    Running suite adding.subtracting
    subtracting.good passed!
    subtracting.bad failed: (- 2 42) should be 0 but instead was -40
    In adding.subtracting, 1 of 2 passed.

    Running suite math.adding
    adding.good passed!
    adding.bad failed: (+ 2 2) should be 3 but instead was 4
    In math.adding, 1 of 2 passed.
    nil