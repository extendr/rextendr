use extendr_api::prelude::*;

#[extendr]
pub fn test_method_2() -> i32 { 2i32 }

extendr_module! {
    mod test_module;
    fn test_method_2;
}