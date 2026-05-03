import '../../../core/errors/exceptions.dart';
import '../../../core/constants/app_constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// untuk menangani riwayat transaksi.
class TransactionRemoteDatasource {
  final FirebaseFirestore _firestore;

  TransactionRemoteDatasource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> getTransactions({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _firestore.collection(AppConstants.transactionsCollection);

      if (startDate != null) {
        query = query.where(
          'createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
        );
      }

      if (endDate != null) {
        query = query.where(
          'createdAt',
          isLessThanOrEqualTo: Timestamp.fromDate(endDate),
        );
      }

      query = query.orderBy('createdAt', descending: true);

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      throw const ServerException('Gagal mengambil riwayat transaksi');
    }
  }
}
