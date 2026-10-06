# Stackfreed

Tap today's ring to close it so the week still holds.

Stackfreed is a local habit builder for people who fail streak apps that punish one miss. You close today first. If a scheduled day already slipped, this week's one lost beat can mend that silent day. A future day cannot take it. A second mend in the same week cannot take it. An unused lost beat drops when the week turns.

Home is the ring row and the SpriteKit day timeline. Dashboard lists closed days, the week ratio, and streak. Settings edits the habit, the scheduled weekdays, contact, onboarding, and reset.

Audience: people who want one primary habit, one weekly grace that still counts, and no social layer.

## Architecture

The Remontoire is a closed ADT with Open, Beaten, and Mended. A fourth case is a defect. The Arbor is a fold over Pallets keyed as Int YYYYMMDD. Beat samples the open Pallet for today, writes a BeatMark, and folds Open to Beaten. Mend writes a LostMark when the tapped Pallet is an empty scheduled day and this week still holds a LostBeat. Mend on a future Pallet is refused. A second Mend while the week already holds a LostMark is refused. An empty Arbor writes Hollow.

This shape fits the product because a day is not a bool. Open, closed, and mended-miss are three states that must stay distinct so a mended miss still counts toward completed over scheduled, while a future day cannot be parked. One observable Remontoire store owns every fold. Views call `beatToday` and `mendPallet` and never keep a parallel flag.

UserDefaults plus Codable projects a `RemontoireDocument` under `skf.arbor.v1`. Memory on the store is the source of truth.

## Lost-beat mend

This is the reason to pick Stackfreed over a streak wheel that lets you park grace in advance.

1. Close today with the ring row or today's ring.
2. Miss a scheduled day.
3. Tap that silent past day to spend this week's lost beat.
4. The miss still counts. Tomorrow refuses. A second mend this week refuses.

The twist has its own Lost beat page plus the silent days you can mend on Rings.

## Art

Claymation claymorphism collage. Thumb-pressed clay volumes with stop-motion fingerprints and visible join seams, cut-paper collage layers stacked in shallow relief, studio tabletop lighting, solid clay subject, not glass, not wire, not a hollow vitrine, no lettering.

Prompts used for every asset:

- `skf_AppIcon`: Clay remontoire ring emblem filling the canvas edge to edge, claymation claymorphism collage, solid clay, no lettering, no rounded-corner treatment, no drop shadow outside the canvas, no alpha.
- `skf_Splash`: Vertical claymation collage of a week of clay pallets with a quiet uncluttered centre band, claymorphism 3D, no lettering.
- `skf_Onboarding1`: Isolated clay figure reaching toward a clay ring on a tabletop, claymation collage, solid subject, no lettering.
- `skf_Onboarding2`: Isolated clay finger closing today's ring mid-press, claymation claymorphism, solid clay, no lettering.
- `skf_Onboarding3`: Isolated clay week of closed rings with one mended silent pallet, claymation collage, solid clay, no lettering.
- `skf_EmptyHome`: Isolated unused clay ring waiting on a table, solid clay not glass, claymation claymorphism, no lettering.
- `skf_EmptyList`: Isolated empty clay ledger leaf, claymation collage, solid clay, no lettering.
- `skf_CardBackdrop`: Abstract claymation collage field of pressed clay slabs and torn paper scraps, low contrast, fill the canvas, no lettering.
- `skf_ControlFace`: Isolated clay ring face for today's close control, claymation claymorphism, solid clay, no lettering.
- `skf_TwistHero`: Isolated silent clay pallet receiving a lost-beat clay token, claymation collage, solid clay, no lettering.
- `skf_SuccessMark`: Isolated clay closed-ring confirmation stamp, claymation claymorphism, solid clay, no lettering.
- `skf_HeaderDecor`: Wide claymation collage band of stacked clay rings and paper scraps, solid clay ornaments, no lettering.

## How this is not a repeat

Falspark already owns habit_rings as a week wheel whose home verb is dragging a false-ring onto a day you plan to miss. Stackfreed keeps one primary habit and one weekly rest that still counts, but the home verb is tap-to-close on a ring row plus a SpriteKit day timeline. Grace is spent only on a day that has already slipped. There is no three-tab bar, no scanner, and no catalog.

## Build

```bash
cd Stackfreed
xcodegen generate
xcodebuild -scheme Stackfreed -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO build
xcodebuild -scheme Stackfreed -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO build-for-testing
```

Simulator demo seed is one-shot behind `skf.demo.v1`. Launch arguments `-ReviewScreen today|log|goals` are read once after onboarding. They are not tabs.
