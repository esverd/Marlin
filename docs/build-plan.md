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

## Phase 2: Kinematics Calibration

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

## Phase 3: Coordinate Verification (current priority)

**Goal:** Verify repeatable, accurate XY motion across a safe test set before adding a pen.

### Standard Bring-Up Sequence
1. `M502` then `M500` so EEPROM matches firmware defaults
2. Confirm safety state:
   - `M211` should report `S1`
   - `M119` should show expected endstop states
3. Set startup pose:
   - Manually place arm at mechanical home
   - `G90`
   - `G92 X43.46 Y40.73 Z0`
4. Use low speed during validation:
   - Keep feedrate around `F120` (`2 mm/s`)

### Coordinate Validation Plan
1. Run short local moves around home to verify sign/direction and no skipped steps
2. Run a medium-radius point set (all points outside dead zone)
3. Run a box perimeter and diagonal checks
4. Return to home and check drift with `M114`

Use `docs/scara/coordinate-validation.gcode` as the baseline script.

### Pass / Fail Criteria
- Pass:
  - No collisions or endstop impacts during scripted points
  - Returns near the same physical location after looped tests
  - No obvious cumulative drift after repeated paths
- Fail:
  - Any collision, chatter, stall, or large endpoint mismatch
  - Position drift grows each loop (indicates skipped steps)

---

## Phase 4: Joint-Angle Limits (new)

**Goal:** Reject kinematically reachable but physically unsafe targets before motion.

### Why This Is Needed
- Stock Marlin SCARA checks reach radius/dead-zone
- It does not model your physical self-collision zones or linkage/endstop angle limits

### Planned Implementation
1. Add explicit joint limit configuration for your mechanism:
   - `J1_MIN`, `J1_MAX` (absolute shoulder angle)
   - `J2_REL_MIN`, `J2_REL_MAX` (elbow relative angle)
2. Compute candidate joint angles from IK for each target move
3. Reject moves that violate limits with a clear error message
4. Keep a small guard margin (for example `2-5°`) near limits

### Code Areas
- Reachability and safety checks: `Marlin/src/module/motion.cpp`
- SCARA kinematics helpers: `Marlin/src/module/scara.cpp`
- Config constants: `Marlin/Configuration.h`

---

## Phase 5: Automatic Homing Sequence (new)

**Goal:** Homing uses your linkage endstops and sets a repeatable, trusted XY state.

### Target Homing Sequence
1. Slow move Joint 1 toward its homing stop until trigger
2. Back off a small angle
3. Re-approach at slower speed for precision
4. Set Joint 1 to calibrated endstop-contact angle
5. Repeat for Joint 2
6. Run forward kinematics from both calibrated joint angles to set XY home
7. Mark XY as homed/trusted and synchronize planner state

### Safety Requirements
- Very low homing speed (10-20 deg/s equivalent)
- Timeout / fail handling if an endstop never triggers
- Debounce or confirmation read for stable endstop detection

### Key Code Locations
- Current SCARA homing guard (skips XY): `Marlin/src/module/motion.cpp`
- SCARA home position logic: `Marlin/src/module/scara.cpp`
- Endstop handling: `Marlin/src/module/endstops.cpp`

---

## Phase 6: Pen Mechanism

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

## Phase 7: Drawing Pipeline

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
