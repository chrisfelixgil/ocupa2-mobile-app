import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:ocupa2/app/config/environment.dart';
import 'package:ocupa2/app/router/app_router.dart';

import 'package:ocupa2/core/network/api_client.dart';
import 'package:ocupa2/core/session/session_event_bus.dart';
import 'package:ocupa2/core/storage/secure_storage_service.dart';
import 'package:ocupa2/core/storage/token_storage.dart';

// AUTH
import 'package:ocupa2/features/auth/data/repositories/auth_repository.dart';
import 'package:ocupa2/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:ocupa2/features/auth/data/services/auth_service.dart';
import 'package:ocupa2/features/auth/data/services/auth_service_impl.dart';
import 'package:ocupa2/features/auth/presentation/viewmodels/auth_view_model.dart';
import 'package:ocupa2/features/auth/presentation/viewmodels/session_view_model.dart';

// CATALOG
import 'package:ocupa2/features/catalog/data/repositories/catalog_repository.dart';
import 'package:ocupa2/features/catalog/data/services/catalog_service.dart';

// JOB SEARCH
import 'package:ocupa2/features/job_search/data/repositories/job_search_repository.dart';
import 'package:ocupa2/features/job_search/data/repositories/job_search_repository_impl.dart';
import 'package:ocupa2/features/job_search/data/services/job_search_service.dart';
import 'package:ocupa2/features/job_search/data/services/job_search_service_impl.dart';
import 'package:ocupa2/features/job_search/presentation/viewmodels/explore_offers_view_model.dart';

// MY ACTIVITY
import 'package:ocupa2/features/my_activity/data/repositories/application_repository.dart';
import 'package:ocupa2/features/my_activity/data/repositories/contract_repository.dart';
import 'package:ocupa2/features/my_activity/data/repositories/experience_repository.dart';
import 'package:ocupa2/features/my_activity/data/repositories/offer_repository.dart';

import 'package:ocupa2/features/my_activity/data/services/application_service.dart';
import 'package:ocupa2/features/my_activity/data/services/contract_service.dart';
import 'package:ocupa2/features/my_activity/data/services/experience_service.dart';
import 'package:ocupa2/features/my_activity/data/services/offer_service.dart';

import 'package:ocupa2/features/my_activity/presentation/viewmodels/applications_view_model.dart';
import 'package:ocupa2/features/my_activity/presentation/viewmodels/contracts_view_model.dart';
import 'package:ocupa2/features/my_activity/presentation/viewmodels/experiences_view_model.dart';
import 'package:ocupa2/features/my_activity/presentation/viewmodels/my_offers_view_model.dart';

// UPLOAD SERVICE PARA EXPERIENCIAS
import 'package:ocupa2/features/uploads/data/services/upload_service.dart'
    as uploads_service;

// JOB POSTING
import 'package:ocupa2/features/job_posting/data/repositories/job_posting_repository.dart';
import 'package:ocupa2/features/job_posting/data/repositories/job_posting_repository_impl.dart';
import 'package:ocupa2/features/job_posting/data/services/job_posting_service.dart';
import 'package:ocupa2/features/job_posting/data/services/job_posting_service_impl.dart';

// UPLOAD SERVICE PARA PUBLICAR OFERTAS
import 'package:ocupa2/features/job_posting/data/services/upload_service.dart'
    as job_posting_upload;

// PAYMENTS
import 'package:ocupa2/features/payments/data/repositories/payment_repository.dart';
import 'package:ocupa2/features/payments/data/repositories/payment_repository_impl.dart';
import 'package:ocupa2/features/payments/data/services/payment_service.dart';
import 'package:ocupa2/features/payments/data/services/payment_service_impl.dart';
import 'package:ocupa2/features/payments/presentation/viewmodels/make_payment_view_model.dart';

class AppProviders extends StatelessWidget {
  const AppProviders({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<TokenStorage>(
          create: (_) => SecureStorageService(),
        ),

        Provider<SessionEventBus>(
          create: (_) => SessionEventBus(),
          dispose: (_, SessionEventBus eventBus) {
            eventBus.dispose();
          },
        ),

        Provider<ApiClient>(
          create: (BuildContext context) {
            return ApiClient.create(
              baseUrl: Environment.apiBaseUrl,
              tokenStorage: context.read<TokenStorage>(),
              sessionEventBus: context.read<SessionEventBus>(),
            );
          },
          dispose: (_, ApiClient apiClient) {
            apiClient.close();
          },
        ),

        // AUTH
        Provider<AuthService>(
          create: (BuildContext context) {
            return AuthServiceImpl(
              apiClient: context.read<ApiClient>(),
            );
          },
        ),

        Provider<AuthRepository>(
          create: (BuildContext context) {
            return AuthRepositoryImpl(
              authService: context.read<AuthService>(),
              tokenStorage: context.read<TokenStorage>(),
            );
          },
        ),

        ChangeNotifierProvider<SessionViewModel>(
          create: (BuildContext context) {
            final SessionViewModel viewModel = SessionViewModel(
              authRepository: context.read<AuthRepository>(),
              sessionEventBus: context.read<SessionEventBus>(),
            );

            unawaited(viewModel.restoreSession());

            return viewModel;
          },
        ),

        ChangeNotifierProvider<AuthViewModel>(
          create: (BuildContext context) {
            return AuthViewModel(
              authRepository: context.read<AuthRepository>(),
              sessionViewModel: context.read<SessionViewModel>(),
            );
          },
        ),

        // CATALOG
        Provider<CatalogService>(
          create: (BuildContext context) {
            return CatalogServiceImpl(
              apiClient: context.read<ApiClient>(),
            );
          },
        ),

        Provider<CatalogRepository>(
          create: (BuildContext context) {
            return CatalogRepository(
              catalogService: context.read<CatalogService>(),
            );
          },
        ),

        // JOB SEARCH
        Provider<JobSearchService>(
          create: (BuildContext context) {
            return JobSearchServiceImpl(
              apiClient: context.read<ApiClient>(),
            );
          },
        ),

        Provider<JobSearchRepository>(
          create: (BuildContext context) {
            return JobSearchRepositoryImpl(
              jobSearchService: context.read<JobSearchService>(),
            );
          },
        ),

        // EXPERIENCES
        Provider<ExperienceService>(
          create: (BuildContext context) {
            return ExperienceServiceImpl(
              apiClient: context.read<ApiClient>(),
            );
          },
        ),

        Provider<uploads_service.UploadService>(
          create: (BuildContext context) {
            return uploads_service.UploadServiceImpl(
              apiClient: context.read<ApiClient>(),
            );
          },
        ),

        Provider<ExperienceRepository>(
          create: (BuildContext context) {
            return ExperienceRepository(
              experienceService:
                  context.read<ExperienceService>(),
            );
          },
        ),

        ChangeNotifierProvider<ExperiencesViewModel>(
          create: (BuildContext context) {
            return ExperiencesViewModel(
              experienceRepository:
                  context.read<ExperienceRepository>(),
              uploadService:
                  context.read<uploads_service.UploadService>(),
            );
          },
        ),

        // APPLICATIONS
        Provider<ApplicationService>(
          create: (BuildContext context) {
            return ApplicationServiceImpl(
              apiClient: context.read<ApiClient>(),
            );
          },
        ),

        Provider<ApplicationRepository>(
          create: (BuildContext context) {
            return ApplicationRepository(
              applicationService:
                  context.read<ApplicationService>(),
            );
          },
        ),

        ChangeNotifierProvider<ApplicationsViewModel>(
          create: (BuildContext context) {
            return ApplicationsViewModel(
              applicationRepository:
                  context.read<ApplicationRepository>(),
            );
          },
        ),

        // MY OFFERS
        Provider<OfferService>(
          create: (BuildContext context) {
            return OfferServiceImpl(
              apiClient: context.read<ApiClient>(),
            );
          },
        ),

        Provider<OfferRepository>(
          create: (BuildContext context) {
            return OfferRepository(
              offerService: context.read<OfferService>(),
            );
          },
        ),

        ChangeNotifierProvider<MyOffersViewModel>(
          create: (BuildContext context) {
            return MyOffersViewModel(
              offerRepository: context.read<OfferRepository>(),
            );
          },
        ),

        // JOB POSTING debe ir antes de ExploreOffersViewModel:
        // ese VM lee JobPostingRepository en su create().
        Provider<JobPostingService>(
          create: (BuildContext context) {
            return JobPostingServiceImpl(
              apiClient: context.read<ApiClient>(),
            );
          },
        ),

        Provider<JobPostingRepository>(
          create: (BuildContext context) {
            return JobPostingRepositoryImpl(
              jobPostingService: context.read<JobPostingService>(),
            );
          },
        ),

        ChangeNotifierProvider<ExploreOffersViewModel>(
          create: (BuildContext context) {
            return ExploreOffersViewModel(
              jobSearchRepository: context.read<JobSearchRepository>(),
              applicationRepository: context.read<ApplicationRepository>(),
              jobPostingRepository: context.read<JobPostingRepository>(),
            );
          },
        ),

        // CONTRACTS
        Provider<ContractService>(
          create: (BuildContext context) {
            return ContractServiceImpl(
              apiClient: context.read<ApiClient>(),
            );
          },
        ),

        Provider<ContractRepository>(
          create: (BuildContext context) {
            return ContractRepository(
              contractService:
                  context.read<ContractService>(),
            );
          },
        ),

        ChangeNotifierProvider<ContractsViewModel>(
          create: (BuildContext context) {
            return ContractsViewModel(
              contractRepository:
                  context.read<ContractRepository>(),
            );
          },
        ),

        // UPLOAD DE JOB POSTING
        Provider<job_posting_upload.UploadService>(
          create: (BuildContext context) {
            return job_posting_upload.UploadService(
              apiClient: context.read<ApiClient>(),
            );
          },
        ),

        // PAYMENTS
        Provider<PaymentService>(
          create: (BuildContext context) {
            return PaymentServiceImpl(
              apiClient: context.read<ApiClient>(),
            );
          },
        ),

        Provider<PaymentRepository>(
          create: (BuildContext context) {
            return PaymentRepositoryImpl(
              paymentService:
                  context.read<PaymentService>(),
            );
          },
        ),

        ChangeNotifierProvider<MakePaymentViewModel>(
          create: (BuildContext context) {
            return MakePaymentViewModel(
              paymentRepository:
                  context.read<PaymentRepository>(),
            );
          },
        ),

        // ROUTER
        Provider<GoRouter>(
          create: (BuildContext context) {
            return createAppRouter(
              context.read<SessionViewModel>(),
            );
          },
          dispose: (_, GoRouter router) {
            router.dispose();
          },
        ),
      ],
      child: child,
    );
  }
}