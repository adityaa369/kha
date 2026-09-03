import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';


import '../../../../data/repositories/loan_repository.dart';
import '../../../../core/error/failures.dart';

class SecureDocumentViewer extends StatefulWidget {
  final String documentId;
  

  const SecureDocumentViewer({
    super.key,
    required this.documentId,
    
  });

  @override
  State<SecureDocumentViewer> createState() => _SecureDocumentViewerState();
}

class _SecureDocumentViewerState extends State<SecureDocumentViewer> {
  DocumentResponse? _response;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchSignedUrl();
  }

  Future<void> _fetchSignedUrl() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final url = await context.read<LoanRepository>().getSignedDocumentUrl(widget.documentId);
      if (mounted) {
        setState(() {
          _response = url;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (e is AuthFailure) {
          _error = "You don't have access to this document.";
        } else if (e is ValidationFailure) {
          _error = "Document unavailable or not found.";
        } else {
          _error = "Failed to load document securely. Please try again.";
        }
      });
    }
  }

  @override
  void dispose() {
    // 4F-4F: Discard URL from active UI state
    _response = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade400, size: 48),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black87)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _fetchSignedUrl,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_response == null) {
      return const Center(child: Text('Document URL could not be resolved.'));
    }

    if (_response!.contentType == 'application/pdf') {
      // PDF viewer logic
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.picture_as_pdf, size: 64, color: Colors.redAccent),
            const SizedBox(height: 16),
            const Text('PDF loaded securely.', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {
                // In a real app, open flutter_pdfview or similar here.
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Opening PDF is not supported in this test env.')),
                );
              },
              icon: const Icon(Icons.open_in_new),
              label: const Text('View PDF'),
            ),
          ],
        ),
      );
    }

    // 4F-4F: We use standard Image.network to avoid flutter_cache_manager storing the secure KYC doc
    // permanently in SQLite/disk cache. Memory cache will be cleared on logout.
    return Image.network(
      _response!.url,
      fit: BoxFit.contain,
      loadingBuilder: (ctx, child, p) => p == null
          ? child
          : const Center(child: CircularProgressIndicator()),
      errorBuilder: (_, __, ___) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.broken_image, color: Colors.grey, size: 48),
            const SizedBox(height: 16),
            const Text('The secure link may have expired.'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _fetchSignedUrl,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh Link'),
            ),
          ],
        ),
      ),
    );
  }
}
