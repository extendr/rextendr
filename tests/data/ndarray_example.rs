use extendr_api::prelude::*;
use ndarray::ArrayView2;

#[extendr]
fn matrix_sum(input: ArrayView2<Rfloat>) -> Rfloat {
    input.iter().sum()
}

extendr_module! {
    mod rextendr;
    fn matrix_sum;
}
