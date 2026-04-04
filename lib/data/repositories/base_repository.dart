import 'package:dio/dio.dart';
import '../../core/error/failures.dart';

abstract class BaseRepository {
  Future<T> handleApiCall<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      if (e.error is Failure) {
        throw e.error as Failure;
      }
      throw ServerFailure(e.message ?? 'Unknown network error');
    } catch (e) {
      if (e is Failure) rethrow;
      throw ServerFailure(e.toString());
    }
  }
}
