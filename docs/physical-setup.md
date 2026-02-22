# SCARA Drawing Arm - Physical Setup Reference

## Purpose
Reference for the current Morgan SCARA drawing-arm hardware and the matching Marlin configuration.

## Hardware Snapshot

| Item | Value |
|---|---|
| Controller | Arduino Mega 2560 |
| Shield | Protoneer CNC Shield v3 |
| Drivers | A4988 |
| Microstepping | 1/8 (two jumpers) |
| Gear reduction | 1:3 on both joints |
| Joint 1 motor wiring | CNC shield X driver slot |
| Joint 2 motor wiring | CNC shield Y driver slot |
| Joint 1 endstop | X min |
| Joint 2 endstop | Y min |
| Z endstop | Not installed |

## Arm Geometry

| Parameter | Value | Source |
|---|---|---|
| `SCARA_LINKAGE_1` | `116 mm` | measured/approx |
| `SCARA_LINKAGE_2` | `114 mm` | measured/approx |
| Theoretical max radius | `230 mm` | `L1 + L2` |
| Configured dead zone | `38 mm` | `MIDDLE_DEAD_ZONE_R` |

Steps-per-degree baseline:

```text
200 steps/rev * 8 microsteps * 3 gear ratio / 360 = 13.333 steps/deg
```

## Coordinate Frames (Locked)

Machine frame is the shoulder pivot frame:
- `SCARA_OFFSET_X = 0`
- `SCARA_OFFSET_Y = 0`

Interpretation:
- +X is to the right of the shoulder pivot.
- +Y is upward from the shoulder pivot.
- Positive angles are CCW.

## Home Pose Constants (Endstop Contact)

Measured at physical switch contact:
- `SCARA_HOME_J1_DEG = -30`
- `SCARA_HOME_J2_REL_DEG = +150`
- `SCARA_HOME_J2_ABS_DEG = +120` (derived)

Expected Cartesian home in pivot frame:

```text
X_home = 116*cos(-30) + 114*cos(120) = 43.46 mm
Y_home = 116*sin(-30) + 114*sin(120) = 40.73 mm
```

## Active Firmware Controls (SCARA Safety)

Current key constants in `Marlin/Configuration.h`:
- `SCARA_JOINT_LIMITS` enabled
- `SCARA_JOINT_GUARD_DEG = 3`
- `SCARA_J1_MIN_DEG = -120`
- `SCARA_J1_MAX_DEG = 120`
- `SCARA_J2_REL_MIN_DEG = 30`
- `SCARA_J2_REL_MAX_DEG = 165`

Note: limit values above are safe initial defaults. Replace with measured hard limits plus margin.

## Joint-Limit Measurement Procedure

1. Keep feedrate low (`F60` to `F120`) and keep one hand on emergency stop.
2. Move each joint toward each hard stop in tiny increments.
3. Record first-contact angle from `M114` SCARA report.
4. Define configured limits inside those contacts with margin:
   - start with `SCARA_JOINT_GUARD_DEG = 3`
   - use `5` if collisions are still likely
5. Reflash after updating limits.

Record values here:

| Constant | Measured value |
|---|---|
| `SCARA_J1_MIN_DEG` | TODO |
| `SCARA_J1_MAX_DEG` | TODO |
| `SCARA_J2_REL_MIN_DEG` | TODO |
| `SCARA_J2_REL_MAX_DEG` | TODO |

## Operator SOP (Current Best Practice)

At power-up:

```gcode
M502
M500
M211 S1
G90
G28 X Y
M114
```

Then set fixture/work origin (paper frame) with `G92`:

```gcode
; Example: set current toolpoint as fixture origin
G92 X0 Y0 Z0
```

For pivot-frame validation, set to home reference instead:

```gcode
G92 X43.46 Y40.73 Z0
```

## Notes

- `NO_MOTION_BEFORE_HOMING` and `HOME_AFTER_DEACTIVATE` are enabled.
- Motion is blocked until XY are homed.
- Marlin now rejects SCARA moves with explicit reasons:
  - outside radius
  - inside dead zone
  - J1 limit exceeded
  - J2 relative limit exceeded
- Pen servo integration is intentionally deferred until XY validation passes.
