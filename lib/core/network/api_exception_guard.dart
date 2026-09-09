import 'package:dio/dio.dart';

import '../errors/error_mapper.dart';
import '../errors/exceptions.dart';

Future<T> guardApiCall<T>(Future<T> Function() call) async {
  try {
    return await call();
  } on DioException catch (e) {
    final error = e.error;
    if (error is AppException) throw error;
    throw AppException(
      ErrorMapper.userMessage(e),
      statusCode: e.response?.statusCode,
      cause: e,
    );
  } catch (e) {
    if (e is AppException) rethrow;
    throw AppException(ErrorMapper.userMessage(e), cause: e);
  }
}
