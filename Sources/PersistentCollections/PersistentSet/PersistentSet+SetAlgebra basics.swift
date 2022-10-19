//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import _CollectionsUtilities

extension PersistentSet: SetAlgebra {
  /// Returns a Boolean value that indicates whether the given element exists
  /// in the set.
  ///
  /// - Parameter element: An element to look for in the set.
  ///
  /// - Returns: `true` if `member` exists in the set; otherwise, `false`.
  ///
  /// - Complexity: This operation is expected to perform O(1) hashing and
  ///    comparison operations on average, provided that `Element` implements
  ///    high-quality hashing.
  @inlinable
  public func contains(_ item: Element) -> Bool {
    _root.containsKey(.top, item, _Hash(item))
  }

  /// Insert a new member to this set, if the set doesn't already contain it.
  ///
  /// - Parameter newMember: The element to insert into the set.
  ///
  /// - Returns: `(true, newMember)` if `newMember` was not contained in the
  ///    set. If an element equal to `newMember` was already contained in the
  ///    set, the method returns `(false, oldMember)`, where `oldMember` is the
  ///    element that was equal to `newMember`. In some cases, `oldMember` may
  ///    be distinguishable from `newMember` by identity comparison or some
  ///    other means.
  ///
  /// - Complexity: If `newMember` is not already a member of `self`, and if
  ///    `self` isn't uniquely held, then this operation is expected to copy
  ///    at most O(log(`count`)) existing members, as long as `Element` properly implements hashing.
  ///
  ///    In addition to this, this operation is expected to perform O(1)
  ///    hashing/comparison operations on the `Element` type (with the same
  ///    caveat.)
  @discardableResult
  @inlinable
  public mutating func insert(
    _ newMember: __owned Element
  ) -> (inserted: Bool, memberAfterInsert: Element) {
    let hash = _Hash(newMember)
    let r = _root.insert(.top, (newMember, ()), hash)
    if r.inserted {
      _invalidateIndices()
      return (true, newMember)
    }
    return _UnsafeHandle.read(r.leaf) {
      (false, $0[item: r.slot].key)
    }
  }

  @discardableResult
  @inlinable
  internal mutating func _insert(_ newMember: __owned Element) -> Bool {
    let hash = _Hash(newMember)
    let r = _root.insert(.top, (newMember, ()), hash)
    return r.inserted
  }

  /// Removes the given element from the set.
  ///
  /// - Parameter member: The element of the set to remove.
  ///
  /// - Returns: The element equal to `member` if `member` is contained in the
  ///    set; otherwise, `nil`. In some cases, the returned element may be
  ///    distinguishable from `newMember` by identity comparison or some other
  ///    means.
  ///
  /// - Complexity: The operation is expected to perform amortized
  ///    O(1) hashing/comparison operations on the `Element` type, if it
  ///    properly implements hashing.
  @discardableResult
  @inlinable
  public mutating func remove(_ member: Element) -> Element? {
    let hash = _Hash(member)
    _invalidateIndices()
    return _root.remove(.top, member, hash)?.key
  }

  /// Inserts the given element into the set unconditionally.
  ///
  /// If an element equal to `newMember` is already contained in the set,
  /// `newMember` replaces the existing element.
  ///
  /// If `newMember` was not already a member, it gets inserted.
  ///
  /// - Parameter newMember: An element to insert into the set.
  ///
  /// - Returns: The original member equal to `newMember` if the set already
  ///    contained such a member; otherwise, `nil`. In some cases, the returned
  ///    element may be distinguishable from `newMember` by identity comparison
  ///    or some other means.
  ///
  /// - Complexity: This operation is expected to perform O(1)
  ///    hashing/comparison operations on the element type, provided that
  ///    `Element` properly implements hashing.
  @discardableResult
  @inlinable
  public mutating func update(with newMember: __owned Element) -> Element? {
    let hash = _Hash(newMember)
    let r = _root.updateValue(.top, forKey: newMember, hash) {
      $0.initialize(to: (newMember, ()))
    }
    if r.inserted { return nil }
    return _UnsafeHandle.update(r.leaf) {
      let p = $0.itemPtr(at: r.slot)
      let old = p.move().key
      p.initialize(to: (newMember, ()))
      return old
    }
  }
}
