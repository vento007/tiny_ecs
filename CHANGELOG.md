## 0.4.5

### Features
* **Parent-Child Relationships**: Added hierarchical entity structures with `createChildEntity()`, `getParent()`, `getChildren()`
* **Query Builder**: Fluent API for complex queries with inclusions and exclusions using `queryBuilder()`
* **Child Queries**: Specialized querying for child entities with `queryChildren1()`, `queryChildren()`, `queryChildren3()`
* **Bulk Operations**: Added `addComponents()` and `createEntityWith()` for efficient multi-component operations
* **Enhanced Component Access**: Added `getAllComponents()` to retrieve all components from an entity
* **Recursive Destruction**: Entity destruction now recursively removes all children

### Improvements
* **Comprehensive Test Suite**: 24 test cases covering all functionality including edge cases and performance
* **Updated Documentation**: Expanded README with broader use cases beyond game engines
* **MIT License**: Added proper MIT license file
* **Enhanced API**: Complete API reference with all methods documented

### Breaking Changes
* None - all changes are additive and backward compatible

 