import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/theme/theme_notifier.dart';
import '../../data/models/models.dart';
import '../../viewmodels/viewmodels.dart';
import '../shared/widgets/widgets.dart';

class RegisterPostView extends StatelessWidget {
  final PostModel? post;
  const RegisterPostView({super.key, this.post});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RegisterPostViewModel(initialPost: post),
      child: const _RegisterPostContent(),
    );
  }
}

class _RegisterPostContent extends StatefulWidget {
  const _RegisterPostContent();
  @override
  State<_RegisterPostContent> createState() => _RegisterPostContentState();
}

class _RegisterPostContentState extends State<_RegisterPostContent> {
  final _titleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final p = context.read<RegisterPostViewModel>().initialPost;
    if (p != null) {
      _titleController.text = p.title;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _showImageSourceSheet(BuildContext context) {
    final ext = context.athlos;
    showModalBottomSheet(
      context: context,
      backgroundColor: ext.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 36, height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 16),
            decoration: BoxDecoration(color: ext.borderColor, borderRadius: BorderRadius.circular(2)),
          ),
          ListTile(
            leading: Icon(Icons.photo_library_outlined, color: ext.primaryColor),
            title: Text('Galeria de fotos', style: TextStyle(color: ext.textPrimary, fontSize: 14)),
            onTap: () {
              Navigator.pop(ctx);
              context.read<RegisterPostViewModel>().pickImage(ImageSource.gallery);
            },
          ),
          ListTile(
            leading: Icon(Icons.camera_alt_outlined, color: ext.primaryColor),
            title: Text('Câmera', style: TextStyle(color: ext.textPrimary, fontSize: 14)),
            onTap: () {
              Navigator.pop(ctx);
              context.read<RegisterPostViewModel>().pickImage(ImageSource.camera);
            },
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RegisterPostViewModel>();
    final ext = context.athlos;
    final isEdit = vm.isEditMode;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: ext.backgroundColor,
      appBar: AthlosAppBar(title: isEdit ? 'Editar Postagem' : 'Nova Postagem'),
      body: Column(children: [
        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              isEdit ? 'Editar\nPostagem' : 'Nova\nPostagem',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: ext.textPrimary, height: 1.2),
            ),
            const SizedBox(height: 6),
            Text(
              isEdit ? 'Atualize o conteúdo da postagem.' : 'Publique um novo aviso ou comunicado.',
              style: TextStyle(fontSize: 12, color: ext.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 20),

            // Imagem da postagem
            AthlosCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.image_outlined, size: 16, color: ext.primaryColor),
                const SizedBox(width: 6),
                Text('Imagem (opcional)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ext.textPrimary)),
              ]),
              const SizedBox(height: 14),
              if (vm.selectedImage != null) ...[
                Stack(children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      File(vm.selectedImage!.path),
                      width: double.infinity,
                      height: 180,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 8, right: 8,
                    child: GestureDetector(
                      onTap: () => context.read<RegisterPostViewModel>().removeImage(),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, color: Colors.white, size: 14),
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => _showImageSourceSheet(context),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.swap_horiz, size: 14, color: ext.primaryColor),
                    const SizedBox(width: 4),
                    Text('Trocar imagem', style: TextStyle(fontSize: 12, color: ext.primaryColor, fontWeight: FontWeight.w500)),
                  ]),
                ),
              ] else
                GestureDetector(
                  onTap: () => _showImageSourceSheet(context),
                  child: Container(
                    width: double.infinity,
                    height: 120,
                    decoration: BoxDecoration(
                      color: ext.surfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: ext.borderColor),
                    ),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.add_photo_alternate_outlined, size: 32, color: ext.textSecondary.withOpacity(0.5)),
                      const SizedBox(height: 6),
                      Text('Toque para adicionar imagem', style: TextStyle(fontSize: 12, color: ext.textSecondary)),
                    ]),
                  ),
                ),
            ])),
            const SizedBox(height: 14),

            AthlosCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.article_outlined, size: 16, color: ext.primaryColor),
                const SizedBox(width: 6),
                Text('Conteúdo', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ext.textPrimary)),
              ]),
              const SizedBox(height: 14),
              TextField(
                controller: _titleController,
                maxLines: 4,
                style: TextStyle(fontSize: 13, color: ext.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Digite o texto da postagem...',
                  hintStyle: TextStyle(fontSize: 13, color: ext.textSecondary.withOpacity(0.6)),
                  filled: true,
                  fillColor: ext.surfaceVariant,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: ext.borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: ext.borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: ext.primaryColor),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
            ])),
            const SizedBox(height: 14),

            AthlosCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.label_outline, size: 16, color: ext.primaryColor),
                const SizedBox(width: 6),
                Text('Categoria', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ext.textPrimary)),
              ]),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: RegisterPostViewModel.categories.map((c) {
                  final sel = c == vm.selectedCategory;
                  final catColor = Color(RegisterPostViewModel.categoryColors[c]!);
                  return GestureDetector(
                    onTap: () => context.read<RegisterPostViewModel>().setCategory(c),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: sel ? catColor.withOpacity(0.15) : ext.surfaceVariant,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: sel ? catColor : ext.borderColor),
                      ),
                      child: Text(
                        c,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: sel ? catColor : ext.textSecondary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ])),
          ]),
        )),

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
                final ok = await context.read<RegisterPostViewModel>().save(
                  title: _titleController.text,
                );
                if (ok && context.mounted) Navigator.pop(context);
              },
              icon: vm.isLoading
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Icon(isEdit ? Icons.save_outlined : Icons.send_outlined, size: 16, color: Colors.white),
              label: Text(
                vm.isLoading
                    ? (isEdit ? 'Salvando...' : 'Publicando...')
                    : (isEdit ? 'Salvar →' : 'Publicar →'),
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
