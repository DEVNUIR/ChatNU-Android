# Flutter validation

Widget/unit test output from the latest migration check:

```text

✅ /home/runner/work/ChatNU-Android/ChatNU-Android/flutter/test/product_identity_test.dart: Persian locale exposes RTL messenger navigation
::group::❌ /home/runner/work/ChatNU-Android/ChatNU-Android/flutter/test/chat_screen_test.dart: desktop renders the real messenger shell and sends locally (failed)
══╡ EXCEPTION CAUGHT BY FLUTTER TEST FRAMEWORK ╞════════════════════════════════════════════════════
The following assertion was thrown running a test:
pumpAndSettle timed out

When the exception was thrown, this was the stack:
#0      WidgetTester.pumpAndSettle.<anonymous closure> (package:flutter_test/src/widget_tester.dart:717:11)
<asynchronous suspension>
#1      TestAsyncUtils.guard.<anonymous closure> (package:flutter_test/src/test_async_utils.dart:130:27)
<asynchronous suspension>
#2      main.<anonymous closure> (file:///home/runner/work/ChatNU-Android/ChatNU-Android/flutter/test/chat_screen_test.dart:37:5)
<asynchronous suspension>
#3      testWidgets.<anonymous closure>.<anonymous closure> (package:flutter_test/src/widget_tester.dart:192:15)
<asynchronous suspension>
#4      TestWidgetsFlutterBinding._runTestBody (package:flutter_test/src/binding.dart:1952:5)
<asynchronous suspension>
<asynchronous suspension>
(elided one frame from package:stack_trace)

The test description was:
  desktop renders the real messenger shell and sends locally
════════════════════════════════════════════════════════════════════════════════════════════════════
Test failed. See exception logs above.
The test description was: desktop renders the real messenger shell and sends locally

::endgroup::
✅ /home/runner/work/ChatNU-Android/ChatNU-Android/flutter/test/chat_screen_test.dart: phone uses conversation list to chat navigation

::error::2 tests passed, 1 failed.
```
