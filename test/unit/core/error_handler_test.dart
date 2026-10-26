import 'package:flutter_test/flutter_test.dart';
import 'package:troona/core/error/error_handler.dart';
import 'package:troona/core/error/exceptions.dart';
import 'package:troona/core/error/failures.dart';

void main() {
  test('known exceptions keep their own failure type', () {
    expect(
      ErrorHandler.handle(const PermissionException(), StackTrace.empty),
      isA<PermissionFailure>(),
    );
  });

  test('unknown errors are unexpected, not cache failures', () {
    final failure = ErrorHandler.handle(StateError('boom'), StackTrace.empty);
    expect(failure, isA<UnexpectedFailure>());
    expect(failure.message, contains('boom'));
  });
}
