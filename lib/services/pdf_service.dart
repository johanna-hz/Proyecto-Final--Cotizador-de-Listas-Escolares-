import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/quote_model.dart';
import 'package:intl/intl.dart';

class PdfService {
  static Future<Uint8List> generateQuotePdf(QuoteModel quote) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy');
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    pw.MemoryImage? logoImage;
    try {
      final ByteData data = await rootBundle.load('assets/images/logo.jpg');
      logoImage = pw.MemoryImage(data.buffer.asUint8List());
    } catch (_) {
      try {
        final ByteData data = await rootBundle.load('assets/images/logo.png');
        logoImage = pw.MemoryImage(data.buffer.asUint8List());
      } catch (_) {
        logoImage = null;
      }
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header with Logo, Business Name, Address & Phone
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    children: [
                      if (logoImage != null) ...[
                        pw.Image(logoImage, width: 50, height: 50),
                        pw.SizedBox(width: 12),
                      ],
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'TRIATES PAPELERÍA',
                            style: pw.TextStyle(
                              fontSize: 20,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.cyan800,
                            ),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text('Listas Escolares y Artículos de Oficina', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                          pw.Text('Calle Rosal #176, Col. Valle de las Flores Infonavit', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                          pw.Text('Tel: 844 673 7122', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.cyan900)),
                        ],
                      ),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.cyan800, width: 1.5),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('NOTA / COTIZACIÓN', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                        pw.Text('Fecha: ${dateFormat.format(quote.createdAt)}', style: const pw.TextStyle(fontSize: 9)),
                        pw.Text('Estado: ${quote.status}', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.pink700)),
                      ],
                    ),
                  ),
                ],
              ),
              pw.Divider(height: 16, thickness: 1.5, color: PdfColors.cyan800),
              
              // Client & Student Info
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey200,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Cliente: ${quote.clientName}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                        pw.SizedBox(height: 2),
                        pw.Text('Teléfono: ${quote.clientPhone.isEmpty ? "N/D" : quote.clientPhone}', style: const pw.TextStyle(fontSize: 10)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Alumno / Grado: ${quote.studentOrGrade}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                        pw.SizedBox(height: 2),
                        pw.Text('Entrega estimada: ${dateFormat.format(quote.deliveryDate)}', style: const pw.TextStyle(fontSize: 10)),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 12),

              // Items Table
              pw.Text('Detalle de Artículos', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.cyan800)),
              pw.SizedBox(height: 6),
              pw.TableHelper.fromTextArray(
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.cyan700),
                cellAlignment: pw.Alignment.centerLeft,
                cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                headers: ['Artículo', 'Marca', 'Cant.', 'Precio U.', 'Importe'],
                data: quote.items.map((item) {
                  double importe = item.unitPrice * item.quantity;
                  return [
                    item.name,
                    item.brand,
                    item.quantity.toString(),
                    currencyFormat.format(item.unitPrice),
                    currencyFormat.format(importe),
                  ];
                }).toList(),
              ),
              pw.SizedBox(height: 12),

              // Totals & Balances
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Container(
                    width: 220,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                      children: [
                        _buildTotalRow('Subtotal:', currencyFormat.format(quote.subtotal)),
                        if (quote.discount > 0)
                          _buildTotalRow('Descuento (10%):', '- ${currencyFormat.format(quote.discount)}', color: PdfColors.red700),
                        _buildTotalRow('TOTAL:', currencyFormat.format(quote.total), isBold: true, fontSize: 11),
                        pw.Divider(color: PdfColors.grey400, height: 8),
                        _buildTotalRow('Abono / Anticipo:', currencyFormat.format(quote.advancePayment), color: PdfColors.green800),
                        _buildTotalRow('SALDO PENDIENTE:', currencyFormat.format(quote.remainingBalance), isBold: true, fontSize: 11, color: quote.remainingBalance > 0 ? PdfColors.red900 : PdfColors.green900),
                      ],
                    ),
                  ),
                ],
              ),
              pw.Spacer(),

              // Footer note
              pw.Center(
                child: pw.Text(
                  '¡Gracias por su preferencia en Triates Papelería!',
                  style: pw.TextStyle(fontStyle: pw.FontStyle.italic, fontSize: 10, color: PdfColors.grey600),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildTotalRow(String label, String value, {bool isBold = false, double fontSize = 10, PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: fontSize, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal, color: color)),
          pw.Text(value, style: pw.TextStyle(fontSize: fontSize, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal, color: color)),
        ],
      ),
    );
  }

  static Future<void> printOrSharePdf(QuoteModel quote) async {
    try {
      final Uint8List pdfBytes = await generateQuotePdf(quote);
      await Printing.sharePdf(bytes: pdfBytes, filename: 'Cotizacion_Triates_${quote.clientName.replaceAll(' ', '_')}.pdf');
    } catch (e) {
      rethrow;
    }
  }
}
