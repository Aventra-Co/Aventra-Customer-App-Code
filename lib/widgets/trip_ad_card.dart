import 'package:flutter/material.dart';
import '../controller/app_color.dart';
import '../controller/app_config_provider.dart';
import '../controller/app_constant.dart';
import '../controller/app_font.dart';
import '../controller/app_image.dart';
import '../controller/app_language.dart';

enum TripAdCardLayout { portrait, landscape }

class TripAdCard extends StatelessWidget {
  final Map trip;
  final TripAdCardLayout layout;
  final double? width;
  final double? height;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;
  final VoidCallback? onShare;
  final Widget? topTrailing;
  final bool showFavorite;
  final bool showShare;
  final bool showImageCount;

  const TripAdCard({
    super.key,
    required this.trip,
    this.layout = TripAdCardLayout.portrait,
    this.width,
    this.height,
    this.onTap,
    this.onFavorite,
    this.onShare,
    this.topTrailing,
    this.showFavorite = false,
    this.showShare = false,
    this.showImageCount = true,
  });

  static String resolveTripName(dynamic item) {
    final title = _resolveTitleOnly(item);
    if (title.isNotEmpty) return title;
    return _resolveBoatOnly(item);
  }

  static String _resolveTitleOnly(dynamic item) {
    if (item is! Map) return '';
    final map = Map<dynamic, dynamic>.from(item);

    String pick(dynamic v) {
      if (v == null || v == 'NA') return '';
      if (v is List) {
        if (v.isEmpty) return '';
        final index = language < v.length ? language : 0;
        return v[index]?.toString().trim() ?? '';
      }
      final text = v.toString().trim();
      return (text.isEmpty || text == 'null') ? '' : text;
    }

    // Case-insensitive key lookup (handles unexpected key casing from API)
    dynamic byKey(String wanted) {
      if (map.containsKey(wanted)) return map[wanted];
      for (final entry in map.entries) {
        if (entry.key.toString().toLowerCase() == wanted.toLowerCase()) {
          return entry.value;
        }
      }
      return null;
    }

    // Prefer exact API keys from response — never boat_name
    final enStr = pick(byKey('title_name_en'));
    final arStr = pick(byKey('title_name_ar'));
    if (language == 1 && arStr.isNotEmpty) return arStr;
    if (enStr.isNotEmpty) return enStr;
    if (arStr.isNotEmpty) return arStr;

    // Legacy fallbacks only
    final legacyEn = pick(byKey('trip_name_english'));
    final legacyAr = pick(byKey('trip_name_arabic'));
    if (language == 1 && legacyAr.isNotEmpty) return legacyAr;
    if (legacyEn.isNotEmpty) return legacyEn;
    if (legacyAr.isNotEmpty) return legacyAr;
    return '';
  }

  static String _resolveBoatOnly(dynamic item) {
    if (item is! Map) return '';
    final map = Map<dynamic, dynamic>.from(item);
    final boat = map['boat_name_english'] ?? map['boat_name'];
    if (boat == null || boat == 'NA') return '';
    if (boat is List) {
      if (boat.isEmpty) return '';
      final index = language < boat.length ? language : 0;
      return boat[index]?.toString().trim() ?? '';
    }
    final text = boat.toString().trim();
    return (text.isEmpty || text == 'null') ? '' : text;
  }

  static String resolveLocalized(dynamic value) {
    if (value == null || value == 'NA') return '';
    if (value is List) {
      if (value.isEmpty) return '';
      final index = language < value.length ? language : 0;
      return value[index]?.toString().trim() ?? '';
    }
    if (value is Map) return '';
    final text = value.toString().trim();
    return text == 'null' ? '' : text;
  }

  static String _clean(dynamic value) {
    if (value == null || value == 'NA' || value == 'null') return '';
    return value.toString().trim();
  }

  static String _formatTime(dynamic value) {
    final raw = _clean(value);
    if (raw.isEmpty) return '';
    // "16:00:00" → "16:00"
    final parts = raw.split(':');
    if (parts.length >= 2) return '${parts[0]}:${parts[1]}';
    return raw;
  }

  /// Card headline = title_name_en / title_name_ar only (boat is separate row)
  String get _tripTitle => _resolveTitleOnly(trip);

  String get _boatName => _resolveBoatOnly(trip);

  /// Headline prefers trip title; boat only if title missing (and then hide boat row)
  String get _headline => _tripTitle.isNotEmpty ? _tripTitle : _boatName;

  bool get _showBoatRow =>
      _boatName.isNotEmpty && _tripTitle.isNotEmpty && _boatName != _tripTitle;

  String get _activityName {
    final activity = trip['activity'];
    if (activity is Map && activity.isNotEmpty) {
      final en = resolveLocalized(activity['activity_english']);
      final ar = resolveLocalized(activity['activity_arabic']);
      if (language == 1 && ar.isNotEmpty) return ar;
      if (en.isNotEmpty) return en;
      if (ar.isNotEmpty) return ar;
    }
    return '';
  }

  String get _routeText {
    final pickup = resolveLocalized(trip['pickup_point'] ?? trip['pickup']);
    final destination = resolveLocalized(
        trip['destinaton'] ?? trip['destination'] ?? trip['destination_english']);
    if (pickup.isNotEmpty && destination.isNotEmpty) {
      return '$pickup → $destination';
    }
    if (destination.isNotEmpty) return destination;
    if (pickup.isNotEmpty) return pickup;
    return resolveLocalized(trip['city_name']);
  }

  String get _priceText {
    final price = trip['price_per_hour'] ?? 0;
    return '$price ${AppLanguage.kwdtext[language]}/Hour';
  }

  /// API: trip_time 0 = open, 1 = fixed
  /// trip_time_label is documentation text only
  bool get _isFixedTime => trip['trip_time']?.toString() == '1';

  String get _timeText {
    final from = _formatTime(trip['from_time']);
    final to = _formatTime(trip['to_time']);
    final fixed = _formatTime(trip['fixed_time']);

    if (_isFixedTime) {
      if (fixed.isNotEmpty) return fixed;
      if (from.isNotEmpty && to.isNotEmpty) return '$from – $to';
      if (from.isNotEmpty) return from;
    } else {
      // open: from_time – to_time
      if (from.isNotEmpty && to.isNotEmpty) return '$from – $to';
      if (from.isNotEmpty) return from;
    }
    return '';
  }

  int get _imageCount {
    final images = trip['tripImages'] ?? trip['trip_images'] ?? trip['images'];
    if (images is List && images.isNotEmpty) return images.length;
    final count = trip['image_count'] ?? trip['total_images'];
    if (count != null) return int.tryParse(count.toString()) ?? 1;
    return 1;
  }

  String get _imageUrl {
    final image = trip['trip_image'] ?? trip['image'];
    if (image == null || image.toString().isEmpty || image == 'NA') return '';
    return '${AppConfigProvider.imageURL}$image';
  }

  bool get _isFavorite => trip['favourite_status'] == 1;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final cardWidth = width ?? size.width * 0.9;
    final cardHeight = height ??
        (layout == TripAdCardLayout.portrait
            ? size.height * 0.28
            : size.height * 0.22);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: cardWidth,
        height: cardHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          image: DecorationImage(
            image: _imageUrl.isNotEmpty
                ? NetworkImage(_imageUrl)
                : const AssetImage(AppImage.dummyIcon) as ImageProvider,
            fit: BoxFit.cover,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.15),
                        Colors.black.withOpacity(0.75),
                      ],
                      stops: const [0.35, 1],
                    ),
                  ),
                ),
              ),
              if (layout == TripAdCardLayout.portrait)
                _buildPortraitContent(context, cardWidth)
              else
                _buildLandscapeContent(context, cardWidth),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPortraitContent(BuildContext context, double cardWidth) {
    return Stack(
      children: [
        Positioned(
          top: 0,
          left: language == 1 ? null : 0,
          right: language == 1 ? 0 : null,
          child: _priceBadge(
            borderRadius: BorderRadius.only(
              topLeft: language == 1 ? Radius.zero : const Radius.circular(20),
              topRight: language == 1 ? const Radius.circular(20) : Radius.zero,
              bottomLeft:
                  language == 1 ? const Radius.circular(16) : Radius.zero,
              bottomRight:
                  language == 1 ? Radius.zero : const Radius.circular(16),
            ),
          ),
        ),
        Positioned(
          top: 8,
          left: language == 1 ? 8 : null,
          right: language == 1 ? null : 8,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showFavorite && onFavorite != null) ...[
                _circleAction(
                  onTap: onFavorite!,
                  child: Image.asset(
                    _isFavorite
                        ? AppImage.likeActiveIcon
                        : AppImage.likeDeactiveIcon,
                    width: 18,
                    height: 18,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              if (showShare && onShare != null) ...[
                _circleAction(
                  onTap: onShare!,
                  child: Image.asset(AppImage.shareIcon, width: 18, height: 18),
                ),
                const SizedBox(width: 6),
              ],
              if (topTrailing != null)
                topTrailing!
              else if (showImageCount)
                _imageCountPill(),
            ],
          ),
        ),
        Positioned(
          left: 12,
          right: 12,
          bottom: 12,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _headline,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  fontFamily: AppFont.fontFamily,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              if (_showBoatRow) _boatRow(_boatName),
              if (_routeText.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  _routeText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    fontFamily: AppFont.fontFamily,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  _peoplePill(),
                  const Spacer(),
                  if (_timeText.isNotEmpty) _timeRow(_timeText, compact: true),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLandscapeContent(BuildContext context, double cardWidth) {
    return Stack(
      children: [
        if (showFavorite || showShare || topTrailing != null)
          Positioned(
            top: 10,
            left: language == 1 ? 10 : null,
            right: language == 1 ? null : 10,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showFavorite && onFavorite != null) ...[
                  _circleAction(
                    onTap: onFavorite!,
                    child: Image.asset(
                      _isFavorite
                          ? AppImage.likeActiveIcon
                          : AppImage.likeDeactiveIcon,
                      width: 18,
                      height: 18,
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                if (showShare && onShare != null)
                  _circleAction(
                    onTap: onShare!,
                    child:
                        Image.asset(AppImage.shareIcon, width: 18, height: 18),
                  ),
                if (topTrailing != null) topTrailing!,
              ],
            ),
          ),
        Positioned(
          left: 14,
          right: 14,
          bottom: 0,
          top: 0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Text(
                _headline,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  fontFamily: AppFont.fontFamily,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (_showBoatRow) Expanded(child: _boatRow(_boatName)),
                  if (_activityName.isNotEmpty)
                    Text(
                      _activityName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        fontFamily: AppFont.fontFamily,
                      ),
                    ),
                ],
              ),
              if (_routeText.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  _routeText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    fontFamily: AppFont.fontFamily,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              // People only on the left; time sits next to price badge
              Padding(
                padding: EdgeInsets.only(
                  bottom: 12,
                  right: language == 1 ? 0 : 150,
                  left: language == 1 ? 150 : 0,
                ),
                child: Row(
                  children: [
                    _peoplePill(),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Time + price flush to the card corner
        Positioned(
          right: language == 1 ? null : 0,
          left: language == 1 ? 0 : null,
          bottom: 0,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (language != 1 && _timeText.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10, left: 8, right: 8),
                  child: _timePill(_timeText),
                ),
              _priceBadge(
                borderRadius: BorderRadius.only(
                  topLeft: language == 1
                      ? Radius.zero
                      : const Radius.circular(14),
                  topRight: language == 1
                      ? const Radius.circular(14)
                      : Radius.zero,
                  bottomLeft: language == 1
                      ? const Radius.circular(20)
                      : Radius.zero,
                  bottomRight: language == 1
                      ? Radius.zero
                      : const Radius.circular(20),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
              if (language == 1 && _timeText.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10, left: 8, right: 8),
                  child: _timePill(_timeText),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _priceBadge({
    required BorderRadius borderRadius,
    EdgeInsetsGeometry padding =
        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColor.themeColor,
        borderRadius: borderRadius,
      ),
      child: Text(
        _priceText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w700,
          fontFamily: AppFont.fontFamily,
        ),
      ),
    );
  }

  Widget _imageCountPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.45),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '1/$_imageCount',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          fontFamily: AppFont.fontFamily,
        ),
      ),
    );
  }

  Widget _peoplePill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.45),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.groups_outlined, color: Colors.white, size: 16),
          const SizedBox(width: 4),
          Text(
            '${trip['max_people'] ?? 0}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFamily: AppFont.fontFamily,
            ),
          ),
        ],
      ),
    );
  }

  Widget _timePill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.45),
        borderRadius: BorderRadius.circular(20),
      ),
      child: _timeRow(text, compact: true),
    );
  }

  Widget _boatRow(String name) {
    return Row(
      children: [
        const Icon(Icons.directions_boat_outlined,
            color: Colors.white, size: 14),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              fontFamily: AppFont.fontFamily,
            ),
          ),
        ),
      ],
    );
  }

  Widget _timeRow(String text, {bool compact = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          _isFixedTime ? Icons.access_time : Icons.autorenew,
          color: Colors.white,
          size: compact ? 14 : 16,
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w500,
              fontFamily: AppFont.fontFamily,
            ),
          ),
        ),
      ],
    );
  }

  Widget _circleAction({required VoidCallback onTap, required Widget child}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.35),
          shape: BoxShape.circle,
        ),
        child: child,
      ),
    );
  }
}
