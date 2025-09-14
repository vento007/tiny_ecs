# Tiny ECS

A minimal, functional Entity Component System (ECS) written in Dart, designed for applications that need to manage complex entities with dynamic component sets. Perfect for game engines, graphical editors, simulations, and data processing systems.

**Key Feature: 100% Component-Agnostic** - This library doesn't dictate what components you should have. You define your own components for your specific application needs!

## Features

- **Functional Design**: Systems are pure functions, components are data structures
- **Type-Safe Queries**: Strongly typed component queries with compile-time safety
- **Component-Agnostic**: Define any components you want - the library adapts automatically
- **Parent-Child Relationships**: Hierarchical entity structures with recursive operations
- **Query Builder**: Fluent API for complex queries with inclusions and exclusions
- **Minimal API**: Simple, easy-to-understand interface
- **Performance**: Efficient component storage and querying
- **Zero Dependencies**: Pure Dart implementation

## Core Concepts

### Entity
Just a unique identifier (integer) representing a game object.

### Component
Pure data structures that extend the `Component` base class:

```dart
class Position extends Component {
  double x, y;
  Position(this.x, this.y);
}

class Velocity extends Component {
  double dx, dy;
  Velocity(this.dx, this.dy);
}
```

### System
Pure functions that operate on entities with specific component combinations:

```dart
void movementSystem(World world, double deltaTime) {
  for (final result in world.query2<Position, Velocity>()) {
    final position = result.component1;
    final velocity = result.component2;
    
    position.x += velocity.dx * deltaTime;
    position.y += velocity.dy * deltaTime;
  }
}
```

### World
The main container that manages entities and components.

## Quick Start

Get a functional ECS running in **under 2 minutes**:

```dart
import 'package:tiny_ecs/tiny_ecs.dart';

// 1. Define YOUR components for YOUR application
class Position extends Component {
  double x, y;
  Position(this.x, this.y);
}

class Velocity extends Component {
  double dx, dy;
  Velocity(this.dx, this.dy);
}

// 2. Create YOUR systems
void movementSystem(World world, double deltaTime) {
  for (final result in world.query2<Position, Velocity>()) {
    final position = result.component1;
    final velocity = result.component2;

    position.x += velocity.dx * deltaTime;
    position.y += velocity.dy * deltaTime;
  }
}

void main() {
  // 3. Create world
  final world = World();

  // 4. Create entities with YOUR components
  final movingObject = world.createEntity();
  world.addComponent(movingObject, Position(0, 0));
  world.addComponent(movingObject, Velocity(100, 50));

  // 5. Query entities
  for (final result in world.query2<Position, Velocity>()) {
    print('Entity ${result.entity} can move!');
  }

  // 6. Run YOUR systems
  movementSystem(world, 1/60);

  // Check result
  final pos = world.getComponent<Position>(movingObject)!;
  print('Object moved to: (${pos.x}, ${pos.y})');
}
```

That's it! You now have a functional ECS ready for your application development needs.

## API Reference

### World Methods

**Entity Management:**
- `createEntity()` - Create a new entity
- `createChildEntity(parent)` - Create a child entity under a parent
- `destroyEntity(entity)` - Remove entity and all its components (recursively for children)

**Component Management:**
- `addComponent<T>(entity, component)` - Add component to entity
- `removeComponent<T>(entity)` - Remove component from entity
- `hasComponent<T>(entity)` - Check if entity has component
- `getComponent<T>(entity)` - Get component from entity
- `getAllComponents(entity)` - Get all components for an entity

**Parent-Child Relationships:**
- `getParent(child)` - Get parent of a child entity
- `getChildren(parent)` - Get all children of a parent entity

**Bulk Operations:**
- `addComponents(entity, components)` - Add multiple components at once
- `createEntityWith(components)` - Create entity with components in one call

### Queries

**Basic Queries:**
- `query<T1>()` - Find entities with one component type
- `query2<T1, T2>()` - Find entities with two component types
- `query3<T1, T2, T3>()` - Find entities with three component types

**Child Queries:**
- `queryChildren1<T1>(parent)` - Query children with one component
- `queryChildren<T1, T2>(parent)` - Query children with two components
- `queryChildren3<T1, T2, T3>(parent)` - Query children with three components

**Advanced Queries:**
- `queryBuilder()` - Create a fluent query builder
- `entitiesWith<T>()` - Get entities with specific component
- `queryEntities(List<Type>)` - Generic multi-component query

### Query Builder API

```dart
world.queryBuilder()
  .withComponent<Position>()
  .withComponent<Velocity>()
  .without<Health>()  // Exclude entities with Health
  .execute();  // Returns Iterable<Entity>
```

## Example: Simple Game

```dart
// Create entities
final player = world.createEntity();
world.addComponent(player, Name('Player'));
world.addComponent(player, Position(0, 0));
world.addComponent(player, Velocity(10, 0));

final enemy = world.createEntity();
world.addComponent(enemy, Name('Goblin'));
world.addComponent(enemy, Position(50, 0));
world.addComponent(enemy, Health(30, 30));

// Game loop
for (int frame = 0; frame < 60; frame++) {
  movementSystem(world, 1/60); // 60 FPS
  healthSystem(world);
}
```

## Example: Graphical Editor

```dart
// Define editor components
class Shape extends Component {
  final String type;
  Shape(this.type);
}

class Bounds extends Component {
  double x, y, width, height;
  Bounds(this.x, this.y, this.width, this.height);
}

class Selected extends Component {}
class Visible extends Component {}

// Create shapes in editor
final rectangle = world.createEntity();
world.addComponent(rectangle, Shape('rectangle'));
world.addComponent(rectangle, Bounds(10, 10, 100, 50));
world.addComponent(rectangle, Visible());

// Select all visible shapes
for (final result in world.query2<Shape, Visible>()) {
  if (/* click detection logic */) {
    world.addComponent(result.entity, Selected());
  }
}
```

## Running Tests

```bash
# Run the comprehensive test suite
dart test
```

## Why Functional ECS?

Traditional OOP ECS systems often suffer from:
- Complex inheritance hierarchies
- Tight coupling between systems
- Mutable state scattered across objects
- Difficult to test and reason about

This functional approach provides:
- **Pure Functions**: Systems are predictable and testable
- **Immutable Queries**: Query results are read-only snapshots
- **Simple Data**: Components are just data, no behavior
- **Composability**: Easy to combine and extend systems

## Performance Characteristics

- Entity creation: O(1)
- Component add/remove: O(1)
- Single component query: O(n) where n = entities with component
- Multi-component query: O(min(n1, n2, ...)) - intersection of smallest set
- Parent-child operations: O(1) lookup/modification
- Recursive entity destruction: O(k) where k = total descendants

The test suite includes performance tests with 1000+ entities to ensure the library scales appropriately for typical game use cases.

## Summary

**Tiny ECS** is a production-ready, functional Entity Component System designed for game engines. Here's what makes it special:

### What We Built
- **100% Component-Agnostic**: No hardcoded components - define whatever your game needs
- **Functional Architecture**: Pure systems, immutable queries, predictable behavior
- **Type-Safe Queries**: Compile-time guarantees for component combinations
- **Parent-Child Hierarchies**: Built-in support for entity relationships
- **Query Builder**: Fluent API for complex queries with exclusions
- **Zero Dependencies**: Pure Dart implementation, works anywhere

### Real-World Ready
- **Efficient operations** with O(1) entity and component management
- **Scalable queries** with optimized intersection algorithms
- **Memory efficient** storage with predictable performance
- **Battle-tested** with comprehensive test coverage (24 test cases)

### Perfect For
- **Game Engines** (2D/3D games of any genre)
- **Graphical Editors** (CAD, image editors, vector graphics)
- **Simulation Systems** (physics, AI, economy, scientific modeling)
- **Content Management** (CMS, document systems)
- **Data Processing** (large entity datasets, ETL pipelines)
- **UI Systems** (dynamic component-based interfaces)
- **IoT Platforms** (device management, sensor data)
- **Animation Systems** (timeline-based animations, tweening)
- **Workflow Engines** (task management, process automation)

### What You Get
```
lib/tiny_ecs.dart          # Core ECS (~350 lines, zero deps)
test/tiny_ecs_test.dart    # Comprehensive test suite (24 test cases)
```

**Start building your application's ECS today** - define your components, write your systems, and let Tiny ECS handle the infrastructure!

## License

MIT License - feel free to use in your applications and projects!



