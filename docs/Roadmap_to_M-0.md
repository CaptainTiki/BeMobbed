## Incremental Roadmap to M-0

Each build should be small, testable, and leave the project runnable.

---

# Build 0.1 — Project Shell + Main Scene

## Goal

Create the basic runnable project scene and folder structure.

## Tasks

- Create `main.tscn`.
- Add a root `Main` node.
- Add placeholder `World`, `Player`, `UI`, and `Managers` nodes.
- Add a simple directional light and camera placeholder.
- Confirm project boots into `main.tscn`.

## Test

Run project. Empty scene loads without errors.

## Done When

The project opens into a stable main scene with no gameplay yet.

---

# Build 0.2 — First-Person Dev Camera

## Goal

Implement flying camera movement for Dev Mode testing.

## Tasks

- Create `player_controller.tscn`.
- Add `CharacterBody3D` or camera rig.
- Add `Camera3D`.
- Implement mouse look.
- Implement WASD movement.
- Implement fly up/down.
- Implement fast movement modifier.
- Add mouse capture toggle if needed.

## Controls

```text
WASD = move
Mouse = look
Space = up
Ctrl = down
Shift = fast move
Esc = release mouse
```

## Test

Run scene and fly around empty space smoothly.

## Done When

We can navigate the world freely and inspect from any angle.

---

# Build 0.3 — Dev Mode Manager

## Goal

Add a centralized Dev Mode state.

## Tasks

- Create `DevModeManager` as autoload or scene manager.
- Add `dev_mode_enabled` flag.
- Add signal/event for Dev Mode toggled.
- Bind `F1` to toggle Dev Mode.
- Show small on-screen label: `DEV MODE ON/OFF`.

## Test

Press F1 and see Dev Mode toggle.

## Done When

Systems can ask whether Dev Mode is active.

---

# Build 0.4 — World Grid Data

## Goal

Create the grid data model for terrain/pathing.

## Tasks

- Create `WorldGrid` script.
- Define grid size, e.g. 64x64.
- Store cell data:
  - height
  - walkable
  - buildable
  - slope_type
  - occupied
  - path_cost
- Add helper methods:
  - `is_in_bounds(cell)`
  - `get_cell(cell)`
  - `get_height(cell)`
  - `is_walkable(cell)`
  - `is_buildable(cell)`
  - `set_occupied(cell, value)`

## Test

Print grid initialization summary on run.

## Done When

The world has queryable terrain data even before visuals are pretty.

---

# Build 0.5 — Simple Terrain Visuals

## Goal

Render the test terrain from grid data.

## Tasks

- Generate or instantiate simple cell visuals.
- Flat cells appear at their height.
- Blocked cells visibly different.
- Ramp/slope cells visibly different if included.
- Add a first rough test arena layout.

## M-0 Terrain Layout Minimum

- Flat area.
- Raised area.
- Ramp/slope route.
- 2-block cliff/blocked edge.
- Choke route.

## Test

Fly around and visually inspect terrain.

## Done When

We have a visible terrain test arena with height/blocking/slope variety.

---

# Build 0.6 — Grid Overlay

## Goal

Add first debug overlay.

## Tasks

- Create grid overlay renderer.
- Draw cell boundaries over terrain.
- Toggle overlay with key or Dev Panel.

## Test

Toggle grid overlay on/off.

## Done When

We can see the block grid clearly while flying.

---

# Build 0.7 — Walkable / Blocked Overlay

## Goal

Visualize terrain walkability.

## Tasks

- Draw overlay colors for:
  - walkable cells
  - blocked terrain
  - slope/ramp cells
  - out-of-bounds if useful
- Ensure overlay uses `WorldGrid` queries, not duplicate logic.

## Test

Confirm overlay matches test arena logic.

## Done When

We can see what mobs should consider pathable vs blocked.

---

# Build 0.8 — Build Definitions + Catalog

## Goal

Create data definitions for placeable blocks.

## Tasks

- Create `BuildDefinition` resource/script.
- Create definitions for:
  - wall block
  - ramp block
  - placeholder turret
  - test core
- Create `BuildCatalog` that exposes available definitions.

## Test

Print catalog contents on run.

## Done When

Placeable blocks are data-driven enough for M-0.

---

# Build 0.9 — Placement Ghost + Grid Snap

## Goal

Preview block placement on the terrain grid.

## Tasks

- Add raycast from camera to terrain.
- Convert hit position to grid cell.
- Show ghost mesh at snapped cell.
- Allow cycling selected build definition with number keys or temporary UI.
- Rotate ghost if relevant.
- Tint valid/invalid if possible.

## Test

Look at ground and see ghost snap to cells.

## Done When

Selected block previews correctly on the terrain grid.

---

# Build 0.10 — Placement Validation

## Goal

Validate whether objects can be placed.

## Tasks

- Check in-bounds.
- Check terrain buildable.
- Check occupied cells.
- Check flatness/slope requirements.
- Check footprint dimensions.
- Add debug reason string for invalid placement.

## Test

Try placing on blocked terrain, occupied cells, slopes, and valid ground.

## Done When

The system can clearly accept/reject placement.

---

# Build 0.11 — Place and Remove Wall Blocks

## Goal

Actually place blocks and update occupancy.

## Tasks

- Left click places selected block if valid.
- Placed object instantiates scene.
- Occupancy grid updates.
- Right click or delete tool removes placed object.
- Occupancy clears on removal.

## Test

Place walls, remove walls, inspect occupancy.

## Done When

Walls become real blockers in grid data.

---

# Build 0.12 — Occupancy Overlay

## Goal

Visualize placed-object occupancy.

## Tasks

- Draw overlay for occupied cells.
- Differentiate terrain blocked vs occupied blocked.
- Update overlay after placement/removal.

## Test

Place/remove wall and watch overlay update.

## Done When

We can see exactly which cells placed blocks claim.

---

# Build 0.13 — Test Core / Target Beacon

## Goal

Add a target for mobs to path toward.

## Tasks

- Create `test_core.tscn`.
- Place it in the arena.
- Mark its footprint occupied or targetable as needed.
- Register target cell with pathing system.

## Test

Core appears and reports target position.

## Done When

The world has a clear mob destination.

---

# Build 0.14 — Flow Field Data Build

## Goal

Generate a cost/distance field from the target over the grid.

## Tasks

- Create `FlowField` script.
- Use target cell as source.
- Flood-fill / Dijkstra over valid neighbors.
- Respect blocked terrain and occupancy.
- Apply basic path costs:
  - flat = 1
  - slope = 2
- Store cell score/distance.
- Store unreachable cells.

## Test

Print reachable cell count and unreachable count.

## Done When

Flow field can calculate terrain-aware reachability.

---

# Build 0.15 — Flow Field Score Overlay

## Goal

Visualize the flow field cost/distance scores.

## Tasks

- Draw color-coded cells based on score.
- Blocked/unreachable cells have distinct visual states.
- Optional numeric labels for scores near camera.

## Test

Generate field and inspect heatmap.

## Done When

We can see the cost/distance field from target outward.

---

# Build 0.16 — Flow Field Direction Overlay

## Goal

Show direction arrows for each pathable cell.

## Tasks

- For each reachable cell, find best neighbor toward lower score.
- Draw arrow on cell top.
- Update when field rebuilds.

## Test

Place walls and rebuild field. Arrows should route around obstacles.

## Done When

We can see the invisible river mobs will follow.

---

# Build 0.17 — Basic Crawler Scene

## Goal

Create the first mob scene.

## Tasks

- Create `basic_crawler.tscn`.
- Add simple mesh/capsule placeholder.
- Add collision.
- Add health value.
- Add basic state enum:
  - spawning
  - moving
  - attacking
  - dead

## Test

Spawn one crawler manually in scene.

## Done When

Crawler exists as an entity ready for movement.

---

# Build 0.18 — Crawler Movement Using Flow Direction

## Goal

Make one crawler move toward target using flow field.

## Tasks

- Convert crawler world position to grid cell.
- Query flow direction for current cell.
- Move crawler toward direction.
- Snap/follow terrain height.
- Stop near target.

## Test

Place crawler in different arena locations and watch it move toward core.

## Done When

One mob can navigate rough terrain toward the target.

---

# Build 0.19 — Crawler Spawn From Ground

## Goal

Make mob spawning feel better than pop-in.

## Tasks

- Spawn crawler slightly below ground.
- Animate/move upward over short duration.
- Activate movement after emergence.

## Test

Spawn crawler and watch emerge from terrain.

## Done When

Mob spawn has basic visual dread.

---

# Build 0.20 — Horde Manager + Spawn Controls Backend

## Goal

Create system to spawn many mobs.

## Tasks

- Create `HordeManager`.
- Add `mob_count` setting.
- Add `spawn_rate` setting.
- Add `start_horde()`.
- Add `stop_spawning()`.
- Add `kill_all_mobs()`.
- Track live mobs.

## Test

Use temporary keybinds to spawn 10/50/100 mobs.

## Done When

Backend horde spawning works without UI polish.

---

# Build 0.21 — Dev Horde Panel

## Goal

Add UI controls for mob testing.

## Tasks

- Create Dev Panel.
- Add mob count field with +/-.
- Add spawn rate field with +/-.
- Add Start Horde button.
- Add Stop Spawning button.
- Add Kill All Mobs button.
- Add live mob count display.

## Test

Use panel to spawn and kill mobs.

## Done When

Mob stress testing can be controlled in-game.

---

# Build 0.22 — Basic Mob Separation

## Goal

Prevent mobs from perfectly stacking.

## Tasks

- Add local neighbor query.
- Apply separation force against nearby mobs.
- Clamp max separation force.
- Keep horde movement stable.

## Test

Spawn 50 mobs in a stream and watch clumping behavior.

## Done When

Mobs retain horde feel without becoming one blob.

---

# Build 0.23 — Wall Interaction

## Goal

Mobs should route around walls placed by the player.

## Tasks

- Ensure wall placement updates occupancy.
- Ensure flow field rebuild respects wall occupancy.
- Ensure mobs use updated flow directions.
- Add manual rebuild if automatic is not ready.

## Test

Place wall line with one gap. Spawn mobs. They should funnel through gap.

## Done When

Player-placed walls reshape mob movement.

---

# Build 0.24 — Placeholder Turret

## Goal

Add first defense interaction.

## Tasks

- Create turret scene.
- Place turret through build system.
- Add range.
- Find nearest mob.
- Deal damage over time or hitscan shots.
- Kill mobs.
- Add simple visual feedback.

## Test

Place turret and spawn mobs. Turret kills approaching mobs.

## Done When

The horde can be thinned by a placed defense.

---

# Build 0.25 — Turret Range Overlay

## Goal

Visualize turret coverage.

## Tasks

- Draw range circle/sphere when overlay enabled.
- Optional: show current target line.

## Test

Place several turrets and toggle range overlay.

## Done When

We can inspect defensive coverage quickly.

---

# Build 0.26 — Mob Attack Target / Core Damage Placeholder

## Goal

Mobs interact with the target instead of only reaching it.

## Tasks

- Add simple HP to Test Core.
- Mobs entering attack range deal damage over time.
- Dev Mode can reset/repair core.
- Optional: if core reaches 0, print failure.

## Test

Spawn mobs with no turrets. Core takes damage.

## Done When

Mobs are a threat, even if loss screen is not implemented.

---

# Build 0.27 — Performance Readout

## Goal

Expose test metrics.

## Tasks

- Show live mob count.
- Show spawned total.
- Show killed total.
- Show FPS.
- Optional frame time.
- Optional flow rebuild time.

## Test

Spawn increasing mob counts and watch stats.

## Done When

We can begin measuring horde limits.

---

# Build 0.28 — M-0 Test Pass and Tuning

## Goal

Use the testbed to find early limits and failure modes.

## Tasks

Run tests:

- 10 mobs, no walls.
- 50 mobs, no walls.
- 100 mobs, no walls.
- 100 mobs with wall funnel.
- 250 mobs with wall funnel.
- 100 mobs over slope route.
- 100 mobs near cliff/blocked route.
- 100 mobs against turret.
- 250 mobs against multiple turrets.

Record:

- FPS.
- Mob clumping.
- Pathing failures.
- Stuck spots.
- Turret targeting issues.
- Overlay usefulness.
- Dread/feel notes.

## Done When

We know the first major bottlenecks and can decide the next milestone.

---

## M-0 Final Checklist

M-0 is complete when all are true:

- [ ] Dev Mode toggle exists.
- [ ] Flying camera works.
- [ ] Test terrain includes height, blocked terrain, and slopes/ramps.
- [ ] World grid stores terrain/path data.
- [ ] Placement grid works.
- [ ] Wall block can be placed and removed.
- [ ] Occupancy updates from placed blocks.
- [ ] Test core/target exists.
- [ ] Flow/path field builds from target.
- [ ] Flow field respects terrain and occupancy.
- [ ] Flow direction arrows can be displayed.
- [ ] Flow score/cost heatmap can be displayed.
- [ ] Walkable/blocked/occupancy overlays exist.
- [ ] Basic crawler exists.
- [ ] Crawler spawns from ground.
- [ ] Crawler moves toward target using path/flow logic.
- [ ] Horde Manager can spawn many crawlers.
- [ ] Dev Panel controls mob count and spawn rate.
- [ ] Kill all mobs works.
- [ ] Basic separation prevents total stacking.
- [ ] Placeholder turret can be placed.
- [ ] Turret attacks/kills mobs.
- [ ] Turret range overlay exists.
- [ ] Core can receive placeholder damage.
- [ ] Live mob count/FPS stats visible.
- [ ] We have run increasing horde tests and documented limits.