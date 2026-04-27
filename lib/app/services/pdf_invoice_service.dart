import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../data/models/case_model.dart';
import '../data/models/expense_model.dart';
import '../data/models/invoice_model.dart';
import '../data/models/time_entry_model.dart';
import 'storage_service.dart';

class PdfInvoiceService {
  static Future<Uint8List> generate(InvoiceModel invoice) async {
    final fontData = await rootBundle.load("fonts/poppins.ttf");
    final font = pw.Font.ttf(fontData);

    final pdf = pw.Document();

    final storage = StorageService.instance;
    final caseBox = await storage.getBox<CaseModel>('cases');
    final timeBox = await storage.getBox<TimeEntryModel>('time_entries');
    final expenseBox = await storage.getBox<ExpenseModel>('expenses');

    final caseModel = caseBox.values.firstWhere((c) => c.id == invoice.caseId);
    final timeEntries = invoice.timeEntryIds
        .map((id) => timeBox.get(int.parse(id)))
        .whereType<TimeEntryModel>()
        .toList();
    final expenses = invoice.expenseIds
        .map((id) => expenseBox.get(int.parse(id)))
        .whereType<ExpenseModel>()
        .toList();

    final indigo = PdfColors.indigo;

    pdf.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.all(24),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text("LegalDesk Invoice",
                style: pw.TextStyle(
                    font: font, fontSize: 20, fontWeight: pw.FontWeight.bold, color: indigo)),
            pw.SizedBox(height: 4),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text("Invoice ID: ${invoice.id}",
                    style: pw.TextStyle(font: font, fontSize: 12)),
                pw.Text("Date: ${invoice.invoiceDate.toLocal().toString().split(' ')[0]}",
                    style: pw.TextStyle(font: font, fontSize: 12)),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Text("Case: ${caseModel.title}",
                style: pw.TextStyle(font: font, fontSize: 12)),
            pw.SizedBox(height: 16),
          ],
        ),
        footer: (context) => pw.Column(
          children: [
            pw.Divider(),
            pw.Center(
              child: pw.Text("Generated using LegalDesk App",
                  style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey)),
            ),
          ],
        ),
        build: (context) => [
          // Time Entries Section
          pw.Text("Time Entries",
              style: pw.TextStyle(font: font, fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          ...timeEntries.map((t) => pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 2),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Expanded(child: pw.Text(t.description, style: pw.TextStyle(font: font, fontSize: 12))),
                pw.Text("${t.hours}h × ₹${t.rate} = ₹${t.total}", style: pw.TextStyle(font: font, fontSize: 12)),
              ],
            ),
          )),
          pw.SizedBox(height: 8),

          // Expenses Section
          pw.Text("Expenses",
              style: pw.TextStyle(font: font, fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          ...expenses.map((e) => pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 2),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Expanded(child: pw.Text(e.title, style: pw.TextStyle(font: font, fontSize: 12))),
                pw.Text("₹${e.amount}", style: pw.TextStyle(font: font, fontSize: 12)),
              ],
            ),
          )),
          pw.SizedBox(height: 8),

          // Total section
          pw.Divider(),
          pw.SizedBox(height: 4),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text("Total", style: pw.TextStyle(font: font, fontWeight: pw.FontWeight.bold, fontSize: 12)),
              pw.Text("₹${invoice.totalAmount.toStringAsFixed(2)}",
                  style: pw.TextStyle(font: font, fontWeight: pw.FontWeight.bold, fontSize: 12)),
            ],
          ),
        ],
      ),
    );

    return pdf.save();
  }
}
