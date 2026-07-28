// True browser E2E entry point. The shared workflow body also has a
// `flutter test --platform chrome` runner for CI without ChromeDriver.
import '../test/functional/app_workflows.dart' as workflows;

void main() => workflows.main();
