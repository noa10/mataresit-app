import 'package:flutter/material.dart';
import '../utils/confidence_utils.dart';

/// A widget that displays confidence scores with color-coded indicators
/// Matches the React web version's visual design
class ConfidenceIndicator extends StatelessWidget {
  final double? score;
  final bool loading;
  final bool showLabel;
  final bool showTooltip;
  final double indicatorWidth;
  final double indicatorHeight;
  final TextStyle? textStyle;

  const ConfidenceIndicator({
    super.key,
    this.score,
    this.loading = false,
    this.showLabel = true,
    this.showTooltip = true,
    this.indicatorWidth = 16.0,
    this.indicatorHeight = 4.0,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    // Show loading state while processing
    if (loading) {
      return _buildLoadingIndicator(context);
    }

    final normalizedScore = ConfidenceUtils.normalizeConfidence(score);
    final confidenceColor = ConfidenceUtils.getConfidenceColor(normalizedScore);
    final confidenceLabel = ConfidenceUtils.getConfidenceLabel(normalizedScore);

    Widget indicator = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Color indicator bar
        Container(
          width: indicatorWidth,
          height: indicatorHeight,
          decoration: BoxDecoration(
            color: Color(confidenceColor.backgroundColor),
            borderRadius: BorderRadius.circular(2.0),
          ),
        ),
        if (showLabel) ...[
          const SizedBox(width: 4.0),
          Text(
            '${normalizedScore.round()}%',
            style: textStyle ?? Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 12.0,
              fontWeight: FontWeight.w600,
              color: Color(confidenceColor.primaryColor),
            ),
          ),
        ],
      ],
    );

    // Wrap with tooltip if enabled
    if (showTooltip) {
      indicator = Tooltip(
        message: _buildTooltipMessage(normalizedScore, confidenceLabel),
        child: indicator,
      );
    }

    return indicator;
  }

  Widget _buildLoadingIndicator(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: indicatorWidth,
          height: indicatorHeight,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(2.0),
          ),
          child: const LinearProgressIndicator(
            backgroundColor: Colors.transparent,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
          ),
        ),
        if (showLabel) ...[
          const SizedBox(width: 4.0),
          Text(
            'Processing...',
            style: textStyle ?? Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 12.0,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ],
    );
  }

  String _buildTooltipMessage(double normalizedScore, String label) {
    final buffer = StringBuffer();
    buffer.writeln('$label confidence');
    
    if (normalizedScore == 100) {
      buffer.write('Verified by user');
    } else {
      buffer.write('AI detection: ${label.toLowerCase()} reliability');
    }
    
    if (normalizedScore < 100) {
      buffer.write('\nEdit to verify and improve accuracy');
    }
    
    return buffer.toString();
  }
}

/// A compact version of the confidence indicator for use in lists
class CompactConfidenceIndicator extends StatelessWidget {
  final double? score;
  final bool loading;

  const CompactConfidenceIndicator({
    super.key,
    this.score,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return ConfidenceIndicator(
      score: score,
      loading: loading,
      showLabel: true,
      showTooltip: true,
      indicatorWidth: 12.0,
      indicatorHeight: 3.0,
      textStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
        fontSize: 10.0,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

/// A badge-style confidence indicator
class ConfidenceBadge extends StatelessWidget {
  final double? score;
  final bool loading;
  final EdgeInsetsGeometry? padding;

  const ConfidenceBadge({
    super.key,
    this.score,
    this.loading = false,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Container(
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 12.0,
              height: 12.0,
              child: CircularProgressIndicator(
                strokeWidth: 2.0,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.grey.shade600),
              ),
            ),
            const SizedBox(width: 4.0),
            Text(
              'Processing',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 10.0,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    final normalizedScore = ConfidenceUtils.normalizeConfidence(score);
    final confidenceColor = ConfidenceUtils.getConfidenceColor(normalizedScore);

    return Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: Color(confidenceColor.lightBackgroundColor),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: Color(confidenceColor.backgroundColor),
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6.0,
            height: 6.0,
            decoration: BoxDecoration(
              color: Color(confidenceColor.backgroundColor),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4.0),
          Text(
            '${normalizedScore.round()}%',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 10.0,
              fontWeight: FontWeight.w600,
              color: Color(confidenceColor.primaryColor),
            ),
          ),
        ],
      ),
    );
  }
}

/// A confidence indicator that shows both the score and label
class DetailedConfidenceIndicator extends StatelessWidget {
  final double? score;
  final bool loading;
  final bool vertical;

  const DetailedConfidenceIndicator({
    super.key,
    this.score,
    this.loading = false,
    this.vertical = false,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return _buildLoadingState(context);
    }

    if (vertical) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Confidence:',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 10.0,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 2.0),
          ConfidenceIndicator(
            score: score,
            showLabel: true,
            showTooltip: true,
          ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Confidence:',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: 12.0,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(width: 4.0),
        ConfidenceIndicator(
          score: score,
          showLabel: true,
          showTooltip: true,
        ),
      ],
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Confidence:',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: 12.0,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(width: 4.0),
        ConfidenceIndicator(
          loading: true,
          showLabel: true,
        ),
      ],
    );
  }
}
