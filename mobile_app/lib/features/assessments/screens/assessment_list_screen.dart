import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/assessment.dart';
import '../../../shared/models/common.dart';
import '../../../shared/services/providers.dart';

class AssessmentListScreen extends ConsumerWidget {
  const AssessmentListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assessmentsAsync = ref.watch(assessmentsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Assessments')),
      body: assessmentsAsync.when(
        data: (paginatedResponse) {
          if (paginatedResponse.items.isEmpty) {
            return _buildEmptyState(context);
          }

          return ListView.builder(
            itemCount: paginatedResponse.items.length,
            itemBuilder: (context, index) {
              final assessment = paginatedResponse.items[index];
              return _buildAssessmentCard(context, assessment);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorState(context, error.toString()),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.assignment, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'No Assessments Found',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          const Text(
            'Assessments will appear here after trainer review',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Failed to Load Assessments',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error,
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssessmentCard(BuildContext context, Assessment assessment) {
    final outcomeColor = _getOutcomeColor(assessment.outcome);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: outcomeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: outcomeColor),
                  ),
                  child: Text(
                    assessment.outcome.toUpperCase(),
                    style: TextStyle(
                      color: outcomeColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    assessment.assessmentId,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow(context, 'Trainee', assessment.traineeId),
            _buildInfoRow(
              context,
              'Rubric',
              '${assessment.rubricId} v${assessment.rubricVersion}',
            ),
            _buildInfoRow(context, 'Session', '#${assessment.sessionId}'),
            if (assessment.score != null)
              _buildInfoRow(
                context,
                'Score',
                '${assessment.score}/${assessment.maxScore}',
              ),
            if (assessment.scoringExplanation != null) ...[
              const SizedBox(height: 8),
              Text(
                assessment.scoringExplanation!,
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Color _getOutcomeColor(String outcome) {
    switch (outcome.toLowerCase()) {
      case 'competent':
        return Colors.green;
      case 'needs_improvement':
        return Colors.orange;
      case 'not_assessable':
        return Colors.grey;
      case 'incomplete':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}

// Provider for assessments
final assessmentsProvider = FutureProvider<PaginatedResponse<Assessment>>((
  ref,
) async {
  final assessmentRepo = ref.watch(assessmentRepositoryProvider);
  return await assessmentRepo.getAssessments();
});
