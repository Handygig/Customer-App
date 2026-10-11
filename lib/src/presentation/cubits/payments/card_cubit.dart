import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:customer_app/src/domain/entities/payments/card_entity.dart';
import 'package:customer_app/src/domain/usecases/payments/card_usecases.dart';
import 'package:customer_app/src/presentation/cubits/payments/card_state.dart';

class CardCubit extends Cubit<CardState> {
  final GetCardsUseCase _getCardsUseCase;
  final AddCardUseCase _addCardUseCase;
  final DeleteCardUseCase _deleteCardUseCase;
  final SetDefaultCardUseCase _setDefaultCardUseCase;
  final ToggleFreezeCardUseCase _toggleFreezeCardUseCase;
  final PayJobAssignmentUseCase _payJobAssignmentUseCase;

  List<CardEntity> _cachedCards = const [];
  CardEntity? _selectedCard;

  CardCubit(
    this._getCardsUseCase,
    this._addCardUseCase,
    this._deleteCardUseCase,
    this._setDefaultCardUseCase,
    this._toggleFreezeCardUseCase,
    this._payJobAssignmentUseCase,
  ) : super(const CardInitial());

  List<CardEntity> get cards => _cachedCards;
  CardEntity? get selectedCard => _selectedCard;

  Future<void> loadCards({bool silent = false}) async {
    if (!silent) {
      emit(const CardLoading());
    }

    final result = await _getCardsUseCase();
    result.fold(
      (failure) => emit(CardError(failure.errorMessage)),
      (cardsList) {
        _cachedCards = cardsList;
        if (_selectedCard == null || !cardsList.any((c) => c.id == _selectedCard!.id)) {
          _selectedCard = cardsList.isNotEmpty
              ? cardsList.firstWhere((c) => c.isDefault, orElse: () => cardsList.first)
              : null;
        }
        emit(CardLoaded(List.unmodifiable(_cachedCards), selectedCard: _selectedCard));
      },
    );
  }

  void selectCard(CardEntity card) {
    _selectedCard = card;
    emit(CardLoaded(List.unmodifiable(_cachedCards), selectedCard: _selectedCard));
  }

  Future<bool> setDefaultCard(int cardId) async {
    final previousCards = List<CardEntity>.from(_cachedCards);
    final previousSelected = _selectedCard;

    _cachedCards = _cachedCards
        .map((c) => c.copyWith(isDefault: c.id == cardId))
        .toList();
    _selectedCard = _cachedCards.firstWhere((c) => c.id == cardId, orElse: () => _cachedCards.first);
    emit(CardLoaded(List.unmodifiable(_cachedCards), selectedCard: _selectedCard));

    final result = await _setDefaultCardUseCase(cardId);
    return result.fold(
      (failure) {
        _cachedCards = previousCards;
        _selectedCard = previousSelected;
        emit(CardError(failure.errorMessage));
        emit(CardLoaded(List.unmodifiable(_cachedCards), selectedCard: _selectedCard));
        return false;
      },
      (_) {
        emit(const CardActionSuccess('Primary card updated successfully'));
        emit(CardLoaded(List.unmodifiable(_cachedCards), selectedCard: _selectedCard));
        return true;
      },
    );
  }

  Future<bool> toggleFreezeCard(int cardId, bool freeze) async {
    final previousCards = List<CardEntity>.from(_cachedCards);
    final previousSelected = _selectedCard;

    _cachedCards = _cachedCards
        .map((c) => c.id == cardId ? c.copyWith(isFrozen: freeze) : c)
        .toList();
    if (_selectedCard?.id == cardId) {
      _selectedCard = _selectedCard!.copyWith(isFrozen: freeze);
    }
    emit(CardLoaded(List.unmodifiable(_cachedCards), selectedCard: _selectedCard));

    final result = await _toggleFreezeCardUseCase(cardId, freeze);
    return result.fold(
      (failure) {
        _cachedCards = previousCards;
        _selectedCard = previousSelected;
        emit(CardError(failure.errorMessage));
        emit(CardLoaded(List.unmodifiable(_cachedCards), selectedCard: _selectedCard));
        return false;
      },
      (_) {
        final msg = freeze ? 'Card frozen successfully' : 'Card unfrozen successfully';
        emit(CardActionSuccess(msg));
        emit(CardLoaded(List.unmodifiable(_cachedCards), selectedCard: _selectedCard));
        return true;
      },
    );
  }

  Future<bool> addCard({
    required String cardType,
    required String maskedCardNumber,
    required String expiryDate,
    required String cardHolderName,
    String? billingAddress,
  }) async {
    emit(const CardLoading());

    final result = await _addCardUseCase(
      cardType: cardType,
      maskedCardNumber: maskedCardNumber,
      expiryDate: expiryDate,
      cardHolderName: cardHolderName,
      billingAddress: billingAddress,
    );

    return result.fold(
      (failure) {
        emit(CardError(failure.errorMessage));
        if (_cachedCards.isNotEmpty) {
          emit(CardLoaded(List.unmodifiable(_cachedCards), selectedCard: _selectedCard));
        }
        return false;
      },
      (newCard) async {
        emit(const CardActionSuccess('Card added successfully'));
        await loadCards(silent: true);
        return true;
      },
    );
  }

  Future<bool> deleteCard(int cardId) async {
    final result = await _deleteCardUseCase(cardId);

    return result.fold(
      (failure) {
        emit(CardError(failure.errorMessage));
        emit(CardLoaded(List.unmodifiable(_cachedCards), selectedCard: _selectedCard));
        return false;
      },
      (_) async {
        _cachedCards = _cachedCards.where((c) => c.id != cardId).toList();
        if (_selectedCard?.id == cardId) {
          _selectedCard = _cachedCards.isNotEmpty ? _cachedCards.first : null;
        }
        emit(const CardActionSuccess('Card removed successfully'));
        emit(CardLoaded(List.unmodifiable(_cachedCards), selectedCard: _selectedCard));
        return true;
      },
    );
  }

  Future<bool> payJobAssignment({
    required int jobAssignmentId,
    required int cardId,
  }) async {
    emit(const CardLoading());

    final result = await _payJobAssignmentUseCase(
      jobAssignmentId: jobAssignmentId,
      cardId: cardId,
    );

    return result.fold(
      (failure) {
        emit(CardError(failure.errorMessage));
        emit(CardLoaded(List.unmodifiable(_cachedCards), selectedCard: _selectedCard));
        return false;
      },
      (payment) {
        emit(CardPaymentSuccess(payment));
        emit(CardLoaded(List.unmodifiable(_cachedCards), selectedCard: _selectedCard));
        return true;
      },
    );
  }
}