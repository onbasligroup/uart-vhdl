from cocotb.triggers import RisingEdge

CLK_NS = 100
BIT_CYCLES = 100


def parity_bit(value: int, mode: str) -> int | None:
    ones = bin(value).count("1") % 2
    mode = mode.lower()
    if mode == "none":
        return None
    if mode == "even":
        return ones
    if mode == "odd":
        return 1 - ones
    raise ValueError(f"Unsupported parity mode: {mode}")


async def wait_cycles(clk, count: int):
    for _ in range(count):
        await RisingEdge(clk)


async def wait_tx_ready(dut, busy_signal: str = "o_busy", timeout_cycles: int = 5000):
    signal = getattr(dut, busy_signal)
    for _ in range(timeout_cycles):
        if int(signal.value) == 0:
            return
        await RisingEdge(dut.i_clk)
    raise AssertionError("TX ready timeout")


async def reset_tx_dut(dut):
    dut.i_rst.value = 1
    dut.i_valid.value = 0
    dut.i_data.value = 0
    await wait_cycles(dut.i_clk, 2)
    dut.i_rst.value = 0
    await wait_cycles(dut.i_clk, 1)


async def reset_rx_dut(dut):
    dut.i_rst.value = 1
    dut.i_rx.value = 1
    await wait_cycles(dut.i_clk, 2)
    dut.i_rst.value = 0
    await wait_cycles(dut.i_clk, 1)


async def reset_loopback_dut(dut):
    dut.i_rst.value = 1
    dut.i_valid.value = 0
    dut.i_data.value = 0
    await wait_cycles(dut.i_clk, 2)
    dut.i_rst.value = 0
    await wait_cycles(dut.i_clk, 1)


async def tx_byte(dut, value: int, busy_signal: str = "o_busy"):
    await wait_tx_ready(dut, busy_signal=busy_signal)
    dut.i_data.value = value
    dut.i_valid.value = 1
    await RisingEdge(dut.i_clk)
    dut.i_valid.value = 0


async def wait_valid_data(
    dut,
    timeout_cycles: int = 3500,
    valid_signal: str = "o_valid",
    data_signal: str = "o_data",
):
    valid = getattr(dut, valid_signal)
    data = getattr(dut, data_signal)
    for _ in range(timeout_cycles):
        await RisingEdge(dut.i_clk)
        if int(valid.value) == 1:
            return int(data.value)
    return None


async def drive_uart_frame(
    dut,
    payload: int,
    parity: str = "none",
    parity_override=None,
    stop_bit: int = 1,
    bit_cycles: int = BIT_CYCLES,
):
    bits = [0] + [(payload >> bit) & 1 for bit in range(8)]
    p = parity_bit(payload, parity)
    if p is not None:
        bits.append(p if parity_override is None else parity_override)
    bits.append(stop_bit)

    for bit in bits:
        dut.i_rx.value = bit
        await wait_cycles(dut.i_clk, bit_cycles)


async def drive_line_level(dut, level: int, cycles: int):
    dut.i_rx.value = level
    await wait_cycles(dut.i_clk, cycles)


async def sample_tx_frame(dut, parity: str = "none", tx_signal: str = "o_tx", bit_cycles: int = BIT_CYCLES):
    tx = getattr(dut, tx_signal)

    for _ in range(5000):
        if int(tx.value) == 0:
            break
        await RisingEdge(dut.i_clk)
    else:
        raise AssertionError("TX start bit timeout")

    await wait_cycles(dut.i_clk, bit_cycles + bit_cycles // 2)

    data_bits = []
    for _ in range(8):
        data_bits.append(int(tx.value))
        await wait_cycles(dut.i_clk, bit_cycles)

    parity_mode = parity.lower()
    parity_value = None
    if parity_mode != "none":
        parity_value = int(tx.value)
        await wait_cycles(dut.i_clk, bit_cycles)

    stop = int(tx.value)
    return data_bits, parity_value, stop
