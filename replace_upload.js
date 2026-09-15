const fs = require('fs');
let content = fs.readFileSync('server/controllers/loans.js', 'utf8');

const replacement = `// @desc    Upload document
// @route   POST /api/loans/upload-document
// @access  Private
exports.uploadDocument = async (req, res) => {
    try {
        const { fileName, fileType, base64Data } = req.body;

        // Security: validate file extension
        const ALLOWED_EXTENSIONS = ['.pdf', '.jpg', '.jpeg', '.png'];
        const ALLOWED_MIME_TYPES = ['application/pdf', 'image/jpeg', 'image/png'];
        
        // Sanitize filename
        const sanitizedName = (fileName || 'document')
            .replace(/[^a-zA-Z0-9._\\-]/g, '_')
            .replace(/\\.\\./g, '')
            .substring(0, 100);
        
        const ext = require('path').extname(sanitizedName).toLowerCase();
        if (!ALLOWED_EXTENSIONS.includes(ext) && ext !== '') {
            return res.status(400).json({
                success: false,
                message: \`File type not allowed. Allowed: \${ALLOWED_EXTENSIONS.join(', ')}\`
            });
        }
        
        if (!ALLOWED_MIME_TYPES.includes(fileType)) {
            return res.status(400).json({
                success: false,
                message: 'Invalid file MIME type'
            });
        }
        
        // Validate base64 size (max 5MB decoded)
        const estimatedSize = (base64Data.length * 3) / 4;
        if (estimatedSize > 5 * 1024 * 1024) {
            return res.status(400).json({
                success: false,
                message: 'File too large. Maximum size is 5MB.'
            });
        }

        if (!fileName || !fileType || !base64Data) {
            return res.status(400).json({ success: false, message: 'Please provide fileName, fileType and base64Data' });
        }

        const buffer = Buffer.from(base64Data, 'base64');
        const GridFSService = require('../services/GridFSService');
        
        const documentId = await GridFSService.uploadDocument(buffer, sanitizedName, fileType, {
            uploadedBy: req.user.id,
            size: buffer.length,
            createdAt: new Date()
        });

        console.log(\`[Upload] Uploaded successfully to GridFS: \${documentId}\`);
        return res.status(200).json({ success: true, documentId: documentId.toString() });

    } catch (err) {
        console.error('[Upload] Upload failed:', err.message);
        return res.status(500).json({ success: false, message: 'Server error during upload' });
    }
};

`;

const startIdx = content.indexOf('// @desc    Upload document');
if (startIdx !== -1) {
    const newContent = content.substring(0, startIdx) + replacement;
    fs.writeFileSync('server/controllers/loans.js', newContent);
    console.log('Successfully replaced uploadDocument');
} else {
    console.log('Could not find marker', startIdx);
}
