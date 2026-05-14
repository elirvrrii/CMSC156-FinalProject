import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/recipe.dart';
import '../services/recipe_service.dart';

// ═══════════════════════════════════════════════════════════════════════════
// ADD RECIPE PAGE
// ═══════════════════════════════════════════════════════════════════════════

class AddRecipePage extends StatefulWidget {
  const AddRecipePage({super.key});

  static void show(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, animation, _) => const AddRecipePage(),
        transitionsBuilder: (_, animation, _, child) => SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
              .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 320),
      ),
    );
  }

  @override
  State<AddRecipePage> createState() => _AddRecipePageState();
}

class _AddRecipePageState extends State<AddRecipePage> {
  final _nameController = TextEditingController();
  final _cookTimeController = TextEditingController();
  final _recipeService = RecipeService();
  final _imagePicker = ImagePicker();
  String? _selectedCategory;
  String? _selectedImagePath;
  bool _isLoading = false;

  final List<_IngredientEntry> _ingredients = [_IngredientEntry()];
  final List<_StepEntry> _steps = [_StepEntry()];

  static const List<String> _categories = [
    'main dish',
    'side dish',
    'appetizer',
    'dessert',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _cookTimeController.dispose();
    for (final e in _ingredients) {
      e.dispose();
    }
    for (final e in _steps) {
      e.dispose();
    }
    super.dispose();
  }

  void _addIngredient() => setState(() => _ingredients.add(_IngredientEntry()));
  void _addStep() => setState(() => _steps.add(_StepEntry()));

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (image != null) {
        setState(() => _selectedImagePath = image.path);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image selected'),
            duration: Duration(milliseconds: 800),
          ),
        );
      }
    } catch (e) {
      print('Image picker error: $e');
      if (mounted) {
        _showError('Unable to access image picker. Please check permissions.');
      }
    }
  }

  void _submit() async {
    // Validate inputs
    if (_nameController.text.trim().isEmpty) {
      _showError('Please enter a recipe name');
      return;
    }

    if (_selectedCategory == null) {
      _showError('Please select a category');
      return;
    }

    if (_cookTimeController.text.trim().isEmpty) {
      _showError('Please enter cook time');
      return;
    }

    if (_selectedImagePath == null) {
      _showError('Please select a recipe image');
      return;
    }

    // Filter out empty ingredients
    final validIngredients = _ingredients
        .where((ing) => ing.nameController.text.trim().isNotEmpty)
        .map((ing) => RecipeIngredient(
              label:
                  '${ing.nameController.text} (${ing.quantityController.text})',
            ))
        .toList();

    if (validIngredients.isEmpty) {
      _showError('Please add at least one ingredient');
      return;
    }

    // Filter out empty steps
    final validSteps = _steps
        .where((step) => step.controller.text.trim().isNotEmpty)
        .map((step) => RecipeStep(text: step.controller.text))
        .toList();

    if (validSteps.isEmpty) {
      _showError('Please add at least one step');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final cookTimeMinutes = int.tryParse(_cookTimeController.text) ?? 0;

      await _recipeService.addRecipe(
        name: _nameController.text.trim(),
        category: _selectedCategory!,
        cookTimeMinutes: cookTimeMinutes,
        ingredients: validIngredients,
        steps: validSteps,
        imagePath: _selectedImagePath!,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recipe added successfully!'),
            backgroundColor: Color(0xFF8FA67A),
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      _showError('Failed to add recipe: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFE57373),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F1EC),
      body: Column(
        children: [
          // ── Beige top section ───────────────────────────────────────────
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: const Icon(Icons.arrow_back_ios_new_rounded,
                            size: 20, color: Color(0xFF4A4A4A)),
                      ),
                      const Expanded(
                        child: Text(
                          'Add Recipe',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'serif',
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2E2E2E),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Image upload placeholder
                GestureDetector(
                  onTap: _pickImage,
                  child: SizedBox(
                    width: 90,
                    height: 90,
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: _selectedImagePath == null
                                ? const Color(0xFFC8956C).withOpacity(0.15)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _selectedImagePath == null
                                  ? const Color(0xFFC8956C)
                                  : Colors.transparent,
                              width: 2,
                            ),
                            image: _selectedImagePath != null
                                ? DecorationImage(
                                    image: FileImage(File(_selectedImagePath!)),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: _selectedImagePath == null
                              ? const Center(
                                  child: Icon(Icons.image_outlined,
                                      size: 48, color: Color(0xFFC8956C)),
                                )
                              : null,
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: const BoxDecoration(
                              color: Color(0xFFC8956C),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.add,
                                color: Colors.white, size: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _selectedImagePath == null ? 'Recipe image *' : 'Change image',
                  style: TextStyle(
                    fontSize: 12,
                    color: _selectedImagePath == null
                        ? const Color(0xFFE57373)
                        : const Color(0xFF8FA67A),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),

          // ── White curved form area ──────────────────────────────────────
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _OutlinedField(
                      label: 'Recipe Name',
                      controller: _nameController,
                      hint: 'Enter recipe name here',
                    ),
                    const SizedBox(height: 16),
                    _CategoryDropdown(
                      categories: _categories,
                      selected: _selectedCategory,
                      onChanged: (v) => setState(() => _selectedCategory = v),
                    ),
                    const SizedBox(height: 16),
                    _OutlinedField(
                      label: 'Cook Time (mins)',
                      controller: _cookTimeController,
                      hint: 'Enter cooking time here',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 20),

                    // Ingredients
                    const _SectionLabel(label: 'Ingredients'),
                    const SizedBox(height: 8),
                    ...List.generate(_ingredients.length, (i) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _IngredientRow(
                        entry: _ingredients[i],
                        onAdd: i == _ingredients.length - 1 ? _addIngredient : null,
                      ),
                    )),

                    const SizedBox(height: 16),

                    // Steps
                    const _SectionLabel(label: 'Steps'),
                    const SizedBox(height: 8),
                    ...List.generate(_steps.length, (i) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _StepRow(
                        entry: _steps[i],
                        stepNumber: i + 1,
                        onAdd: i == _steps.length - 1 ? _addStep : null,
                      ),
                    )),

                    const SizedBox(height: 32),
                    _isLoading
                        ? const SizedBox(
                            height: 52,
                            child: Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF8FA67A),
                              ),
                            ),
                          )
                        : _SubmitButton(label: 'Submit', onTap: _submit),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ADD TWIST PAGE
// ═══════════════════════════════════════════════════════════════════════════

class AddTwistPage extends StatefulWidget {
  final Recipe originalRecipe;

  const AddTwistPage({super.key, required this.originalRecipe});

  static void show(BuildContext context, Recipe recipe) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, animation, _) =>
            AddTwistPage(originalRecipe: recipe),
        transitionsBuilder: (_, animation, _, child) => SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
              .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 320),
      ),
    );
  }

  @override
  State<AddTwistPage> createState() => _AddTwistPageState();
}

class _AddTwistPageState extends State<AddTwistPage> {
  final _nameController = TextEditingController();
  final _recipeService = RecipeService();
  late List<_TwistIngredientEntry> _ingredients;
  late List<_TwistStepEntry> _steps;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _ingredients = widget.originalRecipe.ingredients
        .map((i) => _TwistIngredientEntry(label: i.label, status: IngredientStatus.unchanged))
        .toList();
    _steps = widget.originalRecipe.steps
        .map((s) => _TwistStepEntry(text: s.text, status: StepStatus.unchanged))
        .toList();
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (final e in _ingredients) {
      e.dispose();
    }
    for (final e in _steps) {
      e.dispose();
    }
    super.dispose();
  }

  void _addIngredient() => setState(() => _ingredients
      .add(_TwistIngredientEntry(label: '', status: IngredientStatus.added)));

  void _addStep() => setState(() =>
      _steps.add(_TwistStepEntry(text: '', status: StepStatus.added)));

  void _removeIngredient(int i) => setState(() {
        if (_ingredients[i].status == IngredientStatus.added) {
          _ingredients.removeAt(i);
        } else {
          _ingredients[i].status = IngredientStatus.removed;
        }
      });

  void _removeStep(int i) => setState(() {
        if (_steps[i].status == StepStatus.added) {
          _steps.removeAt(i);
        } else {
          _steps[i].status = StepStatus.removed;
        }
      });

  void _restoreIngredient(int i) =>
      setState(() => _ingredients[i].status = IngredientStatus.unchanged);

  void _restoreStep(int i) =>
      setState(() => _steps[i].status = StepStatus.unchanged);

  void _submit() async {
    // Validate inputs
    if (_nameController.text.trim().isEmpty) {
      _showError('Please enter a twist name');
      return;
    }

    // Get modified ingredients and steps
    final modifiedIngredients = _ingredients
        .where((ing) => ing.status != IngredientStatus.removed)
        .map((ing) => RecipeIngredient(
              label: ing.controller.text,
              status: ing.status == IngredientStatus.added
                  ? IngredientStatus.added
                  : ing.status == IngredientStatus.modified
                      ? IngredientStatus.modified
                      : IngredientStatus.unchanged,
            ))
        .toList();

    final modifiedSteps = _steps
        .where((step) => step.status != StepStatus.removed)
        .map((step) => RecipeStep(
              text: step.controller.text,
              status: step.status == StepStatus.added
                  ? StepStatus.added
                  : step.status == StepStatus.modified
                      ? StepStatus.modified
                      : StepStatus.unchanged,
            ))
        .toList();

    if (modifiedIngredients.isEmpty) {
      _showError('Please have at least one ingredient');
      return;
    }

    if (modifiedSteps.isEmpty) {
      _showError('Please have at least one step');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _recipeService.addTwist(
        parentRecipeId: widget.originalRecipe.id,
        twistName: _nameController.text.trim(),
        modifiedIngredients: modifiedIngredients,
        modifiedSteps: modifiedSteps,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Twist added successfully!'),
            backgroundColor: Color(0xFF8FA67A),
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      _showError('Failed to add twist: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFE57373),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final original = widget.originalRecipe;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F1EC),
      body: Column(
        children: [
          // ── Top section ─────────────────────────────────────────────────
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: const Icon(Icons.arrow_back_ios_new_rounded,
                            size: 20, color: Color(0xFF4A4A4A)),
                      ),
                      const Expanded(
                        child: Text(
                          'Add Twist',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'serif',
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2E2E2E),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Original recipe banner
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC8956C).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: const Color(0xFFC8956C).withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.subdirectory_arrow_right_rounded,
                          size: 16, color: Color(0xFFC8956C)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Twisting: ${original.name} by @${original.author}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFFC8956C),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),

          // ── White curved form area ──────────────────────────────────────
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _OutlinedField(
                      label: 'Twist Name',
                      controller: _nameController,
                      hint: 'Enter your twist name',
                    ),
                    const SizedBox(height: 20),

                    // Ingredients
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const _SectionLabel(label: 'Ingredients'),
                        _AddMoreButton(onTap: _addIngredient),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Edit a field to mark it modified · tap − to remove',
                      style: TextStyle(fontSize: 11, color: Color(0xFFADADAD)),
                    ),
                    const SizedBox(height: 10),
                    ...List.generate(_ingredients.length, (i) {
                      final e = _ingredients[i];
                      return _TwistIngredientRow(
                        entry: e,
                        onRemove: e.status != IngredientStatus.removed
                            ? () => _removeIngredient(i)
                            : null,
                        onRestore: e.status == IngredientStatus.removed
                            ? () => _restoreIngredient(i)
                            : null,
                        onChanged: () => setState(() {
                          if (e.status == IngredientStatus.unchanged) {
                            e.status = IngredientStatus.modified;
                          }
                        }),
                      );
                    }),

                    const SizedBox(height: 20),

                    // Steps
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const _SectionLabel(label: 'Steps'),
                        _AddMoreButton(onTap: _addStep),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Edit a step to mark it modified · tap − to remove',
                      style: TextStyle(fontSize: 11, color: Color(0xFFADADAD)),
                    ),
                    const SizedBox(height: 10),
                    ...List.generate(_steps.length, (i) {
                      final e = _steps[i];
                      return _TwistStepRow(
                        entry: e,
                        stepNumber: i + 1,
                        onRemove: e.status != StepStatus.removed
                            ? () => _removeStep(i)
                            : null,
                        onRestore: e.status == StepStatus.removed
                            ? () => _restoreStep(i)
                            : null,
                        onChanged: () => setState(() {
                          if (e.status == StepStatus.unchanged) {
                            e.status = StepStatus.modified;
                          }
                        }),
                      );
                    }),

                    const SizedBox(height: 32),
                    _isLoading
                        ? const SizedBox(
                            height: 52,
                            child: Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF8FA67A),
                              ),
                            ),
                          )
                        : _SubmitButton(
                            label: 'Submit Twist', onTap: _submit),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ENTRY MODELS
// ═══════════════════════════════════════════════════════════════════════════

class _IngredientEntry {
  final nameController = TextEditingController();
  final quantityController = TextEditingController();
  void dispose() {
    nameController.dispose();
    quantityController.dispose();
  }
}

class _StepEntry {
  final controller = TextEditingController();
  void dispose() => controller.dispose();
}

class _TwistIngredientEntry {
  final controller = TextEditingController();
  IngredientStatus status;

  _TwistIngredientEntry({required String label, required this.status}) {
    controller.text = label;
  }

  void dispose() => controller.dispose();
}

class _TwistStepEntry {
  final controller = TextEditingController();
  StepStatus status;

  _TwistStepEntry({required String text, required this.status}) {
    controller.text = text;
  }

  void dispose() => controller.dispose();
}

// ═══════════════════════════════════════════════════════════════════════════
// SHARED UI COMPONENTS
// ═══════════════════════════════════════════════════════════════════════════

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) => Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF8FA67A),
        ),
      );
}

class _AddMoreButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddMoreButton({required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 26,
          height: 26,
          decoration: const BoxDecoration(
              color: Color(0xFF8FA67A), shape: BoxShape.circle),
          child: const Icon(Icons.add, color: Colors.white, size: 16),
        ),
      );
}

class _SubmitButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _SubmitButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFC8956C),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30)),
          ),
          child: Text(label,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600)),
        ),
      );
}

class _OutlinedField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final TextInputType keyboardType;

  const _OutlinedField({
    required this.label,
    required this.hint,
    required this.controller,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 14, color: Color(0xFF2E2E2E)),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: const TextStyle(
              fontSize: 13,
              color: Color(0xFF8FA67A),
              fontWeight: FontWeight.w500),
          hintStyle:
              const TextStyle(fontSize: 13, color: Color(0xFFBBBBBB)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: Color(0xFF8FA67A), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: Color(0xFF8FA67A), width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      );
}

class _CategoryDropdown extends StatelessWidget {
  final List<String> categories;
  final String? selected;
  final ValueChanged<String?> onChanged;

  const _CategoryDropdown({
    required this.categories,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String>(
        initialValue: selected,
        hint: const Text('Select category',
            style: TextStyle(fontSize: 13, color: Color(0xFFBBBBBB))),
        icon: const Icon(Icons.keyboard_arrow_down_rounded,
            color: Color(0xFF8FA67A)),
        decoration: InputDecoration(
          labelText: 'Recipe Category',
          labelStyle: const TextStyle(
              fontSize: 13,
              color: Color(0xFF8FA67A),
              fontWeight: FontWeight.w500),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: Color(0xFF8FA67A), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: Color(0xFF8FA67A), width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        items: categories
            .map((c) => DropdownMenuItem(
                  value: c,
                  child: Text(c,
                      style: const TextStyle(
                          fontSize: 14, color: Color(0xFF2E2E2E))),
                ))
            .toList(),
        onChanged: onChanged,
      );
}

class _IngredientRow extends StatelessWidget {
  final _IngredientEntry entry;
  final VoidCallback? onAdd;

  const _IngredientRow({required this.entry, this.onAdd});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
              flex: 3,
              child: _miniField(
                  controller: entry.nameController,
                  hint: 'Enter ingredient here')),
          const SizedBox(width: 8),
          Expanded(
              flex: 2,
              child: _miniField(
                  controller: entry.quantityController, hint: 'Quantity')),
          if (onAdd != null) ...[
            const SizedBox(width: 8),
            _AddMoreButton(onTap: onAdd!),
          ],
        ],
      );

  Widget _miniField(
          {required TextEditingController controller,
          required String hint}) =>
      TextField(
        controller: controller,
        style: const TextStyle(fontSize: 13, color: Color(0xFF2E2E2E)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              const TextStyle(fontSize: 12, color: Color(0xFFBBBBBB)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFDDD8D0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: Color(0xFF8FA67A), width: 1.2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      );
}

class _StepRow extends StatelessWidget {
  final _StepEntry entry;
  final int stepNumber;
  final VoidCallback? onAdd;

  const _StepRow(
      {required this.entry, required this.stepNumber, this.onAdd});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
                color: Color(0xFF8FA67A), shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text('$stepNumber',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: entry.controller,
              style: const TextStyle(fontSize: 13, color: Color(0xFF2E2E2E)),
              decoration: InputDecoration(
                hintText: 'Enter step here',
                hintStyle:
                    const TextStyle(fontSize: 12, color: Color(0xFFBBBBBB)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFDDD8D0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                      color: Color(0xFF8FA67A), width: 1.2),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
          ),
          if (onAdd != null) ...[
            const SizedBox(width: 8),
            _AddMoreButton(onTap: onAdd!),
          ],
        ],
      );
}

// ── Twist-specific diff rows ───────────────────────────────────────────────

class _TwistIngredientRow extends StatelessWidget {
  final _TwistIngredientEntry entry;
  final VoidCallback? onRemove;
  final VoidCallback? onRestore;
  final VoidCallback onChanged;

  const _TwistIngredientRow({
    required this.entry,
    required this.onChanged,
    this.onRemove,
    this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    final isRemoved = entry.status == IngredientStatus.removed;
    final isAdded = entry.status == IngredientStatus.added;
    final isModified = entry.status == IngredientStatus.modified;

    final borderColor = isRemoved
        ? const Color(0xFFE57373)
        : isAdded
            ? const Color(0xFF8FA67A)
            : isModified
                ? const Color(0xFFFFB74D)
                : const Color(0xFFDDD8D0);

    final bgColor = isRemoved
        ? const Color(0xFFFFEBEE)
        : isAdded
            ? const Color(0xFFE8F5E9)
            : isModified
                ? const Color(0xFFFFF8E1)
                : Colors.white;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: entry.controller,
              enabled: !isRemoved,
              onChanged: (_) => onChanged(),
              style: TextStyle(
                fontSize: 13,
                color: isRemoved
                    ? const Color(0xFFE57373)
                    : const Color(0xFF2E2E2E),
                decoration:
                    isRemoved ? TextDecoration.lineThrough : null,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: bgColor,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: borderColor),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: borderColor, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (onRestore != null)
            _RestoreButton(onTap: onRestore!)
          else if (onRemove != null)
            _RemoveButton(onTap: onRemove!),
        ],
      ),
    );
  }
}

class _TwistStepRow extends StatelessWidget {
  final _TwistStepEntry entry;
  final int stepNumber;
  final VoidCallback? onRemove;
  final VoidCallback? onRestore;
  final VoidCallback onChanged;

  const _TwistStepRow({
    required this.entry,
    required this.stepNumber,
    required this.onChanged,
    this.onRemove,
    this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    final isRemoved = entry.status == StepStatus.removed;
    final isAdded = entry.status == StepStatus.added;
    final isModified = entry.status == StepStatus.modified;

    final borderColor = isRemoved
        ? const Color(0xFFE57373)
        : isAdded
            ? const Color(0xFF8FA67A)
            : isModified
                ? const Color(0xFFFFB74D)
                : const Color(0xFFDDD8D0);

    final bgColor = isRemoved
        ? const Color(0xFFFFEBEE)
        : isAdded
            ? const Color(0xFFE8F5E9)
            : isModified
                ? const Color(0xFFFFF8E1)
                : Colors.white;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: isRemoved
                  ? const Color(0xFFE57373)
                  : isAdded
                      ? const Color(0xFF8FA67A)
                      : isModified
                          ? const Color(0xFFFFB74D)
                          : const Color(0xFF8FA67A),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text('$stepNumber',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: entry.controller,
              enabled: !isRemoved,
              maxLines: null,
              onChanged: (_) => onChanged(),
              style: TextStyle(
                fontSize: 13,
                color: isRemoved
                    ? const Color(0xFFE57373)
                    : const Color(0xFF2E2E2E),
                decoration:
                    isRemoved ? TextDecoration.lineThrough : null,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: bgColor,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: borderColor),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: borderColor, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: onRestore != null
                ? _RestoreButton(onTap: onRestore!)
                : onRemove != null
                    ? _RemoveButton(onTap: onRemove!)
                    : const SizedBox(width: 28),
          ),
        ],
      ),
    );
  }
}

class _RemoveButton extends StatelessWidget {
  final VoidCallback onTap;
  const _RemoveButton({required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: const Color(0xFFE57373).withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFE57373)),
          ),
          child: const Icon(Icons.remove, size: 14, color: Color(0xFFE57373)),
        ),
      );
}

class _RestoreButton extends StatelessWidget {
  final VoidCallback onTap;
  const _RestoreButton({required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF8FA67A).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF8FA67A)),
          ),
          child: const Text('restore',
              style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF8FA67A),
                  fontWeight: FontWeight.w600)),
        ),
      );
}