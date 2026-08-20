import 'package:flutter/material.dart';

/// A reusable download indicator widget that displays download progress
/// with enhanced visual feedback following mobile UI best practices.
class DownloadIndicator extends StatelessWidget {
  const DownloadIndicator({
    required this.progress,
    this.size = DownloadIndicatorSize.medium,
    this.showPercentage = true,
    this.showFileSize = false,
    this.totalSizeGB,
    super.key,
  });

  final int progress;
  final DownloadIndicatorSize size;
  final bool showPercentage;
  final bool showFileSize;
  final double? totalSizeGB;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return switch (size) {
      DownloadIndicatorSize.small => _buildSmallIndicator(theme),
      DownloadIndicatorSize.medium => _buildMediumIndicator(theme),
      DownloadIndicatorSize.large => _buildLargeIndicator(theme),
    };
  }

  Widget _buildSmallIndicator(ThemeData theme) {
    return SizedBox(
      width: 24,
      height: 24,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress > 0 ? progress / 100 : null,
            strokeWidth: 2,
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.2),
          ),
          if (progress > 0)
            Text(
              '$progress',
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMediumIndicator(ThemeData theme) {
    final downloadedGB = totalSizeGB != null ? (totalSizeGB! * progress / 100) : 0.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 64,
          height: 64,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background circle
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                ),
              ),
              // Progress indicator
              SizedBox(
                width: 56,
                height: 56,
                child: CircularProgressIndicator(
                  value: progress > 0 ? progress / 100 : null,
                  strokeWidth: 3,
                  backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.2),
                ),
              ),
              // Percentage text
              if (showPercentage)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.download,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                    Text(
                      '$progress%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        if (showFileSize && totalSizeGB != null) ...[
          const SizedBox(height: 8),
          Text(
            '${downloadedGB.toStringAsFixed(2)} / ${totalSizeGB!.toStringAsFixed(2)} GB',
            style: TextStyle(
              fontSize: 11,
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLargeIndicator(ThemeData theme) {
    final downloadedGB = totalSizeGB != null ? (totalSizeGB! * progress / 100) : 0.0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Circular progress with icon
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Glow effect
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
                // Background circle
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  ),
                ),
                // Progress indicator
                SizedBox(
                  width: 72,
                  height: 72,
                  child: CircularProgressIndicator(
                    value: progress > 0 ? progress / 100 : null,
                    strokeWidth: 4,
                    backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                // Icon and percentage
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.downloading,
                      size: 28,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 4),
                    if (showPercentage)
                      Text(
                        '$progress%',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                          letterSpacing: 0.5,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress > 0 ? progress / 100 : null,
              minHeight: 6,
              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
            ),
          ),
          const SizedBox(height: 12),
          // Status text
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Downloading...',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
              if (showFileSize && totalSizeGB != null)
                Text(
                  '${downloadedGB.toStringAsFixed(2)} / ${totalSizeGB!.toStringAsFixed(2)} GB',
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w500,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

enum DownloadIndicatorSize {
  small,
  medium,
  large,
}
