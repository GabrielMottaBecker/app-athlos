import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/theme_notifier.dart';
import '../../data/models/models.dart';
import '../../viewmodels/viewmodels.dart';
import '../shared/widgets/widgets.dart';

class RegisterEventView extends StatelessWidget {
  final EventModel? event;
  const RegisterEventView({super.key, this.event});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RegisterEventViewModel(initialEvent: event),
      child: const _RegisterEventContent(),
    );
  }
}

class _RegisterEventContent extends StatefulWidget {
  const _RegisterEventContent();
  @override
  State<_RegisterEventContent> createState() => _RegisterEventContentState();
}

class _RegisterEventContentState extends State<_RegisterEventContent> {
  final _titleController = TextEditingController();
  final _dateController = TextEditingController();
  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();
  final _placeController = TextEditingController();

  static const List<String> _months = [
    'JAN','FEV','MAR','ABR','MAI','JUN','JUL','AGO','SET','OUT','NOV','DEZ',
  ];

  static const Map<String, Color> _typeColors = {
    'TREINO': Color(0xFF10B981),
    'EVENTO SOCIAL': Color(0xFFF59E0B),
    'EXTRAS': Color(0xFF8B5CF6),
  };

  static const Map<String, IconData> _typeIcons = {
    'TREINO': Icons.fitness_center,
    'EVENTO SOCIAL': Icons.celebration_outlined,
    'EXTRAS': Icons.star_outline,
  };

  @override
  void initState() {
    super.initState();
    final e = context.read<RegisterEventViewModel>().initialEvent;
    if (e != null) {
      _titleController.text = e.title;
      _dateController.text = e.date;
      _placeController.text = e.place;
      final parts = e.time.split('–');
      _startTimeController.text = parts.first.trim();
      if (parts.length > 1) _endTimeController.text = parts.last.trim();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _dateController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    _placeController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      _dateController.text = '${_months[picked.month - 1]} ${picked.day.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _pickTime(TextEditingController controller) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked != null) {
      controller.text =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RegisterEventViewModel>();
    final ext = context.athlos;
    final isEdit = vm.isEditMode;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: ext.backgroundColor,
      appBar: AthlosAppBar(title: isEdit ? 'Editar Evento' : 'Novo Evento'),
      body: Column(children: [
        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              isEdit ? 'Editar\nEvento' : 'Criar\nEvento',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: ext.textPrimary, height: 1.2),
            ),
            const SizedBox(height: 6),
            Text(
              isEdit
                  ? 'Atualize as informações do evento na agenda.'
                  : 'Adicione um novo evento à agenda da atlética.',
              style: TextStyle(fontSize: 12, color: ext.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 20),

            // Tipo do evento
            AthlosCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.category_outlined, size: 16, color: ext.primaryColor),
                const SizedBox(width: 6),
                Text('Tipo do Evento', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ext.textPrimary)),
              ]),
              const SizedBox(height: 14),
              Row(children: RegisterEventViewModel.types.map((t) {
                final sel = t == vm.selectedType;
                final color = _typeColors[t] ?? ext.primaryColor;
                return Expanded(child: Padding(
                  padding: EdgeInsets.only(right: t != RegisterEventViewModel.types.last ? 8 : 0),
                  child: GestureDetector(
                    onTap: () => context.read<RegisterEventViewModel>().setType(t),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: sel ? color.withOpacity(0.15) : ext.surfaceVariant,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: sel ? color : ext.borderColor),
                      ),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(_typeIcons[t], size: 20, color: sel ? color : ext.textSecondary),
                        const SizedBox(height: 4),
                        Text(
                          t,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: sel ? color : ext.textSecondary),
                        ),
                      ]),
                    ),
                  ),
                ));
              }).toList()),
            ])),
            const SizedBox(height: 14),

            // Informações do evento
            AthlosCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.info_outline, size: 16, color: ext.primaryColor),
                const SizedBox(width: 6),
                Text('Informações', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ext.textPrimary)),
              ]),
              const SizedBox(height: 14),
              AthlosTextField(
                hint: 'Ex: TREINO DE FUTEBOL',
                label: 'TÍTULO',
                controller: _titleController,
              ),
              const SizedBox(height: 12),
              // Data: digitação livre + ícone de calendário
              AthlosTextField(
                hint: 'Ex: JUN 14',
                label: 'DATA',
                controller: _dateController,
                suffixIcon: IconButton(
                  icon: Icon(Icons.calendar_month_outlined, size: 18, color: ext.primaryColor),
                  onPressed: _pickDate,
                ),
              ),
              const SizedBox(height: 12),
              // Horários: somente números + ícone de relógio
              Row(children: [
                Expanded(child: AthlosTextField(
                  hint: '19:00',
                  label: 'INÍCIO',
                  controller: _startTimeController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9:]')),
                    LengthLimitingTextInputFormatter(5),
                  ],
                  suffixIcon: IconButton(
                    icon: Icon(Icons.access_time, size: 16, color: ext.primaryColor),
                    onPressed: () => _pickTime(_startTimeController),
                  ),
                )),
                const SizedBox(width: 12),
                Expanded(child: AthlosTextField(
                  hint: '21:00',
                  label: 'FIM',
                  controller: _endTimeController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9:]')),
                    LengthLimitingTextInputFormatter(5),
                  ],
                  suffixIcon: IconButton(
                    icon: Icon(Icons.access_time, size: 16, color: ext.primaryColor),
                    onPressed: () => _pickTime(_endTimeController),
                  ),
                )),
              ]),
            ])),
            const SizedBox(height: 14),

            // Local
            AthlosCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.location_on_outlined, size: 16, color: ext.primaryColor),
                const SizedBox(width: 6),
                Text('Local', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ext.textPrimary)),
              ]),
              const SizedBox(height: 14),
              AthlosTextField(
                hint: 'Ex: Campo de Treinamento Alpha',
                label: 'LOCAL',
                controller: _placeController,
              ),
            ])),
            const SizedBox(height: 14),

            // Preview da cor
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: (_typeColors[vm.selectedType] ?? ext.primaryColor).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: (_typeColors[vm.selectedType] ?? ext.primaryColor).withOpacity(0.3)),
              ),
              child: Row(children: [
                Icon(_typeIcons[vm.selectedType], color: _typeColors[vm.selectedType] ?? ext.primaryColor, size: 18),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    'Cor do evento',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _typeColors[vm.selectedType] ?? ext.primaryColor),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'A cor do card é definida automaticamente pelo tipo selecionado.',
                    style: TextStyle(fontSize: 11, color: ext.textSecondary, height: 1.4),
                  ),
                ])),
              ]),
            ),
          ]),
        )),

        // Botões
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ext.surfaceColor,
            border: Border(top: BorderSide(color: ext.borderColor)),
          ),
          child: Row(children: [
            Expanded(child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: ext.primaryColor,
                side: BorderSide(color: ext.borderColor),
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
              child: const Text('Cancelar'),
            )),
            const SizedBox(width: 10),
            Expanded(flex: 2, child: ElevatedButton.icon(
              onPressed: vm.isLoading ? null : () async {
                final ok = await context.read<RegisterEventViewModel>().save(
                  title: _titleController.text,
                  date: _dateController.text,
                  startTime: _startTimeController.text,
                  endTime: _endTimeController.text,
                  place: _placeController.text,
                );
                if (ok && context.mounted) Navigator.pop(context);
              },
              icon: vm.isLoading
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Icon(isEdit ? Icons.save_outlined : Icons.add_circle_outline, size: 16, color: Colors.white),
              label: Text(
                vm.isLoading
                    ? (isEdit ? 'Salvando...' : 'Criando...')
                    : (isEdit ? 'Salvar →' : 'Criar Evento →'),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 13)),
            )),
          ]),
        ),
      ]),
    );
  }
}
