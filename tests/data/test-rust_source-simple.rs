use extendr_api::prelude::*;

#[extendr]
pub fn test_method(){}

extendr_module! {
    mod test_module;
    fn test_method;
}