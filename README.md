# FPGA Field-Oriented Control (FOC) Controller

A **plain-Verilog**, platform-portable Field-Oriented Control (FOC) motor controller. The core FOC math and control are implemented in RTL, with a thin layer of hardware-specific board/sensor shims. This project was implemented on a Zynq-7020 board, but the ARM cores were unused (See Roadmap for potential extensions).

> **Highlights**
> - Plain Verilog (no vendor IP in core RTL) 
> - Full FOC pipeline in hardware: Clarke/Park, PI current loops (**with anti-windup**), inverse Park, **SVPWM**  
> - Trig via **CORDIC** and **quarter-wave LUTs** for efficient sin/cos  
> - Pluggable front-ends for ABZ (Quadrature) encoder & AD7606 ADC
> - On-the-fly parameter tuning via **JTAG/AXI** and **GPIO** (see `Util/PI_Tune.tcl`)

---

## Top-Level Wrapper

`RTL/hardware_top.v` is the **board-level top wrapper** for the project. It instantiates and connects **all** major subsystems, including:
- `foc_top.v` (the core FOC pipeline),
- front-end interfaces (`AD7606_ctrl.v`, `adc_start.v`, `quad.v`),
- PWM outputs to the gate driver / power stage,
- Optional runtime tuning via JTAG/AXI or GPIO, and porting out values for debug visibility through ILA

---

## Core FOC RTL Block

`RTL/foc_top.v` does the **core FOC algorithm** for the controller:

- Data path: ADC samples → **Clarke** → **Park** → **PI (anti-windup)** → **inv Park** → **SVPWM**.  
- Trigonometry via **CORDIC** and/or **quarter-wave LUTs** to compute sin/cos and electrical angle efficiently.  

The **core FOC algorithm** lives under `FOC/` and is entirely **plain Verilog**, free of vendor primitives—making it portable across Xilinx/AMD, Intel/Altera, etc.

---

## Hardware-Specific Modules

- `quad.v` — ABZ **quadrature decoder** for rotor position/velocity.  
- `adc_start.v` — ADC **start/convert** signal generator
- `AD7606_ctrl.v` — **AD7606** parallel ADC interface (BUSY, CONVST, CS, RD, data bus).

Can be replaced with equivalents while keeping their interfaces to `foc_top.v` stable.

---

## Vivado Block Design

The reference system integrates:
- **JTAG/AXI** & **GPIO** blocks used **only** for runtime parameter tuning, allowing tweaking of gains/offsets/limits without re-synthesizing (see `Util/PI_Tune.tcl`).
- **ILA** cores for **debug/visualization** during bring-up, they are not required for normal operation.

![Vivado Block Design](Docs/Vivado%20Block%20Design.png)

---

## Math & DSP Details

### CORDIC for Trigonometry
The design can compute trigonometric functions using **CORDIC**, an iterative shift-add algorithm that avoids multipliers.

- **Why CORDIC?** Excellent resource/performance trade-off on small FPGAs
- CORDIC parameters and algorithms were generated using a tool from [ZipCPU](https://github.com/ZipCPU/cordic), see generator under `Util/Cordic and Sine Table Generators`.
- Used for transforming cartesian coordinates to polar coordinates as a part of the FOC algoritm

### Quarter-Wave LUTs
For sin/cos, the repo also uses **quarter-wave lookup tables** with symmetry (Q1 mirroring & sign changes). This:
- Cuts memory by ~4× vs full-wave LUTs
- Matches fixed-point scaling used in the PI and SVPWM blocks

---

## Control Loops & Anti-Windup

The PI controllers include **anti-windup** to prevent integrator runaway when outputs saturate. The implementation follows common approaches discussed [here](https://www.embeddedrelated.com/showarticle/121.php).

---

## ADC Calibration Techniques

Accurate current feedback is critical. The design takes N ADC samples to measure per-channel DC offset at start-up and are subtracted from the raw input.

---

## Future Improvements

- Optional speed/position loops as pluggable blocks, potentially in ARM cores instead of RTL
- Runtime ADC calibration, as offsets may shift after initial calibration
- Additional ADC/encoder front-ends (SPI ADCs, inline shunts, Hall arrays)  

---


