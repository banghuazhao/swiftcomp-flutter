import '../entities/message.dart';
import '../entities/thread_run.dart';

abstract class ThreadRunsRepository {
    Future<ThreadRun> createRun(String threadId, String assistantId);
    Future<ThreadRun> createMessageAndRun(String assistantId, String message);
    Stream<Message> createRunStream(String threadId, String assistantId);
    Stream<Message> createMessageAndRunStream(String assistantId, String message);
}