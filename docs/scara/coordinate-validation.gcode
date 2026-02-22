; SCARA coordinate validation script (no pen)
; Purpose:
; - Verify XY homing, coordinate frame behavior, and repeatability
; - Run the same checkpoint set 3 times
;
; Preconditions:
; 1) Keep workspace clear and hand near emergency stop
; 2) Motors enabled and endstops wired
; 3) This script assumes pivot-frame reference at home: X43.46 Y40.73

M502
M500
M211 S1
M17
G90

; ------------------------------------------
; Stage 0 - home and baseline state
; ------------------------------------------
G28 X Y
M114
M119
G92 X43.46 Y40.73 Z0
M114

; ------------------------------------------
; Stage 1 - local sign/sanity checks
; ------------------------------------------
G91
G1 X5.00 F120
G1 X-5.00 F120
G1 Y5.00 F120
G1 Y-5.00 F120
G90
M114

; ------------------------------------------
; Stage 2 - checkpoint cycle 1
; ------------------------------------------
G1 X50.00 Y45.00 F120
G1 X60.00 Y60.00 F120
G1 X80.00 Y60.00 F120
G1 X100.00 Y70.00 F120
G1 X120.00 Y90.00 F120
G1 X110.00 Y110.00 F120
G1 X90.00 Y120.00 F120
G1 X70.00 Y110.00 F120
G1 X55.00 Y90.00 F120
G1 X50.00 Y45.00 F120
G1 X43.46 Y40.73 F120
M114

; ------------------------------------------
; Stage 3 - checkpoint cycle 2
; ------------------------------------------
G1 X55.00 Y90.00 F120
G1 X70.00 Y110.00 F120
G1 X90.00 Y120.00 F120
G1 X110.00 Y110.00 F120
G1 X120.00 Y90.00 F120
G1 X100.00 Y70.00 F120
G1 X80.00 Y60.00 F120
G1 X60.00 Y60.00 F120
G1 X50.00 Y45.00 F120
G1 X43.46 Y40.73 F120
M114

; ------------------------------------------
; Stage 4 - checkpoint cycle 3 + perimeter
; ------------------------------------------
G1 X60.00 Y60.00 F120
G1 X120.00 Y60.00 F120
G1 X120.00 Y120.00 F120
G1 X60.00 Y120.00 F120
G1 X60.00 Y60.00 F120
G1 X120.00 Y120.00 F120
G1 X120.00 Y60.00 F120
G1 X60.00 Y120.00 F120
G1 X60.00 Y60.00 F120
G1 X43.46 Y40.73 F120
M114
M119

; Acceptance gate (manual):
; - endpoint error <= 2 mm at all checkpoints
; - return-to-home drift <= 1 mm after each cycle
