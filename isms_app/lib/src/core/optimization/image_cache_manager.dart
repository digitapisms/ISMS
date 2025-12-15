import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Global image cache manager for optimized image loading
class ImageCacheManager {
  static final CacheManager _cacheManager = CacheManager(
    Config(
      'isms_images',
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: 200,
      repo: JsonCacheInfoRepository(databaseName: 'isms_images'),
    ),
  );

  static CacheManager get cacheManager => _cacheManager;

  /// Get cached network image widget with optimized settings
  static Widget cachedImage({
    required String imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
    Duration fadeInDuration = const Duration(milliseconds: 300),
  }) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      cacheManager: _cacheManager,
      placeholder: (context, url) => placeholder ??
          Container(
            color: Colors.grey[200],
            child: const Center(child: CircularProgressIndicator()),
          ),
      errorWidget: (context, url, error) => errorWidget ??
          Container(
            color: Colors.grey[300],
            child: const Icon(Icons.error_outline),
          ),
      fadeInDuration: fadeInDuration,
      memCacheWidth: width?.toInt(),
      memCacheHeight: height?.toInt(),
      maxWidthDiskCache: 1000,
      maxHeightDiskCache: 1000,
    );
  }

  /// Clear image cache
  static Future<void> clearCache() async {
    await _cacheManager.emptyCache();
  }

  /// Get cache size
  static Future<int> getCacheSize() async {
    try {
      final cacheObjects = await _cacheManager.store.retrieveCacheData('');
      if (cacheObjects != null) {
        return cacheObjects.length ?? 0;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }
}

