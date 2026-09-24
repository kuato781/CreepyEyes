# CreepyEyes Hardware Build

This is the current hardware build guide for CreepyEyes.

It reflects the newer compact build developed while assembling FESTER: smaller sub-micro servos, direct-soldered servo wiring, a formed heat-shrink wiring loom, and a 2.5 mm ball-bearing clamp inside the pushrod connector.

> [!WARNING]
> This is not a beginner electronics project. You should already be comfortable with RC servos, small-electronics soldering and wire splicing, multimeter use, LiPo battery handling, flashing firmware to a microcontroller, and basic small-model modification and mechanical fitment.

The exact brands linked in [BOM.md](BOM.md) are what were used during development. Equivalent parts and tools are fine unless a dimension or electrical requirement is specifically called out.

## Build architecture

Each pair of glasses uses:

- 2 sub-micro servos driving the original eyelid mechanisms
- Seeed Studio XIAO ESP32-C3
- 1S 3.7 V 250 mAh LiPo
- DC-DC boost converter configured for approximately 5 V servo power
- 470 µF / 10 V capacitor across the boosted servo rail
- physical power switch
- BT2.0 battery connection
- direct-soldered servo wiring
- heat-shrink-formed loom routed across the frame
- pushrod/linkage connectors clamping the original nylon pull string

The controller and boost board are distributed along the temples rather than stacked.

## Orientation convention

**LEFT and RIGHT are now defined from the wearer's perspective.**

```text
Wearer's LEFT eye  -> D4
Wearer's RIGHT eye -> D5
```

That convention is used in the calibration sketch, production firmware, wiring documentation, and app behavior.

## Before touching electronics

Mechanically inspect the donor glasses first.

Both eyelids should open and close freely before servo installation. If one eye drags or does not fully open, fix or replace the mechanical eye assembly before calibration. A sticky donor mechanism can otherwise look like a servo, linkage, or firmware problem later.

Also test both servos on a servo tester before installing them.

## Servo preparation

The compact build uses GH-S37D-class sub-micro servos rather than the larger MG90S-style servos used in earlier builds.

The smaller servos reduce the side profile significantly and already use thin lead wire that works well with the direct-solder harness.

Optional cleanup:

- trim unused servo mounting ears to reduce bulk
- clean the cut edge carefully without cutting into the case seam

### Servo arm and linkage connector

The supplied servo arms have enough material for the existing pushrod connector.

1. Choose an arm long enough to provide easy access to the connector set screw while still clearing the frame.
2. Enlarge the servo-arm hole to approximately **2.15 mm** so the connector's smooth shoulder can rotate freely.
3. Enlarge the connector's nylon-cord hole to approximately **2 mm** as needed. A diamond Dremel bit works well on the hardened connector material; use high tool speed with low feed pressure.
4. Use the connector nut without a washer.
5. Apply only a small amount of green Loctite to the first 3-5 screw threads. Do not flood Loctite onto the plastic servo arm.
6. Tighten only enough to retain the connector while allowing the smooth shoulder to rotate freely.

The goal is **free rotation and clearance**, not simply making every hole larger.

## Nylon pull-string clamp: current method

The connector's 3 mm set screw does not reach far enough to clamp the thin nylon pull string by itself.

An earlier build used a short piece of 3D-printer filament as a spacer. That worked, but depending on how the filament slug landed, it could damage or cut the nylon string.

The current method uses a **2.5 mm steel ball bearing** inside the connector under the set screw.

The ball:

- fits the connector cleanly
- allows the set screw to clamp the nylon securely
- creates a smooth, repeatable contact surface
- did not leave visible bite marks on the nylon during destructive/reassembly testing

This supersedes the filament-slug method.

## Servo mounting

The working geometry is:

- servos on the outside of the temple frame
- output gear facing rearward
- outer edge aligned near the former stock string-guide edge
- servo body approximately 2 mm below the bottom of the frame

Use servo tape for initial positioning and mechanical testing before committing the final attachment.

Center each servo with a tester before installing the horn. Install the arm near 90 degrees inward and tension the nylon so the eyelid is roughly half closed at servo center. Final endpoints are established later with the calibration sketch.

![Build process photos](images/build-process.jpg)

## Battery and switch

The current battery is a 1S 3.7 V 250 mAh LiPo with a BT2.0 connector.

Battery leads were trimmed to about **15 mm** on the compact build.

Mount the battery as far forward as practical with removable hook-and-loop attachment. The battery remains replaceable rather than permanently glued to the glasses.

Preferred switch convention:

```text
forward  = ON
backward = OFF
```

Mount the switch as far forward and high on the lens/frame area as practical without interfering with folding or wearing the glasses.

Shoe Goo works well for permanent component attachment. Clamp parts while curing. Initial handling can happen after a couple of hours, but allow roughly 24-48 hours for a full cure before treating the bond as finished.

## Direct-solder servo harness

The compact build removes the bulky Futaba-style servo connectors entirely.

The servo leads are cut and hard-soldered into the harness. This is reasonable here because the servos are lightly loaded and a failed servo can still be serviced at the documented splice location.

A useful stagger for the three servo conductors is:

```text
black  25 mm
red    35 mm
white  45 mm
```

Staggering the joints keeps the loom from developing one large rigid bulge.

Current color mapping at the servo splice:

```text
servo black -> harness brown / ground
servo red   -> harness orange / +5 V servo rail
servo white -> harness white / signal
```

Individual joints are insulated and the harness is then bundled for routing.

## Formed heat-shrink loom

The cross-frame wiring is placed inside heat shrink, warmed, and **formed around the glasses while still warm**. Once cool, the loom naturally holds the frame shape.

This reduces the amount of tape needed: a few retention points can hold a pre-shaped loom instead of taping loose wires along the entire frame.

Current working lengths:

```text
1/8 in heat shrink:  about 50 mm per servo-lead section
3/16 in heat shrink: about 170 mm for the seven-wire main bundle
```

## Wiring

The old graphical/PDF wiring diagram is obsolete. The canonical wiring description is now textual in [WIRING.md](WIRING.md).

Do not power the servos from the XIAO 3V3 rail.

The boost converter supplies the servo rail; the XIAO and servo system share ground.

## Boost converter

The compact build uses the same small DC-DC boost board as earlier Creeps.

Configure it for approximately **5 V output** by removing the board's factory configuration jumpers/pads used for the alternate voltage presets.

Before connecting servos:

1. connect battery/input wiring
2. switch the glasses on
3. confirm the boost board's power LED
4. measure the output with a multimeter
5. verify approximately 5 V at the servo rail

Only after that should the servos be connected.

Install the **470 µF / 10 V capacitor across boost OUT+ and OUT-**, observing polarity. Trim its leads short.

The capacitor is on the 5 V servo rail, not on the XIAO battery pads.

## XIAO controller

Mount the XIAO with:

- USB connector accessible
- board parallel to the bottom of the frame
- enough clearance for servo arm/linkage movement

Signal convention:

```text
D4 -> wearer's LEFT servo signal
D5 -> wearer's RIGHT servo signal
```

Power leads can be soldered to the underside while servo signals enter from the top, keeping the package compact.

## Power-on checks

Before final assembly:

- switch OFF: no battery voltage should appear on the switched positive distribution
- switch ON: battery voltage should be present at the XIAO battery input and boost input
- boost output: approximately 5 V
- XIAO logic rail: approximately 3.3 V where expected
- common ground continuity: controller and servo system share ground

Disconnect the battery before trimming any exposed test points or conductors.

## Calibration and firmware

Do not permanently finish the wiring before calibration and full-power servo testing.

Recommended order:

1. mechanically inspect donor glasses
2. test servos with servo tester
3. mount servos and linkage
4. complete power wiring
5. verify battery and boost voltages
6. flash `CreepyEyesCalibration.ino`
7. determine LEFT OPEN / LEFT CLOSED / RIGHT OPEN / RIGHT CLOSED
8. add or update the calibration block in production firmware
9. flash `CreepyEyes.ino`
10. test BLE behavior
11. perform a full battery-powered servo test
12. finish loom routing and permanent attachment

USB power can run the XIAO and BLE logic, but the normal 5 V servo rail depends on the battery/boost system. A final test therefore needs the physical power switch ON and normal battery power.

See [../firmware/README.md](../firmware/README.md) for firmware and calibration details.

## Hardware evolution: V1 vs V2

The newer hardware architecture is primarily a packaging and serviceability refinement:

- smaller GH-S37D-class servos replace larger MG90S-style servos
- servo connectors are removed in favor of staggered direct-solder joints
- factory thin servo wire is retained where useful
- the cross-frame wiring becomes a formed heat-shrink loom
- the 2.5 mm ball-bearing clamp replaces the filament spacer
- component placement is cleaner and closer to the temple profile

![V1 vs V2 hardware comparison](images/v1-v2-comparison.jpg)

The older architecture still works; the compact build is simply the preferred pattern going forward.

## Lessons learned

A few build failures materially improved the design:

- **Check the donor eye mechanism first.** A sticky eyelid can waste time debugging electronics that are not actually at fault.
- **Continuity alone does not prove a tiny XIAO pad joint is good.** If one signal behaves strangely, reflow the solder joint before condemning the GPIO.
- **Do not use the old filament slug as the nylon clamp.** The 2.5 mm ball-bearing spacer is more repeatable and does not damage the cord in current testing.
- **Test before final Shoe Goo/tape.** Calibration, BLE, and full-power motion should all work before the packaging becomes difficult to service.
- **Form the loom while the heat shrink is warm.** The cooled loom then follows the frame naturally and requires much less tape.
