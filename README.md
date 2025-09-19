<div align="center">

<p>
  <img src="https://raw.githubusercontent.com/vento007/tiny_ecs/main/media/logo.png" alt="Tiny ECS Logo" width="320" />
</p>

<h1 align="center">tiny ecs — minimal functional entity component system</h1>

<p align="center"><em>A minimal, functional Entity Component System (ECS) written in Dart, designed for applications that need to manage complex entities with dynamic component sets.</em></p>

<hr>

</div>

**In-memory, typed entity management with:**

- **Typed components** (e.g., `Position`, `Health`, `Weapon`, `Inventory`)
- **Functional systems** (e.g., `movementSystem`, `combatSystem`, `renderSystem`)
- **Type-safe queries** for entity combinations
- **Parent-child hierarchies** with recursive operations
- **Query builder** for complex filtering

## Table of Contents

- [1. Quick Preview](#1-quick-preview)
- [2. Complete Usage Examples](#2-complete-usage-examples)
- [3. System Patterns](#3-system-patterns)
- [4. Advanced Features](#4-advanced-features)
- [5. Query Reference](#5-query-reference)
- [6. Design and Performance](#6-design-and-performance)
- [7. Examples Index](#7-examples-index)
- [License](#license)

## 1. Quick Preview

```dart
// Create a simple 2D game world
final world = World();

// Create player with multiple components
final player = world.createEntity();
world.addComponent(player, Position(100, 200));
world.addComponent(player, Health(100, 100));
world.addComponent(player, Weapon('sword', damage: 25));

// Create enemy
final goblin = world.createEntity();
world.addComponent(goblin, Position(150, 200));
world.addComponent(goblin, Health(30, 30));
world.addComponent(goblin, AI('aggressive'));

// Process all entities with position and health
for (final result in world.query2<Position, Health>()) {
  print('Entity ${result.entity} at (${result.component1.x}, ${result.component1.y}) '
        'has ${result.component2.current}/${result.component2.max} health');
}
// Output:
// Entity 1 at (100, 200) has 100/100 health
// Entity 2 at (150, 200) has 30/30 health
```

## 2. Complete Usage Examples

This section provides copy-paste ready examples demonstrating all major features with a sample game world. Each example can be run as a standalone Dart script.

### 2.1 Setup: Sample Game World

```dart
import 'package:tiny_ecs/tiny_ecs.dart';

// Define your game components
class Position extends Component {
  double x, y;
  Position(this.x, this.y);

  @override
  String toString() => 'Position($x, $y)';
}

class Health extends Component {
  int current, max;
  Health(this.current, this.max);

  @override
  String toString() => 'Health($current/$max)';
}

class Velocity extends Component {
  double dx, dy;
  Velocity(this.dx, this.dy);

  @override
  String toString() => 'Velocity($dx, $dy)';
}

class Weapon extends Component {
  final String name;
  final int damage;
  Weapon(this.name, {required this.damage});

  @override
  String toString() => 'Weapon($name, $damage dmg)';
}

class AI extends Component {
  final String behavior;
  AI(this.behavior);

  @override
  String toString() => 'AI($behavior)';
}

void main() {
  // Create game world
  final world = World();

  // Add player
  final player = world.createEntity();
  world.addComponent(player, Position(100, 200));
  world.addComponent(player, Health(100, 100));
  world.addComponent(player, Velocity(0, 0));
  world.addComponent(player, Weapon('sword', damage: 25));

  // Add enemies
  final goblin = world.createEntity();
  world.addComponent(goblin, Position(150, 200));
  world.addComponent(goblin, Health(30, 30));
  world.addComponent(goblin, Velocity(-5, 0));
  world.addComponent(goblin, AI('aggressive'));

  final orc = world.createEntity();
  world.addComponent(orc, Position(200, 180));
  world.addComponent(orc, Health(50, 50));
  world.addComponent(orc, Weapon('club', damage: 15));
  world.addComponent(orc, AI('defensive'));

  // Add static objects
  final chest = world.createEntity();
  world.addComponent(chest, Position(120, 150));
  world.addComponent(chest, Health(25, 25));

  print('Created ${world.entities.length} entities');

  // Run examples below...
}
```

### 2.2 Basic Queries - Get Entities by Component Type

```dart
// Get all entities with health, query returns Iterable<QueryResult1<Health>>
final healthyEntities = world.query<Health>().toList();
print('Entities with health: ${healthyEntities.length}');
for (final result in healthyEntities) {
  print('  Entity ${result.entity}: ${result.component1}');
}
// Output:
// Entities with health: 4
//   Entity 1: Health(100/100)
//   Entity 2: Health(30/30)
//   Entity 3: Health(50/50)
//   Entity 4: Health(25/25)

// Get all entities with weapons, query returns Iterable<QueryResult1<Weapon>>
final armedEntities = world.query<Weapon>().toList();
print('Armed entities: ${armedEntities.length}');
for (final result in armedEntities) {
  print('  Entity ${result.entity}: ${result.component1}');
}
// Output:
// Armed entities: 2
//   Entity 1: Weapon(sword, 25 dmg)
//   Entity 3: Weapon(club, 15 dmg)

// Get all entities with AI, query returns Iterable<QueryResult1<AI>>
final aiEntities = world.query<AI>().toList();
print('AI entities: ${aiEntities.length}');
for (final result in aiEntities) {
  print('  Entity ${result.entity}: ${result.component1}');
}
// Output:
// AI entities: 2
//   Entity 2: AI(aggressive)
//   Entity 3: AI(defensive)
```

### 2.3 Multi-Component Queries - Get Entities with Specific Combinations

```dart
// Get all entities that can move (have position AND velocity)
final movingEntities = world.query2<Position, Velocity>().toList();
print('Moving entities: ${movingEntities.length}');
for (final result in movingEntities) {
  print('  Entity ${result.entity}: ${result.component1}, ${result.component2}');
}
// Output:
// Moving entities: 2
//   Entity 1: Position(100, 200), Velocity(0, 0)
//   Entity 2: Position(150, 200), Velocity(-5, 0)

// Get all entities that can fight (have position AND weapon)
final fighters = world.query2<Position, Weapon>().toList();
print('Fighter entities: ${fighters.length}');
for (final result in fighters) {
  print('  Entity ${result.entity} at ${result.component1} has ${result.component2}');
}
// Output:
// Fighter entities: 2
//   Entity 1 at Position(100, 200) has Weapon(sword, 25 dmg)
//   Entity 3 at Position(200, 180) has Weapon(club, 15 dmg)

// Get all entities with position, health, AND weapon (3-component query)
final combatants = world.query3<Position, Health, Weapon>().toList();
print('Combat-ready entities: ${combatants.length}');
for (final result in combatants) {
  print('  Entity ${result.entity}: ${result.component1}, ${result.component2}, ${result.component3}');
}
// Output:
// Combat-ready entities: 2
//   Entity 1: Position(100, 200), Health(100/100), Weapon(sword, 25 dmg)
//   Entity 3: Position(200, 180), Health(50/50), Weapon(club, 15 dmg)
```

### 2.4 Working with Individual Entities

```dart
// Check if specific entity has components
print('Player has weapon: ${world.hasComponent<Weapon>(player)}'); // true
print('Goblin has weapon: ${world.hasComponent<Weapon>(goblin)}'); // false
print('Chest has AI: ${world.hasComponent<AI>(chest)}'); // false

// Get specific components from entities
final playerPos = world.getComponent<Position>(player);
final playerHealth = world.getComponent<Health>(player);
print('Player is at $playerPos with $playerHealth');
// Output: Player is at Position(100, 200) with Health(100/100)

// Get all components from an entity
final playerComponents = world.getAllComponents(player).toList();
print('Player has ${playerComponents.length} components: $playerComponents');
// Output: Player has 4 components: [Position(100, 200), Health(100/100), Velocity(0, 0), Weapon(sword, 25 dmg)]

// Modify components directly
playerPos?.x = 110;
playerHealth?.current = 95;
print('After modification: Player at $playerPos with $playerHealth');
// Output: After modification: Player at Position(110, 200) with Health(95/100)
```

### 2.5 Adding and Removing Components Dynamically

```dart
// Add new component to existing entity
world.addComponent(goblin, Weapon('dagger', damage: 8));
print('Goblin now has weapon: ${world.hasComponent<Weapon>(goblin)}'); // true

// Remove component from entity
world.removeComponent<AI>(goblin);
print('Goblin has AI: ${world.hasComponent<AI>(goblin)}'); // false

// Create entity with multiple components at once
final archer = world.createEntityWith([
  Position(300, 250),
  Health(40, 40),
  Weapon('bow', damage: 20),
  AI('ranged')
]);
print('Created archer entity: $archer');
print('Archer components: ${world.getAllComponents(archer).toList()}');
// Output:
// Created archer entity: 5
// Archer components: [Position(300, 250), Health(40, 40), Weapon(bow, 20 dmg), AI(ranged)]
```

### 2.6 Entity Lifecycle Management

```dart
// Create temporary entity
final projectile = world.createEntity();
world.addComponent(projectile, Position(100, 200));
world.addComponent(projectile, Velocity(50, 0));

print('Entities before cleanup: ${world.entities.length}'); // 6

// Destroy entity (removes all its components)
world.destroyEntity(projectile);
print('Entities after cleanup: ${world.entities.length}'); // 5

// Verify entity and components are gone
print('Projectile exists: ${world.entities.contains(projectile)}'); // false
print('Projectile has position: ${world.hasComponent<Position>(projectile)}'); // false
```

## 3. System Patterns

Systems are pure functions that process entities with specific component combinations. Here are common patterns:

### 3.1 Movement System

```dart
void movementSystem(World world, double deltaTime) {
  // Process all entities that can move
  for (final result in world.query2<Position, Velocity>()) {
    final position = result.component1;
    final velocity = result.component2;

    // Update position based on velocity
    position.x += velocity.dx * deltaTime;
    position.y += velocity.dy * deltaTime;
  }
}

// Usage in game loop
movementSystem(world, 1/60); // 60 FPS
print('After movement:');
for (final result in world.query2<Position, Velocity>()) {
  print('  Entity ${result.entity}: ${result.component1}');
}
// Output:
// After movement:
//   Entity 1: Position(110, 200)
//   Entity 2: Position(141.67, 200)
```

### 3.2 Health Management System

```dart
void healthSystem(World world) {
  final deadEntities = <int>[];

  // Find all dead entities
  for (final result in world.query<Health>()) {
    if (result.component1.current <= 0) {
      deadEntities.add(result.entity);
      print('Entity ${result.entity} has died!');
    }
  }

  // Remove dead entities
  for (final entity in deadEntities) {
    world.destroyEntity(entity);
  }
}

// Simulate damage
final goblinHealth = world.getComponent<Health>(goblin);
goblinHealth?.current = 0;

healthSystem(world);
print('Entities remaining: ${world.entities.length}');
// Output:
// Entity 2 has died!
// Entities remaining: 4
```

### 3.3 Combat System

```dart
void combatSystem(World world) {
  final fighters = world.query3<Position, Health, Weapon>().toList();

  // Simple combat: entities damage nearby enemies
  for (int i = 0; i < fighters.length; i++) {
    for (int j = i + 1; j < fighters.length; j++) {
      final fighter1 = fighters[i];
      final fighter2 = fighters[j];

      final pos1 = fighter1.component1;
      final pos2 = fighter2.component1;

      // Check if in combat range (distance < 50)
      final distance = ((pos1.x - pos2.x) * (pos1.x - pos2.x) +
                       (pos1.y - pos2.y) * (pos1.y - pos2.y));

      if (distance < 2500) { // 50 squared
        // Deal damage
        final weapon1 = fighter1.component3;
        final weapon2 = fighter2.component3;

        fighter2.component2.current -= weapon1.damage;
        fighter1.component2.current -= weapon2.damage;

        print('Combat! Entity ${fighter1.entity} vs Entity ${fighter2.entity}');
        print('  Damage dealt: ${weapon1.damage} vs ${weapon2.damage}');
      }
    }
  }
}
```

## 4. Advanced Features

### 4.1 Parent-Child Relationships

Create hierarchical structures where destroying a parent automatically destroys all children:

```dart
// Create a vehicle with wheels
final car = world.createEntity();
world.addComponent(car, Position(500, 300));
world.addComponent(car, Velocity(20, 0));

// Create wheels as children
final frontWheel = world.createChildEntity(car);
world.addComponent(frontWheel, Position(495, 305));

final rearWheel = world.createChildEntity(car);
world.addComponent(rearWheel, Position(505, 305));

print('Car has ${world.getChildren(car).length} wheels');
// Output: Car has 2 wheels

// Query children with specific components
for (final result in world.queryChildren1<Position>(car)) {
  print('  Wheel ${result.entity} at ${result.component1}');
}
// Output:
//   Wheel 6 at Position(495, 305)
//   Wheel 7 at Position(505, 305)

// Destroying parent destroys all children recursively
world.destroyEntity(car);
print('Entities after destroying car: ${world.entities.length}');
// Output: Entities after destroying car: 4 (car + 2 wheels removed)
```

### 4.2 Query Builder for Complex Filtering

Use the fluent query builder for advanced filtering:

```dart
// Find entities with position but without AI (static objects)
final staticObjects = world.queryBuilder()
    .withComponent<Position>()
    .without<AI>()
    .execute()
    .toList();

print('Static objects: $staticObjects');
// Output: Static objects: [1, 4] (player and chest)

// Find entities with weapons but without velocity (stationary fighters)
final stationaryFighters = world.queryBuilder()
    .withComponent<Weapon>()
    .without<Velocity>()
    .execute()
    .toList();

print('Stationary fighters: $stationaryFighters');
// Output: Stationary fighters: [3] (orc)

// Find entities with health and position (can be damaged and located)
final targetableEntities = world.queryBuilder()
    .withComponent<Health>()
    .withComponent<Position>()
    .execute()
    .toList();

print('Targetable entities: $targetableEntities');
// Output: Targetable entities: [1, 3, 4, 5] (all except projectiles)
```

### 4.3 Bulk Operations

Efficiently create and modify multiple entities:

```dart
// Create multiple similar entities at once
final enemyData = [
  {'pos': Position(400, 200), 'hp': 20},
  {'pos': Position(450, 220), 'hp': 25},
  {'pos': Position(380, 180), 'hp': 18},
];

final enemySquad = <int>[];
for (final data in enemyData) {
  final enemy = world.createEntityWith([
    data['pos'] as Position,
    Health(data['hp'] as int, data['hp'] as int),
    AI('patrol'),
    Weapon('spear', damage: 12),
  ]);
  enemySquad.add(enemy);
}

print('Created enemy squad: $enemySquad');
// Output: Created enemy squad: [8, 9, 10]

// Bulk modify components
for (final entity in enemySquad) {
  final health = world.getComponent<Health>(entity);
  health?.current = (health.current * 0.8).round(); // Damage all
}

print('Squad after area damage:');
for (final entity in enemySquad) {
  final health = world.getComponent<Health>(entity);
  print('  Entity $entity: $health');
}
// Output:
// Squad after area damage:
//   Entity 8: Health(16/20)
//   Entity 9: Health(20/25)
//   Entity 10: Health(14/18)
```

## 5. Query Reference

### 5.1 Basic Query Methods

| Method | Returns | Use Case |
|--------|---------|----------|
| `query<T>()` | `Iterable<QueryResult1<T>>` | All entities with one component type |
| `query2<T1, T2>()` | `Iterable<QueryResult2<T1, T2>>` | Entities with two component types |
| `query3<T1, T2, T3>()` | `Iterable<QueryResult3<T1, T2, T3>>` | Entities with three component types |
| `entitiesWith<T>()` | `Iterable<Entity>` | Just entity IDs with component type |

### 5.2 Entity Management

| Method | Returns | Use Case |
|--------|---------|----------|
| `createEntity()` | `Entity` | Create new empty entity |
| `createEntityWith(components)` | `Entity` | Create entity with components |
| `destroyEntity(entity)` | `void` | Remove entity and all components |
| `addComponent(entity, component)` | `void` | Add component to entity |
| `removeComponent<T>(entity)` | `void` | Remove component from entity |
| `hasComponent<T>(entity)` | `bool` | Check if entity has component |
| `getComponent<T>(entity)` | `T?` | Get component from entity |
| `getAllComponents(entity)` | `Iterable<Component>` | Get all entity components |

### 5.3 Parent-Child Operations

| Method | Returns | Use Case |
|--------|---------|----------|
| `createChildEntity(parent)` | `Entity` | Create child under parent |
| `getParent(child)` | `Entity?` | Get parent of child entity |
| `getChildren(parent)` | `Set<Entity>` | Get all children of parent |
| `queryChildren1<T>(parent)` | `Iterable<QueryResult1<T>>` | Query children with component |
| `queryChildren<T1, T2>(parent)` | `Iterable<QueryResult2<T1, T2>>` | Query children with 2 components |

### 5.4 Query Builder

```dart
world.queryBuilder()
  .withComponent<Position>()    // Must have Position
  .withComponent<Health>()      // Must have Health
  .without<AI>()               // Must NOT have AI
  .execute();                  // Returns Iterable<Entity>
```

## 6. Design and Performance

### 6.1 Performance Characteristics

- **Entity creation**: O(1)
- **Component add/remove**: O(1)
- **Single component query**: O(n) where n = entities with that component
- **Multi-component query**: O(min(n1, n2, ...)) - intersection of smallest component set
- **Parent-child operations**: O(1) for lookup, O(k) for recursive destruction where k = descendants

### 6.2 When to Use ECS

**Use ECS when you have:**
- Entities with varying component combinations
- Need to process entities by component type
- Complex entity relationships
- Performance-critical entity processing

**Consider alternatives when:**
- Simple object hierarchies work fine
- Entities always have the same components
- No need for bulk processing by component type

### 6.3 Best Practices

- **Keep components as data**: No methods, just properties
- **Keep systems pure**: No side effects except component modification
- **Batch operations**: Process many entities in single system calls
- **Use specific queries**: More specific queries (3-component) are often faster than generic ones

## 7. Examples Index

### Complete Examples
- `example/main.dart` – Comprehensive ECS demo with game entities
- Documentation examples above – Copy-paste ready code snippets

### Common Patterns
- **Game entities**: Player, enemies, items, projectiles
- **UI systems**: Windows, buttons, layout components
- **Simulation**: Particles, physics bodies, constraints
- **Data processing**: Records, transformations, aggregations

## License

MIT License - see `LICENSE` file.