const fs = require('fs');

let content = fs.readFileSync('../khataa_backend/controllers/loans.js', 'utf8');

const verifyDocsLogic = `
        // --- SECURITY FIX: Verify documentIds ---
        let verifiedDocumentIds = [];
        const allDocumentIds = [];
        if (documentId) allDocumentIds.push(documentId);
        if (Array.isArray(documentIds)) allDocumentIds.push(...documentIds);

        if (allDocumentIds.length > 0) {
            const bucketName = process.env.FIREBASE_STORAGE_BUCKET || 'khaata-42b18.appspot.com';
            const { getStorage } = require('firebase-admin/storage');
            const bucket = getStorage().bucket(bucketName);
            
            for (const docId of allDocumentIds) {
                if (typeof docId !== 'string') continue;
                
                // Allow only expected paths
                if (!docId.startsWith('documents/') && !docId.startsWith('local/')) {
                    console.warn(\`[Security] Rejected arbitrary document path: \${docId}\`);
                    continue; 
                }

                if (docId.startsWith('documents/')) {
                    try {
                        const file = bucket.file(docId);
                        const [exists] = await file.exists();
                        if (exists) {
                            const [metadata] = await file.getMetadata();
                            const uploadedBy = metadata.metadata?.uploadedBy;
                            if (uploadedBy === req.user.id) {
                                verifiedDocumentIds.push(docId);
                            } else {
                                console.warn(\`[Security] User \${req.user.id} attempted to use document \${docId} owned by \${uploadedBy}\`);
                            }
                        }
                    } catch (err) {
                        console.error(\`[Security] Error verifying document \${docId}:\`, err.message);
                    }
                } else if (docId.startsWith('local/')) {
                    // Local fallback verification (in dev mode)
                    const fs = require('fs');
                    const path = require('path');
                    const localPath = path.join(__dirname, '..', 'uploads', docId.replace('local/', ''));
                    // Note: We don't have metadata tracking for local uploads currently.
                    // We just verify it exists to prevent saving garbage strings.
                    if (fs.existsSync(localPath)) {
                        verifiedDocumentIds.push(docId);
                    }
                }
            }
        }
        
        const finalDocumentIds = verifiedDocumentIds;
        const finalDocumentId = finalDocumentIds.length > 0 ? finalDocumentIds[0] : undefined;
        // ----------------------------------------

        const loan = await Loan.create({
`;

content = content.replace(
    '        const loan = await Loan.create({',
    verifyDocsLogic
);

// We also need to update the Loan.create call to use finalDocumentId and finalDocumentIds
content = content.replace(
    'documentId, documentIds, otp: \'FIREBASE_OTP\',',
    'documentId: finalDocumentId, documentIds: finalDocumentIds, otp: \'FIREBASE_OTP\','
);

fs.writeFileSync('../khataa_backend/controllers/loans.js', content);
