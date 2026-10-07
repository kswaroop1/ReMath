import '../domain/progress_repository.dart';
import 'in_memory_progress_repository.dart';

Future<ProgressRepository> openProgressRepository() async =>
    InMemoryProgressRepository();
