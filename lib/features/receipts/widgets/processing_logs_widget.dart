import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../../../shared/models/processing_log_model.dart';
import '../../../core/constants/app_constants.dart';

/// Processing logs widget with real-time streaming and animations
class ProcessingLogsWidget extends ConsumerStatefulWidget {
  final List<ProcessingLogModel> processLogs;
  final String? currentStage;
  final bool showDetailedLogs;
  final DateTime? startTime;

  const ProcessingLogsWidget({
    super.key,
    required this.processLogs,
    this.currentStage,
    this.showDetailedLogs = false,
    this.startTime,
  });

  @override
  ConsumerState<ProcessingLogsWidget> createState() =>
      _ProcessingLogsWidgetState();
}

class _ProcessingLogsWidgetState extends ConsumerState<ProcessingLogsWidget>
    with TickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _expandController;
  late AnimationController _streamController;
  late Animation<double> _expandAnimation;
  late Animation<double> _fadeAnimation;

  final ScrollController _scrollController = ScrollController();
  List<ProcessingLogModel> _displayedLogs = [];
  bool _isStreaming = true;
  Timer? _elapsedTimer;
  int _elapsedSeconds = 0;

  @override
  void initState() {
    super.initState();

    _expandController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _streamController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOut,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _streamController,
      curve: Curves.easeOut,
    );

    // Auto-expand when logs start appearing
    if (widget.processLogs.isNotEmpty) {
      _isExpanded = true;
      _expandController.forward();
    }

    // Start elapsed time timer
    if (widget.startTime != null) {
      _startElapsedTimer();
    }

    // Initialize streaming
    _streamLogs();
  }

  @override
  void didUpdateWidget(ProcessingLogsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Auto-expand when logs start appearing
    if (widget.processLogs.isNotEmpty && !_isExpanded) {
      setState(() {
        _isExpanded = true;
      });
      _expandController.forward();
    }

    // Update streaming when logs change
    if (widget.processLogs != oldWidget.processLogs) {
      _streamLogs();
    }

    // Stop streaming when processing is complete
    if (widget.currentStage == 'COMPLETE' || widget.currentStage == 'ERROR') {
      _isStreaming = false;
      setState(() {
        _displayedLogs = widget.processLogs;
      });
    }

    // Start/stop timer based on startTime
    if (widget.startTime != oldWidget.startTime) {
      if (widget.startTime != null) {
        _startElapsedTimer();
      } else {
        _elapsedTimer?.cancel();
      }
    }
  }

  @override
  void dispose() {
    _expandController.dispose();
    _streamController.dispose();
    _scrollController.dispose();
    _elapsedTimer?.cancel();
    super.dispose();
  }

  void _startElapsedTimer() {
    _elapsedTimer?.cancel();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (widget.startTime != null) {
        setState(() {
          _elapsedSeconds = DateTime.now()
              .difference(widget.startTime!)
              .inSeconds;
        });
      }
    });
  }

  void _streamLogs() {
    if (!_isStreaming || widget.processLogs.length <= _displayedLogs.length) {
      return;
    }

    final newLogs = widget.processLogs.skip(_displayedLogs.length).toList();
    final delay = newLogs.length > 5 ? 50 : 150; // Faster for many logs

    for (int i = 0; i < newLogs.length; i++) {
      Timer(Duration(milliseconds: i * delay), () {
        if (mounted) {
          setState(() {
            _displayedLogs.add(newLogs[i]);
          });
          _streamController.forward().then((_) {
            _streamController.reset();
          });
          _scrollToBottom();
        }
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
    if (_isExpanded) {
      _expandController.forward();
    } else {
      _expandController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          _buildHeader(theme),
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: _buildLogsContent(theme),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return InkWell(
      onTap: _toggleExpanded,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        decoration: BoxDecoration(
          color: theme.cardColor.withValues(alpha: 0.5),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          border: Border(
            bottom: BorderSide(
              color: theme.dividerColor.withValues(alpha: 0.2),
            ),
          ),
        ),
        child: Row(
          children: [
            _getStageIcon(theme),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Processing Details',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (widget.currentStage != null) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStageColor(
                          widget.currentStage!,
                        ).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getStageColor(
                            widget.currentStage!,
                          ).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        ProcessingStages.getStage(widget.currentStage!).name,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: _getStageColor(widget.currentStage!),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (widget.startTime != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, size: 8, color: Colors.green),
                    const SizedBox(width: 6),
                    Text(
                      'Live',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.access_time,
                      size: 12,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${_elapsedSeconds}s',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              '${_displayedLogs.length}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(width: 4),
            AnimatedRotation(
              turns: _isExpanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 300),
              child: Icon(
                Icons.keyboard_arrow_down,
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogsContent(ThemeData theme) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: _displayedLogs.isEmpty
          ? _buildEmptyState(theme)
          : _buildLogsList(theme),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Waiting for processing logs...',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogsList(ThemeData theme) {
    return ListView.builder(
      controller: _scrollController,
      itemCount: _displayedLogs.length + (_isStreaming ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _displayedLogs.length) {
          // Streaming indicator
          return _buildStreamingIndicator(theme);
        }

        final log = _displayedLogs[index];
        return _buildLogItem(theme, log, index);
      },
    );
  }

  Widget _buildLogItem(ThemeData theme, ProcessingLogModel log, int index) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.cardColor.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(top: 6),
              decoration: BoxDecoration(
                color: _getStageColor(log.stepName ?? 'INFO'),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        (log.stepName ?? 'INFO').toUpperCase(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: _getStageColor(log.stepName ?? 'INFO'),
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatTime(log.createdAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color?.withValues(
                            alpha: 0.6,
                          ),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    log.statusMessage,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withValues(
                        alpha: 0.8,
                      ),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreamingIndicator(ThemeData theme) {
    if (!_isStreaming || _displayedLogs.length >= widget.processLogs.length) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Streaming logs...',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _getStageIcon(ThemeData theme) {
    if (widget.currentStage == null) {
      return Icon(Icons.info_outline, size: 20, color: theme.primaryColor);
    }

    switch (widget.currentStage) {
      case 'START':
      case 'FETCH':
        return Icon(Icons.cloud_upload, size: 20, color: Colors.blue);
      case 'PROCESSING':
      case 'GEMINI':
        return Icon(Icons.psychology, size: 20, color: Colors.purple);
      case 'SAVE':
        return Icon(Icons.save, size: 20, color: Colors.orange);
      case 'COMPLETE':
        return Icon(Icons.check_circle, size: 20, color: Colors.green);
      case 'ERROR':
        return Icon(Icons.error, size: 20, color: Colors.red);
      default:
        return Icon(Icons.info_outline, size: 20, color: theme.primaryColor);
    }
  }

  Color _getStageColor(String stage) {
    switch (stage) {
      case 'START':
      case 'FETCH':
        return Colors.blue;
      case 'PROCESSING':
      case 'GEMINI':
        return Colors.purple;
      case 'SAVE':
        return Colors.orange;
      case 'COMPLETE':
        return Colors.green;
      case 'ERROR':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}:'
        '${dateTime.second.toString().padLeft(2, '0')}';
  }
}
