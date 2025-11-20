import 'package:assign_erp/core/util/debug_printify.dart';
import 'package:assign_erp/features/system_admin/data/models/company_info_model.dart';
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
      // Wait for the first occurrence of the InfoLoadedState<CompanyInfo> state
      final state =
          await info.firstWhere((state) => state is SetupsLoaded<Company>)
              as SetupsLoaded<Company>;

      // Check if data is not empty and return the first item if available
      if (state.data.isNotEmpty) {
        // debugPrint('steve-today ${state.data.first}');
        internalCache = state.data.first;
        return state.data.first;
      } else {
        // Handle the case when data is empty
        // debugPrint('No data available');
        return Company.notFound; // Or handle as appropriate for your use case
      }
    } catch (e) {
      // Handle potential errors
      prettyPrint('Error occurred', '$e');
      return Company.notFound; // Or handle the error appropriately
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
