import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_theme.dart';
import '../../../domain/entities/dose_time.dart';
import '../../../domain/entities/medication.dart';
import '../../../domain/exceptions/medication_exceptions.dart';
import '../../../domain/usecases/save_medication.dart';
import '../../providers/medication_providers.dart';
import '../../widgets/weekday_format.dart';

class MedicationFormPage extends ConsumerStatefulWidget {
  const MedicationFormPage({super.key, this.initial});

  /// null이면 신규 등록
  final Medication? initial;

  static Future<void> open(BuildContext context, {Medication? initial}) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MedicationFormPage(initial: initial),
        fullscreenDialog: initial == null,
      ),
    );
  }

  @override
  ConsumerState<MedicationFormPage> createState() => _MedicationFormPageState();
}

class _MedicationFormPageState extends ConsumerState<MedicationFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _memoController;
  late List<DoseTime> _times;
  late Set<int> _weekdays;
  bool _saving = false;

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _nameController = TextEditingController(text: initial?.name);
    _memoController = TextEditingController(text: initial?.memo);
    _times = [...?initial?.times];
    if (_times.isEmpty) _times = [const DoseTime(8, 0)];
    _weekdays = {...?initial?.weekdays};
    if (_weekdays.isEmpty) _weekdays = {...Medication.allWeekdays};
  }

  @override
  void dispose() {
    _nameController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  Future<DoseTime?> _pickTime(DoseTime initial) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initial.hour, minute: initial.minute),
      helpText: '복용 시간',
    );
    return picked == null ? null : DoseTime(picked.hour, picked.minute);
  }

  Future<void> _addTime() async {
    final base = _times.isEmpty ? const DoseTime(8, 0) : _times.last;
    final suggested = DoseTime((base.hour + 4) % 24, base.minute);
    final picked = await _pickTime(suggested);
    if (picked == null || _times.contains(picked)) return;
    setState(() => _times = [..._times, picked]..sort());
  }

  Future<void> _editTime(DoseTime current) async {
    final picked = await _pickTime(current);
    if (picked == null || picked == current) return;
    setState(() {
      _times = {..._times.where((t) => t != current), picked}.toList()..sort();
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(medicationsProvider.notifier).save(
            Medication(
              id: widget.initial?.id,
              name: _nameController.text,
              memo: _memoController.text,
              times: _times,
              weekdays: _weekdays,
              createdAt: widget.initial?.createdAt ?? DateTime.now(),
            ),
          );
      if (mounted) Navigator.of(context).pop();
    } on MedicationException catch (e) {
      _showMessage(_messageOf(e));
    } catch (_) {
      _showMessage('저장하지 못했어요. 다시 시도해 주세요.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('약을 삭제할까요?'),
        content: const Text('알림과 복용 기록도 함께 삭제돼요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await ref.read(medicationsProvider.notifier).delete(widget.initial!.id!);
    if (mounted) Navigator.of(context).pop();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _messageOf(MedicationException e) => switch (e) {
        MedicationValidationException(:final error) => switch (error) {
            MedicationValidationError.emptyName => '약 이름을 입력해 주세요.',
            MedicationValidationError.noTimes => '복용 시간을 하나 이상 추가해 주세요.',
            MedicationValidationError.tooManyTimes =>
              '복용 시간은 최대 ${SaveMedication.maxTimesPerMedication}개까지 등록할 수 있어요.',
            MedicationValidationError.noWeekdays => '복용 요일을 하나 이상 선택해 주세요.',
          },
        ReminderLimitExceededException(:final limit) =>
          '알림은 최대 $limit개까지 예약할 수 있어요. 복용 시간이나 요일을 줄여 주세요.',
      };

  void _setWeekdays(Set<int> days) => setState(() => _weekdays = {...days});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = AppPalette.of(context);
    final canAddTime = _times.length < SaveMedication.maxTimesPerMedication;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: '닫기',
          icon: Icon(
            _isEdit ? Icons.arrow_back_ios_new_rounded : Icons.close_rounded,
            size: 22,
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(_isEdit ? '약 수정' : '약 추가'),
        actions: [
          if (_isEdit)
            TextButton(
              style: TextButton.styleFrom(foregroundColor: p.danger),
              onPressed: _saving ? null : _delete,
              child: const Text('삭제'),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _FormCard(
              children: [
                const _FieldLabel('약 이름'),
                TextFormField(
                  controller: _nameController,
                  autofocus: !_isEdit,
                  style: theme.textTheme.titleMedium,
                  decoration: const InputDecoration(
                    hintText: '예: 혈압약',
                    counterText: '',
                  ),
                  maxLength: 30,
                  textInputAction: TextInputAction.next,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? '약 이름을 입력해 주세요'
                      : null,
                ),
                const SizedBox(height: 20),
                const _FieldLabel('메모', optional: true),
                TextFormField(
                  controller: _memoController,
                  decoration: const InputDecoration(
                    hintText: '예: 식후 30분, 1정',
                    counterText: '',
                  ),
                  maxLength: 50,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _FormCard(
              children: [
                _FieldLabel(
                  '복용 시간',
                  trailing:
                      '${_times.length}/${SaveMedication.maxTimesPerMedication}',
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final time in _times)
                      _TimePill(
                        label: time.label,
                        onTap: () => _editTime(time),
                        onRemove: _times.length > 1
                            ? () => setState(
                                  () => _times = [..._times]..remove(time),
                                )
                            : null,
                      ),
                    if (canAddTime) _AddTimePill(onTap: _addTime),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            _FormCard(
              children: [
                _FieldLabel('복용 요일', trailing: formatWeekdays(_weekdays)),
                Row(
                  children: [
                    for (var day = 1; day <= 7; day++) ...[
                      if (day > 1) const SizedBox(width: 6),
                      Expanded(
                        child: _DayToggle(
                          label: weekdayLabels[day - 1],
                          selected: _weekdays.contains(day),
                          onTap: () => setState(() {
                            _weekdays = {..._weekdays};
                            _weekdays.contains(day)
                                ? _weekdays.remove(day)
                                : _weekdays.add(day);
                          }),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _PresetChip(
                      label: '매일',
                      selected: _weekdays.length == 7,
                      onTap: () => _setWeekdays(Medication.allWeekdays),
                    ),
                    const SizedBox(width: 6),
                    _PresetChip(
                      label: '평일',
                      selected: formatWeekdays(_weekdays) == '평일',
                      onTap: () => _setWeekdays({1, 2, 3, 4, 5}),
                    ),
                    const SizedBox(width: 6),
                    _PresetChip(
                      label: '주말',
                      selected: formatWeekdays(_weekdays) == '주말',
                      onTap: () => _setWeekdays({6, 7}),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4, top: 1),
                  child: Icon(
                    Icons.notifications_active_rounded,
                    size: 16,
                    color: p.textTertiary,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '설정한 시간에 매일(또는 선택한 요일마다) 알림이 와요.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: p.textTertiary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
            ),
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(_isEdit ? '저장하기' : '추가하기'),
          ),
        ),
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text, {this.trailing, this.optional = false});

  final String text;
  final String? trailing;
  final bool optional;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(
            text,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: p.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
          if (optional) ...[
            const SizedBox(width: 6),
            Text('선택', style: TextStyle(fontSize: 13, color: p.textTertiary)),
          ],
          const Spacer(),
          if (trailing != null)
            Text(
              trailing!,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: p.accent,
              ),
            ),
        ],
      ),
    );
  }
}

class _TimePill extends StatelessWidget {
  const _TimePill({required this.label, required this.onTap, this.onRemove});

  final String label;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Material(
      color: p.accentSoft,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.fromLTRB(14, 10, onRemove == null ? 14 : 8, 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: p.accent,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              if (onRemove != null) ...[
                const SizedBox(width: 4),
                Semantics(
                  button: true,
                  label: '$label 삭제',
                  child: GestureDetector(
                    onTap: onRemove,
                    child: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: p.accent.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AddTimePill extends StatelessWidget {
  const _AddTimePill({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Material(
      color: p.fill,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded, size: 18, color: p.textSecondary),
              const SizedBox(width: 4),
              Text(
                '시간 추가',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: p.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DayToggle extends StatelessWidget {
  const _DayToggle({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? p.accent : p.fill,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : p.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? p.textPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: selected ? p.textPrimary : p.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? p.card : p.textSecondary,
          ),
        ),
      ),
    );
  }
}
