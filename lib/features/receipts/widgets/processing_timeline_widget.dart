import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/processing_log_model.dart';
import '../../../core/constants/app_constants.dart';

/// Enhanced processing timeline widget matching React app functionality
class ProcessingTimelineWidget extends ConsumerStatefulWidget {
  final String? currentStage;
  final List<String> stageHistory;
  final int uploadProgress;
  final int? fileSize;
  final String processingMethod;
  final String? modelId;
  final DateTime? startTime;
  final bool isProgressUpdating;

  const ProcessingTimelineWidget({
    super.key,
    this.currentStage,
    this.stageHistory = const [],
    this.uploadProgress = 0,
    this.fileSize,
    this.processingMethod = 'ai-vision',
    this.modelId,
    this.startTime,
    this.isProgressUpdating = false,
  });

  @override
  ConsumerState<ProcessingTimelineWidget> createState() =>
      _ProcessingTimelineWidgetState();
}

class _ProcessingTimelineWidgetState
    extends ConsumerState<ProcessingTimelineWidget>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _pulseController;
  late Animation<double> _progressAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.isProgressUpdating) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(ProcessingTimelineWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.uploadProgress != oldWidget.uploadProgress) {
      _progressController.animateTo(widget.uploadProgress / 100.0);
    }
    if (widget.isProgressUpdating != oldWidget.isProgressUpdating) {
      if (widget.isProgressUpdating) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.stop();
        _pulseController.reset();
      }
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final orderedStages = ProcessingStages.orderedStages;
    final currentStageIndex = widget.currentStage != null
        ? orderedStages.indexOf(widget.currentStage!)
        : -1;

    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          // Header with progress info
          _buildHeader(theme),
          const SizedBox(height: 16),

          // Progress bar
          _buildProgressBar(theme),
          const SizedBox(height: 20),

          // Stage timeline
          _buildStageTimeline(theme, orderedStages, currentStageIndex),

          // Time estimate
          if (widget.startTime != null) ...[
            const SizedBox(height: 16),
            _buildTimeEstimate(theme),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    final remainingTime = _calculateRemainingTime();

    return Row(
      children: [
        Icon(Icons.schedule, size: 16, color: theme.textTheme.bodySmall?.color),
        const SizedBox(width: 8),
        Text(
          remainingTime != null ? '$remainingTime remaining' : 'Processing...',
          style: theme.textTheme.bodySmall,
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: theme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.primaryColor.withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            'high confidence',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.currentStage != null
                  ? ProcessingStages.getStage(widget.currentStage!).name
                  : 'Uploading',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${widget.uploadProgress}%',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        AnimatedBuilder(
          animation: _progressAnimation,
          builder: (context, child) {
            return LinearProgressIndicator(
              value: _progressAnimation.value * (widget.uploadProgress / 100.0),
              backgroundColor: theme.dividerColor.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
              minHeight: 6,
            );
          },
        ),
      ],
    );
  }

  Widget _buildStageTimeline(
    ThemeData theme,
    List<String> orderedStages,
    int currentStageIndex,
  ) {
    return Row(
      children: orderedStages.asMap().entries.map((entry) {
        final index = entry.key;
        final stageName = entry.value;
        final stage = ProcessingStages.getStage(stageName);
        final isCompleted = index < currentStageIndex;
        final isActive = index == currentStageIndex;
        final isLast = index == orderedStages.length - 1;

        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: _buildStageIndicator(
                  theme,
                  stage,
                  isCompleted,
                  isActive,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: _buildStageConnector(theme, isCompleted || isActive),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStageIndicator(
    ThemeData theme,
    ProcessingStage stage,
    bool isCompleted,
    bool isActive,
  ) {
    Color getColor() {
      if (isCompleted) return Colors.green;
      if (isActive) return theme.primaryColor;
      return theme.dividerColor;
    }

    Widget getIcon() {
      if (isCompleted) {
        return const Icon(Icons.check, size: 16, color: Colors.white);
      }
      if (isActive) {
        return AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: widget.isProgressUpdating ? _pulseAnimation.value : 1.0,
              child: SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            );
          },
        );
      }
      return Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      );
    }

    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: getColor(),
            shape: BoxShape.circle,
            border: Border.all(color: getColor(), width: 2),
          ),
          child: Center(child: getIcon()),
        ),
        const SizedBox(height: 8),
        Text(
          stage.name.toUpperCase(),
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: getColor(),
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildStageConnector(ThemeData theme, bool isActive) {
    return Container(
      height: 2,
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: isActive ? theme.primaryColor : theme.dividerColor,
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }

  Widget _buildTimeEstimate(ThemeData theme) {
    final elapsed = DateTime.now().difference(widget.startTime!);
    final elapsedSeconds = elapsed.inSeconds;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.access_time,
            size: 14,
            color: theme.textTheme.bodySmall?.color,
          ),
          const SizedBox(width: 6),
          Text(
            'Live • ${elapsedSeconds}s',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String? _calculateRemainingTime() {
    if (widget.startTime == null || widget.uploadProgress == 0) return null;

    final elapsed = DateTime.now().difference(widget.startTime!);
    final elapsedSeconds = elapsed.inSeconds;

    if (elapsedSeconds < 5) return null; // Not enough data

    final progressRate = widget.uploadProgress / elapsedSeconds;
    final remainingProgress = 100 - widget.uploadProgress;
    final estimatedRemainingSeconds = (remainingProgress / progressRate)
        .round();

    if (estimatedRemainingSeconds <= 0) return null;

    if (estimatedRemainingSeconds < 60) {
      return '$estimatedRemainingSeconds seconds';
    } else {
      final minutes = (estimatedRemainingSeconds / 60).round();
      return '$minutes minute${minutes > 1 ? 's' : ''}';
    }
  }
}
