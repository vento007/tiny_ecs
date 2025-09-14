import 'package:test/test.dart';
import 'package:tiny_ecs/tiny_ecs.dart';

// Example components for testing
class Position extends Component {
  double x, y;
  Position(this.x, this.y);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Position && runtimeType == other.runtimeType && x == other.x && y == other.y;

  @override
  int get hashCode => x.hashCode ^ y.hashCode;
}

class Velocity extends Component {
  final double dx, dy;
  Velocity(this.dx, this.dy);
}

class Health extends Component {
  int current, max;
  Health(this.current, this.max);
}

// Example systems for testing
void movementSystem(World world, double deltaTime) {
  for (final result in world.query2<Position, Velocity>()) {
    result.component1.x += result.component2.dx * deltaTime;
    result.component1.y += result.component2.dy * deltaTime;
  }
}

void healthSystem(World world) {
  final deadEntities = <Entity>[];
  for (final result in world.query<Health>()) {
    if (result.component1.current <= 0) {
      deadEntities.add(result.entity);
    }
  }

  for (final entity in deadEntities) {
    world.destroyEntity(entity);
  }
}

// Custom test components to prove the library is flexible
class TestComponentA extends Component {
  final String data;
  TestComponentA(this.data);
}

class TestComponentB extends Component {
  final int value;
  TestComponentB(this.value);
}

void main() {
  group('TinyECS Core Tests', () {
    late World world;

    setUp(() {
      world = World();
    });

    test('should create entities with unique IDs', () {
      final entity1 = world.createEntity();
      final entity2 = world.createEntity();

      expect(entity1, isNot(equals(entity2)));
      expect(world.entities.contains(entity1), isTrue);
      expect(world.entities.contains(entity2), isTrue);
    });

    test('should work with any custom component types', () {
      final entity = world.createEntity();
      final testCompA = TestComponentA('test data');
      final testCompB = TestComponentB(42);

      world.addComponent(entity, testCompA);
      world.addComponent(entity, testCompB);

      expect(world.hasComponent<TestComponentA>(entity), isTrue);
      expect(world.hasComponent<TestComponentB>(entity), isTrue);
      expect(world.getComponent<TestComponentA>(entity)?.data,
          equals('test data'));
      expect(world.getComponent<TestComponentB>(entity)?.value, equals(42));
    });

    test('should add and retrieve components', () {
      final entity = world.createEntity();
      final position = Position(10.0, 20.0);

      world.addComponent(entity, position);

      expect(world.hasComponent<Position>(entity), isTrue);
      expect(world.getComponent<Position>(entity), equals(position));
    });

    test('should remove components', () {
      final entity = world.createEntity();
      world.addComponent(entity, Position(5.0, 5.0));

      expect(world.hasComponent<Position>(entity), isTrue);

      world.removeComponent<Position>(entity);

      expect(world.hasComponent<Position>(entity), isFalse);
      expect(world.getComponent<Position>(entity), isNull);
    });

    test('should query entities with single component', () {
      final entity1 = world.createEntity();
      final entity2 = world.createEntity();
      final entity3 = world.createEntity();

      world.addComponent(entity1, Position(1.0, 1.0));
      world.addComponent(entity2, Position(2.0, 2.0));
      world.addComponent(entity3, Health(100, 100));

      final results = world.query<Position>().toList();

      expect(results.length, equals(2));
      expect(results.map((r) => r.entity), containsAll([entity1, entity2]));
    });

    test('should query entities with multiple components', () {
      final entity1 = world.createEntity();
      final entity2 = world.createEntity();
      final entity3 = world.createEntity();

      world.addComponent(entity1, Position(1.0, 1.0));
      world.addComponent(entity1, Velocity(5.0, 0.0));

      world.addComponent(entity2, Position(2.0, 2.0));
      // entity2 has no velocity

      world.addComponent(entity3, Velocity(3.0, 3.0));
      // entity3 has no position

      final results = world.query2<Position, Velocity>().toList();

      expect(results.length, equals(1));
      expect(results.first.entity, equals(entity1));
    });

    test('should query with custom component combinations', () {
      final entity1 = world.createEntity();
      final entity2 = world.createEntity();

      world.addComponent(entity1, TestComponentA('hello'));
      world.addComponent(entity1, TestComponentB(100));

      world.addComponent(entity2, TestComponentA('world'));
      // entity2 doesn't have TestComponentB

      final results = world.query2<TestComponentA, TestComponentB>().toList();

      expect(results.length, equals(1));
      expect(results.first.entity, equals(entity1));
      expect(results.first.component1.data, equals('hello'));
      expect(results.first.component2.value, equals(100));
    });

    test('should destroy entities and cleanup components', () {
      final entity = world.createEntity();
      world.addComponent(entity, Position(1.0, 1.0));
      world.addComponent(entity, Health(100, 100));

      expect(world.entities.contains(entity), isTrue);
      expect(world.hasComponent<Position>(entity), isTrue);
      expect(world.hasComponent<Health>(entity), isTrue);

      world.destroyEntity(entity);

      expect(world.entities.contains(entity), isFalse);
      expect(world.hasComponent<Position>(entity), isFalse);
      expect(world.hasComponent<Health>(entity), isFalse);
    });
  });

  group('Example Systems Tests', () {
    late World world;

    setUp(() {
      world = World();
    });

    test('movement system should update positions', () {
      final entity = world.createEntity();
      world.addComponent(entity, Position(0.0, 0.0));
      world.addComponent(entity, Velocity(10.0, 5.0));

      movementSystem(world, 2.0); // 2 seconds

      final position = world.getComponent<Position>(entity)!;
      expect(position.x, equals(20.0));
      expect(position.y, equals(10.0));
    });

    test('health system should remove dead entities', () {
      final entity1 = world.createEntity();
      final entity2 = world.createEntity();

      world.addComponent(entity1, Health(10, 100)); // alive
      world.addComponent(entity2, Health(0, 100)); // dead

      expect(world.entities.length, equals(2));

      healthSystem(world);

      expect(world.entities.length, equals(1));
      expect(world.entities.contains(entity1), isTrue);
      expect(world.entities.contains(entity2), isFalse);
    });
  });

  group('Parent-Child Relationship Tests', () {
    late World world;

    setUp(() {
      world = World();
    });

    test('should create child entities', () {
      final parent = world.createEntity();
      final child = world.createChildEntity(parent);

      expect(world.getParent(child), equals(parent));
      expect(world.getChildren(parent).contains(child), isTrue);
    });

    test('should handle multiple children', () {
      final parent = world.createEntity();
      final child1 = world.createChildEntity(parent);
      final child2 = world.createChildEntity(parent);
      final child3 = world.createChildEntity(parent);

      final children = world.getChildren(parent);
      expect(children.length, equals(3));
      expect(children.containsAll([child1, child2, child3]), isTrue);
    });

    test('should query children with components', () {
      final parent = world.createEntity();
      final child1 = world.createChildEntity(parent);
      final child2 = world.createChildEntity(parent);
      final child3 = world.createChildEntity(parent);

      world.addComponent(child1, Position(1.0, 1.0));
      world.addComponent(child2, Position(2.0, 2.0));
      world.addComponent(child2, Velocity(5.0, 5.0));
      world.addComponent(child3, Health(100, 100));

      final positionResults = world.queryChildren1<Position>(parent).toList();
      expect(positionResults.length, equals(2));

      final posVelResults = world.queryChildren<Position, Velocity>(parent).toList();
      expect(posVelResults.length, equals(1));
      expect(posVelResults.first.entity, equals(child2));
    });

    test('should destroy parent and all children recursively', () {
      final parent = world.createEntity();
      final child1 = world.createChildEntity(parent);
      world.createChildEntity(child1); // grandchild1
      world.createChildEntity(child1); // grandchild2

      expect(world.entities.length, equals(4));

      world.destroyEntity(parent);

      expect(world.entities.length, equals(0));
      expect(world.getChildren(parent).isEmpty, isTrue);
      expect(world.getParent(child1), isNull);
    });

    test('should throw error when creating child of non-existent parent', () {
      expect(() => world.createChildEntity(999), throwsArgumentError);
    });
  });

  group('Query Builder Tests', () {
    late World world;

    setUp(() {
      world = World();
    });

    test('should query with single component using builder', () {
      final entity1 = world.createEntity();
      final entity2 = world.createEntity();
      final entity3 = world.createEntity();

      world.addComponent(entity1, Position(1.0, 1.0));
      world.addComponent(entity2, Position(2.0, 2.0));
      world.addComponent(entity3, Health(100, 100));

      final results = world.queryBuilder()
          .withComponent<Position>()
          .execute()
          .toList();

      expect(results.length, equals(2));
      expect(results, containsAll([entity1, entity2]));
    });

    test('should query with multiple components using builder', () {
      final entity1 = world.createEntity();
      final entity2 = world.createEntity();
      final entity3 = world.createEntity();

      world.addComponent(entity1, Position(1.0, 1.0));
      world.addComponent(entity1, Velocity(5.0, 0.0));

      world.addComponent(entity2, Position(2.0, 2.0));
      world.addComponent(entity2, Health(100, 100));

      world.addComponent(entity3, Velocity(3.0, 3.0));

      final results = world.queryBuilder()
          .withComponent<Position>()
          .withComponent<Velocity>()
          .execute()
          .toList();

      expect(results.length, equals(1));
      expect(results.first, equals(entity1));
    });

    test('should query with exclusions using builder', () {
      final entity1 = world.createEntity();
      final entity2 = world.createEntity();
      final entity3 = world.createEntity();

      world.addComponent(entity1, Position(1.0, 1.0));
      world.addComponent(entity1, Velocity(5.0, 0.0));

      world.addComponent(entity2, Position(2.0, 2.0));
      // entity2 has no velocity

      world.addComponent(entity3, Position(3.0, 3.0));
      world.addComponent(entity3, Health(100, 100));

      final results = world.queryBuilder()
          .withComponent<Position>()
          .without<Velocity>()
          .execute()
          .toList();

      expect(results.length, equals(2));
      expect(results, containsAll([entity2, entity3]));
      expect(results.contains(entity1), isFalse);
    });
  });

  group('Advanced ECS Tests', () {
    late World world;

    setUp(() {
      world = World();
    });

    test('should handle query with 3 components', () {
      final entity1 = world.createEntity();
      final entity2 = world.createEntity();

      world.addComponent(entity1, Position(1.0, 1.0));
      world.addComponent(entity1, Velocity(5.0, 0.0));
      world.addComponent(entity1, Health(100, 100));

      world.addComponent(entity2, Position(2.0, 2.0));
      world.addComponent(entity2, Velocity(3.0, 3.0));
      // entity2 missing health

      final results = world.query3<Position, Velocity, Health>().toList();

      expect(results.length, equals(1));
      expect(results.first.entity, equals(entity1));
    });

    test('should get all components from entity', () {
      final entity = world.createEntity();
      final pos = Position(1.0, 1.0);
      final vel = Velocity(5.0, 0.0);
      final health = Health(100, 100);

      world.addComponent(entity, pos);
      world.addComponent(entity, vel);
      world.addComponent(entity, health);

      final allComponents = world.getAllComponents(entity).toList();

      expect(allComponents.length, equals(3));
      expect(allComponents, containsAll([pos, vel, health]));
    });

    test('should handle bulk component operations', () {
      final components = [
        Position(10.0, 20.0),
        Velocity(5.0, -3.0),
        Health(80, 100),
      ];

      final entity = world.createEntityWith(components);

      expect(world.hasComponent<Position>(entity), isTrue);
      expect(world.hasComponent<Velocity>(entity), isTrue);
      expect(world.hasComponent<Health>(entity), isTrue);

      final position = world.getComponent<Position>(entity)!;
      expect(position.x, equals(10.0));
      expect(position.y, equals(20.0));
    });

    test('should handle edge cases', () {
      final entity = world.createEntity();

      // Test getting component that doesn't exist
      expect(world.getComponent<Position>(entity), isNull);
      expect(world.hasComponent<Position>(entity), isFalse);

      // Test removing component that doesn't exist
      expect(() => world.removeComponent<Position>(entity), returnsNormally);

      // Test destroying entity that doesn't exist
      expect(() => world.destroyEntity(999), returnsNormally);

      // Test querying with no entities
      expect(world.query<Position>().toList().length, equals(0));
    });

    test('should handle empty queries correctly', () {
      // Query with no matching entities
      expect(world.queryEntities([Position]).length, equals(0));
      expect(world.queryEntities([]).length, equals(0));

      // Query with non-existent component types should return empty
      final builder = world.queryBuilder().withComponent<Position>();
      expect(builder.execute().length, equals(0));
    });
  });

  group('Performance and Stress Tests', () {
    late World world;

    setUp(() {
      world = World();
    });

    test('should handle large numbers of entities efficiently', () {
      const entityCount = 1000;
      final entities = <Entity>[];

      // Create many entities with components
      for (int i = 0; i < entityCount; i++) {
        final entity = world.createEntity();
        entities.add(entity);

        world.addComponent(entity, Position(i.toDouble(), i.toDouble()));
        if (i % 2 == 0) {
          world.addComponent(entity, Velocity(i.toDouble(), 0.0));
        }
        if (i % 3 == 0) {
          world.addComponent(entity, Health(100, 100));
        }
      }

      expect(world.entities.length, equals(entityCount));

      // Test queries are still fast and correct
      final positionResults = world.query<Position>().toList();
      expect(positionResults.length, equals(entityCount));

      final posVelResults = world.query2<Position, Velocity>().toList();
      expect(posVelResults.length, equals(500)); // 0,2,4,6...998 = 500 entities

      final tripleResults = world.query3<Position, Velocity, Health>().toList();
      // Entities with all 3: those divisible by both 2 and 3 (i.e., by 6)
      // 0, 6, 12, 18, ..., 996 = (996/6 + 1) = 167 entities
      expect(tripleResults.length, equals(167));
    });
  });
}
