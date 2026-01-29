# Level 2 Implementation Documentation

## Overview

Level 2 features an elevator puzzle with two paths to completion:
- **Violent Path**: Kill all sperms to create a time window, press the toilet button
- **Pacifist Path**: Open 3 valves while kiting sperms, then press button (enemies ignored)

---

## Puzzle Design

### The Elevator Puzzle

**Goal**: Activate the elevator by pressing the toilet button

**Condition (Violent)**: Player must be alone on the elevator (no enemies)

**Condition (Pacifist)**: All 3 valves must be opened (enemies don't matter)

### The Rusty Valves (Pacifist Route)

- Player holds **E** on a valve for **10 seconds** to complete it
- If released, progress **regresses over 7 seconds** back to 0%
- Sperms are **attracted to the active valve** and deal **contact damage**
- Player must **kite** sperms away, sprint back, and continue the valve

### Sperm Behavior

```
IDLE/WANDER
    ↓
ATTRACTED_TO_TOILET (default - always pulled to elevator)
    ↓ (valve activated)
ATTRACTED_TO_VALVE (crowd around player at valve)
    ↓ (valve released OR player damaged)
CHASING_PLAYER (aggro mode)
    ↓ (valve reactivated)
ATTRACTED_TO_VALVE
```

### Respawn System

- When a sperm dies, it respawns after **3 seconds** at a random marker
- This creates pressure for both paths:
  - Violent: Must kill and rush to button before respawns
  - Pacifist: Infinite sperms, must use kite strategy

---

## Files Created/Modified

### New Files

| File | Purpose |
|------|---------|
| `scripts/valve.gd` | Hold-to-interact valve with progress bar and regression |
| `scripts/level2_puzzle.gd` | Tracks valve completion, notifies sperms of active valve |
| `scenes/objects/valve.tscn` | Valve scene (cylinder mesh + interaction Area3D) |

### Modified Files

| File | Changes |
|------|---------|
| `scripts/sibling_sperm_lvl_2.gd` | Added valve attraction state, contact damage to player |
| `scripts/elevato_map_manager.gd` | Added 3-second respawn delay system |
| `scripts/button_elevator.gd` | Checks if all valves complete to bypass enemy check |
| `project.godot` | Added "interact" input action (E key) |
| `scenes/levels/level2.tscn` | Added 3 valves, 5 spawn markers |

---

## Key Variables (Adjustable)

### valve.gd
```gdscript
@export var fill_time: float = 10.0      # Seconds to complete valve
@export var regress_time: float = 7.0    # Seconds to fully regress
@export var interaction_range: float = 2.0
```

### sibling_sperm_lvl_2.gd
```gdscript
@export var contact_damage: int = 1           # Damage per tick when touching player
@export var contact_damage_cooldown: float = 1.0  # Seconds between damage ticks
@export var attraction_speed: float = 4.0     # Speed when attracted to valve/toilet
```

### elevato_map_manager.gd
```gdscript
@export var respawn_enabled: bool = true
@export var respawn_delay: float = 3.0   # Seconds before respawn after death
```

---

## Script Interactions

```
┌─────────────────────────────────────────────────────────────────┐
│                        LEVEL 2 FLOW                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Player holds E on Valve                                        │
│         ↓                                                       │
│  valve.gd emits "valve_started" signal                          │
│         ↓                                                       │
│  level2_puzzle.gd receives signal                               │
│         ↓                                                       │
│  level2_puzzle.gd calls on_valve_activated() on all sperms      │
│         ↓                                                       │
│  sibling_sperm_lvl_2.gd switches to ATTRACTED_TO_VALVE state    │
│         ↓                                                       │
│  Sperms crowd valve, deal contact damage                        │
│         ↓                                                       │
│  Player releases E (health low)                                 │
│         ↓                                                       │
│  valve.gd emits "valve_stopped", progress regresses             │
│         ↓                                                       │
│  level2_puzzle.gd calls on_valve_deactivated() on sperms        │
│         ↓                                                       │
│  Sperms return to ATTRACTED_TO_TOILET state                     │
│                                                                 │
│  ═══════════════════════════════════════════════════════════    │
│                                                                 │
│  When all 3 valves complete:                                    │
│         ↓                                                       │
│  level2_puzzle.gd emits "all_valves_completed"                  │
│         ↓                                                       │
│  button_elevator.gd checks are_all_valves_complete()            │
│         ↓                                                       │
│  If true: Button works even with enemies present                │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Scene Setup (level2.tscn)

```
Level2 (Node3D) ← elevato_map_manager.gd
├── Level2Puzzle (Node) ← level2_puzzle.gd
├── Map
├── Camera3D
├── Player
├── Elevator_final
│   ├── ElevatorZone (Area3D) ← elevator_zone_validator.gd
│   ├── button (StaticBody3D) ← button_elevator.gd
│   │   ├── InteractableArea
│   │   ├── Attraction (Area3D, group: "attraction_toilet")
│   │   └── OmniLight3D
│   └── ...
├── Valve (instance of valve.tscn)
├── Valve2 (instance of valve.tscn)
├── Valve3 (instance of valve.tscn)
├── Marker1-5 (spawn points)
├── NavigationRegion3D
└── SiblingSperm (template, spawned by manager)
```

---

## Input Actions

| Action | Key | Purpose |
|--------|-----|---------|
| `interact` | E | Hold to turn valves |
| `shoot` | Left Mouse | Attack / Press button |
| `aim` | Right Mouse | Aim weapon |

---

## Known Issues / TODO

- [ ] Test valve interaction range
- [ ] Test contact damage balance
- [ ] Verify sperm attraction switching works correctly
- [ ] Test respawn timing with kite strategy
- [ ] Adjust valve positions on elevator platform if needed
- [ ] Add visual/audio feedback for valve progress
