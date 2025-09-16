import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';
import '../../core/constants/app_constants.dart';
import 'loading_widget.dart';

/// Enhanced image viewer with zoom, pan, rotation, and reset functionality
class EnhancedImageViewer extends StatefulWidget {
  final String imageUrl;
  final String? heroTag;
  final String? title;
  final bool showControls;
  final bool enableRotation;
  final bool enableFullscreen;
  final VoidCallback? onClose;
  final double minScale;
  final double maxScale;
  final double initialScale;

  const EnhancedImageViewer({
    super.key,
    required this.imageUrl,
    this.heroTag,
    this.title,
    this.showControls = true,
    this.enableRotation = true,
    this.enableFullscreen = true,
    this.onClose,
    this.minScale = 0.5,
    this.maxScale = 4.0,
    this.initialScale = 1.0,
  });

  @override
  State<EnhancedImageViewer> createState() => _EnhancedImageViewerState();
}

class _EnhancedImageViewerState extends State<EnhancedImageViewer>
    with TickerProviderStateMixin {
  late PhotoViewController _photoViewController;
  late AnimationController _controlsAnimationController;
  late Animation<double> _controlsAnimation;

  double _currentScale = 1.0;
  double _currentRotation = 0.0;
  bool _controlsVisible = true;

  @override
  void initState() {
    super.initState();
    _photoViewController = PhotoViewController();
    _currentScale = widget.initialScale;

    _controlsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _controlsAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controlsAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _controlsAnimationController.forward();
  }

  @override
  void dispose() {
    _photoViewController.dispose();
    _controlsAnimationController.dispose();
    super.dispose();
  }

  void _toggleControls() {
    setState(() {
      _controlsVisible = !_controlsVisible;
    });

    if (_controlsVisible) {
      _controlsAnimationController.forward();
    } else {
      _controlsAnimationController.reverse();
    }
  }

  void _zoomIn() {
    final newScale = (_currentScale * 1.5).clamp(
      widget.minScale,
      widget.maxScale,
    );
    _photoViewController.scale = newScale;
    setState(() {
      _currentScale = newScale;
    });
  }

  void _zoomOut() {
    final newScale = (_currentScale / 1.5).clamp(
      widget.minScale,
      widget.maxScale,
    );
    _photoViewController.scale = newScale;
    setState(() {
      _currentScale = newScale;
    });
  }

  void _resetView() {
    _photoViewController.reset();
    setState(() {
      _currentScale = widget.initialScale;
      _currentRotation = 0.0;
    });
  }

  void _rotateImage() {
    if (!widget.enableRotation) return;

    final newRotation = (_currentRotation + 90) % 360;
    _photoViewController.rotation =
        newRotation * (3.14159 / 180); // Convert to radians
    setState(() {
      _currentRotation = newRotation;
    });
  }

  void _openFullscreen() {
    if (!widget.enableFullscreen) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullscreenImageViewer(
          imageUrl: widget.imageUrl,
          title: widget.title,
          heroTag: widget.heroTag,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Debug image URL
    debugPrint('🖼️ IMAGE DEBUG: Loading image URL: ${widget.imageUrl}');

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: Stack(
        children: [
          // Main image viewer
          ClipRRect(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            child: PhotoView.customChild(
              controller: _photoViewController,
              minScale: widget.minScale,
              maxScale: widget.maxScale,
              initialScale: PhotoViewComputedScale.contained,
              heroAttributes: widget.heroTag != null
                  ? PhotoViewHeroAttributes(tag: widget.heroTag!)
                  : null,
              onTapUp: (context, details, controllerValue) {
                _toggleControls();
              },
              onScaleEnd: (context, details, controllerValue) {
                setState(() {
                  _currentScale = controllerValue.scale ?? widget.initialScale;
                });
              },
              child: _SmartNetworkImage(
                imageUrl: widget.imageUrl,
                fit: BoxFit.contain,
                colorScheme: colorScheme,
                theme: theme,
              ),
            ),
          ),

          // Control buttons overlay
          if (widget.showControls)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _controlsAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _controlsAnimation.value,
                    child: _buildControlsOverlay(colorScheme),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildControlsOverlay(ColorScheme colorScheme) {
    return Stack(
      children: [
        // Top controls
        Positioned(
          top: 8,
          left: 8,
          right: 8,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Title
              if (widget.title != null)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.title!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),

              const SizedBox(width: 8),

              // Fullscreen button
              if (widget.enableFullscreen)
                _buildControlButton(
                  icon: Icons.fullscreen,
                  onPressed: _openFullscreen,
                  tooltip: 'Fullscreen',
                ),
            ],
          ),
        ),

        // Bottom controls
        Positioned(
          bottom: 8,
          left: 8,
          right: 8,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildControlButton(
                icon: Icons.zoom_out,
                onPressed: _currentScale > widget.minScale ? _zoomOut : null,
                tooltip: 'Zoom Out',
              ),
              _buildControlButton(
                icon: Icons.zoom_in,
                onPressed: _currentScale < widget.maxScale ? _zoomIn : null,
                tooltip: 'Zoom In',
              ),
              if (widget.enableRotation)
                _buildControlButton(
                  icon: Icons.rotate_right,
                  onPressed: _rotateImage,
                  tooltip: 'Rotate',
                ),
              _buildControlButton(
                icon: Icons.refresh,
                onPressed: _resetView,
                tooltip: 'Reset View',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required String tooltip,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 20),
        onPressed: onPressed,
        tooltip: tooltip,
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      ),
    );
  }
}

/// Fullscreen image viewer for immersive viewing experience
class FullscreenImageViewer extends StatefulWidget {
  final String imageUrl;
  final String? title;
  final String? heroTag;

  const FullscreenImageViewer({
    super.key,
    required this.imageUrl,
    this.title,
    this.heroTag,
  });

  @override
  State<FullscreenImageViewer> createState() => _FullscreenImageViewerState();
}

class _FullscreenImageViewerState extends State<FullscreenImageViewer>
    with TickerProviderStateMixin {
  late PhotoViewController _photoViewController;
  late AnimationController _controlsAnimationController;
  late Animation<double> _controlsAnimation;

  double _currentScale = 1.0;
  double _currentRotation = 0.0;
  bool _controlsVisible = true;

  @override
  void initState() {
    super.initState();
    _photoViewController = PhotoViewController();

    _controlsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _controlsAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controlsAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _controlsAnimationController.forward();
  }

  @override
  void dispose() {
    _photoViewController.dispose();
    _controlsAnimationController.dispose();
    super.dispose();
  }

  void _toggleControls() {
    setState(() {
      _controlsVisible = !_controlsVisible;
    });

    if (_controlsVisible) {
      _controlsAnimationController.forward();
    } else {
      _controlsAnimationController.reverse();
    }
  }

  void _zoomIn() {
    final newScale = (_currentScale * 1.5).clamp(0.5, 4.0);
    _photoViewController.scale = newScale;
    setState(() {
      _currentScale = newScale;
    });
  }

  void _zoomOut() {
    final newScale = (_currentScale / 1.5).clamp(0.5, 4.0);
    _photoViewController.scale = newScale;
    setState(() {
      _currentScale = newScale;
    });
  }

  void _resetView() {
    _photoViewController.reset();
    setState(() {
      _currentScale = 1.0;
      _currentRotation = 0.0;
    });
  }

  void _rotateImage() {
    final newRotation = (_currentRotation + 90) % 360;
    _photoViewController.rotation = newRotation * (3.14159 / 180);
    setState(() {
      _currentRotation = newRotation;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Main image viewer
          PhotoView.customChild(
            controller: _photoViewController,
            minScale: 0.5,
            maxScale: 4.0,
            initialScale: PhotoViewComputedScale.contained,
            heroAttributes: widget.heroTag != null
                ? PhotoViewHeroAttributes(tag: widget.heroTag!)
                : null,
            onTapUp: (context, details, controllerValue) {
              _toggleControls();
            },
            onScaleEnd: (context, details, controllerValue) {
              setState(() {
                _currentScale = controllerValue.scale ?? 1.0;
              });
            },
            child: _SmartNetworkImageFullscreen(
              imageUrl: widget.imageUrl,
              fit: BoxFit.contain,
            ),
          ),

          // Controls overlay
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controlsAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _controlsAnimation.value,
                  child: _buildFullscreenControls(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullscreenControls() {
    return Stack(
      children: [
        // Top bar with close button and title
        Positioned(
          top: MediaQuery.of(context).padding.top,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.7),
                  Colors.transparent,
                ],
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Close',
                ),
                if (widget.title != null) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.title!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        // Bottom controls
        Positioned(
          bottom: MediaQuery.of(context).padding.bottom + 16,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildFullscreenControlButton(
                  icon: Icons.zoom_out,
                  onPressed: _currentScale > 0.5 ? _zoomOut : null,
                  tooltip: 'Zoom Out',
                ),
                _buildFullscreenControlButton(
                  icon: Icons.zoom_in,
                  onPressed: _currentScale < 4.0 ? _zoomIn : null,
                  tooltip: 'Zoom In',
                ),
                _buildFullscreenControlButton(
                  icon: Icons.rotate_right,
                  onPressed: _rotateImage,
                  tooltip: 'Rotate',
                ),
                _buildFullscreenControlButton(
                  icon: Icons.refresh,
                  onPressed: _resetView,
                  tooltip: 'Reset View',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFullscreenControlButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required String tooltip,
  }) {
    return IconButton(
      icon: Icon(icon, color: Colors.white, size: 24),
      onPressed: onPressed,
      tooltip: tooltip,
      padding: const EdgeInsets.all(12),
    );
  }
}

/// Enhanced image viewer for local files with zoom, pan, rotation, and reset functionality
class EnhancedLocalImageViewer extends StatefulWidget {
  final File imageFile;
  final String? heroTag;
  final String? title;
  final bool showControls;
  final bool enableRotation;
  final bool enableFullscreen;
  final VoidCallback? onClose;
  final double minScale;
  final double maxScale;
  final double initialScale;

  const EnhancedLocalImageViewer({
    super.key,
    required this.imageFile,
    this.heroTag,
    this.title,
    this.showControls = true,
    this.enableRotation = true,
    this.enableFullscreen = true,
    this.onClose,
    this.minScale = 0.5,
    this.maxScale = 4.0,
    this.initialScale = 1.0,
  });

  @override
  State<EnhancedLocalImageViewer> createState() =>
      _EnhancedLocalImageViewerState();
}

class _EnhancedLocalImageViewerState extends State<EnhancedLocalImageViewer>
    with TickerProviderStateMixin {
  late PhotoViewController _photoViewController;
  late AnimationController _controlsAnimationController;
  late Animation<double> _controlsAnimation;

  double _currentScale = 1.0;
  double _currentRotation = 0.0;
  bool _controlsVisible = true;

  @override
  void initState() {
    super.initState();
    _photoViewController = PhotoViewController();
    _currentScale = widget.initialScale;

    _controlsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _controlsAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controlsAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _controlsAnimationController.forward();
  }

  @override
  void dispose() {
    _photoViewController.dispose();
    _controlsAnimationController.dispose();
    super.dispose();
  }

  void _toggleControls() {
    setState(() {
      _controlsVisible = !_controlsVisible;
    });

    if (_controlsVisible) {
      _controlsAnimationController.forward();
    } else {
      _controlsAnimationController.reverse();
    }
  }

  void _zoomIn() {
    final newScale = (_currentScale * 1.5).clamp(
      widget.minScale,
      widget.maxScale,
    );
    _photoViewController.scale = newScale;
    setState(() {
      _currentScale = newScale;
    });
  }

  void _zoomOut() {
    final newScale = (_currentScale / 1.5).clamp(
      widget.minScale,
      widget.maxScale,
    );
    _photoViewController.scale = newScale;
    setState(() {
      _currentScale = newScale;
    });
  }

  void _resetView() {
    _photoViewController.reset();
    setState(() {
      _currentScale = widget.initialScale;
      _currentRotation = 0.0;
    });
  }

  void _rotateImage() {
    if (!widget.enableRotation) return;

    final newRotation = (_currentRotation + 90) % 360;
    _photoViewController.rotation =
        newRotation * (3.14159 / 180); // Convert to radians
    setState(() {
      _currentRotation = newRotation;
    });
  }

  void _openFullscreen() {
    if (!widget.enableFullscreen) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullscreenLocalImageViewer(
          imageFile: widget.imageFile,
          title: widget.title,
          heroTag: widget.heroTag,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: Stack(
        children: [
          // Main image viewer
          ClipRRect(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            child: PhotoView.customChild(
              controller: _photoViewController,
              minScale: widget.minScale,
              maxScale: widget.maxScale,
              initialScale: PhotoViewComputedScale.contained,
              heroAttributes: widget.heroTag != null
                  ? PhotoViewHeroAttributes(tag: widget.heroTag!)
                  : null,
              onTapUp: (context, details, controllerValue) {
                _toggleControls();
              },
              onScaleEnd: (context, details, controllerValue) {
                setState(() {
                  _currentScale = controllerValue.scale ?? widget.initialScale;
                });
              },
              child: Image.file(
                widget.imageFile,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: colorScheme.surfaceContainerHighest,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.image_not_supported_outlined,
                        size: 48,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Image not available',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Controls overlay
          if (widget.showControls)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _controlsAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _controlsVisible ? _controlsAnimation.value : 0.0,
                    child: child,
                  );
                },
                child: Stack(
                  children: [
                    // Top controls
                    Positioned(
                      top: 8,
                      left: 8,
                      right: 8,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (widget.title != null)
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  widget.title!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          const SizedBox(width: 8),
                          if (widget.enableFullscreen)
                            _buildControlButton(
                              icon: Icons.fullscreen,
                              onPressed: _openFullscreen,
                              tooltip: 'Fullscreen',
                            ),
                          if (widget.onClose != null)
                            _buildControlButton(
                              icon: Icons.close,
                              onPressed: widget.onClose!,
                              tooltip: 'Close',
                            ),
                        ],
                      ),
                    ),

                    // Bottom controls
                    Positioned(
                      bottom: 8,
                      left: 8,
                      right: 8,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildControlButton(
                            icon: Icons.zoom_out,
                            onPressed: _currentScale > widget.minScale
                                ? _zoomOut
                                : null,
                            tooltip: 'Zoom Out',
                          ),
                          _buildControlButton(
                            icon: Icons.zoom_in,
                            onPressed: _currentScale < widget.maxScale
                                ? _zoomIn
                                : null,
                            tooltip: 'Zoom In',
                          ),
                          if (widget.enableRotation)
                            _buildControlButton(
                              icon: Icons.rotate_right,
                              onPressed: _rotateImage,
                              tooltip: 'Rotate',
                            ),
                          _buildControlButton(
                            icon: Icons.refresh,
                            onPressed: _resetView,
                            tooltip: 'Reset View',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required String tooltip,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(20),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white, size: 20),
        tooltip: tooltip,
        padding: const EdgeInsets.all(8),
      ),
    );
  }
}

/// Fullscreen image viewer for local files
class FullscreenLocalImageViewer extends StatefulWidget {
  final File imageFile;
  final String? title;
  final String? heroTag;

  const FullscreenLocalImageViewer({
    super.key,
    required this.imageFile,
    this.title,
    this.heroTag,
  });

  @override
  State<FullscreenLocalImageViewer> createState() =>
      _FullscreenLocalImageViewerState();
}

class _FullscreenLocalImageViewerState extends State<FullscreenLocalImageViewer>
    with TickerProviderStateMixin {
  late PhotoViewController _photoViewController;
  late AnimationController _controlsAnimationController;
  late Animation<double> _controlsAnimation;

  double _currentScale = 1.0;
  double _currentRotation = 0.0;
  bool _controlsVisible = true;

  @override
  void initState() {
    super.initState();
    _photoViewController = PhotoViewController();

    _controlsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _controlsAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controlsAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _controlsAnimationController.forward();
  }

  @override
  void dispose() {
    _photoViewController.dispose();
    _controlsAnimationController.dispose();
    super.dispose();
  }

  void _toggleControls() {
    setState(() {
      _controlsVisible = !_controlsVisible;
    });

    if (_controlsVisible) {
      _controlsAnimationController.forward();
    } else {
      _controlsAnimationController.reverse();
    }
  }

  void _zoomIn() {
    final newScale = (_currentScale * 1.5).clamp(0.5, 4.0);
    _photoViewController.scale = newScale;
    setState(() {
      _currentScale = newScale;
    });
  }

  void _zoomOut() {
    final newScale = (_currentScale / 1.5).clamp(0.5, 4.0);
    _photoViewController.scale = newScale;
    setState(() {
      _currentScale = newScale;
    });
  }

  void _resetView() {
    _photoViewController.reset();
    setState(() {
      _currentScale = 1.0;
      _currentRotation = 0.0;
    });
  }

  void _rotateImage() {
    final newRotation = (_currentRotation + 90) % 360;
    _photoViewController.rotation = newRotation * (3.14159 / 180);
    setState(() {
      _currentRotation = newRotation;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Main image viewer
          PhotoView.customChild(
            controller: _photoViewController,
            minScale: 0.5,
            maxScale: 4.0,
            initialScale: PhotoViewComputedScale.contained,
            heroAttributes: widget.heroTag != null
                ? PhotoViewHeroAttributes(tag: widget.heroTag!)
                : null,
            onTapUp: (context, details, controllerValue) {
              _toggleControls();
            },
            onScaleEnd: (context, details, controllerValue) {
              setState(() {
                _currentScale = controllerValue.scale ?? 1.0;
              });
            },
            child: Image.file(
              widget.imageFile,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.image_not_supported_outlined,
                      size: 48,
                      color: Colors.white54,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Image not available',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Controls overlay
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controlsAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _controlsVisible ? _controlsAnimation.value : 0.0,
                  child: child,
                );
              },
              child: Stack(
                children: [
                  // Top controls
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 8,
                    left: 8,
                    right: 8,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (widget.title != null)
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child: Text(
                                widget.title!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        const SizedBox(width: 8),
                        _buildFullscreenControlButton(
                          icon: Icons.close,
                          onPressed: () => Navigator.of(context).pop(),
                          tooltip: 'Close',
                        ),
                      ],
                    ),
                  ),

                  // Bottom controls
                  Positioned(
                    bottom: MediaQuery.of(context).padding.bottom + 16,
                    left: 16,
                    right: 16,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildFullscreenControlButton(
                          icon: Icons.zoom_out,
                          onPressed: _currentScale > 0.5 ? _zoomOut : null,
                          tooltip: 'Zoom Out',
                        ),
                        _buildFullscreenControlButton(
                          icon: Icons.zoom_in,
                          onPressed: _currentScale < 4.0 ? _zoomIn : null,
                          tooltip: 'Zoom In',
                        ),
                        _buildFullscreenControlButton(
                          icon: Icons.rotate_right,
                          onPressed: _rotateImage,
                          tooltip: 'Rotate',
                        ),
                        _buildFullscreenControlButton(
                          icon: Icons.refresh,
                          onPressed: _resetView,
                          tooltip: 'Reset View',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullscreenControlButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required String tooltip,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(25),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white, size: 24),
        tooltip: tooltip,
        padding: const EdgeInsets.all(12),
      ),
    );
  }
}

/// Smart network image widget that tries CachedNetworkImage first and falls back to Image.network
/// This handles iOS 18.x beta compatibility issues with path_provider
class _SmartNetworkImage extends StatefulWidget {
  final String imageUrl;
  final BoxFit fit;
  final ColorScheme colorScheme;
  final ThemeData theme;

  const _SmartNetworkImage({
    required this.imageUrl,
    required this.fit,
    required this.colorScheme,
    required this.theme,
  });

  @override
  State<_SmartNetworkImage> createState() => _SmartNetworkImageState();
}

class _SmartNetworkImageState extends State<_SmartNetworkImage> {
  bool _useFallback = false;
  String? _error;
  Timer? _fallbackTimer;

  @override
  void initState() {
    super.initState();
    debugPrint('🖼️ SMART IMAGE: Attempting to load ${widget.imageUrl}');

    // Start a timer to automatically fallback if CachedNetworkImage takes too long
    // This handles cases where CachedNetworkImage fails silently due to path_provider issues
    _fallbackTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && !_useFallback && _error == null) {
        debugPrint(
          '🖼️ SMART IMAGE: Timeout reached, falling back to Image.network',
        );
        setState(() {
          _useFallback = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    super.dispose();
  }

  void _handleCachedImageError(Object error) {
    debugPrint('🖼️ SMART IMAGE: CachedNetworkImage failed with error: $error');
    debugPrint('🖼️ SMART IMAGE: Falling back to Image.network');
    _fallbackTimer?.cancel();

    if (mounted) {
      setState(() {
        _useFallback = true;
        _error = null;
      });
    }
  }

  void _handleFallbackError(Object error, StackTrace? stackTrace) {
    debugPrint('🖼️ SMART IMAGE: Image.network also failed with error: $error');
    _fallbackTimer?.cancel();

    if (mounted) {
      setState(() {
        _error = error.toString();
      });
    }
  }

  void _handleImageLoaded() {
    debugPrint('🖼️ SMART IMAGE: Image loaded successfully');
    _fallbackTimer?.cancel();

    if (mounted) {
      setState(() {
        _error = null;
      });
    }
  }

  void _retry() {
    debugPrint('🖼️ SMART IMAGE: Retrying image load');
    _fallbackTimer?.cancel();

    if (mounted) {
      setState(() {
        _useFallback = false;
        _error = null;
      });

      // Clear cache if using cached image
      if (!_useFallback) {
        CachedNetworkImage.evictFromCache(widget.imageUrl);
      }

      // Restart the fallback timer
      _fallbackTimer = Timer(const Duration(seconds: 5), () {
        if (mounted && !_useFallback && _error == null) {
          debugPrint(
            '🖼️ SMART IMAGE: Timeout reached on retry, falling back to Image.network',
          );
          setState(() {
            _useFallback = true;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return _buildErrorWidget();
    }

    if (_useFallback) {
      return _buildFallbackImage();
    }

    return _buildCachedImage();
  }

  Widget _buildCachedImage() {
    return CachedNetworkImage(
      imageUrl: widget.imageUrl,
      fit: widget.fit,
      httpHeaders: const {
        'Cache-Control': 'max-age=3600',
        'User-Agent': 'Mataresit-Flutter-App/1.0',
      },
      fadeInDuration: const Duration(milliseconds: 300),
      fadeOutDuration: const Duration(milliseconds: 100),
      placeholder: (context, url) => Container(
        color: widget.colorScheme.surfaceContainerHighest,
        child: const Center(child: LoadingWidget()),
      ),
      errorWidget: (context, url, error) {
        // Trigger fallback on error
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _handleCachedImageError(error);
        });

        return Container(
          color: widget.colorScheme.surfaceContainerHighest,
          child: const Center(child: LoadingWidget()),
        );
      },
      imageBuilder: (context, imageProvider) {
        // Image loaded successfully
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _handleImageLoaded();
        });

        return Image(image: imageProvider, fit: widget.fit);
      },
    );
  }

  Widget _buildFallbackImage() {
    return Image.network(
      widget.imageUrl,
      fit: widget.fit,
      headers: const {
        'Cache-Control': 'max-age=3600',
        'User-Agent': 'Mataresit-Flutter-App/1.0',
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          // Image loaded successfully
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _handleImageLoaded();
          });
          return child;
        }

        return Container(
          color: widget.colorScheme.surfaceContainerHighest,
          child: const Center(child: LoadingWidget()),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _handleFallbackError(error, stackTrace);
        });

        return Container(
          color: widget.colorScheme.surfaceContainerHighest,
          child: const Center(child: LoadingWidget()),
        );
      },
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      color: widget.colorScheme.surfaceContainerHighest,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported_outlined,
            size: 48,
            color: widget.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 8),
          Text(
            'Image not available',
            style: widget.theme.textTheme.bodyMedium?.copyWith(
              color: widget.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _useFallback ? 'Network error' : 'Cache error',
            style: widget.theme.textTheme.bodySmall?.copyWith(
              color: widget.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _retry,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Retry'),
            style: TextButton.styleFrom(
              foregroundColor: widget.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Smart network image widget for fullscreen view with fallback support
class _SmartNetworkImageFullscreen extends StatefulWidget {
  final String imageUrl;
  final BoxFit fit;

  const _SmartNetworkImageFullscreen({
    required this.imageUrl,
    required this.fit,
  });

  @override
  State<_SmartNetworkImageFullscreen> createState() =>
      _SmartNetworkImageFullscreenState();
}

class _SmartNetworkImageFullscreenState
    extends State<_SmartNetworkImageFullscreen> {
  bool _useFallback = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    debugPrint(
      '🖼️ SMART IMAGE (Fullscreen): Attempting to load ${widget.imageUrl}',
    );
  }

  void _handleCachedImageError(Object error) {
    debugPrint(
      '🖼️ SMART IMAGE (Fullscreen): CachedNetworkImage failed with error: $error',
    );
    debugPrint('🖼️ SMART IMAGE (Fullscreen): Falling back to Image.network');

    if (mounted) {
      setState(() {
        _useFallback = true;
        _error = null;
      });
    }
  }

  void _handleFallbackError(Object error, StackTrace? stackTrace) {
    debugPrint(
      '🖼️ SMART IMAGE (Fullscreen): Image.network also failed with error: $error',
    );

    if (mounted) {
      setState(() {
        _error = error.toString();
      });
    }
  }

  void _retry() {
    debugPrint('🖼️ SMART IMAGE (Fullscreen): Retrying image load');

    if (mounted) {
      setState(() {
        _useFallback = false;
        _error = null;
      });

      // Clear cache if using cached image
      if (!_useFallback) {
        CachedNetworkImage.evictFromCache(widget.imageUrl);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return _buildErrorWidget();
    }

    if (_useFallback) {
      return _buildFallbackImage();
    }

    return _buildCachedImage();
  }

  Widget _buildCachedImage() {
    return CachedNetworkImage(
      imageUrl: widget.imageUrl,
      fit: widget.fit,
      httpHeaders: const {
        'Cache-Control': 'max-age=3600',
        'User-Agent': 'Mataresit-Flutter-App/1.0',
      },
      fadeInDuration: const Duration(milliseconds: 300),
      fadeOutDuration: const Duration(milliseconds: 100),
      placeholder: (context, url) => const Center(child: LoadingWidget()),
      errorWidget: (context, url, error) {
        // Trigger fallback on error
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _handleCachedImageError(error);
        });

        return const Center(child: LoadingWidget());
      },
    );
  }

  Widget _buildFallbackImage() {
    return Image.network(
      widget.imageUrl,
      fit: widget.fit,
      headers: const {
        'Cache-Control': 'max-age=3600',
        'User-Agent': 'Mataresit-Flutter-App/1.0',
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }

        return const Center(child: LoadingWidget());
      },
      errorBuilder: (context, error, stackTrace) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _handleFallbackError(error, stackTrace);
        });

        return const Center(child: LoadingWidget());
      },
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.image_not_supported_outlined,
            size: 64,
            color: Colors.white54,
          ),
          const SizedBox(height: 16),
          const Text(
            'Image not available',
            style: TextStyle(color: Colors.white54, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            _useFallback ? 'Network error' : 'Cache error',
            style: const TextStyle(color: Colors.white38, fontSize: 14),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: _retry,
            icon: const Icon(Icons.refresh, size: 16, color: Colors.white54),
            label: const Text('Retry', style: TextStyle(color: Colors.white54)),
            style: TextButton.styleFrom(foregroundColor: Colors.white54),
          ),
        ],
      ),
    );
  }
}
