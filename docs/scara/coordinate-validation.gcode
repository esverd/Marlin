; SCARA coordinate validation script (no pen)
; Preconditions:
; 1) Firmware flashed with current SCARA config
; 2) Arm manually set to mechanical home before G92
; 3) Keep clear of links and endstops

M502
M500
M211 S1
M17

G90
G92 X43.46 Y40.73 Z0
M114
M119

; ------------------------------------------
; Stage 1 - tiny local moves near home
; ------------------------------------------
G1 X50.00 Y41.00 F120
G1 X50.00 Y46.00 F120
G1 X43.46 Y40.73 F120
M114

; ------------------------------------------
; Stage 2 - medium safe point set
; Keep all points outside dead zone (R >= 38)
; ------------------------------------------
G1 X60.00 Y50.00 F120
G1 X80.00 Y60.00 F120
G1 X100.00 Y70.00 F120
G1 X90.00 Y90.00 F120
G1 X70.00 Y95.00 F120
G1 X55.00 Y80.00 F120
G1 X60.00 Y50.00 F120
M114

; ------------------------------------------
; Stage 3 - perimeter and diagonals
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
M114

; ------------------------------------------
; Stage 4 - return to home reference
; ------------------------------------------
G1 X43.46 Y40.73 F120
M114
M119
