enum TryOnStatus { queued, processing, succeeded, failed }

class TryOnGeneration {
  const TryOnGeneration({
    required this.id,
    required this.status,
    required this.createdAt,
    this.resultImagePath,
    this.errorMessage,
    this.isRemoteResult = false,
  });

  final String id;
  final TryOnStatus status;
  final DateTime createdAt;
  final String? resultImagePath;
  final String? errorMessage;
  final bool isRemoteResult;

  bool get isTerminal =>
      status == TryOnStatus.succeeded || status == TryOnStatus.failed;
}
