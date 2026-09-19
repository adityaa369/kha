import sys
sys.stdout.reconfigure(encoding='utf-8')
with open('server/controllers/auth.js', 'r', encoding='utf-8') as f:
    content = f.read()

new_method = '''

// @desc    Generate a custom token for the authenticated user to re-authenticate with Firebase
// @route   GET /api/auth/firebase-custom-token
// @access  Private
exports.getFirebaseCustomToken = async (req, res) => {
    try {
        const MPinCredential = require('../models/MPinCredential');
        const mpinCred = await MPinCredential.findOne({ userId: req.user._id });
        
        if (!mpinCred || !mpinCred.firebaseUid) {
            return res.status(404).json({ success: false, message: 'Firebase UID not found for user.' });
        }
        
        const admin = require('firebase-admin');
        const customToken = await admin.auth().createCustomToken(mpinCred.firebaseUid);
        res.status(200).json({ success: true, customToken });
    } catch (err) {
        console.error('[Auth] Error generating custom token:', err.message);
        res.status(500).json({ success: false, message: 'Server Error' });
    }
};
'''

content += new_method

with open('server/controllers/auth.js', 'w', encoding='utf-8') as f:
    f.write(content)
