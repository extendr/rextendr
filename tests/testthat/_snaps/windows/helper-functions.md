# `ui_throw()` called by `rust_function()` captures Rust compilation errors

    Rust code could not be compiled successfully. Aborting.
    x error[E0412]: cannot find type `i33` in this scope
     --> src\lib.rs:3:19
      |
    3 | fn failed_fn(_x : i33, _y : i34, _z : i35) -> f100 { false }
      |                   ^^^ help: a builtin type with a similar name exists: `i32`
    x error[E0412]: cannot find type `i34` in this scope
     --> src\lib.rs:3:29
      |
    3 | fn failed_fn(_x : i33, _y : i34, _z : i35) -> f100 { false }
      |                             ^^^ help: a builtin type with a similar name exists: `i32`
    x error[E0412]: cannot find type `i35` in this scope
     --> src\lib.rs:3:39
      |
    3 | fn failed_fn(_x : i33, _y : i34, _z : i35) -> f100 { false }
      |                                       ^^^ help: a builtin type with a similar name exists: `i32`
    x error[E0412]: cannot find type `f100` in this scope
     --> src\lib.rs:3:47
      |
    3 | fn failed_fn(_x : i33, _y : i34, _z : i35) -> f100 { false }
      |                                               ^^^^ not found in this scope
    x error: aborting due to 4 previous errors

