import 'package:dio/dio.dart';
import 'package:logging/logging.dart';

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
    var extra = RetryOptions.fromExtra(err.requestOptions);

    var shouldRetry = extra.retries > 0 && await extra.retryEvaluator(err);
    if (shouldRetry) {
      if (extra.retryInterval.inMilliseconds > 0) {
        await Future.delayed(extra.retryInterval);
      }

      // Update options to decrease retry count before new try
      extra = extra.copyWith(retries: extra.retries - 1);
      err.requestOptions.extra = err.requestOptions.extra
        ..addAll(extra.toExtra());

      try {
        logger?.warning(
            "[${err.requestOptions.uri}] An error occured during request, "
            "trying a again (remaining tries: ${extra.retries}, error: ${err.error})");
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
