// This file runs all backup exception tests
// Individual test files are organized by exception type for better maintainability

import 'auth_exception_test.dart' as auth_exception_tests;
import 'backup_exception_test.dart' as backup_exception_tests;
import 'configuration_exception_test.dart' as configuration_exception_tests;
import 'file_operation_exception_test.dart' as file_operation_exception_tests;
import 'network_exception_test.dart' as network_exception_tests;
import 'quota_exception_test.dart' as quota_exception_tests;
import 'service_exception_test.dart' as service_exception_tests;

void main() {
  auth_exception_tests.main();
  backup_exception_tests.main();
  configuration_exception_tests.main();
  file_operation_exception_tests.main();
  network_exception_tests.main();
  quota_exception_tests.main();
  service_exception_tests.main();
}
