import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/models/user_model.dart';
import '../providers/profile_provider.dart';

class ProfileInfoEditor extends ConsumerStatefulWidget {
  final UserModel profile;

  const ProfileInfoEditor({
    super.key,
    required this.profile,
  });

  @override
  ConsumerState<ProfileInfoEditor> createState() => _ProfileInfoEditorState();
}

class _ProfileInfoEditorState extends ConsumerState<ProfileInfoEditor> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  
  bool _isEditing = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _initializeControllers() {
    _firstNameController.text = widget.profile.firstName ?? '';
    _lastNameController.text = widget.profile.lastName ?? '';
    _emailController.text = widget.profile.email ?? '';
    
    // Add listeners to detect changes
    _firstNameController.addListener(_onFieldChanged);
    _lastNameController.addListener(_onFieldChanged);
    _emailController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    final hasChanges = _firstNameController.text != (widget.profile.firstName ?? '') ||
        _lastNameController.text != (widget.profile.lastName ?? '') ||
        _emailController.text != (widget.profile.email ?? '');
    
    if (hasChanges != _hasChanges) {
      setState(() {
        _hasChanges = hasChanges;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Personal Information',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (!_isEditing)
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      setState(() {
                        _isEditing = true;
                      });
                    },
                  ),
              ],
            ),
            
            const SizedBox(height: AppConstants.defaultPadding),
            
            // Form
            Form(
              key: _formKey,
              child: Column(
                children: [
                  // First Name
                  TextFormField(
                    controller: _firstNameController,
                    decoration: const InputDecoration(
                      labelText: 'First Name',
                      border: OutlineInputBorder(),
                    ),
                    enabled: _isEditing,
                    validator: (value) {
                      if (value != null && value.length > 50) {
                        return 'First name must be 50 characters or less';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: AppConstants.defaultPadding),
                  
                  // Last Name
                  TextFormField(
                    controller: _lastNameController,
                    decoration: const InputDecoration(
                      labelText: 'Last Name',
                      border: OutlineInputBorder(),
                    ),
                    enabled: _isEditing,
                    validator: (value) {
                      if (value != null && value.length > 50) {
                        return 'Last name must be 50 characters or less';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: AppConstants.defaultPadding),
                  
                  // Email
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    enabled: _isEditing,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                        if (!emailRegex.hasMatch(value)) {
                          return 'Please enter a valid email address';
                        }
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: AppConstants.defaultPadding),
                  
                  // Error Message
                  if (profileState.updateError != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppConstants.smallPadding),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      child: Text(
                        profileState.updateError!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  
                  if (profileState.updateError != null)
                    const SizedBox(height: AppConstants.defaultPadding),
                  
                  // Action Buttons
                  if (_isEditing)
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: profileState.isUpdating ? null : _cancelEdit,
                            child: const Text('Cancel'),
                          ),
                        ),
                        
                        const SizedBox(width: AppConstants.defaultPadding),
                        
                        Expanded(
                          child: ElevatedButton(
                            onPressed: profileState.isUpdating || !_hasChanges 
                                ? null 
                                : _saveChanges,
                            child: profileState.isUpdating
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Save Changes'),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
      _hasChanges = false;
    });
    
    // Reset controllers to original values
    _firstNameController.text = widget.profile.firstName ?? '';
    _lastNameController.text = widget.profile.lastName ?? '';
    _emailController.text = widget.profile.email ?? '';
    
    // Clear any errors
    ref.read(profileProvider.notifier).clearErrors();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final updates = <String, dynamic>{};
    
    if (_firstNameController.text != (widget.profile.firstName ?? '')) {
      updates['first_name'] = _firstNameController.text.trim().isEmpty 
          ? null 
          : _firstNameController.text.trim();
    }
    
    if (_lastNameController.text != (widget.profile.lastName ?? '')) {
      updates['last_name'] = _lastNameController.text.trim().isEmpty 
          ? null 
          : _lastNameController.text.trim();
    }
    
    if (_emailController.text != (widget.profile.email ?? '')) {
      updates['email'] = _emailController.text.trim().isEmpty 
          ? null 
          : _emailController.text.trim();
    }

    if (updates.isEmpty) {
      setState(() {
        _isEditing = false;
        _hasChanges = false;
      });
      return;
    }

    final success = await ref.read(profileProvider.notifier).updateProfile(updates);
    
    if (success) {
      setState(() {
        _isEditing = false;
        _hasChanges = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }
}
