import 'package:flutter/foundation.dart';
import '../core/constants/drawing_data.dart';
// import '../models/api_models.dart'; // Will be used when API is implemented

enum DrawingStepsState { initial, loading, loaded, error }

class DrawingProvider extends ChangeNotifier {
  // Static data (current implementation)
  final List<DrawingCategory> _categories = DrawingData.categories;

  // Dynamic drawing steps (future API implementation)
  DrawingStepsState _stepsState = DrawingStepsState.initial;
  List<DrawingStep> _currentSteps = [];
  String? _error;
  String? _currentSubject;

  // Current selection state
  String? _selectedCategoryId;
  String? _selectedDrawingId;
  int _currentStepIndex = 0;

  // Getters for static data
  List<DrawingCategory> get categories => _categories;

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

  // Get category by ID
  DrawingCategory? getCategoryById(String categoryId) {
    try {
      return _categories.firstWhere((category) => category.id == categoryId);
    } catch (e) {
      return null;
    }
  }

  // Get drawing by category and drawing ID
  Drawing? getDrawingById(String categoryId, String drawingId) {
    final category = getCategoryById(categoryId);
    if (category == null) return null;

    try {
      return category.drawings.firstWhere((drawing) => drawing.id == drawingId);
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
  void selectDrawing(String categoryId, String drawingId) {
    _selectedCategoryId = categoryId;
    _selectedDrawingId = drawingId;
    _currentStepIndex = 0;

    // For now, load steps from static data
    _loadStaticSteps(categoryId, drawingId);
    notifyListeners();
  }

  // Load steps from static data (current implementation)
  void _loadStaticSteps(String categoryId, String drawingId) {
    final drawing = getDrawingById(categoryId, drawingId);
    if (drawing != null) {
      _stepsState = DrawingStepsState.loaded;
      _currentSteps = drawing.steps;
      _currentSubject = drawing.id;
      _error = null;
    } else {
      _stepsState = DrawingStepsState.error;
      _error = 'Drawing not found';
      _currentSteps = [];
    }
  }

  // Future: Load steps from API
  Future<void> loadStepsFromApi(String subject) async {
    _stepsState = DrawingStepsState.loading;
    _error = null;
    _currentSubject = subject;
    notifyListeners();

    try {
      // TODO: Implement API call
      // final response = await ApiService.getDrawingSteps(subject);
      // final apiResponse = ApiDrawingStepResponse.fromJson(response);
      //
      // if (apiResponse.success) {
      //   _currentSteps = apiResponse.steps.map((apiStep) => DrawingStep(
      //     stepEn: apiStep.stepEn,
      //     stepDe: apiStep.stepDe,
      //     stepImg: apiStep.stepImg,
      //   )).toList();
      //   _stepsState = DrawingStepsState.loaded;
      // } else {
      //   throw Exception('API returned success: false');
      // }

      // For now, simulate API delay and use static data
      await Future.delayed(const Duration(milliseconds: 500));

      // Find the drawing in static data for simulation
      if (_selectedCategoryId != null && _selectedDrawingId != null) {
        _loadStaticSteps(_selectedCategoryId!, _selectedDrawingId!);
      } else {
        throw Exception('No drawing selected');
      }
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
