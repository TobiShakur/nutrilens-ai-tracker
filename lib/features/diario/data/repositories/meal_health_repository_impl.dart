import '../../../../core/failures/scanner_failure.dart';
import '../../../scanner/data/datasources/scanner_firebase_ai_datasource.dart';
import '../../../scanner/data/datasources/scanner_remote_datasource.dart';
import '../../domain/entities/meal_health_evaluation.dart';
import '../../domain/repositories/meal_health_repository.dart';

/// Data repository bridging [MealHealthRepository] to [ScannerRemoteDataSource].
class MealHealthRepositoryImpl implements MealHealthRepository {
  final ScannerRemoteDataSource _remoteDataSource;

  MealHealthRepositoryImpl({ScannerRemoteDataSource? remoteDataSource})
    : _remoteDataSource = remoteDataSource ?? ScannerFirebaseAiDataSourceImpl();

  @override
  Future<MealHealthResult> evaluateMealHealth(
    MealHealthEvaluationInput input, {
    String languageCode = 'es',
  }) async {
    try {
      final dto = await _remoteDataSource.evaluarHealthScore(
        input: input,
        languageCode: languageCode,
      );
      return MealHealthSuccess(dto.toEntity());
    } on ScannerFailure catch (failure) {
      return MealHealthError(failure);
    } catch (_) {
      return const MealHealthError(ScannerNetworkFailure());
    }
  }
}
