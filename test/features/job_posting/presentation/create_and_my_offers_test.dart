import 'package:flutter_test/flutter_test.dart';
import 'package:ocupa2/features/job_posting/data/models/create_offer_request.dart';
import 'package:ocupa2/features/job_posting/data/models/offer.dart';
import 'package:ocupa2/features/job_posting/data/models/offer_location.dart';
import 'package:ocupa2/features/job_posting/data/models/offer_payment.dart';
import 'package:ocupa2/features/job_posting/data/models/offer_status.dart';
import 'package:ocupa2/features/job_posting/data/repositories/job_posting_repository.dart';
import 'package:ocupa2/features/job_posting/presentation/viewmodels/create_offer_status.dart';
import 'package:ocupa2/features/job_posting/presentation/viewmodels/create_offer_view_model.dart';
import 'package:ocupa2/features/job_posting/presentation/viewmodels/my_offers_view_model.dart';
import 'package:ocupa2/features/job_posting/presentation/viewmodels/my_offers_status.dart';

Offer _offer({required String id, OfferStatus status = OfferStatus.active}) {
  return Offer(
    id: id,
    jobTypeKey: 'limpieza',
    jobTypeName: 'Limpieza',
    contractType: 'temporal',
    description: 'Descripción',
    address: 'Santo Domingo',
    location: const OfferLocation(lat: 18.48, lng: -69.89),
    payment: const OfferPayment(amount: 1500, currency: 'DOP'),
    status: status,
  );
}

class _FakeJobPostingRepository implements JobPostingRepository {
  _FakeJobPostingRepository({this.myOffers = const <Offer>[]});

  List<Offer> myOffers;
  int getMyOffersCalls = 0;

  @override
  Future<Offer> createOffer(CreateOfferRequest request) async {
    final Offer created = _offer(id: 'offer_created');
    myOffers = <Offer>[created, ...myOffers];
    return created;
  }

  @override
  Future<List<Offer>> getMyOffers() async {
    getMyOffersCalls += 1;
    return List<Offer>.from(myOffers);
  }

  @override
  Future<Offer> getOfferById(String id) {
    throw UnimplementedError();
  }

  @override
  Future<void> deactivateOffer(String id) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteOffer(String id) {
    throw UnimplementedError();
  }
}

void main() {
  test('publicar oferta exitosa guarda el id creado', () async {
    final _FakeJobPostingRepository repository = _FakeJobPostingRepository();
    final CreateOfferViewModel viewModel = CreateOfferViewModel(
      jobPostingRepository: repository,
    );

    final bool ok = await viewModel.submit(
      jobTypeKey: 'limpieza',
      contractType: 'temporal',
      description: 'Limpieza de hogar',
      address: 'Santo Domingo',
      photo: 'https://ocupa2.ia3x.com/media/foto.jpg',
      paymentId: 'pay_1',
      lat: 18.48,
      lng: -69.89,
      amount: 1500,
      currency: 'DOP',
      deadline: DateTime(2026, 8, 30),
    );

    expect(ok, isTrue);
    expect(viewModel.status, CreateOfferStatus.success);
    expect(viewModel.createdOffer?.id, 'offer_created');
  });

  test('GET /me/offers incluye la oferta recién creada', () async {
    final _FakeJobPostingRepository repository = _FakeJobPostingRepository();
    final CreateOfferViewModel viewModel = CreateOfferViewModel(
      jobPostingRepository: repository,
    );

    await viewModel.submit(
      jobTypeKey: 'limpieza',
      contractType: 'temporal',
      description: 'Limpieza de hogar',
      address: 'Santo Domingo',
      photo: 'https://ocupa2.ia3x.com/media/foto.jpg',
      paymentId: 'pay_1',
      lat: 18.48,
      lng: -69.89,
      amount: 1500,
      currency: 'DOP',
      deadline: DateTime(2026, 8, 30),
    );

    final CreatedOfferVisibility? visibility = await viewModel
        .verifyCreatedOfferInMyOffers();

    expect(visibility?.createdId, 'offer_created');
    expect(visibility?.foundInMyOffers, isTrue);
    expect(repository.getMyOffersCalls, greaterThanOrEqualTo(1));
  });

  test('Mis ofertas muestra published y oculta inactive', () async {
    final _FakeJobPostingRepository repository = _FakeJobPostingRepository(
      myOffers: <Offer>[
        _offer(id: 'new', status: offerStatusFromString('published')),
        _offer(id: 'old', status: OfferStatus.active),
        _offer(id: 'gone', status: OfferStatus.inactive),
      ],
    );
    final MyOffersViewModel viewModel = MyOffersViewModel(
      jobPostingRepository: repository,
    );

    await viewModel.loadMyOffers();

    expect(viewModel.status, MyOffersStatus.loaded);
    expect(viewModel.offers.map((Offer offer) => offer.id), <String>[
      'new',
      'old',
    ]);
  });
}
