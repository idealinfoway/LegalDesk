import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

class ImportedClientData {
  final String? name;
  final String? phone;
  final String? email;
  final String? city;
  final String? state;

  const ImportedClientData({this.name, this.phone, this.email, this.city, this.state});
}

class ContactImportService {
  /// Requests permission and opens the native contact picker.
  /// Returns null if permission denied or user cancels.
  static Future<ImportedClientData?> pickClientFromContacts(BuildContext context) async {
    try {
      // Request permission; for Android 13+ this is a runtime prompt; for iOS requires Info.plist key
      final granted = await FlutterContacts.requestPermission(readonly: true);
      if (!granted) {
        _notify(context, 'Permission denied. Enable Contacts permission to import.');
        return null;
      }

      // Use built-in contact picker (returns only the selected contact's id/display info)
      final picked = await FlutterContacts.openExternalPick();
      if (picked == null) {
        // user cancelled
        return null;
      }

      // We have only id/displayName, refetch with details to get phones/emails/addresses
      final contact = await FlutterContacts.getContact(picked.id, withProperties: true, withPhoto: false);
      if (contact == null) {
        _notify(context, 'Could not read selected contact.');
        return null;
      }

      final name = _composeName(contact);
      final phone = _chooseBestPhone(contact);
      final email = _chooseBestEmail(contact);
      final address = _firstAddress(contact);

      return ImportedClientData(
        name: name,
        phone: phone,
        email: email,
        city: address?.city?.trim().isEmpty == true ? null : address?.city,
        // state: address?.region?.trim().isEmpty == true ? null : address?.region,
      );
    } catch (e) {
      _notify(context, 'Contact import failed: $e');
      return null;
    }
  }

  static void _notify(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  static String? _composeName(Contact c) {
    final dn = c.displayName.trim();
    if (dn.isNotEmpty) return dn;
    final parts = [c.name.first, c.name.last].where((e) => e != null && e.trim().isNotEmpty).map((e) => e!.trim()).toList();
    return parts.isEmpty ? null : parts.join(' ');
  }

  static String? _chooseBestPhone(Contact c) {
    if (c.phones.isEmpty) return null;
    // Prefer mobile, else first non-empty
    c.phones.sort((a, b) {
      final am = a.label.toString().toLowerCase().contains('mobile') ? 0 : 1;
      final bm = b.label.toString().toLowerCase().contains('mobile') ? 0 : 1;
      return am.compareTo(bm);
    });
    final raw = c.phones.first.number;
    return _normalizePhone(raw);
  }

  static String? _chooseBestEmail(Contact c) {
    if (c.emails.isEmpty) return null;
    // Prefer work/professional email
    c.emails.sort((a, b) {
      int score(String label) {
        label = label.toLowerCase();
        if (label.contains('work')) return 0;
        if (label.contains('office')) return 1;
        return 2;
      }
      return score(a.label.toString()).compareTo(score(b.label.toString()));
    });
    final raw = c.emails.first.address.trim();
    return raw.isEmpty ? null : raw;
  }

  static Address? _firstAddress(Contact c) {
    if (c.addresses.isEmpty) return null;
    return c.addresses.first;
  }

  /// Normalize phone by removing spaces, dashes, parentheses; keep leading + if present.
  static String? _normalizePhone(String? input) {
    if (input == null) return null;
    input = input.trim();
    if (input.isEmpty) return null;
    final hasPlus = input.startsWith('+');
    final digits = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return null;
    return hasPlus ? '+$digits' : digits;
  }
}
