import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/category_entity.dart';

/// Model data kategori untuk serialisasi dari/ke Firestore.
class CategoryModel extends CategoryEntity {
  const CategoryModel({
    required super.id,
    required super.name,
    required super.ownerId,
    super.createdAt,
  });

  factory CategoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CategoryModel(
      id: doc.id,
      name: data['name'] ?? '',
      ownerId: data['ownerId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestoreNew() {
    return {
      'name': name,
      'ownerId': ownerId,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toFirestoreUpdate() {
    return {
      'name': name,
    };
  }
}
