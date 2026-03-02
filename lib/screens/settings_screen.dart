import 'package:flutter/material.dart';
import '../services/app_settings.dart';
import '../constants/team_constants.dart';
import '../services/preferences_service.dart';

/// 設定画面
///
/// アプリの各種設定を管理します。
/// - 配信視聴を含めるかどうか
/// - 試合リストのソート順（昇順/降順）
/// - HOMEチームの選択
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _preferencesService = PreferencesService();
  List<String> _selectedHomeTeams = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHomeTeams();
  }

  /// HOMEチーム設定を読み込む
  Future<void> _loadHomeTeams() async {
    try {
      final homeTeams = await _preferencesService.getHomeTeams();
      setState(() {
        _selectedHomeTeams = homeTeams;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('設定の読み込みに失敗しました: $e')),
        );
      }
    }
  }

  /// HOMEチーム選択画面を表示
  Future<void> _showHomeTeamSelectionDialog() async {
    // 全チームリストを作成（J1 + J2 + J3 + 日本代表）
    final allTeams = <String>{
      ...j1Teams,
      ...j2Teams,
      ...j3Teams,
      '日本代表',
    }.toList()
      ..sort();

    // 一時的な選択状態を保持
    final tempSelectedTeams = List<String>.from(_selectedHomeTeams);

    final result = await showDialog<List<String>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('HOMEチームを選択'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: allTeams.length,
              itemBuilder: (context, index) {
                final team = allTeams[index];
                final isSelected = tempSelectedTeams.contains(team);

                return CheckboxListTile(
                  title: Text(team),
                  value: isSelected,
                  onChanged: (checked) {
                    setDialogState(() {
                      if (checked == true) {
                        tempSelectedTeams.add(team);
                      } else {
                        tempSelectedTeams.remove(team);
                      }
                    });
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, tempSelectedTeams),
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedHomeTeams = result;
      });
      await _preferencesService.setHomeTeams(result);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.isEmpty
                  ? 'HOMEチームが選択されていません'
                  : 'HOMEチームを${result.length}件選択しました',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppSettings.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                // 表示設定セクション
                _buildSectionHeader('表示設定'),
                Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('配信視聴を含める'),
                        subtitle: const Text('DAZN視聴の試合も表示します'),
                        value: settings.includeStreaming,
                        onChanged: (value) {
                          settings.setIncludeStreaming(value);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                value ? '配信視聴を含めます' : 'スタジアム観戦のみ表示します',
                              ),
                            ),
                          );
                        },
                        secondary: Icon(
                          settings.includeStreaming ? Icons.tv : Icons.stadium,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        title: const Text('試合リストを昇順に表示'),
                        subtitle: const Text('ONで日付が古い順、OFFで新しい順'),
                        value: settings.matchSortAscending,
                        onChanged: (value) {
                          settings.setMatchSortAscending(value);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                value ? '日付の古い順に表示します' : '日付の新しい順に表示します',
                              ),
                            ),
                          );
                        },
                        secondary: Icon(
                          settings.matchSortAscending
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // チーム設定セクション
                _buildSectionHeader('チーム設定'),
                Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(
                          Icons.sports_soccer,
                          color: Theme.of(context).primaryColor,
                        ),
                        title: const Text('HOMEチーム'),
                        subtitle: Text(
                          _selectedHomeTeams.isEmpty
                              ? '未選択'
                              : '${_selectedHomeTeams.length}チーム選択中',
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: _showHomeTeamSelectionDialog,
                      ),
                      if (_selectedHomeTeams.isNotEmpty) ...[
                        const Divider(height: 1),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Wrap(
                            spacing: 8.0,
                            runSpacing: 8.0,
                            children: _selectedHomeTeams.map((team) {
                              return Chip(
                                label: Text(team),
                                deleteIcon: const Icon(Icons.close, size: 16),
                                onDeleted: () async {
                                  setState(() {
                                    _selectedHomeTeams.remove(team);
                                  });
                                  await _preferencesService
                                      .setHomeTeams(_selectedHomeTeams);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('「$team」を削除しました'),
                                      ),
                                    );
                                  }
                                },
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                      const Divider(height: 1),
                      // アウェイチームのリーグ選択
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(Icons.groups),
                              title: Text('対戦相手のリーグ'),
                              subtitle: Text('予定登録時に選択できるアウェイチームのリーグ'),
                            ),
                            ...[
                              ('j1', 'J1リーグ'),
                              ('j2', 'J2リーグ'),
                              ('j3', 'J3リーグ'),
                            ].map((entry) {
                              final leagueKey = entry.$1;
                              final leagueLabel = entry.$2;
                              final isSelected = settings.selectedLeagues.contains(leagueKey);
                              return CheckboxListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(leagueLabel),
                                value: isSelected,
                                onChanged: (checked) {
                                  final updated = List<String>.from(settings.selectedLeagues);
                                  if (checked == true) {
                                    updated.add(leagueKey);
                                  } else {
                                    updated.remove(leagueKey);
                                  }
                                  settings.setSelectedLeagues(updated);
                                },
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 説明テキスト
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'HOMEチームは試合登録時に選択できる応援チームです。\n'
                    'J1, J2, J3, 日本代表の中から選択できます。\n'
                    '対戦相手のリーグを絞り込むと、予定登録時の選択肢が絞られます。',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                  ),
                ),
              ],
            ),
    );
  }

  /// セクションヘッダーを構築
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }
}
