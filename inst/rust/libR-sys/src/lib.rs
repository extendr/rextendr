//! A low-level libR binding library which is kept deliberately
//! minimal.
//!
//! In particular, it has no external dependencies other that libR
//! installed on the target.
//!
//! ## Synopsis
//!
//! The `libR-sys` crate is a low level bindgen wrapper for the R
//! programming language. The intention is to allow one or more extension
//! mechanisms to be implemented for rust.
//!
//! Effort to make the extension libraries platform-independent can be
//! concentrated here.
//!
//! # Examples
//!
//! ```no_run
//! use libR_sys::{Rf_initialize_R, R_CStackLimit, setup_Rmainloop};
//! use std::os::raw;
//!
//! unsafe {
//!   std::env::set_var("R_HOME", "/usr/lib/R");
//!   let arg0 = "R\0".as_ptr() as *mut raw::c_char;
//!   Rf_initialize_R(1, [arg0].as_mut_ptr());
//!   R_CStackLimit = usize::max_value();
//!   setup_Rmainloop();
//! }
//! ```

#![allow(non_upper_case_globals)]
#![allow(non_camel_case_types)]
#![allow(non_snake_case)]
#![allow(improper_ctypes)]

include!("bindings.rs");

#[cfg(test)]
mod tests {
    use super::*;
    use std::os::raw;

    // Generate constant static strings.
    // Much more efficient than CString.
    // Generates asciiz.
    macro_rules! cstr {
        ($s: expr) => {
            concat!($s, "\0").as_ptr() as *const raw::c_char
        };
    }

    // Generate mutable static strings.
    // Much more efficient than CString.
    // Generates asciiz.
    macro_rules! cstr_mut {
        ($s: expr) => {
            concat!($s, "\0").as_ptr() as *mut raw::c_char
        };
    }

    // Thanks to @qinwf and @scottmmjackson for showing the way here.
    fn start_R() {
        unsafe {
            // TODO: This has only been tested on the debian package
            // r-base-dev.
            if cfg!(unix) {
                if std::env::var("R_HOME").is_err() {
                    // env! gets the build-time R_HOME made in build.rs
                    std::env::set_var("R_HOME", env!("R_HOME"));
                }
            }

            // Due to Rf_initEmbeddedR using __libc_stack_end
            // We can't call Rf_initEmbeddedR.
            // Instead we must follow rustr's example and call the parts.

            //let res = unsafe { Rf_initEmbeddedR(1, args.as_mut_ptr()) };
            Rf_initialize_R(1, [cstr_mut!("R")].as_mut_ptr());

            // In case you are curious.
            // Maybe 8MB is a bit small.
            // eprintln!("R_CStackLimit={:016x}", R_CStackLimit);

            if cfg!(not(target_os = "windows")) {
                R_CStackLimit = usize::max_value();
            }

            setup_Rmainloop();
        }
    }

    // Run some R code. Check the result.
    #[test]
    fn test_eval() {
        start_R();
        unsafe {
            // In an ideal world, we would do the following.
            //   let res = R_ParseEvalString(cstr!("1"), R_NilValue);
            // But R_ParseEvalString is only in recent packages.

            let s = Rf_protect(Rf_mkString(cstr!("1")));
            let mut status: ParseStatus = 0;
            let status_ptr = &mut status as *mut ParseStatus;
            let ps = Rf_protect(R_ParseVector(s, -1, status_ptr, R_NilValue));
            let val = Rf_eval(VECTOR_ELT(ps, 0), R_GlobalEnv);
            Rf_PrintValue(val);
            assert_eq!(TYPEOF(val) as u32, REALSXP);
            assert_eq!(*REAL(val), 1.);
            Rf_unprotect(2);
        }
    }
}
