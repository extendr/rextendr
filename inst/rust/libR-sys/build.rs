use std::{io, io::Error, io::ErrorKind, process::exit, process::Command};

struct InstallationPaths {
    r_home: String,
    library: String,
}

fn probe_r_paths() -> io::Result<InstallationPaths> {
    let rout = Command::new("R")
        .args(&[
            "-s",
            "-e",
            if cfg!(target_os = "windows") {
                r#"cat(R.home(), R.home('bin'), sep = '\n')"#
            } else {
                r#"cat(R.home(), R.home('lib'), sep = '\n')"#
            }
        ])
        .output()?;

    let rout = String::from_utf8_lossy(&rout.stdout);
    let mut lines = rout.lines();

    let r_home = match lines.next() {
        Some(line) => line.to_string(),
        _ => return Err(Error::new(ErrorKind::Other, "Cannot find R home")),
    };

    let library = match lines.next() {
        Some(line) => line.to_string(),
        _ => return Err(Error::new(ErrorKind::Other, "Cannot find R library")),
    };

    Ok(InstallationPaths {
        r_home,
        library,
    })
}

fn main() {
    let details = probe_r_paths();

    let details = match details {
        Ok(result) => result,
        Err(error) => {
            println!("Problem locating local R instal: {:?}", error);
            exit(1);
        }
    };

    println!("cargo:rustc-env=R_HOME={}", &details.r_home);
    println!("cargo:r_home={}", &details.r_home); // Becomes DEP_R_R_HOME for clients
    // make sure cargo links properly against library
    println!("cargo:rustc-link-search={}", &details.library);
    println!("cargo:rustc-link-lib=dylib=R");

    println!("cargo:rerun-if-changed=build.rs");
    println!("cargo:rerun-if-changed=wrapper.h");
}
