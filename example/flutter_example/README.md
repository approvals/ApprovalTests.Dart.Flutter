# approval_tests_flutter example

This app demonstrates widget-tree approval testing against the local
`approval_tests_flutter` package.

Run the example approvals from this directory:

```sh
flutter test
```

The test captures the counter before and after interaction. Its
`*.approved.txt` files are committed as the reviewed baseline; a mismatch leaves
a `*.received.txt` file for inspection.

Approval capture methods do not pump implicitly. Prepare the widget tree before
calling `approvalTest()`. For `tapWidget()`, choose a
`WidgetActionPumpPolicy` explicitly in new tests when the action needs no pump,
one frame, a fixed duration, or bounded settling.

See the package [README](../../README.md) for complete setup and migration
examples.
