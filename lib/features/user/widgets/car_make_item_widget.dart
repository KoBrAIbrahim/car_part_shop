import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/api/models/car_make.dart';

class CarMakeItemWidget extends StatelessWidget {
  final CarMake carMake;
  final String? logoUrl;
  final VoidCallback? onTap;

  const CarMakeItemWidget({
    super.key,
    required this.carMake,
    this.logoUrl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Logo container
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: logoUrl != null
                  ? CachedNetworkImage(
                      imageUrl: logoUrl!,
                      placeholder: (context, url) => Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Icon(
                        Icons.car_repair_rounded,
                        color: AppColors.primary.withOpacity(0.7),
                        size: 30,
                      ),
                      fit: BoxFit.contain,
                      width: 50,
                      height: 50,
                    )
                  : Icon(
                      Icons.car_repair_rounded,
                      color: AppColors.primary.withOpacity(0.7),
                      size: 30,
                    ),
            ),

            const SizedBox(width: 16),

            // Car make info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    carMake.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ID: ${carMake.id}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textDark.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),

            // Arrow icon
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppColors.primary.withOpacity(0.7),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
