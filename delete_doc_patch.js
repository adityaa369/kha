const fs = require('fs');

// 1. Add deleteDocument to controllers/loans.js
let controller = fs.readFileSync('../khataa_backend/controllers/loans.js', 'utf8');

const deleteDocLogic = `
// @desc    Delete document (cleanup orphaned uploads)
// @route   POST /api/loans/delete-document
// @access  Private
exports.deleteDocument = async (req, res) => {
    try {
        const { documentId } = req.body;
        if (!documentId) return res.status(400).json({ success: false, message: 'Missing documentId' });

        if (documentId.startsWith('documents/')) {
            const bucketName = process.env.FIREBASE_STORAGE_BUCKET || 'khaata-42b18.appspot.com';
            const { getStorage } = require('firebase-admin/storage');
            const bucket = getStorage().bucket(bucketName);
            const file = bucket.file(documentId);
            
            const [exists] = await file.exists();
            if (exists) {
                const [metadata] = await file.getMetadata();
                if (metadata.metadata && metadata.metadata.uploadedBy === req.user.id) {
                    await file.delete();
                    console.log(\`[Cleanup] Deleted orphaned document \${documentId}\`);
                    return res.status(200).json({ success: true, message: 'Document deleted' });
                } else {
                    console.warn(\`[Security] User \${req.user.id} attempted to delete document \${documentId} owned by another user\`);
                    return res.status(403).json({ success: false, message: 'Unauthorized' });
                }
            } else {
                return res.status(404).json({ success: false, message: 'Document not found' });
            }
        } else if (documentId.startsWith('local/')) {
            const path = require('path');
            const fsLocal = require('fs');
            const localPath = path.join(__dirname, '..', 'uploads', documentId.replace('local/', ''));
            if (fsLocal.existsSync(localPath)) {
                fsLocal.unlinkSync(localPath);
                console.log(\`[Cleanup] Deleted local orphaned document \${documentId}\`);
                return res.status(200).json({ success: true, message: 'Document deleted' });
            }
            return res.status(404).json({ success: false, message: 'Document not found' });
        } else {
            return res.status(400).json({ success: false, message: 'Invalid documentId format' });
        }
    } catch (err) {
        console.error('[Cleanup] Error deleting document:', err.message);
        return res.status(500).json({ success: false, message: 'Server error during cleanup' });
    }
};

`;

if (!controller.includes('exports.deleteDocument')) {
    controller += deleteDocLogic;
    fs.writeFileSync('../khataa_backend/controllers/loans.js', controller);
}

// 2. Add route to routes/loans.js
let routes = fs.readFileSync('../khataa_backend/routes/loans.js', 'utf8');
if (!routes.includes('deleteDocument')) {
    routes = routes.replace(
        'const {',
        'const {\n    deleteDocument,'
    );
    routes = routes.replace(
        "router.post('/upload-document', protect, uploadDocument);",
        "router.post('/upload-document', protect, uploadDocument);\nrouter.post('/delete-document', protect, deleteDocument);"
    );
    fs.writeFileSync('../khataa_backend/routes/loans.js', routes);
}
console.log('Backend delete route added');
