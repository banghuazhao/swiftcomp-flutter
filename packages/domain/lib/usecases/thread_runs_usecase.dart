import '../entities/message.dart';
import '../entities/thread_run.dart';
import '../repositories_abstract/thread_runs_repository.dart';

abstract class ThreadRunsUseCase {
  Future<ThreadRun> createRun(String threadId, String assistantId);

  Future<ThreadRun> createMessageAndRun(String assistantId, String message);

  Stream<Message> createRunStream(String threadId, String assistantId);

  Stream<Message> createMessageAndRunStream(String assistantId, String message);
}

class ThreadRunsUseCaseImpl implements ThreadRunsUseCase {
  final ThreadRunsRepository repository;

  ThreadRunsUseCaseImpl({required this.repository});

  @override
  Future<ThreadRun> createRun(String threadId, String assistantId) async {
    return await repository.createRun(threadId, assistantId);
  }

  @override
  Future<ThreadRun> createMessageAndRun(
      String assistantId, String message) async {
    return await repository.createMessageAndRun(assistantId, message);
  }

  @override
  Stream<Message> createRunStream(String threadId, String assistantId) {
    return repository.createRunStream(threadId, assistantId);
  }

  @override
  Stream<Message> createMessageAndRunStream(
      String assistantId, String message) {
    return repository.createMessageAndRunStream(assistantId, message);
  }
}
