import 'package:flutter/material.dart';
import '../models/season.dart';
import '../services/season_service.dart';

/// シーズン登録・編集画面
///
/// 新規登録モード: season = null
/// 編集モード: season != null
class SeasonFormScreen extends StatefulWidget {
  final Season? season; // 編集時は既存のSeasonを渡す

  const SeasonFormScreen({super.key, this.season});

  @override
  State<SeasonFormScreen> createState() => _SeasonFormScreenState();
}

class _SeasonFormScreenState extends State<SeasonFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _seasonService = SeasonService();

  late TextEditingController _nameController;
  late TextEditingController _yearController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.season?.name ?? '');
    _yearController = TextEditingController(
      text: widget.season?.year.toString() ?? DateTime.now().year.toString(),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  /// シーズンを保存
  Future<void> _saveSeason() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      final name = _nameController.text.trim();
      final year = int.parse(_yearController.text.trim());

      if (widget.season == null) {
        // 新規登録
        final newSeason = Season(name: name, year: year);
        await _seasonService.addSeason(newSeason);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('シーズンを追加しました')),
        );
      } else {
        // 編集
        widget.season!.name = name;
        widget.season!.year = year;
        await widget.season!.save();

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('シーズンを更新しました')),
        );
      }

      if (mounted) {
        Navigator.of(context).pop(true); // 保存成功を通知
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存に失敗しました: $e')),
        );
      }
    }
  }

  /// シーズンを削除
  Future<void> _deleteSeason() async {
    if (widget.season == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('シーズンを削除'),
        content: Text(
          '「${widget.season!.name}」を削除しますか？\n'
          'このシーズンに登録されている${widget.season!.matches.length}試合も削除されます。',
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
        await widget.season!.delete();

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('シーズンを削除しました')),
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
    final isEditMode = widget.season != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'シーズンを編集' : '新しいシーズン'),
        actions: isEditMode
            ? [
                IconButton(
                  icon: const Icon(Icons.delete),
                  tooltip: '削除',
                  onPressed: _deleteSeason,
                ),
              ]
            : null,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // シーズン名
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'シーズン名',
                hintText: '例: 2026シーズン、2026 J1リーグ',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'シーズン名を入力してください';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // 年度
            TextFormField(
              controller: _yearController,
              decoration: const InputDecoration(
                labelText: '年度',
                hintText: '例: 2026',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '年度を入力してください';
                }
                final year = int.tryParse(value.trim());
                if (year == null) {
                  return '有効な年度を入力してください';
                }
                if (year < 1900 || year > 2100) {
                  return '1900年から2100年の範囲で入力してください';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // 保存ボタン
            FilledButton.icon(
              onPressed: _saveSeason,
              icon: const Icon(Icons.save),
              label: Text(isEditMode ? '更新' : '追加'),
            ),
            const SizedBox(height: 8),

            // キャンセルボタン
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('キャンセル'),
            ),
          ],
        ),
      ),
    );
  }
}
