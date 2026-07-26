import 'package:approval_tests_flutter/src/approval_session.dart';

/// Register class types for tests with Find.byType
///
/// Call this from `setUpAll`. Registrations belong to the current capture
/// session, so `ApprovalWidgets.tearDownAll()` clears them and a later group
/// does not inherit them.
void registerTypes(Set<Type> classTypes) =>
    currentApprovalSession.registerTypes(classTypes);
