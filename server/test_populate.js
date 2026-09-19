const mongoose = require('mongoose');
const { Schema } = mongoose;

const userSchema = new Schema({
    id: { type: String, required: true },
    name: String
});
const User = mongoose.model('User', userSchema);

const loanSchema = new Schema({
    lender: { type: String, ref: 'User' }
});
const Loan = mongoose.model('Loan', loanSchema);

async function run() {
    await mongoose.connect('mongodb://localhost:27017/test_populate');
    await User.deleteMany({});
    await Loan.deleteMany({});
    
    await User.create({ id: 'firebase_123', name: 'John Doe' });
    const loan = await Loan.create({ lender: 'firebase_123' });
    
    try {
        const doc = await Loan.findById(loan._id).populate({
            path: 'lender',
            model: 'User',
            localField: 'lender',
            foreignField: 'id'
        });
        console.log('Success:', doc.lender.name);
    } catch (err) {
        console.error('Error:', err.message);
    }
    
    process.exit(0);
}
run();
