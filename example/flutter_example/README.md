# approval_tests_flutter example

This app demonstrates where approval testing fits as a Flutter codebase grows.
It contains a minimal counter and a representative orders vertical slice with
domain, data, presentation, state-management, and test boundaries.

## Project structure

```text
lib/
├── app.dart
├── main.dart
└── features/
    ├── counter/presentation/
    │   ├── counter_controller.dart
    │   └── counter_page.dart
    └── orders/
        ├── domain/
        │   ├── order.dart
        │   ├── orders_load_exception.dart
        │   └── orders_repository.dart
        ├── data/demo_orders_repository.dart
        └── presentation/
            ├── orders_controller.dart
            ├── orders_state.dart
            ├── orders_screen.dart
            └── orders_view.dart
test/
├── features/
│   ├── counter/presentation/
│   │   └── counter_page_test.dart
│   └── orders/
│       ├── domain/order_test.dart
│       └── presentation/
│           ├── orders_controller_test.dart
│           ├── orders_screen_test.dart
│           └── orders_screen_test.*.approved.txt
└── support/
    ├── fake_orders_repository.dart
    └── order_fixtures.dart
```

## What each level demonstrates

- `counter` is the smallest useful example: inject a controller, assert the
  exact scalar transition, and approve the complete UI before and after it.
- `orders/domain` has immutable data, a repository contract, and a typed load
  exception without Flutter imports.
- `orders/data` implements the domain contract; only the composition root
  imports it.
- `orders/presentation` has sealed loading, loaded, and failure states. The
  screen owns controller setup and disposal, including replacing it when its
  injected repository changes; the view renders states.
- Controller unit tests cover state transitions. Screen approval tests cover
  loading, loaded, and failure UI. Empty and retry behavior use focused
  assertions, avoiding snapshots that add little review value.

`FakeOrdersRepository` and the named order fixtures are shared by controller
and screen tests, so scenario data does not drift between test layers. Replace
the controller with BLoC, Cubit, Riverpod, or Provider without changing the
repository boundary or snapshot workflow.

Run the example approvals from this directory:

```sh
flutter test
```

The first run creates the `*.approved.txt` files. Read them before committing:
they are reviewed test expectations. A mismatch leaves a
`*.received.txt` file for inspection. Run
`dart run approval_tests:review` from this directory to review and promote an
intentional change, then rerun `flutter test`.

For a larger app, mirror `lib/features/...` under `test/features/...`, keep
approved files beside the owning widget test, and snapshot only core states.
Keep business rules in unit tests and centralize realistic scenario data under
`test/support` or named fixture files.

Approval capture methods do not pump implicitly. Prepare the widget tree before
calling `approvalTest()`. For `tapWidget()`, choose a
`WidgetActionPumpPolicy` explicitly in new tests when the action needs no pump,
one frame, a fixed duration, or bounded settling.

See the package [README](../../README.md) for the five-minute setup, guidance on
when approvals fit, semantics and golden examples, and the team snapshot
policy.
