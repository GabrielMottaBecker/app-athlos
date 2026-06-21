import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/theme/theme_notifier.dart';
import '../../data/models/models.dart';
import '../../viewmodels/viewmodels.dart';
import '../shared/widgets/widgets.dart';

class RegisterProductView extends StatelessWidget {
  final ProductModel? product;
  const RegisterProductView({super.key, this.product});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RegisterProductViewModel(initialProduct: product),
      child: const _RegisterProductContent(),
    );
  }
}

class _RegisterProductContent extends StatefulWidget {
  const _RegisterProductContent();
  @override
  State<_RegisterProductContent> createState() => _RegisterProductContentState();
}

class _RegisterProductContentState extends State<_RegisterProductContent> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _estoqueController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final p = context.read<RegisterProductViewModel>().initialProduct;
    if (p != null) {
      _nameController.text = p.name;
      _priceController.text = p.price.toStringAsFixed(2).replaceAll('.', ',');
      _descriptionController.text = p.description;
      _estoqueController.text = p.estoque.toString();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _estoqueController.dispose();
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
              context.read<RegisterProductViewModel>().pickImage(ImageSource.gallery);
            },
          ),
          ListTile(
            leading: Icon(Icons.camera_alt_outlined, color: ext.primaryColor),
            title: Text('Câmera', style: TextStyle(color: ext.textPrimary, fontSize: 14)),
            onTap: () {
              Navigator.pop(ctx);
              context.read<RegisterProductViewModel>().pickImage(ImageSource.camera);
            },
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RegisterProductViewModel>();
    final ext = context.athlos;
    final isEdit = vm.isEditMode;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: ext.backgroundColor,
      appBar: AthlosAppBar(title: isEdit ? 'Editar Produto' : 'Novo Produto'),
      body: Column(children: [
        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              isEdit ? 'Editar\nProduto' : 'Novo\nProduto',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: ext.textPrimary, height: 1.2),
            ),
            const SizedBox(height: 6),
            Text(
              isEdit ? 'Atualize as informações do produto.' : 'Adicione um novo produto à loja.',
              style: TextStyle(fontSize: 12, color: ext.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 20),

            // Foto do produto
            AthlosCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.image_outlined, size: 16, color: ext.primaryColor),
                const SizedBox(width: 6),
                Text('Foto do Produto', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ext.textPrimary)),
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
                      onTap: () => context.read<RegisterProductViewModel>().removeImage(),
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
                    height: 140,
                    decoration: BoxDecoration(
                      color: ext.surfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: ext.borderColor, style: BorderStyle.solid),
                    ),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.add_photo_alternate_outlined, size: 36, color: ext.textSecondary.withOpacity(0.5)),
                      const SizedBox(height: 8),
                      Text('Toque para adicionar foto', style: TextStyle(fontSize: 12, color: ext.textSecondary)),
                    ]),
                  ),
                ),
            ])),
            const SizedBox(height: 14),

            AthlosCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.inventory_2_outlined, size: 16, color: ext.primaryColor),
                const SizedBox(width: 6),
                Text('Informações do Produto', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ext.textPrimary)),
              ]),
              const SizedBox(height: 14),
              AthlosTextField(hint: 'Ex: Camiseta Atlética 2026', label: 'NOME DO PRODUTO', controller: _nameController),
              const SizedBox(height: 12),
              AthlosTextField(
                hint: 'Ex: Camiseta oficial da atlética, 100% algodão',
                label: 'DESCRIÇÃO',
                controller: _descriptionController,
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              AthlosTextField(
                hint: '0,00',
                label: 'PREÇO (R\$)',
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 12),
              AthlosTextField(
                hint: 'Ex: 100',
                label: 'ESTOQUE',
                controller: _estoqueController,
                keyboardType: TextInputType.number,
              ),
            ])),
            const SizedBox(height: 14),

            AthlosCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.category_outlined, size: 16, color: ext.primaryColor),
                const SizedBox(width: 6),
                Text('Categoria', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ext.textPrimary)),
              ]),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: RegisterProductViewModel.categories.map((c) {
                  final sel = c == vm.selectedCategory;
                  return GestureDetector(
                    onTap: () => context.read<RegisterProductViewModel>().setCategory(c),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: sel ? ext.primaryColor : ext.surfaceVariant,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: sel ? ext.primaryColor : ext.borderColor),
                      ),
                      child: Text(
                        c,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: sel ? Colors.white : ext.textSecondary,
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
                final ok = await context.read<RegisterProductViewModel>().save(
                  name: _nameController.text,
                  price: _priceController.text,
                  description: _descriptionController.text,
                  estoque: _estoqueController.text,
                );
                if (ok && context.mounted) Navigator.pop(context);
              },
              icon: vm.isLoading
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Icon(isEdit ? Icons.save_outlined : Icons.add_shopping_cart, size: 16, color: Colors.white),
              label: Text(
                vm.isLoading
                    ? (isEdit ? 'Salvando...' : 'Cadastrando...')
                    : (isEdit ? 'Salvar →' : 'Cadastrar →'),
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