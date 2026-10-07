import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../data/repositories/loan_repository.dart';
import '../../../../core/error/failures.dart';

class SecureDocumentViewer extends StatefulWidget {
  final String documentId;

  const SecureDocumentViewer({super.key, required this.documentId});

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
    if (widget.documentId.startsWith('http')) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final url = await context.read<LoanRepository>().getSignedDocumentUrl(
        widget.documentId,
      );
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
    // 4F4F: Discard URL from active UI state
    _response = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Secure Document Viewer', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 16),
          Flexible(child: _buildContent(context)),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (widget.documentId.startsWith('http')) {
      final isPdf = widget.documentId.toLowerCase().contains('.pdf') || widget.documentId.toLowerCase().contains('format=pdf');
      
      if (isPdf) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.picture_as_pdf, size: 64, color: Colors.redAccent),
              const SizedBox(height: 16),
              const Text(
                'PDF Document',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: widget.documentId));
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Link copied to clipboard!')),
                  );
                },
                icon: const Icon(Icons.copy),
                label: const Text('Copy PDF Link'),
              ),
            ],
          ),
        );
      }

      final secureUrl = widget.documentId.replaceFirst('http://', 'https://');
      return Center(
        child: Image.network(
          secureUrl,
          fit: BoxFit.contain,
          errorBuilder: (_, err, ___) => _errorWidget(err),
        ),
      );
    }

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
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black87),
            ),
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

    bool isPdf = _response!.contentType == 'application/pdf';
    
    // Fallback magic byte check for PDF
    if (!isPdf && _response!.bytes.length > 4) {
      final b = _response!.bytes;
      if (b[0] == 37 && b[1] == 80 && b[2] == 68 && b[3] == 70) {
        isPdf = true;
      }
    }

    if (isPdf) {
      // PDF viewer logic
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.picture_as_pdf, size: 64, color: Colors.redAccent),
            const SizedBox(height: 16),
            const Text(
              'PDF loaded securely.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () async {
                // Since this is a GridFS secure PDF, the user needs the signed URL
                if (_response != null) {
                  // Wait, _response has bytes, not url string! 
                  // If we need to copy it, we can't because it's securely fetched bytes.
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Cannot copy link for secure document. Please take a screenshot or view on desktop.'),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.info_outline),
              label: const Text('PDF Details'),
            ),
          ],
        ),
      );
    }

    // 4F4F: We use standard Image.memory to avoid flutter_cache_manager storing the secure KYC doc
    // permanently in SQLitedisk cache. Memory cache will be cleared on logout.
    return Image.memory(
      _response!.bytes,
      fit: BoxFit.contain,
      errorBuilder: (_, err, ___) => _errorWidget(err),
    );
  }

  Widget _errorWidget([Object? err]) {
    String preview = '';
    if (!widget.documentId.startsWith('http') && _response != null) {
      preview = '\nSize: ${_response!.bytes.length} bytes\nContent-Type: ${_response!.contentType}';
      if (_response!.bytes.length > 5) {
        preview += '\nMagic: ${_response!.bytes.take(5).toList()}';
      }
    }
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.broken_image, color: Colors.grey, size: 48),
          const SizedBox(height: 16),
          Text(err != null ? 'Error: $err$preview' : 'The secure document could not be loaded.$preview'),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: widget.documentId.startsWith('http') ? () => setState(() {}) : _fetchSignedUrl,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }
}
