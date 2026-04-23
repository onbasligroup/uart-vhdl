import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge

CLK_NS = 100
BIT_CYCLES = 100


def odd_parity_bit(value: int) -> int:
    return 1 - (bin(value).count("1") % 2)


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


async def sample_odd_frame(dut):
    while int(dut.o_tx.value) == 1:
        await RisingEdge(dut.i_clk)

    for _ in range(BIT_CYCLES + BIT_CYCLES // 2):
        await RisingEdge(dut.i_clk)

    data_bits = []
    for _ in range(8):
        data_bits.append(int(dut.o_tx.value))
        for _ in range(BIT_CYCLES):
            await RisingEdge(dut.i_clk)

    parity = int(dut.o_tx.value)
    for _ in range(BIT_CYCLES):
        await RisingEdge(dut.i_clk)
    stop = int(dut.o_tx.value)
    return data_bits, parity, stop


@cocotb.test()
async def test_tx_odd_parity_frames(dut):
    cocotb.start_soon(Clock(dut.i_clk, CLK_NS, units="ns").start())
    await reset_dut(dut)

    payloads = [0x00, 0x02, 0x07, 0x5A, 0xC3, 0xFF]
    for payload in payloads:
        await tx_byte(dut, payload)
        data_bits, parity, stop = await sample_odd_frame(dut)
        assert data_bits == [(payload >> bit) & 1 for bit in range(8)]
        assert parity == odd_parity_bit(payload), f"Unexpected parity for 0x{payload:02X}"
        assert stop == 1
