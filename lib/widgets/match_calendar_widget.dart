import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../models/match_result.dart';

/// 観戦スケジュールを表示するカレンダーウィジェット
///
/// 登録済みの試合日にサッカーボールアイコンを表示
class MatchCalendarWidget extends StatefulWidget {
  /// 表示する試合結果のリスト
  final List<MatchResult> matchResults;

  /// 日付がタップされた時のコールバック
  final Function(DateTime)? onDaySelected;

  const MatchCalendarWidget({
    super.key,
    required this.matchResults,
    this.onDaySelected,
  });

  @override
  State<MatchCalendarWidget> createState() => _MatchCalendarWidgetState();
}

class _MatchCalendarWidgetState extends State<MatchCalendarWidget> {
  late DateTime _focusedDay;
  DateTime? _selectedDay;
  late Map<DateTime, List<MatchResult>> _matchesByDate;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
    _buildMatchesByDate();
  }

  @override
  void didUpdateWidget(MatchCalendarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.matchResults != widget.matchResults) {
      _buildMatchesByDate();
    }
  }

  /// 試合を日付でグループ化
  void _buildMatchesByDate() {
    _matchesByDate = {};
    for (final match in widget.matchResults) {
      final date = DateTime(
        match.matchDate.year,
        match.matchDate.month,
        match.matchDate.day,
      );
      _matchesByDate[date] = [...(_matchesByDate[date] ?? []), match];
    }
  }

  /// 指定された日付に試合があるかチェック
  List<MatchResult> _getMatchesForDay(DateTime day) {
    final date = DateTime(day.year, day.month, day.day);
    return _matchesByDate[date] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: TableCalendar<MatchResult>(
          firstDay: DateTime(2020, 1, 1),
          lastDay: DateTime(2030, 12, 31),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          calendarFormat: CalendarFormat.month,
          locale: 'ja_JP',
          // ヘッダースタイル
          headerStyle: HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            titleTextFormatter: (date, locale) {
              return DateFormat('yyyy年M月', locale).format(date);
            },
          ),
          // カレンダースタイル
          calendarStyle: CalendarStyle(
            // 今日の日付スタイル
            todayDecoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            // 選択された日付スタイル
            selectedDecoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              shape: BoxShape.circle,
            ),
            // マーカースタイル
            markerDecoration: BoxDecoration(
              color: Colors.green.shade700,
              shape: BoxShape.circle,
            ),
            markersMaxCount: 3,
          ),
          // イベント（試合）を取得
          eventLoader: _getMatchesForDay,
          // 日付選択時のコールバック
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
            widget.onDaySelected?.call(selectedDay);
          },
          // ページ変更時のコールバック
          onPageChanged: (focusedDay) {
            setState(() {
              _focusedDay = focusedDay;
            });
          },
          // カスタムマーカービルダー（サッカーボールアイコンを表示）
          calendarBuilders: CalendarBuilders(
            markerBuilder: (context, date, matches) {
              if (matches.isEmpty) return null;

              return Positioned(
                bottom: 1,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.green.shade700,
                      ),
                    ),
                    if (matches.length > 1)
                      Padding(
                        padding: const EdgeInsets.only(left: 2.0),
                        child: Text(
                          '${matches.length}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
