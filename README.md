# mmWave Radar Area Scanner & Virtual Loop System (TI IWR6843AOP)

An intelligent, software-defined access control and virtual inductive loop system using the **Texas Instruments IWR6843AOP** Antenna-on-Package $60\text{--}64\text{ GHz}$ mmWave radar sensor. Developed at **Motorline Professional** in partnership with **Texas Instruments**, this project replaces traditional pavement-cut inductive loops with an above-ground radar system capable of real-time 2D spatial tracking, dynamic area calibration, and machine-learning-based Person vs. Vehicle classification.

---

## Table of Contents
- [Overview & Problem Statement](#overview--problem-statement)
- [System Architecture](#system-architecture)
- [Key Features](#key-features)
- [Person vs. Vehicle Classifier](#person-vs-vehicle-classifier)
- [Repository Structure](#repository-structure)
- [Hardware & Software Requirements](#hardware--software-requirements)
- [Installation & Setup](#installation--setup)
- [Usage Workflow](#usage-workflow)
  - [1. Initial Configuration & Setup GUI](#1-initial-configuration--setup-gui)
  - [2. Interactive Area Calibration](#2-interactive-area-calibration)
  - [3. Real-Time Visualizer & Decision Controller](#3-real-time-visualizer--decision-controller)
  - [4. Data Logging & Classifier Retraining Pipeline](#4-data-logging--classifier-retraining-pipeline)
- [Firmware Configuration (`.cfg`)](#firmware-configuration-cfg)
- [License & Acknowledgments](#license--acknowledgments)

---

## Overview & Problem Statement

Traditional vehicle detection systems rely on **magnetic inductive loops** buried under the pavement. This approach introduces significant operational drawbacks:
- Invasive, noisy, and costly asphalt cutting and civil works.
- Inability to install on stone paving, pre-stressed structures, or metallic grates.
- Rigid, fixed detection geometries requiring physical re-excavation for modifications.
- Lack of target classification (inability to distinguish pedestrians from vehicles or track direction of movement).

The **Virtual Loop System** addresses these issues by mounting the TI IWR6843AOP mmWave radar above the ground (on the barrier post or housing). It allows operators to define multiple arbitrary activation (**Trigger**) and protection (**Safety**) zones in software while providing real-time target tracking and classification.

---

## System Architecture

The project splits workloads between onboard sensor processing and high-level host decision logic:

```
+---------------------------------------------------------------------------------+
|                         IWR6843AOP Sensor Hardware                              |
|                                                                                 |
|  +--------------------+   +---------------------------+   +------------------+  |
|  |  BSS (RF Front-End)|   |  DSS (DSP C674x + HWA)    |   | MSS (ARM-R4F)    |  |
|  |  - 3 TX / 4 RX AOP |   |  - 1D/2D/3D FFT           |   | - GTRACK Tracker |  |
|  |  - Auto-Calib/BIST |   |  - CFAR Noise Thresholding|   | - TLV UART Stream|  |
|  +--------------------+   +---------------------------+   +------------------+  |
+----------------------------------------|----------------------------------------+
                                         | Dual UART (CFG & DATA Ports)
                                         v
+---------------------------------------------------------------------------------+
|                             MATLAB Host Application                             |
|                                                                                 |
|  +--------------------+   +---------------------------+   +------------------+  |
|  |  Zone Calibration  |   |  Decision Tree Classifier |   | Decision Engine  |  |
|  |  - `inpolygon()`   |   |  - `bboxDiag`             |   | - Gate Trigger   |  |
|  |  - Coordinate Xform|   |  - `dopplerStd` (Micro-D) |   | - Safety Override|  |
|  +--------------------+   +---------------------------+   +------------------+  |
+---------------------------------------------------------------------------------+
```

- **BSS (BIST Subsystem):** Autonomous RF calibration compensating for temperature and semiconductor manufacturing process variations.
- **DSS (DSP Subsystem):** Integrates the C674x 600 MHz VLIW DSP and Hardware Accelerator (HWA) to execute Range (1D), Doppler (2D), and Angle (3D) FFTs, as well as adaptive CFAR detection.
- **MSS (Master Subsystem):** Runs the GTRACK algorithm (Kalman filter-based object tracking) on an ARM Cortex-R4F CPU and streams TLV-formatted binary data over UART.
- **Host (MATLAB):** Performs spatial coordinate transformation, point-in-polygon zone inclusion tests, decision tree target classification, hysteresis voting, and gate relay/decision logic.

---

## Key Features

1. **Software-Defined Virtual Loops:** Configurable multi-zone layout (Trigger 1, Trigger 2, and Safety Zones) without physical infrastructure changes.
2. **Interactive Calibration Tool:** Guided setup using live radar detections and an immobility detection algorithm (12-sample sliding window with $0.25\text{ m}$ spatial stability over $1\text{ s}$) to automatically construct local coordinate frames.
3. **Machine Learning Classifier:** Person vs. Vehicle discrimination using micro-Doppler spectrum dispersion and physical cluster dimensions, validated with 10-fold cross-validation ($6.8\%$ error rate).
4. **Hysteresis & Voting Logic:** Track-class switching requires $N = 10$ consecutive consistent frame votes (`SWITCH_THRESHOLD`), preventing chatter caused by transient noise.
5. **Absolute Safety Priority:** Any detected object (regardless of class) inside the designated **Safety Zone** triggers an immediate, unconditioned gate closure block.
6. **Motion Direction Sensing:** Radial Doppler velocity mapping discriminates between *Approaching*, *Departing*, and *Stationary* targets in real time.

---

## Person vs. Vehicle Classifier

Target classification relies on features extracted from point clusters associated with unique GTRACK Track IDs:

| Feature Metric | Mathematical / Physical Description | Pedestrian Median | Vehicle Median |
| :--- | :--- | :---: | :---: |
| **Bounding Box Diagonal (`bboxDiag`)** | Extent of point cluster: $\sqrt{\Delta x^2 + \Delta y^2}$ | $0.65\text{ m}$ | $1.51\text{ m}$ |
| **Doppler Dispersion (`dopplerStd`)** | Standard deviation of radial velocity within cluster (micro-Doppler) | $0.36\text{ m/s}$ | $0.29\text{ m/s}$ |
| **Tracking Speed (`trackSpeed`)** | Magnitude of Kalman-filtered track velocity vector: $\sqrt{v_x^2 + v_y^2}$ | $\le 1.6\text{--}2.2\text{ m/s}$ | $> 1.6\text{--}2.2\text{ m/s}$ |

### Decision Tree Rules

1. **If** $\text{bboxDiag} \ge 1.446\text{ m} \longrightarrow$ **Vehicle**
2. **Else If** $\text{dopplerStd} \ge 0.253\text{ m/s} \longrightarrow$ **Person** (indicates articulated limb movement)
3. **Else If** $\text{bboxDiag} < 0.468\text{ m} \longrightarrow$ **Person**
4. **Else** $\longrightarrow$ **Vehicle** (compact rigid body)

---

## Repository Structure

```
.
├── config/
│   └── profile_area_scanner.cfg      # TI IWR6843 CLI configuration file (chirps, frames, CFAR)
├── src/
│   ├── setup_as_exported_desing.m     # App Designer GUI for setup & COM port selection
│   ├── calibration_plot.m            # Interactive zone calibration tool
│   ├── area_scanner_visualizer.m     # Real-time 2D visualizer & decision engine
│   ├── readUARTtoBuffer.m            # Low-level UART stream buffer reader
│   ├── parseBytes_AS.m               # TLV packet parser (Point Cloud, Target List, Target Index)
│   ├── calibrate_person_car_logger.m # Data logging utility for feature extraction
│   └── analyze_calibration_data.m    # Statistical analysis & decision tree training script
├── data/
│   ├── state.mat                     # Persisted calibration geometry, COM ports, & settings
│   └── dados_xpto.csv                # Labeled training dataset for classifier optimization
└── README.md                         # Project documentation
```

---

## Hardware & Software Requirements

### Hardware
- **Sensor:** Texas Instruments **IWR6843AOPEVM** or **IWR6843AOP** custom board.
- **Carrier/Interface:** MMWAVE-ICBOOST board (optional, for debugging/LVDS streaming) or USB interface board.
- **Connection:** Micro-USB to PC (exposes two FTDI COM ports: User/CFG and Data/AUX).

### Software & Toolchain
- **MATLAB:** R2021b or newer (Requires *App Designer*, *Statistics and Machine Learning Toolbox*, and *Instrument Control Toolbox*).
- **TI UniFlash:** Version 6.0+ (for flashing radar firmware binaries).
- **TI Code Composer Studio (CCS):** Version 10.0+ (optional, for firmware compilation).

---

## Installation & Setup

1. **Clone the Repository:**
   ```bash
   git clone https://github.com/your-username/iwr6843aop-virtual-loop.git
   cd iwr6843aop-virtual-loop
   ```

2. **Flash the Radar Firmware:**
   - Connect the IWR6843AOP in flashing mode (S1 DIP switches properly set).
   - Open **UniFlash**, select `IWR6843AOP`, and flash the Area Scanner binary (`.bin`) from the TI mmWave Industrial Toolbox.
   - Power cycle the device into functional mode.

3. **Configure Serial Ports:**
   - Open Device Manager (Windows) or `/dev/tty*` (Linux) to identify:
     - **CFG_PORT:** Enhanced COM Port (Command Line Interface, 115200 baud).
     - **DATA_PORT:** Standard COM Port (Binary streaming, 921600 baud).

---

## Usage Workflow

```
+---------------------------------------------------------------------------------+
| 1. Launch Setup GUI (`setup_as_exported_desing.m`)                              |
|    Set COM ports, mounting height/tilt, and select `.cfg` profile               |
+---------------------------------------------------------------------------------+
                                       |
                                       v
+---------------------------------------------------------------------------------+
| 2. Run Area Calibration (`calibration_plot.m`)                                  |
|    Walk to reference points to define Total Area, Safety, and Trigger zones     |
+---------------------------------------------------------------------------------+
                                       |
                                       v
+---------------------------------------------------------------------------------+
| 3. Execute Real-Time Visualizer (`area_scanner_visualizer.m`)                   |
|    Monitor live tracking, target classification, and gate decision outputs      |
+---------------------------------------------------------------------------------+
                                       | (Optional: Retraining)
                                       v
+---------------------------------------------------------------------------------+
| 4. Data Logging & Retraining Pipeline                                           |
|    Run `calibrate_person_car_logger.m` -> Run `analyze_calibration_data.m`     |
+---------------------------------------------------------------------------------+
```

### 1. Initial Configuration & Setup GUI
Launch MATLAB and run:
```matlab
run('src/setup_as_exported_desing.m')
```
- Enter the **CFG_PORT** and **DATA_PORT** numbers.
- Specify installation parameters: Sensor Height ($h$), Tilt Angle ($\theta$), and Barrier Arm Length.
- Select the `profile_area_scanner.cfg` configuration file.
- Click **Setup Complete** to save settings to `state.mat`.

### 2. Interactive Area Calibration
Run the calibration script:
```matlab
run('src/calibration_plot.m')
```
- **Point 1 (P1):** Automatically computed at the tip of the barrier arm (`gateTip`).
- **Point 2 (P2):** Walk to the furthest detection boundary. The immobility detection algorithm unlocks the "Set Point" button once spatial variance falls below $0.25\text{ m}$ for $1\text{ s}$.
- Drag with the mouse to draw **Safety** (Red) and **Trigger** (Blue) sub-polygons inside the boundary.
- Calibration geometries are automatically persisted to `state.mat`.

### 3. Real-Time Visualizer & Decision Controller
Start the main runtime application:
```matlab
run('src/area_scanner_visualizer.m')
```
- The visualizer streams binary packets over UART, applies rotation matrices to project point clouds into world coordinates $(x, y)$, and executes the decision logic:
  - **Red Banner (Safety Active):** Object detected inside Safety Zone $\rightarrow$ Gate holds open / prevents closure.
  - **Blue Banner (Trigger Active):** Target classified as **Vehicle** inside Trigger Zone $\rightarrow$ Issue opening signal.
  - **Pedestrian Override:** Pedestrians near the gate/housing are classified and ignored by the Trigger logic.

### 4. Data Logging & Classifier Retraining Pipeline
To collect new training datasets or adjust thresholds for different installation heights:
1. Record real-time sessions to a `.txt` file using the recorder mode in the visualizer.
2. Run `calibrate_person_car_logger.m` to parse TLV packets, calculate feature vectors, and append labeled data to `dados_xpto.csv`.
3. Run `analyze_calibration_data.m` to generate statistical summaries, boxplots, linear regressions (SNR attenuation vs. distance compensation), and fit a new decision tree using 10-fold cross-validation.

---

## Firmware Configuration (`.cfg`)

The `.cfg` file defines crucial GTRACK and front-end parameters:

- **Static Boundary Box (`staticDetectionCfg`):** Filters out clutter beyond the site dimensions:
  ```text
  staticDetectionCfg -1.8 0.5 0.0 1.8 0.0 2.0
  ```
- **Sensor Position (`sensorPosition`):** Informs firmware tracker of mounting height and tilt:
  ```text
  sensorPosition 0.87 0 30
  ```

---

## License & Acknowledgments

This project was developed by **João Lafayette** during an engineering internship at **Motorline Professional** in collaboration with **Texas Instruments**.

Special thanks to the R&D team at Motorline Professional and the Texas Instruments mmWave Systems Applications Group.