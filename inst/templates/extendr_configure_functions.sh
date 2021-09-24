if [ -z "${RSCRIPT}" ]; then
  echo ""
  echo "ERROR: RSCRIPT variable needs to be set before sourcing configure_utils.sh"
  echo ""
  exit 100
fi

# Use these system information to do some extra checks
SYSINFO_MACHINE=`"${RSCRIPT}" -e 'cat(Sys.info()[["machine"]])'`
SYSINFO_OS=`"${RSCRIPT}" -e 'cat(tolower(Sys.info()[["sysname"]]))'`

if [ -z "${SYSINFO_MACHINE}" -o -z "${SYSINFO_OS}" ]; then
  echo ""
  echo 'ERROR: Failed to get Sys.info()'
  echo ""
  exit 100
fi

echo "***"
echo "*** SYSINFO_MACHINE:   ${SYSINFO_MACHINE}"
echo "*** SYSINFO_OS:        ${SYSINFO_OS}"
echo "***"

# "true" if there's 32bit version of R installed
if [ -d "${R_HOME}/bin/i386/" ]; then
  HAS_32BIT_R="true"
fi


# Show error messages and exit
#
# USAGE:
#     show_error MSG EXIT_CODE
#
# ARGS:
#     MSG         Additional error message to show
#     EXIT_CODE   Exit code to exit with
show_error() {
  echo "-------------- ERROR: CONFIGURATION FAILED --------------------"
  echo ""
  echo "$1"
  echo "Please refer to <https://www.rust-lang.org/tools/install> to install Rust."
  echo ""
  echo "---------------------------------------------------------------"
  echo ""

  exit $2
}



# Check if cargo is installed and set up as expected
#
# USAGE:
#     check_cargo
#
# VARIABLES:
#     MIN_RUST_VERSION   If this is set, check if the installed version is newer
#                        than the requirement
#
check_cargo() {
  echo "*** Checking if cargo is installed"

  cargo version >/dev/null 2>&1
  if [ $? -ne 0 ]; then
    show_error "cargo command is not available" 1
  fi

  if [ -n "${MIN_RUST_VERSION}" ]; then
    echo "*** Checking if cargo is newer than the required version"

    # Check if the version is minimum required one. `-V` option of `sort` does
    # version sort, and `-C` is for silently checking if the input is already
    # sorted; so, if RUST_VERSION is smaller than MIN_RUST_VERSION, it fails.
    RUST_VERSION="`cargo --version | cut -d' ' -f2`"
    if ! printf '%s\n' "${MIN_RUST_VERSION}" "${RUST_VERSION}" | sort -C -V; then
      show_error "The installed version of cargo (${RUST_VERSION}) is older than the requirement (${MIN_RUST_VERSION})" 2
    fi
  fi

  # On Windows, there should be installed an specific toolchains
  if [ "${SYSINFO_OS}" = "windows" ]; then

    # Check toolchain ------

    _check_cargo_toolchain stable-msvc

    # Check targets ------

    # If there is 32-bit version of R, check the corresponding target is installed already
    if [ "${HAS_32BIT_R}" = "true" ]; then
      TARGETS="x86_64-pc-windows-gnu i686-pc-windows-gnu"
    else
      TARGETS="x86_64-pc-windows-gnu"
    fi

    for TARGET in ${TARGETS}; do
      _check_cargo_target "${TARGET}"
    done
  fi

  echo "cargo is ok"
  echo ""
}

# Check if the installed cargo has a specific toolchain
#
# (This is intended to be used in check_cargo)
#
# USAGE:
#     _check_cargo_toolchain TOOLCHAIN
#
# ARGS:
#     TOOLCHAIN   Toolchain that must be installed (i.e. stable-msvc on Windows)
_check_cargo_toolchain() {
  EXPECTED_TOOLCHAIN="$1"

  cargo "+${EXPECTED_TOOLCHAIN}" version >/dev/null 2>&1
  if [ $? -ne 0 ]; then
    show_error "${EXPECTED_TOOLCHAIN} toolchain is not installed" 3
  fi
}

# Check if the installed cargo has a specific target
#
# (This is intended to be used in check_cargo)
#
# USAGE:
#     _check_cargo_target TARGET
#
# ARGS:
#     TARGET      Targets that must be installed
_check_cargo_target() {
  EXPECTED_TARGET="$1"

  if ! rustup target list --installed | grep -q "${EXPECTED_TARGET}"; then
    show_error "target ${EXPECTED_TARGET} is not installed" 4
  fi
}
