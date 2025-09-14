# OmniBLE
Omnipod Bluetooth PumpManager For Loop

## Status
This repository contains code being tested in Loop.

## For more information
Please join loop zulipchat at https://loop.zulipchat.com/

## For test workaround for InPlay pods

This experimental branch has a new "Pod Keep Alive" option under "Pod Diagnostics".
For the "Silent Tune" option to be able to play a silent tune in the background,
Loop's plist Info for "Required background modes" must be edited to include the
"App plays audio or streams audio/video using AirPlay" item (if not already present).
