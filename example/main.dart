import 'package:tiny_ecs/tiny_ecs.dart';

// Example components for a simple game or application
class Position extends Component {
  double x, y;
  Position(this.x, this.y);

  @override
  String toString() => 'Position($x, $y)';
}

class Velocity extends Component {
  final double dx, dy;
  Velocity(this.dx, this.dy);

  @override
  String toString() => 'Velocity($dx, $dy)';
}

class Health extends Component {
  int current, max;
  Health(this.current, this.max);

  @override
  String toString() => 'Health($current/$max)';
}

class Name extends Component {
  final String value;
  Name(this.value);

  @override
  String toString() => 'Name($value)';
}

// Example system: Move entities with position and velocity
void movementSystem(World world, double deltaTime) {
  print('\n--- Movement System ---');
  for (final result in world.query2<Position, Velocity>()) {
    final position = result.component1;
    final velocity = result.component2;

    position.x += velocity.dx * deltaTime;
    position.y += velocity.dy * deltaTime;

    print('Entity ${result.entity} moved to ${position.toString()}');
  }
}

// Example system: Remove entities with zero health
void healthSystem(World world) {
  print('\n--- Health System ---');
  final deadEntities = <Entity>[];

  for (final result in world.query<Health>()) {
    if (result.component1.current <= 0) {
      deadEntities.add(result.entity);
      print('Entity ${result.entity} has died!');
    }
  }

  for (final entity in deadEntities) {
    world.destroyEntity(entity);
  }
}

void main() {
  print('=== Tiny ECS Example ===\n');

  // Create the world
  final world = World();

  // Create entities with different component combinations
  print('Creating entities...');

  // Player entity
  final player = world.createEntity();
  world.addComponent(player, Name('Player'));
  world.addComponent(player, Position(0.0, 0.0));
  world.addComponent(player, Velocity(10.0, 5.0));
  world.addComponent(player, Health(100, 100));

  // Enemy entity
  final enemy = world.createEntity();
  world.addComponent(enemy, Name('Goblin'));
  world.addComponent(enemy, Position(50.0, 20.0));
  world.addComponent(enemy, Velocity(-5.0, 2.0));
  world.addComponent(enemy, Health(30, 30));

  // Static object (no velocity)
  final chest = world.createEntity();
  world.addComponent(chest, Name('Treasure Chest'));
  world.addComponent(chest, Position(25.0, 15.0));
  world.addComponent(chest, Health(50, 50));

  print('Created ${world.entities.length} entities\n');

  // Show all entities with names
  print('=== All Named Entities ===');
  for (final result in world.query<Name>()) {
    final name = result.component1;
    final position = world.getComponent<Position>(result.entity);
    final health = world.getComponent<Health>(result.entity);

    print('Entity ${result.entity}: ${name.value}');
    if (position != null) print('  Position: $position');
    if (health != null) print('  Health: $health');
  }

  // Simulate game loop
  print('\n=== Game Simulation ===');
  for (int frame = 1; frame <= 3; frame++) {
    print('\nFrame $frame:');
    movementSystem(world, 1.0); // 1 second per frame

    // Damage enemy on frame 2
    if (frame == 2) {
      final enemyHealth = world.getComponent<Health>(enemy);
      if (enemyHealth != null) {
        enemyHealth.current = 0; // Kill the enemy
        print('Enemy took fatal damage!');
      }
    }

    healthSystem(world);
    print('Entities remaining: ${world.entities.length}');
  }

  // Demonstrate parent-child relationships
  print('\n=== Parent-Child Example ===');
  final vehicle = world.createEntity();
  world.addComponent(vehicle, Name('Car'));
  world.addComponent(vehicle, Position(100.0, 100.0));

  final wheel1 = world.createChildEntity(vehicle);
  world.addComponent(wheel1, Name('Front Wheel'));
  world.addComponent(wheel1, Position(95.0, 105.0));

  final wheel2 = world.createChildEntity(vehicle);
  world.addComponent(wheel2, Name('Rear Wheel'));
  world.addComponent(wheel2, Position(105.0, 105.0));

  print('Vehicle entity $vehicle has ${world.getChildren(vehicle).length} wheels');

  // Query children
  for (final result in world.queryChildren1<Name>(vehicle)) {
    print('  Child ${result.entity}: ${result.component1.value}');
  }

  // Demonstrate query builder
  print('\n=== Query Builder Example ===');
  final movingEntities = world.queryBuilder()
      .withComponent<Position>()
      .withComponent<Velocity>()
      .execute()
      .toList();

  print('Entities that can move: $movingEntities');

  final staticEntities = world.queryBuilder()
      .withComponent<Position>()
      .without<Velocity>()
      .execute()
      .toList();

  print('Static entities: $staticEntities');

  print('\n=== Example Complete ===');
  print('Final entity count: ${world.entities.length}');
}