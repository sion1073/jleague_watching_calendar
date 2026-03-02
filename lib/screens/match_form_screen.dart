import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/season.dart';
import '../models/match_result.dart';
import '../models/goal_scorer.dart';
import '../services/season_service.dart';
import '../services/preferences_service.dart';
import '../services/app_settings.dart';
import '../constants/team_constants.dart';

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
  final _preferencesService = PreferencesService();

  // コントローラー
  late TextEditingController _dateController;
  late TextEditingController _homeScoreController;
  late TextEditingController _awayScoreController;
  late TextEditingController _memoController;

  // 状態
  late Season _selectedSeason;
  late DateTime _selectedDate;
  late MatchOutcome _selectedOutcome;
  late ViewingType _selectedViewingType;
  late List<GoalScorer> _goalScorers;
  List<Season> _availableSeasons = [];
  List<String> _availableHomeTeams = [];

  // チーム選択
  String? _selectedHomeTeam;
  String? _selectedAwayTeam;

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
    _selectedViewingType = widget.match?.viewingType ?? ViewingType.stadium;
    _goalScorers = widget.match?.goalScorers.toList() ?? [];

    // コントローラーの初期化
    final dateFormatter = DateFormat('yyyy/MM/dd');
    _dateController = TextEditingController(text: dateFormatter.format(_selectedDate));

    // スコアを分解
    final scoreParts = _parseScore(widget.match?.score ?? '');
    _homeScoreController = TextEditingController(text: scoreParts[0]);
    _awayScoreController = TextEditingController(text: scoreParts[1]);

    _memoController = TextEditingController(text: widget.match?.memo ?? '');

    // 利用可能なシーズンとHOMEチームを取得
    _loadSettings();
  }

  @override
  void dispose() {
    _dateController.dispose();
    _homeScoreController.dispose();
    _awayScoreController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  /// シーズンとHOMEチーム設定を読み込む
  Future<void> _loadSettings() async {
    try {
      final seasons = _seasonService.getSeasonsOrderedByYear(ascending: false);
      final homeTeams = await _preferencesService.getHomeTeams();

      // チーム選択の初期値
      final homeTeam = widget.match?.homeTeam;
      final awayTeam = widget.match?.awayTeam;

      // HOMEチームの初期値（リストに存在する場合のみ設定）
      String? selectedHomeTeam;
      if (homeTeam != null && homeTeams.contains(homeTeam)) {
        selectedHomeTeam = homeTeam;
      }

      // 対戦相手の初期値（リストに存在する場合のみ設定）
      String? selectedAwayTeam;
      if (awayTeam != null && allOpponentTeams.contains(awayTeam)) {
        selectedAwayTeam = awayTeam;
      }

      setState(() {
        _availableSeasons = seasons;
        _availableHomeTeams = homeTeams;
        _selectedHomeTeam = selectedHomeTeam;
        _selectedAwayTeam = selectedAwayTeam;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('設定の読み込みに失敗しました: $e')),
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

  /// 選択リーグに基づいて対戦相手チームリストを生成
  List<String> _getAvailableAwayTeams(List<String> selectedLeagues) {
    final teams = <String>{};
    if (selectedLeagues.contains('j1')) teams.addAll(j1Teams);
    if (selectedLeagues.contains('j2')) teams.addAll(j2Teams);
    if (selectedLeagues.contains('j3')) teams.addAll(j3Teams);
    // その他は常に含める
    teams.add('その他');
    final sorted = teams.toList()..sort();
    return sorted;
  }

  /// 得点者のチーム選択肢を取得
  /// HOMEチームと対戦相手が両方選択されている場合はその2つのみ、
  /// そうでない場合は引数のチームリストから選択できるようにする
  List<String> _getGoalScorerTeamOptions(List<String> availableTeams) {
    if (_selectedHomeTeam != null && _selectedAwayTeam != null) {
      // 両方選択されている場合はその2つのみ
      return [_selectedHomeTeam!, _selectedAwayTeam!];
    }
    return availableTeams;
  }

  /// 得点者を追加するダイアログを表示
  Future<void> _showAddGoalScorerDialog(List<String> availableAwayTeams) async {
    final nameController = TextEditingController();
    final minuteController = TextEditingController();
    String? selectedTeam;

    // 得点者のチーム選択肢を取得
    final teamOptions = _getGoalScorerTeamOptions(availableAwayTeams);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('得点者を追加'),
          content: SingleChildScrollView(
            child: Column(
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
                InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'チーム名',
                    border: OutlineInputBorder(),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedTeam,
                      isExpanded: true,
                      hint: const Text('チーム名を選択'),
                      items: teamOptions.map((team) {
                        return DropdownMenuItem(
                          value: team,
                          child: Text(team),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedTeam = value;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: minuteController,
                  decoration: const InputDecoration(
                    labelText: '得点時間（分）',
                    hintText: '例: 45（未入力も可）',
                    suffixText: '分',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: () {
                if (nameController.text.trim().isEmpty ||
                    selectedTeam == null) {
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
      ),
    );

    if (result == true && selectedTeam != null) {
      final minuteText = minuteController.text.trim();
      final minute = minuteText.isEmpty ? null : int.tryParse(minuteText);

      setState(() {
        _goalScorers.add(GoalScorer(
          name: nameController.text.trim(),
          team: selectedTeam!,
          minuteScored: minute,
        ));
      });
    }

    nameController.dispose();
    minuteController.dispose();
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

  /// 観戦タイプの日本語表記を取得
  String _getViewingTypeLabel(ViewingType viewingType) {
    switch (viewingType) {
      case ViewingType.stadium:
        return 'スタジアム';
      case ViewingType.dazn:
        return 'DAZN';
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
        widget.match!.homeTeam = _selectedHomeTeam ?? '';
        widget.match!.awayTeam = _selectedAwayTeam ?? '';
        widget.match!.score = score;
        widget.match!.outcome = _selectedOutcome;
        widget.match!.viewingType = _selectedViewingType;
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
          homeTeam: _selectedHomeTeam ?? '',
          awayTeam: _selectedAwayTeam ?? '',
          score: score,
          outcomeIndex: _selectedOutcome.index,
          viewingTypeIndex: _selectedViewingType.index,
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

  /// 試合を削除
  Future<void> _deleteMatch() async {
    if (!_isEditMode || widget.match == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('試合記録を削除'),
        content: Text(
          '「${widget.match!.homeTeam} vs ${widget.match!.awayTeam}」の試合記録を削除しますか？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // シーズンから試合を削除
        widget.season.removeMatch(widget.match!);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('試合記録を削除しました')),
        );
        Navigator.of(context).pop(true); // 削除成功を通知
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('削除に失敗しました: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppSettings.of(context);
    final availableAwayTeams = _getAvailableAwayTeams(settings.selectedLeagues);

    // 編集時: 保存済みの対戦相手がフィルタ後のリストに含まれない場合は含めておく
    final awayTeamsForDropdown = (_selectedAwayTeam != null &&
            !availableAwayTeams.contains(_selectedAwayTeam))
        ? ([_selectedAwayTeam!, ...availableAwayTeams]..sort())
        : availableAwayTeams;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? '試合を編集' : '予定を登録'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: _isEditMode
            ? [
                IconButton(
                  icon: const Icon(Icons.delete),
                  tooltip: '削除',
                  onPressed: _deleteMatch,
                ),
              ]
            : null,
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
            DropdownButtonFormField<String>(
              value: _selectedHomeTeam,
              decoration: const InputDecoration(
                labelText: 'HOMEチーム',
                border: OutlineInputBorder(),
                helperText: '設定画面でHOMEチームを選択できます',
              ),
              items: _availableHomeTeams.isEmpty
                  ? [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('HOMEチームが設定されていません'),
                      ),
                    ]
                  : _availableHomeTeams.map((team) {
                      return DropdownMenuItem(
                        value: team,
                        child: Text(team),
                      );
                    }).toList(),
              onChanged: _availableHomeTeams.isEmpty
                  ? null
                  : (value) {
                      setState(() {
                        _selectedHomeTeam = value;
                      });
                    },
              validator: (value) {
                if (_availableHomeTeams.isEmpty) {
                  return '設定画面でHOMEチームを選択してください';
                }
                if (value == null || value.isEmpty) {
                  return 'HOMEチームを選択してください';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // 対戦相手
            DropdownButtonFormField<String>(
              initialValue: _selectedAwayTeam,
              decoration: const InputDecoration(
                labelText: '対戦相手',
                border: OutlineInputBorder(),
                helperText: '設定画面でリーグを絞り込めます',
              ),
              items: awayTeamsForDropdown.map((team) {
                return DropdownMenuItem(
                  value: team,
                  child: Text(team),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedAwayTeam = value;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '対戦相手を選択してください';
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

            // 観戦タイプ
            DropdownButtonFormField<ViewingType>(
              initialValue: _selectedViewingType,
              decoration: const InputDecoration(
                labelText: '観戦タイプ',
                border: OutlineInputBorder(),
              ),
              items: ViewingType.values.map((viewingType) {
                return DropdownMenuItem(
                  value: viewingType,
                  child: Text(_getViewingTypeLabel(viewingType)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedViewingType = value;
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
                          title: Text(scorer.toDisplayString()),
                          subtitle: Text(scorer.team),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, size: 20),
                            onPressed: () => _removeGoalScorer(index),
                          ),
                        );
                      }),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () => _showAddGoalScorerDialog(awayTeamsForDropdown),
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
