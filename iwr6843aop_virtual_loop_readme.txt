===============================================================================
  mmWave Radar Area Scanner & Virtual Loop System (TI IWR6843AOP)
===============================================================================

An intelligent, software-defined access control and virtual inductive loop 
system using the Texas Instruments IWR6843AOP Antenna-on-Package 60-64 GHz 
mmWave radar sensor. Developed at Motorline Professional in partnership with 
Texas Instruments, this project replaces traditional pavement-cut inductive 
loops with an above-ground radar system capable of real-time 2D spatial 
tracking, dynamic area calibration, and machine-learning-based Person vs. 
Vehicle classification.


-------------------------------------------------------------------------------
1. OVERVIEW & PROBLEM STATEMENT
-------------------------------------------------------------------------------

Traditional vehicle detection systems rely on magnetic inductive loops 
buried under the pavement. This approach introduces significant operational 
drawbacks:

  * Invasive, noisy, and costly asphalt cutting and civil works.
  * Inability to install on stone paving, pre-stressed structures, or metallic 
    grates.
  * Rigid, fixed detection geometries requiring physical re-excavation for 
    modifications.
  * Lack of target classification (inability to distinguish pedestrians from 
    vehicles or track direction of movement).

The Virtual Loop System addresses these issues by mounting the TI IWR6843AOP 
mmWave radar above the ground (on the barrier post or housing). It allows 
operators to define multiple arbitrary activation (Trigger) and protection 
(Safety) zones in software while providing real-time target tracking and 
classification.


-------------------------------------------------------------------------------
2. SYSTEM ARCHITECTURE
-------------------------------------------------------------------------------

The project splits workloads between onboard sensor processing and high-level 
host decision logic:

  +-------------------------------------------------------------------------+
  |                        IWR6843AOP Sensor Hardware                       |
  |                                                                         |
  |  +-------------------+  +--------------------------+  +---------------+ |
  |  | BSS (RF Front-End)|  | DSS (DSP C674x + HWA)    |  | MSS (ARM-R4F) | |
  |  | - 3 TX / 4 RX AOP |  | - 1D/2D/3D FFT           |  | - GTRACK      | |
  |  | - Auto-Cal/BIST   |  | - CFAR Noise Thresholding|  | - TLV Streaming| |
  |  +-------------------+  +--------------------------+  +---------------+ |
  +------------------------------------|------------------------------------+
                                       | Dual UART (CFG & DATA Ports)
                                       v
  +-------------------------------------------------------------------------+
  |                        MATLAB Host Application                          |
  |                                                                         |
  |  +-------------------+  +--------------------------+  +---------------+ |
  |  | Zone Calibration  |  | Decision Tree Classifier |  | Decision Engine| |
  |  | - inpolygon()     |  | - bboxDiag               |  | - Gate Trigger| |
  |  | - Coord Xform     |  | - dopplerStd (Micro-D)   |  | - Safety Lock | |
  |  +-------------------+  +--------------------------+  +---------------+ |
  +-------------------------------------------------------------------------+

* BSS (BIST Subsystem): Autonomous RF calibration compensating for temperature 
  and semiconductor manufacturing process variations.
* DSS (DSP Subsystem): Integrates the C674x 600 MHz VLIW DSP and Hardware 
  Accelerator (HWA) to execute Range (1D), Doppler (2D), and Angle (3D) FFTs, 
  as well as adaptive CFAR detection.
* MSS (Master Subsystem): Runs the GTRACK algorithm (Kalman filter-based object 
  tracking) on an ARM Cortex-R4F CPU and streams TLV-formatted binary data over 
  UART.
* Host (MATLAB): Performs spatial coordinate transformation, point-in-polygon 
  zone inclusion tests, decision tree target classification, hysteresis voting, 
  and gate relay/decision logic.


-------------------------------------------------------------------------------
3. KEY FEATURES
-------------------------------------------------------------------------------

1. Software-Defined Virtual Loops: Configurable multi-zone layout (Trigger 1, 
   Trigger 2, and Safety Zones) without physical infrastructure changes.
2. Interactive Calibration Tool: Guided setup using live radar detections and 
   an immobility detection algorithm (12-sample sliding window with 0.25m 
   spatial stability over 1s) to automatically construct local coordinate frames.
3. Machine Learning Classifier: Person vs. Vehicle discrimination using micro-
   Doppler spectrum dispersion and physical cluster dimensions, validated with 
   10-fold cross-validation (6.8% error rate).
4. Hysteresis & Voting Logic: Track-class switching requires N = 10 
   consecutive consistent frame votes (SWITCH_THRESHOLD), preventing chatter 
   caused by transient noise.
5. Absolute Safety Priority: Any detected object (regardless of class) inside 
   the designated Safety Zone triggers an immediate, unconditioned gate closure 
   block.
6. Motion Direction Sensing: Radial Doppler velocity mapping discriminates 
   between Approaching, Departing, and Stationary targets in real time.


-------------------------------------------------------------------------------
4. PERSON VS. VEHICLE CLASSIFIER
-------------------------------------------------------------------------------

Target classification relies on features extracted from point clusters 
associated with unique GTRACK Track IDs:

Metric                   | Description                     | Person | Vehicle
-------------------------+---------------------------------+--------+--------
Bounding Box Diagonal    | Cluster extent: sqrt(dx^2+dy^2) | 0.65 m | 1.51 m
Doppler Dispersion       | Std dev of radial velocity      | 0.36m/s| 0.29m/s
Tracking Speed           | Kalman track velocity magnitude | <=2.2m/s| >2.2m/s

Decision Tree Rules:
  1. IF bboxDiag >= 1.446 m ----------> Vehicle
  2. ELSE IF dopplerStd >= 0.253 m/s --> Person (articulated leg movement)
  3. ELSE IF bboxDiag < 0.468 m ------> Person
  4. ELSE ----------------------------> Vehicle (compact rigid body)


-------------------------------------------------------------------------------
5. REPOSITORY STRUCTURE
-------------------------------------------------------------------------------

.
├── config/
│   └── profile_area_scanner.cfg      # TI IWR6843 CLI configuration file
├── src/
│   ├── setup_as_exported_desing.m     # App Designer GUI for setup & COM ports
│   ├── calibration_plot.m            # Interactive zone calibration tool
│   ├── area_scanner_visualizer.m     # Real-time 2D visualizer & decision engine
│   ├── readUARTtoBuffer.m            # Low-level UART stream buffer reader
│   ├── parseBytes_AS.m               # TLV packet parser
│   ├── calibrate_person_car_logger.m # Data logging utility for training
│   └── analyze_calibration_data.m    # Statistical analysis & decision tree
├── data/
│   ├── state.mat                     # Persisted calibration geometry & settings
│   └── dados_xpto.csv                # Labeled training dataset
└── README.txt                        # Project documentation


-------------------------------------------------------------------------------
6. HARDWARE & SOFTWARE REQUIREMENTS
-------------------------------------------------------------------------------

Hardware:
  * Sensor: Texas Instruments IWR6843AOPEVM or custom IWR6843AOP board.
  * Carrier Board: MMWAVE-ICBOOST board (optional) or USB interface board.
  * Interface: Micro-USB to PC (exposes two FTDI COM ports: CFG and DATA).

Software & Toolchain:
  * MATLAB R2021b or newer (App Designer, Statistics & ML Toolbox, Instrument 
    Control Toolbox).
  * TI UniFlash 6.0+ (for flashing radar firmware binaries).
  * TI Code Composer Studio (CCS) 10.0+ (optional, for custom C compilation).


-------------------------------------------------------------------------------
7. INSTALLATION & SETUP
-------------------------------------------------------------------------------

1. Clone the Repository:
   git clone https://github.com/your-username/iwr6843aop-virtual-loop.git
   cd iwr6843aop-virtual-loop

2. Flash Radar Firmware:
   * Connect the IWR6843AOP in flashing mode (S1 DIP switches).
   * Open UniFlash, select IWR6843AOP, and flash the Area Scanner binary (.bin).
   * Power cycle device into functional mode.

3. Identify Serial Ports (Device Manager / /dev/tty*):
   * CFG_PORT: Enhanced COM Port (CLI at 115200 baud).
   * DATA_PORT: Standard COM Port (Binary stream at 921600 baud).


-------------------------------------------------------------------------------
8. USAGE WORKFLOW
-------------------------------------------------------------------------------

Step 1: Initial Configuration & Setup GUI
  Run: run('src/setup_as_exported_desing.m')
  - Enter CFG_PORT and DATA_PORT.
  - Set mounting height (h), tilt angle (theta), and arm length.
  - Select profile_area_scanner.cfg and click "Setup Complete".

Step 2: Interactive Area Calibration
  Run: run('src/calibration_plot.m')
  - Point 1 (P1): Computed automatically at barrier tip (gateTip).
  - Point 2 (P2): Walk to furthest boundary. Immobility detection unlocks 
    "Set Point" once spatial variance < 0.25m for 1 second.
  - Draw Safety (Red) and Trigger (Blue) sub-polygons by dragging mouse.

Step 3: Real-Time Visualizer & Decision Controller
  Run: run('src/area_scanner_visualizer.m')
  - Monitors live tracking, projects coordinates to (X,Y) world space.
  - Red Banner: Safety Zone Active (Gate holds open / prevents closure).
  - Blue Banner: Vehicle in Trigger Zone (Issues opening signal).
  - Pedestrians near housing are classified and ignored by trigger logic.

Step 4: Data Logging & Retraining Pipeline (Optional)
  - Record sessions to .txt file in visualizer.
  - Run calibrate_person_car_logger.m to generate labeled .csv dataset.
  - Run analyze_calibration_data.m to retrain decision tree thresholds.


-------------------------------------------------------------------------------
9. FIRMWARE CONFIGURATION (.CFG)
-------------------------------------------------------------------------------

Key parameters in profile_area_scanner.cfg:

  * Static Boundary Box (staticDetectionCfg):
    staticDetectionCfg -1.8 0.5 0.0 1.8 0.0 2.0

  * Sensor Position (sensorPosition):
    sensorPosition 0.87 0 30


-------------------------------------------------------------------------------
10. LICENSE & ACKNOWLEDGMENTS
-------------------------------------------------------------------------------

This project was developed by João Lafayette during an engineering internship 
at Motorline Professional in collaboration with Texas Instruments.

Special thanks to the R&D team at Motorline Professional and the Texas 
Instruments mmWave Systems Applications Group.
===============================================================================