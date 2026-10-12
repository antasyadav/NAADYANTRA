import '../models/assessment.dart';
import '../models/common.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../../core/errors/exceptions.dart';

class AssessmentRepository {
  final ApiClient _apiClient;

  AssessmentRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  Future<PaginatedResponse<Assessment>> getAssessments({
    int page = 1,
    int pageSize = 50,
    String? traineeId,
    String? rubricId,
    String? outcome,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
      };
      if (traineeId != null) queryParams['trainee_id'] = traineeId;
      if (rubricId != null) queryParams['rubric_id'] = rubricId;
      if (outcome != null) queryParams['outcome'] = outcome;

      final response = await _apiClient.get(
        ApiConstants.assessments,
        queryParameters: queryParams,
      );

      return PaginatedResponse<Assessment>.fromJson(
        response.data,
        (json) => Assessment.fromJson(json as Map<String, dynamic>),
      );
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to fetch assessments');
    }
  }

  Future<Assessment> getAssessment(String assessmentId) async {
    try {
      final response = await _apiClient.get(
        ApiConstants.assessment(assessmentId),
      );
      return Assessment.fromJson(response.data);
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to fetch assessment');
    }
  }

  Future<PaginatedResponse<AssessmentRubric>> getRubrics({
    int page = 1,
    int pageSize = 50,
    bool? isActive,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
      };
      if (isActive != null) queryParams['is_active'] = isActive;

      final response = await _apiClient.get(
        ApiConstants.assessmentRubrics,
        queryParameters: queryParams,
      );

      return PaginatedResponse<AssessmentRubric>.fromJson(
        response.data,
        (json) => AssessmentRubric.fromJson(json as Map<String, dynamic>),
      );
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to fetch rubrics');
    }
  }
}
