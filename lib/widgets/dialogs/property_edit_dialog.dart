// File: lib/widgets/dialogs/property_edit_dialog.dart
// Purpose: Full responsive 3-step property creation and edit wizard for Super Admin panel.

import 'package:brokerflow_admin/app/context_ext.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/app_colors.dart';
import '../../app/app_text_styles.dart';
import '../../models/address_model.dart';
import '../../models/media_model.dart';
import '../../models/property_enums.dart';
import '../../models/property_model.dart';
import '../../modules/properties/widgets/property_preview_dialog.dart';
import '../../modules/properties/widgets/step_property_details_widget.dart';
import '../../modules/properties/widgets/step_property_location_widget.dart';
import '../../modules/properties/widgets/step_property_type_widget.dart';
import '../../providers/brokers/brokers_provider.dart';
import '../../providers/properties/admin_property_provider.dart';
import '../buttons/app_button.dart';
import '../toast/app_toast.dart';

class PropertyEditDialog extends StatefulWidget {
  final PropertyModel? property;
  final ValueChanged<PropertyModel>? onSave;

  const PropertyEditDialog({super.key, this.property, this.onSave});

  static Future<void> show(
    BuildContext context, {
    PropertyModel? property,
    ValueChanged<PropertyModel>? onSave,
  }) {
    // Pre-fetch brokers for the dropdown
    final brokersProv = Provider.of<BrokersProvider>(context, listen: false);
    if (brokersProv.brokers.isEmpty) {
      brokersProv.fetchBrokers();
    }

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PropertyEditDialog(property: property, onSave: onSave),
    );
  }

  @override
  State<PropertyEditDialog> createState() => _PropertyEditDialogState();
}

class _PropertyEditDialogState extends State<PropertyEditDialog> {
  final ScrollController _scrollController = ScrollController();
  int _currentStep = 0; // 0: Type, 1: Details & Specs, 2: Location & Broker

  // Step 1 State
  late PropertyType _propertyType;

  // Step 2 State
  late ListingType _listingType;
  late ConstructionStatus _constructionStatus;
  late AreaUnit _areaUnit;
  late FacingDirection? _facing;
  late FurnishingStatus _furnishingStatus;
  late int _bedrooms;
  late int _bathrooms;
  late int _balconies;
  late int _parking;
  late List<String> _selectedAmenities;
  late List<MediaModel> _medias;

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _areaController;
  late TextEditingController _floorNumberController;
  late TextEditingController _totalFloorsController;

  // Step 3 State
  late TextEditingController _fullAddressController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _countryController;
  late TextEditingController _pincodeController;
  late TextEditingController _landmarkController;
  String? _selectedBrokerId;

  @override
  void initState() {
    super.initState();
    final p = widget.property;
    final isEdit = p != null;

    _currentStep = isEdit ? 1 : 0;

    // Step 1
    _propertyType = p?.propertyType ?? PropertyType.apartment;

    // Step 2
    _listingType = p?.listingType ?? ListingType.sale;
    _constructionStatus = p?.constructionStatus ?? ConstructionStatus.readyToMove;
    _areaUnit = p?.areaUnit ?? AreaUnit.sqft;
    _facing = p?.facing ?? FacingDirection.east;
    _furnishingStatus = p?.furnishingStatus ?? FurnishingStatus.unfurnished;
    _bedrooms = p?.bedrooms ?? 2;
    _bathrooms = p?.bathrooms ?? 2;
    _balconies = p?.balconies ?? 1;
    _parking = p?.parking ?? 1;
    _selectedAmenities = List<String>.from(p?.amenities ?? []);
    _medias = List<MediaModel>.from(p?.medias ?? []);

    _titleController = TextEditingController(text: p?.propertyTitle ?? '');
    _descriptionController = TextEditingController(text: p?.propertyDescription ?? '');
    _priceController = TextEditingController(
      text: p?.price != null && p!.price > 0 ? p.price.toStringAsFixed(0) : '',
    );
    _areaController = TextEditingController(
      text: p?.area != null && p!.area > 0 ? p.area.toStringAsFixed(0) : '',
    );
    _floorNumberController = TextEditingController(text: p?.floorNumber?.toString() ?? '');
    _totalFloorsController = TextEditingController(text: p?.totalFloors?.toString() ?? '');

    // Step 3
    _fullAddressController = TextEditingController(text: p?.address?.fullAddress ?? '');
    _cityController = TextEditingController(text: p?.address?.city ?? 'Surat');
    _stateController = TextEditingController(text: p?.address?.state ?? 'Gujarat');
    _countryController = TextEditingController(text: p?.address?.country ?? 'India');
    _pincodeController = TextEditingController(text: p?.address?.pincode ?? '');
    _landmarkController = TextEditingController(text: p?.address?.landmark ?? '');
    _selectedBrokerId = p?.brokerId ?? p?.broker?.id;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _areaController.dispose();
    _floorNumberController.dispose();
    _totalFloorsController.dispose();
    _fullAddressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    _pincodeController.dispose();
    _landmarkController.dispose();
    super.dispose();
  }

  bool _validateCurrentStep() {
    if (_currentStep == 0) {
      if (_propertyType == PropertyType.unknown) {
        AppToast.showError('Please select a valid property category.');
        return false;
      }
    } else if (_currentStep == 1) {
      if (_titleController.text.trim().isEmpty) {
        AppToast.showError('Please enter a descriptive property title.');
        return false;
      }
      final price = double.tryParse(_priceController.text.trim());
      if (price == null || price <= 0) {
        AppToast.showError('Please enter a valid price amount.');
        return false;
      }
      final area = double.tryParse(_areaController.text.trim());
      if (area == null || area <= 0) {
        AppToast.showError('Please enter a valid property area size.');
        return false;
      }
    } else if (_currentStep == 2) {
      if (_selectedBrokerId == null || _selectedBrokerId!.isEmpty) {
        AppToast.showError('Please select a broker to associate with this property.');
        return false;
      }
      if (_fullAddressController.text.trim().isEmpty) {
        AppToast.showError('Please provide the street address.');
        return false;
      }
      if (_cityController.text.trim().isEmpty) {
        AppToast.showError('Please enter the city name.');
        return false;
      }
    }
    return true;
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(0.0, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    }
  }

  void _nextStep() {
    if (!_validateCurrentStep()) return;

    if (_currentStep < 2) {
      setState(() => _currentStep++);
      _scrollToTop();
    } else {
      _openPreviewDialog();
    }
  }

  void _previousStep() {
    final isEdit = widget.property != null;
    final minStep = isEdit ? 1 : 0;

    if (_currentStep > minStep) {
      setState(() => _currentStep--);
      _scrollToTop();
    } else {
      Navigator.of(context).pop();
    }
  }

  void _openPreviewDialog() {
    final isEdit = widget.property != null;
    final propertyProvider = Provider.of<AdminPropertyProvider>(context, listen: false);

    final property = PropertyModel(
      id: widget.property?.id,
      brokerId: _selectedBrokerId,
      propertyTitle: _titleController.text.trim(),
      propertyDescription: _descriptionController.text.trim(),
      propertyType: _propertyType,
      listingType: _listingType,
      price: double.tryParse(_priceController.text.trim()) ?? 0.0,
      area: double.tryParse(_areaController.text.trim()) ?? 0.0,
      areaUnit: _areaUnit,
      bedrooms: _bedrooms,
      bathrooms: _bathrooms,
      balconies: _balconies,
      parking: _parking,
      floorNumber: int.tryParse(_floorNumberController.text.trim()),
      totalFloors: int.tryParse(_totalFloorsController.text.trim()),
      furnishingStatus: _furnishingStatus,
      propertyStatus: widget.property?.propertyStatus ?? PropertyStatus.available,
      constructionStatus: _constructionStatus,
      facing: _facing,
      amenities: _selectedAmenities,
      medias: _medias,
      address: AddressModel(
        fullAddress: _fullAddressController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        country: _countryController.text.trim(),
        pincode: _pincodeController.text.trim(),
        landmark: _landmarkController.text.trim(),
        entityType: 'property',
        entityId: widget.property?.id,
      ),
    );

    PropertyPreviewDialog.show(
      context,
      property: property,
      isEdit: isEdit,
      propertyProvider: propertyProvider,
      onSuccess: (saved) {
        if (saved != null && widget.onSave != null) {
          widget.onSave!(saved);
        }
        Navigator.of(context).pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.property != null;

    final isMobile = context.isMobile;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      backgroundColor: AppColors.surface,
      constraints: BoxConstraints(
        maxWidth: isMobile ? double.infinity : MediaQuery.of(context).size.width * 0.70,
      ),
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12.0 : 32.0,
        vertical: isMobile ? 16.0 : 24.0,
      ),
      child: Column(
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Icon(
                    isEdit ? Icons.edit_location_alt_rounded : Icons.add_business_rounded,
                    color: AppColors.primary,
                    size: 22.0,
                  ),
                ),
                const SizedBox(width: 14.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEdit ? 'Edit Property Listing' : 'Add New Property Listing',
                        style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2.0),
                      Text(
                        _getStepSubtitle(),
                        style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Step Progress Indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
            color: AppColors.background,
            child: Row(
              children: [
                _buildStepIndicator(0, 'Category', Icons.apartment_rounded, isEdit),
                _buildStepConnector(0),
                _buildStepIndicator(1, 'Specs & Media', Icons.tune_rounded, isEdit),
                _buildStepConnector(1),
                _buildStepIndicator(2, 'Location & Broker', Icons.location_on_rounded, isEdit),
              ],
            ),
          ),

          // Main Step Content
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(24.0),
              child: _buildCurrentStepWidget(),
            ),
          ),

          // Footer Actions
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 14.0),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                if (_currentStep > (isEdit ? 1 : 0))
                  AppButton(title: 'common_back_tooltip'.tr(), isBorderOnly: true, onPressed: _previousStep)
                else
                  AppButton(
                    title: 'cancel'.tr(),
                    isBorderOnly: true,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                const Spacer(),
                AppButton(
                  title: _currentStep == 2
                      ? (isEdit ? 'property_btn_review_update'.tr() : 'property_btn_review_publish'.tr())
                      : 'property_btn_continue'.tr(),
                  icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18.0),
                  onPressed: _nextStep,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getStepSubtitle() {
    switch (_currentStep) {
      case 0:
        return 'Step 1 of 3: Choose property category and type';
      case 1:
        return 'Step 2 of 3: Enter dimensions, specifications, pricing & photos';
      case 2:
        return 'Step 3 of 3: Set exact location, address & broker assignment';
      default:
        return '';
    }
  }

  Widget _buildStepIndicator(int stepIndex, String label, IconData icon, bool isEdit) {
    final isActive = _currentStep == stepIndex;
    final isDone = _currentStep > stepIndex;

    Color color = AppColors.textSecondary;
    if (isActive) color = AppColors.primary;
    if (isDone) color = Colors.green;

    return Expanded(
      child: InkWell(
        onTap: (isDone || (isEdit && stepIndex >= 1))
            ? () {
                if (_validateCurrentStep()) {
                  setState(() => _currentStep = stepIndex);
                }
              }
            : null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6.0),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
                border: Border.all(color: color, width: isActive ? 1.5 : 1.0),
              ),
              child: Icon(isDone ? Icons.check_rounded : icon, color: color, size: 14.0),
            ),
            const SizedBox(width: 8.0),
            Flexible(
              child: Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                  color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepConnector(int stepIndex) {
    final isDone = _currentStep > stepIndex;
    return Container(
      width: 24.0,
      height: 1.5,
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      color: isDone ? Colors.green : AppColors.border,
    );
  }

  Widget _buildCurrentStepWidget() {
    switch (_currentStep) {
      case 0:
        return StepPropertyTypeWidget(
          selectedType: _propertyType,
          onTypeSelected: (type) => setState(() => _propertyType = type),
        );
      case 1:
        return StepPropertyDetailsWidget(
          listingType: _listingType,
          onListingTypeChanged: (v) => setState(() => _listingType = v),
          constructionStatus: _constructionStatus,
          onConstructionStatusChanged: (v) => setState(() => _constructionStatus = v),
          titleController: _titleController,
          descriptionController: _descriptionController,
          priceController: _priceController,
          areaController: _areaController,
          areaUnit: _areaUnit,
          onAreaUnitChanged: (v) => setState(() => _areaUnit = v),
          bedrooms: _bedrooms,
          onBedroomsChanged: (v) => setState(() => _bedrooms = v),
          bathrooms: _bathrooms,
          onBathroomsChanged: (v) => setState(() => _bathrooms = v),
          balconies: _balconies,
          onBalconiesChanged: (v) => setState(() => _balconies = v),
          parking: _parking,
          onParkingChanged: (v) => setState(() => _parking = v),
          floorNumberController: _floorNumberController,
          totalFloorsController: _totalFloorsController,
          facing: _facing,
          onFacingChanged: (v) => setState(() => _facing = v),
          furnishingStatus: _furnishingStatus,
          onFurnishingStatusChanged: (v) => setState(() => _furnishingStatus = v),
          selectedAmenities: _selectedAmenities,
          onAmenitiesChanged: (v) => setState(() => _selectedAmenities = v),
          medias: _medias,
          onMediasChanged: (v) => setState(() => _medias = v),
        );
      case 2:
        return StepPropertyLocationWidget(
          fullAddressController: _fullAddressController,
          cityController: _cityController,
          stateController: _stateController,
          countryController: _countryController,
          pincodeController: _pincodeController,
          landmarkController: _landmarkController,
          selectedBrokerId: _selectedBrokerId,
          onBrokerChanged: (brokerId) => setState(() => _selectedBrokerId = brokerId),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
