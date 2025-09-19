/// A minimal, functional Entity Component System (ECS)
library tiny_ecs;

/// Entity is just a unique identifier
typedef Entity = int;

/// Base class for all components - just a marker interface
///
/// All components in the ECS must extend this class.
/// Components should be simple data containers without behavior.
abstract class Component {}

class QueryResults {
  final List<Entity> entities;

  QueryResults(this.entities);
}

/// Query result that contains entities and their components
class QueryResult1<T1 extends Component> {
  final Entity entity;
  final T1 component1;

  QueryResult1(this.entity, this.component1);
}

class QueryResult2<T1 extends Component, T2 extends Component> {
  final Entity entity;
  final T1 component1;
  final T2 component2;

  QueryResult2(this.entity, this.component1, this.component2);
}

class QueryResult3<T1 extends Component, T2 extends Component,
    T3 extends Component> {
  final Entity entity;
  final T1 component1;
  final T2 component2;
  final T3 component3;

  QueryResult3(this.entity, this.component1, this.component2, this.component3);
}

/// A fluent query builder for complex entity queries
///
/// Allows building queries with component inclusions and exclusions.
class QueryBuilder {
  final World world;
  final Set<Type> _withTypes = {}; // Components that must be present
  final Set<Type> _withoutTypes = {}; // Components that must NOT be present

  QueryBuilder._internal(this.world);

  /// Create a new query builder for the given world
  QueryBuilder(this.world);

  /// Add a component type that entities must have
  QueryBuilder withComponent<T extends Component>() {
    _withTypes.add(T);
    return this;
  }

  /// Add a component type that entities must NOT have
  QueryBuilder without<T extends Component>() {
    _withoutTypes.add(T);
    return this;
  }

  /// Execute the query and return matching entities
  Iterable<Entity> execute() {
    // Fast path: No exclusions - use existing optimized method
    if (_withoutTypes.isEmpty) {
      return world.queryEntities(_withTypes.toList());
    }

    // Slow path: Has exclusions - need filtering
    final candidates = world.queryEntities(_withTypes.toList());
    return candidates.where((entity) {
      // Check if entity has any excluded components
      for (final type in _withoutTypes) {
        if (world._components[type]?.containsKey(entity) ?? false) {
          return false; // Exclude this entity
        }
      }
      return true; // Keep this entity
    });
  }
}

/// The main ECS World that holds all entities and components
class World {
  int _nextEntityId = 1;

  // Component storage: Map<ComponentType, Map<Entity, Component>>
  final Map<Type, Map<Entity, Component>> _components = {};

  // Set of all active entities
  final Set<Entity> _entities = {};

  // NEW: Parent-child relationship storage
  final Map<Entity, Set<Entity>> _children = {}; // parent -> children set
  final Map<Entity, Entity?> _parents = {}; // child -> parent

  /// Create a new entity
  Entity createEntity() {
    final entity = _nextEntityId++;
    _entities.add(entity);
    return entity;
  }

  /// NEW: Create a child entity under a parent
  Entity createChildEntity(Entity parent) {
    if (!_entities.contains(parent)) {
      throw ArgumentError('Parent entity $parent does not exist');
    }

    final child = createEntity();

    // Update relationship maps - O(1) operations
    _children.putIfAbsent(parent, () => <Entity>{});
    _children[parent]!.add(child);
    _parents[child] = parent;

    return child;
  }

  /// NEW: Get all children of an entity - O(1) lookup
  Set<Entity> getChildren(Entity parent) {
    return _children[parent] ?? <Entity>{};
  }

  /// NEW: Get parent of an entity - O(1) lookup
  Entity? getParent(Entity child) {
    return _parents[child];
  }

  /// Add a component to an entity
  void addComponent<T extends Component>(Entity entity, T component) {
    if (!_entities.contains(entity)) {
      throw ArgumentError('Entity $entity does not exist');
    }

    final componentType = component.runtimeType;
    _components.putIfAbsent(componentType, () => <Entity, Component>{});
    _components[componentType]![entity] = component;
  }

  /// Remove a component from an entity
  void removeComponent<T extends Component>(Entity entity) {
    _components[T]?.remove(entity);
  }

  /// Check if entity has a specific component type
  bool hasComponent<T extends Component>(Entity entity) {
    return _components[T]?.containsKey(entity) ?? false;
  }

  /// Get a component from an entity
  T? getComponent<T extends Component>(Entity entity) {
    return _components[T]?[entity] as T?;
  }

  /// Get all entities that have a specific component
  Iterable<Entity> entitiesWith<T extends Component>() {
    return _components[T]?.keys ?? <Entity>[];
  }

  /// Query entities with 1 component type
  Iterable<QueryResult1<T1>> query<T1 extends Component>() sync* {
    final map1 = _components[T1];
    if (map1 == null) return;

    for (final entry in map1.entries) {
      yield QueryResult1<T1>(entry.key, entry.value as T1);
    }
  }

  /// Query entities with 2 component types
  Iterable<QueryResult2<T1, T2>>
      query2<T1 extends Component, T2 extends Component>() sync* {
    final map1 = _components[T1];
    final map2 = _components[T2];

    if (map1 == null || map2 == null) return;

    // Find intersection of entities
    for (final entity in map1.keys) {
      if (map2.containsKey(entity)) {
        yield QueryResult2<T1, T2>(
          entity,
          map1[entity] as T1,
          map2[entity] as T2,
        );
      }
    }
  }

  /// Query entities with 3 component types
  Iterable<QueryResult3<T1, T2, T3>> query3<T1 extends Component,
      T2 extends Component, T3 extends Component>() sync* {
    final map1 = _components[T1];
    final map2 = _components[T2];
    final map3 = _components[T3];

    if (map1 == null || map2 == null || map3 == null) return;

    for (final entity in map1.keys) {
      if (map2.containsKey(entity) && map3.containsKey(entity)) {
        yield QueryResult3<T1, T2, T3>(
          entity,
          map1[entity] as T1,
          map2[entity] as T2,
          map3[entity] as T3,
        );
      }
    }
  }

  // get all components
  Iterable<Component> getAllComponents(Entity entity) {
    return _components.values.map((map) => map[entity]).whereType<Component>();
  }

  /// Generic query method for multiple component types (returns just entities)
  Iterable<Entity> queryEntities(List<Type> componentTypes) {
    if (componentTypes.isEmpty) return _entities;

    Set<Entity>? result;

    for (final type in componentTypes) {
      final componentMap = _components[type];
      if (componentMap == null) return <Entity>[];

      final entities = componentMap.keys.toSet();
      result = result?.intersection(entities) ?? entities;

      if (result.isEmpty) break;
    }

    return result ?? <Entity>[];
  }

  /// NEW: Query children with 1 component type
  Iterable<QueryResult1<T1>> queryChildren1<T1 extends Component>(
      Entity parent) sync* {
    final children = getChildren(parent);
    final map1 = _components[T1];

    if (map1 == null) return;

    for (final child in children) {
      if (map1.containsKey(child)) {
        yield QueryResult1<T1>(child, map1[child] as T1);
      }
    }
  }

  /// NEW: Query children with 2 component types
  Iterable<QueryResult2<T1, T2>>
      queryChildren<T1 extends Component, T2 extends Component>(
          Entity parent) sync* {
    final children = getChildren(parent);
    final map1 = _components[T1];
    final map2 = _components[T2];

    if (map1 == null || map2 == null) return;

    for (final child in children) {
      if (map1.containsKey(child) && map2.containsKey(child)) {
        yield QueryResult2<T1, T2>(
          child,
          map1[child] as T1,
          map2[child] as T2,
        );
      }
    }
  }

  /// NEW: Query children with 3 component types
  Iterable<QueryResult3<T1, T2, T3>> queryChildren3<T1 extends Component,
      T2 extends Component, T3 extends Component>(Entity parent) sync* {
    final children = getChildren(parent);
    final map1 = _components[T1];
    final map2 = _components[T2];
    final map3 = _components[T3];

    if (map1 == null || map2 == null || map3 == null) return;

    for (final child in children) {
      if (map1.containsKey(child) &&
          map2.containsKey(child) &&
          map3.containsKey(child)) {
        yield QueryResult3<T1, T2, T3>(
          child,
          map1[child] as T1,
          map2[child] as T2,
          map3[child] as T3,
        );
      }
    }
  }

  /// Destroy an entity and all its components
  void destroyEntity(Entity entity) {
    if (!_entities.contains(entity)) return;

    // NEW: Clean up parent-child relationships
    final parent = _parents[entity];
    if (parent != null) {
      _children[parent]?.remove(entity);
    }

    // NEW: Destroy all children recursively
    final children = _children[entity];
    if (children != null) {
      for (final child in children.toList()) {
        destroyEntity(child);
      }
    }

    // NEW: Clean up relationship maps
    _children.remove(entity);
    _parents.remove(entity);

    _entities.remove(entity);

    // Remove from all component maps
    for (final componentMap in _components.values) {
      componentMap.remove(entity);
    }
  }

  /// Get all active entities
  Set<Entity> get entities => Set.unmodifiable(_entities);

  /// Create anew query builder for  fluent querying
  QueryBuilder queryBuilder() => QueryBuilder._internal(this);


  void addComponents(Entity entity, List<Component> components) {
  for (final component in components) {
    final type = component.runtimeType;
    _components.putIfAbsent(type, () => {});
    _components[type]![entity] = component;
  }
}

Entity createEntityWith(List<Component> components) {
  final entity = createEntity();
  addComponents(entity, components);
  return entity;
}


}
