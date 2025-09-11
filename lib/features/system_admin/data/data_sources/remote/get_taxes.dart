import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/features/system_admin/data/models/tax_model.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/setup_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/taxes/tax_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GetTaxes {
  static List<Tax>? _cached;
  static DateTime? _lastFetched;
  static const Duration _cacheDuration = fMinutesDuration;

  // listen to the data loaded state
  static Future<SetupsLoaded<Tax>> _dataLoadedState(TaxBloc bloc) async {
    return await bloc.stream.firstWhere((state) => state is SetupsLoaded<Tax>)
        as SetupsLoaded<Tax>;
  }

  static Future<List<Tax>> getAllTaxes({bool forceRefresh = false}) async {
    final taxBloc = TaxBloc(firestore: FirebaseFirestore.instance);
    final now = DateTime.now();

    if (!forceRefresh &&
        (_cached?.isNotEmpty ?? false) &&
        _lastFetched != null) {
      final isFresh = now.difference(_lastFetched!) < _cacheDuration;
      if (isFresh) return _cached!;
    }

    // Load all data initially
    taxBloc.add(GetSetups<Tax>());
    final state = await _dataLoadedState(taxBloc);
    _cached = state.data;
    _lastFetched = now;

    return state.data;
  }

  static Future<Map<String, ResolveTaxCode>> loadAllTaxRates() async {
    final List<Tax> taxes = await GetTaxes.getAllTaxes();

    return {
      for (final tax in taxes)
        tax.code: ResolveTaxCode(rate: tax.rate, name: tax.name),
    };
  }

  static Future<List<Tax>> byAnyTerm(term) async {
    final taxBloc = TaxBloc(firestore: FirebaseFirestore.instance);

    // Load all data initially to pass to the search delegate
    taxBloc.add(
      SearchSetup<Tax>(
        field: 'name',
        optField: 'code',
        auxField: 'rate',
        query: term,
      ),
    );
    final state = await _dataLoadedState(taxBloc);
    return state.data.isEmpty ? [] : state.data;
  }
}

/*class GetTaxes2 {
  static final taxBloc = TaxBloc(firestore: FirebaseFirestore.instance);

  static Future<SetupsLoaded<Tax>> _dataLoadedState(TaxBloc bloc) async {
    return await bloc.stream.firstWhere((state) => state is SetupsLoaded<Tax>)
        as SetupsLoaded<Tax>;
  }

  /// Get all taxes.
  static Future<List<Tax>> getAllTaxes() async {
    // final taxBloc = TaxBloc(firestore: FirebaseFirestore.instance);
    final taxes = (await _dataLoadedState(taxBloc)).data;
    return taxes;
  }

  /// Get tax rate by code.
  static Future<double> getTaxRateByCode(String code) async {
    final taxes = await getAllTaxes();
    return taxes.isEmpty
        ? 0.0
        : taxes.firstWhere((tax) => tax.code == code).rate;
  }

  static Future<List<Tax>> byAnyTerm(term) async {
    // final taxBloc = TaxBloc(firestore: FirebaseFirestore.instance);

    // Load all data initially to pass to the search delegate
    taxBloc.add(
      SearchSetup<Tax>(
        field: 'name',
        optField: 'code',
        auxField: 'rate',
        query: term,
      ),
    );

    // Ensure to wait for the data to be loaded
    final state = await _dataLoadedState(taxBloc);

    return state.data.isEmpty ? [] : state.data;
  }
}*/
