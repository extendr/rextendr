use extendr_api::prelude::*;

#[extendr(use_try_from = true)]
fn matrix_sum(input : ArrayView2<Rfloat>) -> Rfloat {
    input.iter().sum()
}

extendr_module! {
    mod rextendr;
    fn matrix_sum;
}
