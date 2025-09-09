-- Add processing status constraint to ensure only valid values are allowed
-- This migration adds a CHECK constraint to the processing_status column to prevent
-- cross-platform compatibility issues between React ('complete') and Flutter ('completed')

-- First, update any existing 'complete' values to 'completed' to match Flutter enum
UPDATE public.receipts 
SET processing_status = 'completed' 
WHERE processing_status = 'complete';

-- Add CHECK constraint to ensure only valid processing status values
ALTER TABLE public.receipts 
ADD CONSTRAINT receipts_processing_status_check 
CHECK (processing_status IS NULL OR processing_status IN ('pending', 'processing', 'completed', 'failed', 'manual_review'));

-- Add comment to explain the constraint
COMMENT ON CONSTRAINT receipts_processing_status_check ON public.receipts IS 
'Ensures processing_status only contains valid values compatible with Flutter app enum: pending, processing, completed, failed, manual_review';

-- Create index for better query performance on processing_status
CREATE INDEX IF NOT EXISTS idx_receipts_processing_status_constrained 
ON public.receipts(processing_status) 
WHERE processing_status IS NOT NULL;
