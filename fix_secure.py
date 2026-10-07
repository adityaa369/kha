import sys
filepath = 'lib/features/loans/presentation/widgets/secure_document_viewer.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

target_build = """  Widget build(BuildContext context) {"""
replacement_build = """  Widget build(BuildContext context) {
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

  Widget _buildContent(BuildContext context) {"""

content = content.replace(target_build, replacement_build)

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)
print('Fixed secure document viewer background')
