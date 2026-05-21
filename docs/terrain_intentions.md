# Terrain Intentions

## Purpose

The terrain system is intended to support fast Dev Mode testing, mob pathing experiments, block placement, and eventual authored gameplay spaces.

The terrain should be simple enough to edit quickly, but flexible enough to create flat arenas, jagged alien terrain, raised platforms, cliffs, slopes, smoother rolling hills, blocked/pathable mob test spaces, and mining/base-defense environments.

This system is not trying to become a full voxel engine yet. The immediate goal is a robust grid-based terrain foundation for Milestone Zero.

---

# Core Terrain Philosophy

Terrain data should stay simple.

Visual terrain pieces can become more expressive over time, but the underlying terrain should remain understandable and debuggable.

Each terrain cell should primarily describe:

- height
- walkability
- buildability
- occupancy
- surface type
- slope direction/orientation
- traversal cost

The renderer can then interpret that data and choose which mesh pieces to display.

The game should avoid storing overly specific visual mesh choices directly in the terrain data whenever possible.

For example, the terrain data should not need to manually store ridge end, ridge corner, ridge T-junction, or ridge plus connector. Those can be derived from neighboring cells.

---

# Terrain Editing Goals

Dev Mode terrain editing should allow fast manipulation of terrain during testing.

Initial terrain editing modes:

## NONE

Mouse does nothing to terrain.

Used as a safety/default mode.

## HEIGHT

Left click raises a cell by 1.

Right click lowers a cell by 1.

Height edits should likely clear slope data on the edited cell.

## FLATTEN

Click and drag to flatten all touched cells to the same height.

The target height is sampled from the first clicked cell when the drag begins.

This makes flatten behavior predictable.

Example:

- click a height 3 cell
- drag over nearby cells
- all dragged cells become height 3

Flatten should clear slope data on affected cells.

## SLOPE

Click creates a slope based on surrounding terrain.

Default behavior should attempt to auto-orient the slope by checking neighboring terrain heights.

Pressing `R` manually overrides slope orientation.

Suggested orientation cycle:

- AUTO
- NORTH
- EAST
- SOUTH
- WEST
- AUTO

Manual slope orientation is important because auto-orientation will not always infer the intended shape correctly.

---

# Terrain Shape Concept

Terrain should be built from a combination of:

1. full block/cube height columns
2. a top surface/cap piece

A raised cell should not simply become a full cube immediately. Instead, the top of the cell can use a shaped cap.

Example:

- height 0: flat ground
- height 1: raised cap / peak cap
- height 2: cube column plus raised cap / peak cap
- height 3: two cube columns plus raised cap / peak cap

This allows terrain to feel jagged, sculpted, and alien without requiring complex mesh generation.

---

# Raised Terrain Caps

When terrain is raised, its top shape should be selected based on neighboring cells.

This behaves like 3D autotiling.

Each raised cell checks its cardinal neighbors:

- North
- East
- South
- West

If nearby cells are raised to the same relevant height, the top cap can visually connect to them.

## Cap Types

Minimum raised cap set:

- PEAK
- RIDGE_END
- RIDGE_STRAIGHT
- RIDGE_CORNER
- RIDGE_T
- RIDGE_PLUS

## PEAK

Used when a raised cell has no matching raised neighbors.

Pattern:

    . . .
    . X .
    . . .

Visual intent:

- isolated spike
- square pyramid cap
- jagged raised mound

This is the shape currently being described informally as a "tetrahedron", though technically it is closer to a square pyramid cap.

## RIDGE_END

Used when a raised cell connects to one matching raised neighbor.

Pattern:

    . X .
    . X .
    . . .

Requires four rotations.

## RIDGE_STRAIGHT

Used when a raised cell connects to two opposite matching raised neighbors.

Pattern:

    . X .
    . X .
    . X .

Requires two rotations:

- North/South
- East/West

## RIDGE_CORNER

Used when a raised cell connects to two adjacent matching raised neighbors.

Pattern:

    . X .
    . X X
    . . .

Requires four rotations.

## RIDGE_T

Used when a raised cell connects to three matching raised neighbors.

Pattern:

    . X .
    X X X
    . . .

Requires four rotations.

## RIDGE_PLUS

Used when a raised cell connects to all four cardinal matching raised neighbors.

Pattern:

    . X .
    X X X
    . X .

Can represent:

- plateau center
- mound intersection
- plus-shaped connector

---

# Slopes

Slopes are separate from raised terrain caps.

Raised caps are mostly visual/geological terrain.

Slopes are intentional traversable terrain.

This distinction matters because not every raised terrain shape should automatically become walkable.

## 1x1 Slopes

A 1x1 slope transitions one full height level across one cell.

Required pieces:

- SLOPE_1X1_N
- SLOPE_1X1_E
- SLOPE_1X1_S
- SLOPE_1X1_W

Slope direction should describe the high side.

Example:

- SLOPE_1X1_E
- west edge = low
- east edge = high

## 1x2 Slopes

A 1x2 slope creates a gentler ramp over two cells.

This requires two pieces:

- SLOPE_1X2_LOW
- SLOPE_1X2_HIGH

Example east-facing slope:

    [low half] [high half] [raised terrain]

Height profile:

- cell A: 0.0 to 0.5
- cell B: 0.5 to 1.0

This allows smoother terrain and gentler mob/player traversal.

1x2 slopes should not be implemented before 1x1 slope editing and traversal rules are stable.

## Slope Corners

Corner slope pieces should eventually support turns, intersections, and smoother transitions between slope directions.

Potential future pieces:

- SLOPE_CORNER_1X1
- SLOPE_CORNER_1X2_LOW
- SLOPE_CORNER_1X2_HIGH

Corner slopes should come after straight slopes are working reliably.

---

# Terrain Data vs Visual Meshes

The terrain data should not directly store every visual mesh choice.

Preferred stored data:

- height
- surface_type
- slope_direction
- walkable
- buildable
- occupied
- path_cost

Derived visual choices:

- peak cap
- ridge end
- ridge straight
- ridge corner
- ridge T
- ridge plus

The renderer can derive these from neighboring cell data.

This allows terrain to update naturally when nearby cells are raised or lowered.

Example:

One raised cell:

    . . .
    . X .
    . . .

Renderer chooses:

- PEAK

Two raised cells:

    . X .
    . X .
    . . .

Renderer chooses:

- RIDGE_END
- RIDGE_END

Three raised cells in a line:

    . X .
    . X .
    . X .

Renderer chooses:

- RIDGE_END
- RIDGE_STRAIGHT
- RIDGE_END

---

# Terrain Surface Authority

Slope and cap math should eventually live in one shared terrain utility or terrain surface authority.

The renderer, overlays, pathing, and dev tools should not each define their own slope/corner-height logic.

Suggested future utility:

`TerrainSurface.gd`

Responsibilities:

- get_top_corner_heights(cell_data)
- get_edge_heights(cell_data, direction)
- get_edge_average_height(cell_data, direction)
- is_slope(cell_data)
- get_cap_type_from_neighbor_mask(cell)
- can_surface_connect(cell_a, cell_b)

This avoids bugs where the mesh renders one shape, the overlay shows another, and the mob pathing thinks something else entirely.

---

# Traversal Rules

Walkability should eventually be more specific than asking whether a cell is walkable.

The game will also need:

`can_traverse_between(from_cell, to_cell)`

This should check:

- both cells are walkable
- neither cell is occupied
- the shared edge heights are compatible
- the height difference is not too steep
- slopes permit movement across that edge
- movement type allows the transition

This is important for flow fields and mob movement.

Two cells may both be walkable individually, but not traversable between each other.

Example:

- flat height 0 beside flat height 2

Both cells may be walkable, but the edge between them is a cliff unless a valid slope connects them.

---

# Visual Style Goal

The terrain should support two possible vibes from the same underlying data.

## Jagged Alien Blocks

- sharp peaks
- hard ridges
- geometric caps
- blocky cliff sides
- crystalline silhouettes

## Smooth Low-Poly Hills

- softer mounds
- rounded ridge caps
- smoother slope pieces
- less aggressive silhouettes

The same terrain rules should support both styles by swapping or improving the mesh library.

---

# Initial Mesh Library

Minimum useful terrain mesh set:

## Basic

- flat_ground_1x1
- cube_column_1x1

## Raised Caps

- cap_peak_1x1
- cap_ridge_end_1x1
- cap_ridge_straight_1x1
- cap_ridge_corner_1x1
- cap_ridge_t_1x1
- cap_ridge_plus_1x1

## Traversable Slopes

- slope_1x1
- slope_1x2_low
- slope_1x2_high

## Later Additions

- slope_corner_1x1
- slope_corner_1x2_low
- slope_corner_1x2_high
- cliff_side_variants
- ore_embedded_variants
- damaged_variants
- corporate_floor_variants
- alien_crystal_variants

---

# Near-Term Direction

Do not implement the full terrain mesh library yet.

The next practical step is to make terrain editing and terrain interpretation clean.

## Step 1: Terrain Mutation API

Add methods to modify terrain through WorldGrid or equivalent terrain authority.

Suggested methods:

- raise_cell(cell: Vector2i, amount := 1)
- lower_cell(cell: Vector2i, amount := 1)
- set_cell_height(cell: Vector2i, height: int)
- flatten_cell(cell: Vector2i, target_height: int)
- set_cell_slope(cell: Vector2i, slope_type, slope_direction)
- clear_cell_slope(cell: Vector2i)

Terrain edits should emit a signal such as:

`terrain_changed(changed_cells: Array[Vector2i])`

## Step 2: Dev Mode Terrain UI

Add terrain mode button:

- NONE
- HEIGHT
- FLATTEN
- SLOPE

Add slope orientation override:

- AUTO
- NORTH
- EAST
- SOUTH
- WEST

## Step 3: Shared Terrain Surface Logic

Move slope and top-surface calculations into one shared place.

## Step 4: Basic Slope Authoring

Support 1x1 slopes first.

1x2 slopes come later.

## Step 5: Traversal-Aware Pathing

Add edge-based traversal checks before relying on flow fields for serious mob behavior.

---

# Design Decision Summary

Current preferred direction:

- Manual height editing.
- Manual flatten tool.
- Explicit slope painting.
- Auto slope orientation helper.
- Manual slope orientation override.
- Raised terrain caps auto-connect visually using neighbor masks.
- Traversable slopes are separate from decorative raised caps.
- 1x2 slopes are planned, but not first.
- Corner slopes are planned, but not first.
- Terrain data stays simple.
- Renderer derives visual connector pieces.
- Traversal rules are edge-based, not just cell-based.

This gives the project a strong terrain foundation for Milestone Zero without turning the terrain system into a giant procedural art monster too early.

