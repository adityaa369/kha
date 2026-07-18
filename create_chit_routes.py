import os
import re

routes_content = """const express = require('express');
const { protect } = require('../middleware/auth');
const {
    createChitFund,
    sendInvite,
    getPendingInvites,
    acceptInvite,
    getManagedChitFunds,
    getJoinedChitFunds,
    startChitFund,
    submitBid,
    getBids,
    declareWinner
} = require('../controllers/chitFunds');

const router = express.Router();

router.post('/', protect, createChitFund);
router.get('/managed', protect, getManagedChitFunds);
router.get('/joined', protect, getJoinedChitFunds);

router.get('/invites', protect, getPendingInvites);
router.post('/:id/invite', protect, sendInvite);
router.post('/invites/:inviteId/accept', protect, acceptInvite);

router.post('/:id/start', protect, startChitFund);

router.post('/:id/bid', protect, submitBid);
router.get('/:id/bids', protect, getBids);
router.post('/:id/declare-winner', protect, declareWinner);

module.exports = router;
"""

os.makedirs('server/routes', exist_ok=True)
with open('server/routes/chitFunds.js', 'w', encoding='utf-8') as f:
    f.write(routes_content)

# Update index.js
index_path = 'server/index.js'
with open(index_path, 'r', encoding='utf-8') as f:
    content = f.read()

if "const chitFunds =" not in content:
    # Add route import
    content = content.replace(
        "const users = require('./routes/users');", 
        "const users = require('./routes/users');\nconst chitFunds = require('./routes/chitFunds');"
    )
    # Add route use
    content = content.replace(
        "app.use('/api/users', users);",
        "app.use('/api/users', users);\napp.use('/api/chitfunds', chitFunds);"
    )
    with open(index_path, 'w', encoding='utf-8') as f:
        f.write(content)
        
print("Chit routes created and registered")
