#!/bin/sh

set -eu

APP_HOME=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
CLASSPATH="$APP_HOME/gradle/wrapper/gradle-wrapper.jar"
WRAPPER_URL="https://raw.githubusercontent.com/gradle/gradle/v8.13.0/gradle/wrapper/gradle-wrapper.jar"
WRAPPER_SHA256="81a82aaea5abcc8ff68b3dfcb58b3c3c429378efd98e7433460610fecd7ae45f"

verify_wrapper() {
  if command -v sha256sum >/dev/null 2>&1; then
    ACTUAL=$(sha256sum "$CLASSPATH" | awk '{print $1}')
  elif command -v shasum >/dev/null 2>&1; then
    ACTUAL=$(shasum -a 256 "$CLASSPATH" | awk '{print $1}')
  else
    echo "A SHA-256 tool is required to verify the Gradle wrapper." >&2
    return 1
  fi
  [ "$ACTUAL" = "$WRAPPER_SHA256" ] || {
    echo "Gradle wrapper checksum mismatch." >&2
    return 1
  }
}

download_wrapper() {
  mkdir -p "$(dirname "$CLASSPATH")"
  TMP="$CLASSPATH.tmp.$$"
  trap 'rm -f "$TMP"' EXIT HUP INT TERM
  if command -v curl >/dev/null 2>&1; then
    curl --fail --location --silent --show-error "$WRAPPER_URL" --output "$TMP"
  elif command -v wget >/dev/null 2>&1; then
    wget --quiet --output-document="$TMP" "$WRAPPER_URL"
  else
    echo "curl or wget is required to bootstrap Gradle." >&2
    exit 1
  fi
  mv "$TMP" "$CLASSPATH"
  trap - EXIT HUP INT TERM
}

if [ ! -f "$CLASSPATH" ]; then
  echo "Bootstrapping the verified Gradle 8.13 wrapper from the official Gradle repository..."
  download_wrapper
fi

if ! verify_wrapper; then
  rm -f "$CLASSPATH"
  echo "Refusing to execute an unverified Gradle wrapper." >&2
  exit 1
fi

if [ -n "${JAVA_HOME:-}" ]; then
  JAVACMD="$JAVA_HOME/bin/java"
else
  JAVACMD=java
fi

exec "$JAVACMD" -classpath "$CLASSPATH" org.gradle.wrapper.GradleWrapperMain "$@"
