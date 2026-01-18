import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/layout/custom_scaffold.dart';
import 'package:flutter/material.dart';

class ApprovalRulesScreen extends StatefulWidget {
  const ApprovalRulesScreen({super.key});

  @override
  State<ApprovalRulesScreen> createState() => _ApprovalRulesScreenState();
}

class _ApprovalRulesScreenState extends State<ApprovalRulesScreen> {
  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      title: workflowRulesScreenTitle.toUpperAll,
      body: Center(
        child: Text(
          'Workflow Approval Rules Screen\nProcurement workflow\nAdd number of approvals for each stage:\nPR -> RFQ -> PO\n\n'
          '-----------------------------------------\n'
          '| Approval Workflow Configuration       |\n'
          '-----------------------------------------\n'
          '| Document Type: [ PO ▼ ]               |\n'
          '-----------------------------------------\n'
          '| Approval Steps                         |\n'
          '|---------------------------------------|\n'
          '| Step | Role            | Amount Range |\n'
          '|---------------------------------------|\n'
          '|  1   | Dept Head       | 0 – 5,000    |\n'
          '|  2   | Finance Manager | 5,001 – ∞    |\n'
          '|  3   | CFO             | 20,000 – ∞   |\n'
          '-----------------------------------------\n'
          '| [+ Add Step]                           |\n'
          '-----------------------------------------\n'
          '| [ Save Workflow ]                     |\n'
          '-----------------------------------------',
          style: context.textTheme.titleLarge,
          textAlign: TextAlign.justify,
        ),
      ),
    );
  }

  /* Column _buildWorkflowApprovalBody() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        /// 1⃣ Workflow Overview
        FormGroupCard(
          title: 'Document & Role',
          children: [
            _buildDocumentTypeSelector(),
            _buildRoleSelector(),
          ],
        ),

        /// 2⃣ Conditions & Thresholds
        FormGroupCard(
          title: 'Conditions & Thresholds',
          children: [_buildAmountConditions()],
        ),

        /// Action button
        context.confirmableActionButton(
          label: 'Save Approval Rules',
          onPressed: _onSaveWorkflow,
        ),
        const SizedBox(height: 20.0),
      ],
    );
  }

  Widget _buildDocumentTypeSelector() => const SizedBox();

  Widget _buildAmountConditions() => const SizedBox();*/
}

/*{
  "documentType": "PR",
  "steps": [
    {
      "level": 1,
      "role": "DepartmentHead",
      "condition": "amount <= 5000"
    },
    {
      "level": 2,
      "role": "FinanceManager",
      "condition": "amount > 5000"
    }
  ]
}

// Approval Rules/Configs
-----------------------------------------
| Approval Workflow Configuration       |
-----------------------------------------
| Document Type: [ PO ▼ ]               |
-----------------------------------------
| Approval Steps                         |
|---------------------------------------|
| Step | Role            | Amount Range |
|---------------------------------------|
|  1   | Dept Head       | 0 – 5,000    |
|  2   | Finance Manager | 5,001 – ∞    |
|  3   | CFO             | 20,000 – ∞   |
-----------------------------------------
| [+ Add Step]                           |
-----------------------------------------
| [ Save Workflow ]                     |
-----------------------------------------

UI Types:
========
| Field   | UI             |
| ------- | -------------- |
| docType | Dropdown       |
| role    | Dropdown       |
| level   | Auto-generated |
| min/max | Range fields   |
| steps   | Table + modal  |

*/
