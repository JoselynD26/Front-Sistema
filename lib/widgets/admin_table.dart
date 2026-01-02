import 'package:flutter/material.dart';

class AdminTable extends StatelessWidget {
  final List<DataColumn> columns;
  final List<DataRow> rows;
  final bool isLoading;

  const AdminTable({
    super.key,
    required this.columns,
    required this.rows,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.all(48.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (rows.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(48.0),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.inbox_rounded, size: 48, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                "No se encontraron registros",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
        dataTableTheme: DataTableThemeData(
          headingTextStyle: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
          dataTextStyle: TextStyle(
            color: isDark ? Colors.grey.shade300 : const Color(0xFF334155),
          ),
          headingRowColor: WidgetStateProperty.all(
            isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
          ),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            horizontalMargin: 24,
            columnSpacing: 32,
            headingRowHeight: 56,
            dataRowMinHeight: 52,
            dataRowMaxHeight: double.infinity,
            dividerThickness: 0.5,
            columns: columns,
            rows: rows,
          ),
        ),
      ),
    );
  }
}
