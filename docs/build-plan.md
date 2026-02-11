# SCARA Drawing Arm - Development & Build Plan

## Phase 1: Basic Motion (current)

**Goal:** Get both motors moving correctly in response to G-code commands.

### Steps
1. Flash firmware to Arduino Mega 2560 with current configuration
2. Connect via USB serial (250000 baud) using Pronterface, OctoPrint, or similar
3. Verify serial communication — send `M503` to see current settings
4. Test individual motor movement:
   - `G91` (relative mode)
   - `G1 X10 F10` — shoulder should rotate ~10 degrees
   - `G1 Y10 F10` — elbow should rotate ~10 degrees
5. Verify motor direction — if a motor rotates the wrong way:
   - Flip `INVERT_X_DIR` or `INVERT_Y_DIR` in Configuration.h and reflash
   - OR physically reverse the motor connector
6. Verify steps/degree — command a known angle and measure:
   - `G90` (absolute mode), then `G1 X90 F20` should move shoulder exactly 90 deg
   - If not, adjust `DEFAULT_AXIS_STEPS_PER_UNIT` and reflash (or use `M92 X<new> Y<new>`)

### What to Watch For
- Morgan SCARA ignores `G28` for X/Y — it just beeps. This is expected.
- Manually position the arm to a known pose before powering on.
- Endstops will trigger safety stops if hit — check `M119` to see endstop states.
- If motion is jerky, try reducing `DEFAULT_SEGMENTS_PER_SECOND` (currently 200).

---

## Phase 2: Kinematics Verification

**Goal:** Confirm that Cartesian G-code commands produce correct arm movements.

### Steps
1. Set the arm to its home position manually and send `G92 X0 Y0`
2. Send small Cartesian moves and observe the arm path:
   - `G1 X50 Y0 F20` — arm should reach 50mm along X
   - `G1 X50 Y50 F20` — arm should reach (50,50) in Cartesian space
   - `G1 X0 Y100 F20` — arm should reach 100mm along Y
3. Draw a test square by taping a pen to the end effector:
   ```
   G90
   G1 X80 Y80 F20
   G1 X130 Y80 F20
   G1 X130 Y130 F20
   G1 X80 Y130 F20
   G1 X80 Y80 F20
   ```
   The result should be a square. If it's distorted:
   - Arm lengths may be off — measure more precisely, update `SCARA_LINKAGE_1`/`SCARA_LINKAGE_2`, reflash
   - Offsets may be wrong — adjust with `M665 P<val> T<val>`
4. Use M360-M364 calibration positions to verify angular accuracy

### Calibration Workflow
1. `M360` — arm moves to Theta=0, Psi=120. Measure actual shoulder angle.
2. `M361` — arm moves to Theta=90, Psi=130. Verify shoulder is at 90 deg.
3. If angles are off, adjust with `M665 P<offset>` / `M665 T<offset>`.
4. `M500` to save calibration to EEPROM.

---

## Phase 3: Pen Mechanism

**Goal:** Add servo-based pen up/down control.

### Steps
1. Wire a small servo to the CNC shield (requires servo signal pin — may
   need to use the SpnEn or CoolEn pin, or wire directly to an Arduino pin)
2. Enable in Configuration.h:
   ```cpp
   #define NUM_SERVOS 1
   #define SERVO_DELAY { 300 }
   ```
3. Test with `M280 P0 S<angle>`:
   - Find the pen-up angle (e.g., `M280 P0 S90`)
   - Find the pen-down angle (e.g., `M280 P0 S50`)
4. Add pen up/down commands to G-code files between path segments

---

## Phase 4: Automatic Homing

**Goal:** Use the endstops on both linkages for repeatable automatic homing.

### Approach Options

**Option A: Modify SCARA homing code**
- The stock Morgan SCARA code in `Marlin/src/module/motion.cpp` (line ~2425)
  explicitly skips X/Y homing for SCARA
- Modify to allow endstop-based homing for the A and B axes
- Each arm rotates until it hits its endstop, establishing a known angle
- Set `MANUAL_X_HOME_POS` / `MANUAL_Y_HOME_POS` to the angles at endstop contact

**Option B: Use sensorless homing (requires TMC drivers)**
- Replace A4988 drivers with TMC2209
- Use StallGuard for sensorless homing
- More elegant but requires hardware change

**Key code locations:**
- Homing logic: `Marlin/src/module/motion.cpp` (~line 2425)
- SCARA home position: `Marlin/src/module/scara.cpp` (`scara_set_axis_is_at_home()`)
- Endstop handling: `Marlin/src/module/endstops.cpp`

### Implementation Notes
- Need to define the exact angle each arm is at when its endstop triggers
- The endstop angle depends on physical mounting — measure once hardware is finalized
- Homing speed should be slow for SCARA to avoid damage (10-20 deg/s)
- Consider a two-stage homing: fast approach, back off, slow approach for precision

---

## Phase 5: Drawing Pipeline

**Goal:** Go from SVG/image to physical drawing.

### Software Pipeline
1. **SVG source** — Create or obtain vector artwork
2. **Path optimization** — Use vpype to optimize pen paths:
   ```
   vpype read input.svg linemerge linesort write output.svg
   ```
3. **G-code generation** — Convert paths to G-code:
   - Inkscape + Gcodetools extension
   - vpype + vpype-gcode plugin
   - Custom script to add M280 pen up/down commands
4. **G-code sending** — Stream to the SCARA via serial:
   - Pronterface (GUI)
   - OctoPrint (web interface)
   - `printcore` Python library (programmatic)

### G-code Structure for Drawing
```gcode
; Start
G90              ; Absolute positioning
M280 P0 S90      ; Pen up

; Move to first path start
G1 X80 Y80 F30
M280 P0 S50      ; Pen down

; Draw path
G1 X130 Y80 F20
G1 X130 Y130 F20
; ... more path points ...

M280 P0 S90      ; Pen up
; Move to next path start
; ... repeat ...

M280 P0 S90      ; Pen up (end)
G1 X0 Y0 F30     ; Return home
```

---

## Notes

- Arm lengths are approximate and require reflashing to change. Get them as
  accurate as possible early on to minimize re-calibration iterations.
- Motor direction (`INVERT_X_DIR`, `INVERT_Y_DIR`) will almost certainly need
  flipping during Phase 1. This is normal.
- Start with very slow feedrates (F10-F20) during testing. Increase once confident.
- Use `M665` and `M500` for runtime calibration of angle offsets — no reflashing needed.
