import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import 'options.dart';

/// An interceptor that will try to send failed request again
class RetryInterceptor extends Interceptor {
  final Dio dio;
  final Logger? logger;
  final RetryOptions options;

  RetryInterceptor({required this.dio, this.logger, RetryOptions? options})
      : options = options ?? const RetryOptions();

  @override
  Future<void> onError(DioError err, handler) async {
    var currentCycle = 0;
    var retryCount = options.retries;

    var shouldRetry = retryCount > 0 && retryCount > currentCycle;
    if (shouldRetry) {
      await Future.delayed(options.retryInterval);

      // Update options to decrease retry count before new try
      currentCycle = currentCycle + 1;

      try {
        logger?.w(
          '[${err.requestOptions.uri}] An error occured during request, '
          'trying a again (remaining tries: ${retryCount - currentCycle}, error: ${err.error})',
        );
        // We retry with the updated options
        return handler.resolve(Response(
          // err.request.path,
          requestOptions: err.requestOptions,
          data: err.requestOptions.data,
        ));
      } catch (e) {
        return handler.next(err);
      }
    }

    return handler.next(err);
  }
}
