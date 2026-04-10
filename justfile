default:
  just --list

check: 
  R --quiet -e "devtools::check()"

test: 
  R --quiet -e "devtools::test()"

update-snaps:
  R --quiet -e "testthat::snapshot_accept()"

lint: 
  jarl check R/

fmt:
  air format R/

doc:
  R --quiet -e "devtools::document()"