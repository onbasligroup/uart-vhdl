#!/usr/bin/env python3
"""Run uart-vhdl cocotb regressions with cocotb-tools runner."""

from pathlib import Path
import os
import sys
import sysconfig


ROOT = Path(__file__).resolve().parent.parent
TB = ROOT / "tb"
SRC = ROOT / "src"
BUILD = ROOT / "build" / "cocotb"


TEST_SPECS = [
    {
        "name": "tx",
        "top": "uart_tx_wrap",
        "vhdl": [SRC / "uart_tx.vhd", TB / "uart_tx_wrap.vhd"],
        "module": "test_uart_tx",
    },
    {
        "name": "rx",
        "top": "uart_rx_wrap",
        "vhdl": [SRC / "uart_rx.vhd", TB / "uart_rx_wrap.vhd"],
        "module": "test_uart_rx",
    },
    {
        "name": "loopback",
        "top": "uart_loopback_wrap",
        "vhdl": [SRC / "uart_tx.vhd", SRC / "uart_rx.vhd", TB / "uart_loopback_wrap.vhd"],
        "module": "test_uart_loopback",
    },
]


def main() -> int:
    sys.path.insert(0, str(TB))

    # cocotb's runner needs a resolvable libpython path for embedding.
    if "LIBPYTHON_LOC" not in os.environ:
        libdir = sysconfig.get_config_var("LIBDIR")
        ldlib = sysconfig.get_config_var("LDLIBRARY")
        if libdir and ldlib:
            candidate = Path(libdir) / ldlib
            if candidate.exists():
                os.environ["LIBPYTHON_LOC"] = str(candidate)

    try:
        from cocotb_tools.runner import get_runner
    except ImportError as exc:
        print("ERROR: cocotb-tools runner not available", exc)
        return 1

    BUILD.mkdir(parents=True, exist_ok=True)
    runner = get_runner("ghdl")

    for spec in TEST_SPECS:
        build_dir = BUILD / spec["name"]
        build_dir.mkdir(parents=True, exist_ok=True)

        runner.build(
            sources=[str(p) for p in spec["vhdl"]],
            hdl_toplevel=spec["top"],
            build_dir=str(build_dir),
            always=True,
        )

        runner.test(
            hdl_toplevel=spec["top"],
            test_module=spec["module"],
            build_dir=str(build_dir),
            results_xml=str(build_dir / "results.xml"),
        )

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
