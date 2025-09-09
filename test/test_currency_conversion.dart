import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mataresit_app/shared/widgets/currency_display_widget.dart';

/// Simple test app to verify currency conversion is working
class CurrencyConversionTestApp extends StatelessWidget {
  const CurrencyConversionTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        title: 'Currency Conversion Test',
        home: Scaffold(
          appBar: AppBar(title: const Text('Currency Conversion Test')),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const <Widget>[
                Text(
                  'Testing Currency Conversion:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20),

                Text('Original MYR 23.35:'),
                SizedBox(height: 8),
                CompactCurrencyDisplay(amount: 23.35, currencyCode: 'MYR'),

                SizedBox(height: 20),
                Text('Original MYR 832.84:'),
                SizedBox(height: 8),
                CompactCurrencyDisplay(amount: 832.84, currencyCode: 'MYR'),

                SizedBox(height: 20),
                Text('With conversion details:'),
                SizedBox(height: 8),
                CurrencyDisplayWidget(
                  amount: 23.35,
                  originalCurrency: 'MYR',
                  showOriginalAmount: true,
                  showConversionRate: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void main() {
  runApp(const CurrencyConversionTestApp());
}
