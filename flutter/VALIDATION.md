# Flutter validation

Analyzer output from the latest migration check:

```text
Analyzing flutter...                                            

  error • The getter 'history' isn't defined for the type 'ChatNuRoutes'. Try importing the library that defines 'history', correcting the name to the name of an existing getter, or defining a getter or field named 'history' • lib/features/chat/presentation/chat_navigation.dart:196:49 • undefined_getter
  error • The getter 'models' isn't defined for the type 'ChatNuRoutes'. Try importing the library that defines 'models', correcting the name to the name of an existing getter, or defining a getter or field named 'models' • lib/features/chat/presentation/chat_navigation.dart:237:49 • undefined_getter
  error • The getter 'history' isn't defined for the type 'ChatNuRoutes'. Try importing the library that defines 'history', correcting the name to the name of an existing getter, or defining a getter or field named 'history' • lib/features/chat/presentation/chat_navigation.dart:589:44 • undefined_getter
  error • The getter 'models' isn't defined for the type 'ChatNuRoutes'. Try importing the library that defines 'models', correcting the name to the name of an existing getter, or defining a getter or field named 'models' • lib/features/chat/presentation/chat_navigation.dart:594:44 • undefined_getter

4 issues found. (ran in 12.9s)
```
