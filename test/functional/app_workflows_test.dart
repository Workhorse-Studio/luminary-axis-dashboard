// Browser-functional runner for environments without a standalone WebDriver.
// The canonical suite remains executable through `flutter drive` as a true E2E
// test; this wrapper lets CI run the same workflows through `flutter test`.
import 'app_workflows.dart' as workflows;

void main() => workflows.main(useIntegrationBinding: false);
