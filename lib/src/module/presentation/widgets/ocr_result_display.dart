import 'package:bd_ekyc/src/module/domain/entities/live_ocr_state.dart';
import 'package:flutter/material.dart';

class OcrResultDisplay extends StatelessWidget {
  final LiveOcrState ocrState;
  final VoidCallback? onClear;

  const OcrResultDisplay({super.key, required this.ocrState, this.onClear});

  @override
  Widget build(BuildContext context) {
    if (ocrState.displayText.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getBorderColor(), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_getIcon(), color: _getIconColor(), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _getTitle(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _getTextColor(),
                  ),
                ),
              ),
              if (onClear != null)
                IconButton(
                  onPressed: onClear,
                  icon: const Icon(Icons.clear, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            ocrState.displayText,
            style: TextStyle(fontSize: 14, color: _getTextColor(), height: 1.4),
          ),
          if (ocrState.hasValidNidData) ...[
            const SizedBox(height: 36),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: Colors.green[700], size: 16),
                  const SizedBox(width: 6),
                  Text(
                    "NID Info Scanned",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getBackgroundColor() {
    if (ocrState.errorMessage != null) {
      return Colors.red.withValues(alpha: 0.1);
    } else if (ocrState.hasValidNidData) {
      return Colors.black.withValues(alpha: 0.4);
    } else if (ocrState.isProcessing) {
      return Colors.white.withValues(alpha: 0.7);
    }
    return Colors.white.withValues(alpha: 0.7);
  }

  Color _getBorderColor() {
    if (ocrState.errorMessage != null) {
      return Colors.red.withValues(alpha: 0.3);
    } else if (ocrState.hasValidNidData) {
      return Colors.white.withValues(alpha: 0.3);
    } else if (ocrState.isProcessing) {
      return Colors.blue.withValues(alpha: 0.3);
    }
    return Colors.grey.withValues(alpha: 0.3);
  }

  Color _getTextColor() {
    if (ocrState.errorMessage != null) {
      return Colors.red[700] ?? Colors.red;
    } else if (ocrState.hasValidNidData) {
      return Colors.white;
    } else if (ocrState.isProcessing) {
      return Colors.blue[700] ?? Colors.blue;
    }
    return Colors.black87;
  }

  Color _getIconColor() {
    if (ocrState.errorMessage != null) {
      return Colors.red[700] ?? Colors.red;
    } else if (ocrState.hasValidNidData) {
      return Colors.green[700] ?? Colors.green;
    } else if (ocrState.isProcessing) {
      return Colors.blue[700] ?? Colors.blue;
    }
    return Colors.grey[600] ?? Colors.grey;
  }

  IconData _getIcon() {
    if (ocrState.errorMessage != null) {
      return Icons.error_outline;
    } else if (ocrState.hasValidNidData) {
      return Icons.check_circle_outline;
    } else if (ocrState.isProcessing) {
      return Icons.hourglass_empty;
    }
    return Icons.search;
  }

  String _getTitle() {
    if (ocrState.errorMessage != null) {
      return "Error";
    } else if (ocrState.hasValidNidData) {
      return "NID Detected";
    } else if (ocrState.isProcessing) {
      return "Processing...";
    }
    return "OCR Result";
  }
}
