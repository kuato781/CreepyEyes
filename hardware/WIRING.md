# CreepyEyes Wiring — Current Textual Reference

This file replaces the older graphical/PDF wiring diagram.

**LEFT and RIGHT are defined from the wearer's perspective.**

```text
Wearer's LEFT servo signal  -> D4
Wearer's RIGHT servo signal -> D5
```

## Power topology

```text
1S LiPo (+)
    |
    +--> physical switch -->+--> XIAO BAT+
                            |
                            +--> Boost IN+

1S LiPo (-) ----------------+--> XIAO BAT-
                            |
                            +--> Boost IN-

Boost OUT+ (~5 V) ----------+--> LEFT servo +
                            +--> RIGHT servo +

Boost OUT- -----------------+--> LEFT servo ground
                            +--> RIGHT servo ground

470 µF / 10 V capacitor:
    + lead -> Boost OUT+
    - lead -> Boost OUT-
```

The XIAO and servo system therefore share a common ground, but the servos are powered from the boosted ~5 V rail — **not** from the XIAO 3V3 pin.

## Servo signals

```text
Wearer's LEFT servo signal  -> XIAO D4
Wearer's RIGHT servo signal -> XIAO D5
```

## Current wire-color convention

At the direct-solder servo splice:

```text
servo black -> harness brown -> servo ground / Boost OUT-
servo red   -> harness orange -> servo +5 V / Boost OUT+
servo white -> harness white  -> servo signal
```

For the second servo, black/red/white conductors may remain black/red/white where convenient; electrical function matters more than matching colors. Keep the loom documented and verify every conductor before soldering.

## Working cut lengths from the compact build

These are build-specific working lengths, not universal electrical requirements:

```text
Battery leads:                    ~15 mm
Red/black battery -> boost:      ~300 mm
Red/black battery -> controller: ~380 mm
Orange/brown servo power run:    ~300 mm
White servo signal run:          ~380 mm

Servo splice stagger:
  black: ~25 mm
  red:   ~35 mm
  white: ~45 mm
```

Trim only after dry-fitting the actual glasses. Different donor frames or component placement may require different lengths.

## Heat-shrink loom

```text
1/8 in heat shrink:  ~50 mm on servo-lead sections
3/16 in heat shrink: ~170 mm around the seven-wire main bundle
```

Warm the cross-frame shrink tube and form it to the frame while still pliable. Once cool it retains the curve and needs only a few cloth-tape retention points.

## Boost converter setup

The boost board used during development ships configured for a different voltage range/preset. Reconfigure it for approximately **5 V output** by removing the appropriate factory solder jumpers/pads used on this board.

Always confirm actual output with a multimeter before connecting servos.

```text
Expected:
Battery input: ~3.7-4.2 V depending on charge state
Boost output:  ~5 V
```

## Capacitor

Install the 470 µF / 10 V electrolytic capacitor directly across the servo rail:

```text
capacitor + -> Boost OUT+
capacitor - -> Boost OUT-
```

Observe polarity. Keep leads short.

The boost LED may remain lit briefly after switch-off while the capacitor discharges; that is normal for this build.

## Final checks before connecting servos

1. Battery disconnected: inspect for shorts and solder bridges.
2. Switch OFF: verify switched positive is dead.
3. Switch ON: verify battery voltage at XIAO BAT and boost input.
4. Verify boost output is approximately 5 V.
5. Verify controller/servo grounds are common.
6. Connect servos only after the power rails check out.
7. Perform final servo motion testing with normal battery power; USB alone does not represent the completed 5 V servo-power path.
