import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge

CLK_NS = 100
BIT_CYCLES = 100


async def reset_dut(dut):
    dut.i_rst.value = 1
    dut.i_rx.value = 1
    await RisingEdge(dut.i_clk)
    await RisingEdge(dut.i_clk)
    dut.i_rst.value = 0
    await RisingEdge(dut.i_clk)


async def drive_uart_byte(dut, value: int):
    bits = [0] + [(value >> bit) & 1 for bit in range(8)] + [1]
    for b in bits:
        dut.i_rx.value = b
        for _ in range(BIT_CYCLES):
            await RisingEdge(dut.i_clk)


async def drive_uart_frame(dut, data_bits, stop_bit=1):
    bits = [0] + list(data_bits) + [stop_bit]
    for b in bits:
        dut.i_rx.value = b
        for _ in range(BIT_CYCLES):
            await RisingEdge(dut.i_clk)


async def wait_valid_data(dut, timeout_cycles: int = 3000):
    for _ in range(timeout_cycles):
        await RisingEdge(dut.i_clk)
        if int(dut.o_valid.value) == 1:
            return int(dut.o_data.value)
    return None


@cocotb.test()
async def test_rx_single_byte(dut):
    cocotb.start_soon(Clock(dut.i_clk, CLK_NS, units="ns").start())
    await reset_dut(dut)

    payload = 0x3C
    await drive_uart_byte(dut, payload)

    got = await wait_valid_data(dut)

    assert got is not None, "RX did not assert valid"
    assert got == payload, f"RX payload mismatch expected=0x{payload:02X}, got=0x{got:02X}"


@cocotb.test()
async def test_rx_multi_byte_stream(dut):
    cocotb.start_soon(Clock(dut.i_clk, CLK_NS, units="ns").start())
    await reset_dut(dut)

    payloads = [0x00, 0xFF, 0x42, 0xA5, 0x7E, 0x11, 0xC3, 0x5A]
    for payload in payloads:
        await drive_uart_byte(dut, payload)
        got = await wait_valid_data(dut)
        assert got == payload, f"Expected 0x{payload:02X}, got {got}"


@cocotb.test()
async def test_rx_rejects_bad_stop_bit(dut):
    cocotb.start_soon(Clock(dut.i_clk, CLK_NS, units="ns").start())
    await reset_dut(dut)

    payload = 0x55
    data_bits = [(payload >> bit) & 1 for bit in range(8)]

    await drive_uart_frame(dut, data_bits, stop_bit=0)

    got = await wait_valid_data(dut, timeout_cycles=2500)
    assert got is None, "RX accepted a frame with invalid stop bit"
