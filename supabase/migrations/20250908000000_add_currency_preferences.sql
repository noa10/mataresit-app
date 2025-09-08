-- Currency Preferences Migration
-- Adds comprehensive currency preference system for users including exchange rate caching

-- Add currency preference field to profiles table
ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS preferred_currency VARCHAR(3) DEFAULT 'MYR' CHECK (preferred_currency ~ '^[A-Z]{3}$');

-- Create currency exchange rates cache table
CREATE TABLE IF NOT EXISTS public.currency_exchange_rates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  base_currency VARCHAR(3) NOT NULL CHECK (base_currency ~ '^[A-Z]{3}$'),
  target_currency VARCHAR(3) NOT NULL CHECK (target_currency ~ '^[A-Z]{3}$'),
  exchange_rate DECIMAL(12,6) NOT NULL CHECK (exchange_rate > 0),
  rate_date DATE NOT NULL DEFAULT CURRENT_DATE,
  source VARCHAR(50) DEFAULT 'fawazahmed0' CHECK (source IN ('fawazahmed0', 'manual', 'fallback')),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Ensure unique combination of currencies and date
  UNIQUE(base_currency, target_currency, rate_date)
);

-- Create supported currencies reference table
CREATE TABLE IF NOT EXISTS public.supported_currencies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  currency_code VARCHAR(3) NOT NULL UNIQUE CHECK (currency_code ~ '^[A-Z]{3}$'),
  currency_name VARCHAR(100) NOT NULL,
  currency_symbol VARCHAR(10) NOT NULL,
  decimal_places INTEGER DEFAULT 2 CHECK (decimal_places >= 0 AND decimal_places <= 4),
  symbol_position VARCHAR(10) DEFAULT 'before' CHECK (symbol_position IN ('before', 'after')),
  locale_code VARCHAR(10) DEFAULT 'en_US',
  is_popular BOOLEAN DEFAULT false,
  is_active BOOLEAN DEFAULT true,
  display_order INTEGER DEFAULT 999,
  flag_emoji VARCHAR(10),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS on new tables
ALTER TABLE public.currency_exchange_rates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.supported_currencies ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for currency_exchange_rates (read-only for authenticated users)
CREATE POLICY "Anyone can view exchange rates" ON public.currency_exchange_rates
  FOR SELECT TO authenticated USING (true);

-- Create RLS policies for supported_currencies (read-only for authenticated users)
CREATE POLICY "Anyone can view supported currencies" ON public.supported_currencies
  FOR SELECT TO authenticated USING (true);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_currency_exchange_rates_base_target ON public.currency_exchange_rates(base_currency, target_currency);
CREATE INDEX IF NOT EXISTS idx_currency_exchange_rates_date ON public.currency_exchange_rates(rate_date DESC);
CREATE INDEX IF NOT EXISTS idx_currency_exchange_rates_active ON public.currency_exchange_rates(is_active) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_supported_currencies_popular ON public.supported_currencies(is_popular, display_order) WHERE is_popular = true;
CREATE INDEX IF NOT EXISTS idx_profiles_preferred_currency ON public.profiles(preferred_currency);

-- Create updated_at trigger for currency_exchange_rates
CREATE OR REPLACE FUNCTION update_currency_exchange_rates_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER currency_exchange_rates_updated_at_trigger
  BEFORE UPDATE ON public.currency_exchange_rates
  FOR EACH ROW
  EXECUTE FUNCTION update_currency_exchange_rates_updated_at();

-- Insert popular supported currencies
INSERT INTO public.supported_currencies (
  currency_code, currency_name, currency_symbol, decimal_places, symbol_position, 
  locale_code, is_popular, display_order, flag_emoji
) VALUES 
  ('MYR', 'Malaysian Ringgit', 'RM', 2, 'before', 'ms_MY', true, 1, '🇲🇾'),
  ('USD', 'US Dollar', '$', 2, 'before', 'en_US', true, 2, '🇺🇸'),
  ('SGD', 'Singapore Dollar', 'S$', 2, 'before', 'en_SG', true, 3, '🇸🇬'),
  ('EUR', 'Euro', '€', 2, 'after', 'de_DE', true, 4, '🇪🇺'),
  ('GBP', 'British Pound', '£', 2, 'before', 'en_GB', true, 5, '🇬🇧'),
  ('JPY', 'Japanese Yen', '¥', 0, 'before', 'ja_JP', true, 6, '🇯🇵'),
  ('CNY', 'Chinese Yuan', '¥', 2, 'before', 'zh_CN', false, 7, '🇨🇳'),
  ('THB', 'Thai Baht', '฿', 2, 'before', 'th_TH', false, 8, '🇹🇭'),
  ('IDR', 'Indonesian Rupiah', 'Rp', 0, 'before', 'id_ID', false, 9, '🇮🇩'),
  ('PHP', 'Philippine Peso', '₱', 2, 'before', 'en_PH', false, 10, '🇵🇭'),
  ('VND', 'Vietnamese Dong', '₫', 0, 'after', 'vi_VN', false, 11, '🇻🇳'),
  ('KRW', 'South Korean Won', '₩', 0, 'before', 'ko_KR', false, 12, '🇰🇷'),
  ('AUD', 'Australian Dollar', 'A$', 2, 'before', 'en_AU', false, 13, '🇦🇺'),
  ('CAD', 'Canadian Dollar', 'C$', 2, 'before', 'en_CA', false, 14, '🇨🇦'),
  ('CHF', 'Swiss Franc', 'CHF', 2, 'before', 'de_CH', false, 15, '🇨🇭'),
  ('HKD', 'Hong Kong Dollar', 'HK$', 2, 'before', 'en_HK', false, 16, '🇭🇰'),
  ('NZD', 'New Zealand Dollar', 'NZ$', 2, 'before', 'en_NZ', false, 17, '🇳🇿'),
  ('SEK', 'Swedish Krona', 'kr', 2, 'after', 'sv_SE', false, 18, '🇸🇪'),
  ('NOK', 'Norwegian Krone', 'kr', 2, 'after', 'nb_NO', false, 19, '🇳🇴'),
  ('DKK', 'Danish Krone', 'kr', 2, 'after', 'da_DK', false, 20, '🇩🇰')
ON CONFLICT (currency_code) DO UPDATE SET
  currency_name = EXCLUDED.currency_name,
  currency_symbol = EXCLUDED.currency_symbol,
  decimal_places = EXCLUDED.decimal_places,
  symbol_position = EXCLUDED.symbol_position,
  locale_code = EXCLUDED.locale_code,
  is_popular = EXCLUDED.is_popular,
  display_order = EXCLUDED.display_order,
  flag_emoji = EXCLUDED.flag_emoji;

-- Function to get user's preferred currency with fallback
CREATE OR REPLACE FUNCTION public.get_user_preferred_currency(_user_id UUID)
RETURNS VARCHAR(3)
LANGUAGE sql
STABLE SECURITY DEFINER
AS $function$
  SELECT COALESCE(p.preferred_currency, 'MYR')
  FROM public.profiles p
  WHERE p.id = _user_id
  LIMIT 1;
$function$;

-- Function to get latest exchange rate between two currencies
CREATE OR REPLACE FUNCTION public.get_exchange_rate(
  _base_currency VARCHAR(3),
  _target_currency VARCHAR(3),
  _max_age_days INTEGER DEFAULT 1
)
RETURNS DECIMAL(12,6)
LANGUAGE sql
STABLE SECURITY DEFINER
AS $function$
  SELECT exchange_rate
  FROM public.currency_exchange_rates
  WHERE base_currency = _base_currency
    AND target_currency = _target_currency
    AND is_active = true
    AND rate_date >= CURRENT_DATE - INTERVAL '1 day' * _max_age_days
  ORDER BY rate_date DESC, updated_at DESC
  LIMIT 1;
$function$;

-- Function to upsert exchange rate
CREATE OR REPLACE FUNCTION public.upsert_exchange_rate(
  _base_currency VARCHAR(3),
  _target_currency VARCHAR(3),
  _exchange_rate DECIMAL(12,6),
  _source VARCHAR(50) DEFAULT 'fawazahmed0'
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
DECLARE
  _result_id UUID;
BEGIN
  INSERT INTO public.currency_exchange_rates (
    base_currency,
    target_currency,
    exchange_rate,
    source
  ) VALUES (
    _base_currency,
    _target_currency,
    _exchange_rate,
    _source
  ) ON CONFLICT (base_currency, target_currency, rate_date) DO UPDATE SET
    exchange_rate = EXCLUDED.exchange_rate,
    source = EXCLUDED.source,
    updated_at = NOW()
  RETURNING id INTO _result_id;

  RETURN _result_id;
END;
$function$;

-- Grant necessary permissions
GRANT SELECT ON public.currency_exchange_rates TO authenticated;
GRANT SELECT ON public.supported_currencies TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_user_preferred_currency(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_exchange_rate(VARCHAR(3), VARCHAR(3), INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION public.upsert_exchange_rate(VARCHAR(3), VARCHAR(3), DECIMAL(12,6), VARCHAR(50)) TO authenticated;

-- Add comments for documentation
COMMENT ON COLUMN public.profiles.preferred_currency IS 'User preferred currency for displaying amounts (ISO 4217 code)';
COMMENT ON TABLE public.currency_exchange_rates IS 'Cache for currency exchange rates from external APIs';
COMMENT ON TABLE public.supported_currencies IS 'Reference table for supported currencies with display information';
COMMENT ON FUNCTION public.get_user_preferred_currency(UUID) IS 'Get user preferred currency with MYR fallback';
COMMENT ON FUNCTION public.get_exchange_rate(VARCHAR(3), VARCHAR(3), INTEGER) IS 'Get latest exchange rate between two currencies';
COMMENT ON FUNCTION public.upsert_exchange_rate(VARCHAR(3), VARCHAR(3), DECIMAL(12,6), VARCHAR(50)) IS 'Insert or update exchange rate';
