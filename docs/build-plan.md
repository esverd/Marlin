# SCARA Drawing Arm - Development & Build Plan

## Locked Decisions

1. Keep current hardware for stabilization: Mega 2560 + CNC shield + A4988.
2. Keep `MORGAN_SCARA` kinematics.
3. Machine frame stays at shoulder pivot (`SCARA_OFFSET_X/Y = 0`).
4. Use startup `G92` for fixture/work frame.
5. Enforce safety in firmware with SCARA joint-angle limits.
6. Require homing before normal XY motion.
7. Accept motion only after numeric validation (`<=2 mm` endpoint error, `<=1 mm` return drift).
8. Commit every repo mutation locally (no push required).

## Implementation Status

### Completed

1. Added SCARA home-angle constants and joint-limit constants in `Marlin/Configuration.h`.
2. Added SCARA joint-angle evaluation helper in `Marlin/src/module/scara.cpp`.
3. Added joint-limit rejection in reachability checks with explicit serial reasons in `Marlin/src/module/motion.cpp`.
4. Updated Morgan home position handling to derive XY home from measured home angles in `Marlin/src/module/scara.cpp`.
5. Enabled XY homing path for Morgan/MP SCARA in `Marlin/src/module/motion.cpp`.
6. Disabled diagonal `quick_home_xy()` behavior for SCARA in `Marlin/src/gcode/calibrate/G28.cpp`.
7. Enabled `NO_MOTION_BEFORE_HOMING` and `HOME_AFTER_DEACTIVATE` in `Marlin/Configuration.h`.
8. Enforced XY-only homing gate for SCARA motion lock in `Marlin/src/module/motion.h` (practical for no Z endstop).

### In Progress

1. Measure true mechanical joint limits and replace placeholder limit constants.
2. Run full coordinate validation gate and record measured error values.

## Validation Gate (Before Pen Integration)

Run `docs/scara/coordinate-validation.gcode` and evaluate:

1. Home and setup must complete with no homing failures.
2. Reachability rejects must show correct reason text when tested.
3. Run full checkpoint path for 3 cycles.
4. For every checkpoint, endpoint error must be `<=2 mm`.
5. Return-to-home drift after each cycle must be `<=1 mm`.

If validation fails, fix in this order:

1. Motor direction/sign and wiring.
2. Steps per degree (`M92` / `DEFAULT_AXIS_STEPS_PER_UNIT`).
3. Link lengths (`SCARA_LINKAGE_1/2`).
4. Joint-limit margins (`SCARA_JOINT_GUARD_DEG`).

## Operator Workflow (Current)

1. Power on, connect serial.
2. Run:
   - `M502`
   - `M500`
   - `M211 S1`
   - `G90`
   - `G28 X Y`
   - `M114`
3. Set work frame for the current fixture with `G92`.
4. Run coordinate validation script before any pen tests.

## Remaining Work for Homing Robustness

1. Tune homing feedrates and bump distances after repeated cycle data.
2. Verify homing failure behavior by deliberately disconnecting one switch.
3. Measure homing repeatability over 20 cycles and document scatter.

## Pen-Ready Exit Criteria

1. No collisions in validated workspace.
2. Joint-limit rejects prevent known unsafe motions.
3. Homing repeatability and coordinate error meet gate thresholds.
4. Working envelope is documented and path generator constrained to that envelope.
