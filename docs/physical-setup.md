# SCARA Drawing Arm - Physical Setup Reference

## Purpose
Morgan SCARA robot arm for drawing on paper with a sharpie.

## Arm Geometry

| Parameter | Value | Notes |
|---|---|---|
| SCARA_LINKAGE_1 (shoulder to elbow) | 116 mm | Approximate - may need refinement |
| SCARA_LINKAGE_2 (elbow to end effector) | 114 mm | Approximate - may need refinement |
| Reach radius (theoretical) | 230 mm | `SCARA_LINKAGE_1 + SCARA_LINKAGE_2` |
| Recommended working radius | 220 mm | Stay away from near-straight-arm singularity |
| Gear reduction | 1:3 | Both motors, via pulleys |

Arm lengths are compile-time constants. To adjust, edit `Marlin/Configuration.h`
(`SCARA_LINKAGE_1`, `SCARA_LINKAGE_2`) and reflash.

## Electronics

| Component | Details |
|---|---|
| Controller | Arduino Mega 2560 |
| Shield | Protoneer CNC Shield v3 |
| Stepper drivers | A4988 |
| Microstepping | 1/8 (2 jumpers per driver on CNC shield) |
| Motor 1 (shoulder/A-axis) | X driver slot on CNC shield |
| Motor 2 (elbow/B-axis) | Y driver slot on CNC shield |
| Endstop - shoulder | X_STOP_PIN (pin 9 on CNC shield) |
| Endstop - elbow | Y_STOP_PIN (pin 10 on CNC shield) |
| Z endstop | Not installed |

### Steps Per Degree Calculation

```
  200 steps/rev  (1.8 deg stepper)
x   8            (1/8 microstepping, 2 jumpers on A4988)
x   3            (1:3 gear reduction via pulleys)
= 4800 steps/rev
/ 360 deg
= 13.333 steps/degree
```

## Firmware Configuration Summary

Board define: `BOARD_PROTONEER_CNC_SHIELD_V3`
Kinematics: `MORGAN_SCARA`
PlatformIO env: `mega2560`

### Key Settings in Configuration.h

- `EXTRUDERS 0` - No extruder
- `TEMP_SENSOR_0 0` / `TEMP_SENSOR_BED 0` - No thermal hardware
- `DEFAULT_AXIS_STEPS_PER_UNIT { 13.333, 13.333, 400 }` - A/B in steps/deg, Z in steps/mm
- `DEFAULT_MAX_FEEDRATE { 25, 25, 3 }` - Reduced for safe bring-up
- `DEFAULT_MAX_ACCELERATION { 100, 100, 60 }` - Reduced to minimize skipped steps
- `DEFAULT_ACCELERATION / DEFAULT_TRAVEL_ACCELERATION { 100, 100, 100 }`
- `DEFAULT_XJERK / DEFAULT_YJERK { 1.5, 1.5 }` - Lowered to reduce abrupt joint shocks
- `FEEDRATE_SCALING` enabled - Converts G-code mm/s to deg/s automatically
- `EEPROM_SETTINGS` enabled - Persist calibration with M500
- `X_SAFETY_STOP` / `Y_SAFETY_STOP` enabled - Endstops act as safety limits
- `PRINTABLE_RADIUS` is computed by Marlin for SCARA as `L1 + L2` (230 mm)
- `SCARA_OFFSET_X 0` / `SCARA_OFFSET_Y 0` - Current default coordinate offset
- `MIDDLE_DEAD_ZONE_R 38` - Blocks unreachable / unstable center region

### SCARA Offsets

`SCARA_OFFSET_X` and `SCARA_OFFSET_Y` define the shoulder pivot position relative
to the coordinate origin (0,0). Currently set to `(0, 0)`, so the origin is the
shoulder pivot. Adjust at runtime with `M665` and save with `M500`.

### How to Measure SCARA Offset (Practical Method)

1. Pick where you want drawing `(0,0)` on the paper fixture (usually front-left corner).
2. Measure shoulder pivot center coordinates in that same frame:
   - `SCARA_OFFSET_X` = shoulder X position from drawing origin
   - `SCARA_OFFSET_Y` = shoulder Y position from drawing origin
3. Start with approximate values, then fine tune:
   - Manually set arm to your known startup pose
   - `G92 X0 Y0`
   - Command known points (for example `G1 X100 Y0`, `G1 X0 Y100`) and compare to real pen tip location
   - Correct offsets with `M665 P<shoulder_offset> T<elbow_offset>` for angular correction
4. Save stable runtime calibration with `M500`.

`MIDDLE_DEAD_ZONE_R` is currently `38 mm` to avoid commanding moves too close to the
SCARA center region.

Marlin's stock SCARA checks geometric reachability (outer radius and dead-zone), but
does not model physical linkage self-collision or your custom endstop placements. Keep
all new test moves slow and expand reachable workspace gradually.

## Endstops

Endstops are wired to X and Y stop pins on the CNC shield. In the stock Morgan SCARA
firmware, X/Y endstops are NOT used for homing (homing assumes a known manual position).
They are configured as safety stops only.

`Z_MIN_ENDSTOP_HIT_STATE` is set to `LOW` to avoid false `z_min: TRIGGERED` reports
when no Z endstop is connected.

### Mechanical Home Reference (Current Build)

Measured at endstop contact:
- Joint 1 (L1 relative to world): `-30°`
- Joint 2 (L2 relative to L1): `+150°`

With `L1=116`, `L2=114`, `SCARA_OFFSET_X=0`, `SCARA_OFFSET_Y=0`:

```text
theta1 = -30°
theta2_abs = theta1 + theta2_rel = +120°

X_home = 0 + 116*cos(-30°) + 114*cos(+120°) = 43.46
Y_home = 0 + 116*sin(-30°) + 114*sin(+120°) = 40.73
```

Practical startup sequence (until automatic homing is implemented):

```gcode
; Put arm at mechanical home (both linkage endstops contacted)
M17
G92 X43.46 Y40.73 Z0
M114
```

Do not use `G28` for XY on Morgan SCARA in stock Marlin.

Automatic homing using endstops is planned as a future feature.

## Pen Mechanism

Not yet implemented. Plan is to use a servo on the Z-axis for pen up/down.
The CNC shield Z driver slot is available for future use.

## Calibration

### Runtime-adjustable (M665, saved with M500)
- Angle offsets (shoulder/elbow home position)
- Segments per second

### Requires reflash
- Arm lengths (SCARA_LINKAGE_1, SCARA_LINKAGE_2)

### Calibration G-codes
- `M360` - Move to Theta 0 deg calibration position
- `M361` - Move to Theta 90 deg calibration position
- `M362` - Move to Psi 0 deg calibration position
- `M363` - Move to Psi 90 deg calibration position
- `M364` - Move to Theta-Psi 90 deg calibration position
- `M665` - Report/set SCARA parameters (S=segments/sec, P=shoulder offset, T=elbow offset)
- `M503` - Report all current settings
