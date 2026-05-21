# Working GDD + Roadmap to Milestone Zero

## Project Working Title

**Working title:** _Company Town_ / _Quotafall_ / _Hazard Pay_ / _Deep Asset_ / _Extraction Liability_

For now, this document refers to the game as **Project Quota**.

## High Concept

**Project Quota** is a first-person voxel base-defense mining game where the player is sent by a dystopian corporation to extract valuable ore from hostile frontier worlds. The player explores, mines, builds defenses, and survives escalating hordes of hostile creatures while trying to meet company extraction quotas.

The core twist is that the ore the player extracts is both:

1. **The goal** — ore must be banked to meet the quota / win the run.
2. **The temptation** — ore can also be spent on walls, turrets, power systems, blocks, gear, and survival tools.

This creates a central tension:

> Do I spend ore to survive longer, or bank ore to finish the job?

The player is not a hero. They are an under-equipped corporate contractor, dropped into terrible conditions with insufficient support, offered just enough “company store” upgrades to keep coming back.

## Design Pillars

### 1. The Horde Must Feel Dangerous

The game lives or dies by mob pressure. The first major technical focus is mob tech: enemy count, pathing, movement feel, dread, and performance.

The player should feel pressure before direct combat begins:

- Mobs emerging from the ground.
- Distant sounds before visual contact.
- Movement on the horizon.
- Turrets spinning up.
- Flowing enemy paths around terrain and walls.
- The sense that a bad base layout is about to be punished.

### 2. The Player Shapes the Battlefield

The player builds on a block grid and alters terrain. Enemies navigate across the terrain using pathing / flow-field style behavior.

Player choices should matter spatially:

- Walls redirect enemies.
- Ramps open paths.
- Trenches block or slow enemies.
- Gates create dramatic timing pressure.
- Turrets define kill zones.
- Bad layouts create failure.

### 3. Grid Truth, Flexible Art

Gameplay uses whole-block grid logic. Art can cheat visually.

Example:

- A wind turbine may claim a **2x2x4** gameplay footprint.
- Its actual mesh may be only 1.8 blocks wide and 3.2 blocks high.
- Placement, pathing, occupancy, collision, saving, and validation use the footprint.
- The mesh is only the visual representation.

This keeps gameplay readable and systems sane while allowing better-looking assets.

### 4. Dev Mode From Day One

The game needs a built-in **Dev Mode** for rapid testing.

Dev Mode is not player-facing Creative Mode yet. It is a development toolset:

- Fly movement.
- No damage/death.
- Free block placement.
- Terrain raise/lower/dig tools.
- Spawn mobs.
- Adjust spawn rate/count.
- Kill all mobs.
- Toggle debug overlays.
- Force win/loss later.

Dev Mode lets us enter a run, build a test layout, spawn enemies, stress the horde system, and quickly find what works.

### 5. Test the Real Terrain Problem Early

Milestone Zero should not be a flat parking lot. The mob testbed must include:

- Flat ground.
- Height differences.
- Slopes / ramps.
- Blocked terrain.
- Placed walls.
- Turrets.
- Choke points.

Mobs must be tested against the actual terrain/pathing problems the game depends on.

## Tentative Theme

### Dystopian Corporate Mining Contractor

The player works for a ruthless corporation that sends contractors into dangerous extraction zones. The corporation frames everything as opportunity, productivity, and rewards, while clearly exploiting the worker.

Possible tone:

- Darkly comedic.
- Industrial sci-fi.
- Hazardous working conditions normalized by corporate language.
- Player progression tied to a company rewards / swag store.
- “Benefits” and “upgrades” are sold back to the worker.

The player may earn company scrip, reward points, or quota bonuses, then spend them in a company store on:

- New block types.
- Turret skins.
- Worksite equipment.
- Mining tech.
- Survival tools.
- Corporate-approved cosmetics.
- Questionable “safety” upgrades.

### Possible Naming Flavor

- Hazard Pay
- Quotafall
- Deep Asset
- Company Town
- Extraction Liability
- Ore Else
- Unpaid Overtime
- The Swag Store
- Hostile Worksite
- Breach of Contract

The tone should avoid becoming pure comedy. The best target is probably:

> funny corporate cruelty layered over genuinely tense survival defense.

## Core Game Loop: Long-Term Vision

1. Start at a deployable base/core.
2. Use ore finder/scanner to locate valuable deposits.
3. Travel across hostile terrain.
4. Dig/excavate or deploy mining tools.
5. Extract ore over time.
6. Haul ore back to base.
7. Decide whether to bank ore toward quota or spend it on defenses/tools.
8. Build walls, turrets, gates, traps, power systems, and logistics.
9. Horde attacks begin.
10. Enemies path across terrain toward the base/core.
11. Player survives, repairs, rebuilds, and adapts.
12. Meet quota / extract objective ore / escape.

## Initial Milestone Philosophy

We are not building the full game first.

We are building a **testing suite** that proves the core technical fantasy:

> Can we place blocks on rough terrain, spawn increasingly large hordes, watch them path around obstacles, interact with walls/turrets, and identify performance/design limits?

Milestone Zero is a mob testing ground, not a complete survival/mining loop.

## Milestone Zero Definition

### M-0 Name

**M-0: Horde Testbed**

### M-0 Goal

Create the smallest useful development sandbox for testing:

- Terrain traversal.
- Terrain height/blocking/slope rules.
- Dev fly movement.
- Grid-based block placement.
- Mob spawning.
- Spawn rate/count controls.
- Mob movement/pathing.
- Walls and turret interaction.
- Debug overlays.
- Horde performance limits.

### M-0 Success Criteria

M-0 is complete when we can:

1. Load a test map with rough terrain.
2. Fly around in Dev Mode.
3. Place walls and turrets on a grid.
4. See placement/occupancy rules working.
5. Spawn mobs from the ground.
6. Adjust mob count and spawn rate.
7. Watch mobs route toward a target using terrain-aware pathing.
8. Watch mobs respect walls, blocked terrain, slopes, and cliffs.
9. Watch turrets target and kill mobs.
10. Toggle debug overlays for grid, blocked cells, pathable cells, occupancy, flow direction, and cost/distance scores.
11. Stress-test increasing horde sizes until the game visibly struggles.

### M-0 Is Not

M-0 does **not** require:

- Mining.
- Ore scanner.
- Inventory/backpack.
- Company store.
- Resource economy.
- Save/load.
- Day/night.
- Full wave director.
- Polished UI.
- Pretty terrain textures.
- Final art.
- Real base progression.
- Full player health/damage loop.

## World and Grid Design

### Block Scale

Assume:

- 1 block = 1 meter-ish.
- Placement happens in whole block increments.
- Structures claim integer grid footprints.
- Terrain cells are addressed by integer X/Z coordinates.

### World Cell Data

Each terrain cell should eventually support:

```text
cell_x
cell_z
height
terrain_type
walkable
buildable
slope_type
occupied
occupant_id
path_cost
```

For M-0, minimum useful fields:

```text
cell_x
cell_z
height
walkable
buildable
slope_type
occupied
path_cost
```

### Terrain Types for M-0

M-0 terrain should include:

- Flat walkable ground.
- Raised walkable ground.
- Ramp/slope cells.
- Cliff/blocked edges.
- Fully blocked cells.

### Height/Traversal Rules

Initial simple traversal rule:

```text
height difference 0 = walkable
height difference 1 = walkable if slope/ramp allows it
height difference 2+ = blocked/cliff
occupied by wall/building = blocked
closed gate = blocked later
open gate = walkable later
```

This rule is intentionally simple. It gives us enough structure to debug mobs early.

## Terrain Approach for M-0

### Recommendation

Use a hand-authored or simple generated rough test arena first.

Do not build the full terrain editor before mobs.

M-0 terrain should be enough to test:

- Slope traversal.
- Blocked terrain.
- Choke points.
- Height differences.
- Mob routing.
- Wall placement.
- Turret testing.

### M-0 Test Arena Layout

Suggested layout:

```text
[Mob Spawn Zone]
      |
  open field
      |
  slope/ramp section
      |
  blocked cliff / high ground
      |
 trench or choke point
      |
 base/core/player test area
```

Also include a side “pathing torture strip” with:

- 1-block ramp.
- 2-block cliff.
- Narrow bridge/choke.
- Dead-end pocket.
- Wall maze.
- Raised platform.
- Blocked island.

## Structure Placement Design

### Block Definitions

All placeable objects should be described by data/resources.

Minimum fields:

```text
id
display_name
scene_path
footprint_width
footprint_depth
footprint_height
blocks_movement
blocks_building
requires_flat_ground
allowed_on_slope
category
```

### M-0 Placeables

Minimum placeable objects:

1. **Wall Block**
   - Footprint: 1x1x1
   - Blocks movement.
   - Blocks building.
   - Used to test mob rerouting.

2. **Ramp Block**
   - Footprint: 1x1x1
   - Walkable transition.
   - Used to test slope traversal and player-created paths.

3. **Placeholder Turret**
   - Footprint: 1x1x1 or 2x2x1.
   - Blocks movement at base.
   - Targets nearest mob in range.
   - Deals simple damage.
   - No ammo/power yet.

4. **Test Core / Target Beacon**
   - Footprint: 2x2 or 3x3.
   - Mobs path toward it.
   - Can have HP later.
   - For M-0, it can simply be the pathing destination.

### Placement Rule

All placement must go through one placement pipeline.

Normal mode later:

```text
validate placement
check inventory/cost
place object
consume resources
update occupancy
rebuild pathing/flow field
```

Dev Mode M-0:

```text
validate placement
skip inventory/cost
place object
update occupancy
rebuild pathing/flow field
```

Dev Mode bypasses cost. It should not bypass reality.

## Dev Mode Design

### Purpose

Dev Mode is the rapid testing layer.

It allows us to build test scenarios, spawn mobs, inspect routing, and find performance limits without playing the full game loop.

### M-0 Dev Mode Features

Required:

- Toggle Dev Mode.
- Flying camera/player movement.
- Fast movement modifier.
- Place blocks without inventory/cost.
- Remove placed blocks.
- Start horde.
- Stop spawning.
- Kill all mobs.
- Set mob count.
- Set spawn rate.
- Toggle overlays.
- Rebuild flow field/path field.

Nice-to-have:

- Pause/unpause mobs.
- Spawn one mob.
- Spawn preset groups: 10 / 50 / 100 / 250 / 500.
- Reset test arena.
- Toggle turret ranges.
- Toggle mob debug labels.

### Suggested Dev Controls

```text
F1 = Toggle Dev Mode
F2 = Toggle fly/no-clip movement
F3 = Cycle overlay mode
F4 = Toggle overlay visibility
F5 = Rebuild flow field
F6 = Start horde
F7 = Stop spawning
F8 = Kill all mobs
PageUp = Increase mob count
PageDown = Decrease mob count
Shift + PageUp = Increase spawn rate
Shift + PageDown = Decrease spawn rate
```

These can change. The point is fast iteration.

## Dev UI Panel

M-0 should include a simple Dev Panel.

Suggested panel fields:

```text
DEV MODE

Mob Count:    [-] 100 [+]
Spawn Rate:   [-] 20/sec [+]
Spawn Mode:   [Burst / Stream]

[Start Horde]
[Stop Spawning]
[Kill All Mobs]
[Rebuild Flow Field]

Overlays:
[ ] Grid
[ ] Walkable
[ ] Blocked
[ ] Occupancy
[ ] Flow Arrows
[ ] Flow Scores
[ ] Turret Ranges
[ ] Mob Debug

Stats:
Live Mobs: 0
Spawned Total: 0
Killed Total: 0
FPS: 0
Frame Time: 0 ms
```

The UI can be ugly. It just needs to work.

## Debug Overlay Design

Debug overlays are first-class M-0 tools.

### Required Overlays

1. **Grid Overlay**
   - Shows cell boundaries.

2. **Walkable / Pathable Overlay**
   - Shows cells mobs can path through.

3. **Blocked Terrain Overlay**
   - Shows terrain that blocks movement.

4. **Occupancy Overlay**
   - Shows cells blocked by placed structures.

5. **Flow Field Direction Overlay**
   - Shows arrows indicating movement direction per cell.

6. **Flow Field Score/Cost Overlay**
   - Color-codes cells by distance/cost/score.
   - Helps explain why mobs choose certain routes.

7. **Turret Range Overlay**
   - Shows attack radius for placed turrets.

8. **Mob Debug Overlay**
   - Optional labels/markers for current cell, target, state, stuck flag, or path state.

### Critical Rule

Overlays must visualize the same data that gameplay uses.

If mobs use `WorldGrid.is_walkable(cell)`, the overlay should use that exact query.

If mobs use `FlowField.get_direction(cell)`, the overlay should draw that exact direction.

No duplicate fake debug logic.

## Mob Design for M-0

### M-0 Enemy: Basic Crawler

The first mob should be simple but scary in groups.

Basic properties:

```text
low health
medium speed
short attack range
ground movement only
uses terrain-aware pathing / flow direction
can be spawned in large numbers
```

### M-0 Mob States

Minimum state machine:

```text
Spawning
MovingToTarget
Attacking
Dead
```

Optional states later:

```text
Stuck
Repathing
Emerging
Staggered
Avoiding
```

### Spawn Behavior

Mobs should spawn from the ground instead of popping into existence.

Simple M-0 version:

1. Mob starts slightly below ground.
2. Rises over 0.5–1.0 seconds.
3. Becomes active.
4. Starts moving toward target.

This small effect adds major dread.

### M-0 Movement

Movement should initially prioritize stability and debugability over perfect natural motion.

Possible first approach:

- Use grid cell target / flow direction.
- Mobs move from current position toward next cell direction.
- Y position follows terrain height.
- Basic separation to prevent perfect stacking.
- If no valid direction, mob marks itself stuck or attacks nearby blocker.

### Separation / Crowd Behavior

M-0 should include at least basic local separation.

Goals:

- Mobs should not occupy one exact blob.
- Mobs should still feel like a horde.
- They should not deadlock instantly in chokepoints.

Initial separation rule:

```text
nearby mob within separation_radius applies push force
push force increases strongly as distance gets smaller
limit max push force to prevent explosion
```

This can be rough. We are testing limits.

## Pathing / Flow Field Direction

### Why Flow Fields

The long-term game wants potentially large hordes. Per-mob A* may become expensive and produce inconsistent swarm behavior. Flow fields let many mobs share pathing data toward a common target.

### M-0 Flow Field Concept

For the current target/core:

1. Build a cost/distance field over the grid.
2. Block invalid cells.
3. Assign each reachable cell a score/distance to target.
4. For each cell, compute the best neighbor direction with lower score.
5. Mobs read their current cell's direction and move that way.

### M-0 Rebuild Triggers

Rebuild the flow field when:

- A wall/block is placed.
- A wall/block is removed.
- Terrain height changes later.
- The target/core moves, if applicable.
- The user presses Dev Mode rebuild.

For M-0, manual rebuild button is acceptable even if automatic rebuild is also implemented.

### M-0 Path Cost Rules

Suggested initial costs:

```text
flat ground = 1
slope/ramp = 2
rough terrain = 3 later
blocked terrain = invalid
occupied wall/building = invalid
```

Mobs should prefer easier/shorter routes but still use ramps when necessary.

## Turret Design for M-0

### Placeholder Turret

M-0 turret is a debug combat object.

Minimum features:

- Placeable on grid.
- Claims occupancy.
- Has range.
- Finds nearest mob.
- Rotates toward target if easy.
- Deals damage.
- Kills mobs.
- Optional simple projectile or hitscan.

Do not add:

- Ammo.
- Power.
- Heat.
- Upgrade trees.
- Build costs.
- Fancy targeting modes.

The purpose is to test mobs under combat pressure.

## Performance Testing Goals

M-0 should be built to answer:

- How many mobs can we spawn before frame rate drops?
- Is movement cost CPU-bound?
- Is rendering/animation the bottleneck?
- Is pathing/flow field rebuild expensive?
- Do mobs clump or jam at 50? 100? 250? 500?
- Do turrets targeting many mobs create spikes?
- Do debug overlays become expensive?

### M-0 Metrics

Track/display:

```text
live mob count
spawned total
killed total
FPS
frame time
flow rebuild time, if easy
turret count
projectile count, if using projectiles
```

## Proposed Godot Project Structure

This can change, but M-0 should keep scripts organized enough to avoid chaos.

```text
res://
    system/
      managers/
      main.tscn
    player/
      player_controller.tscn
    world/
      world_grid.tscn
      terrain_test_arena.tscn
      world_grid.gd
      terrain_cell.gd
      grid_overlay.gd
      terrain_overlay.gd
    build/
      wall_block.tscn
      ramp_block.tscn
      placeholder_turret.tscn
      test_core.tscn
      build_definition.gd
      build_catalog.gd
      build_placement_controller.gd
      build_system.gd
      occupancy_grid.gd
    mobs/
      basic_crawler.tscn
      horde_manager.gd
      mob_spawner.gd
      basic_crawler.gd
      mob_movement.gd
      mob_health.gd
    ui/
      dev_panel.tscn
      overlay_panel.tscn
    dev/
      dev_mode_manager.gd
      dev_panel.gd
    pathing/
      flow_field.gd
      flow_field_overlay.gd
    combat/
      placeholder_turret.gd
      turret_targeting.gd
```

For M-0, this can be leaner. Avoid making every file before it is needed.



## Suggested Next Milestone After M-0

Once M-0 works, the next likely milestone is **M-1: Player Build/Survival Loop Skeleton**.

Possible M-1 features:

- Normal first-person walking mode.
- Basic inventory/hotbar.
- Space Engineers-style block list.
- Resource cost checks.
- Basic ore resource.
- Mine/pickup simple ore chunks.
- Spend ore on walls/turrets.
- Bank ore toward quota.
- Simple wave start/end loop.
- Basic loss/win states.

But M-1 should not be planned in full until M-0 reveals the mob/pathing constraints.

## Current Strong Recommendation

Do not start with inventory, mining, or the company store.

Start with:

1. Terrain/pathing test arena.
2. Dev fly movement.
3. Block placement.
4. Mob spawning controls.
5. Debug overlays.
6. Basic turret interaction.
7. Horde stress testing.

The game will earn the rest once the horde feels good.

