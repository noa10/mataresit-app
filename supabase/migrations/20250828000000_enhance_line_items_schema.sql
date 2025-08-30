-- Enhanced Line Items Schema Migration
-- Adds quantity, unit_price, and additional metadata fields to support detailed receipt analysis

-- Add enhanced fields to line_items table
ALTER TABLE public.line_items 
ADD COLUMN IF NOT EXISTS quantity DECIMAL(10,3) DEFAULT 1.0,
ADD COLUMN IF NOT EXISTS unit_price DECIMAL(10,2),
ADD COLUMN IF NOT EXISTS item_category VARCHAR(100),
ADD COLUMN IF NOT EXISTS item_subcategory VARCHAR(100),
ADD COLUMN IF NOT EXISTS brand VARCHAR(100),
ADD COLUMN IF NOT EXISTS size_info VARCHAR(50),
ADD COLUMN IF NOT EXISTS unit_of_measure VARCHAR(20), -- 'each', 'kg', 'lbs', 'ml', 'oz', etc.
ADD COLUMN IF NOT EXISTS discount_amount DECIMAL(10,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS tax_amount DECIMAL(10,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS is_taxable BOOLEAN DEFAULT true,
ADD COLUMN IF NOT EXISTS line_number INTEGER,
ADD COLUMN IF NOT EXISTS notes TEXT,
ADD COLUMN IF NOT EXISTS metadata JSONB;

-- Add computed column for total amount validation
-- This ensures amount = (quantity * unit_price) - discount_amount + tax_amount
ALTER TABLE public.line_items 
ADD COLUMN IF NOT EXISTS computed_amount DECIMAL(10,2) GENERATED ALWAYS AS (
  COALESCE(quantity, 1.0) * COALESCE(unit_price, amount) - COALESCE(discount_amount, 0) + COALESCE(tax_amount, 0)
) STORED;

-- Create function to auto-populate unit_price when amount and quantity are provided
CREATE OR REPLACE FUNCTION calculate_line_item_unit_price()
RETURNS TRIGGER AS $$
BEGIN
  -- If unit_price is not provided but amount and quantity are, calculate unit_price
  IF NEW.unit_price IS NULL AND NEW.amount IS NOT NULL AND NEW.quantity IS NOT NULL AND NEW.quantity > 0 THEN
    NEW.unit_price = NEW.amount / NEW.quantity;
  END IF;
  
  -- If amount is not provided but unit_price and quantity are, calculate amount
  IF NEW.amount IS NULL AND NEW.unit_price IS NOT NULL AND NEW.quantity IS NOT NULL THEN
    NEW.amount = NEW.quantity * NEW.unit_price + COALESCE(NEW.tax_amount, 0) - COALESCE(NEW.discount_amount, 0);
  END IF;
  
  -- Ensure updated_at is set
  NEW.updated_at = NOW();
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for auto-calculation
DROP TRIGGER IF EXISTS line_item_calculation_trigger ON public.line_items;
CREATE TRIGGER line_item_calculation_trigger
  BEFORE INSERT OR UPDATE ON public.line_items
  FOR EACH ROW
  EXECUTE FUNCTION calculate_line_item_unit_price();

-- Add indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_line_items_receipt_id_line_number ON public.line_items(receipt_id, line_number);
CREATE INDEX IF NOT EXISTS idx_line_items_item_category ON public.line_items(item_category);
CREATE INDEX IF NOT EXISTS idx_line_items_brand ON public.line_items(brand);

-- Add comments for documentation
COMMENT ON COLUMN public.line_items.quantity IS 'Quantity of the item purchased';
COMMENT ON COLUMN public.line_items.unit_price IS 'Price per unit of the item';
COMMENT ON COLUMN public.line_items.item_category IS 'Category of the item (e.g., Food, Electronics, Clothing)';
COMMENT ON COLUMN public.line_items.item_subcategory IS 'Subcategory of the item (e.g., Beverages, Smartphones, Shirts)';
COMMENT ON COLUMN public.line_items.brand IS 'Brand name of the item';
COMMENT ON COLUMN public.line_items.size_info IS 'Size information (e.g., Large, 500ml, XL)';
COMMENT ON COLUMN public.line_items.unit_of_measure IS 'Unit of measurement for quantity';
COMMENT ON COLUMN public.line_items.discount_amount IS 'Discount applied to this line item';
COMMENT ON COLUMN public.line_items.tax_amount IS 'Tax amount for this line item';
COMMENT ON COLUMN public.line_items.is_taxable IS 'Whether this item is subject to tax';
COMMENT ON COLUMN public.line_items.line_number IS 'Order of the item on the receipt';
COMMENT ON COLUMN public.line_items.notes IS 'Additional notes about the item';
COMMENT ON COLUMN public.line_items.metadata IS 'Additional metadata in JSON format';
COMMENT ON COLUMN public.line_items.computed_amount IS 'Auto-calculated total amount for validation';

-- Create view for enhanced line items with calculations
CREATE OR REPLACE VIEW public.line_items_enhanced AS
SELECT 
  li.*,
  -- Calculate effective unit price
  CASE 
    WHEN li.unit_price IS NOT NULL THEN li.unit_price
    WHEN li.quantity > 0 THEN li.amount / li.quantity
    ELSE li.amount
  END as effective_unit_price,
  
  -- Calculate total before tax and discount
  COALESCE(li.quantity, 1.0) * COALESCE(li.unit_price, li.amount) as subtotal,
  
  -- Calculate final total
  COALESCE(li.quantity, 1.0) * COALESCE(li.unit_price, li.amount) 
    - COALESCE(li.discount_amount, 0) 
    + COALESCE(li.tax_amount, 0) as calculated_total,
    
  -- Receipt information for context
  r.merchant,
  r.date as receipt_date,
  r.currency
FROM line_items li
JOIN receipts r ON li.receipt_id = r.id;

-- Grant necessary permissions
GRANT SELECT ON public.line_items_enhanced TO authenticated;
GRANT ALL ON public.line_items TO authenticated;

-- Update RLS policies if needed
ALTER TABLE public.line_items ENABLE ROW LEVEL SECURITY;

-- Create RLS policy for line_items (if not exists)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'line_items' 
    AND policyname = 'Users can manage their own receipt line items'
  ) THEN
    CREATE POLICY "Users can manage their own receipt line items" ON public.line_items
      FOR ALL USING (
        receipt_id IN (
          SELECT id FROM public.receipts 
          WHERE user_id = auth.uid()
        )
      );
  END IF;
END $$;
