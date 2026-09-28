import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_colors.dart';

class CustomImagePickerTile extends StatefulWidget {
  final Uint8List? selectedImageBytes;
  final String? existingImageUrl;
  final ValueChanged<Uint8List?> onImagePicked;
  final String label;
  final IconData defaultIcon;

  const CustomImagePickerTile({
    super.key,
    this.selectedImageBytes,
    this.existingImageUrl,
    required this.onImagePicked,
    this.label = 'Add Photo',
    this.defaultIcon = Icons.camera_alt_outlined,
  });

  @override
  State<CustomImagePickerTile> createState() => _CustomImagePickerTileState();
}

class _CustomImagePickerTileState extends State<CustomImagePickerTile> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (file != null) {
        final bytes = await file.readAsBytes();
        widget.onImagePicked(bytes);
      }
    } catch (e) {
      debugPrint('[CustomImagePickerTile] Error picking image: $e');
    }
  }

  void _showPickerModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          decoration: BoxDecoration(
            color: AppColors.ofCardSurface(ctx),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderSubdued,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Select ${widget.label}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ofTextPrimary(ctx),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
                ),
                title: Text(
                  'Take Photo',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.ofTextPrimary(ctx),
                  ),
                ),
                subtitle: const Text(
                  'Use your device camera',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: AppColors.primary),
                ),
                title: Text(
                  'Choose from Gallery',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.ofTextPrimary(ctx),
                  ),
                ),
                subtitle: const Text(
                  'Select an image from photo library',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
              if (widget.selectedImageBytes != null ||
                  (widget.existingImageUrl != null && widget.existingImageUrl!.isNotEmpty)) ...[
                const SizedBox(height: 8),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  ),
                  title: const Text(
                    'Remove Image',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.redAccent,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    widget.onImagePicked(null);
                  },
                ),
              ],
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasMemoryImage = widget.selectedImageBytes != null;
    final hasUrlImage = widget.existingImageUrl != null && widget.existingImageUrl!.isNotEmpty;
    final hasImage = hasMemoryImage || hasUrlImage;

    return Row(
      children: [
        GestureDetector(
          onTap: () => _showPickerModal(context),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: AppColors.ofSurfaceSubdued(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: hasImage ? AppColors.primary : AppColors.ofBorderSubdued(context),
                    width: hasImage ? 1.8 : 1.0,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: hasMemoryImage
                      ? Image.memory(
                          widget.selectedImageBytes!,
                          fit: BoxFit.cover,
                        )
                      : hasUrlImage
                          ? (widget.existingImageUrl!.startsWith('http')
                              ? Image.network(
                                  widget.existingImageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => _buildPlaceholder(),
                                )
                              : Image.asset(
                                  widget.existingImageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => _buildPlaceholder(),
                                ))
                          : _buildPlaceholder(),
                ),
              ),

              // Camera overlay badge
              Positioned(
                bottom: -4,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.ofCardSurface(context), width: 2),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),

              // Clear ('X') button if image exists
              if (hasImage)
                Positioned(
                  top: -6,
                  right: -6,
                  child: GestureDetector(
                    onTap: () => widget.onImagePicked(null),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.black87,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ofTextPrimary(context),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                hasImage ? 'Photo attached' : 'Tap camera icon to pick from gallery or take a photo',
                style: TextStyle(
                  fontSize: 11,
                  color: hasImage ? AppColors.primary : AppColors.textMuted,
                  fontWeight: hasImage ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          widget.defaultIcon,
          size: 30,
          color: AppColors.primary,
        ),
        const SizedBox(height: 4),
        const Text(
          'Photo',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}
