test_that("Multiple rust functions with the same name", {

    rust_src_1 <- "
    #[extendr]
    fn rust_fn_1() -> i32 { 1i32 }

    #[extendr]
    fn rust_fn_2() -> i32 { 2i32 }

    extendr_module! {
        mod rextendr;
        fn rust_fn_1;
        fn rust_fn_2;
    }
    "

    rust_src_2 <- "
    #[extendr]
    fn rust_fn_2() -> i32 { 20i32 }

    #[extendr]
    fn rust_fn_3() -> i32 { 30i32 }

    extendr_module! {
        mod rextendr;
        fn rust_fn_2;
        fn rust_fn_3;
    }
    "

    rust_source(code = rust_src_1, quiet = FALSE)

    # At this point:
    # fn1 -> 1
    # fn2 -> 2
    # fn3 -> (not exported)

    expect_equal(rust_fn_1(), 1L)
    expect_equal(rust_fn_2(), 2L)

    rust_source(code = rust_src_2, quiet = FALSE)

    # At this point:
    # fn1 -> 1 (unchanged)
    # fn2 -> 20 (changed)
    # fn3 -> 30 (new function)

    expect_equal(rust_fn_1(), 1L)
    expect_equal(rust_fn_2(), 20L)
    expect_equal(rust_fn_3(), 30L)


})
