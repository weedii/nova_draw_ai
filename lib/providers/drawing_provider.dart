import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/ui_models.dart';
import '../services/actions/drawing_api_service.dart';
import '../services/actions/api_exceptions.dart';

enum DrawingStepsState { initial, loading, loaded, error }

enum CategoriesState { initial, loading, loaded, error, empty }

class DrawingProvider extends ChangeNotifier {
  // Categories loaded from API
  List<DrawingCategory> _categories = [];
  CategoriesState _categoriesState = CategoriesState.initial;
  String? _categoriesError;

  // Dynamic drawing steps
  DrawingStepsState _stepsState = DrawingStepsState.initial;
  List<DrawingStep> _currentSteps = [];
  String? _error;
  String? _currentSubject;

  // Current selection state
  String? _selectedCategoryId;
  String? _selectedDrawingId;
  int _currentStepIndex = 0;

  // Getters for categories
  List<DrawingCategory> get categories => _categories;
  CategoriesState get categoriesState => _categoriesState;
  String? get categoriesError => _categoriesError;
  bool get isLoadingCategories => _categoriesState == CategoriesState.loading;
  bool get hasCategories => _categories.isNotEmpty;

  // Getters for dynamic steps
  DrawingStepsState get stepsState => _stepsState;
  List<DrawingStep> get currentSteps => _currentSteps;
  String? get error => _error;
  String? get currentSubject => _currentSubject;
  bool get isLoadingSteps => _stepsState == DrawingStepsState.loading;
  bool get hasSteps => _currentSteps.isNotEmpty;

  // Getters for current selection
  String? get selectedCategoryId => _selectedCategoryId;
  String? get selectedDrawingId => _selectedDrawingId;
  int get currentStepIndex => _currentStepIndex;
  bool get hasNextStep => _currentStepIndex < _currentSteps.length - 1;
  bool get hasPreviousStep => _currentStepIndex > 0;

  // Get category by title (since we removed IDs)
  DrawingCategory? getCategoryByTitle(String categoryTitle) {
    try {
      return _categories.firstWhere(
        (category) =>
            category.titleEn.toLowerCase() == categoryTitle.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  // Get drawing by category title and drawing name
  Drawing? getDrawingByName(String categoryTitle, String drawingName) {
    final category = getCategoryByTitle(categoryTitle);
    if (category == null) return null;

    try {
      return category.drawings.firstWhere(
        (drawing) => drawing.nameEn.toLowerCase() == drawingName.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  // Select category
  void selectCategory(String categoryId) {
    _selectedCategoryId = categoryId;
    _selectedDrawingId = null;
    _clearSteps();
    notifyListeners();
  }

  // Select drawing
  void selectDrawing(String categoryTitle, String drawingName) async {
    _selectedCategoryId = categoryTitle;
    _selectedDrawingId = drawingName;
    _currentStepIndex = 0;

    // Get the drawing to find its subject for API call
    final drawing = getDrawingByName(categoryTitle, drawingName);
    if (drawing != null) {
      // Use the drawing's English name as the subject for API
      final subject = drawing.nameEn;
      await loadStepsFromApi(subject);
    } else {
      _stepsState = DrawingStepsState.error;
      _error = 'Drawing not found';
      _currentSteps = [];
      notifyListeners();
    }
  }

  // Load categories with drawings from API
  Future<void> loadCategoriesWithDrawingsFromApi() async {
    _categoriesState = CategoriesState.loading;
    _categoriesError = null;
    notifyListeners();

    try {
      // Fetch categories from API
      final apiCategories = await DrawingApiService.getCategoriesWithDrawings();

      if (apiCategories.isEmpty) {
        _categoriesState = CategoriesState.empty;
        _categories = [];
        _categoriesError = null;
      } else {
        // Convert API categories to UI categories
        _categories = apiCategories.map((apiCategory) {
          // Convert color from hex string to Flutter Color
          final colorValue =
              int.tryParse(apiCategory.color.replaceFirst('#', '0xFF')) ??
              0xFFFF6B6B;
          final categoryColor = Color(colorValue);

          // Convert API drawings to UI drawings
          final drawings = apiCategory.drawings
              .map(
                (apiDrawing) => Drawing(
                  nameEn: apiDrawing.nameEn,
                  nameDe: apiDrawing.nameDe,
                  emoji: apiDrawing.emoji,
                  totalSteps: apiDrawing.totalSteps,
                  thumbnailUrl: apiDrawing.thumbnailUrl,
                ),
              )
              .toList();

          return DrawingCategory(
            titleEn: apiCategory.titleEn,
            titleDe: apiCategory.titleDe,
            descriptionEn: apiCategory.descriptionEn,
            descriptionDe: apiCategory.descriptionDe,
            icon: apiCategory.emoji,
            color: categoryColor,
            drawings: drawings,
          );
        }).toList();

        _categoriesState = CategoriesState.loaded;
        _categoriesError = null;
      }
    } on ApiException catch (e) {
      _categoriesState = CategoriesState.error;
      _categoriesError = e.message;
      _categories = [];
    } catch (e) {
      _categoriesState = CategoriesState.error;
      _categoriesError = 'Failed to load categories: ${e.toString()}';
      _categories = [];
    }

    notifyListeners();
  }

  // Retry loading categories
  Future<void> retryLoadCategories() async {
    await loadCategoriesWithDrawingsFromApi();
  }

  // Load steps from API
  Future<void> loadStepsFromApi(String subject) async {
    _stepsState = DrawingStepsState.loading;
    _error = null;
    _currentSubject = subject;
    _currentStepIndex = 0; // Reset step index
    notifyListeners();

    try {
      // Make API call to generate tutorial
      final apiResponse = await DrawingApiService.generateTutorial(subject);

      if (apiResponse.success) {
        // Convert API steps to local DrawingStep format
        _currentSteps = apiResponse.steps
            .map(
              (apiStep) => DrawingStep(
                stepEn: apiStep.stepEn,
                stepDe: apiStep.stepDe,
                stepImg: apiStep.stepImg,
              ),
            )
            .toList();

        _stepsState = DrawingStepsState.loaded;
        _error = null;
      } else {
        throw Exception('API returned success: false');
      }
    } on ApiException catch (e) {
      _stepsState = DrawingStepsState.error;
      _error = e.message;
      _currentSteps = [];
    } catch (e) {
      _stepsState = DrawingStepsState.error;
      _error = 'Failed to load drawing steps: ${e.toString()}';
      _currentSteps = [];
    }

    notifyListeners();
  }

  // Navigation methods
  void nextStep() {
    if (hasNextStep) {
      _currentStepIndex++;
      notifyListeners();
    }
  }

  void previousStep() {
    if (hasPreviousStep) {
      _currentStepIndex--;
      notifyListeners();
    }
  }

  void goToStep(int stepIndex) {
    if (stepIndex >= 0 && stepIndex < _currentSteps.length) {
      _currentStepIndex = stepIndex;
      notifyListeners();
    }
  }

  void resetSteps() {
    _currentStepIndex = 0;
    notifyListeners();
  }

  // Clear steps
  void _clearSteps() {
    _stepsState = DrawingStepsState.initial;
    _currentSteps = [];
    _error = null;
    _currentSubject = null;
    _currentStepIndex = 0;
  }

  // Clear all state
  void clearAll() {
    _selectedCategoryId = null;
    _selectedDrawingId = null;
    _clearSteps();
    notifyListeners();
  }

  // Retry loading steps from API
  Future<void> retryLoadSteps() async {
    if (_currentSubject != null) {
      await loadStepsFromApi(_currentSubject!);
    }
  }

  // Get current step
  DrawingStep? get currentStep {
    if (_currentSteps.isEmpty || _currentStepIndex >= _currentSteps.length) {
      return null;
    }
    return _currentSteps[_currentStepIndex];
  }

  // Get step progress
  double get stepProgress {
    if (_currentSteps.isEmpty) return 0.0;
    return (_currentStepIndex + 1) / _currentSteps.length;
  }
}
