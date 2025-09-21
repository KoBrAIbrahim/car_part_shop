import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/api/models/car_details.dart';
import '../../../../core/api/services/car_details_service.dart';
import '../../widgets/app_bottom_navigation_bar.dart';

class CarDetailsPage extends StatefulWidget {
  final String carMake;
  final String logoUrl;

  const CarDetailsPage({
    super.key,
    required this.carMake,
    required this.logoUrl,
  });

  @override
  State<CarDetailsPage> createState() => _CarDetailsPageState();
}

class _CarDetailsPageState extends State<CarDetailsPage>
    with TickerProviderStateMixin {
  String? selectedModel;
  String? selectedYear;
  String? selectedEngine;

  List<CarDetailOption> models = [];
  List<CarDetailOption> years = [];
  List<CarDetailOption> engines = [];

  bool isLoadingModels = false;
  bool isLoadingYears = false;
  bool isLoadingEngines = false;

  late AnimationController _slideController;
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _progressController;

  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Initialize animations
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack),
        );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    // Start initial animations
    _fadeController.forward();
    _slideController.forward();
    _scaleController.forward();

    _loadModels();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _loadModels() async {
    setState(() {
      isLoadingModels = true;
    });
    _progressController.forward();

    try {
      final fetchedModels = await CarDetailsService.getUniqueModels(
        widget.carMake,
      );
      setState(() {
        models = fetchedModels;
        isLoadingModels = false;
      });
      _progressController.reset();
    } catch (e) {
      setState(() {
        isLoadingModels = false;
      });
      _progressController.reset();
      _showErrorSnackBar('${tr('user.car_details.error_loading_models')}: $e');
    }
  }

  Future<void> _loadYears() async {
    if (selectedModel == null) return;

    setState(() {
      isLoadingYears = true;
      selectedYear = null;
      selectedEngine = null;
      years = [];
      engines = [];
    });
    _progressController.forward();

    try {
      final fetchedYears = await CarDetailsService.getUniqueYears(
        widget.carMake,
        selectedModel,
      );
      setState(() {
        years = fetchedYears;
        isLoadingYears = false;
      });
      _progressController.reset();
    } catch (e) {
      setState(() {
        isLoadingYears = false;
      });
      _progressController.reset();
      _showErrorSnackBar('${tr('user.car_details.error_loading_years')}: $e');
    }
  }

  Future<void> _loadEngines() async {
    if (selectedModel == null || selectedYear == null) return;

    setState(() {
      isLoadingEngines = true;
      selectedEngine = null;
      engines = [];
    });
    _progressController.forward();

    try {
      final fetchedEngines = await CarDetailsService.getUniqueEngines(
        widget.carMake,
        selectedModel,
        selectedYear,
      );
      setState(() {
        engines = fetchedEngines;
        isLoadingEngines = false;
      });
      _progressController.reset();
    } catch (e) {
      setState(() {
        isLoadingEngines = false;
      });
      _progressController.reset();
      _showErrorSnackBar('${tr('user.car_details.error_loading_engines')}: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _onModelChanged(String? model) {
    setState(() {
      selectedModel = model;
    });
    if (model != null) {
      _loadYears();
    }
  }

  void _onYearChanged(String? year) {
    setState(() {
      selectedYear = year;
    });
    if (year != null) {
      _loadEngines();
    }
  }

  void _onEngineChanged(String? engine) {
    setState(() {
      selectedEngine = engine;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.isDarkMode;

        return Scaffold(
          backgroundColor: AppColors.getBackground(isDark),
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.getCardBackground(isDark).withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.getDivider(isDark).withOpacity(0.3),
                ),
              ),
              child: IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: AppColors.getTextColor(isDark),
                ),
                onPressed: () => context.go('/home'),
              ),
            ),
            title: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.getCardBackground(isDark).withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.getDivider(isDark).withOpacity(0.3),
                ),
              ),
              child: Text(
                tr('user.car_details.title'),
                style: TextStyle(
                  color: AppColors.getTextColor(isDark),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            centerTitle: true,
          ),
          body: Stack(
            children: [
              // Background gradient
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isDark
                        ? [AppColors.darkBackground, AppColors.darkSurface]
                        : [AppColors.lightBackground, AppColors.lightSurface],
                  ),
                ),
              ),

              // Main content
              SafeArea(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),

                          // Car logo and name section with enhanced design
                          ScaleTransition(
                            scale: _scaleAnimation,
                            child: _buildCarHeaderCard(isDark),
                          ),

                          const SizedBox(height: 32),

                          // Progress indicator
                          _buildProgressIndicator(isDark),

                          const SizedBox(height: 24),

                          // Selection Title with animation
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            child: Text(
                              tr('user.car_details.select_car_details'),
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    color: AppColors.getTextColor(isDark),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 22,
                                  ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Animated selectors
                          _buildAnimatedSelector(
                            title: tr('user.car_details.model'),
                            value: selectedModel,
                            items: models,
                            isLoading: isLoadingModels,
                            onChanged: _onModelChanged,
                            isDark: isDark,
                            delay: 0,
                          ),

                          const SizedBox(height: 20),

                          _buildAnimatedSelector(
                            title: tr('user.car_details.year'),
                            value: selectedYear,
                            items: years,
                            isLoading: isLoadingYears,
                            onChanged: _onYearChanged,
                            isDark: isDark,
                            enabled: selectedModel != null,
                            delay: 200,
                          ),

                          const SizedBox(height: 20),

                          _buildAnimatedSelector(
                            title: tr('user.car_details.engine'),
                            value: selectedEngine,
                            items: engines,
                            isLoading: isLoadingEngines,
                            onChanged: _onEngineChanged,
                            isDark: isDark,
                            enabled: selectedYear != null,
                            delay: 400,
                          ),

                          const SizedBox(height: 40),

                          // Enhanced Continue Button
                          _buildContinueButton(isDark),

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: AppBottomNavigationBar(
            currentIndex:
                0, // Car details is not part of main tabs, so keep it at 0 (home)
          ),
        );
      },
    );
  }

  Widget _buildCarHeaderCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [AppColors.darkCardBackground, AppColors.darkSurface]
              : [AppColors.lightCardBackground, AppColors.lightSurface],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.getDivider(isDark).withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : AppColors.getPrimary(isDark).withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 5),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          // Enhanced Car Logo
          Hero(
            tag: 'car_logo_${widget.carMake}',
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white, Color(0xFFF8F9FA)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.getDivider(isDark).withOpacity(0.5),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.getPrimary(isDark).withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: CachedNetworkImage(
                  imageUrl: widget.logoUrl,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.getPrimary(isDark),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Icon(
                    Icons.car_repair_rounded,
                    color: AppColors.getPrimary(isDark),
                    size: 40,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Car make name with gradient text effect
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: isDark
                  ? [AppColors.darkTextLight, AppColors.accent]
                  : [AppColors.lightTextDark, AppColors.accent],
            ).createShader(bounds),
            child: Text(
              widget.carMake,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(bool isDark) {
    int completedSteps = 0;
    if (selectedModel != null) completedSteps++;
    if (selectedYear != null) completedSteps++;
    if (selectedEngine != null) completedSteps++;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getCardBackground(isDark).withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.getDivider(isDark).withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Text(
            'Progress: $completedSteps/3',
            style: TextStyle(
              color: AppColors.getTextColor(isDark),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: completedSteps / 3,
              backgroundColor: AppColors.getDivider(isDark),
              valueColor: AlwaysStoppedAnimation<Color>(
                AppColors.getPrimary(isDark),
              ),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedSelector({
    required String title,
    required String? value,
    required List<CarDetailOption> items,
    required bool isLoading,
    required void Function(String?) onChanged,
    required bool isDark,
    bool enabled = true,
    int delay = 0,
  }) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + delay),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: _buildSelector(
              title: title,
              value:
                  this.selectedModel == null &&
                      title.toLowerCase().contains('year')
                  ? null
                  : this.selectedYear == null &&
                        title.toLowerCase().contains('engine')
                  ? null
                  : title.toLowerCase().contains('model')
                  ? selectedModel
                  : title.toLowerCase().contains('year')
                  ? selectedYear
                  : selectedEngine,
              items: items,
              isLoading: isLoading,
              onChanged: onChanged,
              isDark: isDark,
              enabled: enabled,
            ),
          ),
        );
      },
    );
  }

  Widget _buildSelector({
    required String title,
    required String? value,
    required List<CarDetailOption> items,
    required bool isLoading,
    required void Function(String?) onChanged,
    required bool isDark,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              color: AppColors.getTextColor(isDark),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            gradient: enabled
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [AppColors.darkCardBackground, AppColors.darkSurface]
                        : [
                            AppColors.lightCardBackground,
                            AppColors.lightSurface,
                          ],
                  )
                : null,
            color: enabled
                ? null
                : AppColors.getCardBackground(isDark).withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: enabled
                  ? AppColors.getDivider(isDark).withOpacity(0.5)
                  : AppColors.getDivider(isDark).withOpacity(0.3),
              width: enabled ? 1.5 : 1,
            ),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: AppColors.getPrimary(isDark).withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: isLoading
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.getPrimary(isDark),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Loading...',
                          style: TextStyle(
                            color: AppColors.getTextColor(
                              isDark,
                            ).withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : DropdownButton<String>(
                  value: value,
                  isExpanded: true,
                  underline: const SizedBox(),
                  hint: Text(
                    _getSelectHintText(title),
                    style: TextStyle(
                      color: AppColors.getTextColor(isDark).withOpacity(0.6),
                    ),
                  ),
                  style: TextStyle(color: AppColors.getTextColor(isDark)),
                  dropdownColor: AppColors.getCardBackground(isDark),
                  onChanged: enabled ? onChanged : null,
                  icon: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.getTextColor(isDark).withOpacity(0.7),
                  ),
                  items: items.map((option) {
                    return DropdownMenuItem<String>(
                      value: option.value,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          option.value,
                          style: TextStyle(
                            color: option.isAvailable
                                ? AppColors.getTextColor(isDark)
                                : AppColors.getTextColor(
                                    isDark,
                                  ).withOpacity(0.5),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildContinueButton(bool isDark) {
    final isComplete =
        selectedModel != null && selectedYear != null && selectedEngine != null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      width: double.infinity,
      height: isComplete ? 56 : 0,
      child: isComplete
          ? TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 500),
              tween: Tween(begin: 0.0, end: 1.0),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                            ? [AppColors.darkPrimary, AppColors.secondary]
                            : [AppColors.lightPrimary, AppColors.secondary],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.getPrimary(isDark).withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () async {
                        try {
                          final carId = await CarDetailsService.getCarId(
                            widget.carMake,
                            selectedModel!,
                            selectedYear!,
                            selectedEngine!,
                          );

                          if (carId != null) {
                            final carName =
                                '${widget.carMake} $selectedModel $selectedYear $selectedEngine';

                            if (mounted) {
                              context.push(
                                '/car-parts/$carId?carName=${Uri.encodeComponent(carName)}',
                              );
                            }
                          } else {
                            if (mounted) {
                              _showErrorSnackBar(
                                tr('user.car_details.car_not_found'),
                              );
                            }
                          }
                        } catch (e) {
                          print('❌ [CAR_DETAILS] Error getting car ID: $e');
                          if (mounted) {
                            _showErrorSnackBar(
                              '${tr('user.car_details.error_getting_car_id')}: $e',
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: isDark ? Colors.white : Colors.black,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.arrow_forward_rounded, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            tr('user.car_details.continue'),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            )
          : const SizedBox(),
    );
  }

  String _getSelectHintText(String title) {
    final titleLower = title.toLowerCase();
    switch (titleLower) {
      case 'model':
        return tr('user.car_details.select_model');
      case 'year':
        return tr('user.car_details.select_year');
      case 'engine':
        return tr('user.car_details.select_engine');
      default:
        return 'Select $title';
    }
  }
}
