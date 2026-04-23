import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge

CLK_NS = 100
BIT_CYCLES = 100


async def reset_dut(dut):
    dut.i_rst.value = 1
    dut.i_valid.value = 0
    dut.i_data.value = 0
    await RisingEdge(dut.i_clk)
    await RisingEdge(dut.i_clk)
    dut.i_rst.value = 0
    await RisingEdge(dut.i_clk)


async def tx_byte(dut, value: int):
    for _ in range(5000):
        if int(dut.o_busy.value) == 0:
            break
        await RisingEdge(dut.i_clk)
    else:
        raise AssertionError("TX ready timeout")

    dut.i_data.value = value
    dut.i_valid.value = 1
    await RisingEdge(dut.i_clk)
    dut.i_valid.value = 0


async def sample_none_frame(dut):
    # Wait for start bit.
    while int(dut.o_tx.value) == 1:
        await RisingEdge(dut.i_clk)

    # Move to the center of each data bit.
    for _ in range(BIT_CYCLES + BIT_CYCLES // 2):
        await RisingEdge(dut.i_clk)

    bits = []
    for _ in range(8):
        bits.append(int(dut.o_tx.value))
        for _ in range(BIT_CYCLES):
            await RisingEdge(dut.i_clk)

    stop = int(dut.o_tx.value)
    return bits, stop


@cocotb.test()
async def test_tx_frame_format(dut):
    cocotb.start_soon(Clock(dut.i_clk, CLK_NS, units="ns").start())
    await reset_dut(dut)

    payloads = [0x00, 0xFF, 0xA5, 0x3C, 0x81, 0x5A]

    for payload in payloads:
        await tx_byte(dut, payload)
        bits, stop = await sample_none_frame(dut)
        expected_bits = [(payload >> bit) & 1 for bit in range(8)]

        assert bits == expected_bits, (
            f"TX data mismatch payload=0x{payload:02X} expected={expected_bits} observed={bits}"
        )
        assert stop == 1, f"TX stop bit mismatch payload=0x{payload:02X}"


@cocotb.test()
async def test_tx_back_to_back_stream(dut):
    cocotb.start_soon(Clock(dut.i_clk, CLK_NS, units="ns").start())
    await reset_dut(dut)

    stream = [i ^ 0x5A for i in range(32)]
    for payload in stream:
        await tx_byte(dut, payload)
        bits, stop = await sample_none_frame(dut)
        expected_bits = [(payload >> bit) & 1 for bit in range(8)]
        assert bits == expected_bits
        assert stop == 1
