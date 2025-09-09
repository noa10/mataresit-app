import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/currency_conversion_result.dart';
import '../providers/currency_provider.dart';
import '../utils/currency_formatter.dart';

/// Widget for displaying currency amounts with conversion support
class CurrencyDisplayWidget extends ConsumerWidget {
  final double amount;
  final String originalCurrency;
  final bool showOriginalAmount;
  final bool showConversionRate;
  final bool compact;
  final TextStyle? style;
  final TextStyle? originalAmountStyle;
  final Color? conversionIndicatorColor;
  final bool enableConversion;

  const CurrencyDisplayWidget({
    super.key,
    required this.amount,
    required this.originalCurrency,
    this.showOriginalAmount = true,
    this.showConversionRate = false,
    this.compact = false,
    this.style,
    this.originalAmountStyle,
    this.conversionIndicatorColor,
    this.enableConversion = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userPreferredCurrency = ref.watch(userPreferredCurrencyProvider);

    // If conversion is disabled or same currency, show original amount
    if (!enableConversion ||
        originalCurrency.toUpperCase() == userPreferredCurrency.toUpperCase()) {
      return _buildOriginalAmount(context);
    }

    // Get conversion result
    final conversionParams = CurrencyConversionParams(
      amount: amount,
      fromCurrency: originalCurrency,
      toCurrency: userPreferredCurrency,
    );

    final conversionAsync = ref.watch(
      currencyConversionProvider(conversionParams),
    );

    return conversionAsync.when(
      data: (result) => _buildConvertedAmount(context, result),
      loading: () => _buildLoadingAmount(context),
      error: (error, _) => _buildOriginalAmount(context),
    );
  }

  Widget _buildOriginalAmount(BuildContext context) {
    final formattedAmount = CurrencyFormatter.formatAmountWithCode(
      amount: amount,
      currencyCode: originalCurrency,
      compact: compact,
    );

    return Text(
      formattedAmount,
      style: style ?? Theme.of(context).textTheme.bodyMedium,
    );
  }

  Widget _buildConvertedAmount(
    BuildContext context,
    CurrencyConversionResult result,
  ) {
    if (!result.conversionApplied) {
      return _buildOriginalAmount(context);
    }

    final convertedFormatted = CurrencyFormatter.formatAmountWithCode(
      amount: result.convertedAmount,
      currencyCode: result.targetCurrency,
      compact: compact,
    );

    final originalFormatted = CurrencyFormatter.formatAmountWithCode(
      amount: result.originalAmount,
      currencyCode: result.originalCurrency,
      compact: compact,
    );

    if (!showOriginalAmount && !showConversionRate) {
      // Show only converted amount
      return Text(
        convertedFormatted,
        style: style ?? Theme.of(context).textTheme.bodyMedium,
      );
    }

    // Show converted amount with additional info
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Main converted amount
        Text(
          convertedFormatted,
          style: style ?? Theme.of(context).textTheme.bodyMedium,
        ),

        // Additional info
        if (showOriginalAmount || showConversionRate) ...[
          const SizedBox(height: 2),
          _buildAdditionalInfo(context, result, originalFormatted),
        ],
      ],
    );
  }

  Widget _buildAdditionalInfo(
    BuildContext context,
    CurrencyConversionResult result,
    String originalFormatted,
  ) {
    final parts = <String>[];

    if (showOriginalAmount) {
      parts.add(originalFormatted);
    }

    if (showConversionRate) {
      final rateFormatted = CurrencyFormatter.formatExchangeRate(
        rate: result.exchangeRate,
        fromCurrency: result.originalCurrency,
        toCurrency: result.targetCurrency,
      );
      parts.add(rateFormatted);
    }

    return Text(
      parts.join(' • '),
      style:
          originalAmountStyle ??
          Theme.of(context).textTheme.bodySmall?.copyWith(
            color:
                conversionIndicatorColor ??
                Theme.of(context).colorScheme.onSurfaceVariant,
          ),
    );
  }

  Widget _buildLoadingAmount(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          CurrencyFormatter.formatAmountWithCode(
            amount: amount,
            currencyCode: originalCurrency,
            compact: compact,
          ),
          style: style ?? Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color:
                conversionIndicatorColor ??
                Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }
}

/// Simplified currency display for lists and compact views
class CompactCurrencyDisplay extends StatelessWidget {
  final double amount;
  final String currencyCode;
  final TextStyle? style;
  final bool showSymbol;

  const CompactCurrencyDisplay({
    super.key,
    required this.amount,
    required this.currencyCode,
    this.style,
    this.showSymbol = true,
  });

  @override
  Widget build(BuildContext context) {
    return CurrencyDisplayWidget(
      amount: amount,
      originalCurrency: currencyCode,
      compact: true,
      showOriginalAmount: false,
      showConversionRate: false,
      style: style,
      enableConversion: true,
    );
  }
}

/// Currency display with conversion tooltip
class CurrencyDisplayWithTooltip extends ConsumerWidget {
  final double amount;
  final String originalCurrency;
  final TextStyle? style;
  final bool compact;

  const CurrencyDisplayWithTooltip({
    super.key,
    required this.amount,
    required this.originalCurrency,
    this.style,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userPreferredCurrency = ref.watch(userPreferredCurrencyProvider);

    if (originalCurrency.toUpperCase() == userPreferredCurrency.toUpperCase()) {
      return CurrencyDisplayWidget(
        amount: amount,
        originalCurrency: originalCurrency,
        compact: compact,
        style: style,
        enableConversion: false,
      );
    }

    final conversionParams = CurrencyConversionParams(
      amount: amount,
      fromCurrency: originalCurrency,
      toCurrency: userPreferredCurrency,
    );

    final conversionAsync = ref.watch(
      currencyConversionProvider(conversionParams),
    );

    return conversionAsync.when(
      data: (result) {
        if (!result.conversionApplied) {
          return CurrencyDisplayWidget(
            amount: amount,
            originalCurrency: originalCurrency,
            compact: compact,
            style: style,
            enableConversion: false,
          );
        }

        final convertedFormatted = CurrencyFormatter.formatAmountWithCode(
          amount: result.convertedAmount,
          currencyCode: result.targetCurrency,
          compact: compact,
        );

        final originalFormatted = CurrencyFormatter.formatAmountWithCode(
          amount: result.originalAmount,
          currencyCode: result.originalCurrency,
          compact: compact,
        );

        final rateFormatted = CurrencyFormatter.formatExchangeRate(
          rate: result.exchangeRate,
          fromCurrency: result.originalCurrency,
          toCurrency: result.targetCurrency,
        );

        return Tooltip(
          message: '$originalFormatted\n$rateFormatted',
          child: Text(
            convertedFormatted,
            style: style ?? Theme.of(context).textTheme.bodyMedium,
          ),
        );
      },
      loading: () => CurrencyDisplayWidget(
        amount: amount,
        originalCurrency: originalCurrency,
        compact: compact,
        style: style,
        enableConversion: false,
      ),
      error: (error, stackTrace) => CurrencyDisplayWidget(
        amount: amount,
        originalCurrency: originalCurrency,
        compact: compact,
        style: style,
        enableConversion: false,
      ),
    );
  }
}

/// Currency amount input field with conversion preview
class CurrencyInputField extends ConsumerStatefulWidget {
  final String currencyCode;
  final double? initialAmount;
  final ValueChanged<double?>? onChanged;
  final String? labelText;
  final String? hintText;
  final bool showConversionPreview;

  const CurrencyInputField({
    super.key,
    required this.currencyCode,
    this.initialAmount,
    this.onChanged,
    this.labelText,
    this.hintText,
    this.showConversionPreview = true,
  });

  @override
  ConsumerState<CurrencyInputField> createState() => _CurrencyInputFieldState();
}

class _CurrencyInputFieldState extends ConsumerState<CurrencyInputField> {
  late TextEditingController _controller;
  double? _currentAmount;

  @override
  void initState() {
    super.initState();
    _currentAmount = widget.initialAmount;
    _controller = TextEditingController(
      text: widget.initialAmount != null
          ? CurrencyFormatter.formatForInput(
              amount: widget.initialAmount!,
              currencyCode: widget.currencyCode,
            )
          : '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: widget.labelText,
            hintText: widget.hintText,
            prefixText: CurrencyFormatter.getCurrencySymbol(
              widget.currencyCode,
            ),
            suffixText: widget.currencyCode,
          ),
          onChanged: (value) {
            final amount = CurrencyFormatter.parseAmount(value);
            setState(() => _currentAmount = amount);
            widget.onChanged?.call(amount);
          },
        ),

        if (widget.showConversionPreview &&
            _currentAmount != null &&
            _currentAmount! > 0) ...[
          const SizedBox(height: 8),
          CurrencyDisplayWidget(
            amount: _currentAmount!,
            originalCurrency: widget.currencyCode,
            showOriginalAmount: false,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }
}
