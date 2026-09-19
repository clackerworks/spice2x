#!/bin/sh
# Builds and runs the spice_memmgr.f and engine/*.f unit tests.
# Usage: tests/run_tests.sh [path-to-repo-root]
set -e

ROOT="${1:-$(cd "$(dirname "$0")/.." && pwd)}"
cd "$ROOT"

FC=${FC:-gfortran}
CC=${CC:-gcc}
FFLAGS="-g -O0 -finteger-4-integer-8 -std=legacy -Wno-argument-mismatch"
CFLAGS="-g -O0 -Wno-implicit-int -Wno-implicit-function-declaration -Wno-return-type -Wno-pointer-to-int-cast -std=gnu89"

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

ENGINE_SRCS="engine/matrix.f engine/dcop.f engine/devices.f engine/mosfet.f
    engine/poly.f engine/acanal.f engine/disto.f"

echo "== building spice_memmgr.o, engine/*.o, spice_ui.o and unix.o =="
"$FC" -c $FFLAGS spice_memmgr.f -o "$WORK/spice_memmgr.o"
ENGINE_OBJS=""
for SRC in $ENGINE_SRCS; do
    OBJ="$WORK/$(basename "$SRC" .f).o"
    "$FC" -c $FFLAGS "$SRC" -o "$OBJ"
    ENGINE_OBJS="$ENGINE_OBJS $OBJ"
done
"$FC" -c $FFLAGS spice_ui.f -o "$WORK/spice_ui.o"
"$CC" -c $CFLAGS unix.c -o "$WORK/unix.o"

STATUS=0

echo
echo "== memmgr test suite =="
"$FC" -c $FFLAGS tests/test_memmgr.f -o "$WORK/test_memmgr.o"
"$FC" "$WORK/test_memmgr.o" "$WORK/spice_memmgr.o" "$WORK/unix.o" -o "$WORK/test_memmgr"
if ! "$WORK/test_memmgr"; then
    echo "== memmgr test suite FAILED =="
    STATUS=1
fi

echo
echo "== engine test suite =="
"$FC" -c $FFLAGS tests/test_engine.f -o "$WORK/test_engine.o"
"$FC" "$WORK/test_engine.o" $ENGINE_OBJS "$WORK/spice_ui.o" \
    "$WORK/spice_memmgr.o" "$WORK/unix.o" -o "$WORK/test_engine"
if ! "$WORK/test_engine"; then
    echo "== engine test suite FAILED =="
    STATUS=1
fi

check_error_case () {
    NAME="$1"
    SRC="$2"
    NEEDLE="$3"
    echo
    echo "== error-path test: $NAME =="
    "$FC" -c $FFLAGS "$SRC" -o "$WORK/$NAME.o"
    "$FC" "$WORK/$NAME.o" "$WORK/spice_memmgr.o" "$WORK/unix.o" -o "$WORK/$NAME"
    OUT=$("$WORK/$NAME" 2>&1 || true)
    if echo "$OUT" | grep -qF "$NEEDLE"; then
        echo "PASS: $NAME (found: $NEEDLE)"
    else
        echo "FAIL: $NAME (expected to find: $NEEDLE)"
        echo "--- actual output ---"
        echo "$OUT"
        STATUS=1
    fi
}

check_error_case err_relmem_overrelease tests/err_relmem_overrelease.f \
    "ATTEMPT TO RELEASE MORE THAN TOTAL TABLE"
check_error_case err_clrmem_badptr tests/err_clrmem_badptr.f \
    "TABLE POINTER INVALID"
check_error_case err_getm4_negsize tests/err_getm4_negsize.f \
    "SIZE PARAMETER NEGATIVE"

echo
if [ $STATUS -eq 0 ]; then
    echo "ALL TESTS PASSED"
else
    echo "SOME TESTS FAILED"
fi
exit $STATUS
