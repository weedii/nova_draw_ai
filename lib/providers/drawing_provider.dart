import 'package:flutter/foundation.dart';
import '../core/constants/drawing_data.dart';
import '../services/api_service.dart';

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
  void selectDrawing(String categoryId, String drawingId) async {
    _selectedCategoryId = categoryId;
    _selectedDrawingId = drawingId;
    _currentStepIndex = 0;

    // Get the drawing to find its subject for API call
    final drawing = getDrawingById(categoryId, drawingId);
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

  // Load steps from API
  Future<void> loadStepsFromApi(String subject) async {
    _stepsState = DrawingStepsState.loading;
    _error = null;
    _currentSubject = subject;
    _currentStepIndex = 0; // Reset step index
    notifyListeners();

    try {
      // Make API call to generate tutorial
      final apiResponse = await ApiService.generateTutorial(subject);

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

  // Use static data as fallback when API fails
  void useStaticDataFallback() {
    if (_selectedCategoryId != null && _selectedDrawingId != null) {
      _loadStaticSteps(_selectedCategoryId!, _selectedDrawingId!);
      notifyListeners();
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
