# Night Brew Cafe

Godot 4 / GDScript mobile-first MVP for a top-down coffee-shop management game. It has no web, HTML, or external-art dependency.

## Run

1. Open this folder in Godot 4.3+ using **Import**.
2. Press **F6/F5**; the entry scene is `scenes/Main.tscn`.
3. Press **Open / Close** to begin a short simulated business day. Customers enter, occupy a table, order, wait for the barista and waiter, drink, pay, and leave. If ingredients are depleted or patience expires, they leave unhappy.

## Scene and script map

- `scenes/Main.tscn` — project entry scene.
- `scripts/main.gd` — day cycle, orders, employee dispatch, UI, upgrades, panels, and persistence coordination.
- `scripts/cafe_world.gd` — replaceable grid-floor shop layout and visual placeholder furniture. This is the intended seam for a future TileMap.
- `scripts/cafe_actor.gd` — common movement and placeholder-character drawing for visible people.
- `scripts/customer.gd` — customer state machine and patience.
- `scripts/staff.gd` — employee attributes, roster data, and work state display.
- `scripts/save_system.gd` — local JSON save/load at `user://night_brew_save.json`.

## MVP controls

- **Open / Close** begins or settles a day. The full chain is visible: queue → seating → order → brewing → delivery → drinking → payment → dirty table → cleaning.
- **Spawn**, **×1 / ×2 / ×4** are development tools for observing the live simulation.
- **Machine +** visibly reduces brew time. **Tables +** raises usable table capacity from four to five.
- **Staff** opens the roster. Tapping a row assigns/unassigns that employee. The SSS manager, **夜班经理·星野澪**, has a highlighted detail card; taking her on duty activates a night-blue store effect, gold VIP guests, and double guest revenue.
- **Reset Save** removes the local JSON save and resets the in-memory business state.

## Android APK later

Install Godot's Android build template and configure the Android SDK/JDK in **Editor Settings → Export → Android**. Then choose **Project → Export**, add an Android preset, set the package ID/signing credentials, and export an APK or AAB. The project uses a 1080×1920 portrait base viewport and canvas stretching for phone screens.

## Next production step

Replace the placeholder drawings with a formal portrait art kit and a TileMap navigation layer first. It will make the management loop readable before expanding employee training and the gold-based talent market.
