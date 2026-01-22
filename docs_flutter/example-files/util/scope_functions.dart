/// File from: https://github.com/YusukeIwaki/dart-kotlin_flavor
ReturnType run<ReturnType>(ReturnType Function() operation) {
  return operation();
}

extension ScopeFunctionsForObject<T extends Object> on T {
  /// Behaves like Kotlin `.let()`
  ReturnType ifNotNull<ReturnType>(ReturnType Function(T it) operationFor) {
    return operationFor(this);
  }

  T also(void Function(T self) operationFor) {
    operationFor(this);
    return this;
  }
}
