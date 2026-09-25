# CreepyEyes BOM and Shop Tools

This is the working buy list for the current compact CreepyEyes hardware build.

Prices below are snapshots from the development build and will change. Exact brands are not mandatory unless a fit or electrical requirement is called out.

## Parts that become part of the glasses

| Item | Current source / notes |
| --- | --- |
| Donor Creepy Eyes glasses | [Amazon](https://www.amazon.com/Crazy-Glasses-Blinking-Eyeball-Adults/dp/B0GT4KL9V3/) — development buy was a 4-pack |
| 2x sub-micro servos | [Amazon](https://www.amazon.com/dp/B0GTPPWXXL) — current compact-build servo; much smaller than earlier MG90S-class units |
| Seeed Studio XIAO ESP32-C3 | [Amazon](https://www.amazon.com/dp/B0DGX3LSC7) |
| 1S 3.7 V 250 mAh LiPo | [Common Sense RC](https://www.commonsenserc.com/product_info.php?products_id=4223) — removable battery |
| DC-DC step-up / boost board | [Amazon](https://www.amazon.com/dp/B0B4TB9QNY) — configure to ~5 V output |
| Pushrod / linkage connectors | [Amazon](https://www.amazon.com/dp/B01EE6W2TW) |
| 2.5 mm steel ball bearings | [Amazon](https://www.amazon.com/dp/B08KTBM74G) — current clamp spacer under the linkage set screw; tested tight with no visible bite marks on the nylon pull string |
| 470 µF / 10 V electrolytic capacitor | [Amazon](https://www.amazon.com/dp/B0C1VBXCQM) — across boost OUT+ / OUT- |
| Small slide switch | [Amazon](https://www.amazon.com/dp/B0G8W9QNBQ) |
| BT2.0 connectors | [Amazon](https://www.amazon.com/dp/B081CFXCH8) |
| 28 AWG hookup wire | red, black, orange, brown, white as used in the current loom |
| 1/8 in heat shrink | about 50 mm per servo-lead section |
| 3/16 in heat shrink | about 170 mm for the seven-wire cross-frame bundle |
| Black cloth tape | [Amazon](https://www.amazon.com/gp/product/B0DQPTC3CD) |
| White cloth tape | [Amazon](https://www.amazon.com/gp/product/B0DQPT1TL5) |
| Shoe Goo | component attachment |
| Hook-and-loop / Velcro | removable battery mounting |
| Nylon pull string | reuses/replaces the stock eyelid pull line as needed |

## Optional / legacy parts

| Item | Notes |
| --- | --- |
| JST-XH 3-pin connectors | [Amazon](https://www.amazon.com/gp/product/B0D3LVLMP9) — experimented with during development; not used in the preferred direct-solder servo architecture |
| Servo Y splitters | Not required by the current direct-solder harness. Equivalent parts may still be useful for bench work. |
| External LiPo charge board | [Amazon](https://www.amazon.com/dp/B0H6JPVCG4) — use only if it matches your battery/charging workflow and you understand 1S LiPo charging requirements |

## Useful tools

These are the tools used during the build. Equivalent tools are fine.

| Tool | Current source / purpose |
| --- | --- |
| Servo tester | Convenient for centering and mechanical checks before firmware; any standard compatible tester is fine |
| Soldering iron with suitable tips | Fine/medium conical tip for XIAO/boost pads; larger tip for power wiring |
| Multimeter | Mandatory for verifying battery, 5 V boost output, and continuity |
| Solder wick | [Amazon](https://www.amazon.com/dp/B0DRN688Q5) — convenient for changing boost-board solder jumpers |
| Modeler clamps | [Amazon](https://www.amazon.com/dp/B081HY1VGB) |
| Forceps | [Amazon](https://www.amazon.com/dp/B08Z1SV28S) |
| Diamond Dremel bits | [Amazon](https://www.amazon.com/dp/B0BVMBK8Q5) — connector/string-hole work |
| Magnetic helping hands | [Omnifixo](https://omnifixo.com/en-us) |
| Double-stick servo tape | [Amazon](https://www.amazon.com/dp/B077QMLM7C) |
| Headband magnifier | [Amazon](https://www.amazon.com/Headband-Magnifier-Head-Mounted-Binocular-Magnification-1-5X/dp/B07M7H3P95/) |
| Sprue/flush cutters | servo-ear trimming and general model work |
| Heat gun / controlled heat source | shrinking and forming the loom |
| Small hex drivers | linkage set screw and small hardware |
| Hobby knife / files | cleanup and fitment |

## Printed fixture

The repository includes a simple glasses holder used during assembly/calibration:

```text
stl-bambu-3mf/
├── creepy-glass-holder.3mf
└── creepy-glass-holder.stl
```

The fixture holds the temples open consistently while soldering, fitting linkages, calibrating, and photographing the build.

## Printed travel / storage case

The repository also includes the current 3-slot sliding-lid case used to carry the Creeps:

```text
stl-bambu-3mf/
├── CreepyEyes-3Slot-Box.3mf
├── CreepyEyes_3Slot_Box_BASE_70mm.stl
├── CreepyEyes_3Slot_Box_LID_70mm.stl
├── CreepyEyes_Lid_Overlay_NORMAL.svg
└── CreepyEyes_Lid_Overlay_MIRRORED.svg
```

The SVG files are intended for a merged lid graphic; the normal and mirrored versions support either face/orientation workflow.

![CreepyEyes case](../docs/images/creepbuild/creepcase.png)
