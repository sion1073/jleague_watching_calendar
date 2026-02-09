import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/season.dart';
import '../models/match_result.dart';
import '../models/goal_scorer.dart';
import '../services/season_service.dart';

/// 予定登録・編集画面
///
/// 試合の新規登録または既存試合の編集を行います。
class MatchFormScreen extends StatefulWidget {
  final Season season;
  final MatchResult? match;

  const MatchFormScreen({
    super.key,
    required this.season,
    this.match,
  });

  @override
  State<MatchFormScreen> createState() => _MatchFormScreenState();
}

class _MatchFormScreenState extends State<MatchFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _seasonService = SeasonService();

  // コントローラー
  late TextEditingController _dateController;
  late TextEditingController _homeTeamController;
  late TextEditingController _awayTeamController;
  late TextEditingController _homeScoreController;
  late TextEditingController _awayScoreController;
  late TextEditingController _memoController;

  // 状態
  late Season _selectedSeason;
  late DateTime _selectedDate;
  late MatchOutcome _selectedOutcome;
  late List<GoalScorer> _goalScorers;
  List<Season> _availableSeasons = [];

  bool _isLoading = false;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.match != null;

    // 初期値を設定
    _selectedSeason = widget.season;
    _selectedDate = widget.match?.matchDate ?? DateTime.now();
    _selectedOutcome = widget.match?.outcome ?? MatchOutcome.tbd;
    _goalScorers = widget.match?.goalScorers.toList() ?? [];

    // コントローラーの初期化
    final dateFormatter = DateFormat('yyyy/MM/dd');
    _dateController = TextEditingController(text: dateFormatter.format(_selectedDate));
    _homeTeamController = TextEditingController(text: widget.match?.homeTeam ?? '');
    _awayTeamController = TextEditingController(text: widget.match?.awayTeam ?? '');

    // スコアを分解
    final scoreParts = _parseScore(widget.match?.score ?? '');
    _homeScoreController = TextEditingController(text: scoreParts[0]);
    _awayScoreController = TextEditingController(text: scoreParts[1]);

    _memoController = TextEditingController(text: widget.match?.memo ?? '');

    // 利用可能なシーズンを取得
    _loadSeasons();
  }

  @override
  void dispose() {
    _dateController.dispose();
    _homeTeamController.dispose();
    _awayTeamController.dispose();
    _homeScoreController.dispose();
    _awayScoreController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  /// シーズンを読み込む
  Future<void> _loadSeasons() async {
    try {
      final seasons = _seasonService.getSeasonsOrderedByYear(ascending: false);
      setState(() {
        _availableSeasons = seasons;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('シーズンの読み込みに失敗しました: $e')),
        );
      }
    }
  }

  /// スコアを分解（"3-2" -> ["3", "2"]）
  List<String> _parseScore(String score) {
    if (score.isEmpty) return ['', ''];
    final parts = score.split('-');
    if (parts.length == 2) {
      return [parts[0].trim(), parts[1].trim()];
    }
    return ['', ''];
  }

  /// 日付ピッカーを表示
  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        final dateFormatter = DateFormat('yyyy/MM/dd');
        _dateController.text = dateFormatter.format(picked);
      });
    }
  }

  /// 得点者を追加するダイアログを表示
  Future<void> _showAddGoalScorerDialog() async {
    final nameController = TextEditingController();
    final teamController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('得点者を追加'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: '得点者名',
                hintText: '例: 田中',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: teamController,
              decoration: const InputDecoration(
                labelText: 'チーム名',
                hintText: '例: FC東京',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.trim().isEmpty ||
                  teamController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('名前とチーム名を入力してください')),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            child: const Text('追加'),
          ),
        ],
      ),
    );

    if (result == true) {
      setState(() {
        _goalScorers.add(GoalScorer(
          name: nameController.text.trim(),
          team: teamController.text.trim(),
        ));
      });
    }

    nameController.dispose();
    teamController.dispose();
  }

  /// 得点者を削除
  void _removeGoalScorer(int index) {
    setState(() {
      _goalScorers.removeAt(index);
    });
  }

  /// 勝敗の日本語表記を取得
  String _getOutcomeLabel(MatchOutcome outcome) {
    switch (outcome) {
      case MatchOutcome.win:
        return '勝利';
      case MatchOutcome.lose:
        return '敗北';
      case MatchOutcome.draw:
        return '引き分け';
      case MatchOutcome.tbd:
        return '未定';
    }
  }

  /// 保存処理
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // スコアを組み立て
      final homeScore = _homeScoreController.text.trim();
      final awayScore = _awayScoreController.text.trim();
      final score = (homeScore.isNotEmpty && awayScore.isNotEmpty)
          ? '$homeScore-$awayScore'
          : '';

      if (_isEditMode) {
        // 編集モード: 既存の試合を更新
        widget.match!.matchDate = _selectedDate;
        widget.match!.homeTeam = _homeTeamController.text.trim();
        widget.match!.awayTeam = _awayTeamController.text.trim();
        widget.match!.score = score;
        widget.match!.outcome = _selectedOutcome;
        widget.match!.goalScorers.clear();
        widget.match!.goalScorers.addAll(_goalScorers);
        widget.match!.memo = _memoController.text.trim();

        // シーズンが変更された場合の処理
        if (_selectedSeason.key != widget.season.key) {
          // 元のシーズンから削除
          widget.season.removeMatch(widget.match!);
          // 新しいシーズンに追加
          _selectedSeason.addMatch(widget.match!);
        } else {
          // 同じシーズンの場合は保存のみ
          await widget.season.save();
        }
      } else {
        // 新規登録モード
        final newMatch = MatchResult(
          matchDate: _selectedDate,
          homeTeam: _homeTeamController.text.trim(),
          awayTeam: _awayTeamController.text.trim(),
          score: score,
          outcomeIndex: _selectedOutcome.index,
          goalScorers: _goalScorers,
          memo: _memoController.text.trim(),
        );

        _selectedSeason.addMatch(newMatch);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存に失敗しました: $e')),
        );
      }
    }
  }

  /// キャンセル処理
  void _cancel() {
    Navigator.pop(context, false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? '試合を編集' : '予定を登録'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // シーズン選択
            DropdownButtonFormField<Season>(
              initialValue: _selectedSeason,
              decoration: const InputDecoration(
                labelText: 'シーズン',
                border: OutlineInputBorder(),
              ),
              items: _availableSeasons.map((season) {
                return DropdownMenuItem(
                  value: season,
                  child: Text(season.name),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedSeason = value;
                  });
                }
              },
              validator: (value) {
                if (value == null) {
                  return 'シーズンを選択してください';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // 試合日
            TextFormField(
              controller: _dateController,
              decoration: const InputDecoration(
                labelText: '試合日',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.calendar_today),
              ),
              readOnly: true,
              onTap: _selectDate,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '試合日を選択してください';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // HOMEチーム
            TextFormField(
              controller: _homeTeamController,
              decoration: const InputDecoration(
                labelText: 'HOMEチーム',
                border: OutlineInputBorder(),
                hintText: '例: FC東京',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'HOMEチームを入力してください';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // 対戦相手
            TextFormField(
              controller: _awayTeamController,
              decoration: const InputDecoration(
                labelText: '対戦相手',
                border: OutlineInputBorder(),
                hintText: '例: 浦和レッズ',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '対戦相手を入力してください';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // スコア
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _homeScoreController,
                    decoration: const InputDecoration(
                      labelText: 'HOMEスコア',
                      border: OutlineInputBorder(),
                      hintText: '0',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    '-',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: TextFormField(
                    controller: _awayScoreController,
                    decoration: const InputDecoration(
                      labelText: 'アウェイスコア',
                      border: OutlineInputBorder(),
                      hintText: '0',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 勝敗
            DropdownButtonFormField<MatchOutcome>(
              initialValue: _selectedOutcome,
              decoration: const InputDecoration(
                labelText: '勝敗',
                border: OutlineInputBorder(),
              ),
              items: MatchOutcome.values.map((outcome) {
                return DropdownMenuItem(
                  value: outcome,
                  child: Text(_getOutcomeLabel(outcome)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedOutcome = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // 得点者
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '得点者',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_goalScorers.isEmpty)
                      const Text(
                        '得点者が登録されていません',
                        style: TextStyle(color: Colors.grey),
                      )
                    else
                      ..._goalScorers.asMap().entries.map((entry) {
                        final index = entry.key;
                        final scorer = entry.value;
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.sports_soccer, size: 20),
                          title: Text(scorer.name),
                          subtitle: Text(scorer.team),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, size: 20),
                            onPressed: () => _removeGoalScorer(index),
                          ),
                        );
                      }),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _showAddGoalScorerDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('得点者を追加'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 40),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // メモ
            TextFormField(
              controller: _memoController,
              decoration: const InputDecoration(
                labelText: 'メモ',
                border: OutlineInputBorder(),
                hintText: '試合の感想やメモを入力',
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // 保存・キャンセルボタン
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : _cancel,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('キャンセル'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _save,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('保存'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
