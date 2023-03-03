use extendr_api::prelude::*;

#[extendr]
pub fn test_method_1() -> i32 { 1i32 }

extendr_module! {
    mod test_module;
    fn test_method_1;
}