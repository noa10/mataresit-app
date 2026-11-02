import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/processing_log_model.dart';

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
    final colors = theme.colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        children: [
          _buildHeader(theme),
          Divider(height: 1, thickness: 1, color: colors.outlineVariant),
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: _buildLogsContent(theme),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    final colors = theme.colorScheme;

    return InkWell(
      onTap: _toggleExpanded,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
        child: Row(
          children: [
            _getStageIcon(theme),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Processing Details',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface,
                    ),
                  ),
                  if (widget.currentStage != null) ...[
                    const SizedBox(height: 4),
                    _buildStagePill(theme, widget.currentStage!),
                  ],
                ],
              ),
            ),
            if (widget.startTime != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: colors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Live',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${_elapsedSeconds}s',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontFamily: 'IBMPlexMono',
                        fontSize: 10,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              '${_displayedLogs.length}',
              style: theme.textTheme.labelSmall?.copyWith(
                fontFamily: 'IBMPlexMono',
                fontSize: 10,
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 4),
            AnimatedRotation(
              turns: _isExpanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 300),
              child: Icon(
                Icons.keyboard_arrow_down,
                size: 20,
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStagePill(ThemeData theme, String stage) {
    final colors = theme.colorScheme;
    final foreground = _stageColor(theme, stage);
    final background = stage == 'ERROR'
        ? colors.errorContainer
        : stage == 'COMPLETE'
        ? colors.primaryContainer
        : colors.tertiaryContainer;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: foreground,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            ProcessingStages.getStage(stage).name,
            style: theme.textTheme.labelSmall?.copyWith(
              color: foreground,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogsContent(ThemeData theme) {
    return Container(
      height: 200,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: _displayedLogs.isEmpty
          ? _buildEmptyState(theme)
          : _buildLogsList(theme),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    final colors = theme.colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Waiting for processing logs...',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
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
    final colors = theme.colorScheme;
    final stageColor = _stageColor(theme, log.stepName ?? 'INFO');

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (index > 0)
            Divider(height: 1, thickness: 1, color: colors.outlineVariant),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 5,
                  height: 5,
                  margin: const EdgeInsets.only(top: 5),
                  decoration: BoxDecoration(
                    color: stageColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              (log.stepName ?? 'INFO').toUpperCase(),
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: stageColor,
                                fontFamily: 'IBMPlexMono',
                                fontSize: 10,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatTime(log.createdAt),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colors.onSurfaceVariant,
                              fontFamily: 'IBMPlexMono',
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        log.statusMessage,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurface,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreamingIndicator(ThemeData theme) {
    if (!_isStreaming || _displayedLogs.length >= widget.processLogs.length) {
      return const SizedBox.shrink();
    }

    final colors = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Streaming logs...',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _getStageIcon(ThemeData theme) {
    final colors = theme.colorScheme;
    if (widget.currentStage == null) {
      return Icon(Icons.info_outline, size: 20, color: colors.onSurfaceVariant);
    }

    switch (widget.currentStage) {
      case 'START':
      case 'FETCH':
        return Icon(
          Icons.cloud_upload_outlined,
          size: 20,
          color: colors.primary,
        );
      case 'PROCESSING':
      case 'GEMINI':
        return Icon(
          Icons.psychology_outlined,
          size: 20,
          color: colors.tertiary,
        );
      case 'SAVE':
        return Icon(Icons.save_outlined, size: 20, color: colors.tertiary);
      case 'COMPLETE':
        return Icon(
          Icons.check_circle_outline,
          size: 20,
          color: colors.primary,
        );
      case 'ERROR':
        return Icon(Icons.error_outline, size: 20, color: colors.error);
      default:
        return Icon(
          Icons.info_outline,
          size: 20,
          color: colors.onSurfaceVariant,
        );
    }
  }

  Color _stageColor(ThemeData theme, String stage) {
    final colors = theme.colorScheme;
    switch (stage) {
      case 'START':
      case 'FETCH':
      case 'COMPLETE':
        return colors.primary;
      case 'PROCESSING':
      case 'GEMINI':
      case 'SAVE':
        return colors.tertiary;
      case 'ERROR':
        return colors.error;
      default:
        return colors.onSurfaceVariant;
    }
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}:'
        '${dateTime.second.toString().padLeft(2, '0')}';
  }
}
