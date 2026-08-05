# Contributing

Use focused branches and conventional commit messages.

```text
feature/<scope>
fix/<scope>
docs/<scope>
```

Before opening a pull request:

```bash
./gradlew lint test assembleDebug
```

Keep UI changes accessible, respect reduced motion, avoid hardcoded server addresses outside build configuration, and never add plaintext secrets or private keys to the repository.
