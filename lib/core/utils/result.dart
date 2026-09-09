/// Result type for domain/data operations without throwing across layers.
sealed class Result<T> {
  const Result();

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is ResultFailure<T>;

  R when<R>({
    required R Function(T data) success,
    required R Function(Object error) failure,
  }) {
    return switch (this) {
      Success(:final data) => success(data),
      ResultFailure(:final error) => failure(error),
    };
  }
}

final class Success<T> extends Result<T> {
  const Success(this.data);
  final T data;
}

final class ResultFailure<T> extends Result<T> {
  const ResultFailure(this.error);
  final Object error;
}
