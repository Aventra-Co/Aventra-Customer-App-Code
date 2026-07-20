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
      for (final index in [language, 0]) {
        if (index < boat.length) {
          final text = boat[index]?.toString().trim() ?? '';
          if (text.isNotEmpty && text != 'null') return text;
        }
      }
      return '';
    }
    final text = boat.toString().trim();
    return (text.isEmpty || text == 'null') ? '' : text;
  }

  static String resolveLocalized(dynamic value) {
    if (value == null || value == 'NA') return '';
    if (value is List) {
      if (value.isEmpty) return '';
      for (final index in [language, 0]) {
        if (index < value.length) {
          final text = value[index]?.toString().trim() ?? '';
          if (text.isNotEmpty && text != 'null') return text;
        }
      }
      return '';
    }
    if (value is Map) return '';
    final text = value.toString().trim();
    return text == 'null' ? '' : text;
  }

  /// Prefer city_name (list cards). Details API often omits it — then take the
  /// city segment from pickup_point ("..., Al Khiran, Kuwait" → "Al Khiran").
  static String resolvePickupDisplay(dynamic trip) {
    if (trip is! Map) return '';
    final city = resolveLocalized(trip['city_name']);
    if (city.isNotEmpty) return city;

    final pickup =
        resolveLocalized(trip['pickup_point'] ?? trip['pickup'] ?? trip['address']);
    if (pickup.isEmpty) return '';

    final parts = pickup
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.length >= 2) {
      const countries = {'kuwait', 'kw', 'الكويت', 'saudi arabia', 'uae', 'qatar'};
      final last = parts.last.toLowerCase();
      if (countries.contains(last) || last.contains('kuwait')) {
        return parts[parts.length - 2];
      }
      if (parts.length >= 3) return parts[parts.length - 2];
    }
    return pickup;
  }

  static String _clean(dynamic value) {
    if (value == null || value == 'NA' || value == 'null') return '';
    return value.toString().trim();
  }

  /// Formats "16:00:00" / "04:00 PM" → display time (keeps AM/PM when present,
  /// otherwise converts 24h to 12h to match Owner cards).
  static String _formatTime(dynamic value) {
    final raw = _clean(value);
    if (raw.isEmpty) return '';
    final upper = raw.toUpperCase();
    if (upper.contains('AM') || upper.contains('PM')) return raw;

    final match = RegExp(r'^(\d{1,2}):(\d{2})(?::\d{2})?').firstMatch(raw);
    if (match == null) return raw;
    var hour = int.parse(match.group(1)!);
    final minute = match.group(2)!;
    final suffix = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;
    return '${displayHour.toString().padLeft(2, '0')}:$minute $suffix';
  }

  static String _addHoursToTime(dynamic value, dynamic hours) {
    final raw = _clean(value);
    final duration = double.tryParse(_clean(hours));
    if (raw.isEmpty || duration == null) return '';

    final match = RegExp(
      r'^(\d{1,2}):(\d{2})(?::\d{2})?\s*(AM|PM)?$',
      caseSensitive: false,
    ).firstMatch(raw);
    if (match == null) return '';

    var hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    final meridiem = match.group(3)?.toUpperCase();
    if (meridiem != null) {
      hour %= 12;
      if (meridiem == 'PM') hour += 12;
    }

    final totalMinutes =
        (hour * 60 + minute + (duration * 60).round()) % (24 * 60);
    final resultHour = totalMinutes ~/ 60;
    final resultMinute = totalMinutes % 60;
    final suffix = resultHour >= 12 ? 'PM' : 'AM';
    final displayHour = resultHour % 12 == 0 ? 12 : resultHour % 12;
    return '${displayHour.toString().padLeft(2, '0')}:${resultMinute.toString().padLeft(2, '0')} $suffix';
  }

  static int? _hoursBetween(dynamic fromRaw, dynamic toRaw) {
    final from = _clean(fromRaw);
    final to = _clean(toRaw);
    if (from.isEmpty || to.isEmpty) return null;

    int? toMinutes(String raw) {
      final match = RegExp(
        r'^(\d{1,2}):(\d{2})(?::\d{2})?\s*(AM|PM)?$',
        caseSensitive: false,
      ).firstMatch(raw);
      if (match == null) return null;
      var hour = int.parse(match.group(1)!);
      final minute = int.parse(match.group(2)!);
      final meridiem = match.group(3)?.toUpperCase();
      if (meridiem != null) {
        hour %= 12;
        if (meridiem == 'PM') hour += 12;
      }
      return hour * 60 + minute;
    }

    final start = toMinutes(from);
    final end = toMinutes(to);
    if (start == null || end == null) return null;
    var diff = end - start;
    if (diff <= 0) diff += 24 * 60;
    final hours = (diff / 60).round();
    return hours > 0 ? hours : null;
  }

  String get _tripTitle => _resolveTitleOnly(trip);

  String get _boatName => _resolveBoatOnly(trip);

  /// Title line = trip title only (never boat).
  String get _headline => _tripTitle;

  /// Boat always sits under the title with its icon (when available).
  bool get _showBoatRow => _boatName.isNotEmpty;

  String get _activityName {
    final activity = trip['activity'];
    if (activity is Map && activity.isNotEmpty) {
      final en = resolveLocalized(activity['activity_english'] ??
          activity['name_english'] ??
          activity['english']);
      final ar = resolveLocalized(activity['activity_arabic'] ??
          activity['name_arabic'] ??
          activity['arabic']);
      if (language == 1 && ar.isNotEmpty) return ar;
      if (en.isNotEmpty) return en;
      if (ar.isNotEmpty) return ar;
    }
    if (activity is List && activity.isNotEmpty) {
      final first = activity.first;
      if (first is Map) {
        final en = resolveLocalized(first['activity_english'] ??
            first['name_english'] ??
            first['english']);
        final ar = resolveLocalized(first['activity_arabic'] ??
            first['name_arabic'] ??
            first['arabic']);
        if (language == 1 && ar.isNotEmpty) return ar;
        if (en.isNotEmpty) return en;
        if (ar.isNotEmpty) return ar;
      }
    }
    return resolveLocalized(trip['trip_type_name']);
  }

  /// Match Owner: city → destination (not long pickup address)
  String get _routeText {
    final pickup = resolveLocalized(
        trip['city_name'] ?? trip['pickup_point'] ?? trip['pickup']);
    final destination = resolveLocalized(
        trip['destinaton'] ?? trip['destination'] ?? trip['destination_english']);
    if (pickup.isNotEmpty && destination.isNotEmpty) {
      return '$pickup → $destination';
    }
    if (destination.isNotEmpty) return destination;
    if (pickup.isNotEmpty) return pickup;
    return resolveLocalized(trip['pickup_point']);
  }

  String get _priceText {
    final price = trip['price_per_hour'] ?? 0;
    return '$price ${AppLanguage.kwdtext[language]}/Hour';
  }

  /// API: trip_time 0 = open, 1 = fixed
  bool get _isFixedTime => trip['trip_time']?.toString() == '1';

  bool get _tripTimeIsDisplayString {
    final raw = trip['trip_time'];
    if (raw is! String) return false;
    final s = raw.trim();
    if (s.isEmpty || s == '0' || s == '1') return false;
    final upper = s.toUpperCase();
    return s.contains('-') || upper.contains('AM') || upper.contains('PM');
  }

  /// Match Owner:
  /// - fixed → from – to (or from + minimum_hours)
  /// - open → minimum_hours as "6h" (or duration from from/to)
  String get _timeText {
    if (_tripTimeIsDisplayString) {
      return trip['trip_time'].toString().trim().replaceAll(' - ', ' – ');
    }

    final from = _formatTime(trip['from_time']);
    final to = _formatTime(trip['to_time']);
    final fixed = _formatTime(trip['fixed_time']);
    final minimumHours = _clean(trip['minimum_hours']);

    if (_isFixedTime) {
      if (from.isNotEmpty && to.isNotEmpty) return '$from – $to';
      final start = from.isNotEmpty ? from : fixed;
      final calculatedEnd = _addHoursToTime(start, minimumHours);
      if (start.isNotEmpty && calculatedEnd.isNotEmpty) {
        return '$start – $calculatedEnd';
      }
      if (start.isNotEmpty) return start;
    } else {
      if (minimumHours.isNotEmpty) return '${minimumHours}h';
      final hours = _hoursBetween(trip['from_time'], trip['to_time']);
      if (hours != null) return '${hours}h';
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
              // Title on top; if missing, use boat name so layout stays consistent
              Text(
                _headline.isNotEmpty ? _headline : _boatName,
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
              // Boat row with icon always under the title line
              if (_showBoatRow) ...[
                const SizedBox(height: 6),
                _boatRow(_boatName),
              ],
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
              // Title on top; if missing, use boat name so layout stays consistent
              if (_headline.isNotEmpty || _boatName.isNotEmpty) ...[
                Text(
                  _headline.isNotEmpty ? _headline : _boatName,
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
                if (_showBoatRow || _activityName.isNotEmpty)
                  const SizedBox(height: 8),
              ],
              // Boat always under title with icon (even when title fell back to boat)
              if (_showBoatRow || _activityName.isNotEmpty)
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
        const Icon(
          Icons.directions_boat_outlined,
          color: Colors.white,
          size: 14,
        ),
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
