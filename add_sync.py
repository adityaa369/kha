with open('server/controllers/auth.js', 'r', encoding='utf-8') as f:
    content = f.read()

new_method = '''

// @desc    Sync Firebase State to Khatha DB
// @route   POST /api/auth/sync-firebase
// @access  Private
exports.syncFirebaseState = async (req, res) => {
    try {
        const { emailVerified, email } = req.body;
        const User = require('../models/User');
        const user = await User.findOne({ id: req.user.id });
        
        if (!user) {
            return res.status(404).json({ success: false, message: 'User not found' });
        }
        
        if (emailVerified !== undefined) {
            user.isEmailVerified = emailVerified;
        }
        if (email) {
            user.email = email;
        }
        
        await user.save();
        res.status(200).json({ success: true, message: 'Firebase state synced' });
    } catch (err) {
        console.error('[Auth] Error syncing firebase state:', err.message);
        res.status(500).json({ success: false, message: 'Server Error' });
    }
};
'''

content += new_method

with open('server/controllers/auth.js', 'w', encoding='utf-8') as f:
    f.write(content)
