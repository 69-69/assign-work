import 'package:assign_erp/core/util/debug_printify.dart';
import 'package:assign_erp/features/system_admin/data/models/company_model.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/company/company_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/setup_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GetCompany {
  static Company? internalCache;

  static Future<Company?> load() async {
    if (internalCache != null && internalCache!.isNotEmpty) {
      // Return cache if notEmpty
      return internalCache;
    }

    // Load all data initially to pass to the search delegate
    final info = CompanyBloc(firestore: FirebaseFirestore.instance).stream;

    try {
      final state =
          await info.firstWhere((state) => state is SetupsLoaded<Company>)
              as SetupsLoaded<Company>;

      if (state.data.isNotEmpty) {
        internalCache = state.data.first;
        return state.data.first;
      } else {
        // Handle the case when data is empty
        return Company.empty;
      }
    } catch (e) {
      // Handle potential errors
      prettyPrint('Error occurred', '$e');
      return Company.empty; // Or handle the error appropriately
    }
  }

  /*static Future<CompanyInfo?> load2() async {
    // Load all data initially to pass to the search delegate
    final info =  CompanyInfoBloc(firestore: FirebaseFirestore.instance).stream;

    // Ensure to wait for the data to be loaded
    // Wait for the first occurrence of the InfoLoadedState<CompanyInfo> state
    final state = await info.firstWhere(
          (state) => state is InfoLoadedState<CompanyInfo>,
    ) as InfoLoadedState<CompanyInfo>;

    return state.data.isEmpty? null : state.data.first;
  }*/
}
