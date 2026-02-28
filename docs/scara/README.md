# SCARA Drawing Arm Docs

Use this folder as the entry point for the custom Morgan SCARA setup in this repo.

## Documents

- Physical setup and firmware mapping: `docs/physical-setup.md`
- Development / bring-up plan (including future automatic homing): `docs/build-plan.md`
- Coordinate validation script (pre-pen test path): `docs/scara/coordinate-validation.gcode`
- Frame/position troubleshooting guide: `docs/scara/troubleshooting.md`
- Frame diagnostic motion script: `docs/scara/frame-diagnostic.gcode`

## Current Hardware Snapshot

- Controller: Arduino Mega 2560
- Shield: Protoneer CNC Shield v3
- Drivers: A4988 at 1/8 microstepping (2 jumpers per driver)
- Kinematics: Morgan SCARA
- Arm lengths: L1 = 116 mm, L2 = 114 mm
- Steps per degree: 13.333 (with 1:3 pulley reduction)

## Current Firmware Snapshot

- Board: `BOARD_PROTONEER_CNC_SHIELD_V3`
- PlatformIO environment: `mega2560`
- Endstops on X/Y configured as safety stops
- Servo / pen-lift intentionally deferred until XY motion is validated
