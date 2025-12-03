import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/colors.dart';
import '../../models/api_models.dart';
import '../../services/actions/gallery_api_service.dart';
import '../animations/app_animations.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_loading_widget.dart';
import '../widgets/custom_button.dart';
import '../widgets/save_to_gallery_button.dart';
import '../widgets/app_dialog.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late ScrollController _scrollController;

  List<ApiGalleryDrawing> _drawings = [];
  bool _isLoading = true;
  bool _hasError = false;
  int _currentPage = 1;
  bool _isLoadingMore = false;
  bool _hasMoreDrawings = true;
  String? _selectedDrawingId;

  @override
  void initState() {
    super.initState();

    _fadeController = AppAnimations.createFadeController(vsync: this);
    _fadeAnimation = AppAnimations.createFadeAnimation(
      controller: _fadeController,
    );
    _fadeController.forward();

    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    _loadGallery();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 500) {
      if (!_isLoadingMore && _hasMoreDrawings) {
        _loadMoreDrawings();
      }
    }
  }

  Future<void> _loadGallery() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      final response = await GalleryApiService.fetchGallery(page: 1, limit: 20);

      setState(() {
        _drawings = response.data;
        _currentPage = 1;
        _hasMoreDrawings = response.data.length >= 20;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreDrawings() async {
    if (_isLoadingMore || !_hasMoreDrawings) return;

    try {
      setState(() => _isLoadingMore = true);

      final nextPage = _currentPage + 1;
      final response = await GalleryApiService.fetchGallery(
        page: nextPage,
        limit: 20,
      );

      setState(() {
        _drawings.addAll(response.data);
        _currentPage = nextPage;
        _hasMoreDrawings = response.data.length >= 20;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() => _isLoadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                // Header
                CustomAppBar(
                  title: 'gallery.my_gallery',
                  subtitle: 'gallery.your_creations',
                  emoji: '🖼️',
                  showBackButton: false,
                  showAnimation: true,
                  showSettingsButton: true,
                ),
                // Content
                Expanded(child: _buildContent()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return CustomLoadingWidget(
        message: 'gallery.loading_gallery',
        subtitle: 'common.please_wait',
        showBackButton: false,
      );
    }

    if (_hasError) {
      return _buildErrorState();
    }

    if (_drawings.isEmpty) {
      return _buildEmptyState();
    }

    return _buildGalleryGrid();
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.error_outline,
              size: 50,
              color: AppColors.error,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'gallery.error_loading_gallery'.tr(),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
              fontFamily: 'Comic Sans MS',
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'gallery.error_loading_message'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textDark.withValues(alpha: 0.7),
                fontFamily: 'Comic Sans MS',
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadGallery,
            icon: const Icon(Icons.refresh),
            label: Text('gallery.retry'.tr()),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withValues(alpha: 0.1),
                  AppColors.accent.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Icon(
              Icons.collections_outlined,
              size: 60,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'gallery.no_drawings_yet'.tr(),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
              fontFamily: 'Comic Sans MS',
            ),
          ),

          const SizedBox(height: 12),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'gallery.start_drawing_message'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textDark.withValues(alpha: 0.7),
                fontFamily: 'Comic Sans MS',
              ),
            ),
          ),

          const SizedBox(height: 32),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildDecorativeElement('🎨'),
              const SizedBox(width: 16),
              _buildDecorativeElement('✨'),
              const SizedBox(width: 16),
              _buildDecorativeElement('🌟'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGalleryGrid() {
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _drawings.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _drawings.length) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          );
        }

        final drawing = _drawings[index];
        return _buildGalleryItem(drawing);
      },
    );
  }

  Widget _buildGalleryItem(ApiGalleryDrawing drawing) {
    final hasEditedImages =
        drawing.editedImagesUrls != null &&
        drawing.editedImagesUrls!.isNotEmpty;
    final allImages = <String>[];

    // Add uploaded image first
    if (drawing.uploadedImageUrl != null) {
      allImages.add(drawing.uploadedImageUrl!);
    }

    // Add all edited images
    if (hasEditedImages) {
      allImages.addAll(drawing.editedImagesUrls!);
    }

    final isSelected = _selectedDrawingId == drawing.id;
    // Display the uploaded image (first one)
    final displayImageUrl = allImages.isNotEmpty ? allImages.first : null;

    return GestureDetector(
      onTap: () {
        // Show image viewer for any number of images
        _showImageViewer(drawing, allImages);
      },

      child: Card(
        elevation: isSelected ? 8 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: isSelected
              ? const BorderSide(color: AppColors.primary, width: 3)
              : BorderSide.none,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Main image (uploaded image first)
              if (displayImageUrl != null)
                Container(
                  color: AppColors.background,
                  child: Image.network(
                    displayImageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: AppColors.border,
                        child: const Icon(
                          Icons.image_not_supported,
                          color: AppColors.textDark,
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                              : null,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                        ),
                      );
                    },
                  ),
                ),

              // Gradient overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.6),
                      ],
                    ),
                  ),
                ),
              ),

              // Info at bottom
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Tutorial or title
                      if (drawing.tutorial != null)
                        Row(
                          children: [
                            Text(
                              drawing.tutorial!.categoryEmoji,
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    drawing.tutorial!.subjectEn,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.white,
                                      fontFamily: 'Comic Sans MS',
                                    ),
                                  ),
                                  Text(
                                    drawing.tutorial!.categoryEn,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: AppColors.white.withValues(
                                        alpha: 0.8,
                                      ),
                                      fontFamily: 'Comic Sans MS',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      else
                        Text(
                          _formatDate(drawing.createdAt),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.white,
                            fontFamily: 'Comic Sans MS',
                          ),
                        ),

                      const SizedBox(height: 6),

                      // Image count badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${allImages.length} ${allImages.length == 1 ? 'gallery.image'.tr() : 'gallery.images'.tr()}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.white,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Comic Sans MS',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Tap indicator for all images
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.touch_app,
                        size: 12,
                        color: AppColors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'gallery.view_all'.tr(),
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.white,
                          fontFamily: 'Comic Sans MS',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showImageViewer(ApiGalleryDrawing drawing, List<String> images) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildImageViewerModal(drawing, images),
    );
  }

  void _handleReEditImage(ApiGalleryDrawing drawing) {
    Navigator.pop(context);
    if (drawing.uploadedImageUrl != null && drawing.tutorial != null) {
      context.push(
        '/drawings/${drawing.tutorial!.categoryEn}/${drawing.tutorial!.subjectEn}/edit-options',
        extra: {
          'originalImageUrl': drawing.uploadedImageUrl,
          'dbDrawingId': drawing.id,
        },
      );
    }
  }

  void _navigateToStory(ApiGalleryDrawing drawing, String imageUrl) {
    // Navigate to story screen with image URL and drawing info
    if (drawing.tutorial != null) {
      context.push(
        '/drawings/${drawing.tutorial!.categoryEn}/${drawing.tutorial!.subjectEn}/story',
        extra: {
          'categoryId': drawing.tutorial!.categoryEn,
          'drawingId': drawing.tutorial!.subjectEn,
          'imageUrl': imageUrl,
          'dbDrawingId': drawing.id,
        },
      );
    }
  }

  Future<void> _deleteDrawingImage(
    ApiGalleryDrawing drawing,
    String imageUrl,
  ) async {
    // Check if this is the original/uploaded image
    final isOriginalImage = drawing.uploadedImageUrl == imageUrl;

    // Count total images
    final allImages = <String>[];
    if (drawing.uploadedImageUrl != null) {
      allImages.add(drawing.uploadedImageUrl!);
    }
    if (drawing.editedImagesUrls != null) {
      allImages.addAll(drawing.editedImagesUrls!);
    }

    final isSingleImage = allImages.length == 1;

    // Show appropriate confirmation dialog
    if (isOriginalImage) {
      // Deleting original image - show warning dialog
      AppDialog.showConfirmation(
        context,
        title: 'gallery.delete_original_image_title'.tr(),
        message: 'gallery.delete_original_image_message'.tr(),
        confirmText: 'gallery.delete'.tr(),
        cancelText: 'gallery.cancel'.tr(),
        onConfirmed: () => _performDeleteImage(drawing, imageUrl),
      );
    } else if (isSingleImage) {
      // Only one image and it's not the original - show warning dialog
      AppDialog.showConfirmation(
        context,
        title: 'gallery.delete_single_image_title'.tr(),
        message: 'gallery.delete_single_image_message'.tr(),
        confirmText: 'gallery.delete'.tr(),
        cancelText: 'gallery.cancel'.tr(),
        onConfirmed: () => _performDeleteImage(drawing, imageUrl),
      );
    } else {
      // Multiple images and not the original - show confirmation dialog
      AppDialog.showConfirmation(
        context,
        title: 'gallery.delete_edited_image_title'.tr(),
        message: 'gallery.delete_edited_image_message'.tr(),
        confirmText: 'gallery.delete'.tr(),
        cancelText: 'gallery.cancel'.tr(),
        onConfirmed: () => _performDeleteImage(drawing, imageUrl),
      );
    }
  }

  Future<void> _performDeleteImage(
    ApiGalleryDrawing drawing,
    String imageUrl,
  ) async {
    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('gallery.deleting_drawing'.tr()),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 2),
        ),
      );

      // Call the API to delete the image
      final success = await GalleryApiService.deleteDrawingImage(
        drawing.id,
        imageUrl,
      );

      if (success && mounted) {
        // Refresh the gallery to get updated drawing data
        await _loadGallery();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('gallery.delete_success'.tr()),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );

        // Close the image viewer modal
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('gallery.delete_error'.tr()),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Widget _buildImageViewerModal(
    ApiGalleryDrawing drawing,
    List<String> images,
  ) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (drawing.tutorial != null)
                            Text(
                              drawing.tutorial!.subjectEn,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                                fontFamily: 'Comic Sans MS',
                              ),
                            )
                          else
                            Text(
                              'gallery.original_image'.tr(),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                                fontFamily: 'Comic Sans MS',
                              ),
                            ),
                          const SizedBox(height: 4),
                          Text(
                            '${images.length} ${'gallery.image_count'.tr()}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textDark.withValues(alpha: 0.6),
                              fontFamily: 'Comic Sans MS',
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        color: AppColors.textDark,
                      ),
                    ],
                  ),

                  // Re-edit Button
                  if (drawing.tutorial != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: CustomButton(
                        label: 'gallery.re_edit',
                        onPressed: () => _handleReEditImage(drawing),
                        backgroundColor: AppColors.success,
                        textColor: AppColors.white,
                        icon: Icons.edit,
                        height: 50,
                        fontSize: 14,
                      ),
                    ),
                ],
              ),
            ),
            // Images list
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: images.length,
                itemBuilder: (context, index) {
                  final isOriginal = index == 0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Label
                        Text(
                          isOriginal
                              ? 'gallery.original_image'.tr()
                              : '${'gallery.edit_label'.tr()} ${index}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                            fontFamily: 'Comic Sans MS',
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Image with save button
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                color: AppColors.border,
                                child: Image.network(
                                  images[index],
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      height: 200,
                                      color: AppColors.border,
                                      child: const Icon(
                                        Icons.image_not_supported,
                                        color: AppColors.textDark,
                                      ),
                                    );
                                  },
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                        if (loadingProgress == null) {
                                          return child;
                                        }
                                        return SizedBox(
                                          height: 200,
                                          child: Center(
                                            child: CircularProgressIndicator(
                                              value:
                                                  loadingProgress
                                                          .expectedTotalBytes !=
                                                      null
                                                  ? loadingProgress
                                                            .cumulativeBytesLoaded /
                                                        loadingProgress
                                                            .expectedTotalBytes!
                                                  : null,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    AppColors.primary,
                                                  ),
                                            ),
                                          ),
                                        );
                                      },
                                ),
                              ),
                            ),

                            // Story button (top-right, only for edited images)
                            if (!isOriginal)
                              Positioned(
                                top: 12,
                                right: 12,
                                child: CustomButton(
                                  label: 'gallery.story',
                                  onPressed: () =>
                                      _navigateToStory(drawing, images[index]),
                                  backgroundColor: AppColors.secondary,
                                  textColor: AppColors.white,
                                  icon: Icons.book,
                                  fontSize: 12,
                                  iconSize: 16,
                                  borderRadius: 20,
                                  showShadow: true,
                                  padding: EdgeInsets.symmetric(horizontal: 20),
                                ),
                              ),

                            // Delete button (positioned at bottom-right, left of save button)
                            Positioned(
                              bottom: 16,
                              right: 60,
                              child: CustomButton(
                                label: 'gallery.delete_drawing',
                                onPressed: () =>
                                    _deleteDrawingImage(drawing, images[index]),
                                backgroundColor: AppColors.error,
                                textColor: AppColors.white,
                                icon: Icons.delete_outline,
                                fontSize: 12,
                                iconSize: 20,
                                borderRadius: 8,
                                showShadow: true,
                                iconOnly: true,
                              ),
                            ),

                            // Save button (floating at bottom-right)
                            // Note: SaveToGalleryButton returns Positioned internally when isFloating=true
                            SaveToGalleryButton(
                              imageUrl: images[index],
                              displayMode: SaveButtonDisplayMode.iconOnly,
                              backgroundColor: AppColors.success,
                              textColor: AppColors.white,
                              borderRadius: 12,
                              iconSize: 20,
                              isFloating: true,
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDecorativeElement(String emoji) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(child: Text(emoji, style: const TextStyle(fontSize: 28))),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }
}
